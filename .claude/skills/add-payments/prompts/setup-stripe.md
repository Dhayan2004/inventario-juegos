# Setup Stripe — Mode A (default)

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("stripe-node") → query-docs
   query: "Stripe.checkout.sessions.create webhooks constructEvent
           signature verification raw body Next.js"
2. resolve-library-id("stripe") → query-docs
   query: "@stripe/stripe-js loadStripe Customer Portal billingPortal create"
3. resolve-library-id("nextjs") → query-docs
   query: "App Router route handlers raw body req.text() Stripe webhook"
```

**Razón:** Stripe API version pinning crítico — `Stripe.checkout.sessions.create` shape cambió entre 2023-10-16 y 2024+ versions. `constructEvent` (signature verification) requiere raw body, no parsed JSON — Next.js App Router necesita `request.text()` antes de cualquier `request.json()`. Sin find-docs, runtime falla con "No signatures found matching the expected signature for payload" o (peor) signature verification deprecada que pasa silenciosamente. Citar como `[docs:stripe@v18]` y `[docs:stripe-node@latest]` en commits.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | Schema R-005 v1.1.0 |
| Components | src/shared/components/ui/{Button,Input,Form,Card,Badge}/* | impeccable output |
| Auth | src/lib/{supabase,insforge}/server.ts + 0001_profiles.sql aplicado | add-login output |
| Tech Spec | TECH-SPEC-<nombre>.md sec "Payments Decision" = stripe | Optional (fallback default) |
| Pricing tiers | TECH-SPEC pricing section o user input | ≥1 tier requerido |
| Project name | brand.json.brand.product | Required |

## Pasos

### 1. PREFLIGHT (R10 + add-login chain)

Validar que existan:
- `brand/brand.json` con `schema_version >= "1.1.0"`
- `brand/voice.json` con `cta_examples` ≥ 3 entries (gate 7 SKILL.md)
- `src/shared/components/ui/{Button,Input,Form,Card,Badge}/*.tsx` (impeccable output)
- `src/lib/cn.ts`
- `src/lib/supabase/server.ts` o `src/lib/insforge/server.ts` (add-login output)
- `supabase/migrations/0001_*_profiles.sql` aplicado (auth.users + profiles existen)

Si alguno falta → halt con mensaje específico. NO degradar a Tailwind defaults ni inventar profiles schema.

### 2. Substitute templates → src/

Copiar de `.claude/skills/add-payments/templates/stripe/` a `src/`:

| Template path | Target path | Substitutions |
|---------------|-------------|---------------|
| `lib/stripe/client.ts` | `src/lib/stripe/client.ts` | none (publishable key from env) |
| `lib/stripe/server.ts` | `src/lib/stripe/server.ts` | `{{ STRIPE_API_VERSION }}` → API version pinned (find-docs) |
| `app/(billing)/pricing/page.tsx` | `src/app/(billing)/pricing/page.tsx` | `{{ COPY_PRICING_TITLE }}`, `{{ COPY_PRICING_CTA }}`, `{{ TIER_LABELS }}` |
| `app/(billing)/checkout/page.tsx` | `src/app/(billing)/checkout/page.tsx` | `{{ COPY_CHECKOUT_TITLE }}`, `{{ COPY_CHECKOUT_CTA }}` |
| `app/(billing)/success/page.tsx` | `src/app/(billing)/success/page.tsx` | `{{ COPY_SUCCESS_TITLE }}`, `{{ COPY_SUCCESS_CTA_BACK }}` |
| `app/(billing)/billing/page.tsx` | `src/app/(billing)/billing/page.tsx` | `{{ COPY_BILLING_TITLE }}`, `{{ COPY_PORTAL_CTA }}` |
| `app/api/webhooks/stripe/route.ts` | `src/app/api/webhooks/stripe/route.ts` | none — signature verification + idempotency hard-coded |
| `app/api/stripe/checkout/route.ts` | `src/app/api/stripe/checkout/route.ts` | none — rate limiting documentado en JSDoc |
| `app/api/stripe/portal/route.ts` | `src/app/api/stripe/portal/route.ts` | none |
| `app/api/stripe/refund-request/route.ts` | `src/app/api/stripe/refund-request/route.ts` | none — R14 typed confirmation gate |
| `actions/stripe.ts` | `src/actions/stripe.ts` | none — whitelist validators L-003 + R14 gates |
| `types/billing.ts` | `src/types/billing.ts` | none |
| `migrations/0002_subscriptions.sql` | `supabase/migrations/0002_<timestamp>_subscriptions.sql` | timestamp |

### 3. Copy substitutions (R10 enforcement)

Copy derivado de voice.json + brand.json:

```javascript
const voice = JSON.parse(readFile('brand/voice.json'));
const brand = JSON.parse(readFile('brand/brand.json'));
const product = brand.brand.product;

// Helper: prefer payment-oriented CTA from cta_examples; fallback conservador.
function pickCta(predicate, fallback) {
  const match = voice.voice.cta_examples.find(predicate);
  if (match) return match;
  // PREFLIGHT gate 7: warn a el-evaluador
  console.warn(`[add-payments] voice.json cta_examples sin orientación payment. Usando fallback conservador: "${fallback}"`);
  return fallback;
}

// Pricing
COPY_PRICING_TITLE = `Elegí tu plan de ${product}`;
COPY_PRICING_CTA = pickCta(c => /(suscrib|comprar|continuar|empezar)/i.test(c), 'Continuar al pago');

// Checkout
COPY_CHECKOUT_TITLE = 'Finalizá tu suscripción';
COPY_CHECKOUT_CTA = pickCta(c => /(confirm|pagar|finaliz)/i.test(c), 'Confirmar suscripción');

// Success
COPY_SUCCESS_TITLE = `Bienvenido a ${product}`;
COPY_SUCCESS_CTA_BACK = pickCta(c => /(panel|dashboard|inicio|empez)/i.test(c), 'Ir al panel');

// Billing (customer portal entry)
COPY_BILLING_TITLE = 'Tu suscripción';
COPY_PORTAL_CTA = pickCta(c => /(gestionar|administrar|portal|edit)/i.test(c), 'Gestionar facturación');

// Audit avoid_words
const avoid = voice.voice.avoid_words;
const allCopy = [COPY_PRICING_TITLE, COPY_PRICING_CTA, COPY_CHECKOUT_TITLE, COPY_CHECKOUT_CTA,
                 COPY_SUCCESS_TITLE, COPY_SUCCESS_CTA_BACK, COPY_BILLING_TITLE, COPY_PORTAL_CTA];
allCopy.forEach(s => avoid.forEach(w => {
  if (s.toLowerCase().includes(w.toLowerCase())) throw new Error(`Voice violation: "${w}" in "${s}"`);
}));
```

Tier labels en `/pricing` (ej: "Hobby" / "Pro" / "Team") vienen del Tech Spec o del input del usuario; el audit `avoid_words` corre contra ellos también.

### 4. Append .env.local

```bash
# Append (NO overwrite) si .env.local existe:
cat >> .env.local <<'EOF'

# Payments — Stripe (added by add-payments)
# Public (NEXT_PUBLIC_) — safe en client
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_REPLACE
NEXT_PUBLIC_STRIPE_PRICE_ID_HOBBY=price_REPLACE
NEXT_PUBLIC_STRIPE_PRICE_ID_PRO=price_REPLACE
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Server-only (NEVER prefix with NEXT_PUBLIC_)
STRIPE_SECRET_KEY=sk_test_REPLACE
STRIPE_WEBHOOK_SECRET=whsec_REPLACE
EOF
```

NO escribir valores reales. Solo placeholders. Usuario debe llenar tras correr.

### 5. Verificación pre-handoff

```bash
# L1 syntax
npx tsc --noEmit                                                # parsea TS
supabase db lint supabase/migrations/*subscriptions.sql   # parsea SQL (preferido)
# fallback si supabase CLI no disponible:
# psql -d "$DATABASE_URL" -f supabase/migrations/*subscriptions.sql \
#   --single-transaction --variable=ON_ERROR_STOP=1 --dry-run-equivalent

# Security pre-handoff (8-check)
# 1. STRIPE_SECRET_KEY isolation
grep -r "STRIPE_SECRET_KEY" src/app/\(*\)/                 # debe estar vacío
grep -r "STRIPE_SECRET_KEY" src/lib/stripe/server.ts        # presente
# 2. .trim() en webhook secret
grep "STRIPE_WEBHOOK_SECRET" src/app/api/webhooks/stripe/route.ts | grep -q "\.trim()"
# 3. Signature verification BEFORE DB op
grep -B2 "supabase\|insforge" src/app/api/webhooks/stripe/route.ts | grep -q "constructEvent"
# 4. R14 — refund/cancel/transfer NO export execute()
! grep -E "^export.*execute.*async.*(refund|cancel|transfer)" src/actions/stripe.ts
# 5. Server actions validan ownership
grep -E "user\.id.*===.*metadata\.user_id|auth\.uid\(\).*=" src/actions/stripe.ts
# 6. RLS habilitado en subscriptions
grep "enable row level security" supabase/migrations/*subscriptions.sql
grep "auth.uid() = user_id" supabase/migrations/*subscriptions.sql  # ≥1 match
# 7. Rate limiting documentado en checkout route
grep -E "rate.?limit|5.req|hour" src/app/api/stripe/checkout/route.ts
# 8. Idempotency check en webhook
grep -E "current_period_end|already.processed|idempot" src/app/api/webhooks/stripe/route.ts
```

### 6. Output handoff

Imprimir el bloque `## add-payments handoff` (ver SKILL.md) con:
- **Mode:** STRIPE
- **assumed_default:** según fallback usado
- 8-check security checklist
- Brand Score per page (4 pages)

Mandatory next step: invocar `el-guardian` con `prompts/handoff-el-guardian.md`.

## Citations

- [docs:stripe] · [docs:stripe-node] · [docs:stripe@v18] · [docs:nextjs] (R13)
- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:CONSTRAINTS.md#R13] (external docs citation)
- [memory:CONSTRAINTS.md#R14] (destructive tools — refund/cancel/transfer)
- [memory:lessons#L-001] (RLS by user_id en subscriptions)
- [memory:lessons#L-002] (webhook signature + metadata as data)
- [memory:lessons#L-003] (whitelist validation en checkout/refund inputs)
- [memory:decisions#D-009] (default + override pattern — Stripe es default por friction reduction)
