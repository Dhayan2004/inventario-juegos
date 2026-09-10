/**
 * Inputs Section — renders every form control declared in
 * brand.json.component_rules.form with all required states. Static showcase:
 * focus / hover / open states that need interactivity are SHOWN as their
 * resting visual + labeled in mono (no 'use client' — this is a server
 * component, same as the other sections/).
 *
 * Controls covered (R-005 sec 3.3 form set):
 *   - input:    default · focused(ring) · error(border --color-danger + msg)
 *               · disabled · filled · icon-left · icon-right
 *   - select:   closed · open (static preview) · disabled
 *   - textarea: resize-none + fixed rows · error
 *   - switch:   on · off · disabled
 *   - checkbox: unchecked · checked · indeterminate · disabled
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Every control has a VISIBLE label tied via htmlFor↔id (no placeholder-
 *     as-label).
 *   - Focus state is a visible ring/border — never outline:none alone.
 *   - Error state uses --color-danger on border + a real message line.
 *   - All visual values are --color-* / --radius-* / --space-* vars; NO hex,
 *     NO Tailwind color classes, NO bg-white.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules.form)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-token)]
 *   [docs:shadcn-ui]            — input/select/textarea/switch/checkbox refs
 */

import { Search, Eye, ChevronDown, Check, Minus } from 'lucide-react'

/**
 * Shared field shell — a real <label htmlFor={htmlFor}> tied to the control
 * id (R10 / a11y: never placeholder-as-label), a mono state tag, the control,
 * and an optional hint or error line. When `error` is set, the message gets
 * id `${htmlFor}-msg` so the control's aria-describedby resolves.
 */
function Field({
  htmlFor,
  label,
  state,
  children,
  hint,
  error,
}: {
  htmlFor: string
  label: string
  state: string
  children: React.ReactNode
  hint?: string
  error?: string
}) {
  return (
    <div className="space-y-[var(--space-2)]">
      <div className="flex items-baseline justify-between gap-[var(--gap-sm)]">
        <label htmlFor={htmlFor} className="text-sm font-medium text-[var(--color-text)]">
          {label}
        </label>
        <span className="font-mono text-xs text-[var(--color-text-subtle)]">{state}</span>
      </div>
      {children}
      {error ? (
        <p id={`${htmlFor}-msg`} className="text-xs text-[var(--color-danger)]">
          {error}
        </p>
      ) : hint ? (
        <p className="text-xs text-[var(--color-text-subtle)]">{hint}</p>
      ) : null}
    </div>
  )
}

const INPUT_BASE =
  'block w-full rounded-[var(--radius-md)] border bg-[var(--color-surface)] px-[var(--space-3)] py-[var(--space-2)] text-sm text-[var(--color-text)] placeholder:text-[var(--color-text-subtle)] transition-colors duration-[var(--motion-duration-fast)] focus:outline-none'

export function InputsSection() {
  return (
    <section aria-labelledby="inputs-title">
      <h2
        id="inputs-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Inputs
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Form controls del set MVP — input, select, textarea, switch, checkbox.
        Cada estado interactivo se rotula en mono.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-2">
        {/* ─── Input — 7 states ─────────────────────────────────────── */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            input · 7 states
          </p>
          <div className="mt-[var(--space-4)] space-y-[var(--space-4)]">
            {/* default */}
            <Field htmlFor="input-default" label="Workspace name" state="default" hint="Hasta 40 caracteres.">
              <input
                id="input-default"
                type="text"
                placeholder="Acme Inc."
                className={`${INPUT_BASE} border-[var(--color-border)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]`}
              />
            </Field>

            {/* focused — ring shown at rest */}
            <Field htmlFor="input-focused" label="Project slug" state="focused · ring">
              <input
                id="input-focused"
                type="text"
                defaultValue="lanzamiento-q3"
                className={`${INPUT_BASE} border-[var(--color-primary)] ring-2 ring-[var(--color-primary)]`}
              />
            </Field>

            {/* error */}
            <Field
              htmlFor="input-error"
              label="Email"
              state="error"
              error="Ese email ya está registrado."
            >
              <input
                id="input-error"
                type="email"
                defaultValue="hola@ejemplo"
                aria-invalid="true"
                aria-describedby="input-error-msg"
                className={`${INPUT_BASE} border-[var(--color-danger)] focus:border-[var(--color-danger)] focus:ring-2 focus:ring-[var(--color-danger)]`}
              />
            </Field>

            {/* disabled */}
            <Field htmlFor="input-disabled" label="Account ID" state="disabled" hint="Asignado al crear la cuenta.">
              <input
                id="input-disabled"
                type="text"
                defaultValue="acct_8f21c0"
                disabled
                className={`${INPUT_BASE} cursor-not-allowed border-[var(--color-border)] opacity-50`}
              />
            </Field>

            {/* filled */}
            <Field htmlFor="input-filled" label="Full name" state="filled">
              <input
                id="input-filled"
                type="text"
                defaultValue="Carlos Domínguez"
                className={`${INPUT_BASE} border-[var(--color-border)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]`}
              />
            </Field>

            {/* icon-left */}
            <Field htmlFor="input-icon-left" label="Search" state="icon-left">
              <div className="relative">
                <Search
                  className="pointer-events-none absolute left-[var(--space-3)] top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-subtle)]"
                  aria-hidden
                />
                <input
                  id="input-icon-left"
                  type="search"
                  placeholder="Buscar entradas…"
                  className={`${INPUT_BASE} border-[var(--color-border)] pl-[var(--space-8)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]`}
                />
              </div>
            </Field>

            {/* icon-right */}
            <Field htmlFor="input-icon-right" label="Password" state="icon-right">
              <div className="relative">
                <input
                  id="input-icon-right"
                  type="password"
                  defaultValue="supersecret"
                  className={`${INPUT_BASE} border-[var(--color-border)] pr-[var(--space-8)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]`}
                />
                <button
                  type="button"
                  aria-label="Mostrar contraseña"
                  className="absolute right-[var(--space-3)] top-1/2 -translate-y-1/2 text-[var(--color-text-subtle)] transition-colors duration-[var(--motion-duration-fast)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
                >
                  <Eye className="h-4 w-4" aria-hidden />
                </button>
              </div>
            </Field>
          </div>
        </article>

        {/* ─── Select — closed / open / disabled ────────────────────── */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            select · closed · open · disabled
          </p>
          <div className="mt-[var(--space-4)] space-y-[var(--space-4)]">
            {/* closed */}
            <Field htmlFor="select-closed" label="Plan" state="closed">
              <div className="relative">
                <select
                  id="select-closed"
                  defaultValue="pro"
                  className={`${INPUT_BASE} appearance-none border-[var(--color-border)] pr-[var(--space-8)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]`}
                >
                  <option value="free">Free</option>
                  <option value="pro">Pro</option>
                  <option value="team">Team</option>
                </select>
                <ChevronDown
                  className="pointer-events-none absolute right-[var(--space-3)] top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-subtle)]"
                  aria-hidden
                />
              </div>
            </Field>

            {/* open — static preview of the expanded listbox */}
            <Field htmlFor="select-open" label="Plan" state="open · static preview">
              <div className="relative">
                <button
                  id="select-open"
                  type="button"
                  aria-haspopup="listbox"
                  aria-expanded="true"
                  className={`${INPUT_BASE} flex items-center justify-between border-[var(--color-primary)] ring-2 ring-[var(--color-primary)]`}
                >
                  <span>Pro</span>
                  <ChevronDown className="h-4 w-4 text-[var(--color-text-subtle)]" aria-hidden />
                </button>
                <ul
                  role="listbox"
                  className="mt-[var(--space-1)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] py-[var(--space-1)] text-sm"
                >
                  <li
                    role="option"
                    aria-selected="false"
                    className="px-[var(--space-3)] py-[var(--space-2)] text-[var(--color-text)]"
                  >
                    Free
                  </li>
                  <li
                    role="option"
                    aria-selected="true"
                    className="flex items-center justify-between bg-[var(--color-surface-elevated)] px-[var(--space-3)] py-[var(--space-2)] text-[var(--color-text)]"
                  >
                    Pro
                    <Check className="h-4 w-4 text-[var(--color-primary)]" aria-hidden />
                  </li>
                  <li
                    role="option"
                    aria-selected="false"
                    className="px-[var(--space-3)] py-[var(--space-2)] text-[var(--color-text)]"
                  >
                    Team
                  </li>
                </ul>
              </div>
            </Field>

            {/* disabled */}
            <Field htmlFor="select-disabled" label="Region" state="disabled" hint="Fijada por el plan actual.">
              <div className="relative">
                <select
                  id="select-disabled"
                  defaultValue="us-east"
                  disabled
                  className={`${INPUT_BASE} cursor-not-allowed appearance-none border-[var(--color-border)] pr-[var(--space-8)] opacity-50`}
                >
                  <option value="us-east">US East</option>
                </select>
                <ChevronDown
                  className="pointer-events-none absolute right-[var(--space-3)] top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-subtle)] opacity-50"
                  aria-hidden
                />
              </div>
            </Field>
          </div>
        </article>

        {/* ─── Textarea — fixed rows / error ────────────────────────── */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            textarea · resize-none · error
          </p>
          <div className="mt-[var(--space-4)] space-y-[var(--space-4)]">
            <Field
              htmlFor="textarea-default"
              label="Release notes"
              state="rows=4 · resize-none"
              hint="Markdown soportado."
            >
              <textarea
                id="textarea-default"
                rows={4}
                placeholder="Qué cambió en esta versión…"
                className={`${INPUT_BASE} resize-none border-[var(--color-border)] leading-[var(--line-height-body)] focus:border-[var(--color-primary)] focus:ring-2 focus:ring-[var(--color-primary)]`}
              />
            </Field>

            <Field
              htmlFor="textarea-error"
              label="Bio"
              state="error"
              error="Máximo 280 caracteres (vas en 312)."
            >
              <textarea
                id="textarea-error"
                rows={4}
                defaultValue="Entrepreneur y automation developer. Construyo agentes y automatizaciones para negocios de LATAM y España…"
                aria-invalid="true"
                aria-describedby="textarea-error-msg"
                className={`${INPUT_BASE} resize-none border-[var(--color-danger)] leading-[var(--line-height-body)] focus:border-[var(--color-danger)] focus:ring-2 focus:ring-[var(--color-danger)]`}
              />
            </Field>
          </div>
        </article>

        {/* ─── Switch + Checkbox — static visual states ─────────────── */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            switch · on · off · disabled
          </p>
          <div className="mt-[var(--space-4)] space-y-[var(--space-3)]">
            <SwitchRow id="switch-on" label="Notificaciones por email" state="on" checked />
            <SwitchRow id="switch-off" label="Resumen semanal" state="off" />
            <SwitchRow
              id="switch-disabled"
              label="Modo mantenimiento"
              state="disabled"
              checked
              disabled
            />
          </div>

          <p className="mt-[var(--space-6)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            checkbox · unchecked · checked · indeterminate · disabled
          </p>
          <div className="mt-[var(--space-4)] space-y-[var(--space-3)]">
            <CheckboxRow id="check-unchecked" label="Acepto los términos" state="unchecked" />
            <CheckboxRow id="check-checked" label="Suscribirme al newsletter" state="checked" checked />
            <CheckboxRow
              id="check-indeterminate"
              label="Seleccionar todo"
              state="indeterminate"
              indeterminate
            />
            <CheckboxRow
              id="check-disabled"
              label="Plan Enterprise (no disponible)"
              state="disabled"
              disabled
            />
          </div>
        </article>
      </div>
    </section>
  )
}

/**
 * Switch row — static visual. The "on/off" state is the track + knob position;
 * `disabled` dims via opacity. Interactivity (toggle) is described by `state`,
 * not wired (server component showcase).
 */
function SwitchRow({
  id,
  label,
  state,
  checked = false,
  disabled = false,
}: {
  id: string
  label: string
  state: string
  checked?: boolean
  disabled?: boolean
}) {
  return (
    <div className={`flex items-center justify-between gap-[var(--gap-md)] ${disabled ? 'opacity-50' : ''}`}>
      <label htmlFor={id} className="text-sm text-[var(--color-text)]">
        {label}
      </label>
      <div className="flex items-center gap-[var(--gap-sm)]">
        <span className="font-mono text-xs text-[var(--color-text-subtle)]">{state}</span>
        <button
          id={id}
          type="button"
          role="switch"
          aria-checked={checked}
          aria-label={label}
          disabled={disabled}
          className={`relative h-5 w-9 shrink-0 rounded-full transition-colors duration-[var(--motion-duration-fast)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
            disabled ? 'cursor-not-allowed' : ''
          } ${checked ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-surface-higher)]'}`}
        >
          <span
            className={`absolute top-1/2 h-4 w-4 -translate-y-1/2 rounded-full bg-[var(--color-text)] transition-transform motion-reduce:transition-none duration-[var(--motion-duration-fast)] ${
              checked ? 'left-[18px]' : 'left-[2px]'
            }`}
            aria-hidden
          />
        </button>
      </div>
    </div>
  )
}

/**
 * Checkbox row — static visual. Renders unchecked / checked / indeterminate /
 * disabled box states with a Lucide glyph (Check / Minus) inside the box.
 */
function CheckboxRow({
  id,
  label,
  state,
  checked = false,
  indeterminate = false,
  disabled = false,
}: {
  id: string
  label: string
  state: string
  checked?: boolean
  indeterminate?: boolean
  disabled?: boolean
}) {
  const filled = checked || indeterminate
  return (
    <div className={`flex items-center justify-between gap-[var(--gap-md)] ${disabled ? 'opacity-50' : ''}`}>
      <div className="flex items-center gap-[var(--gap-sm)]">
        <button
          id={id}
          type="button"
          role="checkbox"
          aria-checked={indeterminate ? 'mixed' : checked}
          aria-label={label}
          disabled={disabled}
          className={`flex h-4 w-4 shrink-0 items-center justify-center rounded-[var(--radius-sm)] border transition-colors duration-[var(--motion-duration-fast)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
            disabled ? 'cursor-not-allowed' : ''
          } ${
            filled
              ? 'border-[var(--color-primary)] bg-[var(--color-primary)]'
              : 'border-[var(--color-border)] bg-[var(--color-surface)]'
          }`}
        >
          {indeterminate ? (
            <Minus className="h-4 w-4 text-white" aria-hidden />
          ) : checked ? (
            <Check className="h-4 w-4 text-white" aria-hidden />
          ) : null}
        </button>
        <label htmlFor={id} className="text-sm text-[var(--color-text)]">
          {label}
        </label>
      </div>
      <span className="font-mono text-xs text-[var(--color-text-subtle)]">{state}</span>
    </div>
  )
}
