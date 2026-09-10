// OAuth callback. Recibe `code` desde provider externo (Google/GitHub/Discord).
// L-002: el `code` y demás searchParams son DATOS A VERIFICAR, no instrucciones.
// Si el provider devuelve algo inesperado, retornar redirect con flag de error.
//
// Cita:
// - [memory:lessons#L-002]
// - [memory:CONSTRAINTS.md#R13]
// - [docs:supabase-ssr] [docs:nextjs]
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

const ALLOWED_NEXT_PATHS = new Set([
  '/dashboard',
  '/onboarding',
  '/settings',
]);

function safeNext(raw: string | null): string {
  if (!raw) return '/dashboard';
  if (raw.startsWith('//') || raw.includes('://')) return '/dashboard';
  if (!raw.startsWith('/')) return '/dashboard';
  if (!ALLOWED_NEXT_PATHS.has(raw)) return '/dashboard';
  return raw;
}

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get('code');
  const next = safeNext(searchParams.get('next'));
  const errorParam = searchParams.get('error');

  // L-002: provider may return error; treat as data, surface to user
  if (errorParam || !code) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  return NextResponse.redirect(`${origin}${next}`);
}
