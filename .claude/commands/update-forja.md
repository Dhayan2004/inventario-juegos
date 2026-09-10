---
description: "Actualiza el proyecto Forja a la última versión del template. Auto-detecta REPO_PATH desde alias forja. CLAUDE.md merge inteligente con marker FORJA:PRESERVE:START. Backup automático antes de modificar."
---

# /update-forja

Lee y ejecuta `.claude/skills/update-forja/SKILL.md` (estructura dual-tree) o `.claude/skills/update-forja/SKILL.md` (estructura flat) según cómo esté instalado Forja en el proyecto target.

Refresca el framework (`.claude/commands/`, `.claude/skills/`, `.claude/prompts/`, `.claude/references/`, `scripts/`, `Makefile`, `AGENTS.md`, `CONSTRAINTS.md`, `example.mcp.json`) trayendo la última versión desde el repositorio fuente, preservando archivos del proyecto (`.claude/memory/*.md`, `feature_list.json`, `PROGRESS.md`, `brand/*.json`, `src/features/`, `src/shared/`, `.mcp.json`, rutas de `src/app/`).

**Pipeline (D-027 boundary case):** DETECT → PULL → BACKUP → MERGE → REPORT.

**Precondiciones:**
- Proyecto Forja existente (`.claude/` o `.claude/` presente).
- Working tree limpio (sin cambios sin commit).
- Git inicializado.
- Alias `forja` configurado en `~/.zshrc`, `~/.bashrc` o `~/.bash_profile` (o REPO_PATH manual si no existe).

**CLAUDE.md merge inteligente:** la zona framework se renueva con el template; todo lo debajo del marker `<!-- FORJA:PRESERVE:START` se preserva (aprendizajes / Auto-Blindaje del proyecto). Sin marker → skip + warning, NO sobreescribe.

**Backup automático:** antes de modificar nada se crea `.forja-backup-{timestamp}/` con copia de `CLAUDE.md`, `AGENTS.md`, `CONSTRAINTS.md`, `Makefile` y `.claude/`. Borrar manualmente cuando se confirme OK.

**Config drift:** `package.json`, `next.config.ts`, `tailwind.config.ts`, `tsconfig.json`, `components.json`, `postcss.config.js` se detectan y reportan diff — NO se sobreescriben automáticamente.

**Auto-delegación post-pull:** después del `git pull`, el source tiene la versión más reciente del skill; el pipeline se re-ejecuta desde ESA versión (resuelve el bootstrap problem — no quedás atrapado con la lógica vieja instalada).
