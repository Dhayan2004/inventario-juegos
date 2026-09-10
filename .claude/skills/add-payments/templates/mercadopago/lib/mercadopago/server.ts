/**
 * Mercado Pago SDK — server side (Mode C, LATAM default).
 *
 * MP recibe montos en UNIDAD MAYOR (199.00, no 19900) y cada moneda tiene su
 * exponente ISO 4217 (MXN 2, CLP 0) — `references/currencies.md` (generado del
 * catálogo vendored). NUNCA `amount * 100` a ciegas (PAY-004).
 *
 * Rails irreversibles (OXXO = ticket, SPEI = bank_transfer): NO existe "refund
 * automático" — el camino es payout manual con confirmación humana (R14, PAY-006).
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-002]
 *       · [memory:references#R-012] (catálogo PagoKit) · [docs:mercadopago@v2]
 * @see docs/security/VETTING-pagokit-0.2.2.md (esquema de firma re-verificado)
 */
import 'server-only';
import { MercadoPagoConfig, Payment, PaymentRefund, Preference, PreApproval } from 'mercadopago';

if (!process.env.MP_ACCESS_TOKEN) {
  throw new Error('MP_ACCESS_TOKEN no está definida. Ver .env.example (Dashboard → Tus credenciales).');
}

export const mpClient = new MercadoPagoConfig({
  accessToken: process.env.MP_ACCESS_TOKEN.trim(),
  options: { timeout: 5000 },
});

export const mpPayment = new Payment(mpClient);
export const mpRefund = new PaymentRefund(mpClient);
export const mpPreference = new Preference(mpClient);
export const mpPreApproval = new PreApproval(mpClient);

/** Secret de "Webhooks → Configurar notificación". .trim() obligatorio (fallo silencioso de firma). */
export const MP_WEBHOOK_SECRET = process.env.MP_WEBHOOK_SECRET?.trim() ?? '';

/** Sandbox si el access token es de prueba (prefijo TEST-). */
export const MP_IS_SANDBOX = process.env.MP_ACCESS_TOKEN.trim().startsWith('TEST-');

/** L-003 whitelist de planes (IDs propios, NO montos del cliente). */
export const ALLOWED_PLAN_IDS = [
  process.env.NEXT_PUBLIC_MP_PLAN_ID_HOBBY,
  process.env.NEXT_PUBLIC_MP_PLAN_ID_PRO,
  process.env.NEXT_PUBLIC_MP_PLAN_ID_TEAM,
].filter((id): id is string => Boolean(id));

/** Exponente ISO 4217 — subconjunto LATAM. Fuente completa: references/currencies.md (PAY-004). */
export const CURRENCY_EXPONENT: Record<string, number> = {
  MXN: 2, USD: 2, BRL: 2, ARS: 2, COP: 2, PEN: 2, UYU: 2, CLP: 0,
};

/** Unidades menores (DB) → unidad mayor (API de MP). Lanza si la moneda no está tabulada. */
export function toMajorUnits(amountMinor: number, currency: string): number {
  const exp = CURRENCY_EXPONENT[currency.toUpperCase()];
  if (exp === undefined) throw new Error(`Moneda sin exponente tabulado: ${currency} (ver references/currencies.md)`);
  return exp === 0 ? amountMinor : Number((amountMinor / 10 ** exp).toFixed(exp));
}

/** Unidad mayor (API de MP) → unidades menores (DB). */
export function toMinorUnits(amountMajor: number, currency: string): number {
  const exp = CURRENCY_EXPONENT[currency.toUpperCase()];
  if (exp === undefined) throw new Error(`Moneda sin exponente tabulado: ${currency} (ver references/currencies.md)`);
  return Math.round(amountMajor * 10 ** exp);
}

/**
 * Tipos de pago habilitados en el checkout (MP `payment_methods.excluded_payment_types`).
 * Default MX: tarjeta + OXXO (ticket) + SPEI (bank_transfer). Override por env, coma-separado.
 * Valores MP: credit_card · debit_card · ticket · bank_transfer · atm · account_money.
 */
const ALL_PAYMENT_TYPES = ['credit_card', 'debit_card', 'ticket', 'bank_transfer', 'atm', 'account_money'] as const;
export type MpPaymentType = (typeof ALL_PAYMENT_TYPES)[number];
export const MP_ALLOWED_PAYMENT_TYPES: MpPaymentType[] = (process.env.MP_ALLOWED_PAYMENT_TYPES ?? 'credit_card,debit_card,ticket,bank_transfer')
  .split(',')
  .map((s) => s.trim())
  .filter((s): s is MpPaymentType => (ALL_PAYMENT_TYPES as readonly string[]).includes(s));
export const MP_EXCLUDED_PAYMENT_TYPES = ALL_PAYMENT_TYPES
  .filter((t) => !MP_ALLOWED_PAYMENT_TYPES.includes(t))
  .map((id) => ({ id }));

/**
 * Rails sin reverso automático (PAY-006). `payment_type_id` de MP:
 *   ticket (OXXO, Boleto, Rapipago, PagoEfectivo) · bank_transfer (SPEI, Pix, PSE) · atm.
 * Un "refund" sobre estos NO es una operación del proveedor: es un payout manual (R14).
 */
export const IRREVERSIBLE_PAYMENT_TYPES = ['ticket', 'bank_transfer', 'atm'] as const;
export function isIrreversible(paymentTypeId: string | null | undefined): boolean {
  return !!paymentTypeId && (IRREVERSIBLE_PAYMENT_TYPES as readonly string[]).includes(paymentTypeId);
}

/** Portal de suscripciones del payer (MP no tiene Customer Portal embebible). */
export const MP_SUBSCRIPTIONS_PORTAL_URL =
  process.env.MP_SUBSCRIPTIONS_PORTAL_URL ?? 'https://www.mercadopago.com.mx/subscriptions';
