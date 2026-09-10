# handoff-evaluador

> Handoff post-orchestration mandatory a `el-evaluador`. Sin este handoff, el feature NO se marca passing. el-evaluador corre R7 three-layer + memory promotion + ADR audit. la-forja MISMA no firma — el-evaluador es independent (AP3).

## Cuándo aplica

**Siempre.** Pattern Coordinator, Fork o Swarm — todos hacen handoff a el-evaluador post-orchestration. Sin excepción.

## Pre-handoff — la-forja recolecta outputs

Antes de invocar el handoff, la-forja MISMA agrupa los outputs de los sub-agents en un sumario estructurado:

```yaml
orchestration_summary:
  pattern: coordinator | fork | swarm
  active_feature: <F?-S?>
  blueprint: .claude/PRPs/BLUEPRINT-<nombre>.md

  sub_agents_outputs:
    # Por sub-agent / fase / worktree
    - id: sandbox-1-literal
      branch: la-forja/sandbox-1-literal
      commits: [abc123, def456, ...]
      modified_paths: [...]
      test_run: "npm run test:e2e:auth — PASS"
      resumen_md: ".worktrees/sandbox-1/RESUMEN.md"
      problems_md: null   # si null, no problemas reportados
    - id: sandbox-2-creativo
      ...

  cherry_pick_applied:
    # Solo Fork — post-confirmation humana
    - commit: abc123
      from: sandbox-1-literal
      conflicts: []
    ...

  proposed_memory_entries:
    - type: lesson | error | decision
      proposed_id: L-NNN | E-NNN | D-NNN
      body: |
        Texto de la lesson/error/decision para que el-evaluador audit + record
    ...

  open_questions:
    - "¿Disruptivo approach mejor en lib/auth/proxy pero rompe coherencia con add-payments?"
    ...
```

## Handoff invocation

la-forja NO invoca el-evaluador directamente (R4). Dispatcha un sub-agent con tool filter Reviewer:

```
[Sub-agent dispatched by la-forja]
  Role: Reviewer (post-orchestration)
  Tool filter:
    - Read · Grep
    - Skill: el-evaluador
  System prompt:
    "Sos el reviewer post-orchestration. Recibís el orchestration_summary
     adjunto. Invocá el-evaluador con el summary + cita la-forja handoff.
     el-evaluador correrá R7 three-layer (Syntax → Runtime → System) y
     auditará proposed_memory_entries. Reportá output a la-forja."
```

## R7 three-layer (responsabilidad de el-evaluador)

> [memory:CONSTRAINTS.md#R7] — Three-Layer Verification, no skip.

el-evaluador corre:

| Layer | Comando | Pass criteria |
|-------|---------|---------------|
| 1. Syntax | `make typecheck && make lint` | exit 0 |
| 2. Runtime | `make test` | exit 0 |
| 3. System | `make e2e` (visual diff vs brand.json si UI) | exit 0 + zero anti-slop |

la-forja NO valida — eso es AP3 (self-eval). el-evaluador es independent.

## Memory promotion

el-evaluador audita `proposed_memory_entries` del orchestration_summary:

- Si lesson recurre cross-skill → promueve a `.claude/memory/lessons.md`.
- Si error recurre >2 ocurrencias → promueve a regla en `CONSTRAINTS.md` o lesson.
- Si decision arquitectural → promueve a `.claude/memory/decisions.md` como ADR D-NNN.
- Si cita externa útil → promueve a `.claude/memory/references.md`.

R5 enforcement: SOLO el-evaluador escribe a `.claude/memory/*.md`. la-forja propaga propuestas, el-evaluador decide y escribe.

## Output canónico del handoff

el-evaluador devuelve a la-forja:

```yaml
evaluator_verdict:
  status: PASS | NEEDS_FIX
  layer_1_syntax: PASS | FAIL <details>
  layer_2_runtime: PASS | FAIL <details>
  layer_3_system: PASS | FAIL <details>
  anti_slop_gate: PASS | FAIL <details>  # solo si UI involucrada (R10)
  
  memory_actions:
    - lesson_recorded: L-NNN — "..."
    - error_captured: E-NNN — "..."
    - decision_recorded: D-NNN — "..."
    - reference_promoted: R-NNN — "..."
  
  feature_state_update:
    state: passing | needs_fix
    evidence: "<text para feature_list.json>"
    commit: "<sha del feat o evaluator commit>"
```

## Si NEEDS_FIX

la-forja NO marca feature passing. Opciones:

1. **Re-orchestrate con gap específico:** la-forja toma el gap reportado por el-evaluador y lanza una mini-Swarm (Researcher + Implementer + Reviewer) para fixear ese gap específico. Luego re-handoff a el-evaluador.
2. **Halt + reportar al humano:** si el gap es estructural (Blueprint mal pensado, scope incorrecto), halt + reportar para refactor de Blueprint o degradación.

NUNCA: ignorar NEEDS_FIX y marcar passing por consenso de workers (AP3 anti-pattern).

## Si PASS

la-forja:

1. Recibe el evidence + commit sha de el-evaluador.
2. Actualiza `feature_list.json` con state passing + evidence + commit.
3. (R5: feature_list.json NO es memory store — la-forja MISMA puede actualizar el state machine, eso es state, no memory. Verificar diff con [memory:CONSTRAINTS.md#R5] — sí, R5 cubre `.claude/memory/*.md` solamente; feature_list.json es state, no memory.)
4. Si la-forja orquestó full pipeline → handoff a el-guardian (`prompts/handoff-guardian.md`).
5. Si solo build → handoff queda al humano para invocar `/despachar` (que internamente llama el-guardian).

## R4/R5/R6 enforcement

- R4: la-forja MISMA dispatcha sub-agent Reviewer; el sub-agent invoca el-evaluador. la-forja NO invoca el-evaluador directo.
- R5: workers durante orchestration no escribieron memory; el-evaluador es el ÚNICO writer post-handoff.
- R6: el sub-agent Reviewer valida que el-evaluador existe en skills.md antes de invocar (defensive double-check).

## Edge cases

### Edge: el-evaluador retorna PASS pero la-forja detecta inconsistencia (ej: dos worktrees declararon misma decisión arquitectural distinta)

→ la-forja reporta al humano: "el-evaluador PASS, pero detecté inconsistencia X entre worktrees A y B. ¿Aceptar PASS, o re-validar con focus específico?". Conservador, NO la-forja overrida el-evaluador silenciosamente.

### Edge: Re-orchestrate ciclo mayor a 2 NEEDS_FIX consecutivos

→ Halt forzado. Indicador de problema estructural — Blueprint mal pensado o scope incorrecto. Reportar al humano + opciones: refactor Blueprint con la-herreria o degradar a el-yunque manual.

### Edge: el-evaluador reporta gap en memory_entries propuestos (decisión NO es ADR-worthy)

→ la-forja acepta la decisión de el-evaluador. el-evaluador es la autoridad sobre qué se promueve a memory.

### Edge: la-forja orquestó Fork con N=3, dos PASS, uno descartado

→ Handoff a el-evaluador con summary que documenta los 3 worktrees + cherry-pick aplicado solo de los 2 PASS. el-evaluador valida el merged result, no los worktrees individuales.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO invoca el-evaluador directo, solo dispatcha sub-agent.
- [memory:CONSTRAINTS.md#R5] — el-evaluador es el ÚNICO writer de memory; workers no escriben.
- [memory:CONSTRAINTS.md#R6] — sub-agent Reviewer valida el-evaluador en skills.md antes.
- [memory:CONSTRAINTS.md#R7] — three-layer verification mandatory.
- [memory:CONSTRAINTS.md#AP3] — self-eval prohibido (Reviewer es independent).

## Refusals

- ❌ la-forja MISMA invoca el-evaluador (R4 — solo via sub-agent).
- ❌ Marcar feature passing sin output PASS de el-evaluador (R7 + AP3).
- ❌ Skip de R7 layers (no shortcuts — aún en hotfix las 3 layers corren).
- ❌ la-forja MISMA escribe a `.claude/memory/*.md` (R5 — solo el-evaluador).
- ❌ Override de el-evaluador NEEDS_FIX por consensus de workers (AP3 anti-pattern).
- ❌ Re-orchestrate >2 NEEDS_FIX sin halt + report (loop infinito anti-pattern).
