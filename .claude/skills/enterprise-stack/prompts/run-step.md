# run-step

> Fase 1 de enterprise-stack. Protocolo genérico para ejecutar UN wizard hijo del pipeline (1 de 3). Cada wizard se delega a sub-agent que invoca el wizard hijo. R4/R5/R6 enforced. Contexto acumulado se propaga cross-wizards.

## Inputs

```yaml
wizard:
  number: 1 | 2 | 3
  name: init-saas | add-monetization | add-mobile-stack

context_acumulado:
  project_root: <path>
  baas_decision: <supabase | insforge | null>
  brand_json_exists: bool                      # post-init-saas wizard
  components_exists: bool                       # post-init-saas wizard
  auth_feature_path: <path or null>
  custom_skip: [<list of wizards skipped si CUSTOM mode>]
```

## Output

```yaml
wizard_result:
  wizard_name: init-saas | add-monetization | add-mobile-stack
  outcome: success | failed | paused | skipped

  # si success
  outputs_generated:
    - <paths creados/modificados por el wizard hijo>
  output_summary:
    key_data: <ej: "BaaS: Supabase, Archetype: Sage+Creator, Auth: 4 pages">
    rationale: <1-2 frases>
  next_wizard_context:
    propagate:
      - <variables a heredar>

  # si failed
  fail_reason: <texto>
  fail_in_wizard: <init-saas | add-monetization | add-mobile-stack>
  fail_in_sub_skill: <nombre del skill que falló dentro del wizard>
  resume_instruction: <ej: "Resolvé add-payments configuración. Re-invocá enterprise-stack.">

  # si paused (sub-wizard PAUSE-interno-delegado D-020)
  pause_reason: <texto>
  pause_in_sub_skill: <nombre del skill que pausó>
  pause_resolution: <ej: "Documentá BaaS decision o configurá Stripe API keys">

  # si skipped (CUSTOM mode override del usuario)
  skipped_reason: <texto>

  user_decision_post_wizard: continue | pause | abort
```

## Protocolo por wizard (6 sub-steps)

### Step 1 — Anunciar el wizard

```markdown
━━━ Wizard {N}/3: {wizard_name} ━━━

**Wizard a invocar:** {wizard_name}
**Skills internos que invoca:** {lista de skills hijos del wizard}
**Qué produce:** {output esperado del wizard completo}
**Tiempo estimado:** ~{N}min
```

### Step 2 — R6 validation pre-dispatch

```bash
# Validar wizard en skills.md (CRÍTICO — R6)
grep -E "^### {wizard_name}\b" .claude/memory/skills.md
```

Si NO existe → halt: "wizard {wizard_name} no en skills.md (R6 violation). Re-instalar Forja."

Esto debería estar ya validado en PREFLIGHT, pero double-check antes de cada dispatch (defensivo).

### Step 3 — Validar precondiciones

| Wizard | Precondiciones |
|--------|----------------|
| 1 (init-saas) | AGENTS.md + Next.js (ya validado en PREFLIGHT) |
| 2 (add-monetization) | init-saas DONE (brand.json + auth/ existen) |
| 3 (add-mobile-stack) | init-saas DONE (auth/ necesario para push_subscriptions tied to user_id) |

Si precondiciones fallan → halt + reportar gap.

**NOTA:** add-mobile-stack tiene su propia detección interna que cubre init-saas (ya que es superset). Si el usuario invoca enterprise-stack en CUSTOM mode `skip init-saas + only add-mobile-stack`, add-mobile-stack lo cubre. enterprise-stack NO debe re-validar — el sub-wizard maneja.

### Step 4 — Dispatch sub-agent

R4 enforced: enterprise-stack MISMA NO invoca el wizard. Dispatcha sub-agent:

```
[Sub-agent dispatched by enterprise-stack]
  Role: Wizard executor (wizard {N})
  Tool filter:
    - Read · Edit · Write · Grep · Glob (full-stack dentro del project_root)
    - Bash: typecheck + tests + git
    - Skill: {wizard_name}  (que a su vez invoca skills hijos)
  System prompt:
    "Sos el wizard executor para wizard {N} (enterprise-stack). Invocá
     {wizard_name} con context: {context_acumulado_yaml}. {wizard_name}
     ejecuta su flow normal (PREFLIGHT + Fase 0 detect-state + Fase 1
     run-step). NO escribas a .claude/memory/* (R5). Reportá
     wizard_result a enterprise-stack al terminar."
```

### Step 5 — Sub-agent ejecuta el wizard hijo

Sub-agent:
1. Invoca `{wizard_name}` con context.
2. **El wizard hijo ejecuta su propio flow:** init-saas / add-monetization / add-mobile-stack tienen su PREFLIGHT, Fase 0 detect-state (resume-aware), Fase 1 run-step (3 o 4 sub-pasos según el wizard).
3. **PAUSE-interno-delegado distinción (D-020 doctrine):** si el wizard hijo encuentra PAUSE genuino dentro de uno de sus skills (ej: add-monetization → add-payments → PAUSE-on-prem D-010), el wizard hijo reporta PAUSE-interno-delegado al enterprise-stack. enterprise-stack reporta al usuario halt graceful, NO escala como PAUSE-wizard. NO bloquea para wizards N+1 en pasos futuros — el usuario resuelve el sub-skill problemático y re-invoca enterprise-stack para retomar.
4. R4 strict: enterprise-stack MISMA NO escribe código. Sub-agent + sub-wizard + sub-skills son quienes Edit/Write.
5. Sub-agent reporta `wizard_result` a enterprise-stack al terminar.

### Step 6 — Confirmar output al usuario

```
✅ Wizard {N}/3 completado → {wizard_name}
Outputs principales: {paths_creados resumen}
Dato clave: {key_data — ej: "BaaS Supabase, archetype Sage+Creator"}

Siguiente: Wizard {N+1} ({wizard_name_next}) — ¿continuamos?
  - sí | continue → proceder a wizard N+1
  - pause          → cerrar enterprise-stack, retomar después con resume-aware
  - abort          → cancelar pipeline
```

### Step 6.1 — Halt + handoff si wizard hijo falla

```
❌ Wizard {N} falló: {wizard_name}.
Razón: {fail_reason}
Fail location: {fail_in_wizard} → {fail_in_sub_skill}
Próximo paso: {resume_instruction}

Cuando resolvás, re-invocá enterprise-stack — resume-aware detecta
el progreso parcial y arranca desde wizard {N} o {N+1}.
```

### Step 6.2 — PAUSE-interno-delegado (D-020 doctrine heredada)

Si wizard hijo reporta PAUSE-interno (ej: add-monetization → add-payments → PAUSE-on-prem):

```
⏸️ Wizard {N} ({wizard_name}) PAUSE-interno-delegado.
Razón: {pause_reason}
Sub-skill que pausó: {pause_in_sub_skill} (D-010 / D-011 ADR aplicable)
Próximo paso: {pause_resolution}

D-020 doctrine: PAUSE-interno-delegado NO escala como PAUSE-wizard.
Cuando resolvás el sub-skill, re-invocá enterprise-stack para continuar.
```

### Step 6.3 — Skipped (CUSTOM mode)

Si el wizard fue skipeado por elección del usuario:

```
⏭️ Wizard {N} ({wizard_name}) skipeado por CUSTOM mode override.
Razón: {skipped_reason}
Continuamos a wizard {N+1}.
```

## Context propagation cross-wizards

Cada wizard recibe outputs de wizards previos:

| De → Hacia | Variables propagadas |
|------------|---------------------|
| Wizard 1 (init-saas) → Wizard 2 (add-monetization) | `brand_json_exists=true`, `components_exists=true`, `auth_feature_path`, `baas_decision` (Supabase/Insforge según D-009) |
| Wizard 1 (init-saas) → Wizard 3 (add-mobile-stack) | mismo + ya cubre los 3 primeros pasos del wizard 3 (resume-aware interno de add-mobile-stack los skipea) |
| Wizard 2 (add-monetization) → Wizard 3 (add-mobile-stack) | independientes — add-mobile-stack solo necesita init-saas DONE, no add-monetization |

**NO contradecir cross-wizards.** Si Wizard 1 estableció `baas_decision = supabase`, Wizard 2 debe usar Supabase (no Insforge). Halt + reportar si emerge inconsistencia.

## R4/R5/R6 enforcement explícito

### R4 — Orchestrator stays thin

- enterprise-stack MISMA NO invoca init-saas/add-monetization/add-mobile-stack directo.
- Solo dispatch a sub-agents. Sub-agents son quienes invocan los wizards hijos.
- enterprise-stack lee state files (Read, Grep, Glob), sintetiza, dispatcha. NO Edit/Write.

### R5 — Workers no escriben memory

- Sub-agents NO tienen Write a `.claude/memory/*.md`.
- Si emerge lesson/error/decision durante un wizard hijo → reportar a enterprise-stack en wizard_result.proposed_memory_entries.
- enterprise-stack propaga al handoff de el-evaluador post-pipeline.
- el-evaluador post-pipeline registra (R5 sole writer).

### R6 — Skills registry validation pre-dispatch

- Validar wizard en skills.md ANTES de dispatch (Step 2 arriba — defensivo, double-check sobre PREFLIGHT).
- Si wizard NO existe en skills.md → halt + reportar.

## Edge cases

### Edge 1 — Sub-agent retorna outcome distinto a success/failed/paused/skipped
- Tratar como failed con fail_reason="unexpected outcome from sub-agent".
- Halt + reportar bug a el-evaluador post-pipeline.

### Edge 2 — Usuario interrumpe entre wizards
- enterprise-stack persiste estado mínimo (último wizard completado).
- Re-invocación retoma vía detect-state.md.

### Edge 3 — Wizard sub-success pero outputs incompletos
- Validación post-wizard: `outputs_generated` no-empty + paths existen en disco.
- Si validación falla → re-clasificar como `failed`.

### Edge 4 — BaaS decision cambia entre wizards
- Wizard 1 eligió Supabase, usuario quiere Insforge en Wizard 2 → halt + reportar inconsistencia.
- NO permitir override silencioso.

## Citation

[memory:CONSTRAINTS.md#R4] (orchestrator thin), [memory:CONSTRAINTS.md#R5] (workers no memory), [memory:CONSTRAINTS.md#R6] (skills.md registry validation), [memory:decisions#D-022] (binary shape wizard de wizards), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine — heredada), [memory:decisions#D-019] (init-saas patrón heredado), [memory:decisions#D-021] (add-mobile-stack patrón heredado).
