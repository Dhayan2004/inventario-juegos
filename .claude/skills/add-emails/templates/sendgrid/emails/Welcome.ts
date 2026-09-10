/**
 * Welcome — SendGrid dynamic template metadata.
 *
 * El HTML del template vive en el SendGrid dashboard (uploaded via
 * `npx react-email export` desde la fuente de verdad en repo Mode A).
 * Acá solo declaramos el shape de dynamicTemplateData (type-safe call sites)
 * y el subject derivado.
 *
 * R10 Brand DNA gate: HTML pre-uploaded respeta tokens/voice via
 * substitutions {{handlebars}} en el editor SendGrid (el HTML fuente
 * es identical al de Mode A — single_column_first, fallback fonts
 * Arial/Helvetica, motion none — R-005 contexts.transactional_email).
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface WelcomeData {
  firstName: string;
  productName: string;
  ctaUrl: string;
  unsubscribeUrl: string;
}

export const WelcomeTemplate = {
  id: 'welcome' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.welcome,
  subject: (data: WelcomeData) => `Bienvenido a ${data.productName}`,
} as const;
