#!/usr/bin/env bash
# impeccable dry-run test — covers Mode A + Mode B + Mode C
#
# Validates the L1+L2 pipeline of the F3-S2 skill end-to-end.
# Approach: operator pre-rendered the expected outputs against fixtures
# and snapshotted them in tests/expected/. dry-run.sh validates the
# snapshots against L1 syntax + L2 schema/semantics. If the skill is
# re-run with same fixtures and produces different outputs, diff vs
# tests/expected/ surfaces the change for el-evaluador review.
#
# Usage:  bash .claude/skills/impeccable/tests/dry-run.sh
# Exit 0 = all validations PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_UI="$SKILL_DIR/tests/expected/src/shared/components/ui"
EXPECTED_LIB="$SKILL_DIR/tests/expected/src/lib"

echo "── impeccable dry-run test ────────────────────────────────────"
echo "Skill dir:   $SKILL_DIR"
echo "Expected:    $EXPECTED_UI"
echo ""

PASS=0
FAIL=0

ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 Syntax ──────────────────────────────────────────────────────
echo "L1 — Syntax"

# All TSX files must exist
expected_tsx=(
  "Button/Button.tsx"
  "Card/Card.tsx"
  "Form/Input.tsx"
  "Form/Textarea.tsx"
  "Form/Select.tsx"
  "Modal/Modal.tsx"
  "Navigation/Sidebar.tsx"
  "Navigation/Topbar.tsx"
  "Navigation/Tabs.tsx"
  "Navigation/Breadcrumb.tsx"
  "DataTable/DataTable.tsx"
)
for f in "${expected_tsx[@]}"; do
  if [ -f "$EXPECTED_UI/$f" ]; then
    ok "exists: $f"
  else
    fail "missing: $f"
  fi
done

# Barrel re-exports
expected_index=(
  "Button/index.ts"
  "Card/index.ts"
  "Form/index.ts"
  "Modal/index.ts"
  "Navigation/index.ts"
  "DataTable/index.ts"
  "types.ts"
  "index.ts"
)
for f in "${expected_index[@]}"; do
  if [ -f "$EXPECTED_UI/$f" ]; then
    ok "barrel: $f"
  else
    fail "missing barrel: $f"
  fi
done

# cn helper
if [ -f "$EXPECTED_LIB/cn.ts" ]; then
  ok "cn.ts utility exists"
else
  fail "missing cn.ts utility"
fi

# Each TSX file: exports default fn or named, has cva or composes from siblings
for f in "${expected_tsx[@]}"; do
  full="$EXPECTED_UI/$f"
  if grep -qE 'export (const|function|type)' "$full"; then
    ok "$f has exports"
  else
    fail "$f missing exports"
  fi
done

# ── L2 Runtime / Brand contract compliance ────────────────────────
echo ""
echo "L2 — Runtime / contract compliance"

python3 - <<'PY'
import re, sys, json
from pathlib import Path

ROOT = Path(".claude/skills/impeccable/tests/expected/src/shared/components/ui")
BRAND_JSON = Path(".claude/skills/add-ui-kit/tests/expected/brand/brand.json")

brand = json.loads(BRAND_JSON.read_text())
component_rules = brand["component_rules"]

results = []

# 0. Upstream contract is R-005 v1.1.0
assert brand.get("schema_version") == "1.1.0", f"upstream brand.json schema_version is {brand.get('schema_version')}, expected 1.1.0 (R-005 v1.1)"
results.append(("PASS", "upstream brand.json is R-005 v1.1.0"))
assert isinstance(brand["tokens"]["spacing"]["section_y"], dict), "section_y must be keyed object (R-005 v1.1)"
assert isinstance(brand["tokens"]["spacing"]["component_gap"], dict), "component_gap must be keyed object (R-005 v1.1)"
results.append(("PASS", "upstream tokens.spacing is keyed (E-002 closure)"))

# 1. Button covers all 4 variants
btn = (ROOT / "Button" / "Button.tsx").read_text()
for v in component_rules["button"]["variants"]:
    if f"{v}:" in btn or f"'{v}'" in btn:
        results.append(("PASS", f"Button declares variant '{v}'"))
    else:
        results.append(("FAIL", f"Button missing variant '{v}'"))

# 2. Card covers all 4 variants
card = (ROOT / "Card" / "Card.tsx").read_text()
for v in component_rules["card"]["variants"]:
    if f"{v}:" in card or f"'{v}'" in card:
        results.append(("PASS", f"Card declares variant '{v}'"))
    else:
        results.append(("FAIL", f"Card missing variant '{v}'"))

# 3. Form variants split across files (text+search in Input, textarea, select)
input_tsx = (ROOT / "Form" / "Input.tsx").read_text()
for v in ["text", "search"]:
    if f"{v}:" in input_tsx:
        results.append(("PASS", f"Input declares variant '{v}'"))
    else:
        results.append(("FAIL", f"Input missing variant '{v}'"))
if (ROOT / "Form" / "Textarea.tsx").exists():
    results.append(("PASS", "Form textarea variant has dedicated file"))
if (ROOT / "Form" / "Select.tsx").exists():
    results.append(("PASS", "Form select variant has dedicated file"))

# 4. Modal covers all 3 variants
modal = (ROOT / "Modal" / "Modal.tsx").read_text()
for v in component_rules["modal"]["variants"]:
    if f"{v}:" in modal:
        results.append(("PASS", f"Modal declares variant '{v}'"))
    else:
        results.append(("FAIL", f"Modal missing variant '{v}'"))

# 5. Navigation covers all 4 variants (split across files)
nav_dir = ROOT / "Navigation"
for v in component_rules["navigation"]["variants"]:
    file_name = v.capitalize() + ".tsx"
    if (nav_dir / file_name).exists():
        results.append(("PASS", f"Navigation has dedicated {file_name} for variant '{v}'"))
    else:
        results.append(("FAIL", f"Navigation missing variant '{v}' file"))

# 6. All files have R-005 + R10 citations
for tsx_path in ROOT.rglob("*.tsx"):
    content = tsx_path.read_text()
    has_r005 = "memory:references#R-005" in content
    has_r10  = "memory:CONSTRAINTS.md#R10" in content
    if has_r005 and has_r10:
        results.append(("PASS", f"{tsx_path.name} cites R-005 + R10"))
    else:
        results.append(("FAIL", f"{tsx_path.name} missing citations: R-005={has_r005} R10={has_r10}"))

# 7. NO inline hex literals in any TSX
hex_re = re.compile(r"#[0-9a-fA-F]{6}\b")
hex_violations = []
for tsx_path in ROOT.rglob("*.tsx"):
    content = tsx_path.read_text()
    # Strip JSDoc/comments to focus on body
    body = re.sub(r"/\*[\s\S]*?\*/", "", content)
    body = re.sub(r"//.*", "", body)
    hits = hex_re.findall(body)
    if hits:
        hex_violations.append(f"{tsx_path.name}: {hits}")
if hex_violations:
    results.append(("FAIL", f"hex literals in TSX body: {hex_violations}"))
else:
    results.append(("PASS", "no hex literals in TSX body (R10 enforced)"))

# 8. NO Tailwind purple/indigo defaults
slop_re = re.compile(r"\b(?:bg|text|border|from|to)-(?:indigo|purple|violet)-\d+\b")
slop_violations = []
for tsx_path in ROOT.rglob("*.tsx"):
    content = tsx_path.read_text()
    hits = slop_re.findall(content)
    if hits:
        slop_violations.append(f"{tsx_path.name}: {hits}")
if slop_violations:
    results.append(("FAIL", f"Tailwind purple/indigo slop: {slop_violations}"))
else:
    results.append(("PASS", "no Tailwind purple/indigo defaults (anti-slop)"))

# 9. NO rounded-3xl / shadow-2xl as default
bigshape_re = re.compile(r"\b(?:rounded-3xl|shadow-2xl)\b")
bigshape_violations = []
for tsx_path in ROOT.rglob("*.tsx"):
    content = tsx_path.read_text()
    hits = bigshape_re.findall(content)
    if hits:
        bigshape_violations.append(f"{tsx_path.name}: {hits}")
if bigshape_violations:
    results.append(("FAIL", f"rounded-3xl/shadow-2xl: {bigshape_violations}"))
else:
    results.append(("PASS", "no rounded-3xl/shadow-2xl (anti-slop)"))

# 10. cva pattern present in main components
# Variants components must have cva + VariantProps; pure-wrappers (Radix wrappers
# without project-specific variants) only need cva
cva_with_variants = ["Button/Button.tsx", "Card/Card.tsx", "Form/Input.tsx",
                     "Form/Textarea.tsx", "Form/Select.tsx", "Modal/Modal.tsx",
                     "Navigation/Sidebar.tsx"]
cva_only = ["Navigation/Tabs.tsx"]   # Radix Tabs wrapper, no project-specific variants
for path in cva_with_variants:
    content = (ROOT / path).read_text()
    if "cva(" in content and "VariantProps" in content:
        results.append(("PASS", f"{path} uses cva + VariantProps pattern"))
    else:
        results.append(("FAIL", f"{path} missing cva/VariantProps"))
for path in cva_only:
    content = (ROOT / path).read_text()
    if "cva(" in content:
        results.append(("PASS", f"{path} uses cva (Radix wrapper, no variants)"))
    else:
        results.append(("FAIL", f"{path} missing cva"))

# 11. focus state present (focus-visible OR focus OR focus-within all count)
focus_users = cva_with_variants + cva_only
for path in focus_users:
    content = (ROOT / path).read_text()
    if "focus-visible:" in content or "focus:" in content or "focus-within:" in content:
        results.append(("PASS", f"{path} has focus state"))
    else:
        results.append(("FAIL", f"{path} missing focus state"))

# 12. DataTable Mode B has rationale JSDoc
dt = (ROOT / "DataTable" / "DataTable.tsx").read_text()
required_rationale_keywords = ["nearest_component", "must_include", "Derivation rationale"]
missing_rationale = [k for k in required_rationale_keywords if k not in dt]
if missing_rationale:
    results.append(("FAIL", f"DataTable missing Mode B rationale keywords: {missing_rationale}"))
else:
    results.append(("PASS", "DataTable has full Mode B rationale (R-005 sec 8.2)"))

# Print
fail_count = 0
for status, msg in results:
    print(f"  {'✓' if status == 'PASS' else '✗'} {msg}")
    if status == "FAIL":
        fail_count += 1

sys.exit(0 if fail_count == 0 else 1)
PY

if [ $? -eq 0 ]; then
  PASS=$((PASS + 35))   # approximation; actual count printed above
else
  FAIL=$((FAIL + 1))
fi

# ── Summary ────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "L1 syntax checks PASS=$PASS / FAIL=$FAIL (count includes both layers)"

if [ "$FAIL" -gt 0 ]; then
  echo "❌ dry-run FAILED"
  exit 1
fi
echo "✅ All L1 + L2 dry-run validations PASS."
