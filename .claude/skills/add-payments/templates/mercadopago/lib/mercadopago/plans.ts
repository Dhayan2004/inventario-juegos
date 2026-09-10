/**
 * Catálogo de planes — SERVER SIDE (PAY-008: el precio nunca viene del cliente).
 *
 * Montos en UNIDADES MENORES (centavos para MXN, entero para CLP) + moneda con
 * exponente ISO 4217 (`references/currencies.md`). `toMajorUnits` convierte al
 * formato de MP en el momento de crear la Preference / PreApproval.
 *
 * Los IDs se whitelistean vía NEXT_PUBLIC_MP_PLAN_ID_* (ALLOWED_PLAN_IDS, L-003).
 * `preapprovalPlanId` es opcional: si el plan existe en el dashboard de MP, se cita.
 *
 * Cita: [memory:lessons#L-003] · [memory:references#R-012]
 */
import 'server-only';
import type { BillingInterval, Currency } from '@/types/billing';

export interface MpPlan {
  id: string;
  name: string;
  amountMinor: number;
  currency: Currency;
  /** undefined = pago único (Preference); 'month' | 'year' = suscripción (PreApproval). */
  interval?: BillingInterval;
  maxInstallments?: number;
  preapprovalPlanId?: string;
}

export const PLANS: Record<string, MpPlan> = {
  hobby: { id: 'hobby', name: 'Hobby', amountMinor: 0, currency: 'mxn', interval: 'month' },
  pro: { id: 'pro', name: 'Pro', amountMinor: 49900, currency: 'mxn', interval: 'month', preapprovalPlanId: process.env.MP_PREAPPROVAL_PLAN_PRO },
  team: { id: 'team', name: 'Team', amountMinor: 149900, currency: 'mxn', interval: 'month', preapprovalPlanId: process.env.MP_PREAPPROVAL_PLAN_TEAM },
};
