#!/usr/bin/env bash
# Test del tool-filter estructural de los skills forkeados (Q-FORK-AGENT / D-033)
# Cases (por skill forkeado con agente custom):
#   1. SKILL.md conserva `context: fork` (sin regresión de frontmatter)
#   2. SKILL.md declara `agent: <name>` (binding al subagente tool-filtered)
#   3. .claude/agents/<name>.md existe y declara `name: <name>` + línea `tools:`
#   4. Invariante AP3: el-guardian y el-migrador NO tienen Edit en su whitelist;
#      el-evaluador SÍ (único writer de estado, R5)
#   5. Los tres tienen Write en su whitelist
#   6. Agentes standalone (D-037): TODO .claude/agents/*.md declara name + tools; el crítico visual
#      el-critico-de-diseno NO tiene Write/Edit/Grep/Glob (ve píxeles, no repo) y SÍ Read

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS="$REPO_ROOT/.claude/skills"
AGENTS="$REPO_ROOT/.claude/agents"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── fork-agents tests ──"

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; TESTS_PASS=$((TESTS_PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; TESTS_FAIL=$((TESTS_FAIL+1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# frontmatter YAML del SKILL.md (entre los dos primeros '---')
frontmatter() { awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$1"; }
tools_line() { grep '^tools:' "$1" || true; }
# match de nombre de tool con límites (no matchea NotebookEdit al buscar Edit)
has_tool() { echo "$1" | grep -qE "(^tools:| |,)$2(,| |$)"; }

for name in el-guardian el-evaluador el-migrador; do
  SKILL="$SKILLS/$name/SKILL.md"
  AGENT="$AGENTS/$name.md"

  check "$name: SKILL.md conserva 'context: fork'" \
    "frontmatter '$SKILL' | grep -q '^context: fork$'"
  check "$name: SKILL.md declara 'agent: $name'" \
    "frontmatter '$SKILL' | grep -q '^agent: $name$'"
  check "$name: agents/$name.md existe con name + tools:" \
    "[ -f '$AGENT' ] && grep -q '^name: $name$' '$AGENT' && grep -q '^tools:' '$AGENT'"

  TL=$(tools_line "$AGENT")
  if [[ "$name" == "el-evaluador" ]]; then
    check "$name: whitelist SÍ incluye Edit (único writer de estado, R5)" \
      "has_tool '$TL' Edit"
  else
    check "$name: whitelist NO incluye Edit (AP3 estructural)" \
      "! has_tool '$TL' Edit"
  fi
  check "$name: whitelist incluye Write" \
    "has_tool '$TL' Write"
done

# ── 6. agentes standalone (no ligados por `agent:` desde un SKILL.md) ──
for AGENT in "$AGENTS"/*.md; do
  name=$(basename "$AGENT" .md)
  check "$name: agents/$name.md declara name + tools:" \
    "grep -q '^name: $name$' '$AGENT' && grep -q '^tools:' '$AGENT'"
done
CRITIC="$AGENTS/el-critico-de-diseno.md"
TL=$(tools_line "$CRITIC")
check "el-critico-de-diseno: whitelist SÍ incluye Read (lee el screenshot)" "has_tool '$TL' Read"
for forbidden in Write Edit Grep Glob; do
  check "el-critico-de-diseno: whitelist NO incluye $forbidden (ve píxeles, no repo)" "! has_tool '$TL' $forbidden"
done

echo ""
echo "fork-agents: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
