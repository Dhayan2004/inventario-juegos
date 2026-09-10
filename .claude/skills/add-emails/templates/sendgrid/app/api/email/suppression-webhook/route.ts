/**
 * SendGrid Event Webhook (suppression + delivery + bounces).
 *
 * 6 phases canónicas (mirror Mode A + add-payments webhook):
 *   1. Read raw body (request.text())
 *   2. Verify ECDSA signature (NO HMAC) — public-key based via
 *      @sendgrid/eventwebhook EventWebhook helper
 *   3. Treat-as-data (L-002 — payload validated via Zod schema)
 *   4. Iterate event array, switch event whitelist (default: log + continue)
 *   5. Idempotency check (sg_event_id)
 *   6. DB op via service_role
 *
 * Diferencias clave vs Mode A:
 *   - Resend manda 1 evento por request (Svix); SendGrid manda batches (array)
 *   - Resend usa HMAC SHA256; SendGrid usa ECDSA P-256
 *   - Event types diferentes: bounce/dropped/spamreport/unsubscribe
 *
 * Cita: [memory:lessons#L-002] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:sendgrid-mail@v8] · [docs:sendgrid]
 */
import { NextRequest, NextResponse } from 'next/server';
import { EventWebhook, EventWebhookHeader } from '@sendgrid/eventwebhook';
import { z } from 'zod';
import { createAdminClient } from '@/lib/supabase/admin';
import { SENDGRID_WEBHOOK_PUBLIC_KEY } from '@/lib/sendgrid/server';

export const dynamic = 'force-dynamic';

const SendGridEventSchema = z.object({
  email: z.string().email().max(254),
  timestamp: z.number(),
  event: z.enum([
    'processed',
    'delivered',
    'open',
    'click',
    'bounce',
    'dropped',
    'deferred',
    'spamreport',
    'unsubscribe',
    'group_unsubscribe',
    'group_resubscribe',
  ]),
  sg_event_id: z.string(),
  sg_message_id: z.string().optional(),
  type: z.enum(['bounce', 'blocked', 'expired']).optional(), // bounce sub-type
  reason: z.string().max(2048).optional(),
  status: z.string().max(64).optional(),
});

const EventArraySchema = z.array(SendGridEventSchema);

function lowerEmail(email: string): string {
  return email.toLowerCase();
}

export async function POST(request: NextRequest) {
  // 1. Raw body (mandatory antes de signature)
  const body = await request.text();

  const sig = request.headers.get(EventWebhookHeader.SIGNATURE()) ?? '';
  const ts = request.headers.get(EventWebhookHeader.TIMESTAMP()) ?? '';

  // 2. ECDSA signature verification (NO HMAC). FAIL FAST 401 si bad sig.
  if (!SENDGRID_WEBHOOK_PUBLIC_KEY || !sig || !ts) {
    return NextResponse.json({ error: 'Signature missing' }, { status: 401 });
  }

  try {
    const ew = new EventWebhook();
    const ecPublicKey = ew.convertPublicKeyToECDSA(SENDGRID_WEBHOOK_PUBLIC_KEY);
    const valid = ew.verifySignature(ecPublicKey, body, sig, ts);
    if (!valid) {
      console.error('[Webhook] SendGrid signature invalid');
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }
  } catch (err) {
    console.error('[Webhook] SendGrid signature verification error', err);
    return NextResponse.json(
      { error: 'Signature verification failed' },
      { status: 401 }
    );
  }

  // 3. Parse + treat as data (L-002)
  let events;
  try {
    events = EventArraySchema.parse(JSON.parse(body));
  } catch (err) {
    console.error('[Webhook] event payload shape invalid', err);
    return NextResponse.json({ received: true }); // 200 — anti retry storm
  }

  const supabase = createAdminClient();

  // 4. Iterate batched events
  for (const ev of events) {
    const recipient = lowerEmail(ev.email);
    const eventId = ev.sg_event_id;

    // 5. Idempotency
    const { data: existing } = await supabase
      .from('email_events')
      .select('id')
      .eq('external_event_id', eventId)
      .maybeSingle();
    if (existing) continue; // Duplicate event — skip

    // 6. Log
    await supabase.from('email_events').insert({
      external_event_id: eventId,
      event_type: ev.event,
      recipient_email: recipient,
      metadata: ev as Record<string, unknown>,
      occurred_at: new Date(ev.timestamp * 1000).toISOString(),
    });

    // Suppression updates per event type
    switch (ev.event) {
      case 'bounce':
        // SendGrid bounce.type: 'bounce' (hard) | 'blocked' | 'expired'
        // Solo hard bounces → suppress (block + expired son temporales)
        if (ev.type === 'bounce') {
          await supabase.from('suppression_list').upsert(
            {
              email: recipient,
              reason: 'hard_bounce',
              suppressed_at: new Date().toISOString(),
            },
            { onConflict: 'email' }
          );
        }
        break;
      case 'spamreport':
        await supabase.from('suppression_list').upsert(
          {
            email: recipient,
            reason: 'spam_complaint',
            suppressed_at: new Date().toISOString(),
          },
          { onConflict: 'email' }
        );
        break;
      case 'dropped':
        // SendGrid dropped antes de envío (suppression list, invalid email,
        // unsubscribe). Log only — la suppression ya existe en SendGrid.
        break;
      case 'unsubscribe':
      case 'group_unsubscribe':
        // SendGrid maneja unsubscribe groups internamente. Reflejar
        // en nuestra tabla email_subscriptions para coherencia local.
        break;
      default:
        // processed / delivered / open / click / deferred / group_resubscribe
        // — log only (anti retry storm).
        break;
    }
  }

  return NextResponse.json({ received: true, processed: events.length });
}
