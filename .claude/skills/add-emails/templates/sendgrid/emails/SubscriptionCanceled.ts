/**
 * SubscriptionCanceled — SendGrid dynamic template metadata.
 *
 * R10 + R-005 contexts.transactional_email aplican al HTML uploaded.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface SubscriptionCanceledData {
  firstName: string;
  productName: string;
  cancellationDate: string;
  accessUntilDate: string;
  feedbackUrl?: string;
  unsubscribeUrl: string;
}

export const SubscriptionCanceledTemplate = {
  id: 'subscription_canceled' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.subscription_canceled,
  subject: (data: SubscriptionCanceledData) =>
    `Tu suscripción a ${data.productName} fue cancelada`,
} as const;
