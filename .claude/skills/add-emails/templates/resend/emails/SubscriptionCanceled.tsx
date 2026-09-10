/** SubscriptionCanceledEmail — R10. Cita: [memory:CONSTRAINTS.md#R10] */
import {
  Body, Button, Container, Head, Heading, Hr, Html, Img, Link,
  Preview, Section, Text,
} from '@react-email/components';

export interface SubscriptionCanceledEmailProps {
  firstName: string;
  productName: string;
  cancellationDate: string;
  accessUntilDate: string;
  feedbackUrl?: string;
  unsubscribeUrl: string;
}

export const SubscriptionCanceledEmail = ({
  firstName, productName, cancellationDate, accessUntilDate, feedbackUrl, unsubscribeUrl,
}: SubscriptionCanceledEmailProps) => {
  const colors = {
    primary: '{{ TOKEN_COLORS_PRIMARY }}',
    text: '{{ TOKEN_COLORS_TEXT_PRIMARY }}',
    muted: '{{ TOKEN_COLORS_TEXT_MUTED }}',
    surface: '{{ TOKEN_COLORS_SURFACE }}',
    border: '{{ TOKEN_COLORS_BORDER }}',
  };
  return (
    <Html lang="es">
      <Head><title>Suscripción cancelada</title></Head>
      <Preview>{`Tu suscripción a ${productName} fue cancelada. Acceso hasta ${accessUntilDate}.`}</Preview>
      <Body style={{ backgroundColor: colors.surface, fontFamily: 'Arial, Helvetica, sans-serif', margin: 0, padding: 0 }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
          <Section style={{ textAlign: 'center', padding: '20px 0' }}>
            <Img src={`${process.env.NEXT_PUBLIC_APP_URL}/logo.png`} alt={productName} width="120" height="40" />
          </Section>
          <Heading as="h1" style={{ color: colors.text, fontSize: '24px', lineHeight: '1.3', margin: '0 0 16px 0' }}>
            {'{{ COPY_CANCEL_HEADING }}'}
          </Heading>
          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            Hola {firstName}, recibimos la cancelación de tu suscripción a {productName}.
          </Text>
          <Section style={{ border: `1px solid ${colors.border}`, borderRadius: '6px', padding: '16px', margin: '24px 0' }}>
            <Text style={{ color: colors.muted, fontSize: '14px', margin: 0 }}>
              <strong style={{ color: colors.text }}>Cancelado el:</strong> {cancellationDate}
            </Text>
            <Text style={{ color: colors.muted, fontSize: '14px', margin: '4px 0' }}>
              <strong style={{ color: colors.text }}>Acceso hasta:</strong> {accessUntilDate}
            </Text>
          </Section>
          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            Mantenés acceso a {productName} hasta {accessUntilDate}. Después de esa fecha, tu cuenta pasa a modo lectura.
          </Text>
          {feedbackUrl && (
            <Section style={{ textAlign: 'center', margin: '32px 0' }}>
              <Button href={feedbackUrl} style={{
                backgroundColor: colors.primary, color: '#ffffff', padding: '12px 24px',
                borderRadius: '6px', textDecoration: 'none', fontSize: '16px', fontWeight: 600,
                display: 'inline-block',
              }}>
                {'{{ COPY_FEEDBACK_CTA }}'}
              </Button>
            </Section>
          )}
          <Hr style={{ borderTop: `1px solid ${colors.border}`, margin: '32px 0' }} />
          <Text style={{ color: colors.muted, fontSize: '12px', textAlign: 'center' }}>
            <Link href={unsubscribeUrl} style={{ color: colors.muted }}>Cancelar suscripción</Link>
          </Text>
        </Container>
      </Body>
    </Html>
  );
};

export default SubscriptionCanceledEmail;
