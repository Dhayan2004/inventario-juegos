# Handoff a el-guardian — Pre-deploy Security Checklist (add-payments)

> Este documento se invoca al cierre de add-payments. el-guardian usa Codex como
> "segundo cerebro" para auditar adversarialmente lo generado. Sin PASS de
> el-guardian, deploy bloqueado.

## Contexto

add-payments generó (Mode A — Stripe; Mode B — Polar; Mode C — Mercado Pago, paridad estructural — D-038):
- SDK clients (server + client) — `lib/{stripe,polar,mercadopago}/{client,server}.ts` (+ `verify.ts` puro y `plans.ts` en Mode C)
- 4 pages billing — `/pricing /checkout /success /billing` (R10 contract)
- Webhook handler — `app/api/webhooks/{stripe,polar,mercadopago}/route.ts` con signature verification + L-002 (MP: manifest `id;request-id;ts;`, ventana 300 s, dedup, re-fetch)
- API routes — `app/api/{stripe,polar,mercadopago}/{checkout,portal,refund-request}/route.ts` con rate limiting
- Server actions — `actions/{stripe,polar,mercadopago}.ts` con whitelist L-003 + R14 gates (+ guard PAY-006 en rails irreversibles)
- 0002_subscriptions.sql con RLS L-001 + 0003_payments_ledger.sql (payments · webhook_events_processed · idempotency_keys; policy por org si `auth_org_ids()` existe)
- tests/payments/webhook-*.test.mjs (Layer 3: válido pasa, forjado/replay se rechazan) + payment-page-scripts.json (PCI §6.4.3)
- .env.local con placeholders

## Checklist obligatorio (10 gates × 3 proveedores + gate 0)

### 0. payments-gate (PAY-001..008 del threat-db — mecánico, con razón por finding)

```bash
bash .claude/skills/add-payments/tests/payments-gate.sh src/
# Esperado: 8/8 clean. Cualquier finding critical (PAY-001/005/007) bloquea deploy.
```

### 1. Secret isolation (STRIPE_SECRET_KEY / POLAR_ACCESS_TOKEN / MP_ACCESS_TOKEN)

```
✓ NO `STRIPE_SECRET_KEY` ni `POLAR_ACCESS_TOKEN` en archivos client
  (src/app/(billing)/**/*.tsx, src/components/**)
✓ Las claves SOLO en lib/{stripe,polar}/server.ts y api/ routes
✓ env vars privadas SIN prefix `NEXT_PUBLIC_`
✓ NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY (público, OK en client)
```

Comando audit:
```bash
grep -rn "STRIPE_SECRET_KEY\|POLAR_ACCESS_TOKEN\|POLAR_WEBHOOK_SECRET\|STRIPE_WEBHOOK_SECRET" \
  src/app/\(billing\)/ src/components/ \
  src/lib/stripe/client.ts src/lib/polar/client.ts \
  2>/dev/null
# Esperado: 0 hits
```

### 2. Webhook signature verification (raw body + .trim())

```
✓ webhook handler usa await request.text() (raw body)
✓ NO request.json() antes de constructEvent / validateEvent
✓ STRIPE_WEBHOOK_SECRET / POLAR_WEBHOOK_SECRET con .trim() al leer del env
✓ FAIL FAST en signature mismatch (return 400 / 403)
```

Comando audit:
```bash
# raw body antes de signature
grep -B2 "constructEvent\|validateEvent" \
  src/app/api/webhooks/{stripe,polar}/route.ts | grep -q "request\.text()"

# .trim() en lib level
grep "WEBHOOK_SECRET" src/lib/{stripe,polar}/server.ts | grep -q "\.trim()"

# fail-fast on bad signature
grep -A3 "Invalid signature\|WebhookVerificationError" \
  src/app/api/webhooks/{stripe,polar}/route.ts | grep -E "status: (400|403)"
```

### 3. RLS en subscriptions (L-001)

```
✓ subscriptions table tiene `enable row level security`
✓ ≥1 policy con `auth.uid() = user_id` (SELECT only)
✓ NO policies INSERT/UPDATE direct (solo via service_role en webhook)
✓ Foreign key user_id con `on delete cascade`
```

Comando audit:
```bash
SQL=supabase/migrations/*subscriptions.sql
grep -q "enable row level security" $SQL
grep -c "auth.uid() = user_id" $SQL                # ≥1
grep -c "for select" $SQL                           # ≥1
! grep -E "for (insert|update|delete) using" $SQL  # 0 — no policies de mutación
grep -q "on delete cascade" $SQL
```

### 4. R14 — destructive actions sin execute() automático

```
✓ refundCharge / cancelSubscription / transferFunds NO export como tool({ execute })
✓ Server actions con typed-confirmation gate (z.literal('REFUND'/'CANCEL'))
✓ Audit log (refund_requests table) row insertada ANTES de execute
✓ Ownership check (charge.metadata.user_id vs user.id) presente
```

Comando audit:
```bash
# 0 tool({ execute }) en destructive
! grep -E "tool\(\\{[^}]*execute:\\s*async.*(refund|cancel|transfer)" \
    src/actions/{stripe,polar}.ts

# typed confirmation present
grep -E "z\\.literal\\('(REFUND|CANCEL|TRANSFER)'" \
    src/actions/{stripe,polar}.ts

# audit log antes de execute
grep -B5 "stripe\\.refunds\\.create\\|polar\\.refunds\\.create\\|subscriptions\\.cancel" \
    src/actions/{stripe,polar}.ts | grep -q "refund_requests\\|insert"

# ownership check
grep -E "metadata\\.user_id|subscriptions.*user_id.*user\\.id" \
    src/actions/{stripe,polar}.ts
```

### 5. L-002 — webhook payload tratado como dato

```
✓ Header L-002 enforcement presente en webhook route
✓ metadata.user_id validado contra UUID regex antes de query
✓ event.type en whitelist (default: log + skip, NO throw — anti retry storm)
✓ NO operaciones agentic basadas en metadata.action / metadata.role
```

Comando audit:
```bash
grep -q "L-002 enforcement\|treat-as-data" \
    src/app/api/webhooks/{stripe,polar}/route.ts

grep -q "UUID_RE\|safeUserId" \
    src/app/api/webhooks/{stripe,polar}/route.ts

# default no-throw
grep -A2 "default:" src/app/api/webhooks/{stripe,polar}/route.ts \
    | grep -q "console.log"
! grep -A2 "default:" src/app/api/webhooks/{stripe,polar}/route.ts \
    | grep -q "throw"
```

### 6. L-003 — Whitelist validators en form inputs

```
✓ checkout actions validan plan_id con z.enum (NO z.string libre)
✓ refund actions validan reason con z.enum (no z.string libre)
✓ amount con bounded range (max $10K cap)
✓ currency con z.enum LATAM-aware (usd/eur/mxn/ars/cop)
✓ NO `z.record(z.any())` en server actions
```

Comando audit:
```bash
# enums presentes
grep -E "z\\.enum\\(\\['usd'" src/actions/{stripe,polar}.ts
grep -E "z\\.enum\\(\\['(month|year)'\\]" src/actions/{stripe,polar}.ts
grep -E "z\\.enum\\(\\['requested_by_customer'" src/actions/{stripe,polar}.ts

# bounded amount
grep -E "z\\.number\\(\\)\\.int\\(\\)\\.positive\\(\\)\\.max" \
    src/actions/{stripe,polar}.ts

# 0 z.record(z.any())
! grep "z\\.record\\(z\\.any\\(\\)\\)" src/actions/{stripe,polar}.ts
```

### 7. Idempotency en webhook (prevención de double-grant)

```
✓ Antes de upsert, query existing subscription
✓ Compare current_period_end + status — si igual, skip
✓ NO grant has_access dos veces para el mismo period
```

Comando audit:
```bash
grep -E "current_period_end.*===.*newPeriodEnd|already.processed|Duplicate event" \
    src/app/api/webhooks/{stripe,polar}/route.ts
```

### 8. Acceso solo en subscription.active (NO en checkout)

```
✓ has_access = true SOLO triggered desde:
  - Stripe: customer.subscription.created/updated con status === 'active'
  - Polar: subscription.active event
✓ checkout.session.completed (Stripe) / checkout.updated (Polar) NO concede acceso
```

Comando audit:
```bash
# checkout.completed NO debe tener update has_access: true
! grep -B5 "has_access: true" \
    src/app/api/webhooks/{stripe,polar}/route.ts \
  | grep -E "checkout\\.session\\.completed|checkout\\.updated"

# subscription.active SI debe tenerlo
grep -B5 "has_access: true" \
    src/app/api/webhooks/{stripe,polar}/route.ts \
  | grep -E "subscription\\.active|status === 'active'"
```

### 9. Rate limiting en /api/checkout

```
✓ Documentado en JSDoc del route (anti-abuse: max 5 req/user/hour)
✓ Implementación opcional: in-memory rate limiter con Map (dev) o Upstash (prod)
✓ Auth guard antes de crear session (no anónimos)
```

Comando audit:
```bash
grep -E "rate.?limit|5.req.*hour" \
    src/app/api/{stripe,polar}/checkout/route.ts

grep -B5 "checkout\\.sessions\\.create\\|checkouts\\.custom\\.create" \
    src/app/api/{stripe,polar}/checkout/route.ts | grep -q "user\\b"
```

### 10. PII handling — emails, charge IDs, customer IDs

```
✓ NO logs con email completo en server-side errors (PII redaction)
✓ charge_id / subscription_id en URLs solo en server actions (no en query string público)
✓ webhook secret nunca en error messages user-facing
```

Manual review por el-guardian.

## Manual gates (el-guardian pregunta al usuario)

- [ ] Stripe Dashboard / Polar Dashboard: webhook endpoint creado con URL `https://<domain>/api/webhooks/{stripe,polar}` y eventos seleccionados (suscripción + checkout)
- [ ] Webhook secret copiado a `STRIPE_WEBHOOK_SECRET` / `POLAR_WEBHOOK_SECRET` en .env.local prod
- [ ] Price IDs creados en provider y mapped a `NEXT_PUBLIC_STRIPE_PRICE_ID_*` (Stripe) o `POLAR_PRODUCT_ID` (Polar)
- [ ] Test cards verificados (4242 4242 4242 4242 succeeded en sandbox antes de prod)
- [ ] Customer portal URL configurada en Stripe Dashboard (Mode A) / Polar settings (Mode B)
- [ ] HTTPS only en producción (NEXT_PUBLIC_APP_URL https://)

Si alguno NO → flag y bloquea deploy.

## Severidades

| Severity | Examples | Block deploy? |
|----------|----------|---------------|
| critical | STRIPE_SECRET_KEY en client; signature verification skipped; RLS missing en subscriptions; refund tool con execute() | yes |
| high | metadata.user_id sin UUID validation; checkout.completed concede acceso; .trim() ausente en webhook secret; rate limiting no documentado | yes |
| medium | falta JSDoc citation; logs PII en server | no, fix antes de prod |
| low | copy con avoid_words; tier names sin label semánticos | no, fix antes de prod |

PASS = 0 critical + 0 high.

## Output esperado

el-guardian retorna:

```markdown
# Security Audit — add-payments

**Mode:** STRIPE | POLAR
**Status:** PASS | NEEDS_FIX | FAIL

**Findings:**
- [critical] ... | none
- [high] ... | none
- [medium] ... | none
- [low] ... | none

**Manual gates pending:**
- [ ] Webhook endpoint configured in provider dashboard
- [ ] Price IDs mapped in .env.local
- [ ] Test cards verified
- [ ] HTTPS only

**Deploy gate:** UNBLOCKED | BLOCKED

**Recommendations:**
- ...
```

Si BLOCKED → add-payments retorna NEEDS_FIX al el-evaluador, gaps específicos. el-evaluador decide si regenerate o handoff manual al usuario.

## Citations

- [memory:lessons#L-001] · [memory:lessons#L-002] · [memory:lessons#L-003]
- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14]
- [memory:references#R-005]
- [memory:decisions#D-009]
- [docs:stripe] · [docs:stripe-node@v18] · [docs:polar] · [docs:polar-sdk@v0.x] · [docs:nextjs]
