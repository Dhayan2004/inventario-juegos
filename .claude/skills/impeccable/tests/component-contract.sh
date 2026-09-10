#!/usr/bin/env bash
# component-contract.sh — Impeccable ↔ add-* contract tests
#
# Resuelve E-007: validation runtime real entre brand.json (output de impeccable)
# y los components que add-* skills ASUMEN existen con ciertas props.
#
# Sin este test, add-login templates referencian <Input label="..." hint="..." />
# pero si impeccable NO declara `label` y `hint` en su Input variant, el target
# project compila → falla en runtime. Este test cierra el gap.
#
# Header awareness:
#   E-008: grep -E con | plain (NUNCA \| ni \\|).
#   F3-S10/S11/S12 frictions: -i, -- separator, mode patterns relax, ventanas -A flexibles.
#
# Citations:
#   [memory:errors#E-007] — gap que este test resuelve
#   [memory:decisions#D-009] — add-login consume brand.json contract
#   [memory:decisions#D-010] — add-payments consume brand contract
#   [memory:decisions#D-011] — add-emails consume brand contract
#
# Inputs:
#   - brand/brand.json (si existe, output de add-ui-kit)
#
# Behavior:
#   - Si brand.json NO existe → reporta "Brand DNA absent — corré add-ui-kit primero"
#     (informativo, NO fail fatal — el contract test asume brand exists).
#   - Si brand.json existe → valida contracts cross-skill (add-login/payments/emails).
#
# Usage: bash .claude/skills/impeccable/tests/component-contract.sh
# Exit 0 = all PASS o brand absent (informativo)
# Exit 1 = brand exists pero contracts fallan

set -euo pipefail

# Find project root (looking for brand/brand.json upward)
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
BRAND_JSON="$REPO_ROOT/brand/brand.json"

echo "── impeccable component-contract ───────────────────────────────"
echo "Repo root:  $REPO_ROOT"
echo "Brand JSON: $BRAND_JSON"
echo ""

PASS=0
FAIL=0
WARN=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN + 1)); }

# ── Pre-check: ¿brand.json existe? ──────────────────────────────────
if [ ! -f "$BRAND_JSON" ]; then
  echo "ℹ️  Brand DNA absent — brand.json no encontrado en $BRAND_JSON"
  echo ""
  echo "El test component-contract requiere que add-ui-kit haya corrido primero"
  echo "para generar el contrato Brand DNA. Sin él, los contracts cross-skill"
  echo "no pueden validarse."
  echo ""
  echo "Próximo paso: corré /add-ui-kit (Discovery FRESH) o /init-saas wizard."
  echo ""
  echo "── Status ──────────────────────────────────────────────────────"
  echo "  Status: SKIPPED (brand.json absent — informativo, no fail)"
  echo ""
  echo "ℹ️  component-contract: SKIPPED (no brand.json). Re-correr post-add-ui-kit."
  exit 0
fi

# Helper: extract JSON field via grep + naive parsing
# (no usamos jq para no agregar dep — grep + sed bastan para checks de presencia)
has_field() {
  local field="$1"
  grep -qE "\"$field\"" "$BRAND_JSON"
}

has_component_in_rules() {
  local component="$1"
  grep -qE "\"$component\"" "$BRAND_JSON"
}

has_variant_in_component() {
  local component="$1"
  local variant="$2"
  # Parse simple: buscar "$component" + dentro de su block "$variant"
  # Heurística: si ambos aparecen y "$variant" aparece en líneas cercanas a "$component"
  grep -A50 "\"$component\"" "$BRAND_JSON" | grep -qE "\"$variant\""
}

# ── GRUPO A — Contratos que add-login asume ─────────────────────────
echo "GRUPO A — Contratos add-login (D-009)"

# A1: brand.json tiene component_rules
if has_field "component_rules"; then
  ok "brand.json: component_rules field presente"
else
  fail "brand.json: component_rules field MISSING (crítico para add-login)"
fi

# A2: Button component declarado
if has_component_in_rules "Button"; then
  ok "component_rules: Button declarado"
else
  fail "component_rules: Button MISSING (add-login auth pages requieren <Button>)"
fi

# A3: Button variant primary (los CTA principales de auth pages)
if has_variant_in_component "Button" "primary"; then
  ok "Button: variant 'primary' declarado (CTA de sign-in/sign-up)"
else
  fail "Button: variant 'primary' MISSING (add-login templates lo asumen)"
fi

# A4: Input component declarado
if has_component_in_rules "Input"; then
  ok "component_rules: Input declarado"
else
  fail "component_rules: Input MISSING (add-login forms requieren <Input>)"
fi

# A5: Input props canónicas (label, placeholder, type)
# add-login templates: <Input label="..." placeholder="..." type="email" required />
for prop in "label" "placeholder" "type"; do
  if grep -A30 "\"Input\"" "$BRAND_JSON" | grep -qE "\"$prop\""; then
    ok "Input: prop '$prop' presente en spec"
  else
    warn "Input: prop '$prop' NO declarado explícitamente (add-login lo asume)"
  fi
done

# A6: Input props extendidas (autoComplete, minLength) — add-login password forms
for prop in "autoComplete\|autocomplete" "minLength\|minlength" "required"; do
  pat=$(echo "$prop" | sed 's/\\|/|/g')
  if grep -A40 "\"Input\"" "$BRAND_JSON" | grep -qiE "$pat"; then
    ok "Input: prop extendida '$prop' presente"
  else
    warn "Input: prop extendida '$prop' NO declarada (add-login password forms la asumen)"
  fi
done

# A7: Form / form-related structure (add-login envuelve inputs en <form>)
if grep -qiE "\"Form\"|\"FormField\"|form_structure" "$BRAND_JSON"; then
  ok "component_rules: Form / FormField structure presente"
else
  warn "component_rules: Form structure NO declarada (add-login usa <form> nativo OK)"
fi

# ── GRUPO B — Contratos que add-payments asume ──────────────────────
echo ""
echo "GRUPO B — Contratos add-payments (D-010)"

# B1: Button variant para CTA de checkout
# add-payments /pricing tiene CTA "Subscribe" — asume Button con variant que destaque
# Aceptar variants: 'primary', 'cta', 'checkout', 'upgrade'
button_cta_found=false
for variant in "checkout" "cta" "upgrade" "primary"; do
  if has_variant_in_component "Button" "$variant"; then
    button_cta_found=true
    ok "Button: variant CTA '$variant' presente (add-payments /pricing)"
    break
  fi
done
if [ "$button_cta_found" = false ]; then
  fail "Button: ninguna variant CTA-friendly (checkout/cta/upgrade/primary) declarada"
fi

# B2: Button con estado loading (add-payments checkout submit)
# add-payments asume <Button loading={isLoading}>
if grep -A40 "\"Button\"" "$BRAND_JSON" | grep -qiE "loading|isLoading|loading_state"; then
  ok "Button: estado loading presente en spec"
else
  warn "Button: estado loading NO declarado (add-payments checkout lo asume)"
fi

# B3: Card component (add-payments /pricing usa Cards para tier display)
if has_component_in_rules "Card"; then
  ok "component_rules: Card declarado (add-payments /pricing tiers)"
else
  fail "component_rules: Card MISSING (add-payments /pricing requiere <Card>)"
fi

# ── GRUPO C — Contratos que add-emails asume ────────────────────────
echo ""
echo "GRUPO C — Contratos add-emails (D-011)"

# C1: tokens.colors.primary (email templates header bg)
if grep -qE "\"primary\"" "$BRAND_JSON" && grep -qE "tokens|colors" "$BRAND_JSON"; then
  ok "tokens.colors.primary presente (email templates header)"
else
  fail "tokens.colors.primary MISSING (add-emails templates requieren color primary)"
fi

# C2: tokens.typography (email body font + size)
if grep -qE "typography|font_family\|fontFamily\|font_stack" "$BRAND_JSON"; then
  ok "tokens.typography presente (email body)"
else
  warn "tokens.typography NO declarado explícitamente (add-emails usa fallback Arial/Helvetica)"
fi

# C3: tokens.colors para email semantic colors (success, error)
for semantic in "success\|positive" "error\|negative\|destructive"; do
  pat=$(echo "$semantic" | sed 's/\\|/|/g')
  if grep -qiE "\"($pat)\"" "$BRAND_JSON"; then
    ok "tokens.colors semantic '$semantic' presente"
  else
    warn "tokens.colors semantic '$semantic' NO declarado (email templates usan defaults)"
  fi
done

# C4: voice.json existence (separate file, but related)
VOICE_JSON="$REPO_ROOT/brand/voice.json"
if [ -f "$VOICE_JSON" ]; then
  ok "voice.json existe (add-emails templates consume copy)"
else
  fail "voice.json MISSING (add-emails templates necesitan voice contract)"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS:  $PASS"
echo "  WARN:  $WARN  (gaps soft — add-* skills tienen fallbacks documentados)"
echo "  FAIL:  $FAIL  (gaps críticos — add-* skills fallarán en runtime)"
echo ""

if [ "$FAIL" -eq 0 ]; then
  if [ "$WARN" -gt 0 ]; then
    echo "✅ component-contract: ALL PASS ($PASS checks)"
    echo "   $WARN warnings — gaps soft (review pero NO bloquean integración)"
    echo ""
    echo "ℹ️  Recomendación: revisar warnings y considerar agregar props/tokens"
    echo "   faltantes en brand.json para reducir runtime risk en add-* skills."
  else
    echo "✅ component-contract: ALL PASS ($PASS checks, zero warnings)"
    echo "   Brand DNA contract cumple expectativas de add-login + add-payments + add-emails."
  fi
  exit 0
else
  echo "❌ component-contract: $FAIL contracts críticos rotos"
  echo ""
  echo "Brand DNA NO cumple contratos que add-* skills asumen. Resultado:"
  echo "los templates add-* compilarán pero pueden fallar en runtime cuando"
  echo "los component_rules NO declaran las props/variants que asumen."
  echo ""
  echo "Próximo paso: re-ejecutar /add-ui-kit Discovery con foco en component_rules"
  echo "extendido, o ajustar manualmente brand/brand.json para cumplir contratos."
  exit 1
fi
