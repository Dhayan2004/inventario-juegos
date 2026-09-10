---
name: add-ui-kit
description: >
  Inicializa el Brand DNA contract de un proyecto target. Discovery interactivo
  (FRESH greenfield + REDESIGN existing) que produce 4 outputs: brand.json
  (R-005 secciones 1-9), voice.json (R-005 sección 9.2), brand.css (CSS vars
  derivadas 1:1 de los tokens) y un visual showcase Next.js que renderiza
  todos los componentes declarados en `component_rules`. 5 presets sirven como
  starting points (Editorial Monocle, Modern Minimal, Warm & Soft, Tech Utility,
  Brutalist Experimental). Sin add-ui-kit operacional, R10 falla para cualquier
  proyecto target — todo skill UI-generator (impeccable, los 5 templates UI
  del catalog `ai/`, y add-* en bloque D) queda bloqueado.
tier: core
requires: PREFLIGHT pasa (AGENTS.md existe). Para Mode REDESIGN, además, repo target con código UI ya escrito.
fallback: Si el proyecto ya tiene UI inconsistente sin Brand DNA declarado → Mode REDESIGN. Si Discovery no llega a respuestas válidas → halt + sugerir el preset que más se acerque al brief informal.
dependencies: [find-docs]
---

# add-ui-kit

> *"Antes del primer componente, el contrato. Sin Brand DNA no hay UI."*
> — Forja R10

Skill de inicialización. Convierte una idea de marca (FRESH) o un código heterogéneo (REDESIGN) en el contrato canónico que TODOS los skills UI-generators consumen aguas abajo.

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md (o AGENTS.md en meta-repo)? Si no → halt: "Forja no instalada. Corré 'make setup'."
2. ¿Existe feature_list.json con feature `add-ui-kit` en active? Si no → halt + sugerir activación.
3. ¿Existe brand/brand.json o voice.json YA POBLADO (no template)? Si sí → ofrecer Mode REDESIGN o abort. NO sobrescribir sin confirmación explícita.
4. ¿Está disponible el reference R-005 (.claude/references/BRAND_DNA_SCHEMA.md)? Si no → halt: "Falta el schema canónico. Forja core inconsistente."

CRÍTICO — Verificar los 3 archivos peligrosos ANTES de ejecutar nada:

5. ¿src/app/globals.css existe Y tiene >10 líneas de contenido propio (CSS vars, @layer, etc.)?
   Si SÍ → proyecto existente con tokens propios detectado → Mode REDESIGN FORZADO.
   Comunicar al usuario: "globals.css tiene contenido del proyecto. REDESIGN mode — no toco ese archivo."

6. ¿tailwind.config.ts existe Y tiene theme.extend.colors o theme.colors con contenido?
   Si SÍ → Mode REDESIGN FORZADO. No reemplazar el archivo.

7. ¿src/app/layout.tsx existe Y tiene imports del proyecto (fonts, providers, Toaster, etc.)?
   Si SÍ → Mode REDESIGN FORZADO. No reemplazar el archivo.

Si alguno de los gates 5-7 se dispara Y el usuario insiste en FRESH → ABORT con mensaje:
"El proyecto tiene codebase existente. Correr add-ui-kit en modo FRESH
 sobreescribiría archivos críticos y destruiría el trabajo existente.
 Opciones: (a) usar Mode REDESIGN, o (b) confirmar explícitamente que el proyecto es greenfield."

CRÍTICO — Gate 8: ¿El proyecto tiene un build sano AHORA mismo?

8. Correr `npm run typecheck` (o `npx tsc --noEmit` si typecheck no está definido en package.json).
   · Si exit 0 → continuar.
   · Si fail → halt con mensaje:
     "Build pre-existente roto. add-ui-kit requiere baseline sano para
      poder detectar correctamente cambios destructivos vs errores
      pre-existentes (efecto lid-on-pot, E-009 causa 3).

      Errores actuales (primeras 20 líneas):
      <stdout de typecheck/tsc>

      Resolvé estos errores primero, luego re-invocá add-ui-kit."
   · Si typecheck no está disponible (proyecto pre-Next.js completo, sin TS configurado):
     fallback a `node -e "require('typescript')"` como sanity check mínimo,
     o skip con warning explícito al usuario:
     "Gate 8 skip: typecheck no disponible. Sin baseline sano, no puedo
      distinguir errores pre-existentes de regresiones introducidas por add-ui-kit.
      ¿Continúo igual? (y/n)".

Cita: [memory:errors#E-009] causa 3 (lid-on-pot effect).
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Tras `la-herreria` con UX Design Workflow llegando a fase UI | la-herreria handoff |
| Carlos pide "armá el design system", "definí el brand", "generá brand.json", "Brand DNA" | Coordinator |
| Carlos pide "pasá esta UI a tokens", "consolidá el design", "redesign" | Coordinator → Mode REDESIGN |
| Cualquier skill UI-generator detecta `brand/brand.json` ausente | skill halt → handoff a add-ui-kit |

## Outputs (los artefactos del contrato)

| Output | Path | Schema source |
|--------|------|---------------|
| Brand schema | `brand/brand.json` | R-005 secciones 1-9 ([memory:references#R-005]) |
| Voice schema | `brand/voice.json` | R-005 sección 9.2 |
| CSS variables | `brand/brand.css` | derivado 1:1 de tokens en brand.json |
| Motion module | `brand/motion.ts` | DURATION / EASING / MOTION / SAFE / UNSAFE / tw / transition() — derivado de motion tokens |
| Visual showcase | `src/app/(brand)/showcase/page.tsx` + `sections/**` | Renderiza el vocabulario de componentes + 7 SaaS patterns |
| Showcase chrome | `src/app/(brand)/showcase/{viewport-toggle,feedback-panel}.tsx` + `actions.ts` | Toolbar viewport + feedback loop (escribe `UI_FEEDBACK.md`) |
| Component contract | `COMPONENT_RULES.md` (raíz del proyecto) | R-005 — las 10 reglas; emitido vía `prompts/emit-component-rules.md` |

Cada output cita `[memory:references#R-005]` como source en su header.

El showcase se compone de:
- **Part 1 — vocabulario:** palette, typography, buttons, inputs, cards, badges, alerts, navigation, loading, tabs, avatars, toast, empty-states, motion, voice (`sections/*.tsx`). `components.tsx` quedó superseded por las secciones granulares — no se importa.
- **Part 2 — SaaS patterns:** kpi-row, data-table, onboarding, sidebar, empty-complete, auth-form, navbar (`sections/saas-patterns/*.tsx`).
- **Chrome:** `ViewportToggle` (desktop/tablet/mobile, `'use client'`), `GlobalFeedbackButton` + `FeedbackForm`/`FeedbackButton` (`feedback-panel.tsx`, `'use client'`), server actions en `actions.ts` (`'use server'`), y un How-To panel colapsable con 2 variantes según `NEXT_PUBLIC_HAS_AGENTATION`.

### Scope exception — COMPONENT_RULES.md en raíz

add-ui-kit normalmente solo escribe en `brand/**` + `src/app/(brand)/showcase/**`. `COMPONENT_RULES.md` es la **única excepción sancionada** que vive en la raíz del proyecto (análoga a `brand/` y `AGENTS.md`). Esta excepción NO afloja la regla para ningún otro archivo de raíz. Las variant lists del contrato (button: primary/secondary/ghost/danger; card: default/interactive/metric/empty) DEBEN matchear las del showcase renderizado.

## Dos modos

### Mode FRESH — proyecto greenfield

Discovery interactivo en 6 bloques. El skill conduce la entrevista, ofrece presets como atajos, y al final genera todos los outputs del contrato (ver tabla Outputs).

> **Si existe `ONTOLOGY.md` (Fase −1) — hereda `marca.*`.** El Brand DNA es la **sub-capa de
> implementación** de la ontología (`ONTOLOGY_SCHEMA` §4). Si la raíz tiene `ONTOLOGY.md` con
> `discovery_completed: true`, toma como **punto de partida** (no preguntes desde cero): bloque (a) ←
> `empresa` + `## Glosario`; bloque (b) ← `marca.arquetipo_primario`/`arquetipo_secundario`; el voice
> (d) ← lenguaje propio + `marca.codigo_simbolico`. Confirma/ajusta con el usuario, no copies a ciegas.
> Si no existe `ONTOLOGY.md`, el discovery opera autónomo igual que siempre (degradación segura).

| Bloque | Pregunta | Default si el usuario duda |
|--------|----------|----------------------------|
| (a) Identidad | nombre, product, tagline, positioning, audience | `ONTOLOGY.md › empresa` si existe, si no el repo actual (package.json, README.md) |
| (b) Archetype | primary + secondary + shadow_to_avoid (Mark+Pearson) | `ONTOLOGY.md › marca.arquetipo_*` si existe, si no Creator + Sage (default Forja-aligned) |
| (c) Posture | 6 ejes 1-5 (density, expression, geometry, warmth, editoriality, materiality) | preset `Modern Minimal` |
| (d) Voice axes | 5 ejes 1-5 (directness, warmth, technicality, provocation, hype) | tone neutro: 3/3/3/3/2 |
| (e) Tokens base | colors, typography, shape, spacing | derivar del preset elegido |
| (f) Anti-slop | confirmar 20 patrones del schema + adicionales del proyecto | el set base de R-005 |

Detalle completo en `prompts/discovery-fresh.md`.

### Mode REDESIGN — proyecto existente con UI inconsistente

| Paso | Acción |
|------|--------|
| 1. Scan | grep over `src/**/*.{tsx,jsx,css,scss}` para detectar valores duplicados/inconsistentes (radius, colors, fonts, spacing) |
| 2. Reporte | tabla de gaps con `<token> → <count occurrences> → <values found>` |
| 3. Estandarización | proponer brand.json que consolide los valores más frecuentes como canónicos |
| 4. Migration plan | listar archivos que necesitan refactor a CSS vars (NO ejecuta, deja al-tajo o el-golpe) |

Detalle completo en `prompts/discovery-redesign.md`.

## Loop de ejecución

```
0. PREFLIGHT halt (incluye gates 5-8: contenido de archivos críticos + health del build pre-existente)

1. Detectar modo (en orden de precedencia):
   ├─ ¿globals.css tiene >10 líneas propias? → REDESIGN FORZADO (contenido-based)
   ├─ ¿tailwind.config.ts tiene theme.extend.colors con contenido? → REDESIGN FORZADO
   ├─ ¿layout.tsx tiene imports del proyecto? → REDESIGN FORZADO
   ├─ ¿src/ tiene >5 archivos UI? → REDESIGN (file-count-based)
   └─ resto → FRESH

2. Mode FRESH:
   a. Read prompts/discovery-fresh.md
   b. Conducir 6-block interview (offrecer presets en (c)/(d)/(e))
   c. Read references/archetypes-mark-pearson.md (lookup table)
   d. Read references/presets.md (lookup table)

3. Mode REDESIGN:
   a. Read prompts/discovery-redesign.md
   b. Scan + report (Bash + Grep)
   c. **Preguntar sub-mode al usuario** (SCAN-ONLY default | MERGE):
      ├─ SCAN-ONLY → continuar con Paso 3 + Paso 4 (consolidación + migration plan)
      │              y handoff a el-tajo / el-golpe para refactors masivos.
      └─ MERGE     → cargar prompts/redesign-merge.md y ejecutar el protocolo
                     de merge no-destructivo sobre los 3 archivos críticos
                     (globals.css, tailwind.config.ts, layout.tsx). Verificación
                     post-merge con typecheck por archivo. Si falla → git restore
                     + halt. Cita [memory:errors#E-009] causa 2.
   d. Confirmar con usuario antes de escribir brand.json

4. Generar (ambos modos):
   a. Read templates/brand.json.template + ejecutar prompts/generate-brand-json.md → escribir brand/brand.json
   b. Read templates/voice.json.template + ejecutar prompts/generate-voice-json.md → escribir brand/voice.json
   c. Antes de generar el CSS o el showcase, invocar find-docs:
      · resolve-library-id("nextjs") + query-docs("app router page route group")
      · resolve-library-id("tailwindcss") + query-docs("v3 config arbitrary values + css vars")
      · resolve-library-id("shadcn-ui") + query-docs("button card input variants")
   d. Read templates/brand.css.template + templates/motion.ts.template + ejecutar prompts/generate-brand-css.md → escribir brand/brand.css + brand/motion.ts
   e. Read templates/showcase/page.tsx + viewport-toggle.tsx + feedback-panel.tsx + actions.ts + sections/** + saas-patterns/** + ejecutar prompts/generate-showcase.md (incluye Paso 1D Agentation detection) → escribir src/app/(brand)/showcase/page.tsx + chrome + sections/ + saas-patterns/
   f. Read templates/COMPONENT_RULES.md.template + ejecutar prompts/emit-component-rules.md → escribir COMPONENT_RULES.md en la raíz del proyecto (scope exception). Las variant lists del contrato DEBEN matchear las del showcase (sync requirement).

5. Devolver al orchestrator con paths de todos los outputs + lista de citations utilizadas.

6. el-evaluador → Three-Layer Verification:
   · L1: brand.json + voice.json + COMPONENT_RULES.md parsean; brand.css + motion.ts parsean; showcase/page.tsx + chrome pasan typecheck + lint
   · L2: schema R-005 cumplido (campos required + bounded ranges); CSS vars 1:1 con tokens; variant lists de COMPONENT_RULES == showcase
   · L3: Anti-Slop Gate — los 12 checks (ver tabla abajo · tests/anti-slop-gate.sh)
```

## Anti-Slop Gate (L3 verificación — 12 checks mecánicos)

**Única fuente ejecutable:** `tests/anti-slop-gate.sh` (owner: `el-evaluador`; `el-pulidor` lo reusa,
`impeccable/prompts/validate-anti-slop.md` aplica el subconjunto por componente). Esta tabla **apunta** al
script, no lo duplica (D-036 single source). 9–12 vienen de F-P2.1 / D-037: las penalties que
`el-critico-de-diseno` nombra en píxeles, el gate las caza en JSX donde es mecanizable.

| # | Check | Corre sobre | Regla |
|---|-------|-------------|-------|
| 1 | `forbidden_colors` | brand.json | primary/accent ∉ `#6366F1 #8B5CF6 #A855F7` (Tailwind purple/indigo) sin justificación en `archetype` |
| 2 | `restricted_hues` | brand.json | hue ∉ [235, 285] salvo `archetype.primary == "Magician"` / `purple_as_primary` declarado |
| 3 | `max_fonts` | brand.json | familias ≤ `validation.max_fonts` |
| 4 | `max_radius_values` | brand.json | radius distintos ≤ `validation.max_radius_values` |
| 5 | `archetype_coherence` | voice.json | `tone_axes` coherentes con `archetype.primary` |
| 6 | `anti_slop_patterns` | brand.json | `anti_slop.forbidden_patterns` ≥ 7 (baseline R-005 §4.1) |
| 7 | `dark_mode` | TSX | cero `bg-white` / `bg-gray-900` / `text-gray-800` hardcodeados — todo vía `--color-*` |
| 8 | `no_modals_inline` | TSX | ningún modal/Dialog envuelve una acción inline (form corto → inline/popover/Sheet) |
| 9 | `glow_stack` | TSX | ningún elemento apila ≥2 de `blur-*` / `bg-gradient-*` / `shadow-<color>-<n>/<a>` / `drop-shadow-*` (el *AI tell* del glow) |
| 10 | `reduced_motion` | TSX | archivos con animación de **movimiento** (`animate-in/out`, `transition-transform/all`, `hover:scale/translate`) manejan `prefers-reduced-motion` (`motion-reduce:` / `motion-safe:` / `useReducedMotion` / `brand/motion`). `animate-spin` (progreso) y `animate-pulse` (skeleton, solo opacidad) exentos |
| 11 | `layout_prop_animation` | TSX | sin `transition-all` ni `transition-[…width\|height\|padding\|margin\|top\|left…]` (lista `UNSAFE` de `motion.ts`). Excepción documentada: `viewport-toggle.tsx` (chrome del showcase) |
| 12 | `hero_default` | TSX | sin hero 2-col texto-izq/media-der **con** paleta índigo/púrpura, salvo `brand.json.hero_layout == "split-authorized"` o `CHOSEN.md` (comentario `hero_layout: authorized`) |

**Negativo obligatorio:** el gate corre 9–12 también sobre `tests/fixtures/sloppy/` y exige que los 4
fallen — un gate que nunca falla es decoración (L-010).

**Rúbrica de `el-evaluador`, NO mecanizada (a propósito):** `max_primary_color_usage_percent` ≤ 18 y
`min_contrast_body` ≥ 4.5 se declaran en `validation` y se juzgan sobre la UI renderizada; `no_slop_gradient`
lo cubren 9 + `validate-anti-slop.md` check 1; "label redundante" y "control custom peor que el nativo"
las ve `el-critico-de-diseno` (píxeles), no el AST — `QUALITY_GATES.md` §4.

Si cualquier check falla → NEEDS_FIX → devolver a add-ui-kit con root cause.

## Reglas operativas

1. **Discovery no se salta.** Mode FRESH siempre conduce las 6 preguntas. Si Carlos provee un brief informal, mapear a respuestas; pero las 6 deben quedar respondidas.
2. **Presets son starting points, no la lengua final.** El output siempre son los 6 ejes numéricos + tokens explícitos, NO un nombre de preset. Esta razón es la base de [memory:decisions#D-006].
3. **Validación whitelist en inputs de Discovery.** Cuando capturamos archetype, posture, voice axes — usar enums + bounded ranges. Aplica [memory:lessons#L-003] (whitelist explícita, no `z.record(z.any())`).
4. **Showcase importa brand.css, no inline-styles.** Single source of truth. Si el showcase necesita un valor que no es token, agregar el token a brand.json primero.
5. **brand.json es el schema canónico, no el README de la marca.** Si una decisión no tiene consecuencia en tokens / posture / component_rules / anti_slop, no entra al JSON. Va a `BRAND.md` o `wiki/`.
6. **find-docs antes de Next.js / Tailwind / shadcn.** R13. Las APIs de cada lib pueden haber cambiado post-cutoff. Citar `[docs:nextjs]`, `[docs:tailwindcss]`, `[docs:shadcn-ui]`.
7. **CRÍTICO — Los 3 archivos del proyecto son INTOCABLES si tienen contenido.** Esta regla aplica independientemente del prefijo de rutas del proyecto (con o sin ``):
   - **`globals.css`** con contenido → NUNCA reemplazar. En REDESIGN: agregar un bloque `:root { --hz-*: ... }` al FINAL del archivo, sin tocar las vars existentes.
   - **`tailwind.config.ts`** con `theme.extend.colors` → NUNCA reemplazar. En REDESIGN: agregar `hz: { ... }` DENTRO del `extend` existente, sin tocar otras claves.
   - **`layout.tsx`** con imports del proyecto → NUNCA reemplazar. En REDESIGN: importar brand.css como `<link>` adicional o agregar la import al final de los imports existentes. NUNCA eliminar fonts, Toaster, o providers existentes.

   Si Discovery REDESIGN identifica refactors necesarios en otros archivos → producir migration plan, no ejecutar.

   **La regla "no tocar archivos fuera de brand/ y showcase/" NO desaparece cuando el proyecto no tiene prefijo ``** — la restricción es conceptual, no de ruta literal.

## Refusals (lo que NUNCA hace)

- ❌ Generar UI sin completar Discovery (FRESH) o sin scan + reporte (REDESIGN).
- ❌ Sobrescribir `brand/brand.json` existente sin confirmación explícita del usuario.
- ❌ Hardcodear colores Tailwind purple/indigo defaults como primary sin justificación de archetype.
- ❌ Generar showcase sin importar `brand.css` (single-source-of-truth violation).
- ❌ Saltar la invocación de `find-docs` antes de generar Next.js / Tailwind / shadcn code (R13 violation).
- ❌ Aplicar más de 2 fonts o más de 3 radius distintos.
- ❌ Producir un showcase que muestre componentes con valores hardcodeados que NO derivan de tokens.
- ❌ **REEMPLAZAR `globals.css`, `tailwind.config.ts`, o `layout.tsx` si tienen contenido del proyecto.** Estos archivos son INTOCABLES cuando tienen >10 líneas propias. Reemplazarlos destruye la codebase existente. Modo REDESIGN → append quirúrgico confirmado. Modo FRESH → solo si el archivo está vacío o es el template inicial de Forja.
- ❌ **Ejecutar Mode FRESH en un proyecto que tiene codebase activa.** Si cualquiera de los 3 archivos tiene contenido → REDESIGN o abort. Nunca asumir proyecto vacío sin verificar.
- ❌ **Adaptar o ignorar la restricción "no tocar archivos fuera de brand/ y showcase/"** porque el proyecto no tiene prefijo ``. La restricción aplica sin importar la estructura de directorios del proyecto.

## Tool filter

Read · Grep · Glob · Bash (find/grep para Mode REDESIGN scan; ejecutar `npx tsc --noEmit` para L1) · Write · Edit en estos paths:

- `brand/*` (incluye `brand/motion.ts`)
- `src/app/(brand)/showcase/**` — incluye explícitamente `viewport-toggle.tsx`, `feedback-panel.tsx`, `actions.ts` y `sections/**` (Part 1 + `saas-patterns/`)
- `COMPONENT_RULES.md` (raíz del proyecto — scope exception sancionada, ver Outputs)
- `.env.local` — SOLO append de `NEXT_PUBLIC_HAS_AGENTATION=true` cuando Paso 1D detecta Agentation (append quirúrgico, nunca reescritura)

NO Edit en `.claude/memory/**` (R5 — solo `el-evaluador`). NO Edit fuera de los paths de arriba. La excepción de `COMPONENT_RULES.md` NO afloja la regla para ningún otro archivo de raíz.

**PROHIBIDO ABSOLUTO — independiente de modo, contexto, o estructura de directorios del proyecto:**
- Write/Edit en `**/globals.css` si el archivo tiene >10 líneas de contenido propio
- Write/Edit en `**/tailwind.config.ts` si tiene `theme.extend.colors` o `theme.colors` con contenido
- Write/Edit en `**/layout.tsx` si tiene imports de fonts, providers, o componentes del proyecto
- En esos 3 casos → Edit de APPEND quirúrgico solo con confirmación explícita del usuario, nunca reescritura completa.

NO Edit en `src/` general (REDESIGN scan reporta, no ejecuta refactors).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | Cualquier output de add-ui-kit cita el schema source |
| Lessons aplicadas | `[memory:lessons#L-002]`, `[memory:lessons#L-003]` | Si el showcase incluye file uploads (L-002) o si los inputs Discovery llevan whitelist (L-003) |
| Constraint source | `[memory:CONSTRAINTS.md#R10]` | Header de SKILL.md y de los outputs |
| External docs | `[docs:nextjs]`, `[docs:tailwindcss]`, `[docs:shadcn-ui]` | Showcase y brand.css cuando referencian sintaxis de cada lib (R13 enforced) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `find-docs` | dependency directa — invocar antes de generar showcase + brand.css |
| `el-evaluador` | post-add-ui-kit ejecuta L1+L2+L3 sobre todos los outputs y corre el Anti-Slop Gate (8 checks) |
| `impeccable` (próximo F3-S2) | consume brand.json + voice.json + brand.css + motion.ts + COMPONENT_RULES.md — sin add-ui-kit no opera |
| `ai/` UI-generators (`chat`, `action-stream`, `generative-ui`) | leen `brand.json` antes de instanciar componentes |
| `add-login`, `add-payments`, `add-emails`, `add-mobile` | los formularios + emails respetan tokens + voice |
| `el-guardian` | NO handoff — add-ui-kit no toca secrets ni genera agentic tools destructivas |

## NO aplica

- **el-guardian handoff:** add-ui-kit produce Brand DNA + showcase estático. No genera agentic tools, no toca secrets, no maneja PII.
- **R14 (destructive tools):** no aplica — el skill no genera tools.
- **L-001 (RLS por user_id):** no aplica — no hay tablas BaaS en este flujo.

## Output handoff

Tras pasar Anti-Slop Gate, devolver al orchestrator con:

```markdown
## add-ui-kit handoff

**Mode:** FRESH | REDESIGN
**Preset baseline:** <name or "custom">
**Outputs generated:**
- brand/brand.json (NNN LOC)
- brand/voice.json (NNN LOC)
- brand/brand.css (NNN LOC)
- brand/motion.ts (NNN LOC)
- src/app/(brand)/showcase/page.tsx + chrome (viewport-toggle, feedback-panel, actions) + 15 sections + 7 saas-patterns (NNN LOC total)
- COMPONENT_RULES.md (raíz — scope exception)
**HAS_AGENTATION:** true | false (variante del How-To renderizada)

**Tokens declared:**
- colors: N tokens
- typography: N families
- shape: N radius values
- spacing: N steps

**Citations:**
- [memory:references#R-005]
- [docs:nextjs] · [docs:tailwindcss] · [docs:shadcn-ui]
- [memory:lessons#L-003] (whitelist validation aplicado a Discovery inputs)

**Next:** invocar el-evaluador para L1+L2+L3 + Anti-Slop Gate.
```

---

*"5 presets como atajos. 6 ejes como lengua final. Tokens como contrato."*
