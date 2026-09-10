# detect-origin

> Fase 0 de migration-wizard. Clasifica el origen del proyecto a migrar (5 tipos). Output determina qué pattern de análisis aplicar en Fase 1 (analyze-gaps.md).

## Inputs

- Project root path (cwd o path provisto).
- Acceso de lectura a `package.json`, `README.md`, `.git/`, `src/`, `.claude/`, `` (si existen).

## Output

```yaml
detection:
  project_root: <path>
  project_name: <derivado de package.json name o cwd basename>

  origin_type: A | B | C | D | E
  origin_description: <texto>

  evidence:
    package_json_exists: bool
    git_inicializado: bool
    next_in_deps: bool
    other_framework: <remix | sveltekit | astro | nuxt | gatsby | none>
    has_dot_claude: bool
    has_dot_claude_skills: bool
    has_la_herreria_skill: bool
    has_forge_v2_markers: bool
    has_forge_v3_markers: bool
    has_forja_AGENTS: bool       # ya migrado — halt en PREFLIGHT
    has_src_dir: bool
    has_app_router: bool          # src/app/ o app/
    has_pages_router: bool        # src/pages/ o pages/

  recommendation:
    proceed_to_analyze: bool
    halt_reason: <texto si NO proceder>
```

## Step-by-step

### Paso 1 — Detectar package.json + framework

```bash
test -f package.json && cat package.json | grep -E "\"next\"|\"remix\"|\"sveltekit\"|\"astro\"|\"nuxt\"|\"gatsby\"" 2>/dev/null
```

- Si `next` en deps → `next_in_deps = true`.
- Si otro framework → `other_framework = <nombre>`.
- Si no hay package.json → posible greenfield (Tipo E) o no-Node project.

### Paso 2 — Detectar `.claude/`

```bash
test -d .claude/
test -d .claude/skills/
test -d .claude/skills/la-herreria/
```

- Si `.claude/skills/la-herreria/` existe → markers de Forge V3.x (Tipo A potencial).
- Si `.claude/skills/` existe pero sin la-herreria → markers más antiguos (Forge V2 — Tipo B potencial).
- Si NO `.claude/` → Tipo C/D/E (sin Forge previo).

### Paso 3 — Detectar Forja ya migrado (PREFLIGHT halt)

```bash
test -f AGENTS.md
test -f feature_list.json
test -f .claude/memory/skills.md
```

- Si **TODOS** existen → `has_forja_AGENTS = true` → halt: "Proyecto ya migrado a Forja Enterprise. Corré /forge-check para diagnóstico."
- Si parcial (1 o 2 de 3) → ambiguo. Reportar como warning + permitir continuar como Tipo Forja-parcial (raro, pero válido).

### Paso 4 — Detectar Forge V3 markers

```bash
test -f CLAUDE.md && grep -E "Forge V3|Factory OS|forge V3\.|version.*3" CLAUDE.md
test -f .claude/commands/build.md
test -f .claude/skills/impeccable/SKILL.md
test -f .claude/skills/web-quality/SKILL.md
test -f .claude/prompts/el-yunque.md
```

- Si CLAUDE.md tiene "Forge V3" + .claude/skills/impeccable + .claude/prompts/el-yunque → `has_forge_v3_markers = true`.

### Paso 5 — Detectar Forge V2 markers

```bash
test -f CLAUDE.md && grep -E "Forge V2|Factory OS|version.*2" CLAUDE.md
test -d .claude/skills/ && ! test -d .claude/skills/la-herreria/
```

- Si CLAUDE.md sin "Forge V3" + .claude/skills/ presente + sin la-herreria → `has_forge_v2_markers = true`.

### Paso 6 — Detectar src/ structure

```bash
test -d src/
test -d src/app/ || test -d app/
test -d src/pages/ || test -d pages/
test -d src/features/
```

### Paso 7 — Clasificar origen

```
SI has_forja_AGENTS = true (todos los 3 markers Forja):
  → halt PREFLIGHT: "ya migrado"

SI has_forge_v3_markers = true:
  → origin_type = A
  → origin_description = "Forge V3.x (.claude/skills/la-herreria existe + CLAUDE.md V3)"

SI has_forge_v2_markers = true:
  → origin_type = B
  → origin_description = "Forge V2 (CLAUDE.md sin estructura  + .claude/skills antiguo)"

SI next_in_deps = true Y NO has_forge_v2/v3_markers:
  → origin_type = C
  → origin_description = "Next.js custom (sin Forge/Forja previo)"

SI other_framework != null:
  → origin_type = D
  → origin_description = "Otro framework: {other_framework}"

SI no_package_json Y has_src_dir Y git_inicializado:
  → origin_type = E
  → origin_description = "Greenfield con código (sin package.json claro pero con archivos)"

SI no nada:
  → halt informativo: "No se detecta proyecto. Indicá path con migration-wizard /path/to/project."
```

### Paso 8 — Presentar al usuario

```
━━━ migration-wizard — Fase 0: DETECT ━━━

📂 Proyecto: {project_name}
📍 Path: {project_root}

🔍 Origen detectado: Tipo {A|B|C|D|E}
   {origin_description}

Evidence:
   - package.json: ✅/❌
   - .git: ✅/❌
   - .claude/skills/la-herreria: ✅/❌ (Forge V3 marker)
   - .claude/skills/ (sin la-herreria): ✅/❌ (Forge V2 marker)
   - Framework: {next | remix | sveltekit | astro | none}
   - Estructura: {src/app | src/pages | src/ | none}

¿Proceder a Fase 1 (ANALYZE)? (sí / abort / cambiar path)
```

## Edge cases

### Edge 1 — Proyecto Forge V3 con  parcial
- has_forge_v3_markers = true Y has_forja_AGENTS parcial.
- Reportar como "Tipo A (Forge V3) con migración parcial iniciada".
- Continuar a Fase 1.

### Edge 2 — Monorepo
- package.json en root + sub-packages con sus propios package.json.
- Reportar warning + preguntar al usuario qué sub-paquete migrar.
- NO ejecutar análisis sobre todo el monorepo (genera plan inviable).

### Edge 3 — Stack incompatible (ej: Astro)
- next_in_deps = false + other_framework = astro.
- Tipo D (otro framework).
- En Fase 1 (analyze-gaps.md), documentar costo de re-escritura a Next.js.

### Edge 4 — Greenfield (sin package.json)
- Tipo E (greenfield).
- En Fase 1, recomendar instalar Next.js + Forja desde cero (más rápido que adaptar).

### Edge 5 — Proyecto con package.json pero sin src/
- Posible librería pure (ej: paquete npm).
- Reportar warning + preguntar si realmente quiere "migrar a Forja" (Forja es para apps SaaS, no libs).

## Citation

[memory:decisions#D-023] (pipeline shape DETECT → ANALYZE → PLAN), [memory:decisions#D-014] (boundary case shape-par a el-crisol).
