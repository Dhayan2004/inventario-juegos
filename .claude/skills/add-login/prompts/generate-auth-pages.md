# Generate Auth Pages — 4 pages with R10 enforcement

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("nextjs") → query-docs
   query: "App Router 16 Server Actions form action prop"
2. resolve-library-id("react") → query-docs
   query: "useActionState use client server action"
```

**Razón:** Server Actions API y form action shape han evolucionado en Next.js 16. Sin find-docs, código generado puede usar shapes pre-15.

## R10 enforcement — input check

Antes de generar las pages, leer:
- `brand/brand.json` → tokens.colors, archetype, tagline
- `brand/voice.json` → cta_examples, hooks, avoid_words

Validar:
- `src/shared/components/ui/Button/Button.tsx` exists (impeccable output)
- `src/shared/components/ui/Input/Input.tsx` exists
- `src/shared/components/ui/Form/Form.tsx` exists OR Form pattern declared en `src/shared/components/ui/index.ts`
- `src/shared/components/ui/Card/Card.tsx` exists (para wrapper)

Si alguno falta → halt + handoff a impeccable Mode C (init core component set).

## 4 auth pages a generar

| Page | Path | Layout component |
|------|------|------------------|
| Sign-in | `src/app/(auth)/sign-in/page.tsx` | `<AuthCard variant="form">` (Card del impeccable output) |
| Sign-up | `src/app/(auth)/sign-up/page.tsx` | mismo |
| Forgot password | `src/app/(auth)/forgot/page.tsx` | mismo |
| Update password | `src/app/(auth)/update-password/page.tsx` | mismo |

Plus 1 page bridging:
- Check email | `src/app/(auth)/check-email/page.tsx` | minimalista, sin form

## Anatomy de una page (R10)

```tsx
// src/app/(auth)/sign-in/page.tsx
//
// Auth page sign-in. R10 enforced — consume Brand DNA (brand.json + voice.json)
// vía componentes generados por impeccable (Button, Input, Card, Form).
// NO Tailwind defaults: bg-blue-500, text-gray-700, rounded-3xl.
//
// Cita:
// - [memory:CONSTRAINTS.md#R10] — Brand DNA contract no negociable.
// - [memory:lessons#L-003] — email/password validators con whitelist (en actions/auth.ts).
// - [docs:nextjs] — App Router Server Actions form action.
import Link from 'next/link';
import { Button } from '@/shared/components/ui/Button/Button';
import { Input } from '@/shared/components/ui/Input/Input';
import { Card } from '@/shared/components/ui/Card/Card';
import { LoginForm } from '@/features/auth/components/LoginForm';

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4">
      <Card variant="form" className="w-full max-w-md p-8">
        <header className="space-y-2 text-center">
          {/* Title viene de voice-aligned copy substitution */}
          <h1 className="text-2xl font-semibold">{/* {{ COPY_SIGN_IN_TITLE }} */}</h1>
          <p className="text-sm text-text-muted">{/* {{ COPY_SIGN_IN_SUBTITLE }} */}</p>
        </header>

        <LoginForm />

        <p className="text-center text-sm text-text-muted">
          ¿No tenés cuenta?{' '}
          <Link href="/sign-up" className="text-primary hover:underline">
            Crear cuenta
          </Link>
        </p>
      </Card>
    </main>
  );
}
```

Notas:
- `Button`, `Input`, `Card` vienen de impeccable output. NO duplicar styling.
- `text-primary`, `text-text-muted` son tokens del brand.css (output de add-ui-kit).
- `LoginForm` es un client component que llama a server actions de `actions/auth.ts`.

## LoginForm anatomy (R10 + L-003)

```tsx
// src/features/auth/components/LoginForm.tsx
//
// Client component. R10 enforced — usa Button + Input de impeccable.
// L-003 enforced en validation: email whitelist regex + password length bounded.
//
// Cita:
// - [memory:CONSTRAINTS.md#R10]
// - [memory:lessons#L-003]
'use client';

import { useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { Button } from '@/shared/components/ui/Button/Button';
import { Input } from '@/shared/components/ui/Input/Input';
import { login } from '@/actions/auth';
import { GoogleSignInButton } from './GoogleSignInButton';
import { AuthDivider } from './AuthDivider';

export function LoginForm() {
  const searchParams = useSearchParams();
  const oauthError = searchParams.get('error');
  const [error, setError] = useState<string | null>(
    oauthError === 'auth_callback_failed'
      ? 'Error al iniciar sesión con Google. Intentá de nuevo.'
      : null,
  );
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);

    const result = await login(formData);

    if (result?.error) {
      setError(result.error);
      setPending(false);
    }
    // success: action does redirect, we don't return here
  }

  return (
    <div className="space-y-6">
      <GoogleSignInButton label="Continuar con Google" />
      <AuthDivider />

      <form action={handleSubmit} className="space-y-4">
        <Input
          name="email"
          type="email"
          label="Email"
          placeholder="hola@dominio.com"
          required
          autoComplete="email"
        />
        <Input
          name="password"
          type="password"
          label="Contraseña"
          required
          autoComplete="current-password"
          minLength={8}
          maxLength={128}
        />

        {error && (
          <p role="alert" className="text-sm text-danger">
            {error}
          </p>
        )}

        <Button type="submit" variant="primary" size="lg" className="w-full" disabled={pending}>
          {/* {{ COPY_SIGN_IN_CTA }} */}
        </Button>

        <p className="text-center text-sm">
          <Link href="/forgot" className="text-primary hover:underline">
            ¿Olvidaste tu contraseña?
          </Link>
        </p>
      </form>
    </div>
  );
}
```

Notas R10:
- `<Input label="...">` no `<input className="...">`. impeccable controla el styling.
- `<Button variant="primary">` no `<button className="bg-blue-600">`. cva variants resuelven a tokens.
- `text-danger` es token (brand.json.tokens.colors.danger → CSS var).
- `role="alert"` para a11y (universal_rules R-005 3.2).

## Anti-Slop Gate per page

Post-generación, validar cada page:

```
✓ NO `bg-(blue|gray|purple|indigo|violet)-\d+` Tailwind classes
✓ NO `rounded-3xl` (geometry breaker para TECH UTILITY archetype)
✓ NO `shadow-2xl`
✓ NO hex literals en TSX body
✓ NO `from-` `to-` `via-` (gradients sin justificar)
✓ All form inputs son <Input> (de impeccable), NO <input>
✓ All buttons son <Button> (de impeccable), NO <button>
✓ Each page has <h1> + <main> (semantic)
```

Si algún check falla → regenerate. Max 3 intentos.

## Brand Score per page (≥75 threshold)

Misma rúbrica que impeccable:

| Pillar | Weight | Check |
|--------|--------|-------|
| accessibility | 30 | role=alert, focus-visible, label associations, autoComplete, minLength |
| token_compliance | 25 | tokens del brand.css, NO hex inline, NO Tailwind defaults |
| component_compliance | 20 | usa impeccable components (Button, Input, Card) |
| anti_slop | 15 | pasa los 8 checks arriba |
| voice_and_archetype | 10 | copy alineada con voice.cta_examples + cero avoid_words |

Score < 75 → regenerate.

## Output

5 archivos generados:
- `src/app/(auth)/sign-in/page.tsx`
- `src/app/(auth)/sign-up/page.tsx`
- `src/app/(auth)/forgot/page.tsx`
- `src/app/(auth)/update-password/page.tsx`
- `src/app/(auth)/check-email/page.tsx`

Plus 4 form components (client):
- `src/features/auth/components/LoginForm.tsx`
- `src/features/auth/components/SignupForm.tsx`
- `src/features/auth/components/ForgotPasswordForm.tsx`
- `src/features/auth/components/UpdatePasswordForm.tsx`

Plus 2 shared:
- `src/features/auth/components/GoogleSignInButton.tsx`
- `src/features/auth/components/AuthDivider.tsx`

Plus 1 barrel:
- `src/features/auth/components/index.ts`

## Citations

- [memory:CONSTRAINTS.md#R10]
- [memory:CONSTRAINTS.md#R13]
- [memory:lessons#L-003]
- [docs:nextjs] · [docs:react]
