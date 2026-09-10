# Setup Mercado Pago — Mode C (LATAM: MX · AR · BR · CL · CO · PE · UY)

> Cita: [memory:decisions#D-038] (Mode C con paridad estructural; ranking determinista) ·
> [memory:references#R-012] (catálogo PagoKit) · [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14]
> · `docs/security/VETTING-pagokit-0.2.2.md` §4 (esquema de firma re-verificado contra el SDK oficial).

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("mercadopago") → query-docs
   query: "mercadopago sdk-nodejs v2 MercadoPagoConfig Preference create PreApproval create
           Payment get PaymentRefund create requestOptions idempotencyKey"
2. resolve-library-id("mercadopago") → query-docs
   query: "webhooks x-signature x-request-id manifest ts v1 WebhookSignatureValidator"
3. resolve-library-id("nextjs") → query-docs
   query: "App Router route handlers request.text() nextUrl.searchParams webhook"
```

**Razón:** MP firma **headers + query**, no el body (familia `hmac_field_concat`); el reflejo
`createHmac(secret).update(rawBody)` falla el 100 % de las veces y termina en "rotar el secret".
El manifest es `id:{data.id};request-id:{x-request-id};ts:{ts};` (termina en `;`). Y MP recibe
montos en **unidad mayor** (199.00), al revés de Stripe — con CLP (exponente 0) `* 100` es un
sobrecobro 100× (PAY-004). Citar `[docs:mercadopago@v2]` en commits.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | Schema R-005 v1.1.0 |
| Components | src/shared/components/ui/{Button,Input,Form,Card,Badge}/* | impeccable output |
| Auth | src/lib/{supabase,insforge}/server.ts + 0001_profiles.sql aplicado | add-login output |
| Tech Spec | TECH-SPEC-<nombre>.md sec "Payments Decision" = mercadopago | Sale del ranking (`decision-tree.md`) |
| Planes | TECH-SPEC pricing section o user input → `lib/mercadopago/plans.ts` | ≥1 plan; montos en unidades MENORES + moneda |
| Rails | país del vendedor → `MP_ALLOWED_PAYMENT_TYPES` (MX default: card + ticket/OXXO + bank_transfer/SPEI) | catálogo `regions[MX].instant_rail` |
| Project name | brand.json.brand.product | Required |

## Pasos

### 1. PREFLIGHT (R10 + add-login chain) — igual que Mode A

Validar `brand/brand.json` (`schema_version >= "1.1.0"`), `voice.json` con ≥3 `cta_examples`,
componentes de impeccable, `src/lib/cn.ts`, auth server client, `0001_*_profiles.sql` aplicado.
Si alguno falta → halt con mensaje específico.

### 2. Substitute templates → src/

Copiar de `.claude/skills/add-payments/templates/mercadopago/` a `src/` (+ `templates/shared/`):

| Template path | Target path | Substitutions |
|---------------|-------------|---------------|
| `lib/mercadopago/client.ts` | `src/lib/mercadopago/client.ts` | none (public key from env) |
| `lib/mercadopago/server.ts` | `src/lib/mercadopago/server.ts` | none |
| `lib/mercadopago/verify.ts` | `src/lib/mercadopago/verify.ts` | none — módulo PURO, no tocar (lo ejecuta la Layer 3) |
| `lib/mercadopago/plans.ts` | `src/lib/mercadopago/plans.ts` | `PLANS`: nombres, `amountMinor`, `currency` del Tech Spec |
| `app/api/webhooks/mercadopago/route.ts` | `src/app/api/webhooks/mercadopago/route.ts` | none |
| `app/api/mercadopago/{checkout,portal,refund-request}/route.ts` | `src/app/api/mercadopago/…` | none |
| `app/(billing)/{pricing,checkout,success,billing}/page.tsx` | `src/app/(billing)/…` | `{{ COPY_* }}` desde voice.json (gate 7); `TIERS` en pricing |
| `actions/mercadopago.ts` | `src/actions/mercadopago.ts` | none |
| `types/billing.ts` | `src/types/billing.ts` | none (compartido con Mode A/B) |
| `migrations/0002_subscriptions.sql` | `supabase/migrations/0002_subscriptions.sql` | none |
| `shared/migrations/0003_payments_ledger.sql` | `supabase/migrations/0003_payments_ledger.sql` | none (policy por org se crea sola si existe `auth_org_ids()`) |
| `shared/tests/payments/webhook-mercadopago.test.mjs` | `tests/payments/webhook-mercadopago.test.mjs` | none — corre en CI (job `payments`) |
| `shared/payment-page-scripts.json` | `payment-page-scripts.json` (raíz) | `{{ SECURITY_OWNER_EMAIL }}`, `{{ TODAY }}` |

### 3. Env vars (.env.local, append-only — solo credenciales `TEST-`, Rule 8)

```
MP_ACCESS_TOKEN=TEST-REPLACE_ME            # Dashboard → Tus credenciales → Test
NEXT_PUBLIC_MP_PUBLIC_KEY=TEST-REPLACE_ME  # solo si Bricks embebido
MP_WEBHOOK_SECRET=REPLACE_ME               # Dashboard → Webhooks → Configurar notificación
MP_ALLOWED_PAYMENT_TYPES=credit_card,debit_card,ticket,bank_transfer
NEXT_PUBLIC_MP_PLAN_ID_HOBBY=hobby
NEXT_PUBLIC_MP_PLAN_ID_PRO=pro
NEXT_PUBLIC_MP_PLAN_ID_TEAM=team
MP_SUBSCRIPTIONS_PORTAL_URL=https://www.mercadopago.com.mx/subscriptions   # .com.ar / .com.br / … según país
```

`APP_USR-…` (live) **nunca** en `.env.example` ni en commits: el escáner R15 lo rechaza (D-038).

### 4. Webhook en el dashboard

URL pública `https://<app>/api/webhooks/mercadopago` (localhost no sirve — `cloudflared`/`ngrok` en
dev). Eventos mínimos: `payment` (created/updated) + `subscription_preapproval`. Copiar el secret a
`MP_WEBHOOK_SECRET`. MP espera 200/201 en ≤22 s; reintenta cada 15 min si no.

### 5. Verificación (Three-Layer, R7)

```
L1  npx tsc --noEmit
L2  bash .claude/skills/add-payments/tests/dry-run-mercadopago.sh
    bash .claude/skills/add-payments/tests/payments-gate.sh src/     ← PAY-001..008 sobre lo generado
L3  node --experimental-strip-types tests/payments/webhook-mercadopago.test.mjs
    (válido pasa · forjado / secret incorrecto / sin header / replay / request-id alterado se rechazan)
    + sandbox real: pago de prueba con tarjeta de test del país → webhook llega → ledger `payments` + acceso
```

### 6. Handoff a el-guardian

`prompts/handoff-el-guardian.md` (10 gates × 3 proveedores) + lente **pagos** (`payments-gate.sh`).
Registrar en el Tech Spec `payments.onboarding_lead_time` (del ranking) y la comisión típica
(`--amount/--currency`) como input de `/precio`.

## Lo que Mode C NO hace (y por qué)

- **No `cancel_at_period_end`:** MP no lo soporta en PreApproval. Default = `paused` (se conserva la
  suscripción; el webhook `paused` revoca acceso); `immediately` = `cancelled`. Documentado en
  `references/mercadopago-patterns.md`.
- **No refund automático en OXXO/SPEI/Pix:** el action registra `payout_required` y un humano ejecuta
  el payout (R14 · PAY-006).
- **No Customer Portal embebido:** MP no lo tiene; `/billing` enlaza al portal del payer.
- **No confía en el body del webhook:** siempre re-fetch (`payload_authoritative = false`).
- **No emite CFDI:** en MX "pago exitoso ≠ factura emitida" — el checkout debe capturar RFC si aplica
  (`references/subscription-lifecycle.md` § Fiscal; `el-ontologo` lo pregunta en Fase −1).
