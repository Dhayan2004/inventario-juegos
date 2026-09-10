/**
 * MagicLink — SendGrid dynamic template metadata.
 *
 * R10 + R-005 contexts.transactional_email aplican al HTML uploaded.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface MagicLinkData {
  firstName: string;
  productName: string;
  magicLinkUrl: string;
  expiresInMinutes: number;
  unsubscribeUrl: string;
}

export const MagicLinkTemplate = {
  id: 'magic_link' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.magic_link,
  subject: (data: MagicLinkData) => `Tu enlace de acceso a ${data.productName}`,
} as const;
