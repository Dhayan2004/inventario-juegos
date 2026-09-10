/**
 * /install — Install PWA flow page.
 *
 * R10 enforced: usa InstallPromptUI que consume impeccable Card + Button.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
import type { Metadata } from 'next';
import { InstallPromptUI } from '@/components/InstallPromptUI';

export const metadata: Metadata = {
  title: 'Instalar app',
  description: 'Instalá la app en tu pantalla de inicio para acceso rápido.',
};

export default function InstallPage() {
  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <InstallPromptUI />
    </main>
  );
}
