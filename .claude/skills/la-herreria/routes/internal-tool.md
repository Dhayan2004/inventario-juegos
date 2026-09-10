# Route: 🔧 Herramienta Interna

> *"Sin landing pages, sin revenue model. Solo eficiencia para tu equipo."*

## Metadata

- **Modo:** 🔧 Herramienta Interna
- **Descripción:** tool para uso interno de equipos: dashboards, automatizaciones, admin panels, integraciones.
- **Tiempo estimado:** 4h 20m – 6h 20m
- **Skills activos:** 10 de 10 (incluye Viability Check)
- **Cuándo usar:** cuando los usuarios son conocidos (tu equipo), no hay modelo de negocio externo, y la prioridad es funcionalidad + seguridad sobre diseño o marketing.

---

## Pipeline

```
VIABILITY → PDR → Tech Spec → User Stories → UX Design → UI Workflow → UI → Security → Blueprint
   #0        #2      #3           #5            #6           #7         #8      #9        #10
  20m       20m     15m          25m           30m          40m        30m     60m        30m
```

**Skipped:** BMC completo (#1 → reemplazado por PDR directo), UX Research (#4).

---

### Step 0 · Viability Check (Go/No-Go Gate)

- **Asset:** `assets/00-viability-check.md`
- **Output:** `VIABILITY-[nombre].md`
- **Tiempo:** ~20 min
- **Qué hace:** evalúa viabilidad técnica (¿se puede con el Forja Golden Path?) y operativa (¿resuelve un problema real del equipo?). Para herramientas internas, la dimensión de marketing se reemplaza por "adopción interna".
- **Inputs requeridos:** descripción del problema.
- **Gate:** si NO-GO → detener. Si GO → continuar.

---

### Step 1 · PDR Directo (Sin BMC)

- **Asset:** `assets/02-pdr-generator.md`
- **Output:** `PDR-[nombre].md`
- **Tiempo:** ~20 min
- **Qué hace:** define el problema interno que resuelve la herramienta.
- **Inputs requeridos:** `VIABILITY-[nombre].md` (contexto) + descripción del problema.
- **Adaptación para Internal Tool:**
  - No hay "modelo de negocio" — hay un **problema de operaciones** a resolver.
  - Preguntas clave:
    - *"¿Qué proceso manual estás reemplazando?"*
    - *"¿Quiénes en tu equipo van a usarla? ¿Cuántas personas?"*
    - *"¿Qué datos necesita leer/escribir?"*
    - *"¿Hay sistemas existentes con los que debe integrarse?"*
  - Sección **Fuera de Scope** es crítica.
  - Saltar: análisis de competencia, propuesta de valor de negocio, revenue model.

---

### Step 2 · Tech Spec

- **Asset:** `assets/03-tech-spec.md`
- **Output:** `TECH-SPEC-[nombre].md`
- **Tiempo:** ~15 min
- **Qué hace:** stack, DB schema, integraciones con sistemas internos existentes. BaaS decision delegada a `baas`.
- **Inputs requeridos:** `PDR-[nombre].md`.
- **Adaptación para Internal Tool:**
  - Stack: Forja Golden Path (Next.js + Supabase O Insforge) — pero evaluar si hay restricciones de infra interna (self-hosted Supabase / Insforge según `baas` decision tree).
  - Auth: email/password o SSO corporativo según el contexto.
  - Integraciones: documentar APIs internas, sheets, ERPs, etc. con citation grammar [docs:libname] (R13).
  - Deploy: puede ser Coolify self-hosted en lugar de Vercel.

---

### Step 3 · User Stories

- **Asset:** `assets/05-user-stories.md`
- **Output:** `USER-STORIES-[nombre].md`
- **Tiempo:** ~25 min
- **Qué hace:** stories desde la perspectiva del equipo interno.
- **Inputs requeridos:** `PDR-[nombre].md` + `TECH-SPEC-[nombre].md`.
- **Adaptación para Internal Tool:**
  - Los "usuarios" son roles del equipo: admin, editor, viewer, etc.
  - Incluir stories de permisos/acceso: *"Como admin, puedo crear usuarios..."*
  - Incluir stories de auditoría si hay datos sensibles: *"Como admin, puedo ver quién editó X..."*

---

### Step 4 · UX Design (Simplificado)

- **Asset:** `assets/06-ux-design.md`
- **Output:** `docs/ux-design/information-architecture.md` + `docs/ux-design/interaction-patterns.md`
- **Tiempo:** ~30 min
- **Qué hace:** arquitectura de información + patrones de interacción.
- **Inputs requeridos:** `USER-STORIES-[nombre].md`.
- **Adaptación para Internal Tool:**
  - Foco en: navegación clara, densidad de información, eficiencia de flujo.
  - Saltar o simplificar: personas elaboradas (los usuarios son conocidos), usability testing.
  - No es necesario: onboarding elaborado.
  - Prioridad: *"¿Puede alguien completar la tarea principal en < 3 clics?"*

---

### Step 5 · UI Design Workflow

- **Asset:** `assets/07-ui-design-workflow.md`
- **Output:** `docs/ui-design/screen-flows/` + `docs/ui-design/components/`
- **Tiempo:** ~40 min
- **Qué hace:** screen flows + acceptance targets — críticos para herramientas complejas.
- **Inputs requeridos:** `docs/ux-design/`.
- **Adaptación para Internal Tool:**
  - Priorizar flujos de datos y tablas sobre páginas de presentación.
  - Acceptance targets críticos — los usuarios internos tienen expectativas técnicas altas.

---

### Step 6 · UI (Brand DNA gate, R10 — preset utility)

- **Asset:** `assets/front-end-design.md` → luego `assets/08-ui.md`
- **Output:** `UI-[nombre].md` + `src/features/` + `src/shared/ui/`
- **Tiempo:** ~30 min
- **Qué hace:** UI funcional y densa — priorizando eficiencia sobre estética.
- **Inputs requeridos:** `docs/ui-design/screen-flows/`.
- **⚠️ R10 Brand DNA gate:** invocar `add-ui-kit` con preset **Tech Utility** si no existe Brand DNA — preset adecuado para internal tools (densidad alta, posture funcional).
- **Adaptación para Internal Tool:**
  - Estilo: dashboard denso, tablas, filtros, formularios.
  - Componentes clave: DataTable, FilterBar, StatusBadge, BulkActions, ConfirmModal (último con R14 typed confirmation para destructivas).

---

### Step 7 · Security Audit (handoff a el-guardian recomendado, D3)

- **Asset:** `assets/09-security-audit.md`
- **Skill handoff recomendado:** `el-guardian` ([memory:skills#el-guardian]) — internal tools manejan datos sensibles reales del equipo, audit adversarial con Codex es valioso.
- **Output:** `SECURITY-AUDIT-[nombre].md`
- **Tiempo:** ~60 min
- **Qué hace:** auditoría completa — crítica porque las herramientas internas manejan datos sensibles reales.
- **Inputs requeridos:** `UI-[nombre].md` + `TECH-SPEC-[nombre].md`.
- **⚠️ Énfasis especial para Internal Tools:**
  - Control de acceso por roles (RBAC) — quién puede ver/editar/eliminar qué.
  - Auditoría de acciones (logs de quién hizo qué).
  - Protección de datos sensibles de empleados/clientes internos (RLS L-001 enforced).
  - Rate limiting en APIs internas.
  - **R14 strict:** acciones destructivas (delete*, transfer*, send*) requieren typed confirmation, no `execute()` automático.
  - **Regla:** si hay vulnerabilidades críticas, NO avanzar al Step 8.

---

### Step 8 · Blueprint

- **Asset:** `assets/10-master-blueprint.md`
- **Output:** `.claude/PRPs/BLUEPRINT-[nombre].md`
- **Tiempo:** ~30 min
- **Qué hace:** plan de construcción + plan de rollout interno.
- **Inputs requeridos:** todos los outputs anteriores.
- **Adaptación para Internal Tool:**
  - Incluir: plan de capacitación del equipo, migración de datos desde el proceso actual.
  - Rollout: piloto con un subgrupo → feedback → rollout completo.
  - Mantenimiento: quién es el owner técnico de la herramienta.

---

## Outputs Finales

| Archivo | Generado en |
|---------|-------------|
| `PDR-[nombre].md` | Step 1 |
| `TECH-SPEC-[nombre].md` | Step 2 |
| `USER-STORIES-[nombre].md` | Step 3 |
| `docs/ux-design/` (IA + patterns) | Step 4 |
| `docs/ui-design/` | Step 5 |
| `UI-[nombre].md` | Step 6 |
| `SECURITY-AUDIT-[nombre].md` | Step 7 |
| `BLUEPRINT-[nombre].md` | Step 8 ← **Entregable final** |

---

## Qué se Omite y Por Qué

| Skill omitido | Razón |
|---------------|-------|
| BMC completo (#1) | No hay modelo de negocio externo; se reemplaza con PDR directo orientado a problema interno |
| UX Research completo (#4) | Los usuarios son conocidos — podés hablar con ellos directamente |
| Personas elaboradas | El equipo interno no necesita arquetipos; tiene nombres reales |

---

*"La mejor herramienta interna es la que el equipo usa sin que nadie tenga que pedirles que la usen."*
