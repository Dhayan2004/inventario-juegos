// OrgSwitcher — selector de organización activa. R10 enforced: usa Select de impeccable.
//
// Escribe el contexto de org activa (cookie/estado) llamando a la server action
// setActiveOrganization (actions/teams.ts). NO confía el organization_id del cliente para
// nada destructivo: RLS valida la membresía real (R16 invariante 3). Esto sólo conmuta la
// vista; toda autoridad sigue enforced en Postgres.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:CONSTRAINTS.md#R16] [memory:references#R-005]
'use client';

import { useState, useTransition } from 'react';
import { Select } from '@/shared/components/ui';
import { setActiveOrganization } from '@/actions/teams';

export interface OrgOption {
  id: string;
  name: string;
  role: 'owner' | 'admin' | 'member';
}

export interface OrgSwitcherProps {
  organizations: OrgOption[];
  activeOrgId: string;
}

export function OrgSwitcher({ organizations, activeOrgId }: OrgSwitcherProps) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  // Una sola org → no hay nada que conmutar; no renderizamos el control.
  if (organizations.length <= 1) {
    return null;
  }

  function handleChange(nextOrgId: string) {
    if (nextOrgId === activeOrgId) return;
    setError(null);
    startTransition(async () => {
      const result = await setActiveOrganization(nextOrgId);
      if (result?.error) {
        setError(result.error);
      }
    });
  }

  return (
    <div className="space-y-1">
      <Select
        name="organization_id"
        label="Organización activa"
        value={activeOrgId}
        disabled={pending}
        error={error ?? undefined}
        onChange={(e) => handleChange(e.target.value)}
      >
        {organizations.map((org) => (
          <option key={org.id} value={org.id}>
            {org.name}
          </option>
        ))}
      </Select>
    </div>
  );
}
