# Examples — Two End-to-End Scenarios

> Estos ejemplos muestran el ciclo completo: decision tree → mode selection → setup → first cobro. Sirven como dogfood reference + onboarding rápido.

## Example 1 — SaaS B2B Mexicano (STRIPE)

### Operador

- Empresa: Forja MX SAS (registrada en CDMX, RFC con persona moral)
- Producto: SaaS de automatización de cuentas por cobrar para PYMEs LATAM
- Audiencia: México (60%), Colombia (25%), Argentina (15%)
- Setup speed: NO crítico (ya operando 6 meses, va a migrar de Lemon Squeezy)
- Features avanzados: Stripe Tax (CDMX VAT), Customer Portal robusto, multi-tier (Hobby/Pro/Team)

### Decision tree path

```
P1: Empresa registrada? SÍ → P2
P2: Necesita Stripe Tax / Connect / Issuing? SÍ (Stripe Tax para VAT MX)
   → STRIPE (default fuerte)
```

Resultado: **STRIPE** (1 hop, no PAUSE).

### Tech Spec sec "Payments Decision"

```markdown
## Payments Decision

**Provider:** stripe
**Rationale:**
- Operador: empresa registrada (Forja MX SAS, RFC persona moral)
- Producto: multi-tier (Hobby $0 / Pro $29 USD / Team $99 USD)
- Audiencia: LATAM (MX/CO/AR)
- Setup speed: no prioritario
- Features Stripe-específicos requeridos: Stripe Tax (VAT MX), Customer Portal

**Decision tree path:** P1 → P2 (Stripe Tax requirement)
**Source:** add-payments/prompts/decision-tree.md
**Cita:** [memory:decisions#D-009]
**Assumed default:** false
```

### add-payments invocación

```bash
/add-payments
# Detecta payments.provider = stripe → Mode A
# PREFLIGHT 8 gates → all PASS (add-login + add-ui-kit + impeccable presentes)
# find-docs invocado: stripe-node@v18 + stripe + nextjs
# Substituye 13 archivos en Mode A
# Brand Score per page:
#   /pricing: 87 (target ≥85 met)
#   /checkout: 92
#   /success: 84
#   /billing: 89
# Security pre-handoff 8-check: PASS
# Handoff a el-guardian: PASS (0 critical, 0 high)
# Manual gates flagged:
#   - Webhook endpoint to configure in Stripe Dashboard
#   - Stripe Tax to enable (Tax > Settings > Add VAT MX)
#   - Customer Portal config
```

### Primer cobro

```
1. Usuario crea cuenta (add-login flow)
2. Click "Pro" en /pricing → POST /api/stripe/checkout
3. Stripe Checkout Hosted (con MX VAT calculado automático)
4. Test card 4242 → success_url /success?session_id=cs_test_XXX
5. /success polling profile.has_access = true
6. Webhook customer.subscription.created → upsert subscriptions row
7. Webhook customer.subscription.updated con status='active'
   → grant has_access = true
8. Usuario tiene acceso al producto
```

## Example 2 — Indie Hacker Argentino (POLAR)

### Operador

- Operador: Carlos D. (persona física, sin empresa registrada)
- Producto: tool digital simple — "Generador de PDFs con AI" — subscription única $19/mo
- Audiencia: global (US 40%, MX 20%, AR 15%, ES 10%, BR 8%, otros 7%)
- Setup speed: prioritario (lanza en 1 semana)
- Features avanzados: ninguno — quiere cobrar y nada más

### Decision tree path

```
P1: Empresa registrada? NO → P5
P5: Indie hacker / sin empresa? SÍ → P6
P6: Audiencia global con tax complejo? SÍ → POLAR (MoR)
```

Resultado: **POLAR** (3 hops, no PAUSE).

### Tech Spec sec "Payments Decision"

```markdown
## Payments Decision

**Provider:** polar
**Rationale:**
- Operador: persona física sin empresa (no piensa constituir antes de validar)
- Producto: simple — single subscription tier $19/mo
- Audiencia: global (>5 países, tax handling complejo)
- Setup speed: prioritario (lanza en 1 semana)
- Features Stripe-específicos requeridos: none

**Decision tree path:** P1 → P5 → P6 (audiencia global + sin empresa)
**Source:** add-payments/prompts/decision-tree.md
**Cita:** [memory:decisions#D-009]
**Assumed default:** false
**MoR rationale:** Polar handles VAT/GST/sales tax + entity legal — Carlos
recibe net amount sin tax filing burden cross-jurisdicción.
```

### add-payments invocación

```bash
/add-payments
# Detecta payments.provider = polar → Mode B
# PREFLIGHT 8 gates → all PASS
# find-docs invocado: polar-sdk@v0.x + nextjs
# Substituye 13 archivos en Mode B
# Brand Score per page:
#   /pricing: 81 (single tier — más simple que Example 1)
#   /checkout: 86
#   /success: 88
#   /billing: 83 (con nota de redirect a polar.sh)
# Security pre-handoff 8-check: PASS
# Handoff a el-guardian: PASS (0 critical, 0 high)
# Manual gates:
#   - Webhook endpoint en Polar dashboard
#   - Sandbox test antes de production
```

### Primer cobro

```
1. Usuario crea cuenta (add-login)
2. Click "Suscribirse" en /pricing → POST /api/polar/checkout
3. Polar Checkout (con tax calculado por MoR según ubicación user)
4. Test card 4242 → success_url /success?checkout_id=co_XXX
5. /success polling profile.has_access = true
6. Webhook checkout.updated (status=succeeded) → link checkout → user
7. Webhook subscription.active → grant has_access = true
   (Polar: event explícito vs Stripe que usa subscription.updated)
8. Usuario tiene acceso al producto
```

## Diferencias visibles entre los 2 examples

| Aspecto | Example 1 (Stripe MX) | Example 2 (Polar AR indie) |
|---------|----------------------|----------------------------|
| Tech Spec required? | Sí (Tax requirements documentados) | Recomendado (audiencia global flag) |
| Tier count en /pricing | 3 (Hobby + Pro + Team) | 1 (single sub) |
| Tax handling | Stripe Tax (auto VAT MX) | Polar MoR (auto tax global) |
| Tiempo setup típico | ~1.5h (Tax + Portal config) | ~10 min (sandbox to prod) |
| Files generados | 13 (Stripe templates) | 13 (Polar templates) |
| Webhook event grant | `customer.subscription.updated` con `status='active'` | `subscription.active` (event explícito) |
| Customer portal | Stripe-hosted full URL | polar.sh redirect |
| Test card | 4242 4242 4242 4242 | 4242 4242 4242 4242 (Polar wraps Stripe) |
| Brand Score promedio | 88 | 84 |

## PAUSE example (cuando el árbol bloquea)

### Operador hipotético

- Operador: Lucía (persona física, sin empresa)
- Producto: marketplace multi-tenant complex (sellers + buyers + commission split)
- Audiencia: México only

### Decision tree path

```
P1: Empresa registrada? NO → P5
P5: Indie hacker? SÍ → P6
P6: Audiencia global? NO (México only) → P7
P7: Producto simple? NO (marketplace = multi-tier complex)
   → PAUSE
```

Resultado: **PAUSE** — recomendar constituir empresa antes de continuar. Polar no cubre marketplace complex; Stripe sí pero requiere empresa.

### Output esperado

```markdown
## add-payments PAUSE

**Provider:** none yet
**Rationale:** indie hacker + multi-tier complex (marketplace) = combinación
sin path saludable. Polar no maneja Stripe Connect / commission split bien.
Stripe Connect requiere entidad legal verificada.

**Recommendation:**
- Constituir empresa formal en MX (SAS o equivalente — proceso ~1 mes)
- Re-correr decision tree post-incorporación → P1=SÍ → P2 con Stripe Connect
  requirement → STRIPE
- O alternativa: simplificar producto a non-marketplace (single-product
  subscription) → re-correr → POLAR como MoR

**No procede add-payments** hasta resolver entity question.
```

## Citations

- [memory:decisions#D-009] (default + override pattern)
- [memory:CONSTRAINTS.md#R10] (Brand Score per page)
- [memory:CONSTRAINTS.md#R13] (find-docs invocation)
- [memory:CONSTRAINTS.md#R14] (R14 enforcement)
- [memory:lessons#L-001] · [memory:lessons#L-002] · [memory:lessons#L-003]
- [docs:stripe@v18] · [docs:stripe-node] · [docs:polar] · [docs:polar-sdk@v0.x] · [docs:nextjs]
