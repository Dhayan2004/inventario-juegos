/**
 * POST /api/mercadopago/checkout
 *
 * Crea una suscripción (PreApproval, hosted) o un pago único (Preference /
 * Checkout Pro) y devuelve la URL de MP para redirigir.
 *
 * Rate limit: max 5 checkouts / user / hour (anti-abuse).
 * En dev, in-memory Map suficiente. En prod, considerar Upstash o similar.
 *
 * PAY-008: el cliente nombra QUÉ plan, nunca cuánto cuesta — el precio sale del
 * catálogo de planes del servidor (PLANS). PAY-004: montos con exponente.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-003] · [memory:references#R-012]
 *       · [docs:mercadopago@v2] · [docs:nextjs]
 */
import { NextRequest, NextResponse } from 'next/server';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import {
  mpPreApproval,
  mpPreference,
  ALLOWED_PLAN_IDS,
  MP_EXCLUDED_PAYMENT_TYPES,
  toMajorUnits,
} from '@/lib/mercadopago/server';
import { PLANS } from '@/lib/mercadopago/plans';
import { createClient } from '@/lib/supabase/server';

// In-memory rate limiter (5 req / user / hour). Reset on server restart.
// TODO: replace con Upstash Redis si app va a prod multi-instance.
const RATE_LIMIT = 5;
const WINDOW_MS = 60 * 60 * 1000;
const userBuckets = new Map<string, { count: number; resetAt: number }>();

function rateLimitOk(userId: string): boolean {
  const now = Date.now();
  const bucket = userBuckets.get(userId);
  if (!bucket || now > bucket.resetAt) {
    userBuckets.set(userId, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (bucket.count >= RATE_LIMIT) return false;
  bucket.count++;
  return true;
}

const InputSchema = z.object({
  planId: z.string().regex(/^[a-z0-9_-]{2,40}$/),
});

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  if (!rateLimitOk(user.id)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  const contentType = request.headers.get('content-type') ?? '';
  const raw = contentType.includes('application/json')
    ? await request.json()
    : Object.fromEntries((await request.formData()).entries());
  const parsed = InputSchema.safeParse(raw);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
  }

  // L-003: whitelist enforcement contra ALLOWED_PLAN_IDS del env
  if (!ALLOWED_PLAN_IDS.includes(parsed.data.planId)) {
    return NextResponse.json({ error: 'Plan not available' }, { status: 400 });
  }
  const plan = PLANS[parsed.data.planId];
  if (!plan) {
    return NextResponse.json({ error: 'Plan not available' }, { status: 400 });
  }

  const appUrl = process.env.NEXT_PUBLIC_APP_URL!;
  const idempotencyKey = randomUUID(); // PAY-003: nunca Math.random()/Date.now()
  const amountMajor = toMajorUnits(plan.amountMinor, plan.currency); // PAY-004

  if (plan.interval) {
    // Suscripción hosted: el payer autoriza en init_point; el webhook subscription_preapproval activa.
    const pre = await mpPreApproval.create({
      body: {
        reason: plan.name,
        auto_recurring: {
          frequency: 1,
          frequency_type: plan.interval === 'year' ? 'months' : 'months',
          ...(plan.interval === 'year' ? { frequency: 12 } : {}),
          transaction_amount: amountMajor,
          currency_id: plan.currency.toUpperCase(),
        },
        payer_email: user.email!,
        back_url: `${appUrl}/success`,
        external_reference: user.id, // L-002: se re-valida (UUID) en el webhook
        status: 'pending',
        ...(plan.preapprovalPlanId ? { preapproval_plan_id: plan.preapprovalPlanId } : {}),
      },
      requestOptions: { idempotencyKey },
    });
    return NextResponse.json({ url: pre.init_point });
  }

  // Pago único: Checkout Pro (Preference). Rails MX: tarjeta + OXXO (ticket) + SPEI (bank_transfer).
  const pref = await mpPreference.create({
    body: {
      items: [
        {
          id: plan.id,
          title: plan.name,
          quantity: 1,
          unit_price: amountMajor,
          currency_id: plan.currency.toUpperCase(),
        },
      ],
      payer: { email: user.email! },
      back_urls: {
        success: `${appUrl}/success`,
        failure: `${appUrl}/pricing?reason=failure`,
        pending: `${appUrl}/success?pending=1`,
      },
      auto_return: 'approved',
      notification_url: `${appUrl}/api/webhooks/mercadopago`,
      external_reference: user.id,
      payment_methods: {
        excluded_payment_types: MP_EXCLUDED_PAYMENT_TYPES,
        installments: plan.maxInstallments ?? 1,
      },
      metadata: { user_id: user.id, plan_id: plan.id },
    },
    requestOptions: { idempotencyKey },
  });

  return NextResponse.json({ url: pref.init_point });
}
