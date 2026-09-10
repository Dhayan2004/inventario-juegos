#!/usr/bin/env bash
# protect-branch.sh — Branch protection de `main` como GATE remoto (S2 · Equipos GitHub-native)
#
# Materializa la pieza 2 de la doctrina de el-capataz (github-native.md §3): convierte los checks de A2
# (ci.yml + security.yml) en REQUIRED status checks sobre `main`, de modo que GitHub bloquee el merge sin
# los gates verdes. Refuerza AP8 (que ya gatea el commit local) con un gate remoto que el agente no puede
# saltar. Es IDEMPOTENTE (vuelve a aplicar el mismo estado deseado) y FAIL-SAFE (sin gh/auth/remote NO
# rompe el harness: imprime los pasos manuales y exit 0, mismo patrón que verificar-ci).
#
# Uso:
#   bash scripts/protect-branch.sh
# Tras clonarlo en un proyecto target, hazlo ejecutable: chmod +x scripts/protect-branch.sh
#
# Config por env (con defaults seguros para empresa):
#   REQUIRE_REVIEWS=1      # nº de approvals requeridos antes de mergear (0 = sin review obligatoria)
#   ENFORCE_ADMINS=true    # las reglas aplican también a admins (recomendado para empresa)
#   CODEOWNER_REVIEWS=false # exigir review de CODEOWNERS (poné true sólo con ≥2 colaboradores; ver github-native.md §3)
#   BRANCH=main            # rama a proteger
#
# Citation: [docs:gh] (gh api .../branches/{branch}/protection, PUT) · [memory:CONSTRAINTS.md#R18]
#           (GitHub es un espejo de una sola vía: esto fija el GATE de merge, NO escribe estado de build).
# NO secretos (R15): el token lo provee `gh auth` en el entorno; este script nunca lo imprime ni lo embebe.

set -euo pipefail

# ─── Config (env-overridable) ──────────────────────────────────────────────────
REQUIRE_REVIEWS="${REQUIRE_REVIEWS:-1}"
ENFORCE_ADMINS="${ENFORCE_ADMINS:-true}"
CODEOWNER_REVIEWS="${CODEOWNER_REVIEWS:-false}"
BRANCH="${BRANCH:-main}"

# Required status checks = los `name:` REALES de los jobs de A2 (ci.yml + security.yml).
# NOTA: `Layer 3 — System (e2e…)` y `SAST (CodeQL)` quedan FUERA mientras sean continue-on-error
# (F-P4.5 en los workflows). Cuando dejen de serlo, agrégalos a este arreglo. Ver github-native.md §3.
REQUIRED_CHECKS=(
  "Layer 1 — Syntax (typecheck + lint)"
  "Layer 2 — Runtime (unit + integration)"
  "Smoke — build"
  "Gates — hook autotest + plan integrity"
  "Bootstrap Contract (R11)"
  "Secrets (gitleaks) — fail-closed"
  "Dependencies (npm audit) — fail-closed"
)

# ─── Helpers de salida ──────────────────────────────────────────────────────────
info() { echo "  $1"; }
warn() { echo "  ⚠️  $1" >&2; }

# Imprime los pasos manuales y sale 0 (fail-safe: no rompe el harness).
manual_fallback() {
  echo ""
  echo "ℹ️  No se pudo aplicar branch protection automáticamente: $1"
  echo "   El gobierno local (R1 / AP8 / hooks) sigue vigente; sólo falta el gate de merge remoto."
  echo ""
  echo "   Pasos manuales (Settings → Branches → Add rule sobre '$BRANCH'):"
  echo "     • Require a pull request before merging — approvals: $REQUIRE_REVIEWS"
  echo "     • Require status checks to pass + 'Require branches to be up to date' (strict):"
  for c in "${REQUIRED_CHECKS[@]}"; do
    echo "         - $c"
  done
  echo "     • Do not allow force pushes · Do not allow deletions"
  echo "     • Include administrators: $ENFORCE_ADMINS"
  echo "     • Require review from Code Owners: $CODEOWNER_REVIEWS"
  echo ""
  echo "   O re-corré este script cuando 'gh' esté instalado y autenticado:  gh auth login"
  exit 0
}

# ─── PREFLIGHT (degradación segura) ──────────────────────────────────────────────
command -v gh   >/dev/null 2>&1 || manual_fallback "'gh' (GitHub CLI) no está instalado."
command -v node >/dev/null 2>&1 || manual_fallback "'node' no está disponible (se usa para armar el JSON de la API)."
gh auth status  >/dev/null 2>&1 || manual_fallback "'gh' no está autenticado (corré: gh auth login)."

# Detectar owner/repo desde el remote (vía gh, que resuelve el repo del directorio actual).
REPO_SLUG="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
if [[ -z "$REPO_SLUG" ]]; then
  git remote get-url origin >/dev/null 2>&1 || manual_fallback "este repo no tiene remote 'origin' en GitHub."
  manual_fallback "no se pudo resolver owner/repo desde el remote (¿es un repo de GitHub?)."
fi
info "Repo:   $REPO_SLUG"
info "Branch: $BRANCH"

# ─── Construir el JSON de protección ──────────────────────────────────────────────
# La GitHub API exige TODOS los campos top-level; usar null para desactivar required_status_checks /
# required_pull_request_reviews / restrictions. required_status_checks usa `checks` (context + app_id
# opcional); `strict: true` = la rama debe estar al día con `main` antes de mergear. [docs:gh]

# Se arma con `node` (dependencia garantizada del repo: CI usa setup-node, los scripts ya lo usan) para
# escapar correctamente los em-dash de los `name:` y emitir los null/boolean que la API exige.
# Los checks van como `context` sin `app_id` → cualquier app que reporte ese context cuenta.
PROTECTION_JSON="$(
  CHECKS_LIST="$(printf '%s\n' "${REQUIRED_CHECKS[@]}")" \
  REQUIRE_REVIEWS="$REQUIRE_REVIEWS" \
  CODEOWNER_REVIEWS="$CODEOWNER_REVIEWS" \
  ENFORCE_ADMINS="$ENFORCE_ADMINS" \
  node -e '
    const checks = process.env.CHECKS_LIST.split("\n")
      .filter(Boolean)
      .map((context) => ({ context }));
    const reviews = Number(process.env.REQUIRE_REVIEWS) > 0
      ? {
          required_approving_review_count: Number(process.env.REQUIRE_REVIEWS),
          require_code_owner_reviews: process.env.CODEOWNER_REVIEWS.toLowerCase() === "true",
          dismiss_stale_reviews: true,
        }
      : null; // null = sin review obligatoria (la API lo desactiva con null)
    process.stdout.write(JSON.stringify({
      required_status_checks: { strict: true, checks }, // strict = rama al día con main antes de mergear
      enforce_admins: process.env.ENFORCE_ADMINS === "true" ? true : null, // null desactiva
      required_pull_request_reviews: reviews,
      restrictions: null, // sin restricción de quién puede pushear (la API exige el campo)
      required_linear_history: false,
      allow_force_pushes: false,
      allow_deletions: false,
      required_conversation_resolution: true,
    }));
  '
)"

# ─── Aplicar (idempotente: PUT fija el estado deseado completo) ───────────────────
# La GitHub API de branch protection es declarativa: este PUT siempre converge al mismo estado, así que
# correr el script N veces deja el repo igual (idempotente). [docs:gh]
info "Aplicando branch protection (PUT)…"
if printf '%s' "$PROTECTION_JSON" | gh api \
    -X PUT "repos/$REPO_SLUG/branches/$BRANCH/protection" \
    -H "Accept: application/vnd.github+json" \
    --input - >/dev/null 2>&1; then
  echo ""
  echo "✅ Branch protection aplicada sobre '$BRANCH' en $REPO_SLUG."
  echo "   Required checks (${#REQUIRED_CHECKS[@]}): los gates de A2 (ci.yml + security.yml)."
  echo "   strict=true · enforce_admins=$ENFORCE_ADMINS · approvals=$REQUIRE_REVIEWS · code_owner_reviews=$CODEOWNER_REVIEWS"
  echo "   force-push=off · deletions=off · conversation-resolution=on."
  echo ""
  echo "   GitHub ahora BLOQUEA el merge sin los checks verdes. Esto refuerza AP8 a nivel remoto"
  echo "   (AP8 ya gatea el commit local; branch protection gatea el merge). [memory:CONSTRAINTS.md#R18]"
  exit 0
else
  manual_fallback "la llamada a 'gh api' falló (¿permisos de admin sobre el repo? ¿branch '$BRANCH' existe?)."
fi
