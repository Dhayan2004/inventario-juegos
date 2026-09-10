/**
 * POST /api/polar/refund-request
 *
 * Proxy a server action `requestRefund` (en @/actions/polar) — los 5 R14
 * gates corren dentro del action, esta route NO los duplica ni omite.
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { requestRefund } from '@/actions/polar';

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const result = await requestRefund(null, formData);

  if (result && 'error' in result && result.error) {
    return NextResponse.json({ error: result.error }, { status: 400 });
  }

  return NextResponse.json(result);
}
