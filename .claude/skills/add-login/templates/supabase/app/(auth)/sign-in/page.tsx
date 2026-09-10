// Auth page sign-in. R10 enforced — consume Brand DNA via impeccable
// components (Card, Button, Input). NO Tailwind defaults.
//
// Cita: [memory:CONSTRAINTS.md#R10] [docs:nextjs]
import Link from 'next/link';
import { Card } from '@/shared/components/ui/Card/Card';
import { LoginForm } from '@/features/auth/components/LoginForm';

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-section-md">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold">{/* {{ COPY_SIGN_IN_TITLE }} */}Bienvenido de vuelta</h1>
          <p className="text-sm text-text-muted">{/* {{ COPY_SIGN_IN_SUBTITLE }} */}Entrá a tu cuenta</p>
        </header>

        <LoginForm />

        <p className="text-center text-sm text-text-muted">
          ¿No tenés cuenta?{' '}
          <Link href="/sign-up" className="text-primary hover:underline">
            Crear cuenta
          </Link>
        </p>
      </Card>
    </main>
  );
}
