#!/usr/bin/env bash
# add-payments dry-run test — Mode B (Polar)
#
# Mirror del dry-run-stripe.sh adaptado a la SDK Polar.
#
# Usage: bash .claude/skills/add-payments/tests/dry-run-polar.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLAR="$SKILL_DIR/templates/polar"

echo "── add-payments dry-run-polar ──────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — Polar file presence"

polar_files=(
  "lib/polar/client.ts"
  "lib/polar/server.ts"
  "app/api/webhooks/polar/route.ts"
  "app/api/polar/checkout/route.ts"
  "app/api/polar/portal/route.ts"
  "app/api/polar/refund-request/route.ts"
  "app/(billing)/pricing/page.tsx"
  "app/(billing)/checkout/page.tsx"
  "app/(billing)/success/page.tsx"
  "app/(billing)/billing/page.tsx"
  "actions/polar.ts"
  "types/billing.ts"
  "migrations/0002_subscriptions.sql"
)
for f in "${polar_files[@]}"; do
  if [ -f "$POLAR/$f" ]; then ok "polar: $f"; else fail "polar missing: $f"; fi
done

# ── L2 — SDK shape (R13) ─────────────────────────────────────────────
echo ""
echo "L2 — Polar SDK shape (R13 [docs:polar-sdk@v0.x])"

if grep -q "import 'server-only'" "$POLAR/lib/polar/server.ts"; then
  ok "server.ts uses 'server-only' import guard"
else
  fail "server.ts missing 'server-only' guard"
fi

if grep -q "POLAR_ACCESS_TOKEN.trim()" "$POLAR/lib/polar/server.ts"; then
  ok "POLAR_ACCESS_TOKEN .trim() applied"
else
  fail "POLAR_ACCESS_TOKEN missing .trim()"
fi

if grep -q "POLAR_WEBHOOK_SECRET" "$POLAR/lib/polar/server.ts" && \
   grep -q "?\.trim()" "$POLAR/lib/polar/server.ts"; then
  ok "POLAR_WEBHOOK_SECRET .trim() applied"
else
  fail "POLAR_WEBHOOK_SECRET missing .trim()"
fi

if grep -q "isSandbox" "$POLAR/lib/polar/server.ts"; then
  ok "sandbox/production switch presente"
else
  fail "sandbox switch missing"
fi

if grep -q "ALLOWED_PRODUCT_IDS" "$POLAR/lib/polar/server.ts"; then
  ok "ALLOWED_PRODUCT_IDS whitelist exported"
else
  fail "ALLOWED_PRODUCT_IDS missing"
fi

# ── L2 — Webhook handler (L-002) ─────────────────────────────────────
echo ""
echo "L2 — Polar webhook handler (L-002 + signature)"

WEBHOOK="$POLAR/app/api/webhooks/polar/route.ts"

if grep -q "await request.text()" "$WEBHOOK"; then
  ok "webhook reads raw body via request.text()"
else
  fail "webhook missing request.text()"
fi

if grep -q "validateEvent" "$WEBHOOK" && \
   grep -q "WebhookVerificationError" "$WEBHOOK"; then
  ok "webhook uses validateEvent + WebhookVerificationError"
else
  fail "webhook missing validateEvent"
fi

if grep -q "Object.fromEntries(request.headers" "$WEBHOOK"; then
  ok "webhook converts headers to plain object"
else
  fail "webhook headers shape wrong"
fi

if grep -q "UUID_RE" "$WEBHOOK" && grep -q "safeUserId" "$WEBHOOK"; then
  ok "webhook validates metadata.user_id via UUID_RE"
else
  fail "webhook missing UUID validation"
fi

if grep -q "L-002" "$WEBHOOK"; then
  ok "webhook cites L-002"
else
  fail "webhook missing L-002 citation"
fi

# Default no-throw (excluding comments)
DEFAULT_BLOCK=$(grep -A3 "^      default:" "$WEBHOOK" | grep -vE "^\s*//|^\s*\*")
if echo "$DEFAULT_BLOCK" | grep -q "console.log" && \
   ! echo "$DEFAULT_BLOCK" | grep -E "^\s*throw\b"; then
  ok "webhook default case is no-throw"
else
  fail "webhook default case throws or missing"
fi

# Idempotency check
if grep -q "Duplicate event" "$WEBHOOK"; then
  ok "webhook has idempotency check (Duplicate event)"
else
  fail "webhook missing idempotency"
fi

# Grant access on subscription.active (event explícito Polar) — verificar que
# el case 'subscription.active' enrute a handleSubscriptionActive Y que esa
# función contenga el grant has_access = true.
if grep -A1 "case 'subscription.active':" "$WEBHOOK" | grep -q "handleSubscriptionActive" && \
   awk '/function handleSubscriptionActive/,/^}/' "$WEBHOOK" | grep -q "has_access: true"; then
  ok "webhook grants access on subscription.active event"
else
  fail "webhook may grant access on wrong event"
fi

# ── L2 — RLS L-001 en migration (compartida con Mode A) ──────────────
echo ""
echo "L2 — RLS L-001 en 0002_subscriptions.sql (Polar)"

SQL="$POLAR/migrations/0002_subscriptions.sql"

if grep -q "enable row level security" "$SQL"; then
  ok "RLS habilitado"
else
  fail "RLS missing"
fi

if grep -q "auth.uid() = user_id" "$SQL"; then
  ok "policy auth.uid() = user_id"
else
  fail "policy missing"
fi

if grep -E "for (insert|update|delete) (using|with check)" "$SQL"; then
  fail "INSERT/UPDATE/DELETE direct policies violate L-001"
else
  ok "NO INSERT/UPDATE/DELETE direct policies"
fi

if grep -q "L-001" "$SQL"; then
  ok "L-001 cited"
else
  fail "L-001 citation missing"
fi

# Provider check incluye polar
if grep -qE "provider in \('stripe', 'polar'(, 'mercadopago')?\)" "$SQL"; then
  ok "provider check incluye 'polar'"
else
  fail "provider check missing 'polar'"
fi

# ── L2 — R14 + L-003 in actions/polar.ts ─────────────────────────────
echo ""
echo "L2 — R14 + L-003 en actions/polar.ts"

ACTIONS="$POLAR/actions/polar.ts"

if grep -q "'use server'" "$ACTIONS"; then
  ok "actions has 'use server'"
else
  fail "missing 'use server'"
fi

if grep -q "z.literal('REFUND'" "$ACTIONS"; then
  ok "requestRefund con z.literal('REFUND')"
else
  fail "requestRefund missing typed confirmation"
fi

if grep -q "z.literal('CANCEL'" "$ACTIONS"; then
  ok "cancelSubscription con z.literal('CANCEL')"
else
  fail "cancelSubscription missing typed confirmation"
fi

# Polar refund reason whitelist
if grep -qE "z\.enum\(\['customer_request'" "$ACTIONS"; then
  ok "Polar refund reason z.enum whitelist"
else
  fail "Polar refund reason no whitelisted"
fi

# NO tool({ execute })
if grep -E "^export.*tool\(.*execute.*async.*(refund|cancel)" "$ACTIONS"; then
  fail "destructive tool({ execute }) — R14 violation"
else
  ok "NO tool({ execute }) en destructive (R14 PASS)"
fi

# Audit log antes de execute (Polar refunds.create)
INSERT_LINE=$(grep -n "from('refund_requests')" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "polar.refunds.create" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$INSERT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$INSERT_LINE" -lt "$EXEC_LINE" ]; then
  ok "audit log INSERT (line $INSERT_LINE) antes de polar.refunds.create (line $EXEC_LINE)"
else
  fail "audit log not before refund execute"
fi

# Ownership DB-backed (Polar uses subscriptions.user_id, not metadata) —
# line-based check: ownership query antes de refunds.create
OWN_LINE=$(grep -n "sub.user_id !== user.id" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_REFUND=$(grep -n "polar.refunds.create" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$OWN_LINE" ] && [ -n "$EXEC_REFUND" ] && [ "$OWN_LINE" -lt "$EXEC_REFUND" ]; then
  ok "ownership check (line $OWN_LINE) DB-backed antes de refund execute (line $EXEC_REFUND)"
else
  fail "ownership check missing"
fi

if grep "z.record(z.any())" "$ACTIONS"; then
  fail "actions uses forbidden z.record(z.any())"
else
  ok "no z.record(z.any())"
fi

# ── L2 — Rate limiting in checkout ────────────────────────────────────
echo ""
echo "L2 — Rate limiting on /api/polar/checkout"

CHECKOUT_API="$POLAR/app/api/polar/checkout/route.ts"
if grep -q "rateLimitOk" "$CHECKOUT_API"; then
  ok "rateLimitOk function used"
else
  fail "rate limiting missing"
fi

# ── L2 — R10 en pages ────────────────────────────────────────────────
echo ""
echo "L2 — R10 enforcement en billing pages (Polar)"

for page in pricing checkout success billing; do
  page_path="$POLAR/app/(billing)/$page/page.tsx"
  if grep -q "@/shared/components/ui" "$page_path"; then
    ok "polar/$page imports impeccable"
  else
    fail "polar/$page missing impeccable imports"
  fi
  if grep -E "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" "$page_path"; then
    fail "polar/$page Tailwind defaults (anti-slop)"
  else
    ok "polar/$page no Tailwind defaults"
  fi
  if grep -q "R10" "$page_path"; then
    ok "polar/$page cites R10"
  else
    fail "polar/$page missing R10"
  fi
done

# Polar-specific checks
if grep -q "Merchant of Record\|MoR" "$POLAR/app/(billing)/checkout/page.tsx"; then
  ok "polar/checkout menciona MoR (helps usuario entender Polar)"
else
  fail "polar/checkout no menciona MoR"
fi

if grep -q "polar.sh\|polar (Merchant\|Polar (MoR)" "$POLAR/app/(billing)/billing/page.tsx"; then
  ok "polar/billing menciona portal externo"
else
  fail "polar/billing no menciona portal externo"
fi

# ── L2 — find-docs in shared prompts (already tested in stripe) ──────
echo ""
echo "L2 — Polar-specific prompt checks"

if grep -q "Polar" "$SKILL_DIR/prompts/setup-polar.md" && \
   grep -q "validateEvent" "$SKILL_DIR/prompts/setup-polar.md"; then
  ok "setup-polar.md menciona Polar SDK + validateEvent"
else
  fail "setup-polar.md gaps"
fi

if grep -q "Merchant of Record\|MoR" "$SKILL_DIR/references/polar-patterns.md"; then
  ok "polar-patterns.md menciona MoR"
else
  fail "polar-patterns.md missing MoR"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-payments dry-run-polar: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-payments dry-run-polar: $FAIL failures"
  exit 1
fi
