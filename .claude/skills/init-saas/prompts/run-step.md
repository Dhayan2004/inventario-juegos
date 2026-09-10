# run-step

> Fase 1 de init-saas. Protocolo genérico para ejecutar UN paso del pipeline (1 de 3). Cada paso delega a sub-agent que invoca el skill apropiado. R4/R5 enforced. Contexto acumulado se propaga cross-pasos.

## Inputs

```yaml
step:
  number: 1 | 2 | 3
  name: ui-kit | components | auth
  skill_to_invoke: add-ui-kit | impeccable | add-login

context_acumulado:
  project_root: <path>
  brand_json_path: <path or null>          # paso 1 lo crea, pasos 2+3 lo consumen
  voice_json_path: <path or null>
  brand_css_path: <path or null>
  component_rules_path: <path or null>     # paso 2 lo crea, paso 3 lo consume
  baas_decision: <supabase | insforge | null>  # input opcional para paso 3
```

## Output

```yaml
step_result:
  step_name: ui-kit | components | auth
  outcome: success | failed | paused

  # si success
  outputs_generated:
    - <paths creados/modificados>
  output_summary:
    key_data: <ej: "Archetype: Sage + Creator, Posture density=4">
    rationale: <1-2 frases sobre decisiones tomadas>
  next_step_context:
    propagate:
      - <variables que paso N+1 debe heredar>

  # si failed
  fail_reason: <texto>
  fail_in_skill: <nombre del skill>
  resume_instruction: <ej: "Resolvé add-ui-kit Discovery interview. Re-invocá init-saas.">

  # si paused (sub-skill espera input usuario, ej: add-login espera baas decision)
  pause_reason: <texto>
  pause_resolution: <ej: "Documentá baas decision en feature_list.json o esperá baas skill">

  user_decision_post_step: continue | pause | abort
```

## Protocolo por paso

### Step 1 — Anunciar el paso

```markdown
━━━ Paso {N}/3: {step_name} ━━━

**Skill a invocar:** {skill_to_invoke}
**Qué produce:** {output esperado}
**Dependencias:** {docs previos del pipeline necesarios}
**Tiempo estimado:** ~{N}min
```

### Step 2 — Validar precondiciones

Antes de dispatch, validar que el contexto acumulado cumple los requires del skill a invocar:

| Step | Precondiciones |
|------|----------------|
| 1 (ui-kit) | AGENTS.md + Next.js (ya validado en PREFLIGHT) |
| 2 (components) | `brand_json_path` + `voice_json_path` + `brand_css_path` no-null |
| 3 (auth) | `brand_json_path` + `component_rules_path` no-null + `baas_decision` documentada o fallback Supabase |

Si precondiciones fallan → halt + reportar gap (señal de bug en detect-state.md o invocación con `solo [paso]` sin precondiciones).

### Step 3 — Dispatch sub-agent

R4 enforced: init-saas MISMA NO invoca el skill. Dispatcha sub-agent:

```
[Sub-agent dispatched by init-saas]
  Role: Pipeline executor (paso {N})
  Tool filter:
    - Read · Edit · Write · Grep · Glob (full-stack dentro del project_root)
    - Bash: typecheck + tests + git
    - Skill: {skill_to_invoke}
  System prompt:
    "Sos el pipeline executor para paso {N} (init-saas wizard). Invocá
     {skill_to_invoke} con context: {context_acumulado_yaml}. Output va a
     {paths_canonicos_del_step}. NO escribas a .claude/memory/* (R5).
     Reportá step_result a init-saas con outputs_generated + key_data."
```

### Step 4 — Sub-agent ejecuta el skill

Sub-agent:
1. Invoca `{skill_to_invoke}` con context.
2. Skill ejecuta su flow normal (Discovery FRESH si add-ui-kit, BATCH si impeccable, Mode A si add-login).
3. Si el skill internamente tiene PAUSE (ej: add-login espera baas decision si no documentada → fallback Supabase con flag `assumed_default = true`), el PAUSE es **interno al skill** — el wizard NO lo escala (R4 + D-020 distinción).
4. Sub-agent reporta `step_result` a init-saas al terminar.

### Step 5 — init-saas confirma output

```markdown
{✅ | ❌ | ⚠️} Paso {N}/3 completado → {output_summary.key_data}

**Outputs:**
{outputs_generated lista}

**Siguiente:** Paso {N+1} ({nombre}) — {qué hará}

¿Continuamos? (sí / pause / abort)
```

### Step 6 — Transición según user_decision

| Decision | Acción |
|----------|--------|
| sí / continue | Procede a paso N+1 con context_acumulado actualizado |
| pause | Guarda state + reporta progreso al usuario, halt graceful |
| abort | Halt completo + ofrecer Fase 2 con outputs parciales si aplica |
| (silencio) | Esperar — NO procede sin decisión explícita |

## Contexto que se propaga cross-pasos

```yaml
# Después de paso 1 (add-ui-kit)
context_acumulado.brand_json_path = "brand/brand.json"
context_acumulado.voice_json_path = "brand/voice.json"
context_acumulado.brand_css_path = "brand/brand.css"
context_acumulado.archetype = "Sage + Creator"
context_acumulado.posture = { density: 4, expression: 2, ... }

# Después de paso 2 (impeccable)
context_acumulado.component_rules_path = "brand/component_rules.json"
context_acumulado.components_generated = ["Button", "Input", "Card", ...]
context_acumulado.brand_score_avg = 87.5

# Después de paso 3 (add-login)
context_acumulado.auth_provider = "supabase" | "insforge"
context_acumulado.auth_pages = ["sign-in", "sign-up", "forgot-password", "update-password"]
context_acumulado.middleware_path = "src/middleware.ts"
```

Cada sub-agent recibe el `context_acumulado` actualizado como input.

## Reglas operativas cross-pasos

### 1. NO repetir entrevistas

Si add-ui-kit ya corrió Discovery FRESH (paso 1) y produjo `archetype` + `posture` + `tokens`, impeccable (paso 2) NO vuelve a preguntar — lee directamente del `brand.json`. Sub-agent del paso 2 inyecta estas decisiones en el prompt de impeccable como context-already-decided.

### 2. NO contradecir decisiones de pasos previos

Si paso 1 definió `tokens.colors.primary = "#0066ff"`, paso 2 (impeccable) consume ese valor literal. Si emerge inconsistencia (ej: paso 2 quiere override por accesibilidad) → halt + reportar al humano para resolución manual.

Paso 3 (add-login) consume `tokens` de paso 1 + `component_rules` de paso 2 — ambos respetados literal.

### 3. R4 strict

init-saas MISMA NO invoca skills. Sub-agents dispatchados son los que invocan add-ui-kit/impeccable/add-login. Si te ves haciendo `Skill: add-ui-kit` directamente desde init-saas → R4 violation, refactor a sub-agent dispatch.

### 4. R5 strict

Sub-agents dispatched NO escriben a `.claude/memory/*.md`. El skill que invocan tampoco (cada add-* skill respeta R5 independientemente). Si emerge memory-worthy event:
- Sub-agent reporta a init-saas como parte del step_result.
- init-saas propaga al handoff de el-evaluador post-pipeline.
- el-evaluador post-pipeline registra (R5 sole writer).

### 5. PAUSE-interno-delegado (D-020 distinción)

Si un sub-skill tiene PAUSE interno (ej: add-payments PAUSE para empresa MoR via D-010), ese PAUSE es **interno al skill**. El wizard:
- Reporta el PAUSE al usuario con shape `step_result.outcome = paused`.
- Documenta el `pause_resolution` (qué debe hacer el usuario).
- NO escala el PAUSE al nivel wizard — D-020 documenta que init-saas/add-monetization siguen siendo BINARY al wizard level.

Para init-saas específicamente: ningún paso (add-ui-kit, impeccable, add-login) tiene PAUSE-trinary genuino propio (D-009 add-login binary, add-ui-kit + impeccable son binary internamente sin PAUSE), así que init-saas en práctica nunca encuentra PAUSE delegado. Pero la regla está documentada para futuros wizards.

## Halt + handoff si paso falla

Si `step_result.outcome = failed`:

```markdown
❌ init-saas — Paso {N} falló durante ejecución de {skill}

**Razón:** {fail_reason}

**Context preservado:**
- Pasos completados: {1..N-1} ✅
- Paso {N} ❌
- Pasos pendientes: {N+1..3} ⬜

**Próximo paso (action requerida):**
{resume_instruction}

**Cuando termines:**
- Re-invocá `/init-saas` — Fase 0 detect-state escaneará progreso parcial.
- Resume-aware arrancará desde paso {N} (si falló mid-execution) o paso {N+1}
  (si falló post-success-pero-pre-confirm).
```

NO continuar con paso {N+1} silenciosamente. Forced sequencing es anti-pattern.

## Edge cases

### Edge: sub-agent reporta PAUSE-interno (paused outcome)

→ init-saas reporta el PAUSE al usuario + `pause_resolution`. Halt graceful — el usuario resuelve y re-invoca init-saas. Resume-aware detect-state determina dónde arrancar.

### Edge: sub-agent reporta success pero detect-state Fase 0 dice complete=false

→ Inconsistencia. Probable bug en detect-state (paths canónicos no matchean) o sub-agent reportó success prematuramente. Halt + reportar al usuario para investigación.

### Edge: paso N+1 PREFLIGHT falla post-success de paso N

→ Halt + reportar al usuario. Probable indicador de bug en propagación de context_acumulado. NO bypass del PREFLIGHT del sub-skill.

### Edge: usuario aborta mid-pipeline (paso 1 success, paso 2 sin arrancar)

→ Pipeline parcial guardado. Reportar estado: "1/3 completado. Re-invocá init-saas para resumir desde paso 2 cuando estés listo."

### Edge: paso 3 add-login espera baas decision pero baas skill no fue invocado previamente

→ Sub-agent reporta `paused` con `pause_resolution`: "add-login default Supabase con `assumed_default = true`. Si querés Insforge, abortá + corré /baas + re-invocá init-saas." NO halt forzado — fallback Supabase es path canónico.

### Edge: brand.json válido pero archetype = "test" (placeholder de Discovery FRESH no completado)

→ ui_kit.complete = false aún si brand.json existe. Discovery interrumpida es estado parcial. Re-ejecutar paso 1.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — init-saas thin, sub-agents invocan.
- [memory:CONSTRAINTS.md#R5] — sub-agents no escriben memory.
- [memory:lessons#L-004] — binary D-019 informativo.
- [memory:decisions#D-019] — init-saas binary mode.
- [memory:decisions#D-020] — PAUSE-interno-delegado distinción (referenciable cross-wizards).

## Refusals

- ❌ init-saas MISMA invoca add-ui-kit/impeccable/add-login (R4 violation).
- ❌ Sub-agents escriben memory (R5).
- ❌ Continuar paso N+1 si paso N falló (forced sequencing).
- ❌ Saltar confirmation entre pasos (silent procession).
- ❌ Override de decisiones cross-pasos (no contradicción).
- ❌ Escalar PAUSE-interno-delegado al nivel wizard (D-020 violation).
- ❌ Bypass de PREFLIGHT de sub-skills.
