/**
 * Stripe SDK — client side.
 *
 * Solo expone la publishable key (NEXT_PUBLIC_*). Singleton pattern —
 * loadStripe corre una vez por session.
 *
 * Cita: [docs:stripe@v18]
 */
'use client';

import { loadStripe, type Stripe } from '@stripe/stripe-js';

let stripePromise: Promise<Stripe | null> | null = null;

export function getStripe(): Promise<Stripe | null> {
  if (!stripePromise) {
    const pk = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
    if (!pk) {
      console.error('NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY missing');
      return Promise.resolve(null);
    }
    stripePromise = loadStripe(pk);
  }
  return stripePromise;
}
