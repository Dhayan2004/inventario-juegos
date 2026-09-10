/**
 * Stripe webhook handler.
 *
 * 6 phases en orden estricto (NO reorder):
 *   1. Read raw body (await request.text() — NO json())
 *   2. Verify signature (FAIL FAST 400 si falla)
 *   3. Treat-as-data (L-002 — metadata es untrusted aún post-signature)
 *   4. Switch event.type whitelist (default: log + return, NO throw)
 *   5. Idempotency check (current_period_end + status compare)
 *   6. DB op via service_role + grant access SOLO si status active
 *
 * L-002 enforcement: el payload está validado por signature (Phase 2),
 * pero los campos metadata.* son user-controlled strings (vienen del
 * checkout request original). Aún post-signature, metadata debe tratarse
 * como datos a verificar contra whitelist, NO como instrucciones.
 *
 * Cita: [memory:lessons#L-002] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:stripe-node@v18] · [docs:nextjs]
 */
import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { stripe, STRIPE_WEBHOOK_SECRET } from '@/lib/stripe/server';
import { createAdminClient } from '@/lib/supabase/admin';

// Force dynamic — webhook nunca cacheado
export const dynamic = 'force-dynamic';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** L-002: validate metadata.user_id ANTES de query DB. */
function safeUserId(metadata: Record<string, string> | undefined): string | null {
  const id = metadata?.user_id;
  if (!id || typeof id !== 'string' || !UUID_RE.test(id)) {
    return null;
  }
  return id;
}

export async function POST(request: NextRequest) {
  // L-002 + signature: NO PARSEAR JSON ANTES DE VERIFY.
  // raw body es el único input válido para constructEvent.
  const body = await request.text();
  const sig = request.headers.get('stripe-signature');

  if (!sig) {
    console.error('[Webhook] Missing stripe-signature header');
    return NextResponse.json({ error: 'Missing signature' }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('[Webhook] Signature verification failed', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  try {
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpsert(event.data.object);
        break;
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;
      case 'checkout.session.completed':
        // NO grant access. Solo link checkout → user.
        await handleCheckoutCompleted(event.data.object);
        break;
      default:
        // No throw — anti retry storm. Eventos no manejados → 200 implícito.
        console.log(`[Webhook] Unhandled event type: ${event.type}`);
        break;
    }
  } catch (err) {
    console.error(`[Webhook] Error handling ${event.type}`, err);
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

/* -----------------------------------------------------------------------------
 * Subscription upsert + grant access
 * -------------------------------------------------------------------------- */
async function handleSubscriptionUpsert(sub: Stripe.Subscription) {
  const userId = safeUserId(sub.metadata as Record<string, string>);
  if (!userId) {
    console.error('[Webhook] subscription without valid user_id metadata', { id: sub.id });
    return; // Stripe gets 200 — sin retry storm
  }

  const supabase = createAdminClient();
  const newPeriodEnd = new Date(sub.current_period_end * 1000).toISOString();

  // Idempotency: si ya procesamos this period + status, skip.
  const { data: existing } = await supabase
    .from('subscriptions')
    .select('current_period_end, status')
    .eq('external_subscription_id', sub.id)
    .maybeSingle();

  if (
    existing &&
    existing.current_period_end === newPeriodEnd &&
    existing.status === sub.status
  ) {
    console.log('[Webhook] Duplicate event, skipping', { id: sub.id });
    return;
  }

  await supabase.from('subscriptions').upsert(
    {
      user_id: userId,
      provider: 'stripe',
      external_subscription_id: sub.id,
      external_customer_id: typeof sub.customer === 'string' ? sub.customer : sub.customer.id,
      status: sub.status,
      current_period_end: newPeriodEnd,
      cancel_at_period_end: sub.cancel_at_period_end ?? false,
      amount_cents: sub.items.data[0]?.price.unit_amount ?? null,
      currency: sub.currency,
      interval: sub.items.data[0]?.price.recurring?.interval ?? null,
      plan_id: sub.items.data[0]?.price.id ?? null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'external_subscription_id' }
  );

  // Grant access SOLO si status active o trialing.
  if (sub.status === 'active' || sub.status === 'trialing') {
    await supabase.from('profiles').update({ has_access: true }).eq('id', userId);
    console.log(`[Webhook] Access granted: ${userId}`);
  } else if (sub.status === 'canceled' || sub.status === 'unpaid' || sub.status === 'incomplete_expired') {
    await supabase.from('profiles').update({ has_access: false }).eq('id', userId);
    console.log(`[Webhook] Access revoked: ${userId}`);
  }
}

async function handleSubscriptionDeleted(sub: Stripe.Subscription) {
  const userId = safeUserId(sub.metadata as Record<string, string>);
  if (!userId) return;

  const supabase = createAdminClient();

  await supabase
    .from('subscriptions')
    .update({ status: 'canceled', updated_at: new Date().toISOString() })
    .eq('external_subscription_id', sub.id);

  // Verificar si tiene OTRA active sub antes de revocar (multi-product edge)
  const { data: otherActive } = await supabase
    .from('subscriptions')
    .select('id')
    .eq('user_id', userId)
    .in('status', ['active', 'trialing'])
    .neq('external_subscription_id', sub.id);

  if (!otherActive || otherActive.length === 0) {
    await supabase.from('profiles').update({ has_access: false }).eq('id', userId);
    console.log(`[Webhook] Access revoked: ${userId}`);
  }
}

/** Solo link checkout → user. NO grant acceso (eso lo hace subscription.updated). */
async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const userId = safeUserId(session.metadata as Record<string, string>);
  if (!userId) return;

  const supabase = createAdminClient();
  await supabase
    .from('subscriptions')
    .update({
      external_checkout_id: session.id,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .is('external_checkout_id', null);

  console.log(`[Webhook] Checkout linked: ${session.id} → ${userId}`);
}
