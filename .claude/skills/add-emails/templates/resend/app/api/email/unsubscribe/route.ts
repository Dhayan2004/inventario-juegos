/**
 * GET /api/email/unsubscribe?token=<jwt>
 * POST /api/email/unsubscribe?token=<jwt>  (RFC 8058 mandates same handler)
 *
 * One-Click Unsubscribe handler — token-based, NO user authentication.
 *
 * Cita: [docs:rfc8058] · [memory:lessons#L-002] · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { jwtVerify } from 'jose';
import { createAdminClient } from '@/lib/supabase/admin';

const TokenPayload = z.object({
  email: z.string().email(),
  user_id: z.string().uuid(),
  scope: z.enum(['marketing', 'product_updates', 'all']),
  iat: z.number(),
  exp: z.number(),
});

export async function GET(request: NextRequest) {
  const token = request.nextUrl.searchParams.get('token');
  if (!token) {
    return NextResponse.redirect(new URL('/unsubscribed?error=missing_token', request.url));
  }

  let payload;
  try {
    const secret = new TextEncoder().encode(process.env.UNSUBSCRIBE_JWT_SECRET);
    const { payload: jwt } = await jwtVerify(token, secret);
    payload = TokenPayload.parse(jwt);
  } catch {
    return NextResponse.redirect(new URL('/unsubscribed?error=invalid_token', request.url));
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

  return NextResponse.redirect(new URL('/unsubscribed', request.url));
}

// RFC 8058: POST con body `List-Unsubscribe=One-Click` debe usar mismo handler
export async function POST(request: NextRequest) {
  return GET(request);
}
