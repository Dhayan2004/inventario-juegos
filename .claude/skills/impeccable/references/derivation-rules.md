# Derivation rules — R-005 sección 8.2 paso a paso

> Reference para Mode B (UNKNOWN component generation). Cuando un componente NO está declarado en `brand.json.component_rules`, este archivo define cómo derivarlo.
>
> **Source:** [memory:references#R-005] sección 8.2 (`unknown_component_policy`).

---

## R-005 8.2 — texto literal

```json
{
  "unknown_component_policy": {
    "derive_from": ["purpose", "tokens", "visual_posture", "nearest_component"],
    "must_include": ["states", "responsive_behavior", "accessibility"],
    "requires_rationale": true
  }
}
```

---

## Tabla nearest_component (lookup canónico)

Se consulta en Mode B paso 2.

| componente desconocido | nearest_component declarado | razón |
|------------------------|------------------------------|--------|
| `data-table` | `card.metric` (estructura) + `form.search` (filter row) | tabla densa de métricas filtables |
| `chart` | `card.default` (frame) | container con own color system contenido |
| `avatar` | (atom — no nearest) | usar tokens directamente, no nearest |
| `avatar-group` | `card.default` + array de avatars | grouping pattern |
| `command-palette` | `modal.form` + `form.search` + `navigation.tabs` | modal con search + tabs de categorías |
| `breadcrumb-with-dropdown` | `navigation.breadcrumb` + `navigation.tabs` | nav con dropdown trigger |
| `toast` | `modal.confirm` (dismissible) + `motion.durations.fast` | banner temporal animado |
| `tooltip` | `modal.detail` (lighter) + `motion.durations.fast` | hover info ligero |
| `popover` | `modal.detail` | floating panel anclado |
| `skeleton` | `card.empty` + `motion` (subtle pulse) | placeholder animado |
| `toggle` / `switch` | `button.ghost` (interactive) + form.checkbox semantics | binary state interactive |
| `combobox` | `form.select` + `form.search` | search-enabled dropdown |
| `date-picker` | `form.input` + `modal.detail` | input + calendar popover |
| `sidebar-nav-collapsible` | `navigation.sidebar` + `button.ghost` (toggle) | sidebar con collapse trigger |
| `pagination` | `navigation.tabs` (variant) + `button.ghost` (prev/next) | numbered nav |
| `badge` / `chip` | `button.ghost` (no-action) | inline status indicator |
| `progress-bar` | (atom) | track + indicator usando tokens |
| `slider` | `form.input` + variant range | range input con styling |
| `checkbox` | `form` (componente nuevo del set) | form primitive |
| `radio-group` | `form` + multi state | form primitive |
| `accordion` | `card.interactive` + collapse state | expandable sections |
| `dropdown-menu` | `modal.detail` + `navigation.tabs` items | floating menu |
| `tabs-with-content` | `navigation.tabs` + content slot | tabs + body |
| `divider` | (atom) | border-color from tokens |
| `kbd` | (atom) | mono font + small padding + border |

---

## Pasos de derivation (R-005 8.2 derive_from)

### a. purpose

Capturar 1-2 líneas que describen función + problema, NO implementación.

Ejemplos válidos:
- ✅ "muestra rows comparables y permite reordenar para encontrar outliers" (data-table)
- ✅ "comunica feedback temporal post-acción sin requerir respuesta" (toast)
- ✅ "permite navegar entre secciones del producto rápido vía búsqueda" (command-palette)

Ejemplos inválidos:
- ❌ "es una table con sort y filter" (describe implementación)
- ❌ "componente reutilizable para varios casos" (vacío)

### b. tokens (de brand.json)

Heredar 1:1 del nearest_component:
- colors → del nearest (ej: data-table hereda colors de card.metric)
- typography → del nearest
- shape (radius, border) → del nearest
- spacing → del nearest

Modificadores por purpose:
- Si purpose menciona "denso", "muchos elementos" → density-aware: spacing más compacto
- Si purpose menciona "destacar", "principal" → expression-aware: usar accent puntual
- Si purpose menciona "warning", "danger" → usar tokens.colors.{warning,danger}

### c. visual_posture (modificadores per-axis)

| Axis | Valor | Modificador en derivation |
|------|-------|----------------------------|
| density ≥ 4 | denso | reduce padding por 25%, sticky headers permitidos, scroll horizontal mobile |
| density ≤ 2 | aireado | aumentar padding, max-width contenido, mobile spacing generoso |
| expression ≥ 4 | expresivo | accent color signature en 1-2 elementos del componente (NO todo) |
| expression ≤ 2 | sobrio | sin signature visual, sticking a tokens neutrales |
| geometry ≥ 4 | filoso | radius pequeño (sm/md), border 1px, no curves dramáticas |
| geometry ≤ 2 | suave | radius lg/xl, sin border-style="solid" agresivo |
| warmth ≥ 4 | cálido | microcopy empático en empty/error states, color-warm en accents secondary |
| warmth ≤ 2 | clínico | copy directo factual, color-cool en accents |
| editoriality ≥ 4 | editorial | display typography prominente, hierarchy fuerte |
| editoriality ≤ 2 | utilitario | sans-default simple, jerarquía sutil |
| materiality ≥ 3 | táctil | shadow sutil (`shadow-sm` máximo), depth via surface elevation |
| materiality ≤ 2 | flat | NO shadow, depth solo via border + surface tokens |

### d. nearest_component (lookup table arriba)

Heredar del nearest:
- Estructura general (table vs grid vs flex layout)
- States declarados (default, hover, active, disabled — todos los del nearest)
- Variants signature (4 variants in nearest → 4 variants in derived, mismos nombres si aplican)
- Rules array — TODAS las reglas heredan, MÁS las nuevas específicas del componente

---

## must_include enforcement (R-005 8.2)

### states

Al menos:
- focus-visible (a11y)
- hover (interactive)
- active (interactive)
- disabled (interactive)
- loading (async-capable)

Static components (skeleton, badge): solo focus-visible si tab-reachable.

### responsive_behavior

Definir:
- Mobile (≤ 640px) tap target ≥ 44px obligatorio
- Tablet (641-1024px) layout ajuste
- Desktop (≥ 1025px) full features

Si componente es naturally desktop-only:
- Declarar `mobile_fallback` en JSDoc
- Ejemplos: data-table denso → mobile fallback de stacked cards

### accessibility

ARIA roles correctos por componente:
- modal → `role="dialog"` `aria-modal="true"`
- tabs → `role="tablist"` con tabs `role="tab"` + panels `role="tabpanel"`
- toggle → `role="switch"` `aria-checked`
- combobox → `role="combobox"` con full ARIA combobox spec
- toast → `role="status"` o `role="alert"` según severidad

Keyboard:
- modal → Esc cierra, Tab traps focus
- tabs → Arrow keys navegan
- combobox → Arrow + Enter + Esc spec ARIA combobox

Screen reader:
- Icon-only buttons → `aria-label` obligatorio
- Loading → `aria-busy="true"`
- Disabled → `aria-disabled` si no es nativo `disabled`

---

## requires_rationale enforcement

R-005 8.2 declara `requires_rationale: true`. Mode B genera el componente Y el commit message DEBE incluir el rationale completo (ver `prompts/generate-component-unknown.md` paso 8 template).

el-evaluador rechaza commits Mode B sin:
- Purpose declarado
- nearest_component identificado
- Tokens listados
- Posture-shaped decisions documentadas
- must_include checklist completo

---

## Ejemplo end-to-end: data-table

### Input

```yaml
component: data-table
purpose: "muestra rows comparables y permite reordenar para encontrar outliers"
```

### Lookup

`data-table → card.metric + form.search`.

### Tokens hereditados

Del card.metric:
- bg-surface-elevated
- border-border (rounded-md)
- font-display para headers
- font-mono para amounts numéricos

De form.search:
- input bg-surface
- focus-visible:ring-primary
- magnifier icon

### Posture-shaped (TECH UTILITY)

- density 4 → padding compacto, sticky header
- expression 2 → no accent signature, todo neutral
- geometry 4 → radius small (md, no lg)
- warmth 2 → empty state factual, no microcopy "ánimo"
- editoriality 1 → headers tipográficos sobrios, no prominent
- materiality 1 → flat, no shadow

### must_include

- states: focus-visible en row, hover row highlight, active row selected
- responsive: mobile = scroll horizontal con shadow-edge sticky first column
- accessibility: `role="table"`, `<th scope="col">` per header, sortable cols con `aria-sort`, keyboard navigation row-by-row con Arrow

### Output (resumen)

```typescript
'use client'

/**
 * DataTable · derived component (NOT in brand.json.component_rules)
 *
 * Purpose: muestra rows comparables y permite reordenar para encontrar outliers
 *
 * Derivation rationale (R-005 sec 8.2):
 *   nearest_component: card.metric + form.search
 *   tokens applied:    surface-elevated, border, font-display headers,
 *                      font-mono amounts, focus-ring=primary
 *   posture-shaped:    density=4 → compact padding + sticky header
 *                      geometry=4 → radius-md (no lg)
 *                      materiality=1 → no shadow
 *   inherited rules:   focus visible (card.metric), error message near field
 *                      (form pattern para sortable filter)
 *   additional rules:  aria-sort en sortable headers, keyboard row nav
 *
 * must_include:
 *   states:        focus-visible row, hover row, active selected, disabled
 *   responsive:    mobile = horizontal scroll + sticky first col
 *   accessibility: role=table, th scope=col, aria-sort, keyboard rows
 *
 * Citations: [memory:references#R-005] (sec 8.2) · [memory:CONSTRAINTS.md#R10]
 *            · [docs:tailwindcss] · [docs:shadcn-ui] · [docs:react]
 */

// ... cva + props + render
```

---

*"R-005 8.2 paso a paso: lookup → tokens hereda → posture modifica → must_include enforce → rationale documenta. Sin estos 5, no hay derivation válida."*
