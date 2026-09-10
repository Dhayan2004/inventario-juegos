#!/usr/bin/env bash
# add-emails security pre-handoff test (L3 system check)
#
# Cubre los 10 gates del checklist handoff-el-guardian.md aplicados a los
# templates de Resend + SendGrid. Se corre tras dry-run-resend +
# dry-run-sendgrid pasen.
#
# Usage: bash .claude/skills/add-emails/tests/security-pre-handoff.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESEND="$SKILL_DIR/templates/resend"
SG="$SKILL_DIR/templates/sendgrid"

echo "── add-emails security pre-handoff ─────────────────────────────"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ─────────────────────────────────────────────────────────────────────
# Gate 1 — API key isolation (server only, NEVER client)
# ─────────────────────────────────────────────────────────────────────
echo "Gate 1 — API key isolation"

# Resend
if grep -q "RESEND_API_KEY" "$RESEND/lib/resend/server.ts"; then
  ok "RESEND_API_KEY presente en lib/resend/server.ts"
else
  fail "RESEND_API_KEY missing en server lib"
fi

if grep -q "RESEND_API_KEY" "$RESEND/lib/resend/client.ts" 2>/dev/null; then
  fail "RESEND_API_KEY EN client.ts (CRITICAL leak)"
else
  ok "RESEND_API_KEY ausente de client.ts"
fi

if grep -q "import 'server-only'" "$RESEND/lib/resend/server.ts"; then
  ok "Resend server.ts: 'server-only' guard"
else
  fail "Resend server.ts: 'server-only' guard missing"
fi

# SendGrid
if grep -q "SENDGRID_API_KEY" "$SG/lib/sendgrid/server.ts"; then
  ok "SENDGRID_API_KEY presente en lib/sendgrid/server.ts"
else
  fail "SENDGRID_API_KEY missing en server lib"
fi

if grep -q "SENDGRID_API_KEY" "$SG/lib/sendgrid/client.ts" 2>/dev/null; then
  fail "SENDGRID_API_KEY EN client.ts (CRITICAL leak)"
else
  ok "SENDGRID_API_KEY ausente de client.ts"
fi

if grep -q "import 'server-only'" "$SG/lib/sendgrid/server.ts"; then
  ok "SendGrid server.ts: 'server-only' guard"
else
  fail "SendGrid server.ts: 'server-only' guard missing"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 2 — Webhook secret .trim() applied (silent failure prevention)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 2 — Webhook secret .trim() applied"

if grep "RESEND_WEBHOOK_SECRET" "$RESEND/lib/resend/server.ts" | grep -q "\.trim()"; then
  ok "RESEND_WEBHOOK_SECRET con .trim()"
else
  fail "RESEND_WEBHOOK_SECRET missing .trim() (silent failure risk)"
fi

if grep "SENDGRID_WEBHOOK_PUBLIC_KEY" "$SG/lib/sendgrid/server.ts" | grep -q "\.trim()"; then
  ok "SENDGRID_WEBHOOK_PUBLIC_KEY con .trim()"
else
  fail "SENDGRID_WEBHOOK_PUBLIC_KEY missing .trim()"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 3 — Webhook signature verified BEFORE DB ops
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 3 — Webhook signature verified BEFORE DB ops"

# Resend webhook
RESEND_WH="$RESEND/app/api/email/suppression-webhook/route.ts"

if grep -q "await request.text()" "$RESEND_WH"; then
  ok "Resend webhook: raw body via request.text()"
else
  fail "Resend webhook: missing raw body"
fi

VERIFY_LINE=$(grep -n "wh.verify(" "$RESEND_WH" | head -1 | cut -d: -f1)
DB_LINE=$(grep -n "supabase.from\|createAdminClient()" "$RESEND_WH" | head -1 | cut -d: -f1)
if [ -n "$VERIFY_LINE" ] && [ -n "$DB_LINE" ] && [ "$VERIFY_LINE" -lt "$DB_LINE" ]; then
  ok "Resend webhook: verify (L$VERIFY_LINE) BEFORE DB op (L$DB_LINE)"
else
  fail "Resend webhook: signature NOT verified before DB (verify=$VERIFY_LINE db=$DB_LINE)"
fi

if grep -A6 "Resend signature verification failed\|catch (err)" "$RESEND_WH" | grep -qE "status: 401"; then
  ok "Resend webhook: 401 FAIL FAST on bad signature"
else
  fail "Resend webhook: missing 401 on bad sig"
fi

# SendGrid webhook
SG_WH="$SG/app/api/email/suppression-webhook/route.ts"

if grep -q "await request.text()" "$SG_WH"; then
  ok "SendGrid webhook: raw body via request.text()"
else
  fail "SendGrid webhook: missing raw body"
fi

if grep -q "verifySignature" "$SG_WH"; then
  ok "SendGrid webhook: ECDSA verifySignature invoked"
else
  fail "SendGrid webhook: verifySignature missing"
fi

VERIFY_LINE=$(grep -n "verifySignature(" "$SG_WH" | head -1 | cut -d: -f1)
DB_LINE=$(grep -n "createAdminClient()\|supabase.from" "$SG_WH" | head -1 | cut -d: -f1)
if [ -n "$VERIFY_LINE" ] && [ -n "$DB_LINE" ] && [ "$VERIFY_LINE" -lt "$DB_LINE" ]; then
  ok "SendGrid webhook: verify (L$VERIFY_LINE) BEFORE DB op (L$DB_LINE)"
else
  fail "SendGrid webhook: signature NOT verified before DB (verify=$VERIFY_LINE db=$DB_LINE)"
fi

if grep -A6 "Signature missing\|Invalid signature\|Signature verification failed" "$SG_WH" | grep -qE "status: 401"; then
  ok "SendGrid webhook: 401 FAIL FAST on bad signature"
else
  fail "SendGrid webhook: missing 401 on bad sig"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 4 — R14 destructive sin execute() automático
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 4 — R14: bulkUnsubscribe / deleteSuppressionEntry / resendCampaign sin execute()"

for mode in resend sendgrid; do
  ACTIONS="$SKILL_DIR/templates/$mode/actions/email.ts"

  # NO tool({ execute }) en destructive
  if grep -E "^export.*tool\(.*execute.*async.*(bulk|delete|resend)" "$ACTIONS"; then
    fail "$mode: destructive tool({ execute }) — R14 CRITICAL violation"
  else
    ok "$mode: NO tool({ execute }) en destructive (R14 PASS)"
  fi

  # Typed confirmations
  if grep -q "z.literal('BULK_UNSUBSCRIBE'" "$ACTIONS"; then
    ok "$mode: bulkUnsubscribe typed confirmation"
  else
    fail "$mode: bulkUnsubscribe missing typed-confirm"
  fi

  if grep -q "z.literal('DELETE_SUPPRESSION'" "$ACTIONS"; then
    ok "$mode: deleteSuppressionEntry typed confirmation"
  else
    fail "$mode: deleteSuppressionEntry missing typed-confirm"
  fi

  if grep -q "z.literal('RESEND_CAMPAIGN'" "$ACTIONS"; then
    ok "$mode: resendCampaign typed confirmation"
  else
    fail "$mode: resendCampaign missing typed-confirm"
  fi

  # Audit log antes de execute
  AUDIT_LINE=$(grep -n "from('email_admin_actions')" "$ACTIONS" | head -1 | cut -d: -f1)
  EXEC_LINE=$(grep -n "from('email_subscriptions')\|from('suppression_list')" "$ACTIONS" | head -1 | cut -d: -f1)
  if [ -n "$AUDIT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$AUDIT_LINE" -lt "$EXEC_LINE" ]; then
    ok "$mode: audit log antes de execute"
  else
    fail "$mode: audit log NOT before execute (R14 violation)"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 5 — RLS L-001 en email_subscriptions + policies
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 5 — RLS L-001 en email_subscriptions"

for mode in resend sendgrid; do
  SQL="$SKILL_DIR/templates/$mode/migrations/0003_email_subscriptions.sql"

  if grep -q "enable row level security" "$SQL"; then
    ok "$mode: RLS habilitado"
  else
    fail "$mode: RLS missing"
  fi

  if grep -q "auth.uid() = user_id" "$SQL"; then
    ok "$mode: policy auth.uid() = user_id"
  else
    fail "$mode: policy missing"
  fi

  if grep -E "for (insert|update|delete) (using|with check)" "$SQL" | grep -v "email_admin_actions"; then
    fail "$mode: INSERT/UPDATE/DELETE direct (L-001 violation)"
  else
    ok "$mode: NO INSERT/UPDATE/DELETE direct (service_role only)"
  fi

  if grep -q "on delete cascade" "$SQL"; then
    ok "$mode: FK cascade"
  else
    fail "$mode: FK missing cascade"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 6 — Server actions validan ownership (auth.uid() === sub.user_id)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 6 — Server actions validan ownership / admin role"

for mode in resend sendgrid; do
  ACTIONS="$SKILL_DIR/templates/$mode/actions/email.ts"

  # Auth gate
  if grep -q "supabase.auth.getUser()" "$ACTIONS"; then
    ok "$mode: auth.getUser() invoked"
  else
    fail "$mode: missing auth.getUser()"
  fi

  # Admin role gate (bulkUnsubscribe / deleteSuppressionEntry / resendCampaign)
  if grep -q "profile?.role !== 'admin'" "$ACTIONS"; then
    ok "$mode: admin role gate"
  else
    fail "$mode: admin role gate missing"
  fi

  # L-003: NO z.record(z.any())
  if grep "z.record(z.any())" "$ACTIONS"; then
    fail "$mode: forbidden z.record(z.any()) (L-003 violation)"
  else
    ok "$mode: no z.record(z.any())"
  fi

  # Whitelist enums presentes
  if grep -qE "z\.enum\(" "$ACTIONS"; then
    ok "$mode: z.enum whitelists usadas (L-003)"
  else
    fail "$mode: z.enum missing"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 7 — Webhook signature verified BEFORE DB ops (cross-cite Gate 3)
# Adicional: idempotency check después de signature
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 7 — Webhook idempotency (post-signature)"

for mode in resend sendgrid; do
  WH="$SKILL_DIR/templates/$mode/app/api/email/suppression-webhook/route.ts"
  if grep -q "external_event_id" "$WH"; then
    ok "$mode webhook: idempotency via external_event_id"
  else
    fail "$mode webhook: idempotency missing"
  fi

  # Treat-as-data (Zod schema validation post-signature)
  if grep -qE "EventSchema|EventArraySchema" "$WH"; then
    ok "$mode webhook: Zod schema validation (L-002 treat-as-data)"
  else
    fail "$mode webhook: Zod schema missing"
  fi

  # L-002 cited
  if grep -q "L-002" "$WH"; then
    ok "$mode webhook: cita L-002"
  else
    fail "$mode webhook: missing L-002 citation"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 8 — Rate limiting documented en /api/email/send
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 8 — Rate limiting en /api/email/send"

for mode in resend sendgrid; do
  SEND="$SKILL_DIR/templates/$mode/app/api/email/send/route.ts"
  if grep -qE "RATE_LIMIT|rateLimitOk" "$SEND"; then
    ok "$mode send: rate limiting"
  else
    fail "$mode send: rate limiting missing"
  fi

  # Rate limit value documented
  if grep -qE "RATE_LIMIT *= *[0-9]+" "$SEND"; then
    ok "$mode send: RATE_LIMIT value documented"
  else
    fail "$mode send: RATE_LIMIT value missing"
  fi

  # WINDOW_MS or equivalent
  if grep -qE "WINDOW_MS|60 \* 60 \* 1000" "$SEND"; then
    ok "$mode send: rate window documented"
  else
    fail "$mode send: rate window missing"
  fi

  # 429 status on rate limit hit
  if grep -A1 "Too many requests\|rateLimitOk" "$SEND" | grep -qE "status: 429"; then
    ok "$mode send: 429 on rate limit"
  else
    fail "$mode send: 429 missing"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Gate 9 — SPF/DKIM/DMARC documentation
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 9 — SPF/DKIM/DMARC documentation present"

# Las references/deliverability-best-practices.md o similar deben mencionar SPF/DKIM/DMARC
DELIV="$SKILL_DIR/references/deliverability-best-practices.md"

if [ -f "$DELIV" ]; then
  if grep -qiE "SPF" "$DELIV"; then
    ok "deliverability ref menciona SPF"
  else
    fail "deliverability ref: SPF missing"
  fi
  if grep -qiE "DKIM" "$DELIV"; then
    ok "deliverability ref menciona DKIM"
  else
    fail "deliverability ref: DKIM missing"
  fi
  if grep -qiE "DMARC" "$DELIV"; then
    ok "deliverability ref menciona DMARC"
  else
    fail "deliverability ref: DMARC missing"
  fi
else
  fail "references/deliverability-best-practices.md missing"
fi

# Warning sobre DNS no verifiable: handoff-el-guardian.md gate 10 manual
HANDOFF="$SKILL_DIR/prompts/handoff-el-guardian.md"
if grep -qiE "DNS|deliverability infra|manual" "$HANDOFF"; then
  ok "handoff: warning sobre DNS / deliverability manual gate"
else
  fail "handoff: missing DNS / deliverability gate"
fi

# ─────────────────────────────────────────────────────────────────────
# Gate 10 — Unsubscribe one-click compliant (RFC 8058)
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Gate 10 — Unsubscribe one-click RFC 8058 compliance"

for mode in resend sendgrid; do
  SEND="$SKILL_DIR/templates/$mode/app/api/email/send/route.ts"
  UNSUB="$SKILL_DIR/templates/$mode/app/api/email/unsubscribe/route.ts"

  # Headers en send
  if grep -q "List-Unsubscribe" "$SEND"; then
    ok "$mode send: List-Unsubscribe header"
  else
    fail "$mode send: List-Unsubscribe missing"
  fi

  if grep -q "List-Unsubscribe-Post" "$SEND"; then
    ok "$mode send: List-Unsubscribe-Post (RFC 8058 one-click)"
  else
    fail "$mode send: List-Unsubscribe-Post missing"
  fi

  # GET + POST handlers
  if grep -q "export async function GET" "$UNSUB"; then
    ok "$mode unsubscribe: GET handler"
  else
    fail "$mode unsubscribe: GET missing"
  fi

  if grep -q "export async function POST" "$UNSUB"; then
    ok "$mode unsubscribe: POST handler"
  else
    fail "$mode unsubscribe: POST missing"
  fi

  # No auth required (token-based)
  if grep -q "jwtVerify" "$UNSUB"; then
    ok "$mode unsubscribe: token-based (no user auth required)"
  else
    fail "$mode unsubscribe: missing token verification"
  fi
done

# ─────────────────────────────────────────────────────────────────────
# Bonus — Brand contract per template (R10) — 7 templates Mode A
# ─────────────────────────────────────────────────────────────────────
echo ""
echo "Bonus — R10 Brand contract per Resend template (7 templates)"

emails=(Welcome MagicLink PasswordReset InvoiceReceipt PaymentFailed SubscriptionCanceled EmailChangedConfirmation)
for em in "${emails[@]}"; do
  f="$RESEND/emails/$em.tsx"
  # NO Tailwind purple/indigo/violet/blue (anti-slop AP6)
  if grep -E "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" "$f"; then
    fail "Resend $em: Tailwind purple/indigo/violet/blue (AP6 anti-slop)"
  else
    ok "Resend $em: no Tailwind defaults (AP6 PASS)"
  fi
done

# Bonus — Brand contract per SendGrid template (R10) — 7 descriptors
echo ""
echo "Bonus — R10 Brand contract per SendGrid descriptor (7 templates)"

for em in "${emails[@]}"; do
  f="$SG/emails/$em.ts"
  # NO @react-email/components (HTML vive en dashboard)
  if grep -q "@react-email/components" "$f"; then
    fail "SendGrid $em: importa @react-email/components (Mode A pattern)"
  else
    ok "SendGrid $em: NO @react-email/components (Mode B correct)"
  fi
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
  echo "✅ add-emails security pre-handoff: ALL PASS ($PASS checks across 10 gates)"
  exit 0
else
  echo "❌ add-emails security pre-handoff: $FAIL failures"
  exit 1
fi
