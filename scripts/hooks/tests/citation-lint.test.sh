#!/usr/bin/env bash
# Test scripts/citation-lint.sh
# Cases:
#   1. Markdown without citation but mentions known lib → 1+ warning, exit 0
#   2. Markdown with [docs:supabase] near mention → 0 warnings, exit 0
# (R13 is advisory — exit code is always 0)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/citation-lint.sh"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── citation-lint tests ──"

# ─── C1: mention without citation → warning ─────────────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  cat > test-no-cite.md <<'MD'
# Test no citation

We use supabase for everything.

This paragraph mentions supabase again without a citation.
MD
  output=$(bash "$SCRIPT" test-no-cite.md 2>&1)
  echo "$output"
) > /tmp/forja-test-cl-c1.out 2>&1
if grep -q "supabase' mentioned" /tmp/forja-test-cl-c1.out; then
  echo -e "  \033[0;32mPASS\033[0m  C1: mention without citation → warning emitted"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C1: expected warning"
  cat /tmp/forja-test-cl-c1.out | sed 's|^|        |'
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-cl-c1.out

# ─── C2: mention with [docs:supabase] near it → no warning ──────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  cat > test-with-cite.md <<'MD'
# Test with citation

We use supabase [docs:supabase] for everything.
MD
  output=$(bash "$SCRIPT" test-with-cite.md 2>&1)
  echo "$output"
) > /tmp/forja-test-cl-c2.out 2>&1
if grep -q "Warnings: 0" /tmp/forja-test-cl-c2.out; then
  echo -e "  \033[0;32mPASS\033[0m  C2: mention + [docs:supabase] near → 0 warnings"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C2: expected 0 warnings"
  cat /tmp/forja-test-cl-c2.out | sed 's|^|        |'
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-cl-c2.out

echo ""
echo "citation-lint: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
