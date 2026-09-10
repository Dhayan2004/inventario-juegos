---
description: "Fase −1 — levanta la ontología de la EMPRESA (su 'ser') antes de /descubrir (el-ontologo)."
---

# /ontologia

Lee y ejecuta `.claude/skills/el-ontologo/SKILL.md`.

`el-ontologo` levanta el **"ser" de la empresa** por entrevista grill-me (1 pregunta por turno +
recomendación) con dos lentes: **NEGOCIO** (método Founder OS — segmento, JTBD, problema priorizado con
evidencia, propuesta de valor, modelo operativo) y **MARCA** (método Estudio — arquetipo, código
simbólico, lenguaje propio). Produce `ONTOLOGY.md` regido por `ONTOLOGY_SCHEMA.md`, que extiende el
Brand DNA y se inyecta en cada generación downstream igual que `brand.json`. Reusa el motor de
`el-entrevistador` con el perfil de dominio `ontologia`.

**Resume-aware:** si existe `.ontologia/session.md`, retoma exactamente en la "Siguiente acción".

**Output esperado:** `ONTOLOGY.md` (frontmatter machine-readable + cuerpo narrativo) + `ontology/evidence/`.

**Siguiente paso sugerido al cerrar:** `/descubrir` (el CONTEXT.md del producto deriva del glosario de
empresa) o `/plan` (la-herreria orbita la ontología). `/add-ui-kit` hereda `marca.*` como Brand DNA.
