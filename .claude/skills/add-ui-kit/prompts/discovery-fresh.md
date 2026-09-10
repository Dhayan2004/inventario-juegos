# Discovery FRESH — Brand DNA interview para greenfield

> Prompt operativo. Cuando `add-ui-kit` corre en Mode FRESH, leé este archivo y conducí los 6 bloques en orden.
>
> **Source schema:** [memory:references#R-005] (`.claude/references/BRAND_DNA_SCHEMA.md`).
> **Output esperado:** Discovery answer set → consumo por `prompts/generate-brand-json.md` + `prompts/generate-voice-json.md`.

---

## Reglas del intérprete

1. Una pregunta a la vez. No batchear.
2. Si el usuario duda, ofrecer el default declarado (preset asociado al bloque).
3. Capturar respuestas en estructura whitelist — no `z.record(z.any())`. Aplica [memory:lessons#L-003].
4. Si Carlos provee un brief informal upfront, mapear a las 6 respuestas y **leer el mapeo de vuelta** para confirmación antes de seguir.
5. Si una respuesta es ambigua (ej: "es como Stripe"), pedir UNA aclaración concreta y luego seguir.
6. NO inventar respuestas. Si el usuario dice "no sé", capturar `unknown` + ofrecer preset.

---

## Bloque (a) — Identidad

> Objetivo: capturar metadata estática que va al campo `brand` del schema (R-005 sección 9.1).

### Preguntas

1. **`brand.name`** — ¿Cómo se llama la marca / persona / organización detrás del producto?
2. **`brand.product`** — ¿Cómo se llama el producto? (puede coincidir con name si es solo)
3. **`brand.tagline`** — Una frase de ≤ 12 palabras que resume el producto. Si dudás, podemos volver al final.
4. **`brand.positioning`** — Una oración: "<Product> es el <category> que <single core promise>".
5. **`brand.category`** — ¿En qué categoría compite? (ej: "AI-assisted writing tool", "B2B fintech", "developer-first analytics")
6. **`brand.audience`** — Lista de 1-4 audiencias prioritarias. Concretas, no demográficas vacías.

### Default

Si Carlos pide skip:
- `name` ← el nombre del directorio del repo
- `product` ← name (mismo)
- `tagline` ← `null` + flag para volver al final
- `positioning` ← `null` + flag
- `category` ← inferir del README.md o package.json `description`
- `audience` ← `["unknown — pending discovery"]`

### Validación

```typescript
{
  name:        z.string().min(2).max(60),
  product:     z.string().min(2).max(60),
  tagline:     z.string().max(120).nullable(),
  positioning: z.string().max(200).nullable(),
  category:    z.string().min(3).max(80),
  audience:    z.array(z.string().min(3).max(80)).min(1).max(4),
}
```

---

## Bloque (b) — Archetype (Mark + Pearson)

> Objetivo: declarar `archetype` con `primary` + `secondary` + `shadow_to_avoid` (R-005 sección 2).

### Pregunta

> Voy a leer los 12 arquetipos de Mark + Pearson con su traducción a UI/copy. Decime cuál se siente como el primary del producto, cuál el secondary, y cuál(es) el shadow a evitar (1-2).

Leer al usuario el contenido de `references/archetypes-mark-pearson.md` (tabla completa). El usuario elige por nombre.

### Default

Si el usuario duda:
- primary: `Creator` (default Forja-aligned, sirve a productos de oficio + dev)
- secondary: `Sage`
- shadow_to_avoid: `[Magician, Hero]` (los 2 más comunes en SaaS slop: AI magic + grandilocuencia)

### Validación

```typescript
{
  primary:           z.enum(ARCHETYPES_12),  // ver references/archetypes-mark-pearson.md
  secondary:         z.enum(ARCHETYPES_12).optional(),
  controlled_tension: z.enum(ARCHETYPES_12).optional(),
  shadow_to_avoid:   z.array(z.enum(ARCHETYPES_12)).max(3),
  ui_translation:    z.string().min(10).max(200),  // derivada del primary
  copy_translation:  z.string().min(10).max(200),  // derivada del primary
}
```

`ARCHETYPES_12 = ['Innocent', 'Sage', 'Explorer', 'Outlaw', 'Magician', 'Hero', 'Lover', 'Jester', 'Everyman', 'Caregiver', 'Ruler', 'Creator']`

`ui_translation` y `copy_translation` se autogeneran usando la lookup table en `references/archetypes-mark-pearson.md`. Mostrarlos al usuario y permitir override de 1 línea.

---

## Bloque (c) — Visual Posture (6 ejes 1-5)

> Objetivo: capturar los 6 ejes canónicos de R-005 sección 1.1.

### Paso 1 — Presentar las 5 direcciones visuales PRIMERO

Antes de cualquier pregunta de ejes, leer `references/directions.md` y mostrar al usuario la **tabla resumen de las 5 direcciones** (id + mood en una línea + acento + los 6 valores de posture):

| # | Direction | Mood | Acento |
|---|-----------|------|--------|
| 1 | Editorial Monocle (`editorial-monocle`) | Print-magazine, serif, papel off-white | Rust cálido |
| 2 | Modern Minimal (`modern-minimal`) | Software-native, near-greyscale, un acento | Cobalt |
| 3 | Warm & Soft (`warm-soft`) | Crema, radii suaves, friendly fintech | Terracotta |
| 4 | Tech Utility (`tech-utility`) | Data-dense, mono-friendly | Signal green |
| 5 | Brutalist Experimental (`brutalist-experimental`) | Type gritada, grid visible | Hot red |

> Pregunta: "¿Cuál de estas 5 direcciones se acerca a lo que buscás? Elegí **1-5**, decí **custom** si ninguna encaja y armamos los 6 ejes desde cero, o **semilla** si querés salir del prior con N variantes de entropía externa (Discover, D-037)."

### Paso 2 — Bifurcación según la respuesta

**Si el usuario elige 1-5 (una direction):**
1. Capturar `_baseline_preset = <id de la direction>` (ej: `modern-minimal`).
2. Cargar **verbatim** de `references/directions.md` los 6 ejes de posture de esa direction Y los tokens OKLch (van 1:1 al output, sin re-mapear — regla 1 de directions.md). Esto **salta** la pregunta eje-por-eje (Paso 3) y el bloque (e) de tokens abiertos: la direction YA los provee.
3. Nombrar 1-2 reference apps de la direction para anclar el lenguaje (regla 4 de directions.md).
4. Ofrecer la ÚNICA personalización permitida: el **accent override** (un solo token `--accent`). Si el accent propuesto cae en hue [235°, 285°] y `archetype.primary != Magician` → disparar el anti-slop gate inline (ver bloque (e)). El resto de la paleta queda fija.
5. NO combinar direcciones. Si el usuario quiere mezclar dos → ofrecer `custom` (regla 5).

**Si el usuario elige `custom`:** correr el Paso 3 (los 6 ejes eje por eje) y luego el bloque (e) completo de tokens.

**Si el usuario elige `semilla`:** Discover con entropía externa (`la-herreria/references/design-discover.md`):
1. `bash scripts/design-seed.sh <slug> 5` → `design-lab/<fecha>-<slug>/v1..v5/SEED.md` (PRNG de shell; el agente NO inventa la semilla).
2. Cada variante mapea su semilla → dirección (paleta OKLch · layout · tipo · motivo) y emite los 6 ejes de posture como cualquier `custom`; screenshot desktop+mobile en `vN/`. Sin copiar CSS entre variantes; el string no aparece en la UI.
3. `node scripts/design-diversity.mjs design-lab/<run>` — `COLLAPSE` = repetir con semillas nuevas.
4. El humano elige (`CHOSEN.md`, taste notes = SPEC, R19). La variante elegida entra aquí como `custom` con `_baseline_preset = seed:<run>/vN` y continúa en el bloque (e) con sus tokens.

### Paso 3 — Los 6 ejes (solo si `custom`)

Preguntar uno por uno con la tabla del eje (R-005 1.2). Para cada eje:

1. **Density** (1=aireado, 5=denso operativo) — ejemplos: Apple/Linear=1, Stripe=3, Figma=4, Bloomberg=5
2. **Expression** (1=invisible, 5=protagónica) — ejemplos: GitHub=1, Stripe=3, Cash App=4, MSCHF=5
3. **Geometry** (1=soft, 5=filoso) — ejemplos: Duolingo=1, Stripe=3, Linear/Vercel=4, gaming UI=5
4. **Warmth** (1=clínico, 5=juguetón) — ejemplos: IBM=1, Linear=2, Stripe=3, Mailchimp=4, Duolingo=5
5. **Editoriality** (1=tool, 5=revista) — ejemplos: Jira=1, Linear=2, Stripe=3, Browser Company=4
6. **Materiality** (1=flat, 5=táctil) — ejemplos: Linear=1, Stripe=3, macOS=4, Teenage Eng=5

### Default (si el usuario duda y no quiere elegir)

Modern Minimal direction (id `modern-minimal`) — cargar sus 6 ejes + OKLch verbatim:
```json
{ "density": 2, "expression": 1, "geometry": 3, "warmth": 2, "editoriality": 2, "materiality": 1 }
```

> **Posture es contrato (regla 2 de directions.md):** si la direction elegida dice "sin sombras" o "monospace como body", esos comportamientos NO se negocian. El output canónico siempre son los 6 ejes numéricos + tokens, NUNCA el nombre de la direction (D-006).

### Validación

```typescript
{
  density:      z.number().int().min(1).max(5),
  expression:   z.number().int().min(1).max(5),
  geometry:     z.number().int().min(1).max(5),
  warmth:       z.number().int().min(1).max(5),
  editoriality: z.number().int().min(1).max(5),
  materiality:  z.number().int().min(1).max(5),
}
```

---

## Bloque (d) — Voice axes (5 ejes 1-5)

> Objetivo: capturar `voice.tone_axes` de R-005 sección 9.2.

### Pregunta

> Mismo formato que el bloque anterior pero para el tono de voz. 5 ejes:
>
> 1. **Directness** (1=indirecto/diplomático, 5=blunt/imperativo)
> 2. **Warmth** (1=formal-corporate, 5=cálido-cercano)
> 3. **Technicality** (1=accesible-simple, 5=técnico-jerga-fluida)
> 4. **Provocation** (1=conciliador, 5=confrontativo)
> 5. **Hype** (1=ningún hype, 5=marketing máximo)
>
> ¿Tu producto se acerca más a Linear (3/2/3/2/1) o a Mailchimp (3/4/2/2/2) o a Cash App (4/3/2/3/3)?

Si en bloque (c) eligió una direction (1-5): aplicar el voice tone del preset homónimo en `references/presets.md`. Las directions reconcilian 1:1 por nombre con los presets; `directions.md` no lleva voice axes (solo posture + tokens OKLch), así que el tono se lee de `presets.md` para ese mismo id.

### Default

Tono neutral SaaS-honest:
```json
{ "directness": 3, "warmth": 3, "technicality": 3, "provocation": 2, "hype": 1 }
```

### Capturar también

Estos campos secundarios se llenan post-axes (todos opcionales en primer pase, refinables en sesiones siguientes):

- `voice.principles` — 3-5 principles cortos. Si dudás, derivar del archetype.
- `voice.vibe` — frase 1-line "X que hace Y para Z".
- `voice.code_switching` — palabras técnicas que NO se traducen.
- `voice.safe_words` — palabras propias de la marca (jerga, metáforas).
- `voice.avoid_words` — palabras prohibidas (defaults R-005 + adicionales del proyecto).
- `voice.cta_style` — directo / pushy / question / etc.

### Validación

```typescript
{
  tone_axes: {
    directness:   z.number().int().min(1).max(5),
    warmth:       z.number().int().min(1).max(5),
    technicality: z.number().int().min(1).max(5),
    provocation:  z.number().int().min(1).max(5),
    hype:         z.number().int().min(1).max(5),
  },
  principles:    z.array(z.string().min(3).max(80)).max(7),
  vibe:          z.string().max(160).optional(),
  safe_words:    z.array(z.string().min(2).max(40)).max(20),
  avoid_words:   z.array(z.string().min(2).max(40)).max(50),
}
```

---

## Bloque (e) — Tokens base

> Objetivo: derivar tokens iniciales (colors, typography, shape, spacing) usando el preset elegido como semilla.

> **Si en bloque (c) el usuario eligió una direction (1-5):** este bloque se **salta** — la direction ya entregó los tokens OKLch verbatim + las familias de fuente (`directions.md` reglas 1 + 2). La única personalización ya se ofreció en (c): el accent override de un solo token. Solo correr el procedimiento de abajo para el camino **`custom`**.

### Procedimiento (solo `custom`)

1. Tomar el `_baseline_preset` capturado en bloque (c) — o derivar del posture si fue manual.
2. Leer `references/presets.md` sección "Token defaults por preset".
3. Aplicar tokens del preset al output preliminar.
4. Mostrar al usuario la propuesta:
   ```
   Colors:    primary <#hex>, accent <#hex>, surface <#hex>, ...
   Typography: display <Family>, body <Family>, mono <Family>
   Shape:      radius_sm/md/lg + border_width
   Spacing:    unit + section_y[3] + component_gap[4]
   ```
5. Preguntar 4 overrides puntuales:
   - "¿Cambiás el `primary` color? Sino dejamos el del preset."
   - "¿Tenés font preferida? Sino usamos la del preset."
   - "¿Necesitás más / menos radius?"
   - "¿Spacing más denso / aireado?"

### Default

Aplicar tokens del preset 1:1 sin overrides.

### Validación de overrides

```typescript
{
  primary_color: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
  font_family:   z.string().min(2).max(40).optional(),
  radius_steps:  z.number().int().min(1).max(3).optional(),
  spacing_unit:  z.number().int().min(4).max(16).optional(),
}
```

### Anti-Slop gate inline

Si `primary_color` cae en hue range [235, 285] (Tailwind purple/indigo) y el archetype primary NO es `Magician`:
- Warning bloqueante: "Este color cae en el range default-AI-purple/indigo. Justificá con archetype o cambialo."
- No avanzar hasta que el usuario justifique o cambie.

---

## Bloque (f) — Anti-slop confirmation

> Objetivo: poblar `anti_slop` (R-005 sección 4 + 9.1).

### Pregunta

> Forja viene con 20 patrones default que rechazamos por automático (gradiente blue-purple, glassmorphism, 3 feature cards genéricas, etc — ver el set completo en R-005). ¿Querés añadir patrones específicos de tu industria o producto?

Mostrar la lista de 20 patrones default, marcados como `[default]`. El usuario añade/quita.

### Default

Aceptar los 20 patrones de R-005 sin modificación.

### Casos comunes de adición

| Industria | Patrón típico a añadir |
|-----------|------------------------|
| fintech | "stock chart fake con números inventados sin disclaimer" |
| healthcare | "lavado clínico con foto stock manos sosteniendo planta" |
| dev tools | "mockup terminal con código `lorem ipsum` corriendo" |
| e-commerce | "carousel hero con producto rotando 360° auto-play" |
| AI products | "robot icon en círculo gradient como hero visual" |

### Validación

```typescript
{
  forbidden_colors:   z.array(z.string().regex(/^#[0-9A-Fa-f]{6}$/)).max(20),
  forbidden_patterns: z.array(z.string().min(10).max(200)).max(50),
}
```

---

## Output del Discovery

Al terminar los 6 bloques, devolver al loop principal:

```yaml
discovery_output:
  mode: FRESH
  baseline_preset: "<preset name or 'custom'>"
  identity:
    name, product, tagline, positioning, category, audience
  archetype:
    primary, secondary, controlled_tension, shadow_to_avoid,
    ui_translation, copy_translation
  posture:
    density, expression, geometry, warmth, editoriality, materiality
  voice:
    tone_axes: { directness, warmth, technicality, provocation, hype }
    principles, vibe, safe_words, avoid_words, cta_style
  tokens_seed:
    primary_color, font_family, radius_steps, spacing_unit
  anti_slop:
    forbidden_colors, forbidden_patterns
```

Este YAML pasa como input a:
- `prompts/generate-brand-json.md` → produce `brand/brand.json`
- `prompts/generate-voice-json.md` → produce `brand/voice.json`

---

## Refusals

- ❌ Saltar un bloque entero — los 6 deben quedar respondidos (aunque sea con default).
- ❌ Aceptar respuestas que violan whitelist (ej: posture eje fuera de [1, 5]).
- ❌ Pasar el primary color del bloque (e) si está en restricted hue sin justificación.
- ❌ Avanzar a generación si el output del Discovery tiene flags `null` críticos (name, archetype.primary, posture.*).

---

*"Discovery no se salta. Pero un preset bien elegido te lleva al 80% del camino en 5 minutos."*
