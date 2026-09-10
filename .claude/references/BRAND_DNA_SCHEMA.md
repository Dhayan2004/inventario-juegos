# Brand DNA Schema de Forja

> **Schema version:** v1.1.0 (cited as **R-005** in `.claude/memory/references.md`).
>
> **Changelog:**
> - **v1.1.0** (2026-05-08, F3-tighten-brand-dna): keyed spacing objects + motion enums + archetype docs/enforcement clarification. Rationale en [memory:decisions#D-008]; fricciones disparadoras en [memory:errors#E-002], [memory:errors#E-003], [memory:errors#E-004].
> - **v1.0.0** (2026-05-07): initial schema, used during F3-S1 (`add-ui-kit`) y F3-S2 (`impeccable`). Brand.json + voice.json + brand.css + showcase generation validados con TECH UTILITY preset.

Documento de trabajo para definir un sistema de marca estructurado que permita a agentes IA generar UI production-ready sin caer en diseño genérico.

Contexto: Forja genera código de UI para apps SaaS. El objetivo del Brand DNA es funcionar como contrato operativo antes de crear componentes: suficientemente estricto para evitar AI slop, pero flexible para marcas distintas.

---

## 1. Visual Posture

La postura visual debe describirse con pocos ejes canónicos. No debe ser una nube de adjetivos. Cada eje debe tener consecuencias concretas sobre layout, tipografía, color, componentes y motion.

### 1.1 Ejes canónicos recomendados

| Eje | Pregunta que responde | Impacta principalmente |
|---|---|---|
| Density | ¿La UI respira mucho o comprime información? | Spacing, layout, tablas, dashboards |
| Expression | ¿La marca se expresa fuerte o se contiene? | Color, imagen, composición, motion |
| Geometry | ¿Las formas son suaves, neutrales o filosas? | Radius, iconos, borders, cards |
| Warmth | ¿Se siente humana/cercana o clínica/técnica? | Copy, color, ilustración, microcopy |
| Editoriality | ¿La UI se siente como herramienta o publicación? | Headlines, ritmo visual, hero sections |
| Materiality | ¿Es plana, táctil o con profundidad marcada? | Sombras, borders, surfaces, capas |

Para Forge/Forja, una primera lectura sería:

```json
{
  "density": 3,
  "expression": 4,
  "geometry": 4,
  "warmth": 3,
  "editoriality": 4,
  "materiality": 3
}
```

Traducción: denso pero no abrumador, expresivo sin espectáculo, geométrico, editorial, oscuro, con sensación de oficio y precisión.

### 1.2 Escala 1-5 por eje

#### Density

| Nivel | Definición | Ejemplos |
|---|---|---|
| 1 | Muy aireado, pocas decisiones por pantalla | Apple marketing, Linear landing |
| 2 | Espacioso, navegación clara, baja fricción | Airbnb, Dropbox |
| 3 | Balanceado, útil para SaaS | Stripe, Vercel dashboard |
| 4 | Denso, muchas herramientas visibles | Figma, Notion database |
| 5 | Máxima densidad operativa | Bloomberg Terminal, trading dashboards |

#### Expression

| Nivel | Definición | Ejemplos |
|---|---|---|
| 1 | Casi invisible, marca contenida | GitHub, Linear |
| 2 | Sutil, tokens sobrios | Vercel, Basecamp |
| 3 | Reconocible pero funcional | Stripe, Notion |
| 4 | Fuerte, memorable, con color/ritmo propio | Cash App, Ramp |
| 5 | Protagónica, casi campaña visual | MSCHF, Teenage Engineering |

#### Geometry

| Nivel | Definición | Ejemplos |
|---|---|---|
| 1 | Muy soft, redondeado, amigable | Duolingo, Airbnb |
| 2 | Soft-profesional | Slack, Asana |
| 3 | Neutral, sistema limpio | Stripe, Notion |
| 4 | Angular, técnico, preciso | Linear, Vercel, Forge |
| 5 | Agresivo, editorial, filoso | Balenciaga, gaming UIs premium |

#### Warmth

| Nivel | Definición | Ejemplos |
|---|---|---|
| 1 | Clínico, institucional | IBM, Oracle |
| 2 | Técnico y sobrio | Linear, GitHub |
| 3 | Seguro y humano sin ser cute | Stripe, Vercel |
| 4 | Conversacional, cercano | Mailchimp, Loom |
| 5 | Emocional, juguetón | Duolingo, Oatly |

#### Editoriality

| Nivel | Definición | Ejemplos |
|---|---|---|
| 1 | Herramienta pura | GitHub issues, Jira |
| 2 | Utilitaria con polish | Linear, Vercel dashboard |
| 3 | Product editorial | Stripe, Ramp |
| 4 | Fuerte voz editorial | The Browser Company, Forge |
| 5 | Revista/campaña | The Verge, Pitch decks editoriales |

#### Materiality

| Nivel | Definición | Ejemplos |
|---|---|---|
| 1 | Flat, casi sin capas | Linear |
| 2 | Borders y estados sutiles | GitHub, Vercel |
| 3 | Superficies con tacto ligero | Stripe, Raycast |
| 4 | Capas evidentes, sombras, profundidad | macOS, Arc |
| 5 | Táctil/físico/skeuomorphic | Teenage Engineering, audio tools |

### 1.3 Cuántos ejes bastan

Para una marca SaaS, 4 a 6 ejes son suficientes. Menos de 4 deja demasiada ambigüedad. Más de 7 suele convertirse en ruido, salvo que la marca ya tenga un design system maduro.

Regla práctica:

- 3 ejes: útil para briefing rápido, insuficiente para generación consistente.
- 4-6 ejes: ideal para Brand DNA operativo.
- 7-10 ejes: solo si cada eje valida algo programáticamente.
- Más de 10: probablemente estás describiendo gusto, no sistema.

---

## 2. Brand Archetypes

### 2.1 Framework recomendado

Usaría Mark & Pearson como vocabulario base, no como motor absoluto.

Razón: los 12 arquetipos son familiares para humanos y para LLMs, suficientemente expresivos y fáciles de mapear a tono. Pero no son precisos para UI por sí solos. "Outlaw" no te dice radius, density, motion ni contraste.

Recomendación:

```json
{
  "archetype": {
    "primary": "Creator",
    "secondary": "Sage",
    "shadow_to_avoid": ["Magician", "Hero"],
    "ui_translation": "craft, precision, visible structure, no spectacle",
    "copy_translation": "diagnosis, oficio, claridad, no hype"
  }
}
```

Para Forge:

- Primary: Creator
- Secondary: Sage
- Tensión útil: Outlaw controlado cuando critica el vibe coding
- Evitar: Magician, porque empuja hacia "AI magic"; Hero, porque empuja hacia grandilocuencia.

### 2.2 Declarado o derivado

Debe estar declarado explícitamente, pero con traducción operativa.

No basta esto:

```json
{
  "primary": "Outlaw"
}
```

Sí sirve esto:

```json
{
  "primary": "Outlaw",
  "allowed_behaviors": [
    "Puede desafiar convenciones de categoría",
    "Puede usar copy confrontativo contra el status quo",
    "Puede romper simetría visual cuando ayuda al mensaje"
  ],
  "forbidden_behaviors": [
    "No sacrifica accesibilidad",
    "No insulta al usuario",
    "No convierte la UI en caos visual"
  ]
}
```

### 2.3 Cómo enseñar un archetype a un agente IA

Un agente respeta mejor un arquetipo cuando recibe consecuencias, no etiquetas.

Ejemplo para Outlaw:

```json
{
  "archetype": "Outlaw",
  "copy_rules": [
    "Confronta el status quo, no al usuario",
    "Usa frases cortas y declarativas",
    "Evita lenguaje corporativo conciliador"
  ],
  "ui_rules": [
    "Puede usar contraste fuerte",
    "Puede romper layouts simétricos",
    "Debe mantener jerarquía, legibilidad y estados claros"
  ],
  "avoid": [
    "Caos visual",
    "Ironía adolescente",
    "Estética edgy sin propósito"
  ]
}
```

---

## 3. Component-Level Rules

### 3.1 Reglas universales de mala ejecución

#### Buttons

Mala ejecución:

1. Primary button con gradiente diagonal genérico.
2. Más de un primary visual compitiendo en la misma vista.
3. Hover/focus/disabled inexistentes.
4. Iconos decorativos que no aclaran la acción.
5. Texto vago: "Get Started", "Learn More", "Submit" sin contexto.

Reglas mínimas:

- `button.primary`: una acción principal, contraste alto, sin gradiente default.
- `button.secondary`: menor peso visual, no compite con primary.
- `button.ghost`: solo para acciones terciarias o navegación.
- Estados requeridos: default, hover, active, focus, disabled, loading.

#### Cards

Mala ejecución:

1. Cards dentro de cards sin necesidad.
2. Tres feature cards iguales con iconos genéricos.
3. Sombra pesada sobre dark UI.
4. Border, shadow, blur y gradient al mismo tiempo.
5. Contenido sin jerarquía: título, texto y CTA con pesos similares.

Reglas mínimas:

- Cards solo para items repetidos, herramientas enmarcadas o modals.
- Una card debe tener propósito: agrupar, comparar, ejecutar o revelar.
- En dark UI, preferir border/surface antes que shadow.
- No usar cards como decoración de toda la página.

#### Forms

Mala ejecución:

1. Placeholder usado como label.
2. Error solo por color.
3. Focus invisible.
4. Inputs con height inconsistente.
5. Mensajes de error genéricos: "Invalid input".

Reglas mínimas:

- Label visible por defecto.
- Error cercano al campo y accionable.
- Focus state evidente.
- Tap target mínimo: 44px en mobile.
- Required/optional claro.

#### Navigation

Mala ejecución:

1. Estado activo ambiguo.
2. Navegación crítica escondida por estética.
3. Menú mobile diferente en estructura al desktop sin razón.
4. Nav flotante decorativa que compite con contenido.
5. Labels inconsistentes entre rutas.

Reglas mínimas:

- Active state visible.
- Jerarquía clara: primary nav, secondary nav, utility nav.
- Mobile definido explícitamente.
- No más de una navegación principal.

#### Modals

Mala ejecución:

1. Modal sin título específico.
2. Cierre ambiguo o ausente.
3. Acción destructiva sin confirmación.
4. Modal demasiado ancho para su contenido.
5. Sin focus trap o navegación de teclado.

Reglas mínimas:

- Título contextual.
- Acción primaria clara.
- Cancel/close visible.
- Escape y click outside definidos.
- Focus management obligatorio.

### 3.2 Reglas universales vs dependientes de marca

Universales:

- Contraste mínimo.
- Estados interactivos.
- Labels visibles.
- Jerarquía clara.
- No layout shift innecesario.
- No usar color como única señal.

Dependientes de postura:

- Radius.
- Densidad.
- Nivel de color.
- Sombras/profundidad.
- Movimiento.
- Tono de microcopy.

Ejemplo:

Una card para Linear y una card para Forge pueden compartir estructura, contraste y estados. Pero Linear debería tender a `materiality: 1-2`, `expression: 1-2`, radius bajo y surfaces sobrias. Forge puede usar más contraste, borde naranja puntual, headline más editorial y microcopy más afilado.

### 3.3 Minimum viable component spec

Sí. El Brand DNA debe definir pocos componentes base con variantes obligatorias.

MVP recomendado:

```json
{
  "button": ["primary", "secondary", "ghost", "danger"],
  "input": ["text", "search", "textarea", "select"],
  "card": ["default", "interactive", "metric", "empty"],
  "navigation": ["sidebar", "topbar", "tabs", "breadcrumb"],
  "modal": ["confirm", "form", "detail"],
  "feedback": ["toast", "alert", "banner", "inline_error"],
  "data": ["table", "list", "metric", "empty_state"]
}
```

No conviene definir 30 variantes al inicio. El sistema debe saber derivar nuevos componentes desde tokens, posture y reglas.

---

## 4. Anti-Slop Específico

### 4.1 Lista negra concreta

Patrones visuales y de copy que deberían disparar rechazo o warning fuerte:

1. Gradiente `from #6366F1 to #A855F7` como hero o CTA principal.
2. Gradiente diagonal azul/morado tipo `linear-gradient(135deg, #3B82F6, #8B5CF6)`.
3. Tailwind purple/indigo default como identidad: `#8B5CF6`, `#6366F1`, `#A855F7`.
4. Fondo blanco + Inter + CTA morado + tres cards centradas.
5. Glassmorphism: `backdrop-blur-xl` + border blanco translúcido + blobs.
6. Blobs decorativos con `blur-3xl`, especialmente morado/azul/rosa.
7. Iconos Lucide genéricos en círculos de color sin intención.
8. Tres feature cards con títulos tipo "Fast", "Secure", "Scalable".
9. Hero con eyebrow "Introducing the future of..." sin producto concreto.
10. Headlines con "Build better products faster" o equivalente.
11. Cards con shadow grande: `shadow-2xl` como default.
12. Border radius gigante en SaaS serio: `rounded-3xl` por todas partes.
13. Botones pill por defecto sin relación con la marca.
14. Secciones alternando cards flotantes sobre fondos levemente tintados.
15. Mockups falsos dentro de browser chrome genérico.
16. Data dashboards con números inventados y gráficas sin labels.
17. Avatares circulares random para social proof sin fuente real.
18. Testimonios genéricos sin nombre/cargo verificable.
19. Animaciones fade-up aplicadas a cada bloque de la página.
20. Copy con "seamless", "effortless", "unlock", "supercharge", "next-gen".

### 4.2 Regla universal de tipografía

Regla madre: la tipografía debe tener roles, no solo nombres.

Mal:

```json
{
  "headline": "Inter",
  "body": "Inter"
}
```

Mejor:

```json
{
  "display": {
    "family": "Geist",
    "use_for": ["page titles", "section headlines"],
    "weight_range": [600, 800],
    "tracking": "normal"
  },
  "body": {
    "family": "Geist",
    "use_for": ["paragraphs", "forms", "navigation"],
    "weight_range": [400, 600],
    "line_height": 1.5
  },
  "mono": {
    "family": "Geist Mono",
    "use_for": ["code", "technical labels", "metadata"],
    "avoid_for": ["long paragraphs", "marketing headlines"]
  }
}
```

Reglas universales:

- No introducir una segunda display font sin permiso.
- No usar mono para párrafos largos.
- No usar tracking negativo por defecto.
- No escalar font-size con viewport width.
- No usar una font display expresiva si el resto del sistema es sobrio.
- Definir line-height por rol.

### 4.3 Cómo formalizar "no uses Tailwind purple default"

No conviene una lista infinita de colores prohibidos. Conviene combinar:

1. Paleta autorizada.
2. Familias de hue prohibidas o restringidas.
3. Distancia mínima respecto a defaults conocidos.
4. Regla de intención: cualquier color fuera de tokens requiere rol.

Ejemplo:

```json
{
  "color_policy": {
    "mode": "allowlist_first",
    "allowed_token_only": true,
    "restricted_hues": [
      {
        "name": "default_ai_purple_blue",
        "hue_range": [235, 285],
        "allowed_only_if": ["brand_declares_purple_as_primary"]
      }
    ],
    "forbidden_examples": ["#6366F1", "#8B5CF6", "#A855F7"],
    "new_color_requires": ["semantic_role", "contrast_check", "brand_rationale"]
  }
}
```

---

## 5. Variantes y Contextos

### 5.1 Adaptación por superficie

La marca debe conservar identidad, pero no replicar exactamente la misma UI en todos los medios.

Nunca cambia:

- Paleta base y roles semánticos.
- Tipografía o fallback equivalente.
- Tono de voz.
- Arquetipo operativo.
- Principios de composición.
- Reglas de accesibilidad.

Sí cambia:

- Densidad.
- Tamaño tipográfico.
- Contraste.
- Motion.
- Nivel de detalle.
- Jerarquía de información.

Ejemplo de contextos:

```json
{
  "contexts": {
    "web_app": {
      "density": "balanced",
      "navigation": "full",
      "motion": "crisp"
    },
    "mobile_native": {
      "density": "slightly_spacious",
      "tap_target_min": 44,
      "navigation": "platform_native"
    },
    "vertical_video": {
      "contrast": "higher",
      "type_scale": "larger",
      "safe_area": true,
      "copy": "shorter"
    },
    "pitch_slides": {
      "editoriality": "higher",
      "density": "lower",
      "chart_labels": "large"
    },
    "transactional_email": {
      "motion": "none",
      "fallback_fonts": ["Arial", "Helvetica"],
      "layout": "single_column_first"
    }
  }
}
```

### 5.2 Modos

Sí debería tener modos, pero pocos.

Recomendados:

- `light` / `dark`
- `compact` / `comfortable`
- `formal` / `direct`
- `marketing` / `product`

No recomendaría agregar `playful`, `serious`, `premium`, `bold`, etc. como modos si no tienen consecuencias programáticas.

Buen modo:

```json
{
  "mode": "compact",
  "changes": {
    "spacing_scale": 0.85,
    "font_size_delta": -1,
    "card_padding": "smaller"
  }
}
```

Modo malo:

```json
{
  "mode": "premium",
  "description": "make it feel expensive"
}
```

### 5.3 B2B serio vs B2C playful

El mismo schema sirve. Lo que cambia son los presets iniciales.

B2B serio:

```json
{
  "density": 3,
  "expression": 2,
  "geometry": 3,
  "warmth": 2,
  "editoriality": 2,
  "materiality": 2
}
```

B2C playful:

```json
{
  "density": 2,
  "expression": 4,
  "geometry": 2,
  "warmth": 5,
  "editoriality": 3,
  "materiality": 3
}
```

No necesitas templates distintos, necesitas defaults distintos y validadores sensibles a postura.

---

## 6. Motion Philosophy

### 6.1 Dimensiones brand-defining

Más allá de duración y easing, motion define marca por:

| Dimensión | Pregunta |
|---|---|
| Energy | ¿Se mueve con calma, precisión o impulso? |
| Elasticity | ¿Hace bounce, snap o glide? |
| Directionality | ¿Tiene dirección física clara? |
| Sequencing | ¿Anima todo junto o en cascada? |
| Distance | ¿Los elementos viajan mucho o poco? |
| Responsiveness | ¿Responde instantáneo al input o se siente ceremonial? |
| Continuity | ¿Las transiciones conectan estados o solo decoran? |
| Restraint | ¿Cuánto movimiento se permite antes de sentirse excesivo? |

Para Forge:

```json
{
  "motion_personality": {
    "energy": "precise",
    "elasticity": "snap_not_bounce",
    "directionality": "mechanical",
    "sequencing": "subtle_stagger",
    "distance": "short",
    "restraint": "high"
  }
}
```

Frase: Forge se mueve como una herramienta bien calibrada: rápido, direccional, sin magia.

#### Enum closures por dimensión (R-005 v1.1.0)

Cada dimensión de `motion.personality` es un **enum cerrado** validado schema-level (aplica `[memory:lessons#L-003]` al schema canónico — whitelist explícita, nunca free-string):

| Dimensión | Enum válido (R-005 v1.1.0) |
|-----------|----------------------------|
| `energy` | `precise` · `calm` · `violent` · `ceremonial` · `mechanical` |
| `elasticity` | `snap_not_bounce` · `bounce` · `glide` · `rigid` |
| `directionality` | `mechanical` · `organic` · `physical` · `abstract` |
| `sequencing` | `subtle_stagger` · `uniform` · `cascaded` · `instant_all` |
| `distance` | `short` · `medium` · `long` |
| `restraint` | `high` · `medium` · `low` |

Valores fuera del enum → schema validation fail. add-ui-kit Discovery FRESH ofrece dropdown en este bloque, no free-text. **Source de la enumeración:** [memory:errors#E-003] + [memory:decisions#D-008]. **Citation grammar para downstream:** los outputs (brand.json) cumplen el enum por construcción; impeccable y otros consumers asumen el enum sin lookup ad-hoc.

### 6.2 Reglas universales de motion

- Respetar `prefers-reduced-motion`.
- No animar above-fold con fade-in mayor a 300ms.
- Hover/press feedback debe sentirse menor a 150ms.
- No animar propiedades que causen layout shift sin razón.
- No usar stagger en listas largas.
- No animar texto largo línea por línea.
- Loading state debe comunicar progreso o estado, no solo entretener.
- Motion debe reforzar causalidad: el usuario entiende qué cambió y por qué.
- **Solo `transform` / `opacity`** (lista `SAFE` de `motion.ts`); nunca `width/height/top/left` (check 11 del gate).
- **Exit ≈ 75% de enter** (salir es más rápido que entrar); render condicional siempre con enter/exit, nunca "aparece de golpe" (motion-slop, B1).
- **`reduce_motion_default: true`** en producto de trabajo: parallax = planos a distinta velocidad como máximo; fly-through 3D solo en landing de campaña y con pausa on-page (WCAG 2.2.2). Ver `DESIGN_ENRICH.md` §3.
- **`signature_element`**: UNA pieza de motion/forma que identifica a la marca (el "clic" de Teenage Engineering, el snap de Linear). Si no hay una, el motion es de comité.

### 6.3 Motion personality de marcas admirables

- Linear: instantánea, sobria, casi invisible.
- Stripe: fluida, clara, con profundidad editorial controlada.
- Apple: coreografiada, física, calmada.
- Raycast: rápida, utilitaria, con precisión de keyboard-first.
- Cash App: expresiva, elástica, segura de sí misma.
- Teenage Engineering: táctil, mecánica, juguetona sin parecer infantil.
- Vercel: mínima, nítida, enfocada en feedback.

---

## 7. Validación Programática

### 7.1 Chequeos para un visual linter

Orden recomendado:

1. Accesibilidad: contraste, tamaño táctil, focus visible.
2. Token compliance: colores, fonts, radius, spacing.
3. Component compliance: variantes, estados, estructura.
4. Anti-slop detection: patrones visuales/copy prohibidos.
5. Layout integrity: overflow, solapamientos, responsive.
6. Density match: spacing y cantidad de elementos contra postura.
7. Color role usage: primary/accent/surface usados correctamente.
8. Typography hierarchy: tamaños, pesos, line-height y roles.
9. Motion compliance: duración, easing, reduced motion.
10. Voice compliance: palabras prohibidas, tono, CTA.
11. Archetype consistency: juicio semántico.
12. Context fit: web, mobile, email, slides, video.

### 7.2 Binarios vs juicio

Binarios:

- Contraste AA.
- Color fuera de tokens.
- Font fuera de tokens.
- Radius fuera de rango.
- Falta de focus state.
- Falta de label en form.
- Uso de palabra prohibida.
- Uso de patrón prohibido detectado.
- Tap target menor al mínimo.

De juicio:

- Jerarquía visual.
- Sensación de marca.
- Nivel de editorialidad.
- Si el layout se siente genérico.
- Si el archetype se respeta.
- Si la densidad corresponde al contexto.

Semi-binarios:

- Exceso de primary color.
- Demasiados tamaños tipográficos.
- Demasiados niveles de shadow.
- Demasiadas variantes de radius.
- Copy demasiado largo para el contexto.

### 7.3 Brand Score

Sí puede existir, pero debe tratarse como señal, no como verdad.

Propuesta:

```json
{
  "brand_score_weights": {
    "accessibility": 30,
    "token_compliance": 25,
    "component_compliance": 20,
    "anti_slop": 15,
    "voice_and_archetype": 10
  }
}
```

Interpretación:

- 90-100: listo.
- 75-89: usable con ajustes.
- 60-74: inconsistente.
- Menos de 60: probablemente AI slop o Brand DNA incompleto.

---

## 8. Edge Cases y Conflictos

### 8.1 Accesibilidad vs marca

Gana accesibilidad.

Pero el schema debe anticiparlo con tokens alternativos:

```json
{
  "colors": {
    "primary": "#E85420",
    "primary_accessible_on_light": "#A02408",
    "primary_accessible_on_dark": "#FF8C5C"
  }
}
```

Regla: si el accent no contrasta para texto, se usa para border, icono, focus o background decorativo; no para texto pequeño.

### 8.2 Componentes no anticipados

El agente debe derivar desde:

1. Propósito del componente.
2. Tokens.
3. Postura visual.
4. Componente base más cercano.
5. Reglas universales.

Ejemplo: una data table compleja en una marca minimal no debe volverse vacía. Debe priorizar legibilidad, densidad operativa, sticky headers, estados y jerarquía sobria.

Regla:

```json
{
  "unknown_component_policy": {
    "derive_from": ["purpose", "tokens", "visual_posture", "nearest_component"],
    "must_include": ["states", "responsive_behavior", "accessibility"],
    "requires_rationale": true
  }
}
```

### 8.3 Señales de Brand DNA mal definido

El problema no siempre es la implementación. A veces el schema está flojo.

Señales:

- Tiene muchos adjetivos y pocas reglas.
- Declara colores sin roles.
- Declara fonts sin uso.
- Tiene arquetipo sin consecuencias.
- No define componentes base.
- No tiene anti-patterns concretos.
- No define contextos.
- No define qué hacer cuando accesibilidad choca con marca.
- Usa términos como "premium", "modern", "clean" sin traducción visual.
- No hay ejemplos positivos y negativos.
- Todo está permitido.
- Nada está priorizado.

---

## 9. Schema Actualizado

### 9.1 brand.json propuesto

> **Schema version:** v1.1.0 (post F3-tighten-brand-dna).
>
> **Cambios v1.0 → v1.1 ([memory:decisions#D-008]):**
>
> 1. `tokens.spacing.section_y` array → keyed object `{sm, md, lg}` ([memory:errors#E-002])
> 2. `tokens.spacing.component_gap` array → keyed object `{xs, sm, md, lg}` ([memory:errors#E-002])
> 3. `motion.personality.*` enums cerrados por dimensión ([memory:errors#E-003] · aplica `[memory:lessons#L-003]` al schema)
> 4. `archetype.allowed_behaviors` / `forbidden_behaviors` clarificados como **DOCUMENTACIÓN, NOT enforcement** ([memory:errors#E-004])
>
> **Distinción docs vs enforcement (importante):**
>
> Los campos `archetype.allowed_behaviors` y `archetype.forbidden_behaviors` son arrays de strings descriptivos en lenguaje natural. **Son DOCUMENTACIÓN para humanos y agentes downstream — citables en JSDoc, prompts, copy guidelines, README — pero NO son enforcement-able programáticamente.** El enforcement de marca vive en campos estructurados machine-readable: `tokens` + `anti_slop` + `validation` + `component_rules`. `el-evaluador` valida contra los machine-readable; cita los descriptivos en outputs informativos.

```json
{
  "schema_version": "1.1.0",
  "brand": {
    "name": "Carlos Domínguez",
    "product": "Forge",
    "tagline": "El código mediocre se genera. El gran software se forja.",
    "positioning": "El puente entre el vibe coding caótico y el software bien construido.",
    "category": "AI-assisted software craft system",
    "audience": ["founders", "indie hackers", "dev leads", "B2B tech-ready LATAM"],
    "archetype": {
      "primary": "Creator",
      "secondary": "Sage",
      "controlled_tension": "Outlaw",
      "shadow_to_avoid": ["Magician", "Hero"],
      "ui_translation": "craft, precision, visible structure, no spectacle",
      "copy_translation": "diagnosis, oficio, clarity, no hype"
    }
  },
  "visual_posture": {
    "density": 3,
    "expression": 4,
    "geometry": 4,
    "warmth": 3,
    "editoriality": 4,
    "materiality": 3
  },
  "tokens": {
    "colors": {
      "primary": "#E85420",
      "primary_deep": "#A02408",
      "accent": "#FF8C5C",
      "secondary": "#1A2238",
      "background": "#0A0A0A",
      "surface": "#161616",
      "surface_elevated": "#202020",
      "border": "#2A2A2A",
      "text": "#FFFFFF",
      "text_muted": "#A0A0A0",
      "text_subtle": "#888888",
      "success": "#00C896",
      "danger": "#FF3B5B",
      "warning": "#FFB020"
    },
    "typography": {
      "display": {
        "family": "Geist",
        "weights": [600, 700, 800],
        "use_for": ["page_titles", "section_headlines", "hero_statements"]
      },
      "body": {
        "family": "Geist",
        "weights": [400, 500, 600],
        "line_height": 1.5
      },
      "mono": {
        "family": "Geist Mono",
        "use_for": ["code", "technical_labels", "metadata"],
        "avoid_for": ["long_paragraphs", "marketing_headlines"]
      }
    },
    "shape": {
      "radius_sm": 6,
      "radius_md": 12,
      "radius_lg": 16,
      "radius_lg_max": 16,
      "border_width": 1
    },
    "spacing": {
      "unit": 8,
      "density": "balanced",
      "section_y":     { "sm": 48, "md": 72, "lg": 96 },
      "component_gap": { "xs": 8, "sm": 12, "md": 16, "lg": 24 }
    }
  },
  "component_rules": {
    "button": {
      "variants": ["primary", "secondary", "ghost", "danger"],
      "rules": [
        "Only one primary action per view section",
        "No diagonal gradients",
        "Focus, hover, active, disabled and loading states required",
        "Icon must clarify the action"
      ]
    },
    "card": {
      "variants": ["default", "interactive", "metric", "empty"],
      "rules": [
        "No nested cards",
        "Use border or surface before heavy shadow in dark UI",
        "Card must group, compare, execute or reveal"
      ]
    },
    "form": {
      "variants": ["text", "search", "textarea", "select"],
      "rules": [
        "Visible label by default",
        "Error message must be textual and near the field",
        "Focus state must be visible",
        "Mobile tap targets minimum 44px"
      ]
    },
    "navigation": {
      "variants": ["sidebar", "topbar", "tabs", "breadcrumb"],
      "rules": [
        "Active state must be unambiguous",
        "Do not hide critical navigation for aesthetics",
        "Mobile behavior must be defined"
      ]
    },
    "modal": {
      "variants": ["confirm", "form", "detail"],
      "rules": [
        "Contextual title required",
        "Escape/cancel behavior required",
        "Destructive actions require explicit confirmation",
        "Focus trap required"
      ]
    }
  },
  "hero_layout": "authored",                 // authored | split-authorized — el default texto-izq/media-der solo si CHOSEN.md o este campo lo autoriza (check 12 del gate)
  "signature_element": "snap de 140ms en todo control — el clic mecánico de la marca",
  "motion": {
    "safe_props": ["transform", "opacity"],   // lista SAFE de motion.ts — nunca width/height/top/left (check 11)
    "exit_ratio": 0.75,                       // exit ≈ 75% enter
    "reduce_motion_default": true,            // producto de trabajo: reduce por defecto; landing de campaña puede poner false con pausa on-page
    "parallax_max_layers": 2,                 // planos a distinta velocidad como máximo; 0 = sin parallax
    "personality": {
      "energy": "precise",
      "elasticity": "snap_not_bounce",
      "directionality": "mechanical",
      "sequencing": "subtle_stagger",
      "distance": "short",
      "restraint": "high"
    },
    "durations_ms": {
      "instant": 80,
      "fast": 140,
      "base": 220,
      "slow": 320
    },
    "rules": [
      "Respect prefers-reduced-motion",
      "No above-fold fade-in longer than 300ms",
      "No bounce unless explicitly declared",
      "Avoid layout-shifting animation"
    ]
  },
  "anti_slop": {
    "forbidden_colors": ["#6366F1", "#8B5CF6", "#A855F7"],
    "forbidden_patterns": [
      "diagonal blue-purple gradient hero",
      "glassmorphism cards over blurred blobs",
      "three generic feature cards with icons",
      "Inter on white with purple CTA as default SaaS identity",
      "rounded-3xl everywhere",
      "shadow-2xl as default depth",
      "generic browser mockup with fake dashboard"
    ]
  },
  "contexts": {
    "web_app": {
      "density": "balanced",
      "motion": "crisp",
      "navigation": "full"
    },
    "mobile_native": {
      "density": "slightly_spacious",
      "tap_target_min": 44,
      "navigation": "platform_native"
    },
    "vertical_video": {
      "contrast": "higher",
      "type_scale": "larger",
      "safe_area": true,
      "copy": "shorter"
    },
    "pitch_slides": {
      "editoriality": "higher",
      "density": "lower"
    },
    "transactional_email": {
      "motion": "none",
      "fallback_fonts": ["Arial", "Helvetica"],
      "layout": "single_column_first"
    }
  },
  "validation": {
    "min_contrast_body": 4.5,
    "min_contrast_large": 3,
    "max_fonts": 2,
    "max_radius_values": 3,
    "max_primary_color_usage_percent": 18,
    "brand_score_weights": {
      "accessibility": 30,
      "token_compliance": 25,
      "component_compliance": 20,
      "anti_slop": 15,
      "voice_and_archetype": 10
    }
  }
}
```

### 9.2 voice.json propuesto

```json
{
  "schema_version": "1.1.0",
  "voice": {
    "name": "Carlos",
    "language": "es-419",
    "tone_axes": {
      "directness": 4,
      "warmth": 3,
      "technicality": 3,
      "provocation": 3,
      "hype": 1
    },
    "principles": [
      "Diagnóstico, no crítica",
      "Artesano, no técnico",
      "Confianza serena",
      "Build in public",
      "Proceso antes que polish"
    ],
    "vibe": "Un colega afilado que ya descifró algo y te enseña el atajo",
    "audience": "Emprendedores y B2B Tech-Ready en LATAM",
    "code_switching": {
      "allowed": ["Claude Code", "MCP", "vibe coding", "ship", "deploy", "Blueprint", "prompt", "merge"],
      "rule": "Anglicismos técnicos sin traducir cuando son parte natural del oficio"
    },
    "safe_words": [
      "forjar",
      "yunque",
      "fragua",
      "Blueprint",
      "build in public",
      "craft",
      "intencional",
      "Forge",
      "La Forja",
      "manifiesto del Forjador"
    ],
    "avoid_words": [
      "revolutionary",
      "revolucionario",
      "cutting-edge",
      "AI-powered como cualidad principal",
      "best-in-class",
      "leverage",
      "synergy",
      "disrupt",
      "ecosystem como relleno",
      "unlock your potential",
      "Act now",
      "Limited time",
      "barato",
      "fácil",
      "increíble",
      "seamless experience",
      "effortless",
      "supercharge your workflow",
      "game-changing",
      "next-generation",
      "transform your business",
      "all-in-one platform",
      "scale with confidence"
    ],
    "sentence_rules": {
      "prefer": [
        "Frases cortas",
        "Verbos concretos",
        "Diagnóstico antes que promesa",
        "Metáforas de oficio cuando ayuden"
      ],
      "avoid": [
        "Superlativos vacíos",
        "Promesas absolutas",
        "Corporate SaaS filler",
        "Hype de IA mágica"
      ]
    },
    "hooks": [
      "El código mediocre se genera. El gran software se forja.",
      "Planifica primero. Construye después. Forja siempre.",
      "No vibe coding. Craft coding.",
      "Forge it.",
      "El yunque no improvisa."
    ],
    "cta_style": "Directo, no pushy",
    "cta_examples": [
      "Si te sirve, compártelo.",
      "Pruébalo en tu próximo proyecto y avísame.",
      "El link está en mi bio.",
      "¿Qué piensas? Te leo en comentarios.",
      "Forge it."
    ],
    "pacing": {
      "words_per_minute": 165,
      "pause_after_hook_ms": 400
    }
  }
}
```

---

## 10. Recomendación Final

El Brand DNA no debe intentar describir toda la marca como si fuera un brand book. Debe actuar como un contrato de generación.

La estructura ideal combina:

1. Tokens permitidos.
2. Postura visual con 4-6 ejes.
3. Arquetipo traducido a reglas.
4. Componentes mínimos.
5. Anti-patterns concretos.
6. Contextos de adaptación.
7. Validación programática.

La clave contra el AI slop no es solo prohibir cosas. Es darle al agente una gramática suficiente para tomar buenas decisiones cuando el componente no estaba previsto.
