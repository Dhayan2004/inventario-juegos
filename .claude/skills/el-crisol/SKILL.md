---
name: el-crisol
description: >
  Pipeline de validación estratégica que ejecuta 7 análisis en orden de
  dependencia (brujula → estrella → rivales → precio → roi → metas →
  lanzamiento) y produce un dashboard HTML ejecutivo consolidado con
  métricas, gráficas (Chart.js) y veredicto Go/Caution/No-Go. Se activa
  DESPUÉS del Blueprint (entre la-herreria y la-forja). Detecta strategy
  docs existentes y reutiliza los que ya están (resume-aware state
  detection). Cada paso delega vía sub-agent a un sub-prompt — el-crisol
  MISMA NO invoca skills directo (R4 enforced). 4 modos de invocación:
  "go" (ejecutar todo lo pendiente), "saltar N" (saltar un paso),
  "desde N" (empezar desde un paso concreto), "solo dashboard" (generar
  consolidado con docs existentes). Output final: STRATEGY-REPORT-{nombre}.md
  + strategy-dashboard-{nombre}.html standalone (Chart.js CDN + Liquid
  Glass + Bento Grid + dark mode + print-friendly). Build Confidence Score
  con rúbrica 7 dimensiones ponderadas (cada score cita el dato del doc
  fuente — no se inventan). Veredicto: Go (8-10) → handoff a la-forja,
  Caution (5-7) → re-ajustar áreas con gaps, No-Go (1-4) → replantear
  antes de invertir en construcción. Shape: sequential-pipeline con
  resume-aware state detection — NO selector entre N providers. D-014
  documenta por qué L-004 binary/trinary NO aplica directo.
tier: core
requires: Blueprint aprobado en `.claude/PRPs/BLUEPRINT-*.md` (PREFLIGHT halt-line si falta). feature_list.json con feature en `active` (R1) opcional pero recomendado para tracking. Acceso lectura a la raíz del proyecto + `.claude/reports/` para detección de strategy docs existentes. Para Fase 2 dashboard — capacidad de generar HTML standalone (no requiere servidor).
fallback: Sin Blueprint → halt + handoff `la-herreria`. Sin Blueprint pero usuario pide "solo dashboard" con 0 docs estratégicos existentes → halt informativo (sin docs, dashboard sería vacío). Si Perplexity MCP no está disponible → seguir sin research enrichment (no halt — solo informa al usuario que la calidad puede ser menor). Si dashboard HTML falla la generación → fallback a STRATEGY-REPORT-{nombre}.md sin HTML (markdown legible cubre el caso).
dependencies: []
---

# el-crisol

> *"Validá la estrategia antes de invertir semanas construyendo. Dashboard ejecutivo con datos sólidos para decisión Go / Caution / No-Go."*

Pipeline de validación estratégica. Implementa el bloque entre `la-herreria` (Blueprint planning) y `la-forja` (orquestación de ejecución). 7 análisis en orden de dependencia, cada uno delegado a sub-agent vía sub-prompt. Resume-aware: si docs ya existen, los reutiliza. Output ejecutivo: dashboard HTML standalone + STRATEGY-REPORT consolidado + veredicto Go/Caution/No-Go.

## PREFLIGHT — halt-line en faltantes críticos

```
1. ¿Existe Blueprint aprobado en .claude/PRPs/BLUEPRINT-*.md?
   - Sí → continuar
   - No → halt: "Sin Blueprint aprobado. Corré /la-herreria primero. el-crisol valida estrategia post-Blueprint, no genera Blueprint desde cero."

2. ¿Hay active feature en feature_list.json (R1)?
   - Sí → asociar pipeline al active feature (commits con scope F?-S?)
   - No → continuar pero advertir: "Sin active feature. Outputs irán a `.claude/reports/` sin asociación de scope. Considerá pickear del backlog."

3. ¿La raíz del proyecto + `.claude/reports/` son legibles?
   - Sí → Fase 0 detección procede
   - No → halt: "No puedo leer raíz proyecto / `.claude/reports/`. Verificá permisos."

4. ¿Determinable el {nombre} del proyecto?
   - Si BLUEPRINT-{nombre}.md existe → extraer {nombre}
   - Si docs estratégicos existen con {nombre} común → extraer {nombre}
   - Si nada → preguntar al usuario UNA pregunta antes de proceder
```

PREFLIGHT halt-blocked SOLO en faltantes mandatorios (Blueprint, lectura raíz, nombre indeterminable). El resto se reporta como warning + degradación graceful.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Blueprint aprobado y usuario pide validación estratégica | Coordinator (Forja root) |
| Usuario dice "crisol", "validación estratégica", "vale la pena construir", "pitch deck", "dashboard estratégico" | Coordinator |
| Post-Blueprint cuando el proyecto justifica inversión significativa (>2 semanas build) | Coordinator |
| Usuario quiere consolidar 7 análisis ya hechos en un dashboard | Coordinator (modo "solo dashboard") |

NO se invoca para: planificar features (eso es la-herreria), ejecutar build paralelo (eso es la-forja), task atómico (eso es el-tajo / el-golpe), context loading (eso es primer), task iterativa con feedback (eso es sprint), audit pre-deploy (eso es el-guardian).

## Pipeline de dependencias (los 7 análisis)

```
/brujula ──→ /estrella ──→ /rivales ──→ /precio ──→ /roi ──→ /metas ──→ /lanzamiento
   │              │             │            │          │          │            │
   ▼              ▼             ▼            ▼          ▼          ▼            ▼
 Vision +     North Star    Battlecards  Pricing    Unit Econ    OKRs       Go-to-
 Strategy     Metric        + Landscape  Strategy   + ROI       + Roadmap   Market
```

| # | Sub-prompt invocado | Produce | Necesita antes |
|---|---------------------|---------|----------------|
| 1 | `prompts/run-step.md` con `step=brujula` | `STRATEGY-CANVAS-{nombre}.md` | Solo Blueprint/BMC/PDR |
| 2 | `prompts/run-step.md` con `step=estrella` | `NORTH-STAR-{nombre}.md` | Brujula |
| 3 | `prompts/run-step.md` con `step=rivales` | `COMPETITIVE-ANALYSIS-{nombre}.md` | Brujula |
| 4 | `prompts/run-step.md` con `step=precio` | `PRICING-STRATEGY-{nombre}.md` | Rivales + Estrella |
| 5 | `prompts/run-step.md` con `step=roi` | `saas-analysis-{nombre}.md` + `.html` | Precio + Estrella |
| 6 | `prompts/run-step.md` con `step=metas` | `OKRS-{nombre}.md` | ROI + Estrella |
| 7 | `prompts/run-step.md` con `step=lanzamiento` | `GTM-STRATEGY-{nombre}.md` | Todo lo anterior |

Los sub-prompts canónicos para cada `step` (brujula, estrella, rivales, etc.) son responsabilidad de Forja Phase 5+ (orchestrator wizard). En la versión actual, `prompts/run-step.md` define el protocolo genérico — el sub-agent dispatched lee BLUEPRINT + docs previos + ejecuta análisis usando templates de saas-factory upstream.

## Fase 0 — Detección de estado (resume-aware)

Detalle completo en [`prompts/detect-state.md`](prompts/detect-state.md). Resumen:

1. Scan de raíz proyecto + `.claude/reports/` para los 7 patterns:
   - `STRATEGY-CANVAS-*.md`, `NORTH-STAR-*.md`, `COMPETITIVE-ANALYSIS-*.md`, `PRICING-STRATEGY-*.md`, `saas-analysis-*.md`, `OKRS-*.md`, `GTM-STRATEGY-*.md`
2. Determinar `{nombre}` del proyecto (BLUEPRINT-{nombre} → extracción; o más común entre docs; o pregunta al usuario)
3. Presentar tabla de estado con ✅ (existe) / ⬜ (pendiente) por cada uno de los 7 + dashboard final
4. Preguntar Perplexity MCP availability (opt-in research enrichment)
5. Confirmar inicio con 4 modos: `go` / `saltar N` / `desde N` / `solo dashboard`

## Fase 1 — Ejecución secuencial

Detalle completo en [`prompts/run-step.md`](prompts/run-step.md). Para cada paso pendiente, en orden de dependencia:

1. **Anunciar paso:** N/7 + nombre + dependencias.
2. **Dispatch sub-agent:** la-forja-style — un sub-agent por paso con tool filter apropiado. Sub-agent invoca el template del análisis correspondiente (saas-factory upstream).
3. **Confirmar output:** dato clave extraído + transición.
4. **Reglas:** propagación de contexto cross-pasos, no contradicción, no repetir preguntas, docs existentes son contexto.

R4 enforced: el-crisol MISMA NO invoca templates directo, solo dispatcha al sub-agent que ejecuta. R5 enforced: sub-agents no escriben a memory, solo a outputs estratégicos (STRATEGY-CANVAS, etc.).

## Fase 2 — Consolidación + Dashboard

Cuando los 7 pasos están completos (o los que el usuario decidió ejecutar):

### Paso 1: Resumen ejecutivo

Sub-agent invoca template de [`references/strategy-summary.md`](references/strategy-summary.md). Lee los 7 docs estratégicos y genera:

**Output:** `.claude/reports/STRATEGY-REPORT-{nombre}.md`

### Paso 2: Build Confidence Score

Sub-agent aplica rúbrica de [`references/go-no-go-scoring.md`](references/go-no-go-scoring.md):

- 7 dimensiones (Market Fit 20%, Metric Clarity 10%, Competitive Position 15%, Monetization 15%, Financial Viability 20%, Execution Plan 10%, GTM Feasibility 10%).
- Cada score 1-10 cita el dato del doc fuente — **NO scores inventados**.
- Si paso saltado → dimensión `N/A`, peso redistribuido proporcionalmente.
- Score final = suma ponderada → veredicto Go (8-10) / Caution (5-7) / No-Go (1-4).

### Paso 3: Dashboard HTML

Detalle completo en [`prompts/build-dashboard.md`](prompts/build-dashboard.md). Sub-agent genera:

**Output:** `.claude/reports/strategy-dashboard-{nombre}.html`

Requisitos críticos:

- **Standalone:** abre en cualquier browser sin servidor.
- **Chart.js v4+ vía CDN:** `https://cdn.jsdelivr.net/npm/chart.js`.
- **Layout:** CSS Grid Bento (4 cols desktop, 2 tablet, 1 mobile).
- **Estilo:** Liquid Glass (backdrop-blur, semi-transparencia, bordes sutiles).
- **Theme:** dark mode default.
- **Print-friendly:** `@media print` para exportar a PDF.
- **Datos:** embebidos como `const DATA = { ... }` en `<script>` block.
- **9 secciones canónicas:** Hero, Strategy Canvas, North Star Metric, Competitive Landscape, Pricing & Economics, Financial Projections, OKRs & Roadmap, Go-to-Market, Risks & Verdict.

## Fase 3 — Handoff (veredicto)

```
🔥 El Crisol completado — {nombre}

Build Confidence Score: {X.X}/10 — [Go ✅ / Caution ⚠️ / No-Go ❌]

Documentos generados:
  📊 .claude/reports/strategy-dashboard-{nombre}.html  (dashboard interactivo)
  📄 .claude/reports/STRATEGY-REPORT-{nombre}.md       (resumen ejecutivo)
  + 7 docs individuales (los que se generaron)

→ Abre el dashboard:
  open .claude/reports/strategy-dashboard-{nombre}.html
```

### Según veredicto

**Go (8-10):**
```
Estrategia sólida. Siguiente paso:
→ /la-forja para construir (Fork default, o Coordinator/Swarm según Blueprint shape)
  o → el-yunque manual si preferís control humano fase por fase
```

**Caution (5-7):**
```
Hay áreas que necesitan atención antes de invertir en construcción:
  - {Área 1}: {qué mejorar — cita doc}
  - {Área 2}: {qué mejorar — cita doc}

Podés ajustar esas áreas y re-ejecutar el-crisol,
o proceder con la-forja aceptando los riesgos documentados.
```

**No-Go (1-4):**
```
La estrategia tiene gaps fundamentales:
  - {Gap 1}: {por qué es crítico — cita doc}
  - {Gap 2}: {por qué es crítico — cita doc}

Recomendación: replantear antes de construir.
→ Revisá los documentos marcados y ajustá la estrategia.
→ Re-ejecutá el-crisol para re-evaluar.
```

## Hard rules — R4/R5 verbatim enforcement

### R4 — Orchestrator stays thin

> "El orchestrator (Coordinator, La Forja root, el-tajo, el-golpe) NUNCA invoca un skill directamente. Solo dispatch a sub-agentes." [memory:CONSTRAINTS.md#R4]

el-crisol MISMA es **thin orchestrator**:
- Lee (Read, Grep, Glob) Blueprint + docs estratégicos existentes + outputs de sub-agents.
- Bash limitado a `git status` (informativo) y file globs (detección).
- Dispatch a sub-agents para cada paso del pipeline (sub-agents invocan templates).
- NO Edit/Write a archivos de aplicación (solo a outputs estratégicos vía sub-agents).
- NO invoca templates directo.

### R5 — Memory writers

> "Solo el skill `el-evaluador` puede escribir a archivos en `.claude/memory/*.md`." [memory:CONSTRAINTS.md#R5]

Sub-agents en pipeline el-crisol NO tienen Write a `.claude/memory/*.md`. el-crisol MISMA tampoco. Outputs van a `.claude/reports/` (state, no memory). Si emerge lesson/error/decision durante orchestration, se documenta en handoff a el-evaluador post-pipeline.

### R6 — Skill dispatch validates registry (informativo)

el-crisol MISMA NO invoca otros skills (Phase 5+ orchestrator wizard scope). En la versión actual, sub-agents ejecutan templates directamente. Si en futuro la-forja invoca el-crisol como sub-skill, R6 valida en la-forja level (registry check pre-dispatch).

## Reglas operativas

1. **el-crisol MISMA es thin (R4).** NUNCA invoca templates directo. Solo dispatch a sub-agents que invocan templates de saas-factory upstream.

2. **Resume-aware (Fase 0 mandatory).** Antes de ejecutar cualquier paso, scan de raíz + `.claude/reports/` y detección de docs existentes. Si STRATEGY-CANVAS-{nombre}.md existe → skip Brujula, todos los pasos posteriores la usan como contexto.

3. **No re-preguntar (Reglas de ejecución).** Si Brujula definió target customer, Rivales NO vuelve a preguntar. Sub-agent de cada paso recibe los outputs de pasos anteriores como input.

4. **No contradecir (Reglas de ejecución).** Si Precio definió tiers, ROI los usa tal cual. Si emerge inconsistencia, halt + reportar al humano para resolución manual.

5. **Scores con datos (R8 análogo).** Build Confidence Score: cada dimensión cita el dato concreto del doc fuente. Si dato falta o es ambiguo → score N/A o nota explícita "no validable, requiere {acción}". NUNCA inventar scores.

6. **Dashboard estándar (Bento + Liquid Glass + Chart.js).** El layout, paleta y stack del dashboard son contrato no-negociable. Si ajustes son necesarios para target audience específico, documentar override en commit message.

7. **Handoff a la-forja según veredicto.** Solo en Go el handoff es directo. En Caution/No-Go el siguiente paso es revisar/replantear, no construir. el-crisol NO fuerza handoff a la-forja si el score lo desaconseja.

8. **NO bypass de Fase 2 consolidación.** Aún si el usuario corrió 1 solo de los 7 pasos, el-crisol genera el dashboard con secciones marcadas "Análisis no realizado — ejecutar /{step} para completar". Graceful degradation, no halt.

9. **L-004 NO aplica directo.** Documentado en [`references/strategy-pipeline-rationale.md`](references/strategy-pipeline-rationale.md) y [memory:decisions#D-014]. el-crisol shape es sequential-pipeline-con-resume-detection, NO selector entre N providers. Cita informativa al humano si pregunta por qué no hay default+override en este skill.

10. **find-docs como sub-tool ad-hoc.** Si un sub-agent durante un paso necesita docs frescas (ej: Chart.js API en Fase 2 dashboard), invoca find-docs ad-hoc. el-crisol MISMA no requiere find-docs upfront. Cita: `[docs:chart-js]` cuando aplica.

## Cuándo NO usar el-crisol

- Proyectos personales/experimentales donde el usuario solo quiere construir.
- Features individuales (esos van directo a la-forja con el-tajo o el-golpe).
- Si el Blueprint es trivial y el ROI estratégico no justifica los 7 análisis (~3-4 horas humanas + research si Perplexity).
- Si el usuario ya tiene Strategy Report consolidado en otro formato y solo quiere ejecutar — handoff directo a la-forja sin pasar por el-crisol.

## Refusals (lo que NUNCA hace)

- ❌ Ejecutar pasos sin Blueprint (PREFLIGHT halt — sin contexto base, los análisis son inventados).
- ❌ Invocar templates directamente desde el-crisol MISMA (R4 violation).
- ❌ Escribir a `.claude/memory/*.md` (R5 — solo el-evaluador post-orchestration).
- ❌ Inventar scores en Build Confidence sin citar doc fuente (R8 análogo — datos vacíos NO compensan).
- ❌ Forzar handoff a la-forja si veredicto es No-Go (riesgo: invertir semanas en proyecto con gaps fundamentales).
- ❌ Saltar Fase 0 detección (sin scan, no se sabe qué reutilizar — riesgo de re-trabajo).
- ❌ Generar dashboard con datos de un proyecto y filename de otro (caso de drift cross-proyecto — halt + reportar).
- ❌ Modificar Blueprint upstream (eso es la-herreria scope).
- ❌ Self-eval del veredicto (AP3 — el-evaluador independent post-pipeline si aplica).

## Tool filter — el-crisol MISMA

`Read · Grep · Glob · Bash (limited)`

NO Edit · NO Write directo · NO Skill (no invoca otros skills).

Bash limitado a:
- `git status` / `git log` (informativo, read-only state).
- File system globs (detección de docs estratégicos).
- `open <path>` opcional para abrir dashboard post-generación (no requerido).

Sub-agents reciben tool filter apropiado al paso (Researcher para análisis, Implementer para generar docs, Reviewer para validar consistency cross-pasos). Heredan el modelo de Swarm de la-forja [memory:decisions#D-013].

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en cada `prompts/run-step.md` y SKILL.md (R4 enforcement) |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md + run-step.md (workers no escriben memory) |
| Constraint | `[memory:CONSTRAINTS.md#R8]` | en go-no-go-scoring.md (citation grammar para datos) |
| Lesson | `[memory:lessons#L-004]` | informativa en strategy-pipeline-rationale.md (NO aplica directo, shape distinto) |
| Decision | `[memory:decisions#D-014]` | en SKILL.md + strategy-pipeline-rationale.md (pipeline shape vs selector shape) |
| External docs | `[docs:chart-js]` | en build-dashboard.md cuando sub-agent invoca find-docs para Chart.js API |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `la-herreria` | upstream — el-crisol consume Blueprint generado por la-herreria. Sin Blueprint → halt + handoff. |
| `la-forja` | downstream condicional — solo si veredicto Go, handoff directo. Si Caution/No-Go, no force handoff. |
| `el-yunque` (prompt manual, no skill) | downstream alternativo — `.claude/prompts/el-yunque.md` (NO está en el skills registry). Si usuario prefiere control manual fase por fase post-Go, ejecuta el prompt el-yunque en lugar de la-forja. |
| `el-evaluador` | downstream opcional — post-pipeline el-crisol puede hacer handoff a el-evaluador para R7 three-layer si los outputs son consumidos por orquestación posterior. |
| `find-docs` | sub-tool ad-hoc — sub-agents en Fase 2 invocan find-docs si necesitan Chart.js / browser API freshness. el-crisol MISMA no requiere upfront. |
| `primer` | upstream — si el-crisol arranca en proyecto target sin contexto, primer carga primero. |
| `sprint` | NO direct — sprint es loop iterativo con feedback humano sobre cambios pequeños; el-crisol es pipeline ejecutivo de validación estratégica. Casos distintos. |
| `el-tajo` / `el-golpe` | NO direct — son one-shot atómico/mediano; el-crisol es pipeline de 7 pasos con consolidación. |
| `el-guardian` | NO direct — el-crisol no toca código de aplicación ni secrets. Si dashboard incluye datos sensibles, el-guardian audita en la-forja deploy phase si aplica. |

## Output handoff (canónico)

```markdown
## el-crisol handoff

**Active feature:** {F?-S?}
**Blueprint:** .claude/PRPs/BLUEPRINT-{nombre}.md
**Pipeline ejecutado:** {N}/7 pasos (saltados: {list o ninguno})

**Build Confidence Score:** {X.X}/10 — {Go ✅ / Caution ⚠️ / No-Go ❌}

**Documentos generados:**
- .claude/reports/STRATEGY-REPORT-{nombre}.md
- .claude/reports/strategy-dashboard-{nombre}.html
- {7 docs individuales según pasos ejecutados}

**Veredicto rationale:**
- Market Fit: {X}/10 — {dato clave del STRATEGY-CANVAS}
- Metric Clarity: {X}/10 — {dato clave del NORTH-STAR}
- {... 5 dimensiones más}

**Handoff next (según veredicto):**
- Go → /la-forja (default Fork) o el-yunque manual
- Caution → revisar áreas {list} y re-ejecutar el-crisol
- No-Go → replantear estrategia, NO build

**Memory entries propuestas (opcional):**
- proposed_lesson: {si emerge patrón cross-proyecto}
```

---

*"Antes de la-forja, el crisol. Antes de meter manos múltiples, validá que vale la pena meter una sola."*
