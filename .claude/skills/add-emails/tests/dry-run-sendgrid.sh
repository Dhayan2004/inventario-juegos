#!/usr/bin/env bash
# add-emails dry-run test — Mode B (SendGrid)
#
# Validates L1 (file presence + structure) + L2 (semantics) of Mode B.
# Diferencia clave vs Mode A: emails/*.ts son descriptors (NO JSX),
# templateId resuelve via env vars TEMPLATE_IDS, webhook usa ECDSA
# (NO HMAC), suppression sync con SendGrid v3 REST API.
#
# Usage: bash .claude/skills/add-emails/tests/dry-run-sendgrid.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SG="$SKILL_DIR/templates/sendgrid"

echo "── add-emails dry-run-sendgrid ─────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — SendGrid file presence"

sg_files=(
  "lib/sendgrid/client.ts"
  "lib/sendgrid/server.ts"
  "emails/Welcome.ts"
  "emails/MagicLink.ts"
  "emails/PasswordReset.ts"
  "emails/InvoiceReceipt.ts"
  "emails/PaymentFailed.ts"
  "emails/SubscriptionCanceled.ts"
  "emails/EmailChangedConfirmation.ts"
  "emails/index.ts"
  "app/api/email/send/route.ts"
  "app/api/email/unsubscribe/route.ts"
  "app/api/email/suppression-webhook/route.ts"
  "actions/email.ts"
  "migrations/0003_email_subscriptions.sql"
)
for f in "${sg_files[@]}"; do
  if [ -f "$SG/$f" ]; then ok "sendgrid: $f"; else fail "sendgrid missing: $f"; fi
done

# ── L1 — 7 SendGrid template descriptors ────────────────────────────
echo ""
echo "L1 — 7 SendGrid template descriptors (.id, .templateId(), .subject())"

emails=(Welcome MagicLink PasswordReset InvoiceReceipt PaymentFailed SubscriptionCanceled EmailChangedConfirmation)
for em in "${emails[@]}"; do
  f="$SG/emails/$em.ts"
  # NO JSX — pure metadata
  if grep -q "@react-email/components" "$f"; then
    fail "$em should NOT import @react-email/components (Mode B uses dashboard HTML)"
  else
    ok "$em sin React Email imports (correct)"
  fi
  # Type Data exportado
  if grep -qE "export interface ${em}Data" "$f"; then
    ok "$em exports ${em}Data interface"
  else
    fail "$em missing Data interface"
  fi
  # Descriptor exportado
  if grep -qE "export const ${em}Template" "$f"; then
    ok "$em exports ${em}Template descriptor"
  else
    fail "$em missing Template descriptor"
  fi
  # templateId() resuelve via env
  if grep -q "TEMPLATE_IDS\." "$f"; then
    ok "$em resolves via TEMPLATE_IDS env-driven"
  else
    fail "$em missing TEMPLATE_IDS resolution"
  fi
  # Cita R10 + R-005
  if grep -q "R10" "$f"; then
    ok "$em cites R10"
  else
    fail "$em missing R10 citation"
  fi
  if grep -q "R-005" "$f"; then
    ok "$em cites R-005 (transactional_email context)"
  else
    fail "$em missing R-005 citation"
  fi
done

# ── L2 — SDK shape (R13) ─────────────────────────────────────────────
echo ""
echo "L2 — SendGrid SDK shape (R13 [docs:sendgrid-mail@v8])"

if grep -q "import 'server-only'" "$SG/lib/sendgrid/server.ts"; then
  ok "server.ts uses 'server-only' import guard"
else
  fail "server.ts missing 'server-only' guard"
fi

if grep -q "SENDGRID_API_KEY.trim()" "$SG/lib/sendgrid/server.ts"; then
  ok "SENDGRID_API_KEY .trim() applied"
else
  fail "SENDGRID_API_KEY missing .trim()"
fi

if grep "SENDGRID_WEBHOOK_PUBLIC_KEY" "$SG/lib/sendgrid/server.ts" | grep -q "\.trim()"; then
  ok "SENDGRID_WEBHOOK_PUBLIC_KEY .trim() applied"
else
  fail "SENDGRID_WEBHOOK_PUBLIC_KEY missing .trim()"
fi

if grep -q "ALLOWED_TEMPLATE_IDS" "$SG/lib/sendgrid/server.ts"; then
  ok "ALLOWED_TEMPLATE_IDS whitelist exported"
else
  fail "ALLOWED_TEMPLATE_IDS missing"
fi

if grep -q "ALLOWED_LOCALES" "$SG/lib/sendgrid/server.ts"; then
  ok "ALLOWED_LOCALES whitelist exported"
else
  fail "ALLOWED_LOCALES missing"
fi

if grep -q "TEMPLATE_IDS:" "$SG/lib/sendgrid/server.ts"; then
  ok "TEMPLATE_IDS map env-driven"
else
  fail "TEMPLATE_IDS map missing"
fi

if grep -q "assertTemplateConfigured" "$SG/lib/sendgrid/server.ts"; then
  ok "assertTemplateConfigured guard present"
else
  fail "assertTemplateConfigured missing"
fi

if grep -q "SENDGRID_UNSUBSCRIBE_GROUP_ID" "$SG/lib/sendgrid/server.ts"; then
  ok "SENDGRID_UNSUBSCRIBE_GROUP_ID exported (asm group)"
else
  fail "SENDGRID_UNSUBSCRIBE_GROUP_ID missing"
fi

# SENDGRID_API_KEY ausente del client.ts
if grep -q "SENDGRID_API_KEY" "$SG/lib/sendgrid/client.ts"; then
  fail "SENDGRID_API_KEY EN client.ts (CRITICAL leak)"
else
  ok "SENDGRID_API_KEY ausente de client.ts"
fi

# ── L2 — Send route (dynamic templates + asm group) ──────────────────
echo ""
echo "L2 — /api/email/send (dynamic templates + asm group + RFC 8058)"

SEND="$SG/app/api/email/send/route.ts"

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

# Mode B specific: dynamicTemplateData (NO React render)
if grep -q "dynamicTemplateData" "$SEND"; then
  ok "send: usa dynamicTemplateData (Mode B shape)"
else
  fail "send: missing dynamicTemplateData"
fi

if grep -qE "templateId:|templateId =" "$SEND"; then
  ok "send: templateId pasado a sendgrid.send"
else
  fail "send: templateId not passed"
fi

if grep -q "assertTemplateConfigured" "$SEND"; then
  ok "send: assertTemplateConfigured invoked (env-driven IDs)"
else
  fail "send: assertTemplateConfigured missing"
fi

# asm group conditional
if grep -q "asm:" "$SEND"; then
  ok "send: asm group cuando configurado"
else
  fail "send: asm group missing"
fi

# Privacy: openTracking off por default
if grep -A2 "openTracking:" "$SEND" | grep -q "enable: false"; then
  ok "send: openTracking off por privacy default"
else
  fail "send: openTracking on (privacy concern)"
fi

# NO React Email render (Mode A pattern) en Mode B
if grep -E "Template\(.*as any" "$SEND" | grep -q "react:"; then
  fail "send: usa react: render (Mode A pattern, wrong para Mode B)"
else
  ok "send: NO react: render (correct para Mode B)"
fi

# ── L2 — Unsubscribe route (RFC 8058 + SendGrid sync) ───────────────
echo ""
echo "L2 — /api/email/unsubscribe (RFC 8058 + SendGrid v3 sync)"

UNSUB="$SG/app/api/email/unsubscribe/route.ts"

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

# SendGrid sync (best-effort)
if grep -q "syncSendGridSuppressionGroup\|/v3/asm/groups/" "$UNSUB"; then
  ok "unsubscribe: sync con SendGrid v3 suppression group"
else
  fail "unsubscribe: missing SendGrid sync"
fi

# ── L2 — Webhook handler (ECDSA + L-002) ────────────────────────────
echo ""
echo "L2 — SendGrid webhook (ECDSA P-256 signature + L-002)"

WH="$SG/app/api/email/suppression-webhook/route.ts"

if grep -q "await request.text()" "$WH"; then
  ok "webhook: raw body via request.text()"
else
  fail "webhook: missing raw body"
fi

# ECDSA imports (NO HMAC / Svix)
if grep -q "@sendgrid/eventwebhook" "$WH"; then
  ok "webhook: imports @sendgrid/eventwebhook (ECDSA)"
else
  fail "webhook: missing @sendgrid/eventwebhook"
fi

if grep -q "EventWebhook\b" "$WH"; then
  ok "webhook: EventWebhook helper used"
else
  fail "webhook: EventWebhook missing"
fi

if grep -q "EventWebhookHeader" "$WH"; then
  ok "webhook: EventWebhookHeader for sig/timestamp lookup"
else
  fail "webhook: EventWebhookHeader missing"
fi

if grep -q "convertPublicKeyToECDSA" "$WH"; then
  ok "webhook: ECDSA pubkey conversion"
else
  fail "webhook: ECDSA conversion missing"
fi

if grep -q "verifySignature" "$WH"; then
  ok "webhook: verifySignature invoked"
else
  fail "webhook: verifySignature missing"
fi

# NO Svix HMAC en Mode B
if grep -q "import.*Webhook.*from.*svix\|new Webhook(" "$WH"; then
  fail "webhook: usa Svix (Mode A pattern, wrong para Mode B)"
else
  ok "webhook: NO Svix import (correct para Mode B ECDSA)"
fi

# raw body antes de verify (line numbers)
RAW_LINE=$(grep -n "await request.text()" "$WH" | head -1 | cut -d: -f1)
VERIFY_LINE=$(grep -n "verifySignature(" "$WH" | head -1 | cut -d: -f1)
if [ -n "$RAW_LINE" ] && [ -n "$VERIFY_LINE" ] && [ "$RAW_LINE" -lt "$VERIFY_LINE" ]; then
  ok "webhook: raw body (L$RAW_LINE) antes de verify (L$VERIFY_LINE)"
else
  fail "webhook: order incorrect (raw=$RAW_LINE verify=$VERIFY_LINE)"
fi

# 401 FAIL FAST
if grep -A6 "Signature missing\|Invalid signature\|Signature verification failed" "$WH" | grep -qE "status: 401"; then
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

# Switch event types whitelist (SendGrid: bounce, dropped, spamreport, unsubscribe)
if grep -qE "case 'bounce'" "$WH"; then
  ok "webhook: switch incluye bounce"
else
  fail "webhook: missing bounce case"
fi

if grep -qE "case 'spamreport'" "$WH"; then
  ok "webhook: switch incluye spamreport"
else
  fail "webhook: missing spamreport case"
fi

if grep -qE "case 'dropped'" "$WH"; then
  ok "webhook: switch incluye dropped"
else
  fail "webhook: missing dropped case"
fi

if grep -qE "case 'unsubscribe'" "$WH"; then
  ok "webhook: switch incluye unsubscribe"
else
  fail "webhook: missing unsubscribe case"
fi

# Bounce solo hard suppress (type: 'bounce')
if grep -B2 -A4 "case 'bounce':" "$WH" | grep -q "ev.type === 'bounce'"; then
  ok "webhook: bounce solo hard (type='bounce') suppress"
else
  fail "webhook: bounce no filtra por type='bounce'"
fi

# Default no-throw
DEFAULT_BLOCK=$(grep -A2 "^      default:" "$WH" | grep -vE "^\s*//|^\s*\*")
if ! echo "$DEFAULT_BLOCK" | grep -E "^\s*throw\b"; then
  ok "webhook: default no-throw (anti retry storm)"
else
  fail "webhook: default may throw"
fi

# Batch handling (SendGrid manda arrays)
if grep -q "EventArraySchema\|z.array" "$WH"; then
  ok "webhook: maneja batch arrays (SendGrid pattern)"
else
  fail "webhook: batch handling missing"
fi

if grep -qE "for \(const ev of events\)" "$WH"; then
  ok "webhook: itera events array"
else
  fail "webhook: missing batch loop"
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

ACTIONS="$SG/actions/email.ts"

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

# Mode B specific: deleteSuppressionEntry sincroniza con SendGrid v3 REST
if grep -q "v3/asm/suppressions/global" "$ACTIONS"; then
  ok "actions: deleteSuppressionEntry sync con SendGrid v3 REST"
else
  fail "actions: SendGrid v3 sync missing"
fi

# Audit log antes de execute
INSERT_LINE=$(grep -n "from('email_admin_actions')" "$ACTIONS" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "from('email_subscriptions')" "$ACTIONS" | head -1 | cut -d: -f1)
if [ -n "$INSERT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$INSERT_LINE" -lt "$EXEC_LINE" ]; then
  ok "actions: audit log (L$INSERT_LINE) antes de execute (L$EXEC_LINE)"
else
  fail "actions: audit log NOT before execute"
fi

# z.enum reasons (multi-line array tolerant)
if grep -qE "'admin_compliance'" "$ACTIONS" && \
   grep -qE "'data_subject_request'" "$ACTIONS"; then
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
echo "L2 — RLS L-001 en 0003_email_subscriptions.sql (provider-agnostic)"

SQL="$SG/migrations/0003_email_subscriptions.sql"

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

# NO INSERT/UPDATE/DELETE direct
if grep -E "for (insert|update|delete) (using|with check)" "$SQL" | grep -v "email_admin_actions"; then
  fail "INSERT/UPDATE/DELETE direct policies (L-001 violation)"
else
  ok "NO INSERT/UPDATE/DELETE direct (service_role only)"
fi

if grep -q "on delete cascade" "$SQL"; then
  ok "FK con cascade"
else
  fail "FK missing cascade"
fi

if grep -q "L-001" "$SQL"; then
  ok "L-001 cited en SQL preamble"
else
  fail "L-001 citation missing"
fi

# Tables presentes
for tbl in email_subscriptions suppression_list email_events email_admin_actions; do
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

# ── L2 — find-docs invocation in prompts (R13) ──────────────────────
echo ""
echo "L2 — find-docs invocation in prompts (R13)"

for p in setup-resend setup-sendgrid generate-templates generate-unsubscribe \
         generate-suppression-list; do
  if grep -q "find-docs\|resolve-library-id" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md has find-docs invocation"
  else
    fail "prompts/$p.md missing find-docs"
  fi
done

# decision-tree y handoff: deben citar R13 (literal o range)
for p in decision-tree handoff-el-guardian; do
  if grep -qE "R13|R(10|11|12|13)\.\.14" "$SKILL_DIR/prompts/$p.md"; then
    ok "prompts/$p.md cita R13 (literal o range)"
  else
    fail "prompts/$p.md missing R13 citation"
  fi
done

# ── L2 — SKILL.md citations completas ───────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness (Mode B paths)"

for cite in "R-005" "R10" "R13" "R14" "L-001" "L-002" "L-003" "D-010" "D-011" "sendgrid"; do
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
  echo "✅ add-emails dry-run-sendgrid: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-emails dry-run-sendgrid: $FAIL failures"
  exit 1
fi
