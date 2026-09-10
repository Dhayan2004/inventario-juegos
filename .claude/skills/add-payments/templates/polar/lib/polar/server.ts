/**
 * Polar SDK — server side.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-002] · [docs:polar-sdk@v0.x]
 */
import 'server-only';
import { Polar } from '@polar-sh/sdk';

if (!process.env.POLAR_ACCESS_TOKEN) {
  throw new Error('POLAR_ACCESS_TOKEN missing');
}

const isSandbox = process.env.POLAR_ENVIRONMENT === 'sandbox';

export const polar = new Polar({
  accessToken: process.env.POLAR_ACCESS_TOKEN.trim(),
  server: isSandbox ? 'sandbox' : 'production',
});

/** Webhook secret con .trim() obligatorio. */
export const POLAR_WEBHOOK_SECRET =
  process.env.POLAR_WEBHOOK_SECRET?.trim() ?? '';

/** Product ID whitelist (single product en Polar default; extender si multi-tier). */
export const POLAR_PRODUCT_ID = process.env.POLAR_PRODUCT_ID ?? '';

export const ALLOWED_PRODUCT_IDS = [
  process.env.POLAR_PRODUCT_ID,
].filter((id): id is string => Boolean(id));
