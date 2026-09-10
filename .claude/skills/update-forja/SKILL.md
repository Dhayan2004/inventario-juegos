---
name: update-forja
description: >
  Actualiza proyectos existentes con la última versión del template Forja.
  Pipeline DETECT → PULL → BACKUP → MERGE → REPORT. Auto-detecta REPO_PATH
  desde alias `forja` (sin hardcoding). Soporta estructuras flat y dual-tree.
  Hace git pull del source, luego actualiza framework files (.claude/, scripts/,
  Makefile, AGENTS.md, CONSTRAINTS.md, example.mcp.json) preservando archivos
  del proyecto (memory/, feature_list.json, PROGRESS.md, brand/*.json,
  src/features, src/shared, .mcp.json). CLAUDE.md usa merge inteligente con
  marker FORJA:PRESERVE:START. Shape: pipeline DETECT-PULL-MERGE — boundary
  case análogo a D-014 (sin selector entre N approaches).
tier: core
requires: shell con alias `forja` configurado en ~/.zshrc o ~/.bashrc, git instalado, proyecto Forja existente (forja/.claude/ presente o .claude/ flat).
fallback: Si alias `forja` no existe → preguntar REPO_PATH manualmente. Si proyecto no tiene .claude/ → halt: "no parece proyecto Forja". Si CLAUDE.md no tiene marker → warning + skip CLAUDE.md update.
dependencies: []
---

# update-forja

> *"Actualizar es un acto quirúrgico: renová el framework, jamás toques lo que es del proyecto."*

Skill core para mantener proyectos Forja al día con el template upstream. Pipeline DETECT → PULL → BACKUP → MERGE → REPORT — sin selector entre N approaches, todo se auto-detecta del estado del proyecto y del shell.

**No genera código nuevo.** No tiene `templates/` folder. Solo orquesta `git pull`, `rsync`, `cp`, y merge inteligente de CLAUDE.md.

---

## Shape rationale

`update-forja` es **pipeline DETECT-PULL-MERGE** sin selector. [memory:decisions#D-014] establece la doctrine boundary case: skills sin selector requieren ADR propio.

**Análisis L-004:**

| Decisión potencial | ¿Selector entre N approaches? | ¿L-004 aplica? |
|--------------------|------------------------------|----------------|
| Estructura flat vs dual-tree | Auto-detectada, NO elegida por el usuario | NO |
| CLAUDE.md con marker vs sin marker | Auto-detectada, NO elegida | NO |
| Drift en `package.json` / configs | El skill **informa**, NO decide | NO |
| Alias presente vs ausente | Auto-detectado; fallback es prompt one-time, NO selector de approach | NO |

**Conclusión:** boundary case análogo a D-014 (`el-crisol`) y D-023 (`migration-wizard`). Pipeline shape — L-004 NO aplica directo. ADR propio: [memory:decisions#D-027].

---

## PREFLIGHT — halt-blocked (3 gates)

```
1. ¿Estamos en un proyecto Forja?
   - PASS si `forja/.claude/` existe (dual-tree) o `.claude/` existe (flat).
   - FAIL → halt: "No detecté proyecto Forja en este directorio."

2. ¿Working tree limpio?
   - PASS si `git status --porcelain | wc -l` == 0.
   - FAIL → halt: "Hay cambios sin commit. Hacé commit o stash antes de
     actualizar — el merge podría sobreescribir trabajo no guardado."

3. ¿Git inicializado?
   - PASS si `git rev-parse --is-inside-work-tree` exit 0.
   - FAIL → halt: "Proyecto sin git. Iniciá git antes — el rollback en
     caso de fallo depende de git restore."
```

PREFLIGHT halt es halt genuino del pipeline, NO PAUSE del selector (no hay selector). [memory:decisions#D-014] / [memory:decisions#D-023] establecen el patrón.

---

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario corre `/update-forja` para refrescar framework files | humano |
| Después de un release nuevo del template upstream (CHANGELOG bump) | humano |
| Onboarding: refrescar proyecto Forja que estuvo dormant >1 semana | humano |

NO se invoca para: actualizar el template Forja mismo (este skill corre EN proyectos target), regenerar brand DNA (usar `add-ui-kit`), migrar de Forge legacy a Forja (usar `migration-wizard`).

---

## Pipeline canónico

```
PREFLIGHT
   ↓
FASE 1 — Detectar REPO_PATH desde alias forja
   ↓
FASE 2 — Detectar estructura (flat vs dual-tree)
   ↓
FASE 3 — Git pull del source
   ↓
FASE 3b — Auto-delegación (resuelve bootstrap)
   ↓
FASE 4 — Backup de archivos críticos
   ↓
FASE 5 — Actualizar framework files (rsync + cp)
   ↓
FASE 6 — Merge inteligente de CLAUDE.md
   ↓
FASE 7 — Reporte final + drift report
```

### FASE 1 — Detectar REPO_PATH

```bash
ALIAS_LINE=""
for rc in ~/.zshrc ~/.bashrc ~/.bash_profile; do
  if [ -f "$rc" ]; then
    LINE=$(grep -E "^alias forja=" "$rc" 2>/dev/null | head -1)
    if [ -n "$LINE" ]; then ALIAS_LINE="$LINE"; break; fi
  fi
done

if [ -z "$ALIAS_LINE" ]; then
  echo "No encontré alias 'forja' en ~/.zshrc, ~/.bashrc, ni ~/.bash_profile."
  echo "Indicá la ruta del repo Forja (ej: ~/Developer/software/templates/forja):"
  read REPO_PATH
else
  # Formatos válidos (se extrae el DIR FUENTE completo del `cp -r <dir>/. .`):
  #   alias forja="cp -r ~/Developer/software/templates/forge-enterprise/forge/. ."
  #   alias forja="cp -r ~/Developer/software/templates/forja/forja/. ."   # legacy
  #   alias forja='[ -z "$(ls -A ...)" ] && cp -r <dir>/. . || echo "..."' # con guard
  # REPO_PATH = la ruta antes de "/. " — el subdir del template (forge/ o forja/),
  # que en FASE 2 se detecta como estructura "flat" (tiene .claude/ + CLAUDE.md).
  # NO asumir que el subdir se llama forja/ (la fábrica Enterprise usa forge/).
  REPO_PATH=$(echo "$ALIAS_LINE" | sed -E 's|.*cp -r ([^ ]+)/\. \..*|\1|')
  REPO_PATH="${REPO_PATH/#\~/$HOME}"
fi

[ ! -d "$REPO_PATH" ] && halt "REPO_PATH=$REPO_PATH no existe. Verificá el alias."
```

### FASE 2 — Detectar estructura

```bash
if [ -d "$REPO_PATH/.claude" ] && [ -f "$REPO_PATH/CLAUDE.md" ]; then
  ESTRUCTURA="flat"
  FORJA_DIR="$REPO_PATH"
elif [ -d "$REPO_PATH/forja/.claude" ] && [ -f "$REPO_PATH/forja/CLAUDE.md" ]; then
  ESTRUCTURA="dual-tree"
  FORJA_DIR="$REPO_PATH/forja"
else
  halt "No detecté estructura Forja en $REPO_PATH (ni flat ni dual-tree)."
fi
```

A partir de acá, usar SIEMPRE `$FORJA_DIR` — nunca hardcodear `/forja/`.

### FASE 3 — Git pull del source

```bash
(cd "$REPO_PATH" && git pull origin main)
```

Si falla (merge conflict, detached HEAD, etc.) → halt con stdout del error.

### FASE 3b — Auto-delegación (resuelve bootstrap problem)

Después del `git pull`, `$FORJA_DIR/.claude/skills/update-forja/SKILL.md` tiene la versión MÁS RECIENTE del propio skill.

**Protocolo:**

1. Comparar mtime / hash del `SKILL.md` local vs source.
2. Si difieren → cargar `$FORJA_DIR/.claude/skills/update-forja/SKILL.md` y ejecutar Fases 4-7 desde ESA versión, no esta.
3. Si son iguales → continuar con esta misma versión.

Esto garantiza que cada `/update-forja` se ejecuta con la lógica más nueva, independiente de la versión instalada en el proyecto.

### FASE 4 — Backup de archivos críticos

```bash
TS=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=".forja-backup-$TS"
mkdir -p "$BACKUP_DIR"

[ -f CLAUDE.md ] && cp CLAUDE.md "$BACKUP_DIR/CLAUDE.md"
[ -f AGENTS.md ] && cp AGENTS.md "$BACKUP_DIR/AGENTS.md"
[ -f CONSTRAINTS.md ] && cp CONSTRAINTS.md "$BACKUP_DIR/CONSTRAINTS.md"
[ -f Makefile ] && cp Makefile "$BACKUP_DIR/Makefile"
[ -d .claude ] && cp -r .claude "$BACKUP_DIR/.claude" 2>/dev/null
```

Backup obligatorio antes de tocar nada. [memory:errors#E-009] "no destruir contenido del usuario" — sin backup el rollback depende solo de git.

### FASE 5 — Actualizar framework files

**UPDATE WHOLESALE (framework):**

```bash
rsync -av --delete "$FORJA_DIR/.claude/commands/"   .claude/commands/
rsync -av --delete "$FORJA_DIR/.claude/prompts/"    .claude/prompts/
rsync -av --delete "$FORJA_DIR/.claude/references/" .claude/references/
rsync -av --delete "$FORJA_DIR/.claude/ontology-migrations/" .claude/ontology-migrations/

# Skills: rsync con --delete pero EXCLUIR memory/ por seguridad
rsync -av --delete --exclude='*/memory/' \
  "$FORJA_DIR/.claude/skills/" .claude/skills/

rsync -av --delete "$FORJA_DIR/scripts/" scripts/
cp "$FORJA_DIR/Makefile"          Makefile
cp "$FORJA_DIR/AGENTS.md"         AGENTS.md
cp "$FORJA_DIR/CONSTRAINTS.md"    CONSTRAINTS.md
cp "$FORJA_DIR/example.mcp.json"  example.mcp.json
```

**NEVER TOUCH (project files):**

- `.claude/memory/*.md` — memoria del proyecto ([memory:CONSTRAINTS.md#R5])
- `feature_list.json` — state del proyecto
- `PROGRESS.md` — log del proyecto
- `brand/brand.json`, `brand/voice.json`, `brand/brand.css` — Brand DNA ([memory:CONSTRAINTS.md#R10])
- `src/features/`, `src/shared/` — código del proyecto
- `src/app/page.tsx`, `layout.tsx`, `globals.css` — UI del proyecto (probable custom)
- `.mcp.json` — credenciales reales del usuario
- `node_modules/`, `.next/` — build artifacts

**DETECT-AND-REPORT (config drift — informar, no sobreescribir):**

Para cada uno de: `package.json`, `next.config.ts`, `tailwind.config.ts`, `tsconfig.json`, `components.json`, `postcss.config.js` — comparar local vs source. Si difieren → acumular en reporte de drift al final con diff de 3 líneas relevantes y recomendación.

### FASE 5b — Migrar esquema de ONTOLOGY.md (S3, si aplica)

El template renovó `.claude/ontology-migrations/`. Si el proyecto tiene `ONTOLOGY.md` (ontología
emitida), propagá las migraciones de esquema pendientes SIN tocar los datos del cliente:

```bash
if [ -f ONTOLOGY.md ]; then
  node scripts/apply-ontology-migrations.mjs               # dry-run: reporta pendientes
  node scripts/apply-ontology-migrations.mjs --apply       # aplica (idempotente + backup propio)
fi
```

Es aditivo, idempotente y con su propio backup en `.forja/ontology-backups/` (además del backup de
FASE 4). Si no hay `ONTOLOGY.md`, se salta sin ruido. Incluí el resultado (migraciones aplicadas o
"al día") en el reporte de FASE 7. Detalle: `.claude/ontology-migrations/README.md`.

### FASE 6 — Merge inteligente de CLAUDE.md

```bash
MARKER="<!-- FORJA:PRESERVE:START"
TEMPLATE_CLAUDE="$FORJA_DIR/CLAUDE.md"
TARGET_CLAUDE="./CLAUDE.md"

if [ ! -f "$TARGET_CLAUDE" ]; then
  cp "$TEMPLATE_CLAUDE" "$TARGET_CLAUDE"
  CLAUDE_STATUS="creado desde template (no existía CLAUDE.md previo)"
elif grep -q "$MARKER" "$TARGET_CLAUDE"; then
  PRESERVED=$(sed -n "/$MARKER/,\$p" "$TARGET_CLAUDE")
  FRAMEWORK_ZONE=$(sed "/$MARKER/,\$d" "$TEMPLATE_CLAUDE")
  printf '%s\n%s\n' "$FRAMEWORK_ZONE" "$PRESERVED" > "$TARGET_CLAUDE"
  CLAUDE_STATUS="actualizado (zona framework renovada, aprendizajes preservados)"
else
  CLAUDE_STATUS="NO actualizado — marker FORJA:PRESERVE:START no encontrado en CLAUDE.md local"
fi
```

Cita: [memory:errors#E-009] — la lección "no destruir contenido del usuario" se extiende a `CLAUDE.md` vía marker (no sobreescritura silenciosa de aprendizajes/Auto-Blindaje del proyecto).

### FASE 7 — Reporte final

```
✅ Forja actualizado.

Source: $FORJA_DIR ($ESTRUCTURA)
Versión: $(grep -m1 '^## \[' "$FORJA_DIR/CHANGELOG.md" || echo "sin changelog")

Archivos actualizados:
  - .claude/commands/        — N comandos
  - .claude/skills/          — N skills
  - .claude/prompts/         — N prompts
  - .claude/references/      — N references
  - scripts/                 — hooks + preflight + citation-lint
  - Makefile                 — targets actualizados
  - AGENTS.md                — routing actualizado
  - CONSTRAINTS.md           — R1-Rn actualizados
  - example.mcp.json         — template MCP actualizado
  - CLAUDE.md                — $CLAUDE_STATUS

Archivos NO modificados (tu proyecto):
  - .claude/memory/*.md
  - feature_list.json
  - PROGRESS.md
  - brand/brand.json, voice.json, brand.css (si existen)
  - src/features/, src/shared/
  - src/app/ (tus rutas)
  - .mcp.json (credenciales)

[Si hay drift en configs detectados, listar aquí]:
  ⚠️  Config drift detectado:
  - package.json: source agregó deps X, Y. Considerá npm install.
  - tailwind.config.ts: source agregó plugins. Mergear manualmente si los necesitás.

Backup en: $BACKUP_DIR/ (borrá cuando confirmes OK)
```

Si `CLAUDE_STATUS == "NO actualizado — marker no encontrado"`:

```
⚠️  CLAUDE.md no fue actualizado.
    Para futuros updates, agregá esta línea en tu CLAUDE.md justo antes
    de tus aprendizajes/Auto-Blindaje:

        <!-- FORJA:PRESERVE:START — Todo lo de abajo es tuyo. /update-forja nunca lo toca. -->

    Y movelo a la posición correcta (después del contenido framework).
```

---

## Reglas operativas

1. **Auto-detección de REPO_PATH es no-negociable.** Nunca hardcodear `~/Developer/...`. La fuente de verdad es el alias `forja` del shell del usuario.
2. **Backup antes de tocar (FASE 4 mandatory).** Si por cualquier razón no se puede crear `.forja-backup-$TS/`, halt antes de FASE 5.
3. **NEVER TOUCH list es contrato.** memory/, feature_list, brand/*.json, src/features|shared, .mcp.json, PROGRESS.md, src/app/ — ninguna fase los altera. [memory:CONSTRAINTS.md#R5] · [memory:CONSTRAINTS.md#R10].
4. **CLAUDE.md sin marker = skip.** Nunca sobreescribir CLAUDE.md sin el marker FORJA:PRESERVE:START presente — es contenido del usuario por defecto.
5. **Config drift se reporta, no se sobreescribe.** `package.json`, `next.config.ts`, `tailwind.config.ts`, `tsconfig.json`, `components.json`, `postcss.config.js` — diff con source, listar al final, dejar la decisión al humano.
6. **Auto-delegación post-pull resuelve bootstrap.** Después del `git pull` la fuente tiene la lógica más nueva — usar ESA, no la versión vieja instalada en el proyecto.
7. **PREFLIGHT halt es halt genuino del pipeline, no PAUSE del selector** ([memory:decisions#D-027] boundary case análogo a D-014/D-023 — no hay selector).

---

## Refusals

- ❌ NUNCA tocar archivos en NEVER TOUCH list (memory/, feature_list.json, brand/*.json, src/features|shared, .mcp.json, PROGRESS.md, src/app/).
- ❌ NUNCA sobreescribir CLAUDE.md sin marker FORJA:PRESERVE:START (es contenido del usuario).
- ❌ NUNCA hardcodear paths absolutos — siempre derivar de REPO_PATH desde alias o input del usuario.
- ❌ NUNCA correr sin working tree limpio (Gate 2 lo enforcea — halt sin excepción).
- ❌ NUNCA correr sin backup previo (FASE 4 es obligatoria — si falla, halt antes de FASE 5).
- ❌ NUNCA sobreescribir `package.json` / `tailwind.config.ts` / `tsconfig.json` automáticamente — drift se reporta, no se aplica.
- ❌ NUNCA escribir a `.claude/memory/*.md` — sole writer es `el-evaluador` ([memory:CONSTRAINTS.md#R5]).

---

## Tool filter

`Read · Edit · Write · Grep · Glob · Bash (limited: git, rsync, cp, sed, grep, mkdir, diff)`

NO Skill dispatch (este skill no invoca otros skills — pipeline self-contained).

---

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R5]` | Para invariante "memory es sole-writer evaluador" — NEVER TOUCH list. |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | Para invariante "brand DNA del proyecto" — NEVER TOUCH list. |
| Decision | `[memory:decisions#D-027]` | Para pipeline shape boundary case. |
| Decision | `[memory:decisions#D-014]` | Patrón heredado: pipeline sin selector (`el-crisol`). |
| Decision | `[memory:decisions#D-023]` | Patrón heredado: pipeline DETECT (`migration-wizard`). |
| Error | `[memory:errors#E-009]` | Lección "no destruir contenido del usuario" — extendida a CLAUDE.md vía marker. |
| Lesson | `[memory:lessons#L-004]` | Informativo — NO aplica directo (sin selector). |

---

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `migration-wizard` | Upstream complementario: `migration-wizard` planifica migraciones desde Forge/custom, `update-forja` mantiene proyectos ya migrados al día. NO se invocan entre sí. |
| `el-evaluador` | NO dependencia directa. Post-update el usuario puede correr `el-evaluador` si quiere verificar three-layer. |
| `primer` | Downstream natural: tras `/update-forja`, ejecutar `/avivar` (primer) refresca el contexto con el routing nuevo. |
| `skill-creator` | Sin overlap: `skill-creator` genera scaffolds nuevos; `update-forja` mantiene los existentes. |

---

## Output handoff

```markdown
## update-forja handoff

**Source:** $FORJA_DIR ($ESTRUCTURA)
**Versión:** [primera línea del CHANGELOG.md del source]
**CLAUDE.md status:** [creado | actualizado | NO actualizado (sin marker)]
**Backup:** .forja-backup-$TS/

**Outputs:**
- .claude/{commands,skills,prompts,references}/ — wholesale replace
- scripts/, Makefile, AGENTS.md, CONSTRAINTS.md, example.mcp.json — replace
- CLAUDE.md — merge inteligente (zona framework actualizada, marker preservado)

**Drift detectado:** [N archivos | ninguno]

**Próximo paso:** Si hay drift, revisar los diffs reportados. Borrar $BACKUP_DIR/ cuando confirmes que todo está OK. Correr `/avivar` (primer) para refrescar contexto con el nuevo routing.
```

---

*"El framework se renueva; el proyecto persiste. Esa es la línea que el marker traza."*
