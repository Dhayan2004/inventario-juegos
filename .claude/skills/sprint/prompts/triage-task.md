# Triage Task — ¿es sprint material?

## Objetivo

Decidir en <30s si la tarea del usuario califica como sprint, o si requiere handoff inmediato a otro skill (el-tajo, el-golpe, /build, la-herreria). Triage es el paso 1 obligatorio del loop — NO bypass.

## El test diagnóstico (3 dimensiones)

Para cada tarea, evaluar 3 ejes:

| Eje | Pregunta | Si SÍ | Si NO |
|-----|----------|-------|-------|
| **Atomicidad** | ¿La tarea es one-shot atómica <5min, 1-3 archivos, <500 LOC, sin feedback intermedio? | el-tajo | continuar evaluando |
| **Iteración** | ¿La convergencia depende de feedback humano entre ciclos? | sprint candidato | escalate |
| **Scope** | ¿La tarea cabe en 5-15 min con 1-3 ciclos esperados? | sprint | el-golpe (≤30min) o /build (>30min) |

Sprint = atomicidad NO + iteración SÍ + scope (5-15 min).

## Decision tree

```
1. ¿La tarea se completa en <5 min, sin feedback intermedio, en 1-3 archivos?
   - SÍ → handoff a el-tajo. STOP.
   - NO → continuar.

2. ¿La tarea es un feature completo con planning formal (BLUEPRINT, multi-fase, >30 min)?
   - SÍ → handoff a /build (la-forja). STOP.
   - NO → continuar.

3. ¿La tarea es un feature mediano <30 min one-shot, sin loop iterativo?
   - SÍ → handoff a el-golpe. STOP.
   - NO → continuar.

4. ¿La convergencia depende de feedback humano entre ciclos?
   (el usuario necesita VER el resultado para decidir el próximo paso)
   - SÍ → SPRINT. Procede a plan rápido.
   - NO → handoff a el-tajo (si chiquito) o el-golpe (si mediano). STOP.

5. ¿Hay un criterio de éxito CONCRETO?
   ("hasta que se vea bien" NO es criterio.
    "hasta que el usuario dice 'me gusta'" SÍ.
    "hasta que los 4 edge cases pasen" SÍ.)
   - SÍ → procede.
   - NO → preguntar al usuario UNA pregunta antes de loopear.
```

## Tabla de ejemplos canónicos

| Tarea del usuario | Triage | Razón |
|-------------------|--------|-------|
| "Renombrá `getCwd` a `getCurrentWorkingDirectory` en todo el proyecto" | el-tajo | Atómico, mecánico, sin feedback |
| "Agregá un campo `phone` al schema users + migration + tipo TS" | el-tajo | Atómico, 3 archivos, sin loop |
| "Mejorá el copy del CTA del hero" | sprint | Iterativo, feedback visual del usuario, 2-3 ciclos típicos |
| "Ajustá el spacing del hero hasta que se vea bien" | sprint | Iterativo, feedback visual, criterio "se vea bien" requiere refinar a "qué hace que se vea bien para vos" |
| "Iterá sobre los validators del form hasta que cubran los edge cases" | sprint | Iterativo, criterio concreto (edge cases enumerables), 2-4 ciclos |
| "Refiná el voice del email hasta que matche la voice.json" | sprint | Iterativo, criterio voice.json, feedback humano |
| "Implementá el flujo invitar miembros completo" | el-golpe | Feature mediano <30min, one-shot, sin loop iterativo |
| "Agregá dashboard 4 KPIs con datos de Supabase" | el-golpe | Feature mediano, one-shot |
| "Implementá auth completo con Supabase + RLS + 4 pages" | /build (add-login) | Feature completo con templates pre-armados |
| "Construí el sistema de pagos con Stripe + webhooks + portal" | /build (add-payments) | Feature completo, pipeline formal |
| "Diseñá la arquitectura del nuevo módulo de reportes" | la-herreria | Planning, no execution |

## Edge cases del triage

### Edge 1 — Tarea ambigua

Si la tarea es ambigua entre sprint y el-golpe (ej: "ajustá el form login"), preguntar UNA pregunta:

> "¿Es un ajuste chico que querés ver antes de aceptar (sprint), o un rewrite del form completo (el-golpe)?"

NO loopear sin clarificar.

### Edge 2 — Tarea sin criterio de éxito

Si la tarea no tiene criterio claro (ej: "hacé el hero más bonito"), preguntar UNA pregunta:

> "¿Qué tendría que cumplir para que digas 'listo'? Bonito comparado a qué referencia, o qué sensación querés que dé?"

NO loopear sin criterio. Sin criterio, el sprint diverge.

### Edge 3 — Tarea que parece sprint pero es scope creep

Si el usuario pide "iterá sobre el form hasta que se vea bien Y agregá validación Y mejorá el copy Y...":

> "Cada uno de esos es un sprint distinto. ¿Empezamos por cuál?"

NO bundlear varios sprints en uno. Sprint = un objetivo iterativo, no un combo.

### Edge 4 — Tarea que parece sprint pero el código no existe

Si el usuario dice "iterá sobre el form login" pero el form login no existe:

> "El form login todavía no existe. Esto es scope para /build (add-login) o el-golpe, no sprint. Sprint refina lo existente — no genera desde cero."

Handoff explícito.

### Edge 5 — Active feature ausente (R1 violation)

Si feature_list.json NO tiene active feature:

> "No hay active feature en feature_list.json. Sprint opera DENTRO de un active feature (R1). Pickeá una del backlog o corré /la-herreria primero."

Halt. Sprint no abre feature nueva.

## Output del triage

Sprint documenta el triage al inicio del loop:

```markdown
## Sprint: <descripción 1 línea>

**Triage:**
- Atomicidad: NO (require iteración con feedback)
- Iteración: SÍ (convergencia depende de feedback visual del usuario)
- Scope: 5-15 min, 2-3 ciclos esperados

**Decisión:** sprint material. Procede a plan rápido.
```

Si el triage decide handoff:

```markdown
## Sprint triage: HANDOFF

**Razón:** <ej: tarea atómica, 1 archivo, sin feedback intermedio>
**Skill apropiado:** /el-tajo
**Próxima acción:** corré `/el-tajo` con la misma instrucción.
```

## Citations

- [memory:CONSTRAINTS.md#R1] (WIP=1 — sprint require active feature)
- [memory:skills#el-tajo] (boundary atómico)
- [memory:skills#el-golpe] (boundary mediano)
- [memory:skills#la-forja] (boundary feature completo)
