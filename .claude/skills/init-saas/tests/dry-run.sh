#!/usr/bin/env bash
# init-saas dry-run test
#
# L1 (file presence + frontmatter) + L2 (PREFLIGHT + binary mode + chain)
# + L3 (S1-S6 escenarios canónicos).
# E-008: grep -E con | plain (NUNCA \| ni \\|).
# F3-S10/S11/S12 frictions absorbidas: -i, mode patterns relax, -- separator.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── init-saas dry-run ───────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

init_saas_files=(
  "SKILL.md"
  "prompts/detect-state.md"
  "prompts/run-step.md"
  "references/chain-rationale.md"
)
for f in "${init_saas_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "init-saas: $f"; else fail "init-saas missing: $f"; fi
done

# Wizard shape: NO templates folder
if [ -d "$SKILL_DIR/templates" ]; then
  fail "init-saas: templates/ folder existe (wizard no debe tener)"
else
  ok "init-saas: NO templates/ folder (wizard thin OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: init-saas$" "$SKILL"; then ok "SKILL.md: name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "SKILL.md: $field"; else fail "$field missing"; fi
done

# Dependencies = wizard chain
if grep -qE "^dependencies: \[find-docs.*add-ui-kit.*impeccable.*add-login.*baas\]|^dependencies: \[find-docs, add-ui-kit, impeccable, add-login, baas\]" "$SKILL"; then
  ok "SKILL.md: dependencies cadena wizard"
else
  fail "dependencies cadena wrong"
fi

# tier: core
if grep -qE "^tier: core" "$SKILL"; then ok "SKILL.md: tier core"; else fail "tier wrong"; fi

# ── L2 — SKILL.md PREFLIGHT (3 gates) ──────────────────────────────
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

# ── L2 — Binary mode (D-019) ──────────────────────────────────────
echo ""
echo "L2 — Binary mode D-019"

# FRESH default
if grep -qE "FRESH.*default|default.*FRESH" "$SKILL"; then
  ok "SKILL.md: FRESH default declarado"
else
  fail "FRESH default missing"
fi

# EXISTING resume-aware
if grep -qE "EXISTING.*resume|resume-aware.*EXISTING|resume.*aware" "$SKILL"; then
  ok "SKILL.md: EXISTING resume-aware"
else
  fail "EXISTING missing"
fi

# 3 pasos canónicos
for step in "add-ui-kit" "impeccable" "add-login"; do
  if grep -q "$step" "$SKILL"; then ok "SKILL.md: paso '$step'"; else fail "paso '$step' missing"; fi
done

# Resuelve E-006
if grep -q "E-006" "$SKILL"; then ok "SKILL.md cita E-006"; else fail "E-006 missing"; fi

# D-019 cited
if grep -q "D-019" "$SKILL"; then ok "SKILL.md cita D-019"; else fail "D-019 missing"; fi

# L-004 informativo
if grep -q "L-004" "$SKILL"; then ok "SKILL.md cita L-004"; else fail "L-004 missing"; fi

# Hard rules R4/R5/R10
for rule in "R4" "R5" "R10"; do
  if grep -q "$rule" "$SKILL"; then ok "SKILL.md cites $rule"; else fail "$rule missing"; fi
done

# NO PAUSE genuino documentado
if grep -qE "NO PAUSE|sin PAUSE" "$SKILL"; then
  ok "SKILL.md: NO PAUSE explícito"
else
  fail "NO PAUSE missing"
fi

# Pipeline canónico documentado
if grep -qE "Pipeline canónico|3 pasos" "$SKILL"; then
  ok "SKILL.md: pipeline canónico documented"
else
  fail "pipeline missing"
fi

# Boundaries
for skill in "el-crisol" "add-monetization" "add-mobile" "el-evaluador" "la-forja"; do
  if grep -q "$skill" "$SKILL"; then ok "SKILL.md boundary '$skill'"; else fail "boundary '$skill' missing"; fi
done

# Refusals
if grep -qE "^## Refusals" "$SKILL"; then ok "SKILL.md: Refusals"; else fail "Refusals missing"; fi

# Tool filter
if grep -qE "Tool filter|NO Edit|NO Write|NO Skill" "$SKILL"; then ok "SKILL.md: Tool filter"; else fail "Tool filter missing"; fi

# ── L2 — detect-state.md (Fase 0) ────────────────────────────────
echo ""
echo "L2 — detect-state.md"

DS="$SKILL_DIR/prompts/detect-state.md"

# Scan paths Brand DNA
for path in "brand\.json" "voice\.json" "brand\.css"; do
  if grep -qE "$path" "$DS"; then ok "detect-state: scan $path"; else fail "$path missing"; fi
done

# component_rules.json
if grep -qE "component_rules\.json" "$DS"; then ok "detect-state: scan component_rules"; else fail "component_rules missing"; fi

# auth folder paths
if grep -qE "src/features/auth|app/\\\\\\(auth\\\\\\)|features/auth" "$DS"; then
  ok "detect-state: scan auth folder"
else
  fail "auth folder scan missing"
fi

# 4 modos de inicio
for modo in "go" "desde" "solo" "abort"; do
  if grep -qE "\"$modo|\`$modo" "$DS"; then ok "detect-state: mode '$modo'"; else fail "mode '$modo' missing"; fi
done

# L-004 test aplicado
if grep -qE "L-004 test|test diagnóstico" "$DS"; then
  ok "detect-state: L-004 test"
else
  fail "L-004 test missing"
fi

# Edge cases (>=4)
ds_edges=$(grep -c "^### Edge" "$DS")
if [ "$ds_edges" -ge 4 ]; then ok "detect-state: $ds_edges edges"; else fail "only $ds_edges"; fi

# ── L2 — run-step.md (Fase 1) ────────────────────────────────────
echo ""
echo "L2 — run-step.md"

RS="$SKILL_DIR/prompts/run-step.md"

# Protocol 6 steps
for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5" "Step 6"; do
  if grep -qE "^### $step" "$RS"; then ok "run-step: protocol $step"; else fail "$step missing"; fi
done

# R4 enforcement explícito
if grep -qE "R4 enforced|R4 strict|init-saas MISMA NO" "$RS"; then
  ok "run-step: R4 enforced"
else
  fail "R4 missing"
fi

# R5 enforcement
if grep -qE "R5 strict|workers no escriben|NO escriben.*memory" "$RS"; then
  ok "run-step: R5 enforced"
else
  fail "R5 missing"
fi

# Contexto que se propaga cross-pasos
if grep -qE "context_acumulado|propagación.*contexto|propaga cross-pasos" "$RS"; then
  ok "run-step: context propagation"
else
  fail "context propagation missing"
fi

# PAUSE-interno-delegado distinción
if grep -qE "PAUSE-interno-delegado|PAUSE.*interno|PAUSE.*delegado|D-020" "$RS"; then
  ok "run-step: PAUSE-interno-delegado distinction"
else
  fail "PAUSE distinction missing"
fi

# Halt + handoff si paso falla
if grep -qE "Halt.*handoff|halt.*handoff|paso falla" "$RS"; then
  ok "run-step: halt + handoff if step fails"
else
  fail "halt handoff missing"
fi

# Edge cases
rs_edges=$(grep -c "^### Edge" "$RS")
if [ "$rs_edges" -ge 4 ]; then ok "run-step: $rs_edges edges"; else fail "only $rs_edges"; fi

# ── L2 — references/chain-rationale.md ────────────────────────────
echo ""
echo "L2 — chain-rationale.md"

CR="$SKILL_DIR/references/chain-rationale.md"

# Cadena canónica documentada
if grep -qE "Cadena canónica|cadena canónica" "$CR"; then ok "chain-rationale: cadena canónica"; else fail "cadena missing"; fi

# Cada paso con outputs documentados
for step in "Paso 1" "Paso 2" "Paso 3"; do
  if grep -q "$step" "$CR"; then ok "chain-rationale: $step"; else fail "$step missing"; fi
done

# Permutaciones que fallan documentadas
if grep -qE "Permutación|permutables|único orden válido" "$CR"; then
  ok "chain-rationale: permutaciones fail documented"
else
  fail "permutaciones missing"
fi

# E-006 resolution explicado
if grep -qE "E-006|resuelve.*chicken-egg|cómo resuelve" "$CR"; then
  ok "chain-rationale: E-006 resolution"
else
  fail "E-006 resolution missing"
fi

# Comparación con el-crisol
if grep -qE "el-crisol|shape-par" "$CR"; then
  ok "chain-rationale: el-crisol comparison"
else
  fail "el-crisol comparison missing"
fi

# Cross-skill applicability (patrón wizard)
if grep -qE "patrón wizard|Cross-skill applicability|aplicable a" "$CR"; then
  ok "chain-rationale: patrón wizard applicability"
else
  fail "patrón wizard missing"
fi

# ── L3 — 6 escenarios canónicos S1-S6 ───────────────────────────
echo ""
echo "L3 — 6 escenarios canónicos S1-S6"

# S1: PREFLIGHT halt sin AGENTS.md
if grep -qE "halt.*AGENTS|AGENTS.*halt" "$SKILL"; then
  ok "L3 S1: PREFLIGHT halt sin AGENTS.md"
else
  fail "L3 S1: missing"
fi

# S2: detect-state — tabla con ✅/⬜
if grep -qE "✅|⬜" "$DS" "$SKILL"; then
  ok "L3 S2: tabla con checkmarks ✅/⬜"
else
  fail "L3 S2: missing"
fi

# S3: FRESH path — chain completa (3 pasos pendientes)
if grep -qE "0 de 3.*pendientes|FRESH path|chain completa" "$DS" "$SKILL"; then
  ok "L3 S3: FRESH path chain completa"
else
  fail "L3 S3: missing"
fi

# S4: EXISTING path — skip automático
if grep -qE "EXISTING.*skip|skip automático|saltea pasos completados|skipea" "$DS" "$SKILL"; then
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

# S6: handoff final menciona add-monetization y add-mobile
if grep -qE "add-monetization" "$SKILL" && grep -qE "add-mobile" "$SKILL"; then
  ok "L3 S6: handoff final menciona add-monetization + add-mobile"
else
  fail "L3 S6: missing"
fi

# ── L3 — D-019 binary application ─────────────────────────────────
echo ""
echo "L3 — D-019 binary application"

if grep -qiE "binary.*confirm|confirm.*binary|BINARY.*confirmed" "$SKILL" "$DS"; then
  ok "L3: binary confirmed"
else
  fail "L3: binary confirmation missing"
fi

if grep -qE "FRESH.*EXISTING|2 modos|binary" "$SKILL"; then
  ok "L3: 2 modos documentados"
else
  fail "L3: modos missing"
fi

# resume-aware feature explicit
if grep -qE "resume-aware|resume.*aware" "$SKILL" "$DS"; then
  ok "L3: resume-aware feature"
else
  fail "L3: resume-aware missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ init-saas dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ init-saas dry-run: $FAIL failures"
  exit 1
fi
