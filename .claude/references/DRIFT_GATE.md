# Drift Gate — coherencia ontología↔código (C4 · Graphify)

> **Qué es esto.** El contrato del **gate de coherencia ontológica**: un chequeo OPCIONAL que compara la
> ontología **prescrita** de la empresa (`ONTOLOGY.md` § `entidades_dominio` + `## Glosario`) contra el
> grafo **de facto** que se extrae del código generado, y reporta el **drift** entre ambos. Es la cara
> *a posteriori* del **Peldaño 0 ontológico** de `MINIMALISM.md`: Ponytail *previene* escribir código
> fuera de la ontología; el drift gate lo *detecta* después. **NO es una dependencia dura** — es un
> integration-point que, si el motor de grafo no está disponible, no corre y no rompe nada (degradación
> segura).
>
> **Decisión de producto (C4, docs/06 §C4):** Graphify **NO** es el store de la ontología (es
> descriptivo y de esquema fijo, no prescriptivo — `F-P5.4` "NO Graphify como memoria"). Es un MCP
> externo (YC S26, madurez a evaluar) que se usa **solo** como (a) auditoría del código generado y (b)
> detector de drift ontología↔código, alimentando a `el-evaluador`/`el-guardian`. Fuente: `docs/05` §5 +
> `docs/06` §C4.

- **Versión:** v0.1.0 (2026-06-30, C4 · Drift Gate / coherencia ontológica)
- **Complementa:** `ONTOLOGY_SCHEMA.md` (el "deber ser" prescrito) + `MINIMALISM.md` Peldaño 0 (la prevención *a priori* del mismo drift).
- **Consumidores:** una capa opcional de `el-evaluador` (auditoría del código) + un check pre-release de `/temple` (`project-auditor`). No añade regla nueva a `CONSTRAINTS.md`: es opt-in, no gate duro.

---

## 1. Por qué OPCIONAL y no dependencia dura

Graphify es un integration-point, **jamás una dependencia de arranque**. Tres razones lo mantienen fuera
del camino crítico:

- **Es externo y su madurez está a evaluar.** MCP de terceros (YC S26), esquema de grafo FIJO no
  configurable. Meterlo como dep dura violaría la lección Vercel (`-80% tools = +3× rendimiento`): no se
  añaden tools "por si acaso".
- **Su dirección de flecha es inversa a la nuestra.** Forge parte de la ontología *prescriptiva* y todo
  orbita ese modelo; Graphify *descubre* un grafo *descriptivo* del código que ya existe. Por eso NO
  puede ser el store de la ontología (`docs/05` §5.6) — solo un observador del código.
- **Degradación segura.** Si el motor de grafo no está instalado/configurado, el gate **no corre**: no
  emite drift, no bloquea nada, y el resto de la verificación (R7 Three-Layer, Anti-Slop, `el-guardian`)
  sigue igual. Ausencia de drift-report ≠ FAIL; es "no observado".

> **La frontera con la ontología (no confundir).** `ONTOLOGY.md` es la fuente de verdad prescriptiva
> (`ONTOLOGY_SCHEMA.md`). El grafo de Graphify es material de auditoría *derivado* del código. El
> gate **compara**, nunca **reescribe** la ontología a partir del grafo. Un motor descriptivo no dicta el
> "deber ser".

---

## 2. Qué compara el gate (los dos grafos)

El gate cruza **dos grafos de entidades + relaciones** y busca sus diferencias:

| | Grafo PRESCRITO (el "deber ser") | Grafo DE FACTO (el "ser") |
|---|---|---|
| Origen | `ONTOLOGY.md` § `entidades_dominio` (sustantivos canónicos del dominio) + `## Glosario / lenguaje propio de la empresa` | extraído del código generado por el motor de grafo (tree-sitter local + semántica) |
| Naturaleza | **prescriptivo** — lo que la empresa dice que su mundo contiene | **descriptivo** — lo que el código realmente modela (tablas, tipos, servicios, features) |
| Autoridad | fuente de verdad (`ONTOLOGY_SCHEMA.md`) | evidencia de auditoría (nunca fuente de verdad) |

**Unidad de comparación = la entidad de dominio**, no el símbolo de código. Antes de comparar, el gate
**normaliza** (el paso que evita ruido): mapea nombres de código (`CreditScore`, `credit_scores`,
`scoreService`) al sustantivo canónico de `entidades_dominio` usando el `## Glosario` como diccionario de
sinónimos/alias. Entidades de *framework/infra* (helpers, DTOs, adaptadores, `organization_id`/
`memberships` de M6) **no cuentan como dominio** y quedan fuera del cruce — no son drift, son plumbing.

Además de entidades, el gate coteja **relaciones**: una relación del glosario ("un `préstamo` pertenece a
un `cliente`") que en el código no tiene su FK/asociación equivalente es una relación faltante; una
relación en el código entre dos entidades de dominio que la ontología no declara es una relación no
prescrita.

---

## 3. Cómo se reporta el drift (las tres clases)

El gate produce un **drift report** con tres clases de hallazgo, cada uno con su lectura de negocio:

| Clase | Definición | Lectura | Severidad por defecto |
|-------|-----------|---------|----------------------|
| **D-EXTRA** (código sin correlato ontológico) | entidad/relación de dominio en el grafo del código que **no existe** en `entidades_dominio`/glosario | posible **scope-creep / gold-plating** (la lección Vercel) — se construyó algo que la empresa no pidió, o hay un término no levantado en la ontología | **major** (revisar) |
| **D-MISSING** (ontología sin código) | entidad/relación en `entidades_dominio`/glosario que el código **no implementa** | posible **feature faltante** — el "deber ser" no está construido aún | **minor** (informativo — puede ser trabajo pendiente legítimo, no un defecto) |
| **D-MISMATCH** (relación divergente) | la entidad existe en ambos, pero sus **relaciones no coinciden** (FK/asociación de más o de menos) | el modelo de datos derivó del modelo de negocio | **major** |

**Reglas de reporte:**

- El report NO es un veredicto binario por sí mismo: es **evidencia** que `el-evaluador`/`el-guardian`
  ponderan. Un D-EXTRA puede ser scope-creep real **o** un alias que falta en el glosario — la
  desambiguación es humana/agente, no automática.
- Cada hallazgo **cita ambos lados**: el nodo del grafo del código (archivo:símbolo) y la clave
  ontológica (`entidades_dominio[i]` o término del glosario) — o su ausencia. Sin las dos anclas, no es
  un hallazgo accionable.
- El report se emite como artefacto adjunto (no muta `plan.json` ni memoria). Si se promueve a lección
  recurrente, eso es trabajo de `el-evaluador` (R5 sole-writer) — el gate **solo observa**.
- **Confianza heredada del motor:** los nodos vienen con marca `EXTRACTED / INFERRED / AMBIGUOUS` del
  grafo; un D-EXTRA sobre un nodo `AMBIGUOUS` baja a informativo (no se acusa scope-creep con evidencia
  débil).

---

## 4. Dónde se engancha (los dos puntos de integración)

El gate NO es un hook ni una regla dura. Se cablea en **dos** lugares, ambos opt-in y con degradación
segura si el motor no está:

1. **Capa opcional de `el-evaluador` — auditoría del código generado.**
   Tras la Three-Layer Verification, si el motor de grafo está disponible, `el-evaluador` puede correr el
   drift gate como **evidencia adicional** para el eje minimalismo/YAGNI (`MINIMALISM.md`): un D-EXTRA es
   señal directa de código fuera de la ontología. NO cambia el veredicto PASS/FAIL por sí solo (es
   informativo); refuerza el juicio del evaluador. `el-evaluador` sigue siendo el único writer de memoria
   (R5) — el gate le entrega el report, no escribe él.

2. **Check pre-release de `/temple` (`project-auditor`) — coherencia full-project.**
   `/temple` audita TODO `src/` pre-release. El drift gate encaja ahí como una **dimensión opcional de
   coherencia ontológica** (junto a Seguridad, Datos/RLS, Cache, Calidad Web): corre el grafo sobre `src/`
   completo y reporta el drift contra `ONTOLOGY.md`. Si el motor no está → `project-auditor` **no penaliza
   lo no observable** (mismo patrón que su degradación de Supabase MCP/Codex): la dimensión sale como "no
   corrida", no como cero.

> **Frontera con `el-guardian`.** `el-guardian` audita **seguridad** (adversarial, Codex). El drift gate
> audita **coherencia de dominio** (ontología↔código). Comparten el rol de "evidencia de auditoría que
> alimenta el veredicto", pero no se solapan: uno caza vulnerabilidades, el otro caza scope-creep y
> features faltantes. Ambos degradan seguro si su motor externo no está.

---

## 5. Flujo del gate (cuando el motor está disponible)

```
0. ¿Motor de grafo (Graphify MCP) disponible?  NO → gate NO corre (degradación segura, no FAIL)
1. Extraer grafo DE FACTO del código (tree-sitter local + semántica) — ámbito: feature (el-evaluador) o src/ completo (/temple)
2. Cargar grafo PRESCRITO: ONTOLOGY.md § entidades_dominio + ## Glosario (con discovery_completed: true)
3. Normalizar nombres de código → sustantivos canónicos usando el glosario (alias/sinónimos); descartar plumbing/framework/infra
4. Cruzar entidades + relaciones → clasificar en D-EXTRA / D-MISSING / D-MISMATCH
5. Bajar severidad de hallazgos sobre nodos AMBIGUOUS/INFERRED (evidencia débil)
6. Emitir drift report (artefacto adjunto) → entregar a el-evaluador (eje YAGNI) o a project-auditor (dimensión coherencia)
```

Si `ONTOLOGY.md` no existe o `discovery_completed: false`, no hay grafo prescrito con qué comparar → el
gate **no corre** (misma degradación segura: no hay "deber ser" que auditar).

---

## 6. El contrato en una frase

El drift gate es un **integration-point opcional**, no una dependencia: cuando el motor de grafo está,
compara las **entidades y relaciones de dominio prescritas** por `ONTOLOGY.md` contra el grafo **de facto
del código** y reporta el drift (código sin ontología = posible scope-creep; ontología sin código =
posible feature faltante) como **evidencia** para `el-evaluador` y `/temple`; cuando no está, no corre y
no rompe nada. Es el detector *a posteriori* de la desviación que el Peldaño 0 ontológico de
`MINIMALISM.md` previene *a priori* — nunca la fuente de verdad, siempre su espejo de auditoría.

## Sources
- [docs:graphify] — motor de grafo de conocimiento del código (tree-sitter local + MCP, YC S26). Validar con `find-docs` (`libraryName: "graphify"`, `query: "code knowledge graph MCP entities relations 2026"`) antes de habilitarlo en un proyecto real (R13). Si no resuelve, el gate permanece deshabilitado (degradación segura).
- [web:github.com](https://github.com/safishamsi/graphify) — repo, esquema fijo de entidades/relaciones, confidence scoring (EXTRACTED/INFERRED/AMBIGUOUS), integración MCP.
- `docs/05` §5 (Graphify — drift ontología↔código, uso B "detector de divergencia") + `docs/06` §C4.
