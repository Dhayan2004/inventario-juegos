# Iteration Patterns — patterns canónicos de iteración

## Objetivo

Catalogar los patrones de iteración más comunes en sprints reales. Cada pattern declara: dominio, criterio típico, número esperado de ciclos, signals de convergencia, signals de divergencia, cómo cierra. Sin estos patterns, cada sprint se inventa el shape — con ellos, el agente reconoce el caso y aplica la estructura conocida.

## Pattern A — Copy iteration

**Dominio:** texto visible al usuario (CTAs, headlines, microcopy, email subject lines, tooltips).

**Criterio típico:**
- "El usuario dice 'me gusta'" (criterio subjetivo, requiere user feedback explícito)
- "Matchea el voice de voice.json" (criterio objetivo, validable con voice anti-slop rules)
- "Cumple constraint específico" (length <=N chars, includes keyword X, evita palabras Y)

**Ciclos esperados:** 2-4

**Signals de convergencia:**
- Usuario aprueba con `done` en ciclo 2 o 3
- Cada ciclo se acerca al voice/tone deseado (medible si hay voice.json)
- El usuario dice "esto sí" después de varios "no me convence"

**Signals de divergencia:**
- 3 ciclos consecutivos con feedback "no, otra cosa" sin convergencia direccional
- Usuario cambia el criterio entre ciclos ("ahora con más urgencia / no, mejor más calma")
- Cada ciclo introduce nueva propuesta sin construir sobre la anterior

**Cómo cierra:**
- DONE → `feat|docs(<active>): refine <component> copy` con el texto final
- ESCALATE → si diverge, posible signal de copy strategy ambigua → la-herreria o el-golpe (rewrite del context narrativo)

**Ejemplo concreto:** ver [`examples.md`](examples.md) caso 1 (CTA del hero).

## Pattern B — Styling iteration

**Dominio:** visuales (spacing, typography weights/sizes, colors dentro de tokens, layout responsive breakpoints).

**Criterio típico:**
- "Matchea el wireframe / mockup"
- "Se ve bien en mobile + desktop"
- "Cumple los tokens del brand.json sin override"

**Ciclos esperados:** 2-4

**Signals de convergencia:**
- Visual matchea criterio definido (compárable con screenshot/wireframe)
- Cada ciclo reduce delta visual (medible si hay screenshot baseline)
- Usuario aprueba después de ajuste fino

**Signals de divergencia:**
- Ciclos requieren override de brand tokens (R10 violation — sprint debe pausar y reportar)
- Tarea revela ser rediseño completo, no ajuste (escalate a el-golpe o la-herreria)
- Spacing nunca matchea por discrepancia entre wireframe y design system real

**Cómo cierra:**
- DONE → `style|refactor(<active>): adjust <component> spacing/typography/layout` 
- R10 check obligatorio antes de commit (sprint tocó UI consuming brand tokens)
- ESCALATE → si requiere override de brand → /build con add-ui-kit re-pass

**Anti-pattern dentro de styling:**
- Override de brand tokens "porque queda mejor" → STOP, eso es R10 violation, escalate a /build con justificación.

## Pattern C — Validator iteration

**Dominio:** input validators (form validation, schema validation, edge case coverage en server actions).

**Criterio típico:**
- "Los N edge cases pasan los tests"
- "Cubre los inputs que el usuario describió"
- "Whitelist completa según L-003 patrón"

**Ciclos esperados:** 2-5 (más ciclos esperables porque cada edge case es un ciclo)

**Signals de convergencia:**
- Tests pasan progresivamente (`N-1, N, N+1...` PASS)
- Cada ciclo agrega cobertura de un caso identificado
- Los casos restantes son enumerables (lista finita conocida)

**Signals de divergencia:**
- Cada ciclo descubre 2+ casos nuevos (lista no converge)
- Tests pasados se rompen al agregar nueva validación (regression)
- Validation se vuelve más compleja que la lógica que valida

**Cómo cierra:**
- DONE → `fix|feat(<active>): cubrí edge cases <enumerar> en validator`
- Pre-commit: TODOS los tests pasan (no solo los nuevos)
- ESCALATE → si la lógica subyacente es la incorrecta, refactor mayor (el-golpe / /build)

**Cita L-003:** `[memory:lessons#L-003]` (whitelist explícita, nunca `z.record(z.any())`)

## Pattern D — Voice/tone refinement

**Dominio:** texto largo (emails, modals, error messages, onboarding sequences).

**Criterio típico:**
- "Matchea el voice de voice.json"
- "Tono usuario espera del archetype Caregiver/Hero/etc"
- "Sin marketing slop ('Don't miss out', '🚀 Boost your...')"

**Ciclos esperados:** 2-4

**Signals de convergencia:**
- Anti-slop checks pasan progresivamente
- Usuario reconoce el voice ("sí, así habla la marca")
- Voice.json `tone` + `voice_examples` matchean

**Signals de divergencia:**
- Voice.json no captura realmente el voice deseado (signal de add-ui-kit re-pass)
- Cada ciclo tiende a generic AI voice ("here's a friendly reminder...")
- Usuario rechaza repetidamente sin poder articular qué quiere → criterio borroso, preguntar UNA pregunta o escalate

**Cómo cierra:**
- DONE → `docs|feat(<active>): refiná voice del <component> match voice.json`
- ESCALATE a add-ui-kit si voice.json no captura el voice real (sprint NO modifica voice.json — eso es scope de add-ui-kit + el-evaluador)

## Pattern E — Code review iteration (RARO en sprint)

**Dominio:** revisión de código existente con propuestas de mejora puntuales.

**Criterio típico:**
- "Cubrir las N observaciones del review"
- "Pass second-look review del usuario"

**Ciclos esperados:** 1-3

**Signals de convergencia:**
- Cada observación se cierra con un cambio puntual
- Lista de observaciones es enumerable y finita

**Signals de divergencia:**
- Las observaciones requieren rewrite (escalate a el-golpe)
- El review revela problemas arquitecturales (escalate a la-herreria + /build)

**Cómo cierra:**
- DONE → `refactor|fix(<active>): aplicar feedback del code review`
- ESCALATE si scope crece más allá de los puntos enumerados

**Nota:** este pattern es RARO en sprint — la mayoría de code reviews son one-shot (el-tajo / el-golpe). Sprint solo aplica si los puntos del review son visualmente / experiencialmente subjetivos.

## Patterns que NO son sprint

| Anti-pattern | Por qué no | Skill correcto |
|--------------|------------|----------------|
| "Iterá sobre la arquitectura" | sprint no toca arquitectura | la-herreria |
| "Iterá sobre el security audit" | sprint no produce audit-required code | el-guardian (one-shot) |
| "Iterá sobre las migrations" | sprint no toca DB schema | el-migrador |
| "Iterá sobre todos los componentes UI del proyecto" | scope demasiado grande | /build (la-forja, paralelización) |
| "Iterá hasta que el LLM esté satisfecho" | viola AP3 (self-eval del generador) | rechazar |

## Cuántos ciclos antes de escalate?

| Ciclos completados | Convergencia detectada | Acción recomendada |
|---------------------|------------------------|---------------------|
| 1 | NO | Normal — ciclo 2 |
| 2 | YES | Probable DONE en ciclo 3 |
| 2 | NO | Continuar pero alertar a usuario en ciclo 3 |
| 3 | NO | Checkpoint suave — preguntar si va bien la dirección |
| 4 | NO | Checkpoint duro — recomendar pause o escalate |
| 5 | NO | Checkpoint forzado — done / pause / escalate (no `+5-mas` salvo razón) |
| 5 | NO + segunda vez `+5-mas` solicitado | Force escalate (anti-pattern detectado) |

## Citations

- [memory:lessons#L-003] (whitelist validators — pattern C)
- [memory:CONSTRAINTS.md#R10] (Brand DNA — pattern B)
- [memory:CONSTRAINTS.md#R14] (destructive tools — generic, no específico de pattern)
- [memory:CONSTRAINTS.md#AP3] (no self-eval — anti-pattern boundary)
