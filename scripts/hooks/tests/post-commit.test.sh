#!/usr/bin/env bash
# Test scripts/hooks/post-commit (event sealing) + the R17 plan guard in pre-commit.
#
# Cases:
#   C1. pre-commit: valid .plan/plan.json            → exit 0
#   C2. pre-commit: invalid .plan/plan.json          → exit 1 (R17 fail-closed)
#   C3. pre-commit: .plan/.inconsistent marker       → exit 1 (R17)
#   C4. pre-commit: no .plan/ at all                 → exit 0 (safe degradation)
#   C5. post-commit: seals commit:null events with HEAD hash
#   C6. post-commit: invalid plan.json → writes .inconsistent marker (next pre-commit blocks)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PRE="$REPO_ROOT/scripts/hooks/pre-commit"
POST="$REPO_ROOT/scripts/hooks/post-commit"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── post-commit + R17 plan guard tests ──"

VALID_PLAN='{"_meta":{"schema_version":"2.0.0"},"project":{"name":"T — P","currentStage":{}},"phases":[{"id":"F1","subphases":[{"id":"F1-S1","stories":[{"id":"F1-S1-US01","status":"pending","featureRefs":[]}]}]}]}'

# ─── C1: valid plan.json → pre-commit exit 0 ───────────────────────────────
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .plan; printf '%s' "$VALID_PLAN" > .plan/plan.json
  echo x > f.txt; git add -A
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
run_rc=$?
if [[ "$run_rc" -eq 0 ]]; then echo -e "  ${GREEN}PASS${NC}  C1: valid plan.json → exit 0"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C1: expected 0, got $run_rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C2: invalid plan.json → pre-commit exit 1 (R17) ───────────────────────
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .plan; echo '{ this is not json' > .plan/plan.json
  echo x > f.txt; git add f.txt
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
run_rc=$?
if [[ "$run_rc" -eq 1 ]]; then echo -e "  ${GREEN}PASS${NC}  C2: invalid plan.json → exit 1 (R17)"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C2: expected 1, got $run_rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C3: .inconsistent marker → pre-commit exit 1 (R17) ────────────────────
sb=$(mk_sandbox)
( cd "$sb"; mkdir -p .plan; printf '%s' "$VALID_PLAN" > .plan/plan.json; echo "deadbeef" > .plan/.inconsistent
  echo x > f.txt; git add f.txt
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
run_rc=$?
if [[ "$run_rc" -eq 1 ]]; then echo -e "  ${GREEN}PASS${NC}  C3: .inconsistent marker → exit 1 (R17)"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C3: expected 1, got $run_rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C4: no .plan/ → pre-commit exit 0 (degradation) ───────────────────────
sb=$(mk_sandbox)
( cd "$sb"; echo x > f.txt; git add f.txt
  cp "$PRE" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
  bash .git/hooks/pre-commit ) >/dev/null 2>&1
run_rc=$?
if [[ "$run_rc" -eq 0 ]]; then echo -e "  ${GREEN}PASS${NC}  C4: no .plan/ → exit 0 (degradation)"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C4: expected 0, got $run_rc"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C5: post-commit seals commit:null events with HEAD hash ───────────────
sb=$(mk_sandbox)
sealed=$(
  cd "$sb"; mkdir -p .plan; printf '%s' "$VALID_PLAN" > .plan/plan.json
  printf '%s\n' '{"ts":"2026-06-30T10:00:00Z","actor":"agent","type":"note","target":"F1-S1-US01","body":"x","commit":null}' > .plan/activity.log.jsonl
  cp "$POST" .git/hooks/post-commit && chmod +x .git/hooks/post-commit
  git add -A >/dev/null 2>&1; git commit -q -m "chore(test): seal" --no-verify >/dev/null 2>&1
  head_sha=$(git rev-parse HEAD)
  node -e 'const fs=require("fs");const l=JSON.parse(fs.readFileSync(".plan/activity.log.jsonl","utf8").trim());console.log(l.commit===process.argv[1]?"SEALED":"UNSEALED:"+l.commit)' "$head_sha"
)
if [[ "$sealed" == "SEALED" ]]; then echo -e "  ${GREEN}PASS${NC}  C5: post-commit seals event with HEAD hash"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C5: event not sealed ($sealed)"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

# ─── C6: post-commit on invalid plan.json writes .inconsistent marker ──────
sb=$(mk_sandbox)
marked=$(
  cd "$sb"; mkdir -p .plan; echo '{ broken' > .plan/plan.json
  cp "$POST" .git/hooks/post-commit && chmod +x .git/hooks/post-commit
  git add -A >/dev/null 2>&1; git commit -q -m "chore(test): broken plan" --no-verify >/dev/null 2>&1
  [[ -f .plan/.inconsistent ]] && echo "MARKED" || echo "NOT_MARKED"
)
if [[ "$marked" == "MARKED" ]]; then echo -e "  ${GREEN}PASS${NC}  C6: post-commit marks inconsistent plan"; TESTS_PASS=$((TESTS_PASS+1));
else echo -e "  ${RED}FAIL${NC}  C6: marker not written ($marked)"; TESTS_FAIL=$((TESTS_FAIL+1)); fi
rm_sandbox "$sb"

echo ""
echo "post-commit: $TESTS_PASS passed, $TESTS_FAIL failed"
[[ "$TESTS_FAIL" -eq 0 ]]
