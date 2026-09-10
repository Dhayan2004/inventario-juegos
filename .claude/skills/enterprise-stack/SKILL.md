---
name: enterprise-stack
description: >
  Wizard de wizards. Compone init-saas → add-monetization → add-mobile-stack para setup
  enterprise completo en una sola invocación. Resume-aware con detección de estado al
  estilo el-crisol — escanea outputs de cada wizard hijo y skipea los completados. Binary
  shape (D-022): full chain default (3 wizards) vs custom override (skip wizards
  específicos). Hereda D-019 (init-saas), D-020 (add-monetization PAUSE-interno-delegado
  doctrine), D-021 (add-mobile-stack). Cada sub-wizard maneja su propio PREFLIGHT + state
  detection internos — enterprise-stack solo coordina el orden top-level (R4 thin
  orchestrator). R6 enforced: valida que init-saas, add-monetization, add-mobile-stack
  existan en skills.md antes de dispatch. Si sub-wizard falla → halt + handoff a ese
  wizard manualmente; cuando se resuelve, re-invocar enterprise-stack → resume desde
  wizard pendiente. NO escribe código. Citas: [memory:decisions#D-022] (binary shape,
  wizard de wizards), [memory:decisions#D-019] (init-saas patrón heredado), [memory:
  decisions#D-020] (PAUSE-interno-delegado doctrine), [memory:decisions#D-021]
  (add-mobile-stack patrón heredado), [memory:CONSTRAINTS.md#R4] (orchestrator thin),
  [memory:CONSTRAINTS.md#R6] (skills.md registry validation pre-dispatch).
tier: core
requires: directorio de proyecto Next.js + AGENTS.md en raíz. Skills init-saas, add-monetization, add-mobile-stack disponibles en `.claude/memory/skills.md` (R6 enforcement). Active feature en feature_list.json (R1) recomendado pero soft warning si falta.
fallback: Sin AGENTS.md → halt: "proyecto no inicializado con Forja". Sin Next.js → halt informativo. Si init-saas/add-monetization/add-mobile-stack NO existen en skills.md → halt: "wizard {nombre} no disponible — re-instalar Forja". Si sub-wizard halt durante ejecución → halt + handoff explícito; resume-aware retoma cuando se resuelve.
dependencies: [init-saas, add-monetization, add-mobile-stack]
---

# enterprise-stack

> *"Tres wizards. Una invocación. El stack enterprise completo en ~3-4h primera vez."*

Wizard de wizards. Compone los 3 wizards core de Forja: **init-saas → add-monetization → add-mobile-stack**.

Una invocación → proyecto production-ready con Brand DNA + components + auth + pagos + emails + audit + PWA + push.

Shape estructural heredado de [`init-saas`](../init-saas/SKILL.md) — sequential pipeline + resume-aware state detection. Binary mode selector (D-022): full chain default + custom override (skip wizards específicos), NO PAUSE genuino.

**Diferencia con los 3 wizards hijos:** init-saas/add-monetization/add-mobile-stack invocan skills (add-ui-kit, impeccable, etc.). enterprise-stack invoca **wizards** que a su vez invocan skills. Es un wrapper top-level — un nivel de abstracción superior.

**No genera código.** No tiene `templates/` folder. R4 enforced — enterprise-stack MISMA NO invoca init-saas/add-monetization/add-mobile-stack directamente. Solo dispatch a sub-agents que invocan los wizards.

## PREFLIGHT — halt-blocked en faltantes mandatorios

```
1. ¿AGENTS.md en raíz del proyecto?
   - Sí → continuar
   - No → halt: "proyecto no inicializado con Forja. Corré /forge-init."

2. ¿src/ o pages/ accesible?
   - Sí → continuar (proyecto Next.js)
   - No → halt: "no parece proyecto Next.js."

3. ¿init-saas, add-monetization, add-mobile-stack existen en skills.md? (R6)
   - Read .claude/memory/skills.md
   - Validar las 3 entries por nombre exacto
   - Si alguna falta → halt: "wizard {nombre} no disponible. Re-instalar Forja."

4. ¿feature_list.json con active feature (R1)?
   - Sí → asociar enterprise-stack al active feature
   - No → soft warning: "Sin active feature. Considerá pickear del backlog."
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario greenfield Forja quiere setup completo enterprise | Coordinator |
| Usuario dice "enterprise stack", "setup completo", "todo de una", "production-ready" | Coordinator |
| Triage de la-herreria post-Blueprint detecta SaaS + Mobile + Monetization | la-herreria |
| Usuario corre wizard hijo (init-saas / add-monetization / add-mobile-stack) y al terminar pregunta "¿qué sigue?" → handoff sugiere enterprise-stack para los wizards faltantes | wizard hijo |

NO se invoca para: planificar features (la-herreria), ejecutar feature ya con stack base (la-forja / el-golpe), un wizard hijo aislado (init-saas / add-monetization / add-mobile-stack directamente).

## Mode selector (binary D-022)

| Modo | Trigger | Acción |
|------|---------|--------|
| **FULL** (default) | Sin override del usuario | Chain completa: init-saas → add-monetization → add-mobile-stack (3 wizards) |
| **CUSTOM** (override) | Usuario dice "sin mobile" / "sin pagos" / "skip add-mobile-stack" / "solo init-saas + add-monetization" | Skip wizards específicos según override del usuario |

`prompts/detect-state.md` implementa la detección. **Decision tree:**

```
¿init-saas DONE? (brand.json + voice.json + auth/ existen)
├── Sí → skip init-saas (paso 1 ✅)
└── No → ejecutar init-saas (paso 1 ⬜)

¿add-monetization DONE? (payments/ + emails/ + web-quality report existen)
├── Sí → skip add-monetization (paso 2 ✅)
└── No → ejecutar add-monetization (paso 2 ⬜)

¿add-mobile-stack DONE? (PWA manifest + push subscriptions existen)
├── Sí → skip add-mobile-stack (paso 3 ✅)
└── No → ejecutar add-mobile-stack (paso 3 ⬜)

NOTA: add-mobile-stack es SUPERCONJUNTO de init-saas (ambos cubren ui-kit + components + auth).
Si add-mobile-stack DONE → init-saas implícitamente DONE también.
```

**L-004 test diagnóstico:**

| Caso | ¿Upstream user action requerida del selector? | Resultado |
|------|----------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí (correr forge-init) | PREFLIGHT halt, NO PAUSE selector |
| Sub-wizard PAUSE-interno (ej: add-monetization → add-payments PAUSE-on-prem D-010) | NO — D-020 doctrine: PAUSE-interno-delegado NO escala | NO PAUSE wizard |
| EXISTING parcial (1 de 3 wizards completados) | NO — resume-aware procede desde wizard pendiente | NO PAUSE |
| Custom override (usuario excluye add-mobile-stack) | NO — override es elección del usuario, no degenerate case | NO PAUSE |

**Conclusión D-022:** **BINARY** confirmed. FULL default + CUSTOM override (skip wizards), NO PAUSE genuino. Patrón heredado de D-019/D-021.

## Pipeline canónico (los 3 wizards)

```
init-saas ──→ add-monetization ──→ add-mobile-stack
   (paso 1)        (paso 2)              (paso 3)

Cubre:                                   Adiciona:
- Brand DNA (add-ui-kit)                 - PWA shell (manifest + sw)
- Core components (impeccable)           - Push notifications (VAPID)
- Auth (add-login)                       - push_subscriptions migration
                                         (RLS L-001 tied to user_id)
   ▼
+ pagos (add-payments)
+ emails (add-emails)
+ audit web-quality
```

| # | Sub-prompt | Wizard invocado vía sub-agent | Output | Necesita antes |
|---|------------|-------------------------------|--------|----------------|
| 1 | `prompts/run-step.md` con `wizard=init-saas` | `init-saas` | brand.json + voice.json + components + auth + 0001_profiles.sql | AGENTS.md + Next.js |
| 2 | `prompts/run-step.md` con `wizard=add-monetization` | `add-monetization` | payments + emails + web-quality report | init-saas DONE |
| 3 | `prompts/run-step.md` con `wizard=add-mobile-stack` | `add-mobile-stack` | PWA manifest + sw.js + push migration | init-saas DONE (auth necesario) |

**NOTA importante:** add-mobile-stack es superconjunto de init-saas (los 3 primeros pasos de add-mobile-stack son los mismos que init-saas). Si CUSTOM mode skipea init-saas pero ejecuta add-mobile-stack, add-mobile-stack lo cubre. Si FULL mode ejecuta init-saas primero, add-mobile-stack solo ejecuta su paso 4 (mobile) — paso 1/2/3 se skipean por resume-aware del wizard hijo.

## Fase 0 — Detección de estado (resume-aware)

Detalle completo en [`prompts/detect-state.md`](prompts/detect-state.md). Resumen:

1. Scan paths canónicos de cada wizard hijo:
   - **init-saas DONE:** brand.json + voice.json + brand.css + component_rules.json + ≥7 components + src/features/auth/ + middleware.
   - **add-monetization DONE:** src/features/payments/ + src/features/emails/ + 0002_subscriptions + 0003_email_subscriptions + (opcional) reporte web-quality.
   - **add-mobile-stack DONE:** init-saas DONE + public/manifest.json + public/sw.js + 0004_push_subscriptions.
2. Determinar wizard pendiente: el primero pendiente en orden 1→3.
3. Presentar tabla de estado.
4. Confirmar inicio: `go full` / `custom [skip-X]` / `solo [wizard]` / `abort`.

## Fase 1 — Ejecución secuencial

Detalle en [`prompts/run-step.md`](prompts/run-step.md). Para cada wizard pendiente, en orden:

1. **Anunciar wizard:** N/3 + nombre + skills que invoca internamente.
2. **R6 validation pre-dispatch:** validar que el wizard existe en skills.md (debería ya validado en PREFLIGHT, pero double-check antes de cada dispatch).
3. **Dispatch sub-agent:**
   - Sub-agent invoca el wizard hijo (R4 — enterprise-stack NO invoca directo).
   - Contexto pasado: `project_path`, `baas_decision` si documentada.
4. **Sub-wizard ejecuta su flow:** init-saas / add-monetization / add-mobile-stack tienen su propio PREFLIGHT + Fase 0 + Fase 1 + handoff. enterprise-stack NO interviene.
5. **Confirmar wizard hijo completado:**
   ```
   ✅ Wizard {N}/3 completado → {wizard_name}
   Outputs: [paths del wizard hijo]
   Siguiente: {wizard N+1} — ¿continuamos? (sí / pause / abort)
   ```
6. **Si wizard hijo falla:**
   ```
   ❌ Wizard {N} falló durante ejecución de {wizard_name}.
   Razón: [del wizard hijo]
   Próximo paso: resolvé {wizard_name} manualmente. Cuando termines,
   re-invocá enterprise-stack — resume-aware detecta progreso y arranca
   desde wizard {N} o {N+1}.
   ```

## Reglas de ejecución cross-wizards

1. **NO doble-ejecutar wizard hijo.** Si init-saas DONE, NO re-ejecutarlo. Resume-aware skip.
2. **Propagar baas_decision.** init-saas elige BaaS (Supabase default D-009 / Insforge override) → propagar a add-monetization (que invoca add-payments + add-emails) y add-mobile-stack (que invoca add-mobile).
3. **R4 strict:** enterprise-stack NO invoca init-saas/add-monetization/add-mobile-stack directo. Solo dispatch a sub-agents.
4. **R5 strict:** enterprise-stack NO escribe a `.claude/memory/*`. Sub-wizards reportan a enterprise-stack → propaga al handoff de el-evaluador post-pipeline.
5. **R6 strict:** validar wizards en skills.md ANTES de dispatch.
6. **PAUSE-interno-delegado heredado (D-020 doctrine):** si sub-wizard tiene PAUSE interno (ej: add-monetization → add-payments → PAUSE-on-prem D-010), enterprise-stack reporta "PAUSE-interno-delegado del wizard {N}" al usuario, halt graceful, NO escala como PAUSE-wizard.

## Output handoff (final)

```markdown
## ✅ enterprise-stack completado

**Pipeline ejecutado:** {N}/3 wizards
- ✅ Wizard 1 (init-saas): Brand DNA + components + auth (3 sub-pasos completados)
- ✅ Wizard 2 (add-monetization): payments + emails + web-quality audit
- ✅ Wizard 3 (add-mobile-stack): PWA manifest + push notifications + migrations

**Tenés:** Stack enterprise completo — Brand DNA, core components, auth, pagos, emails, audit, PWA shell, push notifications.

**Tiempo total:** ~3-4h primera vez (depende de Discovery interactivo).

**Próximos pasos:**
- → `/el-guardian` audit pre-deploy con Codex (D3) — recomendado.
- → `/build` para tu primera feature de aplicación (la-forja paralelo o el-yunque manual).
- → `make deploy` cuando todo esté listo (R14 destructivas verificadas).

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: si emergió patrón cross-proyecto durante el setup.
```

Si pipeline parcial:

```markdown
## enterprise-stack — Pipeline parcial

**Estado:** {N}/3 wizards completados
- ✅ Wizard 1 (init-saas): completado
- ⚠️ Wizard 2 (add-monetization): failed durante ejecución
- ⬜ Wizard 3 (add-mobile-stack): pendiente

**Razón del halt:** {mensaje del wizard hijo}

**Próximo paso:** resolvé add-monetization. Cuando termines, re-invocá enterprise-stack
y resume-aware detecta progreso desde Wizard 2 (o Wizard 3 si Wizard 2 ya está
completo).
```

## Hard rules — R4/R5/R6/R10 enforcement

### R4 — Orchestrator stays thin (CRÍTICO para wizard de wizards)

> [memory:CONSTRAINTS.md#R4]: orchestrator NUNCA invoca skill/wizard directamente. Solo dispatch a sub-agentes.

enterprise-stack MISMA:
- Lee state files de cada wizard hijo (Read, Grep, Glob).
- Detecta state Fase 0 + presenta tabla.
- Dispatch a sub-agents Fase 1.
- Sintetiza outputs entre wizards (texto, no código).
- NO Edit/Write a código de aplicación.
- NO invoca init-saas/add-monetization/add-mobile-stack directo.

### R5 — Workers no escriben memory

Sub-agents en pipeline NO tienen Write a `.claude/memory/*.md`. Si emerge lesson/error/decision durante un wizard hijo → reportar a enterprise-stack → propaga al handoff de el-evaluador post-pipeline.

### R6 — Skills registry validation pre-dispatch

> [memory:CONSTRAINTS.md#R6]: antes de invocar cualquier skill, validar el nombre exacto en `.claude/memory/skills.md`.

enterprise-stack MISMA, en PREFLIGHT, valida que las 3 entries (init-saas, add-monetization, add-mobile-stack) existan en skills.md. Si alguna falta → halt con mensaje exacto. NO ejecutar.

### R10 — Brand DNA contract

R10 enforcement queda a cargo del wizard 1 (init-saas → add-ui-kit produce el contrato). enterprise-stack NO valida R10 directamente — los wizards hijos lo hacen.

## Reglas operativas

1. **Resume-aware mandatory.** Fase 0 detección SIEMPRE corre antes de Fase 1.
2. **Propagar baas_decision cross-wizards.**
3. **R4/R5/R6 strict.**
4. **No contradecir cross-wizards.** Si Wizard 1 produjo decisión X (ej: archetype del brand), Wizard 2 y 3 la respetan.
5. **Confirmation explícita entre wizards.** Después de cada wizard, "continuamos / pause / abort".
6. **Halt + handoff explícito si wizard falla.**
7. **NO bypass de PREFLIGHT de wizards hijos.** Cada wizard tiene su propio PREFLIGHT — enterprise-stack respeta.
8. **D-022 binary cita explícita** + D-019 / D-020 / D-021 informativos (patrones heredados).
9. **NO templates folder.**
10. **CUSTOM override válido** — usuario puede skipear wizards. Documentar la elección.

## Refusals

- ❌ Invocar init-saas/add-monetization/add-mobile-stack directamente (R4 violation).
- ❌ Saltar validación R6 de skills.md.
- ❌ Saltar Fase 0 detección.
- ❌ Re-ejecutar wizard ya completado (waste).
- ❌ Saltar confirmation entre wizards.
- ❌ Continuar wizard N+1 si wizard N falló.
- ❌ Bypass de PREFLIGHT de wizards hijos.
- ❌ Override decisiones de wizards previos.
- ❌ Escribir código de aplicación desde enterprise-stack (R4).
- ❌ Escribir a `.claude/memory/*` (R5).
- ❌ Generar templates folder.

## Tool filter — enterprise-stack MISMA

`Read · Grep · Glob · Bash (limited)`

NO Edit · NO Write directo · NO Skill (R4 — solo dispatch).

Bash limitado a:
- File globs (state detection).
- `git status` / `git log` (informativo).
- NO npm install / NO file generation directo.

Sub-agents reciben tool filter completo según el wizard hijo que invoquen.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en SKILL.md + run-step.md |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md |
| Constraint | `[memory:CONSTRAINTS.md#R6]` | en SKILL.md (skills.md validation pre-dispatch) |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | en SKILL.md (delegated to wizards hijos) |
| Lesson | `[memory:lessons#L-004]` | en detect-state.md (binary D-022) |
| Decision | `[memory:decisions#D-022]` | en SKILL.md + detect-state.md (binary mode wizard de wizards) |
| Decision | `[memory:decisions#D-019]` | en SKILL.md + chain-rationale.md (init-saas patrón heredado) |
| Decision | `[memory:decisions#D-020]` | en SKILL.md (PAUSE-interno-delegado doctrine) |
| Decision | `[memory:decisions#D-021]` | en SKILL.md + chain-rationale.md (add-mobile-stack patrón heredado) |

## Integración con otros skills

| Skill / Wizard | Relación |
|----------------|----------|
| `init-saas` | downstream (paso 1). Wizard hijo. |
| `add-monetization` | downstream (paso 2). Wizard hijo. |
| `add-mobile-stack` | downstream (paso 3). Wizard hijo. |
| `el-evaluador` | post-pipeline. Recibe handoff con proposed_memory_entries de los 3 wizards. |
| `el-guardian` | downstream sugerido en handoff final. Audit pre-deploy con Codex. |
| `el-crisol` | shape-par. Mismo shape estructural (sequential pipeline + resume-aware). |
| `la-forja` | downstream sugerido para primera feature de aplicación. |
| `migration-wizard` | shape-par parcial. migration-wizard usa pipeline shape pero produce un PLAN (no ejecuta). |

## Output handoff format

Detalle completo en [`prompts/run-step.md`](prompts/run-step.md). Resumen:

```markdown
## enterprise-stack handoff

**Active feature:** {F?-S?}
**Mode:** FULL | CUSTOM (skip: [wizards-skipped])
**Pipeline ejecutado:** {N}/3 wizards
**Wizards saltados:** {list o ninguno}

**Outputs por wizard:**
- Wizard 1 (init-saas): {paths brand/ + auth/}
- Wizard 2 (add-monetization): {paths payments/ + emails/ + web-quality report}
- Wizard 3 (add-mobile-stack): {paths PWA + push migration}

**Próximos pasos sugeridos:**
- /el-guardian audit pre-deploy
- /build para feature de aplicación
- make deploy cuando esté validado

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: {si emerge}
```

---

*"enterprise-stack: el wizard de wizards. Tres niveles de orquestación coordinados. La diferencia entre 'proyecto Forja con stack enterprise listo' y 'mes de configuración manual con halt-handoff fricciones'."*
