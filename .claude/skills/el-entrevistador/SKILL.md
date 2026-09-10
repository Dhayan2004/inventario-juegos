---
name: el-entrevistador
description: >
  Fase 0 de descubrimiento (grill-me). Convierte una idea cruda en un SPEC
  desambiguado ANTES de /plan, por entrevista de una pregunta por turno con
  recomendación obligatoria. Produce SPEC.md (6 secciones: Visión · Usuarios ·
  Funcionalidades · Flujos · Arquitectura · No-Funcionales), CONTEXT.md (glosario
  del dominio del CLIENTE con igualdad semántica + detección de contradicciones)
  y ADRs (3 criterios). Memoria persistente en `.specfounder/` con "Siguiente
  acción" exacta → resume tras caída sin re-preguntar. Cierra entregando el SPEC
  a `la-herreria` (/plan) vía el adaptador "forge". Portado de SpecFounder v2
  (MIT, Ing. Oscar Lobo). Úsalo cuando la idea aún no está clara o antes de planear.
tier: core
requires: raíz del proyecto escribible (crea `.specfounder/`). NO requiere Bootstrap Contract (corre antes de /plan).
fallback: si el usuario ya tiene un spec/blueprint claro, sugerir saltar directo a /plan (la-herreria, modo B).
dependencies: [la-herreria, migration-wizard]
---

# El Entrevistador — Fase 0 de descubrimiento

> *"No planifiques sobre una idea borrosa. Primero descúbrela, sección por sección."*

Skill de **descubrimiento conversacional**. Es la fase que hoy le falta a Forge: una entrevista
**grill-me** (1 pregunta por turno + recomendación) que levanta el **spec funcional del dominio
del cliente** con igualdad semántica, y lo entrega desambiguado a `la-herreria` en lugar de una
idea cruda.

Encaja exactamente donde Forge empieza:

```
Fase −1 (/ontologia, el-ontologo)  →  Fase 0 (ESTE skill)        →  Fase 1+ (Forge actual)
ONTOLOGY.md (el "ser" empresa)        SPEC.md + CONTEXT.md + ADRs     /plan → Blueprint → /build → …
   └─ ## Glosario de empresa  ──────────► CONTEXT.md DERIVA de él (dos capas)
```

## Es INLINE, a propósito (no `context: fork`)

La entrevista es un ida-y-vuelta con el humano: debe vivir en la conversación principal. **No
lleva `context: fork`** (forkearlo rompería el grill-me). Lo que evita el bloat de ~40 turnos NO
es el fork, es la **memoria en disco** (`.specfounder/`) + el **checkpoint incremental**: el
estado vive en archivos, no en el contexto. *(Excepción: el sombrero Explorador, en proyectos
brownfield grandes, SÍ puede despacharse a un sub-agente forkeado — ver `assets/explorer.md`.)*

## PREFLIGHT (suave)

A diferencia de `la-herreria`, este skill corre **antes** del Bootstrap Contract — no exige
`feature_list.json` ni Brand DNA. Solo necesita poder escribir `.specfounder/` en la raíz del
proyecto. Si el repo es de un cliente existente (brownfield), prefiere el sombrero Explorador
antes de preguntar.

> **Carga de la ontología (Fase −1) si existe — modelo de dos capas.** Si existe `ONTOLOGY.md`
> en la raíz con `discovery_completed: true`, cárgalo como **upstream**: su `## Glosario / lenguaje
> propio de la empresa` es la **capa padre** del `CONTEXT.md` que vas a levantar. El `CONTEXT.md`
> (términos del **producto**) **deriva** de ese glosario y debe ser consistente con él — no redefinas
> un término que la empresa ya canonizó. Además, `segmento_y_actores` y `problema_priorizado` de la
> ontología son contexto: no re-preguntes lo que ya está ahí. Si NO existe `ONTOLOGY.md`, opera
> autónomo (degradación segura — el orden Fase −1 → Fase 0 es recomendado, no obligatorio).

## RESUME-aware — lo PRIMERO que hace

Al activarse, **antes de cualquier pregunta**:

```
1. ¿Existe `.specfounder/session.md` en la raíz del proyecto?
   - NO  → sesión nueva → ir a FASE 0 (Selección).
   - SÍ  → cargar session.md + SPEC.draft.md + CONTEXT.draft.md + adr/,
           mostrar el "resumen de retomada" (ver references/state-schema.md),
           y continuar EXACTAMENTE en el bloque "Siguiente acción". NO re-preguntar nada.
```

Protocolo completo de resume y de checkpoint: [`references/state-schema.md`](references/state-schema.md).

## FASE 0 — Selección (sesión nueva)

El **dominio** es lo primero, porque determina el vocabulario de las 6 secciones:

1. **Dominio** → por ahora **`software`** (único perfil activo; el perfil `ontologia` y los
   creativos llegan en fases posteriores — ver [`references/spine.md`](references/spine.md)).
2. **Modo de proyecto** → `nuevo | existente | re-spec-parcial | glosario-urgente`.
3. *(La metodología de emisión está FIJA en `forge` — no se pregunta.)*

Persistir `domain`, `project_mode`, `phase: seleccion` en `session.md` y avanzar.

## Las fases (el coordinador las conduce, persiste `phase` en `session.md`)

| `phase` | Cuándo | Sombrero (asset) |
|---|---|---|
| `seleccion` | siempre | (este SKILL.md) |
| `exploracion` | solo `existente` / `re-spec` | [`assets/explorer.md`](assets/explorer.md) |
| `vision` | solo `nuevo` (o Visión rota) | [`assets/vision-generator.md`](assets/vision-generator.md) |
| `entrevista` | recorrido grill-me S1–S6 | [`assets/interviewer.md`](assets/interviewer.md) (+ glosarista + arquitecto en paralelo) |
| `cierre` | 6 secciones completas, sin ramas abiertas | (este SKILL.md — mostrar todo para revisión) |
| `emitido` | el adaptador compila + handoff | [`references/emit-forge.md`](references/emit-forge.md) |

En paralelo durante `entrevista`: [`assets/glossarist.md`](assets/glossarist.md) (CONTEXT.draft.md
en tiempo real) y [`assets/architect-adr.md`](assets/architect-adr.md) (ADRs por 3 criterios).

## Reglas grill-me (inviolables — detalle en `assets/interviewer.md`)

1. **Una sola pregunta por turno. Jamás dos.**
2. Cada pregunta incluye **"Mi recomendación:"** concreta y defendible (nunca inventar la decisión: recomendar + confirmar).
3. No avanzar de sección con **ramas abiertas**.
4. Ante ambigüedad, reformular con términos concretos.
5. **Desafiar el lenguaje**: si un término ya definido se usa distinto, llamarlo de inmediato (handoff al Glosarista).
6. Proponer términos canónicos ante lenguaje impreciso.
7. Verificar relaciones entre entidades con **escenarios límite** ("¿qué pasa si un Usuario pertenece a dos Organizaciones?").

## CHECKPOINT (regla de núcleo — antes de CADA pregunta)

Tras **cada** respuesta del usuario y **antes** de la siguiente pregunta, en orden:

1. Actualizar drafts incremental (`.specfounder/SPEC.draft.md` / `CONTEXT.draft.md` / `adr/`).
2. Actualizar `session.md` incremental: `updated_at`, estado de sección, *append* de **una línea**
   al log, ramas abiertas, y el bloque **"Siguiente acción"** con la pregunta exacta.
3. **Recién entonces** preguntar.

> Regla de oro: `session.md` siempre debe poder responder, por sí solo, *"si todo se cae ahora,
> ¿qué pregunta exacta toca al volver?"* Detalle: [`references/state-schema.md`](references/state-schema.md).

## Las 6 secciones (perfil `software`)

| # | Sección | Qué levanta |
|---|---------|-------------|
| 1 | Visión del Producto | qué es en una oración · usuario principal · problema que resuelve |
| 2 | Usuarios y Casos de Uso | tipos de usuario · acciones clave por rol · solo-admin · anónimo |
| 3 | Funcionalidades por Módulo | "El usuario puede…" / "El sistema automáticamente…" por módulo |
| 4 | Flujos de Usuario | acciones críticas · happy path + error path · validaciones |
| 5 | Arquitectura | plataforma · backend · stack · storage · auth · integraciones (si "a decidir" → el Arquitecto propone) |
| 6 | Requisitos No Funcionales | concurrencia · datos sensibles · offline · i18n · SLAs · hosting/región |

Guion completo de preguntas (IDs `S{n}.Q{m}`): [`assets/interviewer.md`](assets/interviewer.md).
Etiquetado por dominio + punto de extensión: [`references/spine.md`](references/spine.md).

> **Sección 6 → contrato de seguridad (S1, cableado ✅).** Las No-Funcionales (datos sensibles,
> protección, hosting/región) SON parte del contrato que consumen los gates shift-left:
> `la-herreria` asset #9 (pre-Blueprint), `el-guardian` (pre-deploy, Capa 0) y `/temple`
> (pre-release) las cruzan junto con `ONTOLOGY.md › requisitos_seguridad`. Ver `CONSTRAINTS.md`
> § Seguridad shift-left.

## Cierre y emisión

Cuando las 6 secciones están `completa` y no quedan ramas abiertas:

1. **`cierre`**: mostrar SPEC.draft.md + CONTEXT.draft.md + ADRs completos para revisión del usuario.
   **El humano aprueba sección por sección** — nada entra al SPEC final sin su "go" explícito (R19).
2. **`emitido`**: ejecutar el adaptador [`references/emit-forge.md`](references/emit-forge.md), que:
   - Escribe los artefactos finales **versionados** en la raíz: `SPEC.md` + `CONTEXT.md` + `docs/adr/`.
   - El commit de emisión lleva **type|scope `spec`** y NO mezcla código (R19, enforced por hooks).
   - Produce el **handoff a `/plan`** (la-herreria consume el SPEC como "trabajo previo", trata
     `CONTEXT.md` como el glosario canónico, y los ADRs como decisiones fijas).
   - Marca `phase: emitido` en `session.md`.

> **Propiedad post-emisión (R19):** emitido el SPEC, su dueño es el humano. Ningún agente lo edita
> unilateralmente durante el build — si una fase descubre que el spec está mal, se **detiene y lo
> surfacea**; el cambio se hace re-entrando a `/descubrir` con el humano. El código, a la inversa,
> es territorio de la IA: el canal del humano es el spec + review, no el editor.

## Handoff → /plan (la-herreria)

```
✅ SPEC completado → SPEC.md + CONTEXT.md + docs/adr/

Siguiente paso:
→ /plan   — la-herreria consume el SPEC desambiguado (no parte de una idea cruda).
            Mapea las 6 secciones a su pipeline y arranca desde la fase pendiente,
            sin re-preguntar lo ya respondido (ver references/emit-forge.md).
```

## Reglas duras (Forge)

- **R4 — Orchestrator delega.** El Entrevistador coordina; cada fase carga su asset y delega al
  sombrero correspondiente (como `la-herreria`). No mezcla las instrucciones de los sombreros con
  las suyas.
- **R6 — Skill validation.** Antes de hacer handoff a `la-herreria` o `migration-wizard`, validar
  contra el registry [memory:skills](../../memory/skills.md).
- **Nunca inventar.** Recomendación + confirmación del usuario; lo no confirmado se marca como rama
  abierta, no se asume.
- **Tres glosarios, tres planos.** `ONTOLOGY.md › ## Glosario` = lenguaje de la **EMPRESA** (capa
  padre, Fase −1, `el-ontologo`); `CONTEXT.md` = términos del **PRODUCTO** (deriva del anterior, esta
  Fase 0); `.claude/memory/glossary.md` = vocabulario del **FRAMEWORK** (el-evaluador). El `CONTEXT.md`
  no redefine un término que la empresa ya canonizó en `ONTOLOGY.md`.

## Frases de activación

| El usuario dice… | Acción |
|------------------|--------|
| "tengo una idea pero no está clara", "ayúdame a definir el proyecto", "entrevístame", "descubramos esto", "levanta el spec" | → FASE 0 (Selección) |
| "¿en qué quedamos?", "retomemos el spec", "continúa la entrevista" | → RESUME (detectar `.specfounder/session.md`) |
| "ya tengo el spec / blueprint claro" | → sugerir saltar a `/plan` (la-herreria, modo B) |
| código de cliente existente / "tengo un sistema legado" | → modo `existente` → sombrero Explorador (o `migration-wizard` si es migración de stack) |

---

*"De idea borrosa a SPEC desambiguado, una pregunta a la vez. Eso es El Entrevistador."*
