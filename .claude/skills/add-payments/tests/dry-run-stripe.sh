#!/usr/bin/env bash
# add-payments dry-run test — Mode A (Stripe)
#
# Validates L1 (file presence + structure) + L2 (semantics) of Mode A.
# Approach: templates ARE the expected output post-substitution.
#
# Usage: bash .claude/skills/add-payments/tests/dry-run-stripe.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRIPE="$SKILL_DIR/templates/stripe"

echo "── add-payments dry-run-stripe ─────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — Stripe file presence"

stripe_files=(
  "lib/stripe/client.ts"
  "lib/stripe/server.ts"
  "app/api/webhooks/stripe/route.ts"
  "app/api/stripe/checkout/route.ts"
  "app/api/stripe/portal/route.ts"
  "app/api/stripe/refund-request/route.ts"
  "app/(billing)/pricing/page.tsx"
  "app/(billing)/checkout/page.tsx"
  "app/(billing)/success/page.tsx"
  "app/(billing)/billing/page.tsx"
  "actions/stripe.ts"
  "types/billing.ts"
  "migrations/0002_subscriptions.sql"
)
for f in "${stripe_files[@]}"; do
  if [ -f "$STRIPE/$f" ]; then ok "stripe: $f"; else fail "stripe missing: $f"; fi
done

# ── L2 — SDK shape (R13) ─────────────────────────────────────────────
echo ""
echo "L2 — Stripe SDK shape (R13 [docs:stripe-node@v18])"

if grep -q "import 'server-only'" "$STRIPE/lib/stripe/server.ts"; then
  ok "server.ts uses 'server-only' import guard"
else
  fail "server.ts missing 'server-only' guard"
fi

if grep -q "STRIPE_SECRET_KEY.trim()" "$STRIPE/lib/stripe/server.ts"; then
  ok "STRIPE_SECRET_KEY .trim() applied"
else
  fail "STRIPE_SECRET_KEY missing .trim()"
fi

if grep -q "STRIPE_WEBHOOK_SECRET" "$STRIPE/lib/stripe/server.ts" && \
   grep -q "?\.trim()" "$STRIPE/lib/stripe/server.ts"; then
  ok "STRIPE_WEBHOOK_SECRET .trim() applied"
else
  fail "STRIPE_WEBHOOK_SECRET missing .trim()"
fi

if grep -q "apiVersion:" "$STRIPE/lib/stripe/server.ts"; then
  ok "apiVersion pinned (placeholder OK in template)"
else
  fail "apiVersion missing"
fi

if grep -q "ALLOWED_PRICE_IDS" "$STRIPE/lib/stripe/server.ts"; then
  ok "ALLOWED_PRICE_IDS whitelist exported"
else
  fail "ALLOWED_PRICE_IDS missing"
fi

# ── L2 — Webhook handler (L-002) ─────────────────────────────────────
echo ""
echo "L2 — Stripe webhook handler (L-002 + signature)"

WEBHOOK="$STRIPE/app/api/webhooks/stripe/route.ts"

# raw body antes de signature
if grep -q "await request.text()" "$WEBHOOK"; then
  ok "webhook reads raw body via request.text()"
else
  fail "webhook missing request.text()"
fi

# constructEvent presente
if grep -q "stripe.webhooks.constructEvent" "$WEBHOOK"; then
  ok "webhook uses constructEvent"
else
  fail "webhook missing constructEvent"
fi

# UUID validation en metadata
if grep -q "UUID_RE" "$WEBHOOK" && grep -q "safeUserId" "$WEBHOOK"; then
  ok "webhook validates metadata.user_id via UUID_RE"
else
  fail "webhook missing UUID validation"
fi

# L-002 cited
if grep -q "L-002" "$WEBHOOK"; then
  ok "webhook cites L-002"
else
  fail "webhook missing L-002 citation"
fi

# Default no-throw — match only switch-level default (indented 6 spaces).
# Filtrar comentarios antes de buscar throw (línea con //).
DEFAULT_BLOCK=$(grep -A3 "^      default:" "$WEBHOOK" | grep -vE "^\s*//|^\s*\*")
if echo "$DEFAULT_BLOCK" | grep -q "console.log" && \
   ! echo "$DEFAULT_BLOCK" | grep -E "^\s*throw\b"; then
  ok "webhook default case is no-throw (anti retry storm)"
else
  fail "webhook default case throws or missing"
fi

# Idempotency check
if grep -q "Duplicate event" "$WEBHOOK" || grep -q "current_period_end ===" "$WEBHOOK"; then
  ok "webhook has idempotency check"
else
  fail "webhook missing idempotency"
fi

# Acceso solo en active/trialing
if grep -B1 "has_access: true" "$WEBHOOK" | grep -qE "active|trialing"; then
  ok "webhook grants access only on active/trialing"
else
  fail "webhook may grant access on wrong status"
fi

# export const dynamic
if grep -q "export const dynamic = 'force-dynamic'" "$WEBHOOK"; then
  ok "webhook is force-dynamic"
else
  fail "webhook missing force-dynamic"
fi

# ── L2 — RLS L-001 enforcement ───────────────────────────────────────
echo ""
echo "L2 — RLS L-001 enforcement in 0002_subscriptions.sql"

SQL="$STRIPE/migrations/0002_subscriptions.sql"

if grep -q "enable row level security" "$SQL"; then
  ok "subscriptions RLS habilitado"
else
  fail "RLS missing"
fi

if grep -q "auth.uid() = user_id" "$SQL"; then
  ok "policy con auth.uid() = user_id"
else
  fail "policy missing"
fi

if grep -q "for select using" "$SQL"; then
  ok "SELECT policy presente"
else
  fail "SELECT policy missing"
fi

# NO INSERT/UPDATE/DELETE direct policies (only via service_role)
if grep -E "for (insert|update|delete) (using|with check)" "$SQL"; then
  fail "INSERT/UPDATE/DELETE direct policies violate L-001 (must be via service_role only)"
else
  ok "NO INSERT/UPDATE/DELETE direct policies"
fi

if grep -q "on delete cascade" "$SQL"; then
  ok "FK con on delete cascade"
else
  fail "FK missing cascade"
fi

if grep -q "L-001" "$SQL"; then
  ok "L-001 cited in SQL preamble"
else
  fail "L-001 citation missing"
fi

# refund_requests table
if grep -q "create table.*refund_requests" "$SQL"; then
  ok "refund_requests audit table presente"
else
  fail "refund_requests missing"
fi

if grep -q "unique (charge_id)" "$SQL"; then
  ok "refund_requests unique(charge_id) for idempotency"
else
  fail "refund_requests missing unique constraint"
fi

# ── L2 — R14 + L-003 in actions ──────────────────────────────────────
echo ""
echo "L2 — R14 + L-003 enforcement in actions/stripe.ts"

ACTIONS="$STRIPE/actions/stripe.ts"

# 'use server' directive
if grep -q "'use server'" "$ACTIONS"; then
  ok "actions has 'use server' directive"
else
  fail "actions missing 'use server'"
fi

# typed confirmation
if grep -q "z.literal('REFUND'" "$ACTIONS"; then
  ok "requestRefund has z.literal('REFUND') gate"
else
  fail "requestRefund missing typed confirmation"
fi

if grep -q "z.literal('CANCEL'" "$ACTIONS"; then
  ok "cancelSubscription has z.literal('CANCEL') gate"
else
  fail "cancelSubscription missing typed confirmation"
fi

# z.enum reason whitelist
if grep -qE "z\.enum\(\['requested_by_customer'" "$ACTIONS"; then
  ok "refund reason uses z.enum whitelist (L-003)"
else
  fail "refund reason not whitelisted"
fi

# NO tool({ execute }) en destructive
if grep -E "^export.*tool\(.*execute.*async.*(refund|cancel|transfer)" "$ACTIONS"; then
  fail "destructive tool with execute() — R14 violation"
else
  ok "NO tool({ execute }) en destructive actions (R14 PASS)"
fi

# Audit log antes de execute — buscar refund_requests insert ANTES del primer
# stripe.refunds.create en el archivo (line-number based)
INSERT_LINE=$(grep -n "from('refund_requests')" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "stripe.refunds.create" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$INSERT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$INSERT_LINE" -lt "$EXEC_LINE" ]; then
  ok "audit log INSERT (line $INSERT_LINE) antes de stripe.refunds.create (line $EXEC_LINE)"
else
  fail "audit log not before refund execute"
fi

# Default cancel = at_period_end
if grep -A3 "immediately:" "$ACTIONS" | grep -q "default(false)"; then
  ok "cancelSubscription default = at_period_end (preserva acceso)"
else
  fail "cancelSubscription default may be immediate"
fi

# z.record(z.any()) NOT used
if grep "z.record(z.any())" "$ACTIONS"; then
  fail "actions uses forbidden z.record(z.any())"
else
  ok "no z.record(z.any())"
fi

# ── L2 — Rate limiting documented in checkout ─────────────────────────
echo ""
echo "L2 — Rate limiting on /api/stripe/checkout"

CHECKOUT_API="$STRIPE/app/api/stripe/checkout/route.ts"
if grep -qE "rate.?[Ll]imit|RATE_LIMIT" "$CHECKOUT_API"; then
  ok "rate limiting documented in checkout"
else
  fail "rate limiting missing"
fi

if grep -q "rateLimitOk" "$CHECKOUT_API"; then
  ok "rateLimitOk function used"
else
  fail "rateLimitOk not invoked"
fi

# ── L2 — R10 enforcement in pages ────────────────────────────────────
echo ""
echo "L2 — R10 enforcement in billing pages (impeccable imports + no Tailwind)"

for page in pricing checkout success billing; do
  page_path="$STRIPE/app/(billing)/$page/page.tsx"
  if grep -q "@/shared/components/ui" "$page_path"; then
    ok "stripe/$page imports impeccable components"
  else
    fail "stripe/$page missing impeccable imports"
  fi
  if grep -E "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" "$page_path"; then
    fail "stripe/$page uses Tailwind purple/indigo/blue (anti-slop)"
  else
    ok "stripe/$page no Tailwind defaults"
  fi
  if grep -q "R10" "$page_path"; then
    ok "stripe/$page cites R10"
  else
    fail "stripe/$page missing R10 citation"
  fi
done

# ── L2 — find-docs invocation in prompts ─────────────────────────────
echo ""
echo "L2 — find-docs invocation in prompts (R13)"

# find-docs solo es mandatory en prompts que generan código contra SDKs.
# generate-subscription-flows.md y handoff-el-guardian.md son references /
# checklists — no generan código nuevo, consumen el output de los anteriores.
for p in setup-stripe setup-polar generate-pricing-pages generate-webhook-handler \
         generate-customer-portal; do
  if grep -q "find-docs" "$SKILL_DIR/prompts/$p.md" && \
     grep -q "resolve-library-id" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md has find-docs invocation"
  else
    fail "prompts/$p.md missing find-docs"
  fi
done

# decision-tree y handoff y subscription-flows: deben citar R13 aunque
# no inventen invocación nueva
for p in decision-tree generate-subscription-flows handoff-el-guardian; do
  if grep -q "R13" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md cita R13 (no requiere find-docs invocation directa)"
  else
    fail "prompts/$p.md missing R13 citation"
  fi
done

# ── L2 — SKILL.md citations ──────────────────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

for cite in "R-005" "R10" "R13" "R14" "L-001" "L-002" "L-003" "D-009"; do
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
  echo "✅ add-payments dry-run-stripe: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-payments dry-run-stripe: $FAIL failures"
  exit 1
fi
