---
name: master-blueprint-generator
description: >
  Genera el Master Blueprint: documento único y completo que contiene TODO lo necesario para
  construir una aplicación desde cero. Organiza el desarrollo en Fases → Subfases → Tareas,
  donde cada fase integra User Stories, Wireframes/screen flows, y referencias de UI Implementation.
  Output: `.claude/PRPs/BLUEPRINT-[nombre].md` consumible por `/build` (la-forja paralelo
  o el-yunque manual).
---

# Asset #10 — Master Blueprint Generator

> **Rol:** Technical Project Manager Senior + Solutions Architect.
> **Objetivo:** consolidar TODO el trabajo de los 9 assets anteriores en un único documento ejecutable que cualquier equipo (humano + agentes Forja) pueda seguir para construir la aplicación completa, fase por fase, sin necesitar otro documento de referencia. Es el input directo de `/build` (la-forja paralelo o el-yunque manual).

---

## Filosofía Central

> *"Un Blueprint no es documentación. Es una máquina de instrucciones.
> Si lo seguís paso a paso, al final tenés una app funcionando."*

### 3 Reglas

1. **Autosuficiente.** El Blueprint NO debe requerir leer ningún otro documento. Todo lo que el equipo necesita está DENTRO: stories, screen flows ASCII, prompts, stack, comandos, schemas. Si falta algo, el Blueprint está incompleto.

2. **Secuencial.** Cada fase produce algo funcional y verificable (R7 Three-Layer aplicable). No hay fases "de preparación" sin entregable. No hay saltos de dependencia. Fase N depende solo de Fases 1..N-1.

3. **Copy-paste-ready.** Los comandos de setup son copiables. Los schemas SQL son copiables. Los screen flows ASCII están inline. Los prompts de UI son copiables. El equipo no tiene que interpretar — solo ejecutar.

---

## Workflow

### FASE 1: Recopilar y Validar Inputs

Verificar que todos los assets previos estén completos:

```
CHECKLIST DE INPUTS:
□ PDR-[nombre].md (asset 02)
□ TECH-SPEC-[nombre].md (asset 03 — incluye BaaS decision D-009)
□ docs/ux-research/ (asset 04 — personas + journey maps)
□ USER-STORIES-[nombre].md (asset 05)
□ docs/ux-design/ (asset 06 — IA + interaction patterns + onboarding)
□ docs/ui-design/ (asset 07 — screen flows + component specs)
□ UI-[nombre].md + componentes en src/ (asset 08 — Brand DNA aplicado)
□ PRE-MORTEM-[nombre].md (asset 09A — opcional)
□ SECURITY-AUDIT-[nombre].md (asset 09B — Critical/High resueltos)
□ brand/brand.json + voice.json + brand.css (Brand DNA, R10 enforced)
```

**Si falta algo:** notificar al usuario qué falta y sugerir ejecutar el asset correspondiente. NO generar el Blueprint con inputs incompletos.

**Hallazgos Critical/High abiertos del asset 09 → BLOQUEAR.** No se genera Blueprint con vulnerabilidades sin resolver.

### FASE 2: Definir las Fases de Desarrollo

#### Principios de Agrupación

```
REGLA 1 — P0 primero, P1 después, P2 al final
REGLA 2 — Dependencias naturales: auth antes de features autenticadas; CRUD entidad base
          antes de features sobre esa entidad; pagos después de features de valor;
          notificaciones después de las acciones que las disparan; admin panel después
          de que exista data; testing después de flujos; SEO/landing al final.
REGLA 3 — Cada fase produce un incremento demostrable y verificable (R7).
REGLA 4 — Máximo 10 fases, mínimo 4. Sweet spot: 6–8 fases para MVP.
```

#### Patrón Universal de Fases (90% de SaaS MVPs)

```
FASE 1: Foundation & Setup
  → Stack, BaaS bootstrap (Supabase/Insforge), DB schema con RLS L-001, auth
    via /add-login (D-009), proyecto corriendo local + Bootstrap Contract R11 cumplido.

FASE 2: Brand DNA + Design System & Layout
  → /add-ui-kit + /add-login (si no en Fase 1) → impeccable BATCH para core 11 componentes,
    layouts, navegación según asset 06 IA pattern.

FASE 3: Core Entity CRUD
  → La entidad principal del negocio.

FASE 4: Core Feature (El "Magic")
  → La feature que diferencia la app (IA, procesamiento, cálculos, etc.).
    Si es AI feature: cargar template de .claude/skills/ai/references/ según subtipo
    del asset 04 ai-feature route.

FASE 5: Monetización
  → /add-monetization wizard (add-payments + add-emails + web-quality) — si aplica.

FASE 6: Comunicación
  → Notificaciones (PWA push si aplica via /add-mobile), emails transaccionales.

FASE 7: Administración
  → Admin panel, moderación, analytics internos.

FASE 8: Quality & Polish (Three-Layer Verification R7 enforced)
  → Layer 1 typecheck/lint, Layer 2 tests, Layer 3 e2e + visual diff vs brand.json
    (Anti-Slop Gate). Coverage targets cumplidos.

FASE 9: Pre-deploy Audit
  → /web-quality (Lighthouse + Core Web Vitals + WCAG + SEO + Best Practices).
  → /el-guardian audit adversarial con Codex (D3).
  → Resolver TODOS los Critical/High.

FASE 10: Launch Preparation
  → Deploy producción (Vercel / Coolify), monitoring (Sentry), DNS, SSL,
    landing/SEO pública si aplica. R14 destructivas verificadas con typed confirmation.

(FASE 11+: Post-MVP)
  → Features P2, integraciones, expansión.
```

**ADAPTAR al proyecto.** Si no tiene pagos → no hay fase de monetización. Si es internal tool → no hay landing.

### FASE 3: Descomponer Fases en Subfases y Tareas

```
FASE [N]: [Nombre]
  ├── Subfase [N.1]: [Nombre] (entregable claro)
  │   ├── Tarea [N.1.1]: [Verbo en infinitivo + path específico]
  │   ├── Tarea [N.1.2]: [...]
  │   └── ...
  ├── Subfase [N.2]: [...]
  └── ...
```

**Subfases (máx 5 por fase):**
- Agrupan tareas relacionadas temáticamente.
- Cada subfase tiene un entregable claro.
- Asignable a un desarrollador / sub-agent individual.
- 2–5 subfases por fase típicamente.

**Tareas (máx 8 por subfase):**
- Cada tarea es accionable por UNA persona en MÁXIMO 1 día.
- Empieza con verbo en infinitivo: "Crear", "Implementar", "Configurar".
- Incluye archivos/rutas específicas (`src/features/auth/...`).
- NO ambigua. Mal: "Hacer el login". Bien: "Crear formulario de login con email/password, validación Zod L-003, redirect a dashboard. Path: `src/app/(auth)/sign-in/page.tsx`".

### FASE 4: Integrar Contenido de Assets Anteriores

Por cada fase, incluir:
- **User Stories que cubre** (referencia inline US-NNN del asset 05).
- **Screen flows aplicables** (ASCII inline desde asset 07).
- **Components a usar** (`impeccable` Mode KNOWN/UNKNOWN — cite component_rules.json).
- **Endpoints / Server Actions** (de Tech Spec sección 5).
- **DB tables / migrations** (con RLS L-001).
- **Tests** (Layer 1 + Layer 2 + Layer 3 según R7).
- **Skills Forja a invocar** (`/add-login`, `/add-payments`, etc. en `/build`).

### FASE 5: Definir Three-Layer Verification por Fase (R7)

Cada fase termina con criterios verificables:

```
FASE [N] — Verificación

Layer 1 (Syntax):
  - make typecheck → exit 0
  - make lint → exit 0

Layer 2 (Runtime):
  - make test → exit 0 (suites: [...])

Layer 3 (System):
  - make e2e → exit 0 (e2e tests: [...])
  - Visual diff vs brand.json (Anti-Slop Gate) si fase incluye UI

Sign-off: el-evaluador firma cada layer. Sin firma, fase no se marca passing.
```

---

## Template del Blueprint

```markdown
# 📋 BLUEPRINT: [Nombre del Proyecto]

> **Master Blueprint generado por Forja la-herreria · [fecha]**
> **PDR:** PDR-[nombre].md | **Tech Spec:** TECH-SPEC-[nombre].md
> **Build Mode:** 🏗️ SaaS Completo / 🚀 MVP / 🔧 Tool / 🎯 Landing / 🤖 AI Feature
> **Total Fases:** [N] | **Estimación total:** [horas]
> **Listo para `/build`** (la-forja paralelo o el-yunque manual)

---

## 0. Contexto Resumido (auto-contenido)

### Producto
[Resumen del PDR — 2-3 párrafos]

### Stack (del Tech Spec)
[Tabla compacta]

### Brand DNA (R10)
- Archetype: [del brand.json]
- Posture: density=[X] expression=[Y]
- Tokens críticos: [colors primary, typography display]

### Personas (del UX Research)
[Lista compacta]

---

## 1. User Stories (resumen del asset 05)

[Tabla compacta de epics + counts P0/P1/P2 + journey map]

[Detalle completo de stories diferido a USER-STORIES-[nombre].md (referenciado, NO embebido)]

---

## 2. Bootstrap Contract (R11) — Pre-flight

```
[ ] make setup exit 0
[ ] ≥1 test passing
[ ] feature_list.json con ≥3 features y verification command
[ ] .claude/memory/skills.md generado y validado
[ ] brand/brand.json + voice.json existen
```

`/build` no se permite hasta que `make preflight` exit 0.

---

## 3. Fases de Desarrollo

### FASE 1: [Nombre]

> **Entregable:** [qué funciona al final de esta fase]
> **Stories cubiertas:** US-001, US-002, US-003
> **Estimación:** [Xh]
> **Dependencias:** Ninguna (primera fase)

#### Subfase 1.1: [Nombre]

**Entregable:** [específico]

**Tareas:**

| ID | Tarea | Path | Estimación |
|----|-------|------|------------|
| 1.1.1 | [Verbo + descripción] | [src/...] | [tiempo] |
| 1.1.2 | [...] | [...] | [...] |

**Skills Forja invocados (en `/build`):**
- [`/add-ui-kit`, `/add-login`, etc.] — qué produce y cuándo en la fase.

**Screen flows aplicables (ASCII inline desde asset 07):**

```
[ASCII del screen flow inline para que el equipo no salga del Blueprint]
```

**DB Schema (con RLS L-001):**

```sql
-- migrations/0001_[entity].sql
CREATE TABLE [entity] (...);
ALTER TABLE [entity] ENABLE ROW LEVEL SECURITY;
CREATE POLICY ...;
```

**Endpoints / Server Actions:**

```typescript
// src/features/[feature]/actions/[name].ts
// Zod L-003 whitelist + R14 typed confirmation si destructiva
```

**Verificación (R7 Three-Layer):**

- Layer 1: `make typecheck && make lint` exit 0.
- Layer 2: `make test -- [suite]` exit 0.
- Layer 3: `make e2e -- [happy-path]` exit 0 + visual diff vs brand.json verde si UI.

**Sign-off:** el-evaluador firma cada layer.

#### Subfase 1.2: [...]
[...]

---

### FASE 2: [Nombre]
[... mismo formato ...]

---

[... más fases hasta FASE N ...]

---

## 4. Cronograma Total

```
Fase 1: [Xh]
Fase 2: [Yh]
...
Total: [horas total] (~[días/semanas])
```

---

## 5. Riesgos del Pre-Mortem (asset 09A — si aplica)

[Lista de Tigers / Paper Tigers / Elephants con mitigaciones que afectan el plan de ejecución]

---

## 6. Plan de Deploy (Fase final)

- **Hosting:** [Vercel / Coolify según Tech Spec]
- **CI/CD:** [GitHub Actions / Vercel auto-deploy]
- **Environments:** [staging + prod]
- **Pre-deploy gate:** `el-guardian` audit + `web-quality` audit. Critical/High resueltos.
- **DNS + SSL:** [provider]
- **Monitoring:** [Sentry / equivalent — DSN configurado]

---

## 7. Próximos Pasos Post-Blueprint

```
✅ BLUEPRINT-[nombre].md generado y aprobado.

Para construir:

→ /build → /build pregunta modo:
   🔨 Modo Forja  — la-forja paralelo (N agentes en sandboxes, default)
   🔧 Build Manual — el-yunque manual (fase por fase con tu aprobación)

→ Pre-build checklist:
  [ ] make preflight exit 0 (Bootstrap Contract R11)
  [ ] Branch matchea ^(feature|fix|refactor|chore|docs)/.+$ (R3)
  [ ] feature_list.json con feature en `active` para Fase 1 (R1 WIP=1)
  [ ] Brand DNA presente (R10)
```

---

*"El Blueprint es la diferencia entre construir lo correcto y construir algo incorrecto rápidamente."*
*Generado por Forja · la-herreria · pipeline completo*
```

---

## Reglas Críticas

1. **Autosuficiencia:** Blueprint debe poder leerse standalone — incluir screen flows ASCII inline, schemas SQL inline, prompts inline.
2. **Secuencialidad:** ninguna fase depende de fases futuras.
3. **Verificabilidad R7:** cada fase tiene Layer 1/2/3 definidos.
4. **Bootstrap Contract R11 mandatory** antes de Fase 1.
5. **Brand DNA R10** asegurado en Fase 1 o Fase 2 (sin esto, fases con UI fallan).
6. **Critical/High del asset 09 resueltos** antes de generar el Blueprint.
7. **Wizards Forja referenciados explícitamente:** `/init-saas`, `/add-monetization`, `/add-mobile-stack`, `/enterprise-stack` cuando apliquen.
8. **R14 destructive tools** documentadas en cada fase relevante (typed confirmation, no `execute()`).
9. **Citation grammar R13** en cualquier referencia a libs externas: `[docs:libname]`.

---

## Output

`.claude/PRPs/BLUEPRINT-[nombre].md` (consumible directo por `/build`).

---

*"Un Blueprint Forja-native es la fábrica que construye la fábrica."*

---

## Paso final — Generar HTML

Después de guardar `BLUEPRINT-{nombre}.md` en `.claude/PRPs/`, invocar:

→ `.claude/skills/la-herreria/prompts/render-doc-html.md`
  con `doc_type: BLUEPRINT`, `project_name: {nombre}`

El BLUEPRINT es el doc culmen del pipeline — el badge del header usa azul prominente (`--accent-blue`) y el HTML es el primer entregable que el humano abre en browser para revisar antes de aprobar `/build`.

Output adicional: `.claude/PRPs/BLUEPRINT-{nombre}.html` (standalone, dark mode, sidebar fija con todas las fases, secciones colapsibles para schemas SQL inline + screen flows ASCII, print-friendly).

Reportar al usuario: "✅ BLUEPRINT-{nombre}.md + BLUEPRINT-{nombre}.html generados (.claude/PRPs/). Abrí el .html para revisar antes de /build."
