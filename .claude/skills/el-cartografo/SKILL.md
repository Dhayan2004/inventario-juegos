---
name: el-cartografo
description: >
  Genera y mantiene el PLANO DE CONTROL (`.plan/`) — la capa de gestión del
  proyecto (fases → subfases → user stories, fechas, módulos, bloqueadores,
  anotaciones) versionada en git y bidireccional (humano por UI `plan.html` vía
  `plan-server.mjs`, agente por filesystem). LEE `feature_list.json` por
  `featureRefs[]`, NO lo reemplaza (la gestión orbita el build verificado). Lo
  crea al cerrar la planeación (handoff de `/plan`/la-herreria) desde el Blueprint
  + SPEC + ONTOLOGY, y lo mantiene vivo durante el build. Regido por
  `references/PLAN_SCHEMA.md`. Sincronización auditable por hooks (post-commit
  sella eventos con el commit; pre-commit fail-closed R17).
tier: core
requires: Node (ya en el stack) + un Blueprint o feature_list.json del proyecto
fallback: si no hay Blueprint, genera un `.plan/` mínimo (project + 1 fase) y pide al humano completarlo por UI
dependencies: []
---

# el-cartografo

> *"El que no mapea el territorio, lo pierde."*
> — Plano de control (A1)

Skill de **gestión de proyecto**. Materializa el plano de control de Forge Enterprise: el "administrador
del proyecto" que el humano ve y el agente mantiene, con una sola fuente de verdad en `.plan/` (git),
**bidireccional** y **auditable por commit**. Es la cara operativa del pilar ② (gestión/equipos).

Contrato del artefacto: [`../../references/PLAN_SCHEMA.md`](../../references/PLAN_SCHEMA.md). Regla:
`[memory:CONSTRAINTS.md#R17]` (R-plan).

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Node disponible? `node --version`. Si no → halt: "el plano necesita Node (server-lite zero-dep)."
3. ¿Ya existe .plan/plan.json? Si sí → modo MANTENER (no regenerar desde cero; resume-aware).
   Si no → modo GENERAR (crear el plano desde el Blueprint/feature_list).
```

## Activación

| Cuándo | Modo |
|--------|------|
| Al cerrar `/plan` (la-herreria entrega el Blueprint) | GENERAR el `.plan/` |
| Carlos pide "creá el plano", "dashboard del proyecto", "mapeá el proyecto" | GENERAR |
| Durante el build, al cambiar estado de una story / dejar nota / capturar Playwright | MANTENER (evento) |
| Carlos pide "abrí el dashboard", "quiero ver el avance" | SERVIR (`make plan`) |

## Modo GENERAR — crear `.plan/` desde el Blueprint

1. **Leer las fuentes** (las que existan, degradación segura): `BLUEPRINT-<nombre>.md` (fases),
   `SPEC.md` (user stories, Fase 0), `ONTOLOGY.md` (empresa/`tenant_model`, Fase −1), `feature_list.json`
   (features de build a referenciar).
2. **Materializar `plan.json` (schema 2.0)** copiando [`templates/plan.json`](templates/plan.json) y
   poblando: `_meta` (traza a `source_spec`/`source_ontology`), `project` (name/client/slug/`tenantId`
   desde la ontología si existe), `phases → subphases → stories`. Cada **story** mapea a sus features de
   build con `featureRefs: ["<id de feature_list>"]` (el puente, PLAN_SCHEMA §4).
3. **Seedear** `activity.log.jsonl` (vacío) y `annotations/media/`.
4. **Sembrar `decisions[]`** (schema 2.1) desde lo que exista: `docs/adr/*.md` (uno por ADR, `adrRef`
   apuntando al archivo) + `.claude/memory/decisions.md` (D-NNN → resumen de 1 línea, misma numeración).
   Las decisiones tomadas NO se pierden al avanzar el proyecto: viven en el dashboard junto a los
   bloqueadores. Sin ADRs ni decisions.md → `decisions: []` (degradación segura).
5. **No inventar:** una story sin feature correspondiente queda con `featureRefs: []`; el status de
   gestión se deriva del build cuando hay refs (todas `passing` → `done`).
6. **Confirmar** el árbol con el humano antes de cerrar.

> `currentStage` arranca en la primera story pendiente; el humano la mueve por UI, o se deriva de la
> feature `active` de `feature_list.json` (ver PLAN_SCHEMA §2).

## Modo MANTENER — escribir eventos (R-plan / R17)

Durante el build, **todo cambio de estado o evidencia se registra como evento** (PLAN_SCHEMA §3):

- **Server arriba (preferido):** `curl -s -XPOST localhost:4317/api/event -d '{...}'` — pasa por la cola
  single-process del server (sin carrera con el humano).
- **Server caído (fallback):** tomar el lock (`.plan/.lock`), append directo a `activity.log.jsonl` +
  (si es `status_change`/`stage_change`) editar `plan.json`, liberar el lock.

Tipos de evento: `note·link·file·status_change·stage_change·playwright·test_result·annotation·blocker_open·blocker_resolve·decision_add·decision_supersede`.

**Decisiones y bloqueantes son de registro OBLIGATORIO** (feedback dogfooding 2026-08-18): cada vez que
en la sesión se toma una decisión de arquitectura/alcance/producto → evento `decision_add` (id `D-{nnn}`
siguiente libre, título + rationale de 1-2 líneas); si reemplaza a una anterior → además
`decision_supersede` sobre la vieja. Cada vez que algo bloquea el avance → `blocker_open` con `owner`.
Una decisión que solo quedó en la conversación es una decisión que se va a perder.

Antes del Clean-State Exit (R12), verificar que `plan.json` refleja el estado real y que no quedan
eventos `commit:null` sin sellar (el `post-commit` los sella en el siguiente commit).

## Modo SERVIR — abrir el dashboard

```
make plan            # arranca plan-server.mjs en http://localhost:4317 y sirve plan.html
make plan-validate   # valida plan.json + cada línea del log (lo mismo que el pre-commit R17)
```

El humano edita **gestión** por la UI (status, etapa, notas); el agente edita por eventos. **Nunca**
LocalStorage — la UI escribe siempre a disco vía el server (sin esto, dos verdades, el bug del kanban).

## La frontera con `feature_list.json` (no la cruces)

- El plano **LEE** `feature_list.json` y lo refleja **read-only** dentro de cada story (vía
  `featureRefs[]`). **NUNCA lo escribe** — las transiciones de build las gobiernan los hooks (R1, ADR D1).
- El humano edita gestión (fechas, notas, etapa); el harness edita build. Dos archivos, una jerarquía.

## Refusals (lo que NUNCA hace)

- ❌ Escribir `feature_list.json` (rompería el pilar ④ / ADR D1 / R1).
- ❌ Reintroducir LocalStorage como caché de estado (vuelve a crear dos verdades).
- ❌ Meter anotaciones en `plan.json` (van al log append-only; si no, read-modify-write conflictivo).
- ❌ Marcar una story `done` sin que sus `featureRefs` estén `passing` (la gestión refleja el build, no lo inventa).
- ❌ Commitear el plano roto (lo gatea el `pre-commit` R17 fail-closed).

## Tool filter

Read · Grep · Glob · Bash (node `plan-server.mjs`, `curl` local, git) · Write (`.plan/**` solamente).
NO Edit ni Write en `feature_list.json` ni `src/**`.

## Integraciones

- **`la-herreria` (`/plan`):** al cerrar el Blueprint, hace handoff a `el-cartografo` para nacer el plano.
- **`feature_list.json`:** fuente read-only del status de build (puente `featureRefs[]`).
- **hooks `post-commit`/`pre-commit`:** sincronización auditable (sella eventos · fail-closed R17).
- **`el-evaluador`:** al marcar una feature `passing`, el plano lo refleja en la story (derivado).
- **`/verificar-ci` (A2):** el `ci_run` de una feature es evidencia que el plano puede mostrar por story.

---

*"`plan.json` es el snapshot; el log es la verdad histórica. Mapeá una vez, mantené siempre."*
