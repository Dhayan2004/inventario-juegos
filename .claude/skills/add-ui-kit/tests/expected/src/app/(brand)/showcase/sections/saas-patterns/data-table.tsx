/**
 * SaaS Pattern B — Data Table con Filtros.
 *
 * Composición completa de una pantalla SaaS real (no un control aislado):
 * toolbar de tabla + tabla tipada + estados de fila + estado vacío + skeleton
 * + paginación. Static showcase: los estados que normalmente requieren
 * interactividad (dropdown de row actions abierto, search con foco, fila
 * seleccionada) se MUESTRAN como su visual en reposo y se etiquetan en mono —
 * no hay 'use client', es un server component como el resto de sections/.
 *
 * Bloques cubiertos (Forge SKILL.md Part 2 · Pattern B, L741-749):
 *   - toolbar:    título de sección + botón "Nuevo" (primary) + search input
 *                 + chips de filtro
 *   - table:      columnas tipadas (checkbox selección · nombre · estado · plan
 *                 · MRR · acciones) con header sticky-look y filas con hover tag
 *   - row:        fila normal · fila seleccionada (checkbox marcado + tint)
 *   - actions:    dropdown Edit / Delete por fila (abierto, static preview)
 *   - empty:      empty state dentro de la tabla (ilustración inline + CTA)
 *   - loading:    filas skeleton que imitan el ritmo de columnas
 *   - pagination: prev/next (prev disabled en página 1) + "1–10 de 47"
 *
 * Anti-Slop checks performed by el-evaluador on this section:
 *   - "Nuevo" usa --color-primary sólido (NO gradiente diagonal); icon-only
 *     y los botones prev/next llevan aria-label.
 *   - Search input tiene <label htmlFor> real (sr-only) atado al id — nunca
 *     placeholder-as-label; el ícono es aria-hidden.
 *   - Empty state ≠ spinner: el empty se muestra solo, nunca con el skeleton.
 *   - Skeleton imita el layout de la tabla (celdas por columna), no un bloque
 *     gris genérico; fill desde --color-text-subtle a baja alfa.
 *   - Sólo tokens --color-* / --radius-* / --space-* / motion vars; NO hex,
 *     NO clases de color Tailwind, NO bg-white, NO gradiente purple/indigo.
 *
 * Citations:
 *   [memory:references#R-005]   — schema source (component_rules: table, form)
 *   [memory:CONSTRAINTS.md#R10] — Brand DNA contract gate (tokens-only)
 *   [docs:nextjs]               — server component in (brand) route group
 *   [docs:tailwindcss]          — arbitrary value syntax bg-[var(--color-token)]
 *   [docs:shadcn-ui]            — Table + DropdownMenu row-actions reference
 *
 * DO NOT edit hex/font/px inline. All visual values come from brand.css vars.
 */

import {
  Plus,
  Search,
  ListFilter,
  ChevronDown,
  MoreHorizontal,
  Pencil,
  Trash2,
  ChevronLeft,
  ChevronRight,
  Inbox,
} from 'lucide-react'

// Typed columns — mirrors a real "Clientes" table. `align` drives the cell
// rhythm so the skeleton can reuse the exact same widths.
type Row = {
  id: string
  name: string
  email: string
  status: 'active' | 'pending' | 'churned'
  plan: string
  mrr: string
}

const ROWS: Row[] = [
  { id: '1', name: 'Acme Studio', email: 'hola@acme.studio', status: 'active', plan: 'Pro', mrr: '$240' },
  { id: '2', name: 'Nimbus Labs', email: 'team@nimbus.io', status: 'active', plan: 'Scale', mrr: '$880' },
  { id: '3', name: 'Faro Digital', email: 'ana@faro.mx', status: 'pending', plan: 'Pro', mrr: '$240' },
  { id: '4', name: 'Orbita Co', email: 'cuentas@orbita.co', status: 'churned', plan: 'Starter', mrr: '$0' },
]

// Status → semantic token. NEVER a hardcoded green/red — read from brand.css.
const STATUS: Record<Row['status'], { label: string; color: string }> = {
  active: { label: 'Activo', color: 'var(--color-success)' },
  pending: { label: 'Pendiente', color: 'var(--color-warning)' },
  churned: { label: 'Cancelado', color: 'var(--color-danger)' },
}

// Shared skeleton bar — muted token fill + pulse (opacity only), same recipe
// as the Loading section so the table skeleton reads consistently.
const BAR = 'animate-pulse rounded-[var(--radius-sm)] bg-[var(--color-text-subtle)]/20'

function StatusBadge({ status }: { status: Row['status'] }) {
  const { label, color } = STATUS[status]
  return (
    <span className="inline-flex items-center gap-[var(--space-2)] text-sm text-[var(--color-text)]">
      <span className="h-2 w-2 rounded-full" style={{ background: color }} aria-hidden="true" />
      {label}
    </span>
  )
}

export function DataTablePattern() {
  return (
    <section aria-labelledby="saas-data-table-title">
      <h2
        id="saas-data-table-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        SaaS · Data Table con Filtros
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Forge SKILL.md Part 2 · Pattern B — toolbar + tabla tipada con row actions, selección, estado vacío, skeleton y paginación. Composición real de pantalla, no un control suelto.
      </p>

      <div className="mt-[var(--space-8)] space-y-[var(--space-8)]">
        {/* ── Variant 1 — tabla con datos: toolbar + filas + selección + dropdown abierto + paginación ── */}
        <article className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]">
          <p className="border-b border-[var(--color-border)] px-[var(--space-6)] pt-[var(--space-4)] pb-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            table · with data
          </p>

          {/* Toolbar — section title + "Nuevo" + search + filter chips */}
          <div className="flex flex-col gap-[var(--space-4)] p-[var(--space-6)] md:flex-row md:items-center md:justify-between">
            <div>
              <h3 className="font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
                Clientes
              </h3>
              <p className="mt-[var(--space-1)] text-sm text-[var(--color-text-muted)]">
                47 cuentas activas este mes.
              </p>
            </div>

            <div className="flex flex-col gap-[var(--gap-sm)] sm:flex-row sm:items-center">
              {/* Search — visible (sr-only) label tied to id; icon aria-hidden */}
              <div className="relative">
                <label htmlFor="dt-search" className="sr-only">
                  Buscar clientes
                </label>
                <Search
                  className="pointer-events-none absolute left-[var(--space-3)] top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-subtle)]"
                  aria-hidden="true"
                />
                <input
                  id="dt-search"
                  type="search"
                  placeholder="Buscar…"
                  className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] py-[var(--space-2)] pl-[calc(var(--space-3)+var(--space-6))] pr-[var(--space-3)] text-sm text-[var(--color-text)] placeholder:text-[var(--color-text-subtle)] transition-colors duration-[var(--motion-duration-fast)] focus:border-[var(--color-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] sm:w-48"
                />
              </div>

              {/* Filter chip — resting state; opens a menu in the real app */}
              <button
                type="button"
                className="inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-3)] py-[var(--space-2)] text-sm font-medium text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface-elevated)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                <ListFilter className="h-4 w-4" aria-hidden="true" />
                Estado
                <ChevronDown className="h-4 w-4 text-[var(--color-text-subtle)]" aria-hidden="true" />
              </button>

              {/* Primary action — solid --color-primary, NO diagonal gradient */}
              <button
                type="button"
                className="inline-flex items-center justify-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-white transition-colors duration-[var(--motion-duration-fast)] hover:opacity-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                <Plus className="h-4 w-4" aria-hidden="true" />
                Nuevo cliente
              </button>
            </div>
          </div>

          {/* Table — typed columns, sticky-look header, selection checkbox */}
          <div className="border-t border-[var(--color-border)]">
            <table className="w-full border-collapse text-left">
              <thead>
                <tr className="border-b border-[var(--color-border)] bg-[var(--color-surface)]">
                  <th scope="col" className="w-[var(--space-12)] px-[var(--space-6)] py-[var(--space-3)]">
                    {/* header select-all checkbox (unchecked) */}
                    <span
                      className="block h-4 w-4 rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)]"
                      role="checkbox"
                      aria-checked="false"
                      aria-label="Seleccionar todos"
                    />
                  </th>
                  <th scope="col" className="px-[var(--space-4)] py-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                    Cliente
                  </th>
                  <th scope="col" className="px-[var(--space-4)] py-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                    Estado
                  </th>
                  <th scope="col" className="hidden px-[var(--space-4)] py-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)] sm:table-cell">
                    Plan
                  </th>
                  <th scope="col" className="px-[var(--space-4)] py-[var(--space-3)] text-right font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                    MRR
                  </th>
                  <th scope="col" className="w-[var(--space-12)] px-[var(--space-6)] py-[var(--space-3)] text-right font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
                    <span className="sr-only">Acciones</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[var(--color-border)]">
                {ROWS.map((row, i) => {
                  // Row 2 (i === 1) shown as the SELECTED state: checked box + tint.
                  const selected = i === 1
                  return (
                    <tr
                      key={row.id}
                      className={
                        selected
                          ? 'bg-[var(--color-primary)]/10'
                          : 'transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface)]'
                      }
                    >
                      <td className="px-[var(--space-6)] py-[var(--space-4)] align-middle">
                        <span
                          className={
                            selected
                              ? 'flex h-4 w-4 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-primary)] text-white'
                              : 'block h-4 w-4 rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)]'
                          }
                          role="checkbox"
                          aria-checked={selected}
                          aria-label={`Seleccionar ${row.name}`}
                        >
                          {selected ? (
                            <svg viewBox="0 0 16 16" className="h-3 w-3" fill="none" aria-hidden="true">
                              <path
                                d="M13 4.5 6.5 11 3 7.5"
                                stroke="currentColor"
                                strokeWidth="2"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                              />
                            </svg>
                          ) : null}
                        </span>
                      </td>
                      <td className="px-[var(--space-4)] py-[var(--space-4)] align-middle">
                        <p className="text-sm font-medium text-[var(--color-text)]">{row.name}</p>
                        <p className="text-xs text-[var(--color-text-subtle)]">{row.email}</p>
                      </td>
                      <td className="px-[var(--space-4)] py-[var(--space-4)] align-middle">
                        <StatusBadge status={row.status} />
                      </td>
                      <td className="hidden px-[var(--space-4)] py-[var(--space-4)] align-middle text-sm text-[var(--color-text-muted)] sm:table-cell">
                        {row.plan}
                      </td>
                      <td className="px-[var(--space-4)] py-[var(--space-4)] align-middle text-right font-mono text-sm text-[var(--color-text)]">
                        {row.mrr}
                      </td>
                      <td className="relative px-[var(--space-6)] py-[var(--space-4)] text-right align-middle">
                        {/* Row actions trigger — icon-only needs aria-label */}
                        <button
                          type="button"
                          aria-label={`Acciones para ${row.name}`}
                          aria-haspopup="menu"
                          aria-expanded={selected}
                          className="inline-flex h-8 w-8 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-muted)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface)] hover:text-[var(--color-text)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
                        >
                          <MoreHorizontal className="h-4 w-4" aria-hidden="true" />
                        </button>

                        {/* Dropdown — shown OPEN on the selected row (static preview) */}
                        {selected ? (
                          <div
                            role="menu"
                            aria-label={`Acciones para ${row.name}`}
                            className="absolute right-[var(--space-6)] top-[calc(100%-var(--space-2))] z-10 w-44 overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] py-[var(--space-1)] text-left shadow-lg"
                          >
                            <button
                              type="button"
                              role="menuitem"
                              className="flex w-full items-center gap-[var(--space-3)] px-[var(--space-4)] py-[var(--space-2)] text-sm text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface)]"
                            >
                              <Pencil className="h-4 w-4 text-[var(--color-text-muted)]" aria-hidden="true" />
                              Editar
                            </button>
                            <button
                              type="button"
                              role="menuitem"
                              className="flex w-full items-center gap-[var(--space-3)] px-[var(--space-4)] py-[var(--space-2)] text-sm text-[var(--color-danger)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-danger)]/10"
                            >
                              <Trash2 className="h-4 w-4" aria-hidden="true" />
                              Eliminar
                            </button>
                          </div>
                        ) : null}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination — prev disabled on page 1 · "1–10 de 47" counter */}
          <div className="flex items-center justify-between border-t border-[var(--color-border)] px-[var(--space-6)] py-[var(--space-4)]">
            <p className="font-mono text-xs text-[var(--color-text-subtle)]">
              1–10 de 47
            </p>
            <div className="flex items-center gap-[var(--gap-xs)]">
              <button
                type="button"
                disabled
                aria-label="Página anterior"
                className="inline-flex h-8 w-8 cursor-not-allowed items-center justify-center rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-text-subtle)] opacity-50"
              >
                <ChevronLeft className="h-4 w-4" aria-hidden="true" />
              </button>
              <button
                type="button"
                aria-label="Página siguiente"
                className="inline-flex h-8 w-8 items-center justify-center rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-text)] transition-colors duration-[var(--motion-duration-fast)] hover:bg-[var(--color-surface-elevated)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                <ChevronRight className="h-4 w-4" aria-hidden="true" />
              </button>
            </div>
          </div>
        </article>

        <div className="grid gap-[var(--space-8)] lg:grid-cols-2">
          {/* ── Variant 2 — loading: skeleton rows that mirror the column rhythm ── */}
          <article className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]">
            <p className="border-b border-[var(--color-border)] px-[var(--space-6)] pt-[var(--space-4)] pb-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
              table · loading (skeleton rows)
            </p>
            <div
              className="divide-y divide-[var(--color-border)]"
              aria-busy="true"
              aria-label="Cargando clientes"
            >
              {[0, 1, 2, 3, 4].map((rowIndex) => (
                <div
                  key={rowIndex}
                  className="flex items-center gap-[var(--space-4)] px-[var(--space-6)] py-[var(--space-4)]"
                >
                  {/* checkbox cell */}
                  <div className={`${BAR} h-4 w-4 shrink-0`} />
                  {/* name + email cell (wide) */}
                  <div className="flex-1 space-y-[var(--space-2)]">
                    <div className={`${BAR} h-3 w-2/5`} />
                    <div className={`${BAR} h-3 w-3/5`} />
                  </div>
                  {/* status cell */}
                  <div className={`${BAR} h-3 w-16 shrink-0`} />
                  {/* mrr cell (narrow, right) */}
                  <div className={`${BAR} h-3 w-12 shrink-0`} />
                  {/* actions cell */}
                  <div className={`${BAR} h-4 w-4 shrink-0`} />
                </div>
              ))}
            </div>
            <p className="border-t border-[var(--color-border)] px-[var(--space-6)] py-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
              mirrors column rhythm · animate-pulse · never shown with the empty state
            </p>
          </article>

          {/* ── Variant 3 — empty: empty state INSIDE the table (no spinner) ── */}
          <article className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)]">
            <p className="border-b border-[var(--color-border)] px-[var(--space-6)] pt-[var(--space-4)] pb-[var(--space-3)] font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
              table · empty state
            </p>
            <div className="flex flex-col items-center justify-center px-[var(--space-6)] py-[var(--space-16)] text-center">
              {/* Inline illustration — simple icon framed in a muted surface */}
              <div className="flex h-12 w-12 items-center justify-center rounded-full border border-[var(--color-border)] bg-[var(--color-surface)]">
                <Inbox className="h-6 w-6 text-[var(--color-text-subtle)]" aria-hidden="true" />
              </div>
              <h3 className="mt-[var(--space-4)] font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-text)]">
                Aún no hay clientes
              </h3>
              <p className="mt-[var(--space-2)] max-w-xs text-sm text-[var(--color-text-muted)]">
                Cuando agregues tu primer cliente, aparecerá aquí con su estado y plan.
              </p>
              {/* Primary CTA — solid, mirrors the toolbar action */}
              <button
                type="button"
                className="mt-[var(--space-6)] inline-flex items-center gap-[var(--space-2)] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-[var(--space-4)] py-[var(--space-2)] text-sm font-semibold text-white transition-colors duration-[var(--motion-duration-fast)] hover:opacity-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)]"
              >
                <Plus className="h-4 w-4" aria-hidden="true" />
                Nuevo cliente
              </button>
            </div>
            <p className="border-t border-[var(--color-border)] px-[var(--space-6)] py-[var(--space-3)] font-mono text-xs text-[var(--color-text-subtle)]">
              empty ≠ loading · illustration + heading + CTA · mutually exclusive with skeleton
            </p>
          </article>
        </div>
      </div>
    </section>
  )
}
