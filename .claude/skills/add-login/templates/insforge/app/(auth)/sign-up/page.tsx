// Auth page sign-up. R10 enforced.
// Cita: [memory:CONSTRAINTS.md#R10] [docs:nextjs]
import Link from 'next/link';
import { Card } from '@/shared/components/ui/Card/Card';
import { SignupForm } from '@/features/auth/components/SignupForm';

export default function SignUpPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-section-md">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold">{/* {{ COPY_SIGN_UP_TITLE }} */}Crear tu cuenta</h1>
          <p className="text-sm text-text-muted">{/* {{ COPY_SIGN_UP_SUBTITLE }} */}Empezá ahora</p>
        </header>

        <SignupForm />

        <p className="text-center text-sm text-text-muted">
          ¿Ya tenés cuenta?{' '}
          <Link href="/sign-in" className="text-primary hover:underline">
            Iniciar sesión
          </Link>
        </p>
      </Card>
    </main>
  );
}
