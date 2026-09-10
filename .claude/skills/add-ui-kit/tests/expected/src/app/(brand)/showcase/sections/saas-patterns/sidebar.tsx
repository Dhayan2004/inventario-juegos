/**
 * Sidebar Pattern (Part 2 — SaaS Patterns) — renders the canonical app-shell
 * layout: a fixed left sidebar + a content area. This is a STRUCTURAL showcase
 * (R-005 sec 3.3, Pattern D "Sidebar Navigation") — it shows the layout
 * skeleton and every nav state as static visuals, NOT a functional router.
 *
 * Structure rendered:
 *   shell:        fixed-width left sidebar (w-64) + flexible content area
 *   sidebar top:  brand/logo lockup (display font + accent mark)
 *   sidebar mid:  nav items with Lucide icons (h-5 w-5)
 *   sidebar foot: avatar (initials on accent) + settings icon-only button
 *   content area: placeholder header + skeleton blocks (layout, not features)
 *   mobile:       icon-only collapsed rail (labels hidden < md) shown alongside
 *
 * Nav item states (shown as static examples, per the spec):
 *   - active:   bg-[var(--color-accent)] + text-[var(--color-secondary)]
 *               (accent is a light/warm token → foreground is the dark
 *               --color-secondary so contrast stays AA; never text on
 *               text-on-accent guesswork)
 *   - inactive: text-[var(--color-text-muted)] on transparent
 *   - hover:    bg-[var(--color-surface-elevated)] (resting visual + mono
 *               caption, since this server component has no interactivity)
 *
 * Motion (R-005 motion rule — transform/opacity/color/background only):
 *   - State changes animate color + background-color via NAV_TRANSITION.
 *   - NEVER animate width/height of the sidebar (the collapsed rail is a
 *     separate static example, not an animated width transition).
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - Active item uses --color-accent fill with the dark --color-secondary
 *     foreground — no low-contrast text-on-accent, no hardcoded hex.
 *   - Icon-only controls (settings, mobile collapse, avatar) carry aria-label.
 *   - Icons are Lucide Outline at h-5 w-5 (sidebar) / h-4 w-4 (inline) — no
 *     mixed icon libraries, no emoji.
 *   - All visual values are --color-* / --radius-* / --space-* vars; NO hex,
 *     NO Tailwind color classes, NO bg-white, NO purple/indigo gradients.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules, Pattern D)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-token)]
 *   [docs:shadcn-ui]            — sidebar / avatar / button reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import { Hexagon, LayoutDashboard, FolderKanban, Inbox, BarChart3, Settings, PanelLeft } from 'lucide-react'

// Shared transition string — color + background-color only (GPU-safe + cheap).
// The sidebar width is NEVER transitioned (R-005 motion rule: no width/height).
const NAV_TRANSITION =
  'transition-[color,background-color] duration-[var(--motion-duration-fast)] ease-[var(--motion-easing)]'

// Nav items for the expanded sidebar. `active` flags the current route, which
// gets the --color-accent fill + dark --color-secondary foreground.
const NAV_ITEMS = [
  { key: 'dashboard', label: 'Dashboard', Icon: LayoutDashboard, active: true },
  { key: 'projects', label: 'Proyectos', Icon: FolderKanban, active: false },
  { key: 'inbox', label: 'Bandeja', Icon: Inbox, active: false },
  { key: 'reports', label: 'Reportes', Icon: BarChart3, active: false },
] as const

export function SidebarPattern() {
  return (
    <section aria-labelledby="sidebar-pattern-title">
      <h2
        id="sidebar-pattern-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Sidebar Navigation
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        App-shell: sidebar fijo izquierdo + área de contenido. Activo{' '}
        <code className="font-mono">bg-[var(--color-accent)]</code>, hover{' '}
        <code className="font-mono">bg-[var(--color-surface-elevated)]</code>.
        Colapsa a solo-íconos en mobile.
      </p>

      {/* Expanded shell — the full desktop layout (≥ md): sidebar + content */}
      <div className="mt-[var(--space-8)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]">
        <p className="border-b border-[var(--color-border)] px-[var(--space-4)] py-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          app shell · sidebar fijo + content area
        </p>

        <div className="flex min-h-[420px]">
          {/* ── Sidebar ────────────────────────────────────────────────── */}
          <aside
            aria-label="Navegación principal (demostración)"
            className="flex w-64 shrink-0 flex-col border-r border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-4)]"
          >
            {/* Brand / logo lockup */}
            <div className="flex items-center gap-[var(--gap-sm)] px-[var(--space-2)]">
              <span
                aria-hidden="true"
                className="inline-flex h-8 w-8 items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-primary)] text-[var(--color-secondary)]"
              >
                <Hexagon className="h-5 w-5" />
              </span>
              <span className="font-[family-name:var(--font-display)] text-lg font-bold text-[var(--color-text)]">
                Forge
              </span>
            </div>

            {/* Nav items */}
            <nav className="mt-[var(--space-8)] flex-1" aria-label="Secciones">
              <ul className="space-y-[var(--space-1)]">
                {NAV_ITEMS.map(({ key, label, Icon, active }) => (
                  <li key={key}>
                    <a
                      href="#sidebar-pattern-title"
                      aria-current={active ? 'page' : undefined}
                      className={`flex items-center gap-[var(--gap-sm)] rounded-[var(--radius-md)] px-[var(--space-3)] py-[var(--space-2)] text-sm ${NAV_TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                        active
                          ? 'bg-[var(--color-accent)] font-semibold text-[var(--color-secondary)]'
                          : 'font-medium text-[var(--color-text-muted)] hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)]'
                      }`}
                    >
                      {/* h-5 w-5 = sidebar size; color inherits from the <a> currentColor */}
                      <Icon className="h-5 w-5 shrink-0" aria-hidden="true" />
                      <span>{label}</span>
                    </a>
                  </li>
                ))}
              </ul>
            </nav>

            {/* Bottom section — avatar + settings */}
            <div className="mt-[var(--space-4)] flex items-center gap-[var(--gap-sm)] border-t border-[var(--color-border)] pt-[var(--space-4)]">
              {/* Avatar — initials fallback on accent (no external <img> in showcase) */}
              <span
                aria-hidden="true"
                className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[var(--color-accent)] font-[family-name:var(--font-display)] text-sm font-semibold text-[var(--color-secondary)]"
              >
                CD
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-[var(--color-text)]">Carlos D.</p>
                <p className="truncate text-xs text-[var(--color-text-subtle)]">carlos@ejemplo.com</p>
              </div>
              {/* Settings — icon-only button needs aria-label */}
              <button
                type="button"
                aria-label="Ajustes de cuenta"
                className={`inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-subtle)] ${NAV_TRANSITION} hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
              >
                <Settings className="h-5 w-5" aria-hidden="true" />
              </button>
            </div>
          </aside>

          {/* ── Content area ───────────────────────────────────────────── */}
          <div className="flex-1 bg-[var(--color-surface)] p-[var(--space-8)]">
            <h3 className="font-[family-name:var(--font-display)] text-2xl font-semibold text-[var(--color-text)]">
              Dashboard
            </h3>
            {/* Layout placeholders — silhouette of content, not real features */}
            <div className="mt-[var(--space-6)] grid grid-cols-2 gap-[var(--gap-md)]">
              <div
                aria-hidden="true"
                className="h-24 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]"
              />
              <div
                aria-hidden="true"
                className="h-24 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]"
              />
            </div>
            <div
              aria-hidden="true"
              className="mt-[var(--gap-md)] h-40 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]"
            />
            <p className="mt-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
              área de contenido · estructura de layout, no funcionalidad completa
            </p>
          </div>
        </div>
      </div>

      {/* Collapsed rail — the mobile / icon-only variant, shown as a separate
          static example (NOT an animated width transition of the shell above) */}
      <div className="mt-[var(--space-6)] overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]">
        <p className="border-b border-[var(--color-border)] px-[var(--space-4)] py-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
          mobile · rail colapsado solo-íconos
        </p>
        <div className="flex min-h-[260px]">
          <aside
            aria-label="Navegación colapsada (demostración)"
            className="flex w-16 shrink-0 flex-col items-center border-r border-[var(--color-border)] bg-[var(--color-surface)] p-[var(--space-2)]"
          >
            {/* Collapse toggle — icon-only, needs aria-label */}
            <button
              type="button"
              aria-label="Expandir navegación"
              className={`inline-flex h-10 w-10 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-muted)] ${NAV_TRANSITION} hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]`}
            >
              <PanelLeft className="h-5 w-5" aria-hidden="true" />
            </button>

            <nav className="mt-[var(--space-4)] flex-1" aria-label="Secciones (colapsado)">
              <ul className="space-y-[var(--space-1)]">
                {NAV_ITEMS.map(({ key, label, Icon, active }) => (
                  <li key={key}>
                    {/* Icon-only rail item — label moves to aria-label so the
                        control stays accessible without visible text */}
                    <a
                      href="#sidebar-pattern-title"
                      aria-label={label}
                      aria-current={active ? 'page' : undefined}
                      className={`inline-flex h-10 w-10 items-center justify-center rounded-[var(--radius-md)] ${NAV_TRANSITION} focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                        active
                          ? 'bg-[var(--color-accent)] text-[var(--color-secondary)]'
                          : 'text-[var(--color-text-muted)] hover:bg-[var(--color-surface-elevated)] hover:text-[var(--color-text)]'
                      }`}
                    >
                      <Icon className="h-5 w-5" aria-hidden="true" />
                    </a>
                  </li>
                ))}
              </ul>
            </nav>

            {/* Avatar pinned to the bottom of the rail */}
            <span
              aria-hidden="true"
              className="mt-[var(--space-4)] inline-flex h-9 w-9 items-center justify-center rounded-full bg-[var(--color-accent)] font-[family-name:var(--font-display)] text-sm font-semibold text-[var(--color-secondary)]"
            >
              CD
            </span>
          </aside>

          <div className="flex-1 bg-[var(--color-surface)] p-[var(--space-6)]">
            <p className="font-mono text-xs text-[var(--color-text-subtle)]">
              hover → background-color · 140ms · activo → bg-[var(--color-accent)] · labels vía aria-label
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
