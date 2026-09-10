/**
 * POST /api/mercadopago/portal
 *
 * MP no tiene Customer Portal embebible (a diferencia de Stripe): el payer
 * gestiona sus suscripciones en su cuenta de Mercado Pago. Esta route valida
 * que exista una suscripción y devuelve la URL del portal del payer; la
 * cancelación/pausa desde nuestra app va por el server action (R14).
 *
 * Cita: [memory:lessons#L-001] (RLS-protected query) · [docs:mercadopago@v2]
 */
import { NextRequest, NextResponse } from 'next/server';
import { MP_SUBSCRIPTIONS_PORTAL_URL } from '@/lib/mercadopago/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(_request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_subscription_id')
    .eq('user_id', user.id)
    .eq('provider', 'mercadopago')
    .in('status', ['active', 'trialing', 'past_due', 'paused'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!sub?.external_subscription_id) {
    return NextResponse.json({ error: 'No active subscription' }, { status: 404 });
  }

  return NextResponse.json({ url: MP_SUBSCRIPTIONS_PORTAL_URL });
}
