/**
 * POST /api/stripe/checkout
 *
 * Crea Stripe Checkout Session para subscription.
 *
 * Rate limit: max 5 sessions / user / hour (anti-abuse).
 * En dev, in-memory Map suficiente. En prod, considerar Upstash o similar.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-003]
 *       · [docs:stripe-node@v18] · [docs:nextjs]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { stripe, ALLOWED_PRICE_IDS } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';

// In-memory rate limiter (5 req / user / hour). Reset on server restart.
// TODO: replace con Upstash Redis si app va a prod multi-instance.
const RATE_LIMIT = 5;
const WINDOW_MS = 60 * 60 * 1000;
const userBuckets = new Map<string, { count: number; resetAt: number }>();

function rateLimitOk(userId: string): boolean {
  const now = Date.now();
  const bucket = userBuckets.get(userId);
  if (!bucket || now > bucket.resetAt) {
    userBuckets.set(userId, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (bucket.count >= RATE_LIMIT) return false;
  bucket.count++;
  return true;
}

const InputSchema = z.object({
  priceId: z.string().regex(/^price_[a-zA-Z0-9]{20,}$/),
});

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  if (!rateLimitOk(user.id)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  const body = await request.json();
  const parsed = InputSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
  }

  // L-003: whitelist enforcement contra ALLOWED_PRICE_IDS del env
  if (!ALLOWED_PRICE_IDS.includes(parsed.data.priceId)) {
    return NextResponse.json({ error: 'Price not available' }, { status: 400 });
  }

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    line_items: [{ price: parsed.data.priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing`,
    customer_email: user.email!,
    client_reference_id: user.id,
    metadata: { user_id: user.id },
    subscription_data: { metadata: { user_id: user.id } },
    automatic_tax: { enabled: true }, // requiere Stripe Tax habilitado en dashboard
  });

  return NextResponse.json({ url: session.url });
}
