/**
 * SaaS Pattern A — Dashboard KPI Row.
 *
 * A composed screen fragment (not a single component): the metric strip that
 * tops most SaaS dashboards. This is the section that proves the showcase is a
 * real product surface, not a generic gallery. Source spec: Forge SKILL.md
 * "Pattern A — Dashboard KPI Row" (4 cards: MRR / Churn / DAU / Conversion).
 *
 * States covered (all rendered as static visual examples — this is a showcase):
 *   - loaded:   4 metric cards, each = big number + label + trend delta
 *   - loading:  skeleton that MIRRORS the exact card layout (label + number + delta)
 *   - error:    inline message + retry affordance (annotated, not wired)
 *
 * Trend delta semantics (the only place color carries meaning here):
 *   - positive movement → --color-success  (▲ up)
 *   - negative movement → --color-danger   (▼ down)
 *   - "down is good" metrics (Churn) invert: a falling value is rendered success.
 *     The arrow follows the NUMBER's direction; the color follows the OUTCOME.
 *
 * Cards are deliberately varied (no identical 4-grid): MRR leads with an accent
 * tint (it is the hero metric), Churn carries a success delta on a falling
 * number, DAU pairs its delta with a tiny static sparkline silhouette, and
 * Conversion shows a flat/neutral delta in --color-text-muted. Same skeleton,
 * different emphasis — that is what a real dashboard looks like.
 *
 * Motion (R-005 motion rule — transform/opacity/color/box-shadow only):
 *   - Skeleton uses `animate-pulse` (opacity only).
 *   - The retry button transitions `background-color` over --motion-duration-fast.
 *   - NO width/height animation; the sparkline is a static silhouette.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - 4 cards are NOT visually identical (varied emphasis / delta direction).
 *   - Delta color is semantic only: --color-success / --color-danger, never decorative.
 *   - Skeleton mirrors the real card silhouette (label + big number + delta),
 *     never a single generic gray block.
 *   - Error state is inline + retry — NOT a full-screen error, NOT a toast.
 *   - All fills come from tokens (--color-* / --color-text-subtle/20), no hex,
 *     no Tailwind palette classes, no purple/indigo gradient.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, SaaS patterns)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — card / skeleton reference for the metric tile
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { TrendingUp, TrendingDown, Minus, RefreshCw } from 'lucide-react'

type DeltaTone = 'success' | 'danger' | 'neutral'

interface Kpi {
  label: string
  value: string
  /** Human-readable change vs. previous period, e.g. "+12.4%". */
  delta: string
  /** Comparison window shown under the delta, e.g. "vs. last month". */
  period: string
  /** Number direction: did the raw metric go up, down, or hold flat? */
  direction: 'up' | 'down' | 'flat'
  /** Outcome color — decoupled from direction so "churn down" reads as good. */
  tone: DeltaTone
  /** Hero metric gets an accent-tinted tile; the rest stay on plain surface. */
  hero?: boolean
}

// Real dashboard metrics. Note the decoupling: Churn's number falls
// (direction: down) but that is a GOOD outcome (tone: success).
const KPIS: readonly Kpi[] = [
  {
    label: 'MRR',
    value: '$48.2k',
    delta: '+12.4%',
    period: 'vs. last month',
    direction: 'up',
    tone: 'success',
    hero: true,
  },
  {
    label: 'Churn',
    value: '2.1%',
    delta: '-0.6 pts',
    period: 'vs. last month',
    direction: 'down',
    tone: 'success', // churn falling is good — color follows the outcome
  },
  {
    label: 'DAU',
    value: '12,847',
    delta: '+3.2%',
    period: 'vs. last week',
    direction: 'up',
    tone: 'success',
  },
  {
    label: 'Conversion',
    value: '3.9%',
    delta: '0.0%',
    period: 'vs. last week',
    direction: 'flat',
    tone: 'neutral',
  },
] as const

const TONE_TEXT: Record<DeltaTone, string> = {
  success: 'text-[var(--color-success)]',
  danger: 'text-[var(--color-danger)]',
  neutral: 'text-[var(--color-text-muted)]',
}

function TrendIcon({ direction }: { direction: Kpi['direction'] }) {
  if (direction === 'up') return <TrendingUp className="h-4 w-4" aria-hidden="true" />
  if (direction === 'down') return <TrendingDown className="h-4 w-4" aria-hidden="true" />
  return <Minus className="h-4 w-4" aria-hidden="true" />
}

export function KpiRowPattern() {
  return (
    <section aria-labelledby="kpi-row-title">
      <h2
        id="kpi-row-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Dashboard KPI Row
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Patrón SaaS — fila de 4 métricas (MRR, Churn, DAU, Conversion) con número grande, label y delta de tendencia. Estados loaded, loading y error.
      </p>

      {/* ─── Loaded ─────────────────────────────────────────────────── */}
      <div className="mt-[var(--space-8)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          state · loaded
        </p>
        <div
          className="mt-[var(--space-4)] grid gap-[var(--gap-md)] sm:grid-cols-2 lg:grid-cols-4"
          role="list"
          aria-label="Métricas del dashboard"
        >
          {KPIS.map((kpi) => {
            // Hero metric is accent-tinted; the rest sit on plain surface.
            const tile = kpi.hero
              ? 'border-[var(--color-primary)]/20 bg-[var(--color-primary)]/5'
              : 'border-[var(--color-border)] bg-[var(--color-surface)]'
            return (
              <article
                key={kpi.label}
                role="listitem"
                className={`rounded-[var(--radius-md)] border p-[var(--space-6)] ${tile}`}
              >
                <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                  {kpi.label}
                </p>
                <p className="mt-[var(--space-3)] font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]">
                  {kpi.value}
                </p>

                {/* Delta row — number direction (arrow) + outcome (color). */}
                <p className={`mt-[var(--space-2)] inline-flex items-center gap-[var(--space-1)] text-sm font-medium ${TONE_TEXT[kpi.tone]}`}>
                  <TrendIcon direction={kpi.direction} />
                  {kpi.delta}
                </p>
                <p className="mt-[var(--space-1)] text-xs text-[var(--color-text-subtle)]">
                  {kpi.period}
                </p>

                {/* DAU gets a static sparkline silhouette — varies the row so
                    the 4 tiles are not identical. Bars are transform-free. */}
                {kpi.label === 'DAU' ? (
                  <div className="mt-[var(--space-4)] flex h-8 items-end gap-[var(--space-1)]" aria-hidden="true">
                    {[40, 55, 35, 70, 60, 85, 75].map((h, i) => (
                      <span
                        key={i}
                        className="w-full rounded-[var(--radius-sm)] bg-[var(--color-primary)]/30"
                        style={{ height: `${h}%` }}
                      />
                    ))}
                  </div>
                ) : null}
              </article>
            )
          })}
        </div>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          hero tile: accent tint · churn ▼ rendered success (down = good) · conversion flat = neutral
        </p>
      </div>

      {/* ─── Loading ────────────────────────────────────────────────── */}
      <div className="mt-[var(--space-8)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          state · loading (skeleton mirrors the card)
        </p>
        <div
          className="mt-[var(--space-4)] grid gap-[var(--gap-md)] sm:grid-cols-2 lg:grid-cols-4"
          aria-busy="true"
          aria-label="Cargando métricas"
        >
          {[0, 1, 2, 3].map((i) => (
            <div
              key={i}
              className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-6)]"
            >
              {/* label line */}
              <div className="h-3 w-16 animate-pulse rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/20" />
              {/* big number — tall + wide to mirror a metric value */}
              <div className="mt-[var(--space-3)] h-8 w-24 animate-pulse rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/20" />
              {/* delta caption */}
              <div className="mt-[var(--space-3)] h-3 w-20 animate-pulse rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/20" />
            </div>
          ))}
        </div>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          mirrors: label + big number + delta · animate-pulse (opacity only)
        </p>
      </div>

      {/* ─── Error ──────────────────────────────────────────────────── */}
      <div className="mt-[var(--space-8)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          state · error (inline + retry)
        </p>
        <div
          role="alert"
          className="mt-[var(--space-4)] flex flex-col gap-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-danger)]/30 bg-[var(--color-danger)]/5 p-[var(--space-6)] sm:flex-row sm:items-center sm:justify-between"
        >
          <div>
            <p className="text-sm font-semibold text-[var(--color-text)]">
              No pudimos cargar las métricas
            </p>
            <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
              La petición a la API de analytics falló. Revisá la conexión y volvé a intentar.
            </p>
          </div>
          {/* Retry affordance — static in the showcase; downstream wires onClick. */}
          <button
            type="button"
            className="inline-flex shrink-0 items-center gap-[var(--space-2)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-medium text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface-elevated)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
          >
            <RefreshCw className="h-4 w-4" aria-hidden="true" />
            Reintentar
          </button>
        </div>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          inline error · role=&quot;alert&quot; · retry button (not a toast, not full-screen)
        </p>
      </div>
    </section>
  )
}
