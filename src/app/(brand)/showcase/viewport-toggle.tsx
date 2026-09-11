'use client'

/**
 * ViewportToggle — simulates desktop / tablet / mobile viewports INSIDE the
 * showcase without iframes. Wraps the showcase content and renders a fixed
 * top toolbar with 3 mode buttons.
 *
 * Three modes:
 *   "desktop" → no width constraint (full browser width)
 *   "tablet"  → max-width 768px, centered, side shadow to indicate the crop
 *   "mobile"  → max-width 375px, centered, side shadow
 *
 * The toolbar (3 buttons) is always full-width, fixed at the top. The inner
 * content transitions max-width with a soft expo-out curve so resizing reads
 * as a deliberate viewport change rather than a snap. State is persisted in
 * localStorage ("ui-kit-viewport") so the chosen viewport survives reloads.
 *
 * Active button indicator: bg-[var(--color-primary)]/10 + text-[var(--color-primary)].
 * Icons: Monitor (desktop), Tablet (tablet), Smartphone (mobile) — Lucide only.
 *
 * Citations:
 *   [memory:references#R-005]   — Brand DNA schema (tokens consumed as CSS vars)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded hex/fonts)
 *   [docs:nextjs]               — 'use client' directive (localStorage + hooks)
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *
 * This is showcase chrome (dev-only). The max-width transition is intentional
 * here — it IS the viewport-resize affordance — and uses the spec's 350ms
 * expo-out curve via inline style. All color/type/shape values stay 1:1 with
 * brand.css CSS vars; no inline hex, font names, or Tailwind color classes.
 */

import { useEffect, useState } from 'react'
import { Monitor, Tablet, Smartphone } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'

export type Viewport = 'desktop' | 'tablet' | 'mobile'

/** localStorage key — persists the chosen viewport across reloads. */
export const VIEWPORT_STORAGE_KEY = 'ui-kit-viewport'

/** Per-mode max-width (px). `null` = unconstrained (full browser width). */
const VIEWPORT_MAX_WIDTH: Record<Viewport, number | null> = {
  desktop: null,
  tablet: 768,
  mobile: 375,
}

const VIEWPORT_MODES: { value: Viewport; label: string; Icon: LucideIcon }[] = [
  { value: 'desktop', label: 'Desktop', Icon: Monitor },
  { value: 'tablet', label: 'Tablet', Icon: Tablet },
  { value: 'mobile', label: 'Mobile', Icon: Smartphone },
]

/** Soft expo-out curve from the spec — distinct from brand --motion-easing. */
const VIEWPORT_EASING = 'cubic-bezier(0.16, 1, 0.3, 1)'

function isViewport(value: string | null): value is Viewport {
  return value === 'desktop' || value === 'tablet' || value === 'mobile'
}

export interface ViewportToggleProps {
  children: React.ReactNode
}

export function ViewportToggle({ children }: ViewportToggleProps) {
  const [viewport, setViewport] = useState<Viewport>('desktop')

  // Read persisted preference on mount (client only — avoids hydration mismatch).
  // Genuine external-system sync (localStorage can't be read during SSR/first
  // render without a mismatch), one of the two valid effect purposes the rule
  // itself documents — not a derived-state anti-pattern.
  useEffect(() => {
    const stored = window.localStorage.getItem(VIEWPORT_STORAGE_KEY)
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (isViewport(stored)) setViewport(stored)
  }, [])

  function selectViewport(next: Viewport) {
    setViewport(next)
    window.localStorage.setItem(VIEWPORT_STORAGE_KEY, next)
  }

  const maxWidth = VIEWPORT_MAX_WIDTH[viewport]
  const isConstrained = maxWidth !== null

  return (
    <div className="min-h-screen bg-[var(--color-surface)]">
      <div
        role="toolbar"
        aria-label="Showcase viewport"
        className="sticky top-0 z-50 flex items-center justify-center gap-[var(--gap-xs)] border-b border-[var(--color-border)] bg-[var(--color-surface-elevated)]/80 px-[var(--space-4)] py-[var(--space-2)] backdrop-blur"
      >
        {VIEWPORT_MODES.map(({ value, label, Icon }) => {
          const active = viewport === value
          return (
            <button
              key={value}
              type="button"
              onClick={() => selectViewport(value)}
              aria-pressed={active}
              aria-label={`${label} viewport`}
              className={[
                'inline-flex items-center gap-[var(--gap-xs)] rounded-[var(--radius-md)] px-[var(--space-3)] py-[var(--space-2)] text-sm font-medium',
                'transition-colors duration-[var(--motion-duration-fast)]',
                'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]',
                active
                  ? 'bg-[var(--color-primary)]/10 text-[var(--color-primary)]'
                  : 'text-[var(--color-text-muted)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text)]',
              ].join(' ')}
            >
              <Icon className="h-5 w-5" aria-hidden />
              <span className="hidden sm:inline">{label}</span>
            </button>
          )
        })}
      </div>

      {/* Inner stage — transitions max-width so the viewport change reads as a
          deliberate resize. Side shadow + border mark the crop when constrained. */}
      <div
        data-viewport={viewport}
        className="mx-auto w-full overflow-hidden transition-[max-width] duration-[350ms]"
        style={{
          maxWidth: isConstrained ? `${maxWidth}px` : '100%',
          transitionTimingFunction: VIEWPORT_EASING,
          boxShadow: isConstrained
            ? '0 0 0 1px var(--color-border), 0 24px 64px -16px color-mix(in srgb, var(--color-text) 35%, transparent)'
            : 'none',
        }}
      >
        {children}
      </div>
    </div>
  )
}

export default ViewportToggle
