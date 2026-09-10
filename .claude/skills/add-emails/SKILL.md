---
name: add-emails
description: >
  Emails transaccionales drop-in para proyecto target. 3 outcomes:
  Resend (default por friction reduction + React Email ecosystem) +
  SendGrid (override por enterprise compliance SOC 2/HIPAA + IP
  dedicada + scaling >100K/mes) + PAUSE on-prem (caso degenerado:
  banking/healthcare/government con data sovereignty mandatory).
  Templates pre-armados: SDK clients, 7 React Email components
  canónicos (Welcome / MagicLink / PasswordReset / InvoiceReceipt /
  PaymentFailed / SubscriptionCanceled / EmailChangedConfirmation),
  api routes (send + unsubscribe one-click + suppression webhook),
  server actions con whitelist L-003 + R14 strict en bulk operations
  (bulkUnsubscribe / deleteSuppressionEntry / resendCampaign),
  0003_email_subscriptions.sql con RLS L-001. Templates respetan
  R-005 contexts.transactional_email (single_column_first layout,
  motion: none, fallback fonts ['Arial', 'Helvetica']). Hereda
  D-010 pattern extendido en D-011 (compliance vs ecosystem axis).
tier: optional
requires: AGENTS.md exists, add-login completado (src/lib/{supabase,insforge}/* + 0001_profiles.sql aplicado), Brand DNA contract presente (brand/brand.json + voice.json con cta_examples ≥3), .env.local writable.
fallback: Sin Tech Spec con `emails.provider` documentado → Resend como default (assumed_default flag). Sin add-login → halt + handoff a add-login (necesita profiles.email para recipients). Sin Brand DNA → halt + handoff a add-ui-kit. Decision tree devuelve PAUSE (data sovereignty) → halt + recomendación de SMTP self-hosted antes de re-invocar. impeccable opcional (solo para pricing-style email previews UI; emails NO consumen impeccable componentes directamente — son React Email shape).
dependencies: [find-docs, baas, add-login, add-ui-kit, impeccable]
---

# add-emails

> *"Un email transaccional es la marca hablándole al usuario en silencio. Si la voz se pierde, la confianza también."*
> — Forja R10 + voice.json contract

Skill drop-in. Setea sistema de emails transaccionales completo (templates + send + unsubscribe + suppression handling + RLS) en un proyecto target, en uno de tres outcomes según decision tree: Resend (default), SendGrid (override por compliance) o PAUSE (recomendación de on-prem antes de continuar). Output: ~18 archivos pre-armados (Mode Resend) o ~18 (Mode SendGrid).

## PREFLIGHT halt (8 gates)

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Existe TECH-SPEC-<nombre>.md con sección "Emails Decision"? Si no → fallback: Resend con flag `assumed_default = true` (loggear).
3. ¿Existe src/lib/{supabase|insforge}/server.ts + 0001_profiles.sql aplicado? Si no → halt: "Falta auth. Corré /add-login primero — emails depende de profiles.email."
4. ¿Existe brand/brand.json + voice.json? Si no → halt: "Falta Brand DNA. Corré /add-ui-kit primero. R10 no negociable."
5. ¿brand.json declara `contexts.transactional_email`? Si no → fallback a defaults conservadores (single_column_first, motion: none, fallback fonts ['Arial', 'Helvetica']) + warning a el-evaluador.
6. ¿voice.json declara cta_examples con ≥3 entries totales? Si sí → procedé, mapeando los más cercanos a contexto email. Si genéricos sin orientación email, warning + fallback conservador (`Confirmar email`, `Reset contraseña`, `Ir al panel`, `Cancelar suscripción`).
7. ¿Decision tree devuelve PAUSE (data sovereignty)? Si sí → halt con recomendación de SMTP self-hosted (Postfix, Mailcow, Listmonk) y abort skill — NO force-fit a Resend/SendGrid.
8. ¿Existe .env.local writable? Si no → crear con placeholders.
```

Sin estos 8 gates, add-emails retorna error sin generar código.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide "agregame emails / transaccionales / welcome / password reset" | Coordinator |
| add-login cierra y proyecto necesita reset password personalizado (overrides Supabase Auth built-in emails) | add-login handoff |
| add-payments cierra y proyecto necesita invoice receipts custom | add-payments handoff |
| la-herreria fase 8 detecta email flows en User Stories | la-herreria handoff |

## Decision tree (Resend / SendGrid / PAUSE)

Detalle completo en [`prompts/decision-tree.md`](prompts/decision-tree.md). Resumen:

| Señal | Inclina hacia |
|-------|---------------|
| Indie / startup / SaaS general con volumen <50K/mes | **Resend** |
| Setup speed prioritario (~5 min vs ~30 min SendGrid) | **Resend** |
| React Email ecosystem deseado (templates como componentes) | **Resend** |
| Audiencia LATAM/global sin compliance estricto | **Resend** |
| SOC 2 Type II / HIPAA / GDPR strict requirements documentados | **SendGrid** |
| Volumen >100K/mes con IPs dedicadas necesarias | **SendGrid** |
| Multi-tenant emailing (varios clientes desde una infra) | **SendGrid** |
| Suppression list robusta + dunning workflow | **SendGrid** |
| Banking en jurisdicción con data sovereignty (BCRA Argentina, AEPD UE strict, Banxico MX) | **PAUSE** |
| Government con air-gapped requirements | **PAUSE** |
| Healthcare con HIPAA on-prem mandatory (no BAA cloud-hosted) | **PAUSE** |

**Default cuando ambiguo:** Resend. Cita [memory:decisions#D-010] (pattern reusado) + [memory:decisions#D-011] (compliance/ecosystem axis específico de add-emails). Resend gana por friction reduction + React Email DX. SendGrid gana por compliance + scaling. PAUSE recomienda SMTP self-hosted antes que force-fit.

## 3 outcomes de operación

### MODE A — RESEND (default)

Trigger:
- Tech Spec `emails.provider = resend`, OR
- Sin Tech Spec (fallback default), OR
- Decision tree señales: indie/startup + volumen <50K + setup speed prioritario + React Email DX deseado.

Detalle: `prompts/setup-resend.md`.

### MODE B — SENDGRID (override por compliance)

Trigger:
- Tech Spec `emails.provider = sendgrid`, OR
- Decision tree señales: SOC 2/HIPAA/GDPR strict + volumen >100K + IPs dedicadas + multi-tenant.

Detalle: `prompts/setup-sendgrid.md`.

### MODE C — PAUSE (data sovereignty)

Trigger:
- Decision tree señales: banking sovereign + government air-gapped + healthcare HIPAA on-prem mandatory.

Output: halt con recomendación de stack SMTP self-hosted:
- **Postfix + Dovecot** para SMTP servers tradicional
- **Mailcow** (Postfix + Rspamd + SOGo) para email server completo Docker
- **Listmonk** para newsletters self-hosted
- **Haraka** o **Halon** para SMTP performance enterprise

`prompts/decision-tree.md` documenta la recomendación PAUSE en detalle. NO se generan archivos en este caso.

## Loop de ejecución

```
0. PREFLIGHT halt (8 gates) — gate 7 puede devolver PAUSE
1. Decision tree → mode A / B / C
   ├─ Mode A (Resend)   → templates/resend/**
   ├─ Mode B (SendGrid) → templates/sendgrid/**
   └─ Mode C (PAUSE)    → halt + recomendación

2. Pre-gen find-docs (R13):
   - Resend: resolve-library-id("resend") + ("react-email")
   - SendGrid: resolve-library-id("sendgrid-mail") + ("sendgrid")
   - Common: resolve-library-id("nextjs") "App Router 16 route handlers"

3. Read brand.json + voice.json (R10):
   - tokens.colors → React Email components inline styles
   - voice.cta_examples → CTAs ("Confirmar email", "Reset contraseña")
   - voice.avoid_words → audit en los 7 templates
   - contexts.transactional_email (R-005) → layout + motion + fonts

4. Substituir templates → src/**
   · 7 React Email components (.tsx)
   · /api/email/{send,unsubscribe,suppression-webhook}/route.ts
   · lib/{resend,sendgrid}/{client,server}.ts
   · actions/email.ts (whitelist L-003 + R14 bulk gates)
   · types/email.ts

5. Generar SQL migration:
   · 0003_email_subscriptions.sql con RLS L-001 + 2 policies
   · Suppression list table (server_role write only)
   · JSDoc cita [memory:lessons#L-001]

6. .env.local update:
   · Resend: RESEND_API_KEY (server only) + RESEND_WEBHOOK_SECRET
   · SendGrid: SENDGRID_API_KEY (server only) + SENDGRID_WEBHOOK_SECRET
   · NEXT_PUBLIC_APP_URL (público)
   · EMAIL_FROM_ADDRESS (público OK, dominio verificado en provider)

7. Security pre-handoff scan (8-check):
   · API keys NO en client
   · Webhook secret .trim() aplicado
   · email_subscriptions RLS habilitado
   · bulkUnsubscribe / deleteSuppressionEntry / resendCampaign sin execute()
   · Server actions validan ownership (recipient email coincide con user?)
   · Rate limiting documentado en /api/email/send
   · Unsubscribe one-click compliant (Gmail/Yahoo 2024 mandate)
   · NO imports directos de SDK en client components

8. Output handoff a el-guardian (pre-deploy):
   · Pasar checklist de prompts/handoff-el-guardian.md
   · Bloquear deploy hasta PASS
```

## Reglas operativas

1. **brand.json + voice.json son contrato no-negociable (R10).** Templates React Email importan colors via brand.json.tokens.colors (NO Tailwind hardcoded). CTAs derivan de voice.cta_examples (con fallback conservador si genéricos). avoid_words audit corre sobre los 7 templates.
2. **R-005 contexts.transactional_email enforced.** Layout `single_column_first` (no multi-col que rompe en clients antiguos). Motion: `none` (animations no soportadas en email clients). Fallback fonts `['Arial', 'Helvetica']` (Inter/Geist no rendea en Outlook). Cita `[memory:references#R-005]` sección 8.x contexts.
3. **find-docs antes de cada generación (R13).** React Email v3 cambió shape de `<Tailwind>` component. SendGrid v8 cambió suppression API endpoint. Sin find-docs, runtime falla.
4. **L-001 enforcement en email_subscriptions SQL.** Tabla con `enable row level security` + SELECT policy `auth.uid() = user_id`. NO INSERT/UPDATE direct (server-side via webhook).
5. **L-002 en webhook handlers (suppression).** Resend/SendGrid bounce/complaint webhooks reciben payload externo. Aunque verifican signature, `email`/`reason` fields son user-controlled. Whitelist de bounce reasons + UUID validation antes de query.
6. **L-003 en validators.** `actions/email.ts` whitelist:
   - `to: z.string().email().max(254)`
   - `template_id: z.enum([...known templates])`
   - `locale: z.enum(['es-419', 'es-ES', 'en-US', 'pt-BR'])`
   - `reply_to: z.string().email().optional()`
   NO `z.record(z.any())` en metadata.
7. **R14 strict en bulk operations.** `bulkUnsubscribe`, `deleteSuppressionEntry`, `resendCampaign` NO export `execute()` automático. Cada uno requiere typed-confirmation gate (input "BULK_UNSUBSCRIBE" o "DELETE_SUPPRESSION") + audit log en DB pre-execute. Cita `[memory:CONSTRAINTS.md#R14]`.
8. **API keys isolation.** RESEND_API_KEY / SENDGRID_API_KEY solo en `lib/{resend,sendgrid}/server.ts` y api routes. NUNCA en client. Audit obligatoria pre-handoff.
9. **Webhook secret .trim() obligatorio.** Aplica como en add-payments — bytes invisibles en .env rompen verification silenciosamente.
10. **Unsubscribe one-click compliant.** Gmail/Yahoo 2024 mandate: `List-Unsubscribe-Post: List-Unsubscribe=One-Click` header + GET endpoint que da-de-baja sin confirmation. Cita `[docs:rfc8058]`.
11. **Rate limiting en /api/email/send.** Documentado en JSDoc + comment. Anti-abuse: max 10 emails por user/hour para transactional flows; bulk via separate authenticated admin route.
12. **NO templates con tracking pixel oculto sin disclosure.** Privacy compliance — si el template tracks open rate, el footer lo declara explícitamente. Cita `[docs:gdpr]` cuando jurisdicción aplica.

## Refusals (lo que NUNCA hace)

- ❌ Generar email templates con Tailwind hardcoded (`bg-purple-500`, `bg-gradient-to-r`). Inline styles via brand tokens.
- ❌ Hardcodear copy ignorando voice.json. CTAs siempre desde `voice.cta_examples` (con fallback conservador).
- ❌ Skipear RLS en email_subscriptions SQL. L-001 no negociable.
- ❌ Exportar `bulkUnsubscribe`, `deleteSuppressionEntry`, `resendCampaign` como `tool({ execute })`. R14 binario.
- ❌ Forzar Resend o SendGrid cuando decision tree devuelve PAUSE. Recomendar SMTP self-hosted, no generar.
- ❌ Importar `RESEND_API_KEY` / `SENDGRID_API_KEY` en archivos accesibles desde client.
- ❌ Skipear `.trim()` en webhook secrets.
- ❌ Templates que rompen en Outlook 2007-2019 (multi-col layouts, flexbox sin tables fallback, custom fonts sin fallback). R-005 contexts.transactional_email.
- ❌ Tracking pixel sin disclosure en footer.
- ❌ Skipear handoff a el-guardian pre-deploy.
- ❌ Editar `brand/**`, `.claude/memory/**`, `src/lib/{supabase,insforge}/**` (otros skills' territory).

## Tool filter

Read · Grep · Glob · Bash (`npx tsc --noEmit` para L1, `supabase db lint` para SQL, `npx react-email export` opcional para verificar React Email componentes compilan a HTML válido) · Write/Edit en `src/app/api/email/**`, `src/lib/{resend,sendgrid}/**`, `src/emails/**`, `src/actions/email.ts`, `src/types/email.ts`, `supabase/migrations/0003_email_subscriptions.sql`, `.env.local` (append-only).

NO Edit en `brand/**` (add-ui-kit). NO Edit en `.claude/memory/**` (el-evaluador). NO Edit en `src/lib/{supabase,insforge}/**` ni `src/app/(auth)/**` (add-login). NO Edit en `src/lib/{stripe,polar,mercadopago}/**` (add-payments).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | brand.json + voice.json + contexts.transactional_email |
| Constraint source | `[memory:CONSTRAINTS.md#R10]` | header de email templates |
| Constraint source | `[memory:CONSTRAINTS.md#R14]` | bulkUnsubscribe / deleteSuppressionEntry / resendCampaign |
| Constraint source | `[memory:CONSTRAINTS.md#R13]` | header de prompts que generan código contra Resend/SendGrid |
| Lessons | `[memory:lessons#L-001]` | email_subscriptions SQL preamble |
| Lessons | `[memory:lessons#L-002]` | webhook handlers header (bounce payload as data) |
| Lessons | `[memory:lessons#L-003]` | actions/email.ts validators header |
| Decisions | `[memory:decisions#D-010]` | pattern precedente reusado |
| Decisions | `[memory:decisions#D-011]` | compliance vs ecosystem axis específico |
| External docs | `[docs:resend]` `[docs:react-email]` `[docs:react-email@v3]` `[docs:sendgrid]` `[docs:sendgrid-mail]` `[docs:nextjs]` `[docs:rfc8058]` (one-click unsubscribe) | Cualquier código que use API |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `find-docs` | dependency. Pre-gen R13 invoca en cada modo. |
| `baas` | upstream. baas decision determina dónde vive email_subscriptions table. |
| `add-login` | upstream **mandatory**. profiles.email es el recipient default. password reset emails reemplazan los de Supabase Auth built-in si esta skill corre antes. |
| `add-ui-kit` | upstream. Sin brand.json + voice.json válidos, halt. contexts.transactional_email del schema crítico. |
| `add-payments` | sibling. Si add-payments corrió antes, add-emails detecta `subscriptions` table y agrega templates payment-related (InvoiceReceipt, PaymentFailed, SubscriptionCanceled). Sin add-payments, esos 3 templates se omiten. |
| `impeccable` | NOT direct dependency. Email templates son React Email shape, NO consumen `@/shared/components/ui` (esos son web components). Si proyecto necesita preview UI de emails, opcional integration. |
| `el-migrador` | downstream Supabase only. Aplica 0003_email_subscriptions.sql. |
| `el-guardian` | mandatory pre-deploy. Audita API keys isolation, webhook signature, suppression handling, R14 gates, RLS, rate limiting, unsubscribe compliance. |
| `el-evaluador` | post-gen valida L1+L2+L3 (Brand contract per template, security pre-handoff). |
| `add-mobile` | sibling. Si add-mobile corre después, push notifications complementan emails (multi-channel notifications). |

## Output handoff

Tras pasar L1+L2+L3 + security pre-handoff:

```markdown
## add-emails handoff

**Mode:** RESEND | SENDGRID | PAUSE
**Files generated:** N (0 si PAUSE)
**Output paths (Resend mode):**
- src/lib/resend/{client,server}.ts
- src/emails/{Welcome,MagicLink,PasswordReset,InvoiceReceipt,PaymentFailed,SubscriptionCanceled,EmailChangedConfirmation}.tsx
- src/app/api/email/{send,unsubscribe,suppression-webhook}/route.ts
- src/actions/email.ts
- src/types/email.ts
- supabase/migrations/0003_email_subscriptions.sql

**Brand contract per template:**
| Template | tokens(25) | layout(20) | a11y(30) | anti-slop(15) | voice(10) | TOTAL |
|----------|-----------|------------|----------|---------------|-----------|-------|
| Welcome                      | ... | ... | ... | ... | ... | ≥75 |
| MagicLink                    | ... | ... | ... | ... | ... | ≥75 |
| PasswordReset                | ... | ... | ... | ... | ... | ≥75 |
| InvoiceReceipt               | ... | ... | ... | ... | ... | ≥75 |
| PaymentFailed                | ... | ... | ... | ... | ... | ≥75 |
| SubscriptionCanceled         | ... | ... | ... | ... | ... | ≥75 |
| EmailChangedConfirmation     | ... | ... | ... | ... | ... | ≥75 |

**Security pre-handoff (8-check):**
- ✅ RESEND_API_KEY NOT exposed in client
- ✅ RESEND_WEBHOOK_SECRET .trim() applied
- ✅ Webhook handler verifies signature BEFORE DB ops
- ✅ bulkUnsubscribe / deleteSuppressionEntry / resendCampaign have NO automatic execute()
- ✅ Server actions validate recipient ownership (auth.uid() === recipient.user_id)
- ✅ RLS enabled on email_subscriptions + 1 SELECT policy
- ✅ Rate limiting documented on /api/email/send (10 req/user/hour)
- ✅ Unsubscribe one-click compliant (RFC 8058)

**Citations:**
- [memory:references#R-005] (Brand DNA + transactional_email context)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:CONSTRAINTS.md#R13] (external docs)
- [memory:CONSTRAINTS.md#R14] (destructive — bulk ops)
- [memory:lessons#L-001] (RLS email_subscriptions)
- [memory:lessons#L-002] (webhook payloads as data)
- [memory:lessons#L-003] (whitelist validators)
- [memory:decisions#D-010] (pattern precedente)
- [memory:decisions#D-011] (compliance vs ecosystem axis)
- [docs:resend] · [docs:react-email@v3] · [docs:nextjs] (Mode A)
- [docs:sendgrid] · [docs:sendgrid-mail] · [docs:nextjs] (Mode B)
- [docs:rfc8058] (one-click unsubscribe)

**Mandatory next step:** invocar `el-guardian` con prompts/handoff-el-guardian.md.

**Frictions encountered (if any):**
- <ambigüedades en brand.json contexts.transactional_email>
- <gaps en voice.cta_examples para email-specific CTAs>
- → Promote to errors.md as E-NNN if recurring
```

---

*"El email transaccional es la única conversación uno-a-uno que tu producto tiene en escala. Cuidá la voz."*
