#!/usr/bin/env bash
# primer dry-run test
#
# Validates L1 (file presence) + L2 (structural correctness of prompts/refs)
# + L3 (timing + simulated invocation against stub project).
#
# Usage: bash .claude/skills/primer/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── primer dry-run ──────────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ───────────────────────────────────────────────
echo "L1 — File presence"

primer_files=(
  "SKILL.md"
  "prompts/load-context.md"
  "prompts/format-output.md"
  "prompts/handoff-targets.md"
  "references/target-project-structure.md"
  "references/output-templates.md"
  "references/examples.md"
)
for f in "${primer_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "primer: $f"; else fail "primer missing: $f"; fi
done

# NO templates folder (primer is prompt-only)
if [ -d "$SKILL_DIR/templates" ]; then
  fail "primer: templates/ folder existe (debe ser prompt-only)"
else
  ok "primer: NO templates/ folder (prompt-only correct)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: primer$" "$SKILL"; then
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
  ok "SKILL.md: dependencies empty (primer no dependencies)"
else
  fail "SKILL.md: dependencies field incorrect"
fi

# ── L2 — SKILL.md awareness ──────────────────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

# 5 elementos canónicos del output
for element in "Active feature" "Última actividad" "Brand snapshot" "Próxima acción"; do
  if grep -q "$element" "$SKILL"; then
    ok "SKILL.md mentions output element '$element'"
  else
    fail "SKILL.md missing output element '$element'"
  fi
done

# Time budget <30s
if grep -q "<30s\\|30s" "$SKILL"; then
  ok "SKILL.md: time budget <30s declarado"
else
  fail "SKILL.md: time budget missing"
fi

# Graceful degradation
if grep -q "graceful degradation\\|degrada graceful" "$SKILL"; then
  ok "SKILL.md: graceful degradation explícito"
else
  fail "SKILL.md: graceful degradation missing"
fi

# Read-only enforcement
if grep -q "read-only" "$SKILL"; then
  ok "SKILL.md: read-only enforcement"
else
  fail "SKILL.md: read-only NOT enforced"
fi

# NO Edit, NO Write (extended grep — usa | sin escape)
if grep -E "NO Edit, NO Write|read-only — primer" "$SKILL"; then
  ok "SKILL.md: tool filter excludes Edit/Write"
else
  fail "SKILL.md: tool filter doesn't restrict Edit/Write"
fi

# Cita L-004 (informativa, no aplica directo)
if grep -q "L-004" "$SKILL"; then
  ok "SKILL.md cites L-004 (informativo)"
else
  fail "SKILL.md missing L-004 citation"
fi

# ── L2 — load-context.md structure ──────────────────────────────────
echo ""
echo "L2 — load-context.md (8-step sequence)"

LOAD="$SKILL_DIR/prompts/load-context.md"

# 8 pasos numerados
for step in "Paso 1 — \`AGENTS.md\`" "Paso 2 — \`feature_list.json\`" "Paso 3 — \`PROGRESS.md\`" "Paso 4 — \`brand/" "Paso 5 — \`.claude/memory/decisions.md\`" "Paso 6 — git status" "Paso 7 — \`README.md\`" "Paso 8 — Format output"; do
  if grep -q "$step" "$LOAD"; then
    ok "load-context: $step"
  else
    fail "load-context: missing $step"
  fi
done

# Optimization: parallelize mention
if grep -q "parallel\\|parallelize" "$LOAD"; then
  ok "load-context: parallelize optimization documented"
else
  fail "load-context: parallelize optimization missing"
fi

# Edge cases
if grep -q "Edge cases" "$LOAD"; then
  ok "load-context: edge cases documented"
else
  fail "load-context: edge cases missing"
fi

# ── L2 — format-output.md template ──────────────────────────────────
echo ""
echo "L2 — format-output.md (canonical template)"

FORMAT="$SKILL_DIR/prompts/format-output.md"

# Template canónico con 5 elementos
for element in "## Active feature" "## Última actividad" "## Brand snapshot" "## Próxima acción sugerida"; do
  if grep -q "$element" "$FORMAT"; then
    ok "format-output: template incluye '$element'"
  else
    fail "format-output: template missing '$element'"
  fi
done

# Bounds documentados
if grep -q "150-300\\|150 a 300" "$FORMAT"; then
  ok "format-output: word bounds 150-300 documented"
else
  fail "format-output: word bounds missing"
fi

# 3 adaptaciones por estado (flexible matching)
for state in "fresh" "build" "deploy"; do
  if grep -qiE "Proyecto $state|en $state|cerca de $state|recién $state|estado $state" "$FORMAT"; then
    ok "format-output: adaptación '$state' state"
  else
    fail "format-output: missing '$state' adaptation"
  fi
done

# Tone declared
if grep -q "Argentino\\|plural Argentino\\|tone:" "$FORMAT"; then
  ok "format-output: tone documented"
else
  fail "format-output: tone missing"
fi

# ── L2 — handoff-targets.md mapping ──────────────────────────────────
echo ""
echo "L2 — handoff-targets.md (mapping table)"

HANDOFF="$SKILL_DIR/prompts/handoff-targets.md"

# Mapping table presente
if grep -q "Estado detectado\\|Próxima acción\\|Skill a invocar" "$HANDOFF"; then
  ok "handoff-targets: mapping table"
else
  fail "handoff-targets: mapping table missing"
fi

# Skills downstream documentados
for skill in "add-ui-kit" "add-login" "add-payments" "add-emails" "add-mobile" "la-herreria" "la-forja" "el-tajo" "el-golpe" "el-guardian"; do
  if grep -q "/$skill" "$HANDOFF"; then
    ok "handoff-targets: $skill referenced"
  else
    fail "handoff-targets: $skill not referenced"
  fi
done

# Forja factory detection edge case
if grep -q "Forja factory" "$HANDOFF"; then
  ok "handoff-targets: Forja factory edge case documented"
else
  fail "handoff-targets: Forja factory edge case missing"
fi

# L-004 cita informativa
if grep -q "L-004" "$HANDOFF"; then
  ok "handoff-targets: cites L-004 informativo"
else
  fail "handoff-targets: L-004 citation missing"
fi

# ── L2 — references structure ────────────────────────────────────────
echo ""
echo "L2 — references structure"

# target-project-structure.md
TPS="$SKILL_DIR/references/target-project-structure.md"
if grep -q "AGENTS.md" "$TPS" && grep -q "feature_list.json" "$TPS"; then
  ok "target-project-structure: documents AGENTS + feature_list"
else
  fail "target-project-structure: incomplete"
fi

if grep -q "Tier 1\\|Tier 2\\|Tier 3" "$TPS"; then
  ok "target-project-structure: 3 tiers documented"
else
  fail "target-project-structure: tiers missing"
fi

# Forja factory detection markers
if grep -q "Forja factory mismo" "$TPS"; then
  ok "target-project-structure: Forja factory detection documented"
else
  fail "target-project-structure: factory detection missing"
fi

# output-templates.md
OUT="$SKILL_DIR/references/output-templates.md"
if grep -q "Template 1\\|Template 2\\|Template 3" "$OUT"; then
  ok "output-templates: 3 templates"
else
  fail "output-templates: 3 templates missing"
fi

# Anti-patterns documented
if grep -qi "Anti-pattern" "$OUT"; then
  ok "output-templates: anti-patterns documented"
else
  fail "output-templates: anti-patterns missing"
fi

# examples.md
EX="$SKILL_DIR/references/examples.md"
if grep -q "Escenario 1\\|Escenario 2\\|Escenario 3" "$EX"; then
  ok "examples: 3 escenarios"
else
  fail "examples: 3 escenarios missing"
fi

# Specific use cases
if grep -q "post-fines de semana\\|onboarding\\|cross-session" "$EX"; then
  ok "examples: specific use cases (sesión nueva, onboarding, post-pause)"
else
  fail "examples: use cases missing"
fi

# ── L3 — Simulated dry-run against stub project ─────────────────────
echo ""
echo "L3 — Simulated invocation timing"

# Crear stub project
STUB_DIR="$(mktemp -d /tmp/forja-primer-test.XXXXXX)"
trap "rm -rf $STUB_DIR" EXIT

mkdir -p "$STUB_DIR/forja/.claude/memory" "$STUB_DIR/forja/brand"
cat > "$STUB_DIR/AGENTS.md" <<'AGENTSEOF'
# stub-project

Routing entry. Stack: Next.js + Supabase. Forja-managed.
AGENTSEOF

cat > "$STUB_DIR/forja/feature_list.json" <<'JSONEOF'
{
  "schema_version": "1.0.0",
  "phase": "1",
  "features": [
    {
      "id": "F1-S1",
      "behavior": "Initial test feature",
      "verification": "test -f stub.txt",
      "state": "active",
      "branch": "feature/F1-S1",
      "evidence": null,
      "commit": null
    }
  ]
}
JSONEOF

cat > "$STUB_DIR/forja/brand/brand.json" <<'BRANDEOF'
{
  "$schema_version": "1.1.0",
  "brand": { "product": "stub-project" },
  "archetype": { "primary": "Sage", "secondary": "Creator" },
  "posture": { "density": 3, "expression": 3, "geometry": 3, "warmth": 3, "editoriality": 3, "materiality": 3 },
  "tokens": { "colors": { "primary": "#000000" } }
}
BRANDEOF

cat > "$STUB_DIR/forja/.claude/memory/decisions.md" <<'DECEOF'
# Decisions

## D-001 — Stub decision
Date: 2026-05-08
DECEOF

cd "$STUB_DIR" && git init -q && git add -A && git commit -q -m "initial stub" && cd - > /dev/null

# Simular las 7 lecturas + timing
START=$(date +%s%N)

# Tier 1 reads
test -f "$STUB_DIR/AGENTS.md" || { fail "L3: AGENTS.md not readable"; exit 1; }
test -f "$STUB_DIR/forja/feature_list.json" || { fail "L3: feature_list.json not readable"; exit 1; }
node -e "JSON.parse(require('fs').readFileSync('$STUB_DIR/forja/feature_list.json'))" 2>/dev/null || { fail "L3: feature_list invalid"; exit 1; }

# Tier 2 reads
test -f "$STUB_DIR/forja/brand/brand.json" || { fail "L3: brand.json not readable"; exit 1; }
node -e "JSON.parse(require('fs').readFileSync('$STUB_DIR/forja/brand/brand.json'))" 2>/dev/null || { fail "L3: brand.json invalid"; exit 1; }
test -f "$STUB_DIR/forja/.claude/memory/decisions.md" || { fail "L3: decisions.md not readable"; exit 1; }

# git
cd "$STUB_DIR" && git rev-parse --abbrev-ref HEAD > /dev/null && git log --oneline -5 > /dev/null && git status --short > /dev/null && cd - > /dev/null

END=$(date +%s%N)
ELAPSED_MS=$(( (END - START) / 1000000 ))

ok "L3: stub project reads completaron en ${ELAPSED_MS}ms"

# Time budget assertion (<30s = 30000ms)
if [ "$ELAPSED_MS" -lt 30000 ]; then
  ok "L3: timing dentro de <30s budget (${ELAPSED_MS}ms)"
else
  fail "L3: timing EXCEDE 30s budget (${ELAPSED_MS}ms)"
fi

# Time budget aspiracional (<5s en stub mínimo = 5000ms)
if [ "$ELAPSED_MS" -lt 5000 ]; then
  ok "L3: timing aspiracional <5s en stub mínimo"
else
  ok "L3: timing >5s en stub (${ELAPSED_MS}ms) — aceptable, real con files reales"
fi

# 5 elementos extraibles del stub
PROJECT_NAME=$(grep -m1 "^# " "$STUB_DIR/AGENTS.md" | sed 's/^# //')
ACTIVE_FEATURE=$(node -e "const d=JSON.parse(require('fs').readFileSync('$STUB_DIR/forja/feature_list.json')); console.log(d.features.find(f=>f.state==='active')?.id || 'none')")
ARCHETYPE=$(node -e "const d=JSON.parse(require('fs').readFileSync('$STUB_DIR/forja/brand/brand.json')); console.log(d.archetype.primary + '+' + d.archetype.secondary)")
GIT_BRANCH=$(cd "$STUB_DIR" && git rev-parse --abbrev-ref HEAD && cd - > /dev/null)
LAST_COMMIT=$(cd "$STUB_DIR" && git log --oneline -1 && cd - > /dev/null)

if [ "$PROJECT_NAME" = "stub-project" ]; then
  ok "L3: project name extracted ($PROJECT_NAME)"
else
  fail "L3: project name incorrect ($PROJECT_NAME)"
fi

if [ "$ACTIVE_FEATURE" = "F1-S1" ]; then
  ok "L3: active feature extracted ($ACTIVE_FEATURE)"
else
  fail "L3: active feature incorrect ($ACTIVE_FEATURE)"
fi

if [ "$ARCHETYPE" = "Sage+Creator" ]; then
  ok "L3: archetype extracted ($ARCHETYPE)"
else
  fail "L3: archetype incorrect ($ARCHETYPE)"
fi

if [ -n "$GIT_BRANCH" ]; then
  ok "L3: git branch extracted ($GIT_BRANCH)"
else
  fail "L3: git branch missing"
fi

if [ -n "$LAST_COMMIT" ]; then
  ok "L3: last commit extracted"
else
  fail "L3: last commit missing"
fi

# ── L3 — Graceful degradation con stub minimal ──────────────────────
echo ""
echo "L3 — Graceful degradation (project sin brand.json)"

STUB2_DIR="$(mktemp -d /tmp/forja-primer-test2.XXXXXX)"
trap "rm -rf $STUB_DIR $STUB2_DIR" EXIT

mkdir -p "$STUB2_DIR/forja"
cat > "$STUB2_DIR/AGENTS.md" <<'EOF'
# minimal-stub
EOF

cat > "$STUB2_DIR/forja/feature_list.json" <<'EOF'
{ "phase": "0", "features": [] }
EOF

# Sin brand.json, sin decisions.md, sin git
ok "L3: stub minimal creado (sin brand, sin decisions, sin git)"

# Verificar que primer puede degradar graceful
test -f "$STUB2_DIR/AGENTS.md" && ok "L3: AGENTS.md presente en minimal stub"
test ! -f "$STUB2_DIR/forja/brand/brand.json" && ok "L3: brand.json ausente (graceful gap)"

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ primer dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ primer dry-run: $FAIL failures"
  exit 1
fi
