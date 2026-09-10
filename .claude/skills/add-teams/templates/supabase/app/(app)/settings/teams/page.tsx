// Settings · Equipo — gestión de la organización activa. R10 enforced: consume Brand DNA vía
// impeccable (Card, Button, Input). NO Tailwind defaults.
//
// Server component: LEE la org activa, sus miembros y sus invitaciones pendientes con el cliente
// server de Supabase (RLS aplica — sólo ve lo que su membresía permite, R16). Compone los
// componentes client de features/teams + la ZONA PELIGROSA (OrgSettings) inline.
//
// R14 (destructivas → confirmación tipada, sin execute() automático):
//   - Renombrar org NO es destructivo → form directo.
//   - Transferir propiedad y borrar org SÍ lo son → cada uno exige escribir un texto exacto
//     (el nombre de la org para transferir, el slug para borrar). La verificación del texto la
//     hace la SERVER ACTION (mismo patrón que api/auth/delete-account/route.ts), no el cliente:
//     la action rebota si el `confirmation` no matchea. Así la frontera de R14 vive server-side.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:CONSTRAINTS.md#R14] [memory:CONSTRAINTS.md#R16] [docs:nextjs] [docs:supabase]
import { redirect } from 'next/navigation';
import { Card } from '@/shared/components/ui';
import { Button } from '@/shared/components/ui';
import { Input } from '@/shared/components/ui';
import { createClient } from '@/lib/supabase/server';
import {
  MembersList,
  InviteMemberForm,
  PendingInvitations,
  type TeamMember,
  type MemberRole,
  type PendingInvitation,
} from '@/features/teams/components';
import {
  renameOrganization,
  transferOwnership,
  deleteOrganization,
  getActiveOrganizationId,
} from '@/actions/teams';

interface OrgRow {
  id: string;
  name: string;
  slug: string;
}

export default async function TeamSettingsPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    redirect('/sign-in');
  }

  // Org activa (cookie/estado escrito por OrgSwitcher). Sin org → no hay nada que gestionar.
  const activeOrgId = await getActiveOrganizationId();
  if (!activeOrgId) {
    redirect('/dashboard');
  }

  // RLS garantiza que sólo se devuelven filas de orgs donde el usuario es miembro (R16).
  const { data: org } = await supabase
    .from('organizations')
    .select('id, name, slug')
    .eq('id', activeOrgId)
    .single<OrgRow>();
  if (!org) {
    redirect('/dashboard');
  }

  // Rol del caller en esta org — decide qué se muestra (gating; la autoridad real es RLS).
  const { data: callerMembership } = await supabase
    .from('memberships')
    .select('role')
    .eq('organization_id', org.id)
    .eq('user_id', user.id)
    .single<{ role: MemberRole }>();
  const callerRole: MemberRole = callerMembership?.role ?? 'member';
  const isOwner = callerRole === 'owner';
  const canManage = callerRole === 'owner' || callerRole === 'admin';

  // Miembros (join a profiles para nombre/email; RLS limita a co-miembros de la org).
  const { data: membershipRows } = await supabase
    .from('memberships')
    .select('id, user_id, role, profiles ( email, full_name )')
    .eq('organization_id', org.id);

  const members: TeamMember[] = (membershipRows ?? []).map((row) => {
    const profile = Array.isArray(row.profiles) ? row.profiles[0] : row.profiles;
    return {
      id: row.id as string,
      userId: row.user_id as string,
      role: row.role as MemberRole,
      email: (profile?.email as string) ?? '',
      name: (profile?.full_name as string | null) ?? null,
    };
  });

  // Invitaciones pendientes — sólo owner/admin las ven (policy "invitations read").
  let invitations: PendingInvitation[] = [];
  if (canManage) {
    const { data: invitationRows } = await supabase
      .from('invitations')
      .select('id, email, role, expires_at')
      .eq('organization_id', org.id)
      .eq('status', 'pending');
    invitations = (invitationRows ?? []).map((row) => ({
      id: row.id as string,
      email: row.email as string,
      role: row.role as PendingInvitation['role'],
      expiresAt: row.expires_at as string,
    }));
  }

  return (
    <main className="mx-auto w-full max-w-3xl px-4 py-section-md space-y-section-sm">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-text">{/* {{ COPY_TEAM_TITLE }} */}Equipo</h1>
        <p className="text-sm text-text-muted">
          {/* {{ COPY_TEAM_SUBTITLE }} */}Gestioná los miembros e invitaciones de {org.name}.
        </p>
      </header>

      {/* Miembros */}
      <section className="space-y-3" aria-labelledby="members-heading">
        <h2 id="members-heading" className="text-lg font-medium text-text">
          Miembros
        </h2>
        <MembersList
          organizationId={org.id}
          members={members}
          callerRole={callerRole}
          callerUserId={user.id}
        />
      </section>

      {/* Invitar + pendientes — sólo owner/admin */}
      {canManage && (
        <>
          <section className="space-y-3" aria-labelledby="invite-heading">
            <h2 id="invite-heading" className="text-lg font-medium text-text">
              {/* {{ COPY_INVITE_HEADING }} */}Invitar a alguien
            </h2>
            <Card variant="form" className="p-6">
              <InviteMemberForm organizationId={org.id} />
            </Card>
          </section>

          <section className="space-y-3" aria-labelledby="pending-heading">
            <h2 id="pending-heading" className="text-lg font-medium text-text">
              Invitaciones pendientes
            </h2>
            <PendingInvitations organizationId={org.id} invitations={invitations} />
          </section>
        </>
      )}

      {/* OrgSettings inline — sólo owner. Renombrar + ZONA PELIGROSA (transferir / borrar, R14). */}
      {isOwner && (
        <section className="space-y-3" aria-labelledby="org-settings-heading">
          <h2 id="org-settings-heading" className="text-lg font-medium text-text">
            Configuración de la organización
          </h2>

          {/* Renombrar — no destructivo, form directo. */}
          <Card variant="default" className="p-6">
            <form action={renameOrganization} className="space-y-4">
              <input type="hidden" name="organization_id" value={org.id} />
              <Input
                name="name"
                type="text"
                label="Nombre de la organización"
                defaultValue={org.name}
                required
                minLength={1}
                maxLength={120}
              />
              <Button type="submit" variant="primary" size="md">
                {/* {{ COPY_RENAME_ORG_CTA }} */}Guardar nombre
              </Button>
            </form>
          </Card>

          {/* ZONA PELIGROSA — R14: cada acción exige escribir un texto exacto; la server action lo valida. */}
          <Card variant="default" className="border-danger p-6 space-y-6">
            <div className="space-y-1">
              <h3 className="text-base font-semibold text-danger">Zona peligrosa</h3>
              <p className="text-sm text-text-muted">
                Estas acciones son irreversibles. Confirmá escribiendo el texto exacto que se te pide.
              </p>
            </div>

            {/* Transferir propiedad — escribir el NOMBRE de la org. */}
            <form action={transferOwnership} className="space-y-3">
              <input type="hidden" name="organization_id" value={org.id} />
              <Input
                name="new_owner_email"
                type="email"
                label="Email del nuevo owner (ya debe ser miembro)"
                placeholder="colega@dominio.com"
                required
                maxLength={254}
              />
              <Input
                name="confirm_name"
                type="text"
                label={`Para confirmar, escribí el nombre de la org: ${org.name}`}
                placeholder={org.name}
                required
                autoComplete="off"
              />
              <Button type="submit" variant="secondary" size="md">
                {/* {{ COPY_TRANSFER_OWNERSHIP_CTA }} */}Transferir propiedad
              </Button>
            </form>

            {/* Borrar org — escribir el SLUG. */}
            <form action={deleteOrganization} className="space-y-3">
              <input type="hidden" name="organization_id" value={org.id} />
              <Input
                name="confirm_slug"
                type="text"
                label={`Para borrar, escribí el slug de la org: ${org.slug}`}
                placeholder={org.slug}
                required
                autoComplete="off"
              />
              <Button type="submit" variant="danger" size="md">
                {/* {{ COPY_DELETE_ORG_CTA }} */}Borrar organización
              </Button>
            </form>
          </Card>
        </section>
      )}
    </main>
  );
}
