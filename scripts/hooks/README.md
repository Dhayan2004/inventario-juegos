# Forja Git Hooks

> Plain shell scripts. No node dependencies. Installed via `scripts/install-hooks.sh` (called by `make setup`).

## Hooks

| Hook | Enforces | Source rule |
|------|----------|-------------|
| `pre-commit` | R1 (WIP=1) — `feature_list.json` has ≤1 active feature; best-effort R5 if `COMMIT_EDITMSG` is populated | [CONSTRAINTS.md R1](../../CONSTRAINTS.md), R5 |
| `commit-msg` | R2 (Conventional Commits regex) + authoritative R5 (memory writer scope) | [CONSTRAINTS.md R2](../../CONSTRAINTS.md), R5 |

## Standalone scripts (not hooks)

| Script | Purpose | Source rule |
|--------|---------|-------------|
| `../preflight.sh` | R11 Bootstrap Contract verification | [CONSTRAINTS.md R11](../../CONSTRAINTS.md) |
| `../citation-lint.sh` | R13 external-doc citation linter (advisory, non-blocking) | [CONSTRAINTS.md R13](../../CONSTRAINTS.md) |
| `../install-hooks.sh` | Copy `scripts/hooks/*` → `.git/hooks/` with backup | — |

## Tests

`scripts/hooks/tests/` contains shell-based unit tests + an integration test. Run with `bash scripts/hooks/tests/run-all.sh`.
