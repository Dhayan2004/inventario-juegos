#!/usr/bin/env bash
# update-forja dry-run test — L1 (structure + presence) + L2 (semantics) + L3 (citations).
#
# Approach: validates the skill assets themselves (SKILL.md / command wrapper /
# memory entries / AGENTS routing / template marker). No git pull or shell
# alias inspection — those are runtime concerns for the actual skill.
# E-008 awareness applied: grep -E uses plain `|` for alternation (NOT \\|),
# and grep -i where case-flex matching matters.
#
# Usage: bash .claude/skills/update-forja/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../../.." && pwd)"
SKILL_MD="$SKILL_DIR/SKILL.md"

FORJA_SUB="$REPO_ROOT/forja"
COMMAND_FILE="$FORJA_SUB/.claude/commands/update-forja.md"
SKILLS_REGISTRY="$FORJA_SUB/.claude/memory/skills.md"
DECISIONS_FILE="$FORJA_SUB/.claude/memory/decisions.md"
CLAUDE_TEMPLATE="$FORJA_SUB/CLAUDE.md"
AGENTS_ROOT="$REPO_ROOT/AGENTS.md"
AGENTS_FORJA="$FORJA_SUB/AGENTS.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

echo "── update-forja dry-run ────────────────────────────────────────"
echo "Skill dir: $SKILL_DIR"
echo "Repo root: $REPO_ROOT"
echo ""

PASS=0
FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

# ── L1 — Structure ───────────────────────────────────────────────────
echo "L1 — Skill structure"

[[ -f "$SKILL_MD" ]] && ok "SKILL.md present" || fail "SKILL.md missing"
[[ -d "$SKILL_DIR/tests" ]] && ok "tests/ present" || fail "tests/ missing"
[[ -f "$SKILL_DIR/tests/dry-run.sh" ]] && ok "tests/dry-run.sh present" || fail "tests/dry-run.sh missing"
[[ -f "$COMMAND_FILE" ]] && ok "commands/update-forja.md present" || fail "command wrapper missing"

# update-forja has NO templates/, NO prompts/, NO references/ (pipeline self-contained)
[[ ! -d "$SKILL_DIR/templates" ]] && ok "no templates/ folder (correct — pipeline self-contained)" || fail "unexpected templates/ folder"

# ── L2 — SKILL.md frontmatter + semantics ────────────────────────────
echo ""
echo "L2 — SKILL.md frontmatter + semantics"

grep -qE "^name: update-forja$" "$SKILL_MD" && ok "frontmatter name set" || fail "frontmatter name missing"
grep -qE "^tier: core$" "$SKILL_MD" && ok "tier=core" || fail "tier not core"
grep -qE "^requires:" "$SKILL_MD" && ok "requires field present" || fail "requires missing"
grep -qE "^fallback:" "$SKILL_MD" && ok "fallback field present" || fail "fallback missing"
grep -qE "^dependencies: \[\]$" "$SKILL_MD" && ok "dependencies = []" || fail "dependencies wrong"
grep -qE "alias .forja." "$SKILL_MD" && ok "alias forja mentioned in frontmatter" || fail "alias forja not in frontmatter"

# ── S1 — PREFLIGHT halt sin .claude/ ni .claude/ ───────────────
echo ""
echo "S1 — PREFLIGHT halt sin proyecto Forja"

grep -qE "\.claude/.*existe.*\.claude/.*existe|\.claude/.*existe.*flat" "$SKILL_MD" && ok "Gate 1 detects both flat and dual-tree" || fail "Gate 1 flat/dual detection missing"
grep -qE "No detecté proyecto Forja" "$SKILL_MD" && ok "Gate 1 halt copy present" || fail "Gate 1 halt copy missing"

# ── S2 — PREFLIGHT halt con working tree dirty ───────────────────────
echo ""
echo "S2 — PREFLIGHT halt con working tree dirty"

grep -qE "git status --porcelain" "$SKILL_MD" && ok "Gate 2 uses git status --porcelain" || fail "Gate 2 dirty check missing"
grep -qiE "Hacé commit o stash" "$SKILL_MD" && ok "Gate 2 halt copy present" || fail "Gate 2 halt copy missing"
grep -qiE "trabajo no guardado" "$SKILL_MD" && ok "Gate 2 mentions unsaved work risk" || fail "Gate 2 risk not stated"

# ── S3 — PREFLIGHT halt sin git ──────────────────────────────────────
echo ""
echo "S3 — PREFLIGHT halt sin git inicializado"

grep -qE "git rev-parse --is-inside-work-tree" "$SKILL_MD" && ok "Gate 3 uses git rev-parse" || fail "Gate 3 git check missing"
grep -qiE "Proyecto sin git" "$SKILL_MD" && ok "Gate 3 halt copy present" || fail "Gate 3 halt copy missing"
grep -qiE "rollback" "$SKILL_MD" && ok "Gate 3 mentions rollback dependency" || fail "Gate 3 rollback rationale missing"

# ── S4 — Detección alias forja desde shell configs ───────────────────
echo ""
echo "S4 — Detección alias forja desde ~/.zshrc / ~/.bashrc / ~/.bash_profile"

grep -qE "\.zshrc" "$SKILL_MD" && ok "~/.zshrc inspected" || fail "~/.zshrc not mentioned"
grep -qE "\.bashrc" "$SKILL_MD" && ok "~/.bashrc inspected" || fail "~/.bashrc not mentioned"
grep -qE "\.bash_profile" "$SKILL_MD" && ok "~/.bash_profile inspected" || fail "~/.bash_profile not mentioned"
grep -qE "alias forja=" "$SKILL_MD" && ok "alias forja= pattern mentioned" || fail "alias pattern not described"
grep -qE "sed -E" "$SKILL_MD" && ok "sed extraction of REPO_PATH present" || fail "sed REPO_PATH extraction missing"

# ── S5 — Detección estructura flat vs dual-tree ──────────────────────
echo ""
echo "S5 — Detección estructura flat vs dual-tree"

grep -qE "ESTRUCTURA=.flat" "$SKILL_MD" && ok "flat mode detected" || fail "flat mode missing"
grep -qE "ESTRUCTURA=.dual-tree" "$SKILL_MD" && ok "dual-tree mode detected" || fail "dual-tree mode missing"
grep -qE "FORJA_DIR=" "$SKILL_MD" && ok "FORJA_DIR variable used" || fail "FORJA_DIR not used"
grep -qiE "nunca hardcodear" "$SKILL_MD" && ok "explicit no-hardcoding rule" || fail "no-hardcoding rule missing"

# ── S6 — Fallback cuando alias no existe ─────────────────────────────
echo ""
echo "S6 — Fallback prompt cuando alias forja no existe"

grep -qiE "No encontré alias .forja." "$SKILL_MD" && ok "fallback prompt copy present" || fail "fallback prompt missing"
grep -qE "read REPO_PATH" "$SKILL_MD" && ok "read REPO_PATH from user" || fail "read REPO_PATH missing"

# ── S7 — Backup creado antes de modificar (FASE 4) ───────────────────
echo ""
echo "S7 — Backup automático antes de modificar"

grep -qE "\.forja-backup-" "$SKILL_MD" && ok ".forja-backup-{ts} naming" || fail "backup naming missing"
grep -qE "BACKUP_DIR=" "$SKILL_MD" && ok "BACKUP_DIR variable defined" || fail "BACKUP_DIR missing"
grep -qE "FASE 4|Fase 4" "$SKILL_MD" && ok "FASE 4 backup phase documented" || fail "FASE 4 missing"
grep -qiE "mandatory|obligatoria|obligatorio" "$SKILL_MD" && ok "backup is mandatory" || fail "backup mandatory not stated"

# ── S8 — NEVER TOUCH list ────────────────────────────────────────────
echo ""
echo "S8 — NEVER TOUCH list (project files)"

grep -qE "NEVER TOUCH" "$SKILL_MD" && ok "NEVER TOUCH list mentioned" || fail "NEVER TOUCH list missing"
grep -qE "\.claude/memory/" "$SKILL_MD" && ok "memory/ in NEVER TOUCH" || fail "memory/ not in NEVER TOUCH"
grep -qE "feature_list\.json" "$SKILL_MD" && ok "feature_list.json in NEVER TOUCH" || fail "feature_list.json not protected"
grep -qE "PROGRESS\.md" "$SKILL_MD" && ok "PROGRESS.md in NEVER TOUCH" || fail "PROGRESS.md not protected"
grep -qE "brand/brand\.json|brand/\*\.json" "$SKILL_MD" && ok "brand/*.json in NEVER TOUCH" || fail "brand JSONs not protected"
grep -qE "src/features" "$SKILL_MD" && ok "src/features/ in NEVER TOUCH" || fail "src/features/ not protected"
grep -qE "src/shared" "$SKILL_MD" && ok "src/shared/ in NEVER TOUCH" || fail "src/shared/ not protected"
grep -qE "\.mcp\.json" "$SKILL_MD" && ok ".mcp.json in NEVER TOUCH" || fail ".mcp.json not protected"
grep -qE "src/app/(page|layout|globals)" "$SKILL_MD" && ok "src/app/ project routes in NEVER TOUCH" || fail "src/app/ routes not protected"

# ── S9 — CLAUDE.md con marker → merge correcto ───────────────────────
echo ""
echo "S9 — CLAUDE.md merge inteligente con marker presente"

grep -qE "FORJA:PRESERVE:START" "$SKILL_MD" && ok "marker name FORJA:PRESERVE:START used" || fail "marker name missing"
grep -qE "sed -n .*/\\\$p|sed -n.*p" "$SKILL_MD" && ok "sed preservation extraction" || fail "sed preservation missing"
grep -qE "FRAMEWORK_ZONE|framework.*zone|zona framework" "$SKILL_MD" && ok "framework zone concept present" || fail "framework zone not mentioned"
grep -qiE "aprendizajes preservados|zona proyecto preservada" "$SKILL_MD" && ok "user content preservation mentioned" || fail "preservation outcome not stated"

# ── S10 — CLAUDE.md sin marker → skip + warning ──────────────────────
echo ""
echo "S10 — CLAUDE.md sin marker → skip graceful + warning"

grep -qiE "marker.*no encontrado|marker no encontrado|sin marker" "$SKILL_MD" && ok "missing marker case handled" || fail "missing marker case absent"
grep -qiE "NO actualizado|no fue actualizado" "$SKILL_MD" && ok "skip outcome stated" || fail "skip outcome missing"
grep -qiE "warning" "$SKILL_MD" && ok "warning emitted when marker missing" || fail "warning not stated"
grep -qiE "no destruir contenido del usuario" "$SKILL_MD" && ok "user-content rationale cited" || fail "user-content rationale missing"

# ── S11 — Auto-delegación post-git-pull (resuelve bootstrap) ─────────
echo ""
echo "S11 — Auto-delegación post-pull (bootstrap problem)"

grep -qiE "Auto-delegación|auto-delegacion|auto-delegate" "$SKILL_MD" && ok "auto-delegation mentioned" || fail "auto-delegation missing"
grep -qiE "bootstrap" "$SKILL_MD" && ok "bootstrap problem named" || fail "bootstrap problem not named"
grep -qE "FASE 3b|Fase 3b" "$SKILL_MD" && ok "FASE 3b dedicated to delegation" || fail "FASE 3b missing"
grep -qiE "versión más reciente|version mas reciente|lógica más nueva" "$SKILL_MD" && ok "rationale: latest version of self" || fail "rationale missing"

# ── S12 — Config drift detect-and-report ─────────────────────────────
echo ""
echo "S12 — Config drift detect-and-report (no overwrite)"

grep -qiE "DETECT-AND-REPORT|detect-and-report|config drift" "$SKILL_MD" && ok "config drift concept named" || fail "config drift not named"
grep -qE "package\.json" "$SKILL_MD" && ok "package.json drift tracked" || fail "package.json not tracked"
grep -qE "next\.config\.ts" "$SKILL_MD" && ok "next.config.ts drift tracked" || fail "next.config.ts not tracked"
grep -qE "tailwind\.config\.ts" "$SKILL_MD" && ok "tailwind.config.ts drift tracked" || fail "tailwind.config.ts not tracked"
grep -qE "tsconfig\.json" "$SKILL_MD" && ok "tsconfig.json drift tracked" || fail "tsconfig.json not tracked"
grep -qiE "informar|reporta|reporte|report" "$SKILL_MD" && ok "reports drift, not overwrites" || fail "no-overwrite stance missing"

# ── S13 — Citation grammar ───────────────────────────────────────────
echo ""
echo "S13 — Citation grammar (D-027, D-014, D-023, E-009, R5, R10, L-004)"

grep -qE "memory:decisions#D-027" "$SKILL_MD" && ok "D-027 cited" || fail "D-027 missing"
grep -qE "memory:decisions#D-014" "$SKILL_MD" && ok "D-014 cited (pipeline pattern)" || fail "D-014 missing"
grep -qE "memory:decisions#D-023" "$SKILL_MD" && ok "D-023 cited (DETECT pipeline)" || fail "D-023 missing"
grep -qE "memory:errors#E-009" "$SKILL_MD" && ok "E-009 cited (no destruir contenido)" || fail "E-009 missing"
grep -qE "memory:CONSTRAINTS\.md#R5" "$SKILL_MD" && ok "R5 cited (memory sole writer)" || fail "R5 missing"
grep -qE "memory:CONSTRAINTS\.md#R10" "$SKILL_MD" && ok "R10 cited (brand DNA)" || fail "R10 missing"
grep -qE "memory:lessons#L-004" "$SKILL_MD" && ok "L-004 cited (informativo)" || fail "L-004 missing"

# ── S14 — Refusals (>=5 explicit) ────────────────────────────────────
echo ""
echo "S14 — Refusals explícitas"

REFUSAL_COUNT=$(grep -cE "^- ❌" "$SKILL_MD" || true)
[[ "$REFUSAL_COUNT" -ge 5 ]] && ok "Refusals count >= 5 ($REFUSAL_COUNT)" || fail "Refusals count too low ($REFUSAL_COUNT)"
grep -qE "❌ NUNCA tocar archivos en NEVER TOUCH" "$SKILL_MD" && ok "refusal: NEVER TOUCH list" || fail "refusal missing: NEVER TOUCH"
grep -qE "❌ NUNCA sobreescribir CLAUDE\.md sin marker" "$SKILL_MD" && ok "refusal: CLAUDE.md sin marker" || fail "refusal missing: CLAUDE.md"
grep -qE "❌ NUNCA hardcodear" "$SKILL_MD" && ok "refusal: hardcoded paths" || fail "refusal missing: hardcoded"
grep -qE "❌ NUNCA correr sin working tree limpio" "$SKILL_MD" && ok "refusal: dirty working tree" || fail "refusal missing: dirty tree"
grep -qE "❌ NUNCA correr sin backup" "$SKILL_MD" && ok "refusal: no backup" || fail "refusal missing: no backup"

# ── S15 — Shape rationale (pipeline boundary, no selector) ───────────
echo ""
echo "S15 — Shape rationale (pipeline sin selector)"

grep -qiE "pipeline DETECT-PULL-MERGE|pipeline DETECT.*PULL.*MERGE" "$SKILL_MD" && ok "pipeline shape named" || fail "pipeline name missing"
grep -qiE "boundary case" "$SKILL_MD" && ok "boundary case explicit" || fail "boundary case not stated"
grep -qiE "L-004 NO aplica directo|L-004 no aplica directo" "$SKILL_MD" && ok "L-004 NO aplica directo stated" || fail "L-004 doctrine not stated"
grep -qiE "sin selector|NO selector" "$SKILL_MD" && ok "absence of selector stated" || fail "no-selector not stated"

# ── L3 — Memory + registry + AGENTS ──────────────────────────────────
echo ""
echo "L3 — Memory + registry + AGENTS routing"

# decisions.md — D-027 anchor + key content
grep -qE "^## D-027 — .update-forja." "$DECISIONS_FILE" && ok "D-027 heading present in decisions.md" || fail "D-027 heading missing"
grep -qE "boundary case análogo a D-014" "$DECISIONS_FILE" && ok "D-027 cites D-014 lineage" || fail "D-014 lineage missing in D-027"
grep -qE "boundary case análogo a D-014 \+ D-023|análogo a D-014 \+ D-023" "$DECISIONS_FILE" && ok "D-027 cites D-014+D-023 lineage" || fail "D-014+D-023 lineage missing"
grep -qE "auto-delegación post-pull|Auto-delegación post-pull|auto-delegacion post-pull" "$DECISIONS_FILE" && ok "auto-delegation pattern named in D-027" || fail "auto-delegation not in D-027"
grep -qE "NEVER TOUCH" "$DECISIONS_FILE" && ok "NEVER TOUCH concept in D-027" || fail "NEVER TOUCH not in D-027"
grep -qE "FORJA:PRESERVE:START" "$DECISIONS_FILE" && ok "marker name in D-027" || fail "marker name missing in D-027"

# skills.md — entry + Core skills count bumped
grep -qE "^### update-forja$" "$SKILLS_REGISTRY" && ok "update-forja entry in skills.md" || fail "update-forja entry missing"
grep -qE "^## Core skills \(19\)$" "$SKILLS_REGISTRY" && ok "Core skills count bumped to 19" || fail "Core skills count not bumped"
grep -qE "memory:decisions#D-027" "$SKILLS_REGISTRY" && ok "D-027 cited in skills.md entry" || fail "D-027 not cited in registry"

# AGENTS routing — both root and 
grep -qE "update-forja" "$AGENTS_ROOT" && ok "update-forja in root AGENTS.md" || fail "update-forja missing in root AGENTS"
grep -qE "update-forja" "$AGENTS_FORJA" && ok "update-forja in AGENTS.md" || fail "update-forja missing in AGENTS"

# Command wrapper sanity
grep -qE "^description:" "$COMMAND_FILE" && ok "command frontmatter has description" || fail "command frontmatter missing"
grep -qE "FORJA:PRESERVE:START" "$COMMAND_FILE" && ok "command mentions marker" || fail "command does not mention marker"
grep -qE "BACKUP|backup" "$COMMAND_FILE" && ok "command mentions backup" || fail "command does not mention backup"
grep -qE "D-027" "$COMMAND_FILE" && ok "command cites D-027" || fail "command does not cite D-027"

# Template marker — FORJA:PRESERVE:START present in template CLAUDE.md
grep -qE "FORJA:PRESERVE:START" "$CLAUDE_TEMPLATE" && ok "marker present in CLAUDE.md template" || fail "marker missing in template CLAUDE.md"
grep -qE "Aprendizajes del Proyecto" "$CLAUDE_TEMPLATE" && ok "Aprendizajes section in template" || fail "Aprendizajes section missing"

# CHANGELOG — v0.1.9 entry
grep -qE "^## \[0\.1\.9\]" "$CHANGELOG" && ok "CHANGELOG v0.1.9 entry present" || fail "CHANGELOG v0.1.9 missing"
grep -qE "update-forja" "$CHANGELOG" && ok "CHANGELOG mentions update-forja" || fail "CHANGELOG does not mention update-forja"

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────────────────────────"
echo "Total: PASS=$PASS  FAIL=$FAIL"
echo "──────────────────────────────────────────────────────────────"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
