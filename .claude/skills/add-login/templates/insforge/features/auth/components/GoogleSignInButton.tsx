// GoogleSignInButton — Insforge variant. R10 enforced.
//
// Cita: [memory:CONSTRAINTS.md#R10] [docs:insforge]
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui/Button/Button';
import { createClient } from '@/lib/insforge/client';

interface GoogleSignInButtonProps {
  redirectTo?: string;
  label?: string;
}

export function GoogleSignInButton({
  redirectTo = '/dashboard',
  label = 'Continuar con Google',
}: GoogleSignInButtonProps) {
  const [pending, setPending] = useState(false);

  async function handleGoogleSignIn() {
    setPending(true);
    const insforge = createClient();

    const { error } = await insforge.auth.oauth({
      provider: 'google',
      redirectTo: `${window.location.origin}/api/auth/callback?next=${encodeURIComponent(redirectTo)}`,
      queryParams: {
        access_type: 'offline',
        prompt: 'consent',
      },
    });

    if (error) {
      console.error('Google sign-in error:', error.message);
      setPending(false);
    }
  }

  return (
    <Button
      type="button"
      variant="secondary"
      size="lg"
      className="w-full"
      onClick={handleGoogleSignIn}
      disabled={pending}
    >
      {pending ? 'Redirigiendo…' : label}
    </Button>
  );
}
