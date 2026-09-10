---
description: "Valida una feature contra el resultado REAL de CI (gh check-runs → boolean anti-spoof); cierra AP5/AP8 (verificar-ci)."
---

# /verificar-ci

Lee y ejecuta `.claude/skills/verificar-ci/SKILL.md`.

`verificar-ci` mueve el árbitro del `verification_command` de la máquina del agente a un **runner remoto
independiente** (GitHub Actions): ejecuta `gh pr checks` / `gh run view` / `gh api check-runs` y devuelve
un **boolean verificable**. Una feature **NO** pasa a `passing` mientras el check-run del commit HEAD no
sea `conclusion == "success"` — y ese `conclusion` lo emite GitHub, el agente no puede fabricarlo.

**Produce:** el objeto `ci_run` ({run_id, sha, conclusion, url}) como evidencia citable `[ci:run#<id>]`,
que `el-evaluador` registra en `feature_list.json` al marcar `passing`.

**Regla que materializa:** `[memory:CONSTRAINTS.md#AP8]` — doble condición para `active → passing`:
(i) `verification_command` local exit 0 (R7) **y** (ii) `ci_run.conclusion == "success"`. Enforced
fail-closed por el `pre-commit`.

**Degradación:** sin `gh`/remote/CI configurado, cae a verificación local (R7) y advierte que AP8 no se
puede enforzar sin CI.
