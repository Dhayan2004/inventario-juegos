#!/usr/bin/env bash
# add-emails dry-run test — Mode A (Resend)
#
# Validates L1 (file presence + structure) + L2 (semantics) of Mode A.
# Approach: templates ARE the expected output post-substitution. Tokens
# y copy keys quedan como `{{ TOKEN_* }}` / `{{ COPY_* }}` placeholders
# (substituidos al apply al target project) y deben verificarse así.
#
# Usage: bash .claude/skills/add-emails/tests/dry-run-resend.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESEND="$SKILL_DIR/templates/resend"

echo "── add-emails dry-run-resend ───────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — Resend file presence"

resend_files=(
  "lib/resend/client.ts"
  "lib/resend/server.ts"
  "emails/Welcome.tsx"
  "emails/MagicLink.tsx"
  "emails/PasswordReset.tsx"
  "emails/InvoiceReceipt.tsx"
  "emails/PaymentFailed.tsx"
  "emails/SubscriptionCanceled.tsx"
  "emails/EmailChangedConfirmation.tsx"
  "emails/index.ts"
  "app/api/email/send/route.ts"
  "app/api/email/unsubscribe/route.ts"
  "app/api/email/suppression-webhook/route.ts"
  "actions/email.ts"
  "migrations/0003_email_subscriptions.sql"
)
for f in "${resend_files[@]}"; do
  if [ -f "$RESEND/$f" ]; then ok "resend: $f"; else fail "resend missing: $f"; fi
done

# ── L1 — 7 React Email templates con shape canónico ─────────────────
echo ""
echo "L1 — 7 canonical React Email templates"

emails=(Welcome MagicLink PasswordReset InvoiceReceipt PaymentFailed SubscriptionCanceled EmailChangedConfirmation)
for em in "${emails[@]}"; do
  f="$RESEND/emails/$em.tsx"
  # Import @react-email/components
  if grep -q "@react-email/components" "$f"; then
    ok "$em imports @react-email/components"
  else
    fail "$em missing @react-email/components import"
  fi
  # Tipo Props exportado
  if grep -qE "export interface ${em}EmailProps" "$f"; then
    ok "$em exports ${em}EmailProps"
  else
    fail "$em missing Props interface"
  fi
  # Tokens R10 placeholders
  if grep -q "TOKEN_COLORS_PRIMARY" "$f"; then
    ok "$em consumes TOKEN_COLORS_PRIMARY (R10)"
  else
    fail "$em missing TOKEN_COLORS_PRIMARY placeholder"
  fi
  # R-005 contexts.transactional_email — fallback fonts Arial/Helvetica
  if grep -q "Arial, Helvetica" "$f"; then
    ok "$em uses Arial/Helvetica fallback (R-005)"
  else
    fail "$em missing Arial/Helvetica fallback"
  fi
  # Cita R10
  if grep -q "R10" "$f"; then
    ok "$em cites R10"
  else
    fail "$em missing R10 citation"
  fi
  # NO Tailwind hardcoded class names (anti-slop)
  if grep -E "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" "$f"; then
    fail "$em uses Tailwind purple/indigo/violet/blue (anti-slop)"
  else
    ok "$em no Tailwind defaults"
  fi
done

# ── L2 — SDK shape (R13) ─────────────────────────────────────────────
echo ""
echo "L2 — Resend SDK shape (R13 [docs:resend])"

if grep -q "import 'server-only'" "$RESEND/lib/resend/server.ts"; then
  ok "server.ts uses 'server-only' import guard"
else
  fail "server.ts missing 'server-only' guard"
fi

if grep -q "RESEND_API_KEY.trim()" "$RESEND/lib/resend/server.ts"; then
  ok "RESEND_API_KEY .trim() applied"
else
  fail "RESEND_API_KEY missing .trim()"
fi

if grep "RESEND_WEBHOOK_SECRET" "$RESEND/lib/resend/server.ts" | grep -q "\.trim()"; then
  ok "RESEND_WEBHOOK_SECRET .trim() applied"
else
  fail "RESEND_WEBHOOK_SECRET missing .trim()"
fi

if grep -q "ALLOWED_TEMPLATE_IDS" "$RESEND/lib/resend/server.ts"; then
  ok "ALLOWED_TEMPLATE_IDS whitelist exported"
else
  fail "ALLOWED_TEMPLATE_IDS missing"
fi

if grep -q "ALLOWED_LOCALES" "$RESEND/lib/resend/server.ts"; then
  ok "ALLOWED_LOCALES whitelist exported"
else
  fail "ALLOWED_LOCALES missing"
fi

# RESEND_API_KEY ausente del client.ts
if grep -q "RESEND_API_KEY" "$RESEND/lib/resend/client.ts"; then
  fail "RESEND_API_KEY EN client.ts (CRITICAL leak)"
else
  ok "RESEND_API_KEY ausente de client.ts"
fi

# ── L2 — Send route ─────────────────────────────────────────────────
echo ""
echo "L2 — /api/email/send route (rate limit + suppression + RFC 8058)"

SEND="$RESEND/app/api/email/send/route.ts"

if grep -qE "RATE_LIMIT|rateLimitOk" "$SEND"; then
  ok "send: rate limiting"
else
  fail "send: rate limiting missing"
fi

if grep -q "isSuppressed" "$SEND"; then
  ok "send: pre-send suppression check"
else
  fail "send: suppression check missing"
fi

if grep -q "List-Unsubscribe-Post" "$SEND"; then
  ok "send: RFC 8058 List-Unsubscribe-Post header"
else
  fail "send: RFC 8058 header missing"
fi

if grep -q "z.enum(ALLOWED_TEMPLATE_IDS)" "$SEND"; then
  ok "send: templateId via z.enum (L-003)"
else
  fail "send: templateId not whitelisted"
fi

if grep -q "z.string().email()" "$SEND"; then
  ok "send: to via z.string().email()"
else
  fail "send: to not validated"
fi

# Auth gate
if grep -q "supabase.auth.getUser()" "$SEND"; then
  ok "send: auth gate"
else
  fail "send: missing auth gate"
fi

# ── L2 — Unsubscribe route (RFC 8058) ───────────────────────────────
echo ""
echo "L2 — /api/email/unsubscribe (RFC 8058 GET+POST)"

UNSUB="$RESEND/app/api/email/unsubscribe/route.ts"

if grep -q "export async function GET" "$UNSUB"; then
  ok "unsubscribe: GET handler"
else
  fail "unsubscribe: missing GET"
fi

if grep -q "export async function POST" "$UNSUB"; then
  ok "unsubscribe: POST handler (RFC 8058)"
else
  fail "unsubscribe: missing POST"
fi

if grep -q "jwtVerify" "$UNSUB"; then
  ok "unsubscribe: JWT verification"
else
  fail "unsubscribe: missing JWT verify"
fi

# ── L2 — Webhook handler (L-002 + signature first) ──────────────────
echo ""
echo "L2 — Resend webhook (Svix HMAC + L-002)"

WH="$RESEND/app/api/email/suppression-webhook/route.ts"

if grep -q "await request.text()" "$WH"; then
  ok "webhook: raw body via request.text()"
else
  fail "webhook: missing raw body"
fi

if grep -q "Webhook(RESEND_WEBHOOK_SECRET)" "$WH"; then
  ok "webhook: Svix Webhook init"
else
  fail "webhook: Svix init missing"
fi

# raw body antes de verify
RAW_LINE=$(grep -n "await request.text()" "$WH" | head -1 | cut -d: -f1)
VERIFY_LINE=$(grep -n "wh.verify(" "$WH" | head -1 | cut -d: -f1)
if [ -n "$RAW_LINE" ] && [ -n "$VERIFY_LINE" ] && [ "$RAW_LINE" -lt "$VERIFY_LINE" ]; then
  ok "webhook: raw body (L$RAW_LINE) antes de verify (L$VERIFY_LINE)"
else
  fail "webhook: order incorrect (raw=$RAW_LINE verify=$VERIFY_LINE)"
fi

# 401 on bad signature
if grep -A6 "Resend signature verification failed\|catch (err)" "$WH" | grep -qE "status: 401"; then
  ok "webhook: 401 FAIL FAST on bad signature"
else
  fail "webhook: missing 401 on bad sig"
fi

# Idempotency
if grep -q "external_event_id" "$WH"; then
  ok "webhook: idempotency via external_event_id"
else
  fail "webhook: idempotency missing"
fi

# Switch event types whitelist
if grep -qE "case 'email\.bounced'" "$WH"; then
  ok "webhook: switch incluye email.bounced"
else
  fail "webhook: missing email.bounced case"
fi

if grep -qE "case 'email\.complained'" "$WH"; then
  ok "webhook: switch incluye email.complained"
else
  fail "webhook: missing email.complained case"
fi

# Default no-throw
DEFAULT_BLOCK=$(grep -A2 "^    default:" "$WH" | grep -vE "^\s*//|^\s*\*")
if ! echo "$DEFAULT_BLOCK" | grep -E "^\s*throw\b"; then
  ok "webhook: default no-throw (anti retry storm)"
else
  fail "webhook: default may throw"
fi

# force-dynamic
if grep -q "export const dynamic = 'force-dynamic'" "$WH"; then
  ok "webhook: force-dynamic"
else
  fail "webhook: missing force-dynamic"
fi

# L-002 cited
if grep -q "L-002" "$WH"; then
  ok "webhook: cita L-002"
else
  fail "webhook: missing L-002"
fi

# ── L2 — Actions L-003 + R14 ────────────────────────────────────────
echo ""
echo "L2 — actions/email.ts (L-003 whitelists + R14 typed-confirm gates)"

ACTIONS="$RESEND/actions/email.ts"

if grep -q "'use server'" "$ACTIONS"; then
  ok "actions: 'use server' directive"
else
  fail "actions: missing 'use server'"
fi

# Typed confirmations
if grep -q "z.literal('BULK_UNSUBSCRIBE'" "$ACTIONS"; then
  ok "actions: bulkUnsubscribe typed-confirm gate"
else
  fail "actions: bulkUnsubscribe missing typed-confirm"
fi

if grep -q "z.literal('DELETE_SUPPRESSION'" "$ACTIONS"; then
  ok "actions: deleteSuppressionEntry typed-confirm gate"
else
  fail "actions: deleteSuppressionEntry missing typed-confirm"
fi

if grep -q "z.literal('RESEND_CAMPAIGN'" "$ACTIONS"; then
  ok "actions: resendCampaign typed-confirm gate"
else
  fail "actions: resendCampaign missing typed-confirm"
fi

# NO tool({ execute }) destructive
if grep -E "^export.*tool\(.*execute.*async.*(bulk|delete|resend)" "$ACTIONS"; then
  fail "actions: destructive tool({ execute }) — R14 CRITICAL violation"
else
  ok "actions: NO tool({ execute }) en destructive (R14 PASS)"
fi

# Admin role gate
if grep -q "profile?.role !== 'admin'" "$ACTIONS"; then
  ok "actions: admin role gate"
else
  fail "actions: admin role gate missing"
fi

# Audit log antes de execute (bulkUnsubscribe)
INSERT_LINE=$(grep -n "from('email_admin_actions')" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "from('email_subscriptions')" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$INSERT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$INSERT_LINE" -lt "$EXEC_LINE" ]; then
  ok "actions: audit log (L$INSERT_LINE) antes de execute (L$EXEC_LINE)"
else
  fail "actions: audit log NOT before execute"
fi

# z.enum reasons
if grep -qE "z\.enum\(\[.admin_compliance" "$ACTIONS"; then
  ok "actions: bulkUnsubscribe reason whitelist (L-003)"
else
  fail "actions: bulkUnsubscribe reason not whitelisted"
fi

# z.record(z.any()) NOT used
if grep "z.record(z.any())" "$ACTIONS"; then
  fail "actions: forbidden z.record(z.any())"
else
  ok "actions: no z.record(z.any())"
fi

# ── L2 — RLS L-001 enforcement ──────────────────────────────────────
echo ""
echo "L2 — RLS L-001 en 0003_email_subscriptions.sql"

SQL="$RESEND/migrations/0003_email_subscriptions.sql"

if grep -q "enable row level security" "$SQL"; then
  ok "email_subscriptions: RLS habilitado"
else
  fail "RLS missing"
fi

if grep -q "auth.uid() = user_id" "$SQL"; then
  ok "policy auth.uid() = user_id"
else
  fail "policy missing"
fi

if grep -q "for select using" "$SQL"; then
  ok "SELECT policy presente"
else
  fail "SELECT policy missing"
fi

# NO INSERT/UPDATE/DELETE direct policies en email_subscriptions
if grep -E "for (insert|update|delete) (using|with check)" "$SQL" | grep -v "email_admin_actions"; then
  fail "INSERT/UPDATE/DELETE direct policies (L-001 violation)"
else
  ok "NO INSERT/UPDATE/DELETE direct policies (service_role only)"
fi

if grep -q "on delete cascade" "$SQL"; then
  ok "FK con cascade"
else
  fail "FK missing cascade"
fi

# L-001 cita
if grep -q "L-001" "$SQL"; then
  ok "L-001 cited en SQL preamble"
else
  fail "L-001 citation missing"
fi

# email_admin_actions table presente (R14 audit)
if grep -q "create table.*email_admin_actions" "$SQL"; then
  ok "email_admin_actions audit table presente (R14)"
else
  fail "email_admin_actions missing"
fi

# suppression_list table presente
if grep -q "create table.*suppression_list" "$SQL"; then
  ok "suppression_list table presente"
else
  fail "suppression_list missing"
fi

# email_events table presente
if grep -q "create table.*email_events" "$SQL"; then
  ok "email_events table presente"
else
  fail "email_events missing"
fi

# profiles.role extension
if grep -q "add column if not exists role" "$SQL"; then
  ok "profiles.role extension presente (admin gate)"
else
  fail "profiles.role missing"
fi

# ── L2 — find-docs invocation in prompts (R13) ──────────────────────
echo ""
echo "L2 — find-docs invocation in prompts (R13)"

# Solo prompts que generan código contra SDKs externos
for p in setup-resend setup-sendgrid generate-templates generate-unsubscribe \
         generate-suppression-list; do
  if grep -q "find-docs\|resolve-library-id" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md has find-docs invocation"
  else
    fail "prompts/$p.md missing find-docs"
  fi
done

# decision-tree y handoff: deben citar R13 (literal o como range R10..14, R11..14, R12..14, R13..14)
for p in decision-tree handoff-el-guardian; do
  if grep -qE "R13|R(10|11|12|13)\.\.14" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md cita R13 (literal o range)"
  else
    fail "prompts/$p.md missing R13 citation"
  fi
done

# ── L2 — SKILL.md citations completas ───────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

for cite in "R-005" "R10" "R13" "R14" "L-001" "L-002" "L-003" "D-010" "D-011"; do
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
  echo "✅ add-emails dry-run-resend: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-emails dry-run-resend: $FAIL failures"
  exit 1
fi
