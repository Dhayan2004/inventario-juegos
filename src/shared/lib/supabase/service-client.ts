import "server-only";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Cliente Supabase con service role key — server-only.
 *
 * La app no tiene auth (BLUEPRINT §0, usuario único); RLS en `game` es deny-all
 * para `anon`/`authenticated` (migración 20260911061546_add_game.sql). El único
 * acceso legítimo es este cliente, que bypassa RLS por diseño de Supabase y NUNCA
 * debe importarse desde código que corre en el navegador.
 */
export function createServiceClient(): SupabaseClient {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceRoleKey) {
    throw new Error(
      "Faltan credenciales de Supabase: NEXT_PUBLIC_SUPABASE_URL y/o SUPABASE_SERVICE_ROLE_KEY."
    );
  }

  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
