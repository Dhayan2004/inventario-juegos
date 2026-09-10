# Format Output — output template

## Objetivo

Producir resumen estructurado en markdown legible para humanos Y para agentes. ~150-300 palabras total. 5 elementos canónicos en orden fijo.

## Template canónico

```markdown
# <Project Name>

**Forja state:** <fase actual> · <last update date> · branch `<git branch>`

## Active feature
**ID:** `<F3-S?>` · **State:** `<active|passing|blocked>`
<behavior summary 1-2 lines max — derivar de feature_list.json behavior field>
**Verification:** `<command>`
**Branch:** `feature/<...>`

## Última actividad
```
<commit hash> <commit message>
<commit hash> <commit message>
<commit hash> <commit message>
<commit hash> <commit message>
<commit hash> <commit message>
```
**Working tree:** `<clean | N modified | N untracked>`

## Brand snapshot
**Archetype:** `<primary>` + `<secondary>` (Mark+Pearson 12-archetype framework)
**Posture:** density=<n> · expression=<n> · geometry=<n> · warmth=<n> · editoriality=<n> · materiality=<n> *(escala 1-5)*
**Visual reference:** `<ej: Linear/Vercel family | Editorial Monocle | Brutalist | Tech Utility>`

## Próxima acción sugerida
<accionable específica — NO genérica. Ejemplos:>
- `Continuá F3-S7 commit M con next-step en prompts/format-output.md`
- `feature_list.json shows 0 active — pickear próxima feature del backlog`
- `Brand DNA pending — corré /add-ui-kit antes de cualquier UI work`
- `7 commits ahead of origin/main sin push — considerá push intermedio`

---
*Context loaded in <N>s. <X> files read. <Y> gaps detected.*
```

## Reglas de formato

1. **Heading H1 = project name** — extraído de brand.json.brand.product (priority) > AGENTS.md heading > directory name (fallback).
2. **Sección "Forja state"**: una línea con 3 fields separados por `·`. Date format `YYYY-MM-DD`. Branch en backticks.
3. **Active feature**: si hay 1 active → mostrar shape canónico. Si 0 active → reportar "No active feature" + sugerir backlog. Si >1 active → reportar "R1 violation: N active" + sugerir resolución.
4. **Última actividad**: 5 commits, oneline format. Working tree state derivado de `git status --short` count.
5. **Brand snapshot**: si brand.json existe → 3 lines (archetype + posture + visual reference). Si no → reportar "Brand DNA pending" + suggested action.
6. **Próxima acción**: SIEMPRE accionable. NO "trabajá en lo que tengas". Específica al estado real.
7. **Footer line**: timing + files read + gaps (informativo, una sola línea).

## Tone

- **Directo**, no flowery.
- **Plural inclusivo Argentino** ("vos", "corré", "tu") — match Forja brand defaults.
- **Sin emojis**, salvo que el brand explícitamente los use (raro).
- **Specific over generic**: nombres concretos, fechas concretas, números concretos.

## Output bounds

- **Min:** ~150 palabras (proyecto fresh con muchos gaps, mucho contenido en "próxima acción")
- **Max:** ~300 palabras (proyecto maduro con info densa)
- **Avg target:** ~200 palabras

Si excede 300 palabras → comprimir descriptions. NO comprimir el "próxima acción" (ese debe ser accionable).

## Adaptaciones por estado del proyecto

### Proyecto fresh (recién inicializado con Forja)

```markdown
# <Project Name>

**Forja state:** Phase 1 (bootstrap) · 2026-05-08 · branch `main`

## Active feature
**(none)** — feature_list.json tiene N features en `pending`, ninguna `active`.

## Última actividad
```
abc1234 chore(forja): initial commit
```
**Working tree:** clean

## Brand snapshot
**(pending)** — corré `/add-ui-kit` para inicializar Brand DNA.

## Próxima acción sugerida
- Corré `/add-ui-kit` Discovery FRESH para definir brand.json + voice.json
- Después: `/add-login` para auth + `/add-payments`/`/add-emails`/`/add-mobile` según necesidad
```

### Proyecto en build (active feature)

```markdown
# Forja

**Forja state:** Phase 3 (skills migration, F3-S7 active) · 2026-05-08 · branch `feature/primer`

## Active feature
**ID:** `F3-S7` · **State:** `active`
Skill primer authored — lightweight context loader (<30s) para proyectos target.
**Verification:** `bash .claude/skills/primer/tests/dry-run.sh`
**Branch:** `feature/primer`

## Última actividad
```
6061367 chore(state): activate F3-S7 (primer)
9e2d506 chore(state): mark promote-l-004 passing
ce2a992 docs(decision-trees): cross-cite L-004
7f1ea33 evaluator(L-004-promotion-citations): cross-cite ADRs
a67bc01 memory(L-004): record diagnostic test
```
**Working tree:** 1 modified

## Brand snapshot
**Archetype:** Creator + Sage
**Posture:** density=4 · expression=2 · geometry=2 · warmth=2 · editoriality=4 · materiality=2
**Visual reference:** Linear/Vercel/Forge family

## Próxima acción sugerida
- Continuá F3-S7 — falta `prompts/handoff-targets.md` + 3 references + tests/dry-run.sh
```

### Proyecto cerca de deploy

```markdown
# <Project Name>

**Forja state:** Phase 6 (pre-deploy) · 2026-05-10 · branch `main`

## Active feature
**(none active)** — última `passing` fue F5-S3 con commit a1b2c3d.

## Última actividad
```
def4567 test(deploy): pre-prod smoke
abc1234 chore(state): mark F5-S3 passing
...
```
**Working tree:** clean

## Brand snapshot
**Archetype:** Caregiver + Sage
**Posture:** density=3 · expression=3 · geometry=3 · warmth=4 · editoriality=2 · materiality=3
**Visual reference:** Warm & Soft

## Próxima acción sugerida
- Invocá `/el-guardian` para pre-deploy security audit
- Después PASS: `/web-quality` Lighthouse audit
- Si ambos PASS: deploy via `/vercel-deployer`
```

## Citations

- [memory:references#R-005] (Brand DNA schema en brand snapshot)
- [memory:CONSTRAINTS.md#R1] (WIP=1 — only 1 active)
- [memory:CONSTRAINTS.md#R3] (active feature resolution)
