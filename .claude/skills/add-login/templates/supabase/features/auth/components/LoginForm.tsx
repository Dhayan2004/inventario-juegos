// LoginForm — client component. R10 enforced: usa Button + Input de impeccable.
// L-003: action backing (actions/auth.ts) valida con Zod whitelist.
//
// Cita: [memory:CONSTRAINTS.md#R10] [memory:lessons#L-003]
'use client';

import Link from 'next/link';
import { useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { Button } from '@/shared/components/ui/Button/Button';
import { Input } from '@/shared/components/ui/Input/Input';
import { login } from '@/actions/auth';
import { GoogleSignInButton } from './GoogleSignInButton';
import { AuthDivider } from './AuthDivider';

export function LoginForm() {
  const searchParams = useSearchParams();
  const oauthError = searchParams.get('error');
  const [error, setError] = useState<string | null>(
    oauthError === 'auth_callback_failed'
      ? 'No pudimos completar el sign-in con Google. Intentá de nuevo.'
      : null,
  );
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    const result = await login(formData);
    if (result?.error) {
      setError(result.error);
      setPending(false);
    }
  }

  return (
    <div className="space-y-6">
      <GoogleSignInButton label="Continuar con Google" />
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
          autoComplete="current-password"
          minLength={8}
          maxLength={128}
        />

        {error && (
          <p role="alert" className="text-sm text-danger">
            {error}
          </p>
        )}

        <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
          {pending ? 'Iniciando sesión…' : /* {{ COPY_SIGN_IN_CTA }} */ 'Iniciar sesión'}
        </Button>

        <p className="text-center text-sm">
          <Link href="/forgot" className="text-primary hover:underline">
            ¿Olvidaste tu contraseña?
          </Link>
        </p>
      </form>
    </div>
  );
}
