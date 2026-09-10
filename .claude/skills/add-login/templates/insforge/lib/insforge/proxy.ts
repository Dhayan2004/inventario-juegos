// Insforge session refresh helper invoked by Next.js 16 proxy.ts.
//
// Cita: [docs:insforge] [docs:nextjs]
import { createServerClient } from '@insforge/sdk';
import { NextResponse, type NextRequest } from 'next/server';

const PROTECTED_PREFIX = '/dashboard';
const AUTH_PREFIXES = ['/sign-in', '/sign-up', '/forgot', '/update-password', '/check-email'];

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const insforge = createServerClient(
    process.env.NEXT_PUBLIC_INSFORGE_URL!,
    process.env.NEXT_PUBLIC_INSFORGE_PUBLIC_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (toSet) => {
          toSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({ request });
          toSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await insforge.auth.getUser();

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
