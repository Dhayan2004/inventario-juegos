#!/usr/bin/env node
// handoff.mjs — Conciencia de contexto (F-P5.1 · docs/06 §12.2 · D-034)
//
// Escribe .forja/HANDOFF.md con el estado real del build para que la próxima
// sesión (o el agente tras una compactación de contexto) retome sin re-preguntar.
// Zero-dep, mismo estilo que plan-server.mjs / apply-ontology-migrations.mjs.
//
// Invocación:
//   node scripts/handoff.mjs                      # manual (/handoff)
//   node scripts/handoff.mjs --source=precompact  # hook PreCompact (automático)
//
// Degradación segura: sin git, sin feature_list.json o sin .plan/, cada
// sección reporta su ausencia en vez de fallar. Exit != 0 solo ante error
// de escritura del propio HANDOFF.md.

import { execSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const OUT_DIR = join(ROOT, ".forja");
const OUT_FILE = join(OUT_DIR, "HANDOFF.md");

const sourceArg = process.argv.find((a) => a.startsWith("--source="));
const SOURCE = sourceArg ? sourceArg.split("=")[1] : "manual";

function sh(cmd) {
  try {
    return execSync(cmd, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] })
      .toString()
      .trim();
  } catch {
    return null;
  }
}

function readJSON(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

// ── Estado git ───────────────────────────────────────────────────────────────
const branch = sh("git rev-parse --abbrev-ref HEAD");
const commits = sh("git log --oneline -5");
const status = sh("git status --short");

// ── State machine (feature_list.json · R1/R3) ────────────────────────────────
const fl = readJSON(join(ROOT, "feature_list.json"));
const active = fl?.features?.find((f) => f.state === "active") ?? null;
const phase = fl?.phase ?? null;

// ── Fase SDD por artefactos (Fase −1 → 0 → plan → build) ────────────────────
const artifacts = [
  ["ONTOLOGY.md", "Fase −1 · ontología levantada"],
  ["SPEC.md", "Fase 0 · spec desambiguado"],
  ["CONTEXT.md", "Fase 0 · glosario de dominio"],
].filter(([f]) => existsSync(join(ROOT, f)));

// ── Plano de control (.plan/ · R17) ──────────────────────────────────────────
let planLine = "— (sin `.plan/` — R17 no aplica)";
if (existsSync(join(ROOT, ".plan", "plan.json"))) {
  planLine = existsSync(join(ROOT, ".plan", ".inconsistent"))
    ? "⚠ `.plan/.inconsistent` presente — reconciliar ANTES de seguir (R17)"
    : "✓ `.plan/plan.json` presente y sin marcador de inconsistencia";
}

// ── Composición ──────────────────────────────────────────────────────────────
const now = new Date().toISOString();
const md = `# HANDOFF — contexto de sesión (auto)

> **Generado:** ${now} · **Fuente:** ${SOURCE} · **Rama:** ${branch ?? "(sin git)"}
> Escrito por \`scripts/handoff.mjs\` (F-P5.1). En sesión nueva: \`/avivar\` lo lee primero.
> Fuente de verdad del build sigue siendo \`feature_list.json\` + hooks — esto es contexto, no estado.

## Estado

- **Fase (feature_list.json):** ${phase ?? "(sin feature_list.json — corré /forge-check)"}
- **Active feature (R1):** ${active ? `\`${active.id}\` — ${active.behavior ?? "(sin descripción)"} · verificación: \`${active.verification ?? "—"}\`` : "(ninguna en `active`)"}
- **Artefactos SDD presentes:** ${artifacts.length ? artifacts.map(([f, d]) => `\`${f}\` (${d})`).join(" · ") : "(ninguno — pre Fase −1/0)"}
- **Plano de control:** ${planLine}

## Últimos commits

\`\`\`
${commits ?? "(sin git)"}
\`\`\`

## Working tree

\`\`\`
${status || "(limpio)"}
\`\`\`

## Siguiente acción

${active ? `Continuar \`${active.id}\`: correr su verificación (\`${active.verification ?? "make test"}\`) y retomar desde el último commit de arriba.` : "Definir la siguiente feature (`/plan`) o activar una de `feature_list.json`."}

## Notas del agente

_(Sección para \`/handoff\` manual: qué se estaba haciendo, decisiones en vuelo aún no
commiteadas, bloqueos, y la siguiente acción EXACTA consciente de la fase SDD. El hook
PreCompact deja esta sección vacía — el agente la enriquece antes de compactar si puede.)_
`;

try {
  mkdirSync(OUT_DIR, { recursive: true });
  writeFileSync(OUT_FILE, md, "utf8");
  console.log(`⚒ handoff → .forja/HANDOFF.md (fuente: ${SOURCE})`);
} catch (err) {
  console.error(`handoff: no pude escribir ${OUT_FILE}: ${err.message}`);
  process.exit(1);
}
