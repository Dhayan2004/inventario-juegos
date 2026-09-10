# Asset #7 — UI Design Workflow

> *"Del User Story a la pantalla concreta. Sin esto, el developer adivina."*

## Qué Hace

Traduce User Stories y escenarios de aceptación en diseños de interfaz concretos antes de que comience la implementación. Toma "qué hace el usuario" y produce "cómo se ve y cómo se comporta" — pantallas, flujos, componentes, estados, y los criterios de aceptación visuales que el código debe cumplir.

**Por qué va antes de UI (asset 08):** los User Stories definen QUÉ. El UI Design Workflow define CÓMO. El asset 08 implementa el resultado visual aplicando Brand DNA (R10). Esta separación evita "developer-driven design" donde el código dicta la UX.

---

## Inputs Requeridos

- `USER-STORIES-[nombre].md` — del asset 05.
- `VPC-[nombre].md` — del asset 01. Jobs, pains y gains para guiar prioridades.
- `docs/ux-research/` — del asset 04.
- `docs/ux-design/` — del asset 06 (IA + interaction patterns + usability evaluation + onboarding).

---

## Referencias (deferred F-tighten)

- `.claude/skills/la-herreria/references/scenario-to-ui.md`
- `.claude/skills/la-herreria/references/screen-flows.md`
- `.claude/skills/la-herreria/references/component-selection.md`
- `.claude/skills/la-herreria/references/acceptance-targets.md`
- `.claude/skills/la-herreria/references/design-discover.md` (Discover con semilla — recetas, on-demand)

---

## Workflow

### Paso 1: Extraer Requisitos de UI desde User Stories

Para cada story con UI, extraer:
- **Pantallas** — qué vistas o páginas son necesarias.
- **Entry points** — cómo llega el usuario a cada pantalla.
- **Datos mostrados** — qué información aparece.
- **Acciones disponibles** — qué puede hacer el usuario.
- **Cambios de estado** — cómo responde la pantalla a las acciones.
- **Estados de error** — qué ve el usuario cuando algo falla.

**Filtro de scope:**
¿La story tiene UI? → seguir el workflow.
¿Es solo API o procesamiento background? → saltar.
**Señal en criterio de aceptación:** si dice "el usuario ve / puede / referencia una pantalla" → tiene UI.

**Output:** documento `## UI Requirements: [Feature]` con las 6 categorías por story.

---

### Paso 2: Diseñar Screen Flows

Mapear los requisitos en un flujo conectado de pantallas.

**Principios:**
- Seguir al usuario, no a la feature — ordenar pantallas por el camino que camina el usuario.
- Una screen flow por feature (o por epic si agrupa stories relacionadas).
- Diseñar primero el walking skeleton — la versión mínima viable.
- Anotar con referencias a las stories — cada decisión traza a una story.

**Estructura de cada pantalla:**

```
### [Nombre de Pantalla]

**Entry from:** [Pantalla anterior] via [acción]
**Story refs:** [Story ID], criterio: [descripción]

#### Layout
[ASCII / prosa — qué está arriba, medio, abajo.]

#### Data Displayed
| Elemento | Fuente | Formato |
|----------|--------|---------|

#### Actions
| Acción | Control | Resultado |
|--------|---------|-----------|

#### States
- Default / Loading / Empty / Error / Success
```

**Output:** `docs/ui-design/screen-flows/[feature-name].md` por feature.

---

### Paso 3: Seleccionar Componentes

Para cada pantalla, identificar qué componentes del design system se necesitan y cuáles hay que crear nuevos.

**Árbol de decisión:**
1. ¿Existe un componente en el design system (`brand/component_rules.json`, output de impeccable BATCH) que hace esto? → usarlo.
2. ¿Se puede componer desde componentes existentes? → componer.
3. ¿Aparecerá en más de una pantalla? → crear componente nuevo con spec; planificar handoff a `impeccable` Mode UNKNOWN para derivación R-005 sec 8.2.
4. ¿Es solo esta pantalla? → implementar inline (no es componente reusable).

Para componentes nuevos: crear spec en `docs/ui-design/components/[nombre].md`.

**R10 contract:** los componentes existentes ya consumen `brand/brand.json` tokens. Componentes nuevos deben hacerlo también — no Tailwind defaults.

---

### Paso 4: Definir Acceptance Targets

Traducir las decisiones de diseño en resultados observables y verificables. Estos se convierten en los criterios de aceptación visuales que el código debe cumplir.

**Qué es testeable:**
- Elemento presente en pantalla.
- Elemento contiene texto o datos específicos.
- Elemento en estado específico (visible, oculto, disabled, focused).
- Acción produce resultado específico (navegación, cambio de estado).
- Mensaje de error aparece en respuesta a input inválido.
- Relación de layout (elemento A aparece antes que B).

**Qué NO es testeable** (dejar a revisión visual + Anti-Slop Gate):
- Colores exactos (a menos que tengan significado semántico: error=rojo).
- Spacing o márgenes precisos (verificación vía visual diff vs `brand.json` en Layer 3).
- Timing de animaciones.

**Output:** sección `## Acceptance Targets` al final de cada screen flow. Estos targets alimentan el e2e (Layer 3, R7) post-implementación.

---

### Paso 5: Verificar Completitud

```
✅ Todos los epics/stories con UI tienen al menos un screen flow
✅ Cada pantalla tiene: entry point, data, actions, states, error states
✅ Todos los componentes identificados (existentes en component_rules.json o nuevos)
✅ Acceptance targets definidos para cada decisión de diseño significativa
✅ Empty states y error states diseñados (no solo el happy path)
✅ Casos móviles anotados si el producto es mobile-first (según journey maps)
```

---

## Estructura de Output

```
docs/ui-design/
├── screen-flows/
│   ├── [epic-o-feature-1].md
│   └── [epic-o-feature-2].md
└── components/
    └── [nuevo-componente].md
```

---

## Naming Convention

| Documento | Archivo |
|-----------|---------|
| Screen Flow | `docs/ui-design/screen-flows/[feature-kebab].md` |
| Component Spec | `docs/ui-design/components/[ComponentName].md` |

---

## Reglas Críticas

- **No diseñar pantallas que ninguna story requiere.** Cada pantalla traza a una story.
- **No saltar empty states y error states.** Estos son los momentos más críticos de UX.
- **Máximo 7 acciones primarias por pantalla.** Más indica que la pantalla hace demasiado.
- **Mobile-first si el journey map muestra uso en móvil.**
- **Los modelos mentales del asset 04 dictan la IA.** Si el usuario piensa en "documentos", la nav refleja documentos — no estados de base de datos.
- **Componentes nuevos delegan a `impeccable` Mode UNKNOWN para derivación R-005.**

---

## Integración con Assets Upstream/Downstream

| Asset | Conexión |
|-------|----------|
| UX Research (#4) | Personas determinan para quién diseñar. Journey maps revelan momentos críticos. Modelos mentales dictan IA |
| User Stories (#5) | Criterios de aceptación → input principal de extracción de UI |
| UX Design (#6) | IA y interaction patterns definen estructura y comportamiento de cada pantalla |
| UI (#8) | Consume screen flows y acceptance targets para implementar el diseño visual final con Brand DNA (R10) |
| Blueprint (#10) | Componentes nuevos identificados aquí se convierten en tasks de implementación |

---

## Direcciones visuales (Discover) — entropía externa, gusto humano (D-037)

Cuando el proyecto necesita **salir del prior** (landing, marca nueva, "que no se vea generado"), antes de
`/design` se corre un Discover paralelo. Es un guardrail, no un pipeline — recetas en
`references/design-discover.md`:

- **Preflight:** pain / person / promise del SPEC presentes (Fase 0). Sin eso no hay Discover visual.
- **Semilla de shell, nunca in-head:** `bash scripts/design-seed.sh <slug> 5` crea
  `design-lab/<fecha>-<slug>/v1..v5/SEED.md` con PRNG del SO. Cada variante mapea SU semilla a una
  dirección (paleta · layout · tipo · motivo) y emite `posture` (R-005 §1.1). "Sé único" está prohibido
  como único mecanismo; el string no se revela en la UI.
- **Aislamiento (R1/R5):** cada variante vive en su `vN/` (o worktree); nadie copia CSS entre variantes;
  nadie escribe el SPEC ni `.plan/decisions[]` hasta que el humano elige.
- **Diversidad medida en pantallas:** `node scripts/design-diversity.mjs design-lab/<run>` — `COLLAPSE`
  (≥3/5 misma composición) invalida el batch: semillas nuevas, no retoque.
- **El humano elige (R19):** `CHOSEN.md` = variante + taste notes (molde "Industrial Control Panel") +
  POC prompt + hash del screenshot. **Un solo writer** registra UNA entrada en `decisions[]`
  (`adrRef` → `CHOSEN.md`). Las 5 direcciones canónicas de `add-ui-kit/references/directions.md` siguen
  siendo el atajo cuando el prior basta; la semilla es la opción `semilla` del bloque (c).
- **Goldens nunca aquí:** se congelan después de `cut` (`QUALITY_GATES.md` §4).

---

## Artboards visuales con `/design` (host Claude Code — opcional, recomendado)

Si el host es **Claude Code con el skill nativo `/design` disponible** (research preview, ago-2026),
los screen flows de este asset se materializan como **artboards editables** antes de implementar:

1. Correr `/design <feature>` DESPUÉS de tener screen flows + acceptance targets (este asset) y el
   Brand DNA vigente — `/design` lee el design system del proyecto vía `CLAUDE.md`/theme, así que
   `brand.json` + `brand.css` deben existir (R10 aplica igual que en el asset 08).
2. El humano **elige y ajusta visualmente** el artboard en el canvas publicado (click-to-select,
   propiedades, texto inline) — esta es SU parte del contrato R19: decide el QUÉ visual sin tocar código.
3. El artboard elegido se convierte en el acceptance target visual del asset 08: la implementación
   consume el artboard + Brand DNA; el acabado lo juzga `el-pulidor critique` (juez visual fresco, cap 2)
   y el golden se congela tras `cut` (`QUALITY_GATES.md` §4) — no hay pixel-diff.

**Degradación segura:** sin `/design` en el host (Codex, Hermes, versiones viejas), este paso se salta
y el flujo original (screen flows en markdown → asset 08) sigue intacto. `/design` acelera, no es dependencia.

---

## Handoff al Asset #8

```
✅ Screen flows: [N] features documentadas
✅ Componentes nuevos: [N] specs creadas / [ninguno]
✅ Acceptance targets: definidos por pantalla

Siguiente: UI (asset 08-ui.md)
Antes de leer 08-ui.md, R10 Brand DNA gate: si brand/brand.json o
voice.json no existen, halt + handoff a add-ui-kit.

Después: tomará screen flows y aplicará principios de diseño visual
para producir la implementación UI final consumiendo Brand DNA.

¿Procedemos?
```
