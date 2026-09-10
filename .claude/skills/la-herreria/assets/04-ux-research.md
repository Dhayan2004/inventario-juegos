# Asset #4 — UX Research

> *"Discovery before design. Sin esto, estás adivinando."*

## Qué Hace

Define quiénes son los usuarios reales del producto, cómo piensan, qué hacen hoy, y dónde se frustran. Cada decisión de diseño downstream — wireframes, flujos, pantallas — se ancla en esta investigación.

Produce tres tipos de documentos:

1. **Personas** — arquetipos derivados del VPC. Personajes para los que se diseña cada pantalla.
2. **Modelos Mentales** — cómo cada persona *piensa* sobre el dominio. Determina la arquitectura de información (asset 06) y los patrones de interacción.
3. **Journey Maps** — recorrido completo de cada persona hacia su objetivo: qué hace, qué piensa, qué siente, dónde se atasca.

---

## Inputs Requeridos

- `VPC-[nombre].md` — del asset 01. Personas se derivan de Customer Jobs y segmentos del VPC.
- `PDR-[nombre].md` — del asset 02. Contexto adicional del producto y su alcance.

---

## Referencias (deferred F-tighten)

- `.claude/skills/la-herreria/references/personas.md`
- `.claude/skills/la-herreria/references/mental-models.md`
- `.claude/skills/la-herreria/references/journey-mapping.md`

---

## Workflow

### Paso 1: Definir Personas

**Protocolo:**
1. Leer `VPC-[nombre].md` — cada tipo de persona que ejecuta Customer Jobs es persona candidata.
2. Agrupar jobs que hace el mismo tipo de persona (máximo 2-4 personas por producto).
3. Definir 1 persona primaria — el producto se optimiza para ella.
4. Para cada persona: Background, Goals (de VPC gains), Frustrations (de VPC pains), Current Behavior, Technical Comfort, Quotes, Design Implications.

**Output:** `docs/ux-research/personas/[persona-name].md` (una por persona).

---

### Paso 2: Mapear Modelos Mentales

Capturar cómo cada persona *piensa* sobre el dominio — no cómo funciona el sistema, sino cómo el usuario lo conceptualiza.

**Fuentes para identificar el modelo mental:**
- ¿Qué herramienta usa hoy? (el modelo mental está embebido en esa herramienta).
- ¿A qué objeto físico o proceso mapea este dominio en su mente?
- ¿Qué patrones de software conocido aplica? (inbox, file system, shopping cart, spreadsheet).

**Output:** `docs/ux-research/mental-models/[persona-name]-[dominio].md`.

---

### Paso 3: Mapear Journey Maps

Un journey map traza a una persona a través de un objetivo específico — desde que se da cuenta que necesita algo hasta que lo logra. Revela pain points que el producto debe resolver y oportunidades de deleite.

**5 fases del journey:**
1. **Become Aware** — qué dispara la necesidad.
2. **Decide** — cómo evalúa opciones.
3. **Act** — el recorrido dentro del producto (más largo).
4. **Verify** — cómo confirma que funcionó.
5. **Reflect** — qué opina de la experiencia.

**Para cada fase:** Pasos → Touchpoints → Pensamientos → Emociones 😤→😐→😊→😄 → Pain Points → Oportunidades.

**Output:** `docs/ux-research/journeys/[persona-name]-[objetivo].md`.

---

### Paso 4: Actualizar el VPC

Los hallazgos fluyen de regreso al VPC. Personas revelan cuáles Customer Jobs importan más. Journey maps revelan cuáles pains son más severos y cuáles gains son más valorados.

Actualizar `VPC-[nombre].md` con los hallazgos antes de continuar al asset 05.

---

## Estructura de Output

```
docs/ux-research/
├── personas/
│   ├── [persona-primaria].md
│   └── [persona-secundaria].md
├── mental-models/
│   ├── [persona-primaria]-[dominio].md
│   └── [persona-secundaria]-[dominio].md
└── journeys/
    ├── [persona-primaria]-[objetivo-principal].md
    └── [persona-secundaria]-[objetivo-principal].md
```

---

## Naming Convention

| Documento | Archivo |
|-----------|---------|
| Persona | `docs/ux-research/personas/[nombre-kebab].md` |
| Mental Model | `docs/ux-research/mental-models/[persona]-[dominio].md` |
| Journey Map | `docs/ux-research/journeys/[persona]-[objetivo].md` |

Nombres reales en kebab-case (ej: `sarah`, `marcus`).

---

## Reglas Críticas

- **2-4 personas máximo.** Más significa que el producto sirve a demasiados segmentos distintos.
- **1 persona primaria.** El producto se optimiza para ella. Las secundarias se benefician pero no dictan el diseño.
- **Mapear el estado actual primero.** Cómo el usuario hace el job HOY, sin el producto. Luego el estado futuro. La diferencia entre ambos es exactamente lo que el producto debe hacer.
- **Pain points del journey = features Must Have.** Si un pain aparece en la fase Act del journey, existe un Must Have en el story map.
- **NO inventar personas.** Se derivan del VPC. Si el VPC dice que los segmentos son X e Y, las personas son X e Y.

---

## Integración con Assets Downstream

| Asset | Cómo consume el UX Research |
|-------|----------------------------|
| User Stories (#5) | Customer Jobs → epics. Backbone del story map sigue el journey map |
| UX Design (#6) | Modelos mentales determinan IA y patrones de interacción |
| UI Design Workflow (#7) | Personas dictan dispositivos primarios (mobile/desktop), journey maps revelan momentos críticos |
| UI (#8) | Emociones del journey map informan tono visual y momentos de deleite (cargado vía Brand DNA voice.json post-add-ui-kit, R10) |
| Blueprint (#10) | Features Must Have priorizan las fases del plan de ejecución |

---

## Handoff al Asset #5

```
✅ Personas definidas: [N] personas ([nombre primaria] — primaria)
✅ Modelos mentales: [N] documentos
✅ Journey maps: [N] mapas
✅ VPC actualizado con hallazgos

Siguiente: User Stories (asset 05-user-stories.md)
Las personas y journeys alimentan directamente el story map —
cada actividad del backbone se deriva de los jobs y fases del journey.

¿Procedemos?
```
