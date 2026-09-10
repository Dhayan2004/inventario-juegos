// UpdatePasswordForm — client component. R10 enforced.
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-003]
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui/Button/Button';
import { Input } from '@/shared/components/ui/Input/Input';
import { updatePassword } from '@/actions/auth';

export function UpdatePasswordForm() {
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    const result = await updatePassword(formData);
    if (result?.error) {
      setError(result.error);
      setPending(false);
    }
  }

  return (
    <form action={handleSubmit} className="space-y-4">
      <Input
        name="password"
        type="password"
        label="Nueva contraseña"
        required
        autoComplete="new-password"
        minLength={8}
        maxLength={128}
      />

      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}

      <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
        {pending ? 'Actualizando…' : 'Actualizar contraseña'}
      </Button>
    </form>
  );
}
