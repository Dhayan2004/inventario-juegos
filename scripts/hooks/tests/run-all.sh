#!/usr/bin/env bash
# Forja hook test runner
# Runs each *.test.sh in scripts/hooks/tests/ and aggregates results.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
else
  GREEN=''; RED=''; NC=''
fi

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_FILES=()

echo "Forja hook test suite"
echo "═════════════════════"
echo ""

for test_file in "$SCRIPT_DIR"/*.test.sh; do
  [[ -f "$test_file" ]] || continue
  name=$(basename "$test_file" .test.sh)
  echo "▸ $name"
  output=$(bash "$test_file" 2>&1)
  rc=$?
  echo "$output" | sed 's|^|  |'
  # Parse summary line: "<name>: N passed, M failed"
  summary=$(echo "$output" | tail -1)
  pass=$(echo "$summary" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo 0)
  fail=$(echo "$summary" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))
  if [[ "$rc" -ne 0 ]]; then
    FAILED_FILES+=("$name")
  fi
  echo ""
done

# Also include integration test if present
INT_TEST="$SCRIPT_DIR/integration.sh"
if [[ -f "$INT_TEST" ]]; then
  echo "▸ integration"
  output=$(bash "$INT_TEST" 2>&1)
  rc=$?
  echo "$output" | sed 's|^|  |'
  if [[ "$rc" -eq 0 ]]; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_FILES+=("integration")
  fi
  echo ""
fi

echo "═════════════════════"
echo -e "Total: ${GREEN}${TOTAL_PASS} passed${NC}, ${RED}${TOTAL_FAIL} failed${NC}"
if [[ "$TOTAL_FAIL" -gt 0 ]]; then
  echo "Failed test files:"
  for f in "${FAILED_FILES[@]}"; do echo "  - $f"; done
  exit 1
fi
exit 0
