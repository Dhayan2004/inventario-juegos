# Handoff a el-guardian — Pre-deploy Security Checklist (add-mobile)

> Cita: [memory:CONSTRAINTS.md#R10..14] · [memory:lessons#L-001..3] · [memory:decisions#D-010..D-012]
> Cita: [memory:CONSTRAINTS.md#R13] · [docs:web-push] · [docs:capacitor] · [docs:expo]

## Contexto

Antes de deploy a producción, el-guardian audita los outputs de add-mobile (Mode A PWA, B Capacitor, C RN+Expo). El audit cubre 10 gates específicos del dominio mobile + push.

## Checklist obligatorio (10 gates)

### 1. VAPID secrets isolation

```bash
# VAPID_PRIVATE_KEY NUNCA en client / SW
! grep -r "VAPID_PRIVATE_KEY" public/sw.js
! grep -r "VAPID_PRIVATE_KEY" src/components/
! grep -r "VAPID_PRIVATE_KEY" src/hooks/
# Esperado: 0 hits

# VAPID_PRIVATE_KEY EN server lib + send route
grep "VAPID_PRIVATE_KEY" src/lib/push/server.ts        # presente
grep "VAPID_PRIVATE_KEY" src/app/api/push/send/route.ts # presente

# NEXT_PUBLIC_VAPID_PUBLIC_KEY puede ir a client (intencional)
# pero NO debe estar en .env.local sin el NEXT_PUBLIC_ prefix
grep "NEXT_PUBLIC_VAPID_PUBLIC_KEY" .env.local  # presente con prefix
! grep "^VAPID_PUBLIC_KEY=" .env.local  # NO sin prefix
```

### 2. Service Worker NO fetch handler (iOS Safari quirk)

```bash
# Crítico — rompe iOS Safari PWA si presente
! grep -E "addEventListener\\(['\"]fetch['\"]" public/sw.js
# Esperado: 0 hits
```

### 3. RLS L-001 en push_subscriptions

```bash
# RLS habilitado
grep "enable row level security" supabase/migrations/0004_push_subscriptions.sql

# 3 policies (SELECT/INSERT/DELETE auth.uid()=user_id)
grep -c "auth.uid() = user_id" supabase/migrations/0004_push_subscriptions.sql  # ≥3
grep "for select using" supabase/migrations/0004_push_subscriptions.sql
grep "for insert with check" supabase/migrations/0004_push_subscriptions.sql
grep "for delete using" supabase/migrations/0004_push_subscriptions.sql

# NO UPDATE direct policy
! grep "for update using" supabase/migrations/0004_push_subscriptions.sql
```

### 4. R14 bulk operations sin execute() automático

```bash
# sendBroadcast / sendToTopic / revokeAllSubscriptions sin tool({execute})
! grep -E "^export.*tool\\(.*execute.*async.*(broadcast|sendToTopic|revokeAll)" src/actions/notifications.ts

# Typed confirmations presentes
grep "z.literal('BROADCAST'" src/actions/notifications.ts
grep "z.literal('SEND_TO_TOPIC'" src/actions/notifications.ts
grep "z.literal('REVOKE_ALL'" src/actions/notifications.ts
```

### 5. SW push handler trata payload as data (L-002)

```bash
# SW NO ejecuta acciones agentic basadas en push payload
# Búsqueda de patterns peligrosos
! grep -E "if \\(payload\\.action.*===" public/sw.js
! grep -E "payload\\.action\\(" public/sw.js
! grep -E "eval\\(.*event\\.data" public/sw.js

# Whitelist de fields explícita en showNotification
grep "typeof payload.title === 'string'" public/sw.js
grep "typeof payload.body === 'string'" public/sw.js
```

### 6. L-003 whitelist en notification validators

```bash
# Schema explícito, NO z.record(z.any())
! grep "z.record(z.any())" src/actions/notifications.ts

# Whitelists presentes
grep "z.string().min(1).max(50)" src/actions/notifications.ts  # title
grep "z.string().max(150)" src/actions/notifications.ts        # body
grep "z.enum(\\[" src/actions/notifications.ts                  # topic enum
```

### 7. Permission flow NO on page load (UX best practice)

```bash
# autoShowDelay configurable (NO hardcoded 0)
grep "autoShowDelay" src/components/PushPermissionPrompt.tsx

# default !== 0 con trigger automático sin justificación
grep -A1 "autoShowDelay" src/components/PushPermissionPrompt.tsx | grep "default"

# localStorage dismissal tracking
grep "DISMISSED_KEY\\|push-prompt-dismissed" src/components/PushPermissionPrompt.tsx
```

### 8. SW updates idempotentes (skipWaiting + clients.claim)

```bash
# skipWaiting presente
grep "skipWaiting" public/sw.js

# clients.claim presente (post-activate)
grep "clients.claim" public/sw.js

# pushsubscriptionchange handler (auto-resuscribir si browser invalida)
grep "pushsubscriptionchange" public/sw.js
```

### 9. Rate limiting documentado en /api/push/send

```bash
# Para flows individuales, NO para bulk (que pasan por R14 gates)
grep -E "RATE_LIMIT|rateLimitOk|rate_limit" src/app/api/push/send/route.ts

# 429 status on rate limit hit
grep "status: 429" src/app/api/push/send/route.ts

# Auth: solo service_role o user-self (R14 enforced en bulk)
grep "SUPABASE_SERVICE_ROLE_KEY\\|auth.getUser" src/app/api/push/send/route.ts
```

### 10. Manifest icons match brand.json (no Lighthouse defaults)

```bash
# manifest.json valid
node -e "JSON.parse(require('fs').readFileSync('public/manifest.json'))"

# theme_color matches brand.json.tokens.colors.primary
# (requiere proyecto target con brand.json poblado — manual check)
test -f public/manifest.json
test -f public/icons/icon-192.png
test -f public/icons/icon-512.png

# Apple-specific meta tags en layout (manual — instructions en setup-pwa.md)
grep -q "apple-mobile-web-app-capable\\|appleWebApp" src/app/layout.tsx 2>/dev/null
```

**Note:** gate 10 requires manual review en target project (icons + brand.json + layout integration). add-mobile output prepara los archivos pero no auto-edita `layout.tsx`.

## Severidades

| Gate | Severity if FAIL |
|------|------------------|
| 1 — VAPID isolation | **CRITICAL** (production secret leak) |
| 2 — SW fetch handler | **HIGH** (iOS Safari PWA broken) |
| 3 — RLS L-001 | **CRITICAL** (cross-user data leak) |
| 4 — R14 bulk gates | **HIGH** (mass-spam risk + agentic injection) |
| 5 — L-002 SW payload | **HIGH** (push-injection-as-action) |
| 6 — L-003 validators | **MEDIUM** (input mass assignment) |
| 7 — Permission flow UX | **MEDIUM** (user retention degraded) |
| 8 — SW idempotency | **LOW** (stale SW state, recoverable) |
| 9 — Rate limiting | **MEDIUM** (abuse prevention) |
| 10 — Manifest brand match | **LOW** (Lighthouse score, not security) |

PASS solo si NO hay CRITICAL ni HIGH failures. MEDIUM failures con mitigación documentada son aceptables.

## Output

```markdown
# Security Audit — add-mobile

**Mode:** PWA | CAPACITOR | RN_EXPO
**Date:** YYYY-MM-DD
**Status:** PASS | NEEDS_FIX | BLOCKED

## Gates
1. ✅/❌ VAPID secrets isolation
2. ✅/❌ Service Worker NO fetch handler
3. ✅/❌ RLS L-001 en push_subscriptions
4. ✅/❌ R14 bulk operations sin execute()
5. ✅/❌ L-002 SW push payload as data
6. ✅/❌ L-003 whitelist validators
7. ✅/❌ Permission flow NO on page load
8. ✅/❌ SW updates idempotentes
9. ✅/❌ Rate limiting /api/push/send
10. ✅/❌ Manifest icons match brand.json

## Findings (if any)
- ...

## Mitigations applied
- ...

## Decision
- PASS: deploy approved
- NEEDS_FIX: return to add-mobile for re-generation
- BLOCKED: critical issue — user intervention required
```

## Citations

- [memory:lessons#L-001..3]
- [memory:CONSTRAINTS.md#R10..14]
- [memory:references#R-005]
- [memory:decisions#D-010..D-012]
- [docs:web-push] · [docs:web-push-libs] · [docs:capacitor] · [docs:capacitor-push-notifications] · [docs:expo] · [docs:expo-notifications] · [docs:nextjs]
