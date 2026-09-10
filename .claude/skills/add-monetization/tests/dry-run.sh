#!/usr/bin/env bash
# add-monetization dry-run test
#
# L1 (file presence + frontmatter) + L2 (PREFLIGHT + binary mode + chain
# + PAUSE-interno-delegado distinction) + L3 (S1-S7 escenarios canónicos).
# E-008 + F3-S10/S11/S12 frictions absorbidas.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── add-monetization dry-run ────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

am_files=(
  "SKILL.md"
  "prompts/detect-state.md"
  "prompts/run-step.md"
  "references/chain-rationale.md"
)
for f in "${am_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "add-monetization: $f"; else fail "missing: $f"; fi
done

if [ -d "$SKILL_DIR/templates" ]; then
  fail "templates/ folder existe (wizard no debe)"
else
  ok "NO templates/ folder (wizard thin OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: add-monetization$" "$SKILL"; then ok "name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "$field"; else fail "$field missing"; fi
done

# Dependencies = wizard chain
if grep -qE "^dependencies: \[find-docs.*add-payments.*add-emails.*web-quality.*add-login\]" "$SKILL"; then
  ok "dependencies cadena wizard"
else
  fail "dependencies wrong"
fi

if grep -qE "^tier: core" "$SKILL"; then ok "tier core"; else fail "tier wrong"; fi

# ── L2 — PREFLIGHT (4 gates) ────────────────────────────────────────
echo ""
echo "L2 — PREFLIGHT"

if grep -qE "^## PREFLIGHT" "$SKILL"; then ok "PREFLIGHT section"; else fail "missing"; fi

# Gate 1: add-login completed
if grep -qE "add-login completado|requiere add-login" "$SKILL"; then
  ok "gate add-login"
else
  fail "gate add-login missing"
fi

# Gate 2: brand.json
if grep -qE "brand\.json|Brand DNA" "$SKILL"; then
  ok "gate Brand DNA"
else
  fail "gate Brand DNA missing"
fi

# Gate 3: impeccable components
if grep -qE "impeccable components|core components" "$SKILL"; then
  ok "gate impeccable components"
else
  fail "gate impeccable missing"
fi

# Handoff a init-saas si add-login missing
if grep -qE "init-saas|halt.*init-saas" "$SKILL"; then
  ok "handoff a init-saas"
else
  fail "handoff init-saas missing"
fi

# ── L2 — Binary mode (D-020) + PAUSE-interno-delegado ──────────────
echo ""
echo "L2 — Binary D-020 + PAUSE-interno-delegado"

# Full chain default
if grep -qE "[Ff]ull chain.*default|default.*full chain" "$SKILL"; then
  ok "full chain default"
else
  fail "full chain default missing"
fi

# Partial mode override
if grep -qE "partial.*payments-only|payments-only.*override|partial mode" "$SKILL"; then
  ok "partial mode override"
else
  fail "partial mode missing"
fi

# 3 pasos
for step in "add-payments" "add-emails" "web-quality"; do
  if grep -q "$step" "$SKILL"; then ok "paso $step"; else fail "paso $step missing"; fi
done

# E-006 cited
if grep -q "E-006" "$SKILL"; then ok "cita E-006"; else fail "E-006 missing"; fi

# D-020 cited
if grep -q "D-020" "$SKILL"; then ok "cita D-020"; else fail "D-020 missing"; fi

# D-010 cited (PAUSE add-payments)
if grep -q "D-010" "$SKILL"; then ok "cita D-010 (PAUSE add-payments)"; else fail "D-010 missing"; fi

# L-004 cited
if grep -q "L-004" "$SKILL"; then ok "cita L-004"; else fail "L-004 missing"; fi

# Hard rules R4/R5/R10
for rule in "R4" "R5" "R10"; do
  if grep -q "$rule" "$SKILL"; then ok "cites $rule"; else fail "$rule missing"; fi
done

# CRÍTICO: PAUSE-interno-delegado distinction
if grep -qE "PAUSE-interno-delegado|PAUSE.interno.delegado" "$SKILL"; then
  ok "SKILL.md: PAUSE-interno-delegado distinction"
else
  fail "PAUSE-interno-delegado missing"
fi

# CRÍTICO: NO PAUSE wizard explícito
if grep -qE "NO PAUSE.wizard|NO PAUSE genuino|sin PAUSE" "$SKILL"; then
  ok "SKILL.md: NO PAUSE-wizard explícito"
else
  fail "NO PAUSE-wizard missing"
fi

# Boundaries
for skill in "add-payments" "add-emails" "web-quality" "init-saas" "el-evaluador" "el-guardian" "la-forja"; do
  if grep -q "$skill" "$SKILL"; then ok "boundary $skill"; else fail "boundary $skill missing"; fi
done

# Refusals
if grep -qE "^## Refusals" "$SKILL"; then ok "Refusals section"; else fail "Refusals missing"; fi

# Tool filter
if grep -qE "Tool filter|NO Edit|NO Write|NO Skill" "$SKILL"; then ok "Tool filter"; else fail "Tool filter missing"; fi

# ── L2 — detect-state.md ───────────────────────────────────────────
echo ""
echo "L2 — detect-state.md"

DS="$SKILL_DIR/prompts/detect-state.md"

# 3 paths scanned
for area in "payments" "emails" "audit\|web-audit"; do
  pat=$(echo "$area" | sed 's/\\|/|/g')
  if grep -qE "$pat" "$DS"; then ok "scan $area"; else fail "scan $area missing"; fi
done

# Provider detection (stripe/polar, resend/sendgrid)
for provider in "stripe" "polar" "resend" "sendgrid"; do
  if grep -qi "$provider" "$DS"; then ok "provider '$provider'"; else fail "provider '$provider' missing"; fi
done

# Audit age threshold
if grep -qE "report_age_days|age_days|<7 días" "$DS"; then
  ok "audit age threshold"
else
  fail "age threshold missing"
fi

# 4 modos
for modo in "go" "partial" "desde" "abort"; do
  if grep -qE "\"$modo|\`$modo|partial.*payments-only" "$DS"; then ok "mode '$modo'"; else fail "mode '$modo' missing"; fi
done

# L-004 test aplicado
if grep -qE "L-004 test|test diagnóstico" "$DS"; then
  ok "L-004 test applied"
else
  fail "L-004 test missing"
fi

# PAUSE-interno-delegado en detect-state edge cases
if grep -qE "PAUSE-interno-delegado|paused-internal" "$DS"; then
  ok "detect-state: PAUSE-interno-delegado distinción"
else
  fail "PAUSE-interno-delegado missing in detect-state"
fi

# Edge cases (>=4)
ds_edges=$(grep -c "^### Edge" "$DS")
if [ "$ds_edges" -ge 4 ]; then ok "$ds_edges edges"; else fail "only $ds_edges"; fi

# ── L2 — run-step.md (CRÍTICO PAUSE distinction) ───────────────────
echo ""
echo "L2 — run-step.md"

RS="$SKILL_DIR/prompts/run-step.md"

# Protocol steps
for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5" "Step 6"; do
  if grep -qE "^### $step" "$RS"; then ok "protocol $step"; else fail "$step missing"; fi
done

# R4/R5
if grep -qE "R4 enforced|R4 strict" "$RS"; then ok "R4 enforced"; else fail "R4 missing"; fi
if grep -qE "R5 strict|R5 enforced|workers no escriben" "$RS"; then ok "R5 enforced"; else fail "R5 missing"; fi

# CRÍTICO: 3 outcomes (success / failed / paused-internal)
for outcome in "success" "failed" "paused-internal"; do
  if grep -qE "outcome.*$outcome|$outcome.*outcome|$outcome:" "$RS"; then
    ok "outcome '$outcome'"
  else
    fail "outcome '$outcome' missing"
  fi
done

# CRÍTICO: PAUSE-interno-delegado section explicit
if grep -qE "PAUSE-interno-delegado|D-020 distinction" "$RS"; then
  ok "run-step: PAUSE-interno-delegado documented"
else
  fail "PAUSE-interno-delegado missing"
fi

# CRÍTICO: NO escala como PAUSE-wizard
if grep -qiE "NO escala.*PAUSE-wizard|NO escalar como PAUSE-wizard|NO se escala" "$RS"; then
  ok "run-step: NO escalar PAUSE explícito"
else
  fail "NO escalar PAUSE missing"
fi

# D-020 distinction documentation section
if grep -qE "D-020 distinction|D-020 documenta|implicaciones cross-skill" "$RS"; then
  ok "run-step: D-020 distinction section"
else
  fail "D-020 distinction section missing"
fi

# Resume-aware retoma post-PAUSE
if grep -qE "resume-aware.*retoma|re-invocá|resume-aware Fase 0" "$RS"; then
  ok "run-step: resume-aware retoma"
else
  fail "resume-aware retoma missing"
fi

# Edge cases
rs_edges=$(grep -c "^### Edge" "$RS")
if [ "$rs_edges" -ge 4 ]; then ok "$rs_edges edges"; else fail "only $rs_edges"; fi

# ── L2 — chain-rationale.md ────────────────────────────────────────
echo ""
echo "L2 — chain-rationale.md"

CR="$SKILL_DIR/references/chain-rationale.md"

# Cadena canónica
if grep -qE "Cadena canónica" "$CR"; then ok "cadena canónica"; else fail "cadena missing"; fi

# 3 pasos documented
for step in "Paso 1" "Paso 2" "Paso 3"; do
  if grep -q "$step" "$CR"; then ok "$step"; else fail "$step missing"; fi
done

# Permutaciones
if grep -qE "Permutación|permutables|orden canónico" "$CR"; then
  ok "permutaciones documentadas"
else
  fail "permutaciones missing"
fi

# E-006 paralelo a init-saas
if grep -qE "paralelo a init-saas|cómo resuelve E-006|init-saas" "$CR"; then
  ok "E-006 paralelo init-saas"
else
  fail "E-006 paralelo missing"
fi

# CRÍTICO: D-020 distinction section (la contribución analítica)
if grep -qE "D-020.*distinction|distinción CRÍTICA|PAUSE-interno-delegado.*PAUSE-wizard|contribución analítica" "$CR"; then
  ok "chain-rationale: D-020 distinction explained"
else
  fail "D-020 distinction missing"
fi

# Razonamiento incorrecto (force-fit) explicado
if grep -qE "force-fit incorrecto|razonamiento.*incorrecto|sería force-fit" "$CR"; then
  ok "chain-rationale: force-fit incorrecto explained"
else
  fail "force-fit incorrecto missing"
fi

# Comparación con init-saas (shape-par)
if grep -qE "init-saas|shape-par|paralelo" "$CR"; then
  ok "comparison init-saas"
else
  fail "init-saas comparison missing"
fi

# Cross-skill applicability — patrón wizard con PAUSE-aware
if grep -qE "wizard con sub-skills PAUSE-aware|patrón canónico para wizards" "$CR"; then
  ok "cross-skill applicability"
else
  fail "cross-skill applicability missing"
fi

# ── L3 — 7 escenarios canónicos S1-S7 ─────────────────────────────
echo ""
echo "L3 — 7 escenarios canónicos S1-S7"

# S1: PREFLIGHT halt sin add-login
if grep -qE "halt.*add-login|add-login.*halt" "$SKILL"; then
  ok "L3 S1: PREFLIGHT halt sin add-login"
else
  fail "L3 S1: missing"
fi

# S2: PREFLIGHT halt sin brand.json
if grep -qE "halt.*Brand DNA|halt.*brand\.json|halt.*add-ui-kit" "$SKILL"; then
  ok "L3 S2: PREFLIGHT halt sin brand.json"
else
  fail "L3 S2: missing"
fi

# S3: detect-state tabla correcta (✅/⬜)
if grep -qE "✅|⬜" "$DS" "$SKILL"; then
  ok "L3 S3: detect-state tabla checkmarks"
else
  fail "L3 S3: missing"
fi

# S4: full chain (3 pasos)
if grep -qE "0 de 3.*pendientes|3 pasos|full chain" "$SKILL" "$DS"; then
  ok "L3 S4: full chain 3 pasos"
else
  fail "L3 S4: missing"
fi

# S5: partial mode (payments-only)
if grep -qE "partial.*payments-only|solo payments|payments-only" "$SKILL" "$DS"; then
  ok "L3 S5: partial mode payments-only"
else
  fail "L3 S5: missing"
fi

# S6: PAUSE delegado documentado (NO PAUSE del wizard)
if grep -qE "PAUSE-interno-delegado.*NO PAUSE-wizard|NO escalar.*wizard|distinct from PAUSE-wizard" "$SKILL" "$RS" "$CR"; then
  ok "L3 S6: PAUSE delegado documentado (NO wizard)"
else
  fail "L3 S6: missing"
fi

# S7: handoff final correcto (add-mobile, la-forja)
if grep -qE "add-mobile" "$SKILL" && grep -qE "la-forja" "$SKILL"; then
  ok "L3 S7: handoff final menciona add-mobile + la-forja"
else
  fail "L3 S7: missing"
fi

# ── L3 — D-020 binary application + distinction ───────────────────
echo ""
echo "L3 — D-020 binary application"

if grep -qiE "binary.*confirm|confirm.*binary|BINARY confirmed" "$SKILL" "$DS"; then
  ok "L3: binary confirmed"
else
  fail "L3: binary confirmation missing"
fi

# 7 ADRs cross-cited (D-009..D-020 con D-020 nuevo)
for adr in "D-009" "D-010" "D-011" "D-014" "D-015" "D-019" "D-020"; do
  if grep -q "$adr" "$SKILL" "$CR" "$RS"; then
    ok "L3: $adr cross-cited"
  else
    fail "L3: $adr missing"
  fi
done

# CRÍTICO: distinción PAUSE-interno-delegado vs PAUSE-wizard explícita
if grep -qE "PAUSE-interno-delegado.*≠.*PAUSE-wizard|≠ PAUSE-wizard|distinct from PAUSE-wizard" "$SKILL" "$CR"; then
  ok "L3: distinción PAUSE-interno-delegado ≠ PAUSE-wizard"
else
  # alternative phrasing
  if grep -qE "NO escala.*PAUSE-wizard|sigue siendo BINARY" "$SKILL" "$CR"; then
    ok "L3: distinción PAUSE-interno-delegado vs PAUSE-wizard (alt phrasing)"
  else
    fail "L3: distinción missing"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ add-monetization dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ add-monetization dry-run: $FAIL failures"
  exit 1
fi
