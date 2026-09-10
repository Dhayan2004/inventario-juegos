# AGENTS.md — Forja Routing

> Routing file. Single entry point for any agent working on this project. Knowledge lives in dedicated files referenced below — this is a router, not a knowledge base.
>
> Cap: 200 lines. Each rule has explicit metadata: source, applicability, expiry. If a rule has no expiry, it expires when the architecture that justifies it changes.

## Identity

- **Repo:** target project — built with Forja
- **Version:** (ver `CHANGELOG.md`)
- **Audience:** AI coding agents (Claude Code primary, Codex secondary, Hermes optional supervisor)
- **Mode:** target project — built with Forja

## Cold-start test

Before doing anything, a fresh agent must answer these 5 questions reading only files in this repo:

1. ¿Qué construye este proyecto? → `README.md` + `BRAND.md`
2. ¿Cuál es el estado actual? → `CHANGELOG.md` + `PROGRESS.md`
3. ¿Qué comando corro para validar? → `Makefile`
4. ¿Cuál es la siguiente tarea? → `feature_list.json` (active) + git branch
5. ¿Dónde están las decisiones de arquitectura? → `.claude/memory/decisions.md`

If any answer is unclear, the repo is mis-routed — fix the routing before proceeding.

## PREFLIGHT halt

Every agent (orchestrator or sub-agent) must run this preflight at session start:

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada. Corré 'make setup'."
2. ¿Existe feature_list.json? Si no → halt: "Falta feature_list.json. Corré /forge-check para diagnóstico."
3. ¿Repo es greenfield (no commits) o tiene Bootstrap Contract cumplido? Si ninguno → halt: "Sin Bootstrap Contract. Corré /forge-check para diagnóstico."
```

> **Source:** relay-kit PREFLIGHT pattern + walkinglabs Bootstrap Contract.
> **Applicability:** any agent before any tool call.
> **Expiry:** never (universal).

## Hard rules (ver CONSTRAINTS.md para enforcement)

| # | Rule | Source | Expiry |
|---|------|--------|--------|
| R1 | WIP=1: solo una feature en `active` en `feature_list.json` | walkinglabs L07 | never |
| R2 | Atomic commits con conventional message: `<type>(<scope>): <desc>` | Forge legacy | never |
| R3 | Active feature se resuelve desde `git rev-parse --abbrev-ref HEAD` matching `^(feature\|fix\|refactor\|chore\|docs)/.+$`, fallback `.forja/HEAD` | relay-kit | never |
| R4 | Orchestrator NEVER invokes a skill — only sub-agents do | relay-kit | never |
| R5 | el-evaluador es el ÚNICO writer de `.claude/memory/*.md` | relay-kit | never |
| R6 | Toda invocación de skill valida nombre contra `.claude/memory/skills.md` ANTES del dispatch | relay-kit | never |
| R7 | Three-layer verification (Syntax → Runtime → System), no skip | walkinglabs L09 | never |
| R8 | Citation grammar para web claims: `[web:domain](url)` + `## Sources` final | relay-kit | never |
| R9 | Citation grammar para memory: `[memory:lessons#L-001]` | relay-kit | never |
| R10 | Brand DNA contract es contrato no-negociable: cada componente UI lee `brand.json` + `voice.json` antes de generar | D9 | never |

## Routing por tarea

| Si la tarea es… | Lee primero… | Skill primario |
|-----------------|--------------|----------------|
| Planificar feature nueva | `.claude/skills/la-herreria/` | `la-herreria` |
| Validar estrategia post-Blueprint | `.claude/skills/el-crisol/` | `el-crisol` |
| Construir feature aprobado | `.claude/skills/la-forja/` o el-yunque manual | `la-forja` |
| Microtarea atómica <5min | `.claude/skills/el-tajo/` | `el-tajo` |
| Feature mediano <30min one-shot | `.claude/skills/el-golpe/` | `el-golpe` |
| Auditar seguridad pre-deploy | `.claude/skills/el-guardian/` | `el-guardian` (Codex) |
| Migración Supabase | `.claude/skills/el-migrador/` | `el-migrador` |
| Generar UI con brand contract | `.claude/skills/add-ui-kit/` | `add-ui-kit` |
| Validar componente UI | `.claude/skills/el-evaluador/` | `el-evaluador` |
| Decidir BaaS (Supabase vs Insforge) | `.claude/skills/baas/` | `baas` |
| Integrar AI con Vercel SDK | `.claude/skills/ai/` | `ai` |
| Cargar contexto sesión | `.claude/skills/primer/` | `primer` |
| Guardar contexto antes de compactar/cerrar (handoff) | `.claude/commands/handoff.md` + `scripts/handoff.mjs` → `.forja/HANDOFF.md` | `/handoff` (comando; hook `PreCompact` automático) |
| Tarea pequeña iterativa | `.claude/skills/sprint/` | `sprint` |
| Configurar tests CI/CD (Playwright) | `.claude/skills/add-e2e-tests/` | `add-e2e-tests` |
| Actualizar proyecto al último template Forja | `.claude/skills/update-forja/` | `update-forja` |

### Diseño — separación de poderes (D-036/D-037, guardrails, no receta)

| Poder | Quién | Regla |
|---|---|---|
| Entropía | `scripts/design-seed.sh` + `design-diversity.mjs` | la semilla sale del PRNG del SO, nunca "de la cabeza"; "sé único" no es mecanismo; diversidad se mide en pantallas (`COLLAPSE` = repetir) |
| Juicio | `el-critico-de-diseno` vía `/pulidor critique` | contexto fresco, solo screenshots, `Read+Bash`; stop en `QUALITY_GATES.md` §4 (cap 2, pairwise, score = telemetría) — nunca en su prompt |
| Gusto / SPEC | humano (R19) | artboards en `design-lab/` no son SPEC hasta `CHOSEN.md`; taste notes = SPEC; un solo writer en `decisions[]` |
| Gates | `el-evaluador` + `anti-slop-gate.sh` (12) | AST/tokens; penalty mecanizable del crítico ⇒ check; golden tras `/pulidor cut`, pairwise, no pixel-diff |
| Gasto / motion | AP9 + `references/DESIGN_ENRICH.md` | dry-run default; fal.ai/Higgsfield solo con frase de autorización y un job; keys en `.env.agents`; Lottie/Rive/CSS antes que video; a11y gana |

No confundir `/descubrir` (Fase 0, spec) con Discover visual (semillas). No renombrar Forja→Forge (D-032).

## Memory protocol

7 archivos en `.claude/memory/`. Append-only. Único writer = `el-evaluador`.

| Archivo | ID | Contenido |
|---------|----|-----------|
| `lessons.md` | L-NNN | Lecciones aprendidas (positivas) |
| `errors.md` | E-NNN | Errores y por qué ocurrieron |
| `decisions.md` | D-NNN | ADRs (architecture decisions) |
| `conventions.md` | — | Convenciones del proyecto |
| `glossary.md` | — | Términos del dominio |
| `references.md` | — | URLs externos validados (promovidos por evaluador) |
| `skills.md` | — | Registry: cada skill con `usar cuando` / `requiere` / `fallback` |

Cualquier agente lee con citation grammar `[memory:lessons#L-001]`.

## Research protocol

Todo claim externo requiere citación inline `[web:dominio.com](url-completa)` + sección `## Sources` al final del output. el-evaluador promueve URLs útiles a `references.md` con un resumen de 1 línea.

## Multi-Agent

Tres patrones, uno por caso de uso:

- **Coordinator** (sequential synthesis para sesiones largas): orchestrator delega secuencialmente, sintetiza entre fases.
- **Fork** (paralelo con worktrees): La Forja con N sandboxes, cherry-pick al final.
- **Swarm** (workers tool-filtered para one-shot): el-tajo / el-golpe.
- **Hermes** (D8.4, opcional): supervisor externo via `delegate_task` ACP. NO core.

Workers tienen tool-filter explícito (Researcher: Read+Grep+Glob+WebFetch · Implementer: Read+Write+Edit+Bash · Reviewer: Read+Grep + skill `el-evaluador` · Critic `el-critico-de-diseno`: Read+Bash, screenshot-only, contexto fresco — `.claude/references/SUBAGENT_TOOL_FILTERS.md` §2).

## Deeper references

- `CONSTRAINTS.md` — reglas duras + enforcement (hooks, gates)
- `BRAND.md` — narrativa, voice, tagline
- `.claude/references/BRAND_DNA_SCHEMA.md` — schema completo de brand contract
- `CHANGELOG.md` — historial de versiones
- `Makefile` — comandos primarios
