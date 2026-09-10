#!/usr/bin/env bash
# Test scripts/handoff.mjs + scripts/statusline.mjs (F-P5.1 · D-034)
# Cases:
#   1. handoff en sandbox con feature_list.json → exit 0 + HANDOFF.md con active feature y "Siguiente acción"
#   2. --source=precompact queda registrado en el archivo
#   3. sin feature_list.json → degrada graceful (exit 0, HANDOFF.md igual existe)
#   4. re-run es idempotente (sobrescribe, no duplica secciones)
#   5. statusline con stdin JSON → una línea con rama + active feature
#   6. statusline sin feature_list.json → degrada ("sin-active"/"—"), exit 0

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
HANDOFF="$REPO_ROOT/scripts/handoff.mjs"
STATUSLINE="$REPO_ROOT/scripts/statusline.mjs"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── handoff / statusline tests ──"

# ─── C1: handoff con feature_list.json ───────────────────────────────────────
sb=$(mk_sandbox)
(
  cd "$sb"
  out=$(node "$HANDOFF" 2>&1); rc=$?
  if [[ $rc -eq 0 && -f .forja/HANDOFF.md ]] \
     && grep -q 'T-1' .forja/HANDOFF.md \
     && grep -q 'Siguiente acción' .forja/HANDOFF.md; then
    echo "  PASS  C1: handoff escribe .forja/HANDOFF.md con active feature + siguiente acción"
    exit 0
  else
    echo "  FAIL  C1: exit=$rc — $out"
    exit 1
  fi
) && TESTS_PASS=$((TESTS_PASS+1)) || TESTS_FAIL=$((TESTS_FAIL+1))

# ─── C2: --source=precompact registrado ──────────────────────────────────────
(
  cd "$sb"
  node "$HANDOFF" --source=precompact >/dev/null 2>&1
  if grep -q 'precompact' .forja/HANDOFF.md; then
    echo "  PASS  C2: --source=precompact queda registrado en el handoff"
    exit 0
  else
    echo "  FAIL  C2: fuente precompact no aparece en HANDOFF.md"
    exit 1
  fi
) && TESTS_PASS=$((TESTS_PASS+1)) || TESTS_FAIL=$((TESTS_FAIL+1))

# ─── C4: idempotencia (una sola sección "Siguiente acción") ─────────────────
(
  cd "$sb"
  node "$HANDOFF" >/dev/null 2>&1
  node "$HANDOFF" >/dev/null 2>&1
  n=$(grep -c '^## Siguiente acción' .forja/HANDOFF.md)
  if [[ "$n" -eq 1 ]]; then
    echo "  PASS  C4: re-run idempotente (1 sección Siguiente acción, no $n)"
    exit 0
  else
    echo "  FAIL  C4: secciones duplicadas ($n)"
    exit 1
  fi
) && TESTS_PASS=$((TESTS_PASS+1)) || TESTS_FAIL=$((TESTS_FAIL+1))

# ─── C5: statusline con feature_list ────────────────────────────────────────
(
  cd "$sb"
  line=$(echo '{"model":{"display_name":"Test"}}' | node "$STATUSLINE" 2>&1); rc=$?
  if [[ $rc -eq 0 ]] && echo "$line" | grep -q 'T-1'; then
    echo "  PASS  C5: statusline muestra active feature ($line)"
    exit 0
  else
    echo "  FAIL  C5: exit=$rc — '$line'"
    exit 1
  fi
) && TESTS_PASS=$((TESTS_PASS+1)) || TESTS_FAIL=$((TESTS_FAIL+1))
rm_sandbox "$sb"

# ─── C3: handoff degrada sin feature_list.json ──────────────────────────────
sb2=$(mk_sandbox)
(
  cd "$sb2"
  rm -f feature_list.json
  out=$(node "$HANDOFF" 2>&1); rc=$?
  if [[ $rc -eq 0 && -f .forja/HANDOFF.md ]] && grep -q 'sin feature_list' .forja/HANDOFF.md; then
    echo "  PASS  C3: sin feature_list.json degrada graceful (exit 0 + aviso)"
    exit 0
  else
    echo "  FAIL  C3: exit=$rc — $out"
    exit 1
  fi
) && TESTS_PASS=$((TESTS_PASS+1)) || TESTS_FAIL=$((TESTS_FAIL+1))

# ─── C6: statusline degrada sin feature_list.json ───────────────────────────
(
  cd "$sb2"
  line=$(node "$STATUSLINE" </dev/null 2>&1); rc=$?
  if [[ $rc -eq 0 ]] && echo "$line" | grep -q 'sin-active'; then
    echo "  PASS  C6: statusline degrada sin feature_list ($line)"
    exit 0
  else
    echo "  FAIL  C6: exit=$rc — '$line'"
    exit 1
  fi
) && TESTS_PASS=$((TESTS_PASS+1)) || TESTS_FAIL=$((TESTS_FAIL+1))
rm_sandbox "$sb2"

echo ""
echo "handoff: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
