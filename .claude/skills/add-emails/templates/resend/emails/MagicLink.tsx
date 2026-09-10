/** MagicLinkEmail — R10. Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005] */
import {
  Body, Button, Container, Head, Heading, Hr, Html, Img, Link,
  Preview, Section, Text,
} from '@react-email/components';

export interface MagicLinkEmailProps {
  firstName: string;
  productName: string;
  magicLinkUrl: string;
  expiresInMinutes: number;
  unsubscribeUrl: string;
}

export const MagicLinkEmail = ({
  firstName, productName, magicLinkUrl, expiresInMinutes, unsubscribeUrl,
}: MagicLinkEmailProps) => {
  const colors = {
    primary: '{{ TOKEN_COLORS_PRIMARY }}',
    text: '{{ TOKEN_COLORS_TEXT_PRIMARY }}',
    muted: '{{ TOKEN_COLORS_TEXT_MUTED }}',
    surface: '{{ TOKEN_COLORS_SURFACE }}',
    border: '{{ TOKEN_COLORS_BORDER }}',
  };
  return (
    <Html lang="es">
      <Head><title>Tu enlace de acceso</title></Head>
      <Preview>{`Tu enlace de acceso a ${productName} (expira en ${expiresInMinutes} min).`}</Preview>
      <Body style={{ backgroundColor: colors.surface, fontFamily: 'Arial, Helvetica, sans-serif', margin: 0, padding: 0 }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
          <Section style={{ textAlign: 'center', padding: '20px 0' }}>
            <Img src={`${process.env.NEXT_PUBLIC_APP_URL}/logo.png`} alt={productName} width="120" height="40" />
          </Section>
          <Heading as="h1" style={{ color: colors.text, fontSize: '24px', lineHeight: '1.3', margin: '0 0 16px 0' }}>
            {'{{ COPY_MAGIC_LINK_HEADING }}'}
          </Heading>
          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            Hola {firstName}, hacé click en el botón para acceder a tu cuenta:
          </Text>
          <Section style={{ textAlign: 'center', margin: '32px 0' }}>
            <Button href={magicLinkUrl} style={{
              backgroundColor: colors.primary, color: '#ffffff', padding: '12px 24px',
              borderRadius: '6px', textDecoration: 'none', fontSize: '16px', fontWeight: 600,
              display: 'inline-block',
            }}>
              {'{{ COPY_MAGIC_LINK_CTA }}'}
            </Button>
          </Section>
          <Text style={{ color: colors.muted, fontSize: '14px' }}>
            Este enlace expira en {expiresInMinutes} minutos. Si vos no pediste este acceso, ignorá este email.
          </Text>
          <Hr style={{ borderTop: `1px solid ${colors.border}`, margin: '32px 0' }} />
          <Text style={{ color: colors.muted, fontSize: '12px', textAlign: 'center' }}>
            <Link href={unsubscribeUrl} style={{ color: colors.muted }}>Cancelar suscripción</Link>
          </Text>
        </Container>
      </Body>
    </Html>
  );
};

export default MagicLinkEmail;
