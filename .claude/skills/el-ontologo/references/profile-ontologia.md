# Perfil de dominio `ontologia` — referencia de `el-ontologo`

> Este es el **perfil de dominio `ontologia`** anunciado como punto de extensión en
> [`el-entrevistador/references/spine.md`](../../el-entrevistador/references/spine.md). Reusa la
> **espina universal** (las 6 ranuras) y el **motor** de `el-entrevistador` (grill-me, igualdad
> semántica, CHECKPOINT, recomendar-y-confirmar, resume) **sin tocarlos** — solo cambia (a) cómo se
> etiquetan las 6 ranuras, (b) el guion de preguntas, (c) qué cuenta como glosario, y (d) cómo se
> emite el resultado.
>
> El sujeto del levantamiento NO es un producto de software: es **el "ser" de la empresa** — su
> identidad, propósito, mercado, problema, significado de marca y restricciones. Output = `ONTOLOGY.md`
> regido por [`ONTOLOGY_SCHEMA.md`](../../../references/ONTOLOGY_SCHEMA.md).

---

## La espina universal aplicada a `ontologia`

Las 6 ranuras (1–6) y las claves `s1..s6` del ledger se conservan (igual que en `software`); solo
cambia la **etiqueta** y la **pregunta esencial**.

| # | Ranura universal | Etiqueta `ontologia` | Pregunta esencial | Lente |
|---|---|---|---|---|
| 1 | Visión / Norte | **Propósito y Norte de la empresa** | ¿Por qué existe esta empresa y hacia dónde apunta? | negocio |
| 2 | Actores | **Segmento y Actores** | ¿A quién sirve y quién participa? (ICP + JTBD) | negocio |
| 3 | Elementos | **Problema y Propuesta de Valor** | ¿Qué dolor real resuelve y con qué oferta? | negocio |
| 4 | Estructura / Flujo | **Modelo Operativo** | ¿Cómo gana y entrega valor? | negocio |
| 5 | Forma / Construcción | **Identidad y Significado de Marca** | ¿De qué está "hecha" simbólicamente la empresa? | marca |
| 6 | Restricciones | **Restricciones y Requisitos de Seguridad** | ¿Qué límites no-negociables (legales, técnicos, regulatorios) aplican? | ambas |

> El **sustrato** de una empresa (ranura 5, "sobre qué base se construye") es su **significado de
> marca** — el arquetipo, el código simbólico, el lenguaje propio. Por eso la ranura 5 es el lente de
> **marca** (Estudio), no la arquitectura técnica.

---

## Mapeo de ranuras → claves del `ONTOLOGY_SCHEMA`

Cada ranura puebla una parte del frontmatter machine-readable + su trozo narrativo:

| Ranura | Clave(s) del schema | Narrativa |
|---|---|---|
| s1 Propósito | `empresa.{nombre,sector}` + North Star/manifiesto | (encabezado) |
| s2 Segmento | `segmento_y_actores[]` (actor/rol/jtbd) | — |
| s3 Problema/Valor | `problema_priorizado` + `propuesta_de_valor` + `entidades_dominio` | — |
| s4 Modelo Operativo | `empresa.modelo_operativo` | `## Cómo opera esta empresa` |
| s5 Marca | `marca.{arquetipo_primario,arquetipo_secundario,codigo_simbolico}` | `## Glosario / lenguaje propio` |
| s6 Restricciones | `restricciones[]` + `requisitos_seguridad[]` | `## Decisiones y supuestos abiertos` |

`entidades_dominio` es un **subproducto** de s3: los sustantivos canónicos que aparecen al describir
problema y propuesta. El sombrero arquitecto los destila; alimentan el Data Model del Blueprint.

---

## Orden de lente (resuelve el solapamiento Founder OS ↔ Estudio)

`docs/04` §"se fusionan o separados" señala que la validación de problema/ICP está **duplicada** en
FOS (nativa) y Estudio (`novolabs-discovery`). Regla canónica de Forge Enterprise:

1. **Lente NEGOCIO primero** (ranuras s1–s4 + s6 parcial) — guion derivado del **método de Founder OS**
   ([`fos-method.md`](fos-method.md)). Captura problema/ICP/JTBD **una sola vez**. Founder OS es la
   **fuente canónica** de la validación de negocio.
2. **Lente MARCA después** (ranura s5) — guion derivado del **método de Estudio**
   ([`estudio-method.md`](estudio-method.md)). **Consume** lo ya capturado por el lente negocio (ICP,
   problema) y **no lo re-pregunta**; añade arquetipo, código simbólico y lenguaje propio encima del
   contexto validado.

> Founder OS valida → Estudio comunica. El lente marca NUNCA re-levanta problema/ICP; si lo necesita,
> lo cita del frontmatter ya escrito.

---

## Guion de preguntas (IDs estables `S{n}.Q{m}`)

Mismo motor grill-me que `software`: **una pregunta por turno**, cada una con **"Mi recomendación:"**,
sin avanzar de ranura con ramas abiertas, CHECKPOINT antes de cada pregunta. Los IDs son estables para
que el cursor de resume sea inequívoco (`S{n}.Qa{m}` para preguntas ad-hoc).

### S1 · Propósito y Norte (lente negocio)
- **S1.Q1** — ¿A qué se dedica la empresa, en una sola oración? (→ `empresa.nombre`, `empresa.sector`)
- **S1.Q2** — ¿Por qué existe — qué cambiaría en el mundo si no existiera? (manifiesto, 1 frase no genérica)
- **S1.Q3** — ¿Cuál es su North Star (la métrica que mide si está cumpliendo su propósito)?

### S2 · Segmento y Actores (lente negocio)
- **S2.Q1** — ¿Quién es el cliente **específico** (no "todos") — descríbelo como una persona real?
- **S2.Q2** — ¿Qué otros actores participan (compra, usa, paga, decide)? ¿Son la misma persona o distintas?
- **S2.Q3** — Por cada actor: ¿qué **trabajo** intenta hacer? (JTBD: "Cuando [contexto], quiero [trabajo], para [resultado]")

### S3 · Problema y Propuesta de Valor (lente negocio)
- **S3.Q1** — ¿Cuál es el dolor #1 del cliente, **en sus propias palabras**? (cita textual → evidencia)
- **S3.Q2** — ¿Qué evidencia tienes de que ese problema es real, urgente y pagado? (→ `customer_problem_fit`)
- **S3.Q3** — ¿Cuál es la propuesta de valor en un titular? ¿Qué la diferencia de las alternativas?
- **S3.Q4** — Al describir lo anterior, ¿qué **sustantivos** son centrales al dominio? (→ `entidades_dominio`)

### S4 · Modelo Operativo (lente negocio)
- **S4.Q1** — ¿Cómo gana dinero la empresa (modelo de ingreso)?
- **S4.Q2** — ¿Cómo entrega el valor (el flujo de "cómo opera", de cliente a resultado)?

### S5 · Identidad y Significado de Marca (lente marca — consume s1–s4)
- **S5.Q1** — Si la empresa fuera una persona, ¿qué **arquetipo** Jung domina? (1 primario + 1 secundario, validado contra el propósito de s1)
- **S5.Q2** — En esta categoría/cultura, ¿qué **significa** simbólicamente lo que vende — no lo que ES, lo que la gente SIENTE? (código simbólico — se DESCUBRE de lo que el cliente dice, no se proyecta)
- **S5.Q3** — ¿Qué **lenguaje propio** usa la empresa — términos que dice distinto al resto? (→ `## Glosario / lenguaje propio`)

> El levantamiento profundo del código simbólico (impronta, 3 capas de beneficio, metáfora — método
> Klaric de 7 pasos) puede despacharse al sombrero de marca; ver [`estudio-method.md`](estudio-method.md).
> Si el cliente no quiere ir tan profundo, `marca.codigo_simbolico.estado: "no_levantado"` es válido y
> no bloquea la emisión.

### S6 · Restricciones y Requisitos de Seguridad (ambos lentes)
- **S6.Q1** — ¿Qué restricciones no-negociables aplican (legales, contractuales, técnicas, de negocio)?
- **S6.Q2** — ¿Qué datos sensibles maneja y qué regulaciones le aplican? (→ `requisitos_seguridad[]`, semilla DevSecOps de S1)

---

## Canon / Glosario (para este perfil)

El glosario de `ontologia` es el **lenguaje propio de la empresa** (cómo nombra su negocio, su
cliente, su oferta). Vive en `## Glosario / lenguaje propio de la empresa` dentro de `ONTOLOGY.md` y
es la **capa padre** del `CONTEXT.md` funcional (modelo de dos capas, `ONTOLOGY_SCHEMA` §6). Mismo
dogma que el Glosarista de software: un concepto = un término, definición de **qué ES**, sinónimos al
banquillo. Lo mantiene [`assets/ontology-glossarist.md`](../assets/ontology-glossarist.md).

## Decisiones irreversibles (para este perfil)

No son ADRs técnicos: son **decisiones de empresa** difíciles de revertir, sorprendentes y con
trade-off real (p. ej. "solo B2B enterprise", "modelo de ingreso por suscripción anual", "el
arquetipo es El Forajido"). Viven en `## Decisiones y supuestos abiertos`. Las maneja
[`assets/ontology-architect.md`](../assets/ontology-architect.md), que además destila
`entidades_dominio` y `requisitos_seguridad`.

---

## Diferencias con el perfil `software` (resumen)

| | `software` (el-entrevistador) | `ontologia` (el-ontologo) |
|---|---|---|
| Sujeto | un producto | la empresa |
| Dir de trabajo | `.specfounder/` | `.ontologia/` |
| Draft vivo | `SPEC.draft.md` + `CONTEXT.draft.md` | `ONTOLOGY.draft.md` |
| Artefacto final | `SPEC.md` + `CONTEXT.md` + `docs/adr/` | `ONTOLOGY.md` + `ontology/evidence/` |
| Glosario | términos del producto (capa derivada) | lenguaje de la empresa (capa padre) |
| "Decisiones irreversibles" | ADRs técnicos | decisiones de empresa |
| Emisión | adaptador `forge` → `/plan` | [`emit-ontology.md`](emit-ontology.md) → Fase 0 / `/plan` |
| Fork | Explorador (brownfield) | source-reader (lee FOS/Estudio) |

El **motor** (grill-me, CHECKPOINT, resume, igualdad semántica) es **el mismo**; ver
[`el-entrevistador/references/state-schema.md`](../../el-entrevistador/references/state-schema.md)
como protocolo canónico de memoria — `el-ontologo` lo reusa con dir `.ontologia/` y draft
`ONTOLOGY.draft.md`.
