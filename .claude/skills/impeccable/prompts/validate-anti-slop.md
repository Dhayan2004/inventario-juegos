# validate-anti-slop — post-gen blocking gate

> Operational prompt. Toma un archivo `.tsx` recién generado por impeccable y corre 6 binary checks. **Blocking**: si alguno falla, NEEDS_FIX → regenerate.
>
> **Source schema:** [memory:references#R-005] sección 4 (anti-slop) + sección 7.2 (validation binarios).
> **Source rule:** [memory:CONSTRAINTS.md#R10] (Brand DNA contract gate).

---

## Input esperado

```yaml
tsx_path: src/shared/components/ui/<Component>/<Component>.tsx
brand_json_path: brand/brand.json
```

## Output esperado

```yaml
result: PASS | FAIL
checks:
  - name: <check_name>
    status: PASS | FAIL
    detail: <message>
gaps_for_regeneration:    # presente solo si FAIL
  - <gap_description>
```

---

> **Single source ejecutable:** los checks mecánicos canónicos (12) viven en
> `.claude/skills/add-ui-kit/tests/anti-slop-gate.sh` (owner: `el-evaluador`). Los 6 de abajo son el
> subconjunto que aplica a UN componente recién generado; ante discrepancia, gana el script.

## 6 binary checks

### Check 1 — No Tailwind purple/indigo defaults

```
Forbidden patterns en el TSX:
  - bg-(indigo|purple|violet)-(50|100|200|300|400|500|600|700|800|900)
  - text-(indigo|purple|violet)-<n>
  - border-(indigo|purple|violet)-<n>
  - from-(indigo|purple|violet)-<n>  to-(indigo|purple|violet)-<n>
  - hex literal en hue range [235, 285]: regex de hex + computar HSL hue
  - var(--color-*) names que en brand.json mappean a colores en ese hue range

Excepción: brand.json.archetype.primary == "Magician" o brand.json.anti_slop.restricted_hues[].allowed_only_if include "brand_declares_purple_as_primary".

Comando sugerido:
  grep -nE 'bg-(indigo|purple|violet)-[0-9]+|text-(indigo|purple|violet)-[0-9]+|from-(indigo|purple|violet)-[0-9]+' "$TSX_PATH"
```

PASS si 0 matches (o si Magician archetype declarado).

### Check 2 — No rounded-3xl ni shadow-2xl como default

```
Forbidden:
  - rounded-3xl (regla R-005 4.1 punto 12)
  - shadow-2xl (regla R-005 4.1 punto 11)

Excepción: si brand.json.tokens.shape.radius_lg ≥ 24 → rounded-3xl puede ser legal en variants específicas. Documentar en JSDoc.

Comando:
  grep -nE 'rounded-3xl|shadow-2xl' "$TSX_PATH"
```

PASS si 0 matches o si excepción documentada.

### Check 3 — No diagonal gradients sin justificación

```
Forbidden:
  - bg-gradient-to-br (diagonal gradient)
  - bg-gradient-to-tl
  - background: linear-gradient con angle != 0/90/180/270
  - style.background con linear-gradient diagonal

Excepción: archetype Magician o brand.json.archetype.allowed_behaviors include "signature_gradient".

Comando:
  grep -nE 'bg-gradient-to-(br|tl|tr|bl)' "$TSX_PATH"
```

### Check 4 — Tokens via CSS vars (NO hex inline, NO font literal)

```
Forbidden:
  - hex literal en JSX/TSX: regex /#[0-9a-fA-F]{6}\b/ en el TSX
  - rgb()/rgba() inline en style=
  - font-family: 'literal' en style= (debe ser var(--font-*))
  - font-(sans|serif) sin fallback a CSS var
  - hardcoded font-size px (debe ser Tailwind class o vía spacing tokens)

Allowed:
  - bg-[var(--color-primary)], text-[var(--color-text)]
  - var(--font-display), var(--font-body), var(--font-mono)
  - font-mono Tailwind class (case especial: mono role aceptable como class)

Comando:
  python3 -c "
import re, sys
content = open('$TSX_PATH').read()
# excluir bloque comment del header donde Brand Score se reporta
body = re.sub(r'^\s*\*\s.*\$', '', content, flags=re.MULTILINE)
hex_hits = re.findall(r'#[0-9a-fA-F]{6}\b', body)
font_literal = re.findall(r'font-family\s*:\s*[\\'\"]\\w+', body)
if hex_hits or font_literal:
    print('FAIL: hex_hits=' + str(hex_hits) + ' font_literal=' + str(font_literal))
    sys.exit(1)
print('PASS')
"
```

### Check 5 — All declared states implemented

```
brand.json.component_rules.<component>.rules incluyen states obligatorios:
  - "Focus, hover, active, disabled and loading states required" (button)
  - "Focus state must be visible" (form)
  - "Visible label by default" (form)
  - etc.

Verificar en el TSX:
  - focus-visible: clases en cva() base
  - hover: clases en cva() variant
  - active: clases en cva() variant
  - disabled: prop disabled handled + clases disabled:*
  - aria-busy or isLoading prop si aplicable

Comando heurístico:
  grep -cE 'focus-visible:|hover:|active:|disabled:' "$TSX_PATH"
  → debe ser ≥ 4 en componentes interactivos (button)
  → ≥ 2 en componentes estáticos (card.empty)
```

### Check 6 — Tap target ≥ 44px en mobile

```
Para componentes con props click-handler o button-like:
  - height base ≥ h-10 (40px) en sm
  - height base ≥ h-11 (44px) en md/lg

Para form inputs:
  - height ≥ h-10 (40px) — pero sm fallback a h-9 acceptable si tap-target alcanza con px padding

Comando heurístico:
  python3 -c "
content = open('$TSX_PATH').read()
import re
# Detectar h-N values
heights = re.findall(r'\\bh-(\\d+)\\b', content)
ints = [int(h) for h in heights]
if ints and min(ints) < 8:  # h-8 = 32px, < 40px tap target
    print('WARN: some height may be < 40px tap target: ' + str(sorted(set(ints))))
"
```

PASS si min height ≥ h-8 (32px) AND component es no-interactive, OR min height ≥ h-10 (40px) si interactive.

---

## Aggregated result

```python
result = "PASS" if all(c.status == "PASS" for c in checks) else "FAIL"
gaps = [c.detail for c in checks if c.status == "FAIL"]

if result == "FAIL":
    return {
        "result": "FAIL",
        "checks": checks,
        "gaps_for_regeneration": gaps,
        "next_action": "regenerate with improve flag focused on the gap list"
    }
return {"result": "PASS", "checks": checks}
```

---

## Cómo se invoca desde Mode A/B/C

```
1. Mode generates TSX → tsx_path
2. Mode invokes validate-anti-slop con tsx_path
3. Si PASS → continue to compute-brand-score
4. Si FAIL → log gaps, retry generate (Mode A/B/C decide cómo)
5. Tras 3 retries failing → halt + reportar al usuario
```

---

## Ejemplos de violaciones típicas

### Ejemplo 1 — purple-500 default

```typescript
// ❌ FAIL Check 1
<button className="bg-indigo-500 text-white">Click</button>

// ✅ PASS
<button className="bg-[var(--color-primary)] text-white">Click</button>
```

### Ejemplo 2 — rounded-3xl como default

```typescript
// ❌ FAIL Check 2
<div className="rounded-3xl shadow-2xl">...</div>

// ✅ PASS
<div className="rounded-[var(--radius-md)] border border-[var(--color-border)]">...</div>
```

### Ejemplo 3 — hex inline

```typescript
// ❌ FAIL Check 4
<button style={{ backgroundColor: '#FF6B35' }}>...</button>

// ✅ PASS
<button className="bg-[var(--color-primary)]">...</button>
```

### Ejemplo 4 — missing focus state

```typescript
// ❌ FAIL Check 5
const buttonVariants = cva('inline-flex items-center')

// ✅ PASS
const buttonVariants = cva(
  'inline-flex items-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]'
)
```

---

## Refusals

- ❌ Marcar PASS si cualquier check falla.
- ❌ Saltar checks por ser "obvio".
- ❌ Permitir excepciones sin documentar en JSDoc del componente.

---

*"6 binary checks. Si uno falla, no hay PASS. NEEDS_FIX → regenerate."*
