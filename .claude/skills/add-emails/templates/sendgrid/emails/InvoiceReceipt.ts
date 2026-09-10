/**
 * InvoiceReceipt — SendGrid dynamic template metadata.
 *
 * Skip si add-payments NO corrió en el proyecto target.
 *
 * R10 + R-005 contexts.transactional_email aplican al HTML uploaded.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 *       · [docs:sendgrid-mail@v8]
 */
import { TEMPLATE_IDS, type AllowedTemplateId } from '@/lib/sendgrid/server';

export interface InvoiceReceiptData {
  firstName: string;
  productName: string;
  invoiceNumber: string;
  amountFormatted: string;
  paymentDate: string;
  nextBillingDate?: string;
  invoiceUrl: string;
  unsubscribeUrl: string;
}

export const InvoiceReceiptTemplate = {
  id: 'invoice_receipt' as AllowedTemplateId,
  templateId: () => TEMPLATE_IDS.invoice_receipt,
  subject: (data: InvoiceReceiptData) =>
    `Recibo #${data.invoiceNumber} — ${data.productName}`,
} as const;
