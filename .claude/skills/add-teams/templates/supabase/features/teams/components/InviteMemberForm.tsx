// InviteMemberForm — client component. R10 enforced: Button + Input + Select (vía RoleSelect) de impeccable.
//
// Sólo owner/admin ven este formulario (gating del consumidor). La autoridad real la enforce
// Postgres: la policy "invitations create" exige owner/admin de la org y el check de tabla
// prohíbe role='owner' (teams-model.md §2). El backing action (inviteMember) valida con Zod
// whitelist: email + role ∈ {admin, member} (L-003). NUNCA se invita como owner.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-003] [memory:references#R-005]
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui';
import { Input } from '@/shared/components/ui';
import { inviteMember } from '@/actions/teams';
import { RoleSelect } from './RoleSelect';

export interface InviteMemberFormProps {
  organizationId: string;
}

export function InviteMemberForm({ organizationId }: InviteMemberFormProps) {
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    setSuccess(false);
    const result = await inviteMember(formData);
    if (result?.error) {
      setError(result.error);
      setPending(false);
    } else {
      setSuccess(true);
      setPending(false);
    }
  }

  return (
    <form action={handleSubmit} className="space-y-4">
      {/* organization_id viaja como hidden, pero RLS lo revalida contra la membresía real (R16 inv. 3) */}
      <input type="hidden" name="organization_id" value={organizationId} />

      <Input
        name="email"
        type="email"
        label="Email"
        placeholder="colega@dominio.com"
        required
        autoComplete="off"
        maxLength={254}
      />

      <RoleSelect name="role" label="Rol" defaultValue="member" required />

      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      {success && (
        <p role="status" className="text-sm text-success">
          {/* {{ COPY_INVITE_SENT }} */}Invitación enviada. Le mandamos un link para unirse.
        </p>
      )}

      <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
        {pending ? 'Enviando…' : /* {{ COPY_INVITE_CTA }} */ 'Enviar invitación'}
      </Button>
    </form>
  );
}
