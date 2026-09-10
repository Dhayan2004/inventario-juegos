/**
 * WelcomeEmail — React Email
 *
 * R10 Brand DNA gate enforced.
 * Layout: single_column_first (R-005 contexts.transactional_email)
 * Motion: none. Fonts: ['Arial', 'Helvetica'] fallback chain.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
import {
  Body, Button, Container, Head, Heading, Hr, Html, Img, Link,
  Preview, Section, Text,
} from '@react-email/components';

export interface WelcomeEmailProps {
  firstName: string;
  productName: string;
  ctaUrl: string;
  unsubscribeUrl: string;
}

export const WelcomeEmail = ({
  firstName,
  productName,
  ctaUrl,
  unsubscribeUrl,
}: WelcomeEmailProps) => {
  const colors = {
    primary: '{{ TOKEN_COLORS_PRIMARY }}',
    text: '{{ TOKEN_COLORS_TEXT_PRIMARY }}',
    muted: '{{ TOKEN_COLORS_TEXT_MUTED }}',
    surface: '{{ TOKEN_COLORS_SURFACE }}',
    border: '{{ TOKEN_COLORS_BORDER }}',
  };

  return (
    <Html lang="es">
      <Head>
        <title>{'{{ COPY_WELCOME_HEADING }}'}</title>
      </Head>
      <Preview>{'{{ COPY_WELCOME_PREVIEW }}'}</Preview>
      <Body style={{
        backgroundColor: colors.surface,
        fontFamily: 'Arial, Helvetica, sans-serif',
        margin: 0,
        padding: 0,
      }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
          <Section style={{ textAlign: 'center', padding: '20px 0' }}>
            <Img
              src={`${process.env.NEXT_PUBLIC_APP_URL}/logo.png`}
              alt={productName}
              width="120"
              height="40"
              style={{ display: 'block', margin: '0 auto' }}
            />
          </Section>

          <Heading
            as="h1"
            style={{ color: colors.text, fontSize: '24px', lineHeight: '1.3', margin: '0 0 16px 0' }}
          >
            {'{{ COPY_WELCOME_HEADING }}'}, {firstName}
          </Heading>

          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            {'{{ COPY_WELCOME_BODY }}'}
          </Text>

          <Section style={{ textAlign: 'center', margin: '32px 0' }}>
            <Button
              href={ctaUrl}
              style={{
                backgroundColor: colors.primary,
                color: '#ffffff',
                padding: '12px 24px',
                borderRadius: '6px',
                textDecoration: 'none',
                fontSize: '16px',
                fontWeight: 600,
                display: 'inline-block',
              }}
            >
              {'{{ COPY_WELCOME_CTA }}'}
            </Button>
          </Section>

          <Hr style={{ borderTop: `1px solid ${colors.border}`, margin: '32px 0' }} />

          <Text style={{ color: colors.muted, fontSize: '12px', textAlign: 'center' }}>
            Recibiste este email porque tenés una cuenta en {productName}.
            <br />
            <Link href={unsubscribeUrl} style={{ color: colors.muted }}>
              Cancelar suscripción
            </Link>
          </Text>
        </Container>
      </Body>
    </Html>
  );
};

export default WelcomeEmail;
