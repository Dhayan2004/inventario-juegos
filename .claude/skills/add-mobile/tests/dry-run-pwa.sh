#!/usr/bin/env bash
# add-mobile dry-run test — Mode A (PWA)
#
# Validates L1 (file presence + structure) + L2 (semantics) of Mode A.
# Approach: templates ARE the expected output post-substitution.
#
# Usage: bash .claude/skills/add-mobile/tests/dry-run-pwa.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PWA="$SKILL_DIR/templates/pwa"

echo "── add-mobile dry-run-pwa ──────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — PWA file presence"

pwa_files=(
  "public/manifest.json"
  "public/sw.js"
  "lib/push/client.ts"
  "lib/push/server.ts"
  "app/api/push/subscribe/route.ts"
  "app/api/push/unsubscribe/route.ts"
  "app/api/push/send/route.ts"
  "app/(mobile)/install/page.tsx"
  "components/PWARegister.tsx"
  "components/PushPermissionPrompt.tsx"
  "components/InstallPromptUI.tsx"
  "hooks/usePushSubscription.ts"
  "actions/notifications.ts"
  "migrations/0004_push_subscriptions.sql"
)
for f in "${pwa_files[@]}"; do
  if [ -f "$PWA/$f" ]; then ok "pwa: $f"; else fail "pwa missing: $f"; fi
done

# Icons (placeholders al menos)
for size in 72 96 128 144 192 512; do
  if [ -f "$PWA/public/icons/icon-${size}.png.placeholder" ] || [ -f "$PWA/public/icons/icon-${size}.png" ]; then
    ok "pwa icon-${size} placeholder presente"
  else
    fail "pwa icon-${size} missing"
  fi
done

# ── L1 — manifest.json valid + tokens ────────────────────────────────
echo ""
echo "L1 — manifest.json structure"

# JSON valid
if node -e "JSON.parse(require('fs').readFileSync('$PWA/public/manifest.json','utf8'))" 2>/dev/null; then
  ok "manifest.json valid JSON"
else
  fail "manifest.json invalid JSON"
fi

# Tokens placeholders presentes (R10 contract)
for placeholder in "{{ APP_NAME }}" "{{ APP_SHORT_NAME }}" "{{ TOKEN_PRIMARY_COLOR }}" "{{ TOKEN_BACKGROUND_COLOR }}"; do
  if grep -q "$placeholder" "$PWA/public/manifest.json"; then
    ok "manifest cites $placeholder"
  else
    fail "manifest missing $placeholder placeholder"
  fi
done

# 6 icons declared
icon_count=$(grep -c '"src": "/icons/icon-' "$PWA/public/manifest.json" || true)
if [ "$icon_count" -ge 6 ]; then
  ok "manifest declares ≥6 icons (got $icon_count)"
else
  fail "manifest declares <6 icons (got $icon_count)"
fi

# any maskable purpose
if grep -q "any maskable" "$PWA/public/manifest.json"; then
  ok "manifest icons con purpose: any maskable"
else
  fail "manifest icons missing maskable purpose"
fi

# ── L1 — Service Worker NO fetch handler (iOS Safari quirk) ──────────
echo ""
echo "L1 — Service Worker NO fetch handler (CRITICAL — iOS Safari)"

if grep -E "addEventListener\\(['\"]fetch['\"]" "$PWA/public/sw.js"; then
  fail "sw.js HAS fetch handler — iOS Safari PWA broken (CRITICAL)"
else
  ok "sw.js NO fetch handler (iOS Safari PWA compatible)"
fi

# Required SW listeners
for listener in "install" "activate" "push" "notificationclick" "pushsubscriptionchange" "message"; do
  if grep -q "addEventListener('$listener'" "$PWA/public/sw.js"; then
    ok "sw.js has $listener handler"
  else
    fail "sw.js missing $listener handler"
  fi
done

# L-002: payload as data
if grep -q "typeof payload.title === 'string'" "$PWA/public/sw.js"; then
  ok "sw.js payload as data — title type guard"
else
  fail "sw.js missing payload type guards (L-002)"
fi

# Payload bounds (slice)
if grep -q "payload.title.slice" "$PWA/public/sw.js"; then
  ok "sw.js bounds payload.title (anti DoS)"
else
  fail "sw.js missing payload bounds"
fi

# L-002 cita
if grep -q "L-002" "$PWA/public/sw.js"; then
  ok "sw.js cita L-002"
else
  fail "sw.js missing L-002 citation"
fi

# ── L2 — VAPID isolation (R13 docs:web-push) ─────────────────────────
echo ""
echo "L2 — VAPID isolation (server-only)"

if grep -q "import 'server-only'" "$PWA/lib/push/server.ts"; then
  ok "lib/push/server.ts uses 'server-only' guard"
else
  fail "lib/push/server.ts missing 'server-only'"
fi

if grep "VAPID_PRIVATE_KEY" "$PWA/lib/push/server.ts" | grep -q "\.trim()"; then
  ok "VAPID_PRIVATE_KEY .trim() applied"
else
  fail "VAPID_PRIVATE_KEY missing .trim()"
fi

if grep "NEXT_PUBLIC_VAPID_PUBLIC_KEY" "$PWA/lib/push/server.ts" | grep -q "\.trim()"; then
  ok "NEXT_PUBLIC_VAPID_PUBLIC_KEY .trim() applied"
else
  fail "NEXT_PUBLIC_VAPID_PUBLIC_KEY missing .trim()"
fi

# VAPID_PRIVATE_KEY NO en client / hooks / components / sw
for path in "$PWA/lib/push/client.ts" "$PWA/hooks/usePushSubscription.ts" "$PWA/components/PWARegister.tsx" "$PWA/components/PushPermissionPrompt.tsx" "$PWA/components/InstallPromptUI.tsx" "$PWA/public/sw.js"; do
  if grep -q "VAPID_PRIVATE_KEY" "$path" 2>/dev/null; then
    fail "$path EXPONE VAPID_PRIVATE_KEY (CRITICAL)"
  else
    ok "$path NO leak VAPID_PRIVATE_KEY"
  fi
done

# ALLOWED_TOPICS exportado
if grep -q "ALLOWED_TOPICS" "$PWA/lib/push/server.ts"; then
  ok "ALLOWED_TOPICS whitelist exported"
else
  fail "ALLOWED_TOPICS missing"
fi

# isAppleEndpoint detector
if grep -q "isAppleEndpoint" "$PWA/lib/push/server.ts"; then
  ok "isAppleEndpoint detector presente"
else
  fail "isAppleEndpoint missing"
fi

# ── L2 — VAPID conversion en client ──────────────────────────────────
echo ""
echo "L2 — VAPID public key Uint8Array conversion (client)"

if grep -q "urlBase64ToUint8Array" "$PWA/lib/push/client.ts"; then
  ok "urlBase64ToUint8Array exported"
else
  fail "urlBase64ToUint8Array missing"
fi

if grep -q "Uint8Array" "$PWA/lib/push/client.ts"; then
  ok "Uint8Array conversion presente"
else
  fail "Uint8Array conversion missing"
fi

# Hook usa la conversion
if grep -q "urlBase64ToUint8Array" "$PWA/hooks/usePushSubscription.ts"; then
  ok "usePushSubscription usa urlBase64ToUint8Array"
else
  fail "usePushSubscription NO usa Uint8Array conversion"
fi

# ── L2 — API routes shape ────────────────────────────────────────────
echo ""
echo "L2 — API routes shape"

# Subscribe route
SUB="$PWA/app/api/push/subscribe/route.ts"
if grep -q "supabase.auth.getUser()" "$SUB"; then
  ok "subscribe: auth gate"
else
  fail "subscribe: auth gate missing"
fi

if grep -q "z.string().url().max(500)" "$SUB"; then
  ok "subscribe: endpoint URL whitelist (L-003)"
else
  fail "subscribe: endpoint not validated"
fi

if grep -q "onConflict: 'user_id,endpoint'" "$SUB"; then
  ok "subscribe: UPSERT idempotent"
else
  fail "subscribe: NOT idempotent"
fi

# Unsubscribe route
UNSUB="$PWA/app/api/push/unsubscribe/route.ts"
if grep -q "export async function DELETE" "$UNSUB"; then
  ok "unsubscribe: DELETE handler"
else
  fail "unsubscribe: DELETE missing"
fi

if grep -q "supabase.auth.getUser()" "$UNSUB"; then
  ok "unsubscribe: auth gate"
else
  fail "unsubscribe: auth gate missing"
fi

# Send route
SEND="$PWA/app/api/push/send/route.ts"
if grep -q "SUPABASE_SERVICE_ROLE_KEY" "$SEND"; then
  ok "send: service_role bearer auth"
else
  fail "send: service_role auth missing"
fi

if grep -qE "RATE_LIMIT|rateLimitOk" "$SEND"; then
  ok "send: rate limiting"
else
  fail "send: rate limiting missing"
fi

if grep -q "status: 429" "$SEND"; then
  ok "send: 429 on rate limit"
else
  fail "send: 429 missing"
fi

if grep -q "isAppleEndpoint" "$SEND"; then
  ok "send: Apple silent failure cleanup"
else
  fail "send: Apple cleanup missing"
fi

if grep -q "z.enum(ALLOWED_TOPICS)" "$SEND"; then
  ok "send: topic whitelist (L-003)"
else
  fail "send: topic not whitelisted"
fi

# ── L2 — actions/notifications.ts (L-003 + R14) ──────────────────────
echo ""
echo "L2 — actions/notifications.ts"

ACTIONS="$PWA/actions/notifications.ts"

if grep -q "'use server'" "$ACTIONS"; then
  ok "actions: 'use server' directive"
else
  fail "actions: missing 'use server'"
fi

# 3 typed-confirm gates
if grep -q "z.literal('BROADCAST'" "$ACTIONS"; then
  ok "actions: sendBroadcast typed-confirm"
else
  fail "actions: BROADCAST gate missing"
fi

if grep -q "z.literal('SEND_TO_TOPIC'" "$ACTIONS"; then
  ok "actions: sendToTopic typed-confirm"
else
  fail "actions: SEND_TO_TOPIC gate missing"
fi

if grep -q "z.literal('REVOKE_ALL'" "$ACTIONS"; then
  ok "actions: revokeAllSubscriptions typed-confirm"
else
  fail "actions: REVOKE_ALL gate missing"
fi

# NO tool({execute}) destructive
if grep -E "^export.*tool\(.*execute.*async.*(broadcast|sendToTopic|revokeAll)" "$ACTIONS"; then
  fail "actions: destructive tool({execute}) — R14 CRITICAL"
else
  ok "actions: NO tool({execute}) destructive (R14 PASS)"
fi

# Admin role gate
if grep -q "profile?.role !== 'admin'" "$ACTIONS"; then
  ok "actions: admin role gate"
else
  fail "actions: admin role gate missing"
fi

# Audit log antes de execute (revokeAll path)
AUDIT_LINE=$(grep -n "from('push_admin_actions')" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "from('push_subscriptions')" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$AUDIT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$AUDIT_LINE" -lt "$EXEC_LINE" ]; then
  ok "actions: audit log (L$AUDIT_LINE) antes de execute (L$EXEC_LINE)"
else
  fail "actions: audit log NOT before execute"
fi

# z.record(z.any()) NOT used
if grep "z.record(z.any())" "$ACTIONS"; then
  fail "actions: forbidden z.record(z.any())"
else
  ok "actions: no z.record(z.any())"
fi

# Whitelist enums
if grep -qE "'admin_compliance'|'system_announcement'" "$ACTIONS"; then
  ok "actions: reason enums whitelisted (L-003)"
else
  fail "actions: reason enums missing"
fi

# ── L2 — RLS L-001 enforcement ───────────────────────────────────────
echo ""
echo "L2 — RLS L-001 en 0004_push_subscriptions.sql"

SQL="$PWA/migrations/0004_push_subscriptions.sql"

if grep -q "enable row level security" "$SQL"; then
  ok "push_subscriptions: RLS habilitado"
else
  fail "RLS missing"
fi

if grep -c "auth.uid() = user_id" "$SQL" | grep -qE "^([3-9]|[1-9][0-9]+)$"; then
  ok "≥3 occurrences of auth.uid()=user_id"
else
  fail "Insufficient auth.uid() policies"
fi

# 3 specific policies
if grep -q "for select using (auth.uid() = user_id)" "$SQL"; then
  ok "SELECT policy presente"
else
  fail "SELECT policy missing"
fi

if grep -q "for insert with check (auth.uid() = user_id)" "$SQL"; then
  ok "INSERT policy presente"
else
  fail "INSERT policy missing"
fi

if grep -q "for delete using (auth.uid() = user_id)" "$SQL"; then
  ok "DELETE policy presente"
else
  fail "DELETE policy missing"
fi

# NO UPDATE direct policy en push_subscriptions
if awk '/^create table.*push_subscriptions/,/^create table/' "$SQL" | grep -E "for update.*using"; then
  fail "push_subscriptions UPDATE direct policy (L-001 violation)"
else
  ok "push_subscriptions NO UPDATE direct (service_role only)"
fi

if grep -q "on delete cascade" "$SQL"; then
  ok "FK cascade"
else
  fail "FK missing cascade"
fi

# 4 tables
for tbl in push_subscriptions push_topic_preferences push_admin_actions; do
  if grep -q "create table.*$tbl" "$SQL"; then
    ok "$tbl table presente"
  else
    fail "$tbl table missing"
  fi
done

# profiles.role
if grep -q "add column if not exists role" "$SQL"; then
  ok "profiles.role extension presente"
else
  fail "profiles.role missing"
fi

# L-001 cita
if grep -q "L-001" "$SQL"; then
  ok "L-001 cited en SQL preamble"
else
  fail "L-001 citation missing"
fi

# ── L2 — components R10 ──────────────────────────────────────────────
echo ""
echo "L2 — components R10 contract"

# PushPermissionPrompt
PERM="$PWA/components/PushPermissionPrompt.tsx"
if grep -q "@/shared/components/ui" "$PERM"; then
  ok "PushPermissionPrompt: impeccable imports"
else
  fail "PushPermissionPrompt: NO impeccable imports"
fi

if grep -E "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" "$PERM"; then
  fail "PushPermissionPrompt: Tailwind purple/indigo (anti-slop)"
else
  ok "PushPermissionPrompt: no Tailwind defaults"
fi

if grep -q "autoShowDelay" "$PERM"; then
  ok "PushPermissionPrompt: autoShowDelay configurable"
else
  fail "PushPermissionPrompt: autoShowDelay missing"
fi

# Default 0 (manual show)
if grep -q "autoShowDelay = 0" "$PERM"; then
  ok "PushPermissionPrompt: default 0 (NO on page load)"
else
  fail "PushPermissionPrompt: default !=0 (UX best practice violated)"
fi

if grep -q "DISMISSED_KEY\|push-prompt-dismissed" "$PERM"; then
  ok "PushPermissionPrompt: localStorage dismissal tracking"
else
  fail "PushPermissionPrompt: dismissal tracking missing"
fi

# InstallPromptUI
INSTALL="$PWA/components/InstallPromptUI.tsx"
if grep -q "@/shared/components/ui" "$INSTALL"; then
  ok "InstallPromptUI: impeccable imports"
else
  fail "InstallPromptUI: NO impeccable imports"
fi

if grep -q "BeforeInstallPromptEvent" "$INSTALL"; then
  ok "InstallPromptUI: BeforeInstallPromptEvent (Chrome detection)"
else
  fail "InstallPromptUI: Chrome detection missing"
fi

if grep -q "isIOSSafari" "$INSTALL"; then
  ok "InstallPromptUI: iOS Safari detection"
else
  fail "InstallPromptUI: iOS Safari detection missing"
fi

if grep -q "display-mode: standalone" "$INSTALL"; then
  ok "InstallPromptUI: already-installed check"
else
  fail "InstallPromptUI: already-installed check missing"
fi

# ── L2 — PWARegister ─────────────────────────────────────────────────
echo ""
echo "L2 — PWARegister (window.location.origin + update polling)"

REG="$PWA/components/PWARegister.tsx"
if grep -q "window.location.origin" "$REG"; then
  ok "PWARegister: window.location.origin (iOS 307 fix)"
else
  fail "PWARegister: missing window.location.origin"
fi

if grep -q "scope: '/'" "$REG"; then
  ok "PWARegister: scope explícito"
else
  fail "PWARegister: scope missing"
fi

if grep -q "registration.update" "$REG"; then
  ok "PWARegister: update polling"
else
  fail "PWARegister: update polling missing"
fi

if grep -q "SKIP_WAITING" "$REG"; then
  ok "PWARegister: SKIP_WAITING postMessage on update"
else
  fail "PWARegister: SKIP_WAITING missing"
fi

# ── L2 — find-docs invocation in prompts (R13) ──────────────────────
echo ""
echo "L2 — find-docs invocation in prompts (R13)"

for p in setup-pwa setup-capacitor setup-react-native-expo generate-install-prompt-ui generate-push-subscription generate-notification-permission-flow; do
  if grep -q "find-docs\|resolve-library-id" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md has find-docs invocation"
  else
    fail "prompts/$p.md missing find-docs"
  fi
done

# decision-tree y handoff: deben citar R13 (literal o range)
for p in decision-tree handoff-el-guardian; do
  if grep -qE "R13|R(10|11|12|13)\.\.14" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md cita R13"
  else
    fail "prompts/$p.md missing R13 citation"
  fi
done

# ── L2 — SKILL.md citations ──────────────────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

for cite in "R-005" "R10" "R13" "R14" "L-001" "L-002" "L-003" "D-010" "D-011" "D-012"; do
  if grep -q "$cite" "$SKILL_DIR/SKILL.md"; then
    ok "SKILL.md cites $cite"
  else
    fail "SKILL.md missing $cite citation"
  fi
done

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-mobile dry-run-pwa: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-mobile dry-run-pwa: $FAIL failures"
  exit 1
fi
