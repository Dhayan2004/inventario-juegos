// PendingInvitations — invitaciones pendientes (revocar / reenviar). R10 enforced.
//
// Sólo owner/admin ven y gestionan invitaciones (policy "invitations read"/"invitations manage").
// R14: revokeInvitation es destructivo → confirmación explícita antes de ejecutar (ConfirmModal),
// sin execute() automático. reenviar (resendInvitation) NO es destructivo → corre directo.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:CONSTRAINTS.md#R14] [memory:references#R-005]
'use client';

import { useState } from 'react';
import { Card } from '@/shared/components/ui';
import { Button } from '@/shared/components/ui';
import { ConfirmModal } from '@/shared/components/ui';
import { revokeInvitation, resendInvitation } from '@/actions/teams';

export interface PendingInvitation {
  id: string;
  email: string;
  role: 'admin' | 'member'; // nunca 'owner' — no se invita como owner
  expiresAt: string; // ISO
}

export interface PendingInvitationsProps {
  organizationId: string;
  invitations: PendingInvitation[];
}

const ROLE_LABELS: Record<PendingInvitation['role'], string> = {
  admin: 'Admin',
  member: 'Miembro',
};

export function PendingInvitations({ organizationId, invitations }: PendingInvitationsProps) {
  const [revokeTarget, setRevokeTarget] = useState<PendingInvitation | null>(null);
  const [pendingId, setPendingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  if (invitations.length === 0) {
    return (
      <Card variant="empty">
        {/* {{ COPY_NO_PENDING_INVITES }} */}No hay invitaciones pendientes.
      </Card>
    );
  }

  async function runAction(
    action: (formData: FormData) => Promise<{ error?: string } | void>,
    invitationId: string,
  ) {
    setError(null);
    setPendingId(invitationId);
    const formData = new FormData();
    formData.set('organization_id', organizationId);
    formData.set('invitation_id', invitationId);
    const result = await action(formData);
    setPendingId(null);
    return result;
  }

  async function handleResend(invitation: PendingInvitation) {
    await runAction(resendInvitation, invitation.id);
  }

  async function handleRevokeConfirmed() {
    if (!revokeTarget) return;
    const result = await runAction(revokeInvitation, revokeTarget.id);
    if (!result?.error) {
      setRevokeTarget(null);
    }
  }

  return (
    <Card variant="default" className="overflow-x-auto p-0">
      {error && (
        <p role="alert" className="px-4 pt-4 text-sm text-danger">
          {error}
        </p>
      )}

      <table role="table" className="w-full text-sm">
        <thead className="bg-surface-elevated">
          <tr>
            <th scope="col" className="px-4 py-2 text-left font-mono text-xs uppercase tracking-widest text-text-subtle">
              Email
            </th>
            <th scope="col" className="px-4 py-2 text-left font-mono text-xs uppercase tracking-widest text-text-subtle">
              Rol
            </th>
            <th scope="col" className="px-4 py-2 text-left font-mono text-xs uppercase tracking-widest text-text-subtle">
              Expira
            </th>
            <th scope="col" className="px-4 py-2 text-right font-mono text-xs uppercase tracking-widest text-text-subtle">
              Acciones
            </th>
          </tr>
        </thead>
        <tbody>
          {invitations.map((invitation) => {
            const busy = pendingId === invitation.id;
            return (
              <tr key={invitation.id} className="border-t border-border">
                <td className="px-4 py-3 text-text">{invitation.email}</td>
                <td className="px-4 py-3 text-text-muted">{ROLE_LABELS[invitation.role]}</td>
                <td className="px-4 py-3 text-text-muted">
                  {new Date(invitation.expiresAt).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-right">
                  <div className="inline-flex gap-2">
                    <Button
                      type="button"
                      variant="secondary"
                      size="sm"
                      disabled={busy}
                      onClick={() => handleResend(invitation)}
                    >
                      {/* {{ COPY_RESEND_INVITE_CTA }} */}Reenviar
                    </Button>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      disabled={busy}
                      onClick={() => setRevokeTarget(invitation)}
                    >
                      {/* {{ COPY_REVOKE_INVITE_CTA }} */}Revocar
                    </Button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* R14: revocar invalida el link de aceptación → confirmación explícita. */}
      <ConfirmModal
        open={revokeTarget !== null}
        onOpenChange={(open) => {
          if (!open) setRevokeTarget(null);
        }}
        title="Revocar invitación"
        description={
          revokeTarget
            ? `El link enviado a ${revokeTarget.email} dejará de funcionar.`
            : undefined
        }
        confirmLabel="Revocar"
        cancelLabel="Cancelar"
        destructive
        isLoading={pendingId !== null && pendingId === revokeTarget?.id}
        onConfirm={handleRevokeConfirmed}
      />
    </Card>
  );
}
