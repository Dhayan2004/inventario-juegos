# Chain rationale — add-monetization

> Por qué este orden, qué produce cada step, cómo resuelve E-006 paralelo a init-saas, y la distinción crítica D-020 (PAUSE-interno-delegado ≠ PAUSE-wizard).

## Cadena canónica

```
add-payments ──→ add-emails ──→ web-quality
   (paso 1)       (paso 2)       (paso 3)
```

## Qué produce cada paso

### Paso 1 — add-payments (Mode A Stripe default o Mode B Polar)

**Inputs:** add-login completado + Brand DNA + impeccable components base.

**Outputs:**
- `lib/stripe/{client,server}.ts` (Mode A) o `lib/polar/...` (Mode B)
- `app/api/webhooks/{stripe|polar}/route.ts` con signature verification
- `app/(marketing)/pricing/page.tsx` (consume voice.cta_examples)
- `app/(app)/checkout/page.tsx` y `success/page.tsx`
- `app/(app)/billing/page.tsx` (customer portal entry)
- `actions/payments.ts` (Zod whitelist L-003 + R14 destructive gates)
- `0002_subscriptions.sql` (RLS L-001 enforced, FK profiles)

**Tiempo típico:** ~30min Mode A (Stripe), similar Mode B.

**PAUSE interno (D-010):** si baas decision tree dicta Polar y usuario indie sin empresa MoR registrada → halt-blocked esperando que usuario constituya empresa. Este PAUSE es **interno al sub-skill**, NO escala al wizard (D-020).

### Paso 2 — add-emails (Mode A Resend default, Mode B SendGrid, Mode C PAUSE on-prem SMTP)

**Inputs:** add-login completado + Brand DNA + impeccable components base.

**Outputs:**
- `lib/{resend|sendgrid}/{client,server}.ts` con SDK + helpers
- 7 React Email templates canónicos en `emails/`:
  - Welcome.tsx, MagicLink.tsx, PasswordReset.tsx, InvoiceReceipt.tsx, PaymentFailed.tsx, SubscriptionCanceled.tsx, EmailChangedConfirmation.tsx
- `app/api/email/send/route.ts` con rate-limit + auth gate + RFC 8058 headers
- `app/api/email/unsubscribe/route.ts` (GET+POST + JWT)
- `app/api/webhooks/email/route.ts` (suppression: bounce/complaint events)
- `actions/emails.ts` (R14 destructive: bulkUnsubscribe + deleteSuppressionEntry)
- `0003_email_subscriptions.sql` (RLS L-001 enforced)

**Tiempo típico:** ~20min Mode A (Resend), similar Mode B.

**PAUSE interno (D-011):** si compliance signals dictan on-prem SMTP (banking + data sovereignty BCRA/AEPD/Banxico, healthcare HIPAA on-prem mandatory, government air-gapped) → halt-blocked esperando que usuario constituya SMTP self-hosted (Postfix/Mailcow/Listmonk/Haraka). NO escala al wizard.

### Paso 3 — web-quality (binary live default / static fallback)

**Inputs:** proyecto target con código de payments + emails ya generado.

**Outputs:**
- `.claude/reports/web-audit-{nombre}-{timestamp}.md` con structured report:
  - Lighthouse scores (live mode) o issues localizados a line numbers (static mode)
  - 4 categorías × 4 niveles severity
  - Pre-deploy gate: PASS / NEEDS_FIX

**Tiempo típico:** ~10min live (con URL/server), ~5min static.

**Sin PAUSE genuino:** D-015 binary. Auto-degrada graceful live → static si no hay URL/server.

## Por qué este orden (no permutable)

| Permutación posible | Por qué falla |
|---------------------|---------------|
| add-emails → add-payments → web-quality | add-payments es independiente de add-emails (no consume), pero el orden natural en monetización SaaS es payments-first (porque emails de pago, recibos, etc. dependen de tener flujo de pago). Permutación posible pero anti-pattern UX. |
| web-quality primero (audit pre-implementación) | NO útil — audit sin código que auditar es vacuo. web-quality cierra como pre-deploy gate, no como inicio. |
| web-quality entre payments y emails | Posible pero subóptimo. web-quality auditan stack completo de monetización; correr el audit a mitad pierde la visión integrada. |
| add-payments → add-emails → web-quality | ✅ Orden canónico (default). |

El orden lo dicta:
1. **Dependency lógica:** payments es feature core, emails complementa, web-quality cierra.
2. **Dependency funcional:** algunos templates de email (InvoiceReceipt, PaymentFailed) referencian eventos de payments — útil tener payments listo primero.
3. **UX de validación:** audit final con stack completo es más útil que audits parciales.

## Cómo resuelve E-006 (paralelo a init-saas)

E-006 documenta el chicken-egg de cadenas de skills. init-saas resolvió la cadena auth/UI:

```
add-ui-kit → impeccable → add-login   (cadena auth/UI, init-saas wizard)
```

add-monetization resuelve la cadena monetización:

```
add-payments → add-emails → web-quality   (cadena monetización, add-monetization wizard)
```

**Patrón cross-wizards:** ambos siguen el mismo shape (sequential pipeline + resume-aware) y resuelven E-006 para sus respectivos dominios.

**Combinables:** un proyecto SaaS típico corre init-saas → add-monetization secuencial. Ambos resume-aware, así que invocar el segundo después del primero es seguro.

## Distinción CRÍTICA — D-020: PAUSE-interno-delegado ≠ PAUSE-wizard

**Esta es la contribución analítica más importante de D-020.**

### El razonamiento posible (incorrecto sin D-020)

> "add-payments es trinary (D-010 — Stripe / Polar / PAUSE empresa MoR).
> add-monetization compone add-payments.
> Por lo tanto, add-monetization es trinary (al wizard level)."

Eso sería force-fit incorrecto. Aplicar L-004 al wizard requiere preguntar:

> ¿Hay degenerate case que requiera upstream user action ESPECÍFICA DEL SELECTOR WIZARD?

El selector wizard de add-monetization es: **full chain vs partial (payments-only)**.

| Degenerate case del selector wizard | ¿Upstream user action requerida del selector? |
|--------------------------------------|----------------------------------------------|
| Sin add-login (PREFLIGHT) | Sí — pero es PREFLIGHT halt, no degenerate del selector |
| Sin Brand DNA (PREFLIGHT) | Sí — PREFLIGHT halt |
| add-payments PAUSE interno | NO — usuario resuelve **dentro de add-payments** (constituyendo empresa o cambiando provider). Cuando resuelve, wizard continúa normal. **NO upstream user action específica del selector wizard.** |

El PAUSE de add-payments es **interno al sub-skill**. El usuario:
1. Lo resuelve dentro del scope de add-payments (decisión Polar vs Stripe vs constituir empresa).
2. NO afecta la elección "full chain vs partial" del selector wizard.
3. Ambos modos del selector wizard siguen siempre disponibles.

**Por lo tanto, add-monetization es BINARY al wizard level.** D-020 codifica esta distinción.

### Implicaciones cross-skill

D-020 establece el principio cross-wizards:

> **PAUSE de un sub-skill NO trinariza el wizard que lo compone, siempre que el PAUSE sea interno (resoluble dentro del scope del sub-skill) y no afecte el selector wizard.**

Aplicable a futuros wizards:
- Wizards futuros que compongan sub-skills con PAUSE genuino (D-010 add-payments, D-011 add-emails, otros futuros) deben aplicar el mismo razonamiento.
- Si emerge un wizard donde el PAUSE de un sub-skill SÍ afecta el selector wizard (ej: el PAUSE bloquea no solo ese paso sino la posibilidad de invocar el wizard completo) → aplicar L-004 estrictamente y considerar trinary al wizard level. Pero ese caso es **distinto** al PAUSE-interno-delegado.

D-020 es el primer ADR cross-skill que codifica esta distinción para wizards. Aplicable universalmente.

## Comparación con init-saas (shape-par paralelo)

| Aspecto | init-saas | add-monetization |
|---------|-----------|-------------------|
| Domain | bootstrap auth/UI | monetización |
| Pasos | 3 (ui-kit → components → auth) | 3 (payments → emails → audit) |
| Sub-skills con PAUSE genuino | NONE (los 3 son binary internamente) | **2** (add-payments D-010 + add-emails D-011) |
| Wizard shape | binary (FRESH / EXISTING) | binary (full chain / partial) |
| PAUSE-interno-delegado emerges? | NO (sub-skills son binary) | **SÍ** — D-020 distinction relevant aquí |
| ADR shape | D-019 binary | D-020 binary + PAUSE-interno-delegado distinction |
| L-004 aplica? | SÍ (binary) | SÍ (binary) — distinción explícita necesaria |

**Por qué add-monetization es el wizard donde D-020 distinction emerge:**

init-saas compone 3 sub-skills binary internamente (add-ui-kit binary FRESH/REDESIGN, impeccable binary KNOWN/UNKNOWN/BATCH no-PAUSE, add-login binary D-009). Ningún sub-skill tiene PAUSE genuino que pudiera tentarse a escalar al wizard.

add-monetization compone 2 sub-skills con PAUSE genuino (D-010 + D-011). Aquí emerge la posibilidad de force-fit trinary al wizard. D-020 establece el principio: **PAUSE-interno-delegado NO trinariza el wizard.**

## Cross-skill applicability — patrón "wizard con sub-skills PAUSE-aware"

D-020 establece el patrón canónico para wizards que componen sub-skills con PAUSE genuino:

1. Wizard mantiene su propio selector (binary o trinary según L-004 al wizard level).
2. Sub-skills PAUSE genuino → wizard reporta PAUSE-interno-delegado al usuario sin escalar.
3. Resume-aware: wizard re-invocado retoma post-resolución del PAUSE interno.
4. ADR del wizard documenta la distinción explícitamente.

Aplicable a futuros wizards:
- **add-mobile-stack** (Phase 5+): si compone add-mobile + push setup + manifest, mismo patrón.
- **enterprise-stack** (Phase 6+): wizards mayores que compongan multi-domain (auth + payments + admin + audit).

## Citation grammar

- [memory:errors#E-006] — gap UX cadenas de skills (add-monetization resuelve para monetización).
- [memory:lessons#L-004] — test diagnóstico al wizard level.
- [memory:decisions#D-009] — add-login binary (no PAUSE — paso de auth en init-saas).
- [memory:decisions#D-010] — **add-payments trinary con PAUSE interno** (relevante para add-monetization paso 1).
- [memory:decisions#D-011] — **add-emails trinary con PAUSE interno** (relevante para add-monetization paso 2).
- [memory:decisions#D-014] — el-crisol boundary case (shape-par estructural).
- [memory:decisions#D-015] — web-quality binary (relevante para add-monetization paso 3).
- [memory:decisions#D-019] — init-saas binary (paralelo, mismo shape wizard).
- [memory:decisions#D-020] — add-monetization binary + **PAUSE-interno-delegado ≠ PAUSE-wizard** (distinción cross-wizards).
- [memory:CONSTRAINTS.md#R4] — wizard MISMA NO invoca skills directo.
- [memory:CONSTRAINTS.md#R10] — Brand DNA contract via sub-skills.

## Anti-patterns

- ❌ Permutar el orden payments → emails → audit (rompe lógica de dependencias).
- ❌ Saltar Fase 0 detección (waste si pasos completos).
- ❌ **Escalar PAUSE-interno-delegado de sub-skill al nivel wizard** (D-020 violation crítica).
- ❌ Force-fit trinary porque add-payments o add-emails son trinary (D-020 distinción).
- ❌ Re-ejecutar audit web-quality si reporte fresco existe (<7 días).
- ❌ Force live mode en web-quality si no hay URL/server (auto-degrada).
- ❌ Bypass del PREFLIGHT de sub-skills.
