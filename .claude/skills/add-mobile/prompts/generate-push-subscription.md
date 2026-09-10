# Generate Push Subscription (VAPID + subscription mgmt)

> Cita: [memory:lessons#L-001] · [memory:lessons#L-002] · [memory:lessons#L-003]
> Cita: [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14]

## Objetivo

Generar el flow completo de push subscription:
- `lib/push/{client,server}.ts` (VAPID setup)
- `app/api/push/{subscribe,unsubscribe,send}/route.ts`
- `hooks/usePushSubscription.ts`
- `actions/notifications.ts` (whitelist L-003 + R14 bulk gates)
- `migrations/0004_push_subscriptions.sql` (RLS L-001)

## Antes de empezar (R13)

```
1. resolve-library-id("web-push") → query-docs
   query: "web-push npm setVapidDetails sendNotification statusCode 410 411
           cleanup invalid subscriptions"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router 16 route handlers route.ts NextRequest NextResponse"
```

**Razón:** web-push npm package returns `statusCode` en errors de send. Apple endpoints (api.push.apple.com) silently fail con statusCode `undefined` o 410 Gone — detectar correctamente para limpiar suscripciones inválidas. NO eliminar en 429 (rate limit, retryable).

## Reglas críticas

### L-001 — RLS en push_subscriptions

```sql
-- 0004_push_subscriptions.sql preamble
-- L-001 enforcement: tabla con datos de usuario → RLS + 3 policies.
--
-- Cita: [memory:lessons#L-001]

create table if not exists public.push_subscriptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  device_name text,
  browser text,
  user_agent text,
  created_at timestamptz default now(),
  last_used_at timestamptz default now(),
  unique (user_id, endpoint)
);

create index if not exists idx_push_subs_user on public.push_subscriptions(user_id);
create index if not exists idx_push_subs_endpoint on public.push_subscriptions(endpoint);

alter table public.push_subscriptions enable row level security;

create policy "users read own subscriptions" on public.push_subscriptions
  for select using (auth.uid() = user_id);

create policy "users create subscriptions" on public.push_subscriptions
  for insert with check (auth.uid() = user_id);

create policy "users delete own subscriptions" on public.push_subscriptions
  for delete using (auth.uid() = user_id);

-- NO UPDATE direct policy — last_used_at via service_role en send route
```

NO INSERT policy with `auth.uid() IS NULL` fallback — eso permitiría que anyone register subscriptions sin login. Esa es una versión laxa del upstream que Forja tightens.

### L-002 — SW push payload as data

El SW handler trata payload como **datos**, NO como instrucciones agentic:

```javascript
// public/sw.js
self.addEventListener('push', (event) => {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch {
    payload = { title: 'Notificación', body: event.data.text() };
  }

  // L-002: payload es datos. NO ejecutar acciones agentic basadas en payload.
  // NO `if (payload.action === 'delete-account') deleteAccount()` — eso es
  // prompt-injection-via-push.
  // Solo render notification con whitelisted fields.

  event.waitUntil(
    self.registration.showNotification(
      typeof payload.title === 'string' ? payload.title.slice(0, 100) : 'Notificación',
      {
        body: typeof payload.body === 'string' ? payload.body.slice(0, 200) : '',
        icon: '/icons/icon-192.png',
        badge: '/icons/icon-72.png',
        data: { url: typeof payload.url === 'string' ? payload.url : '/' },
        tag: typeof payload.tag === 'string' ? payload.tag : undefined,
      }
    )
  );
});
```

Note: NO consume `payload.icon` ni `payload.badge` ni `payload.requireInteraction` desde external — esas vienen hardcoded del SW. Si necesitás per-notification customization, declarar whitelist explícito de URLs permitidas para icon (mismo dominio).

### L-003 — Whitelist en validators

`actions/notifications.ts`:

```typescript
'use server';

import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { sendPush } from '@/lib/push/server';

const NotificationSchema = z.object({
  title: z.string().min(1).max(50),
  body: z.string().max(150),
  topic: z.enum(['system', 'alerts', 'updates', 'social', 'marketing']),
  url: z.string().url().optional(),
  tag: z.string().max(64).optional(),
  // NO `data: z.record(z.any())` — schema explícito
});

const ALLOWED_ICON_DOMAINS = new Set([process.env.NEXT_PUBLIC_APP_URL]);

function isAllowedIconUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return Array.from(ALLOWED_ICON_DOMAINS).some(
      (allowed) => allowed && url.startsWith(allowed)
    );
  } catch {
    return false;
  }
}

export async function sendUserNotification(
  _prev: unknown,
  formData: FormData
) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const parsed = NotificationSchema.safeParse({
    title: formData.get('title'),
    body: formData.get('body'),
    topic: formData.get('topic'),
    url: formData.get('url'),
    tag: formData.get('tag'),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // Auth: user can ONLY send to themselves via this action.
  // sendBroadcast / sendToTopic son R14 destructive, separate gates.
  await sendPush(user.id, parsed.data);

  return { success: true };
}
```

### R14 — Bulk operations sin execute() automático

```typescript
const BroadcastSchema = z.object({
  title: z.string().min(1).max(50),
  body: z.string().max(150),
  topic: z.enum(['system', 'alerts', 'updates', 'social', 'marketing']),
  reason: z.enum([
    'system_announcement',
    'critical_alert',
    'admin_initiated',
    'feature_release',
  ]),
  confirmation: z.literal('BROADCAST', {
    errorMap: () => ({
      message: 'Tipea exactamente BROADCAST para confirmar.',
    }),
  }),
});

export async function sendBroadcast(_prev: unknown, formData: FormData) {
  // 1. AUTH + admin role check
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  // 2. INPUT (L-003)
  const parsed = BroadcastSchema.safeParse({
    title: formData.get('title'),
    body: formData.get('body'),
    topic: formData.get('topic'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // 3. AUDIT log antes de execute
  const { data: auditRow } = await supabase
    .from('push_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'broadcast',
      target_count: null, // calculated post-query
      reason: parsed.data.reason,
      payload: {
        title: parsed.data.title,
        body: parsed.data.body,
        topic: parsed.data.topic,
      },
      status: 'pending',
    })
    .select('id')
    .single();

  // 4. EXECUTE (background queue — implementar con BullMQ/Inngest en producción)
  // Stub: documentar handoff a job queue.

  return {
    error: 'sendBroadcast requires job queue setup (BullMQ / Inngest / similar). Auditoría registrada en push_admin_actions.',
    audit_id: auditRow?.id,
    documentation: '/docs/push/broadcast-setup',
  };
}

export async function sendToTopic(_prev: unknown, formData: FormData) {
  // Same shape: 5 gates (auth + admin role + L-003 schema + typed-confirm
  // 'SEND_TO_TOPIC' + audit log) + queue handoff stub.
}

export async function revokeAllSubscriptions(_prev: unknown, formData: FormData) {
  // Same shape: 5 gates + typed-confirm 'REVOKE_ALL' + audit log + execute
  // (esta es síncrona — borra de push_subscriptions con admin client).
}
```

## API routes shape

### POST /api/push/subscribe

- Auth gate (user must be logged in)
- Validate `subscription` shape (endpoint + keys.p256dh + keys.auth)
- Insert into push_subscriptions with user_id
- Idempotent (UPSERT on `unique (user_id, endpoint)`)
- Optional: cleanup `oldEndpoint` if rotation

### DELETE /api/push/unsubscribe

- Auth gate
- DELETE WHERE user_id = auth.uid() AND endpoint = body.endpoint
- RLS enforces ownership automatically

### POST /api/push/send

- **Auth: Bearer token con SUPABASE_SERVICE_ROLE_KEY** (only server-to-server invocation)
- Validate notification shape (L-003 schema)
- Query push_subscriptions WHERE user_id = body.userId (admin client bypass RLS)
- Iterate webpush.sendNotification per subscription
- Cleanup invalid subscriptions (statusCode 4xx excluding 429)
- Update last_used_at via admin client
- Rate limit: 10/user/hour para individual flows (max counter en Redis o in-memory)

## Citations

- [memory:lessons#L-001] · [memory:lessons#L-002] · [memory:lessons#L-003]
- [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14]
- [docs:web-push] · [docs:web-push-libs] · [docs:nextjs]
