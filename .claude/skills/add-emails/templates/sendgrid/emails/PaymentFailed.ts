/**
 * PaymentFailed — SendGrid dynamic template metadata.
 *
 * R10 + R-005 contexts.transactional_email aplican al HTML uploaded.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface PaymentFailedData {
  firstName: string;
  productName: string;
  failureReason?: string;
  nextRetryDate?: string;
  updatePaymentUrl: string;
  unsubscribeUrl: string;
}

export const PaymentFailedTemplate = {
  id: 'payment_failed' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.payment_failed,
  subject: (data: PaymentFailedData) => `Acción requerida — ${data.productName}`,
} as const;
