/**
 * POST /api/stripe/portal
 *
 * Crea Stripe Customer Portal session — full URL redirect.
 *
 * Cita: [memory:lessons#L-001] (RLS-protected query)
 *       · [docs:stripe-node@v18]
 */
import { NextRequest, NextResponse } from 'next/server';
import { stripe } from '@/lib/stripe/server';
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
    .in('status', ['active', 'trialing', 'past_due'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!sub?.external_customer_id) {
    return NextResponse.json({ error: 'No active subscription' }, { status: 404 });
  }

  const portal = await stripe.billingPortal.sessions.create({
    customer: sub.external_customer_id,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing`,
  });

  return NextResponse.json({ url: portal.url });
}
