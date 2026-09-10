#!/usr/bin/env bash
# add-login security pre-handoff scan
#
# Validates the security gates required before el-guardian handoff:
# 1. service_role / private key isolation
# 2. RLS L-001 in profiles SQL (Supabase)
# 3. RLS-equivalent in schema.ts (Insforge)
# 4. R14 destructive actions (deleteAccount, signOut all)
# 5. L-002 oauth payload guard
# 6. L-003 whitelist validators
#
# Usage:  bash .claude/skills/add-login/tests/security-pre-handoff.sh
# Exit 0 = all checks pass

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUPA="$SKILL_DIR/templates/supabase"
INSF="$SKILL_DIR/templates/insforge"

echo "── add-login security pre-handoff ─────────────────────────────"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── Gate 1 — service_role / private key isolation ──────────────────
echo "Gate 1 — service_role / private key isolation"

# Supabase: service_role only in lib/supabase/admin.ts
# Filter out comment lines (// ...)
violations=$(grep -rEn "service_role|SUPABASE_SERVICE_ROLE_KEY" \
  "$SUPA/app/" "$SUPA/features/" "$SUPA/lib/supabase/client.ts" "$SUPA/lib/supabase/server.ts" \
  2>/dev/null | grep -vE ":[0-9]+:\s*//" || true)

if [ -z "$violations" ]; then
  ok "Supabase: service_role NOT exposed in client/components/server/client.ts"
else
  fail "Supabase: service_role found in disallowed locations: $violations"
fi

# Supabase: service_role IS allowed in admin.ts
if grep -q "SUPABASE_SERVICE_ROLE_KEY" "$SUPA/lib/supabase/admin.ts"; then
  ok "Supabase admin.ts uses service_role (allowed, server-only)"
else
  fail "Supabase admin.ts missing service_role import"
fi

# Insforge: secret_key only in lib/insforge/admin.ts (filter comment lines)
violations=$(grep -rEn "INSFORGE_SECRET_KEY" \
  "$INSF/app/" "$INSF/features/" "$INSF/lib/insforge/client.ts" "$INSF/lib/insforge/server.ts" \
  2>/dev/null | grep -vE ":[0-9]+:\s*//" || true)
if [ -z "$violations" ]; then
  ok "Insforge: INSFORGE_SECRET_KEY NOT exposed in client/components/server/client.ts"
else
  fail "Insforge: INSFORGE_SECRET_KEY found in disallowed locations: $violations"
fi

if grep -q "INSFORGE_SECRET_KEY" "$INSF/lib/insforge/admin.ts"; then
  ok "Insforge admin.ts uses INSFORGE_SECRET_KEY (allowed, server-only)"
else
  fail "Insforge admin.ts missing INSFORGE_SECRET_KEY import"
fi

# ── Gate 2 — RLS L-001 in profiles SQL (Supabase) ──────────────────
echo ""
echo "Gate 2 — RLS L-001 in profiles SQL (Supabase)"

SQL="$SUPA/migrations/0001_profiles.sql"
grep -q "enable row level security" "$SQL" && ok "RLS habilitado" || fail "RLS missing"
grep -q "on delete cascade" "$SQL" && ok "FK on delete cascade" || fail "FK missing cascade"
[ "$(grep -c "auth.uid() = id" "$SQL")" -ge 2 ] && ok "≥2 policies con auth.uid() = id" || fail "<2 policies"
grep -q "handle_new_user" "$SQL" && ok "trigger handle_new_user" || fail "trigger missing"

# ── Gate 3 — RLS-equivalent en Insforge schema.ts ──────────────────
echo ""
echo "Gate 3 — RLS-equivalent en Insforge schema.ts"

SCH="$INSF/lib/insforge/schema.ts"
grep -q "select:.*auth.uid" "$SCH" && ok "Insforge access.select declared" || fail "Insforge access.select missing"
grep -q "update:.*auth.uid" "$SCH" && ok "Insforge access.update declared" || fail "Insforge access.update missing"
grep -q "delete: false" "$SCH" && ok "Insforge access.delete: false (R14 gated)" || fail "Insforge access.delete not guarded"
grep -q "onDelete:.*cascade" "$SCH" && ok "Insforge FK onDelete cascade" || fail "Insforge missing cascade"

# ── Gate 4 — R14 destructive actions ───────────────────────────────
echo ""
echo "Gate 4 — R14 destructive actions"

for del_path in "$SUPA/app/api/auth/delete-account/route.ts" "$INSF/app/api/auth/delete-account/route.ts"; do
  mode=$(echo "$del_path" | grep -oE "(supabase|insforge)" | head -1)
  if grep -q "REQUIRED_CONFIRMATION" "$del_path"; then
    ok "$mode deleteAccount has typed-confirmation gate"
  else
    fail "$mode deleteAccount missing confirmation gate"
  fi
  # Strip line comments before checking for execute() async
  if grep -vE "^\s*//" "$del_path" | grep -E "^\s*execute:\s*async" >/dev/null; then
    fail "$mode deleteAccount defines execute() async (R14 violation)"
  else
    ok "$mode deleteAccount: no execute() async (R14 PASS)"
  fi
done

# ── Gate 5 — L-002 oauth payload guard ─────────────────────────────
echo ""
echo "Gate 5 — L-002 oauth payload guard in callback routes"

for cb_path in "$SUPA/app/api/auth/callback/route.ts" "$INSF/app/api/auth/callback/route.ts"; do
  mode=$(echo "$cb_path" | grep -oE "(supabase|insforge)" | head -1)
  grep -q "L-002" "$cb_path" && ok "$mode callback cites L-002" || fail "$mode callback missing L-002"
  grep -q "ALLOWED_NEXT_PATHS" "$cb_path" && grep -q "safeNext" "$cb_path" \
    && ok "$mode callback has open-redirect guard (safeNext + ALLOWED_NEXT_PATHS)" \
    || fail "$mode callback missing open-redirect guard"
done

# ── Gate 6 — L-003 whitelist validators in actions/auth.ts ─────────
echo ""
echo "Gate 6 — L-003 whitelist validators in actions/auth.ts"

for action_path in "$SUPA/actions/auth.ts" "$INSF/actions/auth.ts"; do
  mode=$(echo "$action_path" | grep -oE "(supabase|insforge)" | head -1)
  grep -q "z\.string()\.email()" "$action_path" && ok "$mode actions: email whitelist" || fail "$mode actions: email missing"
  grep -q "z\.string()\.min(8)\.max(128)" "$action_path" && ok "$mode actions: password 8-128 bound" || fail "$mode actions: password not bounded"
  if grep -vE "^\s*//" "$action_path" | grep -q "z\.record(z\.any())"; then
    fail "$mode actions: forbidden z.record(z.any())"
  else
    ok "$mode actions: no z.record(z.any())"
  fi
done

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ Security pre-handoff: PASS ($PASS checks)"
  echo "   → Mandatory next: handoff a el-guardian con prompts/handoff-el-guardian.md"
  exit 0
else
  echo "❌ Security pre-handoff: $FAIL failures — BLOCKED, no handoff"
  exit 1
fi
