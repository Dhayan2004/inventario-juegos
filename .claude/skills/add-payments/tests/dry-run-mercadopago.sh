#!/usr/bin/env bash
# add-payments dry-run test — Mode C (Mercado Pago) · D-038
#
# Mirror del dry-run-stripe.sh adaptado a la SDK de Mercado Pago v2 + lo que Mode C
# agrega: verificador puro (manifest hmac_field_concat), ledger 0003, rails irreversibles
# (PAY-006), exponente ISO 4217 (PAY-004) y la Layer 3 con eventos firmados (L-010).
#
# Usage: bash .claude/skills/add-payments/tests/dry-run-mercadopago.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MP="$SKILL_DIR/templates/mercadopago"
SHARED="$SKILL_DIR/templates/shared"

echo "── add-payments dry-run-mercadopago ────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence (paridad con Mode A: 13 + verify.ts + plans.ts) ────────
echo "L1 — Mercado Pago file presence"

mp_files=(
  "lib/mercadopago/client.ts"
  "lib/mercadopago/server.ts"
  "lib/mercadopago/verify.ts"
  "lib/mercadopago/plans.ts"
  "app/api/webhooks/mercadopago/route.ts"
  "app/api/mercadopago/checkout/route.ts"
  "app/api/mercadopago/portal/route.ts"
  "app/api/mercadopago/refund-request/route.ts"
  "app/(billing)/pricing/page.tsx"
  "app/(billing)/checkout/page.tsx"
  "app/(billing)/success/page.tsx"
  "app/(billing)/billing/page.tsx"
  "actions/mercadopago.ts"
  "types/billing.ts"
  "migrations/0002_subscriptions.sql"
)
for f in "${mp_files[@]}"; do
  if [ -f "$MP/$f" ]; then ok "mercadopago: $f"; else fail "mercadopago missing: $f"; fi
done
for f in "migrations/0003_payments_ledger.sql" "tests/payments/webhook-mercadopago.test.mjs" "payment-page-scripts.json"; do
  if [ -f "$SHARED/$f" ]; then ok "shared: $f"; else fail "shared missing: $f"; fi
done

# ── L2 — SDK shape (R13) ─────────────────────────────────────────────
echo ""
echo "L2 — Mercado Pago SDK shape (R13 [docs:mercadopago@v2])"
SRV="$MP/lib/mercadopago/server.ts"
grep -q "import 'server-only'" "$SRV" && ok "server.ts uses 'server-only' import guard" || fail "server.ts missing 'server-only' guard"
grep -q "MP_ACCESS_TOKEN.trim()" "$SRV" && ok "MP_ACCESS_TOKEN .trim() applied" || fail "MP_ACCESS_TOKEN missing .trim()"
grep -q "MP_WEBHOOK_SECRET" "$SRV" && grep "MP_WEBHOOK_SECRET" "$SRV" | grep -q "\.trim()" && ok "MP_WEBHOOK_SECRET .trim() applied" || fail "MP_WEBHOOK_SECRET missing .trim()"
grep -q "ALLOWED_PLAN_IDS" "$SRV" && ok "ALLOWED_PLAN_IDS whitelist (L-003)" || fail "ALLOWED_PLAN_IDS missing"
grep -q "CURRENCY_EXPONENT" "$SRV" && grep -q "toMajorUnits" "$SRV" && grep -q "toMinorUnits" "$SRV" && ok "exponente ISO 4217 + toMajorUnits/toMinorUnits (PAY-004)" || fail "exponent helpers missing (PAY-004)"
grep -q "IRREVERSIBLE_PAYMENT_TYPES" "$SRV" && grep -q "isIrreversible" "$SRV" && ok "rails irreversibles tabulados (PAY-006)" || fail "IRREVERSIBLE_PAYMENT_TYPES missing"
grep -qE "startsWith\('TEST-'\)" "$SRV" && ok "sandbox detectado por prefijo TEST- (Rule 8)" || fail "sandbox detection missing"
if cat "$SRV" "$MP/app/api/webhooks/mercadopago/route.ts" "$MP/app/api/mercadopago/checkout/route.ts" | grep -vE '^\s*(\*|//)' | grep -qE "\* 100\b"; then fail "'* 100' a ciegas en server/webhook/checkout (PAY-004)"; else ok "sin '* 100' a ciegas (PAY-004)"; fi

# ── L2 — verify.ts (módulo puro, esquema re-verificado) ──────────────
echo ""
echo "L2 — verify.ts (hmac_field_concat, VETTING §4)"
V="$MP/lib/mercadopago/verify.ts"
grep -q "from 'node:crypto'" "$V" && ! grep -qE "from '@/|from '\./(server|plans)" "$V" && ok "verify.ts es puro (solo node:crypto)" || fail "verify.ts importa de la app (rompe la Layer 3)"
grep -q "buildMpManifest" "$V" && grep -q "join(';') + ';'" "$V" && ok "manifest id;request-id;ts; (termina en ';')" || fail "manifest incorrecto"
grep -q "timingSafeEqual" "$V" && ok "comparación en tiempo constante (PAY-005)" || fail "timingSafeEqual missing (PAY-005)"
grep -q "toleranceSeconds" "$V" && ok "ventana anti-replay configurable" || fail "tolerance missing"
if grep -qE "===\s*(received|computed|v1)" "$V"; then fail "=== sobre la firma (PAY-005)"; else ok "sin === sobre la firma"; fi

# ── L2 — Webhook handler (L-002 + 6 phases) ──────────────────────────
echo ""
echo "L2 — webhook handler (L-002 · dedup G2 · re-fetch)"
WH="$MP/app/api/webhooks/mercadopago/route.ts"
grep -q "await request.text()" "$WH" && ok "raw body via request.text()" || fail "missing request.text()"
RAW_LINE=$(grep -n "await request.text()" "$WH" | head -1 | cut -d: -f1)
VER_LINE=$(grep -n "verifyMpSignature({" "$WH" | head -1 | cut -d: -f1)
PARSE_LINE=$(grep -n "JSON.parse(body)" "$WH" | head -1 | cut -d: -f1)
if [ -n "$RAW_LINE" ] && [ -n "$VER_LINE" ] && [ -n "$PARSE_LINE" ] && [ "$RAW_LINE" -lt "$VER_LINE" ] && [ "$VER_LINE" -lt "$PARSE_LINE" ]; then
  ok "orden: raw ($RAW_LINE) → verify ($VER_LINE) → parse ($PARSE_LINE)"
else
  fail "orden incorrecto raw=$RAW_LINE verify=$VER_LINE parse=$PARSE_LINE"
fi
grep -q "toleranceSeconds: 300" "$WH" && ok "ventana 300 s en el handler" || fail "tolerance 300 missing"
grep -q "status: 400" "$WH" && ok "FAIL FAST 400" || fail "400 missing"
grep -q "webhook_events_processed" "$WH" && grep -q "23505" "$WH" && ok "dedup por event id (G2, unique → 23505 → 200)" || fail "dedup missing (G2)"
grep -q "mpPreApproval.get" "$WH" && grep -q "mpPayment.get" "$WH" && ok "re-fetch (payload_authoritative = false)" || fail "re-fetch missing"
grep -q "UUID_RE" "$WH" && grep -q "safeUserId" "$WH" && ok "L-002 safeUserId sobre external_reference" || fail "safeUserId missing (L-002)"
grep -q "L-002" "$WH" && ok "cita L-002" || fail "L-002 citation missing"
if grep -A3 "^      default:" "$WH" | grep -vE "^\s*//|^\s*\*" | grep -q "throw"; then fail "default case throws (retry storm)"; else ok "default case no-throw"; fi
grep -q "force-dynamic" "$WH" && ok "force-dynamic" || fail "force-dynamic missing"
if awk '/function handlePaymentUpsert/,/^}/' "$WH" | grep -q "has_access: true"; then fail "payment.* concede acceso (CRITICAL)"; else ok "payment.* NO concede acceso"; fi
grep -q "refundable: !isIrreversible" "$WH" && ok "ledger marca refundable por rail (PAY-006)" || fail "refundable flag missing"

# ── L2 — RLS L-001 en SQL + ledger 0003 ──────────────────────────────
echo ""
echo "L2 — RLS L-001 (0002) + ledger 0003 (G2 · R16)"
SQL="$MP/migrations/0002_subscriptions.sql"
grep -q "enable row level security" "$SQL" && ok "0002 RLS enabled" || fail "0002 RLS missing"
grep -q "'mercadopago'" "$SQL" && ok "0002 provider check incluye mercadopago" || fail "0002 provider check missing mercadopago"
LEDGER="$SHARED/migrations/0003_payments_ledger.sql"
grep -q "create table if not exists public.payments" "$LEDGER" && ok "0003 payments" || fail "0003 payments missing"
grep -q "create table if not exists public.webhook_events_processed" "$LEDGER" && grep -q "unique (provider, event_id)" "$LEDGER" && ok "0003 webhook_events_processed unique (provider, event_id)" || fail "0003 dedup table missing"
grep -q "create table if not exists public.idempotency_keys" "$LEDGER" && ok "0003 idempotency_keys" || fail "0003 idempotency_keys missing"
grep -c "enable row level security" "$LEDGER" | grep -q "^3$" && ok "0003 RLS en las 3 tablas" || fail "0003 RLS missing en alguna tabla"
grep -q "auth.uid() = user_id" "$LEDGER" && ok "0003 policy por user_id (L-001)" || fail "0003 user policy missing"
grep -q "auth_org_ids" "$LEDGER" && grep -q "with check" "$LEDGER" && grep -q "pg_proc" "$LEDGER" && ok "0003 policy por org con WITH CHECK, condicional a auth_org_ids() (R16 T1–T3, degradación segura)" || fail "0003 tenant policy missing/unsafe"
grep -q "organization_id uuid" "$LEDGER" && ok "0003 organization_id (R16 invariante 1)" || fail "organization_id missing"

# ── L2 — R14 + L-003 en actions ──────────────────────────────────────
echo ""
echo "L2 — R14 destructive + L-003 whitelist en actions"
ACT="$MP/actions/mercadopago.ts"
grep -q "'use server'" "$ACT" && ok "'use server'" || fail "'use server' missing"
grep -q "z.literal('REFUND'" "$ACT" && ok "requestRefund typed confirmation" || fail "REFUND literal missing"
grep -q "z.literal('CANCEL'" "$ACT" && ok "cancelSubscription typed confirmation" || fail "CANCEL literal missing"
if grep -qE "^export.*tool\(.*execute.*async.*(refund|cancel|transfer)" "$ACT"; then fail "tool({execute}) en destructivo (R14)"; else ok "sin tool({execute}) en destructivos (R14)"; fi
AUDIT_LINE=$(grep -n "from('refund_requests')" "$ACT" | head -1 | cut -d: -f1)
EXEC_LINE=$(grep -n "mpRefund.create" "$ACT" | head -1 | cut -d: -f1)
[ -n "$AUDIT_LINE" ] && [ -n "$EXEC_LINE" ] && [ "$AUDIT_LINE" -lt "$EXEC_LINE" ] && ok "audit log ($AUDIT_LINE) antes de execute ($EXEC_LINE)" || fail "audit log NOT before execute (R14)"
grep -q "isIrreversible(payment.payment_type)" "$ACT" && grep -q "payout_required" "$ACT" && ok "guard PAY-006: rail irreversible → payout_required, sin refund API" || fail "PAY-006 guard missing"
grep -q "randomUUID()" "$ACT" && ok "idempotency key criptográfica (PAY-003)" || fail "randomUUID missing (PAY-003)"
grep -q "from('payments')" "$ACT" && ok "ownership DB-backed vía ledger (PAY-008/R14)" || fail "ownership via ledger missing"
if grep -qE "z\.record\(z\.any\(\)\)" "$ACT"; then fail "z.record(z.any()) (L-003)"; else ok "sin z.record(z.any()) (L-003)"; fi

# ── L2 — checkout route ──────────────────────────────────────────────
echo ""
echo "L2 — checkout route (rate limit · L-003 · PAY-008)"
CO="$MP/app/api/mercadopago/checkout/route.ts"
grep -qE "RATE_LIMIT|rateLimitOk" "$CO" && ok "rate limiting" || fail "rate limiting missing"
grep -q "ALLOWED_PLAN_IDS.includes" "$CO" && grep -q "PLANS\[" "$CO" && ok "plan whitelist + precio server-side (PAY-008)" || fail "PAY-008 guard missing"
grep -q "MP_EXCLUDED_PAYMENT_TYPES" "$CO" && ok "rails configurables (OXXO/SPEI)" || fail "payment types config missing"
grep -q "external_reference: user.id" "$CO" && ok "external_reference = user.id (re-validado en webhook)" || fail "external_reference missing"
grep -q "notification_url" "$CO" && ok "notification_url apunta al webhook" || fail "notification_url missing"
if grep -qE "\b(body|input)\.(amount|price|total)" "$CO"; then fail "monto del cliente en checkout (PAY-008)"; else ok "sin monto del cliente (PAY-008)"; fi

# ── L2 — R10 en pages ────────────────────────────────────────────────
echo ""
echo "L2 — R10 Brand DNA en pages"
for page in pricing checkout success billing; do
  P="$MP/app/(billing)/$page/page.tsx"
  grep -q "@/shared/components/ui" "$P" && ok "$page: importa impeccable components" || fail "$page: no importa @/shared/components/ui"
  if grep -qE "(bg|text)-(purple|indigo|violet|blue)-[0-9]+" "$P"; then fail "$page: Tailwind color default (AP6)"; else ok "$page: sin Tailwind color defaults"; fi
  grep -q "R10" "$P" && ok "$page: cita R10" || fail "$page: sin cita R10"
done
grep -q "EXPONENT" "$MP/app/(billing)/pricing/page.tsx" && ok "pricing: precio con exponente (PAY-004)" || fail "pricing: formatPrice sin exponente"

# ── L3 — Layer 3 real: eventos firmados válido / forjado / replay ─────
echo ""
echo "L3 — webhook-mercadopago.test.mjs contra el verify.ts del template (L-010)"
if MP_VERIFY_PATH="$V" node --experimental-strip-types "$SHARED/tests/payments/webhook-mercadopago.test.mjs" >/tmp/mp-l3.out 2>&1; then
  ok "Layer 3: válido pasa · forjado / secret incorrecto / sin header / replay / request-id alterado se rechazan ($(grep -c '✓' /tmp/mp-l3.out) casos)"
else
  fail "Layer 3 falló: $(tail -3 /tmp/mp-l3.out | tr '\n' ' ')"
fi

# ── Prompts + SKILL citations ────────────────────────────────────────
echo ""
echo "L2 — prompts + citations"
for p in setup-mercadopago; do
  grep -q "find-docs" "$SKILL_DIR/prompts/$p.md" && grep -q "resolve-library-id" "$SKILL_DIR/prompts/$p.md" && ok "$p.md: find-docs (R13)" || fail "$p.md: find-docs missing"
done
grep -q "mercadopago" "$SKILL_DIR/prompts/decision-tree.md" && grep -q "advise.js" "$SKILL_DIR/prompts/decision-tree.md" && ok "decision-tree: ranking determinista + Mode C" || fail "decision-tree sin advise.js / Mode C"
for cite in R-005 R10 R13 R14 L-001 L-002 L-003 D-010 D-038 R-012 PAY-006; do
  grep -q "$cite" "$SKILL_DIR/SKILL.md" && ok "SKILL.md cita $cite" || fail "SKILL.md sin cita $cite"
done

echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-payments dry-run-mercadopago: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-payments dry-run-mercadopago: $FAIL failures"
  exit 1
fi
