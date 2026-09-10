/**
 * POST /api/stripe/refund-request
 *
 * Endpoint que delega a server action `requestRefund` (definida en
 * @/actions/stripe). El route NO ejecuta refund directo — solo proxy
 * para clientes que prefieren API sobre form action.
 *
 * R14 enforcement: el server action contiene los 5 gates (auth +
 * input validation + ownership + audit log + execute). Esta route
 * NO bypassa esos gates — solo invoca el server action y devuelve
 * el resultado.
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { requestRefund } from '@/actions/stripe';

export async function POST(request: NextRequest) {
  const formData = await request.formData();

  // El server action retorna { success: true, refundId } o { error: '...' }.
  // R14 gates corren dentro del action — esta route NO los duplica ni omite.
  const result = await requestRefund(null, formData);

  if (result && 'error' in result && result.error) {
    return NextResponse.json({ error: result.error }, { status: 400 });
  }

  return NextResponse.json(result);
}
