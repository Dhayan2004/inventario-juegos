// MembersList — tabla de miembros con rol. R10 enforced: Card/Button/Select de impeccable.
//
// Gating por rol (teams-model.md §1): un 'member' NO ve acciones de admin (cambiar rol, expulsar).
// Un 'admin' NO puede tocar a un 'owner' (la fila del owner no expone acciones para un admin).
// La UI sólo REFLEJA la autoridad — la frontera real es Postgres (RLS + WITH CHECK + guard_last_owner).
//
// R14 (destructivas → confirmación tipada, sin execute() automático):
//   - updateMemberRole y removeMember corren TRAS confirmación explícita en UI (ConfirmModal).
//     No se exponen como agentic tools con execute(). Patrón de add-login deleteAccount.
//   - 'owner' NUNCA aparece como opción asignable (RoleSelect lo garantiza); el ascenso a owner
//     va por transferOwnership (OrgSettings), no por aquí.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:CONSTRAINTS.md#R14] [memory:lessons#L-003] [memory:references#R-005]
'use client';

import { useState } from 'react';
import { Card } from '@/shared/components/ui';
import { Button } from '@/shared/components/ui';
import { ConfirmModal } from '@/shared/components/ui';
import { updateMemberRole, removeMember } from '@/actions/teams';
import { RoleSelect, type AssignableRole } from './RoleSelect';

export type MemberRole = 'owner' | 'admin' | 'member';

export interface TeamMember {
  id: string; // membership id
  userId: string;
  email: string;
  name: string | null;
  role: MemberRole;
}

export interface MembersListProps {
  organizationId: string;
  members: TeamMember[];
  /** Rol del usuario que está viendo la lista — decide qué acciones se muestran. */
  callerRole: MemberRole;
  /** userId del caller — para no ofrecerse acciones sobre uno mismo. */
  callerUserId: string;
}

const ROLE_LABELS: Record<MemberRole, string> = {
  owner: 'Owner',
  admin: 'Admin',
  member: 'Miembro',
};

export function MembersList({ organizationId, members, callerRole, callerUserId }: MembersListProps) {
  // Sólo owner/admin pueden gestionar; un member sólo lee.
  const canManage = callerRole === 'owner' || callerRole === 'admin';

  // Estado de la acción destructiva pendiente de confirmación (R14).
  const [removeTarget, setRemoveTarget] = useState<TeamMember | null>(null);
  const [pendingId, setPendingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // ¿El caller puede tocar a este miembro? Un admin no puede tocar a un owner (teams-model.md §3.2),
  // y nadie se ofrece acciones sobre sí mismo desde esta tabla.
  function canActOn(member: TeamMember): boolean {
    if (!canManage) return false;
    if (member.userId === callerUserId) return false;
    if (member.role === 'owner') return callerRole === 'owner';
    return true;
  }

  async function handleRoleChange(member: TeamMember, nextRole: AssignableRole) {
    if (nextRole === member.role) return;
    setError(null);
    setPendingId(member.id);
    const formData = new FormData();
    formData.set('organization_id', organizationId);
    formData.set('membership_id', member.id);
    formData.set('role', nextRole);
    const result = await updateMemberRole(formData);
    if (result?.error) {
      setError(result.error);
    }
    setPendingId(null);
  }

  async function handleRemoveConfirmed() {
    if (!removeTarget) return;
    setError(null);
    setPendingId(removeTarget.id);
    const formData = new FormData();
    formData.set('organization_id', organizationId);
    formData.set('membership_id', removeTarget.id);
    const result = await removeMember(formData);
    setPendingId(null);
    if (result?.error) {
      setError(result.error);
    } else {
      setRemoveTarget(null);
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
              Miembro
            </th>
            <th scope="col" className="px-4 py-2 text-left font-mono text-xs uppercase tracking-widest text-text-subtle">
              Rol
            </th>
            {canManage && (
              <th scope="col" className="px-4 py-2 text-right font-mono text-xs uppercase tracking-widest text-text-subtle">
                Acciones
              </th>
            )}
          </tr>
        </thead>
        <tbody>
          {members.map((member) => {
            const actionable = canActOn(member);
            const isSelf = member.userId === callerUserId;
            const busy = pendingId === member.id;
            return (
              <tr key={member.id} className="border-t border-border">
                <td className="px-4 py-3 text-text">
                  <div className="font-medium">{member.name ?? member.email}</div>
                  {member.name && <div className="text-xs text-text-muted">{member.email}</div>}
                  {isSelf && <span className="text-xs text-text-subtle">(tú)</span>}
                </td>
                <td className="px-4 py-3">
                  {/* owner es de SOLO LECTURA aquí: nunca se reasigna a/desde owner por esta tabla. */}
                  {actionable && member.role !== 'owner' ? (
                    <RoleSelect
                      label=""
                      value={member.role as AssignableRole}
                      disabled={busy}
                      onChange={(nextRole) => handleRoleChange(member, nextRole)}
                    />
                  ) : (
                    <span className="text-text-muted">{ROLE_LABELS[member.role]}</span>
                  )}
                </td>
                {canManage && (
                  <td className="px-4 py-3 text-right">
                    {actionable && (
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        disabled={busy}
                        onClick={() => setRemoveTarget(member)}
                      >
                        {/* {{ COPY_REMOVE_MEMBER_CTA }} */}Expulsar
                      </Button>
                    )}
                  </td>
                )}
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* R14: expulsar es destructivo → confirmación explícita antes de ejecutar. */}
      <ConfirmModal
        open={removeTarget !== null}
        onOpenChange={(open) => {
          if (!open) setRemoveTarget(null);
        }}
        title="Expulsar miembro"
        description={
          removeTarget
            ? `${removeTarget.name ?? removeTarget.email} perderá acceso a la organización. Esta acción no se puede deshacer.`
            : undefined
        }
        confirmLabel="Expulsar"
        cancelLabel="Cancelar"
        destructive
        isLoading={pendingId !== null && pendingId === removeTarget?.id}
        onConfirm={handleRemoveConfirmed}
      />
    </Card>
  );
}
