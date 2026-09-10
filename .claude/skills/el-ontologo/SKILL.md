---
name: el-ontologo
description: >
  Fase −1 — levantamiento ontológico de la EMPRESA (su "ser"), antes de descubrir
  cualquier producto. Por entrevista grill-me (una pregunta por turno + recomendación
  obligatoria) levanta dos lentes sobre la misma empresa: NEGOCIO (método Founder OS —
  segmento, JTBD, problema priorizado con evidencia, propuesta de valor, modelo
  operativo) y MARCA (método Estudio — arquetipo, código simbólico, lenguaje propio).
  Produce ONTOLOGY.md (frontmatter machine-readable + cuerpo narrativo) regido por
  ONTOLOGY_SCHEMA.md, que extiende el Brand DNA y se inyecta en cada generación
  downstream igual que brand.json. Reusa el MOTOR de el-entrevistador (grill-me,
  CHECKPOINT, resume) con un perfil de dominio `ontologia`. Memoria persistente en
  `.ontologia/` → resume tras caída sin re-preguntar. Úsalo al iniciar con un cliente/
  empresa nueva, ANTES de /descubrir y /plan.
tier: core
requires: raíz del proyecto escribible (crea `.ontologia/`). NO requiere Bootstrap Contract (corre antes de Fase 0 y de /plan).
fallback: si la empresa ya tiene un ONTOLOGY.md vigente, sugerir ir directo a /descubrir (Fase 0). Si el proyecto no necesita levantamiento de empresa (feature suelta sobre un producto ya conocido), saltar a /plan.
dependencies: [el-entrevistador, la-herreria, add-ui-kit]
---

# El Ontólogo — Fase −1 de levantamiento ontológico

> *"Antes de descubrir el producto, descubre la empresa. Todo lo demás orbita su 'ser'."*

Skill de **levantamiento ontológico**. Es la **Fase −1** del flujo Forge: levanta el **"ser" de la
empresa** (identidad, propósito, mercado, problema, significado de marca, restricciones) y lo
cristaliza en un `ONTOLOGY.md` que el harness inyecta en **cada** generación posterior —
specs, modelo de datos, UI, seguridad— **igual que hoy `brand.json` se inyecta en cada UI**. Es el
mayor diferenciador de Forge Enterprise.

```
Fase −1 (ESTE skill, /ontologia)   →  Fase 0 (/descubrir)          →  Fase 1+ (/plan → /build)
ONTOLOGY.md (el "ser" de la empresa)   SPEC.md + CONTEXT.md + ADRs     Blueprint → build → …
   ↑ negocio (Founder OS) + marca (Estudio)   ↑ deriva del glosario de empresa
```

## Reusa el MOTOR de `el-entrevistador` (no lo reimplementa)

Este skill **no reinventa** el motor de entrevista. Reusa, por referencia y sin modificarlos:

- La **espina universal** de 6 ranuras → [`el-entrevistador/references/spine.md`](../el-entrevistador/references/spine.md).
- El protocolo de **memoria/CHECKPOINT/RESUME** → [`el-entrevistador/references/state-schema.md`](../el-entrevistador/references/state-schema.md) (protocolo canónico para ambos perfiles).
- Las **reglas grill-me** (una pregunta/turno + recomendación + no avanzar con ramas abiertas).

Lo único propio de este skill es el **perfil de dominio `ontologia`** (etiquetas + guion de preguntas
+ glosario de empresa + emisión): [`references/profile-ontologia.md`](references/profile-ontologia.md).

## Es INLINE, a propósito (no `context: fork`)

El levantamiento es un ida-y-vuelta con el humano: vive en la conversación principal. **No lleva
`context: fork`** (forkearlo rompería el grill-me). El anti-bloat NO es el fork, es la **memoria en
disco** (`.ontologia/`) + el **checkpoint incremental**. *(Excepción: el sombrero `source-reader`,
que lee los métodos de Founder OS / Estudio, SÍ puede despacharse a un sub-agente forkeado — ver
[`assets/source-reader.md`](assets/source-reader.md).)*

## PREFLIGHT (suave)

Corre **antes** del Bootstrap Contract y antes de Fase 0 — no exige `feature_list.json` ni Brand DNA.
Solo necesita poder escribir `.ontologia/` en la raíz del proyecto.

## RESUME-aware — lo PRIMERO que hace

Al activarse, **antes de cualquier pregunta** (mismo protocolo que `el-entrevistador`, dir distinto):

```
1. ¿Existe `.ontologia/session.md` en la raíz del proyecto?
   - NO  → sesión nueva → ir a FASE 0 (Preparación).
   - SÍ  → cargar session.md + ONTOLOGY.draft.md, mostrar el "resumen de retomada"
           (formato en state-schema.md), y continuar EXACTAMENTE en "Siguiente acción".
           NO re-preguntar nada.
```

## FASE 0 — Preparación (sesión nueva)

1. **Fijar dominio** = `ontologia` (este skill solo levanta ese perfil; no se pregunta).
2. **Modo** → `nuevo` (empresa desde cero) | `existente` (empresa con material previo: brief, docs,
   transcripciones) | `re-levantamiento` (actualizar una ontología vigente).
3. **Cargar métodos fuente** (READ-ONLY) vía el sombrero [`assets/source-reader.md`](assets/source-reader.md):
   el método de **negocio** ([`references/fos-method.md`](references/fos-method.md), Founder OS) y el
   de **marca** ([`references/estudio-method.md`](references/estudio-method.md), Estudio). Si el modo es
   `existente`, el source-reader también ingiere el material del cliente a `ontology/evidence/` con
   marcas de confianza `[confirmado-por-fuente]/[inferido]/[ausente]`.

Persistir `domain: ontologia`, `project_mode`, `phase: preparacion` en `session.md` y avanzar.

## Las fases (el coordinador las conduce, persiste `phase` en `session.md`)

| `phase` | Cuándo | Sombrero (asset) |
|---|---|---|
| `preparacion` | siempre | (este SKILL.md) + [`assets/source-reader.md`](assets/source-reader.md) |
| `negocio` | ranuras s1–s4 (+ s6 parcial) | [`assets/business-interviewer.md`](assets/business-interviewer.md) |
| `marca` | ranura s5 (consume lo de `negocio`) | [`assets/brand-interviewer.md`](assets/brand-interviewer.md) |
| `cierre` | 6 ranuras completas, sin ramas abiertas | (este SKILL.md — mostrar todo para revisión) |
| `emitido` | compila `ONTOLOGY.md` + handoff | [`references/emit-ontology.md`](references/emit-ontology.md) |

En paralelo durante `negocio` y `marca`: [`assets/ontology-glossarist.md`](assets/ontology-glossarist.md)
(el glosario de empresa, en tiempo real) y [`assets/ontology-architect.md`](assets/ontology-architect.md)
(decisiones de empresa + `entidades_dominio` + `requisitos_seguridad`).

## Orden de lente — NEGOCIO antes que MARCA (resuelve el solapamiento FOS↔Estudio)

El lente **negocio** (Founder OS) corre primero y es la **fuente canónica** del problema/ICP/JTBD. El
lente **marca** (Estudio) corre después y **consume** ese contexto validado — **nunca re-pregunta**
problema/ICP; añade arquetipo, código simbólico y lenguaje propio encima. Detalle:
[`references/profile-ontologia.md`](references/profile-ontologia.md) §"Orden de lente".

## Reglas grill-me (inviolables — heredadas del motor)

1. **Una sola pregunta por turno. Jamás dos.**
2. Cada pregunta incluye **"Mi recomendación:"** concreta y defendible (recomendar + confirmar; nunca inventar la decisión).
3. No avanzar de ranura con **ramas abiertas**.
4. **Desafiar el lenguaje:** si la empresa usa un término ya canonizado con otro sentido, llamarlo de inmediato (handoff al Glosarista).
5. **El código simbólico se DESCUBRE, no se proyecta** (convicción Klaric): se levanta de lo que el cliente DICE/SIENTE, validado antes de cargarse. Nunca lo inventa el agente.
6. **Toda afirmación enforce-able cita evidencia.** Lo no respaldado va a `## Decisiones y supuestos abiertos`, no se afirma como hecho.

## CHECKPOINT (regla de núcleo — antes de CADA pregunta)

Idéntico al de `el-entrevistador` (ver [`state-schema.md`](../el-entrevistador/references/state-schema.md)),
sobre el dir `.ontologia/`:

1. Actualizar `ONTOLOGY.draft.md` incremental (frontmatter + narrativa de la ranura tocada).
2. Actualizar `session.md` incremental: `updated_at`, estado de ranura, *append* de una línea al log,
   ramas abiertas, y el bloque **"Siguiente acción"** con la pregunta exacta.
3. **Recién entonces** preguntar.

> Regla de oro: `session.md` siempre debe poder responder, por sí solo, *"si todo se cae ahora, ¿qué
> pregunta exacta toca al volver?"*

## Las 6 ranuras (perfil `ontologia`)

| # | Ranura | Qué levanta | Lente |
|---|--------|-------------|-------|
| 1 | Propósito y Norte | a qué se dedica · por qué existe (manifiesto) · North Star | negocio |
| 2 | Segmento y Actores | cliente específico · actores · JTBD por actor | negocio |
| 3 | Problema y Propuesta de Valor | dolor #1 (cita) · evidencia/CPF · diferenciadores · entidades de dominio | negocio |
| 4 | Modelo Operativo | cómo gana dinero · cómo entrega valor | negocio |
| 5 | Identidad y Significado de Marca | arquetipo · código simbólico · lenguaje propio | marca |
| 6 | Restricciones y Requisitos de Seguridad | no-negociables · datos sensibles · regulaciones | ambas |

Guion completo (IDs `S{n}.Q{m}`) + mapeo a las claves del schema:
[`references/profile-ontologia.md`](references/profile-ontologia.md). Contrato del artefacto:
[`ONTOLOGY_SCHEMA.md`](../../references/ONTOLOGY_SCHEMA.md).

> **Ranura 6 → contrato de seguridad (S1, cableado ✅).** `requisitos_seguridad` ES el contrato
> que consumen los gates shift-left: `la-herreria` asset #9 (pre-Blueprint), `el-guardian`
> (pre-deploy, Capa 0) y `/temple` (pre-release) lo cruzan con la Sección 6 del SPEC. Un
> `requisito_seguridad: critico` no satisfecho es Critical en todos los gates (ver
> `CONSTRAINTS.md` § Seguridad shift-left).

## Cierre y emisión

Cuando las 6 ranuras están `completa`, sin ramas abiertas, y las **claves obligatorias** del schema
(`ONTOLOGY_SCHEMA` §2) están pobladas:

1. **`cierre`**: mostrar `ONTOLOGY.draft.md` completo (frontmatter + narrativa) para revisión del usuario.
2. **`emitido`**: ejecutar [`references/emit-ontology.md`](references/emit-ontology.md), que:
   - Escribe el artefacto final **versionado** en la raíz: `ONTOLOGY.md` (+ `ontology/evidence/`).
   - Marca `discovery_completed: true` en el frontmatter (gate de consumo downstream).
   - Produce el **handoff** a Fase 0 (`/descubrir`) y a `/plan` (`la-herreria`), y deja `marca.*` como
     punto de partida para `add-ui-kit`.
   - Marca `phase: emitido` en `session.md`.

## Handoff → Fase 0 (/descubrir) y /plan (la-herreria)

```
✅ ONTOLOGY.md emitido (discovery_completed: true)

Siguiente paso:
→ /descubrir  — el-entrevistador levanta el SPEC del producto; su CONTEXT.md DERIVA del
                glosario de empresa de ONTOLOGY.md (modelo de dos capas).
→ /plan       — la-herreria lee ONTOLOGY.md en PREFLIGHT: el Blueprint ORBITA la ontología
                (no rehace BMC/VPC desde cero).
→ /add-ui-kit — hereda marca.arquetipo_primario + lenguaje propio como punto de partida.
```

## Reglas duras (Forge)

- **R4 — Orchestrator delega.** El Ontólogo coordina; cada fase carga su asset y delega al sombrero correspondiente. No mezcla las instrucciones de los sombreros con las suyas.
- **R6 — Skill validation.** Antes de hacer handoff a `el-entrevistador` / `la-herreria` / `add-ui-kit`, validar contra el registry [memory:skills](../../memory/skills.md).
- **Solo lectura sobre las fuentes.** Founder OS y Estudio se leen como **método** (el guion de preguntas); nunca se modifican ni se importa su código. Lo que se porta es la *metodología*, no los repos.
- **Nunca inventar.** Recomendación + confirmación; lo no confirmado es rama abierta. El código simbólico se descubre, no se proyecta.
- **Glosario de empresa ≠ glosario funcional ≠ glosario del harness.** `ONTOLOGY.md › ## Glosario` = lenguaje de la EMPRESA (capa padre); `CONTEXT.md` = términos del PRODUCTO (deriva); `.claude/memory/glossary.md` = vocabulario del FRAMEWORK. Tres planos.

## Frases de activación

| El usuario dice… | Acción |
|------------------|--------|
| "vamos a levantar la empresa", "haz la ontología", "perfilemos el negocio", "Fase −1", "levantamiento ontológico" | → FASE 0 (Preparación) |
| "¿en qué quedamos con la ontología?", "retomemos el levantamiento" | → RESUME (detectar `.ontologia/session.md`) |
| "ya tengo la ontología / el brief de empresa claro" | → sugerir ir a `/descubrir` (Fase 0) |
| empresa con material previo (brief, docs, transcripciones) | → modo `existente` → sombrero source-reader (ingesta a evidence/) |

---

*"De empresa borrosa a `ONTOLOGY.md` enforce-able, una pregunta a la vez. Eso es El Ontólogo."*
