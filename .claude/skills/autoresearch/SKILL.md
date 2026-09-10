---
name: autoresearch
description: >
  Loop opt-in de auto-mejora de la CALIDAD de un skill existente del harness
  (estilo Karpathy: una variable → mide → keep/discard). Úsalo sólo cuando el
  humano pide explícitamente "corré autoresearch sobre <skill>" / "auto-tuning
  de <skill>". Corre bajo safety caps duros en rama dedicada con juez aparte
  (el-evaluador, AP3). NO crea skills (skill-creator) ni firma features
  (el-evaluador). Detalle en el cuerpo + references/autoresearch-loop.md.
tier: hidden
requires: git limpio (working tree sin cambios sin commitear) en el repo del harness · un SKILL_AUTHORING target existente en `.claude/skills/<target>/SKILL.md` · budget explícito confirmado por el humano (default cap $5) · Node disponible para correr los criterios · el-evaluador presente como juez independiente
fallback: si el working tree NO está limpio → halt (no se puede aislar la variable con cambios sin commitear). Si el target no existe en el registry (`skills.md`) → halt (R6). Si no hay criterios binarios definibles para el skill → halt (sin métrica no hay keep/discard objetivo). Si `el-evaluador` no está disponible como juez → halt (AP3: el generador NO se auto-evalúa). Si estás en `main`/`master` → halt (los caps prohíben mutar en la rama principal).
dependencies: [el-evaluador]
---

# autoresearch

> *"El harness se mejora a sí mismo, pero nunca a solas y nunca a ciegas: una variable, una rama, un juez aparte, un presupuesto, y un backup. Sin eso, no corre."*
> — C6 (autoresearch, la mitigación de D-024)

Meta-skill de **auto-mejora del harness**. Porta el loop self-improving de Forge Pro (evals binarias +
mutación de prompt + benchmark) **adaptado a Forja**: reencuadrado como **opt-in con AP3 explícito**, que es
exactamente la mitigación que dejó abierta `[memory:decisions#D-024]` ("evaluar portar autoresearch como
skill `_opcionales/` con AP3 explícito documentado"). El loop de Karpathy — *analizar fallo → hipótesis →
un cambio → medir → keep/discard* — sólo es admisible en Forja bajo caps duros y con el generador separado
del juez. Este SKILL es el runbook; la doctrina extendida vive en
[`references/autoresearch-loop.md`](references/autoresearch-loop.md).

> **El invariante maestro — léelo antes de cualquier modo.** autoresearch **NUNCA** se auto-invoca (opt-in),
> **NUNCA** corre en `main`, **NUNCA** muta el frontmatter de un SKILL.md, **NUNCA** escribe
> `.claude/memory/**` (R5), y **NUNCA** deja que el generador juzgue su propio output (AP3 — el juez es
> `el-evaluador`, independiente). Si alguno de esos no se cumple → halt. Ver §"Safety caps (refusals)".

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Working tree limpio? `git status --porcelain` vacío. Si no → halt:
     "Hay cambios sin commitear. autoresearch aísla UNA variable por commit; commiteá o descartá primero."
3. ¿Rama dedicada (NO main/master)? `git rev-parse --abbrev-ref HEAD`. Si es main/master → halt:
     "autoresearch corre en rama dedicada. Creá `git switch -c autoresearch/<target>` primero."
4. ¿Target válido? `.claude/skills/<target>/SKILL.md` existe Y está en `skills.md` (R6). Si no → halt.
5. ¿Backup + gitignore del scratch? Si no existe `<target>/SKILL.md.backup` → crearlo AHORA (`cp`) antes de
   la 1ª mutación. Y verificar que `.gitignore` excluya `**/autoresearch-results.tsv` y `**/SKILL.md.backup`
   (agregar si faltan): así son **untracked** y el `git reset --hard "$BASE"` del discard NO los borra (el
   reset sólo revierte archivos tracked). El `.tsv` se appendea DESPUÉS del keep/discard, ya fuera del reset.
6. ¿el-evaluador disponible como juez? (R6 sobre `el-evaluador`). Si no → halt (AP3).
7. ¿Budget confirmado? El humano confirma el cap de gasto (default $5). Sin confirmación → halt (opt-in).
8. ¿Criterios binarios definibles (3–6) para el target? Si no → halt (sin métrica objetiva no hay keep/discard).
```

PREFLIGHT es **halt-blocked en TODOS los gates** (a diferencia de otros skills que degradan): un loop de
auto-mutación sin caps es precisamente lo que D-024 vetó. Sin las 8 condiciones, no arranca.

## Activación

| Cuándo | Quién |
|--------|-------|
| El humano dice **explícitamente** "corré autoresearch sobre `<skill>`", "mejorá el skill X con el loop", "auto-tuning de `<skill>`" | Carlos (opt-in) |
| Un skill tiene fricción de calidad medible y recurrente que amerita iteración sistemática | Carlos, tras decidir invertir budget |

**NUNCA se invoca automáticamente.** No está en el Decision Router de `CLAUDE.md`, no lo dispara ningún
hook, ningún otro skill lo llama en su pipeline. Es `tier: hidden` a propósito (equivale al `_opcionales/`
con opt-in de la mitigación D-024). NO se usa para: crear un skill nuevo (eso es `skill-creator`), firmar
una feature (eso es `el-evaluador`), auditar seguridad (eso es `el-guardian`), ni tocar código de la app
(autoresearch sólo itera el CUERPO de un SKILL.md).

## El loop (self-improving, estilo Karpathy)

Detalle completo en [`references/autoresearch-loop.md`](references/autoresearch-loop.md). Por iteración,
hasta `target_score` o `max_iterations`:

```
0. GUARD: re-chequear caps (iter < 30 · gasto acumulado < budget · len(prompt) < 2× baseline) **Y la rama**
   — `git rev-parse --abbrev-ref HEAD` sigue siendo la rama dedicada, NUNCA `main`/`master` (por si algo la
   cambió a mitad del loop). Si algún cap se excede o la rama cambió → STOP limpio (no es error: es el
   diseño). Restaurar best-known y reportar. Luego capturar `BASE=$(git rev-parse HEAD)` — el SHA
   pre-mutación EXACTO de esta iteración, para un discard a prueba de no-ops (nunca `HEAD~1`).

1. ANALIZAR fallos previos: leer las últimas filas de `autoresearch-results.tsv` del target — qué criterio
   falló y en qué inputs. (En la iter 1 no hay historia: se parte del baseline medido.)

2. HIPÓTESIS: una sola, falsable, en la forma "si cambio X en el cuerpo, mejora Y, porque Z". Se escribe al
   log ANTES de mutar (para que el keep/discard sea honesto, no post-hoc).

3. MUTAR UN solo cambio en el CUERPO del SKILL.md (una sección, un ejemplo, una regla, un refusal).
   ❌ NUNCA el frontmatter (name/description/tier/requires/fallback/dependencies) — lo parsea inventory.js
   y lo consume el registry; mutarlo rompe el contrato del harness.

4. COMMIT pre-ejecución (aislar la variable): `git commit -m "chore(autoresearch): <hipótesis-corta>"`.
   Un cambio = un commit → keep = dejar el commit; discard = `git reset --hard "$BASE"` vuelve al SHA
   pre-mutación capturado en el paso 0. (Si la mutación resultó no-op, no habrá commit — no importa: el
   discard resetea a `$BASE`, no a `HEAD~1`, así que jamás borra un commit legítimo previo.)

5. GENERAR N outputs del skill mutado con inputs VARIADOS (los fixtures del target). El generador es el
   propio skill bajo prueba.

6. EVALUAR con los criterios BINARIOS (3–6, custom por skill): cada uno pasa/falla (0/1), sin escala difusa.
   El JUEZ es `el-evaluador` (independiente del generador — AP3). `score = Σ criterios_pass / (N·|criterios|)`.

7. DECIDIR:
     score > best  → KEEP: se queda el commit; best = score; backup se actualiza al nuevo mejor.
     score ≤ best  → DISCARD: `git reset --hard "$BASE"` (el SHA capturado en el paso 0 — estado
                     pre-mutación EXACTO; jamás `HEAD~1`, que borraría un commit legítimo si la mutación fue no-op).

8. APPEND una fila a `<target>/autoresearch-results.tsv` (iter, hipótesis, score, best, decisión, gasto).
   Volver a 0.
```

Al terminar (target_score, cap, o sin hipótesis nuevas): dejar el SKILL.md en el **best-known**, reportar
el diff neto acumulado al humano, y proponer a `el-evaluador` (no escribir tú) cualquier lección emergente.

## Criterios binarios (el corazón del keep/discard)

- **3–6 por skill, custom, BINARIOS** (pasa/no-pasa). Ejemplos genéricos: "¿el output cita con la gramática
  correcta (R9/R13)?", "¿respeta el tool filter declarado?", "¿el PREFLIGHT halt dispara en el input que
  debe?", "¿el output NO excede el largo objetivo?". El set concreto se define con el humano al arrancar.
- **Sin escalas difusas** ("qué tan bueno"): un criterio difuso no da keep/discard reproducible → sesga el
  loop hacia el ruido. Binario o no entra.
- **El juez ejecuta los criterios como checks, no como opinión** — donde se puedan automatizar (`grep`,
  `node`, un assert), se automatizan; donde no, `el-evaluador` los aplica con rúbrica fija y cita evidencia.

## Safety caps (refusals — NO negociables)

Estos caps SON el skill: sin ellos, autoresearch es lo que D-024 vetó. Cada uno es un **refuse hard**:

- ❌ **>30 iteraciones.** `max_iterations = 30`. Al llegar → STOP limpio, restaurar best-known.
- ❌ **Gasto > budget.** `budget` default **$5**, confirmado por el humano (opt-in). Se estima por iteración
   y se acumula en el `.tsv`; al proyectar exceso → STOP antes de gastarlo.
- ❌ **Crecimiento del prompt > 2× del baseline** (anti-bloat, lección Vercel "-80% tools = +3×"). Si una
   mutación empuja el SKILL.md por encima de 2× su tamaño inicial → discard automático de esa mutación.
- ❌ **Correr sin backup.** `<target>/SKILL.md.backup` es obligatorio antes de la 1ª mutación; si no existe
   → no se muta.
- ❌ **Correr en `main`/`master`.** Sólo en rama dedicada (`autoresearch/<target>`). PREFLIGHT lo gatea Y el
   GUARD (paso 0) re-verifica la rama cada iteración antes de cualquier `reset --hard` (defensa en profundidad).
- ❌ **Auto-invocarse.** Opt-in puro: sólo por pedido explícito del humano. Ningún hook, ningún pipeline.
- ❌ **Mutar el frontmatter** de cualquier SKILL.md (rompe inventory.js + el registry). Sólo el cuerpo.
- ❌ **Escribir `.claude/memory/**`** (R5 — sole writer = `el-evaluador`). Si emerge lección → handoff, no escritura.
- ❌ **Auto-evaluar** (AP3): el generador (el skill bajo prueba) NUNCA es su propio juez. Juez = `el-evaluador`.
- ❌ **Tocar código de aplicación** (`src/**`, `scripts/**`) o skills que NO son el target (`el-evaluador/**`,
   `skill-creator/**` están explícitamente fuera de límites).
- ❌ **`--no-verify`** para saltarse hooks (AP2).

## Refusals (lo que NUNCA hace)

- ❌ Arrancar sin las 8 condiciones del PREFLIGHT (working tree limpio, rama dedicada, target válido, backup,
   juez independiente, budget confirmado, criterios definibles).
- ❌ Cambiar más de UNA variable por iteración (rompe el aislamiento → keep/discard deja de ser causal).
- ❌ Declarar keep sin score del juez independiente (AP5 — narrative completion: "quedó mejor" no cuenta).
- ❌ Rellenar el `.tsv` con scores inventados — cada fila cita el veredicto real de `el-evaluador`.
- ❌ Seguir corriendo tras exceder un cap "porque estaba cerca del target" (los caps son duros, no sugerencias).
- ❌ Dejar el SKILL.md en un estado intermedio peor que el baseline (al cerrar, siempre queda el best-known).

## Tool filter

`Read · Grep · Bash (git, node) · Edit`

- **Edit/Write:** SÓLO `.claude/skills/<target>/SKILL.md` (cuerpo, no frontmatter) + su `<target>/autoresearch-results.tsv`
  + su `<target>/SKILL.md.backup`. **NUNCA** ningún otro archivo.
- **Bash:** `git` (status, add, commit, `reset --hard "$BASE"`, rev-parse) y `node` (correr los criterios
  binarios automatizables). **NUNCA** cambiar de rama durante el loop — `git switch`/`git checkout` de rama
  están PROHIBIDOS: la rama se fija en PREFLIGHT y no cambia (crear la rama es paso previo del humano, no del
  skill). **NUNCA** `git push`, **NUNCA** comandos destructivos fuera del `reset --hard "$BASE"` del propio loop.
- **NO** Edit/Write en `.claude/memory/**`, `feature_list.json`, `src/**`, ni en `main`.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Decision | `[memory:decisions#D-024]` | en SKILL.md + references (autoresearch se re-admite como la mitigación de D-024) |
| Constraint | `[memory:CONSTRAINTS.md#AP3]` | juez independiente (self-eval prohibido) |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | no escribe memory (sole writer = el-evaluador) |
| Constraint | `[memory:CONSTRAINTS.md#AP2]` | no `--no-verify` |
| Constraint | `[memory:CONSTRAINTS.md#R6]` | valida el target contra el registry antes de mutarlo |
| Reference | `[docs:git]` | comandos de commit/reset citados vía find-docs si el runbook necesita freshness |

Toda lección o error que emerja del loop se **propone** a `el-evaluador` con esta gramática — autoresearch
no la escribe (R5). El próximo ADR sugerido (que registra `el-evaluador`, no este skill) documenta la
re-admisión: "autoresearch re-admitido como skill opt-in con AP3 — supersede la Decision de no-port de D-024".

## Integraciones

- **`el-evaluador`:** juez independiente de los criterios binarios (AP3) + único writer de cualquier lección
  emergente (R5). autoresearch le hace handoff, no escribe memory.
- **`skill-creator`:** complementario, no solapado — `skill-creator` **crea** el scaffold de un skill nuevo;
  autoresearch **itera la calidad** de un skill ya existente. Un skill nace con skill-creator, madura con autoresearch.
- **`skills.md` (registry):** autoresearch valida el target contra el registry (R6) antes de mutarlo, y NO
  lo edita (eso es de `el-evaluador`).
- **`inventory.js`:** por eso el frontmatter es intocable — inventory.js lo parsea para el ROADMAP; mutarlo
  desincroniza el inventario del repo real.
- **`references/MODEL_PER_ROLE.md`:** guía opcional — si se corre autoresearch, el juez (evaluación difícil)
  encaja en el tier "Opus piensa" y la generación mecánica de outputs en "Haiku rellena" (default: heredar
  el modelo de sesión, no forzar).

---

*"D-024 dijo 'no, todavía no'. C6 dice 'sí, pero sólo así': opt-in, una rama, una variable, un juez aparte,
un presupuesto y un backup. Esa es la diferencia entre auto-mejora y auto-sabotaje."*
