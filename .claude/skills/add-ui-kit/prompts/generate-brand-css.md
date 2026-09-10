# generate-brand-css — brand.json → brand/brand.css

> Operational prompt. Toma `brand/brand.json` y rellena `templates/brand.css.template` para producir `brand/brand.css`.
>
> **Source:** `brand/brand.json` (canonical contract).
> **Template:** `templates/brand.css.template`.
> **Citations en output:** [memory:references#R-005], [memory:CONSTRAINTS.md#R10], [docs:tailwindcss].

---

## Input esperado

`brand/brand.json` poblado por `generate-brand-json.md`.

## Output esperado

`brand/brand.css` — CSS con `:root { --color-* ... }` derivado 1:1 de `brand.json.tokens`.

---

## Procedimiento (5 pasos)

### Paso 1 — find-docs (R13)

Antes de generar CSS Tailwind-aware, invocar `find-docs` para verificar sintaxis actual:

```
1. resolve-library-id("tailwindcss") → libraryId canónico
2. query-docs(libraryId, "v3 arbitrary value var() syntax custom properties")
3. citar [docs:tailwindcss] en el header del brand.css generado
```

Esperar respuesta de Context7 confirmando que `bg-[var(--color-primary)]` y `font-[family-name:var(--font-display)]` son sintaxis válida en Tailwind v3.x. Si Context7 reporta cambio (improbable), ajustar template.

### Paso 2 — Cargar brand.json + template

```
1. Read brand/brand.json
2. Validar JSON parseable
3. Read .claude/skills/add-ui-kit/templates/brand.css.template
```

### Paso 3 — Mapeo 1:1 token → CSS variable

Reglas de mapeo (idempotentes — corriendo dos veces sobre el mismo brand.json produce el mismo brand.css):

```
brand.json.tokens.colors.<role>          → :root { --color-<role>: <hex>; }
brand.json.tokens.typography.<role>.family → :root { --font-<role>: '<family>', system-ui, sans-serif; }
brand.json.tokens.typography.<role>.weights → :root { --font-weight-<role>-{min,max}: <int>; }
brand.json.tokens.typography.body.line_height → :root { --line-height-body: <decimal>; }
brand.json.tokens.shape.<key>            → :root { --<key.replace('_', '-')>: <int>px; }
brand.json.tokens.spacing.unit                    → :root { --space-unit: <int>px; }
brand.json.tokens.spacing.section_y.{sm,md,lg}    → :root { --section-y-<key>: <int>px; }   (R-005 v1.1.0 keyed object)
brand.json.tokens.spacing.component_gap.{xs,sm,md,lg} → :root { --gap-<key>: <int>px; }   (R-005 v1.1.0 keyed object)
brand.json.motion.durations_ms.<tier>             → :root { --motion-duration-<tier>: <int>ms; }
brand.json.motion.personality.energy              → derive --motion-easing (energy es enum cerrado en R-005 v1.1.0)
```

### Paso 4 — Easing derivation

```
motion.personality.energy:
  "precise"     → cubic-bezier(0.4, 0, 0.2, 1)        (Material standard)
  "calm"        → cubic-bezier(0.4, 0.0, 0.2, 1)      (smoother)
  "violent"     → cubic-bezier(0.7, 0, 0.84, 0)       (ease-in sharp)
  "ceremonial"  → cubic-bezier(0.65, 0, 0.35, 1)      (longer ease)
  "mechanical"  → linear                               (no curve — Forge default)
  default       → cubic-bezier(0.4, 0, 0.2, 1)
```

A partir de R-005 v1.1.0, `motion.personality.energy` es **enum cerrado** schema-level (5 valores). El brand.json producido por add-ui-kit cumple por construcción — si el valor cae fuera del enum, el schema validation falla antes de llegar acá. **No hace falta default + warning** — es violación schema-level. Los 4 valores no enumerados (organic_default, snappy, etc.) que existían en R-005 v1.0 se eliminaron de R-005 v1.1.0 [memory:errors#E-003].

### Paso 5 — Render + validate + write

1. Procesar template substituyendo todos los `{{ var }}`.
2. Validar CSS con un parser básico:
   - Cada declaración termina en `;`
   - Cada bloque cierra `}`
   - Las CSS variables empiezan con `--`
3. Validar idempotency: re-correr con el mismo brand.json produce el mismo output (hash check).
4. Write `brand/brand.css`.
5. Reportar al orchestrator:
   - LOC del CSS generado
   - Cantidad de CSS vars exportadas
   - Hash SHA256 del output (para idempotency tracking)

---

## Casos edge

### brand.json incompleto

Si `tokens.colors.<role>` está ausente cuando el role es required:
- `primary`, `surface`, `text`: halt + sugerir re-correr `generate-brand-json`
- otros: aplicar fallback declarado en el template (`primary_deep` ← `primary`, `info` ← `accent`, etc.)

### Mono font opcional

Si `tokens.typography.mono` es `null` en brand.json:
- emitir `--font-mono: ui-monospace, "Courier New", monospace;` (system fallback)
- registrar como warning informativo

### prefers-reduced-motion override

El template ya incluye el bloque `@media (prefers-reduced-motion: reduce)` con override completo (R-005 motion.rules: "Respect prefers-reduced-motion"). NO eliminar de la generación. Si Discovery declara explícitamente que el proyecto requiere motion incluso con reduced-motion (caso muy raro, ej: feedback médico crítico), el caller debe haberlo consultado al usuario y tener consentimiento — pero el output default siempre incluye el override.

---

## Refusals

- ❌ Inventar tokens que no están en brand.json.
- ❌ Hardcodear valores hex en brand.css (deben venir de tokens).
- ❌ Eliminar el override de prefers-reduced-motion sin consentimiento explícito documentado.
- ❌ Saltar la invocación de find-docs (R13 violation).
- ❌ Sobrescribir `brand/brand.css` existente sin que el orchestrator confirme.

---

## Citations en el output

El header CSS lleva:

```css
/*
 * Brand DNA — CSS Variables
 * ...
 * Citations: [memory:references#R-005] · [memory:CONSTRAINTS.md#R10]
 *            [docs:tailwindcss] for var() arbitrary-value usage
 */
```

---

*"brand.json es el contrato. brand.css es el contrato traducido a runtime CSS."*
