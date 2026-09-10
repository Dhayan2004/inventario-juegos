# run-step

> Fase 1 de add-mobile-stack. Protocolo genérico para ejecutar UN paso del pipeline (1 de 4). Cada paso delega a sub-agent que invoca el skill apropiado. R4/R5 enforced. Contexto acumulado se propaga cross-pasos.

## Inputs

```yaml
step:
  number: 1 | 2 | 3 | 4
  name: ui-kit | components | auth | mobile
  skill_to_invoke: add-ui-kit | impeccable | add-login | add-mobile

context_acumulado:
  project_root: <path>
  brand_json_path: <path or null>
  voice_json_path: <path or null>
  brand_css_path: <path or null>
  component_rules_path: <path or null>
  baas_decision: <supabase | insforge | null>
  auth_feature_path: <path or null>           # paso 3 lo crea, paso 4 lo consume
```

## Output

```yaml
step_result:
  step_name: ui-kit | components | auth | mobile
  outcome: success | failed | paused

  # si success
  outputs_generated:
    - <paths creados/modificados>
  output_summary:
    key_data: <ej: "manifest.theme_color: #0066ff (derivado de brand.json)">
    rationale: <1-2 frases sobre decisiones tomadas>
  next_step_context:
    propagate:
      - <variables que paso N+1 debe heredar>

  # si failed
  fail_reason: <texto>
  fail_in_skill: <nombre del skill>
  resume_instruction: <ej: "Configurá VAPID keys en .env.local. Re-invocá add-mobile-stack.">

  # si paused (sub-skill espera input)
  pause_reason: <texto>
  pause_resolution: <ej: "Documentá baas decision o esperá baas skill">

  user_decision_post_step: continue | pause | abort
```

## Protocolo por paso (6 sub-steps)

### Step 1 — Anunciar el paso

```markdown
━━━ Paso {N}/4: {step_name} ━━━

**Skill a invocar:** {skill_to_invoke}
**Qué produce:** {output esperado}
**Dependencias:** {docs previos del pipeline necesarios}
**Tiempo estimado:** ~{N}min
```

### Step 2 — Validar precondiciones

| Step | Precondiciones |
|------|----------------|
| 1 (ui-kit) | AGENTS.md + Next.js (ya validado en PREFLIGHT) |
| 2 (components) | `brand_json_path` + `voice_json_path` + `brand_css_path` no-null |
| 3 (auth) | `brand_json_path` + `component_rules_path` no-null + `baas_decision` documentada o fallback Supabase |
| 4 (mobile) | `brand_json_path` (manifest theme_color) + `auth_feature_path` (push_subscriptions tied to user_id) + `.env.local` writable (VAPID keys) |

Si precondiciones fallan → halt + reportar gap.

### Step 3 — Dispatch sub-agent

R4 enforced: add-mobile-stack MISMA NO invoca el skill. Dispatcha sub-agent:

```
[Sub-agent dispatched by add-mobile-stack]
  Role: Pipeline executor (paso {N})
  Tool filter:
    - Read · Edit · Write · Grep · Glob (full-stack dentro del project_root)
    - Bash: typecheck + tests + git
    - Skill: {skill_to_invoke}
  System prompt:
    "Sos el pipeline executor para paso {N} (add-mobile-stack wizard). Invocá
     {skill_to_invoke} con context: {context_acumulado_yaml}. Output va a
     {paths_canonicos_del_step}. NO escribas a .claude/memory/* (R5).
     Reportá step_result a add-mobile-stack con outputs_generated + key_data."
```

### Step 4 — Sub-agent ejecuta el skill

Sub-agent:
1. Invoca `{skill_to_invoke}` con context.
2. Skill ejecuta su flow normal (Discovery FRESH si add-ui-kit, BATCH si impeccable, Mode A si add-login, PWA default si add-mobile).
3. **PAUSE-interno-delegado distinción (D-020 doctrine — heredada):** Si el skill internamente tiene PAUSE genuino (ej: add-mobile encuentra que el usuario quiere Native shell pero no tiene Capacitor configurado), el PAUSE es **interno al skill** — el wizard NO lo escala como PAUSE-wizard. add-mobile-stack reporta "PAUSE-interno-delegado del paso N" al usuario, halt graceful, y permite que el usuario resuelva el sub-skill manualmente.
4. R4 strict: add-mobile-stack MISMA NO escribe código. Sub-agent es quien Edit/Write.
5. Sub-agent reporta `step_result` a add-mobile-stack al terminar.

### Step 5 — Confirmar output al usuario

```
✅ Paso {N}/4 completado → {paths_creados}
Dato clave: {key_data}
Rationale: {1-2 frases sobre decisiones}

Siguiente: Paso {N+1} ({step_name_next}) — ¿continuamos?
  - sí | continue → proceder a paso N+1
  - pause          → cerrar wizard, retomar después con resume-aware
  - abort          → cancelar pipeline
```

### Step 6 — Halt + handoff si paso falla

```
❌ Paso {N} falló durante ejecución de {skill_to_invoke}.
Razón: {fail_reason}
Fail location: {fail_in_skill}
Próximo paso: {resume_instruction}

Cuando resolvás, re-invocá add-mobile-stack — resume-aware detecta el
progreso parcial y arranca desde paso {N} o {N+1} según corresponda.
```

## Context propagation cross-pasos

Cada paso recibe outputs de pasos previos como input estructurado:

| De → Hacia | Variables propagadas |
|------------|---------------------|
| Paso 1 → Paso 2 | `brand_json_path`, `voice_json_path`, `brand_css_path` |
| Paso 2 → Paso 3 | + `component_rules_path` |
| Paso 3 → Paso 4 | + `auth_feature_path`, `baas_decision` (consumida o fallback Supabase) |

NO re-preguntar interview decisions. NO re-leer interview context si ya se tiene.

## Edge cases

### Edge 1 — Sub-agent retorna outcome distinto a success/failed/paused
- Tratar como failed con fail_reason="unexpected outcome from sub-agent".
- Halt + reportar bug a el-evaluador post-pipeline.

### Edge 2 — Usuario interrumpe entre pasos
- add-mobile-stack persiste estado mínimo (último paso completado en feature_list.json comment).
- Re-invocación retoma vía detect-state.md.

### Edge 3 — Paso sucess pero outputs incompletos
- Validación post-step: `outputs_generated` no-empty + paths existen en disco.
- Si validación falla → re-clasificar como `failed`.

### Edge 4 — Sub-agent intenta escribir a .claude/memory/*
- R5 violation. Halt + reportar a el-evaluador. NO permitir.

## R4/R5 enforcement explícito

### R4 — Orchestrator stays thin
- add-mobile-stack MISMA NO invoca add-ui-kit/impeccable/add-login/add-mobile directo.
- Solo dispatch a sub-agents. Sub-agents son quienes invocan los skills.
- add-mobile-stack lee state files (Read, Grep, Glob), sintetiza, dispatcha. NO Edit/Write a código.

### R5 — Workers no escriben memory
- Sub-agents NO tienen Write a `.claude/memory/*.md`.
- Si emerge lesson/error/decision durante un paso → reportar a add-mobile-stack en step_result.proposed_memory_entries.
- add-mobile-stack propaga al handoff de el-evaluador post-pipeline.
- el-evaluador post-pipeline registra (R5 sole writer).

## Citation

[memory:CONSTRAINTS.md#R4] (orchestrator thin), [memory:CONSTRAINTS.md#R5] (workers no memory), [memory:decisions#D-021] (binary shape), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine), [memory:decisions#D-012] (add-mobile binary interno).
