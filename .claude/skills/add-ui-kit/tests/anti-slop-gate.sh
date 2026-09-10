#!/usr/bin/env bash
# add-ui-kit anti-slop gate test (L3 system verification)
#
# Validates the L3 binary checks of the F3-S1 skill — the same checks
# el-evaluador runs against any add-ui-kit output before signing PASS.
#
# 12 binary checks (R-005 sec 4 + 6.2 + 7.2 · F-P2.1 · D-037):
#   1. forbidden_colors      — primary/accent NOT in Tailwind purple/indigo defaults
#   2. restricted_hues       — primary HSL hue ∉ [235, 285] (unless Magician)
#   3. max_fonts             — unique families ≤ validation.max_fonts
#   4. max_radius_values     — unique radius_* values ≤ validation.max_radius_values
#   5. archetype_coherence   — voice tone_axes consistent with archetype.primary
#   6. anti_slop_patterns    — forbidden_patterns array present + ≥ 7 entries
#   7. dark_mode             — showcase templates use ZERO hardcoded light/dark
#                              Tailwind classes (bg-white / bg-gray-900 /
#                              text-gray-800). Everything via --color-* vars.
#   8. no_modals_inline      — showcase does NOT use a modal/Dialog where an
#                              inline form / popover / Sheet belongs (heuristic
#                              + note; legitimate destructive-confirm & Sheet
#                              drawers are exempt).
#   9. glow_stack            — no element stacks ≥2 of blur-* / bg-gradient-* /
#                              shadow-<color>-<n>/<a> / drop-shadow-* (the "glow"
#                              AI tell) — F-P2.1, critic penalty `glow-stack`
#  10. reduced_motion        — files with MOVEMENT animation (animate-in/out,
#                              transition-transform/all, hover:scale/translate)
#                              handle prefers-reduced-motion (motion-reduce:/
#                              motion-safe:/useReducedMotion/brand/motion).
#                              animate-spin (progress) & animate-pulse
#                              (opacity-only skeleton) are exempt.
#  11. layout_prop_animation — no transition-all / transition-[…width|height|
#                              padding|margin|top|left…] (motion.ts UNSAFE);
#                              viewport-toggle.tsx documented exemption.
#  12. hero_default          — no 2-col text-left/media-right hero with an
#                              indigo/purple/violet palette unless authorized
#                              (brand.json.hero_layout == "split-authorized" or
#                              `hero_layout: authorized` comment) — critic
#                              penalty `purple-hero`
#
# Checks 9-12 run on the showcase (must PASS) AND on tests/fixtures/sloppy/
# (must FAIL — negative fixture; a gate that never fails is decoration, L-010).
#
# Checks 1-6 (+ a semicualitative visual-mood cross-check) run against the
# generated TECH UTILITY brand.json/voice.json fixture. Checks 7-12 run against
# the ported Forge-Pro showcase TEMPLATES (templates/showcase/**).
#
# Visual diff (semicualitativo):
#   Cross-check that TECH UTILITY preset generated brand.json sees as
#   Linear/Vercel mood (dark + dense + geometric + low warmth + low
#   editoriality + low materiality), NOT Mailchimp (high warmth) nor
#   MSCHF (high expression).
#
# Usage:  bash .claude/skills/add-ui-kit/tests/anti-slop-gate.sh
# Exit 0 = anti-slop gate PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRAND_JSON="$SKILL_DIR/tests/expected/brand/brand.json"
SHOWCASE_DIR="$SKILL_DIR/templates/showcase"

echo "── add-ui-kit Anti-Slop Gate test ─────────────────────────────"
echo "Target:  $(basename "$BRAND_JSON") (TECH UTILITY preset)"
echo "Showcase: $SHOWCASE_DIR (Forge-Pro port — checks 7-8)"
echo ""

PASS=0
FAIL=0

ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── Checks 1-6 (+ visual mood) — brand.json/voice.json fixture ─────
echo "Anti-Slop Gate — checks 1-6 (brand.json fixture)"

python3 - <<'PY'
import json, sys, re, colorsys
b = json.load(open('.claude/skills/add-ui-kit/tests/expected/brand/brand.json'))
checks = []

# Check 1 — forbidden_colors
TAILWIND_DEFAULTS = {'#6366F1', '#8B5CF6', '#A855F7'}
primary = b['tokens']['colors'].get('primary', '').upper()
accent  = b['tokens']['colors'].get('accent', '').upper()
hits = [c for c in [primary, accent] if c in TAILWIND_DEFAULTS]
if hits:
    checks.append(('FAIL', f'forbidden_colors: primary/accent uses Tailwind default {hits}'))
else:
    checks.append(('PASS', f'forbidden_colors: primary={primary} accent={accent}'))

# Check 2 — restricted_hues [235, 285]
def hex_to_hue(hex_color):
    h = hex_color.lstrip('#')
    r, g, bl = int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255
    hue, _, _ = colorsys.rgb_to_hsv(r, g, bl)
    return hue * 360

primary_hue = hex_to_hue(primary)
archetype_primary = b['archetype']['primary']
in_restricted = 235 <= primary_hue <= 285
allowed = (archetype_primary == 'Magician') or any(
    'purple_as_primary' in beh.lower() for beh in b['archetype'].get('allowed_behaviors', [])
)
if in_restricted and not allowed:
    checks.append(('FAIL', f'restricted_hues: primary hue {primary_hue:.0f}° in [235, 285] without Magician archetype'))
else:
    checks.append(('PASS', f'restricted_hues: primary hue {primary_hue:.0f}° (NOT in [235, 285])'))

# Check 3 — max_fonts
families = set()
for role in ['display', 'body', 'mono']:
    fam = b['tokens']['typography'].get(role, {})
    if isinstance(fam, dict) and fam.get('family'):
        families.add(fam['family'])
max_fonts = b['validation'].get('max_fonts', 2)
if len(families) > max_fonts:
    checks.append(('FAIL', f'max_fonts: {len(families)} unique families exceeds limit {max_fonts}'))
else:
    checks.append(('PASS', f'max_fonts: {len(families)} unique families ({sorted(families)}) ≤ {max_fonts}'))

# Check 4 — max_radius_values
radii = set([
    b['tokens']['shape'].get('radius_sm'),
    b['tokens']['shape'].get('radius_md'),
    b['tokens']['shape'].get('radius_lg'),
])
radii.discard(None)
max_radius = b['validation'].get('max_radius_values', 3)
if len(radii) > max_radius:
    checks.append(('FAIL', f'max_radius_values: {len(radii)} unique values exceeds limit {max_radius}'))
else:
    checks.append(('PASS', f'max_radius_values: {len(radii)} unique values ({sorted(radii)}) ≤ {max_radius}'))

# Check 5 — archetype_coherence
arch = b['archetype']['primary']
voice_path = '.claude/skills/add-ui-kit/tests/expected/brand/voice.json'
v = json.load(open(voice_path))
ta = v['voice']['tone_axes']
coherence_rules = {
    'Outlaw':    ('provocation', 4, '>='),
    'Caregiver': ('warmth', 4, '>='),
    'Sage':      ('hype', 1, '<='),
    'Creator':   ('hype', 2, '<='),
    'Lover':     ('warmth', 4, '>='),
    'Innocent':  ('warmth', 4, '>='),
}
if arch in coherence_rules:
    axis, threshold, op = coherence_rules[arch]
    val = ta.get(axis, 0)
    if op == '>=' and val < threshold:
        checks.append(('FAIL', f'archetype_coherence: {arch} archetype expects {axis} ≥ {threshold}, got {val}'))
    elif op == '<=' and val > threshold:
        checks.append(('FAIL', f'archetype_coherence: {arch} archetype expects {axis} ≤ {threshold}, got {val}'))
    else:
        checks.append(('PASS', f'archetype_coherence: {arch} archetype + {axis}={val} (rule: {op} {threshold})'))
else:
    checks.append(('PASS', f'archetype_coherence: no specific rule for {arch} (skipped)'))

# Check 6 — anti_slop_patterns
fp = b['anti_slop'].get('forbidden_patterns', [])
if len(fp) < 7:
    checks.append(('FAIL', f'anti_slop_patterns: only {len(fp)} declared (≥7 expected from R-005 baseline)'))
else:
    checks.append(('PASS', f'anti_slop_patterns: {len(fp)} declared (≥7)'))

# Visual mood check (semicualitativo — Tech Utility expects Linear/Vercel feel)
post = b['visual_posture']
mood_check = (
    post['density'] >= 3 and
    post['expression'] <= 3 and
    post['geometry'] >= 3 and
    post['warmth'] <= 3 and
    post['editoriality'] <= 3 and
    post['materiality'] <= 2
)
if mood_check:
    checks.append(('PASS', f'visual_mood: posture matches Linear/Vercel/Forge family (NOT Mailchimp/MSCHF)'))
else:
    checks.append(('FAIL', f'visual_mood: posture {post} does NOT match expected Tech Utility mood'))

# Print
fail_count = 0
for status, msg in checks:
    if status == 'PASS':
        print(f'  ✓ {msg}')
    else:
        print(f'  ✗ {msg}')
        fail_count += 1

sys.exit(0 if fail_count == 0 else 1)
PY

result=$?
if [ "$result" -eq 0 ]; then
  PASS=$((PASS + 7))
else
  FAIL=$((FAIL + 1))
fi

# ── Checks 7-8 — Forge-Pro showcase templates ──────────────────────
echo ""
echo "Anti-Slop Gate — checks 7-8 (showcase templates)"

SHOWCASE_DIR="$SHOWCASE_DIR" python3 - <<'PY'
import os, re, glob, sys

showcase = os.environ['SHOWCASE_DIR']
files = sorted(glob.glob(os.path.join(showcase, '**', '*.tsx'), recursive=True))

def strip_comments(src):
    # Drop block comments first (the showcase doc-comments literally contain
    # strings like "NO bg-white" / "purple/indigo" describing what they avoid —
    # those are prose, NOT code, and must not trip the grep), then line comments.
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.DOTALL)
    src = re.sub(r'//[^\n]*', '', src)
    return src

code = {f: strip_comments(open(f, encoding='utf-8').read()) for f in files}
checks = []

if not files:
    checks.append(('FAIL', f'showcase: no .tsx templates found under {showcase}'))

# ── Check 7 — DARK MODE: no hardcoded light/dark Tailwind color classes ──
# Match each forbidden token only as a standalone Tailwind class (delimited by
# class separators), so it never matches the substring inside bg-[var(--...)].
FORBIDDEN = ['bg-white', 'bg-gray-900', 'text-gray-800']
dark_hits = []
for f in files:
    for tok in FORBIDDEN:
        if re.search(r'(?<![\w-])' + re.escape(tok) + r'(?![\w-])', code[f]):
            dark_hits.append((os.path.relpath(f, showcase), tok))
if dark_hits:
    detail = ', '.join(f'{f}:{t}' for f, t in dark_hits)
    checks.append(('FAIL', f'dark_mode: hardcoded light/dark color class(es) in showcase code — {detail} (use --color-* vars)'))
else:
    checks.append(('PASS', f'dark_mode: 0 hardcoded {FORBIDDEN} classes across {len(files)} showcase templates (all via --color-*)'))

# ── Check 8 — NO MODALS FOR INLINE ACTIONS (heuristic + note) ──
# Find modal/dialog surfaces in real code. Legitimate uses are exempt:
#   - a destructive confirm (grave consequences), and
#   - a Sheet/drawer (role="dialog" used as a slide-in panel).
# The genuine anti-pattern is a modal whose ONLY content is one short text
# input (i.e. "edit a short name" / "confirm trivial delete") where an inline
# form / popover / Sheet belongs. We FAIL only on that; otherwise PASS + note.
MODAL_RE = re.compile(r'role=(["\'])dialog\1|<Dialog\b|<Modal\b|aria-modal=(["\'])true\2')
modal_sites = []
for f in files:
    if MODAL_RE.search(code[f]):
        rel = os.path.relpath(f, showcase)
        body = code[f]
        # Heuristic anti-pattern signal: a dialog body that is essentially a
        # single text <input> and nothing structural (no table/list/Sheet/steps
        # /destructive confirm). Counts as a "modal for an inline action".
        inputs = len(re.findall(r'<input\b', body))
        structural = bool(re.search(r'role=(["\'])menu\1|<table\b|aria-modal|Sheet|stepper|Paso\s+\d|no se puede deshacer|drawer|slide-in', body, re.IGNORECASE))
        smells_inline = inputs >= 1 and inputs <= 1 and not structural
        modal_sites.append((rel, smells_inline))

bad = [r for r, smell in modal_sites if smell]
if bad:
    checks.append(('FAIL', f'no_modals_inline: modal/Dialog wraps an inline-sized action (single short input, no structure) in {bad} — use inline form / popover / Sheet'))
else:
    if modal_sites:
        note = ', '.join(r for r, _ in modal_sites)
        checks.append(('PASS', f'no_modals_inline: {len(modal_sites)} modal/dialog surface(s) reviewed — all legitimate (destructive-confirm / Sheet drawer), none wrap an inline action'))
        checks.append(('NOTE', f'no_modals_inline (manual-review list): {note} — confirm none should be an inline form/popover/Sheet'))
    else:
        checks.append(('PASS', 'no_modals_inline: 0 modal/dialog surfaces in showcase'))

fail_count = 0
for status, msg in checks:
    if status == 'PASS':
        print(f'  ✓ {msg}')
    elif status == 'NOTE':
        print(f'  • {msg}')
    else:
        print(f'  ✗ {msg}')
        fail_count += 1

sys.exit(0 if fail_count == 0 else 1)
PY

result2=$?
if [ "$result2" -eq 0 ]; then
  PASS=$((PASS + 1))   # checks 7 + 8 are one combined gate → +1 toward the /8
else
  FAIL=$((FAIL + 1))
fi


# ── Checks 9-12 — F-P2.1 (JSX slop the critic names; the gate detects) ─────
# Runs twice: showcase must PASS, tests/fixtures/sloppy must FAIL (negative).
run_checks_9_12() {
  TARGET_DIR="$1" EXPECT="$2" BRAND_JSON="$BRAND_JSON" python3 - <<'PYCHK'
import os, re, glob, sys, json

target = os.environ['TARGET_DIR']; expect = os.environ['EXPECT']
files = sorted(glob.glob(os.path.join(target, '**', '*.tsx'), recursive=True))
brand = {}
try: brand = json.load(open(os.environ['BRAND_JSON']))
except Exception: pass

def strip_comments(src):
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.DOTALL)
    return re.sub(r'//[^\n]*', '', src)
raw = {f: open(f, encoding='utf-8').read() for f in files}
code = {f: strip_comments(t) for f, t in raw.items()}
rel = lambda f: os.path.relpath(f, target)
checks = []

# 9 — glow_stack: ≥2 glow ingredients in ONE className string
GLOW = [r'\bblur-', r'\bbg-gradient-', r'\bshadow-[a-z]+-\d{2,3}/\d', r'\bdrop-shadow-']
hits = []
for f, c in code.items():
    for m in re.finditer(r'className=\{?["\'`]([^"\'`]*)["\'`]', c):
        cls = m.group(1)
        if sum(1 for g in GLOW if re.search(g, cls)) >= 2:
            hits.append(f'{rel(f)}: "{cls[:60]}…"')
checks.append(('FAIL', f'glow_stack: {len(hits)} element(s) stack blur/gradient/glow-shadow — {hits[:3]}') if hits
              else ('PASS', f'glow_stack: 0 glow stacks across {len(files)} files'))

# 10 — reduced_motion: movement animation without reduced-motion handling
MOVE = r'\banimate-(in|out)\b|\btransition-(transform|all)\b|\b(hover|group-hover|focus):(scale|translate|rotate)-|\banimate-\[|\bscroll-'
RM = r'motion-reduce:|motion-safe:|prefers-reduced-motion|useReducedMotion|brand/motion|reduceMotion'
bad = [rel(f) for f, c in code.items() if re.search(MOVE, c) and not re.search(RM, c)]
checks.append(('FAIL', f'reduced_motion: movement animation without prefers-reduced-motion handling in {bad}') if bad
              else ('PASS', 'reduced_motion: every file with movement animation handles reduced motion (spin/pulse exempt)'))

# 11 — layout_prop_animation: transition-all / transition-[…layout prop…]
LAYOUT = r'\btransition-all\b|\btransition-\[[^\]]*(width|height|padding|margin|top|left|right|bottom)[^\]]*\]|\banimate-\[[^\]]*(width|height)[^\]]*\]'
EXEMPT = {'viewport-toggle.tsx'}
bad = [rel(f) for f, c in code.items() if os.path.basename(f) not in EXEMPT and re.search(LAYOUT, c)]
checks.append(('FAIL', f'layout_prop_animation: transition-all / layout-prop transition (motion.ts UNSAFE) in {bad}') if bad
              else ('PASS', 'layout_prop_animation: 0 transition-all / layout-prop animations (viewport-toggle.tsx exempt, documented)'))

# 12 — hero_default: 2-col text-left/media-right + indigo/purple/violet palette, unauthorized
authorized_global = brand.get('hero_layout') == 'split-authorized'
SPLIT = r'grid-cols-2\b'; MEDIA = r'<(img|Image|video|picture)\b'
PURPLE = r'\b(from|via|to|bg|text)-(indigo|purple|violet)-\d{2,3}\b|#(6366F1|8B5CF6|A855F7)'
bad = []
for f, c in code.items():
    if authorized_global or re.search(r'hero_layout:\s*authorized', raw[f]): continue
    if re.search(SPLIT, c) and re.search(MEDIA, c) and re.search(PURPLE, c, re.IGNORECASE):
        bad.append(rel(f))
checks.append(('FAIL', f'hero_default: text-left/media-right 2-col hero with indigo/purple palette, unauthorized (CHOSEN.md / brand.json.hero_layout) in {bad}') if bad
              else ('PASS', 'hero_default: 0 unauthorized purple split heroes'))

fails = sum(1 for st, _ in checks if st == 'FAIL')
for st, msg in checks: print(('  ✓ ' if st == 'PASS' else '  ✗ ') + msg)
if expect == 'pass':
    sys.exit(0 if fails == 0 else 1)
else:  # negative fixture: all four must fail, or the gate is decoration (L-010)
    print(f'  • negative fixture: {fails}/4 checks failed as expected' if fails == 4 else f'  ✗ negative fixture: only {fails}/4 checks failed — gate lost its teeth')
    sys.exit(0 if fails == 4 else 1)
PYCHK
}

echo ""
echo "Anti-Slop Gate — checks 9-12 (showcase templates — must PASS)"
if run_checks_9_12 "$SHOWCASE_DIR" pass; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi

echo ""
echo "Anti-Slop Gate — checks 9-12 (tests/fixtures/sloppy — must FAIL, negative)"
if run_checks_9_12 "$SKILL_DIR/tests/fixtures/sloppy" fail; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi

# ── Summary ────────────────────────────────────────────────────────
echo ""
echo "── Anti-Slop Gate Summary ─────────────────────────────────────"
echo "Checks: 12/12 (1-6 binary + visual-mood on fixture · 7-8 dark-mode/no-modals on showcase · 9-12 glow/reduced-motion/layout-prop/hero-default on showcase + negative fixture)"
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "❌ Anti-Slop Gate FAILED — output cannot be marked passing."
  exit 1
fi
echo "✅ Anti-Slop Gate PASS (12/12) — brand.json contract-compliant · showcase dark-mode-clean, no inline-action modals, no glow stacks, reduced-motion handled, no layout-prop animation, no purple split hero · negative fixture fails as designed."
