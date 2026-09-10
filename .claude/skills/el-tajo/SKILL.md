---
name: el-tajo
description: >
  Microtarea atómica one-shot. Scope: <5min wallclock, <500 LOC delta,
  1-3 archivos. Sin discovery, sin planning, sin loop iterativo, sin
  templates folder. Ejemplos canónicos: extraer componente, bumpear
  dep, agregar tracking event, fix typo, rename variable, agregar
  log estructurado. PREFLIGHT duro (2 gates): (1) active feature en
  feature_list.json (R1) — sin active feature, halt; (2) tests + lint
  pasando antes de tocar código — si rojos, halt. Scope check: si la
  tarea excede los criterios atómicos → escalate graceful a el-golpe
  con razón explícita. Output: 1 atomic commit (R2) en active feature
  branch + verification command exit 0. Binary mode (D-016): execute
  (default si scope califica) o escalate-graceful (si scope excede —
  NO PAUSE genuino, escalación siempre disponible). NO requiere
  brand.json (no genera UI por default). NO el-guardian handoff.
  Citas: [memory:CONSTRAINTS.md#R1] (active feature), [memory:CONSTRAINTS.md#R2]
  (atomic commit), [memory:lessons#L-003] si toca inputs externos,
  [memory:decisions#D-016] (binary shape).
tier: core (lightweight)
requires: directorio de proyecto target con git inicializado. Active feature en feature_list.json (R1 — el-tajo opera dentro del active actual, NO abre feature nueva). Tests + lint pasando antes de tocar código (PREFLIGHT halt si rojos).
fallback: Sin active feature → halt: "el-tajo requiere active feature. Pickeá del backlog o invocá /la-herreria primero." Sin git → halt. Tests rojos → halt: "el-tajo no arranca con tests rojos. Fixá los tests primero — un atomic commit en code roto compone más rojo." Si scope excede durante scope-check → escalate graceful a el-golpe con razón explícita.
dependencies: []
---

# el-tajo

> *"Cinco minutos. Trescientas líneas. Un commit. Si dudás del scope, no es tajo."*

Skill prompt-only. Microtarea atómica one-shot. Sin discovery, sin planning, sin loop. Si lo que tenés enfrente NO califica como tajo (>5min, >500 LOC, >3 archivos, requiere planning), escalate a el-golpe sin pena.

**No genera código nuevo desde cero.** No tiene `templates/` folder. NO requiere `find-docs`. NO aplica R10 por default (solo si tajo toca UI con tokens). NO aplica R14 (tajos benignos). NO `el-guardian` handoff.

## PREFLIGHT — duro, halt-blocked

```
1. ¿Hay active feature en feature_list.json (R1)?
   - Sí → el-tajo opera dentro de ese feature (commit con scope del active)
   - No → halt: "el-tajo requiere active feature. Pickeá del backlog o
            invocá /la-herreria primero."

2. ¿Tests + lint pasando antes de tocar código?
   - Corre: `make test && make lint` (o equivalente del proyecto)
   - Si exit 0 → continuar
   - Si rojos → halt: "el-tajo NO arranca con tests rojos. Fixá los tests
                       primero — un atomic commit en code roto compone más
                       rojo. Considerá un sprint de fix antes."

3. ¿Git accesible?
   - Sí → continuar (commit irá al branch del active feature)
   - No → halt: "el-tajo require git para atomic commit"
```

el-tajo halt-blocked en blockers reales (no active feature, tests rojos, no git). NO halt en archivos opcionales (brand.json, etc.) — si la tarea no los necesita, no se valida.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide cambio chiquito atómico (1-3 archivos, claramente <5min) | Coordinator / agente / humano |
| Usuario dice "agregá tracking", "extraé X componente", "bumpeá dep N", "rename Y" | Coordinator |
| Triage de sprint detecta tarea atómica → handoff a el-tajo | sprint |
| la-forja Swarm pattern delega tasks atómicos a el-tajo | la-forja |

NO se invoca para: features completas (eso es la-forja / el-golpe / /build), planificar (la-herreria), iteración con feedback humano (sprint), context loading (primer), tareas medianas <30min (eso es el-golpe), audit security (el-guardian).

## Scope check (binary D-016)

Detalle completo en [`prompts/scope-check.md`](prompts/scope-check.md). Resumen criterios:

| Criterio | Tajo (execute) | Excede (escalate a el-golpe) |
|----------|----------------|------------------------------|
| Wallclock estimado | <5min | ≥5min |
| LOC delta | <500 | ≥500 |
| Archivos modificados | 1-3 | >3 |
| Requiere brief-plan visible? | NO | SÍ |
| Requiere multi-step verification? | NO (1 typecheck local basta) | SÍ |
| Toca UI con brand.json? | Excepcional, atomic typo en JSX | SÍ → escalate |

Decision tree:

```
¿Wallclock estimado <5min Y LOC <500 Y archivos ≤3 Y sin brief-plan?
├── Sí → el-tajo (execute)
└── No → escalate graceful a el-golpe con razón explícita
```

**Escalación NO es PAUSE.** el-golpe está siempre disponible — no requiere upstream user action. D-016 lo documenta: binary shape (execute / escalate-graceful), NO trinary.

## Loop de ejecución (~5min total)

```
1. SCOPE-CHECK (~30s)
   prompts/scope-check.md decide:
   - Tajo material → continúa
   - Excede → escalate graceful a el-golpe con mensaje claro
   Output: scope decision documentada

2. EXECUTE (~3-4min)
   - Lee archivo(s) afectados (1-3 archivos)
   - Aplica cambio mínimo (Edit dirigido, no refactor amplio)
   - NO discovery, NO planning, NO scope creep ("ya que estoy acá...")

3. VERIFY (~30s)
   - Typecheck local si aplica (`tsc --noEmit` o equivalente)
   - Si rompe → revertir parcial, reportar al usuario, NO commit
   - Si OK → continuar

4. COMMIT (~30s)
   - 1 atomic commit (R2) con scope del active feature
   - Mensaje: <type>(<active-feature-id>): <descripción <60 chars>
```

Total típico: 4-5min. Si excede 7min → señal de scope creep, halt + reportar al usuario para considerar escalate.

## Output shape

```markdown
## Tajo: <descripción 1 línea>

**Scope check:** tajo material (<5min, <500 LOC, 1-3 archivos)
**Active feature:** <F?-S?>
**Archivos modificados:** N

**Diff resumen:**
```
<paths con +X/-Y LOC>
```

**Verification:** `<command>` exit 0

**Commit:** `<type>(<active-feature-id>): <desc>`
```

Si scope excedió durante scope-check, output cambia:

```markdown
## Tajo escalation → el-golpe

**Razón:** <ej: "tarea estimada 12min wallclock + 4 archivos, excede 5min/3 files">

**Próximo paso:**
→ Invocá `/el-golpe` con la misma tarea. el-golpe maneja scope mediano
  (<30min, brief-plan visible).
```

## Reglas operativas

1. **Atomic commit en cierre obligatorio.** 1 commit (R2) al final. NO multi-commit. Si la tarea natural produce 2+ commits → señal de excede scope, escalar.

2. **Scope del commit = active feature.** el-tajo NO abre feature nueva (R1). Commit usa scope del active actual: `feat(F3-S?): rename UserCard to UserProfile` o `fix(F3-S?): typo en hero copy`.

3. **NO scope creep.** "Ya que estoy acá, también arreglo X" es anti-pattern. Si emerge un Y útil durante el tajo, documentar en commit message como follow-up: `<commit>\n\nFollow-up sugerido: refactor Y (no incluido en este tajo)`.

4. **Verification mínima local.** typecheck (`tsc --noEmit`) o equivalente — NO test suite completo (eso es el-evaluador post-feature). Si typecheck falla, revertir parcial y reportar.

5. **NO planning visible.** A diferencia de el-golpe (brief-plan 3-5 líneas), el-tajo arranca directo. Si necesitás plan visible, no es tajo — escalate.

6. **NO discovery.** Lectura mínima (1-3 archivos para entender el cambio). Si necesitás explorar codebase >5min para entender, no es tajo — sprint o el-golpe.

7. **R10 condicional.** Si el-tajo toca UI consuming brand tokens (excepcional — típico tajo es typo en copy o rename componente), aplicar R10: leer `brand/brand.json` antes. Mayoría de tajos son lógica/copy/typo, R10 NO aplica.

8. **R14 condicional.** Si el-tajo agrega tool agentic destructiva (raro — tajos típicos son refactor/copy/log), aplicar R14: typed confirmation, no `execute()` automático. Mayoría de tajos NO genera tools.

9. **L-003 si tocás inputs externos.** Si el tajo toca validators, schemas, API routes que reciben datos externos → cita `[memory:lessons#L-003]` y aplicá whitelist explícita. Mayoría de tajos NO toca esto.

10. **NO el-guardian handoff.** el-tajo no toca secrets ni produce código que requiera audit pre-deploy. Si emerge necesidad de audit durante un tajo → señal de scope creep, escalate.

11. **D-016 binary cita explícita.** Scope-check.md cita D-016 + L-004 informativo (test diagnóstico aplicado, resultado binary).

## Refusals (lo que NUNCA hace)

- ❌ Multi-commit. Un atomic commit (R2) o nada.
- ❌ Scope creep ("ya que estoy acá..."). Tajo es atómico.
- ❌ Planning visible. Si necesitás plan, no es tajo.
- ❌ Discovery extendida. Si necesitás explorar, no es tajo.
- ❌ Continuar con tests rojos (PREFLIGHT halt).
- ❌ Abrir feature nueva (R1 — opera dentro del active).
- ❌ Modificar feature_list.json desde el-tajo (R1 + R5 — eso es el-evaluador post-validation).
- ❌ Generar código nuevo desde cero (eso es ai/, add-*, impeccable).
- ❌ Halt forzado por archivos opcionales — solo halt en blockers reales.
- ❌ Self-eval del cambio (AP3 — el-evaluador post-feature, NO el-tajo).

## Tool filter

`Read · Edit · Write · Grep · Glob · Bash` (typecheck local + git).

NO Skill direct (R4 — sub-tasks atómicos no requieren skill orchestration). NO `find-docs` (tajo opera en código existente, no genera contra libs externas).

Bash limitado a:
- `tsc --noEmit` (typecheck local)
- `git status` / `git diff` / `git log` (read-only state)
- `git add` / `git commit` (atomic commit)
- `npm list` (informativo)

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R1]` | en SKILL.md (active feature requirement) |
| Constraint | `[memory:CONSTRAINTS.md#R2]` | en SKILL.md + scope-check.md (atomic commit) |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | condicional (si tajo toca UI) |
| Constraint | `[memory:CONSTRAINTS.md#R14]` | condicional (si tajo genera tools destructivas) |
| Lesson | `[memory:lessons#L-003]` | condicional (si tajo toca inputs externos) |
| Lesson | `[memory:lessons#L-004]` | informativo en scope-check.md (binary D-016 aplicado) |
| Decision | `[memory:decisions#D-016]` | en SKILL.md + scope-check.md (binary shape) |

el-tajo NO genera contra libs externas → NO `[docs:*]` cites obligatorias.

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `el-golpe` | downstream escalate. Si scope-check detecta que tarea excede tajo → handoff explícito. |
| `sprint` | upstream/downstream. sprint triage puede detectar tarea atómica → handoff a el-tajo. el-tajo no escala a sprint (sprint es loop iterativo, el-tajo es one-shot). |
| `la-forja` | upstream. la-forja Swarm pattern delega tasks atómicos a el-tajo. |
| `la-herreria` | upstream. Si no hay active feature, sugerir la-herreria para planning. |
| `primer` | upstream. Si el-tajo arranca sin contexto, primer carga primero. |
| `el-evaluador` | post-cierre. el-evaluador valida el commit del active feature normalmente, no el tajo individual. |
| `el-guardian` | NO direct. el-tajo no toca secrets ni código que requiera audit pre-deploy. |

## Output handoff

```markdown
## el-tajo handoff

**Active feature:** <F?-S?>
**Tajo description:** <texto 1 línea>
**Outcome:** done | escalated

**Scope (si done):** N archivos modificados, M LOC delta, T segundos wallclock
**Commit:** `<type>(<scope>): <desc>` *(solo si done)*

**Razón de escalación (si escalated):** <texto>
**Próximo paso (si escalated):** invocá /el-golpe con la misma tarea
```

NO el-guardian handoff. NO el-evaluador handoff explícito (el-evaluador valida el commit del active feature en su ciclo normal).

---

*"El-tajo es el skill que admite que la mayoría de cambios reales son atómicos. Cinco minutos, un commit, listo. Si dudás del scope, no es tajo."*
