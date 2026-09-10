#!/usr/bin/env bash
# add-mobile dry-run test — Mode B (Capacitor) + Mode C (RN+Expo)
#
# Validates L1 + L2 of native shell modes. Combinado en un script
# porque ambos comparten patterns (config + push integration + RLS).
#
# Usage: bash .claude/skills/add-mobile/tests/dry-run-native.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAP="$SKILL_DIR/templates/capacitor"
EXPO="$SKILL_DIR/templates/react-native-expo"

echo "── add-mobile dry-run-native ───────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ============================================================================
# Mode B — Capacitor
# ============================================================================
echo "Mode B — Capacitor"
echo ""

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — Capacitor file presence"

cap_files=(
  "capacitor.config.ts"
  "lib/native/push.ts"
  "components/CapacitorPWABridge.tsx"
  "app/api/push/register-native/route.ts"
  "migrations/0005_native_push_tokens.sql"
  "next.config.mjs.patch"
)
for f in "${cap_files[@]}"; do
  if [ -f "$CAP/$f" ]; then ok "capacitor: $f"; else fail "capacitor missing: $f"; fi
done

# ── L2 — capacitor.config.ts ─────────────────────────────────────────
echo ""
echo "L2 — capacitor.config.ts"

if grep -q "appId:" "$CAP/capacitor.config.ts"; then
  ok "config: appId field"
else
  fail "config: appId missing"
fi

if grep -q "{{ APP_ID }}" "$CAP/capacitor.config.ts"; then
  ok "config: APP_ID placeholder"
else
  fail "config: APP_ID placeholder missing"
fi

if grep -q "webDir: 'out'" "$CAP/capacitor.config.ts"; then
  ok "config: webDir 'out' (Next.js export target)"
else
  fail "config: webDir incorrect"
fi

if grep -q "PushNotifications:" "$CAP/capacitor.config.ts"; then
  ok "config: PushNotifications plugin"
else
  fail "config: PushNotifications plugin missing"
fi

if grep -q "{{ TOKEN_PRIMARY_COLOR }}\\|{{ TOKEN_BACKGROUND_COLOR }}" "$CAP/capacitor.config.ts"; then
  ok "config: brand tokens placeholders (R10)"
else
  fail "config: brand tokens missing"
fi

# ── L2 — Native push bridge ──────────────────────────────────────────
echo ""
echo "L2 — Native push bridge"

PUSH="$CAP/lib/native/push.ts"

if grep -q "Capacitor.isNativePlatform()" "$PUSH"; then
  ok "push: Capacitor.isNativePlatform() detection"
else
  fail "push: detection missing"
fi

if grep -q "PushNotifications.requestPermissions" "$PUSH"; then
  ok "push: requestPermissions invoked"
else
  fail "push: requestPermissions missing"
fi

if grep -q "PushNotifications.register" "$PUSH"; then
  ok "push: register invoked"
else
  fail "push: register missing"
fi

if grep -q "addListener.*registration" "$PUSH"; then
  ok "push: registration listener"
else
  fail "push: registration listener missing"
fi

if grep -q "Capacitor.getPlatform" "$PUSH"; then
  ok "push: platform detection (ios/android/web)"
else
  fail "push: platform detection missing"
fi

# ── L2 — register-native API route ───────────────────────────────────
echo ""
echo "L2 — /api/push/register-native"

REG="$CAP/app/api/push/register-native/route.ts"

if grep -q "supabase.auth.getUser()" "$REG"; then
  ok "register-native: auth gate"
else
  fail "register-native: auth gate missing"
fi

if grep -q "z.string().min(1).max(500)" "$REG"; then
  ok "register-native: token whitelist (L-003)"
else
  fail "register-native: token not validated"
fi

if grep -q "z.enum(\\['ios', 'android', 'web'\\])" "$REG"; then
  ok "register-native: platform enum (L-003)"
else
  fail "register-native: platform not whitelisted"
fi

if grep -q "User mismatch" "$REG"; then
  ok "register-native: userId vs authenticated user check"
else
  fail "register-native: userId check missing"
fi

if grep -q "onConflict: 'user_id,token'" "$REG"; then
  ok "register-native: UPSERT idempotent"
else
  fail "register-native: NOT idempotent"
fi

# ── L2 — Capacitor migrations RLS ────────────────────────────────────
echo ""
echo "L2 — RLS L-001 en native_push_tokens"

CAP_SQL="$CAP/migrations/0005_native_push_tokens.sql"

if grep -q "enable row level security" "$CAP_SQL"; then
  ok "native_push_tokens: RLS habilitado"
else
  fail "RLS missing"
fi

cap_policies=$(grep -c "auth.uid() = user_id" "$CAP_SQL" || true)
if [ "$cap_policies" -ge 3 ]; then
  ok "≥3 user-scoped policies"
else
  fail "Insufficient policies (got $cap_policies)"
fi

if grep -q "for select using" "$CAP_SQL" && \
   grep -q "for insert with check" "$CAP_SQL" && \
   grep -q "for delete using" "$CAP_SQL"; then
  ok "Capacitor SQL: 3 policies (SELECT/INSERT/DELETE)"
else
  fail "Capacitor SQL: missing policies"
fi

# ── L2 — Capacitor PWA Bridge ────────────────────────────────────────
echo ""
echo "L2 — CapacitorPWABridge component"

BRIDGE="$CAP/components/CapacitorPWABridge.tsx"

if grep -q "Capacitor.isNativePlatform" "$BRIDGE"; then
  ok "bridge: native platform check"
else
  fail "bridge: native check missing"
fi

if grep -q "registerNativePush" "$BRIDGE"; then
  ok "bridge: registerNativePush invoked"
else
  fail "bridge: register missing"
fi

if grep -q "setupForegroundListener" "$BRIDGE"; then
  ok "bridge: foreground listener"
else
  fail "bridge: foreground listener missing"
fi

if grep -q "setupTapListener" "$BRIDGE"; then
  ok "bridge: tap listener (deep linking)"
else
  fail "bridge: tap listener missing"
fi

# ============================================================================
# Mode C — React Native + Expo
# ============================================================================
echo ""
echo "Mode C — React Native + Expo"
echo ""

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — Expo file presence"

expo_files=(
  "app.json"
  "eas.json"
  "lib/push/notifications.ts"
  "lib/push/server-send.ts"
  "migrations/0004b_expo_push_tokens.sql"
)
for f in "${expo_files[@]}"; do
  if [ -f "$EXPO/$f" ]; then ok "expo: $f"; else fail "expo missing: $f"; fi
done

# ── L2 — app.json ────────────────────────────────────────────────────
echo ""
echo "L2 — app.json"

# JSON valid
if node -e "JSON.parse(require('fs').readFileSync('$EXPO/app.json','utf8'))" 2>/dev/null; then
  ok "app.json valid JSON"
else
  fail "app.json invalid JSON"
fi

# Placeholders
for placeholder in "{{ APP_NAME }}" "{{ APP_SLUG }}" "{{ APP_ID }}" "{{ EAS_PROJECT_ID }}" "{{ TOKEN_PRIMARY_COLOR }}"; do
  if grep -q "$placeholder" "$EXPO/app.json"; then
    ok "app.json cites $placeholder"
  else
    fail "app.json missing $placeholder"
  fi
done

# expo-notifications plugin declared
if grep -q "expo-notifications" "$EXPO/app.json"; then
  ok "app.json: expo-notifications plugin"
else
  fail "app.json: expo-notifications missing"
fi

# iOS UIBackgroundModes
if grep -q "remote-notification" "$EXPO/app.json"; then
  ok "app.json: iOS UIBackgroundModes remote-notification"
else
  fail "app.json: UIBackgroundModes missing"
fi

# Android permissions
if grep -q "NOTIFICATIONS" "$EXPO/app.json"; then
  ok "app.json: Android NOTIFICATIONS permission"
else
  fail "app.json: NOTIFICATIONS permission missing"
fi

# ── L2 — eas.json ────────────────────────────────────────────────────
echo ""
echo "L2 — eas.json"

if node -e "JSON.parse(require('fs').readFileSync('$EXPO/eas.json','utf8'))" 2>/dev/null; then
  ok "eas.json valid JSON"
else
  fail "eas.json invalid JSON"
fi

# 3 profiles canónicos
for profile in "development" "preview" "production"; do
  if grep -q "\"$profile\":" "$EXPO/eas.json"; then
    ok "eas.json: $profile profile"
  else
    fail "eas.json: $profile profile missing"
  fi
done

# Submit config
if grep -q "submit\":" "$EXPO/eas.json"; then
  ok "eas.json: submit config"
else
  fail "eas.json: submit config missing"
fi

# autoIncrement en production
if grep -q "autoIncrement" "$EXPO/eas.json"; then
  ok "eas.json: autoIncrement in production"
else
  fail "eas.json: autoIncrement missing"
fi

# ── L2 — expo-notifications setup ────────────────────────────────────
echo ""
echo "L2 — expo-notifications setup"

NOTIF="$EXPO/lib/push/notifications.ts"

if grep -q "expo-notifications" "$NOTIF"; then
  ok "notifications: expo-notifications imported"
else
  fail "notifications: expo-notifications missing"
fi

if grep -q "Device.isDevice" "$NOTIF"; then
  ok "notifications: Device.isDevice check (NO simulator)"
else
  fail "notifications: Device.isDevice missing"
fi

if grep -q "getExpoPushTokenAsync" "$NOTIF"; then
  ok "notifications: getExpoPushTokenAsync (SDK 51+)"
else
  fail "notifications: getExpoPushTokenAsync missing"
fi

if grep -q "projectId" "$NOTIF"; then
  ok "notifications: projectId from EAS config (SDK 51+ requirement)"
else
  fail "notifications: projectId missing"
fi

if grep -q "setNotificationChannelAsync" "$NOTIF"; then
  ok "notifications: Android channel setup"
else
  fail "notifications: Android channel missing"
fi

if grep -q "setNotificationHandler" "$NOTIF"; then
  ok "notifications: foreground handler"
else
  fail "notifications: foreground handler missing"
fi

# ── L2 — server-send ─────────────────────────────────────────────────
echo ""
echo "L2 — server-send via Expo Push Service"

SEND="$EXPO/lib/push/server-send.ts"

if grep -q "exp.host/--/api/v2/push/send" "$SEND"; then
  ok "server-send: Expo Push Service endpoint"
else
  fail "server-send: endpoint missing"
fi

if grep -q "messages.slice(i, i + 100)" "$SEND" || grep -q "100" "$SEND"; then
  ok "server-send: chunking max 100 messages/request"
else
  fail "server-send: chunking missing"
fi

if grep -q "getExpoReceipts" "$SEND"; then
  ok "server-send: receipts API for delivery confirmation"
else
  fail "server-send: receipts API missing"
fi

# ── L2 — Expo migrations RLS ─────────────────────────────────────────
echo ""
echo "L2 — RLS L-001 en expo_push_tokens"

EXPO_SQL="$EXPO/migrations/0004b_expo_push_tokens.sql"

if grep -q "enable row level security" "$EXPO_SQL"; then
  ok "expo_push_tokens: RLS habilitado"
else
  fail "RLS missing"
fi

expo_policies=$(grep -c "auth.uid() = user_id" "$EXPO_SQL" || true)
if [ "$expo_policies" -ge 3 ]; then
  ok "≥3 user-scoped policies"
else
  fail "Insufficient policies (got $expo_policies)"
fi

if grep -q "platform.*in.*'ios', 'android'" "$EXPO_SQL"; then
  ok "expo_push_tokens: platform CHECK constraint"
else
  fail "expo_push_tokens: platform CHECK missing"
fi

if grep -q "on delete cascade" "$EXPO_SQL"; then
  ok "Expo SQL: FK cascade"
else
  fail "Expo SQL: FK cascade missing"
fi

if grep -q "L-001" "$EXPO_SQL"; then
  ok "Expo SQL cita L-001"
else
  fail "Expo SQL missing L-001 citation"
fi

# ============================================================================
# Cross-mode checks
# ============================================================================
echo ""
echo "Cross-mode — D-012 binary boundary"

# decision-tree.md menciona D-012 + binary
if grep -q "binary" "$SKILL_DIR/prompts/decision-tree.md"; then
  ok "decision-tree mentions binary boundary"
else
  fail "decision-tree missing binary boundary"
fi

if grep -q "NO PAUSE" "$SKILL_DIR/prompts/decision-tree.md"; then
  ok "decision-tree explicit NO PAUSE"
else
  fail "decision-tree missing NO PAUSE clarification"
fi

if grep -q "D-012" "$SKILL_DIR/prompts/decision-tree.md"; then
  ok "decision-tree cita D-012"
else
  fail "decision-tree missing D-012 citation"
fi

# Examples documenta anti-pattern PAUSE
if grep -q "PAUSE attempted\|PAUSE not applicable" "$SKILL_DIR/references/examples.md" 2>/dev/null; then
  ok "examples documenta anti-pattern PAUSE attempted"
else
  fail "examples missing anti-pattern PAUSE"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-mobile dry-run-native: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-mobile dry-run-native: $FAIL failures"
  exit 1
fi
