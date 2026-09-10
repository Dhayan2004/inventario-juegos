// GET /api/teams/my-organizations — lista las orgs del usuario autenticado + su
// rol en cada una. Envuelve getMyOrganizations() (lib/teams/queries.ts), que usa
// el server client (anon key + sesión del caller) — NUNCA service_role: RLS sobre
// memberships limita las filas a las del caller (R16 + L-005), no filtramos aquí.
//
// Lo consume el hook useOrganization (client-side) para poblar el OrgSwitcher y
// resolver la org activa. Sólo lectura; no muta nada.
//
// Cita:
// - [memory:lessons#L-005]   (RLS por tenant — la lectura la filtra Postgres)
// - [memory:CONSTRAINTS.md#R16] (aislamiento de tenant; sin service_role en este path)
// - [docs:nextjs] [docs:supabase-js]
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { getMyOrganizations } from '@/lib/teams/queries';

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
  }

  const organizations = await getMyOrganizations();
  return NextResponse.json(organizations, { status: 200 });
}
