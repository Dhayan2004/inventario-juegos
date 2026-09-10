#!/usr/bin/env bash
# Test scripts/preflight.sh
# Cases:
#   1. Sandbox satisfies Bootstrap Contract (3 features, skills.md, .no-brand-yet) → exit 0
#   2. Sandbox missing skills.md → exit 1

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/preflight.sh"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── preflight tests ──"

# ─── C1: contract satisfied ─────────────────────────────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  mkdir -p brand
  touch brand/.no-brand-yet
  bash "$SCRIPT" >/dev/null 2>&1
) ; c1_exit=$?
if [[ "$c1_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C1: Bootstrap Contract satisfied → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C1: expected exit 0, got $c1_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

# ─── C2: contract violated (skills.md missing) ──────────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  rm .claude/memory/skills.md
  output=$(bash "$SCRIPT" 2>&1) && exit_code=0 || exit_code=$?
  echo "$exit_code"
  echo "$output"
) > /tmp/forja-test-pf-c2.out 2>&1
c2_exit=$(head -1 /tmp/forja-test-pf-c2.out)
if [[ "$c2_exit" -eq 1 ]] && grep -q "skills.md missing\|NOT satisfied" /tmp/forja-test-pf-c2.out; then
  echo -e "  \033[0;32mPASS\033[0m  C2: skills.md missing → exit 1 with halt message"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C2: expected exit 1 + halt message, got exit $c2_exit"
  cat /tmp/forja-test-pf-c2.out | sed 's|^|        |'
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-pf-c2.out

echo ""
echo "preflight: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
