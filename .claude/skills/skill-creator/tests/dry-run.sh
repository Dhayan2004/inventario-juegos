#!/usr/bin/env bash
# skill-creator dry-run test
#
# L1 (file presence) + L2 (PREFLIGHT + binary mode + interview + scaffold)
# + L3 (5 escenarios canónicos S1-S5).
#
# E-008: grep -E con | plain (NUNCA \| ni \\|).
# F3-S10/S11 frictions absorbidas: -i flag, mode patterns relax, `--` separator.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── skill-creator dry-run ───────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

skill_creator_files=(
  "SKILL.md"
  "prompts/interview.md"
  "prompts/scaffold.md"
  "references/skill-template.md"
  "references/dry-run-template.md"
)
for f in "${skill_creator_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "skill-creator: $f"; else fail "skill-creator missing: $f"; fi
done

# Meta shape: NO templates folder
if [ -d "$SKILL_DIR/templates" ]; then
  fail "skill-creator: templates/ folder existe (meta shape no debe)"
else
  ok "skill-creator: NO templates/ folder (meta shape OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: skill-creator$" "$SKILL"; then ok "SKILL.md: name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "SKILL.md: $field"; else fail "$field missing"; fi
done

if grep -qE "^dependencies: \[\]" "$SKILL"; then ok "SKILL.md: dependencies empty"; else fail "dependencies wrong"; fi

# tier: core (meta)
if grep -qE "tier: core \(meta\)|core.*meta" "$SKILL"; then
  ok "SKILL.md: tier core (meta)"
else
  fail "SKILL.md: tier meta missing"
fi

# ── L2 — SKILL.md PREFLIGHT (suave, 3 gates) ────────────────────────
echo ""
echo "L2 — SKILL.md PREFLIGHT"

if grep -qE "^## PREFLIGHT" "$SKILL"; then ok "PREFLIGHT section"; else fail "PREFLIGHT missing"; fi

# Gate 1: .claude/skills/ existe
if grep -qE "\.claude/skills/|estructura forja" "$SKILL"; then
  ok "PREFLIGHT gate  structure"
else
  fail "PREFLIGHT gate  missing"
fi

# Gate 2: nombre no colisiona
if grep -qE "ya existe|colision|nombre.*colision" "$SKILL"; then
  ok "PREFLIGHT gate nombre no-colisión"
else
  fail "PREFLIGHT nombre missing"
fi

# Halt-blocked en blockers reales
if grep -qE "halt.*estructura|halt.*colision|halt.*ya existe" "$SKILL"; then
  ok "PREFLIGHT halt-blocked en blockers reales"
else
  fail "halt missing"
fi

# Mode selector binary D-018
if grep -qE "guided.*default|default.*guided" "$SKILL"; then
  ok "SKILL.md: mode guided default"
else
  fail "SKILL.md: mode guided missing"
fi

if grep -qE "template-only.*override|override.*template-only" "$SKILL"; then
  ok "SKILL.md: mode template-only override"
else
  fail "SKILL.md: mode template-only missing"
fi

# 4 artifacts del scaffold
for artifact in "SKILL\.md" "prompts/" "references/" "tests/dry-run\.sh"; do
  if grep -qE "$artifact" "$SKILL"; then
    ok "SKILL.md mentions artifact '$artifact'"
  else
    fail "artifact '$artifact' missing"
  fi
done

# Hard rules R5
if grep -q "R5" "$SKILL"; then ok "SKILL.md cites R5"; else fail "R5 missing"; fi

# L-004 + D-018 + D-014 + D-015
for cite in "L-004" "D-018" "D-014" "D-015"; do
  if grep -q "$cite" "$SKILL"; then ok "SKILL.md cites $cite"; else fail "$cite missing"; fi
done

# E-008 awareness
if grep -qE "E-008|E-008 awareness from birth|E-008 enforced" "$SKILL"; then
  ok "SKILL.md cites E-008 awareness"
else
  fail "E-008 missing"
fi

# Boundaries
for skill_name in "el-evaluador" "find-docs" "la-herreria" "la-forja" "primer" "sprint"; do
  if grep -q "$skill_name" "$SKILL"; then
    ok "SKILL.md boundary '$skill_name'"
  else
    fail "boundary '$skill_name' missing"
  fi
done

# Refusals
if grep -qE "^## Refusals" "$SKILL"; then ok "Refusals section"; else fail "Refusals missing"; fi

# NO templates folder rule
if grep -qE "NO templates folder|sin templates folder" "$SKILL"; then
  ok "SKILL.md: NO templates folder rule"
else
  fail "templates folder rule missing"
fi

# NO genera skill terminado (solo scaffold)
if grep -qE "scaffold, NO skill terminado|NO genera el skill terminado|solo el scaffold" "$SKILL"; then
  ok "SKILL.md: scaffold NOT skill terminado"
else
  fail "scaffold rule missing"
fi

# ── L2 — interview.md (5 preguntas guiadas) ─────────────────────────
echo ""
echo "L2 — interview.md (5 preguntas)"

INT="$SKILL_DIR/prompts/interview.md"

# Las 5 preguntas Q1-Q5
for q in "Q1" "Q2" "Q3" "Q4" "Q5"; do
  if grep -qE "^## $q|^### $q" "$INT"; then
    ok "interview: question '$q'"
  else
    fail "interview: '$q' missing"
  fi
done

# Q5 selector presence (CLAVE)
if grep -qE "selector presence|tiene un selector|presencia.*selector" "$INT"; then
  ok "interview: Q5 selector presence (CLAVE)"
else
  fail "interview: Q5 selector missing"
fi

# Q5a binary vs trinary test
if grep -qE "L-004 test|binary.*trinary|trinario.*PAUSE" "$INT"; then
  ok "interview: Q5a L-004 test"
else
  fail "interview: Q5a missing"
fi

# Q5b boundary case
if grep -qE "boundary case|D-014|sin selector" "$INT"; then
  ok "interview: Q5b boundary case"
else
  fail "interview: Q5b missing"
fi

# Cross-skill scoreboard (D-009..D-018)
for adr in "D-009" "D-010" "D-011" "D-012" "D-013" "D-014" "D-015" "D-016" "D-017" "D-018"; do
  if grep -q "$adr" "$INT"; then
    ok "interview: $adr cross-cited"
  else
    fail "interview: $adr missing"
  fi
done

# Doctrine post-D-015 referenced
if grep -qE "[Dd]octrine post-D-015|presencia del selector.*determina|REGLA OPERACIONAL" "$INT"; then
  ok "interview: doctrine post-D-015 referenced"
else
  fail "interview: doctrine missing"
fi

# CONFIRM block
if grep -qE "CONFIRM block|Confirmación de inputs" "$INT"; then
  ok "interview: CONFIRM block"
else
  fail "interview: CONFIRM missing"
fi

# Edge cases >= 4
int_edges=$(grep -c "^### Edge" "$INT")
if [ "$int_edges" -ge 4 ]; then ok "interview: $int_edges edges"; else fail "only $int_edges edges"; fi

# ── L2 — scaffold.md ────────────────────────────────────────────────
echo ""
echo "L2 — scaffold.md"

SC="$SKILL_DIR/prompts/scaffold.md"

# Output: 4 artifacts
for art in "SKILL\.md" "prompts/" "references/" "tests/dry-run\.sh"; do
  if grep -qE "$art" "$SC"; then
    ok "scaffold: artifact '$art'"
  else
    fail "scaffold: artifact '$art' missing"
  fi
done

# 7 steps documented
for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5" "Step 6" "Step 7"; do
  if grep -q "$step" "$SC"; then ok "scaffold: $step"; else fail "$step missing"; fi
done

# mkdir -p commands
if grep -qE "mkdir -p" "$SC"; then ok "scaffold: mkdir -p commands"; else fail "mkdir missing"; fi

# Validación post-scaffold (bash -n)
if grep -qE "bash -n|parsing.*válido" "$SC"; then
  ok "scaffold: bash -n validation"
else
  fail "scaffold: validation missing"
fi

# Modo template-only documented
if grep -qE "template-only|YAML structured input" "$SC"; then
  ok "scaffold: template-only mode"
else
  fail "scaffold: template-only missing"
fi

# Mensaje final con próximo paso
if grep -qE "Skill scaffolded|Próximo paso|empezá a authorizar" "$SC"; then
  ok "scaffold: mensaje final con próximo paso"
else
  fail "scaffold: mensaje final missing"
fi

# Edge cases
sc_edges=$(grep -c "^### Edge" "$SC")
if [ "$sc_edges" -ge 4 ]; then ok "scaffold: $sc_edges edges"; else fail "only $sc_edges edges"; fi

# ── L2 — references/skill-template.md ────────────────────────────────
echo ""
echo "L2 — references/skill-template.md"

ST="$SKILL_DIR/references/skill-template.md"

# Frontmatter completo documentado
if grep -qE "Frontmatter YAML completo|frontmatter.*completo" "$ST"; then
  ok "skill-template: Frontmatter section"
else
  fail "Frontmatter section missing"
fi

# 14 secciones documentadas
for section in "PREFLIGHT" "Activación" "Mode selector" "Reglas operativas" "Refusals" "Tool filter" "Citation grammar" "Output handoff"; do
  if grep -q "$section" "$ST"; then
    ok "skill-template: section '$section'"
  else
    fail "section '$section' missing"
  fi
done

# Variantes por shape (5 shapes)
for shape in "lightweight" "orchestrator" "pipeline" "validator" "meta"; do
  if grep -q "$shape" "$ST"; then
    ok "skill-template: shape variant '$shape'"
  else
    fail "shape '$shape' missing"
  fi
done

# Comentario TODO post-authoring
if grep -qE "TODO post-authoring|post-authoring" "$ST"; then
  ok "skill-template: TODO post-authoring"
else
  fail "TODO missing"
fi

# ── L2 — references/dry-run-template.md (E-008 from birth) ───────────
echo ""
echo "L2 — references/dry-run-template.md"

DT="$SKILL_DIR/references/dry-run-template.md"

# E-008 awareness header explicit
if grep -qE "E-008 awareness|grep -E con .* plain|NUNCA.*\\\\\\|" "$DT"; then
  ok "dry-run-template: E-008 awareness from birth"
else
  fail "E-008 awareness missing"
fi

# F3-S10/S11 frictions awareness
if grep -qE "F3-S10/S11 frictions|F3-S10|F3-S11" "$DT"; then
  ok "dry-run-template: F3-S10/S11 frictions"
else
  fail "frictions missing"
fi

# 4 frictions documented (mode patterns + case + -- + ventanas)
for friction in "Mode patterns" "[Cc]ase-sensitivity" "getopts ambiguity|grep -qE -- " "ventanas -A flexibles|-A flexibles"; do
  pattern_clean=$(echo "$friction" | sed 's/\\|/|/g')
  if grep -qE "$pattern_clean" "$DT"; then
    ok "dry-run-template: friction '$friction'"
  else
    fail "friction '$friction' missing"
  fi
done

# Standard helpers (ok/fail)
if grep -qE "ok\(\)|fail\(\)|PASS=0|FAIL=0" "$DT"; then
  ok "dry-run-template: standard helpers"
else
  fail "helpers missing"
fi

# Summary block estándar
if grep -qE "Summary block|Summary block estándar" "$DT"; then
  ok "dry-run-template: Summary block"
else
  fail "Summary block missing"
fi

# Skills de referencia (ejemplos por shape)
if grep -qE "Skills de referencia|Por shape:|inspirarse" "$DT"; then
  ok "dry-run-template: skills de referencia por shape"
else
  fail "skills de referencia missing"
fi

# ── L3 — 5 escenarios canónicos S1-S5 ────────────────────────────────
echo ""
echo "L3 — 5 escenarios canónicos S1-S5"

# S1: PREFLIGHT detecta .claude/skills/
if grep -qE "\.claude/skills/|estructura forja" "$SKILL"; then
  ok "L3 S1: PREFLIGHT detecta  structure"
else
  fail "L3 S1: missing"
fi

# S2: entrevista 5 preguntas
q_count=0
for q in "Q1" "Q2" "Q3" "Q4" "Q5"; do
  if grep -qE "^## $q|^### $q" "$INT"; then
    q_count=$((q_count + 1))
  fi
done
if [ "$q_count" -ge 5 ]; then
  ok "L3 S2: entrevista 5 preguntas presentes ($q_count/5)"
else
  fail "L3 S2: only $q_count/5"
fi

# S3: scaffold genera 4 artifacts
if grep -qE "4 artifacts" "$SC"; then
  ok "L3 S3: scaffold 4 artifacts"
else
  # alternative check
  artifact_count=0
  for art in "SKILL\.md" "prompts/" "references/" "tests/"; do
    if grep -qE "$art" "$SC"; then
      artifact_count=$((artifact_count + 1))
    fi
  done
  if [ "$artifact_count" -ge 4 ]; then
    ok "L3 S3: scaffold 4 artifacts ($artifact_count detected)"
  else
    fail "L3 S3: only $artifact_count artifacts"
  fi
fi

# S4: L-004 question presente en entrevista (Q5)
if grep -qE "L-004|selector presence|tiene un selector" "$INT"; then
  ok "L3 S4: L-004 question presente en interview (Q5)"
else
  fail "L3 S4: missing"
fi

# S5: dry-run boilerplate usa grep -E | plain (E-008 from birth)
if grep -qE "grep -E con .* plain|E-008|NUNCA.*\\\\\\|" "$DT"; then
  ok "L3 S5: boilerplate uses grep -E | plain (E-008 from birth)"
else
  fail "L3 S5: missing"
fi

# ── L3 — D-018 binary application ────────────────────────────────────
echo ""
echo "L3 — D-018 binary application"

if grep -qiE "binary.*shape|D-018.*binary|binary.*D-018" "$SKILL"; then
  ok "L3: binary shape declarado"
else
  fail "L3: binary shape missing"
fi

if grep -qE "NO PAUSE|sin PAUSE" "$SKILL"; then
  ok "L3: NO PAUSE explícito"
else
  fail "L3: NO PAUSE missing"
fi

if grep -qE "siempre disponible|ambos modos.*siempre|always available" "$SKILL"; then
  ok "L3: ambos modos siempre disponibles"
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
  echo "✅ skill-creator dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ skill-creator dry-run: $FAIL failures"
  exit 1
fi
