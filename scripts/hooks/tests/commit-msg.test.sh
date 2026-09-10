#!/usr/bin/env bash
# Test scripts/hooks/commit-msg
# Cases:
#   1. feat(F2-S7): description válida → exit 0
#   2. "just text without format" → exit 1 (R2)
#   3. evaluator(D-003): write decision → exit 0

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/commit-msg"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── commit-msg hook tests ──"

run_msg() {
  local msg="$1"
  local sb
  sb=$(mk_sandbox)
  (
    cd "$sb"
    echo "x" > somefile.txt
    git add somefile.txt
    echo "$msg" > .git/COMMIT_EDITMSG
    bash "$HOOK" .git/COMMIT_EDITMSG
  )
  local rc=$?
  rm_sandbox "$sb"
  return "$rc"
}

# C1: valid feat
if run_msg "feat(F2-S7): description that is at least 10 chars long" >/dev/null 2>&1; then
  echo -e "  \033[0;32mPASS\033[0m  C1: feat(F2-S7): valid description → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C1: expected exit 0, got $?"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi

# C2: malformed
output=$(run_msg "just text without format" 2>&1) && rc=0 || rc=$?
if [[ "$rc" -eq 1 ]] && echo "$output" | grep -q "R2 violación"; then
  echo -e "  \033[0;32mPASS\033[0m  C2: malformed message → exit 1 with R2 message"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C2: expected exit 1 + R2 message"
  echo "        rc=$rc output=$output" | head -3
  TESTS_FAIL=$((TESTS_FAIL+1))
fi

# C3: evaluator type
if run_msg "evaluator(D-003): record sequencing decision Phase 4 first" >/dev/null 2>&1; then
  echo -e "  \033[0;32mPASS\033[0m  C3: evaluator(D-003): valid → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C3: expected exit 0, got $?"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi

# C4 (bonus): R5 — memory/** modified but scope=auth → exit 1
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "## new" >> .claude/memory/skills.md
  git add .claude/memory/skills.md
  echo "feat(auth): wrong scope for memory diff and long enough" > .git/COMMIT_EDITMSG
  bash "$HOOK" .git/COMMIT_EDITMSG 2>&1
) > /tmp/forja-test-cm-c4.out 2>&1 ; cm_c4_exit=$?
if [[ "$cm_c4_exit" -eq 1 ]] && grep -q "R5 violación" /tmp/forja-test-cm-c4.out; then
  echo -e "  \033[0;32mPASS\033[0m  C4 (bonus): memory diff + scope=auth → exit 1 with R5 message"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C4 (bonus): expected exit 1 + R5 message, got $cm_c4_exit"
  cat /tmp/forja-test-cm-c4.out | sed 's|^|        |'
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-cm-c4.out

# C5: R19 — SPEC.md staged pero scope ajeno → exit 1
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "## Vision" > SPEC.md
  git add SPEC.md
  echo "feat(auth): touches spec without spec scope long enough" > .git/COMMIT_EDITMSG
  bash "$HOOK" .git/COMMIT_EDITMSG 2>&1
) > /tmp/forja-test-cm-c5.out 2>&1 ; cm_c5_exit=$?
if [[ "$cm_c5_exit" -eq 1 ]] && grep -q "R19 violación" /tmp/forja-test-cm-c5.out; then
  echo -e "  \033[0;32mPASS\033[0m  C5: R19 spec staged + scope=auth → exit 1 with R19 message"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C5: expected exit 1 + R19 message, got $cm_c5_exit"
  cat /tmp/forja-test-cm-c5.out | sed 's|^|        |'
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"
rm -f /tmp/forja-test-cm-c5.out

# C6: R19 — SPEC.md staged con type spec → exit 0 (R2 acepta el type nuevo)
sb=$(mk_sandbox)
(
  cd "$sb"
  echo "## Vision" > SPEC.md
  git add SPEC.md
  echo "spec(s1-vision): ajustar la vision del producto tras kickoff" > .git/COMMIT_EDITMSG
  bash "$HOOK" .git/COMMIT_EDITMSG
) >/dev/null 2>&1 ; cm_c6_exit=$?
if [[ "$cm_c6_exit" -eq 0 ]]; then
  echo -e "  \033[0;32mPASS\033[0m  C6: R19 spec staged + type=spec → exit 0"
  TESTS_PASS=$((TESTS_PASS+1))
else
  echo -e "  \033[0;31mFAIL\033[0m  C6: expected exit 0, got $cm_c6_exit"
  TESTS_FAIL=$((TESTS_FAIL+1))
fi
rm_sandbox "$sb"

echo ""
echo "commit-msg: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
