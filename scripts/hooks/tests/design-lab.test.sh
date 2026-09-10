#!/usr/bin/env bash
# Test del Discover con entropía externa (D-037 · A1/A7)
# Cases:
#   1. design-seed.sh crea N variantes con SEED.md (PRNG de shell, 128 chars alfanuméricos)
#   2. Las N semillas son DISTINTAS entre sí (una por variante)
#   3. SEED.md lleva provenance: source os_prng · string_in_ui: false · sección posture
#   4. Siembra design-lab/.gitignore (pixeles fuera, provenance dentro) y failed-prompts.md (A5)
#   5. Re-correr NO pisa una variante existente (R1: no overwrite)
#   6. design-diversity.mjs --selftest: 3 iguales + 2 distintos → COLLAPSE; 5 distintos → OK
#   7. Doctrina: asset 07 + discovery-fresh exponen la opción semilla; design-discover.md prohíbe "sé único" solo

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SEED_SH="$REPO_ROOT/scripts/design-seed.sh"
DIV_MJS="$REPO_ROOT/scripts/design-diversity.mjs"
ASSET07="$REPO_ROOT/.claude/skills/la-herreria/assets/07-ui-design-workflow.md"
DISC="$REPO_ROOT/.claude/skills/la-herreria/references/design-discover.md"
FRESH="$REPO_ROOT/.claude/skills/add-ui-kit/prompts/discovery-fresh.md"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── design-lab tests ──"

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; TESTS_PASS=$((TESTS_PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; TESTS_FAIL=$((TESTS_FAIL+1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export DESIGN_LAB_ROOT="$TMP/design-lab"

OUT="$(bash "$SEED_SH" landing 5 2>&1)"; RC=$?
RUN="$(find "$DESIGN_LAB_ROOT" -maxdepth 1 -mindepth 1 -type d -name '*-landing' | head -1)"

check "design-seed.sh: exit 0 y 5 SEED.md" "[ $RC -eq 0 ] && [ \"\$(find '$RUN' -name SEED.md | wc -l | tr -d ' ')\" = '5' ]"

SEEDS="$(grep -h '^seed: ' "$RUN"/v*/SEED.md | sed 's/^seed: //')"
check "seeds: 128 chars alfanuméricos cada una" \
  "[ \"\$(echo \"$SEEDS\" | grep -cE '^[A-Za-z0-9]{128}$')\" = '5' ]"
check "seeds: las 5 son distintas (una semilla por variante)" \
  "[ \"\$(echo \"$SEEDS\" | sort -u | wc -l | tr -d ' ')\" = '5' ]"
check "SEED.md: provenance (source os_prng · string_in_ui: false · posture)" \
  "grep -q '^source: os_prng' '$RUN/v1/SEED.md' && grep -q '^string_in_ui: false' '$RUN/v1/SEED.md' && grep -q 'posture' '$RUN/v1/SEED.md'"
check "design-lab/.gitignore siembra: png fuera, SEED.md/CHOSEN.md dentro" \
  "grep -q '^\*.png' '$DESIGN_LAB_ROOT/.gitignore' && grep -q 'SEED.md' '$DESIGN_LAB_ROOT/.gitignore' && grep -q 'CHOSEN.md' '$DESIGN_LAB_ROOT/.gitignore'"
check "failed-prompts.md sembrado (A5 — eval fixtures del próximo modelo)" "[ -f '$DESIGN_LAB_ROOT/failed-prompts.md' ]"

FIRST="$(grep '^seed: ' "$RUN/v1/SEED.md")"
bash "$SEED_SH" landing 5 >/dev/null 2>&1
check "re-correr NO pisa variantes existentes (skip, no overwrite)" "[ \"\$(grep '^seed: ' '$RUN/v1/SEED.md')\" = \"$FIRST\" ]"
check "N fuera de rango (0 / 13) → exit 2" "! bash '$SEED_SH' x 0 >/dev/null 2>&1 && ! bash '$SEED_SH' x 13 >/dev/null 2>&1"

check "design-diversity.mjs --selftest (3 iguales → COLLAPSE · 5 distintos → OK)" "node '$DIV_MJS' --selftest >/dev/null 2>&1"
check "design-diversity.mjs: <2 imágenes → exit 2 (uso)" "! node '$DIV_MJS' >/dev/null 2>&1"

check "asset 07: sección Discover con semilla + diversity check" \
  "grep -q 'Direcciones visuales (Discover)' '$ASSET07' && grep -q 'design-diversity.mjs' '$ASSET07'"
check "discovery-fresh bloque (c): opción semilla" "grep -q 'elige \`semilla\`' '$FRESH'"
check "design-discover.md: prohíbe 'sé único' como único mecanismo" "grep -qi 'Prohibido \"sé único\"' '$DISC'"

echo ""
echo "design-lab: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
