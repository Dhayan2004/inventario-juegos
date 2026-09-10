// RoleSelect — selector de rol para gestión de equipo. R10 enforced: usa Select de impeccable.
//
// Contrato del modelo de rol (teams-model.md §1):
//   - NUNCA ofrece 'owner' en el select. La propiedad se mueve SOLO vía transferOwnership
//     (transfer_org_ownership(), atómico, owner-only). Ver 0005_teams.sql §5.
//   - Sólo se ofrecen los roles invitables/asignables: 'admin' | 'member'.
//   - El gating por rol del caller lo decide el consumidor (members no ven este control);
//     la frontera real es Postgres (RLS + WITH CHECK), esto sólo refleja la autoridad.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-003] [memory:references#R-005]
'use client';

import { Select } from '@/shared/components/ui';

// Roles ASIGNABLES desde la UI — 'owner' NUNCA está aquí (anti-escalación, teams-model.md §3).
export const ASSIGNABLE_ROLES = ['admin', 'member'] as const;
export type AssignableRole = (typeof ASSIGNABLE_ROLES)[number];

const ROLE_LABELS: Record<AssignableRole, string> = {
  admin: 'Admin',
  member: 'Miembro',
};

export interface RoleSelectProps {
  name?: string;
  label?: string;
  value?: AssignableRole;
  defaultValue?: AssignableRole;
  disabled?: boolean;
  required?: boolean;
  error?: string;
  onChange?: (role: AssignableRole) => void;
}

export function RoleSelect({
  name = 'role',
  label = 'Rol',
  value,
  defaultValue,
  disabled,
  required,
  error,
  onChange,
}: RoleSelectProps) {
  return (
    <Select
      name={name}
      label={label}
      value={value}
      defaultValue={defaultValue}
      disabled={disabled}
      required={required}
      error={error}
      onChange={(e) => onChange?.(e.target.value as AssignableRole)}
    >
      {ASSIGNABLE_ROLES.map((role) => (
        <option key={role} value={role}>
          {ROLE_LABELS[role]}
        </option>
      ))}
    </Select>
  );
}
