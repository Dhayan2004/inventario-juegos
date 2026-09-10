// Server Insforge client. Public key + cookies for session refresh.
// secret_key vive en lib/insforge/admin.ts (server-only).
//
// Cita: [docs:insforge] [docs:nextjs]
import { createServerClient } from '@insforge/sdk';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_INSFORGE_URL!,
    process.env.NEXT_PUBLIC_INSFORGE_PUBLIC_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (toSet) => {
          try {
            toSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            /* read-only context, OK */
          }
        },
      },
    },
  );
}
