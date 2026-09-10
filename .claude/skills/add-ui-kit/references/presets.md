# 5 Visual Direction Presets

> Lookup table consumida por `prompts/discovery-fresh.md` bloque (c) y `prompts/generate-brand-json.md`.
>
> **Source:** Forge v3.3 visual directions, mapeadas a los 6 ejes de R-005 sección 1.1.
> **Decisión registrada:** [memory:decisions#D-006] (los 5 presets se mantienen como starting points en Forja, no son la lengua final del schema).
>
> **Reglas:**
> 1. Cada preset declara los 6 ejes de posture, voice axes default sugerido, archetype primary, y tokens base.
> 2. El usuario empieza con un preset y ajusta ejes individuales.
> 3. El output canónico siempre son los 6 ejes numéricos + tokens, NO el nombre del preset.
> 4. Los presets son atajo, no contrato. El contrato es brand.json.

---

## Tabla resumen de los 5 presets

| Preset | density | expression | geometry | warmth | editoriality | materiality | Primary archetype | Vibe | Brand examples |
|--------|---------|------------|----------|--------|--------------|-------------|-------------------|------|----------------|
| Editorial Monocle | 2 | 2 | 3 | 2 | 5 | 1 | Sage | revista editorial seria | The Browser Company, Kinopio |
| Modern Minimal | 2 | 1 | 3 | 2 | 2 | 1 | Innocent / Sage | SaaS limpio sin opinión | Linear, Vercel marketing |
| Warm & Soft | 2 | 3 | 2 | 5 | 2 | 2 | Caregiver / Lover | humano, accesible | Mailchimp, Loom, Notion teams |
| Tech Utility | 4 | 2 | 4 | 2 | 1 | 1 | Creator / Sage | tool densa, productividad | Figma, Raycast, Forge mismo |
| Brutalist Experimental | 3 | 5 | 5 | 1 | 4 | 3 | Outlaw / Creator | rompiendo convenciones | MSCHF, Teenage Engineering, Gumroad creator |

---

## 1. Editorial Monocle

> *"Una revista digital que respeta a sus lectores."*

### 6 ejes

```json
{ "density": 2, "expression": 2, "geometry": 3, "warmth": 2, "editoriality": 5, "materiality": 1 }
```

### Voice axes default

```json
{ "directness": 4, "warmth": 2, "technicality": 3, "provocation": 2, "hype": 1 }
```

### Archetype primary

`Sage` (con secondary `Creator` cuando aplica).

### Token defaults

```json
{
  "colors": {
    "primary": "#1A1A1A",
    "accent":  "#C8A85A",
    "surface": "#FAFAF7",
    "surface_elevated": "#FFFFFF",
    "border":  "#E5E2D9",
    "text":    "#1A1A1A",
    "text_muted": "#6B6B6B",
    "text_subtle": "#9A9A9A"
  },
  "typography": {
    "display": { "family": "GT Sectra", "weights": [400, 700], "use_for": ["headlines", "feature_titles"] },
    "body":    { "family": "Inter",     "weights": [400, 500, 600], "line_height": 1.6 },
    "mono":    null
  },
  "shape": { "radius_sm": 0, "radius_md": 2, "radius_lg": 4, "border_width": 1 },
  "spacing": {
    "unit": 8,
    "section_y":     { "sm": 64, "md": 96, "lg": 128 },
    "component_gap": { "xs": 8, "sm": 16, "md": 24, "lg": 32 }
  }
}
```

### Cuándo elegir

- Producto que vende contenido (newsletters, journalism platforms, course platforms).
- Audiencia que valora pausa y lectura larga.
- B2B que quiere proyectar autoridad sin tocar Ruler.

### Cuándo NO

- Apps con dashboards densos (density 2 hace difícil mostrar mucho dato).
- Productos que necesitan urgencia / acción rápida.

---

## 2. Modern Minimal

> *"Funcionalidad limpia. Punto."*

### 6 ejes

```json
{ "density": 2, "expression": 1, "geometry": 3, "warmth": 2, "editoriality": 2, "materiality": 1 }
```

### Voice axes default

```json
{ "directness": 3, "warmth": 2, "technicality": 3, "provocation": 1, "hype": 1 }
```

### Archetype primary

`Innocent` o `Sage` según positioning. Default neutro `Sage`.

### Token defaults

```json
{
  "colors": {
    "primary": "#0A0A0A",
    "accent":  "#0A0A0A",
    "surface": "#FFFFFF",
    "surface_elevated": "#FAFAFA",
    "border":  "#E5E5E5",
    "text":    "#0A0A0A",
    "text_muted": "#737373",
    "text_subtle": "#A3A3A3",
    "success": "#10B981",
    "danger":  "#EF4444",
    "warning": "#F59E0B"
  },
  "typography": {
    "display": { "family": "Inter", "weights": [600, 700], "use_for": ["headlines", "section_titles"] },
    "body":    { "family": "Inter", "weights": [400, 500], "line_height": 1.5 },
    "mono":    { "family": "JetBrains Mono", "use_for": ["code"], "avoid_for": ["body"] }
  },
  "shape": { "radius_sm": 6, "radius_md": 8, "radius_lg": 12, "border_width": 1 },
  "spacing": {
    "unit": 8,
    "section_y":     { "sm": 48, "md": 80, "lg": 120 },
    "component_gap": { "xs": 8, "sm": 12, "md": 16, "lg": 24 }
  }
}
```

### Cuándo elegir

- Default safe para B2B SaaS sin opinión visual marcada.
- MVP donde la marca aún se está descubriendo.
- Productos que priorizan claridad funcional sobre signature visual.

### Cuándo NO

- Si el producto necesita memorabilidad visual (Modern Minimal sufre de "pude haber sido cualquiera").
- Si la audiencia es fuertemente lifestyle o creativa.

---

## 3. Warm & Soft

> *"Una herramienta que te entiende."*

### 6 ejes

```json
{ "density": 2, "expression": 3, "geometry": 2, "warmth": 5, "editoriality": 2, "materiality": 2 }
```

### Voice axes default

```json
{ "directness": 3, "warmth": 5, "technicality": 2, "provocation": 1, "hype": 2 }
```

### Archetype primary

`Caregiver` o `Lover` según ratio empatía/sensorialidad. `Everyman` si masivo.

### Token defaults

```json
{
  "colors": {
    "primary": "#FF6B6B",
    "accent":  "#FFD166",
    "surface": "#FFF8F1",
    "surface_elevated": "#FFFFFF",
    "border":  "#F2E6D5",
    "text":    "#2B2118",
    "text_muted": "#6B5D4F",
    "text_subtle": "#A39584",
    "success": "#06D6A0",
    "danger":  "#E63946",
    "warning": "#F4A261"
  },
  "typography": {
    "display": { "family": "Outfit", "weights": [600, 700], "use_for": ["headlines"] },
    "body":    { "family": "Outfit", "weights": [400, 500], "line_height": 1.55 },
    "mono":    null
  },
  "shape": { "radius_sm": 8, "radius_md": 14, "radius_lg": 20, "border_width": 1 },
  "spacing": {
    "unit": 8,
    "section_y":     { "sm": 56, "md": 88, "lg": 120 },
    "component_gap": { "xs": 8, "sm": 16, "md": 20, "lg": 28 }
  }
}
```

### Cuándo elegir

- B2C lifestyle / wellness / familia.
- B2B "human-first" (Mailchimp, Loom, Notion para teams).
- Productos donde onboarding empático es diferenciador.

### Cuándo NO

- Productos formales B2B con audiencia fintech / legal.
- Dashboards densos (warmth alto + radius alto + density 2 hace UI demasiado "blanda" para data).

---

## 4. Tech Utility

> *"Una herramienta de oficio. Densa, precisa, sin ruido."*

### 6 ejes

```json
{ "density": 4, "expression": 2, "geometry": 4, "warmth": 2, "editoriality": 1, "materiality": 1 }
```

### Voice axes default

```json
{ "directness": 4, "warmth": 3, "technicality": 4, "provocation": 2, "hype": 1 }
```

### Archetype primary

`Creator` (con secondary `Sage` para autoridad técnica).

### Token defaults

```json
{
  "colors": {
    "primary": "#FF6B35",
    "accent":  "#FFB627",
    "surface": "#0F0F10",
    "surface_elevated": "#18181B",
    "surface_higher": "#27272A",
    "border":  "#3F3F46",
    "text":    "#FAFAFA",
    "text_muted": "#A1A1AA",
    "text_subtle": "#71717A",
    "success": "#10B981",
    "danger":  "#EF4444",
    "warning": "#F59E0B",
    "info":    "#3B82F6"
  },
  "typography": {
    "display": { "family": "Geist", "weights": [600, 700], "use_for": ["page_titles", "section_headlines"] },
    "body":    { "family": "Geist", "weights": [400, 500, 600], "line_height": 1.5 },
    "mono":    { "family": "Geist Mono", "use_for": ["code", "technical_labels", "metadata"], "avoid_for": ["body", "headlines"] }
  },
  "shape": { "radius_sm": 4, "radius_md": 6, "radius_lg": 10, "border_width": 1 },
  "spacing": {
    "unit": 4,
    "section_y":     { "sm": 40, "md": 64, "lg": 96 },
    "component_gap": { "xs": 4, "sm": 8, "md": 12, "lg": 16 }
  }
}
```

### Cuándo elegir

- Dev tools, internal tools, command palettes.
- Products donde el power user vive en la UI horas al día.
- Forge / Forja (default Forja-aligned).

### Cuándo NO

- Marketing sites de productos B2C casuales.
- Audiencias no técnicas que se intimidan con density alta.

---

## 5. Brutalist Experimental

> *"Las reglas son material para construir."*

### 6 ejes

```json
{ "density": 3, "expression": 5, "geometry": 5, "warmth": 1, "editoriality": 4, "materiality": 3 }
```

### Voice axes default

```json
{ "directness": 5, "warmth": 1, "technicality": 3, "provocation": 5, "hype": 2 }
```

### Archetype primary

`Outlaw` (con secondary `Creator` cuando hay rigor de oficio detrás).

### Token defaults

```json
{
  "colors": {
    "primary": "#FF3B30",
    "accent":  "#FFFC00",
    "surface": "#000000",
    "surface_elevated": "#0A0A0A",
    "border":  "#FF3B30",
    "text":    "#FFFFFF",
    "text_muted": "#888888",
    "text_subtle": "#444444",
    "success": "#39FF14",
    "danger":  "#FF3B30",
    "warning": "#FFFC00"
  },
  "typography": {
    "display": { "family": "Space Grotesk", "weights": [700, 800], "use_for": ["headlines", "manifestos"] },
    "body":    { "family": "Space Grotesk", "weights": [400, 600], "line_height": 1.4 },
    "mono":    { "family": "JetBrains Mono", "use_for": ["code", "system_messages"] }
  },
  "shape": { "radius_sm": 0, "radius_md": 0, "radius_lg": 2, "border_width": 2 },
  "spacing": {
    "unit": 8,
    "section_y":     { "sm": 48, "md": 96, "lg": 144 },
    "component_gap": { "xs": 8, "sm": 16, "md": 24, "lg": 32 }
  }
}
```

### Cuándo elegir

- Productos counter-status-quo con audiencia receptiva (creators, dev tools edgy, alt-finance).
- Branding statement-first donde reconocimiento visual > legibilidad universal.
- Cuando el founder/team es la cara y la marca puede asumir riesgo.

### Cuándo NO

- B2B enterprise tradicional.
- Productos para audiencias con baja tolerancia a estética disruptiva.
- Health / legal / educación regulada.

---

## Reglas de aplicación

### Override de ejes individuales

El usuario empieza con un preset y puede ajustar ejes uno por uno. Ejemplo:

> "Quiero Tech Utility pero con `warmth: 3` en vez de 2 — el producto tiene un ángulo más human-first dentro del oficio."

Esta es la lengua final: `{ density: 4, expression: 2, geometry: 4, warmth: 3, editoriality: 1, materiality: 1 }` con preset baseline `Tech Utility (modificado)`.

### Override de tokens

Tokens del preset son sugerencia. Cualquier override del usuario:
1. Se valida contra Anti-Slop Gate (hue range, max_fonts, max_radius).
2. Si pasa, se aplica.
3. Si falla, se rechaza con root cause citando regla violada.

### Combinaciones que requieren justificación

| Preset baseline | Override propuesto | Riesgo / require justification |
|-----------------|---------------------|-------------------------------|
| Modern Minimal | primary color saturado fuerte | Posible Magician shadow — pedir confirmación |
| Tech Utility | warmth: 5 | Tensión con density: 4 (UI demasiado denso para sentirse cálido) |
| Warm & Soft | density: 4 | Tensión con warmth: 5 (UI densa pierde aire empático) |
| Brutalist | warmth: 5 | Contradicción con archetype Outlaw — re-discovery |
| Editorial Monocle | mono font como display | Contradicción con editoriality: 5 — re-discovery |

---

## D-006 rationale (cita corta)

Los 5 presets de Forge v3.3 se mantienen porque son el **vocabulario de entrada** humano más eficiente. Pero el **output canónico** son los 6 ejes numéricos + tokens explícitos. Los presets son atajo, no contrato. Coexisten: presets para discovery, ejes para validación.

Detalle completo en [memory:decisions#D-006].

---

## Ejemplo de uso end-to-end

Usuario en Discovery FRESH bloque (c):

> "Mi producto es un AI tool para developers que ayuda a leer codebases legacy. Audiencia: senior engineers en empresas medianas."

Skill propone:

> *Tech Utility* preset (density 4, expression 2, geometry 4, warmth 2, editoriality 1, materiality 1) con archetype `Creator` + secondary `Sage`. Voice axes 4/3/4/2/1.
> ¿Confirmás? ¿Algún ajuste de eje?

Usuario:

> "Subí warmth a 3, no quiero que se sienta tan frío como Forge."

Output capturado:

```json
{
  "_baseline_preset": "tech_utility",
  "visual_posture": { "density": 4, "expression": 2, "geometry": 4, "warmth": 3, "editoriality": 1, "materiality": 1 }
}
```

Tokens del preset Tech Utility se aplican; el override de `warmth: 3` consume al `el-evaluador` para chequear consistencia (no contradice tokens, OK).

---

*"5 atajos para no empezar de cero. 6 ejes para terminar afilado."*
