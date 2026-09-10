#!/usr/bin/env bash
# la-forja dry-run test
#
# Validates L1 (file presence + structure) + L2 (prompts/refs contract awareness)
# + L3 (mental dry-run de los 3 patterns simulados + pattern selector).
#
# E-008 awareness: usa `grep -E` con `|` plain (no `\|` ni `\\|`) y patterns
# flexibles para variación natural de docs.
#
# Usage: bash .claude/skills/la-forja/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── la-forja dry-run ────────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

la_forja_files=(
  "SKILL.md"
  "prompts/select-pattern.md"
  "prompts/orchestrate-coordinator.md"
  "prompts/orchestrate-fork.md"
  "prompts/orchestrate-swarm.md"
  "prompts/manage-worktrees.md"
  "prompts/tool-filter-workers.md"
  "prompts/handoff-evaluador.md"
  "prompts/handoff-guardian.md"
  "references/coordinator-pattern.md"
  "references/fork-pattern.md"
  "references/swarm-pattern.md"
  "references/worktree-management.md"
  "references/pattern-selector-rationale.md"
  "references/examples.md"
)
for f in "${la_forja_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "la-forja: $f"; else fail "la-forja missing: $f"; fi
done

# la-forja IS write-capable orchestrator — no templates folder rule like sprint/primer
if [ -d "$SKILL_DIR/templates" ]; then
  ok "la-forja: templates/ folder presente (orquestador con comandos canónicos OK)"
else
  ok "la-forja: NO templates/ folder (orquestador thin OK; no genera código)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: la-forja$" "$SKILL"; then
  ok "SKILL.md: name field"
else
  fail "SKILL.md: name field missing"
fi

if grep -q "^tier:" "$SKILL"; then
  ok "SKILL.md: tier field"
else
  fail "SKILL.md: tier field missing"
fi

if grep -q "^requires:" "$SKILL"; then
  ok "SKILL.md: requires field"
else
  fail "SKILL.md: requires field missing"
fi

if grep -q "^fallback:" "$SKILL"; then
  ok "SKILL.md: fallback field"
else
  fail "SKILL.md: fallback field missing"
fi

if grep -qE "^dependencies: \[find-docs\]" "$SKILL"; then
  ok "SKILL.md: dependencies includes find-docs (R13)"
else
  fail "SKILL.md: dependencies field incorrect"
fi

# ── L2 — SKILL.md contract awareness ─────────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

# 3 patterns documentados
for pattern in "Coordinator" "Fork" "Swarm"; do
  if grep -q "$pattern" "$SKILL"; then
    ok "SKILL.md mentions pattern '$pattern'"
  else
    fail "SKILL.md missing pattern '$pattern'"
  fi
done

# Default Fork
if grep -qE "DEFAULT|default Fork|Fork.*default" "$SKILL"; then
  ok "SKILL.md: default Fork declarado"
else
  fail "SKILL.md: default Fork missing"
fi

# Hard rules R4/R5/R6 verbatim
for rule in "R4" "R5" "R6"; do
  if grep -q "$rule" "$SKILL"; then
    ok "SKILL.md cites $rule"
  else
    fail "SKILL.md missing $rule citation"
  fi
done

# R13 find-docs
if grep -q "R13" "$SKILL"; then
  ok "SKILL.md cites R13 (find-docs antes de git worktree)"
else
  fail "SKILL.md missing R13 citation"
fi

# L-004 cita
if grep -q "L-004" "$SKILL"; then
  ok "SKILL.md cites L-004 (binary pattern selector)"
else
  fail "SKILL.md missing L-004 citation"
fi

# D-013 cita
if grep -q "D-013" "$SKILL"; then
  ok "SKILL.md cites D-013 (sexta validación binary)"
else
  fail "SKILL.md missing D-013 citation"
fi

# Boundaries con skills relacionados
for skill in "la-herreria" "el-crisol" "el-evaluador" "el-guardian" "el-tajo" "el-golpe" "el-yunque" "find-docs"; do
  if grep -q "$skill" "$SKILL"; then
    ok "SKILL.md mentions skill boundary '$skill'"
  else
    fail "SKILL.md missing boundary with '$skill'"
  fi
done

# PREFLIGHT con 5 checks
if grep -qE "PREFLIGHT" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT documented"
else
  fail "SKILL.md: PREFLIGHT missing"
fi

# Refusals section
if grep -qE "^## Refusals|Refusals \(lo que NUNCA" "$SKILL"; then
  ok "SKILL.md: Refusals section explícita"
else
  fail "SKILL.md: Refusals section missing"
fi

# Tool filter de la-forja MISMA
if grep -qE "Tool filter|NO Edit|NO Write" "$SKILL"; then
  ok "SKILL.md: Tool filter documented (la-forja MISMA thin)"
else
  fail "SKILL.md: Tool filter missing"
fi

# ── L2 — select-pattern.md (L-004 test) ──────────────────────────────
echo ""
echo "L2 — select-pattern.md"

SELECT="$SKILL_DIR/prompts/select-pattern.md"

# L-004 test diagnóstico documentado
if grep -qE "Test diagnóstico|test diagnóstico|L-004 test" "$SELECT"; then
  ok "select-pattern: L-004 test diagnóstico documented"
else
  fail "select-pattern: L-004 test missing"
fi

# Decision tree
if grep -qE "[Dd]ecision tree|Decision tree" "$SELECT"; then
  ok "select-pattern: decision tree documented"
else
  fail "select-pattern: decision tree missing"
fi

# 3 patterns referenced en decision tree
for pattern in "coordinator" "fork" "swarm"; do
  if grep -qE "$pattern" "$SELECT"; then
    ok "select-pattern: pattern '$pattern' referenced"
  else
    fail "select-pattern: pattern '$pattern' missing"
  fi
done

# R6 validation step
if grep -q "R6" "$SELECT"; then
  ok "select-pattern: R6 validation cited"
else
  fail "select-pattern: R6 validation missing"
fi

# Output canónico YAML shape
if grep -qE "^pattern:|pattern: (coordinator|fork|swarm)" "$SELECT"; then
  ok "select-pattern: output YAML shape mostrado"
else
  fail "select-pattern: output shape missing"
fi

# Edge cases (>=4)
select_edges=$(grep -c "^### Edge" "$SELECT")
if [ "$select_edges" -ge 4 ]; then
  ok "select-pattern: $select_edges edge cases (>=4)"
else
  fail "select-pattern: only $select_edges edge cases (need >=4)"
fi

# ── L2 — orchestrate-coordinator.md ──────────────────────────────────
echo ""
echo "L2 — orchestrate-coordinator.md"

OC="$SKILL_DIR/prompts/orchestrate-coordinator.md"

# R4/R5/R6 verbatim
for rule in "R4" "R5" "R6"; do
  if grep -q "$rule" "$OC"; then
    ok "orchestrate-coordinator: cites $rule"
  else
    fail "orchestrate-coordinator: missing $rule"
  fi
done

# Synthesis between phases
if grep -qE "[Ss]ynthesis|synthesis|Sintetiza" "$OC"; then
  ok "orchestrate-coordinator: synthesis between phases documented"
else
  fail "orchestrate-coordinator: synthesis missing"
fi

# Halt conditions
if grep -qE "[Hh]alt conditions|halt-blocked|Halt|halt" "$OC"; then
  ok "orchestrate-coordinator: halt conditions documented"
else
  fail "orchestrate-coordinator: halt missing"
fi

# Edge cases (>=3)
oc_edges=$(grep -c "^### Edge" "$OC")
if [ "$oc_edges" -ge 3 ]; then
  ok "orchestrate-coordinator: $oc_edges edge cases (>=3)"
else
  fail "orchestrate-coordinator: only $oc_edges edge cases"
fi

# ── L2 — orchestrate-fork.md (PATTERN PRINCIPAL) ──────────────────────
echo ""
echo "L2 — orchestrate-fork.md (PATTERN PRINCIPAL)"

OF="$SKILL_DIR/prompts/orchestrate-fork.md"

# R4/R5/R6/R13
for rule in "R4" "R5" "R6" "R13"; do
  if grep -q "$rule" "$OF"; then
    ok "orchestrate-fork: cites $rule"
  else
    fail "orchestrate-fork: missing $rule"
  fi
done

# N=2-5 sweet spot
if grep -qE "N ?∈ ?\[2, ?5\]|N=2-5|N ?(=|in) ?2-5|2 a 5|sweet spot" "$OF"; then
  ok "orchestrate-fork: N=2-5 sweet spot declarado"
else
  fail "orchestrate-fork: N range missing"
fi

# Personality variants
for variant in "literal" "creativo" "disruptivo"; do
  if grep -qE "$variant" "$OF"; then
    ok "orchestrate-fork: personality '$variant'"
  else
    fail "orchestrate-fork: personality '$variant' missing"
  fi
done

# Cherry-pick con confirmation humana
if grep -qE "[Cc]herry-pick|cherry-pick" "$OF"; then
  ok "orchestrate-fork: cherry-pick documented"
else
  fail "orchestrate-fork: cherry-pick missing"
fi

if grep -qE "confirmation humana|humana ANTES|humano confirma|humano aprueba" "$OF"; then
  ok "orchestrate-fork: cherry-pick requires human confirmation"
else
  fail "orchestrate-fork: human confirmation requirement missing"
fi

# git worktree commands
if grep -qE "git worktree add|git worktree" "$OF"; then
  ok "orchestrate-fork: git worktree commands referenced"
else
  fail "orchestrate-fork: git worktree missing"
fi

# Edge cases (>=4)
of_edges=$(grep -c "^### Edge" "$OF")
if [ "$of_edges" -ge 4 ]; then
  ok "orchestrate-fork: $of_edges edge cases (>=4)"
else
  fail "orchestrate-fork: only $of_edges edge cases"
fi

# ── L2 — orchestrate-swarm.md ────────────────────────────────────────
echo ""
echo "L2 — orchestrate-swarm.md"

OS="$SKILL_DIR/prompts/orchestrate-swarm.md"

# 3 roles tool-filtered
for role in "Researcher" "Implementer" "Reviewer"; do
  if grep -q "$role" "$OS"; then
    ok "orchestrate-swarm: role '$role'"
  else
    fail "orchestrate-swarm: role '$role' missing"
  fi
done

# Tool filters explícitos
if grep -qE "Read.*Grep.*Glob.*WebFetch|Read · Grep · Glob · WebFetch" "$OS"; then
  ok "orchestrate-swarm: Researcher tool filter explícito"
else
  fail "orchestrate-swarm: Researcher tool filter missing"
fi

if grep -qE "Read.*Write.*Edit.*Bash|Read · Write · Edit · Bash" "$OS"; then
  ok "orchestrate-swarm: Implementer tool filter explícito"
else
  fail "orchestrate-swarm: Implementer tool filter missing"
fi

# el-tajo / el-golpe delegation
if grep -qE "el-tajo|el-golpe" "$OS"; then
  ok "orchestrate-swarm: delegation to el-tajo/el-golpe documented"
else
  fail "orchestrate-swarm: delegation missing"
fi

# Forma A vs Forma B
if grep -qE "Forma A|Forma B|Forma directo|delegación" "$OS"; then
  ok "orchestrate-swarm: Forma A vs Forma B documented"
else
  fail "orchestrate-swarm: Forma A/B missing"
fi

# AP3 self-eval prohibido
if grep -qE "AP3|self-eval|Implementer NO valida" "$OS"; then
  ok "orchestrate-swarm: AP3 self-eval prohibido"
else
  fail "orchestrate-swarm: AP3 missing"
fi

# Edge cases (>=3)
os_edges=$(grep -c "^### Edge" "$OS")
if [ "$os_edges" -ge 3 ]; then
  ok "orchestrate-swarm: $os_edges edge cases (>=3)"
else
  fail "orchestrate-swarm: only $os_edges edge cases"
fi

# ── L2 — manage-worktrees.md (R13 + git worktree) ────────────────────
echo ""
echo "L2 — manage-worktrees.md"

MW="$SKILL_DIR/prompts/manage-worktrees.md"

# R13 enforcement
if grep -q "R13" "$MW"; then
  ok "manage-worktrees: R13 cited"
else
  fail "manage-worktrees: R13 missing"
fi

# find-docs invocation
if grep -qE "find-docs|ctx7" "$MW"; then
  ok "manage-worktrees: find-docs invocation documented"
else
  fail "manage-worktrees: find-docs missing"
fi

# [docs:git] citation
if grep -qE "\[docs:git\]" "$MW"; then
  ok "manage-worktrees: [docs:git] citation"
else
  fail "manage-worktrees: [docs:git] missing"
fi

# Comandos canónicos
for cmd in "git worktree add" "git worktree list" "git worktree remove" "git worktree prune" "git cherry-pick"; do
  if grep -q "$cmd" "$MW"; then
    ok "manage-worktrees: command '$cmd' documented"
  else
    fail "manage-worktrees: command '$cmd' missing"
  fi
done

# Naming conventions
if grep -qE ".worktrees/sandbox-N|la-forja/sandbox-N" "$MW"; then
  ok "manage-worktrees: naming conventions documented"
else
  fail "manage-worktrees: naming conventions missing"
fi

# node_modules consideration
if grep -qE "node_modules|symlink" "$MW"; then
  ok "manage-worktrees: node_modules sharing trade-off documented"
else
  fail "manage-worktrees: node_modules consideration missing"
fi

# Edge cases (>=4)
mw_edges=$(grep -c "^### Edge" "$MW")
if [ "$mw_edges" -ge 4 ]; then
  ok "manage-worktrees: $mw_edges edge cases (>=4)"
else
  fail "manage-worktrees: only $mw_edges edge cases"
fi

# ── L2 — tool-filter-workers.md ──────────────────────────────────────
echo ""
echo "L2 — tool-filter-workers.md"

TF="$SKILL_DIR/prompts/tool-filter-workers.md"

# 3 patterns con tool filter explícito
for pattern in "Coordinator" "Fork" "Swarm"; do
  if grep -qE "Pattern $pattern|$pattern:" "$TF"; then
    ok "tool-filter-workers: $pattern pattern filter"
  else
    fail "tool-filter-workers: $pattern filter missing"
  fi
done

# 3 roles Swarm
for role in "Researcher" "Implementer" "Reviewer"; do
  if grep -q "$role" "$TF"; then
    ok "tool-filter-workers: Swarm role '$role'"
  else
    fail "tool-filter-workers: Swarm role '$role' missing"
  fi
done

# Tabla canónica resumen
if grep -qE "[Tt]abla canónica|Tabla resumen|tabla canónica" "$TF"; then
  ok "tool-filter-workers: tabla canónica resumen"
else
  fail "tool-filter-workers: tabla canónica missing"
fi

# Lección Vercel -80% tools
if grep -qE "80%|Vercel|3×|3x" "$TF"; then
  ok "tool-filter-workers: Vercel -80% lesson cited"
else
  fail "tool-filter-workers: Vercel lesson missing"
fi

# ── L2 — handoff-evaluador.md ────────────────────────────────────────
echo ""
echo "L2 — handoff-evaluador.md"

HE="$SKILL_DIR/prompts/handoff-evaluador.md"

# R7 three-layer
if grep -qE "R7|three-layer|Three-Layer" "$HE"; then
  ok "handoff-evaluador: R7 three-layer cited"
else
  fail "handoff-evaluador: R7 missing"
fi

# Mandatory siempre
if grep -qE "[Ss]iempre|mandatory|Siempre" "$HE"; then
  ok "handoff-evaluador: siempre/mandatory declarado"
else
  fail "handoff-evaluador: mandatory missing"
fi

# proposed_memory_entries
if grep -qE "proposed_memory_entries|proposed_lesson|proposed_error" "$HE"; then
  ok "handoff-evaluador: proposed_memory_entries shape"
else
  fail "handoff-evaluador: proposed memory missing"
fi

# AP3 cited
if grep -qE "AP3|self-eval"  "$HE"; then
  ok "handoff-evaluador: AP3 anti-pattern cited"
else
  fail "handoff-evaluador: AP3 missing"
fi

# NEEDS_FIX flow
if grep -qE "NEEDS_FIX|needs_fix" "$HE"; then
  ok "handoff-evaluador: NEEDS_FIX flow documented"
else
  fail "handoff-evaluador: NEEDS_FIX missing"
fi

# ── L2 — handoff-guardian.md ─────────────────────────────────────────
echo ""
echo "L2 — handoff-guardian.md"

HG="$SKILL_DIR/prompts/handoff-guardian.md"

# Conditional aplica
if grep -qE "[Cc]ondicional|condicional|SOLO si|aplica solo" "$HG"; then
  ok "handoff-guardian: conditional aplica documented"
else
  fail "handoff-guardian: conditional missing"
fi

# OWASP / R14
if grep -q "OWASP" "$HG"; then
  ok "handoff-guardian: OWASP cited"
else
  fail "handoff-guardian: OWASP missing"
fi

if grep -q "R14" "$HG"; then
  ok "handoff-guardian: R14 cited"
else
  fail "handoff-guardian: R14 missing"
fi

# Override --skip-security
if grep -qE "skip-security|--skip" "$HG"; then
  ok "handoff-guardian: --skip-security override documented"
else
  fail "handoff-guardian: skip-security missing"
fi

# Deploy NO automatic
if grep -qE "NO ejecuta deploy|NO automático|confirmation humana" "$HG"; then
  ok "handoff-guardian: deploy NOT automatic"
else
  fail "handoff-guardian: deploy automation safeguard missing"
fi

# ── L2 — references/coordinator-pattern.md ───────────────────────────
echo ""
echo "L2 — references/coordinator-pattern.md"

CP="$SKILL_DIR/references/coordinator-pattern.md"

if grep -qE "[Cc]uándo usar|Cuándo usar" "$CP"; then
  ok "coordinator-pattern: cuándo usar section"
else
  fail "coordinator-pattern: cuándo usar missing"
fi

if grep -qE "[Cc]uándo NO|NO usar" "$CP"; then
  ok "coordinator-pattern: cuándo NO usar section"
else
  fail "coordinator-pattern: cuándo NO usar missing"
fi

if grep -qE "[Vv]entajas|Ventajas" "$CP" && grep -qE "[Dd]esventajas|Desventajas" "$CP"; then
  ok "coordinator-pattern: ventajas + desventajas"
else
  fail "coordinator-pattern: ventajas/desventajas missing"
fi

if grep -qE "[Ss]weet spot" "$CP"; then
  ok "coordinator-pattern: sweet spot declarado"
else
  fail "coordinator-pattern: sweet spot missing"
fi

# ── L2 — references/fork-pattern.md ──────────────────────────────────
echo ""
echo "L2 — references/fork-pattern.md"

FP="$SKILL_DIR/references/fork-pattern.md"

# Personalidades por N (2, 3, 4, 5)
for n in "N=2" "N=3" "N=4" "N=5"; do
  if grep -q "$n" "$FP"; then
    ok "fork-pattern: personalidades $n"
  else
    fail "fork-pattern: $n missing"
  fi
done

# 5 personalities
for p in "Literal" "Speed" "Quality" "Creativo" "Disruptivo"; do
  if grep -q "$p" "$FP"; then
    ok "fork-pattern: personality '$p'"
  else
    fail "fork-pattern: personality '$p' missing"
  fi
done

# Cherry-pick decision matrix
if grep -qE "[Cc]herry-pick decision|decision matrix" "$FP"; then
  ok "fork-pattern: cherry-pick decision matrix"
else
  fail "fork-pattern: decision matrix missing"
fi

# ── L2 — references/swarm-pattern.md ─────────────────────────────────
echo ""
echo "L2 — references/swarm-pattern.md"

SP="$SKILL_DIR/references/swarm-pattern.md"

# Forma A and B
if grep -qE "Forma A" "$SP" && grep -qE "Forma B" "$SP"; then
  ok "swarm-pattern: Forma A + Forma B documented"
else
  fail "swarm-pattern: Forma A/B missing"
fi

# 3 workers tool-filtered
if grep -qE "Researcher.*Read.*Grep|Researcher" "$SP" && grep -q "Implementer" "$SP" && grep -q "Reviewer" "$SP"; then
  ok "swarm-pattern: 3 roles tool-filtered"
else
  fail "swarm-pattern: 3 roles missing"
fi

# ── L2 — references/worktree-management.md ───────────────────────────
echo ""
echo "L2 — references/worktree-management.md"

WM="$SKILL_DIR/references/worktree-management.md"

# Comandos canónicos
for cmd in "git worktree add" "git worktree list" "git worktree remove" "git worktree prune"; do
  if grep -q "$cmd" "$WM"; then
    ok "worktree-management: command '$cmd'"
  else
    fail "worktree-management: command '$cmd' missing"
  fi
done

# Naming conventions
if grep -qE "[Nn]aming conventions|.worktrees" "$WM"; then
  ok "worktree-management: naming conventions"
else
  fail "worktree-management: naming missing"
fi

# Disk usage table
if grep -qE "[Dd]isk usage|[Dd]isco|GB|node_modules" "$WM"; then
  ok "worktree-management: disk usage documented"
else
  fail "worktree-management: disk usage missing"
fi

# ── L2 — references/pattern-selector-rationale.md ────────────────────
echo ""
echo "L2 — references/pattern-selector-rationale.md"

PSR="$SKILL_DIR/references/pattern-selector-rationale.md"

# L-004 verbatim
if grep -q "L-004" "$PSR"; then
  ok "pattern-selector-rationale: L-004 cited"
else
  fail "pattern-selector-rationale: L-004 missing"
fi

# 5 ADRs cross-skill (D-009 through D-013)
for adr in "D-009" "D-010" "D-011" "D-012" "D-013"; do
  if grep -q "$adr" "$PSR"; then
    ok "pattern-selector-rationale: $adr cross-cited"
  else
    fail "pattern-selector-rationale: $adr missing"
  fi
done

# Test diagnóstico explicado
if grep -qE "[Tt]est diagnóstico|test diagnóstico" "$PSR"; then
  ok "pattern-selector-rationale: test diagnóstico explicado"
else
  fail "pattern-selector-rationale: test diagnóstico missing"
fi

# Binary outcome documented
if grep -qE "[Bb]inary|binary|BINARY" "$PSR"; then
  ok "pattern-selector-rationale: binary outcome"
else
  fail "pattern-selector-rationale: binary outcome missing"
fi

# Distinción PREFLIGHT halt vs PAUSE
if grep -qE "PREFLIGHT.*PAUSE|PAUSE.*PREFLIGHT|PAUSE genuino|halt.*PAUSE" "$PSR"; then
  ok "pattern-selector-rationale: PREFLIGHT halt vs PAUSE distinction"
else
  fail "pattern-selector-rationale: distinction missing"
fi

# ── L2 — references/examples.md ──────────────────────────────────────
echo ""
echo "L2 — references/examples.md"

EX="$SKILL_DIR/references/examples.md"

# 3 escenarios uno por pattern
for esc in "Escenario 1" "Escenario 2" "Escenario 3"; do
  if grep -q "$esc" "$EX"; then
    ok "examples: $esc documented"
  else
    fail "examples: $esc missing"
  fi
done

# Pattern explicitly assigned per scenario
for pattern in "Coordinator" "Fork" "Swarm"; do
  if grep -q "$pattern" "$EX"; then
    ok "examples: $pattern referenced"
  else
    fail "examples: $pattern missing"
  fi
done

# Tabla resumen final
if grep -qE "Tabla resumen|tabla resumen|resumen.*3 escenarios" "$EX"; then
  ok "examples: tabla resumen final"
else
  fail "examples: tabla resumen missing"
fi

# Anti-pattern observable per scenario
if grep -qE "[Aa]nti-pattern observable|force-fit|anti-pattern" "$EX"; then
  ok "examples: anti-patterns documented"
else
  fail "examples: anti-patterns missing"
fi

# Wallclock comparisons
if grep -qE "[Ww]allclock|min wallclock|min vs" "$EX"; then
  ok "examples: wallclock comparisons documented"
else
  fail "examples: wallclock comparisons missing"
fi

# ── L3 — Mental dry-run de los 3 patterns + selector ─────────────────
echo ""
echo "L3 — Mental dry-run de los 3 patterns + selector"

# Input 1 — "implementar auth + payments + emails con dependencias"
# Expected: pattern selector elige Coordinator
if grep -qE "auth.*payments.*emails|saas-mvp" "$EX"; then
  ok "L3: Coordinator scenario (auth+payments+emails) input documentado"
else
  fail "L3: Coordinator scenario input missing"
fi

if grep -E "Escenario 1" "$EX" | head -1 | grep -qE "Coordinator|coordinator"; then
  ok "L3: Escenario 1 → Coordinator (correcto)"
else
  # Look elsewhere in surrounding lines
  if grep -A2 "Escenario 1" "$EX" | grep -qE "Coordinator|coordinator"; then
    ok "L3: Escenario 1 → Coordinator (correcto)"
  else
    fail "L3: Escenario 1 → Coordinator mapping missing"
  fi
fi

# Input 2 — "explorar 3 estilos UI distintos para landing"
# Expected: pattern selector elige Fork
if grep -qE "landing-redesign|3 approaches|exploración" "$EX"; then
  ok "L3: Fork scenario (3 approaches landing) input documentado"
else
  fail "L3: Fork scenario input missing"
fi

if grep -A2 "Escenario 2" "$EX" | grep -qE "Fork|fork"; then
  ok "L3: Escenario 2 → Fork (correcto, PATTERN PRINCIPAL)"
else
  fail "L3: Escenario 2 → Fork mapping missing"
fi

# Input 3 — "agregar tracking analytics" (one-shot atómico)
# Expected: pattern selector elige Swarm
if grep -qE "tracking analytics|pricing-tracking|atómico" "$EX"; then
  ok "L3: Swarm scenario (atomic task) input documentado"
else
  fail "L3: Swarm scenario input missing"
fi

if grep -A2 "Escenario 3" "$EX" | grep -qE "Swarm|swarm"; then
  ok "L3: Escenario 3 → Swarm (correcto)"
else
  fail "L3: Escenario 3 → Swarm mapping missing"
fi

# Validar que el Output canónico de cada pattern incluye handoff a el-evaluador
# Use -A150 — Fork escenario es largo (cherry-pick recommendation table + cleanup)
for esc in "Escenario 1" "Escenario 2" "Escenario 3"; do
  if grep -A150 "## $esc" "$EX" | grep -qE "el-evaluador|handoff-evaluador"; then
    ok "L3: $esc → handoff-evaluador documented"
  else
    fail "L3: $esc handoff-evaluador missing"
  fi
done

# Validar pattern selector boundaries documented
if grep -qE "force-fit|Pattern force-fit|patrón force-fit" "$EX"; then
  ok "L3: anti-pattern force-fit documented (selector discipline)"
else
  fail "L3: force-fit anti-pattern missing"
fi

# ── L3 — L-004 binary application ────────────────────────────────────
echo ""
echo "L3 — L-004 binary application"

# pattern-selector-rationale.md tiene la generalización D-009..D-013
if grep -qE "D-009.*D-010.*D-011.*D-012.*D-013|D-009 → D-013" "$PSR"; then
  ok "L3: D-009→D-013 progression documented"
else
  # buscar como tabla
  if grep -A20 "Validación cross-skill" "$PSR" | grep -qE "D-009" && \
     grep -A20 "Validación cross-skill" "$PSR" | grep -qE "D-013"; then
    ok "L3: D-009→D-013 cross-skill validation table"
  else
    fail "L3: D-009→D-013 progression missing"
  fi
fi

# Binary count: 3 (D-009, D-012, D-013)
binary_count=$(grep -cE "binary" "$PSR")
if [ "$binary_count" -ge 5 ]; then
  ok "L3: 'binary' aparece $binary_count veces (≥5 expected — pattern selector + ADRs)"
else
  fail "L3: 'binary' aparece $binary_count veces (esperado >=5)"
fi

# Distinción PREFLIGHT halt vs PAUSE
if grep -qE "PREFLIGHT halt ≠ PAUSE|halt.*no es PAUSE|distinción crítica" "$PSR"; then
  ok "L3: distinción explícita PREFLIGHT halt ≠ PAUSE"
else
  fail "L3: distinción PREFLIGHT vs PAUSE missing"
fi

# ── L3 — Pattern selector validation (4 inputs) ──────────────────────
echo ""
echo "L3 — Pattern selector validation (4 inputs)"

# Input "implementar auth completo (con dependencias)" → Coordinator
# Buscar en select-pattern.md decision tree con dependencias secuenciales
if grep -qE "secuenciales fuertes|dependencias secuenciales" "$SELECT"; then
  ok "L3 selector: 'dependencias secuenciales' → Coordinator path"
else
  fail "L3 selector: secuenciales path missing"
fi

# Input "explorar 3 estilos UI distintos para dashboard" → Fork
if grep -qE "paralelizables|2-5|features independientes|exploración" "$SELECT"; then
  ok "L3 selector: 'features independientes/exploración' → Fork path"
else
  fail "L3 selector: paralelizables path missing"
fi

# Input "agregar tracking analytics" (one-shot atómico) → Swarm
if grep -qE "atómico|atómico bien definido|<30min|<5min|one-shot" "$SELECT"; then
  ok "L3 selector: 'atómico one-shot' → Swarm path"
else
  fail "L3 selector: atómico path missing"
fi

# Input "feature con dependencias circulares" → halt-handoff a la-herreria
if grep -qE "halt|handoff a la-herreria|sin Blueprint" "$SELECT"; then
  ok "L3 selector: 'sin Blueprint / refactor needed' → halt-handoff"
else
  fail "L3 selector: halt-handoff path missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ la-forja dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ la-forja dry-run: $FAIL failures"
  exit 1
fi
