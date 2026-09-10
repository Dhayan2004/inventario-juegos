// Sign-out route. POST-only para evitar CSRF accidental via GET prefetch.
//
// NOTE — global sign-out (todas las sesiones del user) requiere
// supabase.auth.admin.signOut con service_role. Esa operación es destructiva
// (R14) y debe gatear con typed confirmation desde UI antes de invocarse.
// Este endpoint solo cierra la session actual.
//
// Cita: [docs:supabase-ssr] [memory:CONSTRAINTS.md#R14]
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: Request) {
  const supabase = await createClient();
  const { origin } = new URL(request.url);

  await supabase.auth.signOut();

  return NextResponse.redirect(`${origin}/sign-in`, { status: 303 });
}
