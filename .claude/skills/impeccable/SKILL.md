---
name: impeccable
description: >
  Component generator que CONSUME el contrato Brand DNA producido por
  add-ui-kit y produce componentes UI production-grade. 3 modos: KNOWN
  (variant declarado en `component_rules`), UNKNOWN (derivación R-005
  sección 8.2: purpose + tokens + posture + nearest_component +
  universal_rules), BATCH (init core component set). PREFLIGHT R10
  enforced — sin brand.json + voice.json válidos, halt sin generar.
  Anti-Slop Gate post-gen + Brand Score weighted (≥75 threshold,
  regenerate hasta 3 intentos). Tokens del brand.json son contrato no
  negociable; NO Tailwind defaults.
tier: core
requires: brand/brand.json + brand/voice.json + brand/brand.css existen y cumplen R-005. Project con TypeScript + Tailwind v3+ + (opcional) shadcn-ui instalado.
fallback: Sin Brand DNA → halt + handoff a `add-ui-kit`. Si shadcn no instalado → usar Tailwind primitives directo (registrado en references/shadcn-mapping.md). Si Tailwind ausente → halt (no soportamos CSS modules en MVP).
dependencies: [find-docs, add-ui-kit]
---

# impeccable

> *"Cada componente respeta el contrato. Sin contrato, no hay componente."*
> — Forja R10

Skill generator. Convierte brand.json + voice.json en código TypeScript + Tailwind production-grade. Consumer downstream del Brand DNA producido por `add-ui-kit`.

## PREFLIGHT halt (R10 enforcement)

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Existe brand/brand.json? Si no → halt: "Falta Brand DNA. Corré /add-ui-kit primero."
3. ¿Existe brand/voice.json? Si no → halt mismo mensaje.
4. ¿brand.json cumple R-005 (validación schema)? Si no → halt: "brand.json malformado. Re-corré /add-ui-kit o reparalo manualmente."
5. ¿brand/brand.css existe? Si no → halt: "Falta brand.css. Re-corré /add-ui-kit (paso generate-brand-css)."
6. ¿Project tiene TypeScript + Tailwind config? Si no → halt + reporte de qué falta.
```

Sin estos 6 gates, impeccable retorna error sin generar código.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide "generá Button.tsx" / "necesito Card variant metric" / "armá los componentes core" | Coordinator |
| Tras `add-ui-kit` cierre, init de proyecto fresh quiere su component set | add-ui-kit handoff |
| Otro skill UI (ai/generative-ui, add-login forms) detecta que un componente esperado no existe en `src/shared/components/ui/` | skill handoff |
| Re-generar un componente tras editar brand.json (drift detection) | el-evaluador handoff |

## 3 modos de operación

### MODE A — KNOWN COMPONENT

Input: nombre + variant que **EXISTE** en `brand.json.component_rules`.

Ejemplos:
- `button.danger` (button es uno de los 5 components declarados, danger es variant declarada)
- `card.metric`
- `form.search`
- `modal.confirm`
- `navigation.tabs`

Flow:
```
a. Read brand/brand.json + voice.json + brand.css
b. Resolve component_rules.<component> → variants array + rules array
c. Read templates/<Component>.tsx con {{ token }} placeholders
d. Substituir tokens (CSS vars vía bg-[var(--color-primary)] syntax)
e. Aplicar archetype-specific allowed/forbidden_behaviors a copy default + clases
f. Aplicar motion.durations + motion.personality a transitions
g. Generar código TypeScript con class-variance-authority pattern
h. validate-anti-slop.md → 6 binary checks
i. compute-brand-score.md → ≥75 o regenerate (max 3 intentos)
```

Detalle: `prompts/generate-component-known.md`.

### MODE B — UNKNOWN COMPONENT (R-005 sección 8.2)

Input: componente que **NO EXISTE** en `component_rules` (ej: data-table, chart, avatar-group, command-palette, breadcrumb-with-dropdown).

R-005 sección 8.2 declara el `unknown_component_policy`:

```json
{
  "derive_from": ["purpose", "tokens", "visual_posture", "nearest_component"],
  "must_include": ["states", "responsive_behavior", "accessibility"],
  "requires_rationale": true
}
```

Flow:
```
a. Read brand.json (mismo que Mode A)
b. Identify purpose: 1-2 lines describiendo qué hace el componente
   y qué problema resuelve (no la implementación)
c. Find nearest_component: lookup en references/derivation-rules.md
   tabla "componente desconocido → componente base más cercano"
d. Apply derivation:
   - tokens del nearest base
   - posture-specific overrides (density, geometry, materiality)
   - universal_rules (states, responsive, a11y de R-005 3.2)
e. Generar código + commit message con rationale (R-005 8.2 must_include)
f. Same validate-anti-slop + compute-brand-score gates
```

Detalle: `prompts/generate-component-unknown.md` + `references/derivation-rules.md`.

### MODE C — BATCH (core component set)

Input: invocación tipo "init core components" o handoff inicial post-add-ui-kit.

Flow:
```
a. Read brand.json
b. Para cada component en component_rules:
   Para cada variant en component.variants:
     Generate via Mode A → src/shared/components/ui/<Component>/<Component>.tsx
c. Generar index.ts barrel re-export desde src/shared/components/ui/index.ts
d. Generar tipos compartidos (BaseProps, VariantProps) en src/shared/components/ui/types.ts
e. Run anti-slop + brand-score sobre TODO el set
f. Reporte: lista de componentes + LOC + Brand Score por componente
```

Default core set (con TECH UTILITY brand.json):
- `Button` (4 variants: primary, secondary, ghost, danger)
- `Card` (4 variants: default, interactive, metric, empty)
- `Form` primitives: `Input`, `Textarea`, `Select` (+ `SearchInput` derivado)
- `Modal` (3 variants: confirm, form, detail)
- `Navigation` (4 variants: sidebar, topbar, tabs, breadcrumb)

Detalle: `prompts/generate-component-batch.md`.

## Loop de ejecución

```
0. PREFLIGHT halt
1. Detectar modo
   ├─ Input es "init core" / batch handoff       → Mode C
   ├─ Input componente está en component_rules   → Mode A
   └─ Input componente NO está                    → Mode B

2. Pre-gen find-docs (R13):
   - resolve-library-id("tailwindcss") + query "v3 config arbitrary values + plugins"
   - resolve-library-id("shadcn-ui") + query "button variants + class-variance-authority"
   - resolve-library-id("react") + query "server components vs client components in Next.js 16"

3. Generar según modo

4. validate-anti-slop.md (post-gen, blocking):
   · No bg-{indigo,purple,violet}-{N} Tailwind classes
   · No rounded-3xl, shadow-2xl como default
   · No diagonal gradients sin justificación
   · Components implementan TODOS estados declarados (focus, hover,
     active, disabled, loading donde aplique)
   · Tokens vienen de brand.css, NO hex inline
   · Fonts vienen de --font-* vars, NO families literal

5. compute-brand-score.md:
   accessibility(30) + token_compliance(25) + component_compliance(20) +
   anti_slop(15) + voice_and_archetype(10) = score 0-100

6. Threshold check:
   score ≥ 75 → PASS
   score < 75 → regenerate con flag improve, retry hasta 3 intentos
   tras 3 intentos < 75 → halt + reportar gaps al usuario

7. Devolver al orchestrator paths + Brand Score + citations utilizadas
```

## Reglas operativas

1. **brand.json es contrato no-negociable.** Si un token no está declarado, no se inventa. Mode B deriva con R-005 8.2 desde tokens existentes.
2. **NO Tailwind defaults.** Cero `bg-blue-500`, `text-purple-600`, `from-indigo-*`. Todo via `bg-[var(--color-primary)]` + `text-[var(--color-text)]`.
3. **class-variance-authority (cva) pattern para variants.** Cada componente exporta variants tipados (TypeScript) + clases derivadas. Ver `references/shadcn-mapping.md`.
4. **Server Components por default en Next.js.** Marcar `"use client"` solo cuando hace falta state/effects/handlers. Validado con find-docs vs Next.js 16+ App Router.
5. **States obligatorios:** focus-visible (a11y), hover, active, disabled, loading donde la variant lo amerite (button.primary sí, card.empty no).
6. **Tap target ≥ 44px en mobile** (component_rules.form.rules + R-005 3.1 forms).
7. **find-docs antes de cada generación.** R13. Tailwind / shadcn / React API pueden haber cambiado.
8. **Brand Score < 75 = NEEDS_FIX.** No mergeable. el-evaluador rechaza.

## Refusals (lo que NUNCA hace)

- ❌ Generar componente sin Brand DNA contract presente y válido.
- ❌ Hardcodear hex / fonts / spacing en TSX (siempre vía CSS vars de brand.css).
- ❌ Usar Tailwind purple/indigo defaults sin justificación de archetype Magician.
- ❌ Saltar validate-anti-slop o compute-brand-score.
- ❌ Mergear con Brand Score < 75.
- ❌ Editar `brand/*` (eso lo hace add-ui-kit).
- ❌ Editar `.claude/memory/**` (R5 — sole writer es el-evaluador).
- ❌ Generar agentic tools (no es el rol de impeccable; ese rol es de `ai`).

## Tool filter

Read · Grep · Glob · Bash (`npx tsc --noEmit`, `npx tailwindcss --content` para L1) · Write/Edit en `src/shared/components/`, `src/features/<feature>/components/`, `tailwind.config.{js,ts}` (extender con tokens-as-CSS-vars), `src/app/**/*.tsx` (cuando un componente se inserta en una page).

NO Edit en `brand/**` (add-ui-kit territory). NO Edit en `.claude/memory/**` (el-evaluador). NO Edit en `supabase/**` (el-migrador).

**Alcance conceptual independiente de prefijo (E-009 causa 2):** las rutas listadas son patrones, NO literales. La restricción aplica con o sin prefijo `` — un proyecto target sin el prefijo igual tiene `**/src/app/globals.css`, `**/tailwind.config.*`, `**/src/app/layout.tsx` críticos. Si esos archivos tienen contenido propio → halt o handoff a add-ui-kit, NUNCA reescritura. Cita [memory:errors#E-009].

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | Cualquier output (header de comentario en TSX) |
| Constraint source | `[memory:CONSTRAINTS.md#R10]` | SKILL.md + cada componente generado en su header |
| Derivation rule | `[memory:references#R-005]` (sec 8.2) | Mode B componentes — el commit message cita rationale |
| Lessons aplicadas | `[memory:lessons#L-002]`, `[memory:lessons#L-003]` | L-002: componentes que reciben contenido externo (search input con suggestions de API). L-003: componentes que validan inputs estructurados (form schemas) |
| External docs | `[docs:tailwindcss]`, `[docs:shadcn-ui]`, `[docs:react]` | Cualquier código que use API de cada lib (R13) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `add-ui-kit` | upstream. Sin sus 4 outputs, impeccable halt. |
| `find-docs` | dependency. Pre-gen invoca R13. |
| `el-evaluador` | post-gen ejecuta L1+L2+L3 + valida Brand Score + Anti-Slop final. |
| `ai/generative-ui` | downstream. Genera componentes runtime que respetan los mismos tokens. |
| `add-login`, `add-payments`, `add-emails` (Fase 3 block D) | downstream. Forms + emails consumen los componentes que impeccable produjo. |
| `el-guardian` | NO handoff — impeccable no toca secrets, no genera tools destructivas. |

## NO aplica

- **el-guardian handoff:** componentes UI estáticos, no destructive tools, no PII handling. Skip.
- **R14 (destructive tools):** no aplica — el skill no genera tools.
- **L-001 (RLS por user_id):** no aplica — no hay tablas BaaS en este flujo.

## Output handoff

Tras pasar Anti-Slop Gate + Brand Score ≥ 75:

```markdown
## impeccable handoff

**Mode:** KNOWN | UNKNOWN | BATCH
**Components generated:** N
**Output paths:**
- src/shared/components/ui/Button/Button.tsx (LOC)
- src/shared/components/ui/Card/Card.tsx (LOC)
- ...

**Brand Score per component:**
| Component | accessibility(30) | tokens(25) | components(20) | anti-slop(15) | voice(10) | TOTAL |
|-----------|-------------------|-----------|----------------|---------------|-----------|-------|
| Button    | 30                | 25        | 20             | 15            | 8         | 98    |
| ...       | ...               | ...       | ...            | ...           | ...       | ...   |

**Anti-Slop Gate:** PASS (no purple/indigo Tailwind defaults, no rounded-3xl,
no shadow-2xl, all states implemented).

**Citations:**
- [memory:references#R-005] (sección 8.2 si Mode B)
- [memory:CONSTRAINTS.md#R10]
- [docs:tailwindcss] · [docs:shadcn-ui] · [docs:react]

**Frictions encountered (if any):**
- <listar campos del brand.json que fueron ambiguos / faltantes>
- → Promote to errors.md as E-NNN if recurring
```

---

*"Generator que respeta el contrato. Si el contrato falla, el generator falla — no al revés."*
