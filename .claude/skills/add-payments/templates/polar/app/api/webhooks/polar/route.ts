/**
 * Polar webhook handler.
 *
 * 6 phases en orden estricto (mirror Stripe handler):
 *   1. Read raw body
 *   2. Verify signature (validateEvent — FAIL FAST 403 si falla)
 *   3. Treat-as-data (L-002)
 *   4. Switch event.type whitelist (default no-throw)
 *   5. Idempotency check
 *   6. DB op via service_role + grant access SOLO en subscription.active
 *
 * L-002 enforcement: payload firmado por signature pero metadata.* es
 * user-controlled — UUID validate antes de query.
 *
 * Cita: [memory:lessons#L-002] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:polar-sdk@v0.x] · [docs:nextjs]
 */
import { NextRequest, NextResponse } from 'next/server';
import { validateEvent, WebhookVerificationError } from '@polar-sh/sdk/webhooks';
import { POLAR_WEBHOOK_SECRET } from '@/lib/polar/server';
import { createAdminClient } from '@/lib/supabase/admin';

export const dynamic = 'force-dynamic';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function safeUserId(metadata: Record<string, unknown> | undefined): string | null {
  const id = metadata?.user_id;
  if (!id || typeof id !== 'string' || !UUID_RE.test(id)) {
    return null;
  }
  return id;
}

export async function POST(request: NextRequest) {
  // L-002 + signature: NO PARSEAR JSON ANTES DE VERIFY.
  const body = await request.text();
  const headers = Object.fromEntries(request.headers.entries());

  let event;
  try {
    event = validateEvent(body, headers, POLAR_WEBHOOK_SECRET);
  } catch (err) {
    if (err instanceof WebhookVerificationError) {
      console.error('[Webhook] Invalid signature');
      return NextResponse.json({ error: 'Invalid signature' }, { status: 403 });
    }
    console.error('[Webhook] Unexpected error', err);
    return NextResponse.json({ error: 'Verification error' }, { status: 500 });
  }

  try {
    switch (event.type) {
      case 'subscription.active':
        await handleSubscriptionActive(event.data);
        break;
      case 'subscription.canceled':
      case 'subscription.revoked':
        await handleSubscriptionCanceled(event.data);
        break;
      case 'subscription.updated':
        await handleSubscriptionUpdated(event.data);
        break;
      case 'checkout.updated':
        if ((event.data as { status?: string }).status === 'succeeded') {
          await handleCheckoutLinked(event.data);
        }
        break;
      default:
        console.log(`[Webhook] Unhandled event type: ${event.type}`);
        break;
    }
  } catch (err) {
    console.error(`[Webhook] Error handling ${event.type}`, err);
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

/* -------------------------------------------------------------------------- */

interface PolarSubscription {
  id: string;
  customer_id: string;
  status: string;
  current_period_end?: string;
  cancel_at_period_end?: boolean;
  amount?: number;
  currency?: string;
  recurring_interval?: string;
  product_id?: string;
  metadata?: Record<string, unknown>;
}

async function handleSubscriptionActive(sub: PolarSubscription) {
  const userId = safeUserId(sub.metadata);
  if (!userId) {
    console.error('[Webhook] subscription.active without valid user_id metadata');
    return;
  }

  const supabase = createAdminClient();

  // Idempotency
  const { data: existing } = await supabase
    .from('subscriptions')
    .select('current_period_end, status')
    .eq('external_subscription_id', sub.id)
    .maybeSingle();

  const newPeriodEnd = sub.current_period_end ?? null;

  if (existing && existing.current_period_end === newPeriodEnd && existing.status === 'active') {
    console.log('[Webhook] Duplicate event, skipping', { id: sub.id });
    return;
  }

  await supabase.from('subscriptions').upsert(
    {
      user_id: userId,
      provider: 'polar',
      external_subscription_id: sub.id,
      external_customer_id: sub.customer_id,
      status: 'active',
      current_period_end: newPeriodEnd,
      cancel_at_period_end: sub.cancel_at_period_end ?? false,
      amount_cents: sub.amount ?? null,
      currency: sub.currency ?? null,
      interval: sub.recurring_interval ?? null,
      plan_id: sub.product_id ?? null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'provider,external_subscription_id' }
  );

  await supabase.from('profiles').update({ has_access: true }).eq('id', userId);
  console.log(`[Webhook] Access granted: ${userId}`);
}

async function handleSubscriptionCanceled(sub: PolarSubscription) {
  const userId = safeUserId(sub.metadata);
  if (!userId) return;

  const supabase = createAdminClient();
  const isRevoke = !sub.cancel_at_period_end;

  await supabase
    .from('subscriptions')
    .update({
      status: isRevoke ? 'revoked' : 'canceled',
      cancel_at_period_end: sub.cancel_at_period_end ?? true,
      updated_at: new Date().toISOString(),
    })
    .eq('external_subscription_id', sub.id);

  if (isRevoke) {
    // Solo revocar si no hay otra active sub
    const { data: otherActive } = await supabase
      .from('subscriptions')
      .select('id')
      .eq('user_id', userId)
      .eq('status', 'active')
      .neq('external_subscription_id', sub.id);

    if (!otherActive || otherActive.length === 0) {
      await supabase.from('profiles').update({ has_access: false }).eq('id', userId);
      console.log(`[Webhook] Access revoked: ${userId}`);
    }
  }
}

async function handleSubscriptionUpdated(sub: PolarSubscription) {
  const userId = safeUserId(sub.metadata);
  if (!userId) return;

  const supabase = createAdminClient();
  await supabase
    .from('subscriptions')
    .update({
      status: sub.status,
      current_period_end: sub.current_period_end,
      cancel_at_period_end: sub.cancel_at_period_end ?? false,
      updated_at: new Date().toISOString(),
    })
    .eq('external_subscription_id', sub.id);
}

interface PolarCheckout {
  id: string;
  metadata?: Record<string, unknown>;
}

async function handleCheckoutLinked(checkout: PolarCheckout) {
  const userId = safeUserId(checkout.metadata);
  if (!userId) return;

  const supabase = createAdminClient();
  await supabase
    .from('subscriptions')
    .update({
      external_checkout_id: checkout.id,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .is('external_checkout_id', null);

  console.log(`[Webhook] Checkout linked: ${checkout.id} → ${userId}`);
}
