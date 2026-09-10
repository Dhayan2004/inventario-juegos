#!/usr/bin/env bash
# add-payments security pre-handoff test
#
# Cubre los 10 gates del checklist handoff-el-guardian.md aplicados a los
# templates de Stripe + Polar. Es el L3 system check del Three-Layer
# Verification — se corre tras dry-run-stripe + dry-run-polar pasen.
#
# Usage: bash .claude/skills/add-payments/tests/security-pre-handoff.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STRIPE="$SKILL_DIR/templates/stripe"
POLAR="$SKILL_DIR/templates/polar"
MP="$SKILL_DIR/templates/mercadopago"

# Mode C (Mercado Pago) usa prefijo MP_ (MP_ACCESS_TOKEN / MP_WEBHOOK_SECRET) — D-038
env_prefix() { case "$1" in mercadopago) echo "MP" ;; *) echo "$1" | tr '[:lower:]' '[:upper:]' ;; esac; }

echo "── add-payments security pre-handoff ──────────────────────────"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ─────────────────────────────────────────────────────────────────────
# Gate 1 — Secret isolation
# ─────────────────────────────────────────────────────────────────────
echo "Gate 1 — Secret isolation"

# Stripe — STRIPE_SECRET_KEY only en server.ts
if grep -rn "STRIPE_SECRET_KEY" "$STRIPE/app/(billing)/" 2>/dev/null; then
  fail "STRIPE_SECRET_KEY exposed en client pages"
else
  ok "STRIPE_SECRET_KEY no aparece en app/(billing)/"
fi

if grep -q "STRIPE_SECRET_KEY" "$STRIPE/lib/stripe/server.ts"; then
  ok "STRIPE_SECRET_KEY presente en lib/stripe/server.ts"
else
  fail "STRIPE_SECRET_KEY missing en server lib"
fi

if grep -q "STRIPE_SECRET_KEY" "$STRIPE/lib/stripe/client.ts"; then
  fail "STRIPE_SECRET_KEY EN client.ts (CRITICAL leak)"
else
  ok "STRIPE_SECRET_KEY ausente de client.ts"
fi

# Polar — POLAR_ACCESS_TOKEN only en server.ts
if grep -rn "POLAR_ACCESS_TOKEN" "$POLAR/app/(billing)/" 2>/dev/null; then
  fail "POLAR_ACCESS_TOKEN exposed en client pages"
else
  ok "POLAR_ACCESS_TOKEN no aparece en app/(billing)/"
fi

if grep -q "POLAR_ACCESS_TOKEN" "$POLAR/lib/polar/server.ts"; then
  ok "POLAR_ACCESS_TOKEN en lib/polar/server.ts"
else
  fail "POLAR_ACCESS_TOKEN missing en server lib"
fi

if grep -q "POLAR_ACCESS_TOKEN" "$POLAR/lib/polar/client.ts" 2>/dev/null; then
  fail "POLAR_ACCESS_TOKEN EN client.ts (leak)"
else
  ok "POLAR_ACCESS_TOKEN ausente de client.ts"
fi

# Mercado Pago (Mode C)
if grep -q "MP_ACCESS_TOKEN" "$MP/lib/mercadopago/server.ts"; then
  ok "MP_ACCESS_TOKEN en lib/mercadopago/server.ts"
else
  fail "MP_ACCESS_TOKEN missing en server lib"
fi
if grep -q "MP_ACCESS_TOKEN" "$MP/lib/mercadopago/client.ts" 2>/dev/null; then
  fail "MP_ACCESS_TOKEN EN client.ts (leak)"
else
  ok "MP_ACCESS_TOKEN ausente de client.ts"
fi
if grep -rn "MP_ACCESS_TOKEN" "$MP/app/(billing)/" 2>/dev/null; then
  fail "MP_ACCESS_TOKEN leaked en (billing) pages"
else
  ok "MP_ACCESS_TOKEN ausente de (billing) pages"
fi

# Webhook secrets también server-only
for provider in stripe polar mercadopago; do
  upper=$(env_prefix "$provider")
  varname="${upper}_WEBHOOK_SECRET"
  if grep -rn "$varname" "$SKILL_DIR/templates/$provider/app/" 2>/dev/null | grep -v "webhooks/$provider/route.ts"; then
    fail "$varname leaked en $provider client/api"
  else
    ok "$varname server-only ($provider)"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 2 — Webhook signature verification
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 2 — Webhook signature verification (raw body + .trim() + FAIL FAST)"

for provider in stripe polar mercadopago; do
  WH="$SKILL_DIR/templates/$provider/app/api/webhooks/$provider/route.ts"

  # Raw body antes de signature
  if grep -q "await request.text()" "$WH"; then
    ok "$provider webhook usa request.text() raw body"
  else
    fail "$provider webhook missing raw body"
  fi

  # NO request.json() before verify — buscar invocación (no import) de
  # constructEvent / validateEvent. Excluir línea de import.
  RAW_LINE=$(grep -n "await request.text()" "$WH" | head -1 | cut -d: -f1)
  VERIFY_LINE=$(grep -nE "(constructEvent|validateEvent|verifyMpSignature)\(" "$WH" | grep -v "^[0-9]*:import" | head -1 | cut -d: -f1)
  if [ -n "$RAW_LINE" ] && [ -n "$VERIFY_LINE" ] && [ "$RAW_LINE" -lt "$VERIFY_LINE" ]; then
    ok "$provider webhook: raw body (line $RAW_LINE) antes de verify (line $VERIFY_LINE)"
  else
    fail "$provider webhook: order incorrect (raw=$RAW_LINE verify=$VERIFY_LINE)"
  fi

  # FAIL FAST (400 Stripe / 400 Mercado Pago / 403 Polar) — buscar status code dentro del catch
  if [ "$provider" = "stripe" ]; then
    if grep -A6 "constructEvent" "$WH" | grep -qE "status: 400"; then
      ok "$provider webhook FAIL FAST 400 on bad signature"
    else
      fail "$provider webhook missing 400 on bad signature"
    fi
  elif [ "$provider" = "mercadopago" ]; then
    if grep -A10 "verifyMpSignature({" "$WH" | grep -qE "status: 400"; then
      ok "$provider webhook FAIL FAST 400 on bad signature (manifest + timingSafeEqual + ventana 300 s)"
    else
      fail "$provider webhook missing 400 on bad signature"
    fi
  else
    if grep -A6 "WebhookVerificationError" "$WH" | grep -qE "status: 403"; then
      ok "$provider webhook FAIL FAST 403 on bad signature"
    else
      fail "$provider webhook missing 403"
    fi
  fi
done

# .trim() en lib level
for provider in stripe polar mercadopago; do
  upper=$(env_prefix "$provider")
  varname="${upper}_WEBHOOK_SECRET"
  if grep "$varname" "$SKILL_DIR/templates/$provider/lib/$provider/server.ts" | grep -q "\.trim()"; then
    ok "$varname con .trim()"
  else
    fail "$varname missing .trim() (silent signature failure risk)"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 3 — RLS en subscriptions (L-001)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 3 — RLS L-001 en subscriptions"

for provider in stripe polar mercadopago; do
  SQL="$SKILL_DIR/templates/$provider/migrations/0002_subscriptions.sql"

  if grep -q "enable row level security" "$SQL"; then
    ok "$provider: RLS habilitado"
  else
    fail "$provider: RLS missing"
  fi

  if grep -q "auth.uid() = user_id" "$SQL"; then
    ok "$provider: policy auth.uid() = user_id"
  else
    fail "$provider: policy missing"
  fi

  if grep -E "for (insert|update|delete) (using|with check)" "$SQL"; then
    fail "$provider: INSERT/UPDATE/DELETE direct policies (L-001 violation)"
  else
    ok "$provider: NO INSERT/UPDATE/DELETE direct (service_role only)"
  fi

  if grep -q "on delete cascade" "$SQL"; then
    ok "$provider: FK cascade"
  else
    fail "$provider: FK missing cascade"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 4 — R14 destructive sin execute()
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 4 — R14 destructive actions sin execute() automático"

for provider in stripe polar mercadopago; do
  ACTIONS="$SKILL_DIR/templates/$provider/actions/$provider.ts"

  # NO tool({ execute }) en refund/cancel
  if grep -E "^export.*tool\(.*execute.*async.*(refund|cancel|transfer)" "$ACTIONS"; then
    fail "$provider: destructive tool({ execute }) — R14 CRITICAL violation"
  else
    ok "$provider: NO tool({ execute }) en destructive (R14 PASS)"
  fi

  # Typed confirmation REFUND
  if grep -q "z.literal('REFUND'" "$ACTIONS"; then
    ok "$provider: requestRefund typed confirmation"
  else
    fail "$provider: requestRefund missing typed-confirm"
  fi

  # Typed confirmation CANCEL
  if grep -q "z.literal('CANCEL'" "$ACTIONS"; then
    ok "$provider: cancelSubscription typed confirmation"
  else
    fail "$provider: cancelSubscription missing typed-confirm"
  fi

  # Audit log antes de execute
  AUDIT_LINE=$(grep -n "from('refund_requests')" "$ACTIONS" | head -1 | cut -d: -f1)
  EXEC_LINE=$(grep -nE "$provider\.refunds\.create|mpRefund\.create" "$ACTIONS" | head -1 | cut -d: -f1)
  if [ -n "$AUDIT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$AUDIT_LINE" -lt "$EXEC_LINE" ]; then
    ok "$provider: audit log antes de refund execute"
  else
    fail "$provider: audit log NOT before execute (R14 violation)"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 5 — L-002 webhook payload as data
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 5 — L-002 enforcement en webhook handlers"

for provider in stripe polar mercadopago; do
  WH="$SKILL_DIR/templates/$provider/app/api/webhooks/$provider/route.ts"

  if grep -q "L-002" "$WH"; then
    ok "$provider webhook cita L-002"
  else
    fail "$provider webhook missing L-002"
  fi

  if grep -q "UUID_RE" "$WH" && grep -q "safeUserId" "$WH"; then
    ok "$provider webhook UUID validation"
  else
    fail "$provider webhook missing UUID validation"
  fi

  # Default no throw (filtered for comments)
  DEFAULT_BLOCK=$(grep -A3 "^      default:" "$WH" | grep -vE "^\s*//|^\s*\*")
  if echo "$DEFAULT_BLOCK" | grep -q "console.log" && \
     ! echo "$DEFAULT_BLOCK" | grep -E "^\s*throw\b"; then
    ok "$provider webhook default no-throw"
  else
    fail "$provider webhook default may throw"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 6 — L-003 whitelist validators
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 6 — L-003 whitelist validators"

for provider in stripe polar mercadopago; do
  ACTIONS="$SKILL_DIR/templates/$provider/actions/$provider.ts"

  if grep "z.record(z.any())" "$ACTIONS"; then
    fail "$provider: forbidden z.record(z.any())"
  else
    ok "$provider: no z.record(z.any())"
  fi

  if grep -qE "z\.enum\(" "$ACTIONS"; then
    ok "$provider: z.enum whitelists usadas"
  else
    fail "$provider: z.enum missing"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 7 — Idempotency en webhook
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 7 — Idempotency en webhook (prevención double-grant)"

for provider in stripe polar mercadopago; do
  WH="$SKILL_DIR/templates/$provider/app/api/webhooks/$provider/route.ts"
  if grep -qE "Duplicate event|current_period_end ===" "$WH"; then
    ok "$provider webhook idempotency check"
  else
    fail "$provider webhook missing idempotency"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 8 — Acceso solo en subscription.active (NO en checkout.completed)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 8 — Acceso solo en subscription.active"

# Stripe — has_access: true debe estar en handleSubscriptionUpsert con
# status === 'active', NO en handleCheckoutCompleted
STRIPE_WH="$STRIPE/app/api/webhooks/stripe/route.ts"
if awk '/function handleCheckoutCompleted/,/^}/' "$STRIPE_WH" | grep -q "has_access: true"; then
  fail "Stripe: has_access granted en checkout.completed (CRITICAL)"
else
  ok "Stripe: checkout.completed NO concede acceso"
fi

# Polar — has_access: true debe estar en handleSubscriptionActive, NO en
# handleCheckoutLinked
POLAR_WH="$POLAR/app/api/webhooks/polar/route.ts"
if awk '/function handleCheckoutLinked/,/^}/' "$POLAR_WH" | grep -q "has_access: true"; then
  fail "Polar: has_access granted en checkout (CRITICAL)"
else
  ok "Polar: checkout NO concede acceso"
fi

if awk '/function handleSubscriptionActive/,/^}/' "$POLAR_WH" | grep -q "has_access: true"; then
  ok "Polar: has_access granted SOLO en subscription.active"
else
  fail "Polar: has_access NOT granted en subscription.active"
fi

# Mercado Pago — has_access: true SOLO en handlePreapprovalUpsert (status authorized → active),
# NUNCA en handlePaymentUpsert (un pago aprobado NO es una suscripción autorizada)
MP_WH="$MP/app/api/webhooks/mercadopago/route.ts"
if awk '/function handlePaymentUpsert/,/^}/' "$MP_WH" | grep -q "has_access: true"; then
  fail "Mercado Pago: has_access granted en payment.* (CRITICAL)"
else
  ok "Mercado Pago: payment.* NO concede acceso"
fi
if awk '/function handlePreapprovalUpsert/,/^}/' "$MP_WH" | grep -q "has_access: true"; then
  ok "Mercado Pago: has_access granted SOLO en subscription_preapproval authorized"
else
  fail "Mercado Pago: has_access NOT granted en preapproval authorized"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 9 — Rate limiting en /api/checkout
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 9 — Rate limiting documentado en /api/checkout"

for provider in stripe polar mercadopago; do
  CO="$SKILL_DIR/templates/$provider/app/api/$provider/checkout/route.ts"
  if grep -qE "RATE_LIMIT|rateLimitOk" "$CO"; then
    ok "$provider checkout: rate limiting"
  else
    fail "$provider checkout: rate limiting missing"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 10 — PII handling
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 10 — PII handling (logs sin emails completos)"

# Buscar console.log con `.email` o `user.email` directo (potencial PII leak)
for provider in stripe polar mercadopago; do
  for f in "$SKILL_DIR/templates/$provider/actions/$provider.ts" \
           "$SKILL_DIR/templates/$provider/app/api/$provider/checkout/route.ts"; do
    if grep -E "console\.(log|error)\([^)]*\.email\b" "$f" 2>/dev/null; then
      fail "$f: console.log con email completo (PII risk)"
    else
      ok "$f: no PII email logs directos"
    fi
  done
done

# ─────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-payments security pre-handoff: ALL PASS ($PASS checks across 10 gates · 3 providers)"
  exit 0
else
  echo "❌ add-payments security pre-handoff: $FAIL failures"
  exit 1
fi
