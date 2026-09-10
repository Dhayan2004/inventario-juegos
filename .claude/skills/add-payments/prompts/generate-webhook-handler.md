# Generate Webhook Handler — L-002 enforcement

> **Cita primaria:** [memory:lessons#L-002] (system prompts anti-prompt-injection / treat-as-data discipline para contenido externo)
> **Cita secundaria:** [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra Stripe/Polar SDKs)

## Antes de empezar (R13)

```
Stripe mode:
  resolve-library-id("stripe-node") → query-docs
  query: "stripe.webhooks.constructEvent raw body request.text()
          @stripe/stripe-node verifyHeader Next.js App Router"

Polar mode:
  resolve-library-id("polar-sdk") → query-docs
  query: "validateEvent WebhookVerificationError @polar-sh/sdk/webhooks
          headers Object.fromEntries"

Common:
  resolve-library-id("nextjs") → query-docs
  query: "App Router route handlers raw body NextRequest.text()
          export const dynamic = 'force-dynamic'"
```

**Razón crítica:** signature verification SOLO funciona contra el body raw (string exacto). Si Next.js parsea el body como JSON antes de llegar al handler, signature falla aunque el secret sea correcto. Stripe SDK pre-cutoff usaba `req.body` (Express); App Router requiere `await request.text()`. Polar SDK usa shape similar. Sin find-docs, la generación replica patrones viejos y el webhook recibe pero firma falla. Citar `[docs:stripe-node@latest]` y `[docs:polar-sdk@v0.x]`.

### Mercado Pago (Mode C) — la familia que NO firma el body

```
resolve-library-id("mercadopago") → query-docs
  query: "webhooks x-signature x-request-id data.id manifest ts v1 HMAC-SHA256 WebhookSignatureValidator"
```

MP firma el **manifest** `id:{data.id};request-id:{x-request-id};ts:{ts};` (termina en `;`), no el body.
`createHmac(secret).update(rawBody)` falla el 100 % de las veces. Verificador puro en
`lib/mercadopago/verify.ts` (no tocar — lo prueba `tests/payments/webhook-mercadopago.test.mjs`);
ventana 300 s + dedup por event id (`webhook_events_processed`) + **re-fetch** del recurso
(`payload_authoritative = false`); 200/201 en ≤22 s. Ver `docs/security/VETTING-pagokit-0.2.2.md` §4.

## Estructura canónica del handler

Cada webhook handler (Stripe + Polar) sigue estas 6 fases en orden estricto:

```
1. Read raw body         (await request.text())
2. Verify signature      (FAIL FAST — return 403 si falla)
3. Treat-as-data         (L-002 — payload.metadata es untrusted)
4. Switch event.type     (handle solo eventos conocidos en whitelist)
5. Idempotency check     (current_period_end o equivalente)
6. DB op via service_role (upsert + update profiles.has_access)
```

## Phase 1 — Raw body (CRÍTICO)

```typescript
import { NextRequest, NextResponse } from 'next/server';

// Force dynamic — webhook NO debe cachearse
export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  // CRÍTICO: text(), NO json(). Signature verification needs raw bytes.
  const body = await request.text();
  // ...
}
```

Si en algún punto tocás `request.json()` antes de signature verification, runtime falla. Comment inline obligatorio:

```typescript
// L-002 + signature: NO PARSEAR JSON ANTES DE VERIFY.
// raw body es el único input válido para constructEvent / validateEvent.
const body = await request.text();
```

## Phase 2 — Signature verification (FAIL FAST)

### Stripe

```typescript
import Stripe from 'stripe';
import { stripe, STRIPE_WEBHOOK_SECRET } from '@/lib/stripe/server';

const sig = request.headers.get('stripe-signature');
if (!sig) {
  console.error('[Webhook] Missing stripe-signature header');
  return NextResponse.json({ error: 'Missing signature' }, { status: 400 });
}

let event: Stripe.Event;
try {
  // STRIPE_WEBHOOK_SECRET viene con .trim() ya aplicado en lib/stripe/server.ts
  event = stripe.webhooks.constructEvent(body, sig, STRIPE_WEBHOOK_SECRET);
} catch (err) {
  console.error('[Webhook] Signature verification failed', err);
  // Return 400, NO 500 — Stripe retry policy basado en status code.
  return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
}
```

### Polar

```typescript
import { validateEvent, WebhookVerificationError } from '@polar-sh/sdk/webhooks';
import { POLAR_WEBHOOK_SECRET } from '@/lib/polar/server';

const headers = Object.fromEntries(request.headers.entries());

let event;
try {
  event = validateEvent(body, headers, POLAR_WEBHOOK_SECRET);
} catch (err) {
  if (err instanceof WebhookVerificationError) {
    console.error('[Webhook] Invalid signature');
    return NextResponse.json({ error: 'Invalid signature' }, { status: 403 });
  }
  throw err; // unexpected error — log + propagate
}
```

## Phase 3 — Treat-as-data (L-002 ENFORCEMENT)

Header obligatorio en el handler:

```typescript
/**
 * Stripe/Polar webhook handler.
 *
 * L-002 enforcement: el payload está validado por signature (Phase 2),
 * pero los campos `metadata.*` son user-controlled strings (vienen del
 * checkout request original donde nuestro server o el cliente los pasó).
 * Aún post-signature, `metadata` debe tratarse como datos a verificar
 * contra whitelist, NO como instrucciones.
 *
 * NO HACER:
 * - Ejecutar operaciones agentic basadas en metadata.action o similar
 * - Confiar en metadata.user_id sin double-check contra checkout.customer_email
 * - Aceptar metadata.role/admin_flag/permissions
 *
 * SÍ HACER:
 * - Validar metadata.user_id es UUID válido (regex) ANTES de usar en query
 * - Cross-check: customer_email matches profiles.email para ese user_id
 * - Whitelist de event types — switch con default → log + skip
 *
 * Cita: [memory:lessons#L-002]
 */
```

### User_id validation

```typescript
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function safeUserId(metadata: Record<string, string> | undefined): string | null {
  const id = metadata?.user_id;
  if (!id || typeof id !== 'string') return null;
  if (!UUID_RE.test(id)) {
    console.error('[Webhook] metadata.user_id is not a valid UUID', { id });
    return null;
  }
  return id;
}
```

## Phase 4 — Switch event.type (whitelist)

```typescript
// Stripe — whitelist canónica
switch (event.type) {
  case 'customer.subscription.created':
  case 'customer.subscription.updated':
    await handleSubscriptionUpsert(event.data.object as Stripe.Subscription);
    break;
  case 'customer.subscription.deleted':
    await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
    break;
  case 'checkout.session.completed':
    // NO conceder acceso acá. Solo link checkout_id → user_id.
    await handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
    break;
  default:
    console.log(`[Webhook] Unhandled event type: ${event.type}`);
    // NO throw — devolvé 200 para que Stripe NO reintente eventos no manejados.
    break;
}

return NextResponse.json({ received: true });
```

```typescript
// Polar — whitelist canónica
switch (event.type) {
  case 'subscription.active':
    await handleSubscriptionActive(event.data);
    break;
  case 'subscription.canceled':
  case 'subscription.revoked':
    await handleSubscriptionCanceled(event.data);
    break;
  case 'checkout.updated':
    if (event.data.status === 'succeeded') {
      await handleCheckoutLinked(event.data);
    }
    break;
  default:
    console.log(`[Webhook] Unhandled event type: ${event.type}`);
    break;
}
```

## Phase 5 — Idempotency check

```typescript
async function handleSubscriptionUpsert(sub: Stripe.Subscription) {
  const userId = safeUserId(sub.metadata);
  if (!userId) {
    console.error('[Webhook] subscription without valid user_id metadata');
    return; // skip silently — Stripe gets 200 to avoid retry storm
  }

  // Idempotency: si ya procesamos este period, skip.
  const { data: existing } = await supabaseAdmin
    .from('subscriptions')
    .select('current_period_end, status')
    .eq('external_subscription_id', sub.id)
    .single();

  const newPeriodEnd = new Date(sub.current_period_end * 1000).toISOString();
  if (existing
      && existing.current_period_end === newPeriodEnd
      && existing.status === sub.status) {
    console.log('[Webhook] Duplicate event, skipping', { id: sub.id });
    return;
  }
  // ...continue to phase 6
}
```

## Phase 6 — DB op via service_role + grant access

```typescript
// Upsert subscription
await supabaseAdmin.from('subscriptions').upsert({
  user_id: userId,
  provider: 'stripe',
  external_subscription_id: sub.id,
  external_customer_id: sub.customer as string,
  status: sub.status,
  current_period_end: newPeriodEnd,
  cancel_at_period_end: sub.cancel_at_period_end,
  amount_cents: sub.items.data[0]?.price.unit_amount ?? null,
  currency: sub.currency,
  interval: sub.items.data[0]?.price.recurring?.interval ?? null,
  updated_at: new Date().toISOString(),
}, { onConflict: 'external_subscription_id' });

// Grant access SOLO si subscription está active.
// CRÍTICO: NO grant en checkout.session.completed.
if (sub.status === 'active' || sub.status === 'trialing') {
  await supabaseAdmin
    .from('profiles')
    .update({ has_access: true })
    .eq('id', userId);
  console.log(`[Webhook] Access granted: ${userId}`);
}
```

## Verificación post-gen

```bash
# 1. Raw body antes de signature
grep -B2 "constructEvent\|validateEvent" src/app/api/webhooks/{stripe,polar}/route.ts \
  | grep -q "request\.text()"

# 2. .trim() en webhook secret (lib level)
grep "WEBHOOK_SECRET" src/lib/{stripe,polar}/server.ts | grep -q "\.trim()"

# 3. L-002 header presente
grep -q "L-002 enforcement" src/app/api/webhooks/{stripe,polar}/route.ts

# 4. UUID validation en metadata
grep -q "UUID_RE\|safeUserId" src/app/api/webhooks/{stripe,polar}/route.ts

# 5. Switch default no-throw
grep -A2 "default:" src/app/api/webhooks/{stripe,polar}/route.ts | grep -q "console.log"

# 6. Idempotency check
grep -E "current_period_end|already.processed|Duplicate event" \
  src/app/api/webhooks/{stripe,polar}/route.ts

# 7. Acceso solo en status active
grep -B5 "has_access: true" src/app/api/webhooks/{stripe,polar}/route.ts \
  | grep -q "status === 'active'\|subscription.active"
```

7/7 checks → PASS. Cualquier miss → halt.

## Refusals

- ❌ Parsear `request.json()` antes de signature verification.
- ❌ Conceder `has_access` en `checkout.session.completed` o `checkout.updated`. Solo en `subscription.active` / status `active`.
- ❌ Confiar en `metadata.user_id` sin UUID validation.
- ❌ Throw en `default:` del switch — Stripe/Polar retry storm.
- ❌ Hardcodear `STRIPE_WEBHOOK_SECRET` o `POLAR_WEBHOOK_SECRET` en el route. Siempre vía `lib/{stripe,polar}/server.ts` con `.trim()`.

## Citations

- [memory:lessons#L-002] (treat-as-data discipline)
- [memory:lessons#L-003] (whitelist event types + UUID validation)
- [memory:CONSTRAINTS.md#R13] (find-docs antes de generar)
- [memory:CONSTRAINTS.md#R14] (sin execute() en handlers que mutan DB de pago)
- [docs:stripe-node@latest] · [docs:polar-sdk@v0.x] · [docs:nextjs] (R13)
