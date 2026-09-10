#!/usr/bin/env bash
# Test scripts/hooks/pre-commit
#
# pre-commit enforces R1 only (WIP=1). R5 lives in commit-msg because
# pre-commit runs before git writes the -m message to COMMIT_EDITMSG;
# any R5 check here would read a stale message. See D-003.
#
# Cases:
#   1. 1 feature active, no memory diff → exit 0
#   2. 2 features active → exit 1 (R1 violation)
#   3. memory/** diff alone (no R5 check in pre-commit) → exit 0
#       (R5 enforcement happens in commit-msg, see commit-msg.test.sh C4)
#   4. R15/U-14a: placeholder de doc (sk_test_REPLACE) → exit 0 (allowlist)
#   5. R15/U-14b: placeholder + llave real en el MISMO archivo → exit 1
#       (regresión BSD grep -q/-v que dejaba pasar secretos)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/pre-commit"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── pre-commit hook tests ──"

# ─── Case 1: 1 active feature, no memory diff → exit 0 ──────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "x" > somefile.txt
  git add somefile.txt
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit
) >/dev/null 2>&1
case_1_exit=$?
if [[ "$case_1_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C1: 1 active feature + no memory diff → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C1: expected exit 0, got $case_1_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

# ─── Case 2: 2 active features → exit 1 (R1) ────────────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  python3 -c "
import json, pathlib
p = pathlib.Path('feature_list.json')
d = json.loads(p.read_text())
d['features'][0]['state'] = 'active'
d['features'][1]['state'] = 'active'
p.write_text(json.dumps(d, indent=2))
"
  echo "x" > somefile.txt
  git add somefile.txt feature_list.json
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  output=$(bash .git/hooks/pre-commit 2>&1) && exit_code=0 || exit_code=$?
  echo "$exit_code"
  echo "$output" | head -3
) > /tmp/forja-test-c2.out 2>&1
case_2_exit=$(head -1 /tmp/forja-test-c2.out)
if [[ "$case_2_exit" -eq 1 ]] && grep -q "R1 violación" /tmp/forja-test-c2.out; then
  echo -e "  \033[0;32mPASS\033[0m  C2: 2 active features → exit 1 with R1 message"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C2: expected exit 1 + R1 message, got exit $case_2_exit"
  cat /tmp/forja-test-c2.out | sed 's|^|        |'
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-c2.out

# ─── Case 3: memory/** diff alone → pre-commit exits 0 (R5 in commit-msg) ───
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "## E-001" >> .claude/memory/skills.md
  git add .claude/memory/skills.md
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit
) >/dev/null 2>&1
case_3_exit=$?
if [[ "$case_3_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C3: memory/** diff → exit 0 (pre-commit defers R5 to commit-msg)"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C3: expected exit 0, got $case_3_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

# ─── Case 4: R15/U-14a — placeholder de doc (sk_test_REPLACE) → exit 0 ──────
sb=$(mk_sandbox)
(
  cd "$sb"
  printf 'STRIPE_SECRET_KEY=sk_test_REPLACE\n' > setup-doc.md
  git add setup-doc.md
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit
) >/dev/null 2>&1
case_4_exit=$?
if [[ "$case_4_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C4: U-14a placeholder de doc (sk_test_REPLACE) → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C4: expected exit 0 (placeholder allowlisted), got $case_4_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

# ─── Case 5: R15/U-14b — placeholder + llave real en el MISMO archivo → 1 ───
sb=$(mk_sandbox)
(
  cd "$sb"
  printf 'STRIPE_SECRET_KEY=sk_test_REPLACE\nconst k = "sk_live_9aB7cD6eF5gH4iJ3kL"\n' > mixed.ts
  git add mixed.ts
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  output=$(bash .git/hooks/pre-commit 2>&1) && exit_code=0 || exit_code=$?
  echo "$exit_code"
  echo "$output"
) > /tmp/forja-test-c5-r15.out 2>&1
case_5_exit=$(head -1 /tmp/forja-test-c5-r15.out)
if [[ "$case_5_exit" -eq 1 ]] && grep -q "R15 violación" /tmp/forja-test-c5-r15.out; then
  echo -e "  \033[0;32mPASS\033[0m  C5: U-14b placeholder + llave real → exit 1 (fail-closed)"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C5: expected exit 1 + R15 (llave real tras placeholder), got exit $case_5_exit"
  sed 's|^|        |' /tmp/forja-test-c5-r15.out
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-c5-r15.out

# ─── Case 6: R19 — spec + código mezclados → exit 1 ─────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "## Vision" > SPEC.md
  mkdir -p src && echo "export {}" > src/index.ts
  git add SPEC.md src/index.ts
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  output=$(bash .git/hooks/pre-commit 2>&1) && exit_code=0 || exit_code=$?
  echo "$exit_code"
  echo "$output"
) > /tmp/forja-test-c6-r19.out 2>&1
case_6_exit=$(head -1 /tmp/forja-test-c6-r19.out)
if [[ "$case_6_exit" -eq 1 ]] && grep -q "R19 violación" /tmp/forja-test-c6-r19.out; then
  echo -e "  \033[0;32mPASS\033[0m  C6: R19 spec + código mezclados → exit 1"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C6: expected exit 1 + R19, got exit $case_6_exit"
  sed 's|^|        |' /tmp/forja-test-c6-r19.out
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-c6-r19.out

# ─── Case 7: R19 — spec solo → exit 0 ───────────────────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "## Vision" > SPEC.md
  git add SPEC.md
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit
) >/dev/null 2>&1
case_7_exit=$?
if [[ "$case_7_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C7: R19 spec solo (sin código) → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C7: expected exit 0, got $case_7_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

# ─── Case 8: D-038 — llave de EJEMPLO de la doc (sk_test_BQokikJOvBi…) en catálogo vendored → exit 0 ──
sb=$(mk_sandbox)
(
  cd "$sb"
  mkdir -p vendor && printf '{"secret_key_pattern":"^sk_(test|live)_[A-Za-z0-9]{24,}$","example":"sk_test_BQokikJOvBiI2HlWgH4olfQ2"}\n' > vendor/paymongo.json
  git add vendor/paymongo.json
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit
) >/dev/null 2>&1
case_8_exit=$?
if [[ "$case_8_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C8: D-038 llave de ejemplo de la doc (BQokikJOvBi) allowlisted → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C8: expected exit 0 (doc example key allowlisted), got $case_8_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

# ─── Case 9: D-038 — llave LIVE de Mercado Pago (APP_USR-…) staged → exit 1 (R15) ──
sb=$(mk_sandbox)
(
  cd "$sb"
  printf 'const mp = "APP_USR-1234567890abcdef-090312-9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c-123456789"\n' > mp.ts
  git add mp.ts
  cp "$HOOK" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit
) >/tmp/forja-test-c9.out 2>&1
case_9_exit=$?
if [[ "$case_9_exit" -eq 1 ]] && grep -q "R15 violación" /tmp/forja-test-c9.out; then
  echo -e "  \033[0;32mPASS\033[0m  C9: D-038 llave live de Mercado Pago (APP_USR-…) → exit 1 (R15)"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C9: expected exit 1 + R15 (APP_USR live key), got $case_9_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

echo ""
echo "pre-commit: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
