---
name: la-herreria
description: >
  Orchestrator de planificación. Convierte una idea cruda en un Blueprint
  ejecutable con Mode Selector (5 modos) y pipeline de 10 fases (Viability →
  BMC/VPC → PDR → Tech Spec → UX Research → User Stories → UX Design → UI
  Design Workflow → UI → Security Audit → Master Blueprint). La Herrería NO
  ejecuta — coordina. Cada fase carga su asset desde `assets/` o `routes/` y
  delega a un sub-agente. Punto de entrada principal: el usuario solo habla
  con La Herrería y ella decide qué ruta tomar.
tier: core
requires: PREFLIGHT pasa (AGENTS.md existe, repo accesible)
fallback: halt con mensaje "Falta /forge-init para inicializar el repo"
dependencies: [find-docs, add-ui-kit, baas, el-guardian, impeccable]
---

# La Herrería

> *"No necesitas saber qué skill usar. Solo dime qué quieres construir."*

Skill de planificación. Convierte una idea cruda en `BLUEPRINT-<nombre>.md` ejecutable. Funciona como orchestrator — coordina 10 fases de diseño, cada una con su propio asset cargable. La Herrería NUNCA escribe código de aplicación; produce documentación + plan.

## PREFLIGHT halt

Antes de cualquier otra acción, este skill DEBE verificar:

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada. Corré 'make setup'."
2. ¿Existe feature_list.json? Si no → halt: "Falta feature_list.json. Corré /forge-init."
3. Repo greenfield O Bootstrap Contract cumplido. Si ninguno → halt: "Sin Bootstrap Contract. Corré /forge-init."
```

Sin estos tres, no se ejecuta. Ver [`AGENTS.md`](../../../../AGENTS.md) sección PREFLIGHT.

## FASE 0 — Mode Selector

Si el modo no está seteado, presentar:

```
¡Hola! Antes de arrancar, dime:

¿Qué quieres construir hoy?

1. 🏗️  SaaS Completo       — App production-ready con auth, pagos y seguridad  · 11 fases · 5-8 h
2. 🚀  MVP para Validar     — Prototype funcional para validar una idea rápido  ·  7 fases · 2-3 h
3. 🔧  Herramienta Interna  — Tool para tu equipo, sin landing ni pagos         · 10 fases · 4-6 h
4. 🎯  Landing Page         — Página de conversión sin backend                  ·  4 steps · ~1 h
5. 🤖  Feature con IA       — Módulo AI para app existente o nueva              ·  7 steps · 2-4 h

Escribe el número o el nombre.
```

Tras la selección:

1. Confirmar el modo
2. Leer `routes/<modo>.md` (source of truth del pipeline)
3. Mostrar pipeline con tiempos
4. Pedir confirmación
5. Ejecutar fases en orden del route file

### Detección de modo implícito

| Si el usuario dice… | Modo |
|---|---|
| "quiero una landing", "crea mi landing page" | 🎯 Landing Page |
| "MVP", "prototipo", "validar rápido" | 🚀 MVP |
| "herramienta interna", "tool para mi equipo" | 🔧 Internal Tool |
| "integrar IA", "feature con AI", "agregar AI" | 🤖 AI Feature |
| "SaaS completo", "pipeline completo" | 🏗️ SaaS Completo |
| Sin indicación clara | → mostrar menú |

## Estructura

```
la-herreria/
├── SKILL.md                          ← este archivo (orchestrator + Mode Selector)
├── routes/                           ← un pipeline por modo (fuente de verdad de los steps)
│   ├── saas-completo.md
│   ├── mvp.md
│   ├── internal-tool.md
│   ├── landing-page.md
│   └── ai-feature.md
├── assets/                           ← un asset por fase (instrucciones del sub-agente)
│   ├── 00-viability-check.md         ← Go/No-Go gate
│   ├── 01-business-model-canvas.md
│   ├── 02-pdr-generator.md
│   ├── 03-tech-spec.md               ← integra `baas` para decisión Supabase vs InsForge (D11)
│   ├── 04-ux-research.md
│   ├── 05-user-stories.md
│   ├── 06-ux-design.md
│   ├── 07-ui-design-workflow.md
│   ├── 08-ui.md                      ← integra `add-ui-kit` para Brand DNA contract (D9, R10)
│   ├── 09-security-audit.md          ← handoff opcional a `el-guardian` (Codex, D3)
│   ├── 10-master-blueprint.md
│   └── (assets opcionales: lean-canvas, job-stories, pre-mortem, interview-script…)
└── references/                       ← knowledge base citable por los assets
    ├── skills-catalog.md
    ├── personas.md
    ├── journey-mapping.md
    ├── information-architecture.md
    ├── interaction-patterns.md
    ├── usability-evaluation.md
    ├── component-selection.md
    ├── acceptance-targets.md
    ├── security-checklist.md
    ├── observability-guide.md
    └── …
```

> **Nota Phase 2:** este SKILL.md es el orchestrator. Los `routes/`, `assets/` y `references/` se portan en sesiones posteriores desde Forge legacy con adaptaciones Forja-específicas (Brand DNA gate en step 8, `el-guardian` handoff en step 9, `baas` decision tree en step 3).

## Pipeline (modo SaaS Completo)

| # | Fase | Asset | Output | Tiempo |
|---|------|-------|--------|--------|
| 0 | Viability Check | `assets/00-viability-check.md` | go/no-go gate | 20m |
| 1 | Business Model Canvas | `assets/01-business-model-canvas.md` | `BMC-<nombre>.md` + `VPC-<nombre>.md` | 20-40m |
| 2 | PDR Generator | `assets/02-pdr-generator.md` | `PDR-<nombre>.md` | 15-30m |
| 3 | Tech Spec | `assets/03-tech-spec.md` | `TECH-SPEC-<nombre>.md` (con BaaS decision) | 10-20m |
| 4 | UX Research | `assets/04-ux-research.md` | `docs/ux-research/` | 30-45m |
| 5 | User Stories | `assets/05-user-stories.md` | `USER-STORIES-<nombre>.md` | 20-40m |
| 6 | UX Design | `assets/06-ux-design.md` | `docs/ux-design/` | 30-50m |
| 7 | UI Design Workflow | `assets/07-ui-design-workflow.md` | `docs/ui-design/screen-flows/` | 30-60m |
| 8 | UI | `assets/08-ui.md` (+ Brand DNA via `add-ui-kit`) | `UI-<nombre>.md` + `src/features/` | 30-60m |
| 9 | Security Audit | `assets/09-security-audit.md` (+ `el-guardian` opcional) | `SECURITY-AUDIT-<nombre>.md` | 45-75m |
| 10 | Master Blueprint | `assets/10-master-blueprint.md` | `BLUEPRINT-<nombre>.md` | 30-60m |

**Total SaaS Completo:** 5-8 h.

Modos cortos (MVP / Internal Tool / Landing / AI Feature) saltan fases según `routes/<modo>.md`.

## Carga de assets (protocolo)

Para cada fase del route activo:

```
1. Detectar la fase por número y nombre
2. Read .claude/skills/la-herreria/assets/<NN>-<nombre>.md
3. Ejecutar el sub-agente siguiendo SUS instrucciones (no las tuyas)
4. Producir el output con la naming convention exacta de la tabla
5. Confirmar con el usuario antes de pasar a la siguiente fase
```

**Caso especial — Fase 8 (UI):** antes de leer `assets/08-ui.md`, este skill DEBE invocar al skill `add-ui-kit` (registry: [memory:skills#add-ui-kit](../../memory/skills.md)) si `brand/brand.json` o `brand/voice.json` no existen. Sin Brand DNA → halt automático por R10. Ver [CONSTRAINTS.md#R10](../../../../CONSTRAINTS.md#L122-L134).

**Caso especial — Fase 9 (Security):** ofrecer al usuario handoff opcional a `el-guardian` (Codex como segundo cerebro, D3) para auditoría adversarial. Si el usuario rechaza, ejecutar el asset estándar `09-security-audit.md`.

**Caso especial — Fase 3 (Tech Spec):** la decisión Supabase vs InsForge se delega al skill `baas` ([memory:skills#baas](../../memory/skills.md)). Resultado se escribe en `TECH-SPEC-<nombre>.md` sección "BaaS Decision".

## Detección de estado

Cuando el usuario inicia conversación, detectar en qué punto está.

> **PREFLIGHT — cargar la ontología (Fase −1) si existe.** Antes de elegir modo, busca `ONTOLOGY.md`
> con `discovery_completed: true` en la raíz. Si existe, el Blueprint **orbita** la ontología: toma
> `problema_priorizado` + `propuesta_de_valor` como entrada de negocio (no rehagas BMC/VPC desde cero
> — ver "Saltar fases"), `entidades_dominio` como semilla del Data Model (Fase 3), `## Glosario` como
> el lenguaje canónico, y `requisitos_seguridad` como insumo de la Fase 9 (Security). Trátala como
> "trabajo previo" (modo B) que no se re-pregunta. Si no existe, opera normal (degradación segura).

### A) Desde cero
**Señales:** "tengo una idea", "quiero crear una app", sin documentos.
**Acción:** ejecutar Mode Selector (FASE 0), luego arrancar Fase 0 (Viability Check) o Fase 1 (BMC) según route.

### B) Con trabajo previo
**Señales:** el usuario adjunta `plan.md`, `PDR-*.md`, `TECH-SPEC-*.md`, wireframes, o dice "ya tengo documentación".
**Acción:** mapear al pipeline y reportar en checklist:

```
Analizando tus documentos…

✅ BMC/VPC      — equivalente en [archivo]
✅ PDR          — equivalente en [archivo]
✅ Tech Spec    — equivalente en [archivo]
⚠️  UX Research — parcial, faltan personas
❌ User Stories — no encontrado
…

Recomiendo continuar desde [siguiente fase pendiente].
```

### C) Skill específico
**Señales:** "hazme screen flows", "genera user stories", "audita la seguridad".
**Acción:** verificar dependencias, resolverlas si faltan, ejecutar la fase concreta.

### D) Retomar
**Señales:** "¿en qué quedamos?", "quiero continuar".
**Acción:** detectar progreso por naming convention de archivos en repo y proponer la siguiente fase.

## Naming convention

Todos los outputs comparten `<nombre-kebab>` definido en Fase 1 y propagado al resto:

| Fase | Output |
|------|--------|
| 1 | `BMC-<nombre>.md` + `VPC-<nombre>.md` |
| 2 | `PDR-<nombre>.md` |
| 3 | `TECH-SPEC-<nombre>.md` |
| 4 | `docs/ux-research/{personas,mental-models,journeys}/` |
| 5 | `USER-STORIES-<nombre>.md` |
| 6 | `docs/ux-design/{information-architecture,interaction-patterns,onboarding,usability-evaluation}/` |
| 7 | `docs/ui-design/{screen-flows,components}/` |
| 8 | `UI-<nombre>.md` + `src/features/<nombre>/` |
| 9 | `SECURITY-AUDIT-<nombre>.md` |
| 10 | `BLUEPRINT-<nombre>.md` |

## Reglas de contexto

1. **No repetir preguntas.** Si el PDR estableció el usuario objetivo, las fases posteriores lo toman de ahí.
2. **No contradecir decisiones previas.** Si Tech Spec eligió Next.js + Supabase, las fases posteriores respetan.
3. **Propagar cambios.** Si el usuario modifica el PDR después de tener Stories, avisar que las Stories pueden necesitar actualización.
4. **Nunca inventar.** Si el PDR no menciona una feature, ningún sub-agente la agrega.
5. **Hallazgos críticos bloquean.** Si la Fase 9 encuentra vulns críticas, la Fase 10 (Blueprint) no se genera hasta resolverlas.

## Saltar fases

| Si el usuario ya tiene… | Saltar | Empezar en |
|--------------------------|--------|------------|
| `ONTOLOGY.md` (Fase −1, con problema + propuesta de valor) | Fase 0–1 | Fase 2 (PDR), orbitando la ontología |
| BMC/modelo de negocio | Fase 1 | Fase 2 (PDR) |
| Diseños en Figma | Fases 6-8 | Fase 9 (Security) |
| Stories | Fases 1-4 | Fase 6 (UX Design) |
| Solo quiere el plan | Fases 6-9 | Stories → Blueprint |
| Docs completos | Fases 1-8 | Security → Blueprint |
| Auditoría aprobada | Fase 9 | Fase 10 (Blueprint) |

Siempre preguntar antes de saltar:

```
Dado que ya tienes <X>, podemos saltar a <Y>.
¿O prefieres que complementemos <X> primero?
```

## Handoff post-Blueprint

Cuando Fase 10 termina, La Herrería ofrece tres caminos:

```
✅ Blueprint completado → BLUEPRINT-<nombre>.md

Siguiente paso:

→ /crisol      — Validación estratégica (7 análisis + dashboard go/no-go)
                 Skill: el-crisol [memory:skills#el-crisol]
→ /build       — Construir con paralelización (2-5 worktrees)
                 Skill: la-forja [memory:skills#la-forja]
→ build manual — Modo el-yunque (secuencial, sin paralelización)

Recomendación:
- Si el proyecto justifica >40 h de desarrollo o hay stakeholders → /crisol primero.
- Si el blueprint tiene ≥3 features independientes → /build (la-forja).
- Si feature único pequeño → modo el-yunque manual.
```

> El handoff (y todo cierre de fase) sigue el formato **Cierre Ejecutivo** de
> [`COMMUNICATION.md`](../../references/COMMUNICATION.md): EN CORTO en lenguaje de negocio →
> QUEDÓ HECHO → OJO → TU DECISIÓN con opciones + recomendación ⭐. Negocio primero, técnica bajo demanda.

## Reglas duras heredadas (Forja)

- **R4 — Orchestrator stays thin.** La Herrería NO escribe código. Coordina sub-agentes que cargan assets. Si un asset pide tocar archivos de producción, eso lo hace `el-yunque` o `la-forja`, no este skill. Ver [CONSTRAINTS.md#R4](../../../../CONSTRAINTS.md#L48-L57).
- **R6 — Skill validation.** Antes de invocar `add-ui-kit`, `baas`, `el-guardian` o cualquier otro skill, validar contra el registry — ej. [memory:skills#add-ui-kit](../../memory/skills.md), [memory:skills#baas](../../memory/skills.md), [memory:skills#el-guardian](../../memory/skills.md). Ver [CONSTRAINTS.md#R6](../../../../CONSTRAINTS.md#L68-L82).
- **R8/R9 — Citation grammar.** Cada claim externo en outputs (Tech Spec, Security Audit, Blueprint) lleva `[web:dominio.com](url)` + sección `## Sources`. Citas internas a memoria: `[memory:lessons#L-NNN]`.
- **R10 — Brand DNA.** Fase 8 obliga a `brand.json` + `voice.json` antes de generar UI. Override solo si conflicto con accesibilidad (gana accesibilidad).

## Frases de activación

**Activan Mode Selector (FASE 0):**

| El usuario dice… | Acción |
|------------------|--------|
| "tengo una idea", "quiero crear algo", "app factory", "empezar un proyecto" | → mostrar menú de modos |

**Detectan modo implícito (saltar menú):**

| El usuario dice… | Modo | Route |
|------------------|------|-------|
| "SaaS completo", "pipeline completo" | 🏗️ | `routes/saas-completo.md` |
| "una landing" | 🎯 | `routes/landing-page.md` |
| "MVP", "validar rápido" | 🚀 | `routes/mvp.md` |
| "herramienta interna" | 🔧 | `routes/internal-tool.md` |
| "feature con IA" | 🤖 | `routes/ai-feature.md` |

**Van directo a una fase concreta:**

| El usuario dice… | Asset |
|------------------|-------|
| "analiza mi modelo de negocio" | `assets/01-business-model-canvas.md` |
| "genera el PDR" | `assets/02-pdr-generator.md` |
| "define el stack" | `assets/03-tech-spec.md` |
| "crea las personas / UX research" | `assets/04-ux-research.md` |
| "user stories" | `assets/05-user-stories.md` |
| "arquitectura de información / navegación" | `assets/06-ux-design.md` |
| "screen flows" | `assets/07-ui-design-workflow.md` |
| "implementa el UI" | `add-ui-kit` → `assets/08-ui.md` |
| "audita seguridad" | `assets/09-security-audit.md` (opcional `el-guardian`) |
| "genera el blueprint" | `assets/10-master-blueprint.md` |
| "¿en qué quedamos?" | → detectar estado D → siguiente fase |

## Loop de ejecución

```
0. Si BUILD_MODE no está seteado → ejecutar Mode Selector (FASE 0)
1. Read routes/<BUILD_MODE>.md
2. Mostrar pipeline + pedir confirmación
3. Para cada fase del route file:
   a. Detectar estado del usuario (A/B/C/D)
   b. Verificar dependencias de la fase
   c. Read assets/<NN>-<nombre>.md
   d. Ejecutar (delegar a sub-agente con tool-filter apropiado)
   e. Producir output con naming convention exacta
   f. Confirmar con el usuario
   g. Proponer siguiente fase
4. Repetir hasta completar el pipeline o hasta donde el usuario quiera parar
```

---

*"De idea a Blueprint en una tarde. Eso es La Herrería."*
