# Generate Suppression List Webhook — L-002 enforcement

## Antes de empezar (R13)

```
Resend mode:
  resolve-library-id("resend") → query-docs
  query: "Resend.events webhook signature verification email.bounced
          email.complained event.types"

SendGrid mode:
  resolve-library-id("sendgrid") → query-docs
  query: "@sendgrid/eventwebhook EventWebhookHeader ECDSA signature
          verifySignature bounce dropped spamreport"
```

**Razón:** suppression webhooks reciben payloads externos del provider — bounces, complaints, drops, opens. Aunque verifican signature, los `email`/`reason`/`url` fields son user-controlled (usuario manipuló su email para bounce intencional, complaint via spam report manual). L-002 mandate: treat-as-data discipline. Sin find-docs, signature shape errors silenciosos.

## 6 phases canónicas (mirror add-payments webhook handler)

```
1. Read raw body (request.text())
2. Verify signature (FAIL FAST)
3. Treat-as-data (L-002 — payload fields untrusted aún post-sig)
4. Switch event.type whitelist (default: log + return)
5. Idempotency check (event.id ya procesado)
6. DB op via service_role
```

## Resend implementation

```typescript
/**
 * Resend suppression webhook.
 *
 * Cita: [memory:lessons#L-002] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:resend@latest]
 */
import { NextRequest, NextResponse } from 'next/server';
import { Webhook } from 'svix'; // Resend usa Svix para webhook signing
import { z } from 'zod';
import { createAdminClient } from '@/lib/supabase/admin';
import { RESEND_WEBHOOK_SECRET } from '@/lib/resend/server';

export const dynamic = 'force-dynamic';

// L-002: whitelist event types
const ResendEventSchema = z.object({
  type: z.enum([
    'email.sent',
    'email.delivered',
    'email.bounced',
    'email.complained',
    'email.opened',
    'email.clicked',
    'email.delivery_delayed',
  ]),
  data: z.object({
    email_id: z.string(),
    to: z.array(z.string().email()).or(z.string().email()),
    bounce: z.object({
      type: z.enum(['hard', 'soft', 'undetermined']),
      message: z.string().max(1024).optional(),
    }).optional(),
  }).passthrough(),
  created_at: z.string(),
});

export async function POST(request: NextRequest) {
  const body = await request.text();
  const headers = {
    'svix-id': request.headers.get('svix-id') ?? '',
    'svix-timestamp': request.headers.get('svix-timestamp') ?? '',
    'svix-signature': request.headers.get('svix-signature') ?? '',
  };

  let event: unknown;
  try {
    const wh = new Webhook(RESEND_WEBHOOK_SECRET);
    event = wh.verify(body, headers);
  } catch (err) {
    console.error('[Webhook] Resend signature verification failed', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }

  // L-002: validate event shape ANTES de DB ops
  const parsed = ResendEventSchema.safeParse(event);
  if (!parsed.success) {
    console.error('[Webhook] event shape invalid', parsed.error);
    return NextResponse.json({ received: true }, { status: 200 }); // 200 para evitar retry
  }

  const supabase = createAdminClient();
  const eventData = parsed.data.data;
  const recipient = Array.isArray(eventData.to) ? eventData.to[0] : eventData.to;

  // Idempotency
  const { data: existing } = await supabase
    .from('email_events')
    .select('id')
    .eq('external_event_id', eventData.email_id + '_' + parsed.data.type)
    .maybeSingle();
  if (existing) {
    return NextResponse.json({ received: true, skipped: 'duplicate' });
  }

  // Log event
  await supabase.from('email_events').insert({
    external_event_id: eventData.email_id + '_' + parsed.data.type,
    event_type: parsed.data.type,
    recipient_email: recipient,
    metadata: eventData,
    occurred_at: parsed.data.created_at,
  });

  // Update suppression list según event type
  switch (parsed.data.type) {
    case 'email.bounced':
      if (eventData.bounce?.type === 'hard') {
        await supabase.from('suppression_list').upsert(
          {
            email: recipient.toLowerCase(),
            reason: 'hard_bounce',
            suppressed_at: new Date().toISOString(),
          },
          { onConflict: 'email' }
        );
        console.log(`[Webhook] Hard bounce suppression: ${recipient}`);
      }
      break;
    case 'email.complained':
      await supabase.from('suppression_list').upsert(
        {
          email: recipient.toLowerCase(),
          reason: 'spam_complaint',
          suppressed_at: new Date().toISOString(),
        },
        { onConflict: 'email' }
      );
      console.log(`[Webhook] Spam complaint suppression: ${recipient}`);
      break;
    default:
      // No suppression action — solo log el event
      break;
  }

  return NextResponse.json({ received: true });
}
```

## SendGrid implementation

```typescript
/**
 * SendGrid suppression webhook.
 *
 * Diferencia clave vs Resend: SendGrid usa ECDSA signature
 * (no HMAC). Public key del Sender Authentication settings.
 *
 * Cita: [memory:lessons#L-002] · [docs:sendgrid]
 */
import { NextRequest, NextResponse } from 'next/server';
import { EventWebhook, EventWebhookHeader } from '@sendgrid/eventwebhook';
import { z } from 'zod';
import { createAdminClient } from '@/lib/supabase/admin';

export const dynamic = 'force-dynamic';

const SendGridEventSchema = z.array(
  z.object({
    event: z.enum([
      'processed', 'delivered', 'open', 'click',
      'bounce', 'dropped', 'spamreport', 'unsubscribe',
      'group_unsubscribe', 'group_resubscribe', 'deferred',
    ]),
    email: z.string().email(),
    timestamp: z.number(),
    sg_event_id: z.string(),
    sg_message_id: z.string(),
    type: z.enum(['hard', 'soft']).optional(), // bounces only
    reason: z.string().max(1024).optional(),
  }).passthrough()
);

export async function POST(request: NextRequest) {
  const body = await request.text();

  const sig = request.headers.get(EventWebhookHeader.SIGNATURE());
  const ts = request.headers.get(EventWebhookHeader.TIMESTAMP());
  if (!sig || !ts) {
    return NextResponse.json({ error: 'Missing signature headers' }, { status: 400 });
  }

  const ew = new EventWebhook();
  const ecPublicKey = ew.convertPublicKeyToECDSA(process.env.SENDGRID_WEBHOOK_PUBLIC_KEY!);
  const valid = ew.verifySignature(ecPublicKey, body, sig, ts);
  if (!valid) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }

  const events: unknown = JSON.parse(body);
  const parsed = SendGridEventSchema.safeParse(events);
  if (!parsed.success) {
    console.error('[Webhook] SendGrid shape invalid', parsed.error);
    return NextResponse.json({ received: true }, { status: 200 });
  }

  const supabase = createAdminClient();

  for (const event of parsed.data) {
    // Idempotency per event
    const { data: existing } = await supabase
      .from('email_events')
      .select('id')
      .eq('external_event_id', event.sg_event_id)
      .maybeSingle();
    if (existing) continue;

    await supabase.from('email_events').insert({
      external_event_id: event.sg_event_id,
      event_type: event.event,
      recipient_email: event.email,
      metadata: event,
      occurred_at: new Date(event.timestamp * 1000).toISOString(),
    });

    // Suppression actions
    if (event.event === 'bounce' && event.type === 'hard') {
      await supabase.from('suppression_list').upsert(
        { email: event.email.toLowerCase(), reason: 'hard_bounce', suppressed_at: new Date().toISOString() },
        { onConflict: 'email' }
      );
    } else if (event.event === 'spamreport') {
      await supabase.from('suppression_list').upsert(
        { email: event.email.toLowerCase(), reason: 'spam_complaint', suppressed_at: new Date().toISOString() },
        { onConflict: 'email' }
      );
    } else if (event.event === 'unsubscribe' || event.event === 'group_unsubscribe') {
      // SendGrid native unsubscribe — ya tracked por su side
      console.log(`[Webhook] Unsubscribe via SendGrid: ${event.email}`);
    }
  }

  return NextResponse.json({ received: true });
}
```

## Pre-send check (cualquier mode)

Antes de invocar `resend.emails.send` o `sgMail.send`, verificar suppression:

```typescript
// src/lib/email/suppression-check.ts
export async function isSuppressed(email: string): Promise<boolean> {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from('suppression_list')
    .select('email')
    .eq('email', email.toLowerCase())
    .maybeSingle();
  return Boolean(data);
}
```

Y en el send action:

```typescript
if (await isSuppressed(recipient)) {
  console.log(`[Email] Skipped — suppressed: ${recipient}`);
  return { skipped: true, reason: 'suppressed' };
}
```

## Verificación post-gen

```bash
# 1. Raw body antes de signature verification
grep -B2 "verify\|verifySignature" src/app/api/email/suppression-webhook/route.ts | grep -q "request.text()"

# 2. L-002 cited
grep -q "L-002" src/app/api/email/suppression-webhook/route.ts

# 3. Event whitelist via z.enum
grep -E "z\.enum\(\[.*'email\.bounced'|'bounce'" src/app/api/email/suppression-webhook/route.ts

# 4. Idempotency check
grep -q "external_event_id" src/app/api/email/suppression-webhook/route.ts

# 5. Default no-throw
grep -A2 "default:" src/app/api/email/suppression-webhook/route.ts | grep -vE "^\s*//" | grep -q "break\|return"

# 6. Pre-send check
test -f src/lib/email/suppression-check.ts
grep -q "isSuppressed" src/actions/email.ts
```

## Refusals

- ❌ Procesar event sin signature verification.
- ❌ z.string() libre en bounce reason. Whitelist enum.
- ❌ Hardcodear PUBLIC_KEY. Siempre via env.
- ❌ Skip idempotency check. Mismo event puede llegar múltiples veces.
- ❌ Default case con throw. Anti retry storm.
- ❌ Send sin pre-check de suppression list.

## Citations

- [memory:lessons#L-002] (treat-as-data en webhook payloads)
- [memory:lessons#L-003] (whitelist event types + bounce reasons)
- [memory:CONSTRAINTS.md#R13]
- [docs:resend@latest] · [docs:sendgrid] (R13)
