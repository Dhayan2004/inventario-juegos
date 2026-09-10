#!/usr/bin/env bash
# migration-wizard dry-run test
#
# Pipeline shape (D-023) — NO binary mode. Boundary case análogo a D-014.
# L1 (file presence + frontmatter) + L2 (PREFLIGHT + 3-fase pipeline + Bootstrap
# Contract checks + R4/R5 enforcement) + L3 (S1-S5 escenarios canónicos).
# E-008: grep -E con | plain.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── migration-wizard dry-run ────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

mw_files=(
  "SKILL.md"
  "prompts/detect-origin.md"
  "prompts/analyze-gaps.md"
  "prompts/build-plan.md"
  "references/bootstrap-contract-checklist.md"
)
for f in "${mw_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "migration-wizard: $f"; else fail "missing: $f"; fi
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

if grep -q "^name: migration-wizard$" "$SKILL"; then ok "name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "$field"; else fail "$field missing"; fi
done

# Dependencies vacío (no depende de skills — solo lee y planifica)
if grep -qE "^dependencies: \[\]" "$SKILL"; then
  ok "dependencies: [] (no skill deps)"
else
  fail "dependencies wrong"
fi

if grep -qE "^tier: core" "$SKILL"; then ok "tier core"; else fail "tier wrong"; fi

# ── L2 — PREFLIGHT (2 gates) ──────────────────────────────────────
echo ""
echo "L2 — SKILL.md PREFLIGHT"

if grep -qE "^## PREFLIGHT" "$SKILL"; then ok "PREFLIGHT section"; else fail "PREFLIGHT missing"; fi

# Gate 1: proyecto detectable
if grep -qE "package\.json|directorio.*proyecto|detect.*proyecto" "$SKILL"; then
  ok "PREFLIGHT gate proyecto detectable"
else
  fail "gate proyecto missing"
fi

# Gate 2: NO Forja ya migrado
if grep -qE "ya migrado|AGENTS\.md|halt.*ya migrado" "$SKILL"; then
  ok "PREFLIGHT gate ya-migrado halt"
else
  fail "gate ya-migrado missing"
fi

# ── L2 — Pipeline shape (D-023, NO binary) ────────────────────────
echo ""
echo "L2 — Pipeline shape D-023"

# 3 fases del pipeline
for fase in "DETECT" "ANALYZE" "PLAN"; do
  if grep -q "$fase" "$SKILL"; then ok "Fase '$fase'"; else fail "Fase '$fase' missing"; fi
done

# D-023 cited
if grep -q "D-023" "$SKILL"; then ok "cita D-023"; else fail "D-023 missing"; fi

# D-014 informativo (boundary case análogo)
if grep -q "D-014" "$SKILL"; then ok "cita D-014 (boundary case análogo)"; else fail "D-014 missing"; fi

# Pipeline shape declarado explícitamente
if grep -qE "pipeline shape|NO selector|Shape.*pipeline|sin selector" "$SKILL"; then
  ok "pipeline shape sin selector documented"
else
  fail "pipeline shape missing"
fi

# L-004 NO aplica directo (boundary case)
if grep -qE "L-004 NO aplica|boundary case" "$SKILL"; then
  ok "L-004 NO aplica directo (boundary case)"
else
  fail "boundary case clarification missing"
fi

# Hard rules R4/R5/R11
for rule in "R4" "R5" "R11"; do
  if grep -q "$rule" "$SKILL"; then ok "cites $rule"; else fail "$rule missing"; fi
done

# 5 tipos de origen documentados
for tipo in "Tipo A" "Tipo B" "Tipo C" "Tipo D" "Tipo E"; do
  if grep -q "$tipo" "$SKILL"; then ok "origen '$tipo'"; else fail "origen '$tipo' missing"; fi
done

# NO ejecuta declaración explícita
if grep -qE "NO ejecuta|solo planif|NO escribe código" "$SKILL"; then
  ok "NO ejecuta migración explícito"
else
  fail "NO ejecuta declaration missing"
fi

# Boundaries
for skill in "el-crisol" "init-saas" "add-monetization" "enterprise-stack" "el-evaluador" "la-forja"; do
  if grep -q "$skill" "$SKILL"; then ok "boundary '$skill'"; else fail "boundary '$skill' missing"; fi
done

if grep -qE "^## Refusals" "$SKILL"; then ok "Refusals"; else fail "Refusals missing"; fi

if grep -qE "Tool filter|NO Edit|NO invocar skills" "$SKILL"; then ok "Tool filter"; else fail "Tool filter missing"; fi

# ── L2 — detect-origin.md ────────────────────────────────────────
echo ""
echo "L2 — detect-origin.md"

DO="$SKILL_DIR/prompts/detect-origin.md"

# 5 tipos clasificados
if grep -q "origin_type" "$DO"; then ok "detect: origin_type"; else fail "origin_type missing"; fi
for tipo in "= A" "= B" "= C" "= D" "= E"; do
  if grep -q "origin_type $tipo" "$DO"; then ok "detect: origin_type $tipo"; else fail "origin_type $tipo missing"; fi
done

# Markers Forge V2/V3
if grep -qE "forge_v2_markers|Forge V2" "$DO"; then ok "Forge V2 markers"; else fail "Forge V2 missing"; fi
if grep -qE "forge_v3_markers|Forge V3" "$DO"; then ok "Forge V3 markers"; else fail "Forge V3 missing"; fi

# PREFLIGHT halt para ya-migrado
if grep -qE "ya migrado|AGENTS|has_forja_AGENTS" "$DO"; then
  ok "ya migrado halt detected"
else
  fail "ya migrado halt missing"
fi

# Edge cases
do_edges=$(grep -c "^### Edge" "$DO")
if [ "$do_edges" -ge 4 ]; then ok "$do_edges edges"; else fail "only $do_edges"; fi

# ── L2 — analyze-gaps.md ────────────────────────────────────────
echo ""
echo "L2 — analyze-gaps.md"

AG="$SKILL_DIR/prompts/analyze-gaps.md"

# R11 gates analizados (5 gates)
for gate in "R11_1" "R11_2" "R11_3" "R11_4" "R11_5"; do
  if grep -q "$gate" "$AG"; then ok "gate $gate"; else fail "$gate missing"; fi
done

# Forja Enterprise extras
if grep -qE "AGENTS_md|forja_enterprise_extras" "$AG"; then
  ok "Forja Enterprise extras analizados"
else
  fail "extras missing"
fi

# RLS L-001
if grep -qE "rls_user_id_tables|L-001" "$AG"; then
  ok "RLS L-001 check"
else
  fail "RLS check missing"
fi

# R14 destructive tools
if grep -qE "r14_destructive_tools|R14" "$AG"; then
  ok "R14 destructive tools check"
else
  fail "R14 check missing"
fi

# Reusable detection
if grep -qE "reusable|skills_existentes|blueprint_or_planning" "$AG"; then
  ok "reusable detection"
else
  fail "reusable missing"
fi

# Estimación tipo-aware
if grep -qE "Tipo A|Tipo B|Tipo C|Tipo D|Tipo E" "$AG"; then
  ok "tipo-aware estimation"
else
  fail "tipo estimation missing"
fi

# Edge cases
ag_edges=$(grep -c "^### Edge" "$AG")
if [ "$ag_edges" -ge 4 ]; then ok "$ag_edges edges"; else fail "only $ag_edges"; fi

# ── L2 — build-plan.md ────────────────────────────────────────
echo ""
echo "L2 — build-plan.md"

BP="$SKILL_DIR/prompts/build-plan.md"

# Plan tiene secciones canónicas
for sec in "Estado Actual" "Gaps Críticos" "Reutilizable" "Pasos de Migración" "Estimación Total" "Primer Comando"; do
  if grep -q "$sec" "$BP"; then ok "section '$sec'"; else fail "'$sec' missing"; fi
done

# Pasos numerados
for paso in "Paso 1" "Paso 2" "Paso 3" "Paso 4" "Paso 5"; do
  if grep -q "$paso" "$BP"; then ok "$paso"; else fail "$paso missing"; fi
done

# NO ejecuta — solo Write del plan
if grep -qE "NO ejecuta|Write file|MIGRATION-PLAN" "$BP"; then
  ok "NO ejecuta — solo escribe plan"
else
  fail "NO ejecuta declaration missing"
fi

# Comandos copy-paste-ready
if grep -qE "\`\`\`bash|\`/init-saas\`|\`/add-ui-kit\`" "$BP"; then
  ok "comandos copy-paste-ready"
else
  fail "comandos missing"
fi

# Edge cases
bp_edges=$(grep -c "^### Edge" "$BP")
if [ "$bp_edges" -ge 3 ]; then ok "$bp_edges edges"; else fail "only $bp_edges"; fi

# ── L2 — bootstrap-contract-checklist.md ─────────────────────
echo ""
echo "L2 — bootstrap-contract-checklist.md"

CC="$SKILL_DIR/references/bootstrap-contract-checklist.md"

# 5 R11 gates documentados
for gate in "R11-1" "R11-2" "R11-3" "R11-4" "R11-5"; do
  if grep -q "$gate" "$CC"; then ok "checklist $gate"; else fail "$gate missing"; fi
done

# 8 extras documentados
extras_count=$(grep -c "^### Extra " "$CC")
if [ "$extras_count" -ge 8 ]; then ok "$extras_count Forja Enterprise extras"; else fail "only $extras_count extras"; fi

# Tabla resumen 13 checks
if grep -qE "13 checks|R11-1.*R11-5.*Extra" "$CC"; then
  ok "tabla resumen 13 checks"
else
  fail "tabla 13 missing"
fi

# ── L3 — escenarios canónicos S1-S5 ───────────────────────────
echo ""
echo "L3 — escenarios canónicos"

# S1: PREFLIGHT halt sin proyecto
if grep -qE "halt.*proyecto|No se detecta proyecto" "$SKILL"; then
  ok "L3 S1: PREFLIGHT halt sin proyecto"
else
  fail "L3 S1: missing"
fi

# S2: PREFLIGHT halt ya-migrado
if grep -qE "ya migrado|halt.*Forja Enterprise" "$SKILL"; then
  ok "L3 S2: PREFLIGHT halt ya-migrado"
else
  fail "L3 S2: missing"
fi

# S3: Pipeline DETECT → ANALYZE → PLAN
if grep -qE "DETECT.*ANALYZE.*PLAN|3 fases" "$SKILL" "$DO" "$AG" "$BP"; then
  ok "L3 S3: pipeline 3 fases"
else
  fail "L3 S3: missing"
fi

# S4: Plan auto-contenido
if grep -qE "auto-contenido|MIGRATION-PLAN.*md" "$SKILL" "$BP"; then
  ok "L3 S4: plan auto-contenido"
else
  fail "L3 S4: missing"
fi

# S5: handoff sugiere primer comando
if grep -qE "Primer Comando|primer comando" "$SKILL" "$BP"; then
  ok "L3 S5: handoff con primer comando"
else
  fail "L3 S5: missing"
fi

# ── L3 — D-023 pipeline shape application ─────────────────────────
echo ""
echo "L3 — D-023 pipeline shape application"

if grep -qiE "pipeline shape|D-023.*pipeline|pipeline.*sin selector" "$SKILL"; then
  ok "pipeline shape declared"
else
  fail "pipeline shape missing"
fi

# Análogo a D-014
if grep -qE "D-014|análogo|boundary case" "$SKILL"; then
  ok "D-014 boundary case análogo"
else
  fail "D-014 análogo missing"
fi

# NO ejecuta — solo planifica
if grep -qE "NO ejecuta|solo planif|produce.*PLAN" "$SKILL"; then
  ok "NO ejecuta — solo planifica"
else
  fail "NO ejecuta missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ migration-wizard dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ migration-wizard dry-run: $FAIL failures"
  exit 1
fi
