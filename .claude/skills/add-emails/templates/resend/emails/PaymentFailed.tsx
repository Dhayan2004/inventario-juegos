/** PaymentFailedEmail — R10. Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005] */
import {
  Body, Button, Container, Head, Heading, Hr, Html, Img, Link,
  Preview, Section, Text,
} from '@react-email/components';

export interface PaymentFailedEmailProps {
  firstName: string;
  productName: string;
  failureReason?: string;
  nextRetryDate?: string;
  updatePaymentUrl: string;
  unsubscribeUrl: string;
}

export const PaymentFailedEmail = ({
  firstName, productName, failureReason, nextRetryDate, updatePaymentUrl, unsubscribeUrl,
}: PaymentFailedEmailProps) => {
  const colors = {
    primary: '{{ TOKEN_COLORS_PRIMARY }}',
    text: '{{ TOKEN_COLORS_TEXT_PRIMARY }}',
    muted: '{{ TOKEN_COLORS_TEXT_MUTED }}',
    surface: '{{ TOKEN_COLORS_SURFACE }}',
    border: '{{ TOKEN_COLORS_BORDER }}',
    warning: '{{ TOKEN_COLORS_WARNING }}',
  };
  return (
    <Html lang="es">
      <Head><title>Acción requerida — pago no procesado</title></Head>
      <Preview>{`Acción requerida: tu pago de ${productName} no se procesó.`}</Preview>
      <Body style={{ backgroundColor: colors.surface, fontFamily: 'Arial, Helvetica, sans-serif', margin: 0, padding: 0 }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
          <Section style={{ textAlign: 'center', padding: '20px 0' }}>
            <Img src={`${process.env.NEXT_PUBLIC_APP_URL}/logo.png`} alt={productName} width="120" height="40" />
          </Section>
          <Heading as="h1" style={{ color: colors.warning, fontSize: '24px', lineHeight: '1.3', margin: '0 0 16px 0' }}>
            {'{{ COPY_PAYMENT_FAILED_HEADING }}'}
          </Heading>
          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            Hola {firstName}, no pudimos procesar el último pago de tu suscripción a {productName}.
          </Text>
          {failureReason && (
            <Section style={{ backgroundColor: '#fff8e1', borderLeft: `4px solid ${colors.warning}`, padding: '12px 16px', margin: '16px 0' }}>
              <Text style={{ color: colors.text, fontSize: '14px', margin: 0 }}>
                <strong>Motivo:</strong> {failureReason}
              </Text>
            </Section>
          )}
          {nextRetryDate && (
            <Text style={{ color: colors.muted, fontSize: '14px' }}>
              Reintentaremos el cobro el <strong>{nextRetryDate}</strong>. Para evitar la suspensión, actualizá tu método de pago.
            </Text>
          )}
          <Section style={{ textAlign: 'center', margin: '32px 0' }}>
            <Button href={updatePaymentUrl} style={{
              backgroundColor: colors.primary, color: '#ffffff', padding: '12px 24px',
              borderRadius: '6px', textDecoration: 'none', fontSize: '16px', fontWeight: 600,
              display: 'inline-block',
            }}>
              {'{{ COPY_UPDATE_PAYMENT_CTA }}'}
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

export default PaymentFailedEmail;
