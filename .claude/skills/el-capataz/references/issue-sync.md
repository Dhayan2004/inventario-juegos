# Issue sync — el flujo determinista de UNA SOLA VÍA (`el-capataz` SYNC)

> **Qué es esto.** El runbook EXACTO e idempotente para proyectar `feature_list.json` + `plan.json` →
> GitHub Issues. **Una sola vía:** `el-capataz` proyecta a Issues; **nunca** lee de Issues hacia el estado
> de build. Doctrina: `references/github-native.md` §7. Reglas: `[memory:CONSTRAINTS.md#R18]` · `[docs:gh]`.

- **Idempotencia:** por una marca HTML `<!-- forge:feature=<id> -->` (features) y `<!-- forge:story=<id> -->`
  (stories) en el **body** del Issue → buscar→actualizar, NUNCA duplicar.
- **R18:** cerrar el Issue **NO** cambia el JSON. El JSON cambia (por hooks/`el-evaluador`), y el sync
  **cierra** el Issue *cuando la feature ya está* `passing` (efecto de la proyección, no su causa).
- **Permisos:** requiere `gh` con scope de issues. Sin él → listar el plan de sync como artefacto + advertir
  (no rompe el build).

---

## 0. Resolver owner/repo + asegurar labels

```bash
read -r OWNER REPO < <(gh repo view --json owner,name -q '.owner.login + " " + .name')
```

Labels canónicos (crear si faltan, idempotente — `gh label create` falla suave si existe):

| Label | Uso |
|-------|-----|
| `forge:feature` | Issue que proyecta una feature de `feature_list.json` |
| `forge:story` | Issue de gestión que proyecta una story de `plan.json` |
| `state:active` | feature `active` (espejo del JSON) |
| `state:passing` | feature `passing` (espejo; el Issue se cierra) |
| `state:blocked` | feature `blocked` (espejo) |

```bash
gh label create "forge:feature" --color 1f883d 2>/dev/null || true
gh label create "state:active"  --color 0969da 2>/dev/null || true
# ...idem para forge:story / state:passing / state:blocked
```

## 1. Features → Issues (idempotente por marca HTML)

Por cada feature de `feature_list.json` (READ-ONLY):

```
título:  [<id>] <behavior>
labels:  forge:feature + state:<active|passing|blocked>   (uno solo de state:*)
body:    <!-- forge:feature=<id> -->        ← marca de idempotencia (primera línea)
         **Verification:** `<verification_command>`
         **CI:** [ci:run#<run_id>]  (si feature_list.json[id].ci_run existe)   ← evidencia A2
         <descripción / acceptance derivada del JSON>
```

Algoritmo determinista:

```bash
# 1) buscar el Issue existente por la marca (incluye cerrados → no recrear uno cerrado)
EXISTING=$(gh issue list --state all --search "<!-- forge:feature=$ID -->" \
            --json number,state,body -q '.[0]')

# 2) NO existe → crear
gh issue create --title "[$ID] $BEHAVIOR" \
  --label "forge:feature" --label "state:$STATE" \
  --body "$BODY_CON_MARCA"

# 3) SÍ existe → editar (título, body, labels de estado). NUNCA crear otro.
gh issue edit "$NUMBER" --title "[$ID] $BEHAVIOR" \
  --add-label "state:$STATE" \
  --remove-label "state:active" --remove-label "state:passing" --remove-label "state:blocked"
# (re-add del actual queda; remover los tres y volver a poner el vigente = label de estado limpio)
```

> **Búsqueda robusta:** preferir la marca HTML en `--search`; si el search de GitHub no la indexa, listar
> `gh issue list --label forge:feature --state all --json number,body` y matchear `<!-- forge:feature=$ID -->`
> en el body localmente. La marca, no el título, es la identidad (el título puede cambiar).

## 2. Stories → Issues (opcional, gestión)

Por cada story de `plan.json` con `featureRefs[]` (READ-ONLY): un Issue de **gestión** que **referencia**
(no duplica) los Issues de feature:

```
título:  [<story.id>] <story title>
labels:  forge:story
body:    <!-- forge:story=<id> -->
         **As** <as> **I want** <want> **so that** <soThat>
         **Acceptance:** <acceptance>
         **Features:** #<num de cada feature en featureRefs>   ← referencia, no copia
```

Misma idempotencia (`<!-- forge:story=<id> -->`). Si una featureRef aún no tiene Issue, sincronizar §1 primero.

## 3. Estados → labels (proyección) + cierre en `passing`

```
- El label de estado SIEMPRE refleja el `state` del JSON (proyección, una vía).
- feature `passing` en el JSON  → cerrar el Issue:  gh issue close "$NUMBER" --reason completed
- feature vuelve a `active`/`blocked` (regresión) en el JSON → reabrir:  gh issue reopen "$NUMBER"
- Cerrar a mano un Issue NO toca el JSON (R18). En el próximo SYNC, si la feature NO está `passing`,
  el Issue se REABRE (la verdad es el JSON, el Issue converge a él).
```

## 4. La regla dura (R18) — por qué esto es de una sola vía

> La autoridad de las transiciones de build es `feature_list.json` + los hooks (R1/AP8). Si cerrar un Issue
> o mergear un PR pudiera marcar `passing`, reintroducirías "transiciones por UI" que D1 prohíbe y romperías
> el single-writer (R5). Por eso `el-capataz`:
> - **lee** `feature_list.json`/`plan.json` y **escribe** Issues (nunca al revés),
> - **cierra** el Issue como *efecto* de que el JSON ya marcó `passing` (vía `el-evaluador` + CI/AP8),
> - **nunca** escribe `feature_list.json` ni `.claude/memory/**` (R5).

## 5. Convergencia distribuida

El sync es vía git/`gh`, no un servidor en vivo (`github-native.md` §7): cada dev corre `el-capataz` SYNC
tras su commit. Como la fuente (el JSON versionado en git) es única, los Issues **convergen** sin importar
quién corra el sync — la marca HTML evita duplicados entre devs.

## Sources
- `references/github-native.md` §7 (sync una-vía) + §0 (invariante R18).
- `[docs:gh]` — `gh issue list/create/edit/close/reopen`, `gh label create`. Validar con `find-docs` (R13).
