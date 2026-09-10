#!/usr/bin/env bash
# add-e2e-tests dry-run test — L1 (structure + presence) + L2 (semantics) + L3 (citations).
#
# Approach: validates the skill assets themselves (SKILL.md / prompts / templates /
# references / command wrapper / memory entries). No npm install or network calls.
# E-008 awareness applied: grep -E uses plain `|` for alternation (NOT \\|),
# and grep -i where case-flex matching matters.
#
# Usage: bash .claude/skills/add-e2e-tests/tests/dry-run.sh
# Exit 0 = all PASS

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../../.." && pwd)"
SKILL_MD="$SKILL_DIR/SKILL.md"
PROMPTS="$SKILL_DIR/prompts"
TEMPLATES="$SKILL_DIR/templates"
REFS="$SKILL_DIR/references"

# AGENTS.md and memory live in the  subtree of the meta-repo.
FORJA_SUB="$REPO_ROOT/forja"
COMMAND_FILE="$FORJA_SUB/.claude/commands/add-e2e-tests.md"
SKILLS_REGISTRY="$FORJA_SUB/.claude/memory/skills.md"
DECISIONS_FILE="$FORJA_SUB/.claude/memory/decisions.md"
AGENTS_ROOT="$REPO_ROOT/AGENTS.md"
AGENTS_FORJA="$FORJA_SUB/AGENTS.md"

echo "── add-e2e-tests dry-run ───────────────────────────────────────"
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
[[ -d "$PROMPTS" ]] && ok "prompts/ present" || fail "prompts/ missing"
[[ -d "$TEMPLATES" ]] && ok "templates/ present" || fail "templates/ missing"
[[ -d "$REFS" ]] && ok "references/ present" || fail "references/ missing"
[[ -f "$SKILL_DIR/tests/dry-run.sh" ]] && ok "tests/dry-run.sh present" || fail "tests/dry-run.sh missing"

# Prompts (4 archivos esperados)
for p in install-deps.md configure-playwright.md scaffold-tests.md optional-github-actions.md; do
  [[ -f "$PROMPTS/$p" ]] && ok "prompts/$p present" || fail "prompts/$p missing"
done

# Templates (5 archivos esperados)
for t in playwright.config.ts.template auth.setup.ts.template example.spec.ts.template helpers-auth.ts.template github-workflow.yml.template; do
  [[ -f "$TEMPLATES/$t" ]] && ok "templates/$t present" || fail "templates/$t missing"
done

# References (2 archivos esperados)
for r in playwright-vs-agent-browser.md auth-pattern-rationale.md; do
  [[ -f "$REFS/$r" ]] && ok "references/$r present" || fail "references/$r missing"
done

# Command wrapper
[[ -f "$COMMAND_FILE" ]] && ok "commands/add-e2e-tests.md present" || fail "commands/add-e2e-tests.md missing"

# ── L2 — SKILL.md frontmatter + semantics ────────────────────────────
echo ""
echo "L2 — SKILL.md frontmatter + semantics"

grep -qE "^name: add-e2e-tests$" "$SKILL_MD" && ok "frontmatter name set" || fail "frontmatter name missing"
grep -qE "^tier: optional$" "$SKILL_MD" && ok "tier=optional" || fail "tier not optional"
grep -qE "^requires:" "$SKILL_MD" && ok "requires field present" || fail "requires missing"
grep -qE "^fallback:" "$SKILL_MD" && ok "fallback field present" || fail "fallback missing"
grep -qE "^dependencies: \[find-docs\]$" "$SKILL_MD" && ok "dependencies = [find-docs]" || fail "dependencies field wrong"

# ── S1 — PREFLIGHT halt sin next en deps ─────────────────────────────
echo ""
echo "S1 — PREFLIGHT halt sin next en deps"

grep -qE "next.* en (deps|package.json)" "$SKILL_MD" && ok "Gate 1 references next in deps" || fail "Gate 1 missing next-in-deps"
grep -qiE "add-e2e-tests requiere proyecto Next.js" "$SKILL_MD" && ok "Gate 1 halt message present" || fail "Gate 1 halt message missing"

# ── S2 — PREFLIGHT halt con typecheck roto (Gate 8 heredado E-009) ───
echo ""
echo "S2 — PREFLIGHT halt con typecheck roto (Gate 8 heredado)"

grep -qE "typecheck baseline sano" "$SKILL_MD" && ok "Gate 3 typecheck baseline mentioned" || fail "typecheck baseline not mentioned"
grep -qE "npm run typecheck|tsc --noEmit" "$SKILL_MD" && ok "typecheck command mentioned" || fail "typecheck command missing"
grep -qE "Build pre-existente roto" "$SKILL_MD" && ok "Build pre-existente halt copy present" || fail "halt copy missing"
grep -qE "lid-on-pot|E-009 causa 3" "$SKILL_MD" && ok "E-009 causa 3 lid-on-pot cited" || fail "E-009 causa 3 not cited"

# ── S3 — Modo selector (minimal vs full) ─────────────────────────────
echo ""
echo "S3 — Mode selector minimal vs full"

grep -qE "MODE A — minimal|Mode A — minimal" "$SKILL_MD" && ok "Mode A minimal documented" || fail "Mode A missing"
grep -qE "MODE B — full|Mode B — full" "$SKILL_MD" && ok "Mode B full documented" || fail "Mode B missing"
grep -qE "BINARY|binary" "$SKILL_MD" && ok "BINARY shape mentioned" || fail "BINARY not mentioned"
grep -qE "default.*minimal|minimal.*default" "$SKILL_MD" && ok "minimal is default" || fail "default not stated"

# ── S4 — minimal mode — solo chromium, sin .github/workflows ─────────
echo ""
echo "S4 — minimal mode — chromium-only, sin GitHub Actions"

# Mode A description should mention chromium only
grep -qiE "chromium-only|chromium only|solo chromium|Chromium only" "$SKILL_MD" && ok "minimal = chromium-only" || fail "chromium-only not stated"
grep -qE "NO.*\.github/workflows/e2e.yml|NO crea.*\.github/workflows" "$SKILL_MD" && ok "minimal NO crea workflow" || fail "minimal workflow exclusion missing"
grep -qE "sin GitHub Actions|sin .github/workflows|NO crea.*github" "$SKILL_MD" && ok "sin GitHub Actions stated" || fail "sin GitHub Actions missing"

# Template playwright.config.ts hints both modes
grep -qE "MINIMAL \(default" "$TEMPLATES/playwright.config.ts.template" && ok "config template hints MINIMAL block" || fail "MINIMAL hint missing"
grep -qE "FULL \(cross-browser\)" "$TEMPLATES/playwright.config.ts.template" && ok "config template hints FULL block" || fail "FULL hint missing"

# ── S5 — full mode — 3 browsers + workflow ───────────────────────────
echo ""
echo "S5 — full mode — 3 browsers + GitHub Actions workflow"

grep -qE "chromium.*firefox.*webkit|firefox.*webkit" "$SKILL_MD" && ok "full lists 3 browsers" || fail "full 3 browsers missing"
grep -qE "GitHub Actions" "$SKILL_MD" && ok "GitHub Actions mentioned" || fail "GitHub Actions missing"
grep -qE "matrix" "$TEMPLATES/github-workflow.yml.template" && ok "workflow has matrix" || fail "workflow matrix missing"
grep -qE "browser: \[chromium, firefox, webkit\]" "$TEMPLATES/github-workflow.yml.template" && ok "workflow matrix lists 3 browsers" || fail "workflow browsers wrong"
grep -qE "fail-fast: false" "$TEMPLATES/github-workflow.yml.template" && ok "workflow fail-fast: false" || fail "fail-fast not false"
grep -qE "actions/setup-node@v4" "$TEMPLATES/github-workflow.yml.template" && ok "setup-node@v4 (not deprecated v3)" || fail "setup-node version wrong"
grep -qE "actions/upload-artifact@v4" "$TEMPLATES/github-workflow.yml.template" && ok "upload-artifact@v4 (not deprecated v3)" || fail "upload-artifact version wrong"
grep -qE "actions/cache@v4" "$TEMPLATES/github-workflow.yml.template" && ok "cache@v4 present" || fail "cache@v4 missing"
grep -qE "playwright install --with-deps" "$TEMPLATES/github-workflow.yml.template" && ok "--with-deps in CI install" || fail "--with-deps missing"
grep -qE "secrets\.TEST_USER_EMAIL" "$TEMPLATES/github-workflow.yml.template" && ok "TEST_USER_EMAIL via secret" || fail "TEST_USER_EMAIL secret missing"
grep -qE "secrets\.TEST_USER_PASSWORD" "$TEMPLATES/github-workflow.yml.template" && ok "TEST_USER_PASSWORD via secret" || fail "TEST_USER_PASSWORD secret missing"

# ── S6 — resume — tests/e2e/ ya existe → halt + reporte ──────────────
echo ""
echo "S6 — resume-aware (tests/e2e/ y playwright.config.ts existing)"

grep -qE "Resume-aware|resume-aware|tests/e2e/.*existe|tests/e2e/.*ya existe" "$SKILL_MD" && ok "resume-aware mentioned" || fail "resume-aware missing"
grep -qE "halt.*reporta inventario|halt.*reporte" "$SKILL_MD" && ok "halt + reporte for existing tests" || fail "halt+reporte missing"
grep -qE "playwright\.config\.ts.*existe|playwright\.config\.ts.*ya existe" "$SKILL_MD" && ok "config existing handled" || fail "config existing not handled"
grep -qE "diff.*confirmación|diff.*confirmation" "$SKILL_MD" && ok "diff + confirmation flow" || fail "diff+confirmation missing"
grep -qE "APPEND" "$SKILL_MD" && ok "APPEND mode suggested in fallback" || fail "APPEND missing"

# ── S7 — package.json scripts agregados correctamente ────────────────
echo ""
echo "S7 — package.json scripts"

grep -qE "test:e2e\"" "$SKILL_MD" && ok "test:e2e script documented" || fail "test:e2e missing"
grep -qE "test:e2e:ui\"" "$SKILL_MD" && ok "test:e2e:ui script documented" || fail "test:e2e:ui missing"
grep -qE "test:e2e:debug\"" "$SKILL_MD" && ok "test:e2e:debug script documented" || fail "test:e2e:debug missing"
grep -qE "skip.*NO overwrite|append-only|NO overwrite" "$SKILL_MD" && ok "append-only on existing scripts" || fail "append-only behavior missing"
grep -qE "test:e2e" "$PROMPTS/scaffold-tests.md" && ok "scaffold-tests.md mentions test:e2e" || fail "scaffold-tests.md missing test:e2e"
grep -qE "playwright test --ui" "$PROMPTS/scaffold-tests.md" && ok "scaffold-tests.md mentions --ui" || fail "--ui flag missing in scaffold"
grep -qE "playwright test --debug" "$PROMPTS/scaffold-tests.md" && ok "scaffold-tests.md mentions --debug" || fail "--debug flag missing in scaffold"

# ── S8 — refusals (no overwrite playwright.config.ts) ────────────────
echo ""
echo "S8 — Refusals"

grep -qE "Sobrescribir.*playwright\.config\.ts" "$SKILL_MD" && ok "refusal: overwrite playwright.config.ts" || fail "overwrite refusal missing"
grep -qE "Modificar specs existentes" "$SKILL_MD" && ok "refusal: modify existing specs" || fail "specs refusal missing"
grep -qE "Instalar paquetes sin que.*PREFLIGHT" "$SKILL_MD" && ok "refusal: install without PREFLIGHT" || fail "install refusal missing"
grep -qE "Hardcodear credenciales" "$SKILL_MD" && ok "refusal: hardcode credentials" || fail "credentials refusal missing"
grep -qE "Reemplazar agent-browser" "$SKILL_MD" && ok "refusal: replace agent-browser" || fail "agent-browser refusal missing"
grep -qE "Ignorar Gate 8" "$SKILL_MD" && ok "refusal: ignore Gate 8" || fail "Gate 8 refusal missing"

# ── S9 — Citation grammar (D-026, D-004, E-009, R4, R13) ─────────────
echo ""
echo "S9 — Citation grammar"

grep -qE "\[memory:decisions#D-026\]" "$SKILL_MD" && ok "SKILL.md cites D-026" || fail "D-026 not cited in SKILL.md"
grep -qE "\[memory:decisions#D-004\]|\[ARCHITECTURE\.md#D4\]" "$SKILL_MD" && ok "SKILL.md cites D-004/D4 (agent-browser coexistence)" || fail "D-004/D4 not cited"
grep -qE "\[memory:errors#E-009\]" "$SKILL_MD" && ok "SKILL.md cites E-009 (Gate 8 herencia)" || fail "E-009 not cited"
grep -qE "\[memory:CONSTRAINTS\.md#R4\]" "$SKILL_MD" && ok "SKILL.md cites R4" || fail "R4 not cited"
grep -qE "\[memory:CONSTRAINTS\.md#R13\]" "$SKILL_MD" && ok "SKILL.md cites R13" || fail "R13 not cited"
grep -qE "\[docs:playwright\]" "$SKILL_MD" && ok "SKILL.md cites docs:playwright" || fail "docs:playwright not cited"

# References cite correctly
grep -qE "\[memory:decisions#D-004\]|\[ARCHITECTURE\.md#D4\]" "$REFS/playwright-vs-agent-browser.md" && ok "ref cites D-004/D4" || fail "ref missing D-004/D4"
grep -qE "\[memory:references#R-003\]" "$REFS/playwright-vs-agent-browser.md" && ok "ref cites R-003 (agent-browser)" || fail "R-003 missing"
grep -qE "\[memory:decisions#D-026\]" "$REFS/playwright-vs-agent-browser.md" && ok "ref cites D-026" || fail "D-026 missing in ref"

# Memory entries land correctly
grep -qE "^## D-026" "$DECISIONS_FILE" && ok "D-026 entry exists in decisions.md" || fail "D-026 not in decisions.md"
grep -qE "add-e2e-tests" "$SKILLS_REGISTRY" && ok "add-e2e-tests registered in skills.md" || fail "not registered in skills.md"

# AGENTS routing
grep -qE "add-e2e-tests" "$AGENTS_ROOT" && ok "root AGENTS.md routes add-e2e-tests" || fail "root AGENTS.md missing entry"
grep -qE "add-e2e-tests" "$AGENTS_FORJA" && ok "AGENTS.md routes add-e2e-tests" || fail "AGENTS.md missing entry"

# ── Template structural checks ───────────────────────────────────────
echo ""
echo "Template structural checks"

grep -qE "import.*from '@playwright/test'" "$TEMPLATES/playwright.config.ts.template" && ok "config imports @playwright/test" || fail "import wrong"
grep -qE "defineConfig" "$TEMPLATES/playwright.config.ts.template" && ok "config uses defineConfig" || fail "defineConfig missing"
grep -qE "testDir: './tests/e2e'" "$TEMPLATES/playwright.config.ts.template" && ok "testDir = ./tests/e2e" || fail "testDir wrong"
grep -qE "fullyParallel: true" "$TEMPLATES/playwright.config.ts.template" && ok "fullyParallel: true" || fail "fullyParallel missing"
grep -qE "process\.env\.CI \? 2 : 0" "$TEMPLATES/playwright.config.ts.template" && ok "retries config = 2 in CI" || fail "retries wrong"
grep -qE "process\.env\.CI \? 1 : undefined" "$TEMPLATES/playwright.config.ts.template" && ok "workers = 1 in CI" || fail "workers wrong"
grep -qE "NEXT_PUBLIC_APP_URL" "$TEMPLATES/playwright.config.ts.template" && ok "baseURL via NEXT_PUBLIC_APP_URL" || fail "baseURL env missing"
grep -qE "reuseExistingServer: !process\.env\.CI" "$TEMPLATES/playwright.config.ts.template" && ok "reuseExistingServer set" || fail "reuseExistingServer missing"
grep -qE "name: 'setup'" "$TEMPLATES/playwright.config.ts.template" && ok "setup project declared" || fail "setup project missing"
grep -qE "auth\\\\.setup\\\\.ts|auth\\.setup\\.ts" "$TEMPLATES/playwright.config.ts.template" && ok "auth.setup.ts referenced" || fail "auth.setup.ts not referenced"

grep -qE "TEST_USER_EMAIL" "$TEMPLATES/auth.setup.ts.template" && ok "auth.setup uses TEST_USER_EMAIL env" || fail "TEST_USER_EMAIL missing"
grep -qE "TEST_USER_PASSWORD" "$TEMPLATES/auth.setup.ts.template" && ok "auth.setup uses TEST_USER_PASSWORD env" || fail "TEST_USER_PASSWORD missing"
grep -qE "user\.json" "$TEMPLATES/auth.setup.ts.template" && ok "auth.setup writes user.json" || fail "user.json path missing"
grep -qE "NEVER hardcode credentials" "$TEMPLATES/auth.setup.ts.template" && ok "auth.setup warns NEVER hardcode" || fail "hardcode warning missing"
grep -qE "supabase|sb-.*-auth-token" "$TEMPLATES/auth.setup.ts.template" && ok "auth.setup compatible with Supabase" || fail "Supabase cookie pattern missing"

grep -qE "test\\(.*'home page renders'" "$TEMPLATES/example.spec.ts.template" && ok "example spec has home test" || fail "example spec home test missing"
grep -qE "test\\.describe" "$TEMPLATES/example.spec.ts.template" && ok "example uses test.describe" || fail "test.describe missing"
grep -qE "delete this file" "$TEMPLATES/example.spec.ts.template" && ok "example marked deletable" || fail "deletable hint missing"

grep -qE "export.*function login" "$TEMPLATES/helpers-auth.ts.template" && ok "helpers exports login()" || fail "login() missing"
grep -qE "export.*function logout" "$TEMPLATES/helpers-auth.ts.template" && ok "helpers exports logout()" || fail "logout() missing"
grep -qE "export.*function assertAuthenticated" "$TEMPLATES/helpers-auth.ts.template" && ok "helpers exports assertAuthenticated()" || fail "assertAuthenticated() missing"

# ── Command wrapper checks ───────────────────────────────────────────
echo ""
echo "Command wrapper"

grep -qE "^description:" "$COMMAND_FILE" && ok "command has description frontmatter" || fail "command description missing"
grep -qE "agent-browser" "$COMMAND_FILE" && ok "command mentions agent-browser coexistence" || fail "agent-browser mention missing"
grep -qE "minimal|Chromium-only" "$COMMAND_FILE" && ok "command mentions minimal mode" || fail "minimal mention missing"
grep -qE "full|GitHub Actions" "$COMMAND_FILE" && ok "command mentions full mode" || fail "full mention missing"
grep -qE "\.claude/skills/add-e2e-tests/SKILL\.md" "$COMMAND_FILE" && ok "command points to SKILL.md" || fail "command misroutes"

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "Some checks failed."
  exit 1
fi

echo "All checks passed."
exit 0
