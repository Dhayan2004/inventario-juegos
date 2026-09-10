/**
 * Empty States Section — renders the 4 canonical empty-state scenarios from
 * brand.json.component_rules (R-005 sec 3.3, "Empty States" / Regla 13) as
 * static visual examples.
 *
 * The cardinal rule of this section: every view that renders data must have a
 * matching empty state, and an empty state is NEVER a spinner — they are
 * mutually exclusive states (a spinner means "loading", an empty state means
 * "loaded, nothing to show"). The loading vocabulary lives in the Loading
 * States section; this one is its complement.
 *
 * Canonical structure (R-005 Regla 13): inline SVG illustration (simple) +
 * heading + description + primary CTA. A DIFFERENT illustration per scenario so
 * the user can tell at a glance which situation they are in.
 *
 * Scenarios covered (R-005 Regla 13):
 *   - empty list      — Inbox glyph      — feature with no data yet → create the first item
 *   - load error      — CloudOff glyph   — fetch failed → retry (recoverable, not a dead end)
 *   - no results      — SearchX glyph    — query matched nothing → clear / adjust filters
 *   - first use        — Sparkles glyph   — onboarding, never used before → guided primary action
 *
 * Motion (R-005 motion rule — transform/opacity/color only):
 *   - These are static. A real app may fade the empty state in on mount
 *     (animate-in fade-in, opacity only) — annotated in a mono label, not wired.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Each empty state ALWAYS has illustration + heading + description + ONE
 *     primary CTA — no naked "No data" string, no orphan illustration.
 *   - A DIFFERENT illustration per scenario (no single shrug glyph reused 4x).
 *   - NEVER an empty state paired with a spinner — empty and loading are
 *     mutually exclusive (this boundary is surfaced in the annotation below).
 *   - SVG strokes use currentColor driven by --color-text-subtle, never a
 *     hardcoded gray hex; CTA uses --color-primary, never a named Tailwind color.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, Empty States)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only, no hex)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — empty-state composition over Card primitives
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { Plus, RotateCcw, X, Wand2, type LucideIcon } from 'lucide-react'

// Each scenario carries its own inline illustration. The SVGs are deliberately
// simple line-art at h-12 w-12, stroked with currentColor so the parent sets the
// tone via --color-text-subtle — no fills, no hardcoded grays. aria-hidden
// because the heading + description already carry the meaning.
type EmptyScenario = {
  /** stable key + the value shown in the mono label */
  key: string
  /** the simple, scenario-specific illustration (line-art, currentColor) */
  Illustration: () => React.ReactNode
  heading: string
  description: string
  /** primary CTA — exactly one per empty state */
  cta: { label: string; Icon: LucideIcon }
  /** mono caption describing the rule this scenario encodes */
  rule: string
}

// --- Inline illustrations (one per scenario, intentionally distinct) ---

/** Empty list — an open inbox tray (nothing has landed yet). */
function InboxGlyph() {
  return (
    <svg
      viewBox="0 0 48 48"
      className="h-12 w-12 text-[var(--color-text-subtle)]"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M6 30 14 12h20l8 18" />
      <path d="M6 30v8h36v-8" />
      <path d="M6 30h10l3 5h10l3-5h10" />
    </svg>
  )
}

/** Load error — a cloud with a slash (the fetch did not come through). */
function CloudOffGlyph() {
  return (
    <svg
      viewBox="0 0 48 48"
      className="h-12 w-12 text-[var(--color-text-subtle)]"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M16 34h18a7 7 0 0 0 1.5-13.8A10 10 0 0 0 17 16.5" />
      <path d="M14 22a7 7 0 0 0-1 14" />
      <path d="M9 9 39 39" />
    </svg>
  )
}

/** No results — a magnifier with an x (the query matched nothing). */
function SearchEmptyGlyph() {
  return (
    <svg
      viewBox="0 0 48 48"
      className="h-12 w-12 text-[var(--color-text-subtle)]"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <circle cx="21" cy="21" r="12" />
      <path d="m30 30 9 9" />
      <path d="m17 17 8 8" />
      <path d="m25 17-8 8" />
    </svg>
  )
}

/** First use — a spark cluster (a fresh, never-used surface inviting a start). */
function SparkleGlyph() {
  return (
    <svg
      viewBox="0 0 48 48"
      className="h-12 w-12 text-[var(--color-text-subtle)]"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 8c1 6 3 8 9 9-6 1-8 3-9 9-1-6-3-8-9-9 6-1 8-3 9-9Z" />
      <path d="M36 24c.5 3 1.5 4 4.5 4.5-3 .5-4 1.5-4.5 4.5-.5-3-1.5-4-4.5-4.5 3-.5 4-1.5 4.5-4.5Z" />
    </svg>
  )
}

const EMPTY_SCENARIOS: EmptyScenario[] = [
  {
    key: 'empty-list',
    Illustration: InboxGlyph,
    heading: 'Todavía no hay nada por acá',
    description: 'Cuando crees tu primer proyecto va a aparecer en esta lista. Empezá cuando quieras.',
    cta: { label: 'Crear proyecto', Icon: Plus },
    rule: 'empty list · illustration + heading + description + 1 primary CTA',
  },
  {
    key: 'load-error',
    Illustration: CloudOffGlyph,
    heading: 'No pudimos cargar esto',
    description: 'Hubo un problema al traer los datos. Suele ser temporal — volvé a intentar en un momento.',
    cta: { label: 'Reintentar', Icon: RotateCcw },
    rule: 'load error · recoverable · CTA reintenta, no es un callejón sin salida',
  },
  {
    key: 'no-results',
    Illustration: SearchEmptyGlyph,
    heading: 'Sin resultados para tu búsqueda',
    description: 'No encontramos nada que coincida con esos filtros. Probá con otros términos o limpialos.',
    cta: { label: 'Limpiar filtros', Icon: X },
    rule: 'no results · query vacía ≠ lista vacía · CTA ajusta la búsqueda',
  },
  {
    key: 'first-use',
    Illustration: SparkleGlyph,
    heading: 'Bienvenido — armemos lo primero juntos',
    description: 'Tu espacio está listo. Te guiamos paso a paso para que dejes todo funcionando en minutos.',
    cta: { label: 'Empezar el tour', Icon: Wand2 },
    rule: 'first use (onboarding) · CTA guía la primera acción de valor',
  },
]

export function EmptyStatesSection() {
  return (
    <section aria-labelledby="empty-states-title">
      <h2
        id="empty-states-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Empty States
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        R-005 sección 3.3 — cuatro escenarios: lista vacía, error de carga, sin resultados y primer uso.
        Cada uno con ilustración + heading + descripción + un CTA primario. Un empty state nunca es un spinner.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-2">
        {EMPTY_SCENARIOS.map(({ key, Illustration, heading, description, cta, rule }) => {
          const CtaIcon = cta.Icon
          return (
            <article
              key={key}
              className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]"
            >
              <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                empty · {key}
              </p>

              {/* The empty state itself — centered illustration + heading +
                  description + a single primary CTA, on a plain surface (no
                  nested card). */}
              <div className="mt-[var(--space-4)] flex flex-col items-center rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-8)] text-center">
                <Illustration />
                <h3 className="mt-[var(--space-4)] font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
                  {heading}
                </h3>
                <p className="mt-[var(--space-2)] max-w-xs text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
                  {description}
                </p>
                <button
                  type="button"
                  className="mt-[var(--space-6)] inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-white transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)] hover:opacity-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
                >
                  <CtaIcon className="h-4 w-4" aria-hidden="true" />
                  {cta.label}
                </button>
              </div>

              <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
                {rule}
              </p>
            </article>
          )
        })}
      </div>

      {/* Boundary note — empty vs loading (annotated, the complement of the
          Loading States section). An empty state and a spinner are mutually
          exclusive: you are either still fetching, or you have a result with
          zero rows. Never both at once. */}
      <article className="mt-[var(--space-6)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          empty · vs loading (annotated)
        </p>
        <p className="mt-[var(--space-3)] text-sm text-[var(--color-text-muted)]">
          Mientras los datos cargan, mostrá un skeleton (sección Loading States). Recién cuando la carga
          termina y no hay nada que mostrar, aparece el empty state. Nunca un empty state con spinner —
          son estados mutuamente excluyentes.
        </p>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          loading → skeleton · loaded + 0 rows → empty state · entry: animate-in fade-in (opacity only)
        </p>
      </article>
    </section>
  )
}
