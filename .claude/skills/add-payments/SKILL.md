---
name: add-payments
description: >
  Pagos completos drop-in para proyecto target. 3 modos con paridad
  estructural: Stripe (default por ranking), Polar (Merchant of Record) y
  Mercado Pago (LATAM: OXXO · SPEI · Pix · PSE, montos con exponente ISO
  4217). El proveedor lo decide un ranking DETERMINISTA
  (vendor/pagokit/advise.js, catálogo de 42 proveedores/136 métodos/106
  monedas — D-038), no una tabla de prosa; toda recomendación cita su
  last_verified_at y si el proveedor es build o solo advise.
  Templates pre-armados (no solo docs): SDK clients server + client,
  webhook handler con signature verification, /pricing + /checkout +
  /success pages, customer portal entry (/billing) + dashboard, server
  actions con whitelist validators + R14 gates, 0002_subscriptions.sql
  con RLS L-001 enforced. Pages consumen componentes de impeccable (R10)
  y copy derivado de voice.json (CTAs + pricing tiers). R14 enforced en
  refund, cancelSubscription, transferFunds (typed confirmation, no
  execute() automático); rails irreversibles (OXXO/SPEI/Pix) NUNCA se
  "reembolsan" por API (payout manual, PAY-006). Ledger
  0003_payments_ledger.sql: payments + webhook_events_processed (dedup)
  + idempotency_keys, tenant-aware (R16). Gate mecánico PAY-001..008
  (tests/payments-gate.sh) + Layer 3 con eventos firmados válido/forjado/
  replay (L-010). el-guardian handoff mandatory pre-deploy.
tier: optional
requires: AGENTS.md exists, add-login completado (src/lib/{supabase,insforge}/* + 0001_profiles.sql aplicado), Brand DNA contract presente (brand/brand.json + voice.json), impeccable corrió previamente (componentes UI base existen en src/shared/components/ui/), .env.local writable.
fallback: Sin Tech Spec con `payments.provider` documentado → Stripe como default (assumed_default flag). Sin add-login → halt + handoff a add-login. Sin Brand DNA → halt + handoff a add-ui-kit. Sin impeccable components → halt + handoff a impeccable Mode C. Sin .env.local writable → crear con placeholders + flag al usuario.
dependencies: [find-docs, baas, add-login, impeccable, add-ui-kit]
---

# add-payments

> *"Cobrar es un acto de marca. Si el checkout traiciona el contrato, el cliente lo siente."*
> — Forja R10

Skill drop-in. Setea pagos completos (checkout + customer portal + webhooks + subscriptions + ledger + RLS) en un proyecto target, en uno de **tres** paths que decide un ranking determinista: **Stripe** (default), **Polar** (Merchant of Record) o **Mercado Pago** (LATAM: OXXO/SPEI/Pix/PSE). Output: ~22 archivos pre-armados por modo + ledger compartido + test de Layer 3, que el target adopta sin reescribir desde cero. Vendor: `vendor/pagokit/` (PagoKit 0.2.2, MIT — datos + `advise.js` + `sign-event.js`; `PROVENANCE.md`, vetting en `docs/security/VETTING-pagokit-0.2.2.md`). Cita [memory:decisions#D-038] · [memory:references#R-012].

## PREFLIGHT halt (8 gates)

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Existe TECH-SPEC-<nombre>.md con sección "Payments Decision"? Si no → fallback: Stripe con flag `assumed_default = true` (loggear).
3. ¿Existe src/lib/{supabase|insforge}/server.ts + 0001_profiles.sql aplicado? Si no → halt: "Falta auth. Corré /add-login primero — payments depende de profiles."
4. ¿Existe brand/brand.json + voice.json? Si no → halt: "Falta Brand DNA. Corré /add-ui-kit primero. R10 no negociable."
5. ¿brand.json cumple R-005 v1.1.0 (schema_version + keyed spacing + motion enums)? Si no → halt: "brand.json malformado. Corré /add-ui-kit (regen)."
6. ¿Existe src/shared/components/ui/{Button,Input,Form,Card,Badge}/*.tsx? Si no → halt: "Faltan componentes base. Corré /impeccable Mode C primero."
7. ¿voice.json declara cta_examples con ≥3 entries totales? Si sí → procedé, mapeando los más cercanos a contexto payment. Si los cta_examples son genéricos sin orientación payment, warning a el-evaluador (no halt) y usar fallback conservador (`Continuar al pago`, `Confirmar suscripción`, `Volver al panel`).
8. ¿Existe .env.local writable? Si no → crear con placeholders y emitir warning (usuario debe llenar credentials).
```

Sin estos 8 gates, add-payments retorna error sin generar código.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide "agregame pagos / billing / checkout / suscripciones" | Coordinator |
| add-login cierra y proyecto declara `payments.required = true` en Tech Spec | add-login handoff |
| la-herreria fase 8 (UI Design Workflow) detecta pricing pages en User Stories | la-herreria handoff |
| Otro skill (add-emails para invoice receipts) requiere `subscriptions` table | skill handoff |

## Decision tree — ranking determinista (advise.js), no prosa

Detalle en [`prompts/decision-tree.md`](prompts/decision-tree.md). El proveedor **no se decide a mano**:

```bash
node .claude/skills/add-payments/vendor/pagokit/scripts/advise.js --json '{
  "seller_country": "MX", "buyer_regions": ["MX"], "billing_mode": "subscription",
  "required_methods": ["oxxo","spei"], "entity_type": "company",
  "example_transaction_amount": 499, "example_currency": "MXN", "needs_keys_within_days": 14 }'
```

El JSON devuelve `recommendation` + `rejected[]` (cada rechazo con su filtro) + fee en dinero real +
`integration_level` (**build** = Forja lo genera · **advise** = el código es tuyo) + `last_verified_at`
(disclaimer obligatorio). El agente **narra** ese output, no lo recomputa (misma filosofía que
`verificar-ci`). Mapa de salida:

| `recommendation.id` | Modo | Templates |
|---|---|---|
| `stripe` (default cuando el ranking lo da o no hay Tech Spec) | **A** | `templates/stripe/**` |
| `polar` (MoR: sin empresa, audiencia global, producto digital) | **B** | `templates/polar/**` |
| `mercadopago` (vendedor LATAM, rails locales OXXO/SPEI/Pix/PSE, cobros en MXN/ARS/BRL/…) | **C** | `templates/mercadopago/**` |
| cualquier otro `build: false` | **ADVISE** | recomendación + fee + checklist; el código es tuyo (regla de honestidad de PagoKit) |
| sin proveedor viable | **PAUSE** | halt + handoff (constituir empresa / MoR cross-border) |

Señales que el ranking ya pondera (no las re-preguntes): país del vendedor y compradores · one-time vs
recurrente · rails requeridos · entidad legal (individual/company) · tipo de producto · plataforma
(iOS = IAP) · **días hasta necesitar llaves** (`needs_keys_within_days` → `payments.onboarding_lead_time`
en el Tech Spec y bloqueador en `.plan/` si excede el hito, G7) · comisión típica (`--amount/--currency`
→ input citable de `/precio`, G8).

## 3 modos de operación (paridad estructural — ningún modo es ciudadano de segunda, D-010/D-038)

### MODE A — STRIPE (default)

Trigger:
- Tech Spec `payments.provider = stripe`, OR
- Sin Tech Spec (fallback default), OR
- Decision tree señales: empresa registrada + features avanzados (Tax, Connect, scheduling).

Flow:
```
a. find-docs (R13): resolve-library-id("stripe-node") + query-docs
   "Stripe.checkout.sessions.create webhooks signature verification@v18"
b. find-docs (R13): resolve-library-id("stripe") + query-docs
   "@stripe/stripe-js loadStripe Elements Customer Portal"
c. find-docs (R13): resolve-library-id("nextjs") + query-docs
   "App Router route handlers webhook raw body Stripe Next.js 16"
d. Read brand/brand.json + voice.json (R10 enforcement)
e. Substituir tokens en templates/stripe/** → src/**
   · placeholders {{ APP_NAME }}, {{ COPY_PRICING_CTA }}, {{ TIER_LABELS }}
   · imports apuntan a src/shared/components/ui/* (impeccable output)
f. Generar 0002_subscriptions.sql con RLS L-001 enforced + JSDoc cita
g. Append vars a .env.local (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET,
   STRIPE_PUBLISHABLE_KEY, NEXT_PUBLIC_STRIPE_PRICE_ID_*)
h. Output handoff a el-guardian (pre-deploy security audit checklist)
```

Detalle: `prompts/setup-stripe.md`.

### MODE B — POLAR (alternativa MoR)

Trigger:
- Tech Spec `payments.provider = polar`, OR
- Decision tree señales: sin empresa + audiencia global + producto digital simple + setup speed prioritario.

Flow paralelo a Mode A pero con SDK `@polar-sh/sdk` en `lib/polar/{client,server}.ts` + webhook handler con `validateEvent + WebhookVerificationError` + handlers para `subscription.active / canceled / revoked / checkout.updated`. Polar es Merchant of Record — maneja tax + entity legal. Misma estructura de pages (/pricing, /checkout, /success, /billing) con shape adaptado.

Detalle: `prompts/setup-polar.md`.

### MODE C — MERCADO PAGO (LATAM)

Trigger:
- Tech Spec `payments.provider = mercadopago`, OR
- Ranking: vendedor en MX/AR/BR/CL/CO/PE/UY con rails locales (OXXO, SPEI, Pix, PSE, boleto) o cobro en moneda local.

Flow paralelo a Mode A con SDK `mercadopago` v2 (`lib/mercadopago/{client,server,verify,plans}.ts`):
Checkout Pro (`Preference`) para pago único y `PreApproval` para suscripciones; webhook con firma sobre el
**manifest** `id;request-id;ts;` (NO sobre el body — familia `hmac_field_concat`, verificador puro en
`verify.ts` re-verificado contra el SDK oficial) + ventana 300 s + dedup por event id + **re-fetch**
(el payload no es autoritativo); montos en unidad MAYOR hacia la API y unidades MENORES en DB con
exponente ISO 4217 (`references/currencies.md`); rails irreversibles marcados en el ledger
(`refundable = false`) → el refund se rechaza y abre `payout_required` (R14). Sin Customer Portal
embebido (enlaza al portal del payer); sin `cancel_at_period_end` (default `paused`).

Detalle: `prompts/setup-mercadopago.md` · `references/mercadopago-patterns.md`.

## Loop de ejecución

```
0. PREFLIGHT halt (8 gates)
1. Detectar modo (Tech Spec "Payments Decision" o correr advise.js — decision-tree.md)
   ├─ payments.provider = stripe OR sin spec y el ranking da stripe → Mode A
   ├─ payments.provider = polar                                    → Mode B
   ├─ payments.provider = mercadopago                              → Mode C
   ├─ ranking → proveedor build: false                             → ADVISE (sin generar código)
   └─ ranking → sin proveedor viable                               → PAUSE

2. Pre-gen find-docs (R13):
   - Stripe mode: resolve-library-id("stripe-node") + ("stripe")
   - Polar mode: resolve-library-id("polar-sdk")
   - Mercado Pago mode: resolve-library-id("mercadopago") "sdk-nodejs v2 Preference PreApproval PaymentRefund webhooks x-signature"
   - Common: resolve-library-id("nextjs") "App Router 16 raw body webhooks"

3. Read brand.json + voice.json (R10):
   - tokens.colors → CSS vars en pricing tiers (vía impeccable)
   - voice.cta_examples → copy de "Suscribirse" / "Continuar al pago"
   - voice.avoid_words → audit de strings en pricing tiers (no "revolutionary")

4. Substituir templates → src/**
   · /pricing /checkout /success pages
   · /billing dashboard (customer portal entry)
   · /api/webhooks/{stripe|polar|mercadopago}/route.ts (signature-verified)
   · /api/{stripe|polar|mercadopago}/{checkout,portal,refund-request}/route.ts
   · lib/{stripe|polar|mercadopago}/{client,server}.ts (+ verify.ts, plans.ts en Mode C)
   · actions/{stripe|polar|mercadopago}.ts (whitelist validators L-003 + R14 gates)
   · types/billing.ts
   · templates/shared/ → tests/payments/webhook-*.test.mjs (Layer 3) + payment-page-scripts.json (PCI §6.4.3, G6)

5. Generar SQL migrations:
   · 0002_subscriptions.sql con RLS L-001 + 2 policies + indexes
   · 0003_payments_ledger.sql (templates/shared): payments + webhook_events_processed (dedup, G2)
     + idempotency_keys; organization_id nullable + policy por org SOLO si existe auth_org_ids() (R16, G1)
   · JSDoc cita [memory:lessons#L-001] en preámbulo
   · Insforge equivalent: lib/insforge/billing-schema.ts si baas = Insforge

6. .env.local update:
   · Append placeholders, NUNCA hardcodear valores reales
   · STRIPE_SECRET_KEY / POLAR_ACCESS_TOKEN / MP_ACCESS_TOKEN: server-only (solo TEST- en .env.example, Rule 8)
   · STRIPE_WEBHOOK_SECRET / POLAR_WEBHOOK_SECRET / MP_WEBHOOK_SECRET: server-only (.trim() crítico)
   · NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY / NEXT_PUBLIC_MP_PUBLIC_KEY: público OK
   · Llaves live (sk_live_ · APP_USR- · lmnsq_live_ · prv_prod_) NUNCA en commits — R15 las rechaza (D-038)

7. Security pre-handoff scan:
   · grep "STRIPE_SECRET_KEY" en src/app/(*) → vacío (solo en api/ + lib/server)
   · grep "POLAR_ACCESS_TOKEN" en src/app/(*) → vacío
   · webhook routes verifican signature ANTES de cualquier op
   · refund / cancelSubscription / transferFunds NO export execute() automático
   · server actions validan ownership (auth.uid() === subscription.user_id)
   · checkout route tiene rate limiting documentado en JSDoc
   · NO imports directos de stripe/polar/mercadopago SDK en client components
   · bash tests/payments-gate.sh src/ → PAY-001..008 limpios (webhook sin firma · body antes de verificar ·
     idempotency débil · `* 100` sin exponente · `===` en firma · refund en rail irreversible ·
     HMAC con API key · monto del cliente)
   · Layer 3: node --experimental-strip-types tests/payments/webhook-<provider>.test.mjs → el handler
     RECHAZA forjado / replay / secret incorrecto (L-010: un gate que nunca falla es decoración)

8. Output handoff a el-guardian (pre-deploy):
   · Pasar el checklist de prompts/handoff-el-guardian.md
   · Bloquear deploy hasta que el-guardian retorne PASS
```

## Reglas operativas

1. **brand.json + voice.json son contrato no-negociable (R10).** /pricing y /billing importan Card/Button/Badge de impeccable. Pricing tiers respetan `voice.avoid_words` (NO "revolutionary", "best-in-class"). CTAs derivan de `voice.cta_examples` o, si genéricos, fallback conservador (PREFLIGHT gate 7).
2. **find-docs antes de cada generación (R13).** Stripe API version pinning crítico — el SDK shape cambia entre versions. Polar SDK shape inestable (v0.x). Sin find-docs, runtime falla o (peor) signature verification deprecada.
3. **L-001 enforcement en subscriptions SQL.** El template incluye `enable row level security` + 2 policies (`auth.uid() = user_id` para SELECT, NO INSERT/UPDATE direct — solo via webhook server-side con service_role). Cita [memory:lessons#L-001].
4. **L-002 en webhook handlers.** Webhook payload está validado por signature (mandatory primer gate), pero `metadata.*` fields son user-controlled strings. NO ejecutar operaciones agentic basadas en metadata sin validar contra whitelist. Comment inline explicando el patrón.
5. **L-003 en validators.** `actions/{stripe,polar,mercadopago}.ts` whitelist:
   - `amount: z.number().int().positive().max(1_000_000_00)` (cap $10K safety)
   - `currency: z.enum(['usd','eur','mxn','ars','cop'])` (LATAM default)
   - `plan_id: z.enum([...known plans])` (NO `z.string()`)
   - `interval: z.enum(['month','year'])`
   Cita [memory:lessons#L-003].
6. **R14 strict en refunds.** `actions/{stripe,polar,mercadopago}.ts` NO export `execute()` automático en `refundCharge`, `cancelSubscription`, `transferFunds`. Cada uno requiere: server action recibe charge_id → valida ownership (`user.id === charge.metadata.user_id`) → typed-confirmation gate (input "REFUND" o "CANCEL") → audit log en DB pre-execute. Cita [memory:CONSTRAINTS.md#R14].
7. **Secret isolation.** STRIPE_SECRET_KEY / POLAR_ACCESS_TOKEN / MP_ACCESS_TOKEN solo en `lib/{stripe,polar,mercadopago}/server.ts` y `api/` routes. NUNCA en client components. Audit obligatoria pre-handoff.
8. **Webhook signature .trim() obligatorio.** STRIPE_WEBHOOK_SECRET / POLAR_WEBHOOK_SECRET / MP_WEBHOOK_SECRET con `.trim()` al leer de env — espacios invisibles rompen verificación silenciosamente.
9. **Idempotencia en webhook handlers.** El mismo evento puede llegar múltiples veces. Handler chequea `current_period_end` antes de upsert — si ya procesado, skip. Además dedup por event id en `webhook_events_processed` (0003, G2): el replay dentro de la ventana de firma también se rechaza.
9b. **Montos con exponente ISO 4217 (PAY-004).** Nunca `* 100`: `references/currencies.md` (generado del catálogo) + helpers `toMinorUnits`/`toMajorUnits`. CLP/JPY tienen exponente 0.
9c. **Rails irreversibles (PAY-006).** OXXO/SPEI/Pix/PSE/boleto no tienen refund por API: el ledger los marca `refundable = false` y el action abre `payout_required` para un humano (R14).
9d. **Honestidad del build.** Si el ranking devuelve un proveedor con `integration_level: advise` o `webhook_confidence != high`, NO se emite verificador ni templates: recomendación + checklist, y el código es del usuario.
10. **Acceso = subscription.active, NO checkout.succeeded.** El webhook concede `has_access = true` en `subscription.active` (Polar), `customer.subscription.created/updated` con `status === 'active'` (Stripe) o `subscription_preapproval` con `authorized` (Mercado Pago). NUNCA en `payment.*` de MP (un pago aprobado no es una suscripción autorizada). NO en checkout success — el frontend nunca es source of truth.
11. **Rate limiting en /api/checkout.** Documentado en JSDoc + comment. Anti-abuse: max 5 checkout sessions por user/hora.
12. **Brand Score per page ≥ 75.** el-evaluador valida /pricing /checkout /success /billing contra brand.json (mismo loop que impeccable). Threshold ≥75, target ≥85.

## Refusals (lo que NUNCA hace)

- ❌ Generar /pricing con Tailwind hardcoded (`bg-purple-500`, `text-gray-700`). Siempre vía componentes impeccable.
- ❌ Hardcodear pricing copy ignorando voice.json. CTAs siempre desde `voice.cta_examples` (con fallback conservador si genéricos).
- ❌ Skipear RLS en subscriptions SQL. L-001 no negociable.
- ❌ Exportar `refundCharge`, `cancelSubscription`, `transferFunds` como tools agentic con `execute()`. R14 binario.
- ❌ Conceder acceso en `checkout.succeeded` (frontend signal). Solo via webhook `subscription.active`.
- ❌ Commitear `.env.local` con valores reales. Solo placeholders.
- ❌ Importar `STRIPE_SECRET_KEY`, `POLAR_ACCESS_TOKEN` o `MP_ACCESS_TOKEN` en archivos accesibles desde client. Audit obligatoria.
- ❌ Emitir un verificador de webhook para un proveedor cuyo esquema no está verificado (`webhook_confidence != high`): re-fetch + dedup + TODO en su lugar.
- ❌ `amount * 100` a ciegas, o confiar `body.amount` del cliente (PAY-004 / PAY-008).
- ❌ Llamar refund por API en OXXO/SPEI/Pix (PAY-006) — payout manual con humano.
- ❌ Verificar la firma con la API key (`createHmac(MP_ACCESS_TOKEN)`, PAY-007) o compararla con `===` (PAY-005).
- ❌ Editar `vendor/pagokit/**` a mano — se re-sincroniza con `scripts/sync-pagokit-catalog.sh` (meta-repo) y se re-veta al subir de tag.
- ❌ Skipear `.trim()` en webhook secrets. Bug silencioso conocido.
- ❌ Skipear handoff a el-guardian pre-deploy.
- ❌ Editar `brand/**` (add-ui-kit), `.claude/memory/**` (R5 — el-evaluador), `src/shared/components/ui/**` (impeccable), `src/lib/{supabase,insforge}/auth*` (add-login).

## Tool filter

Read · Grep · Glob · Bash (`npx tsc --noEmit` para L1, `supabase db lint` o `psql -d <db> -f migration.sql --single-transaction --variable=ON_ERROR_STOP=1` para SQL validation, o `supabase migration check` cuando aplique) · Write/Edit en `src/app/(billing)/**`, `src/app/api/webhooks/{stripe,polar,mercadopago}/**`, `src/app/api/{stripe,polar,mercadopago}/**`, `src/lib/{stripe,polar,mercadopago}/**`, `src/actions/{stripe,polar,mercadopago}.ts`, `src/types/billing.ts`, `supabase/migrations/{0002_subscriptions,0003_payments_ledger}.sql`, `tests/payments/**`, `payment-page-scripts.json`, `.env.local` (append-only). Bash adicional: `node vendor/pagokit/scripts/advise.js` (ranking) y `node vendor/pagokit/scripts/sign-event.js` (eventos firmados para Layer 3) — solo lectura del catálogo, sin red.

NO Edit en `brand/**` (add-ui-kit). NO Edit en `.claude/memory/**` (el-evaluador). NO Edit en `src/shared/components/ui/**` (impeccable). NO Edit en `src/lib/{supabase,insforge}/{client,server,proxy}.ts` ni `src/app/(auth)/**` (add-login).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | brand.json + voice.json reads |
| Constraint source | `[memory:CONSTRAINTS.md#R10]` | header de /pricing /billing /checkout pages |
| Constraint source | `[memory:CONSTRAINTS.md#R14]` | refundCharge / cancelSubscription / transferFunds |
| Constraint source | `[memory:CONSTRAINTS.md#R13]` | header de prompts que generan código contra Stripe/Polar |
| Lessons | `[memory:lessons#L-001]` | subscriptions SQL preamble (RLS) |
| Lessons | `[memory:lessons#L-002]` | webhook handlers header (signature + metadata as data) |
| Lessons | `[memory:lessons#L-003]` | actions/{stripe,polar}.ts validators header |
| Decisions | `[memory:decisions#D-009]` | decision-tree.md rationale (default + override pattern) |
| Decisions | `[memory:decisions#D-010]` · `[memory:decisions#D-038]` | Stripe default + Polar MoR (D-010) · ranking determinista + Mode C + ledger + gate PAY-* (D-038, supersede parcial de D-010) |
| Reference | `[memory:references#R-012]` | catálogo/motores de PagoKit (vendor) — toda recomendación y todo check PAY-* |
| Threat-db | `PAY-001..008` (`la-herreria/references/threat-db.yaml`) | headers de webhook/checkout/actions donde aplica (p. ej. PAY-006 en refund) |
| External docs | `[docs:stripe]` `[docs:stripe-node]` `[docs:stripe@v18]` `[docs:polar]` `[docs:polar-sdk@v0.x]` `[docs:mercadopago@v2]` `[docs:nextjs]` | Cualquier código que use API |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `find-docs` | dependency. Pre-gen R13 invoca en cada modo (Stripe/Polar/Mercado Pago/Next.js raw-body). |
| `vendor/pagokit` | datos + motores (MIT). `advise.js` decide el modo; `sign-event.js` alimenta la Layer 3; `currencies.json` genera `references/currencies.md`. Se sincroniza desde el meta-repo (`scripts/sync-pagokit-catalog.sh`), nunca a mano. |
| `baas` | upstream. baas decision determina dónde vive subscriptions table (Supabase SQL vs Insforge schema). |
| `add-login` | upstream **mandatory**. Sin profiles + auth, halt — payments depende de user_id FK. |
| `add-ui-kit` | upstream. Sin brand.json + voice.json válidos, halt. |
| `impeccable` | upstream. /pricing /billing importan Card/Button/Badge de su output. Sin ellos, halt. |
| `el-migrador` | downstream Supabase only. Aplica 0002_subscriptions.sql (handoff vía supabase migration). |
| `el-guardian` | mandatory pre-deploy. Audita secret isolation, signature verification, R14 gates, RLS, rate limiting + lente **pagos** (`tests/payments-gate.sh <dir>` = PAY-001..008 del threat-db). También en brownfield (`migration-wizard` → integración de pagos existente). |
| `el-evaluador` | post-gen valida L1 (tsc + sql syntax) + L2 (dry-run Stripe/Polar/Mercado Pago + payments-gate) + L3 (Brand Score per page + security pre-handoff 10 gates × 3 proveedores + `webhook-*.test.mjs` con eventos firmados). |
| `add-emails` | downstream. Invoice receipts + `PaymentFailed` (dunning, `references/subscription-lifecycle.md`) consumen Resend si add-emails corrió. Sin add-emails, fallback a los receipts del proveedor (Stripe/Polar; MP envía su comprobante al payer). |
| `el-crisol` (`/precio`) | downstream. La comisión real del ranking (`--amount/--currency`) es input citable del paso 4 (unit economics con fees reales, G8). |
| `la-herreria` (Tech Spec) | upstream. `payments.provider` + `payments.onboarding_lead_time` (G7) salen del ranking; si el lead time excede el hito → bloqueador en `.plan/`. |

## Output handoff

Tras pasar L1+L2+L3 + security pre-handoff:

```markdown
## add-payments handoff

**Mode:** STRIPE | POLAR | MERCADOPAGO | ADVISE | PAUSE
**Ranking:** `recommendation.id` · `integration_level` · `last_verified_at` (disclaimer) · fee típica: <X MXN sobre <Y> · lead time de llaves: <N> días (→ Tech Spec / .plan/)
**Files generated:** N
**Output paths (Stripe mode):**
- src/lib/stripe/{client,server}.ts
- src/app/(billing)/{pricing,checkout,success,billing}/page.tsx
- src/app/api/webhooks/stripe/route.ts
- src/app/api/stripe/{checkout,portal,refund-request}/route.ts
- src/actions/stripe.ts
- src/types/billing.ts
- supabase/migrations/0002_subscriptions.sql

**Brand Score per page:**
| Page | tokens(25) | components(20) | accessibility(30) | anti-slop(15) | voice(10) | TOTAL |
|------|-----------|----------------|-------------------|---------------|-----------|-------|
| pricing                       | ... | ... | ... | ... | ... | ≥75 |
| checkout                      | ... | ... | ... | ... | ... | ≥75 |
| success                       | ... | ... | ... | ... | ... | ≥75 |
| billing (customer portal entry) | ... | ... | ... | ... | ... | ≥75 |

**Security pre-handoff (8-check):**
- ✅ STRIPE_SECRET_KEY NOT exposed in client (grep returned 0 hits in app/(*))
- ✅ STRIPE_WEBHOOK_SECRET .trim() applied
- ✅ Webhook handler verifies signature BEFORE any DB op
- ✅ refundCharge / cancelSubscription / transferFunds have NO automatic execute()
- ✅ Server actions validate ownership (auth.uid() === sub.user_id)
- ✅ RLS enabled on subscriptions + 2 policies (SELECT only, NO INSERT/UPDATE direct)
- ✅ Rate limiting documented on /api/checkout (5 req/user/hour)
- ✅ Idempotency check on subscription.active (current_period_end compared)

**Citations:**
- [memory:references#R-005]
- [memory:CONSTRAINTS.md#R10] (Brand DNA)
- [memory:CONSTRAINTS.md#R14] (destructive tools — refund/cancel/transfer)
- [memory:CONSTRAINTS.md#R13] (external docs)
- [memory:lessons#L-001] (RLS subscriptions)
- [memory:lessons#L-002] (webhook signature + metadata as data)
- [memory:lessons#L-003] (whitelist validators)
- [memory:decisions#D-009] (default + override pattern)
- [docs:stripe] · [docs:stripe-node] · [docs:nextjs] (Mode A)
- [docs:polar] · [docs:polar-sdk] · [docs:nextjs] (Mode B)

**Mandatory next step:** invocar `el-guardian` con prompts/handoff-el-guardian.md como checklist. Deploy bloqueado hasta PASS.

**Frictions encountered (if any):**
- <listar campos del brand.json o voice.json que fueron ambiguos>
- <inconsistencias con add-login profiles shape si surgen>
- → Promote to errors.md as E-NNN if recurring
```

---

*"El checkout es la última promesa que hace tu marca antes de cobrar. Cumplila."*
