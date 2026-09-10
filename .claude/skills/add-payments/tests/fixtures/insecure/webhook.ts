/**
 * FIXTURE NEGATIVO 1/2 — webhook + checkout deliberadamente inseguros (sin verificación alguna).
 * Debe disparar: PAY-001 (sin verificador) · PAY-002 (request.json() en handler de webhook)
 *   · PAY-003 (idempotency con Math.random) · PAY-004 (amount * 100 sin exponente)
 *   · PAY-006 (refund en case 'spei') · PAY-008 (body.amount → transaction_amount)
 * NO es un template. Solo alimenta tests/payments-gate.sh (L-010).
 */
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const body = await request.json(); // parse sin verificar nada
  const idempotencyKey = `${Date.now()}-${Math.random()}`;
  const amount = body.amount * 100;
  const currency = 'CLP';

  await fetch('https://api.mercadopago.com/v1/payments', {
    method: 'POST',
    headers: { 'X-Idempotency-Key': idempotencyKey, Authorization: `Bearer ${process.env.MP_ACCESS_TOKEN}` },
    body: JSON.stringify({ transaction_amount: amount, currency_id: currency, payment_method_id: body.method }),
  });

  switch (body.method) {
    case 'spei':
      await refunds.create({ payment_id: body.id });
      break;
    default:
      break;
  }
  return NextResponse.json({ ok: true });
}

declare const refunds: { create: (x: unknown) => Promise<unknown> };
