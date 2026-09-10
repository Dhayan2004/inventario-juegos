/**
 * Toast Section — renders the 4 toast types from R-005 sec 3.3 ("Toast y
 * Feedback", Regla 12) as static visual examples. Each toast pairs a semantic
 * color token with a Lucide icon, a title, a short body and an OPTIONAL action.
 *
 * Sonner / shadcn Toast is NOT assumed installed in the showcase target, so this
 * section renders the correct STATIC pattern (the exact card a toast paints when
 * it lands) plus a mono note of what to install to wire it up. Same approach the
 * Alerts section takes for its entry animation — appearance behavior is
 * annotated, not interactive, because this is a server-rendered showcase.
 *
 * Types covered:
 *   - success: --color-success — CircleCheck   — async op completed
 *   - error:   --color-danger  — CircleX        — async op failed
 *   - warning: --color-warning — TriangleAlert  — async op needs attention
 *   - info:    --color-info    — Info           — neutral async status
 *
 * Toasts vs Alerts vs inline errors (R-005 Regla 12):
 *   - Toast = an ASYNC action finished (saved, exported, sync done). Transient,
 *     bottom of the viewport, auto-dismisses.
 *   - A field validation error is NOT a toast — it goes under the input (see the
 *     Inputs section). This note is surfaced in the description below.
 *
 * Entry / exit motion (annotated, not wired — static showcase):
 *   - Enter: animate-in motion-reduce:animate-none slide-in-from-bottom fade-in duration-[var(--motion-duration-base)] (~200ms)
 *   - Exit:  animate-out motion-reduce:animate-none slide-out-to-right fade-out duration-[var(--motion-duration-fast)] (~150ms)
 *   - Only opacity + transform animate — never width/height/margin (R-005 motion rule)
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Each toast ALWAYS has a title + an icon in its semantic color; the optional
 *     action is a real button, never a bare colored text link.
 *   - Semantic color comes from --color-success/danger/warning/info only — never
 *     a hardcoded hex, named Tailwind color, or purple/indigo gradient.
 *   - Toast is NOT used for inline field errors; the rule is stated in copy.
 *   - The icon-only dismiss button carries an aria-label (X with no text).
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, Toast y Feedback)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only, no hex)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-success)]/10
 *   [docs:shadcn-ui]            — sonner / toast reference (npx shadcn add sonner)
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { CircleCheck, CircleX, Info, TriangleAlert, X, type LucideIcon } from 'lucide-react'

// Literal, full class strings per type so the Tailwind JIT scanner emits every
// arbitrary-value class. NEVER interpolate the token into the class
// (e.g. `text-[var(--color-${token})]`): the scanner reads source text literally,
// would emit `var(--color-${token})`, and Lightning CSS (Turbopack, Next 16
// default) rejects the `$` — crashing the whole page. It also hides
// danger/warning/info from the scanner. Pick the literal class by token instead.
type ToastType = {
  type: string
  /** semantic color token name shown in the mono label (maps to --color-<token>) */
  token: 'success' | 'danger' | 'warning' | 'info'
  Icon: LucideIcon
  /** colored border for the toast card (literal class so the Tailwind scanner emits it) */
  borderClass: string
  /** icon + title color, full semantic token (literal class) */
  accentClass: string
  title: string
  body: string
  /** optional action label — when present, renders a real button, not a link */
  action?: string
  /** success/info are passive status; error/warning are assertive */
  role: 'status' | 'alert'
}

const TOAST_TYPES: ToastType[] = [
  {
    type: 'success',
    token: 'success',
    Icon: CircleCheck,
    borderClass: 'border-[var(--color-success)]/30',
    accentClass: 'text-[var(--color-success)]',
    title: 'Exportación lista',
    body: 'Tu reporte de marzo se generó. Lo enviamos a tu correo.',
    action: 'Descargar',
    role: 'status',
  },
  {
    type: 'error',
    token: 'danger',
    Icon: CircleX,
    borderClass: 'border-[var(--color-danger)]/30',
    accentClass: 'text-[var(--color-danger)]',
    title: 'No se pudo sincronizar',
    body: 'La conexión se cortó a mitad de camino. Tus cambios siguen guardados.',
    action: 'Reintentar',
    role: 'alert',
  },
  {
    type: 'warning',
    token: 'warning',
    Icon: TriangleAlert,
    borderClass: 'border-[var(--color-warning)]/30',
    accentClass: 'text-[var(--color-warning)]',
    title: 'Subida parcial',
    body: '2 de 5 archivos superaban el límite y se omitieron.',
    action: 'Ver detalle',
    role: 'alert',
  },
  {
    type: 'info',
    token: 'info',
    Icon: Info,
    borderClass: 'border-[var(--color-info)]/30',
    accentClass: 'text-[var(--color-info)]',
    title: 'Nueva versión disponible',
    body: 'Recargá la página para usar las últimas mejoras.',
    // no action — a plain status toast that just auto-dismisses
    role: 'status',
  },
]

export function ToastSection() {
  return (
    <section aria-labelledby="toast-title">
      <h2
        id="toast-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Toast y Feedback
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        R-005 sección 3.3 — success, error, warning, info con acción opcional. Los toasts son para
        acciones asíncronas completadas; para el error de un campo usá texto bajo el input, nunca un
        toast.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-2">
        {TOAST_TYPES.map(({ type, token, Icon, title, body, action, role, borderClass, accentClass }) => (
          <article
            key={type}
            className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]"
          >
            <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
              toast · {type}
              {action ? ' · with action' : ''}
            </p>

            {/* The toast itself — elevated surface + tinted accent border + icon
                in the semantic color, with title, body and the optional action.
                This is the exact card Sonner paints once installed. */}
            <div
              role={role}
              className={`mt-[var(--space-4)] flex items-start gap-[var(--gap-sm)] rounded-[var(--radius-md)] border bg-[var(--color-surface)] p-[var(--space-4)] shadow-sm ${borderClass}`}
            >
              <Icon
                className={`mt-[var(--space-1)] h-5 w-5 shrink-0 ${accentClass}`}
                aria-hidden
              />
              <div className="min-w-0 flex-1">
                <p className={`text-sm font-semibold ${accentClass}`}>{title}</p>
                <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">{body}</p>
                {action ? (
                  <button
                    type="button"
                    className="mt-[var(--space-3)] rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] px-[var(--space-3)] py-[var(--space-1)] text-xs font-semibold text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
                  >
                    {action}
                  </button>
                ) : null}
              </div>
              {/* Icon-only dismiss — needs an aria-label since there's no text. */}
              <button
                type="button"
                aria-label="Cerrar notificación"
                className="-mr-[var(--space-1)] -mt-[var(--space-1)] shrink-0 rounded-[var(--radius-sm)] p-[var(--space-1)] text-[var(--color-text-subtle)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                <X className="h-4 w-4" aria-hidden />
              </button>
            </div>

            <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
              --color-{token} · icon + title + body{action ? ' + action' : ''} + dismiss
            </p>
          </article>
        ))}
      </div>

      {/* Install note — Sonner/Toast is not assumed present in the target. The
          static cards above are the visual contract; this is how you wire them. */}
      <article className="mt-[var(--space-6)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          toast · install (if not present)
        </p>
        <p className="mt-[var(--space-3)] text-sm text-[var(--color-text-muted)]">
          Si Sonner o el Toast de shadcn no están instalados, estas tarjetas muestran el patrón
          correcto. Para hacerlas interactivas, agregá Sonner y montá su provider en el layout raíz.
        </p>
        <pre className="mt-[var(--space-3)] overflow-x-auto rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-3)] font-mono text-xs text-[var(--color-text)]">
          npx shadcn@latest add sonner
        </pre>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          luego: &lt;Toaster /&gt; en app/layout.tsx · toast.success(title, {'{ description, action }'})
        </p>
      </article>

      {/* Enter / exit motion — annotated, not wired (static server showcase). The
          real toast slides up + fades in on mount, and slides out to the right on
          dismiss. Only opacity + transform animate — never width/height/margin. */}
      <article className="mt-[var(--space-6)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          toast · enter + exit motion (annotated)
        </p>
        <p className="mt-[var(--space-3)] text-sm text-[var(--color-text-muted)]">
          Al aparecer, el toast sube desde abajo con un fade-in (~200ms). Al cerrarse, sale hacia la
          derecha con un fade-out más corto (~150ms). Solo se animan opacity y transform.
        </p>
        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          enter: slide-in-from-bottom fade-in · duration-[var(--motion-duration-base)] (~200ms)
        </p>
        <p className="mt-[var(--space-1)] font-mono text-xs text-[var(--color-text-subtle)]">
          exit: slide-out-to-right fade-out · duration-[var(--motion-duration-fast)] (~150ms)
        </p>
      </article>
    </section>
  )
}
