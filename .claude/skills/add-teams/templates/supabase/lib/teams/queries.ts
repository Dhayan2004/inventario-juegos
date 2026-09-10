// Server-side reads for team / tenant management. Usan el server client (anon
// key + sesión del caller) — NUNCA service_role: cada lectura pasa por RLS, así
// el aislamiento de tenant (R16) y la autoridad de rol (L-005) se enforce en
// Postgres, no aquí. El organization_id que llega de la UI sólo devuelve datos
// si el caller pertenece a esa org (las policies de 0000_tenancy.sql/0005_teams.sql
// lo validan); estas funciones NO reimplementan esa frontera.
//
// Cita:
// - [memory:lessons#L-005]   (RLS por tenant — la lectura la filtra Postgres)
// - [memory:CONSTRAINTS.md#R16] (aislamiento de tenant)
// - [docs:supabase-js]
import { createClient } from '@/lib/supabase/server';

// ─────────────────────────────────────────────────────────────────────────────
// Tipos explícitos — match al SQL (0000_tenancy.sql + 0005_teams.sql).
// ─────────────────────────────────────────────────────────────────────────────
export type OrgRole = 'owner' | 'admin' | 'member';
export type InvitationRole = 'admin' | 'member';
export type InvitationStatus = 'pending' | 'accepted' | 'revoked' | 'expired';

export interface Organization {
  id: string;
  name: string;
  slug: string;
  created_at: string;
}

// La org del usuario + el rol que tiene en ella (proyección de la membership).
export interface OrganizationMembership {
  organization: Organization;
  role: OrgRole;
}

export interface OrgMember {
  membership_id: string;
  user_id: string;
  email: string | null;
  full_name: string | null;
  role: OrgRole;
  created_at: string;
}

export interface Invitation {
  id: string;
  organization_id: string;
  email: string;
  role: InvitationRole;
  status: InvitationStatus;
  invited_by: string;
  created_at: string;
  expires_at: string;
}

// Vista pública (mínima) de una invitación leída por token, para la landing de
// aceptación: NO expone invited_by ni metadatos sensibles, sólo lo necesario.
export interface InvitationPreview {
  id: string;
  organization_id: string;
  organization_name: string | null;
  email: string;
  role: InvitationRole;
  status: InvitationStatus;
  expires_at: string;
}

// Las orgs del usuario autenticado + su rol en cada una. RLS sobre memberships
// ya limita las filas a las del caller (auth_org_ids), así que no filtramos por
// user_id manualmente: lo hace Postgres.
export async function getMyOrganizations(): Promise<OrganizationMembership[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('memberships')
    .select('role, organization:organizations(id, name, slug, created_at)')
    .order('created_at', { ascending: true });
  if (error || !data) return [];

  // El embed devuelve `organization` como objeto (relación to-one); normalizamos.
  return data
    .map((row) => {
      const org = Array.isArray(row.organization)
        ? row.organization[0]
        : row.organization;
      if (!org) return null;
      return { organization: org as Organization, role: row.role as OrgRole };
    })
    .filter((m): m is OrganizationMembership => m !== null);
}

// Miembros de una org. RLS sobre memberships devuelve filas SÓLO si el caller
// pertenece a esa org (R16); orgId ajeno ⇒ lista vacía, no error de fuga.
export async function getOrgMembers(orgId: string): Promise<OrgMember[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('memberships')
    .select('id, user_id, role, created_at, profile:profiles(email, full_name)')
    .eq('organization_id', orgId)
    .order('created_at', { ascending: true });
  if (error || !data) return [];

  return data.map((row) => {
    const profile = Array.isArray(row.profile) ? row.profile[0] : row.profile;
    return {
      membership_id: row.id as string,
      user_id: row.user_id as string,
      email: (profile?.email as string | undefined) ?? null,
      full_name: (profile?.full_name as string | undefined) ?? null,
      role: row.role as OrgRole,
      created_at: row.created_at as string,
    };
  });
}

// Invitaciones pendientes de una org. RLS ("invitations read") exige owner/admin
// para ver las invitaciones de la org; un member no obtiene filas.
export async function getPendingInvitations(orgId: string): Promise<Invitation[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('invitations')
    .select(
      'id, organization_id, email, role, status, invited_by, created_at, expires_at',
    )
    .eq('organization_id', orgId)
    .eq('status', 'pending')
    .order('created_at', { ascending: false });
  if (error || !data) return [];
  return data as Invitation[];
}

// Invitación por token, para la landing /invite/[token]. RLS deja que el invitado
// vea la suya por match de email del JWT (aunque aún no sea miembro). NO valida
// la aceptación: eso lo hace accept_invitation() (definer) cuando el usuario
// confirma — esta lectura sólo es para PINTAR la landing.
export async function getInvitationByToken(
  token: string,
): Promise<InvitationPreview | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('invitations')
    .select(
      'id, organization_id, email, role, status, expires_at, organization:organizations(name)',
    )
    .eq('token', token)
    .maybeSingle();
  if (error || !data) return null;

  const org = Array.isArray(data.organization)
    ? data.organization[0]
    : data.organization;
  return {
    id: data.id as string,
    organization_id: data.organization_id as string,
    organization_name: (org?.name as string | undefined) ?? null,
    email: data.email as string,
    role: data.role as InvitationRole,
    status: data.status as InvitationStatus,
    expires_at: data.expires_at as string,
  };
}
