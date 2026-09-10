// Server Supabase client. Uses anon key + cookies for session.
// service_role allowed only via separate file (see admin.ts) when needed,
// never in this default client.
//
// getAll / setAll shape required by @supabase/ssr 0.5+ in Next.js 15+
// because cookies() is async.
//
// Cita: [docs:supabase-ssr] [docs:nextjs]
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // setAll falla en Server Components (read-only context).
            // La session se actualiza en el siguiente proxy/middleware run.
          }
        },
      },
    },
  );
}
