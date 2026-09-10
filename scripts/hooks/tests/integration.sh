#!/usr/bin/env bash
# Forja hooks integration test
# E2E: install hooks in a fresh /tmp repo, attempt invalid commit (rejected),
# attempt valid commit (accepted), cleanup.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
else
  GREEN=''; RED=''; NC=''
fi

PASS=0
FAIL=0
NOTES=()

ok()   { echo -e "  ${GREEN}PASS${NC}  $1"; PASS=$((PASS+1)); }
ng()   { echo -e "  ${RED}FAIL${NC}  $1"; NOTES+=("$1: $2"); FAIL=$((FAIL+1)); }

echo "── integration test (install + commit roundtrip) ──"

SB=$(mktemp -d "${TMPDIR:-/tmp}/forja-hooks-integration-XXXXXX")
trap 'rm -rf "$SB"' EXIT

# Bootstrap a Forja-shaped repo
(
  cd "$SB"
  git init -q
  git config user.email "test@forja.local"
  git config user.name "Forja Test"
  mkdir -p .claude/memory .claude/skills/find-docs brand
  cat > feature_list.json <<'JSON'
{
  "schema_version": "1.0.0",
  "phase": "test",
  "features": [
    {"id": "T-1", "behavior": "stub", "verification": "true", "state": "active", "branch": "feature/t1"},
    {"id": "T-2", "behavior": "stub", "verification": "true", "state": "queued", "branch": "feature/t2"},
    {"id": "T-3", "behavior": "stub", "verification": "true", "state": "queued", "branch": "feature/t3"}
  ]
}
JSON
  cat > .claude/memory/skills.md <<'MD'
# Skills Registry

## Core skills (1)

### test-skill
- **Tier:** core
MD
  cat > .claude/skills/find-docs/references.md <<'MD'
# find-docs cache

| libraryName | libraryId | Versión | One-line |
|-------------|-----------|---------|----------|
| supabase | /supabase/supabase | latest | test |
MD
  touch brand/.no-brand-yet
  # Bootstrap commit before installing hooks
  git add -A
  git commit -q -m "chore(test): bootstrap"
)

# Copy hook scripts into the sandbox so install-hooks can find them
cp -R "$REPO_ROOT/scripts" "$SB/scripts"

# Install hooks
(
  cd "$SB"
  bash scripts/install-hooks.sh
) > /tmp/forja-int-install.out 2>&1
if grep -q "Forja hooks installed:" /tmp/forja-int-install.out; then
  ok "install-hooks reports successful install"
else
  ng "install-hooks didn't report success" "$(head -3 /tmp/forja-int-install.out)"
fi

# --check should pass
(
  cd "$SB"
  bash scripts/install-hooks.sh --check
) > /tmp/forja-int-check.out 2>&1 ; check_exit=$?
if [[ "$check_exit" -eq 0 ]]; then
  ok "install-hooks --check after install → exit 0"
else
  ng "install-hooks --check expected exit 0" "got $check_exit"
fi

# Run preflight in sandbox — should pass
(
  cd "$SB"
  bash scripts/preflight.sh
) > /tmp/forja-int-pf.out 2>&1 ; pf_exit=$?
if [[ "$pf_exit" -eq 0 ]]; then
  ok "preflight in sandbox → exit 0 (Bootstrap Contract satisfied)"
else
  ng "preflight expected exit 0" "got $pf_exit"
fi

# Try invalid commit (no scope) — should be rejected
(
  cd "$SB"
  echo "x" > some.txt
  git add some.txt
  git commit -m "no convention here at all" 2>&1
) > /tmp/forja-int-bad.out 2>&1 ; bad_exit=$?
if [[ "$bad_exit" -ne 0 ]] && grep -q "R2 violación" /tmp/forja-int-bad.out; then
  ok "invalid commit message rejected by commit-msg (R2)"
else
  ng "invalid commit should be rejected" "exit=$bad_exit output=$(head -3 /tmp/forja-int-bad.out)"
fi

# Try valid commit — should succeed
(
  cd "$SB"
  git commit -m "feat(test): integration suite passes through hooks" 2>&1
) > /tmp/forja-int-good.out 2>&1 ; good_exit=$?
if [[ "$good_exit" -eq 0 ]]; then
  ok "valid commit accepted (feat type, scope, ≥10 chars)"
else
  ng "valid commit should pass" "exit=$good_exit output=$(head -3 /tmp/forja-int-good.out)"
fi

# Try memory diff with wrong scope — should be rejected
(
  cd "$SB"
  echo "## new" >> .claude/memory/skills.md
  git add .claude/memory/skills.md
  git commit -m "feat(auth): tries to write memory but scope is wrong" 2>&1
) > /tmp/forja-int-r5.out 2>&1 ; r5_exit=$?
if [[ "$r5_exit" -ne 0 ]] && grep -q "R5 violación" /tmp/forja-int-r5.out; then
  ok "memory diff with non-evaluator/memory scope → rejected by R5"
else
  ng "R5 violation should reject" "exit=$r5_exit output=$(head -5 /tmp/forja-int-r5.out)"
fi

# Try memory diff with scope=memory — should pass
(
  cd "$SB"
  git commit -m "chore(memory): record E-001 stub for integration test"
) > /tmp/forja-int-r5-good.out 2>&1 ; r5_good_exit=$?
if [[ "$r5_good_exit" -eq 0 ]]; then
  ok "memory diff with scope=memory → accepted"
else
  ng "scope=memory should pass" "exit=$r5_good_exit output=$(head -3 /tmp/forja-int-r5-good.out)"
fi

# Cleanup tmp output files
rm -f /tmp/forja-int-install.out /tmp/forja-int-check.out /tmp/forja-int-pf.out \
      /tmp/forja-int-bad.out /tmp/forja-int-good.out /tmp/forja-int-r5.out \
      /tmp/forja-int-r5-good.out

echo ""
echo "integration: ${PASS} passed, ${FAIL} failed"

if [[ "$FAIL" -gt 0 ]]; then
  echo "Notes:"
  for n in "${NOTES[@]}"; do echo "  - $n"; done
  exit 1
fi
exit 0
