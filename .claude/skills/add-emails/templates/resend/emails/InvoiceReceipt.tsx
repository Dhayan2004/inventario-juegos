/** InvoiceReceiptEmail — R10. Skip si add-payments NO corrió. Cita: [memory:CONSTRAINTS.md#R10] */
import {
  Body, Button, Container, Head, Heading, Hr, Html, Img, Link,
  Preview, Section, Text,
} from '@react-email/components';

export interface InvoiceReceiptEmailProps {
  firstName: string;
  productName: string;
  invoiceNumber: string;
  amountCents: number;
  currency: string;
  paymentDate: string;
  nextBillingDate?: string;
  invoiceUrl: string;
  unsubscribeUrl: string;
}

export const InvoiceReceiptEmail = ({
  firstName, productName, invoiceNumber, amountCents, currency,
  paymentDate, nextBillingDate, invoiceUrl, unsubscribeUrl,
}: InvoiceReceiptEmailProps) => {
  const colors = {
    primary: '{{ TOKEN_COLORS_PRIMARY }}',
    text: '{{ TOKEN_COLORS_TEXT_PRIMARY }}',
    muted: '{{ TOKEN_COLORS_TEXT_MUTED }}',
    surface: '{{ TOKEN_COLORS_SURFACE }}',
    border: '{{ TOKEN_COLORS_BORDER }}',
  };
  const formatted = `${(amountCents / 100).toFixed(2)} ${currency.toUpperCase()}`;
  return (
    <Html lang="es">
      <Head><title>Recibo #{invoiceNumber}</title></Head>
      <Preview>{`Recibo #${invoiceNumber} de ${productName} — ${formatted}`}</Preview>
      <Body style={{ backgroundColor: colors.surface, fontFamily: 'Arial, Helvetica, sans-serif', margin: 0, padding: 0 }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
          <Section style={{ textAlign: 'center', padding: '20px 0' }}>
            <Img src={`${process.env.NEXT_PUBLIC_APP_URL}/logo.png`} alt={productName} width="120" height="40" />
          </Section>
          <Heading as="h1" style={{ color: colors.text, fontSize: '24px', lineHeight: '1.3', margin: '0 0 16px 0' }}>
            {'{{ COPY_INVOICE_HEADING }}'}
          </Heading>
          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            Hola {firstName}, gracias por tu suscripción a {productName}.
          </Text>

          <Section style={{ border: `1px solid ${colors.border}`, borderRadius: '6px', padding: '16px', margin: '24px 0' }}>
            <Text style={{ color: colors.muted, fontSize: '14px', margin: 0 }}>
              <strong style={{ color: colors.text }}>Número:</strong> #{invoiceNumber}
            </Text>
            <Text style={{ color: colors.muted, fontSize: '14px', margin: '4px 0' }}>
              <strong style={{ color: colors.text }}>Fecha:</strong> {paymentDate}
            </Text>
            <Text style={{ color: colors.muted, fontSize: '14px', margin: '4px 0' }}>
              <strong style={{ color: colors.text }}>Importe:</strong> {formatted}
            </Text>
            {nextBillingDate && (
              <Text style={{ color: colors.muted, fontSize: '14px', margin: '4px 0' }}>
                <strong style={{ color: colors.text }}>Próximo cobro:</strong> {nextBillingDate}
              </Text>
            )}
          </Section>

          <Section style={{ textAlign: 'center', margin: '32px 0' }}>
            <Button href={invoiceUrl} style={{
              backgroundColor: colors.primary, color: '#ffffff', padding: '12px 24px',
              borderRadius: '6px', textDecoration: 'none', fontSize: '16px', fontWeight: 600,
              display: 'inline-block',
            }}>
              {'{{ COPY_INVOICE_VIEW_CTA }}'}
            </Button>
          </Section>

          <Hr style={{ borderTop: `1px solid ${colors.border}`, margin: '32px 0' }} />
          <Text style={{ color: colors.muted, fontSize: '12px', textAlign: 'center' }}>
            <Link href={unsubscribeUrl} style={{ color: colors.muted }}>Cancelar suscripción</Link>
          </Text>
        </Container>
      </Body>
    </Html>
  );
};

export default InvoiceReceiptEmail;
