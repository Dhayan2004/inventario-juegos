# SendGrid Patterns — Reference

> **find-docs first.** [docs:sendgrid] · [docs:sendgrid-mail@v8]

## SDK init

```typescript
// src/lib/sendgrid/server.ts
import 'server-only';
import sgMail from '@sendgrid/mail';

if (!process.env.SENDGRID_API_KEY) {
  throw new Error('SENDGRID_API_KEY missing');
}

sgMail.setApiKey(process.env.SENDGRID_API_KEY.trim());

export const sendgrid = sgMail;

export const TEMPLATE_IDS = {
  welcome: process.env.SENDGRID_TEMPLATE_ID_WELCOME!,
  magic_link: process.env.SENDGRID_TEMPLATE_ID_MAGIC_LINK!,
  password_reset: process.env.SENDGRID_TEMPLATE_ID_PASSWORD_RESET!,
  invoice_receipt: process.env.SENDGRID_TEMPLATE_ID_INVOICE_RECEIPT!,
  payment_failed: process.env.SENDGRID_TEMPLATE_ID_PAYMENT_FAILED!,
  subscription_canceled: process.env.SENDGRID_TEMPLATE_ID_SUBSCRIPTION_CANCELED!,
  email_changed_confirmation: process.env.SENDGRID_TEMPLATE_ID_EMAIL_CHANGED!,
};
```

## Send con dynamic template

```typescript
import { sendgrid, TEMPLATE_IDS } from '@/lib/sendgrid/server';

await sendgrid.send({
  from: {
    email: process.env.EMAIL_FROM_ADDRESS!,
    name: process.env.EMAIL_FROM_NAME ?? 'App',
  },
  to: user.email,
  templateId: TEMPLATE_IDS.welcome,
  dynamicTemplateData: {
    firstName: user.firstName,
    productName: 'Forja',
    ctaUrl: `${process.env.NEXT_PUBLIC_APP_URL}/onboarding`,
    unsubscribeUrl,
  },
  asm: {
    groupId: parseInt(process.env.SENDGRID_UNSUBSCRIBE_GROUP_ID!, 10),
  },
  trackingSettings: {
    clickTracking: { enable: true },
    openTracking: { enable: false }, // disable por privacy unless disclosed
  },
});
```

## Build pipeline (React Email → SendGrid HTML)

```
1. Componer/editar emails/Welcome.tsx (React Email components)
2. npx react-email export --dir src/emails --outDir .build/emails
3. Manual o CLI helper: subir HTML al SendGrid dashboard como dynamic template
4. SendGrid devuelve template_id (formato d-XXXX)
5. Add to .env.local: SENDGRID_TEMPLATE_ID_WELCOME=d-XXXX
6. Send call usa template_id reference
```

`{{handlebars}}` syntax en HTML para variables substituidas runtime via `dynamicTemplateData`.

## Webhook events whitelist

| Event | Cuándo | Acción |
|-------|--------|--------|
| `processed` | Provider accepted | Log only |
| `delivered` | Inbox confirmed | Log |
| `open` | Tracking pixel | Log si tracking habilitado + disclosure |
| `click` | Link clicked | Log |
| `bounce` con `type: hard` | Permanent | Add to suppression_list |
| `bounce` con `type: soft` | Temporary | Log only |
| `dropped` | SendGrid rechazó (suppression list, invalid email) | Log |
| `spamreport` | Spam complaint | Add to suppression_list (high priority) |
| `unsubscribe` | One-click unsubscribe | SendGrid manages internally |
| `group_unsubscribe` | Unsubscribe group | SendGrid manages |
| `deferred` | Temporary defer | Log |

## ECDSA signature verification

SendGrid usa ECDSA (P-256), NO HMAC. Public key se obtiene de **Sender Authentication > Settings > Event Webhook**:

```typescript
import { EventWebhook, EventWebhookHeader } from '@sendgrid/eventwebhook';

const ew = new EventWebhook();
const ecPublicKey = ew.convertPublicKeyToECDSA(process.env.SENDGRID_WEBHOOK_PUBLIC_KEY!);
const valid = ew.verifySignature(ecPublicKey, body, sig, ts);
```

## Suppression API (v3 REST)

```typescript
// Bloquear send (manual, raro)
await fetch('https://api.sendgrid.com/v3/asm/suppressions/global', {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${process.env.SENDGRID_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ recipient_emails: ['user@example.com'] }),
});

// Desbloquear (R14 destructive — gated)
await fetch(`https://api.sendgrid.com/v3/asm/suppressions/global/user@example.com`, {
  method: 'DELETE',
  headers: { Authorization: `Bearer ${process.env.SENDGRID_API_KEY}` },
});
```

## Compliance

- SOC 2 Type II (audited yearly)
- HIPAA: requiere BAA con SendGrid (paid plan + signed contract)
- GDPR: Data Processing Addendum disponible
- ISO 27001 + 27017 + 27018
- PCI-DSS Level 1 (Twilio infraestructura)

## Multi-tenant (subuser API)

SendGrid permite **subusers** — sub-accounts bajo el master que cada cliente del SaaS gestiona independientemente. Útil cuando vendes "white-label email" como feature. Requiere plan Pro+ y setup admin.

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| `Sender identity not verified` | FROM no en Sender Authentication | Domain Authentication + Single Sender |
| `Invalid template id` | template_id no existe en dashboard | Crear/verificar en Templates UI |
| `403 Forbidden` | API key sin permisos | Re-generate con full access scopes |
| `400 Bad Request` con dynamic data | Handlebar syntax inválido en template HTML | Verificar con Test Send en dashboard |

## Citations

- [docs:sendgrid] · [docs:sendgrid-mail@v8]
- [memory:CONSTRAINTS.md#R13]
- [memory:lessons#L-002] · [memory:lessons#L-003]
