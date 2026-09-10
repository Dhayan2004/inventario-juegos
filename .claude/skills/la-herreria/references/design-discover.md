# design-discover — Discover visual con entropía externa (recetas, on-demand)

> Consumido por `assets/07-ui-design-workflow.md` §"Direcciones visuales (Discover)" y por
> `add-ui-kit/prompts/discovery-fresh.md` bloque (c) opción **semilla**. No es un skill ni un comando:
> es una referencia de recetas (fences) + guardrails. Fuente: Anshu Chimala, *How to turn your AI into a
> world-class designer* (Lenny's, 2026-09-01) + Sakana SSoT (ICLR 2026) + Gu et al. 2026. D-037.
> Cita: `[memory:decisions#D-037]` · `[memory:CONSTRAINTS.md#R19]` · `[memory:CONSTRAINTS.md#R1]`.

## Por qué una semilla y no un adjetivo

Cuatro instancias de Claude Code con el mismo brief de landing colapsan al mismo diseño: gradiente
púrpura, texto a la izquierda, gráfico a la derecha. Pedir "único" o "totalmente al azar" cambia el
barniz, no la estructura (aparecen metáforas de cerámica): el modelo predice el token más probable de
*sonar* aleatorio. Los modelos frontier **sí** convierten una semilla dada en una distribución; **no**
saben inventarla (Gu et al. 2026, *The Illusion of Stochasticity*). Por eso la semilla sale del PRNG del
sistema operativo — `scripts/design-seed.sh` — y el agente solo la **mapea** a una dirección.

Guardrails (no pasos):

- **Prohibido "sé único" como único mecanismo.** Puede ir como color encima de una semilla, nunca en su lugar.
- **Una semilla distinta por variante.** N = 4–5 (≥4 para detectar colapso). Nunca copiar CSS entre `vN`.
- **El string no se revela en la UI.** Provenance en `SEED.md` (`string_in_ui: false`).
- **Diversidad se mide en pantallas, no en semillas:** `node scripts/design-diversity.mjs <run>` — si
  ≥3 de 5 comparten composición, `COLLAPSE`: regenerar con semillas nuevas, no "variar un poco".
- **El SPEC y `.plan/decisions[]` se leen, no se escriben** hasta que el humano elige (`CHOSEN.md`).
  Discover paralelo no viola R1 porque ningún agente escribe el SPEC; un solo writer registra la decisión.
- **Preflight (Nate Herk):** pain / person / promise del SPEC presentes, o no hay Discover visual.
- **Brand DNA en el mapeo, no en el adjetivo:** cada variante emite `posture` (R-005 §1.1) como cualquier
  dirección `custom` de `directions.md`; la ontología (`marca.*`) acota el espacio antes de la semilla.
- **NoveltyBench:** el modelo más grande no es el más diverso — para divergir no hace falta el tier caro
  (`MODEL_PER_ROLE.md`); para juzgar (`el-critico-de-diseno`), sí.

## Receta 1 — semilla → dirección (una por variante)

```text
Sigue este procedimiento:
1. La semilla ya está en design-lab/<run>/vN/SEED.md (la generó scripts/design-seed.sh — NO la
   inventes ni la "mejores").
2. Deriva la dirección creativa (paleta, layout, tipografía, motivo) DE la semilla: busca subpatrones,
   números especiales, repeticiones, cualquier cosa que inspire. Escribe la cuenta en SEED.md (arithmetic).
3. Ejecuta con juicio para que se vea excelente. Emite posture (6 ejes) como contrato.
4. No reveles la semilla en el diseño. Screenshot desktop + mobile en vN/.
```

Contraejemplo a detectar y abortar: cuatro landings con gradiente púrpura, hero texto-izq / gráfico-der,
cerámica. Eso es *prior collapse* → semilla nueva, no retoque.

## Receta 2 — ideas broad + taste notes humanas (Técnica 2)

El humano no dibuja: **elige y recorta**. Las ideas crudas del modelo no valen (cualquiera las tendría).

```text
I want to come up with a bold, unique design language for my product. Can you list as many ideas as
you can, with short, high-level descriptions? Go broad, not deep.
```

El humano reacciona con **taste notes** (esto es texto de SPEC, R19 — vive en `CHOSEN.md`, no en JSX).
Molde (Anshu, "Industrial Control Panel"):

```text
Industrial Control Panel:
- I'm imagining something tactile. Clicky, satisfying buttons, nice sounds.
- Initially I pictured something cartoony or skeuomorphic, but this feels tacky to me. Avoid that.
- Instead, want consistent components and little touches that land this look without going overboard.
- Gray gradients would look boring. Need more texture. Maybe some color, while retaining the control
  panel feel?
Can you sharpen this one based on my tastes?
```

```text
Can you write a concise prompt that an AI agent could use to build an initial POC page with this?
```

El POC prompt se guarda junto a la semilla en la variante elegida y se copia al SPEC cuando el humano
confirma. Ideas que *suenan terribles* van por buen camino: se prueban; si no, se tiran y el prompt va a
`design-lab/failed-prompts.md` (A5: re-test en cada salto de modelo).

## Receta 3 — prompts ambiciosos (calibre, no único camino)

Sirven para probar que el implementador **no se achica**. Si el SPEC (voz, ontología) contradice el
prompt ambicioso, gana el SPEC (R19); el prompt era fixture.

```text
Build me a landing page for my productivity app, with a bold pixel art theme and stunning graphics.
Each section should feel like a still from a video game, yet somehow it should all function as a
landing page.
```

```text
Build me a landing page for my productivity app, set in an isometric living 3D city, where different
features are somehow represented by neighborhoods or buildings.
```

```text
Build me a landing page for my productivity app, with a radically asymmetric layout, dissonant colors
and typography, and uncomfortable negative space. Break all the rules but still make it look good.
```

## Cierre: de artboards a SPEC

1. El humano elige `vN` y escribe `design-lab/<run>/CHOSEN.md` (variante · taste notes · POC prompt ·
   hash del screenshot, del output `--json` de `design-diversity.mjs`).
2. **Un solo writer** registra UNA entrada en `.plan/decisions[]` (`adrRef` → `CHOSEN.md`; seed + hash
   en `rationale`). Las otras variantes se archivan, no se borran.
3. La dirección elegida entra a `add-ui-kit` como dirección `custom` con provenance → `brand.json`.
4. Define/Deliver siguen en `/design` (asset 07) + `el-pulidor critique` (juez fresco) + `cut` + golden
   (`QUALITY_GATES.md` §4). Los goldens **nunca** se congelan en el Discover paralelo.

## Modo B — worktrees (aislamiento fuerte, opcional)

```bash
git worktree add -b design/lab-$(date +%F)-v1 ../<proyecto>-v1 HEAD   # repetir v2..v5
# merge/copy SOLO de la vN ganadora, después de CHOSEN.md
```
