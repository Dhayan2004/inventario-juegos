# Setup SendGrid — Mode B (override por compliance)

## Antes de empezar (R13)

```
1. resolve-library-id("sendgrid-mail") → query-docs
   query: "@sendgrid/mail SendGrid v3 dynamic templates suppression
           bounces unsubscribe groups"
2. resolve-library-id("sendgrid") → query-docs
   query: "@sendgrid/client API v3 webhook event signature
           ECDSA verification"
3. resolve-library-id("nextjs") → query-docs
   query: "App Router route handlers raw body request.text()"
```

**Razón:** SendGrid v8 (paquete `@sendgrid/mail`) cambió la API de suppression endpoints (v3 REST API ahora vs v2 deprecated). Webhook signature verification usa ECDSA con keypair (NO HMAC simple) — sin find-docs, runtime falla con cryptographic error. Citar `[docs:sendgrid-mail@v8]`.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | R-005 v1.1.0 + contexts.transactional_email |
| Auth | src/lib/{supabase,insforge}/server.ts + 0001_profiles.sql | add-login output |
| Tech Spec | TECH-SPEC `emails.provider = sendgrid` con compliance documentado | Required (default es Resend) |
| SendGrid dynamic template IDs | Pre-creados en SendGrid dashboard | Required (mapeo per template) |
| Verified sender domain | TECH-SPEC o user input — verified en SendGrid Sender Authentication | Required |
| Project name | brand.json.brand.product | Required |

## Pasos

### 1. PREFLIGHT (R10 + add-login chain + compliance gate)

Validar:
- Igual que Mode A, más:
- Compliance documentado en Tech Spec (SOC 2 audit / HIPAA BAA / GDPR strict). Si no documentado pero decision tree devolvió SendGrid → loggear warning y procede.

### 2. Substitute templates → src/

Estructura mirror Mode A pero con shape SendGrid:

| Template | Target | Substitutions |
|----------|--------|---------------|
| `lib/sendgrid/server.ts` | `src/lib/sendgrid/server.ts` | `{{ EMAIL_FROM_ADDRESS }}`, `{{ TEMPLATE_ID_<name> }}` por cada template |
| `lib/sendgrid/client.ts` | `src/lib/sendgrid/client.ts` | none (no client SDK) |
| `emails/Welcome.tsx` | `src/emails/Welcome.tsx` | React Email shape (compila a HTML para SendGrid dynamic templates upload) |
| `emails/...` (los otros 6) | mismo path | mismas substitutions que Mode A |
| `app/api/email/send/route.ts` | `src/app/api/email/send/route.ts` | none — usa `templateId` + `dynamicTemplateData` |
| `app/api/email/unsubscribe/route.ts` | mismo path | RFC 8058 + SendGrid unsubscribe groups |
| `app/api/email/suppression-webhook/route.ts` | mismo path | ECDSA signature verification |
| `actions/email.ts` | mismo path | R14 + L-003 |
| `types/email.ts` | mismo path | shared con Mode A |
| `migrations/0003_email_subscriptions.sql` | mismo path | shape-agnostic |

**Diferencia clave:** SendGrid usa **dynamic templates** (HTML pre-uploaded en su dashboard con substitution keys `{{handlebars}}`). El flow:

1. Tu repo tiene `emails/Welcome.tsx` (React Email) — fuente de verdad versionada.
2. Build process: `npx react-email export` genera HTML.
3. CLI helper: subir HTML al SendGrid dashboard → obtiene `template_id`.
4. `.env.local`: `SENDGRID_TEMPLATE_ID_WELCOME=d-XXXX`.
5. Send call: `sgMail.send({ templateId, dynamicTemplateData: { firstName, ... } })`.

### 3. Copy substitutions

Idéntico a Mode A — voice.json + brand.json drive los strings. La diferencia es que los strings se inyectan via `dynamicTemplateData` runtime, no hardcoded en HTML.

### 4. Append .env.local

```bash
cat >> .env.local <<'EOF'

# Emails — SendGrid (added by add-emails Mode B)
# Server-only
SENDGRID_API_KEY=SG.REPLACE
SENDGRID_WEBHOOK_PUBLIC_KEY=REPLACE_ECDSA_PUBKEY

# Template IDs (pre-uploaded en SendGrid dashboard)
SENDGRID_TEMPLATE_ID_WELCOME=d-REPLACE
SENDGRID_TEMPLATE_ID_MAGIC_LINK=d-REPLACE
SENDGRID_TEMPLATE_ID_PASSWORD_RESET=d-REPLACE
SENDGRID_TEMPLATE_ID_INVOICE_RECEIPT=d-REPLACE
SENDGRID_TEMPLATE_ID_PAYMENT_FAILED=d-REPLACE
SENDGRID_TEMPLATE_ID_SUBSCRIPTION_CANCELED=d-REPLACE
SENDGRID_TEMPLATE_ID_EMAIL_CHANGED=d-REPLACE

# Public
NEXT_PUBLIC_APP_URL=http://localhost:3000
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
EMAIL_FROM_NAME="Forja"
SENDGRID_UNSUBSCRIBE_GROUP_ID=REPLACE_INTEGER
EOF
```

### 5. Verificación pre-handoff

Mismos 8 checks que Mode A, adaptados:

```bash
grep -r "SENDGRID_API_KEY" src/app/\(*\)/                    # vacío
grep -r "SENDGRID_API_KEY" src/lib/sendgrid/server.ts          # presente
# ECDSA signature en webhook (NO HMAC)
grep -E "EventWebhookHeader|ECDSA|verifySignature" src/app/api/email/suppression-webhook/route.ts
# Template IDs whitelisted
grep -E "z\.enum\(\['welcome'" src/actions/email.ts
# Suppression Group ID for unsubscribe
grep "asm.*group_id\|SENDGRID_UNSUBSCRIBE_GROUP_ID" src/lib/sendgrid/server.ts
```

### 6. Output handoff

Imprimir bloque `## add-emails handoff` con Mode SENDGRID + flag de compliance documented.

## Diferencias relevantes vs Mode A

| Aspecto | Resend (Mode A) | SendGrid (Mode B) |
|---------|-----------------|-------------------|
| Template source | React Email .tsx en repo (HTML inline send) | React Email .tsx → export HTML → upload a dashboard → templateId reference |
| Webhook signature | HMAC SHA256 (Resend.events helper) | ECDSA pub-key (EventWebhookHeader.VERIFY_SIGNATURE) |
| Suppression list | Resend dashboard + API v1 | SendGrid v3 REST API + suppression groups |
| Unsubscribe | Header + custom endpoint | SendGrid unsubscribe groups (managed) |
| Compliance certs | SOC 2 Type II (2024+) | SOC 2 Type II + HIPAA + GDPR + ISO 27001 + PCI-DSS |
| Free tier | 3,000/mes (100/día) | 100/día primer 30 días, luego paid |
| Setup time típico | ~5 min | ~30 min con SPF/DKIM + Sender Auth + IP warmup |
| Multi-tenant | Limited (no subusers) | Full subuser API |

## Citations

- [docs:sendgrid] · [docs:sendgrid-mail@v8] · [docs:nextjs] (R13)
- [memory:references#R-005] · [memory:CONSTRAINTS.md#R10..14]
- [memory:lessons#L-001..3]
- [memory:decisions#D-010] · [memory:decisions#D-011]
- [docs:rfc8058]
