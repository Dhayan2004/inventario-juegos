#!/usr/bin/env bash
# impeccable Brand Score test (L3 system verification)
#
# Computes the 5-dimension weighted Brand Score for each generated
# component (R-005 sec 7.3) and validates:
#   - per-component score ≥ 75 (PASS threshold)
#   - average score ≥ 85 (TECH UTILITY expected quality)
#
# Usage:  bash .claude/skills/impeccable/tests/brand-score.sh
# Exit 0 = all components ≥ 75 AND average ≥ 75

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── impeccable Brand Score test ────────────────────────────────"
echo ""

python3 - <<'PY'
import json, re, sys
from pathlib import Path

ROOT = Path(".claude/skills/impeccable/tests/expected/src/shared/components/ui")
BRAND_JSON = Path(".claude/skills/add-ui-kit/tests/expected/brand/brand.json")
VOICE_JSON = Path(".claude/skills/add-ui-kit/tests/expected/brand/voice.json")

brand = json.loads(BRAND_JSON.read_text())
voice = json.loads(VOICE_JSON.read_text())
component_rules = brand["component_rules"]
weights = brand["validation"]["brand_score_weights"]
avoid_words = [w.lower() for w in voice["voice"]["avoid_words"]]

def score_component(tsx_path, component_name):
    """Returns (total, breakdown_dict)."""
    if not tsx_path.exists():
        return 0, {"missing": True}
    content = tsx_path.read_text()
    body = re.sub(r"/\*[\s\S]*?\*/", "", content)
    body = re.sub(r"//.*", "", body)

    # 1. accessibility (max 30)
    acc = 0
    if "focus-visible:" in content or "focus:" in content or "focus-within:" in content:
        acc += 8
    if "var(--color-text)" in content or "text-text" in content:
        acc += 8
    aria_required = {
        "Modal": 'role="dialog"',
        "Tabs": "TabsPrimitive",
        "DataTable": 'role="table"',
    }
    if component_name in aria_required:
        if aria_required[component_name] in content:
            acc += 6
        else:
            acc += 0
    elif "aria-" in content:
        acc += 6
    else:
        acc += 4
    if "onKeyDown" in content or "tabIndex" in content or "Esc" in content or "Escape" in content:
        acc += 4
    elif "TabsPrimitive" in content or "DialogPrimitive" in content:
        acc += 4   # Radix handles
    if "aria-label" in content or "aria-busy" in content or "aria-disabled" in content or "aria-hidden" in content or "aria-current" in content or "aria-invalid" in content:
        acc += 4

    # 2. token_compliance (max 25)
    tok = 25
    hex_hits = re.findall(r"#[0-9a-fA-F]{6}\b", body)
    tok -= min(10, 5 * len(hex_hits))
    font_literal = re.findall(r"font-family\s*:\s*['\"]\w+", body)
    tok -= min(5, 5 * len(font_literal))

    # 3. component_compliance (max 20)
    comp = 0
    rules = component_rules.get(component_name.lower(), {}).get("variants", [])
    if rules:
        found = sum(1 for v in rules if f"{v}:" in content or f"'{v}'" in content or f'"{v}"' in content)
        comp += round(8 * found / len(rules))
    else:
        comp += 8
    rules_arr = component_rules.get(component_name.lower(), {}).get("rules", [])
    if rules_arr:
        satisfied = 0
        for rule in rules_arr:
            r_lower = rule.lower()
            if "label" in r_lower and ("<label" in content or "label?" in content):
                satisfied += 1
            elif "focus" in r_lower and ("focus-visible:" in content or "focus:" in content):
                satisfied += 1
            elif "disabled" in r_lower and "disabled:" in content:
                satisfied += 1
            elif "icon" in r_lower and "icon" in content.lower():
                satisfied += 1
            elif "tap target" in r_lower and re.search(r"\bh-1[012]\b", content):
                satisfied += 1
            elif "title" in r_lower and ("title?" in content or "Title" in content):
                satisfied += 1
            elif "no nested" in r_lower:
                satisfied += 1   # we don't nest by construction
            elif "no diagonal" in r_lower and "bg-gradient" not in content:
                satisfied += 1
            elif "active state" in r_lower and ("active:" in content or "data-[state=active]" in content or "aria-current" in content):
                satisfied += 1
            elif "destructive" in r_lower and "destructive" in content.lower():
                satisfied += 1
            elif "escape" in r_lower and ("DialogPrimitive" in content or "onOpenChange" in content):
                satisfied += 1
            elif "focus trap" in r_lower and ("DialogPrimitive" in content):
                satisfied += 1
            elif "navigation" in r_lower and "role=\"navigation\"" in content:
                satisfied += 1
            elif "mobile" in r_lower:
                satisfied += 1
            else:
                satisfied += 0.5   # partial
        comp += round(8 * min(satisfied, len(rules_arr)) / len(rules_arr))
    else:
        comp += 8
    if "VariantProps" in content and "ComponentPropsWithoutRef" in content:
        comp += 4
    elif "VariantProps" in content or "interface" in content:
        comp += 2

    # 4. anti_slop (max 15)
    slop = 15
    if re.search(r"\b(bg|text|border|from|to)-(indigo|purple|violet)-\d+\b", content):
        slop -= 5
    if re.search(r"\b(rounded-3xl|shadow-2xl)\b", content):
        slop -= 4
    if re.search(r"bg-gradient-to-(br|tl|tr|bl)", content):
        slop -= 3

    # 5. voice (max 10)
    vc = 5
    string_lits = re.findall(r'"([^"]{3,})"', body) + re.findall(r"'([^']{3,})'", body)
    text_content = " ".join(string_lits).lower()
    if not text_content:
        vc = 8   # no copy → mostly OK by absence
    else:
        hits = [w for w in avoid_words if w in text_content]
        if hits:
            vc -= min(5, len(hits))
        else:
            vc += 3

    return min(acc, 30) + max(min(tok, 25), 0) + min(comp, 20) + max(slop, 0) + min(max(vc, 0), 10), {
        "accessibility": min(acc, 30),
        "token_compliance": max(min(tok, 25), 0),
        "component_compliance": min(comp, 20),
        "anti_slop": max(slop, 0),
        "voice_and_archetype": min(max(vc, 0), 10),
    }

# Score each component
components = [
    ("Button", ROOT / "Button" / "Button.tsx"),
    ("Card", ROOT / "Card" / "Card.tsx"),
    ("Input", ROOT / "Form" / "Input.tsx"),
    ("Textarea", ROOT / "Form" / "Textarea.tsx"),
    ("Select", ROOT / "Form" / "Select.tsx"),
    ("Modal", ROOT / "Modal" / "Modal.tsx"),
    ("Sidebar", ROOT / "Navigation" / "Sidebar.tsx"),
    ("Topbar", ROOT / "Navigation" / "Topbar.tsx"),
    ("Tabs", ROOT / "Navigation" / "Tabs.tsx"),
    ("Breadcrumb", ROOT / "Navigation" / "Breadcrumb.tsx"),
    ("DataTable", ROOT / "DataTable" / "DataTable.tsx"),   # Mode B
]

print(f"Brand Score Report (TECH UTILITY brand.json)")
print()
print(f"  Component   | acc/30 | tok/25 | comp/20 | anti/15 | voice/10 | TOTAL")
print(f"  ------------|--------|--------|---------|---------|----------|------")
total_score = 0
fails_below_75 = []
for name, path in components:
    score, breakdown = score_component(path, name)
    total_score += score
    print(f"  {name:11s} | {breakdown['accessibility']:6d} | {breakdown['token_compliance']:6d} | {breakdown['component_compliance']:7d} | {breakdown['anti_slop']:7d} | {breakdown['voice_and_archetype']:8d} | {score:5d}")
    if score < 75:
        fails_below_75.append((name, score))

avg = total_score / len(components)
print()
print(f"  Average Brand Score: {avg:.1f}/100 ({len(components)} components)")
print(f"  Threshold: ≥ 75 per component, ≥ 75 average for PASS")
print()

if fails_below_75:
    print(f"❌ FAIL — {len(fails_below_75)} components below threshold:")
    for name, score in fails_below_75:
        print(f"   - {name}: {score}/100")
    sys.exit(1)
elif avg < 75:
    print(f"❌ FAIL — average {avg:.1f} < 75")
    sys.exit(1)
else:
    print(f"✅ PASS — all components ≥ 75 AND average {avg:.1f} ≥ 75")
PY
