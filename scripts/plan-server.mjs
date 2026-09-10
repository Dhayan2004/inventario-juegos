#!/usr/bin/env node
// plan-server.mjs — server-lite zero-dep del plano de control (.plan/) de Forge Enterprise (A1).
//
// Sirve plan.html y persiste el estado en disco/git como única fuente de verdad. Reemplaza el
// LocalStorage del skill project-kanban-dashboard (que el agente no podía leer → dos verdades).
//
//   GET  /                 → plan.html
//   GET  /api/plan         → plan.json + reflejo READ-ONLY de feature_list.json por featureRefs
//   GET  /api/activity     → activity.log.jsonl parseado (array de eventos)
//   POST /api/event        → valida + appendea al log; si el evento muta estado, lo aplica a plan.json
//
// Separación mutable/acumulativo (PLAN_SCHEMA.md §1): plan.json = last-write-wins por campo,
// serializado por una cola single-process; activity.log.jsonl = append-only (O_APPEND atómico).
// Zero-dep: sólo módulos built-in de Node. Doctrina: ../.claude/references/PLAN_SCHEMA.md
//
// Uso: node scripts/plan-server.mjs [--port 4317]   (corre desde la raíz del proyecto)

import http from 'node:http'
import fs from 'node:fs'
import fsp from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url))
const ROOT = process.cwd()
const PLAN_DIR = path.join(ROOT, '.plan')
const PLAN_JSON = path.join(PLAN_DIR, 'plan.json')
const ACTIVITY_LOG = path.join(PLAN_DIR, 'activity.log.jsonl')
const LOCK = path.join(PLAN_DIR, '.lock')
const FEATURE_LIST = path.join(ROOT, 'feature_list.json')
const PLAN_HTML = path.join(SCRIPT_DIR, 'plan.html')

const argPort = (() => {
  const i = process.argv.indexOf('--port')
  return i !== -1 && process.argv[i + 1] ? Number(process.argv[i + 1]) : null
})()
const PORT = argPort || Number(process.env.PLAN_PORT) || 4317

const EVENT_TYPES = new Set([
  'note', 'link', 'file', 'status_change', 'stage_change',
  'playwright', 'test_result', 'annotation', 'blocker_open', 'blocker_resolve',
  'decision_add', 'decision_supersede',
])
const MUTATING = new Set(['status_change', 'stage_change', 'blocker_open', 'blocker_resolve',
  'decision_add', 'decision_supersede'])
const STATUSES = new Set(['done', 'in_progress', 'pending', 'blocked'])

// ─── persistence helpers ─────────────────────────────────────────────────────
function readPlan() {
  return JSON.parse(fs.readFileSync(PLAN_JSON, 'utf8'))
}
async function writePlanAtomic(plan) {
  const tmp = PLAN_JSON + '.tmp'
  await fsp.writeFile(tmp, JSON.stringify(plan, null, 2) + '\n', 'utf8')
  await fsp.rename(tmp, PLAN_JSON) // atomic on POSIX
}
async function appendEvent(ev) {
  await fsp.appendFile(ACTIVITY_LOG, JSON.stringify(ev) + '\n', { flag: 'a' }) // O_APPEND
}
function readActivity() {
  if (!fs.existsSync(ACTIVITY_LOG)) return []
  return fs.readFileSync(ACTIVITY_LOG, 'utf8')
    .split('\n').filter(Boolean).map((l, i) => {
      try { return JSON.parse(l) } catch { return { _parseError: true, line: i + 1, raw: l } }
    })
}

// walk phases → subphases → stories
function findStory(plan, id) {
  for (const ph of plan.phases || [])
    for (const sp of ph.subphases || [])
      for (const st of sp.stories || [])
        if (st.id === id) return st
  return null
}

// READ-ONLY reflection of feature_list.json (the build truth) — never writes it.
function reflectFeatures(plan) {
  let features = {}
  try {
    const fl = JSON.parse(fs.readFileSync(FEATURE_LIST, 'utf8'))
    for (const f of fl.features || []) features[f.id] = f.state || f.status || 'unknown'
  } catch { /* no feature_list or unreadable → degrade: empty reflection */ }
  const reflected = JSON.parse(JSON.stringify(plan))
  for (const ph of reflected.phases || [])
    for (const sp of ph.subphases || [])
      for (const st of sp.stories || []) {
        const refs = (st.featureRefs || []).map((id) => ({ id, state: features[id] || 'unknown' }))
        st._featureStatus = refs // injected, read-only, not persisted
      }
  return reflected
}

// ─── single-process mutation queue (serializes read-modify-write of plan.json) ──
let chain = Promise.resolve()
function enqueue(task) {
  const run = chain.then(task, task)
  chain = run.catch(() => {}) // keep the chain alive on error
  return run
}

function lockHeldByAgent() {
  // agent FS-direct writes take .plan/.lock; the server defers to it (stale after 30s).
  try {
    const st = fs.statSync(LOCK)
    return (Date.now() - st.mtimeMs) < 30_000
  } catch { return false }
}

function applyMutation(plan, ev) {
  switch (ev.type) {
    case 'status_change': {
      const st = findStory(plan, ev.target)
      if (!st) throw new Error(`story not found: ${ev.target}`)
      if (!STATUSES.has(ev.to)) throw new Error(`invalid status: ${ev.to}`)
      ev.from = st.status // record actual previous for the log
      st.status = ev.to
      break
    }
    case 'stage_change':
      plan.project = plan.project || {}
      plan.project.currentStage = ev.to
      break
    case 'blocker_open':
      plan.blockers = plan.blockers || []
      if (!plan.blockers.find((b) => b.id === ev.blocker?.id)) plan.blockers.push(ev.blocker)
      break
    case 'blocker_resolve': {
      const b = (plan.blockers || []).find((x) => x.id === ev.target)
      if (b) { b.severity = 'resolved'; b.resolvedAt = ev.ts.slice(0, 10) }
      break
    }
    case 'decision_add': {
      // las decisiones tomadas NO se pierden: entran al plano como estado de primera clase
      if (!ev.decision || !ev.decision.id) throw new Error('decision_add requires ev.decision.id')
      plan.decisions = plan.decisions || []
      if (!plan.decisions.find((d) => d.id === ev.decision.id)) {
        plan.decisions.push({ status: 'vigente', supersededBy: null, date: ev.ts.slice(0, 10), ...ev.decision })
      }
      break
    }
    case 'decision_supersede': {
      const d = (plan.decisions || []).find((x) => x.id === ev.target)
      if (!d) throw new Error(`decision not found: ${ev.target}`)
      d.status = 'superseded'
      d.supersededBy = ev.by || null
      d.supersededAt = ev.ts.slice(0, 10)
      break
    }
  }
  plan.project = plan.project || {}
  plan.project.lastUpdate = ev.ts.slice(0, 10)
  return plan
}

async function handleEvent(raw) {
  if (!raw || typeof raw !== 'object') throw new Error('event must be an object')
  if (!EVENT_TYPES.has(raw.type)) throw new Error(`unknown event type: ${raw.type}`)
  // actor: 'agent' | 'human' | <member.name> del roster .forja/team.json (PLAN_SCHEMA §3, S2)
  if (typeof raw.actor !== 'string' || !/^[a-z0-9_-]{1,32}$/i.test(raw.actor)) {
    throw new Error('actor must be agent|human|<member.name> (alfanumérico, ≤32)')
  }
  if (!raw.target) throw new Error('event.target required')
  const ev = { ts: new Date().toISOString(), commit: null, ...raw }
  ev.ts = ev.ts || new Date().toISOString()
  ev.commit = null // always unsealed at write time; post-commit hook seals it

  return enqueue(async () => {
    if (MUTATING.has(ev.type)) {
      // defer to an agent FS-direct write if it holds the lock
      let waited = 0
      while (lockHeldByAgent() && waited < 5000) { await new Promise((r) => setTimeout(r, 100)); waited += 100 }
      const plan = readPlan()
      applyMutation(plan, ev)
      await writePlanAtomic(plan)
    }
    await appendEvent(ev)
    return ev
  })
}

// ─── http ────────────────────────────────────────────────────────────────────
function send(res, code, body, type = 'application/json') {
  const payload = type === 'application/json' ? JSON.stringify(body) : body
  res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store' })
  res.end(payload)
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://localhost:${PORT}`)
    if (req.method === 'GET' && (url.pathname === '/' || url.pathname === '/plan.html')) {
      if (!fs.existsSync(PLAN_HTML)) return send(res, 500, '<h1>plan.html no encontrado</h1>', 'text/html')
      return send(res, 200, fs.readFileSync(PLAN_HTML, 'utf8'), 'text/html; charset=utf-8')
    }
    if (req.method === 'GET' && url.pathname === '/api/plan') {
      if (!fs.existsSync(PLAN_JSON)) return send(res, 404, { error: 'no .plan/plan.json — corré /cartografo' })
      return send(res, 200, reflectFeatures(readPlan()))
    }
    if (req.method === 'GET' && url.pathname === '/api/activity') {
      return send(res, 200, readActivity())
    }
    if (req.method === 'POST' && url.pathname === '/api/event') {
      let body = ''
      for await (const chunk of req) { body += chunk; if (body.length > 1e6) { req.destroy(); return } }
      let parsed
      try { parsed = JSON.parse(body || '{}') } catch { return send(res, 400, { error: 'invalid JSON' }) }
      try {
        const ev = await handleEvent(parsed)
        return send(res, 200, { ok: true, event: ev })
      } catch (e) {
        return send(res, 400, { error: String(e.message || e) })
      }
    }
    return send(res, 404, { error: 'not found' })
  } catch (e) {
    return send(res, 500, { error: String(e.message || e) })
  }
})

if (!fs.existsSync(PLAN_DIR)) {
  console.error(`⚠️  No existe ${path.relative(ROOT, PLAN_DIR)}/ — corré el skill /cartografo para inicializar el plano.`)
}
server.listen(PORT, () => {
  console.log(`🗺️  plan-server en http://localhost:${PORT}  (SoT: .plan/ · LEE feature_list.json read-only)`)
})

export { handleEvent, applyMutation, findStory, reflectFeatures } // for tests
