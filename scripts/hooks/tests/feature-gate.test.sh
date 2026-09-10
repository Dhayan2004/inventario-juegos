#!/usr/bin/env bash
# Test the AP8 feature-gate guard in scripts/hooks/pre-commit.
#
# Cases:
#   C1. no .github/workflows/ci.yml → feature → passing without ci_run → exit 0 (safe degradation)
#   C2. ci.yml present + NEW transition to passing WITHOUT ci_run.success → exit 1 (AP8)
#   C3. ci.yml present + NEW transition to passing WITH ci_run.conclusion=success → exit 0
#   C4. ci.yml present + feature ALREADY passing in HEAD (no new transition) → exit 0

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PRE="$REPO_ROOT/scripts/hooks/pre-commit"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── AP8 feature-gate tests ──"

# helper: write feature_list.json with T-1 in a given state (+ optional ci_run), keep R1 (1 active max)
write_fl() { # $1=dir $2=t1_state $3=ci_run_json(optional)
  local ci="${3:-null}"
  cat > "$1/feature_list.json" <<JSON
{ "schema_version":"1.0.0","phase":"test","features":[
  {"id":"T-1","behavior":"stub","verification":"true","state":"$2","ci_run":$ci},
  {"id":"T-2","behavior":"stub","verification":"true","state":"queued"},
  {"id":"T-3","behavior":"stub","verification":"true","state":"queued"}
]}
JSON
}

# ─── C1: no ci.yml → passing without ci_run → exit 0 ───────────────────────
sb=$(mk_sandbox)
( cd "$sb"; write_fl "$sb" passing; git add feature_list.json
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 0 ]]; then echo -e "  ${GREEN}PASS${NC}  C1: no ci.yml → passing sin ci_run → exit 0"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C1: expected 0, got $rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C2: ci.yml + new passing WITHOUT ci_run → exit 1 (AP8) ─────────────────
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .github/workflows; echo "name: ci" > .github/workflows/ci.yml
  write_fl "$sb" passing; git add feature_list.json
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 1 ]]; then echo -e "  ${GREEN}PASS${NC}  C2: ci.yml + passing sin ci_run → exit 1 (AP8)"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C2: expected 1, got $rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C3: ci.yml + new passing WITH ci_run success → exit 0 ─────────────────
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .github/workflows; echo "name: ci" > .github/workflows/ci.yml
  write_fl "$sb" passing '{"run_id":1,"sha":"abc","conclusion":"success"}'; git add feature_list.json
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 0 ]]; then echo -e "  ${GREEN}PASS${NC}  C3: ci.yml + ci_run.success → exit 0"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C3: expected 0, got $rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C4: ci.yml + already passing in HEAD (no new transition) → exit 0 ─────
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .github/workflows; echo "name: ci" > .github/workflows/ci.yml
  # put T-1 passing (no ci_run) into HEAD first
  write_fl "$sb" passing; git add -A; git commit -q -m "chore(test): t1 passing in head" --no-verify
  # re-stage a VALID, DIFFERENT feature_list where T-1 is STILL passing (no new transition)
  cat > feature_list.json <<'JSON'
{ "schema_version":"1.0.0","phase":"test","features":[
  {"id":"T-1","behavior":"stub","verification":"true","state":"passing","ci_run":null},
  {"id":"T-2","behavior":"stub edited","verification":"true","state":"queued"},
  {"id":"T-3","behavior":"stub","verification":"true","state":"queued"}
]}
JSON
  git add feature_list.json
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 0 ]]; then echo -e "  ${GREEN}PASS${NC}  C4: already-passing in HEAD → exit 0 (no new transition)"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C4: expected 0, got $rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C5: ci.yml + malformed staged feature_list.json → exit 1 (fail-closed) ─
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .github/workflows; echo "name: ci" > .github/workflows/ci.yml
  echo '{ this is not json' > feature_list.json; git add feature_list.json
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 1 ]]; then echo -e "  ${GREEN}PASS${NC}  C5: ci.yml + malformed feature_list → exit 1 (fail-closed)"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C5: expected 1, got $rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

echo ""
echo "feature-gate: $TESTS_PASS passed, $TESTS_FAIL failed"
[[ "$TESTS_FAIL" -eq 0 ]]
