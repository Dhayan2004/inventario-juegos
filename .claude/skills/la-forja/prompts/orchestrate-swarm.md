# orchestrate-swarm

> Pattern Swarm — workers tool-filtered para one-shot atómico. Use case: task <30min con sub-tasks bien definidos. Delega a el-tajo (atómico <5min) o el-golpe (mediano <30min).

## Cuándo se usa

Pattern selector decidió Swarm porque:

- Blueprint tiene 1 sub-task atómico bien definido (<30min, 1-3 archivos típicamente).
- Fork es overkill (no se necesita paralelización exploratoria, hay 1 solución correcta).
- Coordinator es overkill (no hay dependencias secuenciales, es one-shot atómico).
- O usuario explícitamente pidió "modo swarm", "researcher+implementer+reviewer", o invocó el-tajo/el-golpe (que internamente usan Swarm).

NO usar Swarm si:

- Task no es atómico (>30min o >3 archivos típicamente) → escalar a Fork o /build.
- Task tiene múltiples sub-decisiones independientes paralelizables → Fork con worktrees.
- Task tiene dependencias secuenciales → Coordinator.

## Inputs

- Active feature en feature_list.json con verification command claro.
- Task description concreta (no Blueprint completo necesariamente — Swarm opera sobre 1 sub-task).
- skills.md registry (R6 validated).

## Workers tool-filtered

Swarm usa 3 roles con tool filter explícito y estricto:

| Role | Tool filter | Responsabilidad |
|------|-------------|-----------------|
| **Researcher** | `Read · Grep · Glob · WebFetch` | Investigar contexto, buscar patrones existentes en codebase, documentar approach. NO escribe código. |
| **Implementer** | `Read · Write · Edit · Bash` | Ejecutar el cambio: Edit archivos, run tests via Bash, verificar build. NO valida solo (siempre handoff a Reviewer). |
| **Reviewer** | `Read · Grep` + invocación de el-evaluador | Validar output del Implementer. Si pasa → confirma a la-forja. Si falla → devuelve a Implementer con NEEDS_FIX. |

NO mezclar tools cross-role. Researcher NO escribe. Implementer NO valida solo. Reviewer NO ejecuta nuevos cambios.

Detalle exhaustivo en [`tool-filter-workers.md`](tool-filter-workers.md).

## Flow canónico

```
[la-forja] Validá registry (R6) — el-tajo o el-golpe debe existir si delegamos
   ↓
[la-forja] Setup 3 workers con tool filter explícito
   ↓
[Researcher] (en paralelo o serial — la-forja decide)
   ├── Lee codebase target
   ├── Busca patrones existentes (grep para evitar duplicación)
   ├── Si necesita docs externos → WebFetch o invoca find-docs
   └── Reporta a la-forja: "approach X, archivos Y, riesgos Z"
   ↓
[la-forja] Sintetiza output Researcher → prompt para Implementer
   ↓
[Implementer]
   ├── Aplica el cambio según approach + paths del Researcher
   ├── Edit/Write archivos
   ├── Run tests via Bash
   └── Reporta a la-forja: "diff aplicado, tests passing, archivos N"
   ↓
[la-forja] Sintetiza output Implementer → prompt para Reviewer
   ↓
[Reviewer]
   ├── Lee diff aplicado
   ├── Invoca el-evaluador para R7 three-layer (Reviewer es el ÚNICO worker que invoca otro skill)
   ├── el-evaluador valida syntax + runtime + system
   └── Reporta a la-forja: "PASS" o "NEEDS_FIX <gap específico>"
   ↓
[la-forja] Si PASS → handoff final
        Si NEEDS_FIX → loop back a Implementer con el gap (max 2 retries antes de halt)
```

## R4 enforcement

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

la-forja MISMA en pattern Swarm:
- Lee outputs de cada worker.
- Sintetiza entre workers (texto, no código).
- NO invoca skills directo. Solo Reviewer worker invoca el-evaluador (esa invocación es del Reviewer, no de la-forja).

Workers tienen tool filter estricto pero pueden invocar skills dentro de su rol:
- Researcher puede invocar find-docs (es un skill de research).
- Reviewer invoca el-evaluador (es el rol de validation).
- Implementer NO invoca skills — solo ejecuta el cambio mecánico (R4 también aplica internamente: si necesita "skill plumbing", no es atómico, escalar a el-golpe o /build).

## R5 enforcement

> [memory:CONSTRAINTS.md#R5] — Workers no escriben a memory.

Ningún worker en Swarm escribe a `.claude/memory/*.md`. Si Researcher descubre algo memoryable, reporta a la-forja → handoff a el-evaluador post-Swarm.

## R6 enforcement

> [memory:CONSTRAINTS.md#R6] — Skill dispatch validates registry.

Antes del dispatch del Swarm:

```
1. Validar el-tajo o el-golpe (si Swarm delega ahí) en skills.md
2. Validar el-evaluador en skills.md (Reviewer lo invoca)
3. Validar find-docs en skills.md (Researcher puede invocarlo)
4. Si alguno falla → halt antes de lanzar Swarm
```

R6 es one-shot por Swarm — task atómico no cambia el registry mid-execution.

## Delegación a el-tajo / el-golpe

Swarm puede operar de 2 formas:

**Forma A — Swarm directo:** la-forja lanza Researcher+Implementer+Reviewer manualmente (sin invocar el-tajo/el-golpe). Útil cuando el sub-task no encaja bien en los workflows de el-tajo/el-golpe.

**Forma B — Delegación:** la-forja invoca el-tajo (si <5min) o el-golpe (si <30min), que internamente usan Swarm con tool filter propio. la-forja MISMA NO invoca el-tajo/el-golpe directo (R4) — un sub-agent dispatchador hace la invocación.

Forma B es preferida cuando aplica — el-tajo/el-golpe ya tienen el Swarm pattern probado y configurado para su scope. Forma A es backup cuando el sub-task no encaja.

## Halt conditions

Swarm halt-blocked en:

- Task no es atómico (>30min, >3 archivos) — escalar a Fork o /build.
- Researcher no encuentra contexto (target codebase incompleto o ambiguo) — halt + handoff a humano.
- Implementer falla 2 veces consecutivas con NEEDS_FIX del Reviewer — halt + reportar gap.
- Reviewer no puede validar (verification command roto) — halt + reportar al humano.
- Skills.md R6 falla.

## Edge cases

### Edge: Researcher reporta "no hay approach claro, hay 3 alternativas"

→ Swarm degrada a Coordinator pequeño: Researcher devuelve a la-forja, la-forja pide UNA pregunta al humano, humano elige, Implementer recibe approach decidido. NO Implementer decide solo si hay ambigüedad genuina.

### Edge: Implementer reporta "el cambio rompe tests existentes que no son del feature"

→ Reviewer valida: si los tests rotos eran legítimamente expected (ej: API rename), Implementer ajusta. Si los tests rotos NO debían romperse → NEEDS_FIX. Si Reviewer no puede determinar → halt + reportar al humano.

### Edge: Reviewer pide NEEDS_FIX 3 veces seguidas

→ Halt forzado. Algo está mal en el approach o en la verification. Reportar al humano con shape: "3 NEEDS_FIX consecutivos, posiblemente approach incorrecto. Sugerencia: re-Researcher o escalar a Fork con N=2 (literal vs creativo)."

### Edge: el-tajo o el-golpe no validan en R6 (missing skill)

→ Swarm degrada a Forma A (workers manual sin delegación). Reportar al humano que el-tajo/el-golpe registry está roto.

## Output handoff (post-orchestration)

```markdown
## la-forja Swarm handoff

**Pattern:** Swarm (workers tool-filtered)
**Active feature:** <F?-S?>
**Forma:** A (workers manual) | B (delegación a el-tajo/el-golpe)

**Researcher output:**
- Approach: <texto>
- Archivos identificados: [paths]
- Riesgos: [list]

**Implementer output:**
- Diff aplicado: [paths]
- Tests run: <verification command + result>

**Reviewer output:**
- Veredicto: PASS | NEEDS_FIX
- el-evaluador R7 layers: L1 PASS / L2 PASS / L3 PASS

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: ...

**Handoff next:**
- el-evaluador (mandatory) → R7 + memory record (Swarm Reviewer ya corrió R7 inline; el-evaluador post-orchestration solo confirma + memory promotion)
- el-guardian (si full pipeline) → pre-deploy audit
```

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO invoca skills; workers invocan dentro de su rol.
- [memory:CONSTRAINTS.md#R5] — workers no escriben a memory.
- [memory:CONSTRAINTS.md#R6] — registry validation antes de Swarm.
- [memory:CONSTRAINTS.md#R7] — Reviewer corre R7 three-layer inline.
- [memory:lessons#L-004] — Swarm es override (no default) del binary pattern selector.
- [memory:decisions#D-013] — la-forja sexta validación cross-skill.

## Refusals

- ❌ Mezclar tool filter cross-role — Researcher NO escribe, Implementer NO valida solo, Reviewer NO ejecuta cambios.
- ❌ Implementer invoca skills (R4 + Swarm internal rule — solo Reviewer invoca el-evaluador, Researcher puede invocar find-docs).
- ❌ Workers escriben a memory (R5).
- ❌ Skip de Reviewer post-Implementer (sin validation no se marca passing).
- ❌ NEEDS_FIX loop infinito — max 2 retries, después halt.
- ❌ Swarm para task no atómico — escalar a Fork o /build.
