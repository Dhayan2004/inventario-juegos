/**
 * Motion Section — visualizes the 4 duration tiers + 6-axis motion personality
 * declared in brand.json.motion. Respects @media (prefers-reduced-motion: reduce)
 * via brand.css override (R-005 motion.rules).
 */

const MOTION_AXES = [
  { name: 'energy', value: 'precise' },
  { name: 'elasticity', value: 'snap_not_bounce' },
  { name: 'directionality', value: 'mechanical' },
  { name: 'sequencing', value: 'subtle_stagger' },
  { name: 'distance', value: 'short' },
  { name: 'restraint', value: 'high' },
]

const DURATIONS = [
  { name: 'instant', cssVar: '--motion-duration-instant', useFor: 'hover/press feedback' },
  { name: 'fast', cssVar: '--motion-duration-fast', useFor: 'small UI transitions' },
  { name: 'base', cssVar: '--motion-duration-base', useFor: 'card / modal entry' },
  { name: 'slow', cssVar: '--motion-duration-slow', useFor: 'page transitions, reveals' },
]

export function MotionSection() {
  return (
    <section aria-labelledby="motion-title">
      <h2
        id="motion-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Motion
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Personalidad en 6 ejes + 4 duraciones. Honra <code className="font-mono">prefers-reduced-motion</code>.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-2">
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            motion.personality
          </p>
          <dl className="mt-[var(--space-3)] space-y-[var(--space-2)] text-sm">
            {MOTION_AXES.map(({ name, value }) => (
              <div key={name} className="flex justify-between font-mono">
                <dt className="text-[var(--color-text-muted)]">{name}</dt>
                <dd className="text-[var(--color-text)]">{value}</dd>
              </div>
            ))}
          </dl>
        </article>

        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            motion.durations_ms
          </p>
          <ul className="mt-[var(--space-3)] space-y-[var(--space-3)]">
            {DURATIONS.map(({ name, cssVar, useFor }, i) => (
              <li key={name} className="space-y-[var(--space-1)]">
                <div className="flex items-baseline justify-between">
                  <span className="font-mono text-sm text-[var(--color-text)]">{name}</span>
                  <span className="font-mono text-xs text-[var(--color-text-subtle)]">
                    var({cssVar})
                  </span>
                </div>
                {/* Static proportional bar — longer = slower tier. NO width
                    animation: width is an UNSAFE layout prop (COMPONENT_RULES
                    Regla 4 / motion.ts UNSAFE list). */}
                <div
                  className="h-1 rounded-full bg-[var(--color-primary)]"
                  style={{ width: `${(i + 1) * 25}%`, minWidth: '4px' }}
                  aria-hidden
                />
                <p className="text-xs text-[var(--color-text-subtle)]">{useFor}</p>
              </li>
            ))}
          </ul>
        </article>
      </div>
    </section>
  )
}
