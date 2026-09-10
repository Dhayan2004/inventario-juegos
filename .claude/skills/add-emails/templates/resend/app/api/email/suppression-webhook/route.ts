/**
 * Resend suppression webhook.
 *
 * 6 phases canónicas (mirror add-payments webhook):
 *   1. Read raw body
 *   2. Verify signature (Svix)
 *   3. Treat-as-data (L-002 — payload validated via Zod schema)
 *   4. Switch event.type whitelist (default: log + return)
 *   5. Idempotency check (external_event_id)
 *   6. DB op via service_role
 *
 * Cita: [memory:lessons#L-002] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:resend@latest]
 */
import { NextRequest, NextResponse } from 'next/server';
import { Webhook } from 'svix';
import { z } from 'zod';
import { createAdminClient } from '@/lib/supabase/admin';
import { RESEND_WEBHOOK_SECRET } from '@/lib/resend/server';

export const dynamic = 'force-dynamic';

const ResendEventSchema = z.object({
  type: z.enum([
    'email.sent', 'email.delivered', 'email.bounced',
    'email.complained', 'email.opened', 'email.clicked',
    'email.delivery_delayed',
  ]),
  data: z.object({
    email_id: z.string(),
    to: z.array(z.string().email()).or(z.string().email()),
    bounce: z.object({
      type: z.enum(['hard', 'soft', 'undetermined']),
      message: z.string().max(1024).optional(),
    }).optional(),
  }).passthrough(),
  created_at: z.string(),
});

export async function POST(request: NextRequest) {
  const body = await request.text();
  const headers = {
    'svix-id': request.headers.get('svix-id') ?? '',
    'svix-timestamp': request.headers.get('svix-timestamp') ?? '',
    'svix-signature': request.headers.get('svix-signature') ?? '',
  };

  let event: unknown;
  try {
    const wh = new Webhook(RESEND_WEBHOOK_SECRET);
    event = wh.verify(body, headers);
  } catch (err) {
    console.error('[Webhook] Resend signature verification failed', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }

  const parsed = ResendEventSchema.safeParse(event);
  if (!parsed.success) {
    console.error('[Webhook] event shape invalid', parsed.error);
    return NextResponse.json({ received: true }); // 200 — anti retry storm
  }

  const supabase = createAdminClient();
  const eventData = parsed.data.data;
  const recipient = Array.isArray(eventData.to) ? eventData.to[0] : eventData.to;
  const eventId = `${eventData.email_id}_${parsed.data.type}`;

  // Idempotency
  const { data: existing } = await supabase
    .from('email_events')
    .select('id')
    .eq('external_event_id', eventId)
    .maybeSingle();
  if (existing) {
    return NextResponse.json({ received: true, skipped: 'duplicate' });
  }

  // Log event
  await supabase.from('email_events').insert({
    external_event_id: eventId,
    event_type: parsed.data.type,
    recipient_email: recipient.toLowerCase(),
    metadata: eventData as Record<string, unknown>,
    occurred_at: parsed.data.created_at,
  });

  // Suppression update
  switch (parsed.data.type) {
    case 'email.bounced':
      if (eventData.bounce?.type === 'hard') {
        await supabase.from('suppression_list').upsert(
          { email: recipient.toLowerCase(), reason: 'hard_bounce', suppressed_at: new Date().toISOString() },
          { onConflict: 'email' }
        );
      }
      break;
    case 'email.complained':
      await supabase.from('suppression_list').upsert(
        { email: recipient.toLowerCase(), reason: 'spam_complaint', suppressed_at: new Date().toISOString() },
        { onConflict: 'email' }
      );
      break;
    default:
      // No suppression action — log only
      break;
  }

  return NextResponse.json({ received: true });
}
