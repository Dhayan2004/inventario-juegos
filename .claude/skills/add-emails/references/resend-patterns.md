# Resend Patterns — Reference

> **find-docs first.** [docs:resend@latest] · [docs:react-email@v3]

## SDK init

```typescript
// src/lib/resend/server.ts
import 'server-only';
import { Resend } from 'resend';

if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY missing');
}

export const resend = new Resend(process.env.RESEND_API_KEY.trim());

export const RESEND_WEBHOOK_SECRET =
  process.env.RESEND_WEBHOOK_SECRET?.trim() ?? '';

export const EMAIL_FROM =
  `${process.env.EMAIL_FROM_NAME ?? 'App'} <${process.env.EMAIL_FROM_ADDRESS}>`;

export const ALLOWED_TEMPLATE_IDS = [
  'welcome',
  'magic_link',
  'password_reset',
  'invoice_receipt',
  'payment_failed',
  'subscription_canceled',
  'email_changed_confirmation',
] as const;
export type AllowedTemplateId = typeof ALLOWED_TEMPLATE_IDS[number];
```

## Send con React Email

```typescript
import { render } from '@react-email/render';
import { resend, EMAIL_FROM } from '@/lib/resend/server';
import { WelcomeEmail } from '@/emails/Welcome';
import { generateUnsubscribeToken } from '@/lib/email/unsubscribe-token';

const token = await generateUnsubscribeToken(user.email, user.id, 'all');
const unsubscribeUrl = `${process.env.NEXT_PUBLIC_APP_URL}/api/email/unsubscribe?token=${token}`;

await resend.emails.send({
  from: EMAIL_FROM,
  to: [user.email],
  subject: 'Bienvenido a Forja',
  react: <WelcomeEmail
    firstName={user.firstName}
    productName="Forja"
    ctaUrl={`${process.env.NEXT_PUBLIC_APP_URL}/onboarding`}
    unsubscribeUrl={unsubscribeUrl}
  />,
  headers: {
    'List-Unsubscribe': `<${unsubscribeUrl}>`,
    'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
  },
});
```

## Webhook events whitelist

| Event | Cuándo | Acción |
|-------|--------|--------|
| `email.sent` | Provider accepted | Log only |
| `email.delivered` | Recipient inbox confirmed | Log + update delivery status |
| `email.bounced` (hard) | Permanent bounce | Add to suppression_list |
| `email.bounced` (soft) | Temporary | Log, retry logic |
| `email.complained` | Spam complaint | Add to suppression_list (high priority) |
| `email.opened` | Tracking pixel rendered (con disclosure) | Optional — log si analytics activo |
| `email.clicked` | Link clicked | Optional log |
| `email.delivery_delayed` | Provider deferred | Log only |

## Free tier vs paid

- Free: 3,000/mes (100/día), single-domain, sin custom return-path
- Pro $20/mo: 50K/mes, multi-domain, dedicated IP $30 add-on
- Enterprise: custom

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| `Domain not verified` | FROM domain no añadido en Resend dashboard | Verify SPF + DKIM en DNS |
| `Recipient suppressed` | Hard bounce previo o complaint | NO re-enable sin investigar; usar deleteSuppressionEntry con audit log (R14) |
| `Invalid signature` | webhook secret no coincide o `.trim()` ausente | Re-copy desde dashboard, verificar `.trim()` |
| `429 Too Many Requests` | Rate limit excedido | Implementar bucket per-user |

## Citations

- [docs:resend@latest] · [docs:react-email@v3]
- [memory:CONSTRAINTS.md#R13]
- [memory:lessons#L-002] · [memory:lessons#L-003]
