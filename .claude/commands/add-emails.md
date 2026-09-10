---
description: "Emails transaccionales drop-in (Resend default / SendGrid override): 7 templates React Email canónicos."
---

# /add-emails

Lee y ejecuta `.claude/skills/add-emails/SKILL.md`.

Templates pre-armados — SDK clients, 7 React Email components (Welcome / MagicLink / PasswordReset / InvoiceReceipt / PaymentFailed / SubscriptionCanceled / EmailChangedConfirmation), api routes (send + unsubscribe one-click + suppression webhook), server actions con whitelist L-003 + R14 strict en bulk operations, migration `0003_email_subscriptions.sql` con RLS L-001 enforced.

**Pre-requisitos:**
- `add-login` completado.
- Brand DNA presente — templates respetan `brand.json` colors + typography (R10).
- `impeccable` components base (para email templates con tokens consistentes).

**Decision tree D-011:** Resend (default por friction reduction) / SendGrid (override compliance SOC 2/HIPAA) / PAUSE on-prem (banking/healthcare data sovereignty).
