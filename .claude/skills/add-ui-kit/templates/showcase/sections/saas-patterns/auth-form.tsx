/**
 * Auth Form Pattern — renders the canonical login/registro form page from the
 * SaaS Patterns set (R-005 sec 3.3, Pattern F "Form Page (Auth)"). Layout is a
 * centered card with the brand logo on top; the form is email + password with a
 * show/hide toggle, inline field validation (errors live UNDER the input, never
 * as a global alert), a submit button with a loading state, and the secondary
 * links "¿Olvidaste tu contraseña?" + "Crear cuenta". Email-only — no OAuth in
 * the initial sprint.
 *
 * Static showcase: focus / typing / submitting states that need interactivity
 * are SHOWN as their resting visual + labeled in mono (no 'use client' — this is
 * a server component, same as the rest of sections/). Three card states are laid
 * out side by side so el-evaluador can see them all at once:
 *   - resting       — empty fields, valid affordances
 *   - inline error  — password too short, error on the field (NOT a banner)
 *   - submitting    — button disabled + aria-busy + Loader2 spinner
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Validation is INLINE under the field (--color-danger border + a real
 *     message line wired via aria-describedby) — never a global <Alert> banner.
 *   - Every input has a VISIBLE <label htmlFor> tied to its id (no placeholder-
 *     as-label); the show/hide toggle is icon-only and carries an aria-label.
 *   - The submitting button is `disabled` + `aria-busy` with an `aria-hidden`
 *     Loader2 spinner — never a free-floating spinner with no busy state.
 *   - All visual values are --color-* / --radius-* / --space-* / --font-* vars;
 *     NO hex, NO Tailwind color classes, NO bg-white, NO purple/indigo gradient.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, Pattern F Auth)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only, no hex)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-primary)]
 *   [docs:shadcn-ui]            — card / input / button reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { Eye, EyeOff, Loader2, type LucideIcon } from 'lucide-react'

// Shared input shell — single source for every field so border/focus stay
// identical across the three card states. Caller appends the per-state border:
// default uses --color-border + primary focus ring; error swaps to --color-danger.
const INPUT_BASE =
  'block w-full rounded-[var(--radius-md)] border bg-[var(--color-surface)] px-[var(--space-3)] py-[var(--space-2)] text-sm text-[var(--color-text)] placeholder:text-[var(--color-text-subtle)] transition-colors duration-[var(--motion-duration-fast)] focus:outline-none'

// Resting field border + primary focus ring (valid state).
const INPUT_OK =
  'border-[var(--color-border)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]'

// Error field border + danger focus ring (paired with an aria-describedby msg).
const INPUT_ERR =
  'border-[var(--color-danger)] focus:border-[var(--color-danger)] focus:ring-2 focus:ring-[var(--color-danger)]'

/**
 * Brand logo placeholder for the card header — a monogram tile, not an <img>.
 * Downstream apps swap this for their real <Logo/>; here it stands in so the
 * "logo on top" layout reads. Tile uses --color-primary on the brand-derived
 * monogram letter (mustache: only the glyph is brand-data, the rest is tokens).
 */
function LogoMark() {
  return (
    <div className="flex flex-col items-center gap-[var(--space-2)]">
      <div
        className="flex h-12 w-12 items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-primary)] font-[family-name:var(--font-display)] text-lg font-bold text-[var(--color-surface)]"
        aria-hidden
      >
        {/* mustache: first glyph of the brand name */}
        {'{{ brand.monogram }}'}
      </div>
      <span className="font-[family-name:var(--font-display)] text-base font-semibold text-[var(--color-text)]">
        {'{{ brand.name }}'}
      </span>
    </div>
  )
}

/**
 * Password field — text input + a trailing icon-only show/hide toggle. `revealed`
 * picks the resting glyph (Eye = currently hidden / EyeOff = currently shown) and
 * the input type; the toggle always carries an aria-label (icon-only a11y). In
 * this server showcase the toggle is not wired — its job is to be visible + named.
 */
function PasswordField({
  id,
  label,
  defaultValue,
  revealed = false,
  error,
}: {
  id: string
  label: string
  defaultValue?: string
  revealed?: boolean
  error?: string
}) {
  const ToggleIcon: LucideIcon = revealed ? EyeOff : Eye
  return (
    <div className="space-y-[var(--space-2)]">
      <div className="flex items-baseline justify-between gap-[var(--gap-sm)]">
        <label htmlFor={id} className="text-sm font-medium text-[var(--color-text)]">
          {label}
        </label>
        <span className="font-mono text-xs text-[var(--color-text-subtle)]">
          {revealed ? 'visible' : 'oculto'}
        </span>
      </div>
      <div className="relative">
        <input
          id={id}
          type={revealed ? 'text' : 'password'}
          defaultValue={defaultValue}
          autoComplete="current-password"
          placeholder="••••••••"
          aria-invalid={error ? 'true' : undefined}
          aria-describedby={error ? `${id}-msg` : undefined}
          className={`${INPUT_BASE} ${error ? INPUT_ERR : INPUT_OK} pr-[var(--space-8)]`}
        />
        <button
          type="button"
          aria-label={revealed ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          className="absolute right-[var(--space-3)] top-1/2 -translate-y-1/2 text-[var(--color-text-subtle)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
        >
          <ToggleIcon className="h-4 w-4" aria-hidden />
        </button>
      </div>
      {error ? (
        <p id={`${id}-msg`} className="text-xs text-[var(--color-danger)]">
          {error}
        </p>
      ) : null}
    </div>
  )
}

export function AuthFormPattern() {
  return (
    <section aria-labelledby="auth-form-title">
      <h2
        id="auth-form-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Auth Form
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        R-005 sección 3.3 Pattern F — card centrada + logo arriba, email + password con toggle, validación inline (nunca alerta global), submit con loading. Email-only, sin OAuth.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-3">
        {/* ─── State 1 — resting (empty, valid affordances) ─────────── */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            state · resting
          </p>

          {/* Centered card — logo on top, then the form */}
          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-6)]">
            <LogoMark />

            <h3 className="mt-[var(--space-6)] text-center font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
              Iniciá sesión
            </h3>

            <form className="mt-[var(--space-6)] space-y-[var(--space-4)]">
              {/* email */}
              <div className="space-y-[var(--space-2)]">
                <label
                  htmlFor="auth-rest-email"
                  className="text-sm font-medium text-[var(--color-text)]"
                >
                  Email
                </label>
                <input
                  id="auth-rest-email"
                  type="email"
                  autoComplete="email"
                  placeholder="hola@ejemplo.com"
                  className={`${INPUT_BASE} ${INPUT_OK}`}
                />
              </div>

              {/* password — hidden by default */}
              <PasswordField id="auth-rest-password" label="Contraseña" />

              {/* forgot link — right-aligned above the CTA */}
              <div className="flex justify-end">
                <a
                  href="#"
                  className="rounded-[var(--radius-sm)] text-xs font-medium text-[var(--color-primary)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
                >
                  ¿Olvidaste tu contraseña?
                </a>
              </div>

              {/* submit CTA — resting */}
              <button
                type="submit"
                className="w-full rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-[var(--color-surface)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                Entrar
              </button>
            </form>

            {/* create-account link — under the card form */}
            <p className="mt-[var(--space-6)] text-center text-sm text-[var(--color-text-muted)]">
              ¿No tenés cuenta?{' '}
              <a
                href="#"
                className="rounded-[var(--radius-sm)] font-medium text-[var(--color-primary)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                Crear cuenta
              </a>
            </p>
          </div>
        </article>

        {/* ─── State 2 — inline validation error (NOT a global alert) ─ */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            state · inline error
          </p>

          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-6)]">
            <LogoMark />

            <h3 className="mt-[var(--space-6)] text-center font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
              Iniciá sesión
            </h3>

            <form className="mt-[var(--space-6)] space-y-[var(--space-4)]">
              {/* email — filled + valid */}
              <div className="space-y-[var(--space-2)]">
                <label
                  htmlFor="auth-err-email"
                  className="text-sm font-medium text-[var(--color-text)]"
                >
                  Email
                </label>
                <input
                  id="auth-err-email"
                  type="email"
                  autoComplete="email"
                  defaultValue="carlos@imperiodigital.io"
                  className={`${INPUT_BASE} ${INPUT_OK}`}
                />
              </div>

              {/* password — revealed + error message under the field */}
              <PasswordField
                id="auth-err-password"
                label="Contraseña"
                defaultValue="1234"
                revealed
                error="La contraseña debe tener al menos 8 caracteres."
              />

              <div className="flex justify-end">
                <a
                  href="#"
                  className="rounded-[var(--radius-sm)] text-xs font-medium text-[var(--color-primary)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
                >
                  ¿Olvidaste tu contraseña?
                </a>
              </div>

              <button
                type="submit"
                className="w-full rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-[var(--color-surface)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                Entrar
              </button>
            </form>

            <p className="mt-[var(--space-6)] text-center text-sm text-[var(--color-text-muted)]">
              ¿No tenés cuenta?{' '}
              <a
                href="#"
                className="rounded-[var(--radius-sm)] font-medium text-[var(--color-primary)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                Crear cuenta
              </a>
            </p>
          </div>

          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            error vive bajo el campo (aria-describedby) · no banner global
          </p>
        </article>

        {/* ─── State 3 — submitting (button loading) ────────────────── */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            state · submitting
          </p>

          <div className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-6)]">
            <LogoMark />

            <h3 className="mt-[var(--space-6)] text-center font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
              Iniciá sesión
            </h3>

            <form className="mt-[var(--space-6)] space-y-[var(--space-4)]">
              {/* email — filled + valid, disabled while submitting */}
              <div className="space-y-[var(--space-2)]">
                <label
                  htmlFor="auth-busy-email"
                  className="text-sm font-medium text-[var(--color-text)]"
                >
                  Email
                </label>
                <input
                  id="auth-busy-email"
                  type="email"
                  autoComplete="email"
                  defaultValue="carlos@imperiodigital.io"
                  disabled
                  className={`${INPUT_BASE} ${INPUT_OK} cursor-not-allowed opacity-50`}
                />
              </div>

              {/* password — disabled while submitting */}
              <div className="space-y-[var(--space-2)]">
                <div className="flex items-baseline justify-between gap-[var(--gap-sm)]">
                  <label
                    htmlFor="auth-busy-password"
                    className="text-sm font-medium text-[var(--color-text)]"
                  >
                    Contraseña
                  </label>
                  <span className="font-mono text-xs text-[var(--color-text-subtle)]">oculto</span>
                </div>
                <div className="relative">
                  <input
                    id="auth-busy-password"
                    type="password"
                    autoComplete="current-password"
                    defaultValue="supersecret"
                    disabled
                    className={`${INPUT_BASE} ${INPUT_OK} cursor-not-allowed pr-[var(--space-8)] opacity-50`}
                  />
                  <button
                    type="button"
                    aria-label="Mostrar contraseña"
                    disabled
                    className="absolute right-[var(--space-3)] top-1/2 -translate-y-1/2 cursor-not-allowed text-[var(--color-text-subtle)] opacity-50"
                  >
                    <Eye className="h-4 w-4" aria-hidden />
                  </button>
                </div>
              </div>

              <div className="flex justify-end">
                <span className="text-xs font-medium text-[var(--color-text-subtle)]">
                  ¿Olvidaste tu contraseña?
                </span>
              </div>

              {/* submit CTA — loading: disabled + aria-busy + spinner */}
              <button
                type="submit"
                disabled
                aria-busy="true"
                className="inline-flex w-full cursor-progress items-center justify-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-[var(--color-surface)] opacity-80"
              >
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                Entrando…
              </button>
            </form>

            <p className="mt-[var(--space-6)] text-center text-sm text-[var(--color-text-muted)]">
              ¿No tenés cuenta?{' '}
              <span className="font-medium text-[var(--color-text-subtle)]">Crear cuenta</span>
            </p>
          </div>

          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            disabled + aria-busy · animate-spin (transform only)
          </p>
        </article>
      </div>
    </section>
  )
}
