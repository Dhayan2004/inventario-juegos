/**
 * SaaS Pattern G — Responsive Navbar.
 *
 * A composed navigation chrome (not a single component): the three navigation
 * shells a SaaS product ships with. Source spec: Forge SKILL.md "Pattern G —
 * Navbar Responsive" (desktop bar + mobile hamburger→Sheet + bottom tab bar).
 *
 * Static showcase: this is a server component (no 'use client'), so the states
 * that need interactivity — hamburger→X toggle, Sheet open/close, hover/active
 * link, current tab — are SHOWN as their resting visual and labeled in mono
 * captions, same convention as sections/navigation.tsx and kpi-row.tsx. The
 * mobile Sheet is rendered inline as an always-open static panel so its full
 * anatomy (links · separator · user footer · X close) is visible at once.
 *
 * Variants covered (all rendered as static visual examples):
 *   - desktop (≥768px):  logo left · nav links · avatar + CTA right. Active link
 *                        gets a primary underline + dot; rest hover to a surface
 *                        tint. Bar is sticky on --color-surface/80 + backdrop-blur.
 *   - mobile (<768px):   logo left · hamburger right → Sheet from the right with
 *                        vertical links (generous padding), a separator, the user
 *                        avatar + name + email pinned at the bottom, and an X close
 *                        in the top-right corner.
 *   - bottom tab bar:    fixed bottom, 4–5 items = icon (h-5 w-5) + text-xs label.
 *                        Active item is --color-primary; iOS safe-area padding via
 *                        env(safe-area-inset-bottom). 5th slot is "Más" (overflow).
 *
 * Motion (R-005 motion rule — transform/opacity/color/background-color/border only):
 *   - Link/tab/button states transition color + background-color + border-color
 *     over --motion-duration-fast; the active underline scales via transform.
 *   - Documented (not wired here): hamburger→X = transform rotate 200ms; Sheet
 *     entrance = slide-in-from-right (translateX) 350ms. Both transform-only.
 *   - NO width/height/top/left animation anywhere.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Exactly ONE primary CTA in the desktop bar (the others are ghost/secondary);
 *     no competing primaries.
 *   - Sticky bar uses a token-tinted translucent surface (--color-surface/80) +
 *     backdrop-blur — NOT an opaque bg-white, NOT a gradient.
 *   - Active link/tab signalled by --color-primary (underline+dot / text+dot),
 *     never a decorative purple/indigo accent.
 *   - Bottom tab bar holds at most 5 items; the 5th is an overflow ("Más").
 *   - Icon-only controls (hamburger, X close, notifications) carry aria-label.
 *   - All fills come from tokens (--color-* / --color-primary/10 …), no hex,
 *     no Tailwind palette classes, no bg-white, no purple/indigo gradient.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules: navigation)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-surface)]/80
 *   [docs:shadcn-ui]            — navigation-menu / sheet / avatar reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { Bell, ChevronDown, Home, LayoutDashboard, Menu, MoreHorizontal, Settings, Users, X } from 'lucide-react'

// Shared transition string — color + background-color + border-color + transform,
// fast easing. Only animatable-safe properties (R-005 motion rule); never
// width/height/top/left.
const TRANSITION =
  'transition-[color,background-color,border-color,transform] duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'

// Desktop nav links. `current` drives the active treatment (underline + dot);
// derived from the router in a real app, static here.
const NAV_LINKS = [
  { label: 'Inicio', current: false },
  { label: 'Panel', current: true },
  { label: 'Equipo', current: false },
  { label: 'Ajustes', current: false },
] as const

// Mobile Sheet links — same destinations, vertical layout with icons.
const SHEET_LINKS = [
  { label: 'Inicio', icon: Home, current: false },
  { label: 'Panel', icon: LayoutDashboard, current: true },
  { label: 'Equipo', icon: Users, current: false },
  { label: 'Ajustes', icon: Settings, current: false },
] as const

// Bottom tab bar — 5 slots max; the 5th is the overflow ("Más"). `current`
// marks the active tab (text + icon in --color-primary).
const TABS = [
  { label: 'Inicio', icon: Home, current: false, overflow: false },
  { label: 'Panel', icon: LayoutDashboard, current: true, overflow: false },
  { label: 'Equipo', icon: Users, current: false, overflow: false },
  { label: 'Ajustes', icon: Settings, current: false, overflow: false },
  { label: 'Más', icon: MoreHorizontal, current: false, overflow: true },
] as const

// Brand-derived initials for the avatar placeholder — not a CSS var, so it is a
// mustache placeholder filled by add-ui-kit from the brand contract.
const AVATAR_INITIALS = '{{ brand.initials | default: "CS" }}'

function Avatar({ size = 'md' }: { size?: 'sm' | 'md' }) {
  const dim = size === 'sm' ? 'h-8 w-8 text-xs' : 'h-9 w-9 text-sm'
  return (
    <span
      aria-hidden="true"
      className={`inline-flex shrink-0 items-center justify-center rounded-full bg-[var(--color-primary)]/10 font-semibold text-[var(--color-primary)] ${dim}`}
    >
      {AVATAR_INITIALS}
    </span>
  )
}

export function NavbarPattern() {
  return (
    <section aria-labelledby="navbar-title">
      <h2
        id="navbar-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Responsive Navbar
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Patrón SaaS — barra desktop (logo · links · avatar+CTA), Sheet móvil con
        hamburguesa, y bottom tab bar fijo con safe-area iOS.
      </p>

      {/* ─── Desktop bar ────────────────────────────────────────────── */}
      <div className="mt-[var(--space-8)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          variant · desktop (≥768px) · sticky surface/80 + backdrop-blur
        </p>

        {/* The bar is sticky on --color-surface/80 + backdrop-blur; rendered
            inside a bordered frame here so the translucency reads in the
            showcase. */}
        <div className="mt-[var(--space-4)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]">
          <nav
            aria-label="Navegación principal (desktop)"
            className="flex items-center justify-between gap-[var(--gap-md)] border-b border-[var(--color-border)] bg-[var(--color-surface)]/80 px-[var(--space-6)] py-[var(--space-4)] backdrop-blur"
          >
            {/* Logo left */}
            <a
              href="#navbar-title"
              className={`flex items-center gap-[var(--space-2)] rounded-[var(--radius-sm)] ${TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
            >
              <span
                aria-hidden="true"
                className="inline-flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-primary)] text-sm font-bold text-white"
              >
                {AVATAR_INITIALS}
              </span>
              <span className="font-[family-name:var(--font-display)] text-base font-bold text-[var(--color-text)]">
                {{ brand.product }}
              </span>
            </a>

            {/* Nav links (center/left of the right cluster) */}
            <ul className="hidden items-center gap-[var(--space-1)] md:flex">
              {NAV_LINKS.map(({ label, current }) => (
                <li key={label}>
                  <a
                    href="#navbar-title"
                    aria-current={current ? 'page' : undefined}
                    className={`relative inline-flex items-center rounded-[var(--radius-sm)] px-[var(--space-3)] py-[var(--space-2)] text-sm ${TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                      current
                        ? 'font-semibold text-[var(--color-text)]'
                        : 'font-medium text-[var(--color-text-muted)] hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)]'
                    }`}
                  >
                    {label}
                    {/* Active link → primary underline (scaleX) + dot. */}
                    {current ? (
                      <>
                        <span
                          aria-hidden="true"
                          className="absolute inset-x-[var(--space-3)] -bottom-px h-0.5 origin-left scale-x-100 rounded-full bg-[var(--color-primary)]"
                        />
                        <span
                          aria-hidden="true"
                          className="ml-[var(--space-2)] inline-block h-1.5 w-1.5 rounded-full bg-[var(--color-primary)]"
                        />
                      </>
                    ) : null}
                  </a>
                </li>
              ))}
            </ul>

            {/* Right cluster: notifications · avatar · primary CTA */}
            <div className="flex items-center gap-[var(--space-3)]">
              <button
                type="button"
                aria-label="Notificaciones"
                className={`relative inline-flex h-9 w-9 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-muted)] ${TRANSITION} hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                <Bell className="h-5 w-5" aria-hidden="true" />
                <span
                  aria-hidden="true"
                  className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-[var(--color-danger)]"
                />
              </button>
              <Avatar size="sm" />
              <button
                type="button"
                className={`hidden rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-white sm:inline-flex ${TRANSITION} hover:bg-[var(--color-primary-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                Nuevo proyecto
              </button>
            </div>
          </nav>

          {/* A sliver of page content so the sticky/backdrop relationship reads. */}
          <div className="px-[var(--space-6)] py-[var(--space-8)]">
            <div className="h-3 w-2/3 rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/15" />
            <div className="mt-[var(--space-3)] h-3 w-1/2 rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/15" />
          </div>
        </div>

        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          active link → primary underline (transform scaleX) + dot · hover → surface tint over fast · sticky → surface/80 + backdrop-blur · 1 primary CTA
        </p>
      </div>

      {/* ─── Mobile: top bar + Sheet ────────────────────────────────── */}
      <div className="mt-[var(--space-8)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          variant · mobile (&lt;768px) · hamburger → Sheet from right
        </p>

        <div className="mt-[var(--space-4)] grid gap-[var(--gap-md)] md:grid-cols-2">
          {/* Mobile top bar — logo left, hamburger right. */}
          <div className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)]">
            <nav
              aria-label="Navegación principal (móvil)"
              className="flex items-center justify-between gap-[var(--gap-sm)] border-b border-[var(--color-border)] bg-[var(--color-surface)]/80 px-[var(--space-4)] py-[var(--space-3)] backdrop-blur"
            >
              <a
                href="#navbar-title"
                className={`flex items-center gap-[var(--space-2)] rounded-[var(--radius-sm)] ${TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                <span
                  aria-hidden="true"
                  className="inline-flex h-7 w-7 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-primary)] text-sm font-bold text-white"
                >
                  {AVATAR_INITIALS}
                </span>
                <span className="font-[family-name:var(--font-display)] text-base font-bold text-[var(--color-text)]">
                  {{ brand.product }}
                </span>
              </a>
              {/* Hamburger — toggles to X on open (transform rotate 200ms). */}
              <button
                type="button"
                aria-label="Abrir menú"
                aria-expanded="false"
                className={`inline-flex h-9 w-9 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text)] ${TRANSITION} hover:bg-[var(--color-surface-elevated)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                <Menu className="h-5 w-5" aria-hidden="true" />
              </button>
            </nav>
            <div className="px-[var(--space-4)] py-[var(--space-6)]">
              <div className="h-3 w-3/4 rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/15" />
              <div className="mt-[var(--space-3)] h-3 w-1/2 rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/15" />
            </div>
          </div>

          {/* Sheet from right — rendered inline as a static, always-open panel so
              its full anatomy is visible. In a real app this is a Radix/shadcn
              Sheet that slides in (translateX) over 350ms. */}
          <div
            role="dialog"
            aria-label="Menú de navegación"
            className="flex max-w-[18rem] flex-col rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-5)] md:ml-auto md:w-[18rem]"
          >
            {/* Sheet header — title + X close (top-right). */}
            <div className="flex items-center justify-between">
              <p className="font-[family-name:var(--font-display)] text-base font-bold text-[var(--color-text)]">
                Menú
              </p>
              <button
                type="button"
                aria-label="Cerrar menú"
                className={`inline-flex h-8 w-8 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-muted)] ${TRANSITION} hover:bg-[var(--color-surface)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                <X className="h-5 w-5" aria-hidden="true" />
              </button>
            </div>

            {/* Vertical links with generous padding; active gets primary tint. */}
            <ul className="mt-[var(--space-4)] flex flex-1 flex-col gap-[var(--space-1)]">
              {SHEET_LINKS.map(({ label, icon: Icon, current }) => (
                <li key={label}>
                  <a
                    href="#navbar-title"
                    aria-current={current ? 'page' : undefined}
                    className={`flex items-center gap-[var(--space-3)] rounded-[var(--radius-md)] px-[var(--space-4)] py-[var(--space-3)] text-sm ${TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                      current
                        ? 'bg-[var(--color-primary)]/10 font-semibold text-[var(--color-primary)]'
                        : 'font-medium text-[var(--color-text-muted)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text)]'
                    }`}
                  >
                    <Icon className="h-5 w-5" aria-hidden="true" />
                    {label}
                  </a>
                </li>
              ))}
            </ul>

            {/* Separator before the user footer. */}
            <hr className="my-[var(--space-4)] border-0 border-t border-[var(--color-border)]" />

            {/* User footer pinned at the bottom — avatar + name + email. */}
            <div className="flex items-center gap-[var(--space-3)]">
              <Avatar />
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-[var(--color-text)]">
                  {{ brand.contact_name | default: "Carmen Solís" }}
                </p>
                <p className="truncate text-xs text-[var(--color-text-subtle)]">
                  {{ brand.contact_email | default: "carmen@ejemplo.com" }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          hamburger → X: transform rotate 200ms · Sheet entrance: slide-in-from-right (translateX) 350ms · links · separator · user footer (avatar + name + email) · X close top-right
        </p>
      </div>

      {/* ─── Bottom tab bar ─────────────────────────────────────────── */}
      <div className="mt-[var(--space-8)]">
        <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          variant · bottom tab bar · fixed bottom · iOS safe-area
        </p>

        {/* Phone-frame preview. The real bar is `fixed bottom-0`; rendered inside
            a rounded frame here so it sits in the showcase flow. */}
        <div className="mt-[var(--space-4)] mx-auto max-w-sm overflow-hidden rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-surface)]">
          <div className="px-[var(--space-4)] py-[var(--space-8)]">
            <div className="h-3 w-2/3 rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/15" />
            <div className="mt-[var(--space-3)] h-3 w-1/2 rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/15" />
          </div>

          {/* The bar. iOS safe-area handled via padding-bottom: env(safe-area-inset-bottom). */}
          <nav
            aria-label="Navegación inferior"
            className="border-t border-[var(--color-border)] bg-[var(--color-surface)]/95 px-[var(--space-2)] pt-[var(--space-2)] backdrop-blur"
            style={{ paddingBottom: 'calc(var(--space-2) + env(safe-area-inset-bottom))' }}
          >
            <ul className="flex items-stretch justify-around">
              {TABS.map(({ label, icon: Icon, current, overflow }) => (
                <li key={label} className="flex-1">
                  <button
                    type="button"
                    aria-current={current ? 'page' : undefined}
                    aria-haspopup={overflow ? 'menu' : undefined}
                    className={`flex w-full flex-col items-center gap-[var(--space-1)] rounded-[var(--radius-md)] px-[var(--space-1)] py-[var(--space-2)] ${TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                      current
                        ? 'text-[var(--color-primary)]'
                        : 'text-[var(--color-text-muted)] hover:text-[var(--color-text)]'
                    }`}
                  >
                    <span className="relative inline-flex items-center">
                      <Icon className="h-5 w-5" aria-hidden="true" />
                      {/* Active dot indicator above the icon (set has no filled variant). */}
                      {current ? (
                        <span
                          aria-hidden="true"
                          className="absolute -top-1.5 left-1/2 h-1 w-1 -translate-x-1/2 rounded-full bg-[var(--color-primary)]"
                        />
                      ) : null}
                      {/* Overflow chevron hints the "Más" dropdown. */}
                      {overflow ? (
                        <ChevronDown className="ml-0.5 h-3 w-3" aria-hidden="true" />
                      ) : null}
                    </span>
                    <span className={`text-xs ${current ? 'font-semibold' : 'font-medium'}`}>
                      {label}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          </nav>
        </div>

        <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
          fixed bottom-0 (framed here) · 5 items max — 5th = &quot;Más&quot; overflow · active → text-primary + dot · safe-area → env(safe-area-inset-bottom)
        </p>
      </div>
    </section>
  )
}
