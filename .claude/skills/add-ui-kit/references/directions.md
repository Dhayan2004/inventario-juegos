# 5 Visual Directions — OKLch + posture canónicos

> Las 5 direcciones visuales pre-curadas de Forja, ahora con paleta **OKLch verbatim**
> + reference apps + reglas "posture es contrato". Cuando el usuario no tiene marca clara
> y dice "lo que recomiendes", Discovery FRESH bloque (c) muestra estas 5 opciones.
>
> **Source schema:** [memory:references#R-005] (6 ejes de posture: density, expression,
> geometry, warmth, editoriality, materiality — cada uno 1-5; sección 1.1 + 1.2).
> **OKLch tokens:** portados verbatim de Forge v3.3 visual directions. No re-mapear a
> "el color más cercano que conozco" — OKLch es soportado nativo por Tailwind 3.4+ y
> todos los browsers modernos.
>
> ## Supersede note — directions.md > presets.md
>
> Este archivo **supersede a `references/presets.md`** como starting point de Discovery.
> Las dos comparten los mismos 5 nombres + los mismos 6 ejes de posture (reconcilian 1:1
> por nombre, así que el lookup por `## N. <preset name>` de `generate-brand-json.md`
> sigue resolviendo). La diferencia: `presets.md` da tokens en **hex** + voice axes +
> archetype; `directions.md` da los tokens en **OKLch** + reference apps + las reglas de
> contrato de posture. El agente de integración de Fase 2 reconectará
> `prompts/discovery-fresh.md` bloque (c) y `prompts/generate-brand-json.md` para que lean
> de acá la paleta OKLch, dejando `presets.md` como la vista hex/voice/archetype del mismo
> set. Hasta que esa reconciliación esté hecha, **mantener ambos archivos** — son vistas
> complementarias del mismo contrato, no duplicados a borrar.
>
> **Reglas (ver "Reglas de aplicación" al final — estrictas):**
> 1. Tokens OKLch van **verbatim** al `globals.css` del proyecto. No improvisar valores intermedios.
> 2. Posture es contrato, no sugerencia.
> 3. La única personalización permitida es el accent override (un solo token).
> 4. No combinar direcciones. Si el usuario insiste, ofrecer `custom` (cae a Discovery bloque por bloque).

---

## Tabla resumen — para mostrar al usuario

| # | Direction | id | Mood en una línea | Acento | density | expression | geometry | warmth | editoriality | materiality |
|---|-----------|----|--------------------|--------|---------|------------|----------|--------|--------------|-------------|
| 1 | Editorial Monocle | `editorial-monocle` | Print-magazine, serif headlines, papel off-white | Rust cálido | 2 | 2 | 3 | 2 | 5 | 1 |
| 2 | Modern Minimal | `modern-minimal` | Software-native, near-greyscale, un acento saturado | Cobalt | 2 | 1 | 3 | 2 | 2 | 1 |
| 3 | Warm & Soft | `warm-soft` | Crema, radii suaves, friendly fintech | Terracotta | 2 | 3 | 2 | 5 | 2 | 2 |
| 4 | Tech Utility | `tech-utility` | Data-dense, mono-friendly, info per square inch | Signal green | 4 | 2 | 4 | 2 | 1 | 1 |
| 5 | Brutalist Experimental | `brutalist-experimental` | Type gritada, grid visible, fealdad deliberada | Hot red | 3 | 5 | 5 | 1 | 4 | 3 |

> Los valores de los 6 ejes son idénticos a `references/presets.md` — esto es lo que hace
> que las dos vistas reconcilien. El output canónico siempre son los 6 ejes numéricos +
> tokens, NO el nombre de la direction (D-006).

---

## 1 · Editorial Monocle — Monocle / FT Magazine

**id:** `editorial-monocle`

**Mood:** Print-magazine. Whitespace generoso, headlines serif grandes, paleta
restringida (papel off-white + tinta + un único acento cálido). Confiado y
silenciosamente inteligente. *"Una revista digital que respeta a sus lectores."*

**Reference apps:** Monocle, The Financial Times Weekend, NYT Magazine, It's Nice That.
También The Browser Company, Kinopio (los `brand_examples` de presets.md para este id).

**Posture (R-005, 6 ejes):**

```json
{ "density": 2, "expression": 2, "geometry": 3, "warmth": 2, "editoriality": 5, "materiality": 1 }
```

**Tokens OKLch — drop into `globals.css` verbatim:**

```css
:root {
  --bg:      oklch(97% 0.012 80);   /* off-white paper */
  --surface: oklch(99% 0.005 80);
  --fg:      oklch(20% 0.02 60);    /* ink */
  --muted:   oklch(48% 0.015 60);
  --border:  oklch(89% 0.012 80);
  --accent:  oklch(58% 0.16 35);    /* warm rust / clay */

  --font-display: 'Iowan Old Style', 'Charter', Georgia, serif;
  --font-body:    -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
}
```

**Posture es contrato (cómo se comporta):**
- Display serif, body sans, mono SOLO para metadata.
- Sin sombras, sin cards rounded — los borders + whitespace hacen el trabajo (geometry 3, materiality 1).
- Una imagen decisiva, recortada solo en la parte inferior.
- Kicker / eyebrow en mono uppercase. Un solo color de acento, usado máximo 2 veces.

---

## 2 · Modern Minimal — Linear / Vercel

**id:** `modern-minimal`

**Mood:** Silencioso, preciso, software-native. System fonts, paleta casi
greyscale, un único acento saturado. La cromática desaparece para que el
contenido sea lo único que registra. *"Funcionalidad limpia. Punto."*

**Reference apps:** Linear, Vercel, Notion 2024, Stripe docs, Raycast, Superhuman.

**Posture (R-005, 6 ejes):**

```json
{ "density": 2, "expression": 1, "geometry": 3, "warmth": 2, "editoriality": 2, "materiality": 1 }
```

**Tokens OKLch — drop into `globals.css` verbatim:**

```css
:root {
  --bg:      oklch(99% 0.002 240);
  --surface: oklch(100% 0 0);
  --fg:      oklch(18% 0.012 250);
  --muted:   oklch(54% 0.012 250);
  --border:  oklch(92% 0.005 250);
  --accent:  oklch(58% 0.18 255);   /* cobalt */

  --font-display: -apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif;
  --font-body:    -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif;
}
```

**Posture es contrato:**
- Letter-spacing ajustado en display (-0.02em).
- Solo hairline borders, sin sombras excepto en dropdowns/modales.
- Numéricos mono con `font-variant-numeric: tabular-nums`.
- Nav sticky con frosted blur, layouts content-led (sin hero illustrations) — expression 1.
- Un único color de acento: links + primary CTA, nada más.

---

## 3 · Warm & Soft — Stripe pre-2020 / Headspace

**id:** `warm-soft`

**Mood:** Fondos crema, acento suave, radii gentiles. Se lee como una revista
de producto reflexiva — amigable sin caer en cute. Bueno para fintech, wellness,
indie SaaS. *"Una herramienta que te entiende."*

**Reference apps:** Stripe pre-2020, Headspace, Substack, Mercury. También
Mailchimp, Loom, Notion teams (los `brand_examples` de presets.md para este id).

**Posture (R-005, 6 ejes):**

```json
{ "density": 2, "expression": 3, "geometry": 2, "warmth": 5, "editoriality": 2, "materiality": 2 }
```

**Tokens OKLch — drop into `globals.css` verbatim:**

```css
:root {
  --bg:      oklch(97% 0.018 70);   /* warm cream */
  --surface: oklch(99% 0.008 70);
  --fg:      oklch(22% 0.02 50);
  --muted:   oklch(50% 0.018 50);
  --border:  oklch(90% 0.014 70);
  --accent:  oklch(64% 0.13 28);    /* terracotta */

  --font-display: 'Tiempos Headline', 'Newsreader', 'Iowan Old Style', Georgia, serif;
  --font-body:    'Söhne', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
}
```

**Posture es contrato:**
- Display serif, body sans suave.
- Radii gentiles (12–16px) — nunca esquinas duras 0px en content cards (geometry 2).
- Acento único usado para primary CTA + un flourish editorial (una comilla, una stat).
- Inner glow suave en hero cards en lugar de drop shadows (materiality 2).
- Evitar íconos genéricos — usar screenshots reales / fotografías / ilustraciones.

---

## 4 · Tech Utility — Datadog / GitHub

**id:** `tech-utility`

**Mood:** Data-dense, monospace-friendly, dark o light + grid. Hecho para
ingenieros y operators que quieren información por pulgada cuadrada, no vibes.
*"Una herramienta de oficio. Densa, precisa, sin ruido."* Default Forja-aligned.

**Reference apps:** Datadog, GitHub, Cloudflare dashboard, Sentry. También
Figma, Raycast, Forge mismo (los `brand_examples` de presets.md para este id).

**Posture (R-005, 6 ejes):**

```json
{ "density": 4, "expression": 2, "geometry": 4, "warmth": 2, "editoriality": 1, "materiality": 1 }
```

**Tokens OKLch — drop into `globals.css` verbatim:**

```css
:root {
  --bg:      oklch(98% 0.005 250);
  --surface: oklch(100% 0 0);
  --fg:      oklch(22% 0.02 240);
  --muted:   oklch(50% 0.018 240);
  --border:  oklch(90% 0.008 240);
  --accent:  oklch(58% 0.16 145);   /* signal green */

  --font-display: -apple-system, BlinkMacSystemFont, 'Inter', 'Segoe UI', system-ui, sans-serif;
  --font-body:    -apple-system, BlinkMacSystemFont, 'Inter', 'Segoe UI', system-ui, sans-serif;
  --font-mono:    'JetBrains Mono', 'IBM Plex Mono', ui-monospace, Menlo, monospace;
}
```

> Nota Forja: el stack `--font-display`/`--font-body` de esta direction lista Inter como
> fallback porque es el system-adjacent default de las dashboards de referencia. El brand.json
> generado debe resolver display + body a una familia distintiva (Geist es la `brand_examples`
> default Forja para este id) — Inter como **fallback** en el stack está OK, Inter como
> familia **declarada** dispara el anti-slop de R-005.

**Posture es contrato:**
- Sans display + sans body (una sola familia) está OK — utility manda sobre editorial (editoriality 1).
- Tabular numerics en todos lados, mono para code / IDs / hashes.
- Tablas densas con hairline borders, sin row striping (density 4).
- Status pills inline (success / warn / danger) con backgrounds tinted restrained.
- Evitar: hero images, headlines oversized, copy de marketing — mostrar el producto.

---

## 5 · Brutalist Experimental — Are.na / Yale

**id:** `brutalist-experimental`

**Mood:** Tipografía gritada. Grid visible. System sans + un único serif
oversized. Fealdad deliberada como confianza. Excelente para arte, indie,
agencias, manifesto pages. *"Las reglas son material para construir."*

**Reference apps:** Are.na, Yale Center for British Art, MSCHF, Read.cv. También
Teenage Engineering, Gumroad creator (los `brand_examples` de presets.md para este id).

**Posture (R-005, 6 ejes):**

```json
{ "density": 3, "expression": 5, "geometry": 5, "warmth": 1, "editoriality": 4, "materiality": 3 }
```

**Tokens OKLch — drop into `globals.css` verbatim:**

```css
:root {
  --bg:      oklch(96% 0.004 100);  /* off-white printer paper */
  --surface: oklch(100% 0 0);
  --fg:      oklch(15% 0.02 100);
  --muted:   oklch(40% 0.02 100);
  --border:  oklch(15% 0.02 100);   /* borders are full-strength fg */
  --accent:  oklch(60% 0.22 25);    /* hot red */

  --font-display: 'Times New Roman', 'Iowan Old Style', Georgia, serif;
  --font-body:    ui-monospace, 'IBM Plex Mono', 'JetBrains Mono', Menlo, monospace;
}
```

**Posture es contrato:**
- Display = serif a tamaños extremos: `clamp(80px, 12vw, 200px)` (expression 5).
- Body = monospace — sí, monospace como body, deliberadamente.
- Borders a full strength (1.5–2px), no muted greys.
- Layouts asimétricos: una columna 70%, la otra 30%.
- Casi sin border-radius (0–2px). Sin sombras. Sin gradients (geometry 5).
- Links subrayados, sin decoración hover — la tipografía carga el peso.

---

## Reglas de aplicación (CRÍTICO)

1. **Verbatim, no aproximación.** Cuando el usuario elige una direction, los
   valores OKLch de la paleta van al `:root` SIN modificación. No re-mapear a
   "el azul más cercano que conozco". OKLch es soportado nativamente por
   Tailwind 3.4+ y todos los browsers modernos.

2. **Posture es contrato, no sugerencia.** Si la direction dice "sin sombras",
   no se agregan sombras "porque queda mejor". Si dice "monospace como body",
   no se cambia a sans "porque es más legible". El usuario eligió esta
   direction porque su mood es coherente — romperlo destruye el resultado. Los
   6 ejes de posture son la traducción numérica de ese contrato (R-005 1.2).

3. **Accent override es la única personalización.** Si el usuario dice "me
   gusta Modern Minimal pero con verde en vez de azul", solo se cambia el
   token `--accent`. El resto de la paleta (bg/surface/fg/muted/border) se
   queda. Cambiar más es perder la coherencia. Si el `--accent` propuesto cae
   en hue range [235°, 285°] (Tailwind purple/indigo) y el archetype primary
   NO es `Magician`, dispara el anti-slop gate inline (Discovery bloque (e)).

4. **Refresca reference apps.** Si el usuario pidió una direction, nombrar 1-2
   reference apps de su lista para anclar el lenguaje. Ejemplo: "Elegiste Modern
   Minimal — pensá en cómo Linear y Vercel resuelven los hairline borders y el
   acento único; lo aplicamos igual a tu producto."

5. **No combinar directions.** El usuario elige UNA. "Mitad Editorial mitad
   Tech Utility" no es una opción — eso es lo que da el AI slop. Si el usuario
   insiste, ofrecer la opción `custom` que cae al flujo de Discovery eje por eje
   (bloque (c) opción ii) en lugar de mezclar.

6. **El output canónico son los 6 ejes + tokens, NO el nombre.** La direction es
   el atajo de entrada; el contrato que firma `brand.json` son los 6 ejes
   numéricos de posture + los tokens explícitos (D-006). El usuario empieza con
   una direction y luego puede ajustar ejes individuales — ese override modificado
   es la lengua final, no "editorial-monocle" a secas.

---

*"5 atajos OKLch para no empezar de cero. 6 ejes para terminar afilado."*
