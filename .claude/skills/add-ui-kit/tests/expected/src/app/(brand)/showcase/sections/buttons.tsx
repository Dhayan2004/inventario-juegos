/**
 * Buttons Section — renders the canonical Button variant + size + state matrix
 * declared in brand.json.component_rules (R-005 sec 3.3, "button").
 *
 * Variants covered (R-005 Regla 8 — canonical set, no ad-hoc className):
 *   default · secondary · outline · ghost · destructive · link
 * Sizes covered:
 *   sm · default · lg
 * States covered:
 *   default · hover (mono caption) · focus-visible (ring shown statically) ·
 *   loading (Loader2 spinner, animate-spin = transform only) · disabled
 * In-context example:
 *   "Guardar cambios" (default / primary CTA) + "Cancelar" (ghost) form pair.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Button default: NO diagonal/purple-to-blue gradient — solid
 *     bg-[var(--color-primary)] only.
 *   - Hierarchy: exactly ONE default CTA per context (the form pair); every
 *     other action is secondary/outline/ghost.
 *   - Motion: only background-color/opacity/transform animate; never
 *     width/height/padding (loading spinner uses animate-spin = transform).
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, button)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — 6 canonical button variants reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { Loader2 } from 'lucide-react'

// Shared transition string — background-color + opacity + color, fast easing.
// Only animatable-safe properties (R-005 motion rule).
const TRANSITION =
  'transition-[background-color,opacity,color,border-color] duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'

// Variant → className map. Each variant resolves to CSS-var tokens only.
const VARIANTS = [
  {
    key: 'default',
    label: 'default',
    className: `bg-[var(--color-primary)] text-white hover:bg-[var(--color-primary-deep)] focus-visible:outline-[var(--color-primary)]`,
  },
  {
    key: 'secondary',
    label: 'secondary',
    className: `bg-[var(--color-secondary)] text-white hover:opacity-90 focus-visible:outline-[var(--color-secondary)]`,
  },
  {
    key: 'outline',
    label: 'outline',
    className: `border border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-text)] hover:bg-[var(--color-surface-elevated)] focus-visible:outline-[var(--color-primary)]`,
  },
  {
    key: 'ghost',
    label: 'ghost',
    className: `text-[var(--color-text-muted)] hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)] focus-visible:outline-[var(--color-primary)]`,
  },
  {
    key: 'destructive',
    label: 'destructive',
    className: `bg-[var(--color-danger)] text-white hover:opacity-90 focus-visible:outline-[var(--color-danger)]`,
  },
  {
    key: 'link',
    label: 'link',
    className: `text-[var(--color-primary)] underline underline-offset-4 hover:text-[var(--color-primary-deep)] focus-visible:outline-[var(--color-primary)]`,
  },
] as const

// Size → padding/text scale map. Spacing comes from --space-* tokens.
const SIZES = [
  { key: 'sm', label: 'sm', className: 'px-[var(--space-3)] py-[var(--space-1)] text-xs' },
  { key: 'default', label: 'default', className: 'px-[var(--space-4)] py-[var(--space-2)] text-sm' },
  { key: 'lg', label: 'lg', className: 'px-[var(--space-6)] py-[var(--space-3)] text-base' },
] as const

// Base button shape shared by every variant/size. Focus-visible ring is never
// removed (a11y). rounded + font-display from tokens.
const BASE =
  'inline-flex items-center justify-center gap-[var(--space-2)] rounded-[var(--radius-md)] font-[family-name:var(--font-display)] font-semibold focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2'

function cx(...parts: string[]) {
  return parts.join(' ')
}

export function ButtonsSection() {
  return (
    <section aria-labelledby="buttons-title">
      <h2
        id="buttons-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Buttons
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        6 variantes canónicas (R-005 Regla 8) × 3 tamaños × estados. Máximo 1{' '}
        <code className="font-mono">default</code> por pantalla — el resto secondary/outline/ghost.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-2">
        {/* Variants — all 6, default size */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            variants · 6 canonical
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-center gap-[var(--gap-sm)]">
            {VARIANTS.map(({ key, label, className }) => (
              <button
                key={key}
                type="button"
                className={cx(BASE, SIZES[1].className, TRANSITION, className)}
              >
                {label}
              </button>
            ))}
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            hover → background-color + opacity · 150ms ease-out-expo
          </p>
        </article>

        {/* Sizes — sm / default / lg on the primary variant */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            sizes · sm / default / lg
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-center gap-[var(--gap-sm)]">
            {SIZES.map(({ key, label, className }) => (
              <button
                key={key}
                type="button"
                className={cx(BASE, className, TRANSITION, VARIANTS[0].className)}
              >
                Button {label}
              </button>
            ))}
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            padding/text scale from --space-* tokens
          </p>
        </article>

        {/* States — default / focus-visible / loading / disabled */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            states · default / focus / loading / disabled
          </p>
          <div className="mt-[var(--space-4)] grid gap-[var(--gap-sm)]">
            {/* default */}
            <div className="flex items-center gap-[var(--space-4)]">
              <button
                type="button"
                className={cx(BASE, SIZES[1].className, TRANSITION, VARIANTS[0].className)}
              >
                Guardar
              </button>
              <span className="font-mono text-xs text-[var(--color-text-subtle)]">default</span>
            </div>

            {/* focus-visible — ring rendered statically so it shows in screenshot */}
            <div className="flex items-center gap-[var(--space-4)]">
              <button
                type="button"
                className={cx(
                  BASE,
                  SIZES[1].className,
                  VARIANTS[0].className,
                  // static ring mirrors the live focus-visible outline
                  'outline outline-2 outline-offset-2 outline-[var(--color-primary)]',
                )}
              >
                Guardar
              </button>
              <span className="font-mono text-xs text-[var(--color-text-subtle)]">
                focus-visible (ring)
              </span>
            </div>

            {/* loading — disabled + aria-busy + spinner (transform only) */}
            <div className="flex items-center gap-[var(--space-4)]">
              <button
                type="button"
                disabled
                aria-busy="true"
                className={cx(
                  BASE,
                  SIZES[1].className,
                  VARIANTS[0].className,
                  'cursor-progress opacity-80',
                )}
              >
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                Guardando…
              </button>
              <span className="font-mono text-xs text-[var(--color-text-subtle)]">
                loading (disabled + aria-busy)
              </span>
            </div>

            {/* disabled */}
            <div className="flex items-center gap-[var(--space-4)]">
              <button
                type="button"
                disabled
                className={cx(
                  BASE,
                  SIZES[1].className,
                  VARIANTS[0].className,
                  'cursor-not-allowed opacity-50',
                )}
              >
                Guardar
              </button>
              <span className="font-mono text-xs text-[var(--color-text-subtle)]">disabled</span>
            </div>
          </div>
        </article>

        {/* In-context — form footer: 1 primary CTA + 1 ghost cancel */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            in-context · form footer
          </p>
          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-6)]">
            <h3 className="font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
              Editar perfil
            </h3>
            <p className="mt-[var(--space-2)] text-sm text-[var(--color-text-muted)]">
              Los cambios se aplican de inmediato a tu cuenta.
            </p>
            <div className="mt-[var(--space-6)] flex justify-end gap-[var(--gap-xs)]">
              {/* ghost = secondary action, no competing CTA */}
              <button
                type="button"
                className={cx(BASE, SIZES[1].className, TRANSITION, VARIANTS[3].className)}
              >
                Cancelar
              </button>
              {/* default = single primary CTA */}
              <button
                type="button"
                className={cx(BASE, SIZES[1].className, TRANSITION, VARIANTS[0].className)}
              >
                Guardar cambios
              </button>
            </div>
          </div>
        </article>
      </div>
    </section>
  )
}
