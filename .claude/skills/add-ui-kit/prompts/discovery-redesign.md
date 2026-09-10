# Discovery REDESIGN — Brand DNA scan & consolidate para proyectos existentes

> Prompt operativo. Cuando `add-ui-kit` corre en Mode REDESIGN, leé este archivo y conducí los 4 pasos en orden.
>
> **Source schema:** [memory:references#R-005].
> **Trigger:** repo target tiene >5 archivos UI escritos sin Brand DNA declarado, o usuario pide "consolidá el design", "unificá tokens", "redesign".

---

## Reglas del intérprete

1. **NO ejecutar refactors masivos.** Este prompt escanea, reporta, propone, y genera el contrato. Refactors profundos del codebase (cambiar Tailwind defaults a CSS vars en 23 archivos, consolidar radius scales, etc.) van a `el-tajo` o `el-golpe` post-handoff.
2. **Capturar el código actual como datos**, no como verdad. Lo que está en código puede ser legacy, copy-paste, o elección consciente — Discovery distingue.
3. **Confirmar consolidaciones con el usuario antes de escribir brand.json.**
4. **Aplicar whitelist en captura.** [memory:lessons#L-003].
5. **Bifurcación sub-mode obligatoria** (ver abajo). REDESIGN ya no es solo SCAN+REPORT — ofrece MERGE controlado como opción explícita.

---

## Sub-modes (preguntar al usuario después del Scan)

Tras completar Paso 1 (Scan) y Paso 2 (Reporte), preguntar al usuario:

```
¿Qué hago con el reporte?

A. SCAN-ONLY — solo dejá el reporte, no toques código. Yo decido luego.
B. MERGE — integrá Brand DNA SIN destruir tokens existentes:
   - globals.css: append CSS vars nuevas al final del :root {} actual
   - tailwind.config.ts: extender theme.extend.colors con keys nuevas
     (sin remover las existentes)
   - layout.tsx: añadir imports de fonts del Brand DNA al final de
     imports actuales (sin remover Toaster/providers/etc.)
   - Generar brand/brand.json + voice.json + brand.css NUEVOS
   - NO generar src/app/(brand)/showcase si ya existe layout/page
     custom — solo si el usuario lo pide explícitamente
```

**Default si el usuario no responde claramente → A (SCAN-ONLY).** El default conservador previene daño en E-009 (causa 2 — restricción path-literal pierde alcance cuando se asume MERGE).

- Si sub-mode = **SCAN-ONLY** → seguir con Paso 3 + Paso 4 (consolidación propuesta + migration plan) y finalizar con handoff a el-tajo/el-golpe.
- Si sub-mode = **MERGE** → cargar `prompts/redesign-merge.md` y ejecutar el protocolo de merge no-destructivo. NO ejecutar Paso 4 (migration plan masivo) — el MERGE solo toca los 3 archivos críticos.

Cita: [memory:errors#E-009] causa 2.

---

## Paso 1 — Scan

### Tooling

| Token | Glob | Patrones a detectar |
|-------|------|---------------------|
| Colors | `src/**/*.{tsx,jsx,ts,js,css,scss,vue,svelte}` | `#[0-9a-fA-F]{3,8}`, `rgb(`, `hsl(`, `var(--*color*)`, `text-<color>-<n>`, `bg-<color>-<n>` |
| Radius | mismos archivos | `border-radius:`, `rounded-<n>`, `rounded-(sm|md|lg|xl|2xl|3xl|full)` |
| Fonts | mismos | `font-family:`, `font-(sans|serif|mono)`, imports de Google Fonts, imports de `next/font/google` |
| Spacing | mismos | `p-<n>`, `m-<n>`, `gap-<n>`, `space-(x\|y)-<n>`, `padding:`, `margin:`, `gap:` |
| Shadow | mismos | `shadow-(sm\|md\|lg\|xl\|2xl)`, `box-shadow:` |

### Comandos sugeridos

```bash
# Colors
grep -rohE '#[0-9a-fA-F]{6,8}' src/ 2>/dev/null | sort -u
grep -rohE 'text-[a-z]+-[0-9]{2,3}|bg-[a-z]+-[0-9]{2,3}|border-[a-z]+-[0-9]{2,3}' src/ 2>/dev/null | sort | uniq -c | sort -rn | head -30

# Radius
grep -rohE 'rounded(-(sm|md|lg|xl|2xl|3xl|full|none))?' src/ 2>/dev/null | sort | uniq -c | sort -rn

# Fonts
grep -rohE 'font-(sans|serif|mono|[a-z]+)' src/ 2>/dev/null | sort | uniq -c | sort -rn
grep -rE 'next/font/google' src/ 2>/dev/null

# Spacing
grep -rohE '\b(p|m|gap|space-x|space-y)-([0-9]+|px)' src/ 2>/dev/null | sort | uniq -c | sort -rn | head -20

# Shadows
grep -rohE 'shadow(-(sm|md|lg|xl|2xl|none))?' src/ 2>/dev/null | sort | uniq -c | sort -rn
```

---

## Paso 2 — Reporte de gaps

Estructura del reporte (mostrar al usuario):

```markdown
## Scan Report — <project-name>

### Colors found
| Hex | Occurrences | Likely role |
|-----|-------------|-------------|
| #6366F1 | 47 | primary (Tailwind indigo-500 default — 🚨 anti-slop) |
| #FFFFFF | 312 | background / text |
| #18181B | 89 | text / surface |
| #E5E7EB | 23 | border |
| ... | ... | ... |

**Anti-slop alerts:**
- 47 occurrences of `#6366F1` (Tailwind indigo-500 default — falls in restricted hue range [235, 285])
- 12 occurrences of `from-purple-500 to-blue-500` gradient (forbidden pattern)

### Radius
| Value | Occurrences | Files |
|-------|-------------|-------|
| rounded-md | 124 | most-used — likely canonical |
| rounded-lg | 89 | second most-used |
| rounded-3xl | 18 | hero/card variants |
| rounded-full | 32 | avatars / pills |
| rounded-2xl | 6 | one-off, candidates for consolidation |
| rounded-xl | 4 | one-off |

**Recommendation:** consolidate to 3 values max (R-005 max_radius_values=3): `md` (default), `lg` (cards), `full` (avatars). Refactor `2xl` → `lg`, `xl` → `lg`, `3xl` → `lg`.

### Fonts
| Family | Occurrences | Source |
|--------|-------------|--------|
| Inter | 234 | next/font/google in app/layout.tsx |
| Geist Mono | 12 | code blocks |
| (none — Tailwind default sans-serif) | 4 | edge case in 2 files |

**Recommendation:** declare `display: Inter` + `body: Inter` + `mono: Geist Mono`. Remove the 4 Tailwind-default fallbacks.

### Spacing
Most used: p-4 (118), p-6 (87), p-8 (54), p-2 (33), gap-4 (76), gap-6 (45)
**Recommendation:** spacing.unit = 8 (Tailwind default × 2 = 8/16/24/32/48/64). Consolidate p-3, p-5, p-7 (irregular) to nearest canonical.

### Shadows
shadow-sm: 23 / shadow: 45 / shadow-md: 12 / shadow-lg: 8 / shadow-2xl: 3 (all in hero sections — anti-slop alert)
**Recommendation:** keep `shadow-sm`/`shadow-md`. Remove `shadow-2xl` (anti-slop pattern #11).

### Anti-slop matches found in codebase
- 12× diagonal blue-purple gradient
- 3× rounded-3xl as default container
- 8× `text-purple-500` / `text-indigo-500` for accents
- 1× `Inter on white with purple CTA` hero pattern (matches default-AI aesthetic)

### Files needing refactor (count, NOT executed by add-ui-kit)
- 23 files reference Tailwind purple/indigo defaults → refactor to `var(--color-primary)` from brand.css
- 18 files have inline radius values not aligned with canonical 3-step scale
- 4 files have Tailwind-default fallbacks where named font expected
```

---

## Paso 3 — Consolidación propuesta

> Pasar al usuario una propuesta de `brand.json` que toma los valores **más frecuentes** del scan como canónicos, y los outliers como anti-patterns / refactor candidates.

### Estructura de la propuesta

```yaml
proposed_brand_json:
  brand:
    # capturar de package.json + README + filtrar vs scan
    name: "<inferido>"
    product: "<inferido>"
    tagline: "<pendiente — ¿confirmás?>"

  archetype:
    # heurística:
    # - si scan muestra warmth / colores cálidos / copy informal → Caregiver / Lover / Jester
    # - si scan muestra geometric / dark / monospace heavy → Creator / Sage
    # - si scan muestra fuerte expression + alto contraste → Outlaw / Magician
    primary: "<heurística + confirmación>"
    secondary: "<...>"
    shadow_to_avoid: ["Magician", "Hero"]

  visual_posture:
    # derivado del scan
    density: <calc>           # promedio de spacing values vs Tailwind median
    expression: <calc>        # diversidad de colors / saturación promedio
    geometry: <calc>          # promedio de radius (1=high radius, 5=low/sharp)
    warmth: <calc>            # heurística de palette + voice cues en strings
    editoriality: <calc>      # ratio de heading-tags vs body en pages
    materiality: <calc>       # presencia de shadow + border + blur

  tokens:
    colors:
      primary: "<color más frecuente para CTAs / acciones>"
      surface: "<background dominante>"
      text:    "<text dominante>"
      ...
    typography:
      display: "<font detectada>"
      body:    "<font detectada>"
      mono:    "<font detectada o null>"
    shape:
      radius_sm: <Nº más frecuente entre los pequeños>
      radius_md: <Nº más frecuente entre los medianos>
      radius_lg: <Nº más frecuente entre los grandes>
    spacing:
      unit: <inferred>

  anti_slop:
    # los patrones detectados que el usuario debería rechazar
    forbidden_patterns:
      - "<patrones default R-005>"
      - "<adicionales detectados en este scan>"
```

### Conversación de confirmación

Para cada bloque del propuesto, leerle al usuario:

> "Detecté X. Lo consolido como canónico. ¿Confirmás o preferís otro valor?"

Capturar overrides en estructura whitelist.

---

## Paso 4 — Migration plan (no ejecuta)

Generar archivo `brand/MIGRATION-PLAN.md` con:

```markdown
# Brand DNA Migration Plan — <project-name>

Generado por add-ui-kit Mode REDESIGN el <YYYY-MM-DD>.

## Contexto

El proyecto tenía UI escrita sin Brand DNA declarado. Tras el scan
de <N> archivos:
- <X> valores únicos de color
- <Y> valores únicos de radius
- <Z> familias de fuente

El nuevo `brand/brand.json` consolida los valores canónicos.
Este archivo lista los refactors necesarios para que el código
existente respete el contrato.

## Refactors recomendados

### 1. Reemplazar Tailwind purple/indigo defaults con var(--color-primary)
**Files affected:** <count>
**Estimated effort:** <S/M/L>
**Skill recomendado:** el-tajo (si <10 files) | el-golpe (10-30) | la-forja (>30)

\`\`\`bash
# Comandos sugeridos para el-tajo
grep -rl 'text-indigo-500\|text-purple-500\|bg-indigo-500\|bg-purple-500' src/
\`\`\`

### 2. Consolidar radius scale
**Files affected:** <count>
**Mapping:**
- `rounded-2xl` → `rounded-lg`
- `rounded-xl` → `rounded-lg`
- `rounded-3xl` → `rounded-lg`
**Skill:** el-tajo

### 3. Eliminar fallbacks Tailwind-default donde named font esperado
**Files affected:** <count>
**Skill:** el-tajo

### 4. Importar brand.css en app/layout.tsx
**Files affected:** 1
**Skill:** el-tajo

## NO incluido en este migration plan

- add-ui-kit NO ejecuta los refactors. Este archivo es input para el-tajo / el-golpe.
- el-evaluador valida que post-refactor, el scan-2 muestre 0 anti-slop matches.
```

---

## Output del Discovery REDESIGN

Tras paso 4, devolver al loop principal:

```yaml
discovery_output:
  mode: REDESIGN
  scan_summary:
    files_scanned:    <N>
    colors_found:     <N>
    radius_found:     <N>
    fonts_found:      <N>
    anti_slop_matches: <N>
  identity, archetype, posture, voice, tokens, anti_slop:
    <ver discovery-fresh.md format>
  redesign_specific:
    migration_plan_path: brand/MIGRATION-PLAN.md
    files_needing_refactor: <count>
    estimated_total_effort: <S/M/L/XL>
```

---

## Refusals

- ❌ Modificar archivos fuera de `brand/`.
- ❌ Ejecutar refactors detectados en el scan — solo reportar.
- ❌ Consolidar tokens sin confirmación explícita del usuario.
- ❌ Generar brand.json si el scan no encontró ≥3 archivos UI (no hay datos suficientes; sugerir Mode FRESH).
- ❌ Saltar el migration plan — es el output de handoff a `el-tajo` / `el-golpe`.

---

*"Scan, report, propose, plan. add-ui-kit no refactoriza — entrega el contrato y el plan."*
