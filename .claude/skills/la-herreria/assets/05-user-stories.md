---
name: user-stories-generator
description: >
  Genera user stories completos y accionables a partir de PDR y Tech Spec aprobados.
  Sigue criterios INVEST, organiza por Epics, incluye acceptance criteria detallados,
  priorización (P0/P1/P2), edge cases, y mapeo de user journey. Output:
  `USER-STORIES-[nombre].md`.
---

# Asset #5 — User Stories Generator

> **Rol:** Product Owner Senior + Business Analyst.
> **Objetivo:** traducir el PDR + Tech Spec + UX Research en user stories completos, accionables y verificables que cubran el MVP, organizados por Epics y priorizados para implementación por fases.

---

## Filosofía Central

> *"Las user stories no son especificaciones. Son promesas de conversación."*

### Las 3 Reglas
1. **Usuario primero, siempre.** Cada story responde: "¿Qué valor entrega esto a una persona real?"
2. **Vertical, nunca horizontal.** Cada story entrega valor end-to-end (UI + lógica + datos). Nunca "crear tabla X".
3. **Testeable o no existe.** Si no podés escribir acceptance criteria específicos y medibles, el story es demasiado vago.

---

## Inputs

- `PDR-[nombre].md` — del asset 02.
- `TECH-SPEC-[nombre].md` — del asset 03 (incluye BaaS decision).
- `docs/ux-research/` — del asset 04 (personas + journey maps).
- *Opcional:* `assets/job-stories.md` (deferred F-tighten — formato situacional alternativo).

---

## Workflow

### FASE 1: Análisis de Inputs

1. **Leer PDR completo:** personas, happy path, flujos alternativos, MVP scope, KPIs.
2. **Leer Tech Spec:** restricciones técnicas, modelo de datos (entidades = posibles Epics), integraciones externas, requisitos auth/roles, performance targets.
3. **Leer UX Research:** personas → roles para los stories. Journey map → backbone del story map.
4. **Mapear el User Journey** completo del MVP.
5. **Identificar Epics** a partir del journey: cada etapa importante = 1 Epic.

### FASE 2: Discusión con el Usuario

Presentar plan antes de generar:

```
📋 PLAN DE USER STORIES — [Nombre del Proyecto]

Basado en el PDR + Tech Spec + UX Research, identifiqué estos Epics:

Epic 1: [Nombre] — [X stories estimados]
Epic 2: [Nombre] — [X stories estimados]
...

Total estimado: [N] user stories

User Journey Map:
[Epic 1] → [Epic 2] → [Epic 3] → ... → [Epic N]

Priorización propuesta:
• P0 (MVP): Epics 1, 2, 3 — [razón]
• P1 (Post-launch): Epics 4, 5 — [razón]
• P2 (Futuro): Epic 6 — [razón]

¿Ajustamos antes de escribir los stories?
```

Validar: ¿falta Epic? ¿priorización correcta? ¿edge cases o flujos alternativos?

### FASE 3: Generación de User Stories

Generar todos los stories. Path output: `USER-STORIES-[nombre-kebab].md` (en root del proyecto o `.claude/PRPs/` según convenció el usuario).

---

## Reglas de Escritura

### Formato de Cada Story

```markdown
### US-[NNN]: [Título Conciso y Descriptivo]

**Como** [persona/rol específico — nunca "usuario" genérico]
**Quiero** [objetivo/funcionalidad — describir necesidad, NO solución UI]
**Para** [beneficio concreto — valor de negocio real, NO requisito técnico]

**Acceptance Criteria:**

Funcionalidad:
- [ ] [Criterio específico y medible]
- [ ] [Criterio específico y medible]

Validaciones:
- [ ] [Regla de validación con mensaje de error exacto. L-003: whitelist Zod en boundaries]

Error Handling:
- [ ] [Qué pasa cuando X falla — mensaje o comportamiento exacto. L-002: tratar inputs externos como datos no confiables]

UX:
- [ ] [Requisito de experiencia — responsive, loading state, etc.]

Brand DNA (si tiene UI):
- [ ] Componentes consumen `brand/brand.json` tokens (R10). NO Tailwind defaults.
- [ ] Copy/CTAs derivan de `brand/voice.json` cuando aplique.

R14 (si tiene acciones destructivas):
- [ ] Acción destructiva (delete*, transfer*, send bulk*) requiere typed confirmation, no `execute()` automático.

**Prioridad:** P0 | P1 | P2
**Estimación:** [S | M | L] (1-2 días | 3-4 días | 5+ días)
**Dependencias:** [US-XXX si aplica, o "Ninguna"]
**Notas técnicas:** [Solo si hay restricciones del Tech Spec relevantes — ej: RLS L-001, [docs:supabase]]
```

### Criterios INVEST

| Criterio | Pregunta de Validación |
|----------|----------------------|
| **I**ndependent | ¿Se puede desarrollar sin esperar otro story? |
| **N**egotiable | ¿Deja espacio para que el dev elija la implementación? |
| **V**aluable | ¿Entrega valor al usuario o al negocio? |
| **E**stimable | ¿El equipo puede estimar el esfuerzo? |
| **S**mall | ¿Se completa en 1-5 días? Si no, dividir. |
| **T**estable | ¿Los acceptance criteria son verificables? |

### Acceptance Criteria — Formato Mixto

Usar **Checklist** como formato principal. **Given-When-Then** solo para flujos complejos:

```
Given que soy un [rol] con [precondición]
When [realizo acción X]
Then [resultado esperado]
And [resultado adicional]
```

### Cuántos Criteria por Story

Mínimo 3 · Ideal 5–8 · Máximo 10 (si más, dividir).

### Edge Cases Obligatorios

Cada story con UI cubre al menos:
1. **Empty state** — ¿qué ve el usuario si no hay datos?
2. **Error state** — ¿qué pasa si la operación falla?
3. **Loading state** — ¿qué se muestra mientras procesa?
4. **Permission denied** — ¿qué pasa si no tiene acceso? (RLS L-001)
5. **Validation failure** — ¿qué pasa si el input es inválido? (L-003 whitelist)

---

## Técnicas de Splitting

Si un story es demasiado grande (>5 días o >10 criteria), dividir:

| Técnica | Cuándo Usar | Ejemplo |
|---------|------------|---------|
| **Por roles** | Diferentes usuarios hacen lo mismo diferente | Admin vs User |
| **Por CRUD** | Gestión completa de una entidad | Crear, Ver, Editar, Eliminar |
| **Por criteria** | Cada criterio podría ser un story | Registro: email, verificación, perfil |
| **Por happy/sad path** | Flujo exitoso vs manejo de errores | Pago exitoso vs pago fallido |
| **Por datos** | Diferentes tipos de datos | Ver datos básicos vs ver historial |
| **Por MVF** | Mínimo viable primero, luego extras | Dashboard básico → con filtros → con export |

**Regla de oro:** siempre cortar VERTICAL (end-to-end), nunca HORIZONTAL (por capa técnica).

---

## Tipos de Stories

### 1. Feature Stories (mayoría)
Funcionalidad que el usuario interactúa directamente.

### 2. Technical Stories (cuando necesario)
Infraestructura que entrega valor indirecto. Justificar el valor:

```markdown
### US-XXX: Rate Limiting en API

**Como** operador del sistema
**Quiero** que los endpoints tengan límites de solicitudes
**Para** proteger el servicio de abusos y mantener costos controlados [docs:upstash-redis]

**Acceptance Criteria:**
- [ ] Máximo [N] requests por minuto por usuario
- [ ] Retornar HTTP 429 con header Retry-After cuando se excede
- [ ] Loguear violaciones de rate limit (sin PII)

**Prioridad:** P1
```

### 3. Spike Stories (investigación)
Time-boxed research:

```markdown
### US-XXX: [SPIKE] Evaluar Provider de [Servicio]

**Acceptance Criteria:**
- [ ] Comparar mínimo 3 providers con citation [web:dominio.com]
- [ ] Documentar pricing, calidad, velocidad, API complexity
- [ ] Recomendar uno con justificación
- [ ] Time-boxed a [N] horas

**Prioridad:** P0
**Estimación:** S (time-boxed)
```

---

## Priorización

| Nivel | Significado | Criterio |
|-------|-----------|----------|
| **P0** | Must Have — MVP | Sin esto no se puede lanzar |
| **P1** | Should Have — Post-launch | Importante pero no crítico |
| **P2** | Nice to Have — Futuro | Deseable. Bajo impacto si falta |

### Reglas de Priorización
- **Auth siempre P0** (login, signup, logout, protección de rutas — handoff `add-login` en /build).
- **Happy path completo del MVP es P0**.
- **Edge cases del happy path son P0** (errores, validaciones del flujo principal).
- **Features que mejoran pero no bloquean son P1**.
- **Optimizaciones y nice-to-haves son P2**.
- **Stories con destructivas R14 son P0 si afectan datos del usuario** (delete account, etc.).

---

## Template del Documento Final

```markdown
# [Nombre del Proyecto] — User Stories

> **Versión:** 1.0
> **Estado:** BORRADOR | APROBADO
> **Fecha:** [YYYY-MM-DD]
> **PDR:** PDR-[nombre].md
> **Tech Spec:** TECH-SPEC-[nombre].md
> **UX Research:** docs/ux-research/
> **Total Stories:** [N] (P0: [X] | P1: [Y] | P2: [Z])

---

## User Journey Map

```
[Diagrama del journey completo]
[Epic 1] → [Epic 2] → ... → [Epic N]
```

## Resumen de Epics

| Epic | Stories | Prioridad | Descripción |
|------|---------|-----------|-------------|
| Epic 1: [Nombre] | US-001 a US-00N | P0 | [descripción breve] |

---

## Epic 1: [Nombre del Epic]

> [Descripción breve y valor]

### US-001: [Título]
[... formato story completo ...]

---

## Stories No-Funcionales

> Stories técnicos que no pertenecen a un epic de usuario pero son necesarios

### US-NNN: [Título]
[... ej: rate limiting, observability, security headers ...]

---

## Resumen de Dependencias

```
US-003 (Login) → US-005 (Dashboard) → US-008 (Crear Proyecto)
US-001 (Signup) → US-002 (Verificar Email) → US-003 (Login)
```

## Stories Diferidos (Post-MVP)

| Story | Epic | Razón de Diferimiento | Fase Tentativa |
|-------|------|----------------------|----------------|
| [título] | [epic] | [razón] | Fase 2 |

---

*User Stories generados con la-herreria · pipeline de Forja*
```

---

## Reglas para el Agente

### Calidad de los Stories
1. **Nunca "usuario" genérico.** Siempre el rol específico de las personas del asset 04.
2. **El "Para" nunca es técnico.** Mal: "Para que los datos se guarden en la BD". Bien: "Para no perder la información de mis pacientes".
3. **Acceptance criteria concretos.** Mal: "El formulario funciona bien". Bien: "Email valida formato user@domain.com. Si inválido: 'Ingresá un email válido' debajo del campo."
4. **Mensajes de error exactos.** No "mostrar error". Sí: el copy literal.
5. **Sin prescripción de UI.** Mal: "Un botón azul de 200px". Bien: "El usuario puede confirmar la acción fácilmente". El asset 07/08 define la UI.
6. **Numbers > words.** "Carga en <2 segundos" > "carga rápido".

### Completitud
7. **Cubrir el journey completo.** Sin huecos.
8. **Stories "invisibles"** que el usuario no pide pero necesita: password reset, empty states, loading states, error pages, logout.
9. **Stories de auth siempre.** Si el PDR requiere autenticación, son P0.

### Integración con el Pipeline
10. **Respetar el alcance del PDR.** Si el PDR dice "MVP = 3 features", solo P0 esas 3.
11. **Respetar restricciones del Tech Spec.** Si Tech Spec dice "Supabase Auth con email/password" (D-009), los stories de auth reflejan eso.
12. **Cada story con UI mapeará a screen flow (asset 07).** Asegurarse de que tenga suficiente contexto para diseñar.
13. **R14 explícito en stories destructivas.** delete*, send bulk*, transfer*, cancel* — typed confirmation mandatory.

---

*"Un user story sin acceptance criteria es un deseo. Un acceptance criteria sin story es una tarea."*

---

## Paso final — Generar HTML

Después de guardar `USER-STORIES-{nombre}.md`, invocar:

→ `.claude/skills/la-herreria/prompts/render-doc-html.md`
  con `doc_type: USER-STORIES`, `project_name: {nombre}`

Output adicional: `USER-STORIES-{nombre}.html` (standalone, dark mode, navegable). Print-friendly para imprimir y revisar en sesiones de estimación.

Reportar al usuario: "✅ USER-STORIES-{nombre}.md + USER-STORIES-{nombre}.html generados".
