#!/usr/bin/env bash
# sprint dry-run test
#
# Validates L1 (file presence) + L2 (structural correctness of prompts/refs)
# + L3 (simulated sprint loop output shape).
#
# Usage: bash .claude/skills/sprint/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── sprint dry-run ──────────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — File presence"

sprint_files=(
  "SKILL.md"
  "prompts/triage-task.md"
  "prompts/execute-iteration.md"
  "prompts/checkpoint-progress.md"
  "prompts/close-or-escalate.md"
  "references/sprint-vs-others.md"
  "references/iteration-patterns.md"
  "references/examples.md"
)
for f in "${sprint_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "sprint: $f"; else fail "sprint missing: $f"; fi
done

# NO templates folder (sprint is prompt-only)
if [ -d "$SKILL_DIR/templates" ]; then
  fail "sprint: templates/ folder existe (debe ser prompt-only)"
else
  ok "sprint: NO templates/ folder (prompt-only correct)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: sprint$" "$SKILL"; then
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

if grep -q "^dependencies: \\[\\]" "$SKILL"; then
  ok "SKILL.md: dependencies empty (sprint no upfront dependencies)"
else
  fail "SKILL.md: dependencies field incorrect"
fi

# ── L2 — SKILL.md contract awareness ─────────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

# 4 fases del loop documentadas
for phase in "TRIAGE" "PLAN RÁPIDO" "LOOP" "CIERRE"; do
  if grep -q "$phase" "$SKILL"; then
    ok "SKILL.md mentions loop phase '$phase'"
  else
    fail "SKILL.md missing loop phase '$phase'"
  fi
done

# Boundaries con 4 skills vecinos
for skill in "el-tajo" "el-golpe" "/build" "la-herreria"; do
  if grep -q "$skill" "$SKILL"; then
    ok "SKILL.md mentions boundary with '$skill'"
  else
    fail "SKILL.md missing boundary with '$skill'"
  fi
done

# Time budget 5-15 min
if grep -qE "5-15 ?min|5\\-15\\\\?min" "$SKILL"; then
  ok "SKILL.md: time budget 5-15 min declarado"
else
  fail "SKILL.md: time budget missing"
fi

# Max 5 ciclos
if grep -qE "[Mm]ax (\\~)?5 ciclos|5 cicl" "$SKILL"; then
  ok "SKILL.md: max ~5 ciclos declarado"
else
  fail "SKILL.md: max ciclos missing"
fi

# Loop visible al usuario
if grep -qiE "loop visible|feedback explícito|feedback entre ciclos" "$SKILL"; then
  ok "SKILL.md: loop visible / feedback explícito declarado"
else
  fail "SKILL.md: feedback explicit requirement missing"
fi

# R10 condicional
if grep -qE "R10 condicional|R10 aplica solo si" "$SKILL"; then
  ok "SKILL.md: R10 condicional (solo si UI) explícito"
else
  fail "SKILL.md: R10 conditional missing"
fi

# R14 condicional
if grep -qE "R14 condicional|R14 aplica solo si" "$SKILL"; then
  ok "SKILL.md: R14 condicional (solo si tools destructivas) explícito"
else
  fail "SKILL.md: R14 conditional missing"
fi

# NO el-guardian
if grep -qE "NO el-guardian|NO ?\`?el-guardian\`? handoff" "$SKILL"; then
  ok "SKILL.md: NO el-guardian handoff explícito"
else
  fail "SKILL.md: el-guardian boundary missing"
fi

# Cita L-004 informativa
if grep -q "L-004" "$SKILL"; then
  ok "SKILL.md cites L-004 (informativo)"
else
  fail "SKILL.md missing L-004 citation"
fi

# Atomic commit en cierre (R2)
if grep -qE "[Aa]tomic commit|atomic.*R2|R2.*atomic" "$SKILL"; then
  ok "SKILL.md: atomic commit en cierre (R2) declarado"
else
  fail "SKILL.md: atomic commit requirement missing"
fi

# ── L2 — triage-task.md structure ────────────────────────────────────
echo ""
echo "L2 — triage-task.md (3-eje diagnostic)"

TRIAGE="$SKILL_DIR/prompts/triage-task.md"

# 3 ejes
for axis in "Atomicidad" "Iteración" "Scope"; do
  if grep -q "$axis" "$TRIAGE"; then
    ok "triage-task: axis '$axis'"
  else
    fail "triage-task: missing axis '$axis'"
  fi
done

# Decision tree
if grep -q "Decision tree" "$TRIAGE"; then
  ok "triage-task: decision tree documented"
else
  fail "triage-task: decision tree missing"
fi

# 5 edge cases
edge_count=$(grep -c "^### Edge " "$TRIAGE")
if [ "$edge_count" -ge 5 ]; then
  ok "triage-task: $edge_count edge cases documented (>=5)"
else
  fail "triage-task: only $edge_count edge cases (need >=5)"
fi

# Tabla de ejemplos canónicos
if grep -q "ejemplos canónicos" "$TRIAGE"; then
  ok "triage-task: tabla de ejemplos canónicos"
else
  fail "triage-task: tabla canónicos missing"
fi

# Skills downstream referenced
for skill in "el-tajo" "el-golpe" "/build" "la-herreria"; do
  if grep -q "$skill" "$TRIAGE"; then
    ok "triage-task: $skill referenced"
  else
    fail "triage-task: $skill not referenced"
  fi
done

# ── L2 — execute-iteration.md structure ──────────────────────────────
echo ""
echo "L2 — execute-iteration.md (per-cycle structure)"

EXEC="$SKILL_DIR/prompts/execute-iteration.md"

# 4 fases del ciclo: EXECUTE, SHOW, ASK, WAIT
for phase in "EXECUTE" "SHOW" "ASK" "WAIT"; do
  if grep -q "$phase" "$EXEC"; then
    ok "execute-iteration: phase '$phase'"
  else
    fail "execute-iteration: missing phase '$phase'"
  fi
done

# 4 opciones de feedback
for opt in "continúa" "pause" "done" "escalate"; do
  if grep -q "\`$opt\`" "$EXEC"; then
    ok "execute-iteration: feedback option '$opt'"
  else
    fail "execute-iteration: missing feedback option '$opt'"
  fi
done

# Template de ciclo
if grep -q "Template de ciclo" "$EXEC"; then
  ok "execute-iteration: template de ciclo documented"
else
  fail "execute-iteration: template missing"
fi

# Edge cases (4)
exec_edge_count=$(grep -c "^### Edge " "$EXEC")
if [ "$exec_edge_count" -ge 4 ]; then
  ok "execute-iteration: $exec_edge_count edge cases documented (>=4)"
else
  fail "execute-iteration: only $exec_edge_count edge cases (need >=4)"
fi

# NO commits intermedios
if grep -qE "NO commits intermedios|sin commits intermedios|no.*git commit por ciclo" "$EXEC"; then
  ok "execute-iteration: NO commits intermedios enforced"
else
  fail "execute-iteration: commits-intermedios boundary missing"
fi

# Ciclo 5 = checkpoint forzado
if grep -qE "[Cc]iclo 5.*checkpoint|checkpoint forzado.*5|max iter" "$EXEC"; then
  ok "execute-iteration: ciclo 5 checkpoint forzado"
else
  fail "execute-iteration: ciclo 5 boundary missing"
fi

# ── L2 — checkpoint-progress.md structure ────────────────────────────
echo ""
echo "L2 — checkpoint-progress.md (triggers + state)"

CP="$SKILL_DIR/prompts/checkpoint-progress.md"

# Triggers de checkpoint (>=5)
for trigger in "pause" "max iter|Ciclo 5|max-iterations" "failure|falla" "Desviación|desviación|divergence" "timeout"; do
  if grep -qE "$trigger" "$CP"; then
    ok "checkpoint-progress: trigger '$trigger'"
  else
    fail "checkpoint-progress: trigger '$trigger' missing"
  fi
done

# 5 outputs canónicos (Caso 1..5)
for caso in "Caso 1" "Caso 2" "Caso 3" "Caso 4" "Caso 5"; do
  if grep -q "$caso" "$CP"; then
    ok "checkpoint-progress: $caso documented"
  else
    fail "checkpoint-progress: $caso missing"
  fi
done

# NO commit en checkpoint
if grep -qE "NO commit|no.*commit hasta cierre|sin commit" "$CP"; then
  ok "checkpoint-progress: NO commit enforced"
else
  fail "checkpoint-progress: NO commit boundary missing"
fi

# +5-mas escape hatch
if grep -q "+5-mas" "$CP"; then
  ok "checkpoint-progress: +5-mas escape hatch documented"
else
  fail "checkpoint-progress: +5-mas missing"
fi

# ── L2 — close-or-escalate.md structure ──────────────────────────────
echo ""
echo "L2 — close-or-escalate.md (3 outcomes)"

CLOSE="$SKILL_DIR/prompts/close-or-escalate.md"

# 3 outcomes
for outcome in "DONE" "PAUSE" "ESCALATE"; do
  if grep -q "$outcome" "$CLOSE"; then
    ok "close-or-escalate: outcome '$outcome'"
  else
    fail "close-or-escalate: missing outcome '$outcome'"
  fi
done

# Pre-commit checks
if grep -qE "[Pp]re-commit checks|Pre-cierre" "$CLOSE"; then
  ok "close-or-escalate: pre-commit/pre-cierre checks documented"
else
  fail "close-or-escalate: pre-commit checks missing"
fi

# 4 edge cases
close_edge_count=$(grep -c "^### Edge " "$CLOSE")
if [ "$close_edge_count" -ge 4 ]; then
  ok "close-or-escalate: $close_edge_count edge cases documented (>=4)"
else
  fail "close-or-escalate: only $close_edge_count edge cases (need >=4)"
fi

# Citations R1, R2, R10, R14, R7
for rule in "R1" "R2" "R10" "R14" "R7"; do
  if grep -q "$rule" "$CLOSE"; then
    ok "close-or-escalate: cites $rule"
  else
    fail "close-or-escalate: missing $rule citation"
  fi
done

# ── L2 — sprint-vs-others.md structure ───────────────────────────────
echo ""
echo "L2 — references/sprint-vs-others.md (boundaries)"

SVO="$SKILL_DIR/references/sprint-vs-others.md"

# Tabla canónica
if grep -q "Tabla canónica" "$SVO"; then
  ok "sprint-vs-others: tabla canónica de boundaries"
else
  fail "sprint-vs-others: tabla canónica missing"
fi

# 5 skills boundaries
for skill in "el-tajo" "el-golpe" "/build|la-forja" "la-herreria" "primer"; do
  if grep -qE "$skill" "$SVO"; then
    ok "sprint-vs-others: boundary with '$skill'"
  else
    fail "sprint-vs-others: boundary with '$skill' missing"
  fi
done

# Anti-patterns boundaries
if grep -q "Anti-pattern boundaries" "$SVO"; then
  ok "sprint-vs-others: anti-patterns documented"
else
  fail "sprint-vs-others: anti-patterns missing"
fi

# ── L2 — iteration-patterns.md structure ─────────────────────────────
echo ""
echo "L2 — references/iteration-patterns.md (5 patterns)"

IP="$SKILL_DIR/references/iteration-patterns.md"

# 5 patterns A-E
for pattern in "Pattern A" "Pattern B" "Pattern C" "Pattern D" "Pattern E"; do
  if grep -q "$pattern" "$IP"; then
    ok "iteration-patterns: $pattern"
  else
    fail "iteration-patterns: $pattern missing"
  fi
done

# Tabla cuántos ciclos antes de escalate
if grep -qE "[Cc]uántos ciclos antes de escalate|ciclos antes de escal" "$IP"; then
  ok "iteration-patterns: tabla de ciclos antes de escalate"
else
  fail "iteration-patterns: ciclos table missing"
fi

# Patterns que NO son sprint
if grep -qE "[Pp]atterns que NO son sprint|NO son sprint" "$IP"; then
  ok "iteration-patterns: anti-patterns explícitos"
else
  fail "iteration-patterns: anti-patterns missing"
fi

# ── L2 — examples.md structure ───────────────────────────────────────
echo ""
echo "L2 — references/examples.md (3 escenarios)"

EX="$SKILL_DIR/references/examples.md"

# 3 escenarios
for esc in "Escenario 1" "Escenario 2" "Escenario 3"; do
  if grep -q "$esc" "$EX"; then
    ok "examples: $esc"
  else
    fail "examples: $esc missing"
  fi
done

# Patterns aplicados (A, B, C según user spec)
for pat in "Pattern A" "Pattern B" "Pattern C"; do
  if grep -q "$pat" "$EX"; then
    ok "examples: $pat referenced"
  else
    fail "examples: $pat not referenced"
  fi
done

# Anti-pattern observable
if grep -qE "[Aa]nti-pattern observable|sprint que NO debería" "$EX"; then
  ok "examples: anti-pattern observable documented"
else
  fail "examples: anti-pattern observable missing"
fi

# Cierre con commit shape (R2)
if grep -qE "Commit:.*\\\`\\\`\\\`|^\\\`\\\`\\\`$" "$EX"; then
  ok "examples: commit shape mostrado"
else
  fail "examples: commit shape missing"
fi

# Citations
for rule in "R10" "R2" "L-003"; do
  if grep -q "$rule" "$EX"; then
    ok "examples: cites $rule"
  else
    fail "examples: missing $rule citation"
  fi
done

# ── L3 — Simulated sprint loop output shape ──────────────────────────
echo ""
echo "L3 — Simulated sprint loop output shape"

# Validar que un dry-run mental produce los elementos canónicos:
# 1. Triage decision (con 3 ejes)
# 2. Plan rápido (criterio + ciclos esperados)
# 3. N ciclos visibles (cada uno con cambio + diff + 4-option feedback)
# 4. Cierre canónico (DONE / PAUSE / ESCALATE)

# Esto se hace inspeccionando que examples.md contiene los 4 elementos
# para cada uno de los 3 escenarios documentados.

# Escenario 1 (CTA copy iteration)
if grep -A1 "Escenario 1" "$EX" | grep -q "CTA"; then
  ok "L3 escenario 1: CTA copy iteration"
fi

# Cada escenario tiene Triage + Loop ciclos + Cierre (Plan está dentro de Triage, no es header standalone)
for elem in "Triage" "Ciclo 1" "Cierre"; do
  esc_count=$(grep -c "$elem" "$EX")
  if [ "$esc_count" -ge 3 ]; then
    ok "L3: '$elem' aparece >=3 veces (uno por escenario)"
  else
    fail "L3: '$elem' aparece $esc_count veces (esperado >=3)"
  fi
done

# Validar shape del feedback: las 4 opciones explícitas en cada ciclo
feedback_options=$(grep -c "continúa.*pause.*done.*escalate\\|continúa.*done.*escalate\\|\`continúa\`" "$EX")
if [ "$feedback_options" -ge 3 ]; then
  ok "L3: feedback con 4 opciones en >=3 ciclos"
else
  fail "L3: 4-option feedback aparece $feedback_options veces (esperado >=3)"
fi

# Cierre con commit conventional R2 shape en escenarios DONE
if grep -qE "docs\\(F[0-9]+-[A-Z]?[0-9]+\\)|style\\(F[0-9]+-[A-Z]?[0-9]+\\)|fix\\(F[0-9]+-[A-Z]?[0-9]+\\)|feat\\(F[0-9]+-[A-Z]?[0-9]+\\)" "$EX"; then
  ok "L3: cierre con commit shape conventional R2"
else
  fail "L3: commit shape conventional missing"
fi

# Triage handoff documented (escenario anti-pattern)
if grep -q "HANDOFF" "$EX"; then
  ok "L3: triage handoff documentado en anti-pattern"
else
  fail "L3: triage handoff missing"
fi

# ── L3 — Simulated sprint dry-run mental ─────────────────────────────
echo ""
echo "L3 — Simulated sprint loop (mental dry-run)"

# Input: "mejorá el copy del CTA del hero"
# Expected: triage detects sprint material (Pattern A)
# Expected output structure validates against examples.md escenario 1

# 1. Triage produces sprint decision
if grep -qE "sprint material|Pattern A" "$EX"; then
  ok "Mental dry-run: 'mejorá CTA' → triage produces sprint decision (Pattern A)"
else
  fail "Mental dry-run: triage path missing"
fi

# 2. Plan establishes criterion
if grep -qE "[Cc]riterio:.*'me gusta'|criterio.*voice" "$EX"; then
  ok "Mental dry-run: plan establishes concrete criterion"
else
  fail "Mental dry-run: criterion missing"
fi

# 3. Loop has at least 2 cycles in escenario 1
if grep -E "Ciclo [12]" "$EX" | head -2 | wc -l | grep -q "2"; then
  ok "Mental dry-run: loop has >=2 cycles documented"
else
  fail "Mental dry-run: insufficient cycles"
fi

# 4. Closure produces atomic commit
if grep -qE "Sprint cerrado.*DONE" "$EX"; then
  ok "Mental dry-run: closure produces DONE state"
else
  fail "Mental dry-run: closure DONE missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ sprint dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ sprint dry-run: $FAIL failures"
  exit 1
fi
