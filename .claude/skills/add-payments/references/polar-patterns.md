# Polar Patterns — Reference

> **find-docs first.** Polar SDK es v0.x — shape inestable. Antes de aplicar cualquier patrón, invocá `resolve-library-id("polar-sdk")` + `query-docs` para validar que los exports y funciones existan en la versión actual. [docs:polar-sdk@v0.x]

## SDK init (server)

```typescript
// src/lib/polar/server.ts
import 'server-only';
import { Polar } from '@polar-sh/sdk';

if (!process.env.POLAR_ACCESS_TOKEN) {
  throw new Error('POLAR_ACCESS_TOKEN missing');
}

const isSandbox = process.env.POLAR_ENVIRONMENT === 'sandbox';

export const polar = new Polar({
  accessToken: process.env.POLAR_ACCESS_TOKEN.trim(),
  server: isSandbox ? 'sandbox' : 'production',
});

// CRÍTICO: .trim() en webhook secret. Polar es especialmente susceptible —
// su signature scheme depende de bytes exactos del secret.
export const POLAR_WEBHOOK_SECRET =
  process.env.POLAR_WEBHOOK_SECRET?.trim() ?? '';

export const POLAR_PRODUCT_ID = process.env.POLAR_PRODUCT_ID ?? '';
```

`'server-only'` previene import accidental desde client.

## Checkout (custom)

```typescript
// src/app/api/polar/checkout/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { polar, POLAR_PRODUCT_ID } from '@/lib/polar/server';
import { createClient } from '@/lib/supabase/server';

/**
 * POST /api/polar/checkout
 *
 * Rate limit: max 5 sessions / user / hour (anti-abuse).
 *
 * [docs:polar-sdk@v0.x] · [docs:nextjs]
 */
export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const checkout = await polar.checkouts.custom.create({
    productId: POLAR_PRODUCT_ID,
    successUrl: `${process.env.NEXT_PUBLIC_APP_URL}/success?checkout_id={CHECKOUT_ID}`,
    customerEmail: user.email!,
    metadata: {
      user_id: user.id,
      product_type: 'subscription',
    },
  });

  return NextResponse.json({ url: checkout.url });
}
```

## Webhook signature verification

```typescript
import { validateEvent, WebhookVerificationError } from '@polar-sh/sdk/webhooks';
import { POLAR_WEBHOOK_SECRET } from '@/lib/polar/server';

const body = await request.text();
const headers = Object.fromEntries(request.headers.entries());

let event;
try {
  event = validateEvent(body, headers, POLAR_WEBHOOK_SECRET);
} catch (err) {
  if (err instanceof WebhookVerificationError) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 403 });
  }
  throw err;
}
```

Diferencias vs Stripe:
- Polar usa `headers` Object plain (no objeto Stripe).
- `validateEvent` returns event directly (no nested `event.data.object`).
- 403 (no 400) en signature mismatch — convención Polar.

## Webhook events canónicos

| Event | Cuándo | Acción |
|-------|--------|--------|
| `checkout.updated` | Status changes (incl. `succeeded`) | Si `status === 'succeeded'`, link checkout_id → user_id (NO grant access) |
| `subscription.active` | Subscription activa | Upsert + GRANT `has_access = true` |
| `subscription.canceled` | Cancelada (puede ser at_period_end o immediate) | Update status, NO revoke access todavía si `cancel_at_period_end` |
| `subscription.revoked` | Acceso revocado (period end o force-cancel) | Update status='revoked' + revoke `has_access` |
| `subscription.updated` | Cambios de plan, dates, etc. | Upsert con new fields |

`subscription.active` es el equivalente Polar de `customer.subscription.updated` con `status === 'active'` en Stripe — pero como event explícito, más robusto para grant logic.

## Customer portal (URL externa)

```typescript
import { polar } from '@/lib/polar/server';

const session = await polar.customerSessions.create({
  customer_id: external_customer_id,
});

// session.customer_portal_url es URL polar.sh — full redirect, no embed.
redirect(session.customer_portal_url);
```

A diferencia de Stripe, el customer portal de Polar vive en `polar.sh/<merchant>/portal/...`. El return URL post-portal está fijo a la app del merchant en Polar settings, no se pasa por API.

## Refund

```typescript
import { polar } from '@/lib/polar/server';

await polar.refunds.create({
  subscription_id: parsed.data.subscriptionId,
  reason: parsed.data.reason, // 'customer_request' | 'duplicate' | 'fraudulent'
});
```

Polar refunds son por subscription, no por charge — más simple que Stripe que require charge_id.

## Test cards

Polar wraps Stripe — usa los mismos test cards (4242 4242 4242 4242, etc.). Sandbox env via `POLAR_ENVIRONMENT=sandbox`.

## Merchant of Record (MoR) — qué cubre

| Aspecto | Polar handles | Tu handles |
|---------|---------------|------------|
| Tax calculation por jurisdicción (VAT/GST/sales tax) | ✓ | — |
| Invoice generation con tax breakdown | ✓ | — |
| Entity legal (Polar es seller of record) | ✓ | — |
| Tax filing en múltiples jurisdicciones | ✓ | — |
| Customer support para issues de tax | ✓ | — |
| Producto + pricing + features | — | ✓ |
| Customer support para issues de producto | — | ✓ |
| Webhooks → grant access | — | ✓ |

Esto es lo que hace Polar atractivo a indie hackers / freelance sin empresa registrada. Sin Polar, eso lo asume Stripe Tax + tu equipo legal (Stripe NO es MoR, solo Tax provider).

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| `validateEvent is not a function` | SDK <0.10 — exports moved | upgrade `@polar-sh/sdk` ≥0.10 |
| `Invalid signature` (post .trim()) | webhook secret de sandbox usado en prod o vice versa | verificar env per ambiente |
| `404 product not found` | `POLAR_PRODUCT_ID` apunta a producto de otro environment | crear producto en sandbox + production separado |
| `customer_id required` en customerSessions.create | subscription sin customer_id linked | check `external_customer_id` no null en DB antes de invocar |

## Citations

- [docs:polar] · [docs:polar-sdk@v0.x]
- [memory:CONSTRAINTS.md#R13] (find-docs first — SDK shape inestable)
- [memory:CONSTRAINTS.md#R14] (refund/cancel sin execute)
- [memory:lessons#L-002] (webhook payload as data)
- [memory:lessons#L-003] (whitelist validators)
- [memory:decisions#D-009] (Polar como override explícito por MoR)
