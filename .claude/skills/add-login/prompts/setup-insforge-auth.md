# Setup Insforge Auth — Mode B (alternativa)

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("insforge") → query-docs
   query: "auth signIn signUp signOut sendPasswordReset Next.js App Router cookies"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router proxy.ts vs middleware.ts cookies in route handlers"
```

**Razón:** Insforge SDK es relativamente joven; el shape de auth methods + el pattern de cookies handling para SSR pueden divergir entre versiones. Sin find-docs, runtime falla.

## Cuándo se elige Mode B

Trigger único: `baas` skill cierra con `decision = "Insforge"` documentado en TECH-SPEC-<nombre>.md sección "BaaS Decision". Razones típicas (de baas decision tree):

- Hosting self-hosted Coolify / Docker Compose preferido
- AI multi-provider con failover deseado (Insforge bundle nativo)
- Vibe-coding-first project, agentes prefieren API simple
- Equipo sin SLA enterprise estricta

Si Tech Spec NO documenta decisión → usar Mode A (Supabase default).

## Inputs requeridos

Mismo set que Mode A (Brand DNA + impeccable components + Tech Spec). Diferencia: el target ya tiene Insforge cliente configurado por `baas` (env vars `NEXT_PUBLIC_INSFORGE_URL` + key).

## Equivalencias Supabase ↔ Insforge

| Supabase | Insforge |
|----------|----------|
| `@supabase/ssr` createServerClient + cookies getAll/setAll | `@insforge/sdk` createServerClient con request/response handlers (ver references/insforge-auth-patterns.md) |
| `supabase.auth.signInWithPassword` | `insforge.auth.signIn` (email + password) |
| `supabase.auth.signUp` | `insforge.auth.signUp` |
| `supabase.auth.signInWithOAuth({provider: 'google'})` | `insforge.auth.oauth({provider: 'google'})` |
| `supabase.auth.exchangeCodeForSession(code)` | `insforge.auth.exchangeCodeForSession(code)` |
| `supabase.auth.resetPasswordForEmail` | `insforge.auth.sendPasswordReset` |
| `supabase.auth.updateUser({password})` | `insforge.auth.updatePassword(password)` |
| `supabase.auth.signOut` | `insforge.auth.signOut` |
| `supabase.auth.getUser()` (server, validated) | `insforge.auth.getUser()` (server) |
| `auth.users` table privada + public.profiles + RLS L-001 | tabla `users` Insforge expone `metadata` JSON; profiles equivalente declarado en `lib/insforge/schema.ts` con policy nativo Insforge |

## Pasos (paralelos a Mode A)

### 1. PREFLIGHT (mismo que Mode A)

Validar Brand DNA + impeccable components + .env.local writable.

Adicional: validar que `NEXT_PUBLIC_INSFORGE_URL` y la key correspondiente estén ya en `.env.local` (los puso `baas`). Si no → halt: "Falta config Insforge. Corré /baas primero."

### 2. Substitute templates → src/

Copiar de `.claude/skills/add-login/templates/insforge/` a `src/`:

| Template path | Target path |
|---------------|-------------|
| `lib/insforge/client.ts` | `src/lib/insforge/client.ts` |
| `lib/insforge/server.ts` | `src/lib/insforge/server.ts` |
| `lib/insforge/proxy.ts` | `src/lib/insforge/proxy.ts` |
| `lib/insforge/schema.ts` | `src/lib/insforge/schema.ts` (declarative profiles + RLS-equivalent) |
| `proxy.ts` (root) | `proxy.ts` (re-export con Insforge updateSession) |
| `app/(auth)/sign-in/page.tsx` | igual que Mode A pero importa de `lib/insforge/*` |
| ... resto de pages | mismas pages, server actions adaptadas |
| `app/api/auth/callback/route.ts` | con `insforge.auth.exchangeCodeForSession` |
| `app/api/auth/sign-out/route.ts` | con `insforge.auth.signOut` |
| `app/api/auth/delete-account/route.ts` | R14 enforced (mismo pattern que Mode A) |
| `actions/auth.ts` | server actions con Insforge SDK |
| `hooks/useAuth.ts` | `useAuth` hook adaptado |
| `types/database.ts` | tipos profiles equivalentes |

NO migration SQL. Insforge declara schema vía `lib/insforge/schema.ts` y aplica vía CLI Insforge (handoff equivalente al de el-migrador para Supabase, fuera del scope de este skill).

### 3. Copy substitutions (R10)

Mismo proceso que Mode A. voice.json es backend-agnostic.

### 4. .env.local update

Verificar que `baas` ya pobló:
```
NEXT_PUBLIC_INSFORGE_URL=https://your-instance.insforge.dev
NEXT_PUBLIC_INSFORGE_PUBLIC_KEY=if_pub_xxx
INSFORGE_SECRET_KEY=if_sec_xxx_PRIVATE  # server-only
```

Append solo `NEXT_PUBLIC_SITE_URL=http://localhost:3000` si no está.

### 5. Verificación pre-handoff

```bash
# L1 syntax
npx tsc --noEmit

# Security pre-handoff (Insforge)
grep -r "INSFORGE_SECRET_KEY" src/app/ src/components/      # debe estar vacío
grep -r "INSFORGE_SECRET_KEY" src/lib/insforge/server.ts          # presente
grep -E "execute:.*async" src/app/api/auth/delete-account/        # debe estar vacío (R14)

# Schema profiles
grep "profiles" src/lib/insforge/schema.ts                        # presente
grep -i "policy\|access" src/lib/insforge/schema.ts               # RLS-equivalent declarado
```

### 6. Output handoff

Mismo bloque que Mode A, con paths Insforge. Mandatory next step: el-guardian.

## Citations

- [docs:insforge] · [docs:nextjs] (R13)
- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:CONSTRAINTS.md#R14] (destructive tools)
- [memory:lessons#L-001] (RLS — Insforge RLS-equivalent declarado en schema.ts)
- [memory:lessons#L-002] (oauth payload as data)
- [memory:lessons#L-003] (whitelist validation in form inputs)
- [memory:decisions#D-007] (impeccable shadcn-customizado-default reuse)
