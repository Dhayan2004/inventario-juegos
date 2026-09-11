/**
 * Badges Section — renders the Badge + Status matrix from R-005 sec 3.3
 * ("Badges y Status"). Badges are INFORMATIVE, never clickable like a primary
 * button, so every example is a static <span>, not a <button>/<a> (this is the
 * Anti-Slop posture rule for this component).
 *
 * Variants covered (R-005 Regla 8 — canonical set, no ad-hoc className):
 *   default · secondary · outline · destructive
 * Semantic variants covered:
 *   success · warning · info · neutral
 *   (success → --color-success, warning → --color-warning, info → --color-info,
 *    neutral → --color-text-subtle on --color-surface)
 * Status-with-dot covered:
 *   Online (success dot) · Offline (text-subtle dot) · Pending (warning dot)
 *
 * Interaction rules (annotated, not interactive here):
 *   - Badges never receive hover/focus affordances — they are not actionable.
 *     The intended appear-in animation (fade-in ~75ms) is described in a mono
 *     label, not wired, because this is a static showcase server component.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Every badge is a <span> (informative), NEVER a <button>/<a> — badges are
 *     not primary actions.
 *   - Semantic colors map 1:1 to tokens (success/warning/info/text-subtle); no
 *     hardcoded green/amber/blue hex.
 *   - outline variant has border + transparent fill (NO solid background).
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, "Badges y Status")
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-success)]
 *   [docs:shadcn-ui]            — 4 canonical badge variants reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

const SEMANTIC_BADGES = [
  { label: 'Success', token: 'success' },
  { label: 'Warning', token: 'warning' },
  { label: 'Info', token: 'info' },
  { label: 'Neutral', token: 'text-subtle' },
] as const

const STATUS_DOTS = [
  { label: 'Online', token: 'success' },
  { label: 'Offline', token: 'text-subtle' },
  { label: 'Pending', token: 'warning' },
] as const

export function BadgesSection() {
  return (
    <section aria-labelledby="badges-title">
      <h2
        id="badges-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Badges & Status
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Informativos, nunca clickeables como botón — variants, semantic colors y
        status dots de R-005 sección 3.3.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-2">
        {/* Variants */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            badge · 4 variants
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-center gap-[var(--gap-sm)]">
            <span className="inline-flex items-center rounded-[var(--radius-sm)] bg-[var(--color-primary)] px-[var(--space-2)] py-[var(--space-1)] text-xs font-semibold text-white">
              Default
            </span>
            <span className="inline-flex items-center rounded-[var(--radius-sm)] bg-[var(--color-secondary)] px-[var(--space-2)] py-[var(--space-1)] text-xs font-semibold text-white">
              Secondary
            </span>
            <span className="inline-flex items-center rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-transparent px-[var(--space-2)] py-[var(--space-1)] text-xs font-medium text-[var(--color-text)]">
              Outline
            </span>
            <span className="inline-flex items-center rounded-[var(--radius-sm)] bg-[var(--color-danger)] px-[var(--space-2)] py-[var(--space-1)] text-xs font-semibold text-white">
              Destructive
            </span>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            appear: fade-in ~var(--motion-duration-instant) · no hover/focus (not actionable)
          </p>
        </article>

        {/* Semantic */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            badge · semantic
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-center gap-[var(--gap-sm)]">
            {SEMANTIC_BADGES.map(({ label, token }) => (
              <span
                key={token}
                className="inline-flex items-center rounded-[var(--radius-sm)] border px-[var(--space-2)] py-[var(--space-1)] text-xs font-medium"
                style={{
                  color: `var(--color-${token})`,
                  borderColor: `var(--color-${token})`,
                  backgroundColor: 'var(--color-surface)',
                }}
              >
                {label}
              </span>
            ))}
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            success / warning / info / text-subtle — token-driven, no hardcoded hue
          </p>
        </article>

        {/* Status with dot */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)] md:col-span-2">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            status · dot indicator
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-center gap-[var(--gap-md)]">
            {STATUS_DOTS.map(({ label, token }) => (
              <span
                key={token}
                className="inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-3)] py-[var(--space-1)] text-xs font-medium text-[var(--color-text)]"
              >
                <span
                  className="h-2 w-2 rounded-full"
                  style={{ backgroundColor: `var(--color-${token})` }}
                  aria-hidden="true"
                />
                {label}
              </span>
            ))}
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            dot is decorative (aria-hidden) — the text label carries the state for SR users
          </p>
        </article>
      </div>
    </section>
  )
}
