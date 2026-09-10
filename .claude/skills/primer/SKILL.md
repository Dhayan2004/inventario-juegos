---
name: primer
description: >
  Lightweight context loader (<30s) para PROYECTOS TARGET generados con Forja.
  Lee secuencia óptima de archivos canónicos (AGENTS.md → feature_list.json
  → PROGRESS.md → brand.json → decisions.md → git log/status → README) y
  retorna resumen estructurado de 5 elementos: proyecto + estado actual,
  active feature, última actividad reciente, brand snapshot, próxima acción
  sugerida. Output: ~150-300 palabras. NO genera código. NO templates folder.
  Casos de uso: sesión nueva en proyecto target (warm cache para que el
  agente arranque productivo), cross-session continuity, onboarding humano,
  retake post-pause largo. NO es la-forja (orchestrator) ni la-herreria
  (planning) ni session_kickoff (que es para Forja factory mismo) — es para
  proyectos GENERADOS con Forja.
tier: core (lightweight)
requires: directorio target con al menos AGENTS.md raíz. feature_list.json + brand/brand.json + .claude/memory/decisions.md son ideales pero opcionales — primer degrada graceful si faltan.
fallback: Si AGENTS.md no existe → modo cold-start (lee README + estructura). Si feature_list.json no existe → omite "active feature" y reporta "feature_list missing — corré /forge-check para diagnosticar". Si brand/brand.json no existe → omite brand snapshot y reporta "Brand DNA pending — corré /add-ui-kit". Si .claude/memory/decisions.md vacío → reporta "0 ADRs — proyecto fresh".
dependencies: []
---

# primer

> *"Cinco minutos de explicación se vuelven treinta segundos de contexto. Esa es la diferencia entre un agente productivo y uno que pregunta lo obvio."*

Skill prompt-only. Carga el contexto del proyecto target en <30s leyendo archivos canónicos en orden óptimo, y produce resumen estructurado de 5 elementos para que cualquier agente (humano o Claude) arranque productivo sin tener que leer toda la doc cold.

**No genera código.** No tiene `templates/` folder. No requiere `find-docs`. No aplica R10 (no genera UI), R14 (no agentic tools destructivas), `el-guardian` handoff (no toca secrets).

## PREFLIGHT — graceful degradation (no halt)

```
1. ¿Existe AGENTS.md en raíz del proyecto target?
   - Sí → arranca lectura canónica
   - No → modo cold-start (README + estructura básica), reporta "AGENTS.md missing — proyecto no inicializado con Forja"

2. ¿Existe feature_list.json?
   - Sí → extrae active feature
   - No → omite "active feature" en resumen, reporta gap

3. ¿Existe brand/brand.json?
   - Sí → extrae archetype + posture summary
   - No → omite brand snapshot, sugiere /add-ui-kit

4. ¿Existe .claude/memory/decisions.md?
   - Sí → cuenta ADRs (informativo)
   - No → reporta "0 ADRs"

5. ¿git status accesible?
   - Sí → extrae branch + 5 últimos commits + working tree state
   - No → omite (proyecto sin git inicializado)
```

`primer` NO halt. Siempre retorna SOMETHING — degrada graceful con gaps explícitos.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Inicio de sesión nueva en proyecto target | Coordinator / agente / humano |
| El agente no tiene contexto del proyecto | Coordinator |
| Usuario dice "qué tenemos", "dónde estamos", "dame contexto", "resumime el proyecto" | Coordinator |
| Cross-session continuity post-pause largo | Agente |
| Onboarding de developer humano nuevo | Humano |
| Pre-`la-herreria` o pre-`/build` para confirmar estado | Coordinator |

NO se invoca para tareas de implementación — esas van a `la-forja`, `el-tajo`, `el-golpe`. `primer` solo carga contexto.

## Loop de ejecución (~30s total)

```
1. Leer AGENTS.md (~3s)
2. Leer .forja/HANDOFF.md si existe (~2s) — handoff de la sesión anterior (F-P5.1, /handoff
   o hook PreCompact): tiene la "Siguiente acción" exacta; si está fresco, pesa más que inferir
3. Leer feature_list.json (~2s)
4. Leer PROGRESS.md (~3s)
5. Leer brand/brand.json (~3s)
6. Leer .claude/memory/decisions.md (sólo el último ADR + count) (~3s)
7. git log --oneline -5 + git status --short (~3s)
8. Leer README.md SOLO si tiene info no replicada en AGENTS (~3s)
9. Formatear output según prompts/format-output.md (~5s)

Total: ~25s típico, <30s en proyectos saludables.
```

Si algún archivo falta → skip (graceful) y continúa. NO retry. NO timeout (los reads son locales).

## Output shape (5 elementos canónicos)

Detalle completo en [`prompts/format-output.md`](prompts/format-output.md). Resumen:

```markdown
# <Project Name>

**Forja state:** <fase actual> · <last update date> · <git branch>

## Active feature
**ID:** <F3-S?> · **State:** <active|passing|blocked>
<behavior summary 1-2 lines>
**Verification:** <command>
**Branch:** <feature/...>

## Última actividad
<5 commits oneline>
**Working tree:** <clean | N modified | N untracked>

## Brand snapshot
**Archetype:** <primary> + <secondary>
**Posture:** density=<n> · expression=<n> · geometry=<n> · warmth=<n> · editoriality=<n> · materiality=<n>
**Visual reference:** <ej: Linear/Vercel family | Editorial Monocle | Brutalist>

## Próxima acción sugerida
<accionable, NO genérica — basada en estado real>
```

Si falta info, el output muestra `(missing)` o sugerencia de skill que la genera.

## Reglas operativas

1. **Output legible para humanos Y para agentes.** Markdown estructurado. NO JSON (eso es feature_list.json — primer es resumen). NO YAML (eso es brand.json — primer es interpretación).
2. **Próxima acción debe ser accionable.** "Continúa el feature F3-S7 con commit X" en lugar de "trabajá en lo que tengas pendiente". Si no hay próxima acción clara, reportar honestamente "Sin pendiente claro — revisar feature_list backlog".
3. **NO inventar info.** Si feature_list.json no tiene active feature, NO inventar uno desde git branch — reportar gap.
4. **NO reemplaza la-herreria.** primer carga contexto. la-herreria planifica. Si el usuario quiere planificar feature nueva, primer reporta el contexto y sugiere `/la-herreria`.
5. **Brand snapshot es informativo, NO contractual.** primer NO valida R10. Solo reporta si el contrato existe + qué archetype es. Validation real corre en cada skill UI-generator (impeccable, add-ui-kit, etc.).
6. **Tiempo budget <30s.** Si las lecturas exceden 30s (proyecto enorme con feature_list.json de 10k features), reportar performance issue + sugerir paginación.
7. **Cita L-004 si aplica.** primer NO usa default+override pattern (no elige entre providers). L-004 NO aplica directo. Pero si en el FUTURO emerge una sub-decisión (ej: ¿reportar 5 vs 10 commits?, ¿incluir branch lookup remoto?), aplicar L-004 test diagnóstico para decidir si binary o trinary.
8. **Forward-compatible con orchestrator wizard (Phase 5+).** primer es invocable por humanos directamente Y por orchestrators que componen cadenas. Output shape es estable.

## Refusals (lo que NUNCA hace)

- ❌ Generar código de aplicación (eso es ai/, add-*, impeccable, etc.).
- ❌ Modificar archivos del proyecto (primer es read-only).
- ❌ Inventar info missing (NO fabricate active feature, NO fabricate brand archetype).
- ❌ Halt si falta archivo opcional. Graceful degradation.
- ❌ Reportar info >30 días stale como si fuera fresca. Si PROGRESS.md no se actualizó hace meses, reportar "stale, last update X días atrás".
- ❌ Editar `brand/**`, `.claude/memory/**`, `feature_list.json`. Read-only.
- ❌ Imitar la-herreria (planning) o la-forja (execution). primer es solo lectura.

## Tool filter

Read · Grep · Glob · Bash (`git log`, `git status`, `git rev-parse`, `git branch`, `head` para snippets).

NO Edit, NO Write — primer es read-only.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | si reporta brand snapshot con cita al schema |
| Lessons | `[memory:lessons#L-004]` | si en el FUTURO una sub-decisión usa default+override pattern |
| Constraint | `[memory:CONSTRAINTS.md#R7]` | informativo si reporta "verification command pending" |

primer NO genera contra libs externas → NO `[docs:*]` cites.

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `la-herreria` | downstream. Después de primer, si el usuario quiere planificar feature nueva, sugerir invocar la-herreria. |
| `la-forja` | downstream. Si active feature está en `passing`, sugerir invocar la-forja para próximo en queue. |
| `el-tajo` / `el-golpe` | downstream. Para microtareas o features medianos. |
| `add-ui-kit` | downstream. Si brand snapshot reporta "Brand DNA pending", sugerir invocar. |
| `el-evaluador` | NOT direct. primer no toca memory store, solo lee. |
| `el-guardian` | NOT direct. primer no toca secrets ni código. |

## Output handoff

```markdown
## primer handoff

**Project:** <name>
**Files read:** N (X seconds total)
**Output length:** ~N words

**Gaps detected:**
- <ej: brand.json missing>
- <ej: feature_list.json no active feature>

**Suggested next steps:**
- <ej: corré /add-ui-kit para inicializar brand>
- <ej: continúa active feature F3-S? con next-step en commit X>

**Context loaded — agent ready.**
```

NO el-guardian handoff. NO el-evaluador post-validation (primer es read-only). Solo handoff a la-herreria / la-forja / etc según próxima acción.

---

*"30 segundos de contexto le ahorran al usuario 5 minutos de explicación. Multiplicado por cada sesión nueva, primer paga su existencia el primer día."*
