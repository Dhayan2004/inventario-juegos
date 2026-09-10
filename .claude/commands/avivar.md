---
description: "Carga contexto de proyecto Forja en <30s al iniciar sesión (primer)."
---

# /avivar

Lee y ejecuta `.claude/skills/primer/SKILL.md`.

Lee secuencia óptima de archivos canónicos (`AGENTS.md` → `feature_list.json` → `PROGRESS.md` → `brand/brand.json` → `.claude/memory/decisions.md` → `git log/status` → `README`) y retorna resumen estructurado de 5 elementos:

1. Proyecto + estado actual
2. Active feature (R3 resolution)
3. Última actividad reciente
4. Brand snapshot
5. Próxima acción sugerida

**Output:** ~150–300 palabras. NO genera código. Para retake post-pause largo, cross-session continuity, onboarding humano.
