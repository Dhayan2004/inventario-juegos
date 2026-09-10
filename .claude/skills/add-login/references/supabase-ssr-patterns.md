# Supabase SSR Patterns — getAll/setAll, NEVER get/set/remove

> Reference para el shape correcto de `@supabase/ssr` en Next.js 16 App Router.
> Cita `[docs:supabase-ssr]` cuando se use.

## La regla

`@supabase/ssr` 0.5+ requiere **siempre** `getAll()` + `setAll()` en el cookies handler. El shape `get/set/remove` (pre-0.5) está **deprecated** y rompe en Next.js 15+ porque las APIs de cookies son async.

## Shape correcto

### Server client (Route Handlers + Server Actions + Server Components)

```typescript
// src/lib/supabase/server.ts
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
            // Esto es esperado: la session se actualiza en el siguiente
            // proxy/middleware run.
          }
        },
      },
    },
  );
}
```

### Browser client (Client Components)

```typescript
// src/lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
```

### Proxy / Middleware (cookies refresh per request)

```typescript
// src/lib/supabase/proxy.ts (Next.js 16) o middleware.ts (legacy)
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

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

  // CRÍTICO: getUser (no getSession) en server. getSession() lee del JWT
  // sin validar contra el server, getUser() valida.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Rutas protegidas
  const isProtectedRoute = request.nextUrl.pathname.startsWith('/dashboard');
  const isAuthRoute =
    request.nextUrl.pathname.startsWith('/sign-in') ||
    request.nextUrl.pathname.startsWith('/sign-up');

  if (isProtectedRoute && !user) {
    return NextResponse.redirect(new URL('/sign-in', request.url));
  }
  if (isAuthRoute && user) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return supabaseResponse;
}
```

## Anti-patterns (NUNCA generar)

```typescript
// ❌ NO — shape pre-0.5
cookies: {
  get(name) { return cookieStore.get(name)?.value; },
  set(name, value, options) { cookieStore.set({ name, value, ...options }); },
  remove(name, options) { cookieStore.set({ name, value: '', ...options }); },
}
// Causa: en Next.js 15+ cookies() es async; este shape rompe.

// ❌ NO — getSession en server
const { data: { session } } = await supabase.auth.getSession();
// Causa: getSession lee del JWT sin validar; vulnerable a tampering.

// ❌ NO — service_role key en createBrowserClient
createBrowserClient(URL, SERVICE_ROLE_KEY) // sec_breach
```

## Quick-check (post-generación)

```bash
SERVER=src/lib/supabase/server.ts
CLIENT=src/lib/supabase/client.ts
PROXY=src/lib/supabase/proxy.ts

grep -q "getAll\\|setAll" $SERVER || echo "FAIL: server client uses old shape"
grep -q "getAll\\|setAll" $PROXY || echo "FAIL: proxy uses old shape"
grep -q "createBrowserClient" $CLIENT || echo "FAIL: client should use createBrowserClient"
grep "supabase.auth.getUser" $PROXY || echo "FAIL: proxy should use getUser, not getSession"
grep "service_role\\|SERVICE_ROLE" $CLIENT && echo "FAIL: client should NOT import service_role"
```

## Citations

- [docs:supabase-ssr] (canonical: getAll/setAll shape)
- [docs:supabase-js] (auth.getUser vs auth.getSession)
- [docs:nextjs] (cookies API async in 15+)
