# Setup Resend — Mode A (default)

## Antes de empezar (R13)

```
1. resolve-library-id("resend") → query-docs
   query: "Resend SDK send emails React templates webhooks
           signature verification Resend.events"
2. resolve-library-id("react-email") → query-docs
   query: "@react-email/components Tailwind Container Section
           render html v3 plain text fallback"
3. resolve-library-id("nextjs") → query-docs
   query: "App Router route handlers raw body request.text()
           webhook headers"
```

**Razón:** React Email v3 cambió el shape de `<Tailwind>` component (ahora es opcional, antes era root). Resend SDK estable pero `Resend.events` (webhook signature helper) se introdujo en SDK v3+ — pre-cutoff usaba HMAC manual. Sin find-docs, generación replica patrones viejos. Citar `[docs:resend@latest]` y `[docs:react-email@v3]`.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | R-005 v1.1.0 + contexts.transactional_email |
| Auth | src/lib/{supabase,insforge}/server.ts + 0001_profiles.sql | add-login output |
| Tech Spec | TECH-SPEC `emails.provider = resend` | Optional (fallback default) |
| Email FROM domain | TECH-SPEC o user input — debe estar verificado en Resend dashboard | Required |
| Project name | brand.json.brand.product | Required |

## Pasos

### 1. PREFLIGHT (R10 + add-login chain)

Validar:
- `brand/brand.json` con `schema_version >= "1.1.0"` + `contexts.transactional_email` (fallback conservador si missing)
- `brand/voice.json` con `cta_examples` ≥3 entries
- `src/lib/supabase/server.ts` o `insforge/server.ts` (add-login output)
- `supabase/migrations/0001_*_profiles.sql` aplicado (profiles.email field disponible)

Si alguno falta → halt mensaje específico.

### 2. Substitute templates → src/

| Template | Target | Substitutions |
|----------|--------|---------------|
| `lib/resend/server.ts` | `src/lib/resend/server.ts` | `{{ EMAIL_FROM_ADDRESS }}` → `noreply@<verified-domain>` |
| `lib/resend/client.ts` | `src/lib/resend/client.ts` | none (no client SDK Resend) |
| `emails/Welcome.tsx` | `src/emails/Welcome.tsx` | `{{ COPY_WELCOME_HEADING }}`, `{{ COPY_WELCOME_CTA }}` |
| `emails/MagicLink.tsx` | `src/emails/MagicLink.tsx` | `{{ COPY_MAGIC_LINK_HEADING }}`, `{{ COPY_MAGIC_LINK_CTA }}` |
| `emails/PasswordReset.tsx` | `src/emails/PasswordReset.tsx` | `{{ COPY_RESET_HEADING }}`, `{{ COPY_RESET_CTA }}` |
| `emails/InvoiceReceipt.tsx` | `src/emails/InvoiceReceipt.tsx` | `{{ COPY_INVOICE_HEADING }}` (skip if add-payments NOT corrió) |
| `emails/PaymentFailed.tsx` | `src/emails/PaymentFailed.tsx` | similar (skip if no add-payments) |
| `emails/SubscriptionCanceled.tsx` | `src/emails/SubscriptionCanceled.tsx` | similar (skip if no add-payments) |
| `emails/EmailChangedConfirmation.tsx` | `src/emails/EmailChangedConfirmation.tsx` | none |
| `app/api/email/send/route.ts` | `src/app/api/email/send/route.ts` | none |
| `app/api/email/unsubscribe/route.ts` | `src/app/api/email/unsubscribe/route.ts` | none — RFC 8058 compliant |
| `app/api/email/suppression-webhook/route.ts` | `src/app/api/email/suppression-webhook/route.ts` | none — signature verification |
| `actions/email.ts` | `src/actions/email.ts` | none — whitelist + R14 bulk gates |
| `types/email.ts` | `src/types/email.ts` | none |
| `migrations/0003_email_subscriptions.sql` | `supabase/migrations/0003_<timestamp>_email_subscriptions.sql` | timestamp |

### 3. Copy substitutions (R10 + voice.json)

```javascript
const voice = JSON.parse(readFile('brand/voice.json'));
const brand = JSON.parse(readFile('brand/brand.json'));
const product = brand.brand.product;

function pickCta(predicate, fallback) {
  const match = voice.voice.cta_examples.find(predicate);
  if (match) return match;
  console.warn(`[add-emails] voice.cta_examples sin orientación email. Fallback: "${fallback}"`);
  return fallback;
}

COPY_WELCOME_HEADING = `Bienvenido a ${product}`;
COPY_WELCOME_CTA = pickCta(c => /(empez|comenz|ir.al|iniciar)/i.test(c), 'Empezar ahora');
COPY_MAGIC_LINK_HEADING = 'Tu enlace de acceso';
COPY_MAGIC_LINK_CTA = pickCta(c => /(iniciar|sesion|entrar|acced)/i.test(c), 'Iniciar sesión');
COPY_RESET_HEADING = 'Restablecé tu contraseña';
COPY_RESET_CTA = pickCta(c => /(reset|restablec|cambiar)/i.test(c), 'Cambiar contraseña');
COPY_INVOICE_HEADING = 'Tu recibo';
// ... etc

// Audit avoid_words contra todos los heading + CTAs + body strings
const avoid = voice.voice.avoid_words;
const allCopy = [/* todos los strings substituidos */];
allCopy.forEach(s => avoid.forEach(w => {
  if (s.toLowerCase().includes(w.toLowerCase()))
    throw new Error(`Voice violation: "${w}" in "${s}"`);
}));
```

### 4. Append .env.local

```bash
cat >> .env.local <<'EOF'

# Emails — Resend (added by add-emails)
# Server-only (NEVER prefix with NEXT_PUBLIC_)
RESEND_API_KEY=re_REPLACE
RESEND_WEBHOOK_SECRET=whsec_REPLACE

# Public — safe en client
NEXT_PUBLIC_APP_URL=http://localhost:3000
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_FROM_NAME="Forja"
EOF
```

### 5. Verificación pre-handoff

```bash
# L1 syntax
npx tsc --noEmit
supabase db lint supabase/migrations/*email_subscriptions.sql

# L2 React Email components compilan
npx react-email export --dir src/emails 2>&1 || echo "warning: react-email CLI not installed (skip)"

# Security 8-check
grep -r "RESEND_API_KEY" src/app/\(*\)/                    # vacío en client
grep -r "RESEND_API_KEY" src/lib/resend/server.ts            # presente
grep "RESEND_WEBHOOK_SECRET" src/lib/resend/server.ts | grep -q "\.trim()"
grep -B2 "supabase\|insforge" src/app/api/email/suppression-webhook/route.ts | grep -q "Resend.events.verifySignature\|HMAC"
! grep -E "^export.*tool\(.*execute.*async.*(bulkUnsubscribe|deleteSuppressionEntry|resendCampaign)" src/actions/email.ts
grep "auth.uid() = user_id" supabase/migrations/*email_subscriptions.sql
grep -E "rate.?limit|10.req|hour" src/app/api/email/send/route.ts
grep -q "List-Unsubscribe-Post\|One-Click" src/lib/resend/server.ts  # RFC 8058
```

### 6. Output handoff

Imprimir el bloque `## add-emails handoff` (ver SKILL.md) con Mode RESEND.

Mandatory next step: invocar `el-guardian` con `prompts/handoff-el-guardian.md`.

## Citations

- [docs:resend] · [docs:resend@latest] · [docs:react-email@v3] · [docs:nextjs] (R13)
- [memory:references#R-005] (Brand DNA + contexts.transactional_email)
- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14]
- [memory:lessons#L-001] · [memory:lessons#L-002] · [memory:lessons#L-003]
- [memory:decisions#D-010] · [memory:decisions#D-011]
- [docs:rfc8058] (one-click unsubscribe Gmail/Yahoo 2024)
