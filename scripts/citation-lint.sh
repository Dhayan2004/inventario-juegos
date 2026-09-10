#!/usr/bin/env bash
# Forja citation linter — R13 (standalone, advisory, NON-BLOCKING)
#
# Scans markdown files for mentions of known external libs without
# nearby [docs:libname] or [web:domain](url) citation. Heuristic;
# false positives expected. ALWAYS exits 0 — never blocks commits.
#
# Source: forja/CONSTRAINTS.md R13.
# Invocation: `make lint-citations` or `bash scripts/citation-lint.sh [file...]`

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

LIBS_FILE=".claude/skills/find-docs/references.md"
if [[ ! -f "$LIBS_FILE" ]]; then
  echo "⚠️  find-docs cache not found at $LIBS_FILE. Skipping citation lint." >&2
  exit 0
fi

# Extract libraryName column from markdown table (skip header + separator)
LIBS=$(awk -F '|' '
  /^\| [a-z]/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    if ($2 != "libraryName" && $2 != "" && $2 !~ /^-+$/) print $2
  }
' "$LIBS_FILE")

if [[ -z "$LIBS" ]]; then
  echo "⚠️  No libs parsed from find-docs cache." >&2
  exit 0
fi

# Files to scan
if [[ $# -gt 0 ]]; then
  FILES=("$@")
else
  # Default: markdown files modified in working tree (staged + unstaged)
  mapfile -t FILES < <(git diff --name-only HEAD 2>/dev/null | grep -E '\.md$' || true)
  if [[ ${#FILES[@]} -eq 0 ]]; then
    # Fallback: files modified in last commit
    mapfile -t FILES < <(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E '\.md$' || true)
  fi
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "Citation lint: no markdown files to scan."
  exit 0
fi

LIB_LIST=$(echo "$LIBS" | tr '\n' ' ')
echo "Citation lint (R13) — scanning ${#FILES[@]} file(s) against ${LIB_LIST% }"
echo ""

WARNINGS=0
for file in "${FILES[@]}"; do
  [[ -f "$file" ]] || continue
  for lib in $LIBS; do
    # Find lines mentioning the lib (word boundary), skip code fences
    while IFS=: read -r line_num line_content; do
      [[ -z "$line_num" ]] && continue
      # Compute 3-line window around the match
      start=$((line_num > 3 ? line_num - 3 : 1))
      end=$((line_num + 3))
      context=$(sed -n "${start},${end}p" "$file" 2>/dev/null)
      # Citation present if [docs:lib], [docs:lib@..], or any [web:...](...) within window
      if echo "$context" | grep -qE "\[docs:${lib}(@[^]]+)?\]|\[web:[^]]+\]\(http"; then
        continue
      fi
      echo "  ⚠️  $file:$line_num — '$lib' mentioned without [docs:$lib] or [web:...] within ±3 lines"
      echo "      → $line_content"
      WARNINGS=$((WARNINGS+1))
    done < <(grep -niE "\\b${lib}\\b" "$file" 2>/dev/null | grep -v '^[0-9]*:.*```' || true)
  done
done

echo ""
echo "Citation lint complete. Warnings: $WARNINGS (advisory, non-blocking)."
exit 0
