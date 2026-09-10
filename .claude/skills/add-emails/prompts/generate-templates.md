# Generate Email Templates — R10 + R-005 transactional_email context

## Antes de empezar (R13)

```
1. resolve-library-id("react-email") → query-docs
   query: "@react-email/components Container Section Heading Text
           Button Link Hr Img Tailwind v3 render renderAsync"
2. resolve-library-id("nextjs") → query-docs (only if SSR-rendered)
```

**Razón:** React Email v3 cambió shape de `<Tailwind>` (ahora opcional + accept config). `<Img>` requiere width/height attrs explícitos para Outlook. Sin find-docs, templates rompen en Outlook 2007-2019.

## 7 templates canónicos

| # | Template | Cuándo se envía | Trigger source |
|---|----------|-----------------|----------------|
| 1 | Welcome | Post-signup confirmation o onboarding | add-login signup flow |
| 2 | MagicLink | Login passwordless | add-login magic link request |
| 3 | PasswordReset | Reset password request | add-login forgot password |
| 4 | InvoiceReceipt | Post-charge succeeded | add-payments webhook (skip si add-payments NO corrió) |
| 5 | PaymentFailed | Charge declined / past_due | add-payments webhook |
| 6 | SubscriptionCanceled | Subscription canceled (immediate o end-of-period) | add-payments webhook |
| 7 | EmailChangedConfirmation | User cambió su email — confirmation a NEW address | add-login update email flow |

## R10 contract per template

```tsx
/**
 * <Template>.tsx — React Email
 *
 * R10 Brand DNA gate enforced.
 * - Colors derivan de brand/brand.json#tokens.colors (inline styles)
 * - CTAs derivan de brand/voice.json#cta_examples
 * - Layout: single_column_first (R-005 contexts.transactional_email)
 * - Motion: none (R-005 contexts.transactional_email)
 * - Fonts: ['Arial', 'Helvetica'] fallback chain (R-005 contexts.transactional_email)
 * - NO Tailwind defaults hardcoded
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
```

## Shape canónico (Welcome.tsx ejemplo)

```tsx
import {
  Body, Container, Head, Heading, Html, Img, Link,
  Preview, Section, Text, Hr, Button,
} from '@react-email/components';

interface WelcomeEmailProps {
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
  // Tokens del brand (substituidos durante setup)
  const colors = {
    primary: '{{ TOKEN_COLORS_PRIMARY }}',     // ej: '#1a73e8'
    text: '{{ TOKEN_COLORS_TEXT_PRIMARY }}',   // ej: '#1a1a1a'
    muted: '{{ TOKEN_COLORS_TEXT_MUTED }}',    // ej: '#6b6b6b'
    surface: '{{ TOKEN_COLORS_SURFACE }}',     // ej: '#ffffff'
    border: '{{ TOKEN_COLORS_BORDER }}',       // ej: '#e5e7eb'
  };

  return (
    <Html lang="es">
      <Head>
        <title>Bienvenido a {productName}</title>
      </Head>
      <Preview>{'{{ COPY_WELCOME_PREVIEW }}'}</Preview>
      <Body style={{
        backgroundColor: colors.surface,
        fontFamily: 'Arial, Helvetica, sans-serif',  // R-005 fallback chain
        margin: 0,
        padding: 0,
      }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
          {/* Logo */}
          <Section style={{ textAlign: 'center', padding: '20px 0' }}>
            <Img
              src={`${process.env.NEXT_PUBLIC_APP_URL}/logo.png`}
              alt={productName}
              width="120"
              height="40"
              style={{ display: 'block', margin: '0 auto' }}
            />
          </Section>

          {/* Heading */}
          <Heading
            as="h1"
            style={{
              color: colors.text,
              fontSize: '24px',
              lineHeight: '1.3',
              margin: '0 0 16px 0',
            }}
          >
            {'{{ COPY_WELCOME_HEADING }}'}, {firstName}
          </Heading>

          {/* Body text */}
          <Text style={{ color: colors.text, fontSize: '16px', lineHeight: '1.5' }}>
            {'{{ COPY_WELCOME_BODY }}'}
          </Text>

          {/* CTA Button */}
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

          {/* Footer con unsubscribe */}
          <Text style={{ color: colors.muted, fontSize: '12px', textAlign: 'center' }}>
            {'{{ COPY_FOOTER_LEGAL }}'}
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
```

## Tokens consumidos (per template)

| Token | CSS var equivalente | Uso |
|-------|---------------------|-----|
| `tokens.colors.primary` | `--accent` | CTA button background |
| `tokens.colors.surface` | `--surface` | Body background |
| `tokens.colors.textPrimary` | `--text-primary` | Headings, body text |
| `tokens.colors.textMuted` | `--text-muted` | Footer, secondary |
| `tokens.colors.border` | `--border` | Hr line |

NO usar gradients, shadows, animations — incompatible con Outlook 2007-2019.

## Avoid_words audit (post-substitution)

```bash
node -e '
const v = JSON.parse(require("fs").readFileSync("brand/voice.json"));
const avoid = v.voice.avoid_words || [];
const files = require("glob").sync("src/emails/*.tsx");
let violations = 0;
for (const f of files) {
  const content = require("fs").readFileSync(f, "utf8");
  for (const word of avoid) {
    const re = new RegExp("\\b" + word + "\\b", "i");
    if (re.test(content)) {
      console.error(`Voice violation: "${word}" in ${f}`);
      violations++;
    }
  }
}
process.exit(violations > 0 ? 1 : 0);
'
```

## Compatibilidad clientes email

| Client | Soporte | Notas |
|--------|---------|-------|
| Gmail web/iOS/Android | ✓ | Tailwind clases convertidas a inline styles via `@react-email/render` |
| Outlook 2007-2019 | ✓ con caveats | NO flexbox, NO grid, NO custom fonts (fallback obligatorio) |
| Outlook 365 | ✓ | mejor soporte CSS |
| Apple Mail (macOS/iOS) | ✓ | full CSS support |
| Yahoo Mail | ✓ | One-Click Unsubscribe header obligatorio (RFC 8058) |
| Spanish-speaking clients (Telmex, Movistar webmail) | ✓ | mismo Gmail-like rendering |

## Fallback fonts (R-005 contexts.transactional_email)

R-005 schema declara:

```json
"contexts": {
  "transactional_email": {
    "fonts": ["Arial", "Helvetica"],
    "layout": "single_column_first",
    "motion": "none"
  }
}
```

Templates **NO** usan custom fonts (Inter, Geist, Space Grotesk del schema R-005 sec 5). Aún si el brand del proyecto los declara, los emails caen al fallback chain. Razón: Outlook 2007-2019 NO renderea custom fonts; el fallback chain garantiza render predecible.

## Verificación post-gen

```bash
# 1. Templates parsean
npx tsc --noEmit

# 2. React Email components compilan a HTML válido
npx react-email export --dir src/emails 2>&1 || echo "warning: react-email CLI not installed"

# 3. NO custom fonts hardcoded
! grep -E "fontFamily.*'(Inter|Geist|Space Grotesk)" src/emails/*.tsx

# 4. NO Tailwind purple/indigo/blue defaults
! grep -E "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" src/emails/*.tsx

# 5. Cada template tiene <Preview>, <Body>, <Container>, footer con unsubscribe
for tpl in Welcome MagicLink PasswordReset InvoiceReceipt PaymentFailed SubscriptionCanceled EmailChangedConfirmation; do
  grep -q "<Preview>" src/emails/$tpl.tsx
  grep -q "Cancelar suscripción\|Unsubscribe" src/emails/$tpl.tsx
done

# 6. R10 cited
for tpl in src/emails/*.tsx; do
  grep -q "R10" "$tpl"
done

# 7. avoid_words audit (script Node arriba)
```

7/7 → PASS.

## Refusals

- ❌ Custom fonts (Inter/Geist/etc.) en emails. Fallback obligatorio.
- ❌ Flexbox / Grid layouts. Tables o block-level only.
- ❌ Animations / transitions / transforms. R-005 motion: none.
- ❌ Multi-column layouts. Single-column first.
- ❌ Tracking pixel oculto sin disclosure en footer.
- ❌ Skipear unsubscribe link en footer.
- ❌ Hardcodear colors hex en lugar de brand tokens.

## Citations

- [docs:react-email@v3] · [docs:nextjs] (R13)
- [memory:references#R-005] (Brand DNA + contexts.transactional_email)
- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R13]
- [memory:errors#E-007] (props binding shape — verificar React Email components shape antes)
