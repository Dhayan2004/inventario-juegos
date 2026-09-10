// SignupForm — client component. R10 enforced.
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-003]
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui/Button/Button';
import { Input } from '@/shared/components/ui/Input/Input';
import { signup } from '@/actions/auth';
import { GoogleSignInButton } from './GoogleSignInButton';
import { AuthDivider } from './AuthDivider';

export function SignupForm() {
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    const result = await signup(formData);
    if (result?.error) {
      setError(result.error);
      setPending(false);
    }
  }

  return (
    <div className="space-y-6">
      <GoogleSignInButton label="Registrarse con Google" />
      <AuthDivider />

      <form action={handleSubmit} className="space-y-4">
        <Input
          name="email"
          type="email"
          label="Email"
          placeholder="hola@dominio.com"
          required
          autoComplete="email"
        />
        <Input
          name="password"
          type="password"
          label="Contraseña"
          required
          autoComplete="new-password"
          minLength={8}
          maxLength={128}
          hint="Mínimo 8 caracteres"
        />

        {error && (
          <p role="alert" className="text-sm text-danger">
            {error}
          </p>
        )}

        <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
          {pending ? 'Creando cuenta…' : /* {{ COPY_SIGN_UP_CTA }} */ 'Crear cuenta'}
        </Button>
      </form>
    </div>
  );
}
