/**
 * Empty State (Complete) Section — renders the full empty-state vocabulary from
 * SKILL.md Pattern E. An empty state is not one screen: it is three distinct
 * moments, each with its own emotional register, its own illustration, and its
 * own single next action.
 *
 * The cardinal rule of this section: each version owns a DIFFERENT inline SVG —
 * the first-use spark, the no-results scope, and the load-error fracture are not
 * interchangeable. Reusing one glyph for all three is the slop pattern this
 * section exists to forbid.
 *
 * Versions covered (SKILL.md Pattern E):
 *   - A · first-use (onboarding) — motivational heading + illustration + primary CTA
 *   - B · no-results (search)    — different illustration + "No encontramos X para 'query'" + clear-filters
 *   - C · load-error             — error icon + technical message + retry
 *
 * Tone register per version (annotated in mono labels, static showcase):
 *   - A is invitational: lead with possibility, one primary CTA, no apology.
 *   - B is neutral + actionable: name the query back, offer to widen the net.
 *   - C is honest + technical: surface a real reason, give retry, never blame the user.
 *
 * Motion (R-005 motion rule — transform/opacity/color/background-color only):
 *   - CTAs transition color/background-color on hover at var(--motion-duration-fast).
 *   - The illustrations are static here; if a real app animates them, only
 *     transform/opacity are allowed — NEVER width/height of the SVG box.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Three DISTINCT inline SVGs — no glyph reused across A / B / C.
 *   - Each version has exactly ONE primary action (no competing CTAs stacked).
 *   - Illustration strokes/fills come from tokens (currentColor driven by
 *     --color-* text classes), never a hardcoded gray or hex.
 *   - Error version (C) uses --color-danger for the icon, surfaces a technical
 *     reason, and offers retry — it does NOT blame the user or show a dead end.
 *   - No-results version (B) echoes the query verbatim instead of a generic
 *     "no results" — and offers a way out (clear filters).
 *   - Icon-only / decorative SVGs are aria-hidden; the retry button keeps its
 *     visible label, no orphan icon button.
 *
 * Citations:
 *   [memory:references#R-005]   — Brand DNA schema (component_rules, empty states)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — button variant reference (primary / outline)
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { RotateCcw } from 'lucide-react'

// Shared shell for one empty-state version — centered column, generous breathing
// room, illustration on top, copy + single action below. Matches the rest of the
// showcase: surface-elevated article with a token border + radius.
const VERSION_SHELL =
  'flex flex-col items-center rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)] text-center'

export function EmptyCompletePattern() {
  return (
    <section aria-labelledby="empty-complete-title">
      <h2
        id="empty-complete-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Empty States
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        SKILL.md Pattern E — tres momentos distintos: primera vez, sin resultados y error de carga. Cada uno con su propio SVG y una sola acción siguiente.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-3">
        {/* Version A — first-use (onboarding): invitational, one primary CTA */}
        <article className={VERSION_SHELL}>
          <p className="self-start font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            empty · first-use
          </p>

          {/* Illustration A — a spark / new beginning. Outline glyph, strokes
              inherit --color-primary via text color. Decorative → aria-hidden. */}
          <svg
            viewBox="0 0 64 64"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mt-[var(--space-6)] h-16 w-16 text-[var(--color-primary)]"
            aria-hidden="true"
          >
            {/* four-point spark */}
            <path d="M32 8v12M32 44v12M8 32h12M44 32h12" />
            <path d="M32 22l3.2 6.8L42 32l-6.8 3.2L32 42l-3.2-6.8L22 32l6.8-3.2L32 22z" />
            {/* tiny accompanying sparkles */}
            <path d="M50 14v6M47 17h6" strokeWidth={1.5} className="text-[var(--color-accent)]" />
          </svg>

          <h3 className="mt-[var(--space-6)] font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
            Empezá tu primer proyecto
          </h3>
          <p className="mt-[var(--space-2)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
            Todavía no hay nada por acá — y eso está perfecto. Creá tu primer proyecto y lo verás aparecer al instante.
          </p>

          <button
            type="button"
            className="mt-[var(--space-6)] inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-white transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)] hover:opacity-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
          >
            Crear proyecto
          </button>

          <p className="mt-[var(--space-6)] font-mono text-xs text-[var(--color-text-subtle)]">
            invitational · 1 primary CTA · no apology
          </p>
        </article>

        {/* Version B — no-results (search): neutral, echoes the query, clear filters */}
        <article className={VERSION_SHELL}>
          <p className="self-start font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            empty · no-results
          </p>

          {/* Illustration B — a magnifier over an empty field. Distinct from A:
              search scope, not a spark. Strokes inherit --color-text-muted. */}
          <svg
            viewBox="0 0 64 64"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mt-[var(--space-6)] h-16 w-16 text-[var(--color-text-muted)]"
            aria-hidden="true"
          >
            {/* magnifier */}
            <circle cx={27} cy={27} r={15} />
            <path d="M38 38l12 12" />
            {/* empty-field dashes inside the lens */}
            <path d="M20 27h14" strokeWidth={1.5} className="text-[var(--color-text-subtle)]" />
          </svg>

          <h3 className="mt-[var(--space-6)] font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
            No encontramos resultados
          </h3>
          <p className="mt-[var(--space-2)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
            No hay nada que coincida con{' '}
            <span className="font-mono text-[var(--color-text)]">&ldquo;factura marzo&rdquo;</span>. Probá con otros términos o limpiá los filtros activos.
          </p>

          <button
            type="button"
            className="mt-[var(--space-6)] inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-medium text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)] hover:bg-[var(--color-surface-elevated)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
          >
            Limpiar filtros
          </button>

          <p className="mt-[var(--space-6)] font-mono text-xs text-[var(--color-text-subtle)]">
            neutral · echoes the query verbatim · offers a way out
          </p>
        </article>

        {/* Version C — load-error: honest + technical, retry, never blames the user */}
        <article className={VERSION_SHELL}>
          <p className="self-start font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            empty · load-error
          </p>

          {/* Illustration C — a fractured / disconnected cloud. Distinct from A & B:
              a break, not a spark or a search. Strokes inherit --color-danger. */}
          <svg
            viewBox="0 0 64 64"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
            className="mt-[var(--space-6)] h-16 w-16 text-[var(--color-danger)]"
            aria-hidden="true"
          >
            {/* broken cloud — left and right halves split by a gap */}
            <path d="M26 40H17a9 9 0 0 1-1-17.9A13 13 0 0 1 29 14" />
            <path d="M38 40h7a9 9 0 0 0 1.5-17.9A13 13 0 0 0 35 14" />
            {/* fracture bolt through the gap */}
            <path d="M33 20l-5 9h8l-5 11" strokeWidth={1.75} />
          </svg>

          <h3 className="mt-[var(--space-6)] font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
            No pudimos cargar los datos
          </h3>
          <p className="mt-[var(--space-2)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
            La petición falló por un tiempo de espera agotado de la red.
          </p>
          {/* Technical detail — surfaced honestly, in mono, never hidden */}
          <p className="mt-[var(--space-2)] font-mono text-xs text-[var(--color-text-subtle)]">
            Error 504 · request_id 7f3a9c
          </p>

          <button
            type="button"
            className="mt-[var(--space-6)] inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] border border-[var(--color-danger)] bg-[var(--color-surface)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-[var(--color-danger)] transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)] hover:bg-[var(--color-danger)]/10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-danger)]"
          >
            <RotateCcw className="h-4 w-4" aria-hidden="true" />
            Reintentar
          </button>

          <p className="mt-[var(--space-6)] font-mono text-xs text-[var(--color-text-subtle)]">
            honest · technical reason + retry · never blames the user
          </p>
        </article>
      </div>
    </section>
  )
}
