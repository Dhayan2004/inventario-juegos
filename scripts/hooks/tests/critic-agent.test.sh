#!/usr/bin/env bash
# Test del juez visual fresco (D-037 · QUALITY_GATES §4)
# Cases:
#   1. El prompt del crítico NO contiene un criterio numérico de parada (9/10, ≥9, "until 9")
#   2. El crítico declara model: (tier piensa) con alias, no id fechado
#   3. El crítico responde NEED_SCREENSHOT sin imagen (regla en el prompt)
#   4. El crítico está prohibido de proponer código / reescribir SPEC (R19 en el prompt)
#   5. el-pulidor despacha al crítico vía Agent (patrón Coordinator) y su tool filter lo acota
#   6. El cap y las paradas viven en QUALITY_GATES §4 (MAX_CRITIC_ITERS=2), no en el prompt del crítico
#   7. modes.md documenta la capa (b) fresca + el modo cut; el comando /pulidor expone cut
#   8. el-evaluador ya no promete "visual diff" sin baseline: exige golden aceptado

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CRITIC="$REPO_ROOT/.claude/agents/el-critico-de-diseno.md"
PULIDOR="$REPO_ROOT/.claude/skills/el-pulidor/SKILL.md"
MODES="$REPO_ROOT/.claude/skills/el-pulidor/references/modes.md"
CMD="$REPO_ROOT/.claude/commands/pulidor.md"
QG="$REPO_ROOT/.claude/references/QUALITY_GATES.md"
EVAL="$REPO_ROOT/.claude/skills/el-evaluador/SKILL.md"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── critic-agent tests ──"

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; TESTS_PASS=$((TESTS_PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; TESTS_FAIL=$((TESTS_FAIL+1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

check "crítico: existe el agente" "[ -f '$CRITIC' ]"
check "crítico: sin criterio numérico de parada en el prompt (9/10 · ≥9 · until 9)" \
  "! grep -qiE '9 ?/ ?10|[≥>]= ?9|until (it is|the critic).*9|9 o m[aá]s' '$CRITIC'"
check "crítico: model: declarado con alias de tier (opus|sonnet|haiku), no id fechado" \
  "grep -qE '^model: (opus|sonnet|haiku)$' '$CRITIC'"
check "crítico: responde NEED_SCREENSHOT sin imagen" "grep -q 'NEED_SCREENSHOT' '$CRITIC'"
check "crítico: prohibido proponer código y reescribir SPEC (R19)" \
  "grep -qi 'Proponer código' '$CRITIC' && grep -q 'R19' '$CRITIC'"
check "crítico: output JSON con score + gaps + penalties" \
  "grep -q '\"score\"' '$CRITIC' && grep -q '\"gaps\"' '$CRITIC' && grep -q '\"penalties\"' '$CRITIC'"

check "el-pulidor: despacha Agent(el-critico-de-diseno) en critique" \
  "grep -q 'Agent(el-critico-de-diseno)' '$PULIDOR'"
check "el-pulidor: tool filter incluye Agent acotado al crítico" \
  "grep -q 'Agent (SOLO \`el-critico-de-diseno\`' '$PULIDOR'"
check "el-pulidor: refusal — no pasarle código ni el stop numérico al crítico" \
  "grep -q 'criterio numérico de parada' '$PULIDOR'"

check "QUALITY_GATES §4: MAX_CRITIC_ITERS=2 vive en el gate, no en el prompt" \
  "grep -q 'MAX_CRITIC_ITERS=2' '$QG' && ! grep -q 'MAX_CRITIC_ITERS' '$CRITIC'"
check "QUALITY_GATES §4: score es telemetría, parada pairwise" \
  "grep -q 'telemetría' '$QG' && grep -qi 'pairwise' '$QG'"
check "QUALITY_GATES §4: cut obligatorio antes del golden" \
  "grep -q 'Cut obligatorio antes del golden' '$QG'"

check "modes.md: capa (b) juez visual fresco documentada" "grep -q 'Capa (b)' '$MODES'"
check "modes.md: Modo 5 — cut con checklist de sustracción" "grep -q '## Modo 5 — cut' '$MODES'"
check "/pulidor: expone el modo cut" "grep -q '/pulidor cut' '$CMD'"

check "el-evaluador: exige golden aceptado, no promete visual diff sin baseline" \
  "grep -q 'golden aceptado' '$EVAL' && ! grep -q 'visual diff dentro de tolerancia' '$EVAL'"

echo ""
echo "critic-agent: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
