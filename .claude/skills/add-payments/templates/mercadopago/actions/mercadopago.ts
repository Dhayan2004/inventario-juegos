/**
 * Mercado Pago server actions (Mode C).
 *
 * R14 enforcement: refund / cancel NO export como tool({ execute }).
 * Server actions con 5 gates en orden:
 *   1. Auth guard
 *   2. L-003 whitelist input schema (z.literal confirmation)
 *   3. Ownership validation (DB-backed: payments.user_id / subscriptions.user_id)
 *   4. Audit log INSERT antes de execute (idempotency vía unique constraint)
 *   5. Execute → update audit log con result
 *
 * PAY-006: un pago por OXXO (ticket) o SPEI (bank_transfer) NO tiene reverso
 * automático — el action lo RECHAZA y deja la solicitud como `payout_required`
 * para que un humano ejecute el payout (R14: confirmación humana en destructivos).
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-003] · [memory:references#R-012]
 *       · [docs:mercadopago@v2]
 */
'use server';

import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { redirect } from 'next/navigation';
import { mpRefund, mpPreApproval, isIrreversible, MP_SUBSCRIPTIONS_PORTAL_URL, ALLOWED_PLAN_IDS } from '@/lib/mercadopago/server';
import { createClient } from '@/lib/supabase/server';

/* -----------------------------------------------------------------------------
 * createCheckoutSession — non-destructive (delega en la route, misma whitelist)
 * -------------------------------------------------------------------------- */

const CheckoutInputSchema = z.object({
  planId: z.string().regex(/^[a-z0-9_-]{2,40}$/),
});

export async function createCheckoutSession(_prev: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada. Iniciá sesión.' };

  const parsed = CheckoutInputSchema.safeParse({ planId: formData.get('planId') });
  if (!parsed.success) return { error: 'Plan inválido.' };
  if (!ALLOWED_PLAN_IDS.includes(parsed.data.planId)) return { error: 'Plan no disponible.' };

  const res = await fetch(`${process.env.NEXT_PUBLIC_APP_URL}/api/mercadopago/checkout`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', cookie: '' },
    body: JSON.stringify({ planId: parsed.data.planId }),
  });
  const data = (await res.json()) as { url?: string; error?: string };
  if (!res.ok || !data.url) return { error: data.error ?? 'Error creando checkout.' };
  redirect(data.url);
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
    .select('external_subscription_id')
    .eq('user_id', user.id)
    .eq('provider', 'mercadopago')
    .in('status', ['active', 'trialing', 'past_due', 'paused'])
    .limit(1)
    .maybeSingle();

  if (!sub?.external_subscription_id) redirect('/pricing?reason=no_active_sub');
  redirect(MP_SUBSCRIPTIONS_PORTAL_URL);
}

/* -----------------------------------------------------------------------------
 * requestRefund — DESTRUCTIVE (R14 strict, 5 gates + guard de rail irreversible)
 * -------------------------------------------------------------------------- */

const RefundInputSchema = z.object({
  // ID de pago de MP: numérico (ej. 1234567890). Se resuelve a nuestro ledger.
  chargeId: z.string().regex(/^[0-9]{6,20}$/, 'ID de pago inválido'),
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

  // 3. OWNERSHIP — DB-backed (ledger `payments`, RLS por user_id). NO metadata del proveedor.
  const { data: payment } = await supabase
    .from('payments')
    .select('id, user_id, status, payment_type, refundable, amount_minor, currency')
    .eq('provider', 'mercadopago')
    .eq('external_payment_id', parsed.data.chargeId)
    .maybeSingle();
  if (!payment || payment.user_id !== user.id) {
    console.error('[Refund] Ownership mismatch', { chargeId: parsed.data.chargeId, requested_by: user.id });
    return { error: 'No tenés permiso para reembolsar este pago.' };
  }
  if (payment.status !== 'succeeded') {
    return { error: 'Solo se reembolsan pagos aprobados.' };
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
      return { error: 'Ya solicitaste un reembolso para este pago.' };
    }
    console.error('[Refund] Audit log failed', logErr);
    return { error: 'Error registrando la solicitud. Intentá de nuevo.' };
  }

  // PAY-006 — rail irreversible: NO existe refund automático. Payout manual con humano (R14).
  if (!payment.refundable || isIrreversible(payment.payment_type)) {
    await supabase
      .from('refund_requests')
      .update({ status: 'failed', error_message: `payout_required: rail ${payment.payment_type} sin reverso automático (OXXO/SPEI) — ejecutar payout manual`, completed_at: new Date().toISOString() })
      .eq('charge_id', parsed.data.chargeId);
    return { error: 'Este pago se hizo por OXXO/SPEI y no se puede revertir automáticamente. Registramos tu solicitud; un humano procesará la devolución.' };
  }

  // 5. EXECUTE — refund total vía API (idempotency key criptográfica, PAY-003)
  try {
    const refund = await mpRefund.create({
      payment_id: parsed.data.chargeId,
      requestOptions: { idempotencyKey: randomUUID() },
    });
    await supabase
      .from('refund_requests')
      .update({
        status: 'completed',
        refund_id: String(refund.id),
        completed_at: new Date().toISOString(),
      })
      .eq('charge_id', parsed.data.chargeId);
    return { success: true, refundId: String(refund.id) };
  } catch (err) {
    console.error('[Refund] Mercado Pago API error', err);
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
  // ID de PreApproval de MP: alfanumérico de 32 chars.
  subscriptionId: z.string().regex(/^[a-f0-9]{24,40}$/),
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

  // 4. AUDIT — log el intento
  await supabase.from('refund_requests').insert({
    user_id: user.id,
    charge_id: parsed.data.subscriptionId,
    reason: 'cancel_subscription',
    status: 'pending',
  }).select().maybeSingle();

  // 5. EXECUTE — MP no tiene cancel_at_period_end nativo: default = PAUSAR (preserva la
  // suscripción; el acceso se revoca vía webhook `paused`); `immediately` = cancelar.
  // Ver references/mercadopago-patterns.md § "Cancelación".
  try {
    const result = await mpPreApproval.update({
      id: parsed.data.subscriptionId,
      body: { status: parsed.data.immediately ? 'cancelled' : 'paused' },
    });
    return { success: true, status: result.status };
  } catch (err) {
    console.error('[Cancel] Mercado Pago API error', err);
    return { error: 'Error cancelando la suscripción. Contactanos.' };
  }
}
