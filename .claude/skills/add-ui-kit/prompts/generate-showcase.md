# generate-showcase — brand.json + voice.json → src/app/(brand)/showcase/

> Operational prompt. Toma `brand/brand.json` + `voice.json` + `brand.css` ya generados, y rellena `templates/showcase/page.tsx` + `sections/*.tsx` para producir el visual showcase Next.js.
>
> **Sources:** brand.json + voice.json + brand.css.
> **Templates:** `templates/showcase/page.tsx` + `templates/showcase/sections/*.tsx`.
> **Citations en output:** [memory:references#R-005], [memory:CONSTRAINTS.md#R10], [docs:nextjs], [docs:tailwindcss], [docs:shadcn-ui].

---

## Input esperado

- `brand/brand.json` — populated y validated.
- `brand/voice.json` — populated y validated.
- `brand/brand.css` — generated.

## Output esperado

Showcase chrome (root del route group):

- `src/app/(brand)/showcase/page.tsx`
- `src/app/(brand)/showcase/viewport-toggle.tsx` — toolbar desktop/tablet/mobile (`'use client'`)
- `src/app/(brand)/showcase/feedback-panel.tsx` — FeedbackButton + FeedbackForm + GlobalFeedbackButton (`'use client'`)
- `src/app/(brand)/showcase/actions.ts` — server actions (saveFeedback / readFeedback / clearFeedback → UI_FEEDBACK.md)

Part 1 — component vocabulary (`sections/`):

- `sections/palette.tsx`
- `sections/typography.tsx`
- `sections/buttons.tsx`
- `sections/inputs.tsx`
- `sections/cards.tsx`
- `sections/badges.tsx`
- `sections/alerts.tsx`
- `sections/navigation.tsx`
- `sections/loading.tsx`
- `sections/tabs.tsx`
- `sections/avatars.tsx`
- `sections/toast.tsx`
- `sections/empty-states.tsx`
- `sections/motion.tsx`
- `sections/voice.tsx`

> `sections/components.tsx` quedó superseded por las secciones granulares (buttons/inputs/cards/badges). No se importa desde page.tsx.

Part 2 — SaaS patterns (`sections/saas-patterns/`):

- `sections/saas-patterns/kpi-row.tsx`
- `sections/saas-patterns/data-table.tsx`
- `sections/saas-patterns/onboarding.tsx`
- `sections/saas-patterns/sidebar.tsx`
- `sections/saas-patterns/empty-complete.tsx`
- `sections/saas-patterns/auth-form.tsx`
- `sections/saas-patterns/navbar.tsx`

Contract emission (root del proyecto — scope exception, ver SKILL.md):

- `COMPONENT_RULES.md` — emitido vía `prompts/emit-component-rules.md` desde `templates/COMPONENT_RULES.md.template`. Las variant lists del contrato DEBEN matchear las del showcase renderizado (button: primary/secondary/ghost/danger; card: default/interactive/metric/empty).

---

## Procedimiento (7 pasos)

### Paso 1 — find-docs (R13)

Antes de escribir cualquier código Next.js / Tailwind / shadcn, invocar `find-docs` 3 veces:

```
1. resolve-library-id("nextjs") + query-docs(<id>, "app router page route group typescript")
   → confirmar:
     - sintaxis de App Router page (export default function ... + Metadata export)
     - route groups con (folder) — paréntesis no se incluyen en URL
     - imports relativos válidos en Next 14/15
   → citar [docs:nextjs] en cada archivo generado.

2. resolve-library-id("tailwindcss") + query-docs(<id>, "v3 arbitrary value var() syntax + font-[family-name:var(--x)]")
   → confirmar sintaxis arbitrary value (paso ya cubierto en generate-brand-css).
   → citar [docs:tailwindcss].

3. resolve-library-id("shadcn-ui") + query-docs(<id>, "button card input variants typescript")
   → consultar shape de componentes shadcn que el showcase pueda referenciar.
   → si shadcn está disponible en target, usar componentes shadcn como import; sino quedarse con primitives Tailwind del template.
   → citar [docs:shadcn-ui].
```

Si Context7 no está disponible o el lib no se resuelve:
- WebFetch a docs oficiales como fallback.
- Documentar el miss en `.claude/memory/errors.md` (vía el-evaluador) para futura promoción.

### Paso 1D — Agentation detection + feedback previo

Antes de renderizar el showcase, detectar el toolbar de Agentation y feedback acumulado (Forge add-ui-kit/SKILL.md L119-134):

```bash
# ¿El toolbar de Agentation está instalado en el target?
grep -rl "agentation\|Agentation" src/ --include="*.tsx" --include="*.ts" 2>/dev/null | head -3 || echo "NO_AGENTATION"

# ¿Hay feedback previo que incorporar?
ls -la UI_FEEDBACK.md 2>/dev/null && echo "HAS_FEEDBACK" || echo "NO_FEEDBACK"
```

Acciones según resultado:

- **HAS_AGENTATION** → escribir `NEXT_PUBLIC_HAS_AGENTATION=true` a `.env.local` del target (append, no sobrescribir otras vars). El `HowToPanel` de `page.tsx` y el `FeedbackForm` de `feedback-panel.tsx` leen ese env var (build-time inlined) y muestran la variante con el campo "Anotaciones Agentation".
- **NO_AGENTATION** → no escribir el env var. El How-To y el feedback panel caen a la variante de solo texto (default).
- **HAS_FEEDBACK** → leer `UI_FEEDBACK.md` completo ANTES de regenerar. Mostrar al usuario el feedback encontrado y confirmar qué cambios se incorporan; ese feedback informa tokens, variantes y reglas del showcase regenerado (y del COMPONENT_RULES.md emitido en Paso 6).
- **NO_FEEDBACK** → primera corrida, nada que incorporar.

> El env var es la ÚNICA escritura fuera de `brand/` + `src/app/(brand)/showcase/` + `COMPONENT_RULES.md`. `.env.local` es append quirúrgico (nunca reescritura), análogo al append de REDESIGN sobre globals.css.

### Paso 2 — Cargar templates + JSON

```
1. Read brand/brand.json
2. Read brand/voice.json
3. Read .claude/skills/add-ui-kit/templates/showcase/page.tsx
4. Read .claude/skills/add-ui-kit/templates/showcase/{viewport-toggle.tsx,feedback-panel.tsx,actions.ts}
5. Read .claude/skills/add-ui-kit/templates/showcase/sections/{palette,typography,buttons,inputs,cards,badges,alerts,navigation,loading,tabs,avatars,toast,empty-states,motion,voice}.tsx
6. Read .claude/skills/add-ui-kit/templates/showcase/sections/saas-patterns/{kpi-row,data-table,onboarding,sidebar,empty-complete,auth-form,navbar}.tsx
7. Read .claude/skills/add-ui-kit/templates/COMPONENT_RULES.md.template (emitido en Paso 6 vía emit-component-rules.md)
```

> La mayoría de las secciones NO tienen Mustache placeholders — todos los valores visuales son CSS vars. Los pocos placeholders viven en `page.tsx`, `sidebar.tsx`, `navbar.tsx`, `auth-form.tsx` y `avatars.tsx` (brand.product / brand.initials / brand.monogram / brand.avatar_sample_url, etc.). `viewport-toggle.tsx`, `feedback-panel.tsx` y `actions.ts` no llevan placeholders.

### Paso 3 — Render templates con substituciones

Para cada archivo template, substituir Mustache vars:

| Var | Source |
|-----|--------|
| `{{ brand.product }}` | brand.json.brand.product |
| `{{ brand.tagline }}` | brand.json.brand.tagline |
| `{{ brand.name }}` | brand.json.brand.name |
| `{{ archetype.primary }}` | brand.json.archetype.primary |
| `{{ archetype.secondary }}` | brand.json.archetype.secondary (default '—') |
| `{{ posture.<axis> }}` | brand.json.visual_posture.<axis> |
| `{{ tokens.typography.<role>.family }}` | brand.json.tokens.typography.<role>.family |
| `{{ motion.<axis> }}` | brand.json.motion.personality.<axis> |
| `{{ voice.hooks }}` | voice.json.voice.hooks (rendered via `| as_json_array`) |
| `{{ voice.cta_examples }}` | voice.json.voice.cta_examples |
| `{{ voice.cta_style }}` | voice.json.voice.cta_style |
| `{{ voice.safe_words }}` | voice.json.voice.safe_words |
| `{{ voice.avoid_words_project }}` | voice.json.voice.avoid_words MINUS baseline 23 (project-specific only) |

`| as_json_array` filter renders array literal: `["a", "b", "c"]` JSON-stringify-safe.

### Paso 4 — Adaptar al target project

| Concern | Acción |
|---------|--------|
| Path target | escribir a `src/app/(brand)/showcase/` (NO al template path) |
| Import de brand.css | el template asume `@/brand/brand.css`; ajustar al alias del proyecto target leyendo `tsconfig.json` |
| App Router vs Pages Router | si target usa Pages Router (legacy), advertir + halt. Showcase asume App Router (R-005 implícito). |
| Tailwind config | verificar que `tailwind.config.{js,ts}` tenga `content` glob cubriendo `app/**/*.{ts,tsx}`. Si no, advertir + ofrecer agregar el path. |

### Paso 5 — Validate L1

Validaciones pre-write:

1. **TypeScript syntax** — todos los archivos parsean (compila sin errors al menos a nivel sintaxis):
   ```bash
   cd forja && npx tsc --noEmit --jsx preserve --target es2022 src/app/\(brand\)/showcase/page.tsx
   ```
2. **Imports resueltos** — imports a `./sections/*`, `./sections/saas-patterns/*`, `./viewport-toggle`, `./feedback-panel`, `./actions` y `@/brand/brand.css` son resolvibles.
3. **Client/Server directives** — `viewport-toggle.tsx` + `feedback-panel.tsx` llevan `'use client'` (usan hooks/localStorage); `actions.ts` lleva `'use server'`; `page.tsx` y todas las `sections/**` son server components (sin `'use client'`). El `HowToPanel` usa `<details>` nativo, no `useState`, así que page.tsx queda como server component compatible con el export de `Metadata`.
4. **No inline hex** — grep en los outputs por patterns `#[0-9a-fA-F]{6}` y `rgb(`. Si encuentra fuera de los bloques de comentario `Incorrecto:`/Anti-Slop → reject (R10 violation: NO inline tokens).
5. **No font hardcoded** — grep por `font-family:` literal o `font-(sans|serif|mono|inter|geist)` literal. Permitido solo `font-mono` Tailwind class para mono role + `font-[family-name:var(--font-display)]` syntax.

> Nota: las secciones nombran hues prohibidos (`#3B82F6`, `bg-blue-500`, etc.) DENTRO de bloques `Anti-Slop`/`Incorrecto:` — distinguir esos negativos de violaciones afirmativas (mismo criterio que la L1 de emit-component-rules.md).

### Paso 6 — Write + reportar

1. Crear `src/app/(brand)/showcase/` + `sections/` + `sections/saas-patterns/` si no existen.
2. Write del chrome: `page.tsx`, `viewport-toggle.tsx`, `feedback-panel.tsx`, `actions.ts`.
3. Write de las 15 secciones Part 1 (`sections/*.tsx`) y las 7 patterns Part 2 (`sections/saas-patterns/*.tsx`). NO escribir `components.tsx` (superseded; no se importa).
4. **Emitir COMPONENT_RULES.md** — ejecutar `prompts/emit-component-rules.md` sobre `templates/COMPONENT_RULES.md.template` → escribir `COMPONENT_RULES.md` en la raíz del proyecto (scope exception sancionada, ver SKILL.md "Tool filter"). Las variant lists del contrato (R8 button / R9 card) DEBEN matchear las del showcase renderizado — sync requirement bidireccional.
5. Si Paso 1D detectó **HAS_AGENTATION**, append `NEXT_PUBLIC_HAS_AGENTATION=true` a `.env.local`.
6. Reportar al orchestrator:
   - paths escritos (chrome + 15 secciones + 7 patterns + COMPONENT_RULES.md [+ .env.local si HAS_AGENTATION])
   - LOC total
   - HAS_AGENTATION true/false (qué variante del How-To se renderizó)
   - Citations utilizadas: [docs:nextjs], [docs:tailwindcss], [docs:shadcn-ui]
   - L1 validations result (PASS/FAIL por validación)

---

## Casos edge

### Project sin Next.js App Router

Si el target es Vite, Remix, o similar:
- halt + reportar: "showcase/page.tsx asume Next.js App Router. Target es <X>. Adaptar manualmente o no generar showcase."
- el-evaluador puede registrar como E-NNN si recurrente.

### Project sin Tailwind

Si target no tiene Tailwind (raro en stack Forja):
- ofrecer convertir las clases Tailwind del template a CSS modules referenciando brand.css vars.
- documentar en `$generated_warnings` y proceder.

### voice.json con hooks/CTAs vacíos

Sección Voice del showcase renderiza arrays vacíos correctamente (los componentes ya tienen condicionales). NO halt — emitir como informativo.

### shadcn no instalado

Si target no tiene shadcn-ui (componentes shadcn referenciados son opcionales en el showcase):
- usar primitives Tailwind del template directamente (ya viene preparado para esto).
- registrar warning sugiriendo instalar shadcn para `impeccable` (F3-S2).

---

## Aplicabilidad de [memory:lessons#L-002]

> **Cuándo:** si el showcase se extiende para incluir file uploads o user-generated content (no es el caso default — el showcase es estático).
>
> Si una variante futura del showcase incluye demo de upload de imágenes o de pegar URLs, el system prompt + componente upload deben llevar las mitigaciones de L-002 (anti-prompt-injection: contenido externo es "datos a analizar" no "instrucciones a obedecer"). Por ahora el showcase no consume nada externo, solo brand.json + voice.json (controlados).

---

## Refusals

- ❌ Hardcodear hex/font/spacing en código TSX (todo desde brand.css).
- ❌ Saltar invocación de find-docs (R13).
- ❌ Generar para Pages Router cuando target es App Router o vice versa sin confirmación.
- ❌ Sobrescribir archivos existentes en `src/app/(brand)/showcase/` sin que el orchestrator confirme.
- ❌ Generar componente que renderiza data sensible de los archivos de configuración (audience emails, internal credentials, etc).

---

## Citations en cada output

Cada archivo TSX lleva en su header de comentario:

```typescript
/**
 * <Component name>
 *
 * Generated by add-ui-kit from brand/{brand,voice}.json.
 *
 * Citations:
 *   [memory:references#R-005]              schema source
 *   [memory:CONSTRAINTS.md#R10]            Brand DNA contract gate
 *   [docs:nextjs]                          App Router syntax
 *   [docs:tailwindcss]                     arbitrary value var() syntax
 *   [docs:shadcn-ui]                       (when imported)
 */
```

---

*"showcase imports brand.css. Nunca inline. Single source of truth."*
