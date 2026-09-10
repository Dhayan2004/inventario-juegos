---
description: "Fase 0 — descubre el spec por entrevista grill-me antes de /plan (el-entrevistador)."
---

# /descubrir

Lee y ejecuta `.claude/skills/el-entrevistador/SKILL.md`.

`el-entrevistador` levanta el **spec funcional del dominio del cliente** por entrevista grill-me
(1 pregunta por turno + recomendación) antes de `/plan`. Produce `SPEC.md` (6 secciones),
`CONTEXT.md` (glosario del cliente) y ADRs, con memoria persistente en `.specfounder/` que
permite retomar tras una caída sin re-preguntar.

**Resume-aware:** si existe `.specfounder/session.md`, retoma exactamente en la "Siguiente acción".

**Output esperado:** `SPEC.md` + `CONTEXT.md` + `docs/adr/`, entregados a `/plan` (la-herreria)
vía el adaptador "forge".

**Siguiente paso sugerido al cerrar:** `/plan` (la-herreria consume el SPEC desambiguado).
