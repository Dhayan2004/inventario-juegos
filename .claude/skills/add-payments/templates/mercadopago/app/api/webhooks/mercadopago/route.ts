/**
 * Mercado Pago webhook handler (Mode C).
 *
 * 6 phases en orden estricto (NO reorder):
 *   1. Read raw body (await request.text()) + headers x-signature / x-request-id + query data.id
 *   2. Verify signature sobre el MANIFEST (NO el body) — FAIL FAST 400. Ventana 300 s.
 *   3. Treat-as-data (L-002): el body NO está firmado → solo se usa `type`, `action`, `data.id`;
 *      el estado real se RE-FETCHEA al API (payload_authoritative = false).
 *   4. Dedup por event id en `webhook_events_processed` (PAY-002/G2) — MP reintenta hasta 2xx.
 *   5. Switch type whitelist (payment · subscription_preapproval); default: log + 200, NO throw.
 *   6. DB op via service_role + grant access SOLO si la preapproval está `authorized`.
 *
 * MP exige 200/201 en ≤22 s: nada pesado aquí; el re-fetch es una llamada.
 *
 * Cita: [memory:lessons#L-002] · [memory:CONSTRAINTS.md#R13] · [memory:references#R-012]
 *       · [docs:mercadopago@v2] · [docs:nextjs]
 */
import { NextRequest, NextResponse } from 'next/server';
import { mpPayment, mpPreApproval, MP_WEBHOOK_SECRET, toMinorUnits, isIrreversible } from '@/lib/mercadopago/server';
import { verifyMpSignature } from '@/lib/mercadopago/verify';
import { createAdminClient } from '@/lib/supabase/admin';

// Force dynamic — webhook nunca cacheado
export const dynamic = 'force-dynamic';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** L-002: `external_reference` lo pusimos nosotros (user.id) pero llega por un canal no firmado → validar. */
function safeUserId(externalReference: string | null | undefined): string | null {
  const id = externalReference;
  if (!id || typeof id !== 'string' || !UUID_RE.test(id)) return null;
  return id;
}

interface MpNotification {
  id?: number | string;
  type?: string;            // payment · subscription_preapproval · subscription_authorized_payment · plan · …
  action?: string;          // payment.created · payment.updated · updated · …
  live_mode?: boolean;
  data?: { id?: string | number };
}

export async function POST(request: NextRequest) {
  // Phase 1 — raw body + headers + query. NO json() antes de verificar.
  const body = await request.text();
  const xSignature = request.headers.get('x-signature');
  const xRequestId = request.headers.get('x-request-id');
  const dataIdFromQuery = request.nextUrl.searchParams.get('data.id') ?? request.nextUrl.searchParams.get('id');

  if (!xSignature || !xRequestId) {
    console.error('[MP Webhook] Missing x-signature / x-request-id');
    return NextResponse.json({ error: 'Missing signature' }, { status: 400 });
  }

  // Phase 2 — firma sobre el manifest, tiempo constante, ventana 300 s.
  const verdict = verifyMpSignature({
    xSignature,
    xRequestId,
    dataId: dataIdFromQuery,
    secret: MP_WEBHOOK_SECRET,
    toleranceSeconds: 300,
  });
  if (!verdict.ok) {
    console.error('[MP Webhook] Signature verification failed', { reason: verdict.reason, requestId: xRequestId });
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  // Phase 3 — parsear SOLO después de verificar; el body sigue siendo no-autoritativo.
  let notification: MpNotification;
  try {
    notification = JSON.parse(body) as MpNotification;
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const resourceId = String(notification.data?.id ?? dataIdFromQuery ?? '');
  const eventId = `${notification.type ?? 'unknown'}:${notification.id ?? xRequestId}`;
  const eventType = `${notification.type ?? 'unknown'}.${notification.action ?? 'unknown'}`;

  const supabase = createAdminClient();

  // Phase 4 — dedup (unique (provider, event_id)). Duplicado → 200 sin reprocesar.
  const { error: dedupErr } = await supabase.from('webhook_events_processed').insert({
    provider: 'mercadopago',
    event_id: eventId,
    event_type: eventType,
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  });
  if (dedupErr) {
    if (dedupErr.code === '23505') {
      console.log('[MP Webhook] Duplicate event, skipping', { eventId });
      return NextResponse.json({ received: true, duplicate: true });
    }
    console.error('[MP Webhook] Dedup insert failed', dedupErr);
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 });
  }

  // Phase 5 — whitelist de tipos. Todo lo demás: log + 200 (MP reintenta ante 4xx/5xx).
  try {
    switch (notification.type) {
      case 'subscription_preapproval':
        await handlePreapprovalUpsert(resourceId);
        break;
      case 'payment':
        await handlePaymentUpsert(resourceId);
        break;
      default:
        // No throw — anti retry storm.
        console.log(`[MP Webhook] Unhandled type: ${notification.type}`);
        break;
    }
  } catch (err) {
    console.error(`[MP Webhook] Error handling ${eventType}`, err);
    return NextResponse.json({ error: 'Processing failed' }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

/* -----------------------------------------------------------------------------
 * Suscripción (PreApproval) — RE-FETCH + upsert + grant access SOLO si authorized
 * -------------------------------------------------------------------------- */
async function handlePreapprovalUpsert(preapprovalId: string) {
  if (!preapprovalId) return;
  // payload_authoritative = false → el estado real vive en el API.
  const pre = await mpPreApproval.get({ id: preapprovalId });
  const userId = safeUserId(pre.external_reference);
  if (!userId) {
    console.error('[MP Webhook] preapproval without valid external_reference', { id: preapprovalId });
    return; // 200 — sin retry storm
  }

  const supabase = createAdminClient();
  const status = mapPreapprovalStatus(pre.status);
  const periodEnd = pre.next_payment_date ?? null;
  const currency = (pre.auto_recurring?.currency_id ?? 'MXN').toLowerCase();
  const amountMajor = pre.auto_recurring?.transaction_amount ?? null;

  // Idempotency: mismo period + status → skip.
  const { data: existing } = await supabase
    .from('subscriptions')
    .select('current_period_end, status')
    .eq('external_subscription_id', preapprovalId)
    .maybeSingle();
  if (existing && existing.current_period_end === periodEnd && existing.status === status) {
    console.log('[MP Webhook] Duplicate state, skipping', { id: preapprovalId });
    return;
  }

  await supabase.from('subscriptions').upsert(
    {
      user_id: userId,
      provider: 'mercadopago',
      external_subscription_id: preapprovalId,
      external_customer_id: pre.payer_id ? String(pre.payer_id) : null,
      status,
      current_period_end: periodEnd,
      cancel_at_period_end: false, // MP no soporta cancel-at-period-end nativo (ver references/mercadopago-patterns.md)
      amount_cents: amountMajor != null ? toMinorUnits(amountMajor, currency) : null,
      currency,
      interval: pre.auto_recurring?.frequency_type === 'days' ? null : 'month',
      plan_id: pre.preapproval_plan_id ?? null,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'external_subscription_id' }
  );

  // Grant access SOLO si authorized. paused/cancelled → revoke.
  if (status === 'active') {
    await supabase.from('profiles').update({ has_access: true }).eq('id', userId);
    console.log(`[MP Webhook] Access granted: ${userId}`);
  } else if (status === 'paused' || status === 'canceled') {
    const { data: otherActive } = await supabase
      .from('subscriptions')
      .select('id')
      .eq('user_id', userId)
      .in('status', ['active', 'trialing'])
      .neq('external_subscription_id', preapprovalId);
    if (!otherActive || otherActive.length === 0) {
      await supabase.from('profiles').update({ has_access: false }).eq('id', userId);
      console.log(`[MP Webhook] Access revoked: ${userId}`);
    }
  }
}

function mapPreapprovalStatus(s: string | undefined): 'active' | 'paused' | 'canceled' | 'incomplete' {
  switch (s) {
    case 'authorized': return 'active';
    case 'paused': return 'paused';
    case 'cancelled': return 'canceled';
    default: return 'incomplete'; // pending
  }
}

/* -----------------------------------------------------------------------------
 * Pago (one-time o cobro de suscripción) — RE-FETCH + ledger `payments`
 * -------------------------------------------------------------------------- */
async function handlePaymentUpsert(paymentId: string) {
  if (!paymentId) return;
  const payment = await mpPayment.get({ id: paymentId });
  const userId = safeUserId(payment.external_reference);
  if (!userId) {
    console.error('[MP Webhook] payment without valid external_reference', { id: paymentId });
    return;
  }
  const currency = (payment.currency_id ?? 'MXN').toLowerCase();
  const supabase = createAdminClient();

  await supabase.from('payments').upsert(
    {
      user_id: userId,
      provider: 'mercadopago',
      external_payment_id: String(payment.id),
      amount_minor: payment.transaction_amount != null ? toMinorUnits(payment.transaction_amount, currency) : 0,
      currency,
      status: mapPaymentStatus(payment.status),
      method: payment.payment_method_id ?? null,
      payment_type: payment.payment_type_id ?? null,
      refundable: !isIrreversible(payment.payment_type_id),
      // Rule 11: solo email del payer, nunca el objeto completo.
      metadata: { payer_email: payment.payer?.email ?? null, live_mode: payment.live_mode ?? null },
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'provider,external_payment_id' }
  );
  console.log('[MP Webhook] Payment upserted', { id: paymentId, status: payment.status, type: payment.payment_type_id });
}

function mapPaymentStatus(s: string | undefined): 'pending' | 'succeeded' | 'failed' | 'canceled' | 'refunded' | 'disputed' {
  switch (s) {
    case 'approved': return 'succeeded';
    case 'rejected': return 'failed';
    case 'cancelled': return 'canceled';
    case 'refunded': return 'refunded';
    case 'charged_back': return 'disputed';
    default: return 'pending'; // pending · in_process · in_mediation · authorized
  }
}
