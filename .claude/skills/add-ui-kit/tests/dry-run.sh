#!/usr/bin/env bash
# add-ui-kit dry-run test
#
# Validates the L1+L2 of the F3-S1 skill pipeline:
#   Discovery (fixture YAML) → 4 outputs (brand.json + voice.json + brand.css + showcase/page.tsx)
#
# This script does NOT call the live add-ui-kit skill (that requires the
# Claude harness). Instead, it validates the *expected* outputs that an
# operator pre-generated using the prompts + templates + lookup tables
# against the fixture, and stores them in tests/expected/. If the skill
# is re-run with the same fixture and produces different outputs, the
# diff against tests/expected/ will surface the change.
#
# Showcase template manifest (Forge-Pro port):
#   L1b asserts the SOURCE TEMPLATE files exist and parse (file present,
#   non-empty, top-level export):
#     - viewport-toggle.tsx, feedback-panel.tsx, actions.ts, page.tsx
#     - every Part 1 section the template page.tsx imports
#     - all 7 Part 2 saas-patterns
#     - COMPONENT_RULES.md.template
#   L1c asserts the RENDERED fixture under tests/expected/src/.../showcase/ is
#   complete + internally consistent after the Forge-Pro port (D-025): the
#   fixture page.tsx no longer references the deleted ComponentsSection, no
#   Mustache placeholder leaked through the render, and every module + section
#   the fixture page.tsx imports actually exists on disk (so the snapshot is
#   self-resolvable). The existing fixture-based L1/L2 checks (brand.json/
#   voice.json/brand.css + fixture page.tsx) stay intact.
#
# Usage:  bash .claude/skills/add-ui-kit/tests/dry-run.sh
# Exit 0 = all validations PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_DIR="$SKILL_DIR/tests/expected"
FIXTURE="$SKILL_DIR/tests/fixtures/discovery-tech-utility.yaml"

echo "── add-ui-kit dry-run test ────────────────────────────────────"
echo "Skill dir:   $SKILL_DIR"
echo "Fixture:     $(basename "$FIXTURE")"
echo "Expected:    $EXPECTED_DIR"
echo ""

PASS=0
FAIL=0

ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 Syntax ──────────────────────────────────────────────────────
echo "L1 — Syntax validation"

if python3 -c "import json; json.load(open('$EXPECTED_DIR/brand/brand.json'))" 2>/dev/null; then
  ok "brand.json parses as valid JSON"
else
  fail "brand.json JSON parse failed"
fi

if python3 -c "import json; json.load(open('$EXPECTED_DIR/brand/voice.json'))" 2>/dev/null; then
  ok "voice.json parses as valid JSON"
else
  fail "voice.json JSON parse failed"
fi

# CSS basic sanity
CSS_FILE="$EXPECTED_DIR/brand/brand.css"
OPENS=$(grep -c '{' "$CSS_FILE" || true)
CLOSES=$(grep -c '}' "$CSS_FILE" || true)
if [ "$OPENS" -eq "$CLOSES" ] && [ "$OPENS" -gt 0 ]; then
  ok "brand.css braces balanced ($OPENS blocks)"
else
  fail "brand.css braces mismatch ($OPENS opens vs $CLOSES closes)"
fi

# CSS variable count
VAR_COUNT=$(grep -c '^\s*--[a-z-]\+:' "$CSS_FILE" || true)
if [ "$VAR_COUNT" -ge 30 ]; then
  ok "brand.css declares $VAR_COUNT CSS vars (≥30 expected)"
else
  fail "brand.css declares only $VAR_COUNT CSS vars (≥30 expected)"
fi

# TSX basic checks (no full typecheck — skill is repo-template, no node_modules here)
TSX_FILE="$EXPECTED_DIR/src/app/(brand)/showcase/page.tsx"
if grep -q '^export default function BrandShowcasePage' "$TSX_FILE"; then
  ok "showcase page.tsx has default export"
else
  fail "showcase page.tsx missing default export"
fi

if grep -q "import '@/brand/brand.css'" "$TSX_FILE"; then
  ok "showcase imports brand.css"
else
  fail "showcase does NOT import brand.css (R10 violation)"
fi

# ── L1c — Rendered fixture completeness (Forge-Pro port, D-025) ─────
# The expected/ fixture is now a full render of the new showcase (not just
# page.tsx). Assert it is complete + internally consistent: no stale
# ComponentsSection, no leaked Mustache placeholder, and every module +
# section the fixture page.tsx imports exists on disk.
echo ""
echo "L1c — Rendered fixture completeness (tests/expected/src/.../showcase/**)"

FIX_DIR="$EXPECTED_DIR/src/app/(brand)/showcase"

# 1. The fixture page.tsx must NOT reference the DELETED ComponentsSection
#    (nor its old ./sections/components module).
if grep -qE 'ComponentsSection|sections/components' "$FIX_DIR/page.tsx"; then
  fail "fixture page.tsx still references the deleted ComponentsSection (stale snapshot)"
else
  ok "fixture page.tsx has no ComponentsSection / sections/components reference"
fi

# 2. No Mustache placeholder may survive in the rendered fixture. We look for
#    `{{ <brand|archetype|posture|tokens|motion|voice> ... }}` and explicitly
#    exclude the JSX `={{` / nested `{{` object-literal opener (style={{ … }}).
FIX_DIR="$FIX_DIR" python3 - <<'PY'
import os, re, glob, sys
fix = os.environ['FIX_DIR']
mustache = re.compile(r'(?<!\{)(?<!=)\{\{\s*(brand|archetype|posture|tokens|motion|voice)\b')
leftovers = []
for f in sorted(glob.glob(os.path.join(fix, '**', '*.tsx'), recursive=True)) + \
         sorted(glob.glob(os.path.join(fix, '*.ts'))):
    for ln, line in enumerate(open(f, encoding='utf-8').read().splitlines(), 1):
        if mustache.search(line):
            leftovers.append(f'{os.path.relpath(f, fix)}:{ln}')
sys.exit(1 if leftovers else 0)
PY
if [ $? -eq 0 ]; then
  ok "fixture has 0 unresolved Mustache placeholders (all {{ }} rendered)"
else
  fail "fixture still contains unresolved Mustache placeholder(s)"
fi

# 3. Every relative module the fixture page.tsx imports must exist on disk so
#    the snapshot is self-resolvable (the whole point of regenerating it).
FIX_DIR="$FIX_DIR" python3 - <<'PY'
import os, re, sys
fix = os.environ['FIX_DIR']
page = open(os.path.join(fix, 'page.tsx'), encoding='utf-8').read()
imports = re.findall(r"from '(\./[^']+)'", page)
missing = []
for imp in imports:
    if imp.endswith('brand.css'):
        continue
    base = os.path.normpath(os.path.join(fix, imp))
    if not (os.path.exists(base + '.tsx') or os.path.exists(base + '.ts')):
        missing.append(imp)
if missing:
    sys.stderr.write('missing: ' + ', '.join(missing) + '\n')
    sys.exit(1)
# Expect the post-port shape: 15 Part-1 sections + 7 saas-patterns + chrome.
sec = len([i for i in imports if i.startswith('./sections/') and '/saas-patterns/' not in i])
saas = len([i for i in imports if i.startswith('./sections/saas-patterns/')])
sys.exit(0 if (sec == 15 and saas == 7) else 2)
PY
rc=$?
if [ "$rc" -eq 0 ]; then
  ok "fixture page.tsx imports resolve on disk (15 Part-1 sections + 7 saas-patterns)"
elif [ "$rc" -eq 2 ]; then
  fail "fixture page.tsx import counts off (expected 15 sections + 7 saas-patterns)"
else
  fail "fixture page.tsx imports a module that does not exist on disk"
fi

# ── L1b — Showcase template manifest (Forge-Pro port) ───────────────
# Assert the SOURCE templates exist + parse, rather than rendering all 23
# files into the expected/ fixture (that's heavy — see header note).
echo ""
echo "L1b — Showcase template manifest (templates/showcase/**)"

TPL_DIR="$SKILL_DIR/templates/showcase"

# parse_ok — compiler-free "does it look like a real module" gate. There is no
# node_modules / tsc in the repo-template (see header + L1 note above), so we do
# NOT brace-count (TSX/JSX delimiters are not naively balanceable). Instead the
# gate is: file exists, is non-empty, and exposes a top-level `export`. Comments
# are stripped so a commented-out export never satisfies the check.
parse_ok() {
  local file="$1"
  python3 - "$file" <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
src = re.sub(r'/\*.*?\*/', '', src, flags=re.DOTALL)
src = re.sub(r'//[^\n]*', '', src)
sys.exit(0 if re.search(r'^\s*export\b', src, re.MULTILINE) else 1)
PY
}

assert_file_parses() {
  local rel="$1"; local label="$2"
  local f="$TPL_DIR/$rel"
  if [ ! -f "$f" ]; then
    fail "$label: $rel MISSING in showcase templates"
  elif [ ! -s "$f" ]; then
    fail "$label: $rel exists but is EMPTY"
  elif parse_ok "$f"; then
    ok "$label: $rel exists + non-empty + has a top-level export"
  else
    fail "$label: $rel exists but has NO top-level export (truncated/invalid)"
  fi
}

# Ported Forge-Pro pieces the new showcase wires up.
assert_file_parses "page.tsx"            "showcase entry"
assert_file_parses "viewport-toggle.tsx" "viewport toggle"
assert_file_parses "feedback-panel.tsx"  "feedback panel"
assert_file_parses "actions.ts"          "server actions"

# actions.ts must be a server-action module + export the 3 fns feedback-panel imports.
ACTIONS="$TPL_DIR/actions.ts"
if [ -f "$ACTIONS" ] && grep -q "'use server'" "$ACTIONS" \
   && grep -q 'export async function saveFeedback' "$ACTIONS" \
   && grep -q 'export async function readFeedback' "$ACTIONS" \
   && grep -q 'export async function clearFeedback' "$ACTIONS"; then
  ok "actions.ts: 'use server' + saveFeedback/readFeedback/clearFeedback exported"
else
  fail "actions.ts: missing 'use server' or one of saveFeedback/readFeedback/clearFeedback"
fi

# Part 1 — every section the template page.tsx imports must exist + parse.
# Derive the list from the page.tsx imports themselves (self-updating manifest).
PAGE="$TPL_DIR/page.tsx"
SECTION_IMPORTS=$(grep -oE "from '\./sections/[a-z-]+'" "$PAGE" | sed -E "s|from './sections/([a-z-]+)'|\1|" | sort -u || true)
SECTION_COUNT=$(printf '%s\n' "$SECTION_IMPORTS" | grep -c . || true)
if [ "$SECTION_COUNT" -ge 11 ]; then
  ok "page.tsx imports $SECTION_COUNT Part 1 sections (≥11 expected)"
else
  fail "page.tsx imports only $SECTION_COUNT Part 1 sections (≥11 expected)"
fi
section_fail=0
while IFS= read -r sec; do
  [ -z "$sec" ] && continue
  f="$TPL_DIR/sections/$sec.tsx"
  if [ -f "$f" ] && [ -s "$f" ] && parse_ok "$f"; then
    :
  else
    fail "Part 1 section sections/$sec.tsx MISSING / empty / no top-level export"
    section_fail=1
  fi
done <<< "$SECTION_IMPORTS"
if [ "$section_fail" -eq 0 ]; then
  ok "all $SECTION_COUNT imported Part 1 sections exist + have a top-level export"
fi

# Part 2 — the 7 saas-patterns must all exist + parse.
SAAS_DIR="$TPL_DIR/sections/saas-patterns"
EXPECTED_SAAS="auth-form data-table empty-complete kpi-row navbar onboarding sidebar"
saas_present=0
saas_fail=0
for p in $EXPECTED_SAAS; do
  f="$SAAS_DIR/$p.tsx"
  if [ -f "$f" ] && [ -s "$f" ] && parse_ok "$f"; then
    saas_present=$((saas_present + 1))
  else
    fail "saas-pattern $p.tsx MISSING / empty / no top-level export"
    saas_fail=1
  fi
done
if [ "$saas_fail" -eq 0 ] && [ "$saas_present" -eq 7 ]; then
  ok "all 7 Part 2 saas-patterns exist + have a top-level export ($EXPECTED_SAAS)"
fi

# COMPONENT_RULES.md.template (project-root contract emitted by the skill).
CR_TPL="$SKILL_DIR/templates/COMPONENT_RULES.md.template"
if [ -f "$CR_TPL" ] && [ -s "$CR_TPL" ]; then
  ok "COMPONENT_RULES.md.template exists (non-empty)"
else
  fail "COMPONENT_RULES.md.template MISSING or empty"
fi

# ── L2 Runtime semantics ───────────────────────────────────────────
echo ""
echo "L2 — Runtime / schema compliance"

# Required fields in brand.json
python3 - <<'PY'
import json, sys
b = json.load(open('.claude/skills/add-ui-kit/tests/expected/brand/brand.json'))
required = [
    ('schema_version', b.get('schema_version')),
    ('brand.name', b['brand'].get('name')),
    ('brand.product', b['brand'].get('product')),
    ('archetype.primary', b['archetype'].get('primary')),
    ('visual_posture.density', b['visual_posture'].get('density')),
    ('tokens.colors.primary', b['tokens']['colors'].get('primary')),
    ('tokens.colors.surface', b['tokens']['colors'].get('surface')),
    ('tokens.colors.text', b['tokens']['colors'].get('text')),
    ('tokens.typography.display.family', b['tokens']['typography']['display'].get('family')),
    ('tokens.typography.body.family', b['tokens']['typography']['body'].get('family')),
    ('tokens.shape.radius_md', b['tokens']['shape'].get('radius_md')),
    ('motion.personality.energy', b['motion']['personality'].get('energy')),
    ('anti_slop.forbidden_colors', b['anti_slop'].get('forbidden_colors')),
    ('validation.max_fonts', b['validation'].get('max_fonts')),
]
missing = [k for k, v in required if v is None]
if missing:
    print(f'  ✗ brand.json missing required fields: {missing}')
    sys.exit(1)
print(f'  ✓ brand.json has all 14 required fields')

# Bounded ranges
for axis in ['density', 'expression', 'geometry', 'warmth', 'editoriality', 'materiality']:
    v = b['visual_posture'][axis]
    assert 1 <= v <= 5, f'{axis}={v} out of range'
print('  ✓ visual_posture all 6 axes in [1, 5]')

# R-005 v1.1.0 schema compliance
assert b['schema_version'] == '1.1.0', f'schema_version is {b["schema_version"]}, expected 1.1.0'
print('  ✓ schema_version is 1.1.0 (R-005 v1.1)')

# Keyed spacing objects (E-002 closure)
section_y = b['tokens']['spacing']['section_y']
assert isinstance(section_y, dict), f'section_y is {type(section_y).__name__}, expected dict (R-005 v1.1)'
assert set(section_y.keys()) == {'sm', 'md', 'lg'}, f'section_y keys = {set(section_y.keys())}, expected sm/md/lg'
print(f'  ✓ tokens.spacing.section_y is keyed object (R-005 v1.1.0): {section_y}')

component_gap = b['tokens']['spacing']['component_gap']
assert isinstance(component_gap, dict), f'component_gap is {type(component_gap).__name__}, expected dict'
assert set(component_gap.keys()) == {'xs', 'sm', 'md', 'lg'}, f'component_gap keys = {set(component_gap.keys())}, expected xs/sm/md/lg'
print(f'  ✓ tokens.spacing.component_gap is keyed object (R-005 v1.1.0): {component_gap}')

# Motion enums (E-003 closure — schema-level whitelist per L-003)
MOTION_ENUMS = {
    'energy':         {'precise', 'calm', 'violent', 'ceremonial', 'mechanical'},
    'elasticity':     {'snap_not_bounce', 'bounce', 'glide', 'rigid'},
    'directionality': {'mechanical', 'organic', 'physical', 'abstract'},
    'sequencing':     {'subtle_stagger', 'uniform', 'cascaded', 'instant_all'},
    'distance':       {'short', 'medium', 'long'},
    'restraint':      {'high', 'medium', 'low'},
}
for dim, enum in MOTION_ENUMS.items():
    val = b['motion']['personality'][dim]
    assert val in enum, f'motion.personality.{dim} = "{val}" NOT in enum {enum}'
print(f'  ✓ motion.personality.* all 6 dimensions in R-005 v1.1.0 enums (closes E-003)')

# CSS vars 1:1 with tokens
import re
css = open('.claude/skills/add-ui-kit/tests/expected/brand/brand.css').read()
expected_vars = ['--color-primary', '--color-surface', '--color-text', '--color-success',
                 '--color-danger', '--color-warning', '--font-display', '--font-body',
                 '--radius-sm', '--radius-md', '--radius-lg',
                 '--space-unit', '--motion-duration-instant', '--motion-duration-fast',
                 '--motion-duration-base', '--motion-duration-slow', '--motion-easing']
for v in expected_vars:
    if not re.search(rf'^\s*{re.escape(v)}\s*:', css, re.MULTILINE):
        print(f'  ✗ brand.css missing required CSS var: {v}')
        sys.exit(1)
print(f'  ✓ brand.css contains all 17 required CSS vars')

# voice.json schema
v = json.load(open('.claude/skills/add-ui-kit/tests/expected/brand/voice.json'))
for axis in ['directness', 'warmth', 'technicality', 'provocation', 'hype']:
    val = v['voice']['tone_axes'][axis]
    assert 1 <= val <= 5, f'tone_axes.{axis}={val} out of range'
print('  ✓ voice.json tone_axes all 5 in [1, 5]')

baseline_avoid = {'revolutionary', 'cutting-edge', 'leverage', 'synergy', 'disrupt'}
present = set(v['voice']['avoid_words'])
if not baseline_avoid.issubset(present):
    print(f'  ✗ voice.json missing baseline avoid_words: {baseline_avoid - present}')
    sys.exit(1)
print('  ✓ voice.json avoid_words contains baseline canon')
PY
if [ $? -eq 0 ]; then PASS=$((PASS + 7)); else FAIL=$((FAIL + 1)); fi

# ── Summary ────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All L1+L2 validations PASS."
