# manage-worktrees

> Gestión de git worktrees para Pattern Fork. Crea, lista, hace cherry-pick (con confirmation), remueve y prunea worktrees. **R13 enforcement: invocá find-docs ANTES de generar comandos git worktree.**

## Antes de empezar — find-docs (R13)

Aunque la-forja conoce git worktree por training data, los flags y syntax pueden cambiar entre versiones de git. Validá con find-docs antes de emitir comandos:

```
Sub-agent invoca find-docs:
  ctx7 library git "git worktree add --detach branch creation parallel"
  ctx7 docs /git/htmldocs "git worktree add list remove prune cherry-pick"
```

Si find-docs reporta sintaxis distinta a la documentada acá → adoptar el output canónico de Context7. Si find-docs no responde → fallback a esta documentación + cita `[docs:git]` informativa con caveat "Context7 unavailable".

`[docs:git]` es la citation grammar canónica para git commands. Aplica R13.

## Comandos canónicos

### Crear worktree

Sintaxis canónica (validada vía Context7 `/git/htmldocs`):

```bash
# Crear worktree con branch nueva basada en HEAD actual
git worktree add <path> -b <branch-name>

# Equivalente explícito (recomendado para la-forja por claridad)
git worktree add .worktrees/sandbox-1 -b la-forja/sandbox-1-literal

# Crear worktree con branch existente
git worktree add <path> <existing-branch>

# Crear worktree en HEAD detached (raro en Fork — preferimos branch named)
git worktree add --detach <path> <commit-ish>
```

Convenciones para Fork:

- **Path:** `.worktrees/sandbox-N` (N = 1..5).
- **Branch:** `la-forja/sandbox-N-<personality>` (ej: `la-forja/sandbox-1-literal`).
- **Base:** HEAD del active branch (típicamente `feature/<active-feature-id>`).

### Listar worktrees

```bash
# Listado simple
git worktree list

# Verbose con HEAD/branch info
git worktree list -v

# Machine-readable (útil para parsear desde la-forja MISMA si necesita check programático)
git worktree list --porcelain
```

la-forja invoca `git worktree list --porcelain` durante PREFLIGHT para detectar worktrees pre-existentes (puede pasar si una sesión Fork anterior no hizo cleanup completo).

### Cherry-pick cross-worktree

Cherry-pick opera sobre commits, no sobre worktrees directamente. Workflow:

```bash
# 1. la-forja inspecciona commits de cada worktree
git log la-forja/sandbox-1-literal --oneline
git log la-forja/sandbox-2-creativo --oneline
git log la-forja/sandbox-3-disruptivo --oneline

# 2. la-forja produce recomendación (NO automático — humano confirma)
# Output ejemplo en orchestrate-fork.md sección "Cherry-pick recomendación"

# 3. Después de confirmation humana, la-forja ejecuta:
git checkout main                                       # o el branch del active feature
git cherry-pick abc123 def456                          # commits de sandbox-1
git cherry-pick ghi789                                 # commit de sandbox-2
# Si hay conflicto:
#   - git status muestra el conflicto
#   - resolver manualmente
#   - git add <files-resolved>
#   - git cherry-pick --continue
# Si abortar:
#   - git cherry-pick --abort
```

la-forja NO ejecuta cherry-pick sin confirmation humana. PEDIR siempre.

### Remover worktree

```bash
# Remover worktree (preserva la branch)
git worktree remove <path>

# Forzar (si hay uncommitted changes)
git worktree remove -f <path>

# Ejemplo
git worktree remove .worktrees/sandbox-1
```

### Borrar branch del worktree (post-cleanup)

Si el worktree fue descartado completamente (no se cherry-pickearon commits útiles):

```bash
# Eliminar branch local
git branch -D la-forja/sandbox-3-disruptivo
```

Si se cherry-pickearon commits, considerar mantener la branch un tiempo por si emerge necesidad de re-mirar el approach (decisión humana, no automática).

### Prune

```bash
# Limpia referencias a worktrees ya removidos del filesystem
git worktree prune

# Verbose
git worktree prune -v
```

la-forja invoca `git worktree prune` SIEMPRE al final del cleanup phase de Fork — limpia entries stale en `.git/worktrees/`.

## Ciclo de vida — Fork pattern

```
1. SETUP (orchestrate-fork.md PREFLIGHT)
   ├── git worktree list --porcelain      # check no-stale worktrees
   ├── df -k .worktrees             # check disco libre
   └── (Por cada N) git worktree add .worktrees/sandbox-N -b la-forja/sandbox-N-<personality>
   ↓
2. EJECUCIÓN (workers en paralelo)
   ├── Workers operan dentro de su worktree
   └── la-forja MISMA NO toca filesystem dentro de worktrees (R4 — workers escriben)
   ↓
3. RECOLECCIÓN (orchestrate-fork.md output recolección)
   ├── git log <branch> --oneline         # commits por worktree
   └── cat .worktrees/sandbox-N/RESUMEN.md  # outputs estructurados de workers
   ↓
4. CHERRY-PICK (con confirmation humana)
   ├── la-forja produce recomendación (tabla qué tomar de qué worktree)
   ├── humano confirma o ajusta
   ├── git cherry-pick <commits>          # en active branch (no en worktrees)
   └── resolver conflicts manualmente si emergen
   ↓
5. CLEANUP
   ├── git worktree remove .worktrees/sandbox-N  (por cada N)
   ├── git branch -D la-forja/sandbox-N-<personality>  (solo si descartado)
   └── git worktree prune
```

## Sharing del filesystem

git worktrees comparten:
- `.git/objects/` — todos los commits, refs, tags.
- Hooks (`.git/hooks/`) instalados en main.
- Configuración global de git.

git worktrees NO comparten:
- Working directory (cada uno tiene archivos checked out independientes).
- `HEAD` (cada uno apunta a su propio branch).
- Index (staging area separada por worktree).

**Implicación para Next.js / Node:**
- `node_modules/` se materializa en cada worktree por default — esto **infla disco** (potencialmente >1GB por worktree con dependencies modernas).
- **Mitigación opcional** (decisión del Forge legacy): symlink `node_modules` desde cada worktree apuntando al main. Trade-off: si un worker hace `npm install <new-pkg>`, modifica el `node_modules` shared → afecta otros worktrees → contradice aislamiento.
- **Recomendación canónica de la-forja:** preferir aislamiento completo (cada worktree con su propio `node_modules`) y validar disk en PREFLIGHT (≥2GB libre por worktree). Symlink es opt-in del usuario, no default.

## R4 enforcement

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

la-forja MISMA opera sobre worktrees con Bash limitado:
- `git worktree add/list/remove/prune` (orchestration ops, no aplicación).
- `git cherry-pick` (con confirmation, merge ops).
- `git log` / `git status` / `git rev-parse` (read-only state).
- `df -k` (PREFLIGHT disk check).

NO usa Edit/Write dentro de worktrees — workers son los que escriben en sus worktrees aislados.

## R13 enforcement

> [memory:CONSTRAINTS.md#R13] — External docs citation.

ANTES de generar comandos git worktree, invocar find-docs:

```
[Sub-agent dispatched by la-forja]
  Skill: find-docs
  Query: ctx7 docs /git/htmldocs "git worktree add list remove prune"
  Output: comandos canónicos validados contra docs upstream
```

Si la sintaxis cambia post-cutoff, adoptarla. Si find-docs no responde, fallback a esta doc con caveat `[docs:git]` informativo.

## Edge cases

### Edge: Worktree pre-existente con mismo path

```bash
git worktree add .worktrees/sandbox-1 -b ...
# fatal: '.worktrees/sandbox-1' already exists
```

→ la-forja PREFLIGHT detecta vía `git worktree list --porcelain`. Si stale (sesión anterior crasheó):
- `git worktree remove --force .worktrees/sandbox-1` (después de validar que no hay uncommitted changes valiosos).
- `git worktree prune`.
- Retry add.

### Edge: Branch pre-existente con mismo nombre

```bash
git worktree add .worktrees/sandbox-1 -b la-forja/sandbox-1-literal
# fatal: A branch named 'la-forja/sandbox-1-literal' already exists.
```

→ Sufijo timestamp: `la-forja/sandbox-1-literal-<unix-ts>`. Reportar al humano.

### Edge: Cherry-pick produce conflictos en TODOS los archivos del Blueprint

→ Indicador de que los worktrees divergieron demasiado (probable causa: personality variants demasiado distintas o Blueprint mal aislado). Halt + reportar al humano. Sugerir degradar a Coordinator + el-yunque manual.

### Edge: Disco se llena durante ejecución

→ workers no pueden escribir, fallan silently. Mitigación PREFLIGHT (chequear `df -k` con margen). Si pasa runtime: la-forja NO mata workers (puede haber WIP valioso) — reporta al humano y espera decisión.

### Edge: git worktree add falla por permisos

→ Reportar al humano. NO la-forja intenta sudo o workarounds — el filesystem es responsabilidad del usuario.

## Citation grammar

- [docs:git] — comandos git worktree canónicos (Context7 /git/htmldocs).
- [memory:CONSTRAINTS.md#R4] — la-forja Bash limitado a git worktree ops.
- [memory:CONSTRAINTS.md#R13] — find-docs antes de emitir comandos.

## Refusals

- ❌ Generar git worktree commands sin invocar find-docs primero (R13).
- ❌ `git cherry-pick` automático sin confirmation humana.
- ❌ Force-remove worktree con uncommitted changes sin validar primero.
- ❌ `rm -rf .worktrees/*` directo (rompe metadata git — usar `git worktree remove`).
- ❌ Symlink `node_modules` cross-worktree por default (rompe aislamiento — opt-in del usuario).
