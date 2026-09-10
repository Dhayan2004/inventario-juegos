# Chain rationale — enterprise-stack

> Por qué este orden de wizards, qué produce cada uno, qué dependencias tienen, y por qué el patrón de "wizard de wizards" funciona.

## Pipeline canónico

```
init-saas ──→ add-monetization ──→ add-mobile-stack
   (paso 1)        (paso 2)              (paso 3)
```

## Qué produce cada wizard

### Wizard 1 — init-saas (D-019)

**Inputs:** AGENTS.md + Next.js + (opcional) preset elegido + (opcional) baas decision documentada.

**Outputs (3 sub-pasos: ui-kit + components + auth):**
- `brand/brand.json`, `voice.json`, `brand.css` (add-ui-kit Discovery FRESH).
- `brand/component_rules.json` + 11 components canónicos en `src/shared/components/ui/` (impeccable Mode C BATCH).
- `lib/supabase/{client,server,proxy}.ts` (Mode A) o `lib/insforge/...` (Mode B) (add-login).
- `src/middleware.ts` (Next.js 16 forward).
- 4 auth pages: `app/(auth)/{sign-in,sign-up,forgot-password,update-password}/page.tsx`.
- Auth routes: `callback/route.ts` + `sign-out/route.ts` + `delete-account/route.ts` (R14 typed confirmation).
- `actions/auth.ts` (Zod whitelist L-003).
- `hooks/useAuth.ts`.
- `0001_profiles.sql` (RLS L-001).

**Tiempo típico:** ~75min total (30 + 25 + 20).

**Por qué primero:** Brand DNA + components + auth son fundación de cualquier feature posterior. Sin esto, add-monetization halts (consumen impeccable Card+Button + voice.json), add-mobile-stack halts (manifest.theme_color depende de brand.json + push_subscriptions tied to user_id de auth).

### Wizard 2 — add-monetization (D-020)

**Inputs:** init-saas DONE (brand.json + auth/ + components).

**Outputs (3 sub-pasos: payments + emails + audit):**
- `lib/stripe/{client,server}.ts` (default D-010) o `lib/polar/...` (override) — add-payments.
- `/api/webhooks/{stripe,polar}/route.ts` con signature verification.
- `/pricing` + `/checkout` + `/success` + `/billing` pages.
- `actions/payments.ts` (Zod L-003 + R14 strict en `refund` / `cancelSubscription` / `transferFunds`).
- `0002_subscriptions.sql` (RLS L-001).
- `lib/resend/{client,server}.ts` (default D-011) o `lib/sendgrid/...` (override) — add-emails.
- 7 React Email templates en `src/features/emails/templates/`.
- `/api/email/send` + `/api/email/unsubscribe` + suppression webhook.
- `actions/emails.ts` (R14 strict en `bulkUnsubscribe` / `deleteSuppressionEntry`).
- `0003_email_subscriptions.sql` (RLS L-001).
- (Opcional) `.claude/reports/web-quality-{timestamp}.md` — auditoría Lighthouse + Core Web Vitals + WCAG + SEO + Best Practices.

**Tiempo típico:** ~75min (30 + 25 + 20).

**Por qué después de init-saas:** add-payments y add-emails consumen impeccable Card+Button + voice.json + auth profiles (referencia FK).

**Por qué antes de add-mobile-stack:** add-mobile-stack es independiente de add-monetization (no se necesita pagos para PWA). Si CUSTOM mode skipea add-monetization, add-mobile-stack sigue funcionando.

### Wizard 3 — add-mobile-stack (D-021)

**Inputs:** init-saas DONE.

**Outputs (4 sub-pasos: ui-kit + components + auth + mobile, los 3 primeros ya están si init-saas DONE):**
- Si init-saas NO DONE: ejecuta los 4 sub-pasos completos (~100min).
- Si init-saas DONE (más común en enterprise-stack): ejecuta solo el 4to sub-paso (mobile, ~25min):
  - `public/manifest.json` — theme_color + icons desde brand.json.
  - `public/sw.js` — service worker SIN fetch handler (iOS Safari quirk).
  - `lib/push/{client,server}.ts` con VAPID.
  - `/api/push/{subscribe,unsubscribe,send}/route.ts` (R14 strict en `sendBroadcast` / `revokeAllSubscriptions`).
  - `src/features/pwa/components/PushPermissionPrompt.tsx` + `InstallPromptUI.tsx`.
  - `src/features/pwa/hooks/usePushSubscription.ts`.
  - `src/features/pwa/actions/notifications.ts` (Zod L-003 whitelist).
  - `0004_push_subscriptions.sql` (RLS L-001 — tied to user_id).

**Tiempo típico:** ~25min en enterprise-stack mode (init-saas ya DONE).

**Por qué último:** add-mobile-stack es superconjunto de init-saas + 1 paso extra (mobile). Es importante que vaya después de init-saas (o que cubra init-saas si CUSTOM mode skipea Wizard 1 — en cuyo caso add-mobile-stack ejecuta los 4 sub-pasos completos via su propio resume-aware).

## Por qué este orden (con CUSTOM override permitido)

| Permutación | Resultado |
|-------------|-----------|
| init-saas → add-monetization → add-mobile-stack | ✅ FULL default. Orden óptimo. |
| init-saas → add-mobile-stack → add-monetization | ✅ Válido. add-mobile-stack y add-monetization son independientes entre sí. CUSTOM mode permite. |
| add-mobile-stack → add-monetization | ✅ CUSTOM skip init-saas — add-mobile-stack cubre init-saas (superconjunto). add-monetization después porque depende de auth. |
| add-monetization → init-saas | ❌ FAIL — add-monetization PREFLIGHT halt: "auth missing" (necesita init-saas DONE). |
| add-monetization → add-mobile-stack | ❌ FAIL — sin init-saas, ambos halts. |

**FULL mode (default):** orden recomendado.

**CUSTOM mode:** usuario puede skipear o reordenar wizards independientes (add-monetization y add-mobile-stack), siempre que init-saas (o equivalent via add-mobile-stack) corra primero.

## Cómo resuelve el chicken-egg de enterprise bootstrap

Antes de enterprise-stack:
- Usuario quiere setup completo SaaS + Mobile + Monetization.
- Tiene que invocar init-saas → add-monetization → add-mobile-stack manualmente, en orden, sabiendo las dependencias.
- 3 invocaciones manuales con confirmation explícita entre cada una.
- Si interrumpe, tiene que recordar dónde quedó y re-invocar el wizard correcto.

Con enterprise-stack:
- Usuario corre `/enterprise-stack` → wizard detecta state → ejecuta los 3 wizards en orden con confirmation explícita → handoff final con stack completo.
- Una invocación. Resume-aware idempotente.
- CUSTOM override disponible para flexibilidad (skip wizards específicos).

## Comparación con los 3 wizards hijos y el-crisol

| Skill | Nivel | Invoca | Output |
|-------|-------|--------|--------|
| `init-saas` | Wizard | 3 skills (add-ui-kit, impeccable, add-login) | Brand DNA + components + auth |
| `add-monetization` | Wizard | 3 skills (add-payments, add-emails, web-quality) | Pagos + emails + audit |
| `add-mobile-stack` | Wizard | 4 skills (add-ui-kit, impeccable, add-login, add-mobile) | Brand DNA + components + auth + PWA |
| `enterprise-stack` | Meta-Wizard (D-022) | 3 wizards | Stack enterprise completo |
| `el-crisol` | Pipeline (D-014 boundary) | 7 sub-prompts | Strategy report + dashboard |

**Patrón cross-wizards (post-D-022):**
1. Resume-aware state detection (D-014 boundary case shape — heredado).
2. Binary mode FRESH/EXISTING o FULL/CUSTOM (L-004 binary, NO PAUSE genuino del selector).
3. PAUSE-interno-delegado de sub-skills/wizards NO escala (D-020 doctrine).
4. R4/R5/R6 enforcement con sub-agents.
5. Citation grammar: cite el ADR del wizard + ADRs heredados (D-019 / D-020 / D-021 / D-022).

## Cross-skill applicability

El patrón de "wizard de wizards" que codifica enterprise-stack es aplicable a cualquier composición de wizards donde:
- N wizards tienen dependencias mayormente independientes (con un punto base común — init-saas).
- Cada wizard tiene PREFLIGHT halt si dependencia falta.
- El patrón se beneficia de meta-orquestación (1 invocación → N wizards en orden).
- Resume-aware aplica a 2 niveles: el meta-wizard y los wizards hijos.

Wizards futuros que apliquen este patrón heredan D-022 + D-019 + D-020 + D-021 doctrine.

## Citation

[memory:decisions#D-022] (binary shape wizard de wizards), [memory:decisions#D-019] (init-saas patrón heredado), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine), [memory:decisions#D-021] (add-mobile-stack patrón heredado), [memory:decisions#D-014] (boundary case shape — pipeline resume-aware), [memory:decisions#D-009] (init-saas → add-login Supabase default), [memory:decisions#D-010] (add-payments PAUSE on-prem trinary), [memory:decisions#D-011] (add-emails PAUSE on-prem trinary), [memory:decisions#D-012] (add-mobile binary interno PWA/Native), [memory:lessons#L-004] (binary test informativo), [memory:CONSTRAINTS.md#R4] (orchestrator thin), [memory:CONSTRAINTS.md#R5] (workers no memory), [memory:CONSTRAINTS.md#R6] (skills.md registry validation pre-dispatch).
