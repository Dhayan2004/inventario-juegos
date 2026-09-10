# Examples — 3 escenarios reales de invocación primer

## Escenario 1 — Sesión nueva en proyecto target post-fines de semana

### Context

- Proyecto: `customer-portal` (cliente B2B SaaS)
- Última sesión: viernes 2026-05-02 (cerró F2-S5)
- Sesión nueva: lunes 2026-05-05
- Agente arranca cold sin contexto

### Invocación

```
Usuario: /primer
```

### Lecturas que primer hace (~12s)

```
Read AGENTS.md            (3s) → product=customer-portal, stack=Next.js+Supabase
Read feature_list.json (2s) → F2-S5 passing, F2-S6 active
Read PROGRESS.md    (3s) → última entry 2026-05-02 "F2-S5 cerrada"
Read brand/brand.json (2s) → Sage+Caregiver, posture 3/3/3/4/2/3
Read .claude/memory/decisions.md (1s) → 4 ADRs, último D-004
git log --oneline -5      (1s)
```

### Output

```markdown
# customer-portal

**Forja state:** Phase 2 (skills migration, F2-S6 active) · 2026-05-02 · branch `feature/F2-S6`

## Active feature
**ID:** `F2-S6` · **State:** `active`
Skill calidad authored — quality gates + verification orchestrator pre-deploy.
**Verification:** `bash .claude/skills/calidad/tests/dry-run.sh`
**Branch:** `feature/F2-S6`

## Última actividad
```
8a9b0c1 feat(F2-S6): scaffold calidad skill structure
def4567 chore(state): mark F2-S5 passing
abc1234 chore(state): activate F2-S6
9876fed chore(state): mark F2-S5 passing — el-evaluador PASS
ffeebb1 feat(F2-S5): el-evaluador prompts/format-output.md
```
**Working tree:** clean

## Brand snapshot
**Archetype:** Caregiver + Sage
**Posture:** density=3 · expression=3 · geometry=3 · warmth=4 · editoriality=2 · materiality=3
**Visual reference:** Warm & Soft (preset)

## Próxima acción sugerida
- Continuá F2-S6 calidad — scaffold hecho viernes, falta SKILL.md + prompts
- Branch `feature/F2-S6` clean — empezá con SKILL.md routing

---
*Context loaded in 12s. 6 files read. 0 gaps.*
```

### Resultado

Agente arranca productivo en <15s totales. Sabe exactamente dónde quedó (F2-S6 calidad mid-build, branch clean, scaffold hecho, falta SKILL.md). Próxima acción es accionable.

## Escenario 2 — Onboarding de developer humano nuevo

### Context

- Developer nuevo se une al equipo
- No conoce el proyecto
- Lee `README.md` brevemente, después invoca primer para entender estado actual

### Invocación

```
Developer: /primer
```

### Lecturas (~10s)

```
Read AGENTS.md            → routing del proyecto
Read feature_list.json → 12 features, 8 passing, 1 active, 3 pending
Read PROGRESS.md    → 6 sesiones documentadas
Read brand/brand.json → Creator+Sage, Tech Utility preset
git log --oneline -5
```

### Output

```markdown
# acme-billing

**Forja state:** Phase 4 (mid-build, F4-S2 active) · 2026-05-08 · branch `feature/F4-S2`

## Active feature
**ID:** `F4-S2` · **State:** `active`
Webhooks Stripe + Polar handlers — signature verification + L-002 audit + R14 destructive gates en refund.
**Verification:** `bash .claude/skills/add-payments/tests/dry-run-stripe.sh`
**Branch:** `feature/F4-S2`

## Última actividad
```
abc1234 feat(F4-S2): stripe webhook 6-phase canonical
def4567 feat(F4-S2): polar webhook ECDSA verification
9876fed test(F4-S1): subscriptions migration PASS
ffeebb1 chore(state): mark F4-S1 passing
1a2b3c4 feat(F4-S1): 0002_subscriptions.sql con RLS L-001
```
**Working tree:** 3 modified

## Brand snapshot
**Archetype:** Creator + Sage (Mark+Pearson)
**Posture:** density=4 · expression=2 · geometry=2 · warmth=2 · editoriality=4 · materiality=2
**Visual reference:** Tech Utility preset

## Próxima acción sugerida
- Continuá F4-S2 — 3 archivos modified en working tree, revisá qué falta
- Si querés ver progreso histórico: `cat PROGRESS.md`
- Si querés explorar features completas: `cat feature_list.json | jq '.features[] | select(.state==\"passing\")'`

---
*Context loaded in 10s. 5 files read. 0 gaps.*
```

### Resultado

Developer humano entiende en <2 minutos lo que normalmente tomaría 30 minutos de exploración. Brand archetype + posture le da feel del producto. Próxima acción le orienta a comandos útiles para profundizar.

## Escenario 3 — Cross-session continuity post-pause largo

### Context

- Proyecto: `internal-dashboard`
- Última sesión: 2026-04-15 (3 semanas atrás)
- Carlos retoma proyecto post-vacaciones
- PROGRESS.md está stale, feature_list.json refleja estado parcial

### Invocación

```
Carlos: dame contexto del proyecto
```

### Lecturas (~14s)

```
Read AGENTS.md
Read feature_list.json → F3-S2 active desde 2026-04-15 (3 semanas stale)
Read PROGRESS.md       → última entry 2026-04-15 "F3-S2 mid-build"
Read brand/brand.json  → Hero+Magician, Modern Minimal
Read .claude/memory/decisions.md → 6 ADRs, último D-006
git log --oneline -5         → último commit 2026-04-15
git status --short           → 5 modified, 2 untracked
```

### Output

```markdown
# internal-dashboard

**Forja state:** Phase 3 (mid-build, F3-S2 active) · ⚠ stale 23 días · branch `feature/F3-S2`

## Active feature
**ID:** `F3-S2` · **State:** `active`
Dashboard analytics page — cohort retention + DAU/MAU charts + filter by signup-source.
**Verification:** `bash scripts/test-dashboard-analytics.sh`
**Branch:** `feature/F3-S2`

## Última actividad (last commit 23 días atrás)
```
abc1234 wip: filter by signup-source (incomplete) — 2026-04-15
def4567 feat(F3-S2): cohort retention chart 30/60/90 days
9876fed feat(F3-S2): DAU/MAU bar chart con voice tooltip
ffeebb1 chore(state): activate F3-S2
1a2b3c4 chore(state): mark F3-S1 passing
```
**Working tree:** 5 modified, 2 untracked

## Brand snapshot
**Archetype:** Hero + Magician
**Posture:** density=2 · expression=4 · geometry=4 · warmth=2 · editoriality=3 · materiality=4
**Visual reference:** Modern Minimal (preset)

## Próxima acción sugerida
- ⚠ Working tree dirty desde hace 23 días — leer `git diff` para ver qué quedó incompleto
- El último commit dice "wip: filter by signup-source (incomplete)" — terminar ese flow primero
- 2 untracked files — probablemente charts components a stage, revisar antes de commit
- Tras resolver: continuar F3-S2 según PROGRESS.md last entry (línea ~120)

---
*Context loaded in 14s. 7 files read. 1 stale flag (PROGRESS.md 23 días).*
```

### Resultado

Carlos sabe en <20s que:
1. Hay 23 días de gap
2. El último commit fue "wip incomplete" — hay deuda
3. Hay 5 modified + 2 untracked en working tree
4. Próxima acción explícita (revisar diff + completar wip + stage untracked)

Sin primer, esto sería 10-15 minutos de exploración manual.

## Cita de schema

Los 3 escenarios usan Brand DNA snapshot del schema R-005 v1.1.0. Ver [memory:references#R-005].

## Citations

- [memory:references#R-005]
- [memory:CONSTRAINTS.md#R1] · [memory:CONSTRAINTS.md#R3]
