# Branch protection en `main` — el procedimiento idempotente (`el-capataz` INIT)

> **Qué es esto.** El runbook EXACTO e idempotente que ejecuta `el-capataz` modo INIT para volver a A2 un
> **gate** (no solo evidencia): además de que el `pre-commit` gatea el commit local (AP8), GitHub bloquea el
> **merge** remoto sin los checks verdes. Las dos capas se refuerzan. Doctrina: `references/github-native.md`
> §3. Cita: `[memory:CONSTRAINTS.md#R18]` · `[docs:gh]`.

- **Endpoint:** `gh api -X PUT repos/{owner}/{repo}/branches/main/protection` (REST `branches/{branch}/protection`).
- **Idempotencia:** SIEMPRE leer el estado actual, calcular el diff, y solo aplicar si difiere (no falla si ya está).
- **Degradación (PREFLIGHT):** sin `gh`/auth/remote/permiso de admin → NO se aplica; se imprime el JSON + los
  pasos manuales y se advierte (no rompe el harness). El gobierno local (R1/AP8/hooks) sigue vigente.

---

## 0. Resolver owner/repo

```bash
# del remote, no hardcodear:
read -r OWNER REPO < <(gh repo view --json owner,name -q '.owner.login + " " + .name')
```

## 1. Leer el estado actual ANTES de aplicar (el diff)

Idempotencia = no aplicar si ya coincide. Leer y comparar:

```bash
# 404 si no hay protección todavía (rama nueva) → tratar como "vacío", aplicar el contrato.
gh api "repos/$OWNER/$REPO/branches/main/protection" \
  --jq '{checks: [.required_status_checks.checks[]?.context],
         strict: .required_status_checks.strict,
         reviews: .required_pull_request_reviews.required_approving_review_count,
         code_owners: .required_pull_request_reviews.require_code_owner_reviews,
         admins: .enforce_admins.enabled,
         force: .allow_force_pushes.enabled,
         del: .allow_deletions.enabled}' 2>/dev/null || echo '{}'
```

Comparar contra el contrato (§2). Si todo coincide → **no-op** (reportar "ya protegido"). Si difiere → §3.

## 2. El contrato — required checks = los `name:` REALES de A2

Required status checks = los `name:` de los jobs de `.github/workflows/ci.yml` y `security.yml` (leídos del
repo en el momento — NO inventar). Estado actual de A2:

**De `ci.yml`:**
- `Layer 1 — Syntax (typecheck + lint)`
- `Layer 2 — Runtime (unit + integration)`
- `Smoke — build`
- `Gates — hook autotest + plan integrity`
- `Bootstrap Contract (R11)`

**De `security.yml`:**
- `Secrets (gitleaks) — fail-closed`
- `Dependencies (npm audit) — fail-closed`

**NO se incluyen aún** (F-P4.5 — por motivos DISTINTOS, no los mezcles):
- `Layer 3 — System (e2e headless + visual diff vs brand.json)` (ci.yml) — **NO es** `continue-on-error`;
  simplemente aún no se exige como gate de merge hasta que `make e2e` sea estable headless en CI.
- `SAST (CodeQL) — warning al inicio, required después` (security.yml) — sí es `continue-on-error` hoy;
  pasa a required cuando se le quite ese flag.

> **Regla:** `el-capataz` LEE los `name:` de los workflows en vivo (`grep -E '^\s*name:' ` por job, o
> `gh api .../actions/workflows`) y usa EXACTAMENTE esos strings como `context`. Si A2 cambió un `name:`,
> el sync de checks lo refleja; si un required check no existe como job → STATUS lo marca como drift.

Resto del contrato (github-native.md §3):
- `strict: true` — la rama debe estar al día con `main` antes de mergear.
- `required_pull_request_reviews.required_approving_review_count: 1` (**0 si el roster tiene 1 dev**).
- `require_code_owner_reviews: true` **solo si el roster tiene ≥2 colaboradores** (si no, GitHub lo ignora; setear `false`).
- `enforce_admins`: recomendado `true` para empresa; **configurable por roster** (`team.json` puede bajarlo a `false`).
- `allow_force_pushes: false` + `allow_deletions: false` sobre `main` (no negociable).

## 3. Aplicar (idempotente) — el JSON de ejemplo

`el-capataz` arma este payload (los `contexts` se generan desde los `name:` leídos; aquí, los 7 actuales):

```jsonc
// payload PUT a repos/{owner}/{repo}/branches/main/protection
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "Layer 1 — Syntax (typecheck + lint)" },
      { "context": "Layer 2 — Runtime (unit + integration)" },
      { "context": "Smoke — build" },
      { "context": "Gates — hook autotest + plan integrity" },
      { "context": "Bootstrap Contract (R11)" },
      { "context": "Secrets (gitleaks) — fail-closed" },
      { "context": "Dependencies (npm audit) — fail-closed" }
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,   // 0 si roster == 1 dev
    "require_code_owner_reviews": true,      // false si roster < 2 colaboradores
    "dismiss_stale_reviews": true
  },
  "enforce_admins": true,                     // configurable por roster
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": false,
  "required_conversation_resolution": true
}
```

Comando (idempotente — re-aplicar PUT es seguro; GitHub fija el estado deseado):

```bash
# scripts/protect-branch.sh encapsula esto; aquí el equivalente directo:
gh api -X PUT "repos/$OWNER/$REPO/branches/main/protection" \
  --input - <<'JSON'
{ ... el payload de arriba, con los contexts derivados de los name: reales ... }
JSON
```

> **Roster-aware (los 2 condicionales):** `el-capataz` lee `.forja/team.json` antes de armar el payload:
> - `members[]` con rol `owner`/`admin`/`member` que sean colaboradores ≥ 2 → `require_code_owner_reviews: true`,
>   `required_approving_review_count: 1`.
> - roster con 1 solo dev → `required_approving_review_count: 0` + `require_code_owner_reviews: false`
>   (si no, el único dev no podría mergear su propio trabajo — degradación de github-native.md §3).

## 4. Verificar (post-aplicación)

```bash
gh api "repos/$OWNER/$REPO/branches/main/protection" \
  --jq '.required_status_checks.checks[].context'   # debe listar los 7 contexts
```

## 5. Degradación si no hay permisos / `gh` / remote

```
- Sin `gh` o sin `gh auth status`  → imprimir el JSON de §3 + el comando, advertir: "Aplicá branch
  protection manualmente (Settings → Branches → main) o autenticá gh. AP8 sigue gateando el commit local."
- Sin permiso de admin (403)        → mismo aviso; el dueño del repo debe correrlo.
- Sin remote                        → INIT solo siembra CODEOWNERS/templates locales; protección N/A.
```

NUNCA fallar el harness por esto — degradar y advertir (mismo patrón que `verificar-ci`).

## Sources
- `references/github-native.md` §3 (el contrato) + §5 (roster-aware).
- `[docs:gh]` — `gh api repos/{owner}/{repo}/branches/{branch}/protection` (REST branch protection). Validar con `find-docs` (R13).
- Los `name:` reales: `.github/workflows/ci.yml` + `.github/workflows/security.yml` (A2).
