// Auth page check-email confirmation. R10 enforced (texto + Card).
// Cita: [memory:CONSTRAINTS.md#R10] [docs:nextjs]
import Link from 'next/link';
import { Card } from '@/shared/components/ui/Card/Card';

export default function CheckEmailPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-section-md">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6 text-center">
        <h1 className="text-2xl font-semibold">{/* {{ COPY_CHECK_EMAIL_TITLE }} */}Revisá tu email</h1>
        <p className="text-sm text-text-muted">
          {/* {{ COPY_CHECK_EMAIL_BODY }} */}
          Te mandamos un link de confirmación. Apretalo para terminar el registro.
        </p>
        <Link href="/sign-in" className="text-primary hover:underline">
          Volver a iniciar sesión
        </Link>
      </Card>
    </main>
  );
}
