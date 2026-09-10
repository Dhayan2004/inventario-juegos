# Worktree management — referencia

> Comandos canónicos `git worktree` para Pattern Fork. Validados vía Context7 `/git/htmldocs`. R13 enforced.

## Comandos canónicos

### `git worktree add`

```bash
# Sintaxis
git worktree add <path> [<commit-ish>]
git worktree add <path> -b <new-branch> [<commit-ish>]
git worktree add --detach <path> <commit-ish>
git worktree add --track -b <branch> <path> <remote>/<branch>

# Usos canónicos en Fork
git worktree add .worktrees/sandbox-1 -b la-forja/sandbox-1-literal
git worktree add .worktrees/sandbox-2 -b la-forja/sandbox-2-creativo
git worktree add .worktrees/sandbox-3 -b la-forja/sandbox-3-disruptivo
```

**Comportamiento:**
- Crea path nuevo + checkout de commit-ish.
- Comparte `.git/objects/`, hooks, config global.
- Per-worktree: `HEAD`, index, working directory.
- Si branch ya existe en otro worktree → error (no se puede checked-out 2× simultáneos).

### `git worktree list`

```bash
git worktree list                  # listing simple
git worktree list -v               # verbose (HEAD info)
git worktree list --porcelain      # machine-readable
git worktree list --porcelain -z   # null-terminated entries (con --porcelain)
```

la-forja invoca `--porcelain` durante PREFLIGHT para detectar worktrees stale.

Output típico simple:
```
/path/to/repo                  abc1234 [main]
/path/to/repo/forja/.worktrees/sandbox-1  def5678 [la-forja/sandbox-1-literal]
/path/to/repo/forja/.worktrees/sandbox-2  ghi9012 [la-forja/sandbox-2-creativo]
```

### `git worktree remove`

```bash
git worktree remove <path>
git worktree remove -f <path>      # force, aún con uncommitted changes
```

la-forja invoca `git worktree remove` (sin -f por default) en cleanup phase. Si retorna error por uncommitted changes:
- Validar si hay WIP valioso pendiente (lectura del worktree antes de force).
- Si humano confirma descarte → `git worktree remove -f`.
- Si NO → halt + reportar.

### `git worktree prune`

```bash
git worktree prune
git worktree prune -v              # verbose
git worktree prune --dry-run       # solo reportar, no actuar
```

Limpia entries en `.git/worktrees/` cuyos paths del filesystem ya no existen. la-forja invoca SIEMPRE en cleanup phase post-`remove`.

### `git cherry-pick`

```bash
# Cherry-pick un commit
git cherry-pick <commit-sha>

# Cherry-pick un rango
git cherry-pick <start-sha>^..<end-sha>

# Continuar después de resolver conflicto
git cherry-pick --continue

# Abortar
git cherry-pick --abort

# Skip commit problemático
git cherry-pick --skip
```

la-forja produce recomendación + comandos exactos, humano confirma, la-forja ejecuta cherry-pick en el active branch (NO en worktrees).

## Naming conventions de la-forja

| Recurso | Pattern | Ejemplo |
|---------|---------|---------|
| Worktree path | `.worktrees/sandbox-N` | `.worktrees/sandbox-1` |
| Branch | `la-forja/sandbox-N-<personality>` | `la-forja/sandbox-1-literal` |
| Output files | `.worktrees/sandbox-N/<RESUMEN\|MEJORAS\|ARQUITECTURA\|PROBLEMAS>.md` | `.worktrees/sandbox-1/RESUMEN.md` |

`.worktrees/` agregado a `.gitignore` (la-forja PREFLIGHT verifica + agrega si falta) — los worktrees son ephemeral, no se commitean.

## Disk usage

Cada worktree materializa working directory. Para Next.js + Supabase típico:

| Componente | Tamaño aproximado |
|------------|-------------------|
| Source code (src + brand + .claude) | ~50-200 MB |
| `node_modules/` (Next 16 + libs) | ~800 MB - 1.5 GB |
| `.next/` build cache (si build run) | ~200-500 MB |
| Test artifacts, screenshots | ~50-200 MB |
| **Total typical** | **~1.5-2.5 GB por worktree** |

PREFLIGHT chequea `df -k` con margen N×2GB. Si fail:
- Sugerir reducir N.
- O habilitar symlink `node_modules` (opt-in, NO default).
- O degradar a Coordinator.

## node_modules sharing (opt-in)

**Default Forja: NO symlink** (aislamiento completo, validado por disco).

**Opt-in symlink** (cuando disco es premium):

```bash
# En cada worktree después de git worktree add:
cd .worktrees/sandbox-N
rm -rf node_modules
ln -s ../../node_modules node_modules
```

**Trade-offs:**
- ✅ Disco N×2GB → 1×2GB.
- ❌ Si worker hace `npm install <new-pkg>`, modifica el shared `node_modules` → afecta otros worktrees.
- ❌ Romper aislamiento es la razón de existir del Fork pattern.

**Mitigación si opt-in:**
- Workers prompt explícito: "NO ejecutes `npm install` durante el build. Si necesitás un package nuevo, document en PROBLEMAS.md y la-forja lo agrega post-cherry-pick."

## Ciclo de vida completo

```
PREFLIGHT
  ├── git worktree list --porcelain         # check stale
  ├── df -k                                 # check disk
  └── (cleanup stale si aplica)
       └── git worktree remove --force <stale-path>
       └── git worktree prune

SETUP
  ├── (Por cada N de 1..N)
  │   └── git worktree add .worktrees/sandbox-N -b la-forja/sandbox-N-<personality>
  └── (opt-in) symlink node_modules

EJECUCIÓN
  └── workers operan en sus worktrees (la-forja MISMA NO toca filesystem dentro)

RECOLECCIÓN
  ├── (Por cada N) git log la-forja/sandbox-N-<personality> --oneline
  └── (Por cada N) cat .worktrees/sandbox-N/RESUMEN.md

CHERRY-PICK (con confirmation humana)
  ├── git checkout <active-feature-branch>
  ├── git cherry-pick <commits>
  └── (resolver conflicts manualmente)

CLEANUP
  ├── (Por cada N) git worktree remove .worktrees/sandbox-N
  ├── (Por cada N descartado) git branch -D la-forja/sandbox-N-<personality>
  └── git worktree prune
```

## Edge cases

### Edge: stale worktree (sesión Fork crasheó previa)

Detectado en PREFLIGHT vía `git worktree list --porcelain`. Resolución:
```bash
git worktree remove --force .worktrees/sandbox-1
git worktree prune
```

Después de validar que no hay WIP valioso. Si hay → opción humana de salvarlo (cherry-pick antes de remove).

### Edge: branch reuso (la-forja/sandbox-1-literal ya existe)

```bash
git worktree add .worktrees/sandbox-1 -b la-forja/sandbox-1-literal
# fatal: A branch named 'la-forja/sandbox-1-literal' already exists.
```

Resolución: sufijo timestamp `la-forja/sandbox-1-literal-<unix-ts>`. Reportar al humano.

### Edge: worktree path no creable (permisos)

```bash
git worktree add .worktrees/sandbox-1 -b ...
# fatal: could not create directory ...
```

Reportar al humano. la-forja NO intenta `chmod`/`sudo`.

### Edge: cherry-pick conflict denso

Si después de `git cherry-pick`, `git status` muestra >5 archivos en conflict:
- la-forja pausa el cherry-pick.
- Reporta al humano con tabla qué archivos conflictan + qué versión preferir según worktree origin.
- Humano resuelve manualmente.
- `git cherry-pick --continue` after.

### Edge: cherry-pick abortado mid-way

Si humano dice "abortar":
```bash
git cherry-pick --abort
```

la-forja reporta estado: "cherry-pick abortado, branch active al estado pre-cherry-pick. Worktrees aún disponibles para inspección, NO se hizo cleanup automático. Pedí cleanup explícito si estás listo."

## Citation grammar

- [docs:git] — comandos validados contra Context7 `/git/htmldocs`.
- [memory:CONSTRAINTS.md#R4] — la-forja Bash limitado a git worktree ops.
- [memory:CONSTRAINTS.md#R13] — find-docs antes de emitir comandos.
- [memory:references#R-007] — Context7 (find-docs sub-tool).

## Anti-patterns

- ❌ `rm -rf .worktrees/<sandbox>` directo (rompe metadata git — usar `git worktree remove`).
- ❌ Force-remove sin validar uncommitted changes valiosos.
- ❌ Symlink `node_modules` por default (rompe aislamiento — opt-in solo).
- ❌ Cherry-pick sin confirmation humana.
- ❌ Skip de `git worktree prune` post-cleanup (deja stale entries).
