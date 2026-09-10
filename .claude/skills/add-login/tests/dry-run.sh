#!/usr/bin/env bash
# add-login dry-run test — covers Mode A (Supabase) + Mode B (Insforge)
#
# Validates the L1+L2 pipeline of F3-S3 skill end-to-end.
# Approach: templates are the "expected" output (after placeholder
# substitution they emit to src/**). dry-run.sh validates the
# template files against L1 syntax + L2 schema/semantics directly.
#
# Usage:  bash .claude/skills/add-login/tests/dry-run.sh
# Exit 0 = all validations PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUPA="$SKILL_DIR/templates/supabase"
INSF="$SKILL_DIR/templates/insforge"

echo "── add-login dry-run test ─────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 Syntax — Mode A (Supabase) ──────────────────────────────────
echo "L1 — Mode A (Supabase) file presence"

supa_files=(
  "lib/supabase/client.ts"
  "lib/supabase/server.ts"
  "lib/supabase/proxy.ts"
  "lib/supabase/admin.ts"
  "proxy.ts"
  "app/(auth)/sign-in/page.tsx"
  "app/(auth)/sign-up/page.tsx"
  "app/(auth)/forgot/page.tsx"
  "app/(auth)/update-password/page.tsx"
  "app/(auth)/check-email/page.tsx"
  "app/api/auth/callback/route.ts"
  "app/api/auth/sign-out/route.ts"
  "app/api/auth/delete-account/route.ts"
  "actions/auth.ts"
  "hooks/useAuth.ts"
  "types/database.ts"
  "migrations/0001_profiles.sql"
  "features/auth/components/LoginForm.tsx"
  "features/auth/components/SignupForm.tsx"
  "features/auth/components/ForgotPasswordForm.tsx"
  "features/auth/components/UpdatePasswordForm.tsx"
  "features/auth/components/GoogleSignInButton.tsx"
  "features/auth/components/AuthDivider.tsx"
  "features/auth/components/index.ts"
)
for f in "${supa_files[@]}"; do
  if [ -f "$SUPA/$f" ]; then ok "supa: $f"; else fail "supa missing: $f"; fi
done

# ── L1 Syntax — Mode B (Insforge) ──────────────────────────────────
echo ""
echo "L1 — Mode B (Insforge) file presence"

insf_files=(
  "lib/insforge/client.ts"
  "lib/insforge/server.ts"
  "lib/insforge/proxy.ts"
  "lib/insforge/admin.ts"
  "lib/insforge/schema.ts"
  "proxy.ts"
  "app/(auth)/sign-in/page.tsx"
  "app/(auth)/sign-up/page.tsx"
  "app/(auth)/forgot/page.tsx"
  "app/(auth)/update-password/page.tsx"
  "app/(auth)/check-email/page.tsx"
  "app/api/auth/callback/route.ts"
  "app/api/auth/sign-out/route.ts"
  "app/api/auth/delete-account/route.ts"
  "actions/auth.ts"
  "hooks/useAuth.ts"
  "types/database.ts"
  "features/auth/components/LoginForm.tsx"
  "features/auth/components/SignupForm.tsx"
  "features/auth/components/ForgotPasswordForm.tsx"
  "features/auth/components/UpdatePasswordForm.tsx"
  "features/auth/components/GoogleSignInButton.tsx"
  "features/auth/components/AuthDivider.tsx"
  "features/auth/components/index.ts"
)
for f in "${insf_files[@]}"; do
  if [ -f "$INSF/$f" ]; then ok "insf: $f"; else fail "insf missing: $f"; fi
done

# ── L2 Runtime — Supabase SSR shape (R13) ──────────────────────────
echo ""
echo "L2 — Supabase SSR shape (R13)"

# server.ts uses getAll/setAll, NOT get/set/remove
if grep -q "getAll" "$SUPA/lib/supabase/server.ts" && grep -q "setAll" "$SUPA/lib/supabase/server.ts"; then
  ok "server.ts uses getAll/setAll (R13 supabase-ssr@latest)"
else
  fail "server.ts missing getAll/setAll"
fi
if grep -qE "^\s*(get|set|remove)\(" "$SUPA/lib/supabase/server.ts"; then
  fail "server.ts uses deprecated get/set/remove shape"
else
  ok "server.ts no deprecated get/set/remove"
fi

# proxy.ts uses getUser, NOT getSession
if grep -q "auth.getUser" "$SUPA/lib/supabase/proxy.ts" && ! grep -q "auth.getSession" "$SUPA/lib/supabase/proxy.ts"; then
  ok "proxy.ts uses getUser (validated), not getSession"
else
  fail "proxy.ts uses getSession or missing getUser"
fi

# client.ts uses createBrowserClient
if grep -q "createBrowserClient" "$SUPA/lib/supabase/client.ts"; then
  ok "client.ts uses createBrowserClient"
else
  fail "client.ts missing createBrowserClient"
fi

# ── L2 Runtime — RLS L-001 enforcement in profiles SQL ─────────────
echo ""
echo "L2 — RLS L-001 enforcement in profiles SQL"

SQL="$SUPA/migrations/0001_profiles.sql"
if grep -q "enable row level security" "$SQL"; then
  ok "RLS habilitado"
else
  fail "RLS missing"
fi

if [ "$(grep -c "auth.uid() = id" "$SQL")" -ge 2 ]; then
  ok "≥2 policies con auth.uid() = id"
else
  fail "<2 policies"
fi

if grep -q "on delete cascade" "$SQL"; then
  ok "FK con on delete cascade"
else
  fail "FK missing on delete cascade"
fi

if grep -q "handle_new_user" "$SQL" && grep -q "after insert on auth.users" "$SQL"; then
  ok "trigger handle_new_user defined"
else
  fail "trigger missing"
fi

if grep -A 16 "function public.handle_new_user" "$SQL" | grep -q "security definer"; then
  ok "handle_new_user is security definer"
else
  fail "handle_new_user not security definer (trigger won't bypass RLS at signup)"
fi

if grep -q "L-001" "$SQL"; then
  ok "L-001 cited in SQL preamble"
else
  fail "L-001 citation missing in SQL"
fi

# ── L2 Runtime — Insforge schema declarative L-001-equivalent ──────
echo ""
echo "L2 — Insforge schema declarative L-001-equivalent"

SCH="$INSF/lib/insforge/schema.ts"
if grep -q "select:.*auth.uid" "$SCH" && grep -q "update:.*auth.uid" "$SCH"; then
  ok "Insforge schema access policies (select+update) declared"
else
  fail "Insforge schema missing access policies"
fi
if grep -q "delete: false" "$SCH"; then
  ok "Insforge schema delete: false (R14 gated route only)"
else
  fail "Insforge schema missing delete: false guard"
fi
if grep -q "L-001" "$SCH"; then
  ok "L-001 cited in schema.ts"
else
  fail "L-001 citation missing in schema.ts"
fi

# ── L2 Runtime — L-002 in callback routes ──────────────────────────
echo ""
echo "L2 — L-002 in callback routes (oauth payload as data)"

for mode_path in "$SUPA/app/api/auth/callback/route.ts" "$INSF/app/api/auth/callback/route.ts"; do
  if grep -q "L-002" "$mode_path"; then
    ok "$(basename $(dirname $(dirname $(dirname $(dirname $mode_path))))) callback cites L-002"
  else
    fail "$mode_path missing L-002 citation"
  fi
  if grep -q "ALLOWED_NEXT_PATHS" "$mode_path" && grep -q "safeNext" "$mode_path"; then
    ok "$(basename $(dirname $(dirname $(dirname $(dirname $mode_path))))) callback has open-redirect guard"
  else
    fail "$mode_path missing safeNext / ALLOWED_NEXT_PATHS"
  fi
done

# ── L2 Runtime — L-003 whitelist in actions/auth.ts ────────────────
echo ""
echo "L2 — L-003 whitelist validation in actions/auth.ts"

for action_path in "$SUPA/actions/auth.ts" "$INSF/actions/auth.ts"; do
  if grep -q "z\.string()\.email()" "$action_path"; then
    ok "$(basename $(dirname $(dirname $action_path))) actions: email schema z.string().email()"
  else
    fail "$action_path missing email whitelist"
  fi
  if grep -q "z\.string()\.min(8)\.max(128)" "$action_path"; then
    ok "$(basename $(dirname $(dirname $action_path))) actions: password 8-128 bound"
  else
    fail "$action_path password not bounded 8-128"
  fi
  # exclude comment lines (lines starting with //)
  if grep -vE "^\s*//" "$action_path" | grep -q "z\.record(z\.any())"; then
    fail "$action_path uses forbidden z.record(z.any())"
  else
    ok "$(basename $(dirname $(dirname $action_path))) actions: no z.record(z.any())"
  fi
done

# ── L2 Runtime — R14 destructive actions ───────────────────────────
echo ""
echo "L2 — R14 destructive actions (deleteAccount typed-confirmation)"

for del_path in "$SUPA/app/api/auth/delete-account/route.ts" "$INSF/app/api/auth/delete-account/route.ts"; do
  if grep -q "REQUIRED_CONFIRMATION" "$del_path"; then
    ok "$(basename $(dirname $(dirname $(dirname $(dirname $del_path))))) deleteAccount: typed confirmation gate"
  else
    fail "$del_path missing typed confirmation gate"
  fi
  if grep -q "R14" "$del_path"; then
    ok "$(basename $(dirname $(dirname $(dirname $(dirname $del_path))))) deleteAccount cites R14"
  else
    fail "$del_path missing R14 citation"
  fi
  # No agentic execute()
  if grep -E "^\s*execute:\s*async" "$del_path"; then
    fail "$del_path defines execute() async (R14 violation)"
  else
    ok "$(basename $(dirname $(dirname $(dirname $(dirname $del_path))))) deleteAccount: no execute() async"
  fi
done

# ── L2 Runtime — R10 enforcement in auth pages ─────────────────────
echo ""
echo "L2 — R10 enforcement in auth pages (impeccable component imports)"

for page in sign-in sign-up forgot update-password check-email; do
  for mode in supabase insforge; do
    page_path="$SKILL_DIR/templates/$mode/app/(auth)/$page/page.tsx"
    if grep -q "@/shared/components/ui" "$page_path"; then
      ok "$mode/$page imports impeccable ui components"
    else
      fail "$mode/$page missing impeccable imports"
    fi
    # No Tailwind purple/indigo
    if grep -E "(bg|text)-(purple|indigo|violet)-[0-9]+" "$page_path" >/dev/null; then
      fail "$mode/$page uses Tailwind purple/indigo (anti-slop violation)"
    else
      ok "$mode/$page no purple/indigo defaults"
    fi
    # R10 cited
    if grep -q "R10" "$page_path"; then
      ok "$mode/$page cites R10"
    else
      fail "$mode/$page missing R10 citation"
    fi
  done
done

# ── L2 Runtime — R10 enforcement in form components ────────────────
echo ""
echo "L2 — R10 enforcement in form components"

for form in LoginForm SignupForm ForgotPasswordForm UpdatePasswordForm GoogleSignInButton; do
  for mode in supabase insforge; do
    form_path="$SKILL_DIR/templates/$mode/features/auth/components/$form.tsx"
    if grep -q "@/shared/components/ui" "$form_path"; then
      ok "$mode/$form imports impeccable Button/Input"
    else
      fail "$mode/$form missing impeccable imports"
    fi
  done
done

# ── L2 Runtime — find-docs invocation in prompts (R13) ─────────────
echo ""
echo "L2 — find-docs invocation header in prompts (R13)"

for p in setup-supabase-auth setup-insforge-auth generate-auth-pages generate-profiles-migration generate-oauth-config; do
  if grep -q "find-docs" "$SKILL_DIR/prompts/$p.md" && grep -q "resolve-library-id" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md has find-docs invocation"
  else
    fail "prompts/$p.md missing find-docs"
  fi
done

# ── L2 Runtime — Schema R-005 v1.1.0 contract awareness ─────────────
echo ""
echo "L2 — Schema R-005 contract awareness"

if grep -q "R-005" "$SKILL_DIR/SKILL.md"; then ok "SKILL.md cites R-005"; else fail "SKILL.md no R-005 cite"; fi
if grep -q "R10" "$SKILL_DIR/SKILL.md"; then ok "SKILL.md cites R10"; else fail "SKILL.md no R10 cite"; fi
if grep -q "R14" "$SKILL_DIR/SKILL.md"; then ok "SKILL.md cites R14"; else fail "SKILL.md no R14 cite"; fi

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-login dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-login dry-run: $FAIL failures"
  exit 1
fi
