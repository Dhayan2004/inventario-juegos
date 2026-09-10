/**
 * POST /api/mercadopago/refund-request
 *
 * Endpoint que delega al server action `requestRefund` (definido en
 * @/actions/mercadopago). El route NO ejecuta refund directo — solo proxy
 * para clientes que prefieren API sobre form action.
 *
 * R14 enforcement: el server action contiene los 5 gates (auth +
 * input validation + ownership + audit log + execute) y el guard de rail
 * irreversible (PAY-006: OXXO/SPEI no se "reembolsan" — payout manual).
 * Esta route NO bypassa esos gates.
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { requestRefund } from '@/actions/mercadopago';

export async function POST(request: NextRequest) {
  const formData = await request.formData();

  // R14 gates corren dentro del action — esta route NO los duplica ni omite.
  const result = await requestRefund(null, formData);

  if (result && 'error' in result && result.error) {
    return NextResponse.json({ error: result.error }, { status: 400 });
  }

  return NextResponse.json(result);
}
