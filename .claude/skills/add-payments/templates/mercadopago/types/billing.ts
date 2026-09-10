/**
 * Shared billing types — Stripe + Polar + Mercado Pago.
 *
 * Montos SIEMPRE en unidades menores (`amount_cents` / `amount_minor`) con
 * exponente ISO 4217 por moneda (references/currencies.md — PAY-004).
 *
 * Cita: [memory:lessons#L-003] (whitelist enums) · [memory:references#R-005] · [memory:references#R-012]
 */

export type BillingProvider = 'stripe' | 'polar' | 'mercadopago';

export type BillingInterval = 'month' | 'year';

export type Currency = 'usd' | 'eur' | 'mxn' | 'ars' | 'cop' | 'brl' | 'clp' | 'pen' | 'uyu';

export type SubscriptionStatus =
  | 'incomplete'
  | 'incomplete_expired'
  | 'trialing'
  | 'active'
  | 'past_due'
  | 'canceled'
  | 'unpaid'
  | 'paused'
  | 'revoked';

export interface PricingTier {
  id: string;
  name: string;
  label: string;
  featured?: boolean;
  /** Unidades menores (centavos MXN; entero CLP). */
  amountCents: number;
  currency: Currency;
  interval: BillingInterval;
  features: string[];
  priceId: string; // Stripe: price_*; Polar: product_*; Mercado Pago: id de plan propio (whitelist L-003)
}

export interface Subscription {
  id: string;
  user_id: string;
  organization_id?: string | null;
  provider: BillingProvider;
  external_subscription_id: string;
  external_customer_id: string | null;
  external_checkout_id: string | null;
  status: SubscriptionStatus;
  current_period_end: string | null;
  cancel_at_period_end: boolean;
  amount_cents: number | null;
  currency: Currency | null;
  interval: BillingInterval | null;
  plan_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

/** Ledger de pagos (0003_payments_ledger.sql) — un renglón por pago del proveedor. */
export type PaymentStatus = 'pending' | 'succeeded' | 'failed' | 'canceled' | 'refunded' | 'disputed';

export interface PaymentRecord {
  id: string;
  user_id: string;
  organization_id: string | null;
  provider: BillingProvider;
  external_payment_id: string;
  amount_minor: number;
  currency: Currency;
  status: PaymentStatus;
  /** payment_method_id del proveedor (visa, oxxo, spei, pix…). */
  method: string | null;
  /** payment_type_id del proveedor (credit_card, ticket, bank_transfer…). */
  payment_type: string | null;
  /** false en rails irreversibles (OXXO/SPEI/Pix): el reverso es payout manual, R14. */
  refundable: boolean;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export type RefundReason =
  | 'requested_by_customer'
  | 'duplicate'
  | 'fraudulent'
  | 'cancel_subscription';

export type RefundStatus = 'pending' | 'completed' | 'failed';

export interface RefundRequest {
  id: string;
  user_id: string;
  charge_id: string;
  refund_id: string | null;
  reason: RefundReason;
  status: RefundStatus;
  error_message: string | null;
  requested_at: string;
  completed_at: string | null;
}
