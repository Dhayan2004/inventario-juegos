/**
 * POST /api/push/subscribe
 *
 * Auth required (user must be logged in). Idempotent (UPSERT on
 * unique(user_id, endpoint)). Optional: cleanup oldEndpoint on rotation.
 *
 * Cita: [memory:lessons#L-001] (RLS) · [memory:lessons#L-003] (input whitelist)
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

const SubscriptionSchema = z.object({
  subscription: z.object({
    endpoint: z.string().url().max(500),
    keys: z.object({
      p256dh: z.string().min(1).max(200),
      auth: z.string().min(1).max(100),
    }),
  }),
  deviceInfo: z.object({
    platform: z.string().max(64).optional(),
    language: z.string().max(16).optional(),
    userAgent: z.string().max(500).optional(),
  }).optional(),
  oldEndpoint: z.string().url().max(500).optional(),
});

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();
  const parsed = SubscriptionSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid' },
      { status: 400 }
    );
  }

  const { subscription, deviceInfo, oldEndpoint } = parsed.data;
  const admin = createAdminClient();

  // Cleanup old endpoint if rotation
  if (oldEndpoint) {
    await admin
      .from('push_subscriptions')
      .delete()
      .eq('endpoint', oldEndpoint)
      .eq('user_id', user.id);
  }

  // Upsert (idempotent)
  const { data, error } = await admin
    .from('push_subscriptions')
    .upsert(
      {
        user_id: user.id,
        endpoint: subscription.endpoint,
        p256dh: subscription.keys.p256dh,
        auth: subscription.keys.auth,
        browser: deviceInfo?.platform ?? null,
        user_agent: deviceInfo?.userAgent ?? null,
        last_used_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,endpoint' }
    )
    .select('id')
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true, subscription_id: data.id });
}
