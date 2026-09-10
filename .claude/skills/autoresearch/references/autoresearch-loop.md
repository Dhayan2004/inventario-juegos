# autoresearch — el loop self-improving (doctrina extendida, C6)

> **Qué es esto.** El detalle del loop de auto-mejora que el skill `autoresearch` ejecuta sobre un SKILL.md
> target: el porte del loop de Forge Pro (evals binarias + mutación de prompt + benchmark) **adaptado a
> Forja** como opt-in con AP3 explícito. Es la materialización de la *Mitigation* que dejó abierta
> `[memory:decisions#D-024]`. Este doc es la doctrina; el runbook operativo es el SKILL.md.

- **Versión:** v0.1.0 (2026-06-30, C6 · autoresearch + modelo-por-rol)
- **Lo consume:** el skill `autoresearch` (`/autoresearch`). Juez: `el-evaluador` (AP3). Registry: `skills.md`.
- **Reglas de enforcement:** `[memory:CONSTRAINTS.md#AP3]` (juez ≠ generador) · `[memory:CONSTRAINTS.md#R5]`
  (no escribe memory) · `[memory:CONSTRAINTS.md#AP2]` (no `--no-verify`) · `[memory:CONSTRAINTS.md#R6]`
  (target válido en el registry).

---

## 1. Por qué D-024 lo vetó y por qué C6 lo re-admite

`[memory:decisions#D-024]` descartó autoresearch de Forja porque un **loop autónomo sin humano** viola AP3
(self-eval del generador) y roza R4 (fat orchestrator). Pero la misma ADR dejó una puerta: su *Mitigation*
dice explícitamente "evaluar portar autoresearch como skill `_opcionales/` con AP3 explícito documentado".

C6 ejecuta esa mitigación. La diferencia entre el autoresearch vetado y el admitido no es el algoritmo — es
el **encuadre**:

| Dimensión | autoresearch vetado (Forge Pro) | autoresearch admitido (Forja C6) |
|---|---|---|
| Invocación | podía correr autónomo | **opt-in puro**, sólo por pedido humano explícito |
| Juez | el propio loop se auto-evaluaba | **`el-evaluador`, independiente** (AP3) |
| Alcance del cambio | libre | **una variable por commit** (aislamiento causal) |
| Rama | cualquiera | **rama dedicada, nunca `main`** |
| Presupuesto | ilimitado | **cap $5 + 30 iter + 2× prompt** (duros) |
| Reversibilidad | difusa | **`git reset --hard "$BASE"`** exacto por discard |
| Memoria | escribía resultados donde fuera | **no toca `.claude/memory/**`** (R5); handoff a `el-evaluador` |

Sin ese encuadre, autoresearch es auto-sabotaje. Con él, es auto-mejora acotada y auditable.

## 2. El algoritmo en detalle (el ciclo de Karpathy)

El patrón mental es el de Karpathy que ya cita `CLAUDE.md` ("piensa antes de codificar → simplicidad primero
→ cambios quirúrgicos → orientado a metas"), aplicado al propio prompt de un skill:

```
setup:  baseline = medir(target, criterios, fixtures)   # score de partida, sin mutar
        best = baseline ; iter = 0 ; gasto = 0 ; len0 = len(SKILL.md)
        backup  = cp SKILL.md SKILL.md.backup           # obligatorio

loop while (best < target_score) and (iter < 30) and (gasto < budget):
   0. guard      → caps (iter<30 · gasto<budget · len<2×len0) + rama sigue siendo la dedicada (no main/master)
                   BASE=$(git rev-parse HEAD)   # SHA pre-mutación; el discard resetea a BASE, nunca a HEAD~1
   1. analizar   → leer autoresearch-results.tsv: ¿qué criterio falla más y en qué inputs?
   2. hipótesis  → UNA, falsable: "si cambio X, mejora Y, porque Z" (se escribe al log ANTES de mutar)
   3. mutar      → UN cambio en el CUERPO del SKILL.md (nunca frontmatter)
                   guard anti-bloat: si len(SKILL.md) > 2×len0 → discard inmediato, no evaluar
   4. commit     → git add <target>/SKILL.md ; git commit -m "chore(autoresearch): <hipótesis-corta>"
   5. generar    → N outputs del skill mutado con inputs variados (fixtures)
   6. evaluar    → el-evaluador aplica los criterios binarios → score = Σpass / (N·|criterios|)
   7. decidir    → score > best ? KEEP (best=score) : DISCARD (git reset --hard "$BASE")
   8. log        → append fila al .tsv ; iter++ ; gasto += estimado_iter

teardown: dejar SKILL.md en best-known ; reportar diff neto ; proponer lección a el-evaluador (no escribir)
```

**Un cambio = un commit** es lo que hace el keep/discard *causal*: como sólo una variable se movió, el
delta de score se le atribuye a ella, y `git reset --hard "$BASE"` la revierte sin residuos. Cambiar dos
cosas a la vez rompe la inferencia (no sabés cuál ayudó) — por eso es refuse hard en el SKILL.

## 3. Los criterios binarios (por qué binarios)

Una escala difusa ("del 1 al 10, ¿qué tan claro es el skill?") no da keep/discard reproducible: dos corridas
del mismo output dan números distintos y el loop persigue ruido. Un criterio **binario** (pasa/no-pasa) es:

- **Reproducible:** el mismo output da el mismo veredicto siempre.
- **Automatizable:** muchos se vuelven un `grep`/`node`/assert que el juez corre como check, no como opinión.
- **Auditable:** cada fila del `.tsv` cita qué criterio pasó/falló y en qué input.

**Cómo definir un buen set (3–6):** derivarlos del contrato del skill target. Ejemplos por familia:

| Familia del skill | Criterios binarios candidatos |
|---|---|
| Skill con PREFLIGHT halt | "¿el halt dispara en el input que debe fallar?" · "¿NO dispara en el input válido?" |
| Skill con tool filter | "¿el output NO usa una tool fuera del filter declarado?" |
| Skill que cita | "¿toda claim externa lleva `[web:...]`/`[docs:...]` + `## Sources`? (R8/R13)" |
| Skill generador de UI | "¿el output NO usa el hue blacklist? (AP6)" · "¿lee brand.json antes de generar? (R10)" |
| Cualquiera (anti-bloat) | "¿el output/SKILL NO excede el largo objetivo?" (empata con el cap 2×) |

Menos de 3 criterios ⇒ métrica pobre (score salta en escalones grandes). Más de 6 ⇒ ruido y coste de juez.

## 4. Los safety caps, uno por uno

| Cap | Valor | Por qué | Qué pasa al tocarlo |
|-----|-------|---------|---------------------|
| Iteraciones | ≤ 30 | evita loops infinitos que queman budget sin converger | STOP limpio, restaurar best-known |
| Budget | $5 (default, opt-in confirmado) | el humano fija cuánto vale la mejora | STOP antes de proyectar exceso |
| Crecimiento del prompt | ≤ 2× baseline | anti-bloat (lección Vercel "-80% tools = +3×"); un skill que crece sin control pierde rendimiento | discard automático de la mutación que lo excede |
| Backup | obligatorio antes de mutar | un mal loop no debe poder perder el original | no se muta sin `SKILL.md.backup` |
| Rama | dedicada, nunca `main` | aislar el experimento del código en uso | PREFLIGHT halt si estás en main/master |
| Opt-in | siempre | AP3/D-024: la auto-mejora no autónoma | ningún hook/pipeline lo dispara |

Los caps **son el diseño**, no barandillas opcionales: tocar uno es un final normal del loop (STOP/discard),
no un error. El "éxito" de autoresearch es converger *dentro* de los caps, o parar limpio al tocarlos.

## 5. El formato del `.tsv` (bitácora del experimento)

`<target>/autoresearch-results.tsv` — una fila por iteración, tab-separated, append-only:

```
iter	ts	hypothesis	criteria_pass	criteria_total	score	best	decision	cost_usd	commit
1	2026-06-30T18:40:02Z	"claritas: separar refusals en lista"	14	18	0.78	0.78	keep	0.11	a1b2c3d
2	2026-06-30T18:44:10Z	"acortar la sección de ejemplos"	12	18	0.67	0.78	discard	0.09	(reset)
```

- **Append-only** (como el `activity.log.jsonl` del plano): la historia del experimento no se reescribe.
- **`commit`** referencia el hash del commit de esa mutación (o `(reset)` si se descartó).
- **`score`/`best`/`decision`** son del juez independiente — nunca del generador (AP3, AP5).
- El `.tsv` es la evidencia que el humano revisa para decidir si acepta el diff neto (merge de la rama) o lo descarta.

## 6. Fronteras (lo que autoresearch NO es)

| No es… | Diferencia |
|--------|-----------|
| `skill-creator` | crea el **scaffold** de un skill nuevo; autoresearch **itera la calidad** de uno existente |
| `el-evaluador` | firma **features** (Three-Layer + Anti-Slop, escribe memory); aquí es el **juez** del loop, no el sujeto |
| `update-forja` | trae el template **upstream**; autoresearch mejora **este** skill localmente en una rama |
| un agente autónomo | es **opt-in**, con caps y juez separado — precisamente lo que lo distingue del autoresearch vetado |

## Sources

- `docs/06` §C6 — autoresearch como parte de Calidad (S4), reencuadrado anti-bloat.
- `docs/02` §3.10 — el loop self-improving de Forge Pro (evals binarias + mutación de prompt).
- `[memory:decisions#D-024]` — la Decision de no-port y su *Mitigation* (opt-in + AP3), que C6 ejecuta.
- `[docs:git]` — semántica de `commit`/`reset --hard "$BASE"` (aislamiento por commit). Validar con `find-docs` (R13) si el runbook necesita freshness.
