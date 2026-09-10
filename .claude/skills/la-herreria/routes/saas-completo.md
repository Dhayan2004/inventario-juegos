# Route: 🏗️ SaaS Completo

> *"El pipeline completo. De idea a Blueprint production-ready."*

## Metadata

- **Modo:** 🏗️ SaaS Completo
- **Descripción:** Aplicación web production-ready con auth, pagos, seguridad y escalabilidad
- **Tiempo estimado:** 5h 20m – 8h 20m
- **Skills activos:** 11 de 11 (incluye Viability Check)
- **Cuándo usar:** cuando el objetivo es lanzar un producto real, no solo validar

---

## Pipeline

```
VIABILITY → BMC/Lean → PDR → Tech Spec → UX Research → User Stories → UX Design → UI Workflow → UI → Pre-Mortem + Security → Blueprint
   #0         #1        #2       #3           #4             #5            #6           #7        #8          #9                #10
  20m        30m       20m      15m          40m            30m           45m          45m       30m         60m                45m
```

**Skills opcionales integrados:** Lean Canvas (alt. Step 1), Interview Script (post Step 4), Job Stories (alt. Step 5), Pre-Mortem (Step 9)

---

### Step 0 · Viability Check (Go/No-Go Gate)

- **Asset:** `assets/00-viability-check.md`
- **Output:** `.claude/PRPs/VIABILITY-[nombre].md`
- **Tiempo:** ~20 min
- **Qué hace:** evalúa viabilidad técnica (Forja Golden Path fit), de negocio y marketing. Genera veredicto GO/CAUTION/NO-GO antes de invertir horas en planificación.
- **Inputs requeridos:** solo la idea del usuario (o `$ARGUMENTS` si se proporcionó contexto).
- **Gate:** Si NO-GO → detener pipeline. Si CAUTION → recomendar ruta MVP. Si GO → continuar.

---

### Step 1 · Business Model Canvas

- **Asset:** `assets/01-business-model-canvas.md`
- **Asset alternativo:** `assets/lean-canvas.md` (Lean Canvas de Ash Maurya)
- **Output:** `BMC-[nombre].md` + `VPC-[nombre].md` (o `LEAN-CANVAS-[nombre].md`)
- **Tiempo:** 20–40 min
- **Qué hace:** define los 9 bloques del modelo de negocio + Value Proposition Canvas.
- **Inputs requeridos:** `VIABILITY-[nombre].md` (contexto) + idea del usuario.
- **Notas:** define el `[nombre-kebab]` del proyecto aquí. Se propaga a todos los outputs (R3 active feature compatible).
- **Bifurcación:** antes de comenzar, preguntar:
  ```
  Para tu modelo de negocio tengo dos caminos:

  📊 Business Model Canvas — Modelo completo (9 bloques + VPC).
     Mejor si: ya conocés tu mercado, tenés datos, producto establecido.

  📋 Lean Canvas — Enfocado en hipótesis y validación (Ash Maurya).
     Mejor si: idea nueva, muchas incertidumbres, fase exploratoria.

  ¿Cuál preferís?
  ```

---

### Step 2 · PDR Generator

- **Asset:** `assets/02-pdr-generator.md`
- **Output:** `PDR-[nombre].md`
- **Tiempo:** 15–30 min
- **Qué hace:** entrevista de producto → Product Definition Report completo.
- **Inputs requeridos:** `BMC-[nombre].md`.

---

### Step 3 · Tech Spec (con BaaS Decision Tree, D11)

- **Asset:** `assets/03-tech-spec.md`
- **Output:** `TECH-SPEC-[nombre].md`
- **Tiempo:** 10–20 min
- **Qué hace:** stack, DB schema, arquitectura, APIs, decisiones técnicas. **Sección obligatoria "BaaS Decision"** delegada al skill `baas` ([memory:skills#baas]).
- **Inputs requeridos:** `PDR-[nombre].md`.
- **Stack:** Forja Golden Path — Next.js 16 + React 19 + TypeScript + Tailwind + **Supabase (default) o InsForge (override según Tech Spec)** + Vercel AI SDK v5 + OpenRouter [docs:vercel-ai-sdk@v5] + Zod.

---

### Step 4 · UX Research

- **Asset:** `assets/04-ux-research.md`
- **Output:** `docs/ux-research/` (personas/, mental-models/, journeys/)
- **Tiempo:** 30–45 min
- **Qué hace:** personas + modelos mentales + journey maps desde el PDR.
- **Inputs requeridos:** `PDR-[nombre].md`.

**🔀 Checkpoint post-UX Research:**
```
✅ UX Research completado.

Antes de continuar con User Stories, ¿querés:

1. ▶️  Continuar al Step 5 (User Stories)
2. 🎤  Generar Interview Scripts (The Mom Test) para validar las personas con usuarios reales
3. ✏️  Ajustar algo en las personas o journeys

Recomiendo opción 1 si ya conocés bien a tus usuarios.
Recomiendo opción 2 si hay hipótesis que necesitan validación.
```

Si elige 2 → leer `assets/interview-script.md` y ejecutar (asset deferred — F-tighten). Al terminar, retomar Step 5.

---

### Step 5 · User Stories

- **Asset:** `assets/05-user-stories.md`
- **Asset alternativo:** `assets/job-stories.md` (Job Stories — formato situacional, deferred F-tighten)
- **Output:** `USER-STORIES-[nombre].md` (o `JOB-STORIES-[nombre].md`)
- **Tiempo:** 20–40 min
- **Qué hace:** Epics + Stories INVEST con criterios de aceptación.
- **Inputs requeridos:** `PDR-[nombre].md` + `TECH-SPEC-[nombre].md` + `docs/ux-research/`.
- **Bifurcación:** antes de comenzar, preguntar:
  ```
  Para documentar los requisitos tengo dos formatos:

  📝 User Stories — "Como [rol], quiero [acción] para [beneficio]"
     Mejor si: múltiples roles, permisos (RBAC), equipo familiarizado con User Stories.

  🎯 Job Stories — "Cuando [situación], quiero [motivación] para [resultado]"
     Mejor si: pocos roles pero muchos contextos, features disparadas por eventos.

  ¿Cuál preferís?
  ```

---

### Step 6 · UX Design

- **Asset:** `assets/06-ux-design.md`
- **Output:** `docs/ux-design/` (information-architecture.md, interaction-patterns.md, onboarding.md, usability-evaluation/)
- **Tiempo:** 30–50 min
- **Qué hace:** IA + interaction patterns + usabilidad + onboarding.
- **Inputs requeridos:** `USER-STORIES-[nombre].md`.

---

### Step 7 · UI Design Workflow

- **Asset:** `assets/07-ui-design-workflow.md`
- **Output:** `docs/ui-design/screen-flows/` + `docs/ui-design/components/`
- **Tiempo:** 30–60 min
- **Qué hace:** screen flows + acceptance targets por pantalla.
- **Inputs requeridos:** `docs/ux-design/`.

---

### Step 8 · UI (Brand DNA gate, R10)

- **Asset:** `assets/front-end-design.md` → luego `assets/08-ui.md`
- **Output:** `UI-[nombre].md` + `src/features/` + `src/shared/ui/`
- **Tiempo:** 30–60 min
- **Qué hace:** design system + UI implementada (anti-AI-slop con Brand DNA contract).
- **Inputs requeridos:** `docs/ui-design/screen-flows/`.
- **⚠️ R10 Brand DNA Gate (mandatorio):** antes de leer `08-ui.md`, este step DEBE invocar al skill `add-ui-kit` ([memory:skills#add-ui-kit]) si `brand/brand.json` o `brand/voice.json` no existen. Sin Brand DNA → halt automático. Ver [memory:CONSTRAINTS.md#R10].
- **⚠️ Importante:** leer `front-end-design.md` ANTES que `08-ui.md` para los principios estéticos.

---

### Step 9 · Pre-Mortem + Security Audit

**9A · Pre-Mortem (Riesgos de Producto/Mercado/Equipo)**

- **Asset:** `assets/pre-mortem.md`
- **Output:** `PRE-MORTEM-[nombre].md`
- **Tiempo:** ~20 min
- **Qué hace:** análisis de riesgos usando Tigers/Paper Tigers/Elephants. Cubre riesgos de producto, mercado, ejecución, financieros y equipo.
- **Inputs requeridos:** `PDR-[nombre].md` + `BMC-[nombre].md` + `TECH-SPEC-[nombre].md`.

**🔀 Checkpoint pre-Security:**
```
✅ Pre-Mortem completado.

Tigers: [N] | Paper Tigers: [N] | Elephants: [N]
Nivel de riesgo: [🔴 Alto | 🟡 Medio | 🟢 Bajo]

¿Continuamos con la auditoría de seguridad técnica?
```

**9B · Security Audit (Riesgos Técnicos/Código) — opcional handoff a el-guardian (D3)**

- **Asset:** `assets/09-security-audit.md`
- **Skill handoff opcional:** `el-guardian` ([memory:skills#el-guardian]) — Codex como segundo cerebro para auditoría adversarial. Ofrecer al usuario; si rechaza, ejecutar el asset estándar.
- **Output:** `SECURITY-AUDIT-[nombre].md`
- **Tiempo:** 45–75 min
- **Qué hace:** OWASP Top 10 2025 + vibe-coding-specific risks + escalabilidad + observabilidad. R14 destructive tools verification incluida.
- **Inputs requeridos:** `UI-[nombre].md` + `TECH-SPEC-[nombre].md` + `PRE-MORTEM-[nombre].md`.
- **⚠️ Regla crítica:** si hay vulnerabilidades críticas, NO avanzar al Step 10.
- **Integración:** los Tigers del Pre-Mortem se incorporan como contexto de riesgos en el Security Audit.

---

### Step 10 · Master Blueprint

- **Asset:** `assets/10-master-blueprint.md`
- **Output:** `.claude/PRPs/BLUEPRINT-[nombre].md`
- **Tiempo:** 30–60 min
- **Qué hace:** consolida TODO en un plan de ejecución por fases con estimaciones, listo para `/build` (la-forja paralelo o el-yunque manual).
- **Inputs requeridos:** todos los outputs anteriores.
- **Prerequisito:** Security Audit aprobado (sin críticos).

---

## Outputs Finales

| Archivo | Generado en | Opcional |
|---------|-------------|----------|
| `VIABILITY-[nombre].md` | Step 0 | |
| `BMC-[nombre].md` + `VPC-[nombre].md` | Step 1 | Alt: `LEAN-CANVAS-[nombre].md` |
| `PDR-[nombre].md` | Step 2 | |
| `TECH-SPEC-[nombre].md` (con BaaS Decision) | Step 3 | |
| `docs/ux-research/` | Step 4 | |
| `INTERVIEW-SCRIPT-[nombre].md` | Post Step 4 | ✅ Opcional |
| `USER-STORIES-[nombre].md` | Step 5 | Alt: `JOB-STORIES-[nombre].md` |
| `docs/ux-design/` | Step 6 | |
| `docs/ui-design/` | Step 7 | |
| `UI-[nombre].md` | Step 8 | |
| `PRE-MORTEM-[nombre].md` | Step 9A | |
| `SECURITY-AUDIT-[nombre].md` | Step 9B | |
| `BLUEPRINT-[nombre].md` | Step 10 | ← **Entregable final** |

---

## Cuándo Saltar Steps

| Situación | Skip | Razón |
|-----------|------|-------|
| Ya tiene BMC/modelo de negocio | Step 1 | Empezá en PDR con el doc existente |
| Ya tiene diseños en Figma | Steps 6, 7, 8 | No regenerar UI (pero R10 Brand DNA gate sigue aplicando) |
| Ya tiene UX research | Step 4 | Empezá en User Stories |
| Ya tiene auditoría aprobada | Step 9 | Va directo a Blueprint |

---

## Siguiente Paso (Post-Blueprint)

Al completar el Blueprint, ofrecer:

```
✅ Blueprint completado → .claude/PRPs/BLUEPRINT-[nombre].md

El plan completo está listo. ¿Qué sigue?

→ /crisol       — Validación estratégica (7 análisis + dashboard go/no-go)
→ /build        — Construir el producto (la-forja paralelo o el-yunque manual)
→ /init-saas    — Si querés bootstrap completo SaaS antes de la primera feature
→ /lanzamiento  — Diseñar la estrategia de Go-to-Market
→ /metas        — Definir OKRs para el primer trimestre
→ /precio       — Diseñar la estrategia de pricing
→ /roi          — Proyecciones financieras
```

---

*"El pipeline completo no es burocracia — es la diferencia entre un producto que dura y uno que hay que rehacer."*
