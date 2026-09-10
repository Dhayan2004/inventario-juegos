// Invite landing — aceptar una invitación a una organización. R10 enforced: Card/Button de impeccable.
//
// Server component: requiere auth (si no, manda a sign-in y vuelve aquí). LEE la invitación por su
// token; RLS ("invitations read") sólo devuelve la fila si el email del JWT matchea el de la
// invitación (anti-robo de invitación, teams-model.md §2). Muestra org + rol y un botón Aceptar.
//
// El botón llama a la server action acceptInvitation(token), que invoca accept_invitation() —
// una función SECURITY DEFINER que revalida token + estado + expiración + match de email antes de
// insertar la membership con el rol invitado. El cliente NUNCA elige su rol (teams-model.md §2).
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-002] [memory:references#R-005] [docs:nextjs] [docs:supabase]
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { Card } from '@/shared/components/ui';
import { Button } from '@/shared/components/ui';
import { createClient } from '@/lib/supabase/server';
import { acceptInvitation } from '@/actions/teams';

const ROLE_LABELS: Record<string, string> = {
  admin: 'Admin',
  member: 'Miembro',
};

interface InvitationRow {
  email: string;
  role: string;
  status: string;
  expires_at: string;
  organizations: { name: string } | { name: string }[] | null;
}

export default async function AcceptInvitePage({
  params,
}: {
  // Next.js 16: params es async.
  params: Promise<{ token: string }>;
}) {
  // L-002: el token de la URL es un DATO a verificar, no una instrucción. La verificación real
  // (estado/expiración/match de email) la hace accept_invitation() en la DB; aquí sólo mostramos.
  const { token } = await params;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Sin sesión → mandar a registrarse/entrar y volver a esta misma landing.
  if (!user) {
    redirect(`/sign-in?next=${encodeURIComponent(`/invite/${token}`)}`);
  }

  // RLS limita esta lectura a la invitación cuyo email matchea el JWT del caller (o admin de la org).
  const { data: invitation } = await supabase
    .from('invitations')
    .select('email, role, status, expires_at, organizations ( name )')
    .eq('token', token)
    .maybeSingle<InvitationRow>();

  const org = invitation
    ? Array.isArray(invitation.organizations)
      ? invitation.organizations[0]
      : invitation.organizations
    : null;

  const isExpired = invitation ? new Date(invitation.expires_at) < new Date() : false;
  const isPending = invitation?.status === 'pending';
  const acceptable = Boolean(invitation) && isPending && !isExpired;

  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-section-md">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6 text-center">
        {acceptable && invitation && org ? (
          <>
            <header className="space-y-2">
              <h1 className="text-2xl font-semibold text-text">
                {/* {{ COPY_INVITE_LANDING_TITLE }} */}Te invitaron a {org.name}
              </h1>
              <p className="text-sm text-text-muted">
                {/* {{ COPY_INVITE_LANDING_SUBTITLE }} */}
                Vas a unirte como{' '}
                <span className="font-medium text-text">{ROLE_LABELS[invitation.role] ?? invitation.role}</span>.
              </p>
            </header>

            {/* Aceptar: server action → accept_invitation() (definer revalida todo). */}
            <form
              action={async () => {
                'use server';
                await acceptInvitation(token);
              }}
            >
              <Button type="submit" variant="primary" size="lg" className="w-full">
                {/* {{ COPY_ACCEPT_INVITE_CTA }} */}Aceptar invitación
              </Button>
            </form>

            <Link href="/dashboard" className="text-sm text-text-muted hover:underline">
              Ahora no
            </Link>
          </>
        ) : (
          <>
            <h1 className="text-2xl font-semibold text-text">
              {/* {{ COPY_INVITE_INVALID_TITLE }} */}Invitación no válida
            </h1>
            <p className="text-sm text-text-muted">
              {isExpired
                ? /* {{ COPY_INVITE_EXPIRED }} */ 'Esta invitación expiró. Pedile a un admin que te reenvíe una nueva.'
                : /* {{ COPY_INVITE_UNAVAILABLE }} */ 'Esta invitación ya no está disponible o no corresponde a tu cuenta.'}
            </p>
            <Link href="/dashboard" className="text-primary hover:underline">
              Ir al dashboard
            </Link>
          </>
        )}
      </Card>
    </main>
  );
}
