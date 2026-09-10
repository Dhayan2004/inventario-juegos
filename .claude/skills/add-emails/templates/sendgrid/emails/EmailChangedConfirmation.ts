/**
 * EmailChangedConfirmation — SendGrid dynamic template metadata.
 *
 * R10 + R-005 contexts.transactional_email aplican al HTML uploaded.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface EmailChangedConfirmationData {
  firstName: string;
  productName: string;
  oldEmail: string;
  newEmail: string;
  confirmUrl: string;
  expiresInMinutes: number;
  unsubscribeUrl: string;
}

export const EmailChangedConfirmationTemplate = {
  id: 'email_changed_confirmation' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.email_changed_confirmation,
  subject: (data: EmailChangedConfirmationData) =>
    `Confirmá tu nuevo email — ${data.productName}`,
} as const;
