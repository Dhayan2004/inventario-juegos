# detect-state

> Fase 0 de add-monetization. Scan resume-aware de los 3 outputs (payments + emails + audit). Determina pipeline actual + presenta tabla + confirma modo.

## Inputs

- Project root path.
- PREFLIGHT pasó: add-login + Brand DNA + impeccable components presentes.

## Output

```yaml
detection:
  project_root: <path>
  
  step_status:
    payments:
      complete: bool
      paths_found: [<list>]   # src/features/payments/, lib/stripe/, app/(app)/billing/
      paths_missing: [<list>]
      provider_detected: stripe | polar | null
    emails:
      complete: bool
      paths_found: [<list>]   # lib/resend/, lib/sendgrid/, emails/ folder
      paths_missing: [<list>]
      provider_detected: resend | sendgrid | null
    audit:
      complete: bool
      paths_found: [<list>]   # .claude/reports/web-audit-*.md
      paths_missing: [<list>]
      report_age_days: <number or null>
  
  next_pending_step: 1 | 2 | 3 | none
  pending_count: 0 | 1 | 2 | 3
  estimated_time_min: <number>
  
  start_mode: go | partial-payments-only | desde-N | abort
  resume_path: full-chain | partial | already-complete
```

## Step-by-step

### Paso 1 — Scan paths add-payments

```bash
# Provider detection (stripe o polar)
test -d src/features/payments/ || test -d app/\(app\)/billing/
ls lib/stripe/ 2>/dev/null && echo "stripe"
ls lib/polar/ 2>/dev/null && echo "polar"

# Webhook handler
test -f app/api/webhooks/stripe/route.ts || test -f app/api/webhooks/polar/route.ts

# Subscriptions table migration
ls .claude/migrations/*subscriptions*.sql 2>/dev/null

# Pricing/checkout pages
ls src/app/\(marketing\)/pricing/page.tsx 2>/dev/null
ls src/app/\(app\)/checkout/page.tsx 2>/dev/null
```

Si features/payments/ + webhook + subscriptions migration + pricing page existen → `payments.complete = true`.

### Paso 2 — Scan paths add-emails

```bash
# Provider detection
ls lib/resend/ 2>/dev/null && echo "resend"
ls lib/sendgrid/ 2>/dev/null && echo "sendgrid"

# 7 React Email templates canónicos
ls emails/ 2>/dev/null
ls emails/Welcome.tsx 2>/dev/null
ls emails/MagicLink.tsx 2>/dev/null
ls emails/InvoiceReceipt.tsx 2>/dev/null
# (PasswordReset, PaymentFailed, SubscriptionCanceled, EmailChangedConfirmation)

# Send route + suppression
test -f app/api/email/send/route.ts
test -f app/api/email/unsubscribe/route.ts
```

Si lib/{provider}/ + emails/ folder con ≥4 templates + send route → `emails.complete = true`.

### Paso 3 — Scan paths web-quality

```bash
# Reportes recientes
ls .claude/reports/web-audit-*.md 2>/dev/null

# Si existe el más reciente, calcular edad en días
recent_audit=$(ls -t .claude/reports/web-audit-*.md 2>/dev/null | head -1)
if [ -n "$recent_audit" ]; then
  age_days=$(( ($(date +%s) - $(stat -f %m "$recent_audit" 2>/dev/null)) / 86400 ))
fi
```

Threshold: si reporte existe + age_days <7 → `audit.complete = true`. Si >7 días → audit stale, `complete = false` (re-ejecutar para data fresh).

### Paso 4 — Determinar `next_pending_step`

```
Loop por step en orden 1→3:
  Si step.complete = false → next_pending_step = step
  Salir del loop.
Si todos completos → next_pending_step = none.
```

### Paso 5 — Estimar tiempo

```
estimated_time_min:
  payments pendiente: ~30min (sub-skill add-payments full)
  emails pendiente:    ~20min (add-emails con providers)
  audit pendiente:     ~10min (web-quality live o ~5min static)
```

### Paso 6 — Presentar tabla

```markdown
🔨 add-monetization — Cadena de monetización

**Project:** {path}
**Mode:** {full chain | partial | already-complete}

  #   Skill          Produce                       Estado
  1   add-payments   Pagos integrados              ✅ ya existe / ⬜ pendiente
                     (Stripe/Polar + webhook
                      + subscriptions table)
  2   add-emails     Emails transaccionales        ✅ / ⬜
                     (Resend/SendGrid + 7 React
                      Email templates)
  3   web-quality    Audit pre-deploy              ✅ (age: Xd) / ⬜
                     (Lighthouse scores +
                      Core Web Vitals)
  ──────────────────────────────────────────────────────
  Pendientes: {N} de 3  ·  Tiempo estimado: ~{T}min
  Existentes: {M} de 3  (se reutilizan)
```

### Paso 7 — Confirmar inicio

```markdown
**¿Arrancamos?**

- "go"                 → ejecutar lo pendiente desde paso N (full chain)
- "solo payments"      → modo partial: solo paso 1, skipea emails + audit
- "desde N"            → forzar arranque desde paso N
- "abort"              → no ejecutar
```

### Paso 8 — L-004 test diagnóstico

| Caso | ¿Upstream user action requerida del selector wizard? | Resultado |
|------|---------------------------------------------------|-----------|
| Sin add-login (PREFLIGHT) | Sí (correr init-saas) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Sin Brand DNA (PREFLIGHT) | Sí (add-ui-kit) | **PREFLIGHT halt, NO PAUSE genuino** |
| Sin impeccable components (PREFLIGHT) | Sí (impeccable Mode C) | **PREFLIGHT halt, NO PAUSE genuino** |
| Full chain con scope ambiguo | NO — partial mode siempre disponible | NO PAUSE |
| Partial → después usuario quiere full | NO — re-invocar wizard, resume-aware | NO PAUSE |
| add-payments retorna PAUSE-interno (D-010) | **PAUSE-interno-delegado** — NO escala al selector wizard | **NO PAUSE wizard** |
| add-emails retorna PAUSE-interno (D-011 on-prem SMTP) | **PAUSE-interno-delegado** — NO escala al selector wizard | **NO PAUSE wizard** |
| web-quality auto-degrada live → static | NO — graceful degradation, no halt | NO PAUSE |

**Conclusión D-020:** **BINARY** confirmed. full chain default + partial override. NO PAUSE-wizard.

**CRÍTICO:** PAUSE-interno-delegado ≠ PAUSE-wizard. Documentado verbatim en D-020 — primer ADR cross-skill que codifica esta distinción para wizards futuros.

## Edge cases

### Edge: payments existe con shape distinto al canónico (ej: Lemon Squeezy en lugar de Stripe/Polar)

→ `payments.complete = false` con warning explícito: "detecté integración Lemon Squeezy distinta a Stripe/Polar (defaults Forja). ¿Re-ejecutar add-payments (sobrescribe) o pause para reconciliación manual?".

### Edge: emails templates ausentes pero lib/{provider}/ existe

→ `emails.complete = false` (templates son output crítico de add-emails, no solo el SDK). Re-ejecutar add-emails.

### Edge: audit reporte existe pero pre-deploy gate = NEEDS_FIX

→ `audit.complete = true` (técnicamente sí corrió) pero warning: "último audit reportó NEEDS_FIX en X categorías. ¿Re-correr audit post-fix o aceptar status actual?". Default: re-correr para data fresh.

### Edge: usuario corre wizard en proyecto ya completado (3 ✅)

→ Reportar: "add-monetization: nada que hacer. Pagos + emails + audit ya están todos. Próximos pasos sugeridos: /add-mobile, /la-forja."

### Edge: usuario fuerza "desde 2" cuando paso 1 incompleto

→ Halt: "Paso 2 (add-emails) requiere add-payments completo. Detecté payments.complete = false. Corré 'go' o 'solo payments' primero."

### Edge: web-quality en proyecto sin URL ni server running

→ web-quality auto-degrada a static analysis (D-015 binary). NO halt — wizard procede con audit static. Reportar al usuario que se usó modo static.

### Edge: add-payments PAUSE-interno triggered (usuario indie sin empresa MoR + Polar elegido)

→ Sub-agent reporta `step_result.outcome = paused-internal` con `pause_resolution = "constituí empresa MoR para Polar O elegí Stripe (no requiere)"`. Wizard NO escala como PAUSE-wizard. Reporta al usuario:

```markdown
⏸️ Paso 1 (add-payments) PAUSED-internal

**Razón (PAUSE-interno-delegado de add-payments D-010):**
Polar requiere empresa MoR registrada. Tu setup actual indie no tiene
empresa registrada disponible.

**Resolución:**
- Opción A: constituí empresa MoR (proceso legal, ~días-semanas)
- Opción B: cambiá decisión a Stripe (no requiere empresa)

**Cuando resuelvas:**
Re-invocá `/add-monetization` → resume-aware detectará progreso y arrancará
desde paso 2 (si paso 1 quedó completado post-resolución).

**NO PAUSE-wizard:** este es PAUSE-interno-delegado (D-020 distinción).
Wizard sigue siendo BINARY al wizard level.
```

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — wizard thin.
- [memory:lessons#L-004] — test diagnóstico.
- [memory:decisions#D-020] — add-monetization binary + PAUSE-interno-delegado distinction.
- [memory:decisions#D-010] — add-payments PAUSE interno trinary.
- [memory:decisions#D-011] — add-emails PAUSE interno trinary.
- [memory:decisions#D-015] — web-quality binary live/static.
- [memory:errors#E-006] — gap UX que wizard resuelve.

## Refusals

- ❌ Saltar scan (sin detección no se sabe qué skipear).
- ❌ Re-ejecutar add-payments si subscriptions ya existen.
- ❌ Force-fit trinary inventando un PAUSE-wizard.
- ❌ **Escalar PAUSE-interno-delegado al nivel wizard** (D-020 violation crítica).
- ❌ Confundir PREFLIGHT halt con PAUSE del selector.
- ❌ Marcar audit.complete = true con reporte stale (>7 días).
- ❌ Saltar confirmation antes de Fase 1.
