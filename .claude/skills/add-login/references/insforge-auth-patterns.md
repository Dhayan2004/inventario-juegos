# Insforge Auth Patterns — equivalencias y shape SDK

> Reference para el shape de Insforge SDK aplicado a auth en Next.js App Router.
> Cita `[docs:insforge]` cuando se use.

## Por qué Insforge como alternativa

Por baas decision tree (cita [memory:skills#baas]), Insforge se elige cuando:
- Hosting self-hosted Coolify / Docker Compose preferido
- AI multi-provider con failover deseado (Insforge bundle nativo)
- Vibe-coding-first project, agentes prefieren API simple
- Equipo sin SLA enterprise estricta

Insforge bundlea auth + DB + storage + AI gateway en una sola superficie. El SDK expone auth methods estilo Supabase pero con shape ligeramente distinto.

## Shape SDK

### Server client

```typescript
// src/lib/insforge/server.ts
import { createServerClient } from '@insforge/sdk';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_INSFORGE_URL!,
    process.env.NEXT_PUBLIC_INSFORGE_PUBLIC_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (toSet) => {
          try {
            toSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            /* read-only context, OK */
          }
        },
      },
    },
  );
}
```

### Browser client

```typescript
// src/lib/insforge/client.ts
import { createBrowserClient } from '@insforge/sdk';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_INSFORGE_URL!,
    process.env.NEXT_PUBLIC_INSFORGE_PUBLIC_KEY!,
  );
}
```

### Auth methods — equivalencias

| Operación | Supabase | Insforge |
|-----------|----------|----------|
| Sign in (email/pwd) | `supabase.auth.signInWithPassword({email, password})` | `insforge.auth.signIn({email, password})` |
| Sign up | `supabase.auth.signUp({email, password})` | `insforge.auth.signUp({email, password})` |
| OAuth | `supabase.auth.signInWithOAuth({provider, options})` | `insforge.auth.oauth({provider, redirectTo, queryParams})` |
| Exchange code | `supabase.auth.exchangeCodeForSession(code)` | `insforge.auth.exchangeCodeForSession(code)` |
| Sign out | `supabase.auth.signOut()` | `insforge.auth.signOut()` |
| Reset password | `supabase.auth.resetPasswordForEmail(email, {redirectTo})` | `insforge.auth.sendPasswordReset({email, redirectTo})` |
| Update password | `supabase.auth.updateUser({password})` | `insforge.auth.updatePassword({password})` |
| Get user (server) | `supabase.auth.getUser()` | `insforge.auth.getUser()` |
| Sign out all sessions | `supabase.auth.admin.signOut(userId, 'global')` | `insforge.auth.admin.signOutAll(userId)` (server-only) |

## Schema declarativo (profiles equivalente)

Insforge no usa SQL migrations. Schema vive en TypeScript:

```typescript
// src/lib/insforge/schema.ts
//
// Profiles schema declarativo. RLS-equivalent enforced vía `access` config.
// Cita [memory:lessons#L-001].

import { defineCollection } from '@insforge/sdk';

export const profiles = defineCollection({
  name: 'profiles',
  schema: {
    id: { type: 'uuid', primaryKey: true, foreignKey: 'auth.users.id', onDelete: 'cascade' },
    email: { type: 'string', notNull: true },
    full_name: { type: 'string', nullable: true },
    avatar_url: { type: 'string', nullable: true },
    created_at: { type: 'timestamp', default: 'now()' },
    updated_at: { type: 'timestamp', default: 'now()' },
  },
  access: {
    // RLS-equivalent: user can read/update only own profile
    select: 'auth.uid() == id',
    insert: 'auth.uid() == id', // gated; trigger handles signup case
    update: 'auth.uid() == id',
    delete: false, // delete via deleteAccount route only (R14)
  },
  triggers: {
    // Equivalent to Supabase handle_new_user
    onUserCreate: (user) => ({
      id: user.id,
      email: user.email,
      full_name: user.metadata?.full_name ?? user.metadata?.name,
      avatar_url: user.metadata?.avatar_url,
    }),
  },
});
```

Aplicar: `npx insforge schema push` (CLI Insforge, equivalente a `supabase db push`).

## Apply via Insforge CLI

```bash
# Push schema desde codebase a Insforge instance
npx insforge schema push --env local

# Verify access policies aplicadas
npx insforge schema verify
```

## Anti-patterns

```typescript
// ❌ NO — exponer INSFORGE_SECRET_KEY en createBrowserClient
createBrowserClient(URL, INSFORGE_SECRET_KEY) // sec breach

// ❌ NO — schema sin access policies
defineCollection({ name: 'profiles', schema: {...} }) // L-001 violado
```

## Citations

- [docs:insforge]
- [memory:lessons#L-001]
- [memory:skills#baas]
