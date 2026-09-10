#!/usr/bin/env bash
# el-tajo dry-run test
#
# L1 (file presence) + L2 (PREFLIGHT + scope-check) + L3 (5 escenarios S1-S5).
# E-008: grep -E con | plain (NUNCA \| ni \\|).
# F3-S10/S11 frictions absorbidas: mode patterns relax, -i, `--` separator.
#
# Usage: bash .claude/skills/el-tajo/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── el-tajo dry-run ─────────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

el_tajo_files=(
  "SKILL.md"
  "prompts/scope-check.md"
  "references/examples.md"
)
for f in "${el_tajo_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "el-tajo: $f"; else fail "el-tajo missing: $f"; fi
done

# NO templates folder (lightweight)
if [ -d "$SKILL_DIR/templates" ]; then
  fail "el-tajo: templates/ folder existe (lightweight no debe tener)"
else
  ok "el-tajo: NO templates/ folder (lightweight OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: el-tajo$" "$SKILL"; then
  ok "SKILL.md: name field"
else
  fail "SKILL.md: name field missing"
fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then
    ok "SKILL.md: $field field"
  else
    fail "SKILL.md: $field missing"
  fi
done

if grep -qE "^dependencies: \[\]" "$SKILL"; then
  ok "SKILL.md: dependencies empty (no upstream)"
else
  fail "SKILL.md: dependencies field incorrect"
fi

# tier: core (lightweight)
if grep -qE "tier: core \(lightweight\)|core.*lightweight" "$SKILL"; then
  ok "SKILL.md: tier core (lightweight)"
else
  fail "SKILL.md: tier lightweight missing"
fi

# ── L2 — SKILL.md PREFLIGHT (2 gates duros) ─────────────────────────
echo ""
echo "L2 — SKILL.md PREFLIGHT"

if grep -qE "^## PREFLIGHT" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT section"
else
  fail "SKILL.md: PREFLIGHT missing"
fi

# Gate 1: active feature (R1)
if grep -qE "active feature.*feature_list|R1" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT gate active feature (R1)"
else
  fail "SKILL.md: gate active feature missing"
fi

# Gate 2: tests + lint passing
if grep -qE "[Tt]ests \+ lint|tests.*lint pasando|tests rojos" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT gate tests passing"
else
  fail "SKILL.md: gate tests missing"
fi

# Halt en blockers reales
if grep -qE "halt.*active feature|halt.*tests rojos" "$SKILL"; then
  ok "SKILL.md: halt-blocked en blockers reales"
else
  fail "SKILL.md: halt missing"
fi

# Scope criterios atómicos
for criterion in "<5min" "<500 LOC" "1-3 archivos"; do
  if grep -qF "$criterion" "$SKILL"; then
    ok "SKILL.md: criterio '$criterion'"
  else
    # alternativa con menos de
    if grep -qE "5 ?min|500 LOC|1.3 archivos|3 archivos" "$SKILL"; then
      ok "SKILL.md: criterio '$criterion' (variante)"
    else
      fail "SKILL.md: criterio '$criterion' missing"
    fi
  fi
done

# Loop de ejecución 4 fases
for phase in "SCOPE-CHECK" "EXECUTE" "VERIFY" "COMMIT"; do
  if grep -q "$phase" "$SKILL"; then
    ok "SKILL.md: phase '$phase'"
  else
    fail "SKILL.md: phase '$phase' missing"
  fi
done

# Hard rules R1/R2
for rule in "R1" "R2"; do
  if grep -q "$rule" "$SKILL"; then
    ok "SKILL.md cites $rule"
  else
    fail "SKILL.md missing $rule"
  fi
done

# L-004 + D-016
if grep -q "L-004" "$SKILL"; then
  ok "SKILL.md cites L-004 (informativo)"
else
  fail "SKILL.md L-004 missing"
fi

if grep -q "D-016" "$SKILL"; then
  ok "SKILL.md cites D-016 (binary)"
else
  fail "SKILL.md D-016 missing"
fi

# Escalation a el-golpe (binary D-016)
if grep -qE "escalate.*el-golpe|escalación.*el-golpe|escalate-graceful" "$SKILL"; then
  ok "SKILL.md: escalation a el-golpe documented"
else
  fail "SKILL.md: escalation missing"
fi

# Boundaries
for skill in "el-golpe" "sprint" "la-forja" "la-herreria" "el-evaluador"; do
  if grep -q "$skill" "$SKILL"; then
    ok "SKILL.md: boundary '$skill'"
  else
    fail "SKILL.md: boundary '$skill' missing"
  fi
done

# Refusals section
if grep -qE "^## Refusals" "$SKILL"; then
  ok "SKILL.md: Refusals section"
else
  fail "SKILL.md: Refusals missing"
fi

# Tool filter
if grep -qE "Tool filter|Read.*Edit.*Write" "$SKILL"; then
  ok "SKILL.md: Tool filter"
else
  fail "SKILL.md: Tool filter missing"
fi

# NO discovery, NO planning, NO loop (case-insensitive — el-tajo usa "Sin loop" en español)
for refusal in "NO discovery|sin discovery|Sin discovery" "NO planning|sin planning|Sin planning" "NO loop|sin loop|Sin loop|NO sprint"; do
  pattern_clean=$(echo "$refusal" | sed 's/\\|/|/g')
  if grep -qiE "$pattern_clean" "$SKILL"; then
    ok "SKILL.md: refusal '$refusal'"
  else
    fail "SKILL.md: refusal '$refusal' missing"
  fi
done

# ── L2 — scope-check.md ──────────────────────────────────────────────
echo ""
echo "L2 — scope-check.md"

SC="$SKILL_DIR/prompts/scope-check.md"

# Inputs/Output
if grep -qE "^## Inputs|^## Output" "$SC"; then
  ok "scope-check: Inputs/Output sections"
else
  fail "scope-check: I/O sections missing"
fi

# Output YAML shape
if grep -qE "outcome: execute \\| escalate|outcome: execute" "$SC"; then
  ok "scope-check: output YAML shape"
else
  fail "scope-check: output shape missing"
fi

# 3 criterios atómicos (los 3 son AND)
for criterion in "Wallclock" "LOC" "[Aa]rchivos modificados"; do
  if grep -qE "$criterion" "$SC"; then
    ok "scope-check: criterion '$criterion'"
  else
    fail "scope-check: criterion '$criterion' missing"
  fi
done

# Heurísticas adicionales
if grep -qE "[Hh]eurísticas|heurísticas adicionales" "$SC"; then
  ok "scope-check: heurísticas adicionales section"
else
  fail "scope-check: heurísticas missing"
fi

# L-004 + D-016 cited
if grep -q "L-004" "$SC"; then
  ok "scope-check: L-004 cited"
else
  fail "scope-check: L-004 missing"
fi

if grep -q "D-016" "$SC"; then
  ok "scope-check: D-016 cited"
else
  fail "scope-check: D-016 missing"
fi

# Decision tree
if grep -qE "[Dd]ecision tree" "$SC"; then
  ok "scope-check: decision tree"
else
  fail "scope-check: decision tree missing"
fi

# Edge cases (>=4)
sc_edges=$(grep -c "^### Edge" "$SC")
if [ "$sc_edges" -ge 4 ]; then
  ok "scope-check: $sc_edges edge cases (>=4)"
else
  fail "scope-check: only $sc_edges edge cases"
fi

# Escalation messaging
if grep -qE "Tajo escalation|escalation messaging" "$SC"; then
  ok "scope-check: escalation messaging"
else
  fail "scope-check: escalation messaging missing"
fi

# ── L2 — references/examples.md ──────────────────────────────────────
echo ""
echo "L2 — references/examples.md"

EX="$SKILL_DIR/references/examples.md"

# 3 escenarios
for esc in "Escenario 1" "Escenario 2" "Escenario 3"; do
  if grep -q "$esc" "$EX"; then
    ok "examples: $esc"
  else
    fail "examples: $esc missing"
  fi
done

# Anti-pattern observable
if grep -qE "[Aa]nti-pattern observable|escalation NO ejecutado" "$EX"; then
  ok "examples: anti-pattern observable"
else
  fail "examples: anti-pattern missing"
fi

# Tabla resumen
if grep -qE "Tabla resumen|3 escenarios" "$EX"; then
  ok "examples: tabla resumen"
else
  fail "examples: tabla missing"
fi

# Commit shape conventional R2
if grep -qE "refactor\(F[0-9]+-S\?\)|chore\(F[0-9]+-S\?\)|feat\(F[0-9]+-S\?\)" "$EX"; then
  ok "examples: commit shape conventional R2"
else
  fail "examples: commit shape missing"
fi

# ── L3 — 5 escenarios canónicos S1-S5 ────────────────────────────────
echo ""
echo "L3 — 5 escenarios canónicos S1-S5"

# S1: PREFLIGHT halt sin active feature
if grep -qE "halt.*active feature|sin active feature.*halt" "$SKILL"; then
  ok "L3 S1: PREFLIGHT halt sin active feature"
else
  fail "L3 S1: missing"
fi

# S2: PREFLIGHT halt con tests rojos
if grep -qE "tests rojos.*halt|halt.*tests rojos|NO arranca con tests rojos" "$SKILL"; then
  ok "L3 S2: PREFLIGHT halt con tests rojos"
else
  fail "L3 S2: missing"
fi

# S3: scope check — tarea dentro de rango (window -A20 — yaml está ~10 lines después del header)
if grep -A20 "Escenario 1" "$EX" | grep -qE "execute|wallclock_min: [1-4]"; then
  ok "L3 S3: scope check execute (Escenario 1)"
else
  fail "L3 S3: missing"
fi

# S4: escalación a el-golpe cuando excede
if grep -qE "Tajo escalation.*el-golpe|escalation.*el-golpe" "$EX" "$SC"; then
  ok "L3 S4: escalación a el-golpe documentada"
else
  fail "L3 S4: missing"
fi

# S5: output 1 atomic commit
if grep -qE "1 atomic commit|atomic commit.*R2|Commit:.*\`<type>" "$SKILL"; then
  ok "L3 S5: output 1 atomic commit"
else
  fail "L3 S5: missing"
fi

# ── L3 — D-016 binary aplicado ───────────────────────────────────────
echo ""
echo "L3 — D-016 binary application"

# Binary shape declarado
if grep -qiE "binary.*shape|D-016.*binary|binary.*D-016" "$SKILL" "$SC"; then
  ok "L3: binary shape declarado"
else
  fail "L3: binary shape missing"
fi

# NO PAUSE explícito
if grep -qE "NO PAUSE|sin PAUSE" "$SKILL" "$SC"; then
  ok "L3: NO PAUSE explícito"
else
  fail "L3: NO PAUSE missing"
fi

# Escalation siempre disponible
if grep -qE "siempre disponible|escalación.*siempre|always available" "$SC"; then
  ok "L3: escalación siempre disponible (no PAUSE)"
else
  fail "L3: always-available reasoning missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ el-tajo dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ el-tajo dry-run: $FAIL failures"
  exit 1
fi
