# Plan Schema — el plano de control (`.plan/`) de Forge Enterprise (A1)

> **Qué es esto.** El contrato del **plano de control**: la capa de *gestión* del proyecto (fases →
> subfases → user stories, fechas, módulos, bloqueadores, anotaciones) que vive en `.plan/`, versionada
> en git, **bidireccional** (el humano escribe por UI, el agente por filesystem). Es la cara operativa
> del pilar ② (gestión/equipos). **LEE `feature_list.json`, NO lo reemplaza** (gestión orbita el build).
>
> Extiende el schema del skill `project-kanban-dashboard` (de Carlos) con lo que el plano enterprise
> pide: subfases, user stories, módulos por área, fechas previstas, etapa actual, diagramas, y el puente
> `featureRefs[]` a la state machine de build. **Fuente de diseño:** `docs/07` Punto 3 (§1–§10).

- **Versión:** v0.2.0 (2026-08-18 — `decisions[]` + eventos de decisión; v0.1.0: 2026-06-30, A1)
- **Lo produce/mantiene:** el skill `el-cartografo` (`/cartografo`) + el agente durante el build + el humano por UI (`plan.html` vía `plan-server.mjs`).
- **Regla de enforcement:** `[memory:CONSTRAINTS.md#R17]` (R-plan: el plano es parte del commit atómico).

---

## 1. Los dos archivos (separación mutable vs acumulativo)

```
.plan/
├── plan.json              ← ESTADO ESTRUCTURADO (mutable, "verdad actual" única) — snapshot materializado
├── activity.log.jsonl     ← BITÁCORA (append-only, inmutable) — la autoridad de reconstrucción
├── annotations/media/     ← capturas de Playwright, .mmd de Mermaid, imágenes (referenciadas por el log)
├── plan-snapshot.html     ← (opcional) cristal read-only fechado por commit (auditoría en git)
└── .lock                  ← lockfile efímero del read-modify-write de plan.json (NO se commitea)
```

**La regla maestra (`docs/07` §4.1):** lo que tiene una sola *verdad actual* (status, fechas,
`currentStage`) vive en `plan.json` (**last-write-wins por campo, con lock**); lo que es *acumulativo e
inmutable* (una nota, un link, una captura, un resultado de test) va al `activity.log.jsonl`
(**append-only, nunca last-write-wins**). Esto vuelve trivial la concurrencia humano↔agente: dos
appends nunca se pisan (`O_APPEND` atómico por línea), y `plan.json` se puede **reconstruir** reproduciendo
el log (event-sourcing ligero). **Las anotaciones NUNCA viven en `plan.json`** — si las metes ahí,
conviertes cada nota en un read-modify-write que compite por el lock.

---

## 2. `plan.json` — esquema 2.0 (estado estructurado)

```jsonc
{
  "_meta": {
    "schema_version": "2.0.0",          // versionado del schema (migraciones por número)
    "generated_by": "el-cartografo",    // quién lo creó al cerrar la planeación
    "source_spec": "SPEC.md",           // traza al spec (Fase 0 SDD) que lo originó
    "source_ontology": "ONTOLOGY.md"    // traza a la ontología (Fase −1) — diferenciador
  },
  "project": {                          // cabecera (extiende el `project` del kanban)
    "name": "Cliente — Proyecto",       // string · REQUERIDO (el texto tras " — " se acentúa)
    "client": "Cliente S.A.",
    "slug": "cliente",
    "kickoff": "2026-07-01",            // YYYY-MM-DD
    "currentStage": { "phaseId": "F2", "subphaseId": "F2-S1", "storyId": "F2-S1-US03" },  // ← ETAPA ACTUAL
    "tenantId": "cliente",              // ← multi-tenant (M6): namespacea el plano por cliente
    "lastUpdate": "2026-06-30"
  },
  "tools": { /* registro herramienta → {color, icon}, igual que el kanban */ },
  "statusLabels": { /* FIJO: done|in_progress|pending|blocked — NO modificar (igual que el kanban) */ },

  "modules": [                          // ← NUEVO · módulos por ÁREA (cruzan fases)
    { "id": "MOD-AUTH", "area": "backend",  "name": "Auth & multi-tenant", "phases": ["F1","F2"] }
  ],

  "phases": [                           // árbol fases → subfases → stories
    {
      "id": "F2", "number": 2, "name": "Pre-aprobación", "color": "#10b981",
      "plannedStart": "2026-07-15", "plannedEnd": "2026-08-05",   // ← FECHAS PREVISTAS
      "deliverables": ["Motor de scoring"],
      "subphases": [                                              // ← NIVEL NUEVO
        {
          "id": "F2-S1", "name": "Motor de scoring",
          "plannedStart": "2026-07-15", "plannedEnd": "2026-07-25",
          "stories": [                                           // ← USER STORIES
            {
              "id": "F2-S1-US03",
              "as": "analista de crédito", "want": "ver el resultado data-driven", "soThat": "no recalculo a mano",
              "status": "in_progress",                           // done|in_progress|pending|blocked
              "modules": ["MOD-DATA"],                           // qué módulos toca
              "featureRefs": ["M2-F3"],                          // ← PUENTE a feature_list.json (§4)
              "acceptance": ["4 resultados", "disclaimer visible"],
              "plannedStart": "2026-07-18", "plannedEnd": "2026-07-22",
              "blocker": null                                    // id de blockers[] o null
            }
          ]
        }
      ]
    }
  ],

  "blockers": [ /* id, title, owner, since, severity, description, affects[], resolvedAt — igual que el kanban */ ],

  "decisions": [                        // ← NUEVO (v2.1) · las decisiones tomadas NO se pierden
    { "id": "D-001",                    // D-{nnn} estable — mismo namespace que decisions.md si existe
      "title": "Postgres como fuente de verdad",
      "date": "2026-07-01",
      "status": "vigente",              // vigente | superseded
      "supersededBy": null,             // id de la decisión que la reemplaza (o null)
      "rationale": "El Sheets pasa a destino de render; el agente no compite con humanos por celdas",
      "affects": ["MOD-DATA", "F2"],    // módulos/fases/stories que toca (IDs del plano)
      "adrRef": "docs/adr/0003-postgres.md",  // traza al ADR versionado (o null)
      "commit": null                    // commit que la implementó (lo sella post-commit vía evento)
    }
  ],

  "diagrams": [                         // ← NUEVO · diagramas como código (versionable)
    { "id": "DG-01", "title": "Flujo pre-aprobación", "type": "mermaid",
      "phaseId": "F2", "src": ".plan/annotations/media/flow-preaprobacion.mmd" }
  ]
}
```

### Reglas
- **`statusLabels`** es FIJO (4 estados: `done|in_progress|pending|blocked`). Igual que el kanban.
- **`currentStage`** es la etapa actual (breadcrumb F2 › S1 › US03 + badge "Estás aquí"). La fija el humano
  por UI; opcionalmente se **deriva** de la feature `active` de `feature_list.json` (ver §4).
- **IDs jerárquicos:** fase `F{n}`, subfase `{phaseId}-S{n}`, story `{subphaseId}-US{nn}`, módulo `MOD-{XX}`,
  bloqueador `BLK-{nnn}`, diagrama `DG-{nn}`, decisión `D-{nnn}`. IDs estables = bloqueadores/featureRefs que no se rompen.
- **`decisions[]` (v2.1):** una decisión NUNCA se borra — se marca `superseded` (+ `supersededBy`). El
  dashboard las pinta junto a los bloqueadores para que ni decisiones ni bloqueantes se pierdan al avanzar
  el proyecto (feedback dogfooding 2026-08-18 punto 3). Si el proyecto lleva `.claude/memory/decisions.md`
  (R5), ESE sigue siendo el registro narrativo canónico del build; `plan.decisions[]` es la **vista de
  gestión** (misma numeración D-NNN, resumen de 1 línea + traza `adrRef`). `el-cartografo` las siembra
  desde `docs/adr/` + `decisions.md` al generar el plano, y el agente registra `decision_add` al tomar
  una nueva durante el build.
- **Validación mínima** (la que corren los hooks): JSON parsea + `_meta.schema_version` conocido +
  `project` presente + `phases` es array. Todo lo demás degrada con guardas.

---

## 3. `activity.log.jsonl` — bitácora bidireccional (append-only, un evento JSON por línea)

```jsonl
{"ts":"2026-06-30T14:02:11Z","actor":"human","type":"note","target":"F2-S1-US03","body":"El cliente quiere el disclaimer más visible","commit":null}
{"ts":"2026-06-30T15:20:03Z","actor":"agent","type":"status_change","target":"F2-S1-US03","from":"pending","to":"in_progress","commit":null}
{"ts":"2026-06-30T15:48:12Z","actor":"agent","type":"playwright","target":"F2-S1-US03","label":"resultado A renderiza ok","media":".plan/annotations/media/F2-S1-US03-shot-01.png","commit":null}
{"ts":"2026-06-30T15:48:30Z","actor":"agent","type":"test_result","target":"F2-S1-US03","verification":"make test","result":"pass","commit":null}
```

- **Tipos (vocabulario cerrado):** `note` · `link` · `file` · `status_change` · `stage_change` ·
  `playwright` · `test_result` · `annotation` · `blocker_open` · `blocker_resolve` · `decision_add` ·
  `decision_supersede` (v2.1 — `decision_add` lleva `decision:{id,title,rationale,…}`;
  `decision_supersede` lleva `target` = id viejo + `by` = id nuevo o null).
- **`actor`** — `agent` | `<member.name>` del roster `.forja/team.json` (`carlos`, `joaco`…) cuando hay
  equipo (S2); `human` se mantiene como alias genérico válido (degradación: proyecto sin roster). La vista
  de actividad de `plan.html` filtra por actor → con roster, filtra por persona. Roster + actores: el-capataz
  (`.claude/skills/el-capataz/references/github-native.md` §6).
- **`target`** = id de story/subfase/fase/blocker, o `"project"` (para `stage_change`).
- **`commit`** = `null` mientras el evento está sin commitear; el hook `post-commit` lo **sella** con el
  hash del commit recién creado → cada nota/captura/cambio queda atada a un commit (trazabilidad por grep).
- **Eventos que mutan `plan.json`** (`status_change`, `stage_change`, `blocker_open`, `blocker_resolve`,
  `decision_add`, `decision_supersede`): el `plan-server.mjs` aplica el cambio al snapshot **además** de
  loggear el evento. Los demás (`note`/`link`/`file`/`playwright`/`test_result`/`annotation`) solo se
  loggean (no tocan `plan.json`).

---

## 4. El puente a `feature_list.json` — el plano LO LEE, no lo reemplaza (`docs/07` §6)

Cada **story** lleva `featureRefs: ["M2-F3"]` que apunta a IDs de `feature_list.json`. Fronteras:

| | `feature_list.json` (build, pilar ④) | `.plan/plan.json` (gestión, pilar ②) |
|---|---|---|
| Modela | state machine atómica (`{behavior, verification, state}`) | fases→subfases→stories, fechas, módulos, blockers, anotaciones |
| Gobierna | **hooks** (R1 WIP=1, transiciones por hook — ADR D1) | humano (UI) + agente (FS), last-write-wins + append-log |
| Granularidad | fina, verificable (1 feature = 1 unidad de build) | gruesa, de negocio (1 story = lo prometido al cliente) |

- El plano **deriva** el status de gestión de una story desde sus `featureRefs`: si todas están
  `passing` → la story se refleja `done`. **La verdad del build sigue en `feature_list.json`**
  (gobernada por hooks, intocable por la UI); el plano solo lo **refleja read-only**.
- El humano NO edita features desde el plano (violaría R1/transiciones-por-hook). Edita **gestión**
  (fechas, notas, etapa); el harness edita **build**. Dos archivos, una jerarquía, fronteras claras.

> **Por qué NO absorber `feature_list.json`:** romperia el pilar ④ (state machine gobernada por hooks,
> ADR D1) y reintroduciría "transiciones por UI" que D1 prohíbe. La tentación de "un solo JSON para
> todo" es el error.

---

## 5. Sincronización (hooks) y disciplina del agente (R-plan)

- **`post-commit`** (no puede abortar — ya ocurrió): sella los eventos `commit:null` con el hash, valida
  ambos JSON, y deja rastro si hay inconsistencia. Re-render del snapshot = diferido (Clean-State Exit).
- **`pre-commit`** (fail-closed): si `.plan/plan.json` no parsea o quedó marcado inconsistente → **aborta**
  el commit. Degradación segura: **si no existe `.plan/`, el guard se salta** (proyectos sin plano).
- **`R-plan` ([memory:CONSTRAINTS.md#R17]):** toda sesión de build mantiene `.plan/` vivo — al cambiar el
  estado de una story, registrar capturas o resultados, el agente **escribe un evento** (`POST /api/event`
  si el server corre, o append directo al log + edición de `plan.json` con lock si no). Antes del
  Clean-State Exit (R12), verifica que `plan.json` refleja el estado real y no hay eventos sin sellar.

---

## 6. Concurrencia (el punto técnico delicado, `docs/07` §4)

- **Estado estructurado** (`plan.json`) → last-write-wins por campo, **serializado por la cola
  single-process del `plan-server.mjs`** (un solo proceso Node = los `POST` se aplican uno a uno). El
  lockfile `.plan/.lock` (`fs.open` flag `wx`) sólo hace falta cuando el **agente edita por FS con el
  server caído**; el server respeta ese lock.
- **Bitácora** (`activity.log.jsonl`) → append-only (`O_APPEND` atómico por línea) → dos actores
  escribiendo notas simultáneas **no se pisan**. Elimina el 90% de los conflictos.
- **No es CRDT/OT** (eso es para edición colaborativa de texto en tiempo real, que NO es el caso).
  Append-only + cola single-process + last-write-wins por campo es el nivel correcto de complejidad.

---

## 7. Alcance A1 (MUST construido) vs diferido

- ✅ **MUST (P1–P5 + P8):** `plan-server.mjs` (server-lite, corta LocalStorage) · `activity.log.jsonl` ·
  `plan.json` schema 2.0 · `featureRefs[]` · hooks `post-commit`/`pre-commit` + `R-plan` · skill
  `el-cartografo`.
- 🔜 **SHOULD/COULD (diferido, documentado):** vista calendario/Gantt (P6) · panel de anotaciones con
  media (P7) · `plan-snapshot.html` por commit (P9) · file-watcher+SSE auto-reload (P10) · render Mermaid
  (P11) · `make plan-rebuild` event-sourcing (P13). El sync `plan.json → GitHub Issues/PR` (P12)
  **ya fue entregado por S2** — `el-capataz` proyección una-vía idempotente (R18).
- 🚫 **WON'T:** backend real como SoT (mata la auditabilidad-por-git → Forge Cloud) · drag-and-drop ·
  notas de voz.

## Sources
- `docs/07` Punto 3 (plano de control) — diseño completo, §1–§10.
- Schema base: skill `project-kanban-dashboard` (`references/schema.md`).
