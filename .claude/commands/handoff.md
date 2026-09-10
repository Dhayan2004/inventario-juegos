---
description: "Escribe el handoff de sesión (.forja/HANDOFF.md) consciente de la fase SDD, antes de compactar o cerrar (F-P5.1/F-P5.2)."
---

# /handoff

Patrón de **conciencia de contexto** (docs/06 §12.2 · D-034). Tres piezas, este comando es la manual:

1. **Hook `PreCompact`** (automático, ya configurado en `.claude/settings.json`): antes de cada
   compactación corre `node scripts/handoff.mjs --source=precompact` y persiste el estado.
2. **Statusline** (visibilidad): `scripts/statusline.mjs` muestra rama · active feature · fase · plan.
3. **`/handoff`** (este comando): handoff manual **enriquecido**, consciente de la fase SDD.

## Pasos

1. Corre `node scripts/handoff.mjs --source=manual` → regenera `.forja/HANDOFF.md` con el estado
   mecánico (git, active feature, artefactos SDD, plano R17).
2. **Enriquece la sección `## Notas del agente`** del archivo con lo que el script NO puede saber:
   - Qué se estaba haciendo exactamente (a mitad de qué paso).
   - Decisiones en vuelo aún no commiteadas (y su porqué).
   - Bloqueos o esperas (CI corriendo, pregunta pendiente al humano).
   - **Siguiente acción EXACTA, consciente de la fase SDD** (F-P5.2): si estás en Fase −1 →
     ranura de `ONTOLOGY.md` que sigue; Fase 0 → sección del SPEC + "Siguiente acción" de
     `.specfounder/session.md`; planeación → fase del Blueprint; build → paso del feature activo
     + su `verification`; verificación → capa R7 pendiente.
3. Si hay eventos del plano sin sellar o `.plan/.inconsistent`, decláralo (R17 manda reconciliar
   antes de seguir).

## Límites

- **Viabilidad conocida (docs/07):** ningún hook lee el % de contexto — no existe trigger fiable
  a 50%; el hook dispara al compactar (~95%). El handoff manual ANTES de operaciones largas es
  la disciplina recomendada.
- `HANDOFF.md` es **contexto, no estado**: la fuente de verdad del build sigue siendo
  `feature_list.json` + hooks (R1/AP8). No es writer de memory (R5 intacto).
- En sesión nueva, `/avivar` (primer) lo lee primero si existe.
