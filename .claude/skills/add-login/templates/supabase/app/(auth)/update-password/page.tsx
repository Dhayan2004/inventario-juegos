// Auth page update password (post password-reset link click). R10 enforced.
// Cita: [memory:CONSTRAINTS.md#R10] [docs:nextjs]
import { Card } from '@/shared/components/ui/Card/Card';
import { UpdatePasswordForm } from '@/features/auth/components/UpdatePasswordForm';

export default function UpdatePasswordPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-section-md">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold">{/* {{ COPY_UPDATE_PWD_TITLE }} */}Nueva contraseña</h1>
          <p className="text-sm text-text-muted">{/* {{ COPY_UPDATE_PWD_SUBTITLE }} */}Ingresá la nueva contraseña abajo.</p>
        </header>

        <UpdatePasswordForm />
      </Card>
    </main>
  );
}
