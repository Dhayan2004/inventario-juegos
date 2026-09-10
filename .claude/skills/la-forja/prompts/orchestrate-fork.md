# orchestrate-fork (PATTERN PRINCIPAL)

> Pattern Fork — paralelización con git worktrees. **Default de la-forja.** N agentes (2-5) trabajan en worktrees aislados con variantes de personalidad; cherry-pick de la mejor solución cross-worktree.

## Cuándo se usa

Pattern selector decidió Fork porque:

- Blueprint tiene 2-5 features independientes paralelizables.
- O usuario explícitamente pidió "modo forja", "lanzá worktrees", "explorá N approaches".
- O quiere comparar approaches alternativos para una sola feature (literal vs creativo vs disruptivo).

NO usar Fork si:

- N=1 (no aporta paralelización — degradar a Swarm o ejecutar en main).
- N>5 (satura recursos + cherry-pick conflicts super-lineales — reducir a 5 o degradar a Coordinator).
- Blueprint con dependencias secuenciales fuertes (Coordinator es el path correcto).
- Disco libre <N×2GB (warn al usuario, sugerir reducir N o degradar a Coordinator).

## Inputs

- `.claude/PRPs/BLUEPRINT-<nombre>.md` con features independientes listadas.
- `feature_list.json` con active feature.
- skills.md registry (R6 validated por cada worktree pre-dispatch).
- N (entero ∈ [2, 5], default 3) — número de worktrees.
- N personality variants (asignación canónica en `references/fork-pattern.md`).

## Flow canónico

```
[la-forja] PREFLIGHT
   ├── ¿N ∈ [2, 5]? Si no → halt o ajustar
   ├── ¿Disco libre ≥ N×2GB? Si no → warn + opción reducir N
   └── ¿git ≥ 2.5? Si no → halt
   ↓
[la-forja] manage-worktrees.md
   ├── git worktree add .worktrees/sandbox-1 -b la-forja/sandbox-1-literal HEAD
   ├── git worktree add .worktrees/sandbox-2 -b la-forja/sandbox-2-creativo HEAD
   ├── ... (N veces)
   └── (find-docs invocado antes para validar git worktree syntax — R13)
   ↓
[la-forja] Para cada worktree N:
   ├── Validá skills citados por el Blueprint para ese worktree (R6)
   ├── Setup tool-filter del sub-agent (researcher/implementer/reviewer si Swarm interno
   │   o full-stack agent si Fork puro con personality variant)
   ├── Inject personality prompt variant (literal/creativo/disruptivo/quality/speed)
   └── Dispatch sub-agent al worktree N (sub-agent invoca skills, NO la-forja)
   ↓
[Workers en paralelo]
   ├── Worker 1 (literal): Edit/Write dentro de sandbox-1 worktree
   ├── Worker 2 (creativo): Edit/Write dentro de sandbox-2 worktree
   └── Worker N: ...
   (Workers reportan output a la-forja al terminar)
   ↓
[la-forja] Recolección de outputs
   ├── Por cada worktree: lista de commits + diff resumen + RESUMEN.md (si worker lo generó)
   └── Si worker reportó error o stuck → marcar como descartado o partial
   ↓
[la-forja] Cherry-pick recomendación (manual con guidance)
   ├── Producir tabla "qué tomar de qué worktree"
   ├── Anticipar conflictos esperados + comandos para resolver
   ├── Recomendar orden de merge (literal baseline → +creativo mejoras → ?disruptivo)
   └── PEDIR confirmation humana ANTES de ejecutar cherry-pick
   ↓
[Humano confirma] → la-forja ejecuta cherry-pick(s) en main branch
   ↓
[la-forja] Cleanup (manage-worktrees.md cleanup phase)
   ├── git worktree remove .worktrees/sandbox-N
   ├── git branch -D la-forja/sandbox-N-<personality>  (si decidido descartar)
   └── git worktree prune
   ↓
[la-forja] Handoff a el-evaluador (post-orchestration)
```

## R4 enforcement

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

la-forja MISMA en pattern Fork:
- Lee Blueprint + outputs de workers (Read, Grep, Glob).
- Bash limitado a `git worktree add/list/remove/prune` y `git cherry-pick` (con confirmation).
- NO Edit/Write a archivos de aplicación dentro de los worktrees — workers son los que escriben en sus worktrees aislados.
- NO invoca skills directo. Workers son los que invocan dentro de su worktree.

Workers tienen tool filter completo (Read+Edit+Write+Bash) **dentro de su worktree** — pueden generar código, ejecutar tests, todo lo que el skill que invocan necesite. Pero workers NO escriben fuera de su worktree (.claude/memory/* es bloqueado por R5 + por filesystem path scope).

## R5 enforcement

> [memory:CONSTRAINTS.md#R5] — Workers no escriben a memory.

Workers en pattern Fork NO tienen Write a `.claude/memory/*.md` aún dentro de su worktree (cada worktree comparte el git index pero memory store es shared filesystem path; R5 sigue aplicando).

Si un worker emerge una lesson/error/decision durante el build:
- Worker la documenta en `.worktrees/sandbox-N/RESUMEN.md` o `PROBLEMAS.md` (worker-local).
- la-forja recolecta los RESUMEN.md de todos los worktrees al final.
- la-forja propaga al handoff de el-evaluador como `proposed_memory_entries`.
- el-evaluador post-orchestration es quien escribe a `.claude/memory/*.md`.

## R6 enforcement

> [memory:CONSTRAINTS.md#R6] — Skill dispatch validates registry.

Antes de cada worktree dispatch:

```
1. Lee .claude/memory/skills.md
2. Para cada skill que el Blueprint cita y que ese worktree va a usar:
   - Buscá nombre exacto
   - Si no existe → halt antes de lanzar el worktree
   - Si existe → validá `requires` cumplidos en el repo target
3. Si todos los skills validan → setup worktree y dispatch worker
```

R6 valida una vez antes del lanzamiento simultáneo de los N worktrees, NO durante (workers no pueden modificar el registry, R5).

## Personality variants

Asignación canónica:

| N | Variants asignadas | Use case |
|---|---|---|
| 2 | Literal + Creativo | Comparar fidelidad estricta vs mejora pragmática |
| 3 | Literal + Creativo + Disruptivo | DEFAULT — añade exploración arquitectónica |
| 4 | Literal + Quality + Creativo + Disruptivo | Añade TDD-first |
| 5 | Literal + Speed + Quality + Creativo + Disruptivo | Espectro completo |

Cada variant inyecta un sistema-prompt en su sub-agent. Detalles en [`references/fork-pattern.md`](references/fork-pattern.md) sección "Personalidades por N".

## Cherry-pick recomendación (NO automático)

la-forja NO ejecuta `git cherry-pick` automáticamente. Produce recomendación con shape:

```markdown
## Cherry-pick recomendado

**Orden de merge:**
1. Sandbox 1 (literal) → baseline limpia
2. Sandbox 2 (creativo) → mejoras de UX
3. Sandbox 3 (disruptivo) → evaluar caso por caso

**Por fase del Blueprint:**

| Fase | Worktree ganador | Commits a cherry-pick | Razón |
|------|------------------|----------------------|-------|
| 1: Auth setup | Sandbox 1 (literal) | abc123, def456 | Más limpio, menos abstracciones |
| 2: Pricing UI | Sandbox 2 (creativo) | ghi789 | Mejor jerarquía visual + voice consistente |
| 3: Webhook | Sandbox 1 (literal) | jkl012 | Disruptivo agregó complejidad innecesaria |

**Conflictos anticipados:**
- `app/(auth)/sign-in/page.tsx` entre sandbox 1 y 2 (ambos modificaron)
  - Resolver con: `git checkout --theirs app/(auth)/sign-in/page.tsx` (preferir creativo)

**Ideas de Disruptivo a considerar (NO auto-apply):**
- Approach alternativo en lib/auth/proxy.ts (ver sandbox-3/ARQUITECTURA.md)
- Decisión: descartar — añade complexity sin beneficio claro

**Comandos a ejecutar (después de tu confirmation):**
git checkout main
git cherry-pick abc123 def456                          # Sandbox 1 fase 1
git cherry-pick ghi789                                 # Sandbox 2 fase 2
# resolver conflicto manualmente si emerge
git cherry-pick jkl012                                 # Sandbox 1 fase 3
```

PEDIR confirmation humana ANTES de cualquier `git cherry-pick`. NO la-forja decide solo qué tomar — el humano confirma o ajusta.

## Halt conditions

Fork halt-blocked en:

- N=1 (degradar a Swarm).
- N>5 (reducir o degradar a Coordinator).
- Disco lleno (degradar o abortar).
- git worktree no disponible (degradar a Coordinator).
- Skills.md R6 falla (halt antes de lanzar worktrees).
- Worker reporta error irrecuperable (descarta ese worktree, sigue con los otros).
- TODOS los workers fallan (reportar al humano, opciones: re-tirar con Coordinator o el-yunque).

## Edge cases

### Edge: 3 worktrees pero el creativo y el disruptivo convergen al mismo approach

→ Documentar en cherry-pick recomendación. Tomar uno (preferir creativo si paridad), descartar el otro. Evitar duplicar commits del mismo cambio efectivo.

### Edge: Disruptivo encuentra approach claramente superior pero rompe coherencia con resto

→ Reportar al humano con shape: "Disruptivo propuso X. Es mejor que el approach del Blueprint en aspecto Y, pero rompe coherencia con Z. ¿Adoptar disruptivo y refactorizar Z, o descartar disruptivo?". NO la-forja adopta disruptivo unilateralmente — afecta el Blueprint completo.

### Edge: Worker se atora (no progresa en >30min)

→ Marcar worktree como stuck. NO matar al worker silenciosamente — reportar al humano: "Worker N stuck en fase X. ¿Esperar más, descartar este worktree, o pause completo?".

### Edge: Conflicto en cherry-pick que no se anticipó

→ la-forja pausa el merge. Reporta el conflicto exacto + comandos para resolver + qué versión recomienda preferir. Humano resuelve manualmente y avisa para continuar.

### Edge: feature_list.json tocado por workers (rompe R1 WIP=1)

→ R5 + R1 violation. Worker tiene Write filtered fuera de worktree, pero feature_list.json está dentro del worktree (workers comparten branch). Mitigación: prompt de cada worker explícitamente dice "NO modifiques feature_list.json — la-forja maneja state machine post-merge".

## Output handoff (post-orchestration)

```markdown
## la-forja Fork handoff

**Pattern:** Fork (paralelo con worktrees)
**Active feature:** <F?-S?>
**N worktrees:** <2-5>
**Personality variants:** [literal, creativo, ...]

**Outputs por worktree:**
- Sandbox 1 (literal): branch la-forja/sandbox-1-literal — N commits — RESUMEN.md
- Sandbox 2 (creativo): branch la-forja/sandbox-2-creativo — M commits — RESUMEN.md + MEJORAS.md
- Sandbox 3 (disruptivo): branch la-forja/sandbox-3-disruptivo — K commits — RESUMEN.md + ARQUITECTURA.md

**Cherry-pick aplicado** (post-confirmation humana):
- Commits cherry-picked: [list]
- Conflictos resueltos: [paths]

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: ...
- proposed_error: ...

**Cleanup ejecutado:**
- worktrees removed: .worktrees/sandbox-{1,2,3}
- branches deleted: la-forja/sandbox-{1,2,3}-*

**Handoff next:**
- el-evaluador (mandatory) → R7 + memory record
- el-guardian (si full pipeline) → pre-deploy audit
```

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO invoca skills, workers en sus worktrees son los que invocan.
- [memory:CONSTRAINTS.md#R5] — workers no escriben a memory aún dentro de worktree.
- [memory:CONSTRAINTS.md#R6] — registry validation antes de lanzar workers.
- [memory:CONSTRAINTS.md#R13] — find-docs invocado antes de generar git worktree commands (ver `manage-worktrees.md`).
- [memory:lessons#L-004] — Fork es el default del binary pattern selector.
- [memory:decisions#D-013] — la-forja confirma binary cross-skill.
- [docs:git] — git worktree commands canónicos vía find-docs.

## Refusals

- ❌ Fork con N=1 (degenerate, no es paralelización).
- ❌ Fork con N>5 (satura disco + conflictos super-lineales).
- ❌ Cherry-pick automático sin confirmation humana (riesgo de pérdida de mejoras).
- ❌ Fork cuando Blueprint tiene dependencias secuenciales fuertes (force-fit anti-pattern).
- ❌ la-forja MISMA escribe código en worktrees (R4 — workers escriben).
- ❌ Workers escriben a memory (R5 — solo el-evaluador post-orchestration).
- ❌ Saltar handoff a el-evaluador post-merge (R7 — sin three-layer no se marca passing).
