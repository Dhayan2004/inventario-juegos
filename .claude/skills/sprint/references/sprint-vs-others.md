# Sprint vs Others — boundaries con el-tajo, el-golpe, /build, la-herreria

## Objetivo

Documentar las boundaries operacionales entre sprint y los 4 skills vecinos en el espectro de scope/iteration. Boundaries claras evitan force-fit (sprint usado para tareas que deberían ser one-shot) y triage erróneos.

## Tabla canónica de boundaries

| Skill | Scope | Duration | Iteración | Output | Failure mode |
|-------|-------|----------|-----------|--------|--------------|
| **el-tajo** | <500 LOC, 1-3 archivos, atómico | <5 min | NO (one-shot) | 1 atomic commit | Rollback automático (revert / git reset) |
| **sprint** | refinement de existente, 1-3 archivos típicamente | 5-15 min | SÍ (max 5 ciclos con feedback) | 1 atomic commit en done | Pause (diff staged) o escalate |
| **el-golpe** | feature mediano, 5-15 archivos | <30 min | NO (one-shot completo) | N atomic commits cohesivos | Estado parcial + log estructurado |
| **/build** (la-forja) | feature completo, multi-archivo, multi-fase | >30 min, hasta horas | NO loop visible (paralelización por worktree) | Multi-commit feature branch | Blueprint roll-back, fase-by-fase recovery |
| **la-herreria** | planning (NO execution) | 10-30 min | iteración Q&A con usuario | BLUEPRINT-*.md | Replanning |

## Diferencia operacional concreta

### el-tajo vs sprint

**el-tajo:**
- Tarea: "Renombrá `getCwd` a `getCurrentWorkingDirectory` en 8 archivos"
- Comportamiento: ejecuta el rename, corre tests, commit. Sin feedback intermedio.
- Si falla: rollback automático.
- Failure mode: el-tajo NO continúa con cambio parcial.

**sprint:**
- Tarea: "Renombrá `getCwd`... y validá que el nombre nuevo es claro"
- Si la tarea es claramente mecánica → es el-tajo, NO sprint. El "validá claro" no es feedback útil — el rename es deterministic.
- sprint solo cuando el feedback es genuinamente decision-relevant (copy refinement, styling, voice tone, edge case coverage).

**Test rápido:** ¿el cambio puede definirse 100% antes de empezar? → el-tajo. ¿El cambio depende de cómo se ve / suena / siente al usuario? → sprint.

### el-golpe vs sprint

**el-golpe:**
- Tarea: "Implementá flujo invitar miembros — UI + server action + DB + email"
- Comportamiento: planifica internamente las fases, ejecuta one-shot completo, commits cohesivos al final.
- Iteración: NO loop visible. el-golpe puede internamente iterar pero al usuario le entrega resultado completo.
- Failure mode: estado parcial + log de qué se hizo (resumable).

**sprint:**
- Tarea: "Refiná los validators del form invitar miembros — cubrí los 4 edge cases"
- Comportamiento: cada ciclo agrega cobertura de un edge case + diff visible + feedback.
- El form ya existe (sprint refina lo existente).
- Failure mode: pause con diff staged, retake con cabeza fresca.

**Test rápido:** ¿el código existe y se refina? → sprint. ¿el código no existe y hay que construirlo? → el-golpe (mediano) o /build (grande).

### /build vs sprint

**/build (la-forja):**
- Tarea: "Auth completo con Supabase + RLS + 4 pages + hooks + RLS policies + email templates"
- Comportamiento: planning formal (Blueprint), paralelización en worktrees, multi-commit feature branch, three-layer verification post-build.
- Iteración: NO loop visible al usuario per-ciclo (puede haber Coordinator-pattern interno con sub-agents secuenciales).
- Failure mode: rollback fase-by-fase.

**sprint:**
- Tarea: "Refiná el copy de la página /sign-up para matchear voice del wizard de onboarding"
- Comportamiento: 2-3 ciclos cortos sobre archivo existente, feedback visual del usuario.
- Failure mode: pause / escalate.

**Test rápido:** ¿hay Blueprint? → /build. ¿No hay Blueprint y la tarea es chiquita refinable? → sprint o el-tajo según iteración necesaria.

### la-herreria vs sprint

**la-herreria:**
- Tarea: "Diseñá la arquitectura del módulo de reportes"
- Comportamiento: Q&A iterativo con el usuario para producir BLUEPRINT-*.md
- Output: documento markdown, NO código.

**sprint:**
- Tarea: "Refiná el draft del BLUEPRINT-reportes.md hasta que matche el level of detail de los blueprints anteriores"
- Comportamiento: ciclos editando el .md, feedback visual del usuario.
- Output: el .md modificado + commit.

**Test rápido:** ¿produce documento de planning desde cero? → la-herreria. ¿refina documento existente con feedback? → sprint (caso atípico, mayoría de sprints son sobre código).

## Boundaries con skills auxiliares

### sprint vs primer

**primer:** lee contexto, NO modifica. Read-only.
**sprint:** lee + modifica + commitea. Write-capable.

primer es upstream de sprint si el agente arranca cold sin contexto: corre primer primero, después decide si sprint aplica.

### sprint vs find-docs

**find-docs:** sub-tool ad-hoc invocable DENTRO de cualquier skill que genere código contra libs externas (R13).

sprint NO requiere find-docs upfront (sprint refina lo existente, no genera contra libs nuevas). PERO si en un ciclo emerge necesidad ("este componente usa Tailwind v4 grid-cols, ajustá según sintaxis nueva"), sprint invoca find-docs ad-hoc dentro de ese ciclo, NO antes del loop.

### sprint vs el-evaluador

**el-evaluador:** valida outputs de skills (three-layer verification + Anti-Slop Gate). Único writer de memory store.

sprint NO se auto-evalúa. Cuando sprint cierra `done` con commit, ese commit es parte del active feature; cuando el active feature cierra, el-evaluador hace su pase usual. sprint NO requiere el-evaluador handoff explícito.

### sprint vs el-guardian

**el-guardian:** pre-deploy security audit con Codex como segundo cerebro.

sprint NO toca secrets ni produce código que requiera audit pre-deploy. Si emerge necesidad de audit durante un sprint (ej: el sprint terminó tocando un webhook handler con signature verification), escalate a el-golpe o /build (que SÍ tienen handoff a el-guardian estructurado). sprint NO cierra audit-required code.

## Anti-pattern boundaries (qué NO es sprint)

| Anti-pattern | Por qué no es sprint | Skill correcto |
|--------------|---------------------|----------------|
| "Iterá hasta que esté perfecto" sin criterio | sprint require criterio concreto | preguntar criterio o escalate |
| "Iterá sobre TODO el codebase" | sprint es chiquito (1-3 archivos típico) | /build (refactor formal) |
| "Iterá una vez" | sprint require >=2 ciclos para justificar el loop overhead | el-tajo |
| "Iterá hasta que pase CI" | CI feedback NO es "user feedback" | el-tajo (deterministic fix) o el-golpe |
| "Iterá hasta que el LLM diga que está bien" | sprint require user feedback, no self-eval | rechazar (anti-pattern AP3) |
| "Iterá sobre 20 archivos" | scope demasiado grande, signal de feature | /build |
| "Iterá indefinidamente" | sprint tiene max 5 ciclos | si emerge necesidad → escalate |

## Cita L-004 (test diagnóstico) en sprint

L-004 NO aplica directo a sprint (sprint no elige entre N providers). PERO si en el FUTURO emerge una sub-decisión sobre el behavior del loop:

> ¿Permitir 5 vs 10 ciclos máximos por default?
>
> Test diagnóstico: ¿hay un degenerate case que requiera acción upstream del usuario antes de re-invocar el skill productivamente?
>
> - Para 5 vs 10: NO. Es preference, ambos disponibles. → binary (default 5, override 10 via `+5-mas`).
> - Si emerge degenerate case (ej: "loop infinito sin progreso requiere RESET completo del active feature antes de re-invocar"): trinary con PAUSE.

Mi expectativa actual: probablemente binary. Sprint loop con max-iter es escalation graceful (handoff a el-golpe / /build), NO halt-blocked. Si emerge ADR concreto durante uso real, registrarlo como D-NNN con el test L-004 explícito.

## Citations

- [memory:lessons#L-004] (test diagnóstico binario-vs-trinario)
- [memory:skills#el-tajo]
- [memory:skills#el-golpe]
- [memory:skills#la-forja]
- [memory:skills#la-herreria]
- [memory:skills#primer]
- [memory:skills#find-docs]
- [memory:skills#el-evaluador]
- [memory:skills#el-guardian]
