# el-pulidor — las 5 rúbricas de acabado

> Detalle de los 5 modos de `el-pulidor`. Cada modo es una rúbrica de **auditoría read-only** (AP3): se
> señala el problema y se hace handoff al generador, **nunca se aplica el fix**. Todos los modos comparan
> contra el contrato Brand DNA (`brand/brand.json` + `brand/voice.json`, R-005) y reusan el Anti-Slop Gate
> de `el-evaluador` (R-005 §8.1) — no lo reimplementan. `[memory:CONSTRAINTS.md#AP3]` ·
> `[memory:CONSTRAINTS.md#R10]` · `[memory:references#R-005]`.

- **Versión:** v0.2.0 (D-037 · juez visual fresco en `critique` + modo `cut`; v0.1.0: C1)
- **Consumido por:** `el-pulidor/SKILL.md` (loop de ejecución paso 5).

---

## Modo 1 — critique (evaluación UX/UI holística)

Evaluación **holística** de 1 pantalla o flujo. No busca el pixel: busca si la pantalla **funciona como
experiencia** y si respeta el contrato. Produce veredicto + issues priorizados + **preguntas
provocativas** que el generador debe responder antes de "arreglar".

### Las ~10 dimensiones

| # | Dimensión | Qué se audita | Slop / fallo típico |
|---|-----------|---------------|---------------------|
| 1 | **Jerarquía visual** | ¿hay UNA acción primaria clara? tamaño/peso/color guían el ojo | 3 CTAs compitiendo, todo el mismo peso, primario indistinguible |
| 2 | **AI-slop** (cruza Anti-Slop Gate) | patrones "Claude default" (AP6): purple/indigo, gradiente diagonal, 3 cards centradas, rounded-3xl/shadow-2xl | genérico, sin personalidad de marca, se ve "generado" |
| 3 | **Discoverability** | ¿el usuario encuentra lo que necesita? affordances claras, labels, iconos legibles | acciones escondidas, iconos ambiguos sin label, navegación no evidente |
| 4 | **Information density** | ¿demasiado o demasiado poco? balance whitespace/contenido | pantalla vacía que desperdicia espacio, o muro denso ilegible |
| 5 | **Estados** | ¿están diseñados empty / loading / error / success? | solo el happy path; "no data" es una página en blanco; error crudo |
| 6 | **Accesibilidad** | contraste ≥4.5:1, focus visible, orden de tab, texto alternativo, targets ≥44px | contraste bajo, sin focus-visible, keyboard trap |
| 7 | **Consistencia** | ¿usa los mismos patrones que el resto de la app? mismos componentes, mismo spacing scale | botón custom aquí y componente de impeccable allá, spacings ad-hoc |
| 8 | **Responsive** | ¿se rompe en mobile? reflow, tap targets, overflow | tabla que hace scroll horizontal, texto cortado, targets chicos |
| 9 | **Microcopy / voz** | ¿el copy respeta `voice.json`? tono, CTAs, mensajes de error humanos | "Something went wrong" genérico, CTA marketing-slop ("Allow to never miss out!") |
| 10 | **Momentum / friction** | ¿el flujo tiene fricción innecesaria? pasos de más, confirmaciones redundantes | wizard de 5 pasos para algo de 1, permiso pedido en page-load |

### Veredicto

| Veredicto | Criterio |
|-----------|----------|
| **Ship ✅** | 0 Critical, 0 High. Acabado listo; a lo sumo Medium/Low cosmético. |
| **Polish ⚠️** | Sin Critical, pero ≥1 High (jerarquía o discoverability floja, tokens hardcoded). Pasada de polish/normalize antes de deploy. |
| **Rework ❌** | ≥1 Critical (AI-slop flagrante, a11y rota, estado faltante que rompe UX). Vuelve al generador con preguntas. |

### Preguntas provocativas (obligatorias en critique)

`critique` no solo lista bugs: **provoca decisiones de diseño**. Cada pantalla con veredicto Polish/Rework
lleva 2-5 preguntas que el generador (`impeccable`/humano) debe responder — no las responde `el-pulidor`
(AP3: no decide el diseño, lo cuestiona). Ejemplos:

- "¿Cuál es la ÚNICA acción que querés que el usuario haga aquí? Ahora compiten N."
- "¿Qué ve el usuario cuando no hay datos / cuando falla / mientras carga? Si no está diseñado, es un gap."
- "¿Este componente custom existe por una razón, o reinventa `Card` de impeccable?"
- "El copy dice X — ¿matchea el `tone` de voice.json, o es placeholder?"

### Capa (b) — juez visual fresco (D-037: el juicio no lo hace quien vio el código)

Pedirle al mismo agente que juzgue "su" diseño no funciona: ve su JSX, sus decisiones, su racional
(Khullar et al. 2026, *Self-Attribution Bias*: el sesgo vive en el **formato del turno**, no en el texto
"sé objetivo"). Por eso la estética la juzga **`el-critico-de-diseno`** en contexto vacío:

1. Screenshot **desktop (1440×900) + mobile (390×844)** con agent-browser →
   `.claude/reports/critiques/<pantalla>/iter-k@{desktop,mobile}.png`.
2. Refs opcionales: `brand/moodboard/*.png` (4 elegidas por el tenant — baseline de gusto, NO target).
3. `Agent(el-critico-de-diseno)` con **solo**: rutas de los PNG + la postura del brand en una línea
   (`visual_posture` de `brand.json`) + rutas de refs. **Nada** de código, `src/**`, critiques previas,
   hilo de conversación, ni criterio numérico de parada.
4. El JSON que devuelve (`aesthetic · studio_bar · gaps[] · penalties[] · rank_if_refs[] · score`) se
   guarda en `iter-k.md` y se fusiona con la capa (a) en `UI-CRITIQUE-<pantalla>.md`: los `gaps` de
   ejecución van al handoff; los `gaps` marcados `scope` van al humano (R19).
5. **Cap y paradas** (`QUALITY_GATES.md` §4): `MAX_CRITIC_ITERS=2` (humano puede subir a 4) · parada
   feliz = el producto **gana o empata** el ranking contra las refs (pairwise, con position swap) ·
   no-progreso = el ranking flippea o los gaps se contradicen entre vueltas → devolver al humano ·
   `score` es telemetría, nunca gate. Si tras el cap no hay convergencia: archivar último `iter-k.md` y
   pasar a `cut` con el mejor snapshot. El harness no se queda en loop.
6. **Penalties → gate**: cada penalty del crítico que sea mecanizable (glow-stack, hero-default,
   layout-prop animation, reduced-motion ausente) debe tener eco en `anti-slop-gate.sh` (F-P2.1); las
   que no (label redundante, custom-peor-que-nativo) se quedan como hallazgo del crítico.

STATIC (sin URL/server): la capa (b) se omite con caveat explícito en el reporte — no se "simula" el
juicio visual leyendo JSX.

**Output:** `UI-CRITIQUE-<pantalla>.md` + `.claude/reports/critiques/<pantalla>/iter-k.md`.

---

## Modo 2 — polish (pasada pixel-perfect)

Para una pantalla/componente que ya está "bien de fondo" y necesita el **acabado fino**. 8 categorías,
cada issue con `archivo:línea` + antes/después **conceptual** (NO el patch — AP3). Produce un **checklist**.

### Las 8 categorías

| # | Categoría | Checklist |
|---|-----------|-----------|
| 1 | **Spacing & rhythm** | spacing desde el scale del brand (no px sueltos); ritmo vertical consistente; padding/gap coherentes por grupo |
| 2 | **Typography** | escala tipográfica del brand; line-height legible; jerarquía h1→h6 correcta; sin `font-family` literal (usa `--font-*`) |
| 3 | **Los 8 estados** | por componente interactivo: `default · hover · active · focus-visible · disabled · loading · error · empty` (los que apliquen) — cada uno presente y distinguible |
| 4 | **Micro-interacciones / motion** | transiciones desde `motion.durations` + `motion.personality` del brand; sin motion donde el contexto pide `motion: none` (R-005 §9); respeta `prefers-reduced-motion` |
| 5 | **A11y fina** | focus-visible visible (no `outline: none` a secas); tap targets ≥44px mobile; contraste AA; `aria-*` correcto; nombres accesibles |
| 6 | **Alineación óptica** | alineación real vs. matemática (iconos, texto+icono, baseline); centrado óptico |
| 7 | **Borders / elevation** | radius desde tokens (no `rounded-3xl` default); sombras desde el sistema (no `shadow-2xl` genérico); bordes sutiles consistentes |
| 8 | **Dark-mode parity** | si el brand declara dark mode: contraste y tokens correctos en ambos temas; sin colores que solo funcionan en uno |

### Formato de cada item del checklist

```
- [ ] [High] Button.primary sin estado `loading` — src/shared/components/ui/Button/Button.tsx:34
      Antes: click → sin feedback. Después (conceptual): spinner + disabled durante submit.
      Handoff: impeccable (regenerar variant con estado loading).
```

**Output:** `UI-POLISH-<pantalla>.md`.

---

## Modo 3 — normalize (realinear con el design system)

Cuando una parte de la UI "se salió" del contrato: hex hardcoded, px sueltos, componentes custom que
reinventan los de `impeccable`. `normalize` **detecta el drift y propone el mapeo** — no reescribe.

### Estrategia (en orden)

1. **Detectar hardcoded values** (Grep sobre el target):
   - Colores hex/rgb inline → deben ser `var(--color-*)` de `brand.css`.
   - `px`/`rem` sueltos de spacing → tokens del scale.
   - `font-family` literal → `var(--font-*)`.
   - Clases Tailwind default de color (`bg-blue-500`, `text-purple-600`, `from-indigo-*`) → tokens (AP6).
2. **Detectar componentes custom que duplican impeccable:**
   - Si existe `src/shared/components/ui/<X>` y hay un `<div>`/markup custom que hace lo mismo → proponer
     reemplazo por el componente reusable.
   - Si el componente NO existe en el design system → NO inventarlo (eso es `impeccable`); marcar como
     "candidato a componente" y hacer handoff.
3. **Detectar drift de variants:** un componente que usa una variant no declarada en `component_rules`.
4. **Producir tabla de cambios propuestos** (hardcoded → token, custom → componente), con `archivo:línea`.

### Formato

```markdown
| Ubicación | Actual (drift) | Propuesto (contrato) | Handoff |
|-----------|----------------|----------------------|---------|
| Hero.tsx:12 | `bg-[#6366F1]` | `bg-[var(--color-primary)]` | impeccable |
| Hero.tsx:30 | `<div className="card…">` custom | `<Card variant="default">` | impeccable |
| List.tsx:8 | `text-purple-600` (AP6) | token de brand.css | impeccable |
```

**Degradación:** sin componentes de impeccable materializados, `normalize` solo señala hardcoded values
(no puede proponer mapeo a componentes) y lo advierte en el reporte.

**Output:** `UI-NORMALIZE-<area>.md`.

---

## Modo 4 — redesign (auditoría full-project + plan)

El modo caro: audita **todas** las pantallas del proyecto y produce un **plan ejecutable por fases**. Es el
único modo que **NO** se corre por default — el usuario lo pide explícito. **NO toca código hasta que el
humano aprueba el plan** (es un plan, no una ejecución).

### El flujo

1. **Inventario de pantallas:** Glob de `src/app/**/page.tsx` + `src/features/**/components/` → lista de
   pantallas/vistas con su propósito.
2. **Correr critique (rúbrica de las 10 dims) sobre cada pantalla** — pero consolidado, no un reporte por
   pantalla: una **matriz de deuda de acabado** (pantalla × dimensión → severidad).
3. **Detectar patrones sistémicos** (lo que redesign ve y critique-por-pantalla no):
   - inconsistencias que se repiten (mismo spacing ad-hoc en 8 lugares),
   - componentes custom duplicados a lo largo del proyecto (candidatos fuertes a design system),
   - falta sistémica de estados (ningún form tiene error state),
   - drift de tokens generalizado.
4. **Priorizar** por impacto × esfuerzo → plan por fases.
5. **Plan ejecutable:** cada fase con objetivo, pantallas afectadas, handoff (qué skill ejecuta), y
   estimación relativa. NO el código.
6. **Esperar aprobación humana** antes de cualquier handoff de ejecución.

### Estructura del `REDESIGN-AUDIT.md`

```markdown
# Redesign Audit — <proyecto>

**Fecha:** YYYY-MM-DD · **Auditor:** el-pulidor (advisory, AP3) · **Brand DNA:** R-005
**Veredicto global:** Ship ✅ | Polish ⚠️ | Rework ❌

## 1. Inventario de pantallas (N)
| Pantalla | Propósito | Veredicto |
|----------|-----------|-----------|

## 2. Matriz de deuda de acabado
| Pantalla | Jerarquía | AI-slop | States | A11y | Tokens | … |
| (cada celda: — / Low / Med / High / Crit) |

## 3. Patrones sistémicos (lo que se repite)
- S-01 — <patrón> · afecta N pantallas · severity

## 4. Plan ejecutable (por fases — NO ejecutado)
### Fase 1 — <objetivo> (Critical/High)
- Pantallas: … · Handoff: impeccable | el-golpe · Esfuerzo: S/M/L
### Fase 2 — …

## 5. Próximo paso
→ Aprobá el plan y elegí desde qué fase ejecutar. el-pulidor NO ejecuta (AP3):
  los fixes van a impeccable (componentes) / el-golpe|sprint (pantallas).

## Sources
- [memory:references#R-005] · [memory:CONSTRAINTS.md#AP3] · [memory:CONSTRAINTS.md#R10]
```

**Output:** `REDESIGN-AUDIT.md` (raíz del proyecto o `.claude/reports/`).

---

## Modo 5 — cut (sustracción antes del golden)

La IA **añade**; nunca resta. Pedir "clean, minimalist" no basta: aun así salen glows, highlights
aleatorios, labels junto a fotos que ya comunican, botones custom peores que los nativos (Anshu, calorie
tracker). Restraint = premium. `cut` es el **último paso de Deliver**, obligatorio antes de congelar un
golden screen (`QUALITY_GATES.md` §4). Es un pase con mandato humano: el humano pide el corte (o acepta
la lista de candidatos); `el-pulidor` propone, **no borra** (AP3).

### Checklist de sustracción (por cada nodo visible)

| # | Pregunta | Si la respuesta es "no" |
|---|----------|-------------------------|
| 1 | ¿Este contenedor/card/borde comunica algo que el contenido no comunica ya? | candidato |
| 2 | ¿Este gradiente / glow / glass / blur es la **tesis** del artboard elegido (`CHOSEN.md`) o decoración? | candidato |
| 3 | ¿Este label repite lo que la imagen/ícono/valor ya dice? | candidato |
| 4 | ¿Este control custom es mejor que el nativo (iOS/Android/web)? | candidato (volver a nativo o al kit) |
| 5 | ¿Este highlight/color de texto tiene un motivo del brand o es aleatorio? | candidato |
| 6 | ¿El hero texto-izq/media-der lo autorizó `CHOSEN.md` / `brand.json.hero_layout`, o es el default? | candidato |
| 7 | ¿Este componente ya existe en el kit (`add-ui-kit`/`impeccable`) y se reimplementó? | candidato → normalize |
| 8 | ¿Cada animación respeta `prefers-reduced-motion` y anima solo `transform/opacity` (`motion.ts` SAFE)? | candidato |

Receta de mandato humano (fence reutilizable — Anshu):

```text
Dial this back:
- Simplify the layout into an image-centric grid
- Get rid of gradients, glows, and unnecessary containers
- Kill redundant labels when photos/content already communicate
- Prefer native controls over custom ones that look worse
- Aim for a truly minimalist aesthetic that feels native
No añadas personalidad nueva. No dispares enrich ni video.
```

### Formato

```markdown
| # | Ubicación | Qué se resta | Por qué (checklist #) | Handoff |
|---|-----------|--------------|----------------------|---------|
| C-01 | Hero.tsx:40-58 | glow rosa de fondo + overlay gradient | #2 no es la tesis (CHOSEN: "control panel industrial") | el-golpe |
```

Tras el corte (aplicado por el implementador y con OK humano): screenshot desktop+mobile →
`.claude/reports/critiques/<pantalla>/post-cut@{desktop,mobile}.png` = **candidato golden**. El humano
acepta → `brand/golden/<pantalla>@{desktop,mobile}.png` (F-P2.3). El golden se congela **después** del
cut, nunca en el Discover paralelo (demasiado inestable).

**Output:** `UI-CUT-<pantalla>.md`.

---

## Regla transversal a los 5 modos

- **Cada finding cita el contrato** (`[memory:references#R-005]` para la regla de brand violada,
  `[memory:CONSTRAINTS.md#AP6]` para AI-slop). Sin cita del estándar violado = finding débil (análogo a R8).
- **Cada finding lleva handoff** (quién aplica el fix). Un finding sin handoff no es accionable.
- **NUNCA el patch, solo el antes/después conceptual** (AP3).
- **Anti-Slop Gate reusado**, no reimplementado (owner: `el-evaluador`).
- Hallazgos fuera de acabado → derivar: performance/SEO → `web-quality`; seguridad → `el-guardian`.
