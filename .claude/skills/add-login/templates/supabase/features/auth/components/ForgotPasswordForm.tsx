// ForgotPasswordForm — client component. R10 enforced.
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-003]
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui/Button/Button';
import { Input } from '@/shared/components/ui/Input/Input';
import { resetPassword } from '@/actions/auth';

export function ForgotPasswordForm() {
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    const result = await resetPassword(formData);
    if (result?.error) {
      setError(result.error);
      setPending(false);
    } else {
      setSuccess(true);
      setPending(false);
    }
  }

  if (success) {
    return (
      <p role="status" className="text-center text-sm text-success">
        Listo. Si el email existe, te llega el link para reestablecer la contraseña.
      </p>
    );
  }

  return (
    <form action={handleSubmit} className="space-y-4">
      <Input
        name="email"
        type="email"
        label="Email"
        placeholder="hola@dominio.com"
        required
        autoComplete="email"
      />

      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}

      <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
        {pending ? 'Enviando…' : 'Mandar link de reset'}
      </Button>
    </form>
  );
}
