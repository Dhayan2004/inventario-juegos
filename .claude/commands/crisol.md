---
description: "Validación estratégica post-Blueprint: 7 análisis + dashboard + veredicto Go/Caution/No-Go (el-crisol)."
---

# /crisol

Lee y ejecuta `.claude/skills/el-crisol/SKILL.md`.

Pipeline secuencial entre `la-herreria` y `la-forja`: brújula → estrella → rivales → precio → roi → metas → lanzamiento → dashboard ejecutivo HTML + Build Confidence Score.

**Modos de invocación:** `go` (default — ejecutar todo lo pendiente), `saltar N`, `desde N`, `solo dashboard`.

**Pre-requisito:** Blueprint aprobado en `.claude/PRPs/BLUEPRINT-*.md`.

**Output:** `STRATEGY-REPORT-<nombre>.md` + `strategy-dashboard-<nombre>.html` con veredicto:
- **Go (8-10)** → handoff a `la-forja` vía `/build`.
- **Caution (5-7)** → ajustar áreas con gaps.
- **No-Go (1-4)** → replantear estrategia antes de invertir.
