#!/usr/bin/env bash
# el-crisol dry-run test
#
# Validates L1 (file presence + frontmatter) + L2 (Fase 0 estado + contract awareness)
# + L3 (Fase 1-3 flow + 4 escenarios canónicos S1-S4).
#
# E-008 awareness: usa `grep -E` con `|` plain (no `\|` ni `\\|`), ventanas -A flexibles.
# Shape: sequential-pipeline (NO selector entre providers). L-004 NO aplica directo.
#
# Usage: bash .claude/skills/el-crisol/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── el-crisol dry-run ───────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

el_crisol_files=(
  "SKILL.md"
  "prompts/detect-state.md"
  "prompts/run-step.md"
  "prompts/build-dashboard.md"
  "references/go-no-go-scoring.md"
  "references/strategy-summary.md"
  "references/strategy-pipeline-rationale.md"
)
for f in "${el_crisol_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "el-crisol: $f"; else fail "el-crisol missing: $f"; fi
done

# NO templates folder (el-crisol no genera código de aplicación)
if [ -d "$SKILL_DIR/templates" ]; then
  fail "el-crisol: templates/ folder existe (debe ser sin templates como la-forja)"
else
  ok "el-crisol: NO templates/ folder (orquestador thin OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: el-crisol$" "$SKILL"; then
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

if grep -qE "^dependencies: \[\]" "$SKILL"; then
  ok "SKILL.md: dependencies field empty (no upstream skills)"
else
  fail "SKILL.md: dependencies field incorrect"
fi

# ── L2 — SKILL.md PREFLIGHT + 3 fases ────────────────────────────────
echo ""
echo "L2 — SKILL.md PREFLIGHT + 3 fases"

if grep -qE "^## PREFLIGHT" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT section"
else
  fail "SKILL.md: PREFLIGHT missing"
fi

# Blueprint gate
if grep -qE "BLUEPRINT-\*\.md|Blueprint aprobado" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT requires BLUEPRINT"
else
  fail "SKILL.md: BLUEPRINT gate missing"
fi

# Handoff a la-herreria si falta
if grep -qE "handoff.*la-herreria|halt.*la-herreria" "$SKILL"; then
  ok "SKILL.md: halt + handoff la-herreria si Blueprint falta"
else
  fail "SKILL.md: handoff la-herreria missing"
fi

# 3 fases del pipeline
for fase in "Fase 0" "Fase 1" "Fase 2" "Fase 3"; do
  if grep -q "$fase" "$SKILL"; then
    ok "SKILL.md mentions '$fase'"
  else
    fail "SKILL.md missing '$fase'"
  fi
done

# 7 pasos del pipeline
for paso in "brujula" "estrella" "rivales" "precio" "roi" "metas" "lanzamiento"; do
  if grep -q "$paso" "$SKILL"; then
    ok "SKILL.md mentions step '$paso'"
  else
    fail "SKILL.md missing step '$paso'"
  fi
done

# 4 modos de invocación (acepta "modo" o "modo N" o `modo`)
for modo in "go" "saltar" "desde" "solo dashboard"; do
  if grep -qE "\"$modo( N)?\"|\`$modo\`|\"$modo\"" "$SKILL"; then
    ok "SKILL.md mode '$modo'"
  else
    fail "SKILL.md mode '$modo' missing"
  fi
done

# Veredicto Go/Caution/No-Go
for veredicto in "Go" "Caution" "No-Go"; do
  if grep -q "$veredicto" "$SKILL"; then
    ok "SKILL.md verdict '$veredicto'"
  else
    fail "SKILL.md verdict '$veredicto' missing"
  fi
done

# Hard rules R4/R5
for rule in "R4" "R5"; do
  if grep -q "$rule" "$SKILL"; then
    ok "SKILL.md cites $rule"
  else
    fail "SKILL.md missing $rule citation"
  fi
done

# L-004 + D-014 (NO aplica directo)
if grep -q "L-004" "$SKILL"; then
  ok "SKILL.md cites L-004 (informativo NO aplica directo)"
else
  fail "SKILL.md L-004 missing"
fi

if grep -q "D-014" "$SKILL"; then
  ok "SKILL.md cites D-014 (pipeline shape vs selector)"
else
  fail "SKILL.md D-014 missing"
fi

# Boundaries con skills relacionados
for skill in "la-herreria" "la-forja" "el-yunque" "el-evaluador" "find-docs"; do
  if grep -q "$skill" "$SKILL"; then
    ok "SKILL.md mentions boundary '$skill'"
  else
    fail "SKILL.md boundary '$skill' missing"
  fi
done

# Refusals section
if grep -qE "^## Refusals" "$SKILL"; then
  ok "SKILL.md: Refusals section"
else
  fail "SKILL.md: Refusals section missing"
fi

# Tool filter
if grep -qE "Tool filter|NO Edit|NO Write" "$SKILL"; then
  ok "SKILL.md: Tool filter (el-crisol thin)"
else
  fail "SKILL.md: Tool filter missing"
fi

# ── L2 — detect-state.md (Fase 0 estado) ─────────────────────────────
echo ""
echo "L2 — detect-state.md (Fase 0)"

DS="$SKILL_DIR/prompts/detect-state.md"

# Scan de los 7 docs estratégicos
for pattern in "STRATEGY-CANVAS" "NORTH-STAR" "COMPETITIVE-ANALYSIS" "PRICING-STRATEGY" "saas-analysis" "OKRS" "GTM-STRATEGY"; do
  if grep -q "$pattern" "$DS"; then
    ok "detect-state: pattern '$pattern' scanned"
  else
    fail "detect-state: pattern '$pattern' missing"
  fi
done

# Scan en raíz Y .claude/reports
if grep -qE "raíz|root" "$DS" && grep -qE "\.claude/reports" "$DS"; then
  ok "detect-state: scan en raíz Y .claude/reports"
else
  fail "detect-state: dual scan missing"
fi

# Determinar nombre del proyecto
if grep -qE "project_name|nombre del proyecto|extraer.*nombre" "$DS"; then
  ok "detect-state: project_name extraction"
else
  fail "detect-state: project_name logic missing"
fi

# Tabla de estado con ✅ y ⬜
if grep -qE "✅|✓ " "$DS" && grep -qE "⬜|☐ " "$DS"; then
  ok "detect-state: tabla estado con checkmarks"
else
  fail "detect-state: tabla estado missing"
fi

# Perplexity opt-in
if grep -qE "Perplexity|perplexity" "$DS"; then
  ok "detect-state: Perplexity opt-in"
else
  fail "detect-state: Perplexity missing"
fi

# 4 modos de inicio (acepta "modo" o "modo N" o `modo`)
for modo in "go" "saltar" "desde" "solo dashboard"; do
  if grep -qE "\"$modo( N)?\"|\`$modo\`|\"$modo\"" "$DS"; then
    ok "detect-state: start mode '$modo'"
  else
    fail "detect-state: start mode '$modo' missing"
  fi
done

# Edge cases (>=4)
ds_edges=$(grep -c "^### Edge" "$DS")
if [ "$ds_edges" -ge 4 ]; then
  ok "detect-state: $ds_edges edge cases (>=4)"
else
  fail "detect-state: only $ds_edges edge cases"
fi

# ── L2 — run-step.md (Fase 1 protocolo) ──────────────────────────────
echo ""
echo "L2 — run-step.md (Fase 1)"

RS="$SKILL_DIR/prompts/run-step.md"

# Protocolo paso a paso
for keyword in "Anunciar" "Dispatch" "Confirmar" "Transición"; do
  if grep -qE "$keyword" "$RS"; then
    ok "run-step: protocol step '$keyword'"
  else
    fail "run-step: protocol step '$keyword' missing"
  fi
done

# R4 enforcement (sub-agent dispatch, NO el-crisol directo)
if grep -qE "R4|Orchestrator stays thin|sub-agent dispatch|el-crisol MISMA NO" "$RS"; then
  ok "run-step: R4 enforcement"
else
  fail "run-step: R4 missing"
fi

# R5 enforcement (sub-agents no escriben memory)
if grep -qE "R5|workers no escriben.*memory|NO escriben a memory" "$RS"; then
  ok "run-step: R5 enforcement"
else
  fail "run-step: R5 missing"
fi

# Reglas de ejecución cross-pasos
for regla in "No re-preguntar" "No contradecir" "Docs existentes"; do
  if grep -q "$regla" "$RS"; then
    ok "run-step: rule '$regla'"
  else
    fail "run-step: rule '$regla' missing"
  fi
done

# Mapeo paso → template
if grep -qE "Mapeo|Mapping|paso.*template" "$RS"; then
  ok "run-step: mapping paso→template"
else
  fail "run-step: mapping missing"
fi

# Edge cases (>=4)
rs_edges=$(grep -c "^### Edge" "$RS")
if [ "$rs_edges" -ge 4 ]; then
  ok "run-step: $rs_edges edge cases (>=4)"
else
  fail "run-step: only $rs_edges edge cases"
fi

# ── L2 — build-dashboard.md (Fase 2 dashboard) ───────────────────────
echo ""
echo "L2 — build-dashboard.md (Fase 2)"

BD="$SKILL_DIR/prompts/build-dashboard.md"

# Chart.js CDN
if grep -qE "cdn.jsdelivr.net/npm/chart.js" "$BD"; then
  ok "build-dashboard: Chart.js CDN canónico"
else
  fail "build-dashboard: Chart.js CDN missing"
fi

# Specs canónicas
for spec in "Liquid Glass" "Bento" "dark mode" "print" "standalone"; do
  if grep -qiE "$spec" "$BD"; then
    ok "build-dashboard: spec '$spec'"
  else
    fail "build-dashboard: spec '$spec' missing"
  fi
done

# Responsive breakpoints
if grep -qE "768px|1200px|breakpoint" "$BD"; then
  ok "build-dashboard: responsive breakpoints"
else
  fail "build-dashboard: breakpoints missing"
fi

# 9 secciones canónicas
for seccion in "Hero" "Strategy Canvas" "North Star Metric" "Competitive Landscape" "Pricing" "Financial Projections" "OKRs" "Go-to-Market" "Risks"; do
  if grep -q "$seccion" "$BD"; then
    ok "build-dashboard: section '$seccion'"
  else
    fail "build-dashboard: section '$seccion' missing"
  fi
done

# Chart types canónicos (case-insensitive — los docs usan capitalize)
for chart in "radar" "doughnut" "line" "scatter" "bar"; do
  if grep -qiE "type: '$chart'|$chart chart" "$BD"; then
    ok "build-dashboard: Chart.js type '$chart'"
  else
    fail "build-dashboard: chart '$chart' missing"
  fi
done

# Mapa de extracción de datos
if grep -qE "Mapa de extracción|extracción de datos|De STRATEGY-CANVAS" "$BD"; then
  ok "build-dashboard: mapa de extracción documented"
else
  fail "build-dashboard: mapa extracción missing"
fi

# CSS custom properties canónicas (-- al inicio confunde getopts → usar -- separator)
if grep -qE -- "--bg-primary|--bg-card|--accent-green" "$BD"; then
  ok "build-dashboard: CSS custom properties"
else
  fail "build-dashboard: CSS vars missing"
fi

# Graceful degradation
if grep -qE "[Gg]raceful degradation|Análisis no realizado" "$BD"; then
  ok "build-dashboard: graceful degradation"
else
  fail "build-dashboard: graceful degradation missing"
fi

# find-docs invocation (R13 condicional)
if grep -qE "find-docs|ctx7|R13" "$BD"; then
  ok "build-dashboard: find-docs/R13 condicional"
else
  fail "build-dashboard: find-docs missing"
fi

# Edge cases (>=4)
bd_edges=$(grep -c "^### Edge" "$BD")
if [ "$bd_edges" -ge 4 ]; then
  ok "build-dashboard: $bd_edges edge cases (>=4)"
else
  fail "build-dashboard: only $bd_edges edge cases"
fi

# ── L2 — references/go-no-go-scoring.md ──────────────────────────────
echo ""
echo "L2 — references/go-no-go-scoring.md"

GNG="$SKILL_DIR/references/go-no-go-scoring.md"

# 7 dimensiones
for dim in "Market Fit" "Metric Clarity" "Competitive Position" "Monetization" "Financial Viability" "Execution Plan" "GTM Feasibility"; do
  if grep -q "$dim" "$GNG"; then
    ok "go-no-go: dimension '$dim'"
  else
    fail "go-no-go: dimension '$dim' missing"
  fi
done

# Pesos
for peso in "20%" "10%" "15%"; do
  if grep -q "$peso" "$GNG"; then
    ok "go-no-go: weight '$peso'"
  else
    fail "go-no-go: weight '$peso' missing"
  fi
done

# Veredicto thresholds
if grep -qE "8\.0.*10\.0|8-10" "$GNG"; then
  ok "go-no-go: Go threshold 8-10"
else
  fail "go-no-go: Go threshold missing"
fi

if grep -qE "5\.0.*7\.9|5-7" "$GNG"; then
  ok "go-no-go: Caution threshold 5-7"
else
  fail "go-no-go: Caution threshold missing"
fi

if grep -qE "1\.0.*4\.9|1-4" "$GNG"; then
  ok "go-no-go: No-Go threshold 1-4"
else
  fail "go-no-go: No-Go threshold missing"
fi

# Cita doc fuente (R8 análogo)
if grep -qE "cita.*doc fuente|cite.*doc|[Dd]ato clave" "$GNG"; then
  ok "go-no-go: cita doc fuente enforcement"
else
  fail "go-no-go: cita enforcement missing"
fi

# NO inventar scores
if grep -qE "NO scores inventados|NO inventar|no inventar" "$GNG"; then
  ok "go-no-go: NO inventar scores explicit"
else
  fail "go-no-go: NO inventar enforcement missing"
fi

# Si falta dimensión → N/A redistribute
if grep -qE "N/A|redistrib|reescal" "$GNG"; then
  ok "go-no-go: N/A redistribución de pesos"
else
  fail "go-no-go: N/A redistribution missing"
fi

# ── L2 — references/strategy-summary.md ──────────────────────────────
echo ""
echo "L2 — references/strategy-summary.md"

SS="$SKILL_DIR/references/strategy-summary.md"

# Estructura del documento
for sec in "Executive Summary" "Métricas Clave" "Visión y Posicionamiento" "Competencia" "Monetización" "Proyección Financiera" "Metas" "Go-to-Market" "Riesgos" "Build Confidence Score" "Siguiente Paso"; do
  if grep -q "$sec" "$SS"; then
    ok "strategy-summary: section '$sec'"
  else
    fail "strategy-summary: section '$sec' missing"
  fi
done

# Status column with semaforo
if grep -qE "ok.*warning.*critical|ok/warning/critical" "$SS"; then
  ok "strategy-summary: status semaforo"
else
  fail "strategy-summary: semaforo missing"
fi

# Siguiente paso por veredicto
for v in "Go" "Caution" "No-Go"; do
  if grep -q "$v" "$SS"; then
    ok "strategy-summary: verdict '$v' next-step"
  else
    fail "strategy-summary: verdict '$v' missing"
  fi
done

# ── L2 — references/strategy-pipeline-rationale.md (D-014 + L-004) ───
echo ""
echo "L2 — strategy-pipeline-rationale.md (D-014 + L-004)"

SPR="$SKILL_DIR/references/strategy-pipeline-rationale.md"

# L-004 cited
if grep -q "L-004" "$SPR"; then
  ok "strategy-pipeline-rationale: L-004 cited"
else
  fail "strategy-pipeline-rationale: L-004 missing"
fi

# D-014 cited
if grep -q "D-014" "$SPR"; then
  ok "strategy-pipeline-rationale: D-014 cited"
else
  fail "strategy-pipeline-rationale: D-014 missing"
fi

# Sequential pipeline shape declared
if grep -qE "[Ss]equential pipeline|sequential.*pipeline" "$SPR"; then
  ok "strategy-pipeline-rationale: sequential pipeline shape"
else
  fail "strategy-pipeline-rationale: pipeline shape missing"
fi

# NO selector / category error
if grep -qE "NO.*selector|no.*selector entre|category error|NO aplica directo" "$SPR"; then
  ok "strategy-pipeline-rationale: NO selector / category error"
else
  fail "strategy-pipeline-rationale: NO selector reasoning missing"
fi

# 5 ADRs cross-skill cross-cited (D-009 → D-013)
for adr in "D-009" "D-010" "D-011" "D-012" "D-013"; do
  if grep -q "$adr" "$SPR"; then
    ok "strategy-pipeline-rationale: $adr cross-cited"
  else
    fail "strategy-pipeline-rationale: $adr missing"
  fi
done

# Boundary explicit (where L-004 stops applying)
if grep -qE "[Bb]oundary|límite|primer.*donde.*NO aplica" "$SPR"; then
  ok "strategy-pipeline-rationale: boundary documented"
else
  fail "strategy-pipeline-rationale: boundary missing"
fi

# Resume-aware mention
if grep -qE "[Rr]esume-aware|resume.*aware" "$SPR"; then
  ok "strategy-pipeline-rationale: resume-aware shape"
else
  fail "strategy-pipeline-rationale: resume-aware missing"
fi

# ── L3 — Mental dry-run de los 4 escenarios canónicos ────────────────
echo ""
echo "L3 — Mental dry-run de 4 escenarios canónicos"

# S1: Cold start (0 docs)
# Expected: PREFLIGHT pasa (Blueprint ok), tabla muestra 7 ⬜, default `go`
if grep -qE "[Cc]old start|sin docs estratégicos|0 docs" "$SPR" || grep -qE "cold start|0 docs" "$DS"; then
  ok "L3 S1: cold start scenario documented"
else
  fail "L3 S1: cold start missing"
fi

if grep -A20 "^## Edge cases" "$DS" | grep -qE "[Cc]old start|0 docs|sin docs"; then
  ok "L3 S1: cold start edge case in detect-state"
else
  # buscar fuera de edge cases
  if grep -qE "[Cc]old start" "$DS"; then
    ok "L3 S1: cold start edge case in detect-state"
  else
    fail "L3 S1: cold start edge missing"
  fi
fi

# S2: Resume parcial (3 of 7 exist)
# Expected: scan detecta los 3, marca ✅, los otros 4 ⬜, modo selectable
if grep -qE "[Rr]esume parcial|resume.*parcial|skip.*existentes" "$DS" "$SPR" "$SKILL"; then
  ok "L3 S2: resume parcial scenario documented"
else
  fail "L3 S2: resume parcial missing"
fi

# S3: Solo dashboard (todos existen)
# Expected: modo `solo dashboard` default, salta Fase 1, va directo a Fase 2
if grep -qE "solo dashboard|solo-dashboard" "$DS" "$SKILL"; then
  ok "L3 S3: solo dashboard mode documented"
else
  fail "L3 S3: solo dashboard missing"
fi

# S4: Veredicto Go → handoff a la-forja
# Expected: SKILL.md sección handoff por veredicto incluye Go → la-forja
if grep -A30 "Según veredicto" "$SKILL" | grep -qE "Go.*8-10.*la-forja|Go ✅.*la-forja"; then
  ok "L3 S4: Go verdict → handoff la-forja"
else
  # buscar separadamente
  if grep -B2 -A5 "^\*\*Go" "$SKILL" | grep -q "la-forja"; then
    ok "L3 S4: Go verdict → handoff la-forja"
  else
    fail "L3 S4: Go handoff la-forja missing"
  fi
fi

# Caution handoff
if grep -A10 "^\*\*Caution" "$SKILL" | grep -qE "ajustar|re-ejecutar|aceptar"; then
  ok "L3 S4: Caution verdict → ajustar/re-ejecutar"
else
  fail "L3 S4: Caution handoff missing"
fi

# No-Go handoff
if grep -A10 "^\*\*No-Go" "$SKILL" | grep -qE "replantear|NO build|gaps fundamentales"; then
  ok "L3 S4: No-Go verdict → replantear"
else
  fail "L3 S4: No-Go handoff missing"
fi

# ── L3 — D-014 boundary application ──────────────────────────────────
echo ""
echo "L3 — D-014 boundary (L-004 NO aplica directo)"

# D-014 documenta NO aplica
if grep -qE "L-004 NO aplica|NO aplica directo|category error" "$SPR"; then
  ok "L3: L-004 NO aplica directo a el-crisol explícito"
else
  fail "L3: L-004 NO aplica statement missing"
fi

# Pipeline shape ≠ selector shape
if grep -qE "shape distinto|sequential pipeline|NO selector|pipeline.*selector" "$SPR"; then
  ok "L3: pipeline shape ≠ selector shape"
else
  fail "L3: shape distinction missing"
fi

# Tabla de generalización (D-009..D-014)
if grep -A15 "Generalización" "$SPR" | grep -qE "D-009" && grep -A15 "Generalización" "$SPR" | grep -qE "D-014"; then
  ok "L3: tabla generalización D-009→D-014 cross-skill"
else
  # alternative window
  if grep -B2 -A2 "D-014" "$SPR" | grep -q "primer"; then
    ok "L3: D-014 marca boundary cross-skill"
  else
    fail "L3: generalización tabla missing"
  fi
fi

# ── L3 — Pipeline ejecución mental dry-run ───────────────────────────
echo ""
echo "L3 — Pipeline ejecución mental dry-run"

# Input: "validá la estrategia de mi SaaS" (cold start)
# Expected flow: PREFLIGHT → Fase 0 detect (0 docs) → preguntar `go` → Fase 1 ejecuta 7 pasos → Fase 2 dashboard → Fase 3 veredicto

# Fase 0 detect-state invocada
if grep -qE "Fase 0|detect-state" "$SKILL"; then
  ok "L3 flow: Fase 0 detect-state invoked"
else
  fail "L3 flow: Fase 0 missing"
fi

# Fase 1 run-step invocada
if grep -qE "Fase 1|run-step" "$SKILL"; then
  ok "L3 flow: Fase 1 run-step invoked"
else
  fail "L3 flow: Fase 1 missing"
fi

# Fase 2 build-dashboard invocada
if grep -qE "Fase 2|build-dashboard" "$SKILL"; then
  ok "L3 flow: Fase 2 build-dashboard invoked"
else
  fail "L3 flow: Fase 2 missing"
fi

# Fase 3 handoff por veredicto
if grep -qE "Fase 3|veredicto" "$SKILL"; then
  ok "L3 flow: Fase 3 handoff por veredicto"
else
  fail "L3 flow: Fase 3 missing"
fi

# 7 pasos en orden de dependencia documentados
if grep -E "brujula.*estrella.*rivales.*precio.*roi.*metas.*lanzamiento|brujula → estrella" "$SKILL" >/dev/null; then
  ok "L3 flow: 7 pasos en orden de dependencia"
else
  fail "L3 flow: dependency order missing"
fi

# Build Confidence Score scoring referenced
if grep -qE "Build Confidence Score|build confidence score" "$SKILL"; then
  ok "L3 flow: Build Confidence Score referenced in SKILL.md"
else
  fail "L3 flow: Build Confidence Score missing"
fi

# Sub-agent dispatch pattern (R4 thin orchestrator)
if grep -qE "Dispatch sub-agent|dispatch.*sub-agent|sub-agent dispatched" "$SKILL" "$RS"; then
  ok "L3 flow: sub-agent dispatch pattern (R4 thin)"
else
  fail "L3 flow: sub-agent dispatch missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ el-crisol dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ el-crisol dry-run: $FAIL failures"
  exit 1
fi
