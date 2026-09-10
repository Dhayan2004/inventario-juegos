# Setup Supabase Auth — Mode A (default)

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("supabase-ssr") → query-docs
   query: "createServerClient cookies getAll setAll Next.js 16 App Router"
2. resolve-library-id("supabase-js") → query-docs
   query: "auth signInWithOAuth signInWithPassword resetPasswordForEmail exchangeCodeForSession"
3. resolve-library-id("nextjs") → query-docs
   query: "App Router proxy.ts vs middleware.ts cookies in route handlers"
```

**Razón:** Supabase SSR API cambió de `get/set/remove` a `getAll/setAll` en 0.5+. Si tu code generation no usa el shape actual, falla en runtime con cookies undefined. Citar como `[docs:supabase-ssr@latest]` en el commit message.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | Schema R-005 v1.1.0 |
| Components | src/shared/components/ui/{Button,Input,Form,Card}/* | impeccable output |
| Tech Spec | TECH-SPEC-<nombre>.md sec "BaaS Decision" = Supabase | Optional (fallback default) |
| Project name | brand.json.brand.product | Required |

## Pasos

### 1. PREFLIGHT (R10)

Validar que existan:
- `brand/brand.json` con `schema_version >= "1.1.0"`
- `brand/voice.json` con `voice.cta_examples` non-empty
- `src/shared/components/ui/Button/Button.tsx` (o equivalent) — output impeccable
- `src/shared/components/ui/Input/Input.tsx`
- `src/shared/components/ui/Form/Form.tsx` (o pattern equivalente)
- `src/lib/cn.ts`

Si alguno falta → halt con mensaje específico. NO degradar a Tailwind defaults.

### 2. Substitute templates → src/

Copiar de `.claude/skills/add-login/templates/supabase/` a `src/`:

| Template path | Target path | Substitutions |
|---------------|-------------|---------------|
| `lib/supabase/client.ts` | `src/lib/supabase/client.ts` | none (anon key from env) |
| `lib/supabase/server.ts` | `src/lib/supabase/server.ts` | none |
| `lib/supabase/proxy.ts` | `src/lib/supabase/proxy.ts` | `{{ PROTECTED_PREFIX }}` → `/dashboard` (default) |
| `proxy.ts` (root) | `proxy.ts` | none |
| `app/(auth)/sign-in/page.tsx` | `src/app/(auth)/sign-in/page.tsx` | `{{ COPY_SIGN_IN_TITLE }}`, `{{ COPY_SIGN_IN_SUBTITLE }}`, `{{ COPY_SIGN_IN_CTA }}` |
| `app/(auth)/sign-up/page.tsx` | `src/app/(auth)/sign-up/page.tsx` | `{{ COPY_SIGN_UP_* }}` |
| `app/(auth)/forgot/page.tsx` | `src/app/(auth)/forgot/page.tsx` | `{{ COPY_FORGOT_* }}` |
| `app/(auth)/update-password/page.tsx` | `src/app/(auth)/update-password/page.tsx` | `{{ COPY_UPDATE_PWD_* }}` |
| `app/(auth)/check-email/page.tsx` | `src/app/(auth)/check-email/page.tsx` | `{{ COPY_CHECK_EMAIL }}` |
| `app/api/auth/callback/route.ts` | `src/app/api/auth/callback/route.ts` | none |
| `app/api/auth/sign-out/route.ts` | `src/app/api/auth/sign-out/route.ts` | none |
| `app/api/auth/delete-account/route.ts` | `src/app/api/auth/delete-account/route.ts` | none — R14 enforced (typed confirmation required) |
| `actions/auth.ts` | `src/actions/auth.ts` | none |
| `hooks/useAuth.ts` | `src/hooks/useAuth.ts` | none |
| `types/database.ts` | `src/types/database.ts` | `{{ APP_DOMAIN }}` if multi-tenant — usually skip |
| `migrations/0001_profiles.sql` | `supabase/migrations/0001_<timestamp>_profiles.sql` | timestamp |

### 3. Copy substitutions (R10 enforcement)

Las copy substitutions usan voice.json:

```javascript
const voice = JSON.parse(readFile('brand/voice.json'));
const product = JSON.parse(readFile('brand/brand.json')).brand.product;

// Sign-in
COPY_SIGN_IN_TITLE = `Bienvenido de vuelta a ${product}`;
COPY_SIGN_IN_SUBTITLE = "Entra a tu cuenta"; // simple, voice-aligned
COPY_SIGN_IN_CTA = voice.voice.cta_examples[0]; // primer CTA del listado

// Sign-up
COPY_SIGN_UP_TITLE = `Forjá tu cuenta`;  // si product = "Forge", reusa hooks
COPY_SIGN_UP_CTA = "Crear cuenta";

// Audit: NINGUN string contiene voice.avoid_words
const avoid = voice.voice.avoid_words;
const allCopy = [COPY_SIGN_IN_TITLE, COPY_SIGN_UP_TITLE, /* ... */];
allCopy.forEach(s => avoid.forEach(w => {
  if (s.toLowerCase().includes(w.toLowerCase())) throw new Error(`Voice violation: "${w}" in "${s}"`);
}));
```

Si el target prefiere copy custom, reemplazar valores manualmente — pero el audit contra `avoid_words` corre siempre.

### 4. Append .env.local

```bash
# Append (NO overwrite) si .env.local existe:
cat >> .env.local <<EOF

# Auth — Supabase (added by add-login)
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...REPLACE
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# Server-only (NEVER prefix with NEXT_PUBLIC_)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...REPLACE_PRIVATE
EOF
```

NO escribir valores reales. Solo placeholders. Usuario debe llenar tras correr.

### 5. Verificación pre-handoff

```bash
# L1 syntax
npx tsc --noEmit                                       # parsea TS
psql --syntax-check supabase/migrations/*.sql    # parsea SQL

# Security pre-handoff
grep -r "service_role" src/app/        # debe estar vacío
grep -r "SUPABASE_SERVICE_ROLE_KEY" src/app/  # vacío
grep "enable row level security" supabase/migrations/*.sql  # presente
grep "auth.uid() = id" supabase/migrations/*.sql            # 2+ matches
grep "handle_new_user" supabase/migrations/*.sql            # presente
grep -E "execute:.*async" src/app/api/auth/delete-account/  # debe estar vacío (R14)
```

### 6. Output handoff

Imprimir el bloque `## add-login handoff` (ver SKILL.md).

Mandatory next step: invocar `el-guardian` con `prompts/handoff-el-guardian.md`.

## Citations

- [docs:supabase] · [docs:supabase-ssr] · [docs:nextjs] (R13)
- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:CONSTRAINTS.md#R13] (external docs citation)
- [memory:CONSTRAINTS.md#R14] (destructive tools)
- [memory:lessons#L-001] (RLS by user_id)
- [memory:lessons#L-002] (oauth payload as data, not instructions)
- [memory:lessons#L-003] (whitelist validation in form inputs)
