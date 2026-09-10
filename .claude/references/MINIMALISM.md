# Minimalismo / YAGNI medible (C5 · Ponytail absorbido, NO instalado)

> **Qué es esto.** La doctrina de **minimalismo de código medible** de Forge Enterprise. Absorbe la
> *metodología* de Ponytail (la escalera de decisión + el benchmark adversarial reproducible) **sin
> instalar el plugin** — la lección Vercel (`-80% tools = +3× rendimiento`) prohíbe montar un segundo
> motor de minimalismo cuando Forge ya tiene Anti-Slop Gate + `el-evaluador` + `el-guardian`. Define
> tres cosas: (1) la **escalera de decisión "qué código NO escribir"** con su **Peldaño 0 ontológico**
> (el diferenciador que Ponytail no puede tener), (2) el **eje minimalismo/YAGNI** que se añade a la
> rúbrica de `el-evaluador`, y (3) la **metodología de benchmark adversarial** como activo de venta
> enterprise.
>
> **Decisión de producto (C5, docs/06 §C5):** absorber la metodología, **NO** la dependencia. El
> minimalismo pasa de ser un truco de eficiencia (Ponytail) a una **garantía de fidelidad al negocio**
> (Forge) vía el Peldaño 0 ontológico. Fuente: `docs/05` §2 + `docs/06` §C5.

- **Versión:** v0.1.0 (2026-06-30, C5 · Minimalismo / YAGNI medible)
- **Complementa:** `MINIMALISM.md` **previene** el drift ontología↔código *a priori*; `DRIFT_GATE.md` lo **detecta** *a posteriori*. Son la cara-A y cara-B del mismo eje.
- **Consumidor del score:** `el-evaluador` cablea el eje minimalismo en su rúbrica (otro proceso lo integra en el SKILL de `el-evaluador`; aquí se define el **criterio** y el **score**). No añade regla nueva a `CONSTRAINTS.md`.

---

## 1. La escalera de decisión — "qué código NO escribir"

Antes de escribir código, se recorre la escalera **de arriba hacia abajo** y se detiene en el primer
peldaño que resuelve. El código solo se escribe si ningún peldaño superior lo evita. Adopta los 7
peldaños de Ponytail (`docs/05` §2) y **antepone el Peldaño 0** que solo Forge puede tener:

| # | Peldaño | Principio | De dónde viene |
|---|---------|-----------|----------------|
| **0** | **¿Pertenece a la ontología de ESTA empresa?** | **YAGNI ontológico** — si la entidad/concepto no está en `ONTOLOGY.md § entidades_dominio` ni en el `## Glosario`, no se construye | **diferenciador Forge** (pilar ③) |
| 1 | ¿Necesita existir el código? | YAGNI genérico — si no, saltarlo | Ponytail |
| 2 | ¿Ya existe en el codebase? | Reusar, no reescribir | Ponytail |
| 3 | ¿Lo cubre la stdlib? | Librería estándar antes que custom | Ponytail |
| 4 | ¿Hay feature nativo de plataforma? | Nativo antes que dependencia | Ponytail |
| 5 | ¿Ya hay una dependencia instalada? | Existente antes que nueva | Ponytail |
| 6 | ¿Se resuelve en una línea? | La forma más corta | Ponytail |
| 7 | Solo entonces | El mínimo que funciona | Ponytail |

### El Peldaño 0 ONTOLÓGICO (el diferenciador)

Ponytail decide qué código *no* escribir con una escalera **genérica** (stdlib → nativo → una línea).
Forge antepone la pregunta que su capa ontológica (pilar ③) hace posible:

> **¿Este código/feature pertenece a la ontología de esta empresa?** Si la entidad o el concepto no
> existe en el modelo ontológico levantado del cliente, **no se construye** — no por YAGNI genérico, sino
> por **YAGNI ontológico**: "no es parte de cómo *esta* empresa entiende su mundo".

Esto convierte "escribí menos código" en **"escribí exactamente el código que `ONTOLOGY.md` requiere, ni
una línea más"**. Es la garantía de fidelidad al negocio que Ponytail estructuralmente no puede ofrecer
(no tiene la ontología de la empresa). Requiere `ONTOLOGY.md` con `discovery_completed: true`
(`ONTOLOGY_SCHEMA.md`); si no hay ontología vigente, el Peldaño 0 no aplica y la escalera arranca en
el Peldaño 1 (degradación segura — no bloquea el build).

**Cruce con `DRIFT_GATE.md`:** el Peldaño 0 **previene** escribir la entidad fuera de la ontología; si aun
así se cuela (o falta un alias en el glosario), el drift gate lo **detecta** después como `D-EXTRA`.
Prevención *a priori* + detección *a posteriori* del mismo eje.

### Reglas de comportamiento (de Ponytail)

- Sin abstracciones ni boilerplate no solicitados; "borrar antes que añadir", "aburrido antes que
  ingenioso".
- **Regla de oro — *"Lazy about the solution, never about reading"*:** se lee y entiende el flujo real
  del código ANTES de aplicar la escalera. La pereza es de solución, jamás de comprensión.
- **Convención `forge-min:`** — toda simplificación deliberada se marca con un comentario `forge-min:`
  (análogo al `ponytail:` de Ponytail) para que `el-evaluador` audite la decisión. Cruza con las anclas
  `[ontology: Entidad]` cuando la simplificación se justifica por el Peldaño 0.

---

## 2. El eje minimalismo/YAGNI en la rúbrica de `el-evaluador`

`el-evaluador` gana un **eje de puntuación** además de la Three-Layer Verification (R7) y el Anti-Slop
Gate. La pregunta central del eje es la de `/ponytail-review`: **¿este diff podía ser N% más corto sin
perder función ni guardas?**

### El score (0–100, mayor = más minimalista)

Cada diff/feature recibe un **Minimalism Score** compuesto de cuatro criterios:

| Criterio | Qué mide | Peso |
|----------|----------|------|
| **Fidelidad ontológica (Peldaño 0)** | ¿todo lo construido corresponde a `entidades_dominio`/glosario? cero `D-EXTRA` (ver `DRIFT_GATE.md`) | 40% |
| **Escalada bien recorrida (Peldaños 1–7)** | ¿se prefirió stdlib/nativo/existente/una-línea sobre custom/nueva-dep? | 30% |
| **Ausencia de bloat** | ¿sin abstracciones/boilerplate/config no solicitados? ¿sin gold-plating? | 20% |
| **Guardas intactas** | las excepciones intocables (§4) están **todas** presentes — es un **gate, no un peso negociable** | 10% (y **veto**) |

- **Umbral informativo:** un score < 60 es señal de over-engineering → `el-evaluador` lo reporta como
  `NEEDS_FIX` en el eje minimalismo (no un FAIL duro por sí solo, salvo que caiga el veto de §4).
- **Veto de seguridad:** si el criterio "Guardas intactas" no es 100%, el score minimalista **no importa**
  — es FAIL. El minimalismo NUNCA justifica quitar una guarda (§4). *"Perezoso, no negligente."*
- El score cita su evidencia: cada penalización apunta al archivo:símbolo o al hallazgo `D-EXTRA` del
  drift gate. No se inventan números (misma disciplina que el Build Confidence Score de `el-crisol`).

> **Frontera con el resto de `el-evaluador`.** El eje minimalismo **no reemplaza** ni la Three-Layer
> Verification (R7) ni el Anti-Slop Gate — los complementa. Un diff puede pasar syntax/runtime/system y
> aun así tener un Minimalism Score bajo (over-engineered pero funcional). Y `el-evaluador` sigue siendo el
> único writer de memoria (R5): si el patrón de bloat recurre, él lo promueve a lección — no este doc.

---

## 3. Metodología de benchmark adversarial reproducible (activo de venta)

Un comprador enterprise no compra "menos código"; compra **garantías cuantificadas con evidencia
adversarial**. Ponytail probó que se puede empaquetar minimalismo + prueba de no-regresión de seguridad
en un artefacto medible (`docs/05` §2.3). Forge **copia la metodología** (no el plugin) como su propio
benchmark publicable en un futuro `benchmarks/`.

### El diseño del benchmark (calcado de la metodología de Ponytail)

- **Brazos aislados sobre tareas idénticas:** `baseline` (sin doctrina), `forge` (escalera + Peldaño 0),
  y controles como `yagni-oneliner` (el system prompt de 7 palabras) para tener un piso de comparación.
- **Dos familias de tareas:**
  - **Feature (elección de alcance):** tickets de una línea donde el agente decide cuánto construir. La
    métrica es LOC/tokens/costo/tiempo. Referencia Ponytail: **−54% LOC, −22% tokens, −20% costo, −27%
    tiempo** vs baseline (`docs/05` §2.3) — ej. *date picker* −94% usando `<input type="date">` nativo en
    vez de una librería (Peldaño 4).
  - **Seguridad (no-regresión):** funciones ejecutadas **contra input adversarial real** (path traversal,
    SQL injection, tokens forjados) con checks **deterministas**. La tesis clave: solo el `yagni-oneliner`
    desnudo tiró una guarda (95%); la doctrina estructurada mantiene **100% de guardas preservadas**. El
    minimalismo ingenuo rompe seguridad; el minimalismo estructurado no.
- **Cómo Forge lo exhibe:** un par de números atado — **"−N% LOC con 100% de guardas de seguridad
  preservadas bajo input adversarial"**. La métrica de ahorro **nunca se muestra sin** la prueba de
  no-regresión de seguridad al lado. Ese par es la promesa vendible: eficiencia *demostrada* que no
  sacrifica seguridad.

> **Por qué esto le importa a Forge (no solo a Ponytail).** El diferenciador de Forge es el **Peldaño 0
> ontológico**: el benchmark de Forge puede mostrar un tercer eje que Ponytail no tiene — **cero drift
> ontología↔código** (medido con `DRIFT_GATE.md`). "Menos código, seguro, **y fiel al negocio del
> cliente**." Ese es el argumento de venta enterprise que Ponytail jamás podrá hacer.

---

## 4. Excepciones intocables (las guardas duras — NUNCA se simplifican)

Estas son las **mismas guardas duras de `el-guardian`** y del Anti-Slop Gate. Ningún peldaño de la
escalera, ningún score minimalista, ninguna optimización de LOC puede tocarlas:

- **Validación de input** (Zod en todo boundary externo — regla de código de Forja).
- **Manejo de errores.**
- **Seguridad** — todo lo que `el-guardian` protege (auth, RLS/tenant `MULTI_TENANCY.md`, secrets,
  OWASP). El `el-guardian` es el **freno** del minimalismo: valida que las simplificaciones no abrieron un
  hueco.
- **Accesibilidad** (a11y — gana sobre el schema cuando hay conflicto, Anti-Slop §8.1).
- **Features explícitamente pedidos** por el usuario/Blueprint.

Regla operativa: si aplicar un peldaño de la escalera tocaría cualquiera de estos, **no se aplica** — se
escribe el código completo. El veto del §2 hace esto verificable en la rúbrica.

---

## 5. Lo que Forge absorbe vs lo que NO instala (frontera explícita)

| De Ponytail | Forge | Por qué |
|-------------|-------|---------|
| Escalera de decisión (7 peldaños) | ✅ absorbe (+ Peldaño 0) | metodología, no código |
| Metodología de benchmark adversarial | ✅ absorbe (activo de venta, futuro `benchmarks/`) | `docs/05` §2.3 |
| Eje minimalismo/YAGNI | ✅ absorbe (rúbrica de `el-evaluador`) | solapa con Independent Evaluator |
| Convención de comentario de simplificación | ✅ absorbe como `forge-min:` | auditable por `el-evaluador` |
| **El plugin (skills/hooks/MCP de Ponytail)** | ❌ **NO instala** | lección Vercel: Forge ya tiene Anti-Slop + `el-evaluador` + `el-guardian`; un 2º motor de minimalismo crea solapamiento de hooks y viola "no añadir tools por si acaso" |

---

## 6. El contrato en una frase

Forge escribe **exactamente el código que la ontología de la empresa requiere, ni una línea más**: recorre
una escalera de decisión encabezada por el **Peldaño 0 ontológico** (YAGNI de fidelidad al negocio),
puntúa cada diff con un **eje minimalismo/YAGNI** en `el-evaluador` (con veto de seguridad — *perezoso,
no negligente*), y exhibe la garantía como un **benchmark adversarial reproducible** que ata `−N% LOC` a
`100% de guardas de seguridad preservadas`. Absorbe la *metodología* de Ponytail; jamás instala el plugin
(lección Vercel).

## Sources
- [web:github.com](https://github.com/DietrichGebert/ponytail) — repo Ponytail: escalera de decisión de 7 peldaños, niveles de intensidad, excepciones de seguridad, formato skill (v4.8.4, ~68.5k stars, MIT).
- [web:github.com](https://github.com/DietrichGebert/ponytail/blob/main/benchmarks/results/2026-06-18-agentic.md) — metodología de benchmark adversarial: 4 brazos aislados, tareas feature/seguridad, checks deterministas, números (−54% LOC, 100% guardas preservadas).
- `docs/05` §2 (Ponytail — minimalismo medible, §2.4 mapeo a Forge, §2.5 Peldaño 0 ontológico) + `docs/06` §C5.
