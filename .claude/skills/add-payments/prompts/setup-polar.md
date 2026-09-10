# Setup Polar — Mode B (alternativa MoR)

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("polar-sdk") → query-docs
   query: "Polar checkouts.custom.create webhooks validateEvent
           WebhookVerificationError @polar-sh/sdk"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router route handlers raw body request.text() webhook"
```

**Razón:** Polar SDK shape es inestable (v0.x) — los exports de `@polar-sh/sdk/webhooks` (`validateEvent`, `WebhookVerificationError`) no existen en versiones <0.10. Si tu code generation asume un shape viejo, runtime falla con `validateEvent is not a function` al primer hit del webhook (el error puede no aparecer hasta el primer pago real). Citar como `[docs:polar-sdk@v0.x]` y `[docs:polar]` en commits.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | Schema R-005 v1.1.0 |
| Components | src/shared/components/ui/{Button,Input,Form,Card,Badge}/* | impeccable output |
| Auth | src/lib/{supabase,insforge}/server.ts + 0001_profiles.sql aplicado | add-login output |
| Tech Spec | TECH-SPEC-<nombre>.md sec "Payments Decision" = polar | Required (default es Stripe) |
| Pricing tiers | TECH-SPEC pricing section o user input | ≥1 tier requerido |
| Project name | brand.json.brand.product | Required |

## Pasos

### 1. PREFLIGHT (R10 + add-login chain)

Idéntico a Mode A (ver `setup-stripe.md` paso 1). Adicional para Polar:
- Verificar que el operador NO tenga empresa registrada en Tech Spec, OR que decision tree haya devuelto Polar explícitamente. Si decision tree apunta a Stripe pero el usuario fuerza Polar manualmente, loggear warning y continuar.

Si alguno falta → halt con mensaje específico. NO degradar a Tailwind defaults ni inventar profiles schema.

### 2. Substitute templates → src/

Copiar de `.claude/skills/add-payments/templates/polar/` a `src/`:

| Template path | Target path | Substitutions |
|---------------|-------------|---------------|
| `lib/polar/client.ts` | `src/lib/polar/client.ts` | none |
| `lib/polar/server.ts` | `src/lib/polar/server.ts` | `{{ POLAR_ENVIRONMENT }}` → `sandbox` o `production` |
| `app/(billing)/pricing/page.tsx` | `src/app/(billing)/pricing/page.tsx` | mismas que Mode A |
| `app/(billing)/checkout/page.tsx` | `src/app/(billing)/checkout/page.tsx` | mismas |
| `app/(billing)/success/page.tsx` | `src/app/(billing)/success/page.tsx` | mismas |
| `app/(billing)/billing/page.tsx` | `src/app/(billing)/billing/page.tsx` | mismas |
| `app/api/webhooks/polar/route.ts` | `src/app/api/webhooks/polar/route.ts` | none — validateEvent + idempotency |
| `app/api/polar/checkout/route.ts` | `src/app/api/polar/checkout/route.ts` | none — rate limiting documentado |
| `app/api/polar/portal/route.ts` | `src/app/api/polar/portal/route.ts` | none |
| `app/api/polar/refund-request/route.ts` | `src/app/api/polar/refund-request/route.ts` | none — R14 typed confirmation |
| `actions/polar.ts` | `src/actions/polar.ts` | none — whitelist validators L-003 + R14 gates |
| `types/billing.ts` | `src/types/billing.ts` | shared con Mode A — si ya copiado, skip |
| `migrations/0002_subscriptions.sql` | `supabase/migrations/0002_<timestamp>_subscriptions.sql` | timestamp |

**Nota:** la SQL migration es shape-shareable con Mode A (subscriptions table no varía entre Stripe y Polar — solo cambia el shape de los IDs externos: `polar_subscription_id` vs `stripe_subscription_id`). El template Polar usa columnas `provider text check (provider in ('stripe', 'polar'))` + `external_subscription_id text` para soportar futura migración entre providers sin re-schema.

### 3. Copy substitutions (R10 enforcement)

Idéntico al Mode A (`setup-stripe.md` paso 3) — el helper `pickCta()` y las copy keys son las mismas. Solo cambia el routing interno (Polar checkout URL en lugar de Stripe Checkout Session).

```javascript
// Adicional Polar-specific:
// El customer portal de Polar es externo (polar.sh URL). El /billing
// page redirige al portal de Polar después de un click — no embed iframe.
COPY_PORTAL_REDIRECT_NOTE = 'Te redirigimos al portal de facturación de Polar';
```

### 4. Append .env.local

```bash
# Append (NO overwrite) si .env.local existe:
cat >> .env.local <<'EOF'

# Payments — Polar (added by add-payments)
# Server-only (NEVER prefix with NEXT_PUBLIC_)
POLAR_ACCESS_TOKEN=polar_at_REPLACE
POLAR_WEBHOOK_SECRET=polar_whsec_REPLACE
POLAR_PRODUCT_ID=REPLACE_PRODUCT_UUID
POLAR_ENVIRONMENT=sandbox

# Public — safe en client
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
```

NO escribir valores reales. Solo placeholders. Polar usa OAuth tokens (`polar_at_*`) — son server-only sin excepción.

### 5. Verificación pre-handoff

```bash
# L1 syntax
npx tsc --noEmit                                                # parsea TS
supabase db lint supabase/migrations/*subscriptions.sql   # parsea SQL

# Security pre-handoff (8-check)
# 1. POLAR_ACCESS_TOKEN isolation
grep -r "POLAR_ACCESS_TOKEN" src/app/\(*\)/                # debe estar vacío
grep -r "POLAR_ACCESS_TOKEN" src/lib/polar/server.ts        # presente
# 2. .trim() en webhook secret
grep "POLAR_WEBHOOK_SECRET" src/app/api/webhooks/polar/route.ts | grep -q "\.trim()"
# 3. validateEvent BEFORE DB op
grep -B2 "supabase\|insforge" src/app/api/webhooks/polar/route.ts | grep -q "validateEvent"
# 4. R14 — refund/cancel NO export execute()
! grep -E "^export.*execute.*async.*(refund|cancel)" src/actions/polar.ts
# 5. Server actions validan ownership
grep -E "user\.id.*===.*metadata\.user_id|auth\.uid\(\).*=" src/actions/polar.ts
# 6. RLS habilitado en subscriptions (compartido con Mode A)
grep "enable row level security" supabase/migrations/*subscriptions.sql
grep "auth.uid() = user_id" supabase/migrations/*subscriptions.sql
# 7. Rate limiting documentado en checkout route
grep -E "rate.?limit|5.req|hour" src/app/api/polar/checkout/route.ts
# 8. Idempotency check en webhook (current_period_end o equivalente)
grep -E "current_period_end|already.processed|idempot" src/app/api/webhooks/polar/route.ts
```

### 6. Output handoff

Imprimir el bloque `## add-payments handoff` (ver SKILL.md) con:
- **Mode:** POLAR
- **MoR note:** Polar maneja tax + entity legal — el operador no necesita empresa registrada
- 8-check security checklist
- Brand Score per page (4 pages)

Mandatory next step: invocar `el-guardian` con `prompts/handoff-el-guardian.md`.

## Diferencias relevantes vs Mode A

| Aspecto | Stripe (Mode A) | Polar (Mode B) |
|---------|-----------------|----------------|
| Customer portal | `stripe.billingPortal.sessions.create` (mismo dominio embed-friendly) | URL externa polar.sh — redirect, no embed |
| Webhook signature | `stripe.webhooks.constructEvent(body, sig, secret)` | `validateEvent(body, headers, secret)` from `@polar-sh/sdk/webhooks` |
| Event canonicales | `customer.subscription.created/updated/deleted` | `subscription.active / canceled / revoked` |
| Acceso "ON" trigger | `customer.subscription.updated` con `status === 'active'` | `subscription.active` (event explícito) |
| Tax handling | Stripe Tax requiere config + empresa registrada | Polar = MoR, automatic |
| Refund flow | `stripe.refunds.create({ charge })` | `polar.refunds.create({ subscription_id })` |
| Test cards | 4242 4242 4242 4242 | 4242 4242 4242 4242 (Polar wraps Stripe) |
| Setup time típico | ~1h con Stripe Tax + Customer Portal config | ~10 min con sandbox |

## Citations

- [docs:polar] · [docs:polar-sdk] · [docs:polar-sdk@v0.x] · [docs:nextjs] (R13)
- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:CONSTRAINTS.md#R13] (external docs citation)
- [memory:CONSTRAINTS.md#R14] (destructive tools — refund/cancel)
- [memory:lessons#L-001] (RLS by user_id en subscriptions)
- [memory:lessons#L-002] (webhook signature + metadata as data)
- [memory:lessons#L-003] (whitelist validation en checkout/refund inputs)
- [memory:decisions#D-009] (default + override pattern — Polar es override explícito)
