# tests/dry-run.sh template canónico — anotado

> Referencia interna del skill-creator. Boilerplate del dry-run.sh con E-008 absorbido + F3-S10/S11 frictions documentadas preventivamente. Cada nuevo skill arranca con la doctrine en el header.

## Header del archivo

```bash
#!/usr/bin/env bash
# {{NAME}} dry-run test
#
# L1 (file presence + frontmatter) + L2 (PREFLIGHT + contract awareness)
# + L3 ({{N}} escenarios canónicos S1-S{{N}}).
#
# E-008 awareness: usa `grep -E` con `|` plain (NUNCA `\|` ni `\\|`).
# F3-S10/S11 frictions absorbidas:
#   - Mode patterns: relax con ( N)? si pattern puede variar
#     Ejemplo: "$modo( N)?" matchea "saltar" o "saltar 3"
#   - Case-sensitivity: usar -i flag donde el patrón puede capitalizar
#     Ejemplo: grep -qiE "Critical|critical"
#   - Patterns con --: usar `grep -qE -- "pattern"` para evitar getopts ambiguity
#     Ejemplo: grep -qE -- "--bg-primary|--accent-green"
#   - Ventanas -A flexibles:
#     -A30 default para secciones largas
#     -A150 para bloques extendidos (tablas + cleanup phases)
#   - Patterns bilingües: cubrir confirmed/confirmado, true/sí, etc.
#     Ejemplo: grep -qiE "binary.*confirm|confirm.*binary"
#
# Usage: bash .claude/skills/{{NAME}}/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── {{NAME}} dry-run ──────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
```

## L1 — File presence

```bash
# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

skill_files=(
  "SKILL.md"
  # TODO: agregar archivos específicos de prompts/ y references/ según shape
  # Ejemplos (lightweight): "prompts/triage-task.md", "references/examples.md"
  # Ejemplos (orchestrator): "prompts/select-pattern.md", "references/coordinator-pattern.md"
)
for f in "${skill_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "{{NAME}}: $f"; else fail "{{NAME}} missing: $f"; fi
done

# templates/ folder según shape:
# - lightweight/meta: NO templates folder
# - orchestrator/pipeline/validator: depende del shape
{{TEMPLATES_CHECK_PER_SHAPE}}
```

Variantes:
- **lightweight/meta**: incluir check `if [ -d templates ]; then fail; else ok; fi`.
- **otros shapes**: dejar comentario explicando si templates existe o no según diseño.

## L1 — Frontmatter

```bash
# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: {{NAME}}$" "$SKILL"; then ok "SKILL.md: name field"; else fail "name missing"; fi

for field in "tier:" "requires:" "fallback:"; do
  if grep -q "^$field" "$SKILL"; then ok "SKILL.md: $field"; else fail "$field missing"; fi
done

# Dependencies — variar según skill
# Si lightweight/meta sin upstream → "^dependencies: \[\]"
# Si requiere find-docs → "^dependencies: \[find-docs\]"
# Si requiere otros → "^dependencies: \[<list>\]"
if grep -qE "^dependencies: {{DEPENDENCIES_REGEX}}" "$SKILL"; then
  ok "SKILL.md: dependencies correct"
else
  fail "SKILL.md: dependencies wrong"
fi

# Tier formato exacto
if grep -qE "tier: {{TIER_REGEX}}" "$SKILL"; then
  ok "SKILL.md: tier correct"
else
  fail "SKILL.md: tier wrong"
fi
```

## L2 — Contract awareness

```bash
# ── L2 — SKILL.md contract awareness ─────────────────────────────────
echo ""
echo "L2 — SKILL.md contract awareness"

# PREFLIGHT section
if grep -qE "^## PREFLIGHT" "$SKILL"; then ok "PREFLIGHT section"; else fail "PREFLIGHT missing"; fi

# TODO: gates específicos según skill
# Ejemplo: if grep -qE "active feature.*feature_list|R1" "$SKILL"; then ok "gate active feature"; fi

# Hard rules cited (R1, R2, R5, R10, R13, R14 según shape)
# TODO: ajustar lista según skill
for rule in {{RULES_TO_CHECK}}; do
  if grep -q "$rule" "$SKILL"; then ok "cites $rule"; else fail "$rule missing"; fi
done

# L-004 cited (siempre, mínimo informativo)
if grep -q "L-004" "$SKILL"; then ok "cites L-004"; else fail "L-004 missing"; fi

# D-{{ADR_ID}} cited
if grep -q "D-{{ADR_ID}}" "$SKILL"; then ok "cites D-{{ADR_ID}}"; else fail "D-{{ADR_ID}} missing"; fi

# Boundaries con skills relacionados
for skill_name in {{BOUNDARY_SKILLS}}; do
  if grep -q "$skill_name" "$SKILL"; then ok "boundary '$skill_name'"; else fail "boundary '$skill_name' missing"; fi
done

# Refusals section
if grep -qE "^## Refusals" "$SKILL"; then ok "Refusals section"; else fail "Refusals missing"; fi

# Tool filter
if grep -qE "Tool filter" "$SKILL"; then ok "Tool filter"; else fail "Tool filter missing"; fi
```

## L2 — prompts/<file>.md (per archivo)

```bash
# ── L2 — prompts/<file>.md ──────────────────────────────────────────
echo ""
echo "L2 — prompts/<file>.md"

PROMPT_FILE="$SKILL_DIR/prompts/<file>.md"

# TODO: checks específicos del prompt
# Ejemplos:
# - Estructura de inputs/output sections
# - Edge cases (>=3 o >=4 según complejidad)
# - Citation grammar específica
# - Pattern detection o decision tree

# Ejemplo edge cases count:
prompt_edges=$(grep -c "^### Edge" "$PROMPT_FILE")
if [ "$prompt_edges" -ge 3 ]; then ok "<file>: $prompt_edges edges"; else fail "only $prompt_edges edges"; fi
```

## L3 — Escenarios canónicos

```bash
# ── L3 — {{N}} escenarios canónicos S1-S{{N}} ───────────────────────
echo ""
echo "L3 — {{N}} escenarios canónicos S1-S{{N}}"

# TODO: 1 check por escenario canónico documentado en references/examples.md
# Cada check valida que el SKILL.md o prompts/ refleja el flow del escenario.

# Ejemplo S1: PREFLIGHT halt sin precondición X
# if grep -qE "halt.*X" "$SKILL"; then ok "L3 S1: halt sin X"; else fail "L3 S1: missing"; fi

# Ejemplo S2: ejecución happy path
# if grep -A20 "Escenario 1" "$EX" | grep -qE "execute|outcome:"; then ok "L3 S2: happy path"; fi
```

## L3 — D-{{ADR_ID}} application (si has_selector)

```bash
# ── L3 — D-{{ADR_ID}} {{BINARY|TRINARY}} application ────────────────
echo ""
echo "L3 — D-{{ADR_ID}} {{BINARY|TRINARY}} application"

# Binary/Trinary shape declarado
if grep -qiE "binary.*shape|D-{{ADR_ID}}.*{{BINARY|TRINARY}}" "$SKILL"; then
  ok "L3: shape declarado"
else
  fail "L3: shape missing"
fi

# NO PAUSE explícito (si binary)
# o PAUSE genuino documentado (si trinary)
{{NO_PAUSE_OR_PAUSE_CHECK}}

# Selector siempre disponible (si binary)
{{ALWAYS_AVAILABLE_CHECK}}
```

## L3 — Boundary case (si NOT has_selector, ADR análogo a D-014)

```bash
# ── L3 — D-{{ADR_ID}} boundary case (NO selector) ───────────────────
echo ""
echo "L3 — D-{{ADR_ID}} boundary case"

# Shape declarado sin selector
if grep -qE "shape distinto|sin selector|sequential pipeline|validator-fijo" "$SKILL"; then
  ok "L3: shape sin selector declarado"
else
  fail "L3: shape rationale missing"
fi

# L-004 NO aplica explícito
if grep -qE "L-004 NO aplica|NO aplica directo|category error" "$SKILL"; then
  ok "L3: L-004 NO aplica directo"
else
  fail "L3: L-004 boundary missing"
fi

# Doctrine refinada D-015 cited
if grep -q "D-014" "$SKILL"; then
  ok "L3: D-014 doctrine context"
else
  fail "L3: D-014 missing"
fi
```

## Summary block (estándar)

```bash
# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ {{NAME}} dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ {{NAME}} dry-run: $FAIL failures"
  exit 1
fi
```

## TODOs explícitos en el boilerplate

El generated dry-run.sh debe tener TODOs visibles para que el autor sepa qué reemplazar:

```bash
# ============================================================
# TODO post-scaffold (cuando vas a authorizar el skill):
# 1. Reemplazar `{{NAME}}` por nombre real del skill.
# 2. Llenar L1 file presence con archivos específicos de prompts/references.
# 3. Llenar L2 contract awareness con reglas operativas reales.
# 4. Llenar L3 escenarios con S1..S{{N}} basados en references/examples.md.
# 5. Si has_selector → completar L3 D-{{ADR_ID}} binary/trinary checks.
# 6. Si NOT has_selector → completar L3 boundary case checks (D-014 doctrine).
# 7. Run hasta `ALL PASS ($N checks)`.
# 8. Comparable lightness: target 60-100 checks (más checks no = mejor).
# ============================================================
```

## Verificación pre-write

Antes de escribir el archivo, validar:

1. `bash -n` parsing válido (sintaxis bash correcta).
2. Header E-008 awareness presente.
3. F3-S10/S11 frictions awareness presente.
4. PASS/FAIL counter init.
5. ok()/fail() helpers definidos.
6. Summary block al final.

Si validación falla → halt + reportar bug en el template.

## Skills de referencia para inspirarse

Por shape:

- **lightweight**: `.claude/skills/primer/tests/dry-run.sh` (61-80 checks típico).
- **orchestrator**: `.claude/skills/la-forja/tests/dry-run.sh` (160+ checks).
- **pipeline**: `.claude/skills/el-crisol/tests/dry-run.sh` (157 checks).
- **validator**: `.claude/skills/web-quality/tests/dry-run.sh` (158 checks).
- **meta**: `.claude/skills/skill-creator/tests/dry-run.sh` (este mismo skill).

## Citation grammar

- [memory:errors#E-008] — escape syntax awareness from birth.
- [memory:decisions#D-018] — skill-creator binary mode (boilerplate generated by both modes).
