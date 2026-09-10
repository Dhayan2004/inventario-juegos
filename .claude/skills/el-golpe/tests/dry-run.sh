#!/usr/bin/env bash
# el-golpe dry-run test
#
# L1 (file presence) + L2 (PREFLIGHT + brief-plan + verify) + L3 (S1-S6 escenarios).
# E-008: grep -E con | plain.
# F3-S10/S11 frictions absorbidas: -i, mode patterns relax, `--` separator.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── el-golpe dry-run ────────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

el_golpe_files=(
  "SKILL.md"
  "prompts/brief-plan.md"
  "prompts/verify.md"
  "references/examples.md"
)
for f in "${el_golpe_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "el-golpe: $f"; else fail "el-golpe missing: $f"; fi
done

if [ -d "$SKILL_DIR/templates" ]; then
  fail "el-golpe: templates/ folder existe (lightweight no debe)"
else
  ok "el-golpe: NO templates/ folder (lightweight OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: el-golpe$" "$SKILL"; then ok "SKILL.md: name field"; else fail "SKILL.md: name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "SKILL.md: $field"; else fail "SKILL.md: $field missing"; fi
done

if grep -qE "^dependencies: \[\]" "$SKILL"; then ok "SKILL.md: dependencies empty"; else fail "SKILL.md: dependencies wrong"; fi

if grep -qE "tier: core \(lightweight\)|core.*lightweight" "$SKILL"; then
  ok "SKILL.md: tier core (lightweight)"
else
  fail "SKILL.md: tier lightweight missing"
fi

# ── L2 — SKILL.md PREFLIGHT (2-4 gates) ──────────────────────────────
echo ""
echo "L2 — SKILL.md PREFLIGHT"

if grep -qE "^## PREFLIGHT" "$SKILL"; then ok "SKILL.md: PREFLIGHT section"; else fail "PREFLIGHT missing"; fi

# Gate 1: active feature R1
if grep -qE "active feature.*feature_list|R1" "$SKILL"; then
  ok "SKILL.md: gate active feature (R1)"
else
  fail "SKILL.md: gate active feature missing"
fi

# Gate 2: brand.json si UI (R10 condicional)
if grep -qE "brand\.json|R10" "$SKILL"; then
  ok "SKILL.md: gate brand.json si UI (R10)"
else
  fail "SKILL.md: gate brand.json missing"
fi

# Handoff add-ui-kit si brand.json missing + UI requerida
if grep -qE "handoff.*add-ui-kit|halt.*add-ui-kit" "$SKILL"; then
  ok "SKILL.md: handoff add-ui-kit si brand.json missing"
else
  fail "SKILL.md: handoff add-ui-kit missing"
fi

# Gate 3: tests + lint passing
if grep -qE "[Tt]ests.*lint|tests rojos" "$SKILL"; then
  ok "SKILL.md: gate tests passing"
else
  fail "SKILL.md: gate tests missing"
fi

# Loop ejecución 4 phases
for phase in "SCOPE-CHECK \+ BRIEF PLAN" "EXECUTE one-shot" "VERIFY" "COMMIT"; do
  if grep -qE "$phase" "$SKILL"; then
    ok "SKILL.md: phase '$phase'"
  else
    fail "SKILL.md: phase '$phase' missing"
  fi
done

# Brief plan visible obligatorio
if grep -qE "[Bb]rief plan visible|brief.*visible|3-5 líneas" "$SKILL"; then
  ok "SKILL.md: brief plan visible obligatorio"
else
  fail "SKILL.md: brief visible missing"
fi

# One-shot NO loop
if grep -qiE "one-shot.*NO loop|sin loop|NO sprint" "$SKILL"; then
  ok "SKILL.md: one-shot sin loop"
else
  fail "SKILL.md: one-shot missing"
fi

# Hard rules R1/R2/R10/R14 cited
for rule in "R1" "R2" "R10" "R14"; do
  if grep -q "$rule" "$SKILL"; then
    ok "SKILL.md cites $rule"
  else
    fail "SKILL.md missing $rule"
  fi
done

# Lessons L-001/L-003 cited
for lesson in "L-001" "L-003"; do
  if grep -q "$lesson" "$SKILL"; then
    ok "SKILL.md cites $lesson"
  else
    fail "SKILL.md missing $lesson"
  fi
done

# L-004 + D-017
if grep -q "L-004" "$SKILL"; then ok "SKILL.md cites L-004"; else fail "L-004 missing"; fi
if grep -q "D-017" "$SKILL"; then ok "SKILL.md cites D-017"; else fail "D-017 missing"; fi

# Escalation a /build (la-forja)
if grep -qE "escalate.*/build|escalación.*/build|escalate.*la-forja|escalate-graceful" "$SKILL"; then
  ok "SKILL.md: escalation a /build documented"
else
  fail "SKILL.md: escalation missing"
fi

# Boundaries
for skill in "el-tajo" "sprint" "la-forja" "la-herreria" "add-ui-kit" "impeccable" "el-migrador"; do
  if grep -q "$skill" "$SKILL"; then
    ok "SKILL.md: boundary '$skill'"
  else
    fail "SKILL.md: boundary '$skill' missing"
  fi
done

# Refusals
if grep -qE "^## Refusals" "$SKILL"; then ok "SKILL.md: Refusals"; else fail "Refusals missing"; fi

# Tool filter
if grep -qE "Tool filter|Read.*Edit.*Write" "$SKILL"; then ok "SKILL.md: Tool filter"; else fail "Tool filter missing"; fi

# ── L2 — brief-plan.md ──────────────────────────────────────────────
echo ""
echo "L2 — brief-plan.md"

BP="$SKILL_DIR/prompts/brief-plan.md"

# Output canónico
if grep -qE "Brief plan: |canónico" "$BP"; then ok "brief-plan: output canónico"; else fail "output missing"; fi

# Reglas del brief
for rule in "[Cc]oncisión" "[Cc]oncreción" "Approach con dep awareness|dep awareness" "Verification concreta" "Estimación honesta"; do
  pattern_clean=$(echo "$rule" | sed 's/\\|/|/g')
  if grep -qE "$pattern_clean" "$BP"; then
    ok "brief-plan: rule '$rule'"
  else
    fail "brief-plan: rule '$rule' missing"
  fi
done

# 4 archivos = límite mencionado
if grep -qE "1-3 ideal|max 5|6\+ archivos|límite" "$BP"; then
  ok "brief-plan: límite archivos mencionado"
else
  fail "brief-plan: límite missing"
fi

# L-004 + D-017 cited
for cite in "L-004" "D-017"; do
  if grep -q "$cite" "$BP"; then ok "brief-plan: $cite"; else fail "$cite missing"; fi
done

# User confirmation explicit ("go" / "ajustá" / "escalá")
for opt in "\"go\"" "ajustá" "escal"; do
  if grep -qE "$opt" "$BP"; then
    ok "brief-plan: option '$opt'"
  else
    fail "brief-plan: option '$opt' missing"
  fi
done

# Edge cases >= 4
bp_edges=$(grep -c "^### Edge" "$BP")
if [ "$bp_edges" -ge 4 ]; then ok "brief-plan: $bp_edges edge cases"; else fail "only $bp_edges edges"; fi

# ── L2 — verify.md ──────────────────────────────────────────────────
echo ""
echo "L2 — verify.md"

VR="$SKILL_DIR/prompts/verify.md"

# 5 steps protocolo
for step in "Step 1.*[Tt]ypecheck" "Step 2.*[Tt]ests" "Step 3.*[Cc]onsole errors" "Step 4.*[Bb]uild check" "Step 5.*[Cc]ommit atomic"; do
  if grep -qE "$step" "$VR"; then
    ok "verify: protocol $step"
  else
    fail "verify: $step missing"
  fi
done

# Pass criteria explícito
if grep -qiE "pass criteria|exit 0" "$VR"; then
  ok "verify: pass criteria"
else
  fail "verify: pass criteria missing"
fi

# Conventional commits R2 enforcement
if grep -qE "Conventional [Cc]ommits|conventional commits format|R2" "$VR"; then
  ok "verify: R2 conventional commits"
else
  fail "verify: R2 missing"
fi

# AP2 no-bypass
if grep -qE "AP2|--no-verify" "$VR"; then
  ok "verify: AP2 no-bypass"
else
  fail "verify: AP2 missing"
fi

# Halt logic si fail
if grep -qE "[Rr]etry/halt logic|fail.*halt|FAIL handling" "$VR"; then
  ok "verify: halt logic on fail"
else
  fail "verify: halt logic missing"
fi

# Edge cases
vr_edges=$(grep -c "^### Edge" "$VR")
if [ "$vr_edges" -ge 4 ]; then ok "verify: $vr_edges edge cases"; else fail "only $vr_edges"; fi

# ── L2 — references/examples.md ─────────────────────────────────────
echo ""
echo "L2 — references/examples.md"

EX="$SKILL_DIR/references/examples.md"

# 3 escenarios + anti-pattern
for esc in "Escenario 1" "Escenario 2" "Escenario 3"; do
  if grep -q "$esc" "$EX"; then ok "examples: $esc"; else fail "$esc missing"; fi
done

if grep -qE "[Aa]nti-pattern observable|escalado a /build" "$EX"; then
  ok "examples: anti-pattern observable"
else
  fail "anti-pattern missing"
fi

# Tabla resumen
if grep -qE "Tabla resumen|3 escenarios" "$EX"; then ok "examples: tabla resumen"; else fail "tabla missing"; fi

# Brief plan visible en cada escenario
brief_count=$(grep -c "Brief plan emitido" "$EX")
if [ "$brief_count" -ge 3 ]; then
  ok "examples: brief plan emitido en >=3 escenarios"
else
  fail "examples: only $brief_count briefs"
fi

# Commit shape conventional R2 cross-escenarios
if grep -qE "feat\(F[0-9]+-S\?\)" "$EX"; then
  ok "examples: commit shape conventional R2"
else
  fail "examples: commit shape missing"
fi

# Sub-skills mencionados (impeccable, el-migrador)
for ss in "impeccable" "el-migrador"; do
  if grep -q "$ss" "$EX"; then ok "examples: sub-skill '$ss'"; else fail "$ss missing"; fi
done

# ── L3 — 6 escenarios canónicos S1-S6 ───────────────────────────────
echo ""
echo "L3 — 6 escenarios canónicos S1-S6"

# S1: PREFLIGHT halt sin active feature
if grep -qE "halt.*active feature|requiere active feature.*halt" "$SKILL"; then
  ok "L3 S1: PREFLIGHT halt sin active feature"
else
  fail "L3 S1: missing"
fi

# S2: PREFLIGHT halt sin brand.json cuando UI
if grep -qE "halt.*brand\.json|brand\.json.*halt|halt.*add-ui-kit" "$SKILL"; then
  ok "L3 S2: PREFLIGHT halt sin brand.json + UI"
else
  fail "L3 S2: missing"
fi

# S3: brief-plan visible antes de ejecutar
if grep -qE "esperar \"go\"|user confirms|brief.*OBLIGATORIO" "$SKILL" "$BP"; then
  ok "L3 S3: brief-plan visible antes de ejecutar"
else
  fail "L3 S3: missing"
fi

# S4: ejecución one-shot sin loop
if grep -qiE "one-shot.*sin loop|NO sprint|sin loop iterativo" "$SKILL"; then
  ok "L3 S4: ejecución one-shot sin loop"
else
  fail "L3 S4: missing"
fi

# S5: escalación a /build si scope excede
if grep -qE "[Gg]olpe partial.*/build|escalation.*/build|escalado a /build" "$EX" "$SKILL"; then
  ok "L3 S5: escalación a /build documented"
else
  fail "L3 S5: missing"
fi

# S6: output 1-3 commits atómicos
if grep -qE "1-3 commits atómicos|1-3 commits|commits atómicos.*1-3" "$SKILL"; then
  ok "L3 S6: output 1-3 commits atómicos"
else
  fail "L3 S6: missing"
fi

# ── L3 — D-017 binary aplicado ───────────────────────────────────────
echo ""
echo "L3 — D-017 binary application"

if grep -qiE "binary.*shape|D-017.*binary|binary.*D-017" "$SKILL" "$BP"; then
  ok "L3: binary shape declarado"
else
  fail "L3: binary shape missing"
fi

if grep -qE "NO PAUSE|sin PAUSE" "$SKILL" "$BP"; then
  ok "L3: NO PAUSE explícito"
else
  fail "L3: NO PAUSE missing"
fi

if grep -qE "siempre disponible|escalación.*siempre|/build.*disponible" "$BP" "$SKILL"; then
  ok "L3: escalación siempre disponible"
else
  fail "L3: always-available missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ el-golpe dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ el-golpe dry-run: $FAIL failures"
  exit 1
fi
