# Stripe Patterns — Reference

> **find-docs first.** Antes de aplicar cualquiera de estos patrones, invocá `resolve-library-id("stripe-node")` + `query-docs` para validar el shape actual. Stripe API version pinning es crítico — esta reference puede quedar atrasada respecto al SDK [docs:stripe-node@latest].

## SDK init (server)

```typescript
// src/lib/stripe/server.ts
import 'server-only';
import Stripe from 'stripe';

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error('STRIPE_SECRET_KEY missing');
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY.trim(), {
  // Pin API version explícitamente — sin esto, Stripe usa la latest del account
  // y el shape del response cambia entre versions (ej: 2024-09-30 vs 2024-12-18).
  apiVersion: '2024-12-18.acacia', // [docs:stripe-node@v18 — verify latest]
  typescript: true,
});

// CRÍTICO: .trim() en webhook secret — espacios invisibles en .env rompen
// signature verification silenciosamente.
export const STRIPE_WEBHOOK_SECRET =
  process.env.STRIPE_WEBHOOK_SECRET?.trim() ?? '';
```

`'server-only'` import previene accidental import del client (Next.js bundler error si alguien lo importa desde un client component).

## SDK init (client)

```typescript
// src/lib/stripe/client.ts
'use client';
import { loadStripe, type Stripe } from '@stripe/stripe-js';

let stripePromise: Promise<Stripe | null> | null = null;

export function getStripe(): Promise<Stripe | null> {
  if (!stripePromise) {
    stripePromise = loadStripe(
      process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!
    );
  }
  return stripePromise;
}
```

Singleton pattern — `loadStripe` corre una vez por session.

## Checkout session (Hosted Checkout)

```typescript
// src/app/api/stripe/checkout/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { stripe } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';

/**
 * POST /api/stripe/checkout
 *
 * Rate limit: max 5 sessions / user / hour (anti-abuse).
 * En prod, considerar Upstash o similar. En dev, in-memory Map suficiente.
 *
 * [docs:stripe-node@v18] · [docs:nextjs]
 */
export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();
  // L-003: whitelist priceId — solo permitidos los del .env
  const ALLOWED_PRICE_IDS = [
    process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_HOBBY,
    process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_PRO,
  ].filter(Boolean) as string[];

  if (!ALLOWED_PRICE_IDS.includes(body.priceId)) {
    return NextResponse.json({ error: 'Invalid price' }, { status: 400 });
  }

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    line_items: [{ price: body.priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing`,
    customer_email: user.email,
    client_reference_id: user.id,
    // metadata se propaga al webhook — útil para correlation
    metadata: { user_id: user.id },
    subscription_data: { metadata: { user_id: user.id } },
  });

  return NextResponse.json({ url: session.url });
}
```

## Webhook events canónicos (subscription lifecycle)

| Event | Cuándo | Acción |
|-------|--------|--------|
| `checkout.session.completed` | Usuario completa checkout | Link `checkout.id` → `user_id` (NO grant access) |
| `customer.subscription.created` | Nueva subscription creada (post-checkout) | Upsert subscription row, status field reflects |
| `customer.subscription.updated` | Status change (active/past_due/canceled) | Upsert + grant/revoke según status |
| `customer.subscription.deleted` | Subscription deleted (cancelada al fin del period) | Update status='canceled', revoke access |
| `invoice.payment_failed` | Cobro recurrente falló | Status moves a `past_due`, opcional notification |
| `invoice.payment_succeeded` | Cobro recurrente exitoso | NO acción crítica (subscription.updated llega también) |

Whitelist en switch — eventos fuera de esta lista van a `default: console.log + return`.

## Customer portal

```typescript
// src/app/api/stripe/portal/route.ts
import { stripe } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_customer_id')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing', 'past_due'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .single();

  if (!sub?.external_customer_id) {
    return NextResponse.json({ error: 'No active subscription' }, { status: 404 });
  }

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: sub.external_customer_id,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing`,
  });

  return NextResponse.json({ url: portalSession.url });
}
```

Customer portal de Stripe es full URL externa — `redirect()` server-side o `window.location.href` client-side. No embed iframe (Stripe lo bloquea).

## Test cards

| Caso | Número |
|------|--------|
| Success | 4242 4242 4242 4242 |
| Requires authentication (3DS) | 4000 0025 0000 3155 |
| Declined (insufficient funds) | 4000 0000 0000 9995 |
| Declined (lost card) | 4000 0000 0000 9987 |

CVC: cualquiera (123). Date: cualquiera futura. ZIP: cualquiera (12345).

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| `No signatures found matching the expected signature for payload` | body parsed antes de `constructEvent` | usar `await request.text()`, NO `request.json()` |
| `Stripe.checkout.sessions.create: No such price: 'price_REPLACE'` | env vars no llenas | reemplazar placeholders en .env.local |
| `400 — customer_email is required if customer is not provided` | user.email null (sign-up incompleto) | guard antes de invocar create |
| `Webhook signing secret mismatch` | `.trim()` ausente o secret cambió | re-copy desde Stripe Dashboard, asegurar `.trim()` |

## Citations

- [docs:stripe] · [docs:stripe-node@v18] · [docs:stripe-node@latest]
- [memory:CONSTRAINTS.md#R13] (find-docs first)
- [memory:CONSTRAINTS.md#R14] (destructive — refund/cancel sin execute)
- [memory:lessons#L-002] (webhook payload as data)
- [memory:lessons#L-003] (whitelist validators)
