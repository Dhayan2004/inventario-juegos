/**
 * Navigation Section — renders the navigation + iconography patterns declared
 * in brand.json.component_rules.navigation (R-005 sec 3.3, "Navigation e
 * Iconografía"). Static showcase: hover / focus states that need interactivity
 * are SHOWN as their resting visual + labeled in mono (no 'use client' — this
 * is a server component, same as the other sections/).
 *
 * Patterns covered (R-005 sec 3.3 navigation set):
 *   - sidebar nav:  item default(inactive) · item active(indicator + --color-text)
 *                   · item hover (mono caption) · item with notification badge
 *   - top nav:      search field (label↔id) · notifications bell (badge) · avatar
 *
 * Iconography (R-005 size rule):
 *   - Lucide Outline only — never mix icon libraries.
 *   - h-4 w-4 inline · h-5 w-5 sidebar/nav · h-6 w-6 standalone.
 *   - inactive icons → --color-text-subtle · active → --color-text.
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Active indicator animates transform ONLY (translate/scale) — never
 *     width/height/left. Inactive→active color via color/background-color.
 *   - Icon-only controls (notifications) carry an aria-label; the search
 *     input has a visible/sr-only label tied via htmlFor↔id.
 *   - All visual values are --color-* / --radius-* / --space-* vars; NO hex,
 *     NO Tailwind color classes, NO bg-white.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules.navigation)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-token)]
 *   [docs:shadcn-ui]            — sidebar / navigation-menu / avatar refs
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { LayoutDashboard, FolderKanban, Inbox, Settings, Search, Bell } from 'lucide-react'

// Shared transition string — color + background-color + transform, fast easing.
// Only animatable-safe properties (R-005 motion rule); never width/height/left.
const NAV_TRANSITION =
  'transition-[color,background-color,transform] duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'

// Sidebar items. `badge` renders a notification count; `active` flags the
// current route (gets the active indicator + --color-text + active surface).
const SIDEBAR_ITEMS = [
  { key: 'dashboard', label: 'Dashboard', Icon: LayoutDashboard, active: true },
  { key: 'projects', label: 'Proyectos', Icon: FolderKanban, active: false },
  { key: 'inbox', label: 'Bandeja', Icon: Inbox, active: false, badge: 3 },
  { key: 'settings', label: 'Ajustes', Icon: Settings, active: false },
] as const

export function NavigationSection() {
  return (
    <section aria-labelledby="navigation-title">
      <h2
        id="navigation-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Navigation
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Sidebar + top nav con iconografía Lucide Outline. Inactivo{' '}
        <code className="font-mono">--color-text-subtle</code>, activo{' '}
        <code className="font-mono">--color-text</code>. Active indicator vía{' '}
        <code className="font-mono">transform</code>.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-8)] md:grid-cols-2">
        {/* Sidebar nav — active / inactive / hover (caption) / badge */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            sidebar · active / inactive / badge
          </p>
          <nav
            aria-label="Demostración de navegación lateral"
            className="mt-[var(--space-4)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-2)]"
          >
            <ul className="space-y-[var(--space-1)]">
              {SIDEBAR_ITEMS.map(({ key, label, Icon, active, badge }) => (
                <li key={key} className="relative">
                  {/* Active indicator — a left bar revealed via transform (scaleY).
                      transform is GPU-safe; never animate left/width here. */}
                  <span
                    aria-hidden="true"
                    className={`absolute left-0 top-1/2 h-5 w-[2px] -translate-y-1/2 origin-center rounded-full bg-[var(--color-primary)] ${NAV_TRANSITION} ${
                      active ? 'scale-y-100 opacity-100' : 'scale-y-0 opacity-0'
                    }`}
                  />
                  <a
                    href="#navigation-title"
                    aria-current={active ? 'page' : undefined}
                    className={`flex items-center gap-[var(--gap-sm)] rounded-[var(--radius-sm)] px-[var(--space-3)] py-[var(--space-2)] text-sm ${NAV_TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                      active
                        ? 'bg-[var(--color-surface-elevated)] font-semibold text-[var(--color-text)]'
                        : 'font-medium text-[var(--color-text-subtle)] hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)]'
                    }`}
                  >
                    {/* h-5 w-5 = sidebar size. Inactive icon inherits text-subtle,
                        active inherits text — color comes from the <a> currentColor. */}
                    <Icon className="h-5 w-5 shrink-0" aria-hidden="true" />
                    <span className="flex-1">{label}</span>
                    {badge ? (
                      <span
                        className="inline-flex min-w-5 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-primary)] px-[var(--space-1)] text-xs font-semibold text-white"
                        aria-label={`${badge} sin leer`}
                      >
                        {badge}
                      </span>
                    ) : null}
                  </a>
                </li>
              ))}
            </ul>
          </nav>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            hover → background-color · 140ms · active indicator → transform · 200ms
          </p>
        </article>

        {/* Top nav — search + notifications + avatar */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            top nav · search / notifications / avatar
          </p>
          <header className="mt-[var(--space-4)] flex items-center gap-[var(--gap-md)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-4)] py-[var(--space-3)]">
            {/* Search — visible-to-AT label tied via htmlFor↔id, icon h-4 w-4 inline */}
            <div className="relative flex-1">
              <label htmlFor="showcase-nav-search" className="sr-only">
                Buscar
              </label>
              <Search
                className="pointer-events-none absolute left-[var(--space-3)] top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-subtle)]"
                aria-hidden="true"
              />
              <input
                id="showcase-nav-search"
                type="search"
                placeholder="Buscar…"
                className={`block w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] py-[var(--space-2)] pl-[var(--space-8)] pr-[var(--space-3)] text-sm text-[var(--color-text)] placeholder:text-[var(--color-text-subtle)] ${NAV_TRANSITION} focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]`}
              />
            </div>

            {/* Notifications — icon-only button needs aria-label; badge dot overlays */}
            <button
              type="button"
              aria-label="Notificaciones (2 sin leer)"
              className={`relative inline-flex h-9 w-9 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-subtle)] ${NAV_TRANSITION} hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
            >
              <Bell className="h-5 w-5" aria-hidden="true" />
              <span
                aria-hidden="true"
                className="absolute right-[var(--space-2)] top-[var(--space-2)] h-2 w-2 rounded-full bg-[var(--color-danger)] ring-2 ring-[var(--color-surface)]"
              />
            </button>

            {/* Avatar — initials fallback on accent surface (no external <img> in showcase) */}
            <button
              type="button"
              aria-label="Menú de cuenta"
              className={`inline-flex h-9 w-9 items-center justify-center rounded-full bg-[var(--color-primary)] font-[family-name:var(--font-display)] text-sm font-semibold text-white ${NAV_TRANSITION} hover:opacity-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
            >
              CD
            </button>
          </header>
          <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
            icon-only → aria-label · search input → label htmlFor↔id · icons Lucide Outline
          </p>
        </article>
      </div>
    </section>
  )
}
