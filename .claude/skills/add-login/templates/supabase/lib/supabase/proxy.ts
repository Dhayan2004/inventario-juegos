// Supabase session refresh helper invoked by Next.js 16 proxy.ts (or
// middleware.ts en legacy 14-15). Refresca cookies por request, redirige
// rutas protegidas a /sign-in si no hay user, y redirige rutas auth a
// /dashboard si hay user.
//
// CRÍTICO: usa supabase.auth.getUser() (valida token contra server),
// NUNCA getSession() (lee JWT sin validar).
//
// Cita: [docs:supabase-ssr] [docs:nextjs]
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

const PROTECTED_PREFIX = '/dashboard';
const AUTH_PREFIXES = ['/sign-in', '/sign-up', '/forgot', '/update-password', '/check-email'];

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const pathname = request.nextUrl.pathname;
  const isProtected = pathname.startsWith(PROTECTED_PREFIX);
  const isAuth = AUTH_PREFIXES.some((p) => pathname.startsWith(p));
  const isCallback = pathname.startsWith('/api/auth/callback');

  if (isProtected && !user) {
    return NextResponse.redirect(new URL('/sign-in', request.url));
  }
  if (isAuth && user && !isCallback) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return supabaseResponse;
}
