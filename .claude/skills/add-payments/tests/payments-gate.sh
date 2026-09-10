#!/usr/bin/env bash
# add-payments payments-gate — los 8 checks PAY-001..008 del threat-db, en ripgrep/python
# (port de los validadores de PagoKit 0.2.2, MIT — hooks/checks/*.js; regex citadas por RULE_ID).
#
# Corre sobre los templates de los 3 proveedores (deben PASAR) y sobre
# tests/fixtures/insecure/ (debe FALLAR 8/8 — un gate que nunca falla es decoración, L-010).
#
#   PAY-001 webhook_has_signature      — handler de webhook sin verificador (constructEvent / verify*Signature /
#                                        createHmac+timingSafeEqual / validateEvent)   [webhook-has-signature]
#   PAY-002 raw_body_before_verify     — request.json() en un handler de webhook que verifica sobre el body
#                                        (Stripe/Polar); MP verifica headers+query (exento)  [raw-body]
#   PAY-003 idempotency_canonical      — Math.random()/Date.now() cerca de idempotency key   [idempotency-canonical]
#   PAY-004 minor_units                — `* 100` sobre un monto sin lógica de exponente        [minor-units]
#   PAY-005 timing_safe_compare        — firma/hmac comparada con ==/===/!=/!==               [no-plaintext-secret-compare]
#   PAY-006 no_refund_on_irreversible  — refunds.create en rama de rail irreversible (spei/oxxo/pix/pse)
#                                                                                              [no-refund-on-irreversible]
#   PAY-007 webhook_secret_not_api_key — HMAC con la API key (MP_ACCESS_TOKEN/STRIPE_SECRET_KEY) en vez del
#                                        webhook secret                                        [webhook-secret-not-api-key]
#   PAY-008 no_client_amount_trust     — body.amount/req.json().amount → payload del proveedor  [no-client-amount-trust]
#
# Usage:  bash .claude/skills/add-payments/tests/payments-gate.sh [dir…]
#   sin args → templates/{stripe,polar,mercadopago} (pass) + tests/fixtures/insecure (fail)
#   con args → corre los checks sobre esos dirs y falla si hay findings (modo el-guardian / /temple)
# Exit 0 = gate PASS

set -uo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_gate() {
  TARGET_DIR="$1" EXPECT="$2" python3 - <<'PYCHK'
import os, re, glob, sys
target = os.environ['TARGET_DIR']; expect = os.environ['EXPECT']
files = sorted(glob.glob(os.path.join(target, '**', '*.ts'), recursive=True) + glob.glob(os.path.join(target, '**', '*.tsx'), recursive=True))
files = [f for f in files if '/vendor/' not in f and '/node_modules/' not in f]

def strip(src):  # comentarios fuera (bloque + línea, incl. trailing; no toca 'https://'), strings dentro
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.DOTALL)
    return re.sub(r'(?<![:\w])//[^\n]*', '', src)
raw = {f: open(f, encoding='utf-8').read() for f in files}
code = {f: strip(t) for f, t in raw.items()}
rel = lambda f: os.path.relpath(f, target)

WEBHOOK_PATH = re.compile(r'/webhooks?/|webhook\.ts$|/notifications?/|/ipn/', re.I)
POST_HANDLER = re.compile(r'export\s+async\s+function\s+POST\s*\(')
VERIFIER = re.compile(r'constructEvent\s*\(|verify[A-Za-z]*Signature\s*\(|validateEvent\s*\(|\bverifyMpSignature\s*\(|createHmac\s*\(|timingSafeEqual\s*\(|\bwh\.verify\s*\(|Webhook\s*\([^)]*\)\s*\.verify')
FIELD_CONCAT = re.compile(r'buildMpManifest|hmac_field_concat|verifyMpSignature')  # familia que verifica headers+query, no body
findings = {k: [] for k in ['PAY-001','PAY-002','PAY-003','PAY-004','PAY-005','PAY-006','PAY-007','PAY-008']}

for f, c in code.items():
    is_webhook = bool(WEBHOOK_PATH.search(f)) and bool(POST_HANDLER.search(c))
    if is_webhook:
        # PAY-001
        if not VERIFIER.search(c): findings['PAY-001'].append(rel(f))
        # PAY-002 — solo familias que firman el body
        if not FIELD_CONCAT.search(c) and re.search(r'\b(request|req)\.json\s*\(\s*\)', c):
            findings['PAY-002'].append(rel(f))
    # PAY-003 — generador débil a ±2 líneas de "idempotency"
    lines = c.split('\n')
    for i, ln in enumerate(lines):
        if re.search(r'idempotency[_-]?key', ln, re.I):
            window = '\n'.join(lines[max(0, i-2): i+3])
            if re.search(r'Math\.random\s*\(|Date\.now\s*\(', window):
                findings['PAY-003'].append(f'{rel(f)}:{i+1}'); break
    # PAY-004 — `* 100` sobre monto sin lógica de exponente en el archivo
    if re.search(r'\b(amount|monto|price|total|transaction_amount|unit_price)\w*\)?\s*\*\s*100(?![\d.])', c) \
       and not re.search(r'exponent|toMinorUnits|toMajorUnits|minor[_-]?unit|zero[_-]?decimal|10\s*\*\*', c, re.I):
        findings['PAY-004'].append(rel(f))
    # PAY-005 — comparación no constante de firma/hmac/digest
    for i, ln in enumerate(lines):
        if re.search(r'(?:!==|===|!=|==)', ln) and re.search(r'\b(sig|signature|hmac|digest|expected|firma|v1|checksum)\w*\b', ln, re.I) \
           and not re.search(r'timingSafeEqual|constantTime|length|typeof|===\s*(?:null|undefined|true|false|\'|")', ln) \
           and not re.search(r'\.(status|ok|reason|type|action)\b', ln):
            findings['PAY-005'].append(f'{rel(f)}:{i+1}'); break
    # PAY-006 — refund en rama de rail irreversible
    for m in re.finditer(r"case\s*['\"](spei|oxxo|pix|pse|boleto|ticket|bank_transfer)['\"]\s*:(.{0,300})", c, re.S):
        if re.search(r'refunds?\s*\.\s*create\s*\(|\.refund\s*\(|mpRefund\.create', m.group(2)) and not re.search(r'status\s*[:(]\s*4\d\d|throw|payout|unsupported', m.group(2), re.I):
            findings['PAY-006'].append(f'{rel(f)} (case {m.group(1)})'); break
    # PAY-007 — HMAC con API key
    if re.search(r'createHmac\s*\([^)]*(MP_ACCESS_TOKEN|STRIPE_SECRET_KEY|POLAR_ACCESS_TOKEN|LEMONSQUEEZY_API_KEY)', c):
        findings['PAY-007'].append(rel(f))
    # PAY-008 — monto del cliente hacia el proveedor
    if re.search(r'\b(body|input|json|data)\s*\.\s*(amount|monto|price|total|transaction_amount)\b', c) \
       and re.search(r'transaction_amount\s*:|unit_amount\s*:|amount\s*:\s*(?:amount|monto|total)\b|amount_in_cents\s*:', c) \
       and not re.search(r'PLANS\[|findUnique|\.from\(\s*[\'"](products|plans|prices)[\'"]', c):
        findings['PAY-008'].append(rel(f))

failed = [k for k, v in findings.items() if v]
for k in sorted(findings):
    v = findings[k]
    print(('  ✗ ' if v else '  ✓ ') + f'{k}: ' + (f'{len(v)} finding(s) — {v[:3]}' if v else 'clean'))
if expect == 'pass':
    sys.exit(0 if not failed else 1)
else:
    print(f'  • negative fixture: {len(failed)}/8 checks failed as expected' if len(failed) == 8 else f'  ✗ negative fixture: only {len(failed)}/8 fired ({sorted(set(findings) - set(failed))} silent) — gate lost its teeth')
    sys.exit(0 if len(failed) == 8 else 1)
PYCHK
}

PASS=0; FAIL=0
if [ $# -gt 0 ]; then
  for d in "$@"; do
    echo "── payments-gate → $d"
    if run_gate "$d" pass; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
  done
else
  for provider in stripe polar mercadopago; do
    echo "── payments-gate → templates/$provider (must PASS)"
    if run_gate "$SKILL_DIR/templates/$provider" pass; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
  done
  echo "── payments-gate → tests/fixtures/insecure (must FAIL 8/8, negative)"
  if run_gate "$SKILL_DIR/tests/fixtures/insecure" fail; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
fi

echo ""
echo "payments-gate: PASS $PASS · FAIL $FAIL"
[ "$FAIL" -eq 0 ] && echo "✅ payments-gate PASS" || { echo "❌ payments-gate FAILED"; exit 1; }
