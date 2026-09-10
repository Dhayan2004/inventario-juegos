/**
 * POST /api/polar/portal
 *
 * Crea Polar Customer Portal session — URL externa polar.sh redirect.
 *
 * Cita: [memory:lessons#L-001] (RLS-protected query) · [docs:polar-sdk@v0.x]
 */
import { NextRequest, NextResponse } from 'next/server';
import { polar } from '@/lib/polar/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(_request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_customer_id')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!sub?.external_customer_id) {
    return NextResponse.json({ error: 'No active subscription' }, { status: 404 });
  }

  const session = await polar.customerSessions.create({
    customer_id: sub.external_customer_id,
  });

  return NextResponse.json({ url: session.customer_portal_url });
}
