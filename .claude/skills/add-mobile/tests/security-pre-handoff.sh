#!/usr/bin/env bash
# add-mobile security pre-handoff test (L3 system check)
#
# Cubre los 10 gates del checklist handoff-el-guardian.md aplicados a
# templates/pwa + templates/capacitor + templates/react-native-expo.
# Se corre tras dry-run-pwa + dry-run-native pasen.
#
# Usage: bash .claude/skills/add-mobile/tests/security-pre-handoff.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PWA="$SKILL_DIR/templates/pwa"
CAP="$SKILL_DIR/templates/capacitor"
EXPO="$SKILL_DIR/templates/react-native-expo"

echo "── add-mobile security pre-handoff ─────────────────────────────"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ─────────────────────────────────────────────────────────────────────
# Gate 1 — VAPID secrets isolation (CRITICAL)
# ─────────────────────────────────────────────────────────────────────
echo "Gate 1 — VAPID secrets isolation"

# VAPID_PRIVATE_KEY NUNCA en client / SW / hooks / components
for path in "$PWA/lib/push/client.ts" "$PWA/public/sw.js" "$PWA/hooks/usePushSubscription.ts" "$PWA/components/PushPermissionPrompt.tsx" "$PWA/components/InstallPromptUI.tsx" "$PWA/components/PWARegister.tsx"; do
  if grep -q "VAPID_PRIVATE_KEY" "$path" 2>/dev/null; then
    fail "$path EXPONE VAPID_PRIVATE_KEY (CRITICAL)"
  else
    ok "$path NO leak VAPID_PRIVATE_KEY"
  fi
done

# VAPID_PRIVATE_KEY EN server lib + send route (intencional)
if grep -q "VAPID_PRIVATE_KEY" "$PWA/lib/push/server.ts"; then
  ok "VAPID_PRIVATE_KEY presente en lib/push/server.ts"
else
  fail "VAPID_PRIVATE_KEY missing en server lib"
fi

# server-only guard
if grep -q "import 'server-only'" "$PWA/lib/push/server.ts"; then
  ok "lib/push/server.ts: 'server-only' guard"
else
  fail "lib/push/server.ts: 'server-only' guard missing"
fi

# NEXT_PUBLIC_VAPID_PUBLIC_KEY puede ir a client (intencional)
if grep -q "NEXT_PUBLIC_VAPID_PUBLIC_KEY" "$PWA/hooks/usePushSubscription.ts"; then
  ok "NEXT_PUBLIC_VAPID_PUBLIC_KEY en hook (intencional para subscribe)"
else
  fail "NEXT_PUBLIC_VAPID_PUBLIC_KEY missing en hook"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 2 — Service Worker NO fetch handler (HIGH — iOS Safari)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 2 — Service Worker NO fetch handler (iOS Safari quirk)"

if grep -E "addEventListener\\(['\"]fetch['\"]" "$PWA/public/sw.js"; then
  fail "sw.js HAS fetch handler — iOS Safari PWA broken (HIGH)"
else
  ok "sw.js NO fetch handler (iOS Safari PWA compatible)"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 3 — RLS L-001 (CRITICAL)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 3 — RLS L-001 en push tables"

# PWA: push_subscriptions
PWA_SQL="$PWA/migrations/0004_push_subscriptions.sql"
if grep -q "enable row level security" "$PWA_SQL"; then
  ok "PWA: push_subscriptions RLS habilitado"
else
  fail "PWA: RLS missing"
fi

# 3 specific policies
for policy in "for select using (auth.uid() = user_id)" "for insert with check (auth.uid() = user_id)" "for delete using (auth.uid() = user_id)"; do
  if grep -q "$policy" "$PWA_SQL"; then
    ok "PWA: $policy"
  else
    fail "PWA: missing $policy"
  fi
done

# NO UPDATE direct policy en push_subscriptions
if awk '/^create table.*push_subscriptions/,/^create table/' "$PWA_SQL" | grep -E "for update.*using"; then
  fail "PWA: push_subscriptions UPDATE direct (L-001 violation)"
else
  ok "PWA: push_subscriptions NO UPDATE direct"
fi

# Capacitor: native_push_tokens
if grep -q "enable row level security" "$CAP/migrations/0005_native_push_tokens.sql"; then
  ok "Capacitor: native_push_tokens RLS habilitado"
else
  fail "Capacitor: RLS missing"
fi

# Expo: expo_push_tokens
if grep -q "enable row level security" "$EXPO/migrations/0004b_expo_push_tokens.sql"; then
  ok "Expo: expo_push_tokens RLS habilitado"
else
  fail "Expo: RLS missing"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 4 — R14 destructive (HIGH)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 4 — R14: bulk operations sin execute() automático"

ACTIONS="$PWA/actions/notifications.ts"

if grep -E "^export.*tool\\(.*execute.*async.*(broadcast|sendToTopic|revokeAll)" "$ACTIONS"; then
  fail "R14 CRITICAL violation: destructive tool({execute})"
else
  ok "NO tool({execute}) destructive (R14 PASS)"
fi

# 3 typed-confirm gates
for gate in "BROADCAST" "SEND_TO_TOPIC" "REVOKE_ALL"; do
  if grep -q "z.literal('$gate'" "$ACTIONS"; then
    ok "Typed-confirm gate '$gate'"
  else
    fail "Typed-confirm gate '$gate' missing"
  fi
done

# Audit log antes de execute
AUDIT_LINE=$(grep -n "from('push_admin_actions')" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "from('push_subscriptions')" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$AUDIT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$AUDIT_LINE" -lt "$EXEC_LINE" ]; then
  ok "Audit log antes de execute (L$AUDIT_LINE < L$EXEC_LINE)"
else
  fail "Audit log NOT before execute"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 5 — L-002 SW push payload as data (HIGH)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 5 — L-002 SW push payload as DATA, not instructions"

SW="$PWA/public/sw.js"

# NO patterns peligrosos (acción agentic basada en payload).
# Filtrar comments (// y *) para no flag el anti-pattern documentado.
if grep -E "if \\(payload\\.action.*===" "$SW" | grep -v "^\\s*//\\|^\\s*\\*"; then
  fail "SW ejecuta acción agentic basada en payload (L-002 violation)"
else
  ok "SW NO acción agentic basada en payload"
fi

if grep -E "eval\\(.*event\\.data" "$SW"; then
  fail "SW eval() con event.data (CRITICAL)"
else
  ok "SW NO eval con event.data"
fi

# Whitelist explícita type guards
for field in "title" "body" "url"; do
  if grep -q "typeof payload.$field === 'string'" "$SW"; then
    ok "SW type guard payload.$field"
  else
    fail "SW missing type guard for payload.$field"
  fi
done

if grep -q "L-002" "$SW"; then
  ok "SW cita L-002"
else
  fail "SW missing L-002 citation"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 6 — L-003 whitelist validators (MEDIUM)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 6 — L-003 whitelist validators"

# NO z.record(z.any())
if grep "z.record(z.any())" "$ACTIONS"; then
  fail "actions/notifications: forbidden z.record(z.any())"
else
  ok "actions/notifications: no z.record(z.any())"
fi

# Specific bounds
if grep -q "z.string().min(1).max(50)" "$ACTIONS"; then
  ok "title bound min(1).max(50)"
else
  fail "title bounds missing"
fi

if grep -q "z.string().max(150)" "$ACTIONS"; then
  ok "body bound max(150)"
else
  fail "body bound missing"
fi

if grep -q "z.enum(ALLOWED_TOPICS)" "$ACTIONS"; then
  ok "topic z.enum whitelist"
else
  fail "topic enum missing"
fi

# Subscribe route también whitelist
SUB="$PWA/app/api/push/subscribe/route.ts"
if grep -q "z.string().url().max(500)" "$SUB"; then
  ok "subscribe: endpoint URL whitelist"
else
  fail "subscribe: endpoint not whitelisted"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 7 — Permission flow NO on page load (MEDIUM)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 7 — Permission flow NO on page load (UX best practice)"

PERM="$PWA/components/PushPermissionPrompt.tsx"

# autoShowDelay default 0 (manual show)
if grep -q "autoShowDelay = 0" "$PERM"; then
  ok "autoShowDelay default 0 (NO on page load)"
else
  fail "autoShowDelay default !==0 (UX violation)"
fi

# localStorage dismissal tracking
if grep -q "DISMISSED_KEY\\|push-prompt-dismissed" "$PERM"; then
  ok "localStorage dismissal tracking"
else
  fail "Dismissal tracking missing"
fi

# permission===denied → return null
if grep -q "permission === 'denied'" "$PERM"; then
  ok "permission denied → null"
else
  fail "permission denied check missing"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 8 — SW updates idempotentes (LOW)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 8 — SW updates idempotentes"

if grep -q "skipWaiting" "$SW"; then
  ok "SW: skipWaiting"
else
  fail "SW: skipWaiting missing"
fi

if grep -q "clients.claim" "$SW"; then
  ok "SW: clients.claim"
else
  fail "SW: clients.claim missing"
fi

if grep -q "pushsubscriptionchange" "$SW"; then
  ok "SW: pushsubscriptionchange handler (auto-resuscribe)"
else
  fail "SW: pushsubscriptionchange missing"
fi

# PWARegister postMessage SKIP_WAITING
REG="$PWA/components/PWARegister.tsx"
if grep -q "SKIP_WAITING" "$REG"; then
  ok "PWARegister: SKIP_WAITING postMessage"
else
  fail "PWARegister: SKIP_WAITING missing"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 9 — Rate limiting /api/push/send (MEDIUM)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 9 — Rate limiting /api/push/send"

SEND="$PWA/app/api/push/send/route.ts"

if grep -qE "RATE_LIMIT|rateLimitOk" "$SEND"; then
  ok "send: rate limiting"
else
  fail "send: rate limiting missing"
fi

if grep -qE "RATE_LIMIT *= *[0-9]+" "$SEND"; then
  ok "send: RATE_LIMIT value documented"
else
  fail "send: RATE_LIMIT value missing"
fi

if grep -qE "WINDOW_MS|60 \\* 60 \\* 1000" "$SEND"; then
  ok "send: rate window documented"
else
  fail "send: rate window missing"
fi

if grep -q "status: 429" "$SEND"; then
  ok "send: 429 on rate limit"
else
  fail "send: 429 missing"
fi

# Service role bearer (no user-direct broadcast)
if grep -q "SUPABASE_SERVICE_ROLE_KEY" "$SEND"; then
  ok "send: service_role bearer auth (server-to-server only)"
else
  fail "send: service_role auth missing"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 10 — Manifest icons match brand.json (LOW)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 10 — Manifest icons match brand.json (placeholders)"

# manifest.json valid
if node -e "JSON.parse(require('fs').readFileSync('$PWA/public/manifest.json','utf8'))" 2>/dev/null; then
  ok "manifest.json valid JSON"
else
  fail "manifest.json invalid"
fi

# Tokens placeholders presentes (R10 contract)
if grep -q "{{ TOKEN_PRIMARY_COLOR }}" "$PWA/public/manifest.json"; then
  ok "manifest cites TOKEN_PRIMARY_COLOR (R10)"
else
  fail "manifest TOKEN_PRIMARY_COLOR missing"
fi

# 6 icons declared
icon_count=$(grep -c '"src": "/icons/icon-' "$PWA/public/manifest.json" || true)
if [ "$icon_count" -ge 6 ]; then
  ok "manifest declares ≥6 icons"
else
  fail "manifest <6 icons (got $icon_count)"
fi

# Maskable purpose
if grep -q "any maskable" "$PWA/public/manifest.json"; then
  ok "manifest icons maskable"
else
  fail "manifest no maskable purpose"
fi

# Apple-specific tags documented (en setup-pwa.md prompt)
if grep -q "apple-mobile-web-app-capable\\|appleWebApp" "$SKILL_DIR/prompts/setup-pwa.md"; then
  ok "setup-pwa documenta Apple meta tags"
else
  fail "setup-pwa missing Apple meta tags"
fi

# ─────────────────────────────────────────────────────────────────────
# Bonus — D-012 binary boundary documented
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Bonus — D-012 binary boundary"

if grep -q "binary" "$SKILL_DIR/prompts/decision-tree.md"; then
  ok "decision-tree mentions binary"
else
  fail "decision-tree missing binary mention"
fi

if grep -q "D-012" "$SKILL_DIR/SKILL.md"; then
  ok "SKILL.md cita D-012"
else
  fail "SKILL.md missing D-012"
fi

# ─────────────────────────────────────────────────────────────────────
# Bonus — Capacitor + Expo VAPID isolation (no FCM secrets en client)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Bonus — Capacitor + Expo secrets isolation"

# Capacitor: NO FCM_SERVER_KEY en components
for path in "$CAP/components/CapacitorPWABridge.tsx" "$CAP/lib/native/push.ts"; do
  if grep -q "FCM_SERVER_KEY" "$path" 2>/dev/null; then
    fail "$path EXPONE FCM_SERVER_KEY"
  else
    ok "$path NO leak FCM_SERVER_KEY"
  fi
done

# Expo: NO requires server secrets (Expo Push Service es gratis)
if grep -q "EXPO_PUSH_SERVER_KEY\\|EXPO_PRIVATE_KEY" "$EXPO/lib/push/notifications.ts" 2>/dev/null; then
  fail "expo notifications EXPONE non-existent secret"
else
  ok "expo notifications NO secrets requeridos (Expo Push Service)"
fi

# ─────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-mobile security pre-handoff: ALL PASS ($PASS checks across 10 gates)"
  exit 0
else
  echo "❌ add-mobile security pre-handoff: $FAIL failures"
  exit 1
fi
