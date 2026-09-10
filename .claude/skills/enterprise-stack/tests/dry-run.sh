#!/usr/bin/env bash
# enterprise-stack dry-run test
#
# L1 (file presence + frontmatter) + L2 (PREFLIGHT + binary mode + 3-wizard chain
# + R6 validation) + L3 (S1-S6 escenarios canónicos).
# E-008: grep -E con | plain.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── enterprise-stack dry-run ────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

es_files=(
  "SKILL.md"
  "prompts/detect-state.md"
  "prompts/run-step.md"
  "references/chain-rationale.md"
)
for f in "${es_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "enterprise-stack: $f"; else fail "missing: $f"; fi
done

# Wizard shape: NO templates folder
if [ -d "$SKILL_DIR/templates" ]; then
  fail "templates/ folder existe"
else
  ok "NO templates/ folder (wizard thin OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: enterprise-stack$" "$SKILL"; then ok "name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "$field"; else fail "$field missing"; fi
done

# Dependencies = los 3 wizards hijos
if grep -qE "^dependencies: \[init-saas.*add-monetization.*add-mobile-stack\]|^dependencies: \[init-saas, add-monetization, add-mobile-stack\]" "$SKILL"; then
  ok "dependencies = 3 wizards hijos"
else
  fail "dependencies wrong"
fi

if grep -qE "^tier: core" "$SKILL"; then ok "tier core"; else fail "tier wrong"; fi

# ── L2 — PREFLIGHT (4 gates incluyendo R6) ────────────────────────
echo ""
echo "L2 — SKILL.md PREFLIGHT"

if grep -qE "^## PREFLIGHT" "$SKILL"; then ok "PREFLIGHT section"; else fail "PREFLIGHT missing"; fi

# Gate 1: AGENTS.md
if grep -qE "AGENTS\.md.*raíz|halt.*AGENTS" "$SKILL"; then
  ok "PREFLIGHT gate AGENTS.md"
else
  fail "gate AGENTS.md missing"
fi

# Gate 2: Next.js
if grep -qE "src/.*pages/|Next\.js" "$SKILL"; then
  ok "PREFLIGHT gate Next.js"
else
  fail "gate Next.js missing"
fi

# Gate 3: R6 skills.md validation (CRÍTICO para wizard de wizards)
if grep -qE "skills\.md|R6" "$SKILL"; then
  ok "PREFLIGHT gate R6 skills.md validation"
else
  fail "gate R6 missing"
fi

# Gate 4: active feature soft warning (R1)
if grep -qE "active feature.*R1|R1.*active feature" "$SKILL"; then
  ok "PREFLIGHT gate active feature soft (R1)"
else
  fail "gate R1 missing"
fi

# ── L2 — Binary mode (D-022) ──────────────────────────────────────
echo ""
echo "L2 — Binary mode D-022"

if grep -qE "FULL.*default|default.*FULL" "$SKILL"; then
  ok "FULL default declarado"
else
  fail "FULL default missing"
fi

if grep -qE "CUSTOM.*override|override.*CUSTOM" "$SKILL"; then
  ok "CUSTOM override"
else
  fail "CUSTOM missing"
fi

# 3 wizards hijos
for wizard in "init-saas" "add-monetization" "add-mobile-stack"; do
  if grep -q "$wizard" "$SKILL"; then ok "wizard '$wizard'"; else fail "wizard '$wizard' missing"; fi
done

# D-022 cited
if grep -q "D-022" "$SKILL"; then ok "cita D-022"; else fail "D-022 missing"; fi

# D-019 informativo (init-saas patrón heredado)
if grep -q "D-019" "$SKILL"; then ok "cita D-019 (init-saas)"; else fail "D-019 missing"; fi

# D-020 doctrine
if grep -q "D-020" "$SKILL"; then ok "cita D-020 (PAUSE doctrine)"; else fail "D-020 missing"; fi

# D-021 informativo (add-mobile-stack patrón heredado)
if grep -q "D-021" "$SKILL"; then ok "cita D-021 (add-mobile-stack)"; else fail "D-021 missing"; fi

# L-004 informativo
if grep -q "L-004" "$SKILL"; then ok "cita L-004"; else fail "L-004 missing"; fi

# Hard rules R4/R5/R6/R10
for rule in "R4" "R5" "R6" "R10"; do
  if grep -q "$rule" "$SKILL"; then ok "cites $rule"; else fail "$rule missing"; fi
done

# NO PAUSE genuino documentado
if grep -qE "NO PAUSE|sin PAUSE" "$SKILL"; then
  ok "NO PAUSE explícito"
else
  fail "NO PAUSE missing"
fi

# Pipeline canónico documentado (3 wizards)
if grep -qE "Pipeline canónico|3 wizards|los 3 wizards" "$SKILL"; then
  ok "pipeline 3 wizards documented"
else
  fail "pipeline missing"
fi

# Boundaries
for skill in "init-saas" "add-monetization" "add-mobile-stack" "el-crisol" "el-evaluador" "el-guardian" "la-forja"; do
  if grep -q "$skill" "$SKILL"; then ok "boundary '$skill'"; else fail "boundary '$skill' missing"; fi
done

if grep -qE "^## Refusals" "$SKILL"; then ok "Refusals"; else fail "Refusals missing"; fi

if grep -qE "Tool filter|NO Edit|NO Write|NO Skill" "$SKILL"; then ok "Tool filter"; else fail "Tool filter missing"; fi

# ── L2 — detect-state.md ────────────────────────────────────────
echo ""
echo "L2 — detect-state.md"

DS="$SKILL_DIR/prompts/detect-state.md"

# Scan paths de los 3 wizards
if grep -qE "init_saas|init-saas DONE" "$DS"; then ok "scan init-saas DONE"; else fail "init-saas scan missing"; fi
if grep -qE "add_monetization|add-monetization DONE" "$DS"; then ok "scan add-monetization DONE"; else fail "add-monetization scan missing"; fi
if grep -qE "add_mobile_stack|add-mobile-stack DONE" "$DS"; then ok "scan add-mobile-stack DONE"; else fail "add-mobile-stack scan missing"; fi

# 4 modos de inicio
for modo in "go" "custom" "solo" "abort"; do
  if grep -qE "\"$modo|\`$modo" "$DS"; then ok "mode '$modo'"; else fail "mode '$modo' missing"; fi
done

# L-004 test aplicado
if grep -qE "L-004 test|test diagnóstico" "$DS"; then
  ok "L-004 test"
else
  fail "L-004 test missing"
fi

# Edge cases (>=4)
ds_edges=$(grep -c "^### Edge" "$DS")
if [ "$ds_edges" -ge 4 ]; then ok "$ds_edges edges"; else fail "only $ds_edges"; fi

# ── L2 — run-step.md ────────────────────────────────────────────
echo ""
echo "L2 — run-step.md"

RS="$SKILL_DIR/prompts/run-step.md"

# Protocol 6+ sub-steps (incluyendo PAUSE y SKIPPED handling)
for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5" "Step 6"; do
  if grep -qE "^### $step" "$RS"; then ok "protocol $step"; else fail "$step missing"; fi
done

# R4 enforcement
if grep -qE "R4 enforced|R4 strict|enterprise-stack MISMA NO" "$RS"; then
  ok "R4 enforced"
else
  fail "R4 missing"
fi

# R5 enforcement
if grep -qE "R5 strict|workers no escriben|NO escriben.*memory|NO tienen Write" "$RS"; then
  ok "R5 enforced"
else
  fail "R5 missing"
fi

# R6 enforcement (CRÍTICO en wizard de wizards)
if grep -qE "R6 validation|skills\.md.*pre-dispatch|R6 enforcement" "$RS"; then
  ok "R6 enforcement explicit"
else
  fail "R6 missing"
fi

# Context propagation
if grep -qE "context_acumulado|cross-wizards|propagation" "$RS"; then
  ok "context propagation cross-wizards"
else
  fail "context propagation missing"
fi

# PAUSE-interno-delegado (D-020 heredada)
if grep -qE "PAUSE-interno-delegado|D-020" "$RS"; then
  ok "PAUSE-interno-delegado distinction"
else
  fail "PAUSE distinction missing"
fi

# Halt + handoff si wizard falla
if grep -qE "Halt.*handoff|halt.*handoff|wizard falla|wizard hijo falla" "$RS"; then
  ok "halt + handoff if wizard fails"
else
  fail "halt handoff missing"
fi

# Edge cases
rs_edges=$(grep -c "^### Edge" "$RS")
if [ "$rs_edges" -ge 4 ]; then ok "$rs_edges edges"; else fail "only $rs_edges"; fi

# ── L2 — chain-rationale.md ────────────────────────────────────
echo ""
echo "L2 — chain-rationale.md"

CR="$SKILL_DIR/references/chain-rationale.md"

if grep -qE "Pipeline canónico|cadena canónica" "$CR"; then ok "pipeline canónico"; else fail "pipeline missing"; fi

# Cada wizard documentado
for wizard in "Wizard 1" "Wizard 2" "Wizard 3"; do
  if grep -q "$wizard" "$CR"; then ok "$wizard"; else fail "$wizard missing"; fi
done

# Permutaciones
if grep -qE "Permutación|permutables|único orden válido|FULL default|CUSTOM" "$CR"; then
  ok "permutaciones documented"
else
  fail "permutaciones missing"
fi

# Comparación con wizards hijos
if grep -qE "init-saas|add-monetization|add-mobile-stack|wizard de wizards" "$CR"; then
  ok "comparison wizards hijos"
else
  fail "comparison missing"
fi

# Cross-skill applicability
if grep -qE "Cross-skill applicability|patrón.*wizard|aplicable a" "$CR"; then
  ok "patrón wizard applicability"
else
  fail "patrón wizard missing"
fi

# ── L3 — escenarios canónicos S1-S6 ───────────────────────────
echo ""
echo "L3 — escenarios canónicos"

# S1: PREFLIGHT halt sin AGENTS.md
if grep -qE "halt.*AGENTS|AGENTS.*halt" "$SKILL"; then
  ok "L3 S1: PREFLIGHT halt sin AGENTS.md"
else
  fail "L3 S1: missing"
fi

# S2: detect-state — tabla con ✅/⬜
if grep -qE "✅|⬜" "$DS" "$SKILL"; then
  ok "L3 S2: tabla con checkmarks"
else
  fail "L3 S2: missing"
fi

# S3: FULL path — chain completa (3 wizards)
if grep -qE "FULL.*default|3 wizards|chain completa" "$DS" "$SKILL"; then
  ok "L3 S3: FULL path chain completa"
else
  fail "L3 S3: missing"
fi

# S4: CUSTOM path — skip wizards específicos
if grep -qE "CUSTOM.*skip|skip wizards|custom_skip" "$DS" "$SKILL"; then
  ok "L3 S4: CUSTOM skip override"
else
  fail "L3 S4: missing"
fi

# S5: handoff explícito cuando wizard falla
if grep -qE "halt.*handoff|wizard falla|wizard hijo falla" "$RS" "$SKILL"; then
  ok "L3 S5: handoff explícito cuando falla"
else
  fail "L3 S5: missing"
fi

# S6: handoff final menciona el-guardian + /build
if grep -qE "el-guardian" "$SKILL" && grep -qE "/build|la-forja" "$SKILL"; then
  ok "L3 S6: handoff final menciona el-guardian + /build"
else
  fail "L3 S6: missing"
fi

# ── L3 — D-022 binary application ─────────────────────────────────
echo ""
echo "L3 — D-022 binary application"

if grep -qiE "binary.*confirm|confirm.*binary|BINARY.*confirmed" "$SKILL" "$DS"; then
  ok "binary confirmed"
else
  fail "binary confirmation missing"
fi

if grep -qE "FULL.*CUSTOM|2 modos|binary" "$SKILL"; then
  ok "2 modos documentados"
else
  fail "modos missing"
fi

if grep -qE "resume-aware|resume.*aware" "$SKILL" "$DS"; then
  ok "resume-aware feature"
else
  fail "resume-aware missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ enterprise-stack dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ enterprise-stack dry-run: $FAIL failures"
  exit 1
fi
