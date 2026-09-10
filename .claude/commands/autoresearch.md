---
description: "Loop self-improving OPT-IN sobre un SKILL.md target — una variable/commit, rama dedicada, juez independiente y caps duros (autoresearch)."
---

# /autoresearch

Lee y ejecuta `.claude/skills/autoresearch/SKILL.md`.

`autoresearch` es el meta-skill de **auto-mejora del harness**: itera la CALIDAD de un skill ya existente
con un loop estilo Karpathy — *analizar fallo → una hipótesis → un solo cambio en el CUERPO del SKILL.md
→ commit para aislar la variable → N outputs → evaluar con criterios BINARIOS → keep (commit) / discard
(`git reset --hard HEAD~1`)*. Es la materialización de la mitigación de `[memory:decisions#D-024]`
(autoresearch se re-admite **sólo** como skill opt-in con AP3 explícito).

**Recordá antes de correrlo (safety caps NO negociables):**
- **Opt-in puro** — nunca se auto-invoca; sólo por tu pedido explícito sobre un `<skill>` concreto.
- **Rama dedicada, NUNCA `main`** (`git switch -c autoresearch/<target>` primero).
- **Caps duros:** ≤ 30 iteraciones · budget $5 · crecimiento del prompt ≤ 2× (anti-bloat) · **backup obligatorio**.
- **Juez independiente** = `el-evaluador` (AP3 — el generador no se auto-evalúa).
- **NO toca `.claude/memory/**`** (R5) · **NO muta el frontmatter** (lo parsea inventory.js) · **NO `--no-verify`** (AP2).

**Uso:** `/autoresearch <skill-target>` (ej: `/autoresearch la-herreria`). El skill hace PREFLIGHT
halt-blocked en las 8 condiciones (working tree limpio, rama dedicada, target en el registry, backup, juez
disponible, budget confirmado, criterios binarios definibles) antes de mutar nada.

**Output esperado:** el SKILL.md target en su best-known + `<target>/autoresearch-results.tsv` (bitácora del
experimento) + `<target>/SKILL.md.backup`. Cualquier lección emergente se **propone** a `el-evaluador`, no se escribe.
