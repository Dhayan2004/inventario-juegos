---
name: migration-wizard
description: >
  Pipeline DETECT → ANALYZE → PLAN para migrar proyectos existentes a Forja Enterprise.
  Detecta tipo de origen del proyecto (Forge V2/V3, Forge V3.x con .claude/skills/la-herreria,
  Next.js custom, otro framework). Analiza estado actual vs Bootstrap Contract de Forja
  (los 5 gates de R11) + extras (AGENTS.md, CLAUDE.md Factory OS, hooks, memory store, RLS).
  Identifica gaps críticos que bloquean `/build` y reusable existente. Produce
  `MIGRATION-PLAN-{nombre}.md` con pasos priorizados, comandos Forja exactos a correr, y
  estimación de tiempo. NO ejecuta la migración — solo planifica. Shape: pipeline
  DETECT → ANALYZE → PLAN (D-023 — análogo a D-014 boundary case el-crisol). NO hay selector
  entre N approaches — el approach se determina por el estado detectado del proyecto
  (auto-detection). L-004 NO aplica directo. Citas: [memory:decisions#D-023] (pipeline
  shape, boundary case análogo a D-014), [memory:decisions#D-014] (el-crisol pipeline
  resume-aware sin selector — patrón heredado), [memory:CONSTRAINTS.md#R11] (Bootstrap
  Contract gates analizados).
tier: core
requires: directorio del proyecto a migrar accesible (path provisto por usuario o cwd).
fallback: Si no hay proyecto detectable (no `package.json`, no `.git`) → halt informativo: "No se detecta proyecto. Indicá el path del proyecto a migrar." Si ya está en Forja Enterprise (AGENTS.md existe + Bootstrap Contract cumplido) → halt: "Proyecto ya migrado a Forja Enterprise. NO necesita migration-wizard."
dependencies: []
---

# migration-wizard

> *"DETECT → ANALYZE → PLAN. No ejecutamos la migración — la planificamos. La ejecución es elección del usuario."*

Pipeline shape (D-023 — análogo a D-014 boundary case `el-crisol`). Detecta un proyecto existente, analiza su estado vs Bootstrap Contract de Forja, y produce un plan de migración paso a paso con comandos exactos a correr.

**Casos de uso:**
- Proyecto Next.js existente que quiere adoptar Forja.
- Proyecto Forge V2 / V3.x que migra a Forja Enterprise.
- Proyecto greenfield que ya tiene código y quiere agregar el harness Forja.

**No genera código.** No ejecuta migración. NO tiene `templates/` folder. R4 enforced — migration-wizard MISMA NO invoca skills. Solo dispatch a sub-agents para Detect/Analyze. La ejecución del plan generado es responsabilidad del usuario (corre los comandos indicados en el plan en orden).

## Shape (D-023)

A diferencia de wizards binary (D-019/D-020/D-021/D-022), migration-wizard es **pipeline shape sin selector entre N approaches**. El approach se determina por el estado detectado del proyecto (auto-detection en 5 tipos de origen):

- **Tipo A — Proyecto Forge V3.x** (`.claude/skills/la-herreria` existe + CLAUDE.md V3) → plan port skills + adoptar Bootstrap Contract.
- **Tipo B — Proyecto Forge V2** (CLAUDE.md sin estructura  + .claude/skills antiguo) → plan más complejo, re-estructurar.
- **Tipo C — Proyecto Next.js custom** (sin Forge/Forja previo) → plan instalar harness completo.
- **Tipo D — Proyecto otro framework** (Remix/SvelteKit/Astro/etc.) → plan re-write en Next.js o documentar incompatibilidad.
- **Tipo E — Greenfield con código** (sin package.json claro) → plan instalar Next.js + Forja desde cero.

L-004 NO aplica directo. D-023 documenta esto explícitamente como boundary case shape-par a D-014 (el-crisol pipeline resume-aware sin selector entre N providers).

## PREFLIGHT — halt-blocked en faltantes

```
1. ¿Hay un proyecto en el directorio actual o en el path provisto?
   - Detectar: package.json, .git, src/, README.md
   - Sí → continuar
   - No → halt: "No se detecta proyecto. Indicá el path con `migration-wizard /path/to/project`."

2. ¿Ya es Forja Enterprise?
   - Detectar: AGENTS.md existe + feature_list.json + .claude/memory/skills.md
   - Sí → halt: "Proyecto ya migrado a Forja Enterprise. NO necesita migration-wizard.
                 Si querés diagnosticar el entorno, corré /forge-check."
   - No → continuar
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario tiene proyecto Next.js custom y quiere adoptar Forja | Coordinator |
| Usuario dice "migrar a Forja", "adoptar Forja Enterprise", "Forge V3 a Forja" | Coordinator |
| Usuario greenfield ya con código quiere instalar el harness | Coordinator |
| Triage: usuario abrió un repo que NO es Forja → handoff sugiere migration-wizard | session_kickoff / la-herreria |

NO se invoca para: planificar features (la-herreria), ejecutar feature ya con stack Forja (la-forja / el-golpe), proyectos ya migrados (`/forge-check` para diagnóstico).

## Pipeline (3 fases sin selector)

> **Nota sobre paths.** Los paths `.claude/skills/...` y `CLAUDE.md` que aparecen en este documento (Fase 0 detección, Fase 1 análisis de reusable, plan generado) refieren al **proyecto fuente** que migration-wizard analiza (proyecto Forge V2/V3, Next.js custom, etc.) — NO son paths dentro de Forja Enterprise. Los paths Forja siempre llevan prefijo `` (`.claude/skills/`, `AGENTS.md`).

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Fase 0:        │    │  Fase 1:        │    │  Fase 2:        │
│  DETECT         │ ─→ │  ANALYZE        │ ─→ │  PLAN           │
│  (origen)       │    │  (gaps + reuse) │    │  (MIGRATION-PLAN)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Fase 0 — Detección de Origen

`prompts/detect-origin.md` clasifica el proyecto:

```
A. Forge V3.x (.claude/skills/la-herreria existe + CLAUDE.md tiene "Forge V3")
B. Forge V2 (CLAUDE.md sin estructura  + .claude/skills antiguo)
C. Next.js custom (src/ + package.json con "next" sin Forge/Forja)
D. Otro framework (package.json sin "next" — Remix, SvelteKit, Astro, etc.)
E. Greenfield con código (sin package.json claro pero con archivos)
```

Presentar: "Detecté: [Tipo A/B/C/D/E] — [descripción]".

### Fase 1 — Análisis de Gaps + Reusable

`prompts/analyze-gaps.md` cubre:

#### 1A. Bootstrap Contract Gates (R11 + extras Forja)

```
Bootstrap Contract analizado:
[ ] R11-1: make setup / package.json + deps presentes
[ ] R11-2: ≥1 test passing
[ ] R11-3: feature_list.json con ≥3 features y verification command
[ ] R11-4: .claude/memory/skills.md generado y validado
[ ] R11-5: brand/brand.json + voice.json existen (Brand DNA R10)

Extras Forja Enterprise:
[ ] AGENTS.md en raíz (routing host-agnostic)
[ ] CLAUDE.md (Factory OS — adapter para Claude Code)
[ ] Hooks instalados (R1 WIP=1 + R2 conventional commits + R5 memory writer)
[ ] Memory store (7 typed files: lessons, errors, decisions, conventions, glossary, references, skills)
[ ] Git inicializado + commits con conventional format (R2)
[ ] RLS L-001 en tablas con user_id (si hay BaaS)
[ ] R14 destructive tools sin execute() automático
```

#### 1B. Análisis de Contenido Reusable

```
¿Qué tiene el proyecto que Forja puede reusar?
- Skills existentes (.claude/skills/) → mapear los que matchean Forja registry
- BLUEPRINT o planning docs → si existen, usar como punto de partida (no rehacer)
- brand.json / design system → si existe en otro formato, migrar a R-005 schema
- Tests existentes → R11-2 coverage
- DB migrations → reusar si compatibles con RLS L-001
- API routes existentes → reusar si compatibles con Server Actions + Zod L-003
- AI templates / prompts → migrar a .claude/skills/ai/references/ si compatibles
```

### Fase 2 — Producir MIGRATION-PLAN

`prompts/build-plan.md` genera `MIGRATION-PLAN-{nombre}.md` con:

```markdown
# MIGRATION-PLAN-{nombre}

> Plan generado por migration-wizard · [fecha]
> **Origen detectado:** [Tipo A/B/C/D/E]
> **Estimación total:** ~Xh para Bootstrap Contract mínimo / ~Xh para enterprise completo

## Estado Actual vs Bootstrap Contract

[Tabla de 13 checks (R11-1..R11-5 + 8 extras Forja Enterprise) con ✅/⬜/⚠️]

## Gaps Críticos (bloquean /build)

| # | Gap | Acción Forja | Comando | Estimación |
|---|-----|--------------|---------|------------|
| 1 | brand.json missing (R10/R11-5) | /add-ui-kit Discovery FRESH | `/add-ui-kit` | ~30min |
| 2 | feature_list.json missing (R11-3) | Crear manualmente con backlog inicial | `cp example.feature_list.json feature_list.json` | ~15min |
| 3 | ... | ... | ... | ... |

## Reutilizable del Proyecto Actual

[Lista de lo que NO hay que rehcer:]
- ✅ src/ con feature-first existente — compatible con Forja
- ✅ Tests unitarios en Vitest — R11-2 cubierto
- ⚠️ Skills .claude/skills/ — 5 de 23 matchean Forja registry, los demás archivar o portar manualmente
- ⚠️ DB migrations — reusar pero verificar RLS L-001 antes de Wizard 1
- ❌ CLAUDE.md actual — incompatible con Factory OS Forja, reemplazar

## Pasos de Migración (ordenados por dependencia)

### Paso 1 — Adoptar AGENTS.md + CLAUDE.md Forja
- Acción: copiar `AGENTS.md` y `CLAUDE.md` (Factory OS) al proyecto.
- Comando: `cp -r path/to/forja-template/forja/AGENTS.md ./`
- Tiempo: ~10min.
- Por qué primero: routing es la fundación. Sin esto, ningún skill se invoca correctamente.

### Paso 2 — Crear feature_list.json
- Acción: generar feature_list inicial con backlog del PDR existente (si hay) o features del Blueprint.
- Comando: ver template en example.feature_list.json.
- Tiempo: ~30min (planificar features inicial).

### Paso 3 — Instalar hooks (R1/R2/R5/R11)
- Acción: `make install-hooks` (script en scripts/install-hooks.sh).
- Tiempo: ~5min.

### Paso 4 — Generar memory store (skills.md primero)
- Acción: copiar `.claude/memory/` template y poblar skills.md con los 23 skills disponibles.
- Tiempo: ~15min.

### Paso 5 — Brand DNA (R10 — bloqueante)
- Acción: `/add-ui-kit` Discovery FRESH para generar brand.json + voice.json + brand.css.
- Tiempo: ~30min.

### Paso 6 — Componentes core (impeccable BATCH)
- Acción: `/init-saas` cubre Brand + components + auth en una invocación (recomendado si Wizard 5 ya cubrió Brand DNA, init-saas EXISTING resume desde paso 2).
- Tiempo: ~25min para components + ~20min para auth (~45min total si init-saas resume desde paso 2).

### Paso 7 — Tests (R11-2)
- Acción: instalar Vitest si no existe. Crear ≥1 test passing.
- Comando: `cd forja && npm i -D vitest` + crear test sample.
- Tiempo: ~20min.

### Paso 8 — Verificar Bootstrap Contract
- Acción: `make preflight` debería pasar exit 0.
- Si falla: revisar mensaje exacto del gate y resolver.

### Paso 9 — Setup enterprise completo (opcional)
- Acción: `/enterprise-stack` para agregar pagos, emails, mobile, audit.
- Tiempo: ~3h (post-init-saas).

## Estimación Total

- **Bootstrap Contract mínimo (Pasos 1-8):** ~3h primera vez.
- **Enterprise completo (Pasos 1-9):** ~6h primera vez.

## Primer Comando a Correr (HOY)

```
cp -r path/to/forja-template/forja/. ./
cd forja && /add-ui-kit  # comenzar con Brand DNA si Wizard 5 es bloqueante
```

(Adaptar según gaps detectados.)

## Próximos Pasos Después del Plan

1. Correr el primer comando indicado.
2. Avanzar paso por paso siguiendo el plan.
3. Cuando termines: `make preflight` → si exit 0, `/build` para tu primera feature.
4. Si emerge un edge case durante la migración: documentar en errors.md (vía el-evaluador) para futuros migration-wizards.
```

NO ejecuta ningún paso. Solo produce el plan. Para ejecutar: usuario sigue el plan correndo los comandos indicados en orden.

## Reglas de ejecución

1. **NO escribir código de aplicación.** migration-wizard solo lee + analiza + escribe el `MIGRATION-PLAN-{nombre}.md`.
2. **R4 strict:** migration-wizard NO invoca skills (add-ui-kit, init-saas, etc.). Solo lista cuáles correr en el plan.
3. **R5 strict:** migration-wizard NO escribe a `.claude/memory/*`. Si emerge lesson/error durante el análisis (ej: encontrar un patrón común de migración Forge V3 → Forja), reportar al usuario para que el-evaluador lo registre post-migración.
4. **No asumir Forja Golden Path violado.** Si el proyecto usa otro stack (Remix, SvelteKit), documentar incompatibilidad clara en el plan + ofrecer migración a Next.js como pre-paso.
5. **Citation grammar R8:** si el plan menciona docs externos (ej: how to migrate from Forge V2), citar `[web:dominio.com](url)` o `[docs:libname]` con Sources.

## Output

`MIGRATION-PLAN-{nombre}.md` (en root del proyecto target o `.claude/PRPs/` según preferencia del usuario).

## Hard rules — R4/R5 enforcement

### R4 — Orchestrator stays thin

migration-wizard MISMA:
- Lee state files del proyecto (Read, Grep, Glob).
- Analiza gaps + reuse.
- Escribe el `MIGRATION-PLAN-{nombre}.md` (Write).
- NO ejecuta migración (no Edit a archivos del proyecto, excepto el plan).
- NO invoca skills.

Sub-agents (Detect, Analyze, Plan) reciben tool filter limitado (Read · Grep · Glob · Bash limited).

### R5 — Workers no escriben memory

Sub-agents NO tienen Write a `.claude/memory/*.md`. Si emerge insight durante el análisis, reportar a migration-wizard → propaga al handoff de el-evaluador post-pipeline (si aplica).

## Reglas operativas

1. **Detectar antes de analizar.** Sin saber el origen, el análisis es genérico. Diferentes orígenes requieren diferentes patterns.
2. **Plan exhaustivo.** Cada gap detectado debe tener: acción + comando + estimación.
3. **Comandos copy-paste-ready.** El usuario debe poder copiar y correr.
4. **Honest assessment.** Si el proyecto es muy distinto al Golden Path, decirlo claramente. NO forzar migración inviable.
5. **Reusable explícito.** Documentar lo que NO hay que rehcer — evita re-trabajo.
6. **Estimación realista.** Mejor sobrestimar que subestimar. Migración real lleva horas, no minutos.
7. **First command actionable.** El plan termina con UN comando concreto para empezar HOY.

## Refusals

- ❌ Ejecutar migración (solo producir plan).
- ❌ Invocar skills directamente (R4 — el plan los lista pero no los corre).
- ❌ Escribir a `.claude/memory/*` (R5).
- ❌ Generar templates folder.
- ❌ Producir plan sin Detect previo (cada origen tiene su pattern).
- ❌ Asumir compatibilidad con Forja sin verificar (R10 / R11 gates).
- ❌ Forzar migración a Forja si stack es fundamentalmente incompatible (Astro, Hugo, etc.) sin documentar el costo de re-escritura.

## Tool filter — migration-wizard MISMA

`Read · Grep · Glob · Write (solo MIGRATION-PLAN) · Bash (limited)`

NO Edit a archivos del proyecto · NO invocar skills (R4 — solo dispatch a sub-agents para Detect/Analyze).

Bash limitado a:
- File globs (state detection).
- `git status` / `git log` (informativo del proyecto a migrar).
- `cat package.json | head` (extraer metadata).
- NO npm install / NO file generation directo en el proyecto.

Sub-agents (Detect, Analyze, Plan):
- Detect: Read · Grep · Glob · Bash (limited).
- Analyze: Read · Grep · Glob · Bash (limited).
- Plan: Read · Write (solo el plan).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en SKILL.md + run-step.md |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md |
| Constraint | `[memory:CONSTRAINTS.md#R11]` | en SKILL.md (Bootstrap Contract gates analizados) |
| Decision | `[memory:decisions#D-023]` | en SKILL.md + analyze-gaps.md (pipeline shape) |
| Decision | `[memory:decisions#D-014]` | en SKILL.md + chain-rationale.md (boundary case análogo — pipeline sin selector) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `el-crisol` | shape-par boundary case (D-014). Mismo shape estructural: pipeline + resume-aware-detect, NO selector entre N providers. |
| `init-saas` | downstream sugerido en plan (Paso 6). El plan dice cuándo correrlo. |
| `add-monetization` | downstream sugerido en plan (opcional Paso 9). |
| `add-mobile-stack` | downstream sugerido en plan (opcional Paso 9). |
| `enterprise-stack` | downstream sugerido en plan (Paso 9 — wrapper enterprise completo). |
| `add-ui-kit` | downstream sugerido en plan (Paso 5 — Brand DNA bloqueante R10). |
| `el-evaluador` | post-migration sugerido. Recibe handoff con proposed_memory_entries (patrones de migración detectados). |
| `el-guardian` | post-migration sugerido. Audit pre-deploy una vez Bootstrap Contract cumplido. |
| `la-forja` | downstream final post-migración. Primera feature de aplicación post-Bootstrap Contract. |

## Output handoff format

```markdown
## migration-wizard handoff

**Origen detectado:** [Tipo A/B/C/D/E]
**Bootstrap Contract gates passing:** [N/13]
**Gaps críticos detectados:** [N]
**Reusable detectado:** [N items]
**MIGRATION-PLAN generado:** {path}
**Estimación total:** ~Xh para Bootstrap Contract / ~Xh para enterprise

**Primer comando a correr:**
{comando exacto}

**Próximos pasos sugeridos:**
- Correr el plan paso por paso.
- Al terminar, `make preflight` exit 0 → `/build` para primera feature.
- Documentar lessons learned post-migración (vía el-evaluador).

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: si emergió patrón de migración (ej: "Forge V3 a Forja Enterprise: 90% de skills mapean directo").
```

---

*"migration-wizard: el agente que mira un proyecto cualquiera y le dice 'esto es lo que falta y este es el orden exacto para hacerlo'. Pipeline sin selector. Honestidad brutal sobre gaps. Plan accionable."*
