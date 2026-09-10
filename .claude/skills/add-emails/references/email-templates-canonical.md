# Email Templates — Canonical Reference (7 templates)

> Cada template tiene: trigger source, props requeridas, copy keys (substituidos desde voice.json), tokens consumidos.

## 1. Welcome

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-login signup confirmation o post-onboarding step 1 |
| Props | `firstName`, `productName`, `ctaUrl`, `unsubscribeUrl` |
| Copy keys | `COPY_WELCOME_HEADING`, `COPY_WELCOME_BODY`, `COPY_WELCOME_CTA`, `COPY_WELCOME_PREVIEW` |
| Tokens | colors.primary (CTA), colors.text, colors.surface, colors.border |
| Suggested CTA | "Empezar ahora" / "Ir al panel" / "Configurar tu cuenta" |
| Preview text | ≤90 chars, hint del onboarding ("Tu cuenta está lista. Te llevamos al primer paso.") |

## 2. MagicLink

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-login passwordless login request |
| Props | `firstName`, `magicLinkUrl`, `expiresInMinutes`, `unsubscribeUrl` |
| Copy keys | `COPY_MAGIC_LINK_HEADING`, `COPY_MAGIC_LINK_CTA`, `COPY_MAGIC_LINK_EXPIRY_NOTE` |
| Tokens | colors.primary, colors.text, colors.muted (expiry note) |
| Suggested CTA | "Iniciar sesión" / "Acceder" |
| Preview | "Tu enlace de acceso a {productName} (expira en 15 min)." |
| Security note obligatoria | "Si vos no pediste este enlace, ignorá este email." |

## 3. PasswordReset

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-login forgot password flow |
| Props | `firstName`, `resetUrl`, `expiresInMinutes`, `unsubscribeUrl` |
| Copy keys | `COPY_RESET_HEADING`, `COPY_RESET_CTA`, `COPY_RESET_EXPIRY_NOTE` |
| Tokens | mismos que MagicLink |
| Suggested CTA | "Cambiar contraseña" / "Restablecer" |
| Preview | "Restablecé tu contraseña de {productName}. Enlace válido 15 min." |
| Security note | "Si vos no pediste este reset, ignorá este email y considerá cambiar tu contraseña." |

## 4. InvoiceReceipt

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-payments webhook subscription.active o invoice.paid |
| Skip si | add-payments NO corrió en el proyecto |
| Props | `firstName`, `productName`, `invoiceNumber`, `amount`, `currency`, `paymentDate`, `nextBillingDate`, `invoiceUrl`, `unsubscribeUrl` |
| Copy keys | `COPY_INVOICE_HEADING`, `COPY_INVOICE_THANK_YOU`, `COPY_INVOICE_VIEW_CTA` |
| Tokens | colors.text, colors.muted (details), colors.primary (CTA), colors.border (details table) |
| Suggested CTA | "Ver recibo" / "Descargar PDF" |
| Preview | "Recibo #{invoiceNumber} de {productName} — {amount} {currency}" |
| Sección obligatoria | Details table con line items + total + tax breakdown (si aplica) |

## 5. PaymentFailed

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-payments webhook invoice.payment_failed |
| Skip si | add-payments NO corrió |
| Props | `firstName`, `productName`, `failureReason`, `nextRetryDate`, `updatePaymentUrl`, `unsubscribeUrl` |
| Copy keys | `COPY_PAYMENT_FAILED_HEADING`, `COPY_PAYMENT_FAILED_BODY`, `COPY_UPDATE_PAYMENT_CTA` |
| Tokens | colors.text, colors.warning (reason highlight), colors.primary (CTA) |
| Suggested CTA | "Actualizar método de pago" / "Resolver pago" |
| Preview | "Acción requerida: tu pago de {productName} no se procesó." |
| Tono | Urgent pero no alarmante. Provider error message NO incluido raw — abstract. |

## 6. SubscriptionCanceled

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-payments webhook subscription.canceled o customer.subscription.deleted |
| Skip si | add-payments NO corrió |
| Props | `firstName`, `productName`, `cancellationDate`, `accessUntilDate`, `feedbackUrl?`, `unsubscribeUrl` |
| Copy keys | `COPY_CANCEL_HEADING`, `COPY_CANCEL_BODY`, `COPY_FEEDBACK_CTA?` |
| Tokens | colors.text, colors.muted (dates), colors.primary (feedback CTA opcional) |
| Suggested CTA | "Compartir feedback" (opcional) o "Volver a suscribirte" |
| Preview | "Tu suscripción a {productName} fue cancelada. Acceso hasta {accessUntilDate}." |
| Tono | Empático, sin guilt-trip. NO "estamos tristes que te vayas" cliché. |

## 7. EmailChangedConfirmation

| Aspecto | Detalle |
|---------|---------|
| Trigger | add-login update email flow — envío al NEW email address pidiendo confirmación |
| Props | `firstName`, `oldEmail`, `newEmail`, `confirmUrl`, `expiresInMinutes`, `unsubscribeUrl` |
| Copy keys | `COPY_EMAIL_CHANGED_HEADING`, `COPY_EMAIL_CHANGED_CTA` |
| Tokens | colors.text, colors.primary (CTA), colors.warning (security note) |
| Suggested CTA | "Confirmar email" / "Activar nuevo email" |
| Preview | "Confirmá tu nuevo email para {productName}." |
| Security note | "Si vos no solicitaste este cambio, contactanos en soporte@{domain}.com inmediatamente." |

## Common patterns across all 7

### Header section

```tsx
<Section style={{ textAlign: 'center', padding: '20px 0' }}>
  <Img
    src={`${APP_URL}/logo.png`}
    alt={productName}
    width="120" height="40"
  />
</Section>
```

### Preview tag (cada template)

```tsx
<Preview>{COPY_<NAME>_PREVIEW}</Preview>
```

≤90 chars, mostrado por Gmail/Outlook como secondary text. Crítico para open rates.

### Footer (cada template)

```tsx
<Hr style={{ borderTop: `1px solid ${colors.border}`, margin: '32px 0' }} />
<Text style={{ color: colors.muted, fontSize: '12px', textAlign: 'center' }}>
  {COPY_FOOTER_LEGAL_NOTICE}
  <br />
  Recibiste este email porque tenés una cuenta en {productName}.
  <br />
  <Link href={unsubscribeUrl} style={{ color: colors.muted }}>
    Cancelar suscripción
  </Link>
  {' · '}
  <Link href={`${APP_URL}/legal/privacy`} style={{ color: colors.muted }}>
    Política de privacidad
  </Link>
</Text>
```

### Tokens consumidos (síntesis 7 templates)

| Token | Frecuencia | Uso |
|-------|-----------|-----|
| `tokens.colors.primary` | 7/7 | CTA buttons |
| `tokens.colors.text` | 7/7 | Headings + body |
| `tokens.colors.muted` | 7/7 | Footer + secondary |
| `tokens.colors.surface` | 7/7 | Body background |
| `tokens.colors.border` | 7/7 | Hr separators |
| `tokens.colors.warning` | 2/7 | Payment failed, email changed (security note) |

## Locale-aware variants

Si Tech Spec declara `i18n.enabled = true` y multiple locales, cada template puede tener variants:

- `Welcome.es-419.tsx` (español LATAM neutral)
- `Welcome.es-ES.tsx` (español Spain)
- `Welcome.en-US.tsx` (English US)
- `Welcome.pt-BR.tsx` (português Brasil)

Send action recibe `locale: z.enum(...)` y elige variant. Default `es-419` para audiencia LATAM.

## Citations

- [memory:references#R-005] (Brand DNA + contexts.transactional_email)
- [memory:CONSTRAINTS.md#R10]
- [docs:react-email@v3]
