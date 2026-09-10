/**
 * FIXTURE NEGATIVO 2/2 — verificador "hecho a mano" mal hecho.
 * Debe disparar: PAY-005 (=== sobre la firma) · PAY-007 (HMAC keyed con MP_ACCESS_TOKEN).
 * NO es un template. Solo alimenta tests/payments-gate.sh (L-010).
 */
import { NextRequest, NextResponse } from 'next/server';
import { createHmac } from 'node:crypto';

export async function POST(request: NextRequest) {
  const raw = await request.text();
  const sig = request.headers.get('x-signature') ?? '';
  const expected = createHmac('sha256', process.env.MP_ACCESS_TOKEN!).update(raw).digest('hex');
  if (sig !== expected) return NextResponse.json({ error: 'bad' }, { status: 400 });
  return NextResponse.json({ ok: true });
}
