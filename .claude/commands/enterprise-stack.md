---
description: "Wizard de wizards: init-saas → add-monetization → add-mobile-stack. Setup enterprise completo en un comando."
---

# /enterprise-stack

Lee y ejecuta `.claude/skills/enterprise-stack/SKILL.md`.

Wizard de wizards (D-022 binary FULL/CUSTOM). Compone los 3 wizards core en una sola invocación:

1. **init-saas** — Brand DNA + components base + auth (D-019)
2. **add-monetization** — Pagos + emails + audit web-quality (D-020)
3. **add-mobile-stack** — PWA + Web Push (D-021)

Resume-aware con detección de outputs de cada wizard hijo.

**Pre-requisito:** Next.js project con `AGENTS.md`. **R6 mandatory** — los 3 wizards hijos deben existir en `.claude/memory/skills.md`. PREFLIGHT halt si falta alguno.

**Modos:** `FULL` (default — los 3 wizards en orden) / `CUSTOM` (override — skip wizards específicos: "sin mobile", "sin pagos").

Hereda doctrine completa: D-019 + D-020 (PAUSE-interno-delegado distinction propagada cross-wizards) + D-021.

Output enterprise completo en ~3-4h primera vez.
