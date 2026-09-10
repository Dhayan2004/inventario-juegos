# generate-component-unknown — derivation R-005 sección 8.2 → component code

> Operational prompt para Mode B. Toma un componente que **NO EXISTE** en `brand.json.component_rules` y deriva uno nuevo aplicando R-005 sección 8.2 `unknown_component_policy`.
>
> **Source schema:** [memory:references#R-005] sección 8.2.
> **Lookup tables:** `references/derivation-rules.md`.
> **Templates:** los mismos `templates/<Component>.tsx` se reusan adaptando el `nearest_component`.

---

## R-005 sección 8.2 — texto literal del schema

```json
{
  "unknown_component_policy": {
    "derive_from": ["purpose", "tokens", "visual_posture", "nearest_component"],
    "must_include": ["states", "responsive_behavior", "accessibility"],
    "requires_rationale": true
  }
}
```

Es decir:
- Derivar desde 4 fuentes: purpose + tokens + visual_posture + nearest_component
- Output debe incluir 3 cosas mínimo: states + responsive_behavior + accessibility
- El commit message DEBE documentar el rationale (`requires_rationale: true`)

---

## Input esperado

```yaml
component: "data-table" | "chart" | "avatar-group" | "command-palette" | ...
purpose: <string 1-2 lines>      # qué hace + qué problema resuelve
extras:
  base_element?: "div" | "table" | "ul" | "section"  # default 'div'
  expected_props?: [string]       # hint de props que el caller usará
target_path?: src/shared/components/ui/<Component>/<Component>.tsx
```

## Output esperado

- `src/shared/components/ui/<Component>/<Component>.tsx`
- (si no existe) `src/shared/components/ui/<Component>/index.ts` barrel
- Commit message con rationale completo (R-005 8.2 requires_rationale)

---

## Procedimiento (8 pasos)

### Paso 1 — Identify purpose

Si el caller no proveyó purpose, conducir UNA pregunta:

> "<component> no está declarado en brand.json. Antes de derivarlo, decime en 1-2 líneas: ¿qué hace? ¿qué problema resuelve para el usuario?"

Capturar y validar:
- ≥ 10 chars, ≤ 240 chars
- 1-2 oraciones
- Describe función, NO implementación (mal: "es una table con sort"; bien: "muestra rows comparables y permite reordenar para encontrar outliers")

### Paso 2 — Lookup nearest_component

Leer `references/derivation-rules.md`. Tiene una tabla:

```
componente desconocido → nearest_component declarado → razón
─────────────────────────────────────────────────────────────
data-table             → card.metric (estructura) + form.search (filter)
chart                  → card.default (frame) + propio sistema de colors
avatar-group           → card.default + repeated atomic image
command-palette        → modal.form + form.search + navigation.tabs
breadcrumb-with-dropdown → navigation.breadcrumb + navigation.tabs
toast                  → modal.confirm (dismissible) + motion.durations.fast
tooltip                → modal.detail (light) + motion.durations.fast
popover                → modal.detail
skeleton               → card.empty + motion (subtle pulse)
toggle / switch        → button.ghost + form.checkbox semantics
combobox               → form.select + form.search
date-picker            → form.input + modal.detail
sidebar-nav-collapsible → navigation.sidebar + button.ghost
```

Si `<component>` no está en la tabla → halt + reportar:

> "<component> no tiene nearest_component obvio. Sugerencias para extender:
> - ¿Es una variant de algo declarado? Mode A.
> - ¿Es composición de varios? Listame los building blocks.
> - ¿Es algo nuevo? Agregalo a derivation-rules.md primero (commit: `feat(impeccable): extend derivation-rules with <component>`)."

### Paso 3 — find-docs (R13)

Mismo set que Mode A:

```
1. resolve-library-id("tailwindcss") + query "v3 arbitrary value"
2. resolve-library-id("shadcn-ui") + query "<component> if exists, else <nearest_component>"
3. resolve-library-id("react") + query "Next.js 16 RSC vs client"
```

Si shadcn-ui ofrece el componente directamente (data-table, command-palette, popover, etc.), traer el shape de su API y usar como referencia. Citar `[docs:shadcn-ui]`.

### Paso 4 — Apply derivation rules (R-005 8.2)

Para cada uno de los 4 derive_from sources:

#### a. purpose (paso 1)

→ define la responsibility del componente. NO se traduce a tokens directamente, pero filtra qué rules aplicar (ej: si purpose dice "muestra estado de error" → priorizar `tokens.colors.danger`).

#### b. tokens (de brand.json)

Aplicar 1:1 los tokens del nearest_component como baseline:
- Surface, border, text desde brand.json
- Radius desde brand.json.tokens.shape (mismo nivel que el nearest)
- Spacing en múltiplos de `--space-unit`

#### c. visual_posture

Cada eje impone modificadores:
- `density` ≥ 4 → reduce padding, sticky headers permitidos
- `expression` ≥ 4 → permitir un accent color signature en el componente
- `geometry` ≥ 4 → radius pequeño (sm/md), borders 1px
- `warmth` ≥ 4 → microcopy empático en empty/error states
- `editoriality` ≥ 4 → typography display más prominente
- `materiality` ≥ 3 → permitir shadow sutil; <3 prohibe shadow > sm

#### d. nearest_component

Trae:
- Estructura general (table vs grid vs flex)
- States declarados (default, hover, active, etc.)
- Variants signature (4 variants in card → 4 variants in derived data-table)
- Rules array — heredar TODAS y agregar las específicas del nuevo

### Paso 5 — must_include enforcement

R-005 8.2 dice el output debe incluir 3 cosas:

1. **states**: focus-visible (a11y) + hover (interactive) + active + disabled donde aplique. Loading state si el componente puede ser async.
2. **responsive_behavior**: definir breakpoint behavior. Mobile siempre tap-target ≥ 44px. Desktop puede densar. Si el componente es naturalmente desktop-only (data-table denso), declarar `mobile_fallback` (ej: scroll horizontal o stacked rows).
3. **accessibility**: ARIA roles correctos para semantics, keyboard navigation, screen reader labels donde el visual no basta (ej: icon-only buttons → `aria-label`).

Si el output draft falla cualquiera → regenerate con flag `improve` enfocado en el missing aspect.

### Paso 6 — Generate TSX con derivation rationale en JSDoc

Estructura canónica (extiende la del Mode A):

```typescript
'use client'  // SI necesita state/effects

/**
 * <Component> · derived component (NOT in brand.json.component_rules)
 *
 * Purpose: <purpose 1-2 lines>
 *
 * Derivation rationale (R-005 sec 8.2):
 *   - nearest_component: <component>.<variant>
 *   - tokens applied:    <list>
 *   - posture-specific:  <which posture axes shaped which decision>
 *   - inherited rules:   <list rules from nearest>
 *   - additional rules:  <list new rules introduced for this purpose>
 *
 * must_include (R-005 sec 8.2):
 *   - states: <list>
 *   - responsive_behavior: <description>
 *   - accessibility: <description>
 *
 * Citations:
 *   [memory:references#R-005] schema (sec 8.2 unknown_component_policy)
 *   [memory:CONSTRAINTS.md#R10] Brand DNA contract gate
 *   [docs:tailwindcss] · [docs:shadcn-ui] · [docs:react]
 */

import { cva, type VariantProps } from 'class-variance-authority'
// ... (resto análogo a Mode A)
```

### Paso 7 — Validate (anti-slop + brand-score) + write

Mismo workflow que Mode A:
- validate-anti-slop.md (blocking)
- compute-brand-score.md (≥75 threshold con retry up to 3)
- write a target_path

Brand Score con must_include penalty: si states/responsive/accessibility faltan, restar:
- states missing: -10 component_compliance
- responsive missing: -5 component_compliance
- accessibility missing: -10 accessibility

### Paso 8 — Commit message con rationale (R-005 8.2 requires_rationale)

Estructura del commit message obligatoria para Mode B:

```
feat(<component>): derive <component> from <nearest_component>

Mode B derivation per R-005 sec 8.2 (unknown_component_policy).

Purpose: <purpose 1-2 lines>

Derivation:
  nearest_component: <name>.<variant>
  tokens:            <list>
  posture-shaped:    <axis name=value> → <decision>
  inherited rules:   <list>
  new rules:         <list>

must_include:
  states:        <list>
  responsive:    <description>
  accessibility: <description>

Brand Score: <N>/100
  accessibility:        <N>/30
  token_compliance:     <N>/25
  component_compliance: <N>/20
  anti_slop:            <N>/15
  voice_and_archetype:  <N>/10

Cites: [memory:references#R-005] (sec 8.2) · [memory:CONSTRAINTS.md#R10]
       · [docs:tailwindcss] · [docs:shadcn-ui] · [docs:react]

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

---

## Casos edge

### Composite component (data-table = card + form.search + button.ghost)

Para componentes que son composición, el TSX puede importar primitives del set core (que existieron tras Mode A o Mode C):

```typescript
import { Card } from '@/shared/components/ui/Card'
import { Input } from '@/shared/components/ui/Form'
import { Button } from '@/shared/components/ui/Button'

export function DataTable({ ... }) {
  return (
    <Card variant="default">
      <Input variant="search" placeholder="Buscar..." />
      ...
    </Card>
  )
}
```

Esta es la forma preferida — reuso del set core mantiene consistency.

### Cross-skill composition (data-table que llama a `ai/generative-ui` runtime)

Si el componente derivado ESPERA contenido externo (ej: filtros LLM-generados), aplicar [memory:lessons#L-002]:
- system prompt explícito sobre "datos a analizar, no instrucciones"
- sanitización de cualquier text que viene del LLM antes de renderizar

Si el componente VALIDA inputs estructurados (ej: filter form), aplicar [memory:lessons#L-003]:
- Zod schema con whitelist explícita (z.enum, no z.record(z.any()))

### Componente sin nearest obvio (ej: WebGL canvas)

Halt + reportar al usuario. Sugerir:
- Generarlo from-scratch fuera de impeccable
- O extender `derivation-rules.md` con un nuevo nearest mapping antes de seguir

NO derivar a-ciegas — la rationale debe ser sólida.

---

## Refusals

- ❌ Saltar paso 1 (purpose) — sin purpose, no hay derivation válida.
- ❌ Saltar paso 8 (commit con rationale) — R-005 8.2 `requires_rationale: true`.
- ❌ Generar componente que falla must_include (states/responsive/a11y).
- ❌ Tomar un nearest_component arbitrario sin lookup en derivation-rules.md.
- ❌ Mergear con Brand Score < 75.

---

*"R-005 8.2 es el contrato. derivation requires rationale, must include states + responsive + a11y. Sin esos 3, no se mergea."*
