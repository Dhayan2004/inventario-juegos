// useOrganization hook — client-side. Mantiene el contexto de la ORG ACTIVA:
// la org actual + la lista de orgs del usuario + setActiveOrg que persiste la
// elección. NO confundir con el LocalStorage del plano de control (A1): aquí
// es el almacenamiento del lado app, propio del usuario final del target.
//
// Persistencia (división de responsabilidades, sin cookies en competencia):
//   - localStorage → lectura instantánea en el cliente (sin parpadeo de "no org").
//   - cookie `forja-active-org` → la escribe la SERVER ACTION `setActiveOrganization`
//     (httpOnly), NO este hook. Así el server (RPC/queries) sabe cuál org mostrar en el
//     primer render y JS no puede manipular la cookie. La cookie NO es la fuente de
//     autoridad: RLS valida cada acceso (R16); si el usuario fija una org a la que no
//     pertenece, las queries devuelven vacío. (Antes este hook escribía la MISMA cookie
//     por document.cookie → colisión con la httpOnly del server; ya no.)
//
// La lista de orgs viene de un endpoint que envuelve getMyOrganizations()
// (lib/teams/queries.ts) — server-side + RLS, nunca service_role. El cambio de org se
// PERSISTE delegando en la server action (no se duplica la lógica de cookie acá).
//
// Cita:
// - [memory:lessons#L-005]   (la autoridad de tenant es RLS; la cookie sólo es UI)
// - [memory:CONSTRAINTS.md#R16] (aislamiento de tenant)
// - [docs:react] [docs:nextjs]
'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { setActiveOrganization } from '@/actions/teams';

export type OrgRole = 'owner' | 'admin' | 'member';

export interface Organization {
  id: string;
  name: string;
  slug: string;
  created_at: string;
}

export interface OrganizationMembership {
  organization: Organization;
  role: OrgRole;
}

// Endpoint server-side que proyecta getMyOrganizations() (RLS-scoped).
const ORGS_ENDPOINT = '/api/teams/my-organizations';
const STORAGE_KEY = 'forja-active-org';
// La cookie `forja-active-org` la posee la server action setActiveOrganization (httpOnly).
// Este hook sólo toca localStorage (lectura instantánea); NO escribe document.cookie.

function readStoredOrgId(): string | null {
  if (typeof window === 'undefined') return null;
  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

function persistOrgIdLocal(orgId: string | null): void {
  if (typeof window === 'undefined') return;
  try {
    if (orgId) {
      window.localStorage.setItem(STORAGE_KEY, orgId);
    } else {
      window.localStorage.removeItem(STORAGE_KEY);
    }
  } catch {
    // localStorage no disponible (modo privado / SSR): la cookie del server cubre el render.
  }
}

interface UseOrganizationResult {
  organizations: OrganizationMembership[];
  activeOrg: Organization | null;
  activeRole: OrgRole | null;
  loading: boolean;
  error: string | null;
  setActiveOrg: (orgId: string) => Promise<void>;
  refresh: () => Promise<void>;
}

export function useOrganization(): UseOrganizationResult {
  const [organizations, setOrganizations] = useState<OrganizationMembership[]>([]);
  const [activeOrgId, setActiveOrgId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadOrganizations = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(ORGS_ENDPOINT, { credentials: 'same-origin' });
      if (!res.ok) throw new Error(`Failed to load organizations (${res.status})`);
      const data: OrganizationMembership[] = await res.json();
      setOrganizations(data);

      // Resolver la org activa: la persistida si todavía es válida; si no, la primera.
      const stored = readStoredOrgId();
      const valid = data.some((m) => m.organization.id === stored);
      const next = valid ? stored : (data[0]?.organization.id ?? null);
      setActiveOrgId(next);
      if (next !== stored) persistOrgIdLocal(next);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error');
      setOrganizations([]);
      setActiveOrgId(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadOrganizations();
  }, [loadOrganizations]);

  const setActiveOrg = useCallback(
    async (orgId: string) => {
      // Sólo permite activar una org de la lista del usuario (defensa de UI; la
      // frontera real sigue siendo RLS en cada query — R16).
      if (!organizations.some((m) => m.organization.id === orgId)) return;
      setActiveOrgId(orgId);          // optimista en cliente
      persistOrgIdLocal(orgId);       // lectura instantánea
      // La persistencia AUTORITATIVA (cookie httpOnly) la hace la server action, que
      // revalida la membresía vía RLS. No duplicamos la lógica de cookie acá (R16).
      await setActiveOrganization(orgId);
    },
    [organizations],
  );

  const { activeOrg, activeRole } = useMemo(() => {
    const match = organizations.find((m) => m.organization.id === activeOrgId);
    return {
      activeOrg: match?.organization ?? null,
      activeRole: match?.role ?? null,
    };
  }, [organizations, activeOrgId]);

  return {
    organizations,
    activeOrg,
    activeRole,
    loading,
    error,
    setActiveOrg,
    refresh: loadOrganizations,
  };
}
