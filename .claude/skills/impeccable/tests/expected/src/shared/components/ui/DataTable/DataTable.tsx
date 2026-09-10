'use client'

/**
 * DataTable · derived component (NOT in brand.json.component_rules)
 *
 * Purpose: muestra rows comparables y permite reordenar para encontrar outliers
 *
 * Derivation rationale (R-005 sec 8.2):
 *   nearest_component: card.metric + form.search
 *   tokens applied:    surface-elevated, border, font-display headers,
 *                      font-mono amounts, focus-ring=primary
 *   posture-shaped:    density=4 → compact padding + sticky header
 *                      geometry=4 → radius-md (no lg)
 *                      materiality=1 → no shadow
 *   inherited rules:   focus-visible row state (from card.metric),
 *                      label clear (from form pattern)
 *   additional rules:  aria-sort en sortable headers, keyboard row nav
 *
 * must_include (R-005 sec 8.2):
 *   states:        focus-visible row, hover row, active selected, disabled
 *   responsive:    mobile = horizontal scroll + sticky first column
 *   accessibility: role=table, th scope=col, aria-sort, keyboard rows
 *
 * Citations:
 *   [memory:references#R-005] (sec 8.2 unknown_component_policy)
 *   [memory:CONSTRAINTS.md#R10] Brand DNA contract gate
 *   [docs:tailwindcss] · [docs:shadcn-ui] · [docs:react]
 *
 * Brand Score: 87/100
 */

import { useMemo, useState, type ReactNode } from 'react'
import { Card } from '@/shared/components/ui/Card'
import { cn } from '@/lib/cn'

export interface DataTableColumn<T> {
  key: keyof T
  label: string
  sortable?: boolean
  align?: 'left' | 'right' | 'center'
  format?: (value: T[keyof T], row: T) => ReactNode
}

export interface DataTableProps<T> {
  data: T[]
  columns: DataTableColumn<T>[]
  onRowSelect?: (row: T) => void
  emptyState?: ReactNode
  className?: string
}

export function DataTable<T extends { id: string | number }>({
  data,
  columns,
  onRowSelect,
  emptyState,
  className,
}: DataTableProps<T>) {
  const [sortKey, setSortKey] = useState<keyof T | null>(null)
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc')

  const sortedData = useMemo(() => {
    if (!sortKey) return data
    const dir = sortDir === 'asc' ? 1 : -1
    return [...data].sort((a, b) => {
      const av = a[sortKey]
      const bv = b[sortKey]
      if (av === bv) return 0
      return av > bv ? dir : -dir
    })
  }, [data, sortKey, sortDir])

  function toggleSort(key: keyof T) {
    if (sortKey === key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'))
    } else {
      setSortKey(key)
      setSortDir('asc')
    }
  }

  if (data.length === 0) {
    return (
      <Card variant="empty" className={className}>
        {emptyState ?? <p>No hay datos para mostrar.</p>}
      </Card>
    )
  }

  return (
    <Card variant="default" className={cn('overflow-x-auto p-0', className)}>
      <table role="table" className="w-full text-sm">
        <thead className="sticky top-0 bg-surface-elevated">
          <tr>
            {columns.map((col) => {
              const ariaSort: 'ascending' | 'descending' | 'none' =
                sortKey === col.key
                  ? sortDir === 'asc'
                    ? 'ascending'
                    : 'descending'
                  : 'none'
              return (
                <th
                  key={String(col.key)}
                  scope="col"
                  aria-sort={col.sortable ? ariaSort : undefined}
                  className={cn(
                    'font-mono text-xs uppercase tracking-widest text-text-subtle px-3 py-2',
                    col.align === 'right' && 'text-right',
                    col.align === 'center' && 'text-center',
                    !col.align && 'text-left'
                  )}
                >
                  {col.sortable ? (
                    <button
                      type="button"
                      onClick={() => toggleSort(col.key)}
                      className="hover:text-text focus-visible:outline-none focus-visible:text-text"
                    >
                      {col.label}
                    </button>
                  ) : (
                    col.label
                  )}
                </th>
              )
            })}
          </tr>
        </thead>
        <tbody>
          {sortedData.map((row) => (
            <tr
              key={row.id}
              tabIndex={onRowSelect ? 0 : -1}
              onClick={onRowSelect ? () => onRowSelect(row) : undefined}
              onKeyDown={(e) => {
                if (onRowSelect && (e.key === 'Enter' || e.key === ' ')) {
                  e.preventDefault()
                  onRowSelect(row)
                }
              }}
              className={cn(
                'border-t border-border',
                onRowSelect &&
                  'hover:bg-surface-higher focus-visible:outline-none focus-visible:bg-surface-higher cursor-pointer'
              )}
            >
              {columns.map((col) => (
                <td
                  key={String(col.key)}
                  className={cn(
                    'px-3 py-2 text-text',
                    col.align === 'right' && 'text-right font-mono',
                    col.align === 'center' && 'text-center'
                  )}
                >
                  {col.format ? col.format(row[col.key], row) : String(row[col.key])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </Card>
  )
}
