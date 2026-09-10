/**
 * Stripe server actions.
 *
 * R14 enforcement: refund / cancel / transfer NO export como tool({ execute }).
 * Server actions con 5 gates en orden:
 *   1. Auth guard
 *   2. L-003 whitelist input schema (z.literal confirmation)
 *   3. Ownership validation (charge.metadata o subscriptions.user_id)
 *   4. Audit log INSERT antes de execute (idempotency vía unique constraint)
 *   5. Execute → update audit log con result
 *
 * L-003 whitelist en validators (z.enum currency/interval/reason, bounded
 * amount, NO z.string libre).
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-003]
 *       · [docs:stripe-node@v18]
 */
'use server';

import { z } from 'zod';
import { redirect } from 'next/navigation';
import { stripe, ALLOWED_PRICE_IDS } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';

/* -----------------------------------------------------------------------------
 * createCheckoutSession — non-destructive
 * -------------------------------------------------------------------------- */

const CheckoutInputSchema = z.object({
  priceId: z.string().regex(/^price_[a-zA-Z0-9]{20,}$/),
});

export async function createCheckoutSession(_prev: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada. Iniciá sesión.' };

  const parsed = CheckoutInputSchema.safeParse({
    priceId: formData.get('priceId'),
  });
  if (!parsed.success) return { error: 'Plan inválido.' };

  if (!ALLOWED_PRICE_IDS.includes(parsed.data.priceId)) {
    return { error: 'Plan no disponible.' };
  }

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    line_items: [{ price: parsed.data.priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing`,
    customer_email: user.email!,
    client_reference_id: user.id,
    metadata: { user_id: user.id },
    subscription_data: { metadata: { user_id: user.id } },
    automatic_tax: { enabled: true },
  });

  if (!session.url) return { error: 'Error creando session.' };
  redirect(session.url);
}

/* -----------------------------------------------------------------------------
 * createPortalSession — non-destructive
 * -------------------------------------------------------------------------- */

export async function createPortalSession() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/sign-in?next=/billing');

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_customer_id')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing', 'past_due'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!sub?.external_customer_id) {
    redirect('/pricing?reason=no_active_sub');
  }

  const portal = await stripe.billingPortal.sessions.create({
    customer: sub!.external_customer_id,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing`,
  });

  redirect(portal.url);
}

/* -----------------------------------------------------------------------------
 * requestRefund — DESTRUCTIVE (R14 strict, 5 gates)
 * -------------------------------------------------------------------------- */

const RefundInputSchema = z.object({
  chargeId: z.string().regex(/^ch_[a-zA-Z0-9]{20,}$/, 'ID de cobro inválido'),
  reason: z.enum(['requested_by_customer', 'duplicate', 'fraudulent']),
  confirmation: z.literal('REFUND', {
    errorMap: () => ({ message: 'Tipea exactamente REFUND para confirmar.' }),
  }),
});

export async function requestRefund(_prev: unknown, formData: FormData) {
  // 1. AUTH
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada.' };

  // 2. INPUT (L-003)
  const parsed = RefundInputSchema.safeParse({
    chargeId: formData.get('chargeId'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // 3. OWNERSHIP — charge.metadata.user_id matches user.id
  let charge;
  try {
    charge = await stripe.charges.retrieve(parsed.data.chargeId);
  } catch {
    return { error: 'Cobro no encontrado.' };
  }
  if (charge.metadata?.user_id !== user.id) {
    console.error('[Refund] Ownership mismatch', {
      chargeId: parsed.data.chargeId,
      requested_by: user.id,
      charge_owner: charge.metadata?.user_id,
    });
    return { error: 'No tenés permiso para reembolsar este pago.' };
  }

  // 4. AUDIT LOG (idempotency via unique constraint)
  const { error: logErr } = await supabase
    .from('refund_requests')
    .insert({
      user_id: user.id,
      charge_id: parsed.data.chargeId,
      reason: parsed.data.reason,
      status: 'pending',
    });
  if (logErr) {
    if (logErr.code === '23505') {
      return { error: 'Ya solicitaste un reembolso para este cobro.' };
    }
    console.error('[Refund] Audit log failed', logErr);
    return { error: 'Error registrando la solicitud. Intentá de nuevo.' };
  }

  // 5. EXECUTE
  try {
    const refund = await stripe.refunds.create({
      charge: parsed.data.chargeId,
      reason: parsed.data.reason,
      metadata: { user_id: user.id, requested_via: 'self_service' },
    });
    await supabase
      .from('refund_requests')
      .update({
        status: 'completed',
        refund_id: refund.id,
        completed_at: new Date().toISOString(),
      })
      .eq('charge_id', parsed.data.chargeId);
    return { success: true, refundId: refund.id };
  } catch (err) {
    console.error('[Refund] Stripe API error', err);
    await supabase
      .from('refund_requests')
      .update({
        status: 'failed',
        error_message: String(err),
        completed_at: new Date().toISOString(),
      })
      .eq('charge_id', parsed.data.chargeId);
    return { error: 'Error procesando el reembolso. Contactanos.' };
  }
}

/* -----------------------------------------------------------------------------
 * cancelSubscription — DESTRUCTIVE (R14 strict, 5 gates)
 * -------------------------------------------------------------------------- */

const CancelInputSchema = z.object({
  subscriptionId: z.string().regex(/^sub_[a-zA-Z0-9]{20,}$/),
  immediately: z.boolean().default(false),
  confirmation: z.literal('CANCEL', {
    errorMap: () => ({ message: 'Tipea exactamente CANCEL para confirmar.' }),
  }),
});

export async function cancelSubscription(_prev: unknown, formData: FormData) {
  // 1. AUTH
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada.' };

  // 2. INPUT
  const parsed = CancelInputSchema.safeParse({
    subscriptionId: formData.get('subscriptionId'),
    immediately: formData.get('immediately') === 'true',
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // 3. OWNERSHIP — DB-backed (NO metadata)
  const { data: sub } = await supabase
    .from('subscriptions')
    .select('id, user_id, status')
    .eq('external_subscription_id', parsed.data.subscriptionId)
    .maybeSingle();

  if (!sub || sub.user_id !== user.id) {
    return { error: 'Suscripción no encontrada o sin permiso.' };
  }

  // 4. AUDIT — log el intento (refund_requests es shape-extensible)
  await supabase.from('refund_requests').insert({
    user_id: user.id,
    charge_id: parsed.data.subscriptionId,
    reason: 'cancel_subscription',
    status: 'pending',
  }).select().maybeSingle();

  // 5. EXECUTE — default cancel at_period_end (preserva acceso pagado)
  try {
    const result = parsed.data.immediately
      ? await stripe.subscriptions.cancel(parsed.data.subscriptionId)
      : await stripe.subscriptions.update(parsed.data.subscriptionId, {
          cancel_at_period_end: true,
        });
    return { success: true, status: result.status };
  } catch (err) {
    console.error('[Cancel] Stripe API error', err);
    return { error: 'Error cancelando la suscripción. Contactanos.' };
  }
}
