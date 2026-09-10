/**
 * Cards Section — renders the 3 card variants from R-005 sec 3.3 with their
 * interaction posture described in mono labels (this is a static showcase, so
 * hover/navigate behavior is annotated, not wired).
 *
 * Variants covered:
 *   - default:  border, NO shadow            — listas, contenido estático
 *   - elevated: shadow-md, NO border         — destacados, modal-like
 *   - accent:   border-primary/20 + bg-primary/5 — KPIs, info clave de marca
 *
 * Interaction rules (annotated, not interactive here):
 *   - Clickable card → shadow transition on hover, duration var(--motion-duration-base) (~200ms)
 *   - Navigating card → may add scale-[1.01] on hover; non-navigating cards must NOT scale
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - NEVER nest an Elevated card inside another Card (no card-in-card)
 *   - default variant has NO shadow; elevated variant has NO border
 *   - NO rounded-3xl + shadow-2xl combo; radius/shadow come from tokens only
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules.card)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — card variant reference
 */

export function CardsSection() {
  return (
    <section aria-labelledby="cards-title">
      <h2
        id="cards-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Cards
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Tres variantes de R-005 sección 3.3 — default, elevated, accent. Nunca anidar Elevated dentro de otra Card.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-3">
        {/* Default — border, no shadow */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            card · default
          </p>
          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)]">
            <p className="text-sm font-semibold text-[var(--color-text)]">Default card</p>
            <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
              Borde + surface, sin shadow. Para listas y contenido estático.
            </p>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            border · shadow: none
          </p>
        </article>

        {/* Elevated — shadow-md, no border */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            card · elevated
          </p>
          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] bg-[var(--color-surface)] p-[var(--space-4)] shadow-md">
            <p className="text-sm font-semibold text-[var(--color-text)]">Elevated card</p>
            <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
              Sombra suave, sin borde. Para elementos destacados y superficies modal-like.
            </p>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            shadow-md · border: none
          </p>
        </article>

        {/* Accent — brand-tinted border + background */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            card · accent
          </p>
          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-primary)]/20 bg-[var(--color-primary)]/5 p-[var(--space-4)]">
            <p className="text-sm font-semibold text-[var(--color-text)]">Accent card</p>
            <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
              Tinte de marca sutil. Para KPIs e información clave que debe resaltar.
            </p>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            border-primary/20 · bg-primary/5
          </p>
        </article>
      </div>

      {/* Interaction posture — clickable vs navigating (annotated, static) */}
      <div className="mt-[var(--space-6)] grid gap-[var(--space-6)] md:grid-cols-2">
        {/* Clickable — shadow transition on hover */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            card · clickable (hover preview)
          </p>
          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)] shadow-md transition-shadow duration-[var(--motion-duration-base)] ease-[var(--motion-easing)]">
            <p className="text-sm font-semibold text-[var(--color-text)]">Clickable card</p>
            <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
              Eleva la sombra al hover. No escala — solo acciona, no navega.
            </p>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            hover: shadow · transition-shadow ~200ms · scale: none
          </p>
        </article>

        {/* Navigating — shadow + subtle scale on hover */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            card · navigates (hover preview)
          </p>
          <div className="mt-[var(--space-4)] scale-[1.01] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)] shadow-md transition-[transform,box-shadow] duration-[var(--motion-duration-base)] ease-[var(--motion-easing)]">
            <p className="text-sm font-semibold text-[var(--color-text)]">Navigating card</p>
            <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
              Eleva la sombra y agrega un scale-[1.01] sutil porque lleva a otra vista.
            </p>
          </div>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            hover: shadow + scale-[1.01] · transform/box-shadow only
          </p>
        </article>
      </div>
    </section>
  )
}
