---
name: sprint
description: >
  Lightweight task loop (5-15 min) para tareas pequeñas iterativas que NO
  ameritan /build pipeline completo. Orquesta loop iterativo corto sobre
  cambios pequeños (copy, styling, validators, voice/tone refinement) con
  feedback explícito del usuario entre ciclos. Boundaries claras: el-tajo
  (one-shot atómico <5min, sin iteración), el-golpe (one-shot mediano
  <30min, sin iteración), /build (feature completo con planning formal,
  Blueprint, multi-fase). sprint es el único skill que corre LOOP visible.
  Loop max ~5 ciclos: triage → plan rápido → ciclos (change → diff →
  feedback) → cierre (commit atómico, pause con diff staged, o handoff
  explícito a el-golpe / /build). NO genera código de producción de cero
  — refina código existente. NO templates folder. Output: visible loop
  con diff por ciclo + cierre con 1 commit atómico (R2). Casos de uso:
  copy iteration ("mejorá el CTA del hero"), styling iteration ("ajustá
  spacing del hero"), validator iteration ("cubrí los edge cases del
  form"), voice/tone refinement ("matcheá el voice del email").
tier: core (lightweight)
requires: directorio de proyecto target con git inicializado. Active feature en feature_list.json (R1 — sprint NO abre feature nueva, opera dentro del active actual). PREFLIGHT mínimo (no requiere brand.json, no requiere find-docs upfront).
fallback: Si la tarea es <5min atómica → escalar a el-tajo. Si es feature mediano <30min one-shot → escalar a el-golpe. Si es feature completo con planning → escalar a /build (la-forja). Si max iterations (5) sin convergencia → handoff a el-golpe (one-shot rewrite del scope) o /build (planning formal).
dependencies: []
---

# sprint

> *"Cinco ciclos cortos con feedback son más rápidos que un one-shot perfecto. Pero solo si el feedback existe entre ciclos."*

Skill prompt-only. Orquesta un loop iterativo corto (5-15 min, max ~5 ciclos) sobre cambios pequeños donde la convergencia depende de feedback humano entre cada ciclo. NO genera código de producción de cero, NO planifica features, NO toca arquitectura — refina código existente o copy/styling visible al usuario.

**No genera código nuevo.** No tiene `templates/` folder. No requiere `find-docs` upfront (solo invoca como sub-tool si un ciclo emerge necesidad de docs frescas). NO aplica R10 por default (solo si el sprint toca UI). NO aplica R14 por default (solo si el sprint genera tools agentic destructivas). NO `el-guardian` handoff (sprint no toca secrets ni produce código que requiera audit pre-deploy).

## PREFLIGHT — graceful, no halt en fallbacks operacionales

```
1. ¿Hay un active feature en feature_list.json (R1)?
   - Sí → sprint opera dentro de ese feature (commits van con el scope del active)
   - No → halt: "sprint require active feature. Corré /la-herreria o pickeá del backlog."

2. ¿La tarea del usuario califica como sprint?
   - Triage en prompts/triage-task.md decide:
     - <5min atómica → escalar a el-tajo
     - 15min one-shot → escalar a el-golpe o /build
     - 5-15min iterativa → SPRINT
   - Si triage no resuelve → preguntar al usuario UNA pregunta antes de proceder

3. ¿Git accesible?
   - Sí → sprint opera con working tree visible (diff por ciclo)
   - No → halt: "sprint require git para diff visible entre ciclos"
```

sprint NO halt por archivos opcionales. Falla halt-blocked solo si: no hay active feature (R1) o no hay git.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide refinar copy / styling / voice tone | Coordinator / agente / humano |
| Usuario pide cubrir edge cases de un validator | Coordinator |
| Usuario dice "iterá hasta que se vea bien", "ajustá hasta que matche", "refiná" | Coordinator |
| Active feature está en `active` y la próxima micro-iteración es ambigua sin feedback | Agente |
| Cambio chiquito que el usuario quiere VER antes de aceptar | Coordinator |

NO se invoca para: implementar features nuevos (eso es la-forja / el-golpe / /build), microtareas atómicas one-shot (eso es el-tajo), planning de features (eso es la-herreria), security audit (eso es el-guardian), context loading (eso es primer).

## Loop de ejecución (~5-15 min total, max ~5 ciclos)

```
1. TRIAGE (~30s)
   prompts/triage-task.md decide:
   - sprint material → continúa
   - el-tajo / el-golpe / /build → handoff explícito + halt
   Output: triage decision documentada

2. PLAN RÁPIDO (~1 min)
   - Estimar 1-3 ciclos esperados
   - Definir criterio de éxito CONCRETO ("el usuario dice 'me gusta'", "los 4 edge cases pasan", "spacing matchea wireframe")
   - Si criterio no es claro → preguntar al usuario UNA pregunta antes de loopear

3. LOOP (max ~5 ciclos, cada ciclo ~2-3 min)
   prompts/execute-iteration.md ejecuta:
   a. Execute small change (Edit / Write / refactor pequeño)
   b. Show diff/result al usuario (texto, screenshot si UI, output si validator)
   c. User feedback:
      - "continúa / siguiente" → ciclo N+1
      - "pause" → checkpoint-progress.md (save state + reportar)
      - "done / me gusta / suficiente" → close
      - "esto no va / mejor escalar" → escalate (el-golpe / /build)
   d. Si ciclo N == 5 sin convergencia → checkpoint forzado: reportar al usuario,
      preguntar si pause o escalate (NO continuar a ciclo 6 silencioso)

4. CIERRE (~1-2 min)
   prompts/close-or-escalate.md decide:
   - DONE → atomic commit con scope del active feature (R2)
   - PAUSE → log + diff staged (no commit), reportar estado para retake
   - ESCALATE → handoff explícito a el-golpe / /build con contexto del loop
```

Total típico: 5-15 min. Max budget: ~20 min antes de forzar escalate.

## Output shape (loop visible)

Detalle completo en [`prompts/execute-iteration.md`](prompts/execute-iteration.md). Resumen:

```markdown
## Sprint: <descripción 1 línea>

**Triage:** sprint material (no atómico, no feature completo, iterativo con feedback)
**Plan:** 2-3 ciclos esperados. Criterio: <concreto>

### Ciclo 1
**Cambio:** <qué se modificó>
**Diff:**
```
<diff o output>
```
**Tu turno:** ¿continúa, pause, done, escalate?

### Ciclo 2
...

### Cierre
**Resultado:** done en N ciclos
**Commit:** `<type>(<active-feature-scope>): <desc>`
```

Si pause o escalate, el cierre cambia (ver [`prompts/close-or-escalate.md`](prompts/close-or-escalate.md)).

## Reglas operativas

1. **Loop visible al usuario.** Cada ciclo muestra el cambio Y pide feedback explícito. NO loops silenciosos. NO ciclos batch sin checkpoint.
2. **Max 5 ciclos.** Si N=5 sin convergencia, forzar checkpoint. Continuar silencioso a ciclo 6 es anti-pattern (probable divergencia o scope creep — escalate).
3. **Criterio de éxito CONCRETO antes del loop.** "Hasta que se vea bien" NO es criterio. "Hasta que el usuario dice 'me gusta'" SÍ. "Hasta que los 4 edge cases pasen" SÍ. Si el criterio es ambiguo, preguntar UNA cosa al usuario antes de loopear.
4. **Atomic commit en cierre DONE.** Un solo commit (R2) al final del sprint exitoso. Ciclos intermedios pueden ser stash o WIP no-commit; NO commits intermedios por ciclo (eso rompería R2 atomic + ensuciaría history).
5. **Scope del commit = active feature.** Sprint NO abre feature nueva (R1 — WIP=1). El commit final usa el scope del active feature actual (ej: `feat(F3-S8): refine CTA copy hero`). Si el sprint cierra DONE pero el cambio NO encaja en active feature → es signo de scope creep, escalate.
6. **NO inventar tareas.** Sprint refina lo que el usuario pide. NO agregar "mientras estamos acá, también arreglé X". Eso es scope creep — comportamiento de el-golpe / /build, no de sprint.
7. **find-docs como sub-tool, NO header.** Sprint NO requiere docs frescas upfront. Si un ciclo emerge necesidad ("ajustá el layout para usar grid-cols-12 nuevo en Tailwind v4"), invoca find-docs ad-hoc dentro del ciclo, NO antes del loop.
8. **R10 condicional.** Si el sprint toca UI (Edit en archivos `.tsx` que renderean componentes consuming brand tokens), aplicar R10: leer `brand/brand.json` antes de modificar tokens visuales. Si el sprint refina lógica/tests/copy técnico, R10 NO aplica.
9. **R14 condicional.** Si el sprint genera o modifica tools agentic con efectos destructivos (delete*, send*, refund*, deploy*), aplicar R14 al cierre: typed confirmation, no `execute()` automático. Mayoría de sprints son benignos (copy, styling, validators) — R14 no aplica.
10. **Cita L-004 si aplica.** Sprint no usa default+override pattern (no elige entre N providers). L-004 NO aplica directo. Pero si en el FUTURO emerge una sub-decisión (ej: "¿permitir 5 vs 10 ciclos máximos?"), aplicar el test diagnóstico binario-vs-trinario:
    > ¿Hay un degenerate case que requiera acción upstream del usuario antes de re-invocar el skill productivamente? → No (max iterations es escalation graceful, no halt-blocked) → binary.
    Mi expectativa: probablemente binario (default = continuar hasta done; override = pause/escalate). Si emerge ADR durante el build, escribirlo como D-013 con el test explícito.
11. **NO el-guardian handoff.** Sprint no toca secrets ni produce código que requiera audit pre-deploy. Si emerge necesidad de audit durante un sprint, escalate a el-golpe o /build (NO sprint cerrando audit-required code).

## Refusals (lo que NUNCA hace)

- ❌ Generar código de aplicación nuevo desde cero (eso es ai/, add-*, impeccable, /build).
- ❌ Loops silenciosos sin feedback entre ciclos. Cada ciclo pide turno al usuario.
- ❌ Continuar a ciclo 6 sin checkpoint forzado. Max 5 ciclos.
- ❌ Múltiples commits intermedios (rompe R2 atomic). Un commit en cierre DONE.
- ❌ Abrir feature nueva en feature_list.json (rompe R1 WIP=1). Sprint opera dentro del active.
- ❌ Self-eval del cambio sin user feedback. Sprint no decide "ya está bien" — el usuario decide.
- ❌ Halt agresivo en archivos opcionales (brand.json, etc). Solo halt en blockers reales (no active feature, no git).
- ❌ Skipear triage. Si el usuario pide algo que es atómico → handoff a el-tajo. Si es feature → handoff a el-golpe / /build. Triage es paso 1, NO bypass.

## Tool filter

Read · Edit · Write · Grep · Glob · Bash (`git diff`, `git status`, `git stash`, `git add`, `git commit`).

NO tool restrictions hard (sprint puede modificar archivos — es write-capable). Pero opera con discipline: cada Edit muestra diff antes de pedir feedback.

Find-docs invocable como sub-tool ad-hoc (no upfront).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R1]` | informativo si reporta active feature |
| Constraint | `[memory:CONSTRAINTS.md#R2]` | informativo en commit final atómico |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | si el sprint toca UI y aplica brand check |
| Constraint | `[memory:CONSTRAINTS.md#R14]` | si el sprint genera tools destructivas |
| Lessons | `[memory:lessons#L-004]` | si en el FUTURO emerge sub-decisión binary-vs-trinary |

Sprint NO genera contra libs externas por default → NO `[docs:*]` cites obligatorias. Si un ciclo invoca find-docs, ese ciclo cita.

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `el-tajo` | upstream / downstream. Si triage detecta tarea atómica → handoff a el-tajo. Sprint NUNCA hace one-shot atómico (eso es el-tajo). |
| `el-golpe` | downstream escalate. Si max iterations sin convergencia, handoff a el-golpe (one-shot rewrite del scope). |
| `/build` (la-forja) | downstream escalate. Si triage detecta feature completo o sprint diverge a feature, handoff a /build. |
| `la-herreria` | upstream. Si no hay active feature, sugerir la-herreria para planning. |
| `primer` | upstream. Si el usuario pide sprint pero el agente no tiene contexto, primer carga primero. |
| `find-docs` | sub-tool ad-hoc. Sprint invoca find-docs DENTRO de un ciclo si emerge necesidad, NO antes del loop. |
| `el-evaluador` | post-cierre. el-evaluador valida el commit final del sprint (R7 three-layer si aplica al active feature). |
| `el-guardian` | NO direct. Sprint no toca secrets ni produce audit-required code. |
| `add-ui-kit` / `impeccable` | NO direct. Sprint no genera UI desde cero — refina lo existente. |

## Output handoff

```markdown
## sprint handoff

**Active feature:** <F?-S?>
**Cycles run:** N / 5
**Outcome:** done | pause | escalate

**Cambios totales:** <files modified, LOC delta>

**Commit:** `<type>(<scope>): <desc>` *(solo si done)*

**Suggested next steps:**
- <ej: si done — continuá active feature con próximo step>
- <ej: si pause — retake con `git diff` para ver estado>
- <ej: si escalate — invocá /el-golpe o /build con contexto>
```

NO el-guardian handoff. NO el-evaluador handoff explícito (el-evaluador valida el commit del active feature normalmente, no el sprint en sí).

---

*"Sprint es el skill que admite que la primera versión nunca es la final. Cinco ciclos cortos con feedback son más rápidos que un one-shot perfecto. Pero solo si el feedback existe entre ciclos — sin feedback, sprint es solo un /build degradado."*
