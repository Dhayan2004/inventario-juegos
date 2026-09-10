---
name: el-capataz
description: >
  Gobernanza GitHub-native del equipo de desarrollo sobre M6 + A1 + A2:
  regenera CODEOWNERS desde el roster (`.forja/team.json`) + los `modules[]`
  del plano, setea branch protection en `main` (required checks = los jobs de
  ci.yml/security.yml de A2), siembra PR/Issue templates si faltan, y proyecta
  `feature_list.json` + `plan.json` → GitHub Issues en UNA SOLA VÍA (idempotente
  por marca HTML). Cierra D12 (CODEOWNERS + branch protection + sync una-vía).
  Es el espejo de una vía R18: GitHub es proyección read-only de la verdad —
  NUNCA escribe `feature_list.json` ni marca `passing` al cerrar un Issue o
  mergear un PR. Sibling gh-based de `verificar-ci`: PREFLIGHT con degradación
  segura si no hay `gh`/auth/remote/CI (advierte + documenta manual, no rompe).
tier: core
requires: GitHub CLI (`gh`) instalado y autenticado (`gh auth status`) + repo con remote en GitHub + workflows ci.yml/security.yml presentes (de A2) + roster `.forja/team.json` (lo crea en INIT si falta)
fallback: si no hay `gh`/remote/CI, degradar a setup MANUAL documentado (CODEOWNERS + pasos de branch protection + Issues listados) + advertir que la protección remota no se aplica; NO romper el harness (mismo patrón que verificar-ci). El gobierno local (R1/AP8/hooks) sigue vigente.
dependencies: []
---

# el-capataz

> *"El plano dice QUÉ se construye; el capataz dice QUIÉN responde por cada pieza y que nadie la suba sin pasar por el control. Pero el capataz no inventa la verdad: la refleja."*
> — S2 (equipos GitHub-native), R18

Skill CORE de gobernanza. Materializa la decisión **D12** (declarada en `ARCHITECTURE.md`, no implementada
hasta S2): pone **CODEOWNERS + branch protection + PR/Issue templates + sync una-vía** sobre la base que ya
dan la memoria single-writer (R5), la state machine (`feature_list.json`), el plano (A1) y el `ci_run` (A2).
Es la cara **GitHub-native** del pilar ② (equipos/gestión). No reinventa roles: reusa `owner`/`admin`/`member`
de M6. Toda la doctrina vive en **[`references/github-native.md`](references/github-native.md)** — este SKILL
es el runbook operativo, NO la duplica.

> **El invariante maestro (R18) — léelo antes de cualquier modo:** GitHub es un **espejo de UNA SOLA VÍA**.
> `feature_list.json` + los hooks (R1/AP8) son la autoridad; Issues/PRs/boards son **proyección read-only**.
> Cerrar un Issue, mergear un PR o mover una card **NUNCA** marca `passing` ni muta `feature_list.json`.
> Ver §"La frontera (R18)" abajo. Detalle: [`references/github-native.md`](references/github-native.md) §0.

## PREFLIGHT halt

```
1. ¿`gh` instalado? `command -v gh`. Si no → fallback: setup MANUAL documentado + advertir (no romper).
2. ¿`gh auth status` OK? Si no → fallback: emitir CODEOWNERS + Issues como artefactos locales, advertir
   que branch protection/sync remoto NO se aplican sin auth. (degradación segura, no halt duro).
3. ¿Repo con remote GitHub? `git remote get-url origin`. Si no → fallback: solo INIT local (CODEOWNERS +
   templates) + advertir que protección/Issues necesitan remote.
4. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
5. ¿Existen .github/workflows/ci.yml + security.yml? (modo INIT branch protection):
   - Sí → required checks = sus `name:` reales (ver references/branch-protection.md).
   - No → fallback: setea protección SIN required checks aún + advierte "corré A2 (ci.yml) primero".
6. ¿Existe .forja/team.json (roster)? Si no → en modo INIT lo CREA con un solo `owner` derivado de
   `git config user.name` + el owner del remote (degradación de references/github-native.md §5).
```

Sin `gh`/auth/remote NO se aborta el harness — se **degrada y advierte**, igual que `verificar-ci`.

## Activación

| Modo | Cuándo se invoca | Qué hace |
|------|------------------|----------|
| **INIT** | `/capataz init` · primer setup del equipo en el repo · roster nuevo · cambió el roster/módulos | (re)genera `.github/CODEOWNERS` desde roster + `plan.json[modules]`, setea branch protection en `main` vía `protect-branch.sh`/`gh api`, siembra `.github/pull_request_template.md` + `.github/ISSUE_TEMPLATE/` si faltan, crea `.forja/team.json` si falta |
| **SYNC** | `/capataz sync` · tras un commit de estado (post `el-evaluador`) · al despachar | proyecta `feature_list.json` + `plan.json` → GitHub Issues en UNA VÍA, idempotente por marca HTML, cierra Issues de features `passing` |
| **STATUS** | `/capataz` · `/capataz status` · auditoría de gobernanza | reporta cobertura de CODEOWNERS (paths sin dueño), estado de branch protection (required checks faltantes), items de `feature_list`/`plan` sin Issue sincronizado |

## Los tres modos

### MODO INIT — sembrar el gobierno del repo

```
1. PREFLIGHT halt (arriba).
2. Roster: leer .forja/team.json. Si falta → crearlo desde templates/team.json con 1 owner
   derivado de git config user.name + owner del remote (no es secreto).
3. CODEOWNERS (.github/CODEOWNERS):
   - Read .forja/team.json (members[].github + areas) + (si existe) .plan/plan.json (modules[].area).
   - `*` → owners/admins del roster. Cruzar module.area → devs cuya areas[] la cubre.
   - Áreas sensibles (**/migrations/, **/api/auth/, **/api/payments/, .github/, CONSTRAINTS.md, .claude/)
     → exigen revisor owner/admin (references/github-native.md §2).
   - Degradación: roster 1 dev → lo nombra en `*` (la review de code owner se apaga en branch protection).
4. Branch protection en `main`: leer estado actual (diff), aplicar idempotente vía
   `scripts/protect-branch.sh` (o `gh api -X PUT .../branches/main/protection`).
   Required checks = los `name:` de ci.yml + security.yml. Procedimiento EXACTO: references/branch-protection.md.
5. Templates (.github/): si NO existen, sembrar pull_request_template.md + ISSUE_TEMPLATE/{feature.yml,
   bug.yml, config.yml} (los issue-forms YAML reales que viajan en forge/.github/; NO hay `story.md` — las
   stories se proyectan por `gh issue` en SYNC, no por un ISSUE_TEMPLATE). `config.yml` fija
   blank_issues_enabled:false (la verdad vive en feature_list.json, R18).
   Si YA existen con contenido propio → halt + reportar (NO sobrescribir — patrón E-009).
6. Reportar: CODEOWNERS escrito, protección aplicada (o pasos manuales si degradado), templates sembrados.
```

### MODO SYNC — proyectar el estado a Issues (UNA VÍA)

```
1. PREFLIGHT (necesita gh + auth + remote; si falta → listar Issues como artefacto + advertir, no romper).
2. Read feature_list.json (READ-ONLY) + (si existe) .plan/plan.json (READ-ONLY).
3. Por cada feature → Issue idempotente por marca <!-- forge:feature=<id> --> en el body
   (buscar→editar, NUNCA duplicar). Labels: forge:feature + state:<active|passing|blocked>.
4. Por cada story de plan.json con featureRefs → Issue de gestión que REFERENCIA (no duplica) las features.
5. Feature en `passing` → CERRAR su Issue (la proyección lo cierra; el JSON ya cambió por hooks, NO al revés).
6. Procedimiento determinista EXACTO + idempotencia + labels: references/issue-sync.md.
```

> SYNC es vía git/`gh`, no un servidor compartido en vivo: cada dev corre SYNC tras su commit; los Issues
> convergen porque la fuente (el JSON en git) es única (`references/github-native.md` §7).

### MODO STATUS — reportar cobertura sin mutar nada

```
1. CODEOWNERS: paths del repo sin dueño asignado (gap report) + áreas sensibles sin owner/admin.
2. Branch protection: leer `gh api .../branches/main/protection`; required checks presentes vs los `name:`
   esperados de ci.yml/security.yml (faltantes → flag). enforce_admins / force_pushes / deletions.
3. Sync: features/stories de los JSON sin Issue (marca HTML ausente) o con label de estado desfasado.
4. STATUS es READ-ONLY: nunca escribe CODEOWNERS, protección ni Issues — solo reporta el diff a aplicar.
```

## La frontera (R18) — GitHub es un espejo de una sola vía

- ✅ `feature_list.json` / `plan.json` → **se reflejan** en Issues, labels, CODEOWNERS y PR body (una vía).
- ❌ `el-capataz` **NUNCA escribe** `feature_list.json` ni `.claude/memory/**` (R5). Solo lee y proyecta.
- ❌ Cerrar un Issue, mergear un PR o mover una card **NO** marca una feature `passing` ni muta el JSON.
  Esa transición la gobiernan los hooks (R1 + AP8 + R7), no un webhook de GitHub. La tentación de "que
  cerrar el Issue marque done" es exactamente el error que D1 prohíbe (reintroduce transiciones por UI).
- El sync **cierra** el Issue *cuando la feature ya está* `passing` en el JSON (efecto, no causa).

Cita: `[memory:CONSTRAINTS.md#R18]`. Detalle: [`references/github-native.md`](references/github-native.md) §0.

## Refusals (lo que NUNCA hace)

- ❌ Escribir/mutar `feature_list.json` (R18 + R5). Solo lo LEE para proyectar.
- ❌ Marcar una feature `passing` desde GitHub (cerrar Issue / mergear PR ≠ `passing`). Eso es hooks/AP8.
- ❌ Editar `.claude/memory/**` (R5 — sole writer es `el-evaluador`).
- ❌ Sobrescribir `.github/pull_request_template.md` o `ISSUE_TEMPLATE/` con contenido propio del proyecto
  (siembra solo si faltan; si existen → halt + reportar, patrón E-009).
- ❌ Setear branch protection que afloje los gates de A2 (no quitar required checks; no `allow_force_pushes`
  ni `allow_deletions` en `main`).
- ❌ Inventar un segundo modelo de roles — reusa `owner`/`admin`/`member` de M6 (github-native.md §4).
- ❌ Duplicar Issues (idempotencia por marca HTML obligatoria).
- ❌ Romper el harness por falta de `gh`/auth/remote/CI → degrada y advierte (como `verificar-ci`).

## Tool filter

Read · Grep · Glob · Bash (`gh`, `git` solamente) · Write/Edit **solo** en `.github/**`
(`CODEOWNERS`, `pull_request_template.md`, `ISSUE_TEMPLATE/**`) y `.forja/team.json`.

NO Write/Edit en `feature_list.json` (R18). NO en `.claude/memory/**` (R5). NO en `.plan/**` (territorio de
`el-cartografo`). NO en `.github/workflows/**` (territorio de A2 / `verificar-ci`).

**Alcance conceptual independiente de prefijo (E-009 causa 2):** los paths son patrones, no literales —
`**/feature_list.json` y `**/.claude/memory/**` están prohibidos con o sin prefijo de directorio.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint source | `[memory:CONSTRAINTS.md#R18]` | espejo de una vía (header de CODEOWNERS/Issues generados) |
| Constraint source | `[memory:CONSTRAINTS.md#R5]` | nunca escribir memoria |
| Constraint source | `[memory:CONSTRAINTS.md#AP8]` | por qué cerrar Issue ≠ passing (la verdad la da CI/hooks) |
| ADR (declaración) | `[ARCHITECTURE.md#D12]` | D12 declaró GitHub-native (CODEOWNERS + branch protection + sync); vive en ARCHITECTURE.md, no en decisions.md |
| Decisions (S2) | `[memory:decisions#D-029]` | la decisión de S2 que IMPLEMENTA D12 (espejo de una vía + add-teams) |
| Lessons | `[memory:lessons#L-005]` | roles M6 reusados para autoridad de review |
| Errores | `[memory:errors#E-009]` | no sobrescribir templates con contenido propio |
| CI evidence | `[ci:run#<run_id>]` | el `ci_run` de A2 que se refleja en el body del Issue |
| External docs | `[docs:gh]` | cualquier comando `gh api`/`gh issue`/`gh pr` (validar con find-docs, R13) |

## Integraciones

| Skill / artefacto | Relación |
|-------------------|----------|
| `verificar-ci` / `ci.yml` (A2) | upstream. Sus jobs (`name:`) son los required status checks de branch protection. El `ci_run` que produce se refleja en el body del Issue (`[ci:run#<id>]`). `el-capataz` es su sibling gh-based: misma degradación PREFLIGHT. |
| `el-cartografo` / `plan.json` (A1) | upstream READ-ONLY. `modules[].area` alimenta CODEOWNERS; `stories[]` con `featureRefs` alimentan Issues de gestión. El `actor` del plano admite `member.name` del roster (github-native.md §6). |
| `add-teams` / roles M6 | comparte vocabulario de roles (`owner`/`admin`/`member`). `add-teams` los administra en las apps target; `el-capataz` los consume para CODEOWNERS/approvals del repo del equipo. |
| `/despachar` | downstream. Rellena el PR body desde `feature_list`+`plan`; corre `verificar-ci` antes del deploy. `el-capataz` siembra el `pull_request_template.md` que `/despachar` rellena. |
| `el-evaluador` | el ÚNICO writer de `feature_list.json`/memoria. `el-capataz` solo lee su salida y la proyecta a GitHub (R18). |

## Output handoff

```markdown
## el-capataz handoff

**Mode:** INIT | SYNC | STATUS
**gh:** available | degraded (manual)

**INIT:**
- .github/CODEOWNERS — N paths cubiertos (M áreas sensibles → owner/admin)
- Branch protection `main` — required checks: <lista de name: de ci.yml/security.yml> | (manual: pasos)
- Templates: pull_request_template.md / ISSUE_TEMPLATE/* sembrados | ya existían (no tocados)
- .forja/team.json — creado | existente (K members)

**SYNC:**
- Features → Issues: X creados, Y actualizados, Z cerrados (passing)
- Stories → Issues: ...
- (R18) feature_list.json NO modificado — solo proyección.

**STATUS:**
- CODEOWNERS gaps: <paths sin dueño>
- Branch protection: <required checks faltantes vs A2>
- Sync drift: <features/stories sin Issue o con label desfasado>

**Citations:** [memory:CONSTRAINTS.md#R18] · [ARCHITECTURE.md#D12] · [memory:decisions#D-029] · [docs:gh]
```

---

*"El plano es la verdad; GitHub es su espejo. El capataz lo mantiene limpio — en una sola dirección."*
