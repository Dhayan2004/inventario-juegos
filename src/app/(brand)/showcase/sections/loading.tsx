/**
 * Loading Section — renders the canonical loading-state vocabulary from
 * brand.json.component_rules (R-005 sec 3.3, "Loading States" / Regla 9).
 *
 * The cardinal rule of this section: a skeleton MIRRORS the exact layout of the
 * thing that is loading — never a generic gray block. Each skeleton below is the
 * silhouette of a real component the downstream app renders.
 *
 * Variants covered (R-005 Regla 9):
 *   - skeleton · dashboard card  (big number + label silhouette)
 *   - skeleton · table row       (cells matching column rhythm)
 *   - skeleton · profile         (avatar + name + bio lines)
 *   - progress · determinate     (value-driven bar)
 *   - progress · indeterminate   (animate-pulse track)
 *   - spinner · inline           (Loader2 in a loading button — for data loads,
 *     NEVER a full-screen spinner)
 *
 * Motion (R-005 motion rule — transform/opacity/color only):
 *   - Skeleton uses `animate-pulse` (opacity only).
 *   - Spinner uses `animate-spin` (transform only).
 *   - The determinate bar's width is fixed via inline style (static showcase);
 *     real apps must animate `transform: scaleX`, NEVER `width`.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Skeletons match a real layout (number+label / row / avatar+name+bio) —
 *     no single generic rounded rectangle standing in for "loading".
 *   - Skeleton fills come from muted tokens (--color-border /
 *     --color-text-subtle), never a hardcoded gray.
 *   - Loading button is `disabled` + `aria-busy` with an `aria-hidden` spinner.
 *   - NO full-screen / full-page spinner for a data load.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, Loading States)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-border)]
 *   [docs:shadcn-ui]            — skeleton / progress / spinner reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { Loader2 } from 'lucide-react'

// Shared skeleton bar — muted token fill + pulse (opacity only).
// Tone comes from --color-text-subtle at low alpha so it reads as "absent
// content", never a hardcoded gray. Caller sets width/height utilities.
const BAR = 'animate-pulse rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/20'

export function LoadingSection() {
  return (
    <section aria-labelledby="loading-title">
      <h2
        id="loading-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Loading States
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        R-005 sección 3.3 — el skeleton imita el layout exacto que carga, nunca un bloque genérico. Spinner inline para botones, jamás pantalla completa.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-2">
        {/* Skeleton — dashboard card (big number + label silhouette) */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            skeleton · dashboard card
          </p>
          <div
            className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)]"
            aria-busy="true"
            aria-label="Cargando métrica"
          >
            {/* label line */}
            <div className={`${BAR} h-3 w-24`} />
            {/* big number — tall + wide to mirror a metric value */}
            <div className={`${BAR} mt-[var(--space-3)] h-8 w-32`} />
            {/* delta caption */}
            <div className={`${BAR} mt-[var(--space-3)] h-3 w-20`} />
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            mirrors: label + big number + delta · animate-pulse
          </p>
        </article>

        {/* Skeleton — table row (cells matching column rhythm) */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            skeleton · table row
          </p>
          <div
            className="mt-[var(--space-4)] divide-y divide-[var(--color-border)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]"
            aria-busy="true"
            aria-label="Cargando filas"
          >
            {[0, 1, 2].map((row) => (
              <div
                key={row}
                className="flex items-center gap-[var(--space-4)] p-[var(--space-3)]"
              >
                {/* name cell (wide) */}
                <div className={`${BAR} h-3 flex-1`} />
                {/* status cell (medium) */}
                <div className={`${BAR} h-3 w-16`} />
                {/* amount cell (narrow, right-aligned) */}
                <div className={`${BAR} h-3 w-12`} />
              </div>
            ))}
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            mirrors: 3 cells per row · column rhythm preserved
          </p>
        </article>

        {/* Skeleton — profile (avatar + name + bio) */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            skeleton · profile
          </p>
          <div
            className="mt-[var(--space-4)] flex items-start gap-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)]"
            aria-busy="true"
            aria-label="Cargando perfil"
          >
            {/* avatar — circular, matches a real avatar footprint */}
            <div className="h-12 w-12 shrink-0 animate-pulse rounded-full bg-[var(--color-text-subtle)]/20" />
            <div className="flex-1 space-y-[var(--space-2)]">
              {/* name line */}
              <div className={`${BAR} h-4 w-32`} />
              {/* handle / role line */}
              <div className={`${BAR} h-3 w-20`} />
              {/* bio lines */}
              <div className={`${BAR} h-3 w-full`} />
              <div className={`${BAR} h-3 w-4/5`} />
            </div>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            mirrors: avatar + name + handle + 2 bio lines
          </p>
        </article>

        {/* Progress — determinate + indeterminate */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            progress · determinate + indeterminate
          </p>
          <div className="mt-[var(--space-4)] space-y-[var(--space-6)]">
            {/* Determinate — known value, ARIA exposes it */}
            <div className="space-y-[var(--space-2)]">
              <div className="flex items-baseline justify-between">
                <span className="text-sm text-[var(--color-text)]">Subiendo archivo</span>
                <span className="font-mono text-xs text-[var(--color-text-subtle)]">68%</span>
              </div>
              <div
                role="progressbar"
                aria-valuenow={68}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-label="Progreso de subida"
                className="h-2 w-full overflow-hidden rounded-full bg-[var(--color-text-subtle)]/20"
              >
                <div
                  className="h-full rounded-full bg-[var(--color-primary)]"
                  style={{ width: '68%' }}
                />
              </div>
              <p className="font-mono text-xs text-[var(--color-text-subtle)]">
                determinate · real apps animate transform:scaleX, never width
              </p>
            </div>

            {/* Indeterminate — unknown duration, pulse the whole track */}
            <div className="space-y-[var(--space-2)]">
              <span className="text-sm text-[var(--color-text)]">Procesando…</span>
              <div
                role="progressbar"
                aria-label="Procesando, duración desconocida"
                className="h-2 w-full animate-pulse overflow-hidden rounded-full bg-[var(--color-primary)]/30"
              >
                <div className="h-full w-1/3 rounded-full bg-[var(--color-primary)]" />
              </div>
              <p className="font-mono text-xs text-[var(--color-text-subtle)]">
                indeterminate · animate-pulse · no aria-valuenow
              </p>
            </div>
          </div>
        </article>

        {/* Spinner — inline in a loading button (NEVER full-screen for data) */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)] md:col-span-2">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            spinner · inline (button loading state)
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-center gap-[var(--space-4)]">
            {/* Primary loading button — disabled + aria-busy + spinner */}
            <button
              type="button"
              disabled
              aria-busy="true"
              className="inline-flex cursor-progress items-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-white opacity-80"
            >
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
              Guardando…
            </button>

            {/* Secondary loading button — same contract, ghost-ish surface */}
            <button
              type="button"
              disabled
              aria-busy="true"
              className="inline-flex cursor-progress items-center gap-[var(--space-2)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-medium text-[var(--color-text-muted)] opacity-80"
            >
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
              Sincronizando…
            </button>

            {/* Standalone inline spinner — for an in-place region, not the page */}
            <span className="inline-flex items-center gap-[var(--space-2)] text-sm text-[var(--color-text-muted)]">
              <Loader2 className="h-5 w-5 animate-spin text-[var(--color-primary)]" aria-hidden="true" />
              Cargando comentarios…
            </span>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            disabled + aria-busy · animate-spin (transform only) · NO full-screen spinner for data loads
          </p>
        </article>
      </div>
    </section>
  )
}
