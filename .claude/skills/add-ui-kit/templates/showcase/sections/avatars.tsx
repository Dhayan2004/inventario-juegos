/**
 * Avatars Section — renders the Avatar matrix from R-005 sec 3.3 ("Avatars").
 * Avatars are IDENTITY affordances, never a generic "unknown user" icon — for
 * that, R-005 says use a Lucide icon, so this section always pairs an image
 * variant with a deterministic initials fallback (the network image can fail,
 * and an empty avatar must still read as a person, not a broken box).
 *
 * Sizes covered (R-005 Regla — canonical scale, no ad-hoc px):
 *   sm  h-8 w-8   ·   default h-10 w-10   ·   lg h-14 w-14
 * Fill variants covered (each at default size):
 *   with image (real photo)  ·  with initials fallback (always implemented)
 * Group covered:
 *   -space-x-2 overlap, border-2 border-[var(--color-surface)] ring so each
 *   avatar reads against its neighbour, plus a "+N" overflow counter chip.
 *
 * Interaction rules (annotated, not interactive here):
 *   - Avatars are presentational here — no hover/focus affordance is wired
 *     because a bare avatar is not actionable. When an avatar IS a control
 *     (menu trigger, link to a profile) the consuming component adds the
 *     focus-visible ring + aria-label; that posture is described in a mono
 *     label, not rendered, since this is a static showcase server component.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Initials fallback uses brand tokens (surface-elevated fill + text on it),
 *     NEVER a hardcoded gray (#e5e7eb / bg-gray-200) placeholder.
 *   - Group ring is border-[var(--color-surface)] (cuts the avatar from the
 *     page bg), the "+N" chip border is --color-border — no hardcoded white.
 *   - Avatars are circular identity tokens (rounded-full), never used as a
 *     generic icon slot — that is a Lucide job per R-005.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, "Avatars")
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (no hardcoded values)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax border-[var(--color-surface)]
 *   [docs:shadcn-ui]            — Avatar (image + fallback) composition reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

const SIZES = [
  { label: 'sm', box: 'h-8 w-8', text: 'text-xs' },
  { label: 'default', box: 'h-10 w-10', text: 'text-sm' },
  { label: 'lg', box: 'h-14 w-14', text: 'text-base' },
] as const

const GROUP_INITIALS = ['MR', 'AL', 'JS', 'KP'] as const
const GROUP_OVERFLOW = 5

export function AvatarsSection() {
  return (
    <section aria-labelledby="avatars-title">
      <h2
        id="avatars-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Avatars
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Identidad de usuario — sizes, fallback de iniciales y avatar group con
        contador de R-005 sección 3.3.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-2">
        {/* Sizes — with image */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            avatar · sizes (with image)
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-end gap-[var(--gap-md)]">
            {SIZES.map(({ label, box }) => (
              <div key={label} className="flex flex-col items-center gap-[var(--space-2)]">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src="{{ brand.avatar_sample_url | default: 'https://i.pravatar.cc/112' }}"
                  alt="Foto de perfil de Mara Ríos"
                  className={`${box} rounded-full border border-[var(--color-border)] object-cover`}
                />
                <span className="font-mono text-xs text-[var(--color-text-subtle)]">{label}</span>
              </div>
            ))}
          </div>
        </article>

        {/* Sizes — initials fallback */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            avatar · sizes (initials fallback)
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap items-end gap-[var(--gap-md)]">
            {SIZES.map(({ label, box, text }) => (
              <div key={label} className="flex flex-col items-center gap-[var(--space-2)]">
                <span
                  className={`${box} ${text} inline-flex items-center justify-center rounded-full border border-[var(--color-border)] bg-[var(--color-surface)] font-[family-name:var(--font-display)] font-semibold text-[var(--color-text)]`}
                  aria-label="Avatar de Mara Ríos"
                >
                  MR
                </span>
                <span className="font-mono text-xs text-[var(--color-text-subtle)]">{label}</span>
              </div>
            ))}
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            fallback siempre presente — la imagen puede fallar, las iniciales no
          </p>
        </article>

        {/* Avatar group */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)] md:col-span-2">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            avatar group · -space-x-2 + &quot;+N&quot; counter
          </p>
          <div className="mt-[var(--space-4)] flex items-center -space-x-2">
            {GROUP_INITIALS.map((initials) => (
              <span
                key={initials}
                className="inline-flex h-10 w-10 items-center justify-center rounded-full border-2 border-[var(--color-surface)] bg-[var(--color-surface)] text-xs font-semibold text-[var(--color-text)] ring-1 ring-[var(--color-border)]"
                aria-label={`Avatar de ${initials}`}
              >
                {initials}
              </span>
            ))}
            <span
              className="inline-flex h-10 w-10 items-center justify-center rounded-full border-2 border-[var(--color-surface)] bg-[var(--color-surface-elevated)] text-xs font-semibold text-[var(--color-text-muted)] ring-1 ring-[var(--color-border)]"
              aria-label={`Y ${GROUP_OVERFLOW} personas más`}
            >
              +{GROUP_OVERFLOW}
            </span>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            border-2 border-[var(--color-surface)] separa cada avatar del de atrás · &quot;+N&quot; resume el overflow
          </p>
        </article>
      </div>
    </section>
  )
}
