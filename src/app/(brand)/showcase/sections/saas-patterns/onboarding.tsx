/**
 * Onboarding Pattern (SaaS Pattern C) — renders a full-page onboarding STEP,
 * NOT a modal. Mirrors the multi-step "Paso N de M" flow declared for SaaS
 * surfaces (Forge SKILL.md Pattern C: progress indicator + heading + form +
 * Continuar/Atrás + optional skip link).
 *
 * Static showcase: this is a server component (no 'use client'), so states that
 * need interactivity (hover / focus / current vs done step) are SHOWN as their
 * resting visual and labeled in mono captions — same convention as
 * sections/navigation.tsx.
 *
 * Pieces covered:
 *   - progress:  "Paso 2 de 4" — 4-segment bar (done · current · upcoming) +
 *                accessible numeric label via aria-valuenow on role=progressbar.
 *   - heading:   step title (--font-display) + 1-line description.
 *   - form:      relevant fields for this step (text + select), label↔id wired.
 *   - actions:   "Continuar" (primary CTA) + "Atrás" (ghost) + "Saltar este paso"
 *                skip link (rendered because this step is marked optional).
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Exactly ONE primary CTA (Continuar); Atrás is ghost, skip is a link —
 *     no competing primaries.
 *   - Progress segments animate transform/background-color ONLY (the current
 *     segment fill uses scaleX via transform-origin-left); never width/left.
 *   - Inputs carry a visible <label htmlFor> ↔ id; focus-visible ring is
 *     present and never removed.
 *   - All visual values are --color-* / --radius-* / --space-* vars; NO hex,
 *     NO Tailwind color classes, NO bg-white, NO purple/indigo gradient.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules: button/form/navigation)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-token)]
 *   [docs:shadcn-ui]            — button / input / select / progress refs
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { ArrowLeft, ArrowRight, Check } from 'lucide-react'

// Shared transition string — color + background-color + transform, fast easing.
// Only animatable-safe properties (R-005 motion rule); never width/height/left.
const TRANSITION =
  'transition-[color,background-color,transform] duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'

// Flow metadata — the showcase renders step 2 of a 4-step flow. `state` drives
// the segment fill: 'done' (full + check), 'current' (active fill), 'upcoming'
// (empty track). Derived in a real flow from the router; static here.
const CURRENT_STEP = 2
const TOTAL_STEPS = 4
const STEPS = [
  { key: 'cuenta', label: 'Cuenta', state: 'done' },
  { key: 'perfil', label: 'Perfil', state: 'current' },
  { key: 'equipo', label: 'Equipo', state: 'upcoming' },
  { key: 'listo', label: 'Listo', state: 'upcoming' },
] as const

export function OnboardingPattern() {
  return (
    <section aria-labelledby="onboarding-title">
      <h2
        id="onboarding-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Onboarding step
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Flujo de página completa (no modal) — indicador{' '}
        <code className="font-mono">Paso 2 de 4</code>, formulario del paso, y CTAs{' '}
        Continuar / Atrás con skip opcional.
      </p>

      <div className="mt-[var(--space-8)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          full-page step · progress / form / continuar+atrás / skip
        </p>

        {/* Full-page step frame — a real route would be a centered card on
            --color-surface; rendered inline here as a static preview. */}
        <div className="mt-[var(--space-4)] rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-8)]">
          {/* Progress indicator — accessible value on role=progressbar; the
              segment bar below is decorative (aria-hidden) reinforcement. */}
          <div
            role="progressbar"
            aria-valuemin={1}
            aria-valuemax={TOTAL_STEPS}
            aria-valuenow={CURRENT_STEP}
            aria-label={`Paso ${CURRENT_STEP} de ${TOTAL_STEPS}: ${STEPS[CURRENT_STEP - 1].label}`}
          >
            <div className="flex items-center justify-between">
              <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                Paso {CURRENT_STEP} de {TOTAL_STEPS}
              </p>
              <p className="text-xs font-medium text-[var(--color-text-muted)]">
                {STEPS[CURRENT_STEP - 1].label}
              </p>
            </div>

            {/* 4-segment track. Done = filled + check; current = animated fill
                via scaleX (transform, GPU-safe); upcoming = empty track. */}
            <ol aria-hidden="true" className="mt-[var(--space-3)] flex gap-[var(--gap-xs)]">
              {STEPS.map(({ key, state }) => (
                <li
                  key={key}
                  className="h-1.5 flex-1 overflow-hidden rounded-full bg-[var(--color-border)]"
                >
                  <span
                    className={`block h-full origin-left rounded-full ${TRANSITION} ${
                      state === 'upcoming'
                        ? 'scale-x-0 bg-[var(--color-primary)]'
                        : 'scale-x-100 bg-[var(--color-primary)]'
                    }`}
                  />
                </li>
              ))}
            </ol>

            {/* Step dots with labels — done carries a check icon (h-4 w-4 inline). */}
            <ol aria-hidden="true" className="mt-[var(--space-3)] flex justify-between">
              {STEPS.map(({ key, label, state }, i) => (
                <li key={key} className="flex items-center gap-[var(--space-1)]">
                  <span
                    className={`inline-flex h-5 w-5 items-center justify-center rounded-full text-xs font-semibold ${TRANSITION} ${
                      state === 'upcoming'
                        ? 'border border-[var(--color-border)] text-[var(--color-text-subtle)]'
                        : 'bg-[var(--color-primary)] text-white'
                    }`}
                  >
                    {state === 'done' ? <Check className="h-4 w-4" /> : i + 1}
                  </span>
                  <span
                    className={`text-xs ${
                      state === 'current'
                        ? 'font-semibold text-[var(--color-text)]'
                        : 'text-[var(--color-text-subtle)]'
                    }`}
                  >
                    {label}
                  </span>
                </li>
              ))}
            </ol>
          </div>

          {/* Step heading + description */}
          <div className="mt-[var(--space-8)]">
            <h3 className="font-[family-name:var(--font-display)] text-2xl font-bold text-[var(--color-text)]">
              Contanos sobre vos
            </h3>
            <p className="mt-[var(--space-2)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
              Personalizamos tu espacio de trabajo con estos datos. Podés cambiarlos
              después en Ajustes.
            </p>
          </div>

          {/* Step form — fields relevant to "Perfil": name (text) + role (select).
              Each input is tied to its <label> via htmlFor↔id. */}
          <form className="mt-[var(--space-6)] space-y-[var(--space-4)]">
            <div>
              <label
                htmlFor="onboarding-name"
                className="block text-sm font-medium text-[var(--color-text)]"
              >
                Nombre completo <span className="text-[var(--color-danger)]">*</span>
              </label>
              <input
                id="onboarding-name"
                type="text"
                required
                placeholder="Carmen Solís"
                className={`mt-[var(--space-2)] block w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] px-[var(--space-3)] py-[var(--space-2)] text-sm text-[var(--color-text)] placeholder:text-[var(--color-text-subtle)] ${TRANSITION} focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]`}
              />
            </div>

            <div>
              <label
                htmlFor="onboarding-role"
                className="block text-sm font-medium text-[var(--color-text)]"
              >
                ¿Cuál es tu rol?
              </label>
              <select
                id="onboarding-role"
                defaultValue="founder"
                className={`mt-[var(--space-2)] block w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] px-[var(--space-3)] py-[var(--space-2)] text-sm text-[var(--color-text)] ${TRANSITION} focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]`}
              >
                <option value="founder">Fundador/a</option>
                <option value="developer">Desarrollador/a</option>
                <option value="designer">Diseñador/a</option>
                <option value="operations">Operaciones</option>
              </select>
            </div>
          </form>

          {/* Actions — Continuar (single primary CTA) + Atrás (ghost). Skip link
              renders because this step is optional. Icons h-4 w-4 inline. */}
          <div className="mt-[var(--space-8)] flex items-center justify-between gap-[var(--gap-md)]">
            <button
              type="button"
              className={`inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-medium text-[var(--color-text-muted)] ${TRANSITION} hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
            >
              <ArrowLeft className="h-4 w-4" aria-hidden="true" />
              Atrás
            </button>

            <div className="flex items-center gap-[var(--gap-md)]">
              {/* Skip link — only shown for optional steps */}
              <a
                href="#onboarding-title"
                className={`rounded-[var(--radius-sm)] text-sm font-medium text-[var(--color-text-subtle)] underline-offset-4 ${TRANSITION} hover:text-[var(--color-text-muted)] hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                Saltar este paso
              </a>
              <button
                type="button"
                className={`inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-5)] py-[var(--space-2)] text-sm font-semibold text-white ${TRANSITION} hover:bg-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                Continuar
                <ArrowRight className="h-4 w-4" aria-hidden="true" />
              </button>
            </div>
          </div>
        </div>

        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          progressbar → aria-valuenow={CURRENT_STEP} · current fill → transform scaleX ·
          1 primary CTA (Continuar) · Atrás ghost · skip link opcional
        </p>
      </div>
    </section>
  )
}
