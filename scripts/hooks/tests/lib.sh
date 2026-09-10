#!/usr/bin/env bash
# Forja hook test helpers
# Sourced by individual *.test.sh files

set -uo pipefail

# Colors (off if not a tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

# Counters (per file)
TESTS_PASS=0
TESTS_FAIL=0

# Run a test case.
#   $1: description
#   $2: expected exit code
#   $3...: command + args
run_case() {
  local desc="$1"; shift
  local expected="$1"; shift
  local actual
  local output
  output=$("$@" 2>&1) && actual=0 || actual=$?

  if [[ "$actual" -eq "$expected" ]]; then
    echo -e "  ${GREEN}PASS${NC}  $desc (exit $actual)"
    TESTS_PASS=$((TESTS_PASS+1))
  else
    echo -e "  ${RED}FAIL${NC}  $desc (expected exit $expected, got $actual)"
    if [[ -n "$output" ]]; then
      echo "        output: $(echo "$output" | head -3 | sed 's|^|        |')"
    fi
    TESTS_FAIL=$((TESTS_FAIL+1))
  fi
}

# Assert that the output of a command contains a substring.
#   $1: description
#   $2: substring to grep for
#   $3...: command + args
assert_output_contains() {
  local desc="$1"; shift
  local needle="$1"; shift
  local output
  output=$("$@" 2>&1 || true)
  if echo "$output" | grep -q -- "$needle"; then
    echo -e "  ${GREEN}PASS${NC}  $desc (matches '$needle')"
    TESTS_PASS=$((TESTS_PASS+1))
  else
    echo -e "  ${RED}FAIL${NC}  $desc (expected output containing '$needle')"
    echo "        output: $(echo "$output" | head -3 | sed 's|^|        |')"
    TESTS_FAIL=$((TESTS_FAIL+1))
  fi
}

# Create a sandbox repo at a fresh temp dir, populate minimal Forja state.
# Echoes the absolute path of the sandbox.
mk_sandbox() {
  local dir
  dir=$(mktemp -d "${TMPDIR:-/tmp}/forja-hooks-test-XXXXXX")
  (
    cd "$dir"
    git init -q
    git config user.email "test@forja.local"
    git config user.name "Forja Test"
    mkdir -p .claude/memory .claude/skills/find-docs
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
    git add -A
    git commit -q -m "chore(test): bootstrap" --no-verify 2>/dev/null || true
  )
  echo "$dir"
}

# Cleanup helper
rm_sandbox() {
  local dir="$1"
  if [[ -n "$dir" && "$dir" =~ /forja-hooks-test- && -d "$dir" ]]; then
    rm -rf "$dir"
  fi
}
