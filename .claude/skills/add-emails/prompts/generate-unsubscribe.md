# Generate Unsubscribe — RFC 8058 + R14 bulk gate

## Antes de empezar (R13)

```
1. resolve-library-id("nextjs") → query-docs
   query: "App Router GET handler RFC 8058 List-Unsubscribe-Post
           One-Click headers"
2. resolve-library-id("resend") OR resolve-library-id("sendgrid-mail") → query-docs
   query: "unsubscribe groups suppression list manage individual subscription"
```

**Razón:** Gmail/Yahoo 2024 mandate (effective Feb 2024): senders >5K emails/day requieren `List-Unsubscribe: <https://...>` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click` headers. NO honoring esto → emails van a spam folder. Cita `[docs:rfc8058]`.

## Two endpoints

### 1. GET /api/email/unsubscribe?token=XXX (one-click)

Triggered desde el header `List-Unsubscribe-Post: List-Unsubscribe=One-Click` que Gmail/Yahoo procesan. NO requires user authentication — el token JWT-signed en la URL es la auth.

```typescript
/**
 * GET /api/email/unsubscribe?token=<jwt>
 *
 * RFC 8058 One-Click Unsubscribe handler.
 * NO auth — el token es signed JWT con email + user_id + scope.
 *
 * Cita: [docs:rfc8058] · [memory:lessons#L-002] · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { jwtVerify } from 'jose';
import { createAdminClient } from '@/lib/supabase/admin';

const UnsubTokenPayload = z.object({
  email: z.string().email(),
  user_id: z.string().uuid(),
  scope: z.enum(['marketing', 'product_updates', 'all']),
  iat: z.number(),
  exp: z.number(),
});

export async function GET(request: NextRequest) {
  const token = request.nextUrl.searchParams.get('token');
  if (!token) {
    return NextResponse.redirect(new URL('/unsubscribed?error=missing_token', request.url));
  }

  // L-002: token está firmado pero el contenido es user-controlled (vía email link).
  // Validación shape antes de query.
  let payload;
  try {
    const secret = new TextEncoder().encode(process.env.UNSUBSCRIBE_JWT_SECRET);
    const { payload: jwt } = await jwtVerify(token, secret);
    payload = UnsubTokenPayload.parse(jwt);
  } catch {
    return NextResponse.redirect(new URL('/unsubscribed?error=invalid_token', request.url));
  }

  // L-003: scope is z.enum, NO z.string libre
  const supabase = createAdminClient();

  // Single-row update — RLS bypass via service_role
  await supabase
    .from('email_subscriptions')
    .upsert(
      {
        user_id: payload.user_id,
        scope: payload.scope,
        unsubscribed_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,scope' }
    );

  return NextResponse.redirect(new URL('/unsubscribed', request.url));
}

/**
 * POST /api/email/unsubscribe?token=XXX
 *
 * RFC 8058 mandates same handler para POST con body
 * `List-Unsubscribe=One-Click`. Idéntico a GET.
 */
export async function POST(request: NextRequest) {
  return GET(request);
}
```

### 2. Token generation (server-side helper)

```typescript
// src/lib/email/unsubscribe-token.ts
import { SignJWT } from 'jose';

export async function generateUnsubscribeToken(
  email: string,
  user_id: string,
  scope: 'marketing' | 'product_updates' | 'all' = 'all'
): Promise<string> {
  const secret = new TextEncoder().encode(process.env.UNSUBSCRIBE_JWT_SECRET);
  return new SignJWT({ email, user_id, scope })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('30d')
    .sign(secret);
}
```

Y en `lib/{resend,sendgrid}/server.ts`, al llamar `send`, agregar headers:

```typescript
// Resend
await resend.emails.send({
  from: EMAIL_FROM,
  to: [recipient],
  subject: '...',
  react: <WelcomeEmail {...props} />,
  headers: {
    'List-Unsubscribe': `<${process.env.NEXT_PUBLIC_APP_URL}/api/email/unsubscribe?token=${token}>`,
    'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
  },
});
```

## R14 strict — bulk operations

**Cualquier operación que modifica la suppression de N>1 users** es destructive y requiere los 5 R14 gates documentados en [memory:CONSTRAINTS.md#R14] + add-payments precedent (refund-flow.md):

### `bulkUnsubscribe` — DESTRUCTIVE

```typescript
'use server';

const BulkUnsubscribeSchema = z.object({
  user_ids: z.array(z.string().uuid()).min(1).max(10000),
  scope: z.enum(['marketing', 'product_updates', 'all']),
  confirmation: z.literal('BULK_UNSUBSCRIBE', {
    errorMap: () => ({ message: 'Tipea exactamente BULK_UNSUBSCRIBE para confirmar.' }),
  }),
  reason: z.enum(['admin_compliance', 'data_subject_request', 'spam_complaint_batch']),
});

export async function bulkUnsubscribe(_prev: unknown, formData: FormData) {
  // 1. AUTH — solo admin (verificar role)
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  // 2. INPUT (L-003)
  const userIds = formData.getAll('user_ids') as string[];
  const parsed = BulkUnsubscribeSchema.safeParse({
    user_ids: userIds,
    scope: formData.get('scope'),
    confirmation: formData.get('confirmation'),
    reason: formData.get('reason'),
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  // 3. AUDIT log antes de execute
  const { data: auditRow, error: logErr } = await supabase
    .from('email_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'bulk_unsubscribe',
      target_user_ids: parsed.data.user_ids,
      reason: parsed.data.reason,
      status: 'pending',
    })
    .select()
    .single();
  if (logErr) return { error: 'Error registrando.' };

  // 4. EXECUTE
  try {
    await createAdminClient()
      .from('email_subscriptions')
      .upsert(
        parsed.data.user_ids.map(uid => ({
          user_id: uid,
          scope: parsed.data.scope,
          unsubscribed_at: new Date().toISOString(),
        })),
        { onConflict: 'user_id,scope' }
      );

    await supabase
      .from('email_admin_actions')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', auditRow.id);

    return { success: true, count: parsed.data.user_ids.length };
  } catch (err) {
    await supabase
      .from('email_admin_actions')
      .update({ status: 'failed', error_message: String(err) })
      .eq('id', auditRow.id);
    return { error: 'Error procesando.' };
  }
}
```

### `deleteSuppressionEntry` — DESTRUCTIVE (re-enables sending)

Re-habilita envío a un email previamente suppressed (bounce/complaint). **Especialmente sensible** — si un email tuvo hard bounce, re-enabling puede causar IP reputation damage. Mismos 5 gates + audit log.

```typescript
const DeleteSuppressionSchema = z.object({
  email: z.string().email(),
  confirmation: z.literal('DELETE_SUPPRESSION'),
  reason: z.enum(['user_complaint_resolved', 'address_corrected', 'admin_override']),
});
```

### `resendCampaign` — DESTRUCTIVE (re-send a N users)

Mismos 5 gates. NO export con `execute()` automático.

## Verificación post-gen

```bash
# RFC 8058 headers en send
grep -q "List-Unsubscribe" src/lib/{resend,sendgrid}/server.ts
grep -q "One-Click" src/lib/{resend,sendgrid}/server.ts

# Token generation
test -f src/lib/email/unsubscribe-token.ts
grep -q "SignJWT\|jwtVerify" src/lib/email/unsubscribe-token.ts

# Endpoint GET + POST
grep -q "export async function GET" src/app/api/email/unsubscribe/route.ts
grep -q "export async function POST" src/app/api/email/unsubscribe/route.ts

# R14 — bulk operations sin execute()
! grep -E "^export.*tool\(.*execute.*async.*(bulkUnsubscribe|deleteSuppressionEntry|resendCampaign)" src/actions/email.ts

# Typed confirmations
grep -E "z\.literal\('(BULK_UNSUBSCRIBE|DELETE_SUPPRESSION|RESEND_CAMPAIGN)'" src/actions/email.ts

# Audit table existe
grep -q "email_admin_actions" supabase/migrations/*email_subscriptions.sql
```

## Refusals

- ❌ Endpoint /api/email/unsubscribe que requiera login. Token-based ONLY (RFC 8058).
- ❌ Token sin expiry. 30d max recommended.
- ❌ Skip POST handler. RFC 8058 mandates GET + POST con same shape.
- ❌ `bulkUnsubscribe` / `deleteSuppressionEntry` / `resendCampaign` con `tool({ execute })`.
- ❌ Skip role check (admin-only) en bulk operations.
- ❌ Skip audit log row antes de execute.

## Citations

- [docs:rfc8058] (Gmail/Yahoo 2024 One-Click Unsubscribe mandate)
- [docs:nextjs] (R13)
- [memory:CONSTRAINTS.md#R14] (bulk operations sin execute)
- [memory:lessons#L-002] (token contenido as data)
- [memory:lessons#L-003] (whitelist scope + reason)
