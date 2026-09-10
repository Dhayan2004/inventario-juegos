---
description: "Pagos drop-in con ranking determinista (Stripe default / Polar MoR / Mercado Pago LATAM): checkout + portal + webhooks firmados + ledger + subscriptions; gate PAY-001..008 y Layer 3 con eventos forjados/replay."
---

# /add-payments

Lee y ejecuta `.claude/skills/add-payments/SKILL.md`.

Templates pre-armados — SDK clients server+client, webhook handler con signature verification, `/pricing` + `/checkout` + `/success` + `/billing` pages, customer portal entry, server actions con whitelist L-003 + R14 gates en `refund` / `cancelSubscription` / `transferFunds`, migration `0002_subscriptions.sql` con RLS L-001 enforced.

**Pre-requisitos:**
- `add-login` completado (necesita profiles).
- Brand DNA presente.
- `impeccable` components base.

**el-guardian handoff mandatory pre-deploy** con secret isolation + signature verification + rate limiting verificados.

**Tip:** si querés pagos + emails + audit en un flujo, usar `/add-monetization`.
