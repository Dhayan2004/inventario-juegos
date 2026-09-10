#!/usr/bin/env bash
# web-quality dry-run test
#
# Validates L1 (file presence + frontmatter) + L2 (mode selector + 4 categorías)
# + L3 (S1-S6 escenarios canónicos + D-015 binary application).
#
# E-008 awareness: usa `grep -E` con `|` plain (no `\|` ni `\\|`).
# F3-S10 frictions awareness:
#   - Mode patterns: relax con ( N)? si pattern puede variar
#   - Case-sensitivity: -i flag donde aplica
#   - Patterns con --: usar `grep -qE -- "pattern"` para getopts
#
# Usage: bash .claude/skills/web-quality/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── web-quality dry-run ─────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — File presence ──────────────────────────────────────────────
echo "L1 — File presence"

web_quality_files=(
  "SKILL.md"
  "prompts/run-audit.md"
  "prompts/build-report.md"
  "references/performance.md"
  "references/accessibility.md"
  "references/seo.md"
  "references/best-practices.md"
  "references/audit-mode-rationale.md"
)
for f in "${web_quality_files[@]}"; do
  if [ -f "$SKILL_DIR/$f" ]; then ok "web-quality: $f"; else fail "web-quality missing: $f"; fi
done

# NO templates folder (web-quality es validator thin, no genera código)
if [ -d "$SKILL_DIR/templates" ]; then
  fail "web-quality: templates/ folder existe (debe ser thin validator)"
else
  ok "web-quality: NO templates/ folder (validator thin OK)"
fi

# ── L1 — SKILL.md frontmatter ────────────────────────────────────────
echo ""
echo "L1 — SKILL.md frontmatter"

SKILL="$SKILL_DIR/SKILL.md"

if grep -q "^name: web-quality$" "$SKILL"; then
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

if grep -qE "^dependencies: \[find-docs\]" "$SKILL"; then
  ok "SKILL.md: dependencies includes find-docs (R13)"
else
  fail "SKILL.md: dependencies field incorrect"
fi

# ── L2 — SKILL.md PREFLIGHT + binary mode + 4 categorías ─────────────
echo ""
echo "L2 — SKILL.md contract awareness"

if grep -qE "^## PREFLIGHT" "$SKILL"; then
  ok "SKILL.md: PREFLIGHT section"
else
  fail "SKILL.md: PREFLIGHT missing"
fi

# Detección Next.js (src/ o pages/)
if grep -qE "src/|pages/" "$SKILL"; then
  ok "SKILL.md: detección Next.js (src/ o pages/)"
else
  fail "SKILL.md: Next.js detection missing"
fi

# Halt informativo "no parece un proyecto Next.js"
if grep -qE "no parece.*Next\.js|halt.*Next\.js" "$SKILL"; then
  ok "SKILL.md: halt informativo si no es Next.js"
else
  fail "SKILL.md: Next.js halt missing"
fi

# Binary mode selector (live + static)
for mode in "live" "static"; do
  if grep -qiE "$mode audit|$mode analysis|modo $mode|mode.*$mode|$mode mode" "$SKILL"; then
    ok "SKILL.md: mode '$mode' documented"
  else
    fail "SKILL.md: mode '$mode' missing"
  fi
done

# Default live + fallback static
if grep -qE "default|DEFAULT" "$SKILL" && grep -qiE "live.*default|default.*live" "$SKILL"; then
  ok "SKILL.md: live default declarado"
else
  fail "SKILL.md: live default missing"
fi

if grep -qE "fallback graceful|graceful fallback|static.*fallback" "$SKILL"; then
  ok "SKILL.md: static fallback graceful"
else
  fail "SKILL.md: static fallback missing"
fi

# 4 categorías canónicas
for cat in "Performance" "Accessibility" "SEO" "Best Practices"; do
  if grep -q "$cat" "$SKILL"; then
    ok "SKILL.md: category '$cat'"
  else
    fail "SKILL.md: category '$cat' missing"
  fi
done

# Core Web Vitals
for cwv in "LCP" "INP" "CLS"; do
  if grep -q "$cwv" "$SKILL"; then
    ok "SKILL.md: Core Web Vital '$cwv'"
  else
    fail "SKILL.md: '$cwv' missing"
  fi
done

# WCAG 2.1 AA
if grep -qE "WCAG 2\.1.*AA|AA.*WCAG 2\.1" "$SKILL"; then
  ok "SKILL.md: WCAG 2.1 AA mandatory"
else
  fail "SKILL.md: WCAG 2.1 AA missing"
fi

# Niveles de severidad (case-insensitive — F3-S10 friction)
for sev in "Critical" "High" "Medium" "Low"; do
  if grep -qiE "\*\*$sev\*\*|severity.*$sev|$sev priority" "$SKILL"; then
    ok "SKILL.md: severity '$sev'"
  else
    fail "SKILL.md: severity '$sev' missing"
  fi
done

# Lighthouse Score Targets (≥90 / 100 / ≥95 / ≥95)
if grep -qE "≥ ?90|>= ?90|>=90" "$SKILL"; then
  ok "SKILL.md: Performance target ≥90"
else
  fail "SKILL.md: Performance target missing"
fi

if grep -qE "Accessibility.*100|100.*Accessibility" "$SKILL"; then
  ok "SKILL.md: Accessibility target 100"
else
  fail "SKILL.md: Accessibility target missing"
fi

if grep -qE "≥ ?95|>= ?95|>=95" "$SKILL"; then
  ok "SKILL.md: Best Practices/SEO target ≥95"
else
  fail "SKILL.md: BP/SEO target missing"
fi

# agent-browser default D4
if grep -qE "agent-browser.*default|default.*agent-browser|D4" "$SKILL"; then
  ok "SKILL.md: agent-browser default (D4)"
else
  fail "SKILL.md: agent-browser default missing"
fi

# R-003 reference cited
if grep -q "R-003" "$SKILL"; then
  ok "SKILL.md: R-003 cited (agent-browser)"
else
  fail "SKILL.md: R-003 missing"
fi

# Hard rules R4/R5/R13
for rule in "R4" "R5" "R13"; do
  if grep -q "$rule" "$SKILL"; then
    ok "SKILL.md cites $rule"
  else
    fail "SKILL.md missing $rule citation"
  fi
done

# L-004 + D-015
if grep -q "L-004" "$SKILL"; then
  ok "SKILL.md cites L-004"
else
  fail "SKILL.md L-004 missing"
fi

if grep -q "D-015" "$SKILL"; then
  ok "SKILL.md cites D-015"
else
  fail "SKILL.md D-015 missing"
fi

# Boundaries
for skill in "el-guardian" "el-evaluador" "la-forja" "find-docs" "impeccable" "add-ui-kit"; do
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
  ok "SKILL.md: Tool filter (web-quality thin)"
else
  fail "SKILL.md: Tool filter missing"
fi

# ── L2 — run-audit.md (live + static modes) ──────────────────────────
echo ""
echo "L2 — run-audit.md"

RA="$SKILL_DIR/prompts/run-audit.md"

# R13 enforcement + find-docs
if grep -q "R13" "$RA"; then
  ok "run-audit: R13 cited"
else
  fail "run-audit: R13 missing"
fi

if grep -qE "find-docs|ctx7" "$RA"; then
  ok "run-audit: find-docs invocation"
else
  fail "run-audit: find-docs missing"
fi

# 2 modes (live + static) protocol
for mode in "LIVE" "STATIC"; do
  if grep -qE "Mode $mode|mode $mode|$mode — protocolo" "$RA"; then
    ok "run-audit: $mode protocolo"
  else
    fail "run-audit: $mode protocolo missing"
  fi
done

# agent-browser CLI documented
if grep -qE "agent-browser audit|agent-browser CLI" "$RA"; then
  ok "run-audit: agent-browser commands"
else
  fail "run-audit: agent-browser commands missing"
fi

# Lighthouse CLI fallback
if grep -qE "lighthouse|Lighthouse" "$RA"; then
  ok "run-audit: Lighthouse CLI fallback"
else
  fail "run-audit: Lighthouse fallback missing"
fi

# Severity mapping
for sev in "Critical" "High" "Medium" "Low"; do
  if grep -qE "$sev" "$RA"; then
    ok "run-audit: severity '$sev' mapped"
  else
    fail "run-audit: severity '$sev' missing"
  fi
done

# R4/R5 enforcement
if grep -qE "R4|Orchestrator stays thin" "$RA"; then
  ok "run-audit: R4 enforcement"
else
  fail "run-audit: R4 missing"
fi

if grep -qE "R5|workers no escriben.*memory|NO escriben a memory" "$RA"; then
  ok "run-audit: R5 enforcement"
else
  fail "run-audit: R5 missing"
fi

# Pattern detection static
if grep -qE "[Pp]attern detection|pattern detection static" "$RA"; then
  ok "run-audit: pattern detection static"
else
  fail "run-audit: pattern detection missing"
fi

# Edge cases (>=4)
ra_edges=$(grep -c "^### Edge" "$RA")
if [ "$ra_edges" -ge 4 ]; then
  ok "run-audit: $ra_edges edge cases (>=4)"
else
  fail "run-audit: only $ra_edges edge cases"
fi

# ── L2 — build-report.md (template del reporte) ──────────────────────
echo ""
echo "L2 — build-report.md"

BR="$SKILL_DIR/prompts/build-report.md"

# Estructura del reporte
for sec in "Lighthouse Scores" "Core Web Vitals" "Issues Críticos" "Alta Prioridad" "Media Prioridad" "Baja Prioridad" "Resumen" "Pre-deploy Gate" "Prioridad Recomendada" "Checklist Pre-Deploy"; do
  if grep -q "$sec" "$BR"; then
    ok "build-report: section '$sec'"
  else
    fail "build-report: section '$sec' missing"
  fi
done

# Code snippets en Critical/High
if grep -qE "ANTES|DESPUÉS|snippet_before|snippet_after" "$BR"; then
  ok "build-report: code snippets ANTES/DESPUÉS"
else
  fail "build-report: code snippets missing"
fi

# Line numbers requirement
if grep -qE "[Ll]ine numbers|path:line|file:line|:[0-9]+" "$BR"; then
  ok "build-report: line numbers requirement"
else
  fail "build-report: line numbers missing"
fi

# Pre-deploy gate PASS/NEEDS_FIX
if grep -qE "PASS|NEEDS_FIX" "$BR"; then
  ok "build-report: pre-deploy gate PASS/NEEDS_FIX"
else
  fail "build-report: gate missing"
fi

# Forja-specific checks
if grep -qE "brand/brand\.css|brand\.json.*cliente|brand\.json.*bundle" "$BR"; then
  ok "build-report: Forja-specific brand checks"
else
  fail "build-report: Forja-specific checks missing"
fi

# ── L2 — references/performance.md ───────────────────────────────────
echo ""
echo "L2 — references/performance.md"

PERF="$SKILL_DIR/references/performance.md"

# Performance budget table
if grep -qE "Performance budget|Budget.*KB|< ?1\.5 ?MB" "$PERF"; then
  ok "performance: budget table"
else
  fail "performance: budget table missing"
fi

# Next.js specific (next/image, next/font, next/dynamic)
for nx in "next/image" "next/font" "next/dynamic" "next/script"; do
  if grep -q "$nx" "$PERF"; then
    ok "performance: $nx documented"
  else
    fail "performance: $nx missing"
  fi
done

# agent-browser CLI commands (no -- flag prefix issue here, but ready)
if grep -qE "agent-browser audit|agent-browser CLI" "$PERF"; then
  ok "performance: agent-browser CLI commands"
else
  fail "performance: agent-browser commands missing"
fi

# R-003 cited
if grep -q "R-003" "$PERF"; then
  ok "performance: R-003 cited (agent-browser)"
else
  fail "performance: R-003 missing"
fi

# Core Web Vitals targets
for metric in "LCP.*2\.5s\|2\.5s.*LCP" "INP.*200ms\|200ms.*INP" "CLS.*0\.1\|0\.1.*CLS"; do
  # Use -E without escaping | (E-008 friction prevention)
  pattern_test=$(echo "$metric" | sed 's/\\|/|/g')
  if grep -qE "$pattern_test" "$PERF"; then
    name="${metric%%.*}"
    ok "performance: target $name documented"
  else
    name="${metric%%.*}"
    fail "performance: target $name missing"
  fi
done

# ── L2 — references/accessibility.md (WCAG 2.1 AA) ───────────────────
echo ""
echo "L2 — references/accessibility.md"

A11Y="$SKILL_DIR/references/accessibility.md"

# WCAG 2.1 AA mandatory
if grep -qE "WCAG 2\.1 AA|AA.*WCAG 2\.1" "$A11Y"; then
  ok "accessibility: WCAG 2.1 AA mandatory"
else
  fail "accessibility: WCAG 2.1 AA missing"
fi

# POUR principles
for p in "Perceivable" "Operable" "Understandable" "Robust"; do
  if grep -q "$p" "$A11Y"; then
    ok "accessibility: POUR '$p'"
  else
    fail "accessibility: POUR '$p' missing"
  fi
done

# Conformance levels
for level in "**A**" "**AA**" "**AAA**"; do
  if grep -qF "$level" "$A11Y"; then
    ok "accessibility: conformance level $level"
  else
    fail "accessibility: $level missing"
  fi
done

# Critical patterns
for pattern in "html lang\|lang=\"" "alt=\"" "aria-label" "focus-visible"; do
  pat_clean=$(echo "$pattern" | sed 's/\\|/|/g')
  if grep -qE "$pat_clean" "$A11Y"; then
    ok "accessibility: pattern '$pattern' covered"
  else
    fail "accessibility: pattern '$pattern' missing"
  fi
done

# Manual checks
if grep -qE "Manual checks|manual mandatory" "$A11Y"; then
  ok "accessibility: manual checks documented"
else
  fail "accessibility: manual checks missing"
fi

# ── L2 — references/seo.md (Next.js metadata API) ────────────────────
echo ""
echo "L2 — references/seo.md"

SEO="$SKILL_DIR/references/seo.md"

# Next.js metadata API (App Router)
if grep -qE "metadata API|metadata: Metadata|generateMetadata" "$SEO"; then
  ok "seo: Next.js metadata API"
else
  fail "seo: metadata API missing"
fi

# app/sitemap.ts + app/robots.ts
for file in "app/sitemap.ts" "app/robots.ts"; do
  if grep -q "$file" "$SEO"; then
    ok "seo: $file documented"
  else
    fail "seo: $file missing"
  fi
done

# Title + description targets
if grep -qE "50-60 chars|150-160 chars" "$SEO"; then
  ok "seo: title/description char limits"
else
  fail "seo: char limits missing"
fi

# Structured data (JSON-LD)
if grep -qE "JSON-LD|structured data|schema\.org" "$SEO"; then
  ok "seo: JSON-LD structured data"
else
  fail "seo: JSON-LD missing"
fi

# Open Graph + Twitter Cards
if grep -qE "openGraph|Open Graph" "$SEO"; then
  ok "seo: Open Graph"
else
  fail "seo: Open Graph missing"
fi

# Manual SEO checks
if grep -qE "Manual SEO checks|manual checklist" "$SEO"; then
  ok "seo: manual checks documented"
else
  fail "seo: manual checks missing"
fi

# ── L2 — references/best-practices.md (NEW) ──────────────────────────
echo ""
echo "L2 — references/best-practices.md"

BP="$SKILL_DIR/references/best-practices.md"

# Security section
for sec in "HTTPS" "CSP" "npm audit" "source maps" "secrets"; do
  if grep -qiE "$sec" "$BP"; then
    ok "best-practices: section '$sec'"
  else
    fail "best-practices: section '$sec' missing"
  fi
done

# Modern Standards
for mod in "HTML5" "viewport" "deprecated" "passive event"; do
  if grep -qiE "$mod" "$BP"; then
    ok "best-practices: modern '$mod'"
  else
    fail "best-practices: modern '$mod' missing"
  fi
done

# Code Quality
for cq in "console" "semantic" "Error Boundar" "memory cleanup"; do
  if grep -qiE "$cq" "$BP"; then
    ok "best-practices: code quality '$cq'"
  else
    fail "best-practices: '$cq' missing"
  fi
done

# Forja-specific (brand.css + brand.json checks)
if grep -qE "brand\.css|brand/brand\.css" "$BP"; then
  ok "best-practices: brand/brand.css check"
else
  fail "best-practices: brand.css check missing"
fi

if grep -qE "brand\.json.*NO|NO.*brand\.json|brand\.json.*cliente" "$BP"; then
  ok "best-practices: brand.json NO en cliente check"
else
  fail "best-practices: brand.json check missing"
fi

# CSP headers config (use -- separator due to -- in regex possible)
if grep -qE "default-src|script-src" "$BP"; then
  ok "best-practices: CSP headers documented"
else
  fail "best-practices: CSP missing"
fi

# ── L2 — references/audit-mode-rationale.md (D-015 + L-004) ──────────
echo ""
echo "L2 — audit-mode-rationale.md (D-015 + L-004)"

AMR="$SKILL_DIR/references/audit-mode-rationale.md"

# L-004 cited
if grep -q "L-004" "$AMR"; then
  ok "audit-mode-rationale: L-004 cited"
else
  fail "audit-mode-rationale: L-004 missing"
fi

# D-015 cited
if grep -q "D-015" "$AMR"; then
  ok "audit-mode-rationale: D-015 cited"
else
  fail "audit-mode-rationale: D-015 missing"
fi

# D-014 refinement
if grep -q "D-014" "$AMR"; then
  ok "audit-mode-rationale: D-014 refinement context"
else
  fail "audit-mode-rationale: D-014 missing"
fi

# Binary outcome documented
if grep -qiE "binary|BINARY" "$AMR"; then
  ok "audit-mode-rationale: binary outcome"
else
  fail "audit-mode-rationale: binary missing"
fi

# Refinement doctrine declared
if grep -qE "[Rr]efinamiento|refinamiento|refines doctrine|refina.*doctrine" "$AMR"; then
  ok "audit-mode-rationale: D-014 doctrine refinement"
else
  fail "audit-mode-rationale: refinement missing"
fi

# 7 ADRs cross-cited (D-009 → D-015)
for adr in "D-009" "D-010" "D-011" "D-012" "D-013" "D-014" "D-015"; do
  if grep -q "$adr" "$AMR"; then
    ok "audit-mode-rationale: $adr cross-cited"
  else
    fail "audit-mode-rationale: $adr missing"
  fi
done

# Distinción "tener selector" key principle
if grep -qE "selector presence|tiene un selector|presencia.*selector|selector entre N" "$AMR"; then
  ok "audit-mode-rationale: 'tiene selector' principle"
else
  fail "audit-mode-rationale: selector principle missing"
fi

# ── L3 — Mental dry-run de los 6 escenarios canónicos ────────────────
echo ""
echo "L3 — 6 escenarios canónicos S1-S6"

# S1: PREFLIGHT — detección suave de src/ o pages/
if grep -qE "src/|pages/" "$SKILL"; then
  ok "L3 S1: PREFLIGHT detección src/ pages/"
else
  fail "L3 S1: PREFLIGHT detection missing"
fi

if grep -qE "halt informativo|halt: \"no parece" "$SKILL"; then
  ok "L3 S1: halt informativo (suave, no halt duro)"
else
  fail "L3 S1: halt suave missing"
fi

# S2: Mode selector presentation (live vs static)
if grep -qE "preguntar.*usuario|UNA pregunta.*live|live.*static" "$SKILL"; then
  ok "L3 S2: mode selector presentation al usuario"
else
  fail "L3 S2: selector presentation missing"
fi

# S3: Live audit menciona agent-browser + R13 (window -A30 — agent-browser está ~17 lines after Mode LIVE header)
if grep -A30 -E "Mode LIVE|LIVE — protocolo|live audit" "$RA" | grep -qE "agent-browser|find-docs|R13"; then
  ok "L3 S3: live audit menciona agent-browser + R13"
else
  fail "L3 S3: live audit R13 missing"
fi

# S4: Static analysis fallback graceful sin PAUSE
if grep -qE "graceful.*sin PAUSE|fallback graceful|NO halt.*static|static.*always available|SIEMPRE disponible" "$AMR" "$SKILL"; then
  ok "L3 S4: static fallback graceful sin PAUSE"
else
  fail "L3 S4: static fallback missing"
fi

# S5: Report format — 4 categorías + severity + checklist pre-deploy
if grep -qE "Performance.*Accessibility.*SEO.*Best Practices" "$BR" || \
   (grep -q "Performance" "$BR" && grep -q "Accessibility" "$BR" && grep -q "SEO" "$BR" && grep -q "Best Practices" "$BR"); then
  ok "L3 S5: 4 categorías en report"
else
  fail "L3 S5: 4 categorías missing"
fi

if grep -q "Checklist Pre-Deploy" "$BR"; then
  ok "L3 S5: checklist pre-deploy"
else
  fail "L3 S5: checklist missing"
fi

# S6: Score targets present (Performance ≥90, A11y 100, BP ≥95, SEO ≥95)
if grep -qE "≥ ?90.*Performance|Performance.*≥ ?90|Performance.*90" "$SKILL"; then
  ok "L3 S6: Performance ≥90 target"
else
  fail "L3 S6: Performance target missing"
fi

if grep -qE "Accessibility.*100|100.*Accessibility" "$SKILL"; then
  ok "L3 S6: Accessibility 100 target"
else
  fail "L3 S6: A11y 100 target missing"
fi

if grep -qE "Best Practices.*≥ ?95|≥ ?95.*Best" "$SKILL"; then
  ok "L3 S6: Best Practices ≥95 target"
else
  fail "L3 S6: BP target missing"
fi

if grep -qE "SEO.*≥ ?95|≥ ?95.*SEO" "$SKILL"; then
  ok "L3 S6: SEO ≥95 target"
else
  fail "L3 S6: SEO target missing"
fi

# ── L3 — D-015 binary application + scoreboard final ─────────────────
echo ""
echo "L3 — D-015 binary application + scoreboard final"

# D-015 confirma binary (case-insensitive, "confirm" cubre confirmed/confirmado)
if grep -qiE "binary.*confirm|confirm.*binary" "$AMR"; then
  ok "L3 D-015: binary confirmed"
else
  fail "L3 D-015: binary confirmation missing"
fi

# 7 ADRs scoreboard table
sb_count=$(grep -cE "D-00[9]|D-01[0-5]" "$AMR")
if [ "$sb_count" -ge 7 ]; then
  ok "L3 D-015: scoreboard 7 ADRs ($sb_count refs)"
else
  fail "L3 D-015: scoreboard incomplete ($sb_count refs)"
fi

# 4 binary + 2 trinary + 1 boundary explicit
if grep -qE "Binary \(4\)|4 binary|D-009.*D-012.*D-013.*D-015" "$AMR"; then
  ok "L3 D-015: 4 binary cases enumerated"
else
  # buscar de manera más laxa
  if grep -E "Binary" "$AMR" | grep -qE "D-009"; then
    ok "L3 D-015: binary cases enumerated"
  else
    fail "L3 D-015: 4 binary missing"
  fi
fi

if grep -qE "Trinary \(2\)|2 trinary|D-010.*D-011" "$AMR"; then
  ok "L3 D-015: 2 trinary cases enumerated"
else
  fail "L3 D-015: 2 trinary missing"
fi

# D-014 boundary case
if grep -qE "Boundary case|boundary.*D-014|D-014.*boundary|boundary \(1\)" "$AMR"; then
  ok "L3 D-015: D-014 boundary case in scoreboard"
else
  fail "L3 D-015: boundary case missing"
fi

# Selector presence as definitive principle
if grep -qE "selector presence|presencia.*selector.*determina|presence.*determina|si y solo si" "$AMR"; then
  ok "L3 D-015: selector presence as definitive principle"
else
  fail "L3 D-015: definitive principle missing"
fi

# ── L3 — agent-browser default D4 enforcement ────────────────────────
echo ""
echo "L3 — agent-browser default D4 enforcement"

# Default D4 documentado
if grep -qE "D4|Default Forja D4|default.*D4" "$SKILL" "$PERF"; then
  ok "L3 D4: default D4 documented"
else
  fail "L3 D4: D4 missing"
fi

# Playwright NO default
if grep -qE "NO Playwright|Playwright.*opcional|opcional.*Playwright" "$SKILL" "$PERF"; then
  ok "L3 D4: Playwright NOT default"
else
  fail "L3 D4: Playwright not-default boundary missing"
fi

# 4× ahorro tokens cited
if grep -qE "4× ahorro|~4×|4x ahorro" "$SKILL" "$PERF"; then
  ok "L3 D4: 4× tokens savings cited"
else
  fail "L3 D4: 4× savings missing"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✅ web-quality dry-run: ALL PASS ($PASS checks)"
  exit 0
else
  echo "❌ web-quality dry-run: $FAIL failures"
  exit 1
fi
