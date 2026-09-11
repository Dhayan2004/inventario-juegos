/**
 * Palette Section — renders all color tokens from brand.css.
 * Token names mirror brand.json.tokens.colors.* exactly.
 *
 * Anti-Slop Gate hook: el-evaluador screenshots this section and runs
 * hue-range check against the rendered swatches — if any swatch falls
 * in [235°, 285°] without `archetype.primary === 'Magician'`, NEEDS_FIX.
 */

const COLOR_TOKENS: Array<{ name: string; label: string; isBorderToken?: boolean }> = [
  { name: 'primary', label: 'Primary' },
  { name: 'primary-deep', label: 'Primary deep' },
  { name: 'accent', label: 'Accent' },
  { name: 'surface', label: 'Surface' },
  { name: 'surface-elevated', label: 'Surface elevated' },
  { name: 'border', label: 'Border', isBorderToken: true },
  { name: 'text', label: 'Text' },
  { name: 'text-muted', label: 'Text muted' },
  { name: 'text-subtle', label: 'Text subtle' },
  { name: 'success', label: 'Success' },
  { name: 'danger', label: 'Danger' },
  { name: 'warning', label: 'Warning' },
]

export function PaletteSection() {
  return (
    <section aria-labelledby="palette-title">
      <h2
        id="palette-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Palette
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Cada swatch lee directo de <code className="font-mono">--color-*</code> en{' '}
        <code className="font-mono">brand.css</code>. No hex inline — single source of truth.
      </p>

      <div className="mt-[var(--space-8)] grid grid-cols-2 gap-[var(--gap-md)] sm:grid-cols-3 md:grid-cols-4">
        {COLOR_TOKENS.map(({ name, label, isBorderToken }) => (
          <div
            key={name}
            className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-3)]"
          >
            <div
              className="h-16 w-full rounded-[var(--radius-sm)]"
              style={{
                background: isBorderToken ? 'transparent' : `var(--color-${name})`,
                borderWidth: isBorderToken ? '4px' : 0,
                borderColor: isBorderToken ? `var(--color-${name})` : 'transparent',
                borderStyle: isBorderToken ? 'solid' : 'none',
              }}
              aria-label={`Swatch for color-${name}`}
            />
            <p className="mt-[var(--space-2)] font-mono text-xs text-[var(--color-text-muted)]">
              --color-{name}
            </p>
            <p className="text-sm text-[var(--color-text)]">{label}</p>
          </div>
        ))}
      </div>
    </section>
  )
}
