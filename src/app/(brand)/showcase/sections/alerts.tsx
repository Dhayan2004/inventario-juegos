/**
 * Alerts Section — renders the 4 alert types from R-005 sec 3.3 as static
 * visual examples. Each type pairs a semantic color token with a Lucide icon,
 * an AlertTitle and an AlertDescription. The entry animation (fade + slide) is
 * described in a mono label, not wired here (this is a server-rendered
 * showcase — appearance behavior is annotated, like the Cards section).
 *
 * Types covered:
 *   - info:        --color-info     — Info       — neutral guidance, defaults
 *   - success:     --color-success  — CircleCheck — confirmation of an action
 *   - warning:     --color-warning  — TriangleAlert — needs attention, recoverable
 *   - destructive: --color-danger   — CircleX    — error / blocking failure
 *
 * Entry motion (annotated, not interactive here):
 *   - animate-in motion-reduce:animate-none fade-in slide-in-from-top-1 duration-[var(--motion-duration-base)] (~200ms)
 *   - Only opacity + transform animate — never width/height/margin (R-005 motion rule)
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Each alert ALWAYS has a title + a description + a type-appropriate icon
 *   - Semantic color comes from --color-info/success/warning/danger only —
 *     never a hardcoded hex, named Tailwind color, or purple/indigo gradient
 *   - Alert is NOT used for inline field errors (that belongs under the input,
 *     see Inputs section); this note is surfaced in the description below
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, alert)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only, no hex)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-info)]/10
 *   [docs:shadcn-ui]            — alert + AlertTitle + AlertDescription reference
 */

import { CircleCheck, CircleX, Info, TriangleAlert, type LucideIcon } from 'lucide-react'

// Literal, full class strings per type so the Tailwind JIT scanner emits every
// arbitrary-value class (interpolating the token into the class would hide
// success/warning/danger from the scanner). Same pattern as the Buttons section.
type AlertType = {
  type: string
  /** semantic color token name shown in the mono label (maps to --color-<token>) */
  token: 'info' | 'success' | 'warning' | 'danger'
  Icon: LucideIcon
  /** tinted surface + matching border for the alert container */
  surfaceClass: string
  /** icon + title color, full semantic token */
  accentClass: string
  title: string
  description: string
  /** info/success are passive status; warning/destructive are assertive */
  role: 'status' | 'alert'
}

const ALERT_TYPES: AlertType[] = [
  {
    type: 'info',
    token: 'info',
    Icon: Info,
    surfaceClass: 'border-[var(--color-info)]/30 bg-[var(--color-info)]/10',
    accentClass: 'text-[var(--color-info)]',
    title: 'Sincronización en curso',
    description: 'Estamos importando tus contactos. Podés seguir trabajando mientras tanto.',
    role: 'status',
  },
  {
    type: 'success',
    token: 'success',
    Icon: CircleCheck,
    surfaceClass: 'border-[var(--color-success)]/30 bg-[var(--color-success)]/10',
    accentClass: 'text-[var(--color-success)]',
    title: 'Cambios guardados',
    description: 'Tu perfil se actualizó correctamente y ya es visible para tu equipo.',
    role: 'status',
  },
  {
    type: 'warning',
    token: 'warning',
    Icon: TriangleAlert,
    surfaceClass: 'border-[var(--color-warning)]/30 bg-[var(--color-warning)]/10',
    accentClass: 'text-[var(--color-warning)]',
    title: 'Tu plan vence pronto',
    description: 'Quedan 3 días de prueba. Agregá un método de pago para no perder acceso.',
    role: 'alert',
  },
  {
    type: 'destructive',
    token: 'danger',
    Icon: CircleX,
    surfaceClass: 'border-[var(--color-danger)]/30 bg-[var(--color-danger)]/10',
    accentClass: 'text-[var(--color-danger)]',
    title: 'No se pudo procesar el pago',
    description: 'Tu tarjeta fue rechazada. Revisá los datos o probá con otro método.',
    role: 'alert',
  },
]

export function AlertsSection() {
  return (
    <section aria-labelledby="alerts-title">
      <h2
        id="alerts-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Alerts
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Cuatro tipos de R-005 sección 3.3 — info, success, warning, destructive. Para feedback de un
        campo usá texto bajo el input, nunca un Alert.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-2">
        {ALERT_TYPES.map(({ type, token, Icon, surfaceClass, accentClass, title, description, role }) => (
          <article
            key={type}
            className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]"
          >
            <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
              alert · {type}
            </p>

            {/* The alert itself — tinted surface + matching border, icon in the
                semantic color, title + description as required by R-005. */}
            <div
              role={role}
              className={`mt-[var(--space-4)] flex gap-[var(--gap-sm)] rounded-[var(--radius-md)] border p-[var(--space-4)] ${surfaceClass}`}
            >
              <Icon className={`mt-[var(--space-1)] h-5 w-5 shrink-0 ${accentClass}`} aria-hidden />
              <div className="min-w-0">
                <p className={`text-sm font-semibold ${accentClass}`}>{title}</p>
                <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
                  {description}
                </p>
              </div>
            </div>

            <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
              --color-{token} · title + description + icon
            </p>
          </article>
        ))}
      </div>

      {/* Entry motion — annotated, not wired (static server showcase). The real
          component fades + slides in via animate-in motion-reduce:animate-none on mount. */}
      <article className="mt-[var(--space-6)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          alert · entry motion (annotated)
        </p>
        <p className="mt-[var(--space-3)] text-sm text-[var(--color-text-muted)]">
          Al aparecer, el Alert hace un fade-in con un desplazamiento sutil desde arriba. Solo se
          animan opacity y transform — nunca alto, ancho ni márgenes.
        </p>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          animate-in motion-reduce:animate-none fade-in slide-in-from-top-1 · duration-[var(--motion-duration-base)] (~200ms)
        </p>
      </article>
    </section>
  )
}
