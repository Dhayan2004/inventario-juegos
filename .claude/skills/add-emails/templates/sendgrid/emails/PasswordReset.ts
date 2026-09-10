/**
 * PasswordReset — SendGrid dynamic template metadata.
 *
 * R10 + R-005 contexts.transactional_email aplican al HTML uploaded.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface PasswordResetData {
  firstName: string;
  productName: string;
  resetUrl: string;
  expiresInMinutes: number;
  unsubscribeUrl: string;
}

export const PasswordResetTemplate = {
  id: 'password_reset' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.password_reset,
  subject: (data: PasswordResetData) => `Restablecé tu contraseña — ${data.productName}`,
} as const;
