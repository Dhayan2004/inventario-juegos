---
name: init-saas
description: >
  Wizard pipeline que compone la cadena canónica de bootstrapping SaaS:
  add-ui-kit → impeccable (Mode C BATCH) → add-login. Resume-aware con
  detección de estado al estilo el-crisol — escanea brand.json + voice.json
  + brand.css (output add-ui-kit), component_rules.json + core component
  set (output impeccable), src/features/auth/ (output add-login) y skipea
  los pasos ya completados. Resuelve E-006 (UX gap del usuario que
  invocaba add-login y descubría 3 PREFLIGHT halts en cadena). Binary
  shape (D-019): FRESH (default — chain completa con todos los pasos
  pendientes) vs EXISTING (resume-aware — saltea pasos completados,
  sigue desde donde quedó). NO PAUSE genuino: state detection determina
  qué pasos correr; no hay degenerate case con upstream user action
  específica del selector. R4 enforced — init-saas MISMA NO invoca
  skills, dispatch a sub-agents que invocan. Cada paso pasa contexto
  acumulado al siguiente (brand.json path → impeccable, component_rules
  → add-login). Si paso falla → halt con handoff explícito al skill;
  cuando se resuelve, init-saas resume desde paso N. NO escribe código
  — solo coordina. Citas: [memory:errors#E-006] (resuelve), [memory:
  decisions#D-019] (binary shape), [memory:CONSTRAINTS.md#R4] (orchestrator
  thin), [memory:CONSTRAINTS.md#R10] (Brand DNA gate enforced via add-ui-kit).
tier: core
requires: directorio de proyecto Next.js con `src/` o `pages/` accesible (PREFLIGHT halt si ninguno). AGENTS.md en raíz (proyecto inicializado con Forja). Para add-login (paso 3) — `baas` decision documentada en feature_list.json o Tech Spec, o fallback Supabase default. Active feature en feature_list.json (R1) recomendado pero soft warning si falta.
fallback: Sin AGENTS.md → halt: "proyecto no inicializado con Forja. Corré /forge-init primero." Sin src/ ni pages/ → halt: "no parece proyecto Next.js." Si paso N falla durante ejecución → halt + handoff explícito al skill que falló (ej: "add-ui-kit halt en Discovery FRESH — el usuario debe completar interview antes de continuar"). Cuando paso resuelve, re-invocar init-saas → resume-aware detecta progreso parcial y arranca desde paso N+1.
dependencies: [find-docs, add-ui-kit, impeccable, add-login, baas]
---

# init-saas

> *"Tres skills. Una invocación. La cadena que cierra el chicken-egg de E-006."*

Wizard pipeline. Compone la cadena canónica de bootstrapping SaaS Forja: **add-ui-kit → impeccable → add-login**. Shape estructural heredado de [`el-crisol`](../el-crisol/SKILL.md) — sequential pipeline + resume-aware state detection. Binary mode selector (D-019): FRESH default + EXISTING resume-aware sin PAUSE.

**Resuelve E-006:** el usuario que quería "auth completa" tenía que descubrir solo la dependency chain (add-login → impeccable → add-ui-kit) y correr 3 invocaciones manuales con halt-handoff messages. init-saas compone la cadena automáticamente con detección de estado.

**No genera código.** No tiene `templates/` folder. R4 enforced — init-saas MISMA NO invoca add-ui-kit / impeccable / add-login directamente. Solo dispatch a sub-agents que invocan.

## PREFLIGHT — halt-blocked en faltantes mandatorios

```
1. ¿AGENTS.md en raíz del proyecto?
   - Sí → continuar (proyecto inicializado con Forja)
   - No → halt: "proyecto no inicializado con Forja. Corré /forge-init."

2. ¿src/ o pages/ accesible?
   - Sí → continuar (proyecto Next.js)
   - No → halt: "no parece proyecto Next.js — init-saas requiere Next.js
            con App Router (src/) o Pages Router (pages/)."

3. ¿feature_list.json con active feature (R1)?
   - Sí → asociar wizard al active feature (commits con scope)
   - No → soft warning: "Sin active feature. Considerá pickear del backlog
          o arrancar feature nueva via la-herreria."
```

PREFLIGHT halt-blocked SOLO en gates 1+2 (estructura mandatoria). Gate 3 es soft warning — no bloquea ejecución.

**Respeto integral de PREFLIGHT de sub-skills (E-009 causa 2):** init-saas NUNCA bypassa los gates de sub-skills. Si add-ui-kit dispara gates 5-8 (contenido en globals.css / tailwind.config.ts / layout.tsx, o typecheck baseline roto) → init-saas cede control al sub-skill y reporta al usuario. NO fuerza FRESH ni ignora el halt para "completar la cadena". La cadena se completa solo si cada sub-skill da PASS. Cita [memory:errors#E-009].

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario greenfield Forja quiere auth completa lista para iterar | Coordinator |
| Usuario dice "init saas", "setup completo", "dame brand + auth", "bootstrap SaaS" | Coordinator |
| Usuario corre add-login directo y recibe halt → handoff sugiere init-saas | add-login |
| Triage de la-herreria post-Blueprint detecta SaaS feature → sugiere init-saas | la-herreria |

NO se invoca para: planificar features (la-herreria), ejecutar feature ya con stack base (la-forja / el-golpe), agregar monetización (add-monetization wizard), agregar mobile (add-mobile directo).

## Mode selector (binary D-019)

| Modo | Trigger | Acción |
|------|---------|--------|
| **FRESH** (default) | Sin brand.json + sin core components + sin auth | Chain completa: add-ui-kit → impeccable → add-login (3 pasos) |
| **EXISTING** (resume-aware) | Algún output ya existe (state detection) | Skipea pasos completados, sigue desde donde quedó |

`prompts/detect-state.md` implementa la detección. **Decision tree:**

```
¿brand.json + voice.json + brand.css existen?
├── Sí → skip add-ui-kit (paso 1 ✅)
└── No → ejecutar add-ui-kit (paso 1 ⬜)

¿brand/component_rules.json + core components existen?
├── Sí → skip impeccable (paso 2 ✅)
└── No → ejecutar impeccable Mode C (paso 2 ⬜)

¿src/features/auth/ + middleware existen?
├── Sí → skip add-login (paso 3 ✅)
└── No → ejecutar add-login (paso 3 ⬜)
```

**L-004 test:** ¿degenerate case requiere upstream user action específica del selector?

| Caso | ¿Upstream user action requerida del selector? | Resultado |
|------|----------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí (correr forge-init / migrar a Next) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| FRESH path con sub-skill que tiene PAUSE interno | NO — PAUSE-interno-delegado se maneja en el sub-skill, no en wizard | NO PAUSE wizard |
| EXISTING parcial (1 de 3 pasos completados) | NO — resume-aware procede desde paso 2 | NO PAUSE |

**Conclusión D-019:** **BINARY** confirmed. FRESH default + EXISTING override (resume-aware), NO PAUSE genuino.

## Pipeline canónico (los 3 pasos)

```
add-ui-kit ──→ impeccable (Mode C BATCH) ──→ add-login
   │                  │                            │
   ▼                  ▼                            ▼
Brand DNA       Core component set          Auth completa
brand.json      Button/Input/Card/Modal     middleware + 4 pages
voice.json      Form/Tabs/Sidebar/Topbar    + actions + RLS L-001
brand.css       Breadcrumb/Select/Textarea
                Brand Score ≥75
```

| # | Sub-prompt | Skill invocado vía sub-agent | Output | Necesita antes |
|---|------------|------------------------------|--------|----------------|
| 1 | `prompts/run-step.md` con `step=ui-kit` | `add-ui-kit` (Discovery FRESH) | brand.json + voice.json + brand.css + showcase | AGENTS.md + Next.js |
| 2 | `prompts/run-step.md` con `step=components` | `impeccable` (Mode C BATCH) | core 11 components consuming brand.json | brand.json + voice.json + brand.css |
| 3 | `prompts/run-step.md` con `step=auth` | `add-login` (Mode A Supabase default o B Insforge override) | lib/supabase + middleware + 4 pages + 0001_profiles.sql | brand.json + impeccable components |

## Fase 0 — Detección de estado (resume-aware)

Detalle completo en [`prompts/detect-state.md`](prompts/detect-state.md). Resumen:

1. Scan paths canónicos:
   - `brand/brand.json`, `voice.json`, `brand.css`
   - `brand/component_rules.json` (output impeccable BATCH)
   - `src/shared/components/ui/` (los 11 components canónicos: Button, Input, Card, Modal, Form, Tabs, Sidebar, Topbar, Breadcrumb, Select, Textarea)
   - `src/features/auth/` o equivalente (output add-login)
   - `src/middleware.ts` o `src/middleware.js`
2. Determinar paso actual: el primero pendiente en orden 1→3.
3. Presentar tabla de estado.
4. Confirmar inicio: `go` (proceder desde paso pendiente) / `desde N` (forzar arranque desde N) / `solo [paso]` (correr 1 paso aislado).

## Fase 1 — Ejecución secuencial

Detalle en [`prompts/run-step.md`](prompts/run-step.md). Para cada paso pendiente, en orden:

1. **Anunciar paso:** N/3 + nombre + dependencias declaradas.
2. **Dispatch sub-agent:**
   - Sub-agent invoca el skill correspondiente (R4 — init-saas NO invoca directo).
   - Contexto pasado: `project_path`, `brand_json_path` (si existe), `baas_decision` (si documentada).
3. **Confirmar output:**
   ```
   ✅ Paso N/3 completado → [archivo/folder generado]
   Dato clave: [ej: "Archetype: Sage + Creator, Posture: density=4 expression=2"]
   Siguiente: [paso N+1] — ¿continuamos? (sí / pause / abort)
   ```
4. **Si paso falla:**
   ```
   ❌ Paso N falló durante ejecución de [skill].
   Razón: [mensaje del skill]
   Próximo paso: resolvé [skill] manualmente. Cuando termines,
   re-invocá init-saas — resume-aware detecta progreso y arranca
   desde paso N o N+1 según corresponda.
   ```

## Reglas de ejecución cross-pasos

1. **NO repetir entrevistas.** Si add-ui-kit ya corrió Discovery FRESH y produjo brand.json con `archetype` y `posture`, impeccable NO vuelve a preguntar — lee del brand.json directamente.
2. **Propagar contexto.** Cada paso recibe `brand_json_path` (si existe), `voice_json_path` (si existe), `component_rules_path` (si existe), y outputs de pasos previos.
3. **NO contradecir.** Si add-ui-kit definió `tokens.colors.primary = #0066ff`, impeccable NO override. add-login NO override. Si emerge inconsistencia, halt + reportar.
4. **R4 strict:** init-saas MISMA NO escribe código. Sub-agents son los que invocan add-ui-kit / impeccable / add-login (los cuales internamente generan código en el target project).
5. **R5 strict:** init-saas NO escribe a `.claude/memory/*`. Si emerge lesson/error durante ejecución, sub-agent reporta a init-saas → init-saas propaga al handoff de el-evaluador post-pipeline.

## Output handoff (final)

```markdown
## ✅ init-saas completado

**Pipeline ejecutado:** {N}/3 pasos
- ✅ Paso 1 (add-ui-kit): brand.json + voice.json + brand.css + showcase
- ✅ Paso 2 (impeccable): 11 core components con Brand Score ≥75
- ✅ Paso 3 (add-login): middleware + 4 auth pages + Supabase/Insforge

**Tenés:** Brand DNA + core component set + auth completa.

**Próximos pasos opcionales:**
- → `/add-monetization` para integrar pagos + emails + audit web-quality
- → `/add-mobile` para PWA shell + push notifications
- → `/la-forja` o `/build` para tu primera feature de aplicación

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: si emerge patrón cross-proyecto
```

Si pipeline parcial (algún paso falló o user paused):

```markdown
## init-saas — Pipeline parcial

**Estado:** {N}/3 pasos completados
- ✅ Paso 1: completado
- ⚠️ Paso 2: failed durante ejecución de impeccable
- ⬜ Paso 3: pendiente

**Razón del halt:** {mensaje}

**Próximo paso:** resolvé impeccable. Cuando termines, re-invocá init-saas
y resume-aware detecta progreso desde paso 2 (o paso 3 si paso 2 ya está
completo).
```

## Hard rules — R4/R5/R10 enforcement

### R4 — Orchestrator stays thin (CRÍTICO para wizards)

> [memory:CONSTRAINTS.md#R4]: orchestrator NUNCA invoca skill directamente. Solo dispatch a sub-agentes.

init-saas MISMA:
- Lee (Read, Grep, Glob) state files (brand.json, src/features/auth/, etc.)
- Detecta state Fase 0 + presenta tabla
- Dispatch a sub-agents Fase 1
- Sintetiza outputs entre pasos (texto, no código)
- NO Edit/Write a código de aplicación
- NO invoca add-ui-kit/impeccable/add-login directo

Sub-agents reciben tool filter completo (Read+Edit+Write+Bash) **dentro del proyecto target** — pueden ejecutar el skill que les corresponda. init-saas coordina, sub-agents construyen.

### R5 — Workers no escriben memory

Sub-agents en pipeline NO tienen Write a `.claude/memory/*.md`. Si emerge lesson/error/decision durante un paso:
- Sub-agent reporta a init-saas como output del paso.
- init-saas propaga al handoff de el-evaluador post-pipeline.
- el-evaluador post-pipeline registra (R5 sole writer).

### R10 — Brand DNA contract

R10 enforcement queda a cargo del sub-agent que invoca add-ui-kit (paso 1, genera el contrato), impeccable (paso 2, consume el contrato), y add-login (paso 3, consume el contrato + el output de impeccable). init-saas NO valida R10 directamente — los sub-skills lo hacen.

## Reglas operativas

1. **Resume-aware mandatory.** Fase 0 detección SIEMPRE corre antes de Fase 1. Sin scan, no se sabe qué reutilizar — riesgo de re-ejecución innecesaria de Discovery FRESH (~30min wasted).

2. **Propagar contexto cross-pasos.** Cada paso recibe outputs de pasos previos como input estructurado. NO re-preguntar interview decisions.

3. **R4 strict cross-skill.** init-saas dispatcha sub-agents; sub-agents invocan add-ui-kit/impeccable/add-login. NO invocaciones directas desde init-saas.

4. **No contradecir cross-skills.** Si paso N produjo decisión X, paso N+1 la respeta. Halt + reportar si emerge inconsistencia.

5. **Confirmation explícita entre pasos.** Después de cada paso completado, init-saas pregunta "continuamos / pause / abort" — NO procede silenciosamente al siguiente paso.

6. **Halt + handoff explícito si paso falla.** El mensaje debe nombrar el skill que falló + qué falta resolver. Resume-aware se encarga de retomar.

7. **NO bypass de PREFLIGHT de sub-skills.** Si add-ui-kit, impeccable, add-login tienen PREFLIGHT propio, init-saas respeta sus halts. NO override.

8. **D-019 binary cita explícita.** detect-state.md cita D-019 + L-004 informativo (test diagnóstico aplicado, resultado binary).

9. **Resuelve E-006.** SKILL.md cita E-006 explícitamente — init-saas existe POR E-006. Otros wizards futuros heredan este patrón.

10. **NO templates folder.** Wizards son orchestration thin, no generan templates.

## Refusals

- ❌ Invocar add-ui-kit/impeccable/add-login directamente (R4 violation).
- ❌ Saltar Fase 0 detección (sin scan no se sabe qué skipear).
- ❌ Re-ejecutar Discovery FRESH si brand.json ya existe (waste).
- ❌ Saltar confirmation entre pasos (silent procession anti-pattern).
- ❌ Continuar paso N+1 si paso N falló (forced sequencing).
- ❌ Bypass de PREFLIGHT de sub-skills.
- ❌ Override decisiones de pasos previos (no contradicción).
- ❌ Escribir código de aplicación desde init-saas (R4).
- ❌ Escribir a `.claude/memory/*` (R5 — solo el-evaluador).
- ❌ Generar templates folder (anti-pattern wizard shape).

## Tool filter — init-saas MISMA

`Read · Grep · Glob · Bash (limited)`

NO Edit · NO Write directo · NO Skill (R4 — solo dispatch).

Bash limitado a:
- File globs (state detection)
- `git status` / `git log` (informativo)
- NO npm install / NO file generation directo

Sub-agents reciben tool filter completo según el skill que invoquen.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en SKILL.md + run-step.md (orchestrator thin) |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md (workers no memory) |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | en SKILL.md (Brand DNA gate via sub-skills) |
| Error | `[memory:errors#E-006]` | en SKILL.md + chain-rationale.md (resuelve gap UX) |
| Lesson | `[memory:lessons#L-004]` | en detect-state.md (binary D-019) |
| Decision | `[memory:decisions#D-019]` | en SKILL.md + detect-state.md (binary mode) |
| Decision | `[memory:decisions#D-009]` | en chain-rationale.md (add-login Supabase default) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `add-ui-kit` | downstream (paso 1). init-saas dispatcha sub-agent que invoca add-ui-kit Discovery FRESH. |
| `impeccable` | downstream (paso 2). Mode C BATCH consuming brand.json. |
| `add-login` | downstream (paso 3). Default Supabase (D-009) o Insforge override. |
| `baas` | upstream condicional. Si baas decision NO documentada → fallback Supabase con flag `assumed_default`. |
| `find-docs` | sub-tool ad-hoc. Sub-agents lo invocan según necesidad de cada paso. |
| `add-monetization` | downstream sugerido en handoff final. Wizard paralelo para pagos. |
| `add-mobile` | downstream sugerido en handoff final. PWA + push opcional. |
| `el-evaluador` | post-pipeline. Recibe handoff con proposed_memory_entries de sub-agents. |
| `el-crisol` | shape-par. Mismo shape estructural (sequential pipeline + resume-aware), distinto domain (strategy vs build). |
| `la-forja` | downstream sugerido. Después de init-saas, primera feature de aplicación. |

## Output handoff format

Detalle completo en [`prompts/run-step.md`](prompts/run-step.md). Resumen:

```markdown
## init-saas handoff

**Active feature:** {F?-S?}
**Mode:** FRESH | EXISTING (resume-aware)
**Pipeline ejecutado:** {N}/3
**Paso(s) saltado(s):** {list o ninguno}

**Outputs por paso:**
- Paso 1 (add-ui-kit): {paths brand/}
- Paso 2 (impeccable): {paths components/}
- Paso 3 (add-login): {paths auth/ + middleware}

**Próximos pasos sugeridos:**
- /add-monetization (pagos + emails + audit)
- /add-mobile (PWA + push)
- /la-forja para feature de aplicación

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: {si emerge}
```

---

*"init-saas es la respuesta arquitectural a E-006. Tres skills. Una invocación. Resume-aware. La cadena que cierra el chicken-egg sin sacrificar R4."*
