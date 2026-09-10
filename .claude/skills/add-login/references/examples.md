# add-login Examples — completos por modo

> Dos casos: (1) Forge (Tech Spec implicit, Supabase default) y (2) un proyecto ficticio "Saga" que eligió Insforge por baas decision.

## Example 1 — Mode A (Supabase default)

### Input

- Tech Spec: ausente o silencioso sobre BaaS → fallback Supabase.
- Brand DNA: `brand/brand.json` con `brand.product = "Forge"`, archetype Creator+Sage.
- voice.json con `cta_examples: ["Si te sirve, compártelo.", "Pruébalo en tu próximo proyecto y avísame.", "Forge it."]`
- impeccable Mode C ya corrió → 11 components en `src/shared/components/ui/`.

### Comando del usuario

> "Agregame login completo. Que pueda entrar con Google y email/password."

### Flow

1. PREFLIGHT: 7 gates. Pasa todos.
2. baas decision: ausente → fallback Supabase con flag `assumed_default = true`. Loggear en TECH-SPEC handoff (sugerir al usuario crear Tech Spec si va a continuar).
3. find-docs (R13):
   - resolve-library-id("supabase-ssr") → `/supabase/auth-helpers-nextjs` o `/supabase/ssr`
   - resolve-library-id("supabase-js") → `/supabase/supabase-js`
   - resolve-library-id("nextjs") → `/vercel/next.js`
   - Confirma getAll/setAll shape; confirma proxy.ts en Next.js 16.
4. R10 read brand.json + voice.json. Audit copy contra avoid_words.
5. Substitute templates → src/:
   - `lib/supabase/{client,server,proxy}.ts`
   - `proxy.ts` root
   - 5 pages en `app/(auth)/`
   - 6 components en `features/auth/components/`
   - 3 routes en `app/api/auth/`
   - `actions/auth.ts` con whitelist validators
   - `hooks/useAuth.ts`
   - `types/database.ts`
   - `supabase/migrations/<TS>_profiles.sql`
6. Append .env.local placeholders.
7. Security pre-handoff scan: 0 hits en grep de service_role en client.
8. Output handoff a el-guardian con checklist.

### Output preview (sign-in page)

```tsx
// src/app/(auth)/sign-in/page.tsx
//
// Auth page sign-in. R10 enforced — consume Brand DNA del proyecto Forge.
// [memory:CONSTRAINTS.md#R10] [docs:nextjs]

import Link from 'next/link';
import { Card } from '@/shared/components/ui/Card/Card';
import { LoginForm } from '@/features/auth/components/LoginForm';

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4">
      <Card variant="form" className="w-full max-w-md p-8 space-y-6">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold">Bienvenido de vuelta a Forge</h1>
          <p className="text-sm text-text-muted">Entrá a tu cuenta</p>
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

### Brand Score esperado

| Page | tokens | components | a11y | anti-slop | voice | TOTAL |
|------|--------|-----------|------|-----------|-------|-------|
| sign-in | 25 | 20 | 28 | 15 | 9 | 97 |
| sign-up | 25 | 20 | 28 | 15 | 9 | 97 |
| forgot | 25 | 20 | 27 | 15 | 8 | 95 |
| update-password | 25 | 20 | 27 | 15 | 8 | 95 |

Threshold 75 / actual 95+ → PASS holgado.

### Security pre-handoff esperado

- ✅ service_role NOT in app/ ni features/
- ✅ RLS enabled + 2 policies + handle_new_user trigger en SQL
- ✅ deleteAccount route con typed-confirmation gate (no execute)
- ✅ callback con safeNext + ALLOWED_NEXT_PATHS

## Example 2 — Mode B (Insforge)

### Input

- Tech Spec con sección "BaaS Decision" = Insforge (rationale: self-hosted Coolify + AI multi-provider failover).
- Brand DNA: `brand.product = "Saga"`, archetype Magician+Sage (controlled tension Outlaw).
- voice.json con `cta_examples: ["Empezá tu saga.", "Inscribite acá."]`
- impeccable corrió con preset Editorial Monocle.

### Comando del usuario

> "Agregame auth con Insforge."

### Flow paralelo

1. PREFLIGHT igual.
2. baas decision: Insforge documentado → Mode B.
3. find-docs (R13):
   - resolve-library-id("insforge")
   - resolve-library-id("nextjs")
4. R10 read brand.json + voice.json.
5. Substitute templates desde `templates/insforge/` → src/:
   - `lib/insforge/{client,server,proxy,schema}.ts`
   - Pages mismas, imports apuntan a `lib/insforge/*`
   - actions/auth.ts adaptado al SDK Insforge
6. NO SQL migration. `npx insforge schema push` para aplicar `lib/insforge/schema.ts`.
7. Security pre-handoff scan: 0 hits en grep de INSFORGE_SECRET_KEY en client.
8. Output handoff a el-guardian.

### Brand Score esperado

Mismo orden de magnitud. La diferencia es backend, no UI.

### Security pre-handoff esperado

- ✅ INSFORGE_SECRET_KEY NOT in app/ ni features/
- ✅ schema.ts con access policies (`auth.uid() == id` en select/insert/update; delete: false)
- ✅ deleteAccount con typed confirmation
- ✅ callback con safeNext

## Citations

- [memory:CONSTRAINTS.md#R10]
- [memory:CONSTRAINTS.md#R13]
- [memory:CONSTRAINTS.md#R14]
- [memory:lessons#L-001]
- [memory:skills#baas]
- [docs:supabase-ssr] · [docs:insforge] · [docs:nextjs]
