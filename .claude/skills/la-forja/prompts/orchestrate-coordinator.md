# orchestrate-coordinator

> Pattern Coordinator — sequential synthesis para sesiones largas con dependencias entre fases. Use case: feature N+1 NO arranca sin output completo de feature N.

## Cuándo se usa

Pattern selector decidió Coordinator porque:

- Blueprint tiene dependencias secuenciales fuertes (fase N+1 consume output de fase N).
- O Fork no es viable (disco bajo, conflictos circulares persistentes, target sin git worktree).
- O el usuario explícitamente pidió "modo coordinator", "secuencial", "una fase a la vez".

NO usar Coordinator si las features son independientes — Fork es default para paralelización.

## Inputs

- `.claude/PRPs/BLUEPRINT-<nombre>.md` con fases ordenadas.
- `feature_list.json` con active feature.
- skills.md registry (R6 validated antes de cada fase dispatch).

## Flow canónico

```
[la-forja] Lee Blueprint
   ↓
[la-forja] Para cada fase N en orden:
   ├── 1. Validá skills citados en fase N contra skills.md (R6)
   ├── 2. Dispatch sub-agent para fase N (sub-agent invoca el skill apropiado)
   ├── 3. Sub-agent reporta output a la-forja
   ├── 4. la-forja sintetiza output:
   │      - ¿Output coherente con Blueprint?
   │      - ¿Output cumple criterios de éxito de la fase?
   │      - ¿Output produce input válido para fase N+1?
   ├── 5. Si synthesis falla → halt + reportar al humano antes de avanzar
   └── 6. Si OK → fase N+1 con synthesis acumulada como contexto
   ↓
[la-forja] Handoff final a el-evaluador (post-orchestration)
```

## R4 enforcement

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

la-forja MISMA en pattern Coordinator:
- Lee (Read, Grep, Glob) el Blueprint y outputs intermedios de sub-agents.
- Valida (lectura skills.md) registry pre-dispatch.
- Sintetiza (texto, no código de aplicación) entre fases.
- NO invoca skills directo. Sub-agents son los que invocan.

Si te ves haciendo Edit/Write a archivos de aplicación dentro de orchestrate-coordinator → R4 violation, refactor a sub-agent.

## R5 enforcement

> [memory:CONSTRAINTS.md#R5] — Workers no escriben a memory.

Sub-agents en pattern Coordinator NO tienen Write a `.claude/memory/*.md`. Si una fase emerge una lesson/error/decision para registrar:

- Sub-agent reporta a la-forja como parte del output.
- la-forja propaga al handoff final de el-evaluador con shape `proposed_memory_entry: {type, body}`.
- el-evaluador post-orchestration es quien hace el record (R5 sole writer).

## R6 enforcement

> [memory:CONSTRAINTS.md#R6] — Skill dispatch validates registry.

Antes de cada fase dispatch:

```
1. Lee .claude/memory/skills.md
2. Buscá skill que la fase invoca (ej: add-login, impeccable, ai)
3. Si no existe → halt: "Skill <nombre> no registrado. Audita skills.md."
4. Si existe → validá `requires` cumplidos en el repo target
5. Si requires fallan → halt con fallback message
6. Dispatch
```

R6 corre por cada fase, no una sola vez al inicio. Una fase puede pasar y la siguiente fallar si el repo cambió entre dispatch.

## Synthesis entre fases

la-forja sintetiza output de fase N para alimentar fase N+1:

```yaml
fase_n_synthesis:
  output_archivos: [paths modified]
  output_decisions: [choices made by sub-agent]
  output_open_questions: [things sub-agent left for next phase]
  output_artifacts: [generated files, schemas, etc.]

context_for_fase_n_plus_1:
  inputs: <subset relevante del synthesis>
  constraints: <derivadas del output: ej "no romper schema X declarado en fase N">
  open_questions_to_resolve: <lo que la fase actual debe responder>
```

la-forja MISMA produce este synthesis (es texto + lectura, no código de aplicación — coherente con R4). El sub-agent de la fase N+1 recibe el synthesis como parte de su prompt.

## Halt conditions

Coordinator halt-blocked en:

- Skills.md dispatch falla (R6).
- Fase N output NO produce input válido para fase N+1 (synthesis check fails).
- Sub-agent reporta error irrecuperable.
- Disco bajo o resource exhaustion durante una fase.
- Usuario interrumpe explícitamente.

Halt → reportar al humano con shape:

```
**Halt en fase N (de M):**
- Razón: <explícita>
- Output parcial: [paths con WIP]
- Próximo paso sugerido: <reanudar | abortar | degradar a el-yunque manual>
```

NO continuar fase N+1 silenciosamente si la N falló — eso es divergence anti-pattern.

## Edge cases

### Edge: Fase N produce 2 outputs alternativos (sub-agent ofreció choice)

→ la-forja synthesis pide UNA pregunta al humano: "Fase N produjo A y B. Para fase N+1, ¿cuál input usás?". NO la-forja decide solo si el sub-agent explícitamente ofreció choice — el humano es la autoridad.

### Edge: Fase N+1 require dato de fase N-2 (no fase inmediata anterior)

→ Coordinator mantiene synthesis acumulada de TODAS las fases previas, no solo fase inmediata. Sub-agent de fase N+1 recibe contexto completo.

### Edge: Fase N falla, fase N+1 era independiente

→ Si Coordinator era forced (Fork no viable), reportar al humano: "Fase N falló pero N+1 es independiente. ¿Saltar N y proceder con N+1, o halt completo?". Default conservador: halt completo, dejar al humano decidir. NO la-forja salta fases sin confirmation.

### Edge: Synthesis es muy denso (Blueprint con 8+ fases)

→ Coordinator pattern empieza a degradar (cognitive load alto, synthesis se vuelve unwieldy). Reportar al humano: "Blueprint tiene N fases con synthesis denso. ¿Considerás dividir el Blueprint o aceptás cognitive cost?". No halt automático, solo warning.

## Output handoff (post-orchestration)

```markdown
## la-forja Coordinator handoff

**Pattern:** Coordinator (sequential synthesis)
**Active feature:** <F?-S?>
**Fases completadas:** N de M

**Synthesis acumulada:**
- Fase 1 → output X (paths: [...])
- Fase 2 → output Y consumiendo X (paths: [...])
- ...
- Fase N → output Z

**Memory entries propuestas (para el-evaluador):**
- [proposed_lesson] L-NNN — ...
- [proposed_error] E-NNN — ...

**Handoff next:**
- el-evaluador (mandatory) → R7 three-layer + memory record
- el-guardian (si full pipeline) → pre-deploy audit
```

## Citation grammar

- [memory:CONSTRAINTS.md#R4] verbatim en este prompt — la-forja MISMA NO invoca skills.
- [memory:CONSTRAINTS.md#R5] verbatim — workers no escriben memory.
- [memory:CONSTRAINTS.md#R6] verbatim — registry validation por fase.
- [memory:CONSTRAINTS.md#R7] — three-layer post-orchestration mandatory.
- [memory:lessons#L-004] — binary pattern selector confirmado.
- [memory:decisions#D-013] — la-forja sexta validación L-004 cross-skill.

## Refusals

- ❌ Saltar synthesis entre fases — es la razón de existir del Coordinator. Sin synthesis, sería sequential dispatch dumb (peor que Fork).
- ❌ Avanzar fase N+1 sin validar fase N output — silent divergence anti-pattern.
- ❌ Sub-agent escribe a memory — R5 violation. Solo el-evaluador post-orchestration.
- ❌ la-forja MISMA escribe código de aplicación — R4 violation, eso es trabajo de sub-agent.
