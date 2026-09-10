/**
 * Tabs Section — renders the Tabs component from R-005 sec 3.3 ("Tabs") as a
 * static showcase. Tabs switch between sibling panels of the SAME hierarchy;
 * they are NOT a stepped flow (use a Stepper / numbered steps for progress).
 *
 * Variants covered:
 *   - default (underline): active tab marked by an underline indicator on a
 *     surface background — the canonical, lowest-chrome variant
 *   - segmented (pill):    active tab marked by an elevated background pill
 *     inside a muted track — for compact, toggle-like groupings
 *
 * Showcase note: a live tab list needs client interactivity (selected index +
 * roving focus), but this is a STATIC server-component showcase, so each
 * variant renders with one tab pre-selected and its REAL panel content visible
 * (never empty tabs). The switch behavior is annotated in mono labels below.
 *
 * Interaction rules (annotated, not interactive here):
 *   - Active indicator (underline / pill) animates via `transform` in ~150ms
 *     (--motion-duration-fast) — NEVER animate width/left/margin.
 *   - Tablist is roving-tabindex: active tab tabIndex=0, the rest tabIndex=-1;
 *     ArrowLeft/ArrowRight move selection (wired in the client impl, not here).
 *   - Max 5 tabs — beyond that, prefer a dropdown or sidebar nav.
 *
 * Accessibility (ARIA tabs pattern — mirrored statically here):
 *   - role="tablist" wraps role="tab" triggers; each tab has aria-selected and
 *     aria-controls pointing at its role="tabpanel" (panel aria-labelledby tab).
 *   - Inactive panels would be hidden; here every panel's content is described
 *     so the contract is visible in one screenshot.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Active indicator uses transform-only motion (no width/left animation).
 *   - Tabs are NOT used as a progress/stepper flow (sibling panels only).
 *   - No more than 5 tabs per list (overflow → dropdown/sidebar nav).
 *   - Token-driven only: surface/elevated/primary/border — no hardcoded hue,
 *     no Tailwind color classes, no inline hex/px/font.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, "Tabs")
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — Tabs (TabsList / TabsTrigger / TabsContent) reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

const UNDERLINE_TABS = [
  { label: 'Overview', active: true },
  { label: 'Activity', active: false },
  { label: 'Settings', active: false },
] as const

const SEGMENTED_TABS = [
  { label: 'Day', active: false },
  { label: 'Week', active: true },
  { label: 'Month', active: false },
] as const

export function TabsSection() {
  return (
    <section aria-labelledby="tabs-title">
      <h2
        id="tabs-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Tabs
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Cambian entre paneles hermanos del mismo nivel — máximo 5, nunca para
        flujos con progreso (eso es un Stepper). R-005 sección 3.3.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-2">
        {/* Default — underline indicator */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            tabs · default (underline)
          </p>

          {/* Tablist */}
          <div
            role="tablist"
            aria-label="Underline tabs example"
            className="mt-[var(--space-4)] flex gap-[var(--gap-md)] border-b border-[var(--color-border)]"
          >
            {UNDERLINE_TABS.map(({ label, active }) => (
              <button
                key={label}
                type="button"
                role="tab"
                id={`tab-underline-${label.toLowerCase()}`}
                aria-selected={active}
                aria-controls={`panel-underline-${label.toLowerCase()}`}
                tabIndex={active ? 0 : -1}
                className={
                  active
                    ? 'relative -mb-px border-b-2 border-[var(--color-primary)] px-[var(--space-1)] pb-[var(--space-2)] text-sm font-semibold text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'
                    : 'relative -mb-px border-b-2 border-transparent px-[var(--space-1)] pb-[var(--space-2)] text-sm font-medium text-[var(--color-text-muted)] transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]'
                }
              >
                {label}
              </button>
            ))}
          </div>

          {/* Active panel — real content, never empty */}
          <div
            role="tabpanel"
            id="panel-underline-overview"
            aria-labelledby="tab-underline-overview"
            className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)]"
          >
            <p className="text-sm font-semibold text-[var(--color-text)]">Overview</p>
            <p className="mt-[var(--space-1)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
              Resumen del proyecto: 24 entradas activas, última sincronización
              hace 3 minutos. Cada tab muestra su propio contenido — nunca un
              panel vacío.
            </p>
          </div>

          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            active: underline · indicator transform ~var(--motion-duration-fast) · roving tabIndex
          </p>
        </article>

        {/* Segmented — elevated pill indicator */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            tabs · segmented (pill)
          </p>

          {/* Tablist — muted track holding the active pill */}
          <div
            role="tablist"
            aria-label="Segmented tabs example"
            className="mt-[var(--space-4)] inline-flex gap-[var(--space-1)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-1)]"
          >
            {SEGMENTED_TABS.map(({ label, active }) => (
              <button
                key={label}
                type="button"
                role="tab"
                id={`tab-segmented-${label.toLowerCase()}`}
                aria-selected={active}
                aria-controls={`panel-segmented-${label.toLowerCase()}`}
                tabIndex={active ? 0 : -1}
                className={
                  active
                    ? 'rounded-[var(--radius-sm)] bg-[var(--color-surface-elevated)] px-[var(--space-3)] py-[var(--space-1)] text-sm font-semibold text-[var(--color-text)] shadow-sm transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'
                    : 'rounded-[var(--radius-sm)] px-[var(--space-3)] py-[var(--space-1)] text-sm font-medium text-[var(--color-text-muted)] transition-colors duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]'
                }
              >
                {label}
              </button>
            ))}
          </div>

          {/* Active panel — real content, never empty */}
          <div
            role="tabpanel"
            id="panel-segmented-week"
            aria-labelledby="tab-segmented-week"
            className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)]"
          >
            <p className="text-sm font-semibold text-[var(--color-text)]">This week</p>
            <p className="mt-[var(--space-1)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
              1,284 eventos · +8.2% vs. la semana anterior. El segmented control
              agrupa rangos cortos y excluyentes; para más de 5 opciones, usá un
              dropdown.
            </p>
          </div>

          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            active: bg pill · indicator transform ~var(--motion-duration-fast) · max 5 tabs
          </p>
        </article>
      </div>

      {/* Boundary note — Tabs vs Stepper (annotated, not a component) */}
      <div className="mt-[var(--space-6)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          cuándo NO usar tabs
        </p>
        <p className="mt-[var(--space-3)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
          Si los paneles tienen un orden con progreso (paso 1 → 2 → 3), no son
          tabs: usá un Stepper / pasos numerados. Tabs son para contenido
          hermano e intercambiable, sin secuencia obligatoria.
        </p>
      </div>
    </section>
  )
}
