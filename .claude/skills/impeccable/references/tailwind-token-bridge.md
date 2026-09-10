# tailwind.config ↔ brand.json bridge

> Reference para extender `tailwind.config.{js,ts}` con los tokens del brand.json.
>
> **Citation:** [docs:tailwindcss], [memory:references#R-005].

---

## Por qué necesitamos extender tailwind.config

Por default, `bg-[var(--color-primary)]` funciona vía Tailwind arbitrary values pero **NO** ofrece autocompletion ni IntelliSense. Si extendemos `tailwind.config.theme.colors`, las clases `bg-primary`, `text-text-muted`, `border-border` se vuelven sugeribles por el editor.

Tradeoff:
- **Solo arbitrary values**: cero config, todo via `[var(--*)]`. Menos DX.
- **Extended theme**: agrega `tailwind.config.theme.extend.colors` con referencias a CSS vars. Mejor DX, pero el config debe regenerarse cuando brand.json cambia.

impeccable default: **extend theme** + mantener arbitrary values como fallback. El user gana ambos.

---

## tailwind.config.ts canónico (TypeScript)

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/app/**/*.{ts,tsx}',
    './src/shared/components/**/*.{ts,tsx}',
    './src/features/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary:                       'var(--color-primary)',
        'primary-deep':                'var(--color-primary-deep)',
        'primary-on-dark':             'var(--color-primary-accessible-on-dark)',
        'primary-on-light':            'var(--color-primary-accessible-on-light)',
        accent:                        'var(--color-accent)',
        secondary:                     'var(--color-secondary)',
        background:                    'var(--color-background)',
        surface:                       'var(--color-surface)',
        'surface-elevated':            'var(--color-surface-elevated)',
        'surface-higher':              'var(--color-surface-higher)',
        border:                        'var(--color-border)',
        text:                          'var(--color-text)',
        'text-muted':                  'var(--color-text-muted)',
        'text-subtle':                 'var(--color-text-subtle)',
        success:                       'var(--color-success)',
        danger:                        'var(--color-danger)',
        warning:                       'var(--color-warning)',
        info:                          'var(--color-info)',
      },
      fontFamily: {
        display: ['var(--font-display)', 'system-ui', 'sans-serif'],
        body:    ['var(--font-body)', 'system-ui', 'sans-serif'],
        mono:    ['var(--font-mono)', 'ui-monospace', 'monospace'],
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
      },
      borderWidth: {
        DEFAULT: 'var(--border-width)',
      },
      transitionDuration: {
        instant: 'var(--motion-duration-instant)',
        fast:    'var(--motion-duration-fast)',
        base:    'var(--motion-duration-base)',
        slow:    'var(--motion-duration-slow)',
      },
      transitionTimingFunction: {
        brand: 'var(--motion-easing)',
      },
      ringColor: {
        DEFAULT: 'var(--color-primary)',
      },
      // Spacing semantic keys from brand.json (R-005 v1.1.0 keyed objects)
      // section_y = vertical rhythm between page sections
      // component_gap = inline spacing between sibling elements
      spacing: {
        'section-sm': 'var(--section-y-sm)',
        'section-md': 'var(--section-y-md)',
        'section-lg': 'var(--section-y-lg)',
        'gap-xs':     'var(--gap-xs)',
        'gap-sm':     'var(--gap-sm)',
        'gap-md':     'var(--gap-md)',
        'gap-lg':     'var(--gap-lg)',
        // Tailwind core scale (1-24) preserved — used for ad-hoc spacing.
        // For semantic page rhythm, prefer section-md / gap-md utilities.
      },
    },
  },
  plugins: [
    // typography plugin opcional cuando hay editorial content
    // require('@tailwindcss/typography')
  ],
}

export default config
```

---

## Cómo impeccable lo modifica

### Caso 1: tailwind.config.ts ya existe

impeccable detecta el archivo. Si:
- `theme.extend.colors.primary` ya existe y mappea a `var(--color-primary)` → no-op (ya configurado por add-ui-kit handoff o sesión previa).
- `theme.extend.colors.primary` no existe → extiende manteniendo el resto del config intacto.
- `theme.extend.colors.primary` mappea a un literal hex → halt + reportar conflicto al usuario (puede ser pre-add-ui-kit; necesita coordinación).

### Caso 2: tailwind.config no existe

impeccable genera el archivo completo (template arriba) + reporta al usuario:

> "Generé `tailwind.config.ts`. Revisá `content` glob — apunta a `./src/**`, ajustá si tu estructura difiere."

### Caso 3: tailwind.config.js (CommonJS)

Convertir mentalmente a JS pero NO sobreescribir el archivo. impeccable extiende manteniendo el módulo CommonJS:

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  // ...
}
```

---

## Generación de utility classes desde tokens

Una vez extendido, las clases sugeribles son:

| Clase | Resuelve a |
|-------|-----------|
| `bg-primary` | `background-color: var(--color-primary)` |
| `text-text-muted` | `color: var(--color-text-muted)` |
| `border-border` | `border-color: var(--color-border)` |
| `font-display` | `font-family: var(--font-display)` |
| `rounded-md` | `border-radius: var(--radius-md)` |
| `duration-fast` | `transition-duration: var(--motion-duration-fast)` |
| `ease-brand` | `transition-timing-function: var(--motion-easing)` |
| `ring-primary` | `--tw-ring-color: var(--color-primary)` |

impeccable prefiere estas clases sobre `[var(--*)]` syntax cuando el extend está disponible (más limpio y autocompletable).

---

## Ejemplo end-to-end

### Antes (sin extend, todo arbitrary)

```tsx
<button className="bg-[var(--color-primary)] text-white font-[family-name:var(--font-display)] rounded-[var(--radius-md)] hover:opacity-90 transition-colors duration-[var(--motion-duration-fast)]">
  Click
</button>
```

### Después (con extend en tailwind.config)

```tsx
<button className="bg-primary text-white font-display rounded-md hover:opacity-90 transition-colors duration-fast">
  Click
</button>
```

Mismas clases CSS resueltas, pero TSX más limpio y autocompletable.

---

## Plugins recomendados (opcionales)

| Plugin | Cuándo |
|--------|--------|
| `@tailwindcss/typography` | si el proyecto tiene long-form content (blogs, docs, marketing pages) |
| `@tailwindcss/forms` | reset estándar de form elements — pero impeccable lo override con tokens |
| `@tailwindcss/container-queries` | si components.json declara responsive container variants |
| `tailwindcss-animate` | si quiere animations utility (requerido por shadcn defaults) |

Decisión por proyecto, no impone impeccable.

---

## Semantic spacing utilities (R-005 v1.1.0)

Después de R-005 v1.1.0 (closes [memory:errors#E-002]), `tokens.spacing.section_y` y `component_gap` son keyed objects con nombres semánticos. impeccable expone estos como utility classes Tailwind:

| Utility class | Resuelve a | Cuándo |
|----------------|-----------|--------|
| `py-section-sm` / `py-section-md` / `py-section-lg` | `var(--section-y-{sm,md,lg})` | rhythm vertical entre page sections |
| `gap-gap-xs` / `gap-gap-sm` / `gap-gap-md` / `gap-gap-lg` | `var(--gap-{xs,sm,md,lg})` | inline spacing entre sibling elements |
| `mt-gap-md`, `mb-gap-lg`, etc. | mismo | reusable en margin/padding utilities |

Antes de R-005 v1.1.0, esto requería `py-[var(--section-y-md)]` arbitrary values (más verbose). Ahora es `py-section-md` directo (autocompletable + cleaner). Componentes existentes pueden seguir usando arbitrary values; nuevos generados por impeccable Mode A/B/C prefieren las clases semánticas.

## Citation

**Source:** [docs:tailwindcss] (vía Context7 — query "v3 config theme extend custom colors css vars").
**Verified:** la sintaxis `var(--*)` en `theme.extend.colors` es soportada desde Tailwind v3.0+ y se mantiene en v4.0 (con sintaxis CSS-first opcional).

R13 enforced — antes de generar el config, find-docs valida la sintaxis actual.

---

*"Los tokens viven en brand.css. tailwind.config los expone como utility classes. impeccable bridges ambos."*
