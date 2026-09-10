# emit-component-rules — brand.json + voice.json → COMPONENT_RULES.md

> Operational prompt. Toma `brand/brand.json` + `brand/voice.json` ya generados, rellena `templates/COMPONENT_RULES.md.template`, y escribe el resultado en la **raíz del proyecto** como `COMPONENT_RULES.md`.
>
> **Sources:** brand.json + voice.json.
> **Template:** `templates/COMPONENT_RULES.md.template`.
> **Output:** `COMPONENT_RULES.md` (project root).
> **Citations en output:** [memory:references#R-005], [memory:CONSTRAINTS.md#R10], [docs:nextjs], [docs:tailwindcss], [docs:shadcn-ui].

---

## Qué es COMPONENT_RULES.md

El contrato escrito que TODO agente UI-generator (`impeccable`, los templates UI de `ai/`, y los `add-*` del bloque D) lee ANTES de crear o modificar un componente. No es un resumen de `brand.json` — es enforcement explícito de las 10 reglas, expresado en el dialecto Forja (CSS-var arbitrary values, módulo de motion del proyecto, voice del proyecto).

Es el complemento legible-por-humano-y-agente del trío `brand.json` (qué) + `brand.css` (cómo, en CSS) + `COMPONENT_RULES.md` (qué NO hacer, en prosa enforceable).

## Input esperado

- `brand/brand.json` — populated y validated (necesario: `brand.product`, `tokens.colors.*`, `tokens.typography.*`, `component_rules.*`, `motion.durations_ms`, `validation`).
- `brand/voice.json` — populated y validated (para el copy guidance de Regla 10 / empty states).

## Output esperado

- `COMPONENT_RULES.md` en la raíz del proyecto target (NO en `templates/`, NO en `src/`).

---

## Excepción de scope (leer dos veces)

add-ui-kit escribe normalmente solo en `brand/**` y `src/app/(brand)/showcase/**`. `COMPONENT_RULES.md` es la **única excepción**: vive en la raíz del proyecto, igual que el directorio `brand/`.

```
proyecto/
├── COMPONENT_RULES.md     ← este output (root, scope exception)
├── brand/
│   ├── brand.json
│   ├── voice.json
│   ├── brand.css
│   └── motion.ts
└── src/app/(brand)/showcase/
```

Justificación: agentes downstream esperan encontrar el contrato en root (igual que `AGENTS.md` / `CLAUDE.md`), no enterrado en `brand/`. La restricción "no tocar archivos fuera de brand/ y showcase/" tiene esta única salida documentada — y solo para este archivo, que add-ui-kit es dueño de generar. No habilita tocar ningún otro archivo root (`package.json`, `tsconfig.json`, `layout.tsx`, etc. siguen intocables).

---

## Procedimiento (5 pasos)

### Paso 1 — Cargar template + JSON

```
1. Read brand/brand.json
2. Read brand/voice.json
3. Read .claude/skills/add-ui-kit/templates/COMPONENT_RULES.md.template
```

### Paso 2 — Resolver substituciones

El template usa pocos placeholders porque la mayoría de los valores visuales son
CSS vars (no se inyectan acá — viven en `brand.css`). Substituir solo lo brand-derived:

| Var | Source |
|-----|--------|
| `{{ brand.product }}` | brand.json.brand.product |
| `{{ generated_at_iso }}` | timestamp ISO actual |
| `{{ mode }}` | FRESH \| REDESIGN (modo activo de add-ui-kit) |
| `{{ baseline_preset }}` | preset baseline (o "custom") |
| `{{ tokens.typography.body.family }}` | brand.json.tokens.typography.body.family |
| `{{ tokens.typography.display.family }}` | brand.json.tokens.typography.display.family |
| `{{ tokens.typography.mono.family }}` | brand.json.tokens.typography.mono.family (default 'ui-monospace') |

### Paso 3 — Sincronizar las reglas con brand.json (NO inventar)

Las Reglas 8/9 listan variantes de Button/Card. Esas listas deben matchear
**exactamente** `brand.json.component_rules.{button,card}.variants`. Si el proyecto
declaró variantes distintas a las del template default (`button: [primary, secondary, ghost, danger]`,
`card: [default, interactive, metric, empty]`), reescribir esas secciones para reflejar
lo declarado. El contrato escrito y el JSON no pueden divergir.

Igual para los tokens de color de Regla 2: la lista debe ser el set real de
`brand.json.tokens.colors` (sin los `| optional` que el proyecto no pobló).

### Paso 4 — Validate L1

Validaciones pre-write:

1. **No hex inline** — grep en el output por `#[0-9a-fA-F]{6}` FUERA de bloques de
   ejemplo marcados como `Incorrecto:`. Los ejemplos negativos (`#3B82F6`, `#6366F1`)
   son intencionales y permitidos; cualquier hex en una regla afirmativa → reject.
2. **No font hardcoded afirmativo** — las únicas menciones a Inter/Roboto/Arial
   deben estar en la Regla 3 como prohibición. Ningún `font-inter` afirmativo.
3. **Variantes consistentes** — las listas de Regla 8/9 == `component_rules.*.variants`.
4. **Markdown parsea** — headings bien formados, code fences cerrados.

### Paso 5 — Write + reportar

1. Write `COMPONENT_RULES.md` en la raíz del proyecto target (overwrite solo si el
   orchestrator confirma; ver edge case abajo).
2. Reportar al orchestrator:
   - path escrito (`COMPONENT_RULES.md`)
   - LOC total
   - Citations utilizadas: [memory:references#R-005], [memory:CONSTRAINTS.md#R10], [docs:nextjs], [docs:tailwindcss], [docs:shadcn-ui]
   - L1 validations result (PASS/FAIL por validación)

---

## Casos edge

### COMPONENT_RULES.md ya existe en root

NO sobrescribir sin confirmación del orchestrator. Puede contener reglas
project-specific agregadas a mano. Ofrecer: (a) regenerar desde cero, o
(b) diff + merge manual. Default: halt + mostrar diff.

### brand.json declara variantes no-default

Reescribir Reglas 8/9 con las variantes reales (Paso 3). Si el proyecto agregó
un componente nuevo a `component_rules` que no tiene regla en el template
(ej: `data_table`, `toast`), agregar una Regla 11+ derivada de sus `rules[]`
+ los universal rules de R-005 sección 8.2.

### voice.json con avoid_words vacíos

La Regla 10 referencia `voice.json` para el copy de empty states. Si está vacío,
mantener la referencia genérica ("directo, sin hype") sin halt — informativo.

### Mono family ausente

Si `tokens.typography.mono.family` no fue poblado, usar 'ui-monospace' (mismo
default que brand.css) en la mención de Regla 3. No halt.

---

## Relación con generate-showcase

`COMPONENT_RULES.md` (este prompt) y el showcase (`generate-showcase.md`) son las
dos caras del mismo contrato: el showcase **muestra** las variantes renderizadas,
COMPONENT_RULES las **declara como ley escrita**. Ambos derivan de `component_rules`
en brand.json — deben quedar sincronizados. Si uno cambia las variantes, el otro
también. Emitir COMPONENT_RULES después de (o junto con) el showcase para que las
listas de variantes coincidan.

---

## Refusals

- ❌ Hardcodear hex / font / spacing en una regla afirmativa (todo es CSS var o placeholder).
- ❌ Escribir el archivo fuera de la raíz del proyecto (no en `brand/`, no en `templates/`, no en `src/`).
- ❌ Tocar cualquier OTRO archivo root — la excepción de scope es solo para `COMPONENT_RULES.md`.
- ❌ Listar variantes de Button/Card que no existan en `brand.json.component_rules`.
- ❌ Sobrescribir un `COMPONENT_RULES.md` existente sin confirmación del orchestrator.
- ❌ Divergir del showcase: las variantes declaradas acá y las renderizadas allá deben matchear.

---

## Citations en el output

El header (comentario HTML al tope de `COMPONENT_RULES.md`) lleva:

```markdown
<!--
  Component Rules — Brand DNA enforcement contract
  Auto-generated by add-ui-kit from brand/brand.json + brand/voice.json.

  Schema source: [memory:references#R-005]
  Citations: [memory:references#R-005] · [memory:CONSTRAINTS.md#R10]
             [docs:nextjs] · [docs:tailwindcss] · [docs:shadcn-ui]
-->
```

---

*"brand.json es el qué. brand.css es el cómo. COMPONENT_RULES.md es el qué nunca."*
