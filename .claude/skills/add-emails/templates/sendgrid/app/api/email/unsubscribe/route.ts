/**
 * GET /api/email/unsubscribe?token=<jwt>
 * POST /api/email/unsubscribe?token=<jwt>  (RFC 8058 mandates same handler)
 *
 * One-Click Unsubscribe handler — token-based, NO user authentication.
 *
 * Mode B (SendGrid): además de actualizar nuestra tabla email_subscriptions,
 * sincronizamos con SendGrid suppression group via v3 REST API para que el
 * provider deje de enviar — fuente de verdad cruzada.
 *
 * Cita: [docs:rfc8058] · [docs:sendgrid] · [memory:lessons#L-002..3]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { jwtVerify } from 'jose';
import { createAdminClient } from '@/lib/supabase/admin';
import { SENDGRID_UNSUBSCRIBE_GROUP_ID } from '@/lib/sendgrid/server';

const TokenPayload = z.object({
  email: z.string().email(),
  user_id: z.string().uuid(),
  scope: z.enum(['marketing', 'product_updates', 'all']),
  iat: z.number(),
  exp: z.number(),
});

async function syncSendGridSuppressionGroup(email: string): Promise<void> {
  if (!SENDGRID_UNSUBSCRIBE_GROUP_ID || !process.env.SENDGRID_API_KEY) return;
  try {
    await fetch(
      `https://api.sendgrid.com/v3/asm/groups/${SENDGRID_UNSUBSCRIBE_GROUP_ID}/suppressions`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${process.env.SENDGRID_API_KEY.trim()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ recipient_emails: [email.toLowerCase()] }),
      }
    );
  } catch (err) {
    // Sync best-effort: nuestra tabla manda, SendGrid es secondary.
    console.error('[Unsubscribe] SendGrid sync failed', err);
  }
}

export async function GET(request: NextRequest) {
  const token = request.nextUrl.searchParams.get('token');
  if (!token) {
    return NextResponse.redirect(
      new URL('/unsubscribed?error=missing_token', request.url)
    );
  }

  let payload;
  try {
    const secret = new TextEncoder().encode(process.env.UNSUBSCRIBE_JWT_SECRET);
    const { payload: jwt } = await jwtVerify(token, secret);
    payload = TokenPayload.parse(jwt);
  } catch {
    return NextResponse.redirect(
      new URL('/unsubscribed?error=invalid_token', request.url)
    );
  }

  const supabase = createAdminClient();
  await supabase.from('email_subscriptions').upsert(
    {
      user_id: payload.user_id,
      scope: payload.scope,
      unsubscribed_at: new Date().toISOString(),
    },
    { onConflict: 'user_id,scope' }
  );

  // Sync con SendGrid suppression group (best-effort)
  await syncSendGridSuppressionGroup(payload.email);

  return NextResponse.redirect(new URL('/unsubscribed', request.url));
}

// RFC 8058: POST con body `List-Unsubscribe=One-Click` debe usar mismo handler
export async function POST(request: NextRequest) {
  return GET(request);
}
