// Browser Supabase client. Uses anon key (public, safe to expose).
// NEVER import service_role here — anon key only.
//
// Cita: [docs:supabase-ssr] [memory:CONSTRAINTS.md#R10]
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
