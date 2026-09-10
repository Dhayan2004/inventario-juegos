---
name: add-mobile-stack
description: >
  Wizard pipeline que extiende init-saas agregando mobile/PWA. Compone la cadena
  add-ui-kit → impeccable (Mode C BATCH) → add-login → add-mobile (PWA + Web Push).
  Resume-aware con detección de estado al estilo el-crisol/init-saas — escanea brand.json
  + voice.json (output add-ui-kit), component_rules.json + core components (output
  impeccable), src/features/auth/ (output add-login), manifest.json + sw.js + push
  subscriptions migration (output add-mobile) y skipea pasos completados. Binary shape
  (D-021): FRESH (chain completa de 4 pasos) vs EXISTING (resume desde donde quedó).
  Hereda D-019 informativo (init-saas binary, mismo patrón). add-mobile (D-012) es
  binary internamente — el wizard hereda ese binary sin modificarlo. R4 enforced —
  add-mobile-stack MISMA NO invoca skills, dispatch a sub-agents que invocan. Cada paso
  pasa contexto acumulado al siguiente. Si paso falla → halt + handoff explícito al
  skill que falló; cuando se resuelve, re-invocar add-mobile-stack → resume desde
  paso N. NO escribe código. Citas: [memory:decisions#D-021] (binary shape),
  [memory:decisions#D-019] (patrón heredado), [memory:decisions#D-012] (add-mobile
  binary interno), [memory:CONSTRAINTS.md#R4] (orchestrator thin),
  [memory:CONSTRAINTS.md#R10] (Brand DNA gate via add-ui-kit).
tier: core
requires: directorio de proyecto Next.js con `src/` o `pages/` accesible (PREFLIGHT halt si ninguno). AGENTS.md en raíz (proyecto inicializado con Forja). Para add-login (paso 3) — `baas` decision documentada o fallback Supabase default. Para add-mobile (paso 4) — `.env.local` writable para VAPID keys. Active feature en feature_list.json (R1) recomendado pero soft warning.
fallback: Sin AGENTS.md → halt: "proyecto no inicializado con Forja. Corré /forge-init primero." Sin src/ ni pages/ → halt: "no parece proyecto Next.js." Si paso N falla durante ejecución → halt + handoff explícito al skill que falló (ej: "add-mobile halt — VAPID keys faltan en .env.local"). Cuando paso resuelve, re-invocar add-mobile-stack → resume-aware detecta progreso y arranca desde paso N+1.
dependencies: [find-docs, add-ui-kit, impeccable, add-login, add-mobile, baas]
---

# add-mobile-stack

> *"Cuatro skills. Una invocación. La cadena completa SaaS + Mobile en un wizard."*

Wizard pipeline. Compone la cadena canónica de bootstrapping SaaS + Mobile Forja: **add-ui-kit → impeccable (Mode C BATCH) → add-login → add-mobile (PWA)**.

Shape estructural heredado de [`init-saas`](../init-saas/SKILL.md) — sequential pipeline + resume-aware state detection. Binary mode selector (D-021): FRESH default + EXISTING resume-aware sin PAUSE.

**Diferencia con init-saas:** init-saas cubre 3 pasos (Brand + components + auth). add-mobile-stack agrega un 4to paso (mobile/PWA) para proyectos que necesitan PWA + push notifications desde el bootstrap.

**No genera código.** No tiene `templates/` folder. R4 enforced — add-mobile-stack MISMA NO invoca add-ui-kit / impeccable / add-login / add-mobile directamente. Solo dispatch a sub-agents que invocan.

## PREFLIGHT — halt-blocked en faltantes mandatorios

```
1. ¿AGENTS.md en raíz del proyecto?
   - Sí → continuar (proyecto inicializado con Forja)
   - No → halt: "proyecto no inicializado con Forja. Corré /forge-init."

2. ¿src/ o pages/ accesible?
   - Sí → continuar (proyecto Next.js)
   - No → halt: "no parece proyecto Next.js — add-mobile-stack requiere Next.js
            con App Router (src/) o Pages Router (pages/)."

3. ¿feature_list.json con active feature (R1)?
   - Sí → asociar wizard al active feature
   - No → soft warning: "Sin active feature. Considerá pickear del backlog."
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario greenfield Forja quiere setup completo SaaS + Mobile | Coordinator |
| Usuario dice "init mobile saas", "setup completo con PWA", "bootstrap mobile-first" | Coordinator |
| Usuario corre add-mobile directo sin auth → halt → handoff sugiere add-mobile-stack | add-mobile |
| Triage de la-herreria post-Blueprint detecta SaaS + Mobile feature → sugiere add-mobile-stack | la-herreria |

NO se invoca para: planificar features (la-herreria), ejecutar feature ya con stack base (la-forja / el-golpe), agregar monetización (add-monetization wizard), setup SaaS sin mobile (init-saas).

## Mode selector (binary D-021)

| Modo | Trigger | Acción |
|------|---------|--------|
| **FRESH** (default) | Sin brand.json + sin core components + sin auth + sin manifest.json | Chain completa: add-ui-kit → impeccable → add-login → add-mobile (4 pasos) |
| **EXISTING** (resume-aware) | Algún output ya existe (state detection) | Skipea pasos completados, sigue desde donde quedó |

`prompts/detect-state.md` implementa la detección. **Decision tree:**

```
¿brand.json + voice.json + brand.css existen?
├── Sí → skip add-ui-kit (paso 1 ✅)
└── No → ejecutar add-ui-kit (paso 1 ⬜)

¿brand/component_rules.json + core components (≥7 de 11) existen?
├── Sí → skip impeccable (paso 2 ✅)
└── No → ejecutar impeccable Mode C BATCH (paso 2 ⬜)

¿src/features/auth/ + middleware existen?
├── Sí → skip add-login (paso 3 ✅)
└── No → ejecutar add-login (paso 3 ⬜)

¿public/manifest.json + public/sw.js + push_subscriptions migration existen?
├── Sí → skip add-mobile (paso 4 ✅)
└── No → ejecutar add-mobile (paso 4 ⬜)
```

**L-004 test diagnóstico (heredado D-019):** ¿degenerate case requiere upstream user action específica del selector?

| Caso | ¿Upstream user action? | Resultado |
|------|----------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí (correr forge-init / migrar a Next) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| FRESH path con sub-skill que tiene PAUSE interno | NO — PAUSE-interno-delegado se maneja en el sub-skill | NO PAUSE wizard (D-020 doctrine — heredada) |
| EXISTING parcial (1 de 4 pasos completados) | NO — resume-aware procede desde paso 2 | NO PAUSE |
| add-mobile (D-012) PWA-only fallback graceful | NO — add-mobile internamente decide PWA vs Native | NO PAUSE wizard |

**Conclusión D-021:** **BINARY** confirmed. FRESH default + EXISTING override (resume-aware), NO PAUSE genuino. Patrón heredado de D-019 (init-saas) y D-020 doctrine (PAUSE-interno-delegado NO escala).

## Pipeline canónico (los 4 pasos)

```
add-ui-kit ──→ impeccable ──→ add-login ──→ add-mobile
   │              │              │              │
   ▼              ▼              ▼              ▼
Brand DNA    Core component   Auth completa   PWA + Push
brand.json   set (11)         middleware +    manifest.json +
voice.json   Brand Score≥75   4 pages +       sw.js + VAPID +
brand.css                     RLS L-001       push_subs RLS
```

| # | Sub-prompt | Skill invocado vía sub-agent | Output | Necesita antes |
|---|------------|------------------------------|--------|----------------|
| 1 | `prompts/run-step.md` con `step=ui-kit` | `add-ui-kit` (Discovery FRESH) | brand.json + voice.json + brand.css + showcase | AGENTS.md + Next.js |
| 2 | `prompts/run-step.md` con `step=components` | `impeccable` (Mode C BATCH) | core 11 components + component_rules.json | brand.json + voice.json + brand.css |
| 3 | `prompts/run-step.md` con `step=auth` | `add-login` (Mode A Supabase / B Insforge) | lib/supabase + middleware + 4 pages + 0001_profiles.sql | brand.json + impeccable components |
| 4 | `prompts/run-step.md` con `step=mobile` | `add-mobile` (D-012 PWA default / Native override) | manifest.json + sw.js + VAPID + actions + 0004_push_subscriptions.sql con RLS L-001 | add-login completado + brand.json (manifest theme_color) + .env.local writable |

## Fase 0 — Detección de estado (resume-aware)

Detalle completo en [`prompts/detect-state.md`](prompts/detect-state.md). Resumen:

1. Scan paths canónicos:
   - `brand/brand.json`, `voice.json`, `brand.css`
   - `brand/component_rules.json` (output impeccable BATCH)
   - `src/shared/components/ui/` (los 11 components canónicos)
   - `src/features/auth/` o equivalente (output add-login)
   - `src/middleware.ts`
   - `public/manifest.json`, `public/sw.js`, supabase migration `0004_push_subscriptions.sql`
2. Determinar paso actual: el primero pendiente en orden 1→4.
3. Presentar tabla de estado.
4. Confirmar inicio: `go` / `desde N` / `solo [paso]` / `abort`.

## Fase 1 — Ejecución secuencial

Detalle en [`prompts/run-step.md`](prompts/run-step.md). Para cada paso pendiente, en orden:

1. **Anunciar paso:** N/4 + nombre + dependencias declaradas.
2. **Dispatch sub-agent:**
   - Sub-agent invoca el skill correspondiente (R4 — add-mobile-stack NO invoca directo).
   - Contexto pasado: `project_path`, `brand_json_path`, `voice_json_path`, `baas_decision`, outputs de pasos previos.
3. **Confirmar output:**
   ```
   ✅ Paso N/4 completado → [archivo/folder generado]
   Dato clave: [ej: "manifest.theme_color: #0066ff (derivado de brand.json)"]
   Siguiente: [paso N+1] — ¿continuamos? (sí / pause / abort)
   ```
4. **Si paso falla:**
   ```
   ❌ Paso N falló durante ejecución de [skill].
   Razón: [mensaje del skill — ej: "VAPID keys faltan en .env.local"]
   Próximo paso: resolvé [skill] manualmente. Cuando termines,
   re-invocá add-mobile-stack — resume-aware detecta progreso y arranca
   desde paso N o N+1 según corresponda.
   ```

## Reglas de ejecución cross-pasos

1. **NO repetir entrevistas.** Si add-ui-kit ya corrió Discovery FRESH y produjo brand.json con `archetype` y `posture`, impeccable NO vuelve a preguntar — lee del brand.json directamente.
2. **Propagar contexto.** Cada paso recibe outputs de pasos previos como input estructurado.
3. **NO contradecir.** Si add-ui-kit definió `tokens.colors.primary = #0066ff`, add-mobile usa ese mismo color para `manifest.theme_color`. NO override.
4. **R4 strict:** add-mobile-stack MISMA NO escribe código. Sub-agents son los que invocan los skills.
5. **R5 strict:** add-mobile-stack NO escribe a `.claude/memory/*`. Si emerge lesson/error, sub-agent reporta a add-mobile-stack → propaga al handoff de el-evaluador post-pipeline.

## Output handoff (final)

```markdown
## ✅ add-mobile-stack completado

**Pipeline ejecutado:** {N}/4 pasos
- ✅ Paso 1 (add-ui-kit): brand.json + voice.json + brand.css + showcase
- ✅ Paso 2 (impeccable): 11 core components con Brand Score ≥75
- ✅ Paso 3 (add-login): middleware + 4 auth pages + Supabase/Insforge
- ✅ Paso 4 (add-mobile): manifest.json + sw.js + VAPID + push subscriptions con RLS L-001

**Tenés:** Brand DNA + core component set + auth + PWA shell + push notifications.

**Próximos pasos opcionales:**
- → `/add-monetization` para integrar pagos + emails + audit web-quality
- → `/enterprise-stack` para setup completo (init-saas + add-monetization + add-mobile-stack)
- → `/la-forja` o `/build` para tu primera feature de aplicación

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: si emerge patrón cross-proyecto
```

Si pipeline parcial:

```markdown
## add-mobile-stack — Pipeline parcial

**Estado:** {N}/4 pasos completados
- ✅ Paso 1: completado
- ✅ Paso 2: completado
- ⚠️ Paso 3: failed durante ejecución de add-login
- ⬜ Paso 4: pendiente

**Razón del halt:** {mensaje}

**Próximo paso:** resolvé add-login. Cuando termines, re-invocá add-mobile-stack
y resume-aware detecta progreso desde paso 3 (o paso 4 si paso 3 ya está completo).
```

## Hard rules — R4/R5/R10 enforcement

### R4 — Orchestrator stays thin (CRÍTICO para wizards)

> [memory:CONSTRAINTS.md#R4]: orchestrator NUNCA invoca skill directamente. Solo dispatch a sub-agentes.

add-mobile-stack MISMA:
- Lee (Read, Grep, Glob) state files (brand.json, src/features/auth/, public/manifest.json, etc.).
- Detecta state Fase 0 + presenta tabla.
- Dispatch a sub-agents Fase 1.
- Sintetiza outputs entre pasos (texto, no código).
- NO Edit/Write a código de aplicación.
- NO invoca add-ui-kit/impeccable/add-login/add-mobile directo.

Sub-agents reciben tool filter completo dentro del proyecto target.

### R5 — Workers no escriben memory

Sub-agents en pipeline NO tienen Write a `.claude/memory/*.md`. Si emerge lesson/error/decision durante un paso → sub-agent reporta a add-mobile-stack → propaga al handoff de el-evaluador post-pipeline.

### R10 — Brand DNA contract

R10 enforcement queda a cargo del sub-agent que invoca add-ui-kit (paso 1, genera el contrato), impeccable (paso 2, consume), add-login (paso 3, consume), y add-mobile (paso 4, consume — manifest.theme_color + icons derivan de brand.json). add-mobile-stack NO valida R10 directamente — los sub-skills lo hacen.

## Reglas operativas

1. **Resume-aware mandatory.** Fase 0 detección SIEMPRE corre antes de Fase 1.
2. **Propagar contexto cross-pasos.** Cada paso recibe outputs de pasos previos.
3. **R4 strict cross-skill.** add-mobile-stack dispatcha sub-agents; sub-agents invocan skills. NO invocaciones directas.
4. **No contradecir cross-skills.** Si paso N produjo decisión X, paso N+1 la respeta. Halt + reportar si emerge inconsistencia.
5. **Confirmation explícita entre pasos.** Después de cada paso, "continuamos / pause / abort".
6. **Halt + handoff explícito si paso falla.** El mensaje nombra el skill que falló + qué falta resolver.
7. **NO bypass de PREFLIGHT de sub-skills.** Si add-ui-kit, impeccable, add-login, add-mobile tienen PREFLIGHT propio, add-mobile-stack respeta sus halts.
8. **D-021 binary cita explícita.** detect-state.md cita D-021 + D-019 informativo (patrón heredado) + L-004 informativo.
9. **Hereda D-020 doctrine.** PAUSE-interno-delegado de sub-skills NO escala como PAUSE-wizard.
10. **NO templates folder.** Wizards son orchestration thin.

## Refusals

- ❌ Invocar add-ui-kit/impeccable/add-login/add-mobile directamente (R4 violation).
- ❌ Saltar Fase 0 detección.
- ❌ Re-ejecutar Discovery FRESH si brand.json ya existe (waste).
- ❌ Saltar confirmation entre pasos.
- ❌ Continuar paso N+1 si paso N falló.
- ❌ Bypass de PREFLIGHT de sub-skills.
- ❌ Override decisiones de pasos previos.
- ❌ Escribir código de aplicación desde add-mobile-stack (R4).
- ❌ Escribir a `.claude/memory/*` (R5).
- ❌ Generar templates folder (anti-pattern wizard shape).

## Tool filter — add-mobile-stack MISMA

`Read · Grep · Glob · Bash (limited)`

NO Edit · NO Write directo · NO Skill (R4 — solo dispatch).

Bash limitado a:
- File globs (state detection).
- `git status` / `git log` (informativo).
- NO npm install / NO file generation directo.

Sub-agents reciben tool filter completo según el skill que invoquen.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en SKILL.md + run-step.md |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | en SKILL.md |
| Lesson | `[memory:lessons#L-004]` | en detect-state.md (binary D-021) |
| Decision | `[memory:decisions#D-021]` | en SKILL.md + detect-state.md (binary mode) |
| Decision | `[memory:decisions#D-019]` | en SKILL.md + chain-rationale.md (patrón heredado de init-saas) |
| Decision | `[memory:decisions#D-020]` | en SKILL.md (PAUSE-interno-delegado doctrine) |
| Decision | `[memory:decisions#D-012]` | en SKILL.md + chain-rationale.md (add-mobile binary interno) |
| Decision | `[memory:decisions#D-009]` | en chain-rationale.md (add-login Supabase default) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `init-saas` | shape-par + downstream-extension. add-mobile-stack es init-saas + 1 paso (mobile). Mismo patrón shape D-019. |
| `add-ui-kit` | downstream (paso 1). |
| `impeccable` | downstream (paso 2). Mode C BATCH. |
| `add-login` | downstream (paso 3). Default Supabase (D-009). |
| `add-mobile` | downstream (paso 4). D-012 binary PWA / Native. |
| `baas` | upstream condicional. |
| `find-docs` | sub-tool ad-hoc. |
| `add-monetization` | downstream sugerido en handoff final. |
| `enterprise-stack` | upstream wizard de wizards (D-022). |
| `el-evaluador` | post-pipeline. Recibe handoff con proposed_memory_entries. |
| `el-crisol` | shape-par. Mismo shape estructural. |
| `la-forja` | downstream sugerido. |

## Output handoff format

Detalle completo en [`prompts/run-step.md`](prompts/run-step.md). Resumen:

```markdown
## add-mobile-stack handoff

**Active feature:** {F?-S?}
**Mode:** FRESH | EXISTING (resume-aware)
**Pipeline ejecutado:** {N}/4
**Paso(s) saltado(s):** {list o ninguno}

**Outputs por paso:**
- Paso 1 (add-ui-kit): {paths brand/}
- Paso 2 (impeccable): {paths components/}
- Paso 3 (add-login): {paths auth/ + middleware}
- Paso 4 (add-mobile): {paths manifest.json + sw.js + push migration}

**Próximos pasos sugeridos:**
- /add-monetization (pagos + emails + audit)
- /enterprise-stack (wrapper completo si querés todo en una)
- /la-forja para feature de aplicación
- /el-guardian audit pre-deploy

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: {si emerge}
```

---

*"add-mobile-stack: cuatro skills coordinados con resume-aware. La diferencia entre 'PWA listo desde día 1' y 'PWA agregada después con friction'."*
