#!/usr/bin/env bash
# Forja preflight — Bootstrap Contract verification (R11)
# Invoked by: `make preflight` and the /build command (Phase 3+)
# Source: forja/CONSTRAINTS.md R11 + ARCHITECTURE.md "Bootstrap Contract"

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0
SKIP=0
HALT_MSGS=()

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; HALT_MSGS+=("$2"); FAIL=$((FAIL+1)); }
skip() { echo "  ⏭  $1"; SKIP=$((SKIP+1)); }

echo "Forja Bootstrap Contract preflight (R11)"
echo "════════════════════════════════════════"
echo ""

# ─── Check 1: deps installed (or not yet bootstrapped) ───────────────────────
if [[ ! -f package.json ]]; then
  skip "package.json (Phase 1 skeleton — no Node app yet)"
elif [[ ! -d node_modules ]]; then
  fail "package.json present but node_modules missing" \
       "Run 'npm install' or 'make setup'."
else
  ok "package.json + node_modules present"
fi

# ─── Check 2: ≥1 test exists (soft in Phase 1-2) ─────────────────────────────
if [[ -d tests || -d __tests__ ]]; then
  ok "test directory present"
elif [[ -f package.json ]] && grep -q '"test":' package.json 2>/dev/null; then
  ok "test script in package.json"
else
  skip "≥1 test passing (pending Phase 3 — no test infrastructure yet in skeleton)"
fi

# ─── Check 3: feature_list.json valid + ≥3 features with verification ────────
if [[ ! -f feature_list.json ]]; then
  fail "feature_list.json missing" \
       "Run /forge-init to bootstrap feature_list.json."
else
  if node -e "JSON.parse(require('fs').readFileSync('feature_list.json','utf8'))" 2>/dev/null; then
    ok "feature_list.json valid JSON"
    VCOUNT=$(node -e "
      const d=JSON.parse(require('fs').readFileSync('feature_list.json','utf8'));
      console.log(d.features.filter(f=>f.verification).length);
    " 2>/dev/null || echo 0)
    if [[ "$VCOUNT" -ge 3 ]]; then
      ok "feature_list.json has ≥3 features with verification command ($VCOUNT)"
    else
      fail "feature_list.json has only $VCOUNT features with verification (need ≥3)" \
           "Add at least $((3 - VCOUNT)) more features with non-empty 'verification' field."
    fi
  else
    fail "feature_list.json is invalid JSON" \
         "Fix JSON syntax errors in feature_list.json."
  fi
fi

# ─── Check 4: skills.md present + has Core skills section ────────────────────
SKILLS_MD=".claude/memory/skills.md"
if [[ ! -f "$SKILLS_MD" ]]; then
  fail "$SKILLS_MD missing" \
       "Skill registry is required. Restore from git or recreate."
elif ! grep -q '## Core skills' "$SKILLS_MD"; then
  fail "$SKILLS_MD has no '## Core skills' section" \
       "Skills registry must list Core skills with tier/usar cuando/requiere/fallback."
else
  ok "skills.md present + has Core skills section"
fi

# ─── Check 5: Brand DNA (or no-brand-yet flag for template repos) ────────────
if [[ -f brand/brand.json && -f brand/voice.json ]]; then
  ok "Brand DNA (brand.json + voice.json)"
elif [[ -f brand/.no-brand-yet ]]; then
  skip "Brand DNA (brand/.no-brand-yet flag — repo is template, brand belongs to target project)"
else
  fail "Brand DNA missing (brand.json + voice.json)" \
       "Generate brand contract via add-ui-kit skill, OR touch brand/.no-brand-yet for template repos."
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "Pass: $PASS · Skip: $SKIP · Fail: $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "❌ Bootstrap Contract NOT satisfied. /build is not permitted."
  echo ""
  echo "Remediation:"
  for msg in "${HALT_MSGS[@]}"; do
    echo "  → $msg"
  done
  exit 1
fi

echo "✅ Bootstrap Contract satisfied. /build is permitted."
exit 0
