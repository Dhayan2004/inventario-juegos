/**
 * Resend SDK — server side.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-002..3] · [docs:resend@latest]
 */
import 'server-only';
import { Resend } from 'resend';

if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY missing');
}

export const resend = new Resend(process.env.RESEND_API_KEY.trim());

export const RESEND_WEBHOOK_SECRET =
  process.env.RESEND_WEBHOOK_SECRET?.trim() ?? '';

export const EMAIL_FROM =
  `${process.env.EMAIL_FROM_NAME ?? 'App'} <${process.env.EMAIL_FROM_ADDRESS ?? 'noreply@example.com'}>`;

export const ALLOWED_TEMPLATE_IDS = [
  'welcome',
  'magic_link',
  'password_reset',
  'invoice_receipt',
  'payment_failed',
  'subscription_canceled',
  'email_changed_confirmation',
] as const;
export type AllowedTemplateId = typeof ALLOWED_TEMPLATE_IDS[number];

export const ALLOWED_LOCALES = ['es-419', 'es-ES', 'en-US', 'pt-BR'] as const;
export type AllowedLocale = typeof ALLOWED_LOCALES[number];
