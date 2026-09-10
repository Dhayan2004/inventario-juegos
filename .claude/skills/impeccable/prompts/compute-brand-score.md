# compute-brand-score — weighted score per R-005 sección 7.3

> Operational prompt. Toma un archivo `.tsx` recién generado + `brand.json` + `voice.json` y produce un Brand Score 0-100 según los weights declarados en `validation.brand_score_weights`.
>
> **Source schema:** [memory:references#R-005] sección 7.3.
> **Threshold:** ≥ 75 para mergear (≥ 90 = listo, 75-89 = usable con ajustes, < 75 = NEEDS_FIX).

---

## Input esperado

```yaml
tsx_path: src/shared/components/ui/<Component>/<Component>.tsx
brand_json_path: brand/brand.json
voice_json_path: brand/voice.json
```

## Output esperado

```yaml
score: 0-100
breakdown:
  accessibility: 0-30
  token_compliance: 0-25
  component_compliance: 0-20
  anti_slop: 0-15
  voice_and_archetype: 0-10
verdict: PASS | NEEDS_FIX | HALT
gaps_for_improve_pass: []  # si verdict != PASS
```

---

## 5 dimensiones (weights de brand.json.validation.brand_score_weights)

### 1. accessibility (max 30)

| Sub-check | Peso | Pass criterion |
|-----------|------|----------------|
| focus-visible declared | 8 | regex `focus-visible:` en cva o className |
| min_contrast_body ≥ 4.5 | 8 | text vs surface contrast ≥ 4.5 — para componente con texto |
| ARIA roles correctos | 6 | dialog → role='dialog', tablist → role='tablist', etc. |
| Keyboard navigation | 4 | onKeyDown, tabIndex, Esc handler en modals |
| Screen reader labels | 4 | aria-label en icon-only, aria-busy en loading, aria-disabled |

Total max: 30.

```python
def score_accessibility(tsx_content, component_type):
    score = 0
    if "focus-visible" in tsx_content:
        score += 8
    # Asume contrast OK si tokens están declarados (validate-anti-slop ya verificó)
    if "var(--color-text)" in tsx_content and "var(--color-surface)" in tsx_content:
        score += 8
    aria_roles_required = {"modal": "role=\"dialog\"", "tabs": "role=\"tablist\""}
    if component_type in aria_roles_required:
        if aria_roles_required[component_type] in tsx_content:
            score += 6
    elif "aria-" in tsx_content:
        score += 6  # any aria attr earns partial
    if "onKeyDown" in tsx_content or "tabIndex" in tsx_content or "Escape" in tsx_content:
        score += 4
    if "aria-label" in tsx_content or "aria-busy" in tsx_content or "aria-disabled" in tsx_content:
        score += 4
    return min(score, 30)
```

### 2. token_compliance (max 25)

| Sub-check | Peso | Pass criterion |
|-----------|------|----------------|
| All colors via var(--color-*) | 10 | 0 hex literals in TSX body |
| All fonts via var(--font-*) | 5 | 0 font-family literals |
| All radius via var(--radius-*) | 5 | 0 px-literal radius (rounded-N puede pasar si N mappea) |
| All spacing via var(--space-*) o Tailwind escala canon | 5 | 0 hardcoded margin/padding hex |

Total max: 25. **Validate-anti-slop ya hizo binary check 4 sobre esto** — compute-brand-score puntúa la calidad: 25 = todo via vars; 20 = 1 hardcoded; 15 = 2 hardcoded; etc.

### 3. component_compliance (max 20)

| Sub-check | Peso | Pass criterion |
|-----------|------|----------------|
| All declared variants present | 8 | cva variants object incluye TODAS las brand.json.component_rules.<c>.variants |
| All declared rules followed | 8 | regex match per rule (ej: "Visible label by default" → grep `<label`) |
| TypeScript types complete | 4 | exports VariantProps + ComponentProps* + props interface |

```python
def score_component_compliance(tsx_content, component_rules):
    score = 0
    declared_variants = component_rules["variants"]
    found_variants = []
    # Buscar variants en cva
    import re
    cva_block = re.search(r"cva\([\\s\\S]*?\\}\\s*\\)", tsx_content)
    if cva_block:
        block_text = cva_block.group(0)
        for v in declared_variants:
            if f"{v}:" in block_text or f"\"{v}\"" in block_text:
                found_variants.append(v)
    score += round(8 * len(found_variants) / len(declared_variants))

    # Rules followed: heurística por keywords
    rules = component_rules["rules"]
    rules_satisfied = 0
    for rule in rules:
        if "label" in rule.lower() and "<label" in tsx_content:
            rules_satisfied += 1
        elif "focus" in rule.lower() and "focus-visible:" in tsx_content:
            rules_satisfied += 1
        elif "disabled" in rule.lower() and "disabled:" in tsx_content:
            rules_satisfied += 1
        elif "active state" in rule.lower() and "active:" in tsx_content:
            rules_satisfied += 1
        elif "icon" in rule.lower() and "icon" in tsx_content.lower():
            rules_satisfied += 1
        elif "tap target" in rule.lower() and ("h-10" in tsx_content or "h-11" in tsx_content or "h-12" in tsx_content):
            rules_satisfied += 1
        elif "title" in rule.lower() and ("<h" in tsx_content or "title" in tsx_content.lower()):
            rules_satisfied += 1
    if len(rules) > 0:
        score += round(8 * rules_satisfied / len(rules))

    # TS types
    if "VariantProps" in tsx_content and "ComponentProps" in tsx_content:
        score += 4
    elif "VariantProps" in tsx_content or "interface" in tsx_content:
        score += 2
    return min(score, 20)
```

### 4. anti_slop (max 15)

| Sub-check | Peso | Pass criterion |
|-----------|------|----------------|
| 0 forbidden colors | 5 | check 1 de validate-anti-slop pasa |
| 0 rounded-3xl/shadow-2xl default | 4 | check 2 pasa |
| 0 diagonal gradients sin justificación | 3 | check 3 pasa |
| forbidden_patterns NOT detected | 3 | grep contra `brand.json.anti_slop.forbidden_patterns` por keywords |

Total max: 15. validate-anti-slop hizo binary; este es el quality score.

### 5. voice_and_archetype (max 10)

| Sub-check | Peso | Pass criterion |
|-----------|------|----------------|
| Default copy NO usa avoid_words | 5 | grep voice.json.avoid_words contra strings literales del TSX |
| Default copy NO contradice archetype | 3 | heurística: Outlaw archetype + copy "amigable" sin manifesto = -3 |
| Microcopy en empty/error states alineado con voice | 2 | si empty/error state existe, debe usar safe_words o sentence_rules.prefer |

Componentes sin copy default (ej: Card sin children rendering text) puntúan 0/0/0 = 10/10 por absence (es decir, no penalizar sin copy).

```python
def score_voice(tsx_content, voice_json):
    # Extraer strings literales del TSX
    import re
    string_literals = re.findall(r'"([^"]{3,})"', tsx_content)
    string_literals += re.findall(r"'([^']{3,})'", tsx_content)
    text_content = " ".join(string_literals).lower()

    if not text_content:
        return 10  # sin copy → no penalizar

    score = 5
    avoid = [w.lower() for w in voice_json["voice"]["avoid_words"]]
    hits = [w for w in avoid if w in text_content]
    if hits:
        score -= min(5, len(hits))

    # Archetype coherence — heurística simple
    arch = voice_json.get("archetype_primary", "")  # impeccable lee desde brand.json
    if arch == "Outlaw" and any(w in text_content for w in ["please", "kindly", "could you"]):
        score -= 3
    elif arch == "Caregiver" and any(w in text_content for w in ["fail", "error", "invalid"]):
        score -= 2  # debería ser empático, no juzgar
    else:
        score += 3

    safe_words = [w.lower() for w in voice_json["voice"].get("safe_words", [])]
    if any(sw in text_content for sw in safe_words):
        score += 2

    return min(max(score, 0), 10)
```

---

## Score aggregation

```python
total = (
    score_accessibility(tsx, comp_type) +
    score_token_compliance(tsx) +
    score_component_compliance(tsx, brand["component_rules"][comp_type]) +
    score_anti_slop(tsx, brand["anti_slop"]) +
    score_voice(tsx, voice)
)
# weights del brand.json son la fuente de verdad
weights = brand["validation"]["brand_score_weights"]
# El total ya está escalado por weights (cada función retorna max=weight)
# Salvo que los weights difieran del default — en ese caso re-escalar
```

---

## Verdict

| Score | Verdict | Action |
|-------|---------|--------|
| 90-100 | PASS — listo | Continue to write |
| 75-89 | PASS — usable con ajustes | Continue to write con warning informativo |
| 60-74 | NEEDS_FIX | Regenerate con improve flag (max 3 attempts) |
| < 60 | HALT | Reportar gaps al usuario, sugerir Mode B re-derivation o brand.json review |

R-005 sección 7.3 declara estos rangos textualmente.

---

## Output template

```markdown
## Brand Score Report — <Component>

**Total: <N>/100** — <verdict>

| Dimension | Score | Max | Notes |
|-----------|-------|-----|-------|
| accessibility | 28 | 30 | aria-label missing on icon-only button |
| token_compliance | 25 | 25 | all colors/fonts/radius/spacing via vars |
| component_compliance | 18 | 20 | 4/4 variants, 3/4 rules satisfied (loading state missing) |
| anti_slop | 15 | 15 | clean |
| voice_and_archetype | 8 | 10 | default copy uses 'effortless' (avoid_word) |

**Gaps for improve pass:**
- Add aria-label to icon-only button variants
- Implement loading state with aria-busy
- Replace 'effortless' default copy with archetype-aligned phrase

**Citation:** [memory:references#R-005] sección 7.3 weights + thresholds.
```

---

## Refusals

- ❌ Marcar PASS si score < 75.
- ❌ Permitir score sin breakdown completo.
- ❌ Inventar sub-scores sin runtime check del TSX.

---

*"5 dimensiones × weights de brand.json.validation = 0-100. ≥75 mergea. Sino regenera."*
