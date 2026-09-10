#!/usr/bin/env bash
# Forja hook installer
# Copies scripts/hooks/* to .git/hooks/ with backup of any existing hooks.
# Idempotent. Invoked by `make setup`.
#
# Usage:
#   bash scripts/install-hooks.sh           # install (with backup)
#   bash scripts/install-hooks.sh --check   # verify install only, exit 1 if missing

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "❌ Not a git repo. Run from inside a Forja repo." >&2
  exit 1
fi
cd "$REPO_ROOT"

HOOKS_SRC="scripts/hooks"
HOOKS_DST="$REPO_ROOT/.git/hooks"

if [[ ! -d "$HOOKS_SRC" ]]; then
  echo "❌ Source hooks directory not found: $HOOKS_SRC" >&2
  exit 1
fi

mkdir -p "$HOOKS_DST"

MODE="${1:-install}"

INSTALLED=()
SKIPPED=()
MISSING=()

for hook_file in "$HOOKS_SRC"/*; do
  [[ -f "$hook_file" ]] || continue

  hook_name=$(basename "$hook_file")

  # Skip non-hook files (README.md, etc.)
  case "$hook_name" in
    pre-commit|commit-msg|pre-push|post-commit|prepare-commit-msg|pre-rebase|post-merge|post-checkout|post-rewrite|update|pre-receive|post-receive|applypatch-msg|pre-applypatch|post-applypatch|pre-auto-gc|fsmonitor-watchman|push-to-checkout) ;;
    *) continue ;;
  esac

  dst="$HOOKS_DST/$hook_name"

  if [[ "$MODE" == "--check" ]]; then
    if [[ -x "$dst" ]] && cmp -s "$hook_file" "$dst"; then
      INSTALLED+=("$hook_name")
    else
      MISSING+=("$hook_name")
    fi
    continue
  fi

  # Backup existing hook only if it differs from incoming
  if [[ -f "$dst" ]] && ! cmp -s "$hook_file" "$dst"; then
    cp "$dst" "$dst.bak"
    echo "  💾 Backup: $hook_name → ${hook_name}.bak"
  fi

  cp "$hook_file" "$dst"
  chmod +x "$dst"

  if [[ -x "$dst" ]]; then
    INSTALLED+=("$hook_name")
  else
    SKIPPED+=("$hook_name (could not chmod +x)")
  fi
done

echo ""
if [[ "$MODE" == "--check" ]]; then
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "❌ Hooks missing or out of sync:"
    for h in "${MISSING[@]}"; do echo "   - $h"; done
    echo ""
    echo "Run: bash scripts/install-hooks.sh"
    exit 1
  fi
  echo "✅ All hooks installed and in sync (${#INSTALLED[@]}):"
  for h in "${INSTALLED[@]}"; do echo "   - $h"; done
  exit 0
fi

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
  echo "Forja hooks installed:"
  for h in "${INSTALLED[@]}"; do
    echo "  ✅ $h → .git/hooks/$h"
  done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped:"
  for h in "${SKIPPED[@]}"; do
    echo "  ⚠️  $h"
  done
fi

echo ""
echo "Active enforcement:"
echo "  R1 (WIP=1)            → pre-commit"
echo "  R2 (Conventional)     → commit-msg"
echo "  R5 (memory scope)     → commit-msg (authoritative) + pre-commit (best-effort)"
echo "  R11 (Bootstrap)       → make preflight"
echo "  R13 (citation)        → make lint-citations (advisory)"
echo "  R15 (no secrets)      → pre-commit (fail-closed secrets scan)"
echo "  R17 (plan integrity)  → pre-commit (fail-closed) + post-commit (seal events)"

exit 0
