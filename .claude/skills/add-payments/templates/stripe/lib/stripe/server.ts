/**
 * Stripe SDK — server side.
 *
 * - STRIPE_SECRET_KEY isolation: 'server-only' import previene leak a client bundle.
 * - .trim() en webhook secret: espacios invisibles en .env rompen signature
 *   verification silenciosamente.
 * - apiVersion pinning: el shape de Stripe responses cambia entre versions —
 *   sin pin, runtime drift inesperado al rotar API.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-002] · [docs:stripe-node@v18]
 *
 * @see https://docs.stripe.com/api/versioning
 */
import 'server-only';
import Stripe from 'stripe';

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error('STRIPE_SECRET_KEY missing');
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY.trim(), {
  // Pin explicit — invocá find-docs("stripe-node") para confirmar latest stable.
  apiVersion: '{{ STRIPE_API_VERSION }}', // ej: '2024-12-18.acacia'
  typescript: true,
  appInfo: {
    name: '{{ APP_NAME }}',
  },
});

/** Webhook secret con .trim() obligatorio. */
export const STRIPE_WEBHOOK_SECRET =
  process.env.STRIPE_WEBHOOK_SECRET?.trim() ?? '';

/** Allowed price IDs (whitelist L-003). */
export const ALLOWED_PRICE_IDS = [
  process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_HOBBY,
  process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_PRO,
  process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_TEAM,
].filter((id): id is string => Boolean(id));
