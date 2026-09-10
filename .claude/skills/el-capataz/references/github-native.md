# GitHub-native team governance — la doctrina de `el-capataz` (S2)

> **Qué es esto.** El contrato de la gobernanza de equipo de Forge Enterprise. Materializa la decisión
> **D12** (declarada en `ARCHITECTURE.md`, no implementada hasta S2): CODEOWNERS, branch protection, PR
> templates con body autogenerado, y sync `feature_list.json`/`plan.json` → GitHub Issues. Es la cara
> **GitHub-native** del pilar ② (equipos/gestión), sobre la base de trazabilidad que ya dan la memoria
> single-writer (R5), la state machine (`feature_list.json`), el `actor` del plano (A1) y el `ci_run` (A2).
>
> **Fuente de diseño:** `docs/06` §S2 + `docs/07` §7.5 + `01` §5.2. **Decisión de producto:** §9-C
> (GitHub-native basta para MVP; el plano de roles/permisos propio es COULD, no se construye).

- **Versión:** v0.1.0 (2026-06-30, S2 · Equipos)
- **Lo produce/mantiene:** el skill `el-capataz` (`/capataz`).
- **Regla de enforcement:** `[memory:CONSTRAINTS.md#R18]` (espejo de una sola vía).

---

## 0. El invariante maestro — GitHub es un ESPEJO de una sola vía (R18)

La autoridad sobre las transiciones de build es, y sigue siendo, **`feature_list.json` + los hooks**
(R1 WIP=1, ADR D1). GitHub (Issues, PRs, project boards) es una **proyección read-only** de esa verdad,
**nunca su fuente**:

- ✅ `feature_list.json` / `plan.json` → **se reflejan** en Issues, labels y PR body (una vía).
- ❌ Cerrar un Issue, mergear un PR o mover una card **NUNCA** marca una feature `passing` ni muta
  `feature_list.json`. Eso lo gobiernan los hooks (R1 + AP8 + R7), no un webhook de GitHub.
- ❌ `el-capataz` **no escribe** `feature_list.json` ni `.claude/memory/**` (R5). Sólo lee y proyecta.

> Por qué: si GitHub pudiera escribir el estado de build, reintroducirías "transiciones por UI" que D1
> prohíbe y romperías el single-writer (R5). La tentación de "que cerrar el Issue marque done" es el error.

---

## 1. Las cuatro piezas (el 80% de "equipos" con esfuerzo medio)

| # | Pieza | Artefacto | Quién lo aplica |
|---|-------|-----------|-----------------|
| 1 | **CODEOWNERS** | `.github/CODEOWNERS` | viaja en el template; `el-capataz` lo regenera desde el roster + `modules[]` del plano |
| 2 | **Branch protection** | `gh api` sobre `main` | `el-capataz` modo INIT (idempotente) — required checks = jobs de A2 |
| 3 | **PR template + body autogen** | `.github/pull_request_template.md` + body desde `feature_list`+`plan` | viaja en el template; `/despachar` rellena el body |
| 4 | **Issue templates + sync** | `.github/ISSUE_TEMPLATE/` + `gh issue` (una vía) | `el-capataz` modo SYNC |

---

## 2. CODEOWNERS ← roster + módulos del plano

CODEOWNERS mapea **paths → revisores de GitHub**. Forge lo deriva de dos fuentes que ya existen:

- **El roster del equipo** (`.forja/team.json`, ver §5): cada dev con su handle de GitHub y sus áreas.
- **Los `modules[]` de `plan.json`** (A1): cada módulo tiene `area` (`backend`/`frontend`/…) y dueños
  implícitos. `el-capataz` cruza `module.area` → los devs del roster cuya `areas[]` la cubre.

Reglas:
- El path raíz (`*`) cae a los `owner`/`admin` del roster (el rol de M6 — ver §4).
- Áreas sensibles (`**/migrations/`, `**/api/auth/`, `**/api/payments/`, `.github/`, `CONSTRAINTS.md`,
  `.claude/`) exigen revisor con rol `owner`/`admin`.
- Degradación: roster con 1 solo dev ⇒ CODEOWNERS lo nombra a él en `*` (la review de CODEOWNERS se
  desactiva en branch protection cuando hay <2 colaboradores — ver §3).

---

## 3. Branch protection — el contrato (required checks = los gates de A2)

`el-capataz` modo INIT setea protección en `main` vía `gh api repos/{owner}/{repo}/branches/main/protection`
(idempotente: leer estado actual, aplicar diff). El contrato:

- **Required status checks** = los jobs de los workflows de A2, por su `name:`:
  `Layer 1 — Syntax (typecheck + lint)` · `Layer 2 — Runtime (unit + integration)` · `Smoke — build` ·
  `Gates — hook autotest + plan integrity` · `Bootstrap Contract (R11)` · `Secrets (gitleaks) — fail-closed` ·
  `Dependencies (npm audit) — fail-closed`. Quedan FUERA por ahora (F-P4.5): `SAST (CodeQL)` porque hoy es
  `continue-on-error` en security.yml (no bloqueante hasta que se endurezca), y `Layer 3 — System (e2e…)`
  hasta que `make e2e` sea estable headless en CI (NO es `continue-on-error` — simplemente aún no se exige
  como gate de merge). `strict: true` (rama al día con `main` antes de mergear).
- **Required PR before merge** + `required_approving_review_count: 1` (0 si el roster tiene 1 dev).
- **`require_code_owner_reviews: true`** sólo si el roster tiene ≥2 colaboradores (si no, GitHub lo ignora).
- **`enforce_admins`**: recomendado `true` para empresa; configurable por roster.
- **`allow_force_pushes: false`** + **`allow_deletions: false`** sobre `main`.

> **Esto es lo que vuelve a A2 un GATE, no sólo evidencia.** `ci_run.conclusion == success` (AP8) ya era
> condición para `passing`; con branch protection, además **GitHub bloquea el merge** sin los checks verdes.
> Las dos capas se refuerzan: AP8 gatea el commit local; branch protection gatea el merge remoto.

**Degradación segura (PREFLIGHT):** sin `gh`/sin auth/sin remote/sin `ci.yml` ⇒ `el-capataz` no puede
setear protección remota → **advierte** y documenta los pasos manuales, NO falla el harness (mismo patrón
que `verificar-ci`). El gobierno local (R1/AP8/hooks) sigue vigente.

---

## 4. Roles M6 (owner/admin/member) ↔ gobernanza de GitHub

El modelo de rol del equipo **reusa** los roles de membresía de M6 (`owner`/`admin`/`member`, definidos en
`0000_tenancy.sql`) como vocabulario único — **no se inventa un segundo modelo de roles**:

| Rol M6 | En el equipo de desarrollo | Mapea a |
|--------|----------------------------|---------|
| `owner` | dueño del repo/proyecto; aprueba áreas sensibles; admin de branch protection | GitHub admin/maintain |
| `admin` | revisor de CODEOWNERS; puede aprobar PRs; mantiene el roster | GitHub write + code owner |
| `member` | contribuye en feature branches; no aprueba sus propios PRs (AP3) | GitHub write |

Esto une el pilar ① (M6) y el ②: el mismo `role` gobierna el aislamiento de datos (RLS) **y** la autoridad
de revisión (CODEOWNERS/approvals). `add-teams` administra esos roles en las apps generadas; `el-capataz`
los consume para la gobernanza del repo del equipo.

---

## 5. El roster del equipo — `.forja/team.json`

Fuente única de quién es quién (vive en `.forja/`, versionado, NO secreto):

```jsonc
{
  "schema_version": "1.0.0",
  "members": [
    { "name": "carlos", "github": "dodc1981", "role": "owner",  "areas": ["*"] },
    { "name": "joaco",  "github": "joaco-gh",  "role": "admin",  "areas": ["frontend", "design"] }
  ]
}
```

- **`name`** = el mismo identificador que usa el `actor` del log del plano (A1) — ver §6.
- **`role`** = rol M6 (§4). **`areas`** = áreas de `modules[].area` que esta persona posee (para CODEOWNERS).
- **`github`** = handle para CODEOWNERS / approvals. Degradación: roster ausente ⇒ `el-capataz` lo crea
  con un solo `owner` derivado de `git config user.name` + el owner del remote.

---

## 6. Actores nombrados — el puente con el plano (A1)

A1 dejó el `actor` del `activity.log.jsonl` como `{human, agent}` con la nota "extensible a nombres propios
cuando haya equipo — S2". S2 lo cierra: **`actor` ahora admite el `name` de un miembro del roster**
(`carlos`, `joaco`) además de `agent`. El vocabulario abierto: `agent` | `<member.name>`; `human` se
mantiene como alias genérico válido (degradación: proyecto sin roster). La vista de actividad de `plan.html`
ya filtra por actor — con el roster, filtra por persona. Contrato del campo: `PLAN_SCHEMA.md` §3.

---

## 7. Issue sync — el flujo determinista de una sola vía (modo SYNC)

`el-capataz` proyecta a GitHub Issues; **nunca** lee de Issues hacia el estado:

1. **Features → Issues:** por cada feature de `feature_list.json`, un Issue con título `[<id>] <behavior>`,
   label `forge:feature` + label de estado (`state:active`/`state:passing`/`state:blocked`), y body con
   `verification` + (si existe) `[ci:run#<id>]`. Idempotente por una marca `<!-- forge:feature=<id> -->`
   en el body (buscar→actualizar, no duplicar).
2. **Stories → Issues (opcional):** por cada story de `plan.json` con `featureRefs`, un Issue de gestión que
   referencia (no duplica) los Issues de feature; body = `as/want/soThat` + `acceptance`.
3. **Labels de estado** se actualizan al estado actual del JSON (proyección). Cerrar el Issue **no** cambia
   el JSON; el JSON cambia (por hooks) y el sync **cierra** el Issue cuando la feature está `passing`.
4. **Permisos:** requiere `gh` con scope de issues. Degrada con aviso si falta (no rompe el build).

> El sync es **vía git/`gh`, no un servidor compartido en vivo** (`docs/07` §7.5): cada dev corre `el-capataz`
> SYNC tras su commit; los Issues convergen porque la fuente (el JSON en git) es única.

## Sources
- `docs/06` §S2 (equipos GitHub-native) · `docs/07` §7.5 + Punto 3 §6 (sync una-vía) · `01` §5.2 (D12).
- `[docs:gh]` — GitHub CLI `gh api .../branches/{branch}/protection`, `gh issue`. Validar con `find-docs` (R13).
