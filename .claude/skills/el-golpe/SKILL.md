---
name: el-golpe
description: >
  Feature mediano one-shot. Scope: <30min wallclock, 1-3 commits atómicos,
  multi-archivo. Más estructura que el-tajo (brief-plan visible 3-5 líneas
  antes de ejecutar) pero sin loop iterativo (a diferencia de sprint).
  Ejemplos canónicos: implementar flujo invitar miembros, dashboard 4 KPIs,
  auth flow simple. PREFLIGHT (2 gates): (1) active feature en feature_list.json
  (R1) — sin active, halt; (2) si feature tiene UI → brand.json debe existir
  (R10) — sin brand.json + UI requerida, halt + handoff add-ui-kit. Brief plan
  visible al usuario, espera "go" antes de ejecutar. Ejecución one-shot:
  sin loop, sin ciclos de feedback. Si UI → invocar impeccable (R10). Si
  logic → implementar directo con Zod whitelist (R3 análogo a L-003). Output:
  1-3 commits atómicos. Si scope excede durante ejecución → commit lo hecho,
  halt, sugerir /build (la-forja) para el resto. Binary mode (D-017): execute
  (default si scope califica) o escalate-graceful (si scope excede a /build —
  NO PAUSE, escalación siempre disponible). NO sprint (sin loop iterativo).
  NO templates folder. Citas: [memory:CONSTRAINTS.md#R1] (active feature),
  [memory:CONSTRAINTS.md#R2] (atomic commits), [memory:CONSTRAINTS.md#R10]
  (brand contract si UI), [memory:lessons#L-001] si toca DB user data,
  [memory:lessons#L-003] si toca inputs externos, [memory:decisions#D-017]
  (binary shape).
tier: core (lightweight)
requires: directorio de proyecto target con git inicializado. Active feature en feature_list.json (R1 — el-golpe opera dentro del active actual). Si feature tiene UI → brand/brand.json existe (PREFLIGHT halt si UI requerida y brand.json missing). Tests + lint pasando antes de tocar código.
fallback: Sin active feature → halt: "el-golpe requiere active feature." Sin git → halt. Si feature requiere UI y brand.json missing → halt + handoff add-ui-kit. Si scope excede durante ejecución → commit lo hecho con scope acotado, halt, sugerir /build (la-forja) para el resto. Si tests rojos pre-arranque → halt: "el-golpe no arranca con tests rojos."
dependencies: []
---

# el-golpe

> *"Treinta minutos. Brief de tres líneas. Tres commits máximo. Si necesitás más, no es un golpe — es feature."*

Skill prompt-only. Feature mediano one-shot con brief-plan visible. Sin loop iterativo (eso es sprint), sin discovery extendida (eso es la-herreria), sin paralelización (eso es la-forja Fork). Si lo que tenés excede 30min o requiere planning formal, escalate a `/build` sin pena.

**No genera templates folder.** No requiere `find-docs` upfront (sub-tool ad-hoc si emerge necesidad). Aplica R10 condicional (solo si toca UI). Aplica R14 condicional (solo si genera tools destructivas). NO `el-guardian` handoff por default.

## PREFLIGHT — duro, halt-blocked

```
1. ¿Hay active feature en feature_list.json (R1)?
   - Sí → el-golpe opera dentro de ese feature
   - No → halt: "el-golpe requiere active feature. Pickeá del backlog o
            invocá /la-herreria primero."

2. ¿La feature requiere UI?
   - Sí → ¿brand/brand.json existe?
     - Sí → continuar
     - No → halt: "el-golpe con UI requiere brand.json. Corré /add-ui-kit
              primero para inicializar Brand DNA."
   - No → continuar (logic-only golpe, no R10)

3. ¿Tests + lint pasando antes de tocar código?
   - Si exit 0 → continuar
   - Si rojos → halt: "el-golpe NO arranca con tests rojos. Fixá primero."

4. ¿Git accesible?
   - Sí → continuar
   - No → halt: "el-golpe require git para atomic commits"
```

el-golpe halt-blocked en blockers reales. NO halt en archivos opcionales si no son requeridos por la feature.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide feature mediano (~30min, multi-archivo, sin paralelización) | Coordinator |
| Usuario dice "agregá flow X", "implementá dashboard Y", "hacé auth simple" | Coordinator |
| Triage de sprint detecta tarea no-iterativa de ~30min → handoff a el-golpe | sprint |
| Triage de el-tajo detecta scope excede atómico → handoff a el-golpe | el-tajo |
| la-forja Swarm pattern delega tasks medianos a el-golpe | la-forja |

NO se invoca para: microtarea atómica (eso es el-tajo), feature completa con planning formal (eso es la-forja /build), iteración con feedback humano (sprint), context loading (primer), audit security pre-deploy (el-guardian).

## Scope check (binary D-017)

| Criterio | Golpe (execute) | Excede (escalate a /build) |
|----------|-----------------|---------------------------|
| **Wallclock estimado** | <30min | ≥30min |
| **Commits atómicos** | 1-3 | >3 |
| **Brief-plan visible** | 3-5 líneas | Necesita Blueprint completo |
| **Discovery requerida** | <5min lectura | Multi-step exploration |
| **Paralelización** | NO (one-shot) | SÍ → la-forja Fork |
| **Iteración con feedback** | NO (one-shot) | SÍ → sprint |

Decision tree:

```
¿wallclock <30min Y commits ≤3 Y brief-plan basta Y sin paralelización Y sin iteración?
├── Sí → el-golpe (execute)
└── No → escalate graceful a /build (la-forja)
```

**Escalación NO es PAUSE.** /build (la-forja) siempre disponible. D-017 documenta binary shape, NO trinary.

## Loop de ejecución (~30min total)

```
1. SCOPE-CHECK + BRIEF PLAN (~3min)
   prompts/brief-plan.md decide:
   - Golpe material → produce brief 3-5 líneas
   - Excede → escalate a /build
   Output: brief plan visible al usuario, esperar "go" o ajustes

2. EXECUTE one-shot (~20-25min)
   - Read archivos relevantes (1-3min)
   - Aplicar cambios según brief
     - Si UI → invocar impeccable para componentes (R10 enforcement vía sub-agent)
     - Si logic → implementar directo con whitelist explícita (L-003)
     - Si DB → consider RLS user_id (L-001) + handoff a el-migrador si schema change
   - NO loop (sin "ciclo 1 → ciclo 2"). Si necesita iteración → escalate a sprint.

3. VERIFY (~3min)
   prompts/verify.md ejecuta protocolo:
   - typecheck → exit 0
   - tests relevantes → exit 0
   - sin console errors (visual check si UI)
   - Si fail → revertir parcial, reportar al usuario

4. COMMIT (~2min)
   - 1-3 commits atómicos (R2)
   - Cada commit con scope del active feature
   - Mensaje: <type>(<active-feature-id>): <descripción>
```

Total típico: 25-30min. Si excede 35min → halt + reportar al usuario.

## Output shape

```markdown
## Golpe: <descripción 1 línea>

**Brief plan:**
- Archivo 1: <qué cambia>
- Archivo 2: <qué cambia>
- Archivo N: <qué cambia>
- Verification: <command>

**Active feature:** <F?-S?>

**Ejecución:**
- Commit 1: <type>(<scope>): <desc>
- Commit 2: <type>(<scope>): <desc>
- Commit 3: <type>(<scope>): <desc>

**Verification:** typecheck + tests PASS, sin console errors.
```

Si scope excede durante ejecución, output cambia:

```markdown
## Golpe partial → /build escalation

**Commits ejecutados:** N de M planeados
- <list de commits exitosos>

**Razón de halt:** <ej: "fase 3 require schema change + cascade en 8 archivos">

**Próximo paso:**
→ Invocá `/build` (la-forja) para completar el resto. el-golpe ya commitió
  el progreso parcial — la-forja arranca desde ahí.
```

## Reglas operativas

1. **Brief plan visible OBLIGATORIO antes de ejecutar.** A diferencia de el-tajo (que arranca directo), el-golpe muestra plan 3-5 líneas y espera "go". Si el usuario dice "ajustá X", re-emitir plan.

2. **One-shot NO loop.** Si emerge necesidad de iteración con feedback humano entre cambios → halt + escalate a sprint. el-golpe ejecuta brief-plan completo o escalate.

3. **Atomic commits R2.** 1-3 commits máximo. Cada uno atómico, con scope del active feature. NO multi-commit dentro del mismo cambio (eso es disciplina del programador, no del agent).

4. **Scope creep = halt.** Si durante ejecución emerge "ya que estoy acá, también necesito Y", halt + reportar. NO scope creep silencioso.

5. **R10 condicional.** Si feature toca UI consuming brand tokens → sub-agent invoca impeccable. Si feature es logic-only → R10 NO aplica.

6. **R14 condicional.** Si feature genera tools agentic destructivas → typed confirmation, no `execute()`. Mayoría de golpes son features funcionales benignas.

7. **L-001 si toca user data.** Si feature crea tabla nueva con datos de usuario → RLS por `user_id` mandatorio, citado en SQL.

8. **L-003 si toca inputs externos.** Form validators, API routes, tool inputSchemas — whitelist explícita con Zod, no `z.record(z.any())`.

9. **find-docs ad-hoc.** Sub-agent puede invocar find-docs durante ejecución si emerge necesidad (ej: API call contra lib externa). NO upfront.

10. **el-guardian handoff condicional.** Si golpe genera código sensible (auth flow + secrets, payments + webhooks, etc.) → handoff a el-guardian post-cierre. Mayoría de golpes son features benignas — NO handoff.

11. **D-017 binary cita explícita.** brief-plan.md cita D-017 + L-004 informativo. Escalation a /build siempre disponible — NO PAUSE.

## Refusals

- ❌ Loop iterativo (eso es sprint).
- ❌ Discovery extendida >5min (eso es la-herreria).
- ❌ Paralelización con worktrees (eso es la-forja Fork).
- ❌ Multi-commit (>3 commits) — escalate a /build.
- ❌ Scope creep ("ya que estoy acá...") — halt + reportar.
- ❌ Continuar con tests rojos pre-arranque (PREFLIGHT halt).
- ❌ UI sin brand.json (PREFLIGHT halt + handoff add-ui-kit).
- ❌ Generar tool destructiva con `execute()` automático (R14).
- ❌ Tabla user data sin RLS user_id (L-001).
- ❌ Validators con `z.record(z.any())` (L-003).
- ❌ Modificar feature_list.json desde el-golpe (R1 + R5).
- ❌ Self-eval (AP3 — el-evaluador post-feature).

## Tool filter

`Read · Edit · Write · Grep · Glob · Bash` (typecheck + tests + git).

NO Skill direct (R4 — el-golpe MISMA es thin orchestrator). Sub-agent dispatched para ejecución cuando R10/R14 aplican.

Bash limitado a:
- `tsc --noEmit`, `npm test -- --findRelatedTests <files>` (verification)
- `git status` / `git diff` / `git log` / `git add` / `git commit`
- `npm list` / `npm audit` (informativo)

find-docs invocable como sub-tool ad-hoc dentro de un commit si emerge necesidad.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R1]` | en SKILL.md (active feature) |
| Constraint | `[memory:CONSTRAINTS.md#R2]` | en SKILL.md + verify.md (atomic commits) |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | condicional (si UI) |
| Constraint | `[memory:CONSTRAINTS.md#R14]` | condicional (si tools destructivas) |
| Lesson | `[memory:lessons#L-001]` | condicional (si tabla user data) |
| Lesson | `[memory:lessons#L-003]` | condicional (si inputs externos) |
| Lesson | `[memory:lessons#L-004]` | informativo en brief-plan.md (binary D-017) |
| Decision | `[memory:decisions#D-017]` | en SKILL.md + brief-plan.md (binary shape) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `el-tajo` | upstream. el-tajo escala a el-golpe si scope excede atómico. |
| `sprint` | par. sprint es loop iterativo, el-golpe es one-shot. Triage decide cuál. |
| `la-forja` (`/build`) | downstream escalate. Si golpe excede 30min o requiere planning formal → escalate. |
| `la-herreria` | upstream. Si no hay active feature, sugerir la-herreria. |
| `add-ui-kit` | upstream condicional. Si UI sin brand.json → halt + handoff. |
| `impeccable` | sub-tool si UI. Sub-agent del golpe invoca impeccable para componentes. |
| `el-migrador` | sub-tool si schema change. Sub-agent invoca para migration nueva. |
| `find-docs` | sub-tool ad-hoc. Si código contra libs externas requiere docs frescas. |
| `el-evaluador` | post-cierre. Valida los commits del golpe en su ciclo R7 normal. |
| `el-guardian` | condicional. Si golpe toca secrets/auth/payments → handoff post-cierre. |
| `primer` | upstream. Si arranca sin contexto, primer carga primero. |

## Output handoff

```markdown
## el-golpe handoff

**Active feature:** <F?-S?>
**Golpe description:** <texto 1 línea>
**Outcome:** done | partial-escalated

**Brief plan executed (si done):**
- Archivo 1: <cambio aplicado>
- Archivo 2: <cambio aplicado>

**Commits (si done):**
- <type>(<scope>): <desc>
- <type>(<scope>): <desc>

**Verification:** PASS (typecheck + tests + sin console errors)

**Razón de escalación (si partial):** <texto>
**Commits ejecutados (si partial):** N de M
**Próximo paso (si partial):** invocá /build con el resto

**Memory entries propuestas (opcional):**
- proposed_lesson / proposed_error si emerge patrón
```

NO el-guardian handoff por default. Solo si golpe tocó secrets/auth/payments/destructivas.

---

*"El-golpe es el skill que admite que la mayoría de features útiles son medianos. Treinta minutos, brief, tres commits, listo. Si necesitás más, no es un golpe — es feature."*
