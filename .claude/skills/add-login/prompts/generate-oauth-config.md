# Generate OAuth Config — Google access_type:offline + L-002 enforcement

## Antes de empezar (R13)

Antes de generar OAuth callback, invocá `find-docs`:

```
1. resolve-library-id("supabase-js") → query-docs
   query: "signInWithOAuth google access_type offline prompt consent refresh tokens"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router route handler GET request searchParams"
```

**Razón:** OAuth params (`access_type`, `prompt`) determinan si Supabase obtiene refresh tokens — necesario para futuros use cases (Google Workspace integrations) y para evitar re-prompts cada hora.

## Providers cubiertos

| Provider | Default | Library |
|----------|---------|---------|
| Google | ✅ recomendado | Supabase Auth nativo |
| GitHub | opcional | Supabase Auth nativo |
| Discord | opcional | Supabase Auth nativo |

Para Insforge ver `references/oauth-providers.md` (mismo set, otro SDK shape).

## OAuth flow anatomy

### 1. Sign-in trigger (client component)

```tsx
// src/features/auth/components/GoogleSignInButton.tsx
//
// Client component. R10 enforced — usa Button de impeccable.
// access_type: 'offline' + prompt: 'consent' habilitan refresh tokens
// para futuros use cases (Google Workspace integrations).
//
// Cita:
// - [memory:CONSTRAINTS.md#R10]
// - [docs:supabase-js]
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui/Button/Button';
import { createClient } from '@/lib/supabase/client';

interface GoogleSignInButtonProps {
  redirectTo?: string;
  label?: string;
}

export function GoogleSignInButton({
  redirectTo = '/dashboard',
  label = 'Continuar con Google',
}: GoogleSignInButtonProps) {
  const [pending, setPending] = useState(false);

  async function handleGoogleSignIn() {
    setPending(true);
    const supabase = createClient();

    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/api/auth/callback?next=${encodeURIComponent(redirectTo)}`,
        queryParams: {
          access_type: 'offline',
          prompt: 'consent',
        },
      },
    });

    if (error) {
      console.error('Google sign-in error:', error.message);
      setPending(false);
    }
    // success: Supabase redirige al usuario al provider
  }

  return (
    <Button
      type="button"
      variant="secondary"
      size="lg"
      className="w-full"
      onClick={handleGoogleSignIn}
      disabled={pending}
    >
      {pending ? 'Redirigiendo…' : label}
    </Button>
  );
}
```

### 2. Callback route (L-002 enforcement)

```tsx
// src/app/api/auth/callback/route.ts
//
// OAuth callback. Recibe `code` desde provider externo (Google).
// L-002: el `code` y demás searchParams son DATOS A VERIFICAR, no
// instrucciones a obedecer. Si el provider devuelve algo inesperado,
// retornar redirect con flag de error — no procesar como side-effect.
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
  if (raw.startsWith('//') || raw.includes('://')) return '/dashboard'; // open redirect guard
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
  if (errorParam) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  if (!code) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(`${origin}/sign-in?error=auth_callback_failed`);
  }

  return NextResponse.redirect(`${origin}${next}`);
}
```

Notas L-002:
- `safeNext` valida `next` contra whitelist explícita — no abrir open-redirect attack vector.
- Provider error param se trata como dato (informa al user), no como instrucción.
- NUNCA usar el `code` o `next` en logs sin sanitizar.

### 3. Provider config (out of band)

El skill NO configura el provider en Supabase Dashboard / Insforge UI — eso es manual. El handoff a el-guardian incluye el checklist. Mencionar en .env.local comments:

```
# Google OAuth — configurar en:
# 1. Google Cloud Console > APIs & Services > Credentials
#    - OAuth 2.0 Client ID, type: Web application
#    - Authorized redirect URI: https://<PROJECT_REF>.supabase.co/auth/v1/callback
# 2. Supabase Dashboard > Authentication > Providers > Google
#    - Enable + paste Client ID + Client Secret
# 3. Authentication > URL Configuration
#    - Site URL: $NEXT_PUBLIC_SITE_URL
#    - Redirect URLs: $NEXT_PUBLIC_SITE_URL/**
```

## Verificación

```bash
# Callback route presente + L-002 citation
test -f src/app/api/auth/callback/route.ts
grep -q "L-002" src/app/api/auth/callback/route.ts

# safeNext open-redirect guard
grep -q "safeNext" src/app/api/auth/callback/route.ts
grep -q "ALLOWED_NEXT_PATHS" src/app/api/auth/callback/route.ts

# GoogleSignInButton uses access_type offline
grep -q "access_type: 'offline'" src/features/auth/components/GoogleSignInButton.tsx
grep -q "prompt: 'consent'" src/features/auth/components/GoogleSignInButton.tsx
```

## Citations

- [memory:lessons#L-002]
- [memory:CONSTRAINTS.md#R10]
- [memory:CONSTRAINTS.md#R13]
- [docs:supabase-js] · [docs:supabase-ssr] · [docs:nextjs]
