# Output Templates — ejemplos de resumen bien-formed

> 3 templates concretos para los 3 estados canónicos de un proyecto target.

## Template 1 — Proyecto fresh (recién `forge-init`)

Indicators: AGENTS.md +  existen, pero feature_list.json tiene 0 features con `state: passing`. Brand DNA pending. Solo 1-2 commits.

```markdown
# acme-saas

**Forja state:** Phase 0 (bootstrap) · 2026-05-08 · branch `main`

## Active feature
**(none)** — feature_list.json tiene 5 features `pending`, ninguna `active`.

## Última actividad
```
e8f9a01 chore(forja): initial commit (saas-factory cherry-pick)
```
**Working tree:** clean

## Brand snapshot
**(pending)** — corré `/add-ui-kit` Discovery FRESH para definir brand.json + voice.json.

## Próxima acción sugerida
- Inicializá Brand DNA: `/add-ui-kit` Discovery FRESH
- Después: pickea primer feature del backlog (`F1-S1` parece next) e invocá `/la-forja` o `/el-golpe`

---
*Context loaded in 8s. 4 files read. 2 gaps detected (brand.json + componentes UI base).*
```

**Características:**
- Próxima acción muy específica (Discovery FRESH explícito)
- Reconoce gaps explícitos
- Sugiere skill chain (add-ui-kit → la-forja/el-golpe)

## Template 2 — Proyecto en build mid-flight

Indicators: feature en `state: active`, working tree dirty, brand DNA presente, varios commits recientes.

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
f11be4e feat(primer): prompts/{load-context,format-output,handoff-targets}.md
889b554 feat(primer): SKILL.md routing + output shape + graceful degradation
6061367 chore(state): activate F3-S7 (primer)
9e2d506 chore(state): mark promote-l-004 passing
ce2a992 docs(decision-trees): cross-cite L-004
```
**Working tree:** 1 modified

## Brand snapshot
**Archetype:** Creator + Sage (Mark+Pearson)
**Posture:** density=4 · expression=2 · geometry=2 · warmth=2 · editoriality=4 · materiality=2
**Visual reference:** Linear/Vercel/Forge family (Tech Utility preset)

## Próxima acción sugerida
- Continuá F3-S7 — falta `references/output-templates.md` (estás acá), `references/examples.md`, `tests/dry-run.sh`
- Después: chore(state) mark passing + merge --ff-only main

---
*Context loaded in 12s. 7 files read. 0 gaps.*
```

**Características:**
- Active feature con behavior + verification command + branch
- 5 commits recientes con context
- Brand snapshot completo (archetype + posture + visual reference)
- Próxima acción detallada (qué archivos faltan)

## Template 3 — Proyecto cerca de deploy

Indicators: features `passing`, working tree clean, branch `main`, último commit es `chore(state): mark X passing`.

```markdown
# customer-portal-mvp

**Forja state:** Phase 5 (pre-deploy) · 2026-05-10 · branch `main`

## Active feature
**(none active)** — última `passing` fue F5-S3 (security audit pre-prod) con commit a1b2c3d.

## Última actividad
```
a1b2c3d chore(state): mark F5-S3 passing — el-guardian PASS
def4567 fix(F5-S3): resolve high-severity finding (RLS gap)
abc1234 feat(F5-S3): el-guardian audit run + findings
9876fed Merge feature/add-mobile — F3-S6 PASSING
ffeebb1 chore(state): mark F3-S6 passing
```
**Working tree:** clean

## Brand snapshot
**Archetype:** Caregiver + Sage
**Posture:** density=3 · expression=3 · geometry=3 · warmth=4 · editoriality=2 · materiality=3
**Visual reference:** Warm & Soft (preset)

## Próxima acción sugerida
- Pre-deploy completo? Invocá `/web-quality` Lighthouse audit (Performance + A11y + SEO + Best Practices ≥90)
- Si PASS: deploy via `/vercel-deployer` o equivalente (env vars + dominios + DNS verify)
- Si necesitás re-auditar security tras última fix: re-run `/el-guardian`

---
*Context loaded in 11s. 6 files read. 0 gaps.*
```

**Características:**
- "(none active)" pero con context de qué fue el último passing
- 5 commits que reflejan flow pre-deploy
- Próxima acción es chain de pre-deploy (web-quality → deploy)

## Anti-patterns (output que primer NO debe producir)

### Anti-pattern 1 — Genérico

```markdown
# Project

Some project that uses Forja.

## Status
Some features done, some pending.

## Next steps
Continue working on the project.
```

**Problema:** zero specifics. Inútil. primer NO debe producir esto.

### Anti-pattern 2 — Inventado

```markdown
## Active feature
F999-S1: Add advanced AI integration with custom model fine-tuning.
```

**Problema:** primer no debería inventar features. Si feature_list.json no tiene F999-S1, primer NO lo menciona.

### Anti-pattern 3 — Demasiado largo

primer NO debería producir 1000-word essays. Bound max 300 palabras.

```markdown
# Project Name

This is a comprehensive overview of the project status. The project was initialized on 2026-05-01 by Carlos Domínguez. It uses Next.js 16 with the App Router architecture, which is a modern approach to React server components...

[20 paragraphs of fluff]
```

**Problema:** primer es resumen, no documentación. Comprimir.

### Anti-pattern 4 — Sin acción

```markdown
## Próxima acción sugerida
Trabajá en lo que tengas pendiente.
```

**Problema:** zero accionable. primer SIEMPRE produce próxima acción específica, o reporta honestamente "Sin pendiente claro — revisar backlog".

## Cita de schema

Brand snapshot deriva del schema R-005 v1.1.0:
- `archetype.primary` + `archetype.secondary` (Mark+Pearson 12 archetypes)
- `posture.{density,expression,geometry,warmth,editoriality,materiality}` (escala 1-5)
- `tokens.colors.primary` (informativo, NO render)

Ver [memory:references#R-005] para schema completo.

## Citations

- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R1] (WIP=1)
- [memory:CONSTRAINTS.md#R3] (active feature resolution)
