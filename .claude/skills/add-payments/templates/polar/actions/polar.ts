/**
 * Polar server actions.
 *
 * R14 enforcement: refund / cancel NO export como tool({ execute }).
 * Mismos 5 gates que Stripe (auth → input L-003 → ownership DB-backed →
 * audit log → execute).
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-003]
 *       · [docs:polar-sdk@v0.x]
 */
'use server';

import { z } from 'zod';
import { redirect } from 'next/navigation';
import { polar, ALLOWED_PRODUCT_IDS, POLAR_PRODUCT_ID } from '@/lib/polar/server';
import { createClient } from '@/lib/supabase/server';

/* -----------------------------------------------------------------------------
 * createCheckoutSession (non-destructive)
 * -------------------------------------------------------------------------- */

export async function createCheckoutSession() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada.' };

  if (!ALLOWED_PRODUCT_IDS.includes(POLAR_PRODUCT_ID)) {
    return { error: 'Producto no configurado.' };
  }

  const checkout = await polar.checkouts.custom.create({
    productId: POLAR_PRODUCT_ID,
    successUrl: `${process.env.NEXT_PUBLIC_APP_URL}/success?checkout_id={CHECKOUT_ID}`,
    customerEmail: user.email!,
    metadata: { user_id: user.id, product_type: 'subscription' },
  });

  if (!checkout.url) return { error: 'Error creando checkout.' };
  redirect(checkout.url);
}

/* -----------------------------------------------------------------------------
 * createPortalSession (non-destructive)
 * -------------------------------------------------------------------------- */

export async function createPortalSession() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/sign-in?next=/billing');

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_customer_id')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!sub?.external_customer_id) {
    redirect('/pricing?reason=no_active_sub');
  }

  const session = await polar.customerSessions.create({
    customer_id: sub!.external_customer_id,
  });

  redirect(session.customer_portal_url);
}

/* -----------------------------------------------------------------------------
 * requestRefund (DESTRUCTIVE — R14 strict, 5 gates)
 * -------------------------------------------------------------------------- */

const RefundInputSchema = z.object({
  subscriptionId: z.string().min(1, 'ID de suscripción inválido'),
  reason: z.enum(['customer_request', 'duplicate', 'fraudulent']),
  confirmation: z.literal('REFUND', {
    errorMap: () => ({ message: 'Tipea exactamente REFUND para confirmar.' }),
  }),
});

export async function requestRefund(_prev: unknown, formData: FormData) {
  // 1. AUTH
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada.' };

  // 2. INPUT
  const parsed = RefundInputSchema.safeParse({
    subscriptionId: formData.get('subscriptionId'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // 3. OWNERSHIP — DB-backed (Polar metadata no expuesta tan trivialmente)
  const { data: sub } = await supabase
    .from('subscriptions')
    .select('id, user_id')
    .eq('external_subscription_id', parsed.data.subscriptionId)
    .eq('provider', 'polar')
    .maybeSingle();

  if (!sub || sub.user_id !== user.id) {
    return { error: 'Suscripción no encontrada o sin permiso.' };
  }

  // 4. AUDIT LOG (idempotency vía unique constraint en charge_id)
  const { error: logErr } = await supabase
    .from('refund_requests')
    .insert({
      user_id: user.id,
      charge_id: parsed.data.subscriptionId,
      reason: parsed.data.reason === 'customer_request'
        ? 'requested_by_customer'
        : parsed.data.reason,
      status: 'pending',
    });
  if (logErr) {
    if (logErr.code === '23505') {
      return { error: 'Ya solicitaste un reembolso para esta suscripción.' };
    }
    return { error: 'Error registrando la solicitud.' };
  }

  // 5. EXECUTE
  try {
    const refund = await polar.refunds.create({
      subscription_id: parsed.data.subscriptionId,
      reason: parsed.data.reason,
    });
    await supabase
      .from('refund_requests')
      .update({
        status: 'completed',
        refund_id: refund.id,
        completed_at: new Date().toISOString(),
      })
      .eq('charge_id', parsed.data.subscriptionId);
    return { success: true, refundId: refund.id };
  } catch (err) {
    console.error('[Refund] Polar API error', err);
    await supabase
      .from('refund_requests')
      .update({
        status: 'failed',
        error_message: String(err),
        completed_at: new Date().toISOString(),
      })
      .eq('charge_id', parsed.data.subscriptionId);
    return { error: 'Error procesando el reembolso.' };
  }
}

/* -----------------------------------------------------------------------------
 * cancelSubscription (DESTRUCTIVE — R14 strict)
 * -------------------------------------------------------------------------- */

const CancelInputSchema = z.object({
  subscriptionId: z.string().min(1),
  immediately: z.boolean().default(false),
  confirmation: z.literal('CANCEL', {
    errorMap: () => ({ message: 'Tipea exactamente CANCEL para confirmar.' }),
  }),
});

export async function cancelSubscription(_prev: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada.' };

  const parsed = CancelInputSchema.safeParse({
    subscriptionId: formData.get('subscriptionId'),
    immediately: formData.get('immediately') === 'true',
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('id, user_id')
    .eq('external_subscription_id', parsed.data.subscriptionId)
    .eq('provider', 'polar')
    .maybeSingle();

  if (!sub || sub.user_id !== user.id) {
    return { error: 'Suscripción no encontrada.' };
  }

  await supabase.from('refund_requests').insert({
    user_id: user.id,
    charge_id: parsed.data.subscriptionId,
    reason: 'cancel_subscription',
    status: 'pending',
  });

  try {
    await polar.subscriptions.update({
      id: parsed.data.subscriptionId,
      data: parsed.data.immediately
        ? { status: 'canceled' }
        : { cancel_at_period_end: true },
    });
    return { success: true };
  } catch (err) {
    console.error('[Cancel] Polar API error', err);
    return { error: 'Error cancelando la suscripción.' };
  }
}
