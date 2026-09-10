# Handoff a el-guardian — Pre-deploy Security Checklist (add-emails)

> Sin PASS de el-guardian, deploy bloqueado.

## Contexto

add-emails generó (Mode A — Resend; Mode B — SendGrid mirror; Mode C — PAUSE = no files):
- SDK clients (server-only) — `lib/{resend,sendgrid}/server.ts`
- 7 React Email templates con R10 + R-005 contexts.transactional_email
- API routes: `/api/email/{send,unsubscribe,suppression-webhook}`
- Server actions con whitelist L-003 + R14 bulk gates
- 0003_email_subscriptions.sql + suppression_list + email_events + email_admin_actions con RLS L-001
- .env.local con placeholders

## Checklist obligatorio (10 gates)

### 1. API key isolation

```
✓ NO RESEND_API_KEY ni SENDGRID_API_KEY en archivos client
  (src/app/(*)/, src/components/, src/emails/)
✓ Solo en lib/{resend,sendgrid}/server.ts y api routes
✓ env vars privadas SIN prefix NEXT_PUBLIC_
```

```bash
grep -rn "RESEND_API_KEY\|SENDGRID_API_KEY\|RESEND_WEBHOOK_SECRET\|SENDGRID_WEBHOOK_PUBLIC_KEY" \
  src/app/\(*\)/ src/components/ src/emails/ 2>/dev/null
# Esperado: 0 hits
```

### 2. Webhook signature verification

```
✓ Suppression webhook usa raw body (request.text()) ANTES de verify
✓ Resend: Svix.verify() FAIL FAST 401
✓ SendGrid: ECDSA EventWebhook.verifySignature FAIL FAST 401
✓ Webhook secret/public key con .trim() (Resend) o env-loaded (SendGrid)
✓ NO request.json() before verification
```

### 3. RLS L-001 en email tables

```
✓ email_subscriptions tiene enable row level security
✓ SELECT policy auth.uid() = user_id
✓ NO INSERT/UPDATE direct (server-side via webhook + actions)
✓ suppression_list NO accesible para users (admin-only o service_role)
✓ email_events NO accesible para users (server-only)
✓ email_admin_actions NO accesible para users (admin-only)
```

```bash
SQL=supabase/migrations/*email_subscriptions.sql
grep -q "enable row level security" $SQL
grep -c "auth.uid() = user_id" $SQL    # ≥1
! grep -E "for (insert|update|delete) (using|with check)" $SQL
```

### 4. R14 bulk operations sin execute()

```
✓ bulkUnsubscribe NO export tool({ execute })
✓ deleteSuppressionEntry NO export tool({ execute })
✓ resendCampaign NO export tool({ execute })
✓ Cada uno con typed-confirmation (z.literal BULK_UNSUBSCRIBE,
  DELETE_SUPPRESSION, RESEND_CAMPAIGN)
✓ Audit log en email_admin_actions ANTES de execute
✓ Role check admin antes de proceder
```

### 5. L-002 webhook payload as data

```
✓ Suppression webhook valida event shape via Zod schema
✓ z.enum cerrado para event types (NO z.string libre)
✓ z.enum cerrado para bounce types (hard/soft/undetermined)
✓ Default case en switch sin throw (anti retry storm)
✓ recipient_email lowercased antes de DB (case-insensitive matching)
```

### 6. L-003 whitelist en send action

```
✓ to: z.string().email().max(254)
✓ template_id: z.enum([...known templates])
✓ locale: z.enum(['es-419', 'es-ES', 'en-US', 'pt-BR'])
✓ NO z.record(z.any())
✓ reply_to validado si presente
```

### 7. Unsubscribe RFC 8058 compliance

```
✓ List-Unsubscribe header en send call
✓ List-Unsubscribe-Post: List-Unsubscribe=One-Click header
✓ /api/email/unsubscribe acepta GET + POST con same shape
✓ Token JWT-signed (jose lib) con 30d expiry max
✓ NO requiere user authentication (token-based)
```

### 8. R10 Brand contract en templates

```
✓ 7 templates importan brand tokens (NO Tailwind purple/blue/etc)
✓ Layout single_column_first (R-005 contexts.transactional_email)
✓ Motion none (no animations)
✓ Fallback fonts ['Arial', 'Helvetica'] (NO Inter/Geist en email)
✓ Footer con unsubscribe link
✓ <Preview> tag en cada template
✓ avoid_words audit script PASS
```

### 9. Rate limiting + suppression check

```
✓ /api/email/send tiene rate limiter (10 req/user/hour transactional)
✓ Pre-send check isSuppressed() invocado antes de provider call
✓ Bulk operations admin-only role check
```

### 10. Deliverability infra (manual gates)

el-guardian NO puede verificar DNS automáticamente, pero pregunta al usuario:

```
[ ] SPF record configurado en DNS del FROM domain
    (v=spf1 include:_spf.resend.com ~all  | include:sendgrid.net)
[ ] DKIM keys publicadas en DNS del FROM domain
    (resend._domainkey.<domain>  o  s1._domainkey.<domain>)
[ ] DMARC record con p=quarantine o p=reject
[ ] FROM domain verified en provider dashboard
[ ] Webhook endpoint URL configurada en provider dashboard
    (https://<app-domain>/api/email/suppression-webhook)
[ ] HTTPS only en producción
[ ] Test send a address propio + verificar inbox (no spam)
[ ] Mail-tester.com score ≥9.0/10
```

Si alguno NO → flag y bloquea deploy.

## Severidades

| Severity | Examples | Block deploy? |
|----------|----------|---------------|
| critical | API key en client; signature verification skipped; bulk ops con execute() | yes |
| high | RLS missing en email tables; .trim() ausente en webhook secret; rate limit no documentado; missing one-click unsubscribe | yes |
| medium | falta JSDoc citation; logs PII en server; SPF/DKIM/DMARC sin configurar (deliverability degradado pero no leak) | no, fix antes de prod |
| low | template con avoid_words; preview text falta; sin disclosure de tracking pixel | no, fix antes de prod |

PASS = 0 critical + 0 high.

## Output

```markdown
# Security Audit — add-emails

**Mode:** RESEND | SENDGRID | PAUSE
**Status:** PASS | NEEDS_FIX | FAIL

**Findings:**
- [critical] ... | none
- [high] ... | none
- [medium] ... | none
- [low] ... | none

**Manual gates pending (deliverability):**
- [ ] SPF/DKIM/DMARC configurados
- [ ] FROM domain verified
- [ ] Webhook endpoint registered
- [ ] HTTPS only
- [ ] Test inbox + mail-tester score ≥9.0/10

**Deploy gate:** UNBLOCKED | BLOCKED
```

## Citations

- [memory:lessons#L-001..3]
- [memory:CONSTRAINTS.md#R10..14]
- [memory:references#R-005]
- [memory:decisions#D-010] · [memory:decisions#D-011]
- [docs:resend] · [docs:sendgrid] · [docs:react-email@v3] · [docs:rfc8058]
