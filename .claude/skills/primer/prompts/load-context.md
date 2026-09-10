# Load Context — secuencia óptima de lectura

## Objetivo

Cargar el contexto del proyecto target en <30s leyendo archivos canónicos en orden óptimo. Cada lectura informa la siguiente — el orden NO es arbitrario.

## Orden de lectura (8 pasos)

### Paso 1 — `AGENTS.md` (raíz del proyecto target)

```
Read: <project-root>/AGENTS.md
```

**Por qué primero:** AGENTS.md es el routing del agente — declara el stack (Next.js + Supabase / Insforge), las reglas operativas locales del proyecto target, y dónde está el rest del context. Si no existe → modo cold-start.

**Extraer:**
- Project name (heading o explicit)
- Stack declarado
- Reglas locales (override de Forja defaults si las hay)

### Paso 2 — `feature_list.json`

```
Read: feature_list.json
```

**Por qué segundo:** después de saber el proyecto, el siguiente input crítico es "¿qué se está construyendo ahora?". feature_list.json tiene el estado canónico — active feature + queue.

**Extraer:**
- `phase` (campo top-level)
- Feature con `state: "active"` (debería haber 1, R1 enforcement)
- Total features (informativo)
- Last passing feature (last item con `state: "passing"`)

### Paso 3 — `PROGRESS.md`

```
Read: PROGRESS.md
```

**Por qué tercero:** complementa feature_list.json con narrative humana de sesiones previas. JSON es para máquinas, PROGRESS.md es para humanos.

**Extraer:**
- Última entrada (top del archivo si es reverse-chrono, bottom si forward-chrono)
- Date de última update
- Si stale (>30 días) → flag

**Si no existe:** continuar — feature_list.json tiene la info crítica.

### Paso 4 — `brand/brand.json` + `brand/voice.json`

```
Read: brand/brand.json (parse top-level)
Read: brand/voice.json (parse archetype)
```

**Por qué cuarto:** brand snapshot es informativo para humanos + contextual para agentes downstream (impeccable, add-ui-kit). No es crítico para "active feature", pero es parte del DNA del proyecto.

**Extraer:**
- `brand.product` (name)
- `archetype.primary` + `archetype.secondary`
- `posture` (6 ejes density/expression/geometry/warmth/editoriality/materiality)
- `tokens.colors.primary` (hex)
- `voice.tone` summary

**Si no existe:** reportar "Brand DNA pending — corré /add-ui-kit" en próxima acción.

### Paso 5 — `.claude/memory/decisions.md`

```
Read: .claude/memory/decisions.md (head 100 lines + grep "^## D-")
```

**Por qué quinto:** ADRs informan decisiones arquitecturales tomadas. NO leer todo el archivo — solo count + último ADR.

**Extraer:**
- Count total `## D-NNN` headers
- Último ADR (más reciente — mayor número)
- Date del último ADR

**Si vacío:** reportar "0 ADRs — proyecto fresh".

### Paso 6 — git status

```
Bash: git rev-parse --abbrev-ref HEAD  (current branch)
Bash: git log --oneline -5  (5 commits recientes)
Bash: git status --short  (working tree state)
```

**Por qué sexto:** git es source of truth para "active feature" (R3 — branch matching `^(feature|fix|refactor|chore|docs)/.+$`). Confirma vs feature_list.json.

**Extraer:**
- Current branch
- Last 5 commit messages (oneline)
- Working tree: clean | N modified | N untracked

**Si proyecto sin git:** omitir, reportar "no git initialized".

### Paso 7 — `README.md` (solo si tiene info nueva)

```
Read: README.md (head 50 lines)
```

**Por qué séptimo:** README es para humanos visiting el repo cold. Si AGENTS.md ya cubre el contexto, README es redundante. Solo leer si NO hay AGENTS.md o si tiene info no replicada (ej: setup steps específicos).

**Extraer:**
- Solo si NO está en AGENTS.md: setup commands, env vars críticas

### Paso 8 — Format output

```
Apply: prompts/format-output.md
```

Aplicar el output template. Detalle en [`format-output.md`](format-output.md).

## Optimizaciones

1. **Read parallelize.** Los pasos 1-7 son independientes (todos reads, no escrituras). Si el agente soporta parallel tool calls, ejecutar 1-7 en paralelo y formatear post-batch. Reduce de ~25s a ~10s en proyectos saludables.
2. **Skip ramas no críticas si timeout.** Si el agente está bajo time pressure (<10s budget), priorizar 1+2+6 (AGENTS + feature_list + git) y skipear 3+4+5+7 (PROGRESS, brand, decisions, README).
3. **Cache fresh reads.** En la misma sesión, si primer se invoca 2 veces seguidas, los reads pueden cachearse. NO implementar cache sofisticado — confiar en el harness.

## Edge cases

| Caso | Comportamiento |
|------|----------------|
| AGENTS.md missing | Modo cold-start: leer README + structure básica |
| feature_list.json corrupted JSON | Reportar "feature_list invalid JSON — corregir" + continuar con git como fallback |
| brand.json missing | Skip brand snapshot, sugerir `/add-ui-kit` |
| decisions.md vacío | Reportar "0 ADRs" |
| git no inicializado | Omitir git section |
| Multiple branches matching feature/* | R3 fallback: usar `.forja/HEAD` si existe; sino reportar ambigüedad |
| feature_list.json con multiple active (violation R1) | Reportar gap + sugerir resolver R1 violation antes de continuar |
| README.md == AGENTS.md (mismo contenido) | Skip paso 7 |

## Citations

- [memory:CONSTRAINTS.md#R1] (WIP=1 — only 1 active feature)
- [memory:CONSTRAINTS.md#R3] (Active feature resolution: branch + .forja/HEAD)
- [memory:references#R-005] (Brand DNA schema cita en brand snapshot)
