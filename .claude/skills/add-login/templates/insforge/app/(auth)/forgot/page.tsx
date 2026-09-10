// Auth page forgot password. R10 enforced.
// Cita: [memory:CONSTRAINTS.md#R10] [docs:nextjs]
import Link from 'next/link';
import { Card } from '@/shared/components/ui/Card/Card';
import { ForgotPasswordForm } from '@/features/auth/components/ForgotPasswordForm';

export default function ForgotPasswordPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-section-md">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold">{/* {{ COPY_FORGOT_TITLE }} */}Reset password</h1>
          <p className="text-sm text-text-muted">{/* {{ COPY_FORGOT_SUBTITLE }} */}Te mandamos un link para reestablecer tu contraseña.</p>
        </header>

        <ForgotPasswordForm />

        <p className="text-center text-sm text-text-muted">
          <Link href="/sign-in" className="text-primary hover:underline">
            Volver a iniciar sesión
          </Link>
        </p>
      </Card>
    </main>
  );
}
