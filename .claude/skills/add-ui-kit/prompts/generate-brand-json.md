# generate-brand-json — Discovery output → brand/brand.json

> Operational prompt. Toma el `discovery_output` (FRESH o REDESIGN) y rellena `templates/brand.json.template` para producir `brand/brand.json`.
>
> **Source schema:** [memory:references#R-005].
> **Template:** `templates/brand.json.template`.
> **Reference outputs:** `references/examples.md` (3 ejemplos well-formed).
> **Lookup tables:** `references/archetypes-mark-pearson.md`, `references/presets.md`.

---

## Input esperado

```yaml
discovery_output:
  mode: FRESH | REDESIGN
  baseline_preset: <string or 'custom'>
  identity:
    name, product, tagline, positioning, category, audience
  archetype:
    primary, secondary, controlled_tension, shadow_to_avoid
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

## Output esperado

`brand/brand.json` — JSON parseable que cumple R-005.

---

## Procedimiento (8 pasos)

### Paso 1 — Cargar template + lookup tables

```
1. Read .claude/skills/add-ui-kit/templates/brand.json.template
2. Read .claude/skills/add-ui-kit/references/archetypes-mark-pearson.md
3. Read .claude/skills/add-ui-kit/references/presets.md
4. Read .claude/skills/add-ui-kit/references/examples.md (shape reference only)
```

### Paso 2 — Resolver archetype.ui_translation + copy_translation + behaviors

Lookup en `archetypes-mark-pearson.md`:

```
archetype.primary = discovery_output.archetype.primary
→ buscar la sección con ese título en archetypes-mark-pearson.md
→ extraer:
   - ui_translation = "concrete posture/typography/color guidance" del archetype
   - copy_translation = "concrete voice rules" del archetype
   - allowed_behaviors[0..2] del archetype
   - forbidden_behaviors[0..2] del archetype (mezclar con shadow_to_avoid de Discovery)
```

Si Discovery proveyó override de `ui_translation` o `copy_translation` (1-line), usar el override del usuario.

### Paso 3 — Resolver tokens base

Lookup en `presets.md`:

```
baseline_preset = discovery_output.baseline_preset
→ buscar sección "## N. <preset name>" en presets.md
→ extraer Token defaults bloque "Token defaults"
→ aplicar 1:1 a tokens.colors / tokens.typography / tokens.shape / tokens.spacing
```

Aplicar overrides de Discovery `tokens_seed`:

| Override | Acción |
|----------|--------|
| `primary_color` | reemplazar `tokens.colors.primary`. Si era el del preset → no warn. Si nuevo → validar Anti-Slop (paso 6). |
| `font_family` | reemplazar `tokens.typography.display.family` Y `tokens.typography.body.family` (consolidate to 1 family si max_fonts=1). |
| `radius_steps` | si =3 → mantener radius_sm/md/lg. Si =1 → radius_md sólo + sm = md = lg. Si =2 → radius_sm + radius_lg, md = sm. |
| `spacing_unit` | reemplazar `tokens.spacing.unit`. |

### Paso 4 — Derivar campos secundarios de colores

Dado `tokens.colors.primary`, calcular:

```
- primary_deep:                  HSL primary con lightness -25% (fallback: primary)
- primary_accessible_on_dark:    HSL primary con lightness +20% si surface es dark, sino primary
- primary_accessible_on_light:   HSL primary con lightness -25% si surface es light, sino primary
- accent: si Discovery no proveyó, usar el del preset
```

Si un cálculo no se puede hacer determinísticamente (ej: HSL conversión sin lib), dejar el campo opcional como `null` y agregar a `$generated_warnings`.

### Paso 5 — Llenar component_rules

Los rules son universales (R-005 sección 3.3) y vienen pre-poblados en el template. NO re-escribir. Solo ajustar si Discovery declaró `archetype.allowed_behaviors` específicas que aplican a un componente — en ese caso, anexar UN rule extra a la sección correspondiente.

Ejemplo: si `archetype.primary = Outlaw` y allowed_behaviors include "manifesto headlines en hero", anexar a `component_rules.button.rules`: "Primary CTA puede usar copy de manifesto cuando aparece en hero".

### Paso 6 — Anti-Slop Gate (validación inline antes de escribir)

Antes de generar el archivo, correr 6 binary checks contra el output draft.

**Pre-check schema R-005 v1.1.0 (obligatorio):**
- `tokens.spacing.section_y` es keyed object `{sm, md, lg}`. Array → reject.
- `tokens.spacing.component_gap` es keyed object `{xs, sm, md, lg}`. Array → reject.
- `motion.personality.{energy, elasticity, directionality, sequencing, distance, restraint}` cada uno está en su enum cerrado de R-005 v1.1.0 sec 6.1. Out-of-enum → reject + listar valores válidos al usuario.

Si el pre-check falla, halt antes de los 6 binary checks — el shape del draft no cumple schema canónico.

**6 binary checks contra el draft:**

| Check | Pass criterion |
|-------|---------------|
| `forbidden_colors` | `tokens.colors.primary` y `accent` NO están en `["#6366F1", "#8B5CF6", "#A855F7"]` |
| `restricted_hues` | si `tokens.colors.primary` HSL hue ∈ [235, 285] → solo OK si `archetype.primary == "Magician"` o `archetype.allowed_behaviors` declara `purple_as_primary` explícito |
| `max_fonts` | unique families en `tokens.typography.{display,body,mono}` ≤ `validation.max_fonts` |
| `max_radius_values` | unique radius en `tokens.shape.{radius_sm,radius_md,radius_lg}` ≤ `validation.max_radius_values` |
| `archetype_coherence` | si `archetype.primary == Outlaw` → `voice.tone_axes.provocation ≥ 3`. Si `archetype.primary == Caregiver` → `voice.tone_axes.warmth ≥ 4`. Si `archetype.primary == Creator` y `editoriality ≤ 2` → warning. |
| `min_contrast_body` | tokens.colors.text vs tokens.colors.surface contrast ratio ≥ 4.5 (WCAG AA) |

Si alguno falla → halt + reportar al usuario:

```
❌ Anti-Slop Gate failed at <check>:
   <root cause>
   <suggested fix>

¿Cambio el valor o reabrimos el bloque de Discovery correspondiente?
```

NO escribir el archivo hasta que los 6 checks pasen.

### Paso 7 — Render template → JSON

Procesar el template `brand.json.template`:

1. Reemplazar todos los `{{ var }}` con valores concretos del Discovery output.
2. Procesar `| optional` filters: si el valor está ausente, omitir el campo del JSON output (no emitir como `null` salvo que el campo sea explícitamente nullable).
3. Procesar `| default: X` filters: si el valor está ausente, usar X.
4. Validar que el output sea JSON parseable con `python3 -c "import json; json.load(open('...'))"`.
5. Validar contra schema R-005 (campos required + bounded ranges).

### Paso 8 — Escribir + reportar

```
1. Write brand/brand.json
2. Reportar al orchestrator:
   - LOC del JSON generado
   - Warnings emitidos (paso 4)
   - Anti-Slop Gate result (PASS / FAIL)
   - Path: brand/brand.json
```

---

## Casos edge

### Discovery output incompleto

Si algún campo `required` del schema R-005 está `null` en el Discovery output:
- `brand.name` → halt + pedir al usuario
- `brand.tagline` → permitir `null` con flag para volver al final
- `archetype.primary` → halt + sugerir Creator (default)
- `posture.<axis>` → halt + sugerir preset Modern Minimal default
- `tokens.colors.primary` → halt + ofrecer color del preset

### Override conflictivo (preset + manual)

Si el usuario eligió preset `Tech Utility` y luego en bloque (e) override `primary_color = #FF6B6B`:
- aplicar override
- pero registrar en `$generated_warnings`: "Primary color #FF6B6B no es del preset Tech Utility (que usa #FF6B35). Mantener intencional o re-discovery."
- avanzar (no halt — el usuario tiene autoridad)

### Mode REDESIGN: tokens consolidados

En REDESIGN, `tokens_seed` viene del scan (most-frequent values). Aplicarlos directo. Si el scan detectó >3 radius → consolidate per `references/presets.md` "max_radius_values" rule, registrar la consolidación en `$generated_warnings`.

---

## Refusals

- ❌ Escribir `brand/brand.json` si Anti-Slop Gate falla.
- ❌ Inventar archetype `ui_translation` o `copy_translation` — siempre lookup en archetypes-mark-pearson.md.
- ❌ Omitir campos required del schema R-005 (brand.name, archetype.primary, posture.* completo, tokens.colors.{primary,surface,text}).
- ❌ Sobrescribir `brand/brand.json` existente sin que el orchestrator confirme.

---

## Citations en el output

El JSON generado lleva en su header:

```json
{
  "$schema_source": "[memory:references#R-005]",
  "$generated_by": "add-ui-kit (FRESH mode, Tech Utility preset baseline)",
  "$generated_at": "2026-05-07T22:30:00Z"
}
```

Estos campos NO son parte del schema runtime; son provenance metadata para audit. `el-evaluador` los usa para verificar que el archivo no fue editado a mano post-add-ui-kit.

---

*"Discovery YAML → schema-compliant JSON → Anti-Slop Gate → write."*
