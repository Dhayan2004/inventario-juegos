---
description: "Genera/mantiene el plano de control (.plan/) del proyecto — dashboard bidireccional versionado en git (el-cartografo)."
---

# /cartografo

Lee y ejecuta `.claude/skills/el-cartografo/SKILL.md`.

`el-cartografo` materializa el **plano de control** (`.plan/`): la capa de gestión del proyecto
(fases → subfases → user stories, fechas, módulos, bloqueadores, anotaciones) versionada en git y
**bidireccional** — el humano edita por la UI (`plan.html` vía `plan-server.mjs`), el agente por
filesystem (eventos). **LEE `feature_list.json` por `featureRefs[]`, NO lo reemplaza** (la gestión
orbita el build verificado). Regido por `.claude/references/PLAN_SCHEMA.md`.

**Modos:** GENERAR (al cerrar `/plan`, nace desde el Blueprint + SPEC + ONTOLOGY) · MANTENER (eventos
durante el build, R-plan/R17) · SERVIR (`make plan` → http://localhost:4317).

**Sincronización auditable:** el hook `post-commit` sella cada evento con el commit; el `pre-commit` es
fail-closed (R17) si el plano queda roto.

**Output esperado:** `.plan/plan.json` (estado estructurado) + `.plan/activity.log.jsonl` (bitácora
append-only) + `.plan/annotations/`.
