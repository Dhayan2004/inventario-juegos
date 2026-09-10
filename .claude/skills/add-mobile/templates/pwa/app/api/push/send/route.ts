/**
 * POST /api/push/send
 *
 * Auth: solo service_role bearer token (server-to-server invocation).
 * Rate limit: 10 push/user/hour para flows individuales.
 * Bulk via separate authenticated admin route (R14 gates en actions/notifications.ts).
 *
 * Cita: [memory:lessons#L-002] · [memory:lessons#L-003] · [memory:CONSTRAINTS.md#R13..14]
 *       · [docs:web-push-libs]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createAdminClient } from '@/lib/supabase/admin';
import { webpush, ALLOWED_TOPICS, isAppleEndpoint } from '@/lib/push/server';

// Rate limiter (in-memory). Para producción, usar Upstash Redis.
const RATE_LIMIT = 10;
const WINDOW_MS = 60 * 60 * 1000;
const userBuckets = new Map<string, { count: number; resetAt: number }>();
function rateLimitOk(userId: string): boolean {
  const now = Date.now();
  const b = userBuckets.get(userId);
  if (!b || now > b.resetAt) {
    userBuckets.set(userId, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (b.count >= RATE_LIMIT) return false;
  b.count++;
  return true;
}

const SendSchema = z.object({
  userId: z.string().uuid(),
  notification: z.object({
    title: z.string().min(1).max(50),
    body: z.string().max(150),
    topic: z.enum(ALLOWED_TOPICS),
    url: z.string().url().optional(),
    tag: z.string().max(64).optional(),
  }),
});

export async function POST(request: NextRequest) {
  // Auth: solo service_role
  const authHeader = request.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();
  const parsed = SendSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid' },
      { status: 400 }
    );
  }

  if (!rateLimitOk(parsed.data.userId)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  const admin = createAdminClient();

  // Topic preference check
  const { data: pref } = await admin
    .from('push_topic_preferences')
    .select('enabled')
    .eq('user_id', parsed.data.userId)
    .eq('topic', parsed.data.notification.topic)
    .maybeSingle();

  if (pref && pref.enabled === false) {
    return NextResponse.json({ skipped: true, reason: 'topic_disabled' });
  }

  // Fetch user subscriptions
  const { data: subs } = await admin
    .from('push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .eq('user_id', parsed.data.userId);

  if (!subs?.length) {
    return NextResponse.json({ success: true, sent: 0 });
  }

  let sent = 0;
  let failed = 0;

  for (const sub of subs) {
    try {
      await webpush.sendNotification(
        {
          endpoint: sub.endpoint,
          keys: { p256dh: sub.p256dh, auth: sub.auth },
        },
        JSON.stringify(parsed.data.notification)
      );

      await admin
        .from('push_subscriptions')
        .update({ last_used_at: new Date().toISOString() })
        .eq('id', sub.id);

      sent++;
    } catch (err: any) {
      const status = err.statusCode;
      // 410 Gone = subscription invalidada → delete.
      // Apple silent failure (statusCode undefined) on Apple endpoint → conservative delete.
      // 429 rate limit → mantener (retryable).
      if (
        status === 410 ||
        status === 404 ||
        (!status && isAppleEndpoint(sub.endpoint))
      ) {
        await admin
          .from('push_subscriptions')
          .delete()
          .eq('id', sub.id);
      }
      failed++;
    }
  }

  return NextResponse.json({ success: true, sent, failed });
}
