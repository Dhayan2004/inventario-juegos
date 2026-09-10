<!-- Portado y adaptado de SpecFounder v2 (domains/_spine.md + domains/software.md).
     SpecFounder es MIT © Ing. Oscar Lobo. Adaptado para Forge Enterprise — skill `el-entrevistador` (Fase 0). -->

# La espina universal — referencia de `el-entrevistador`

> Este archivo define la **espina universal** de descubrimiento: las **6 ranuras (slots)** que estructuran todo el SPEC, y su **etiquetado** para el único dominio activo hoy: `software`.
>
> El método de descubrimiento es **agnóstico de dominio por diseño**. Lo que cambia entre dominios **no es el motor** (las preguntas afiladas, la igualdad semántica, el canon/glosario, el protocolo de CHECKPOINT, recomendar-y-confirmar, el levantamiento de la Visión), sino **cómo se nombran las 6 secciones, qué cuenta como glosario y cómo se emite el resultado**.
>
> En Forge Enterprise **solo `software` está activo**. Esta arquitectura de ranuras existe precisamente para que perfiles futuros se cuelguen sin tocar el motor — ver "Punto de extensión" más abajo. **No implementes otros perfiles en esta fase.**

---

## Las 6 ranuras universales

Cada ranura tiene un número fijo (1–6) y una pregunta esencial. Un perfil de dominio solo cambia la **etiqueta** de cada ranura; el número, su orden y su intención se conservan.

| # | Ranura universal | Pregunta esencial | Qué captura |
|---|---|---|---|
| 1 | **Visión / Norte** | ¿Hacia dónde apunta esto y por qué existe? | El "Norte" del proyecto (≤ 2 párrafos, producto del levantamiento de la Visión). |
| 2 | **Actores** | ¿Quién o qué participa? | Las entidades protagonistas. |
| 3 | **Elementos** | ¿Qué hace o qué contiene? | Las unidades de valor. |
| 4 | **Estructura / Flujo** | ¿En qué orden se recorre o se ordena? | La secuencia. |
| 5 | **Forma / Construcción** | ¿Sobre qué base se construye? | El sustrato. |
| 6 | **Restricciones** | ¿Qué límites invisibles aplican? | Lo no-negociable. |

> La numeración de ranuras (1–6) y las claves `s1..s6` del ledger (`.specfounder/session.md`) se conservan en **todos** los dominios; solo cambia su **etiqueta** según el perfil activo.

---

## Perfil activo: `software`

> **domain:** `software`
> **Salida:** adaptador `forge` ÚNICAMENTE — el SPEC neutral se entrega a `/plan` (skill `la-herreria`) vía `references/emit-forge.md`.
> **Espina:** las 6 ranuras conservan su nombre clásico de software.

Aplica a cualquier stack o tecnología (no está casado con ninguno): sistemas backend, apps móviles/escritorio, APIs, sitios y aplicaciones web, CLIs, librerías, etc.

### Mapeo de ranuras → secciones del SPEC

| Ranura | Sección del SPEC (`software`) |
|---|---|
| 1 Visión | **Visión del Producto** |
| 2 Actores | **Usuarios y Casos de Uso** |
| 3 Elementos | **Funcionalidades por Módulo** |
| 4 Estructura/Flujo | **Flujos de Usuario** |
| 5 Forma | **Arquitectura** |
| 6 Restricciones | **Requisitos No Funcionales** |

Estas 6 secciones, en este orden, son la estructura canónica de `SPEC.draft.md` para el dominio `software`. Cada sombrero de fase escribe la sección que le corresponde y mantiene IDs de pregunta estables `S{n}.Q{m}` (y `S{n}.Qa{m}` para preguntas de aclaración/follow-up), donde `{n}` es el número de ranura.

### Canon / Glosario

Términos únicos del dominio del problema (entidades, conceptos de negocio). **No** conceptos generales de programación. Viven en `CONTEXT.draft.md`. Su propósito —igualdad semántica— es que el usuario y la IA usen las mismas palabras con el mismo significado, sin redefinirlas en cada momento.

### Decisiones irreversibles

ADRs clásicos (`.specfounder/adr/`): elección de base de datos, patrón de arquitectura, proveedor de auth, etc., cuando cumplen los 3 criterios: difíciles de revertir, sorprendentes, y con trade-off real.

### Notas del perfil

- En la Sección 5 (**Arquitectura**) el agente pregunta el stack/tecnología que usa el equipo; **no asume ninguno**. Si el usuario dice "a decidir", el sombrero de arquitectura propone una opción concreta y justificada (recomendar-y-confirmar).

---

## Artefactos paralelos (universales en todos los dominios)

Estos dos artefactos acompañan al SPEC y no son una de las 6 ranuras; existen en cualquier dominio.

- **Canon / Glosario** (`.specfounder/CONTEXT.draft.md`): un concepto = un término. En `software` es el vocabulario del dominio del problema. Su propósito —igualdad semántica— es idéntico en cualquier perfil.
- **Decisiones irreversibles** (`.specfounder/adr/`): decisiones difíciles de revertir, sorprendentes y con trade-off real. En `software` son ADRs.

---

## Cómo lo usa `el-entrevistador`

1. El orquestador (`SKILL.md`) fija el dominio. **Hoy siempre es `software`** (no se pregunta; es el único activo).
2. Carga el perfil correspondiente, que **renombra las 6 ranuras** y ajusta las preguntas guía.
3. Cada sombrero de fase formula las preguntas de su ranura (no las genéricas), aplicando preguntas afiladas e IDs `S{n}.Q{m}` / `S{n}.Qa{m}` estables.
4. Cada sombrero lee y escribe los drafts de `.specfounder/` (`SPEC.draft.md`, `CONTEXT.draft.md`, `adr/`) y aplica el protocolo de **CHECKPOINT**: persiste el avance en `session.md` ANTES de preguntar al usuario.
5. Al cierre, la emisión usa el adaptador **`forge`** (`references/emit-forge.md`): el SPEC neutral se entrega a `/plan` (skill `la-herreria`).

---

## Punto de extensión (perfiles que cuelgan de esta espina)

La arquitectura de 6 ranuras es deliberadamente abstracta para que se le cuelguen perfiles nuevos **sin tocar el motor de entrevista**. En Forge Enterprise:

- **`software` (este skill, `el-entrevistador`):** el perfil de la Fase 0 — levanta el spec funcional de un producto. Es el que documenta este archivo.
- **`ontologia` (M3, skill `el-ontologo` — ✅ CONSTRUIDO):** levantamiento del "ser" de la empresa (identidad, propósito, mercado, problema, significado de marca y restricciones), no de un producto. Reusa estas mismas 6 ranuras con etiquetas propias y un canon distinto (el lenguaje de la empresa). Es la **Fase −1** que precede a `el-entrevistador`. Vive en [`../../el-ontologo/references/profile-ontologia.md`](../../el-ontologo/references/profile-ontologia.md) — el motor (grill-me, igualdad semántica, CHECKPOINT, resume) se reusó **sin modificarse**, exactamente como este punto de extensión preveía.
- **Fase posterior — perfiles creativos (W2, no en este ciclo):** estructuras no-software (p. ej. narrativas, series de contenido) que también renombran las 6 ranuras; su "glosario" es una **biblia** (nombres, lugares, reglas del mundo) y sus "decisiones irreversibles" son reglas de continuidad/canon.

> Patrón para añadir un perfil (el que siguió `ontologia`): crea su propio archivo de perfil que mapee las 6 ranuras a etiquetas y preguntas del nuevo dominio, define qué cuenta como su canon y sus decisiones irreversibles, y **deja el motor intacto**. **No implementes los perfiles creativos ahora.**
