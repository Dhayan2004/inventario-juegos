// OAuth callback (Insforge variant). L-002 enforced.
//
// Cita: [memory:lessons#L-002] [docs:insforge] [docs:nextjs]
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/insforge/server';

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

  if (errorParam || !code) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  const insforge = await createClient();
  const { error } = await insforge.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  return NextResponse.redirect(`${origin}${next}`);
}
