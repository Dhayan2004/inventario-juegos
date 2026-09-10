/**
 * SendGrid SDK — server side.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-002..3]
 *       · [docs:sendgrid-mail@v8] · [docs:sendgrid]
 */
import 'server-only';
import sgMail from '@sendgrid/mail';

if (!process.env.SENDGRID_API_KEY) {
  throw new Error('SENDGRID_API_KEY missing');
}

sgMail.setApiKey(process.env.SENDGRID_API_KEY.trim());

export const sendgrid = sgMail;

export const SENDGRID_WEBHOOK_PUBLIC_KEY =
  process.env.SENDGRID_WEBHOOK_PUBLIC_KEY?.trim() ?? '';

export const EMAIL_FROM = {
  email: process.env.EMAIL_FROM_ADDRESS ?? 'noreply@example.com',
  name: process.env.EMAIL_FROM_NAME ?? 'App',
};

export const SENDGRID_UNSUBSCRIBE_GROUP_ID = process.env.SENDGRID_UNSUBSCRIBE_GROUP_ID
  ? parseInt(process.env.SENDGRID_UNSUBSCRIBE_GROUP_ID, 10)
  : undefined;

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

/**
 * Dynamic template IDs map — pre-uploaded en SendGrid dashboard.
 * Format: d-XXXXXXXX (32 chars). Substituido al runtime via dynamicTemplateData.
 *
 * NO secrets — son IDs públicos de templates en el dashboard del owner.
 */
export const TEMPLATE_IDS: Record<AllowedTemplateId, string> = {
  welcome: process.env.SENDGRID_TEMPLATE_ID_WELCOME ?? '',
  magic_link: process.env.SENDGRID_TEMPLATE_ID_MAGIC_LINK ?? '',
  password_reset: process.env.SENDGRID_TEMPLATE_ID_PASSWORD_RESET ?? '',
  invoice_receipt: process.env.SENDGRID_TEMPLATE_ID_INVOICE_RECEIPT ?? '',
  payment_failed: process.env.SENDGRID_TEMPLATE_ID_PAYMENT_FAILED ?? '',
  subscription_canceled: process.env.SENDGRID_TEMPLATE_ID_SUBSCRIPTION_CANCELED ?? '',
  email_changed_confirmation: process.env.SENDGRID_TEMPLATE_ID_EMAIL_CHANGED ?? '',
};

export function assertTemplateConfigured(id: AllowedTemplateId): string {
  const tid = TEMPLATE_IDS[id];
  if (!tid) {
    throw new Error(
      `SendGrid template ${id} no configurado. ` +
      `Setear SENDGRID_TEMPLATE_ID_${id.toUpperCase()} en .env.local.`
    );
  }
  return tid;
}
