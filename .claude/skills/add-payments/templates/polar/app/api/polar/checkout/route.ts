/**
 * POST /api/polar/checkout
 *
 * Crea Polar Checkout — full URL redirect.
 *
 * Rate limit: max 5 sessions / user / hour (anti-abuse).
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-003]
 *       · [docs:polar-sdk@v0.x] · [docs:nextjs]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { polar, ALLOWED_PRODUCT_IDS, POLAR_PRODUCT_ID } from '@/lib/polar/server';
import { createClient } from '@/lib/supabase/server';

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
  productId: z.string().optional(),
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

  let body: unknown = {};
  try {
    body = await request.json();
  } catch {
    body = {};
  }
  const parsed = InputSchema.safeParse(body);
  const productId = parsed.success && parsed.data.productId ? parsed.data.productId : POLAR_PRODUCT_ID;

  // L-003 whitelist
  if (!ALLOWED_PRODUCT_IDS.includes(productId)) {
    return NextResponse.json({ error: 'Product not available' }, { status: 400 });
  }

  const checkout = await polar.checkouts.custom.create({
    productId,
    successUrl: `${process.env.NEXT_PUBLIC_APP_URL}/success?checkout_id={CHECKOUT_ID}`,
    customerEmail: user.email!,
    metadata: {
      user_id: user.id,
      product_type: 'subscription',
    },
  });

  return NextResponse.json({ url: checkout.url });
}
