// Server-only Supabase admin client (uses service_role).
// NEVER import this file from client components or app/(auth) pages.
// Solo accesible desde:
// - app/api/auth/delete-account/route.ts (con confirmation gate, R14)
// - server actions destinadas a admin operations
//
// Cita: [memory:CONSTRAINTS.md#R14] [docs:supabase-js]
import { createClient } from '@supabase/supabase-js';

export function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    },
  );
}
