#!/usr/bin/env bash
# add-mobile-stack dry-run test
#
# L1 (file presence + frontmatter) + L2 (PREFLIGHT + binary mode + 4-step chain)
# + L3 (S1-S6 escenarios canónicos).
# E-008: grep -E con | plain (NUNCA \| ni \\|).
# F3-S10/S11/S12 frictions absorbidas: -i, mode patterns relax, -- separator.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── add-mobile-stack dry-run ────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

ams_files=(
  "SKILL.md"
  "prompts/detect-state.md"
  "prompts/run-step.md"
  "references/chain-rationale.md"
)
for f in "${ams_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "add-mobile-stack: $f"; else fail "missing: $f"; fi
done

# Wizard shape: NO templates folder
if [ -d "$SKILL_DIR/templates" ]; then
  fail "templates/ folder existe (wizard no debe)"
else
  ok "NO templates/ folder (wizard thin OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: add-mobile-stack$" "$SKILL"; then ok "name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "$field"; else fail "$field missing"; fi
done

# Dependencies = wizard chain (4 skills)
if grep -qE "^dependencies: \[find-docs.*add-ui-kit.*impeccable.*add-login.*add-mobile.*baas\]|^dependencies: \[find-docs, add-ui-kit, impeccable, add-login, add-mobile, baas\]" "$SKILL"; then
  ok "dependencies cadena 4-step wizard"
else
  fail "dependencies cadena wrong"
fi

if grep -qE "^tier: core" "$SKILL"; then ok "tier core"; else fail "tier wrong"; fi

# ── L2 — PREFLIGHT (3 gates) ──────────────────────────────────────
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

# Gate 3: active feature soft warning (R1)
if grep -qE "active feature.*R1|R1.*active feature" "$SKILL"; then
  ok "PREFLIGHT gate active feature soft (R1)"
else
  fail "gate R1 missing"
fi

# ── L2 — Binary mode (D-021) ──────────────────────────────────────
echo ""
echo "L2 — Binary mode D-021"

if grep -qE "FRESH.*default|default.*FRESH" "$SKILL"; then
  ok "FRESH default declarado"
else
  fail "FRESH default missing"
fi

if grep -qE "EXISTING.*resume|resume-aware.*EXISTING|resume.*aware" "$SKILL"; then
  ok "EXISTING resume-aware"
else
  fail "EXISTING missing"
fi

# 4 pasos canónicos
for step in "add-ui-kit" "impeccable" "add-login" "add-mobile"; do
  if grep -q "$step" "$SKILL"; then ok "paso '$step'"; else fail "paso '$step' missing"; fi
done

# D-021 cited
if grep -q "D-021" "$SKILL"; then ok "cita D-021"; else fail "D-021 missing"; fi

# D-019 informativo (patrón heredado)
if grep -q "D-019" "$SKILL"; then ok "cita D-019 (patrón heredado)"; else fail "D-019 missing"; fi

# D-020 doctrine (PAUSE-interno-delegado)
if grep -q "D-020" "$SKILL"; then ok "cita D-020 (PAUSE doctrine)"; else fail "D-020 missing"; fi

# D-012 add-mobile binary interno
if grep -q "D-012" "$SKILL"; then ok "cita D-012 (add-mobile binary)"; else fail "D-012 missing"; fi

# L-004 informativo
if grep -q "L-004" "$SKILL"; then ok "cita L-004"; else fail "L-004 missing"; fi

# Hard rules R4/R5/R10
for rule in "R4" "R5" "R10"; do
  if grep -q "$rule" "$SKILL"; then ok "cites $rule"; else fail "$rule missing"; fi
done

# NO PAUSE genuino documentado
if grep -qE "NO PAUSE|sin PAUSE" "$SKILL"; then
  ok "NO PAUSE explícito"
else
  fail "NO PAUSE missing"
fi

# Pipeline canónico documentado (4 pasos)
if grep -qE "Pipeline canónico|4 pasos|los 4 pasos" "$SKILL"; then
  ok "pipeline 4 pasos documented"
else
  fail "pipeline missing"
fi

# Boundaries
for skill in "el-crisol" "init-saas" "add-monetization" "enterprise-stack" "el-evaluador" "la-forja"; do
  if grep -q "$skill" "$SKILL"; then ok "boundary '$skill'"; else fail "boundary '$skill' missing"; fi
done

if grep -qE "^## Refusals" "$SKILL"; then ok "Refusals"; else fail "Refusals missing"; fi

if grep -qE "Tool filter|NO Edit|NO Write|NO Skill" "$SKILL"; then ok "Tool filter"; else fail "Tool filter missing"; fi

# ── L2 — detect-state.md ────────────────────────────────────────
echo ""
echo "L2 — detect-state.md"

DS="$SKILL_DIR/prompts/detect-state.md"

# Scan paths Brand DNA
for path in "brand\.json" "voice\.json" "brand\.css"; do
  if grep -qE "$path" "$DS"; then ok "scan $path"; else fail "$path missing"; fi
done

# component_rules
if grep -qE "component_rules\.json" "$DS"; then ok "scan component_rules"; else fail "component_rules missing"; fi

# auth folder
if grep -qE "src/features/auth|app/\\\\\\(auth\\\\\\)|features/auth" "$DS"; then
  ok "scan auth folder"
else
  fail "auth folder scan missing"
fi

# manifest.json + sw.js (mobile-specific)
for path in "manifest\.json" "sw\.js"; do
  if grep -qE "$path" "$DS"; then ok "scan $path (mobile)"; else fail "$path missing"; fi
done

# push subscriptions migration
if grep -qE "push_subscriptions" "$DS"; then ok "scan push_subscriptions"; else fail "push_subscriptions missing"; fi

# 4 modos de inicio
for modo in "go" "desde" "solo" "abort"; do
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

# Protocol 6 sub-steps
for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5" "Step 6"; do
  if grep -qE "^### $step" "$RS"; then ok "protocol $step"; else fail "$step missing"; fi
done

# R4 enforcement
if grep -qE "R4 enforced|R4 strict|add-mobile-stack MISMA NO" "$RS"; then
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

# Context propagation
if grep -qE "context_acumulado|propagación.*contexto|propaga cross-pasos|Context propagation" "$RS"; then
  ok "context propagation"
else
  fail "context propagation missing"
fi

# PAUSE-interno-delegado distinción
if grep -qE "PAUSE-interno-delegado|PAUSE.*interno|D-020" "$RS"; then
  ok "PAUSE-interno-delegado distinction"
else
  fail "PAUSE distinction missing"
fi

# Halt + handoff si paso falla
if grep -qE "Halt.*handoff|halt.*handoff|paso falla" "$RS"; then
  ok "halt + handoff if step fails"
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

if grep -qE "Cadena canónica|cadena canónica" "$CR"; then ok "cadena canónica"; else fail "cadena missing"; fi

# Cada paso documentado (4 pasos)
for step in "Paso 1" "Paso 2" "Paso 3" "Paso 4"; do
  if grep -q "$step" "$CR"; then ok "$step"; else fail "$step missing"; fi
done

# Permutaciones que fallan
if grep -qE "Permutación|permutables|único orden válido" "$CR"; then
  ok "permutaciones fail documented"
else
  fail "permutaciones missing"
fi

# E-006 extension explained (chicken-egg)
if grep -qE "chicken-egg|E-006" "$CR"; then
  ok "chicken-egg / E-006 extension"
else
  fail "chicken-egg missing"
fi

# Comparación con init-saas (shape-par)
if grep -qE "init-saas|shape-par" "$CR"; then
  ok "init-saas comparison"
else
  fail "init-saas comparison missing"
fi

# Cross-skill applicability (patrón wizard)
if grep -qE "patrón wizard|Cross-skill applicability|aplicable a" "$CR"; then
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

# S3: FRESH path — chain completa (4 pasos pendientes)
if grep -qE "0 de 4.*pendientes|FRESH path|chain completa|4 pasos" "$DS" "$SKILL"; then
  ok "L3 S3: FRESH path chain completa"
else
  fail "L3 S3: missing"
fi

# S4: EXISTING path — skip automático
if grep -qE "EXISTING.*skip|skip automático|skipea|saltea" "$DS" "$SKILL"; then
  ok "L3 S4: EXISTING skip automático"
else
  fail "L3 S4: missing"
fi

# S5: handoff explícito cuando paso falla
if grep -qE "halt.*handoff|paso falla|step fails" "$RS" "$SKILL"; then
  ok "L3 S5: handoff explícito cuando falla"
else
  fail "L3 S5: missing"
fi

# S6: handoff final menciona add-monetization y enterprise-stack
if grep -qE "add-monetization" "$SKILL" && grep -qE "enterprise-stack" "$SKILL"; then
  ok "L3 S6: handoff final menciona add-monetization + enterprise-stack"
else
  fail "L3 S6: missing"
fi

# ── L3 — D-021 binary application ─────────────────────────────────
echo ""
echo "L3 — D-021 binary application"

if grep -qiE "binary.*confirm|confirm.*binary|BINARY.*confirmed" "$SKILL" "$DS"; then
  ok "binary confirmed"
else
  fail "binary confirmation missing"
fi

if grep -qE "FRESH.*EXISTING|2 modos|binary" "$SKILL"; then
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
  echo "✅ add-mobile-stack dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-mobile-stack dry-run: $FAIL failures"
  exit 1
fi
