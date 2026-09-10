#!/usr/bin/env bash
# Test scripts/apply-ontology-migrations.mjs (S3)
# Cases:
#   1. dry-run no escribe (ONTOLOGY.md intacto, sin ledger) → exit 0
#   2. --apply inyecta la sección + sella ontology_version + crea ledger + backup
#   3. idempotencia: segundo --apply no duplica (sección aparece 1 vez, reporta "al día")
#   4. create_path crea el directorio declarado
#   5. sin ONTOLOGY.md → exit 1 (safety guard)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RUNNER="$REPO_ROOT/scripts/apply-ontology-migrations.mjs"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "── ontology-migrations tests ──"

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; TESTS_PASS=$((TESTS_PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; TESTS_FAIL=$((TESTS_FAIL+1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

TGT="$(mktemp -d)"
TPL="$(mktemp -d)"
MIGDIR="$TPL/.claude/ontology-migrations"
mkdir -p "$MIGDIR"

# ── ONTOLOGY.md objetivo (v0.1, con anchor estable) ──────────────────────────
cat > "$TGT/ONTOLOGY.md" <<'EOF'
---
ontology_version: "0.1"
discovery_completed: true
empresa:
  nombre: "Acme"
---

# Ontología: Acme

## Decisiones y supuestos abiertos
- **Decisión:** dato del cliente que NO se debe tocar.
EOF

# ── Migración 0001 (ontology_md) ─────────────────────────────────────────────
cat > "$MIGDIR/0001_add-antipatrones.md" <<'EOF'
---
migration_id: "0001"
title: "Agrega ## Antipatrones (v0.1 → v0.2)"
type: "ontology_md"
anchor: "## Decisiones y supuestos abiertos"
position: "before"
check_line: "## Antipatrones"
ontology_version: "0.2"
---

## Antipatrones / lo que la empresa NO es
- **NO somos:** placeholder.
EOF

# ── C1: dry-run no escribe ───────────────────────────────────────────────────
out=$( cd "$TGT" && node "$RUNNER" --template-dir="$TPL" 2>&1 ); rc=$?
check "C1a: dry-run exit 0" "[ $rc -eq 0 ]"
check "C1b: dry-run reporta DRY RUN" "echo \"\$out\" | grep -q 'DRY RUN'"
check "C1c: dry-run NO escribe la sección" "! grep -q '## Antipatrones' '$TGT/ONTOLOGY.md'"
check "C1d: dry-run NO crea ledger" "[ ! -f '$TGT/.forja/ontology.migrations' ]"

# ── C2: --apply inyecta, sella versión, ledger, backup ───────────────────────
out=$( cd "$TGT" && node "$RUNNER" --template-dir="$TPL" --apply 2>&1 ); rc=$?
check "C2a: apply exit 0" "[ $rc -eq 0 ]"
check "C2b: sección inyectada" "grep -q '## Antipatrones' '$TGT/ONTOLOGY.md'"
check "C2c: dato del cliente intacto" "grep -q 'NO se debe tocar' '$TGT/ONTOLOGY.md'"
check "C2d: ontology_version sellado a 0.2" "grep -q 'ontology_version: \"0.2\"' '$TGT/ONTOLOGY.md'"
check "C2e: ledger registra 0001" "grep -q '^0001 ' '$TGT/.forja/ontology.migrations'"
check "C2f: backup creado" "ls '$TGT/.forja/ontology-backups/'*/ONTOLOGY.md >/dev/null 2>&1"

# ── C3: idempotencia ─────────────────────────────────────────────────────────
out=$( cd "$TGT" && node "$RUNNER" --template-dir="$TPL" --apply 2>&1 ); rc=$?
count=$(grep -c '^## Antipatrones' "$TGT/ONTOLOGY.md")
check "C3a: re-apply exit 0" "[ $rc -eq 0 ]"
check "C3b: sección aparece exactamente 1 vez" "[ '$count' -eq 1 ]"
check "C3c: reporta al día" "echo \"\$out\" | grep -q 'al día'"

# ── C4: create_path ──────────────────────────────────────────────────────────
cat > "$MIGDIR/0002_evidence-dir.md" <<'EOF'
---
migration_id: "0002"
title: "Crea ontology/evidence (v0.2 → v0.3)"
type: "create_path"
paths: "ontology/evidence"
ontology_version: "0.3"
---
EOF
out=$( cd "$TGT" && node "$RUNNER" --template-dir="$TPL" --apply 2>&1 ); rc=$?
check "C4a: create_path exit 0" "[ $rc -eq 0 ]"
check "C4b: directorio creado" "[ -d '$TGT/ontology/evidence' ]"
check "C4c: ledger registra 0002" "grep -q '^0002 ' '$TGT/.forja/ontology.migrations'"

# ── C5: safety guard — sin ONTOLOGY.md ───────────────────────────────────────
EMPTY="$(mktemp -d)"
out=$( cd "$EMPTY" && node "$RUNNER" --template-dir="$TPL" 2>&1 ); rc=$?
check "C5: sin ONTOLOGY.md → exit 1" "[ $rc -eq 1 ]"

rm -rf "$TGT" "$TPL" "$EMPTY"

echo ""
echo "ontology-migrations: ${TESTS_PASS} passed, ${TESTS_FAIL} failed"
exit "$TESTS_FAIL"
