# Forja Playbook — Prompts de Operación Diaria

> Colección de prompts listos para copiar y pegar. Diseñados para que cambies lo mínimo posible entre proyectos. Todo lo que necesitas reemplazar está entre `{{dobles llaves}}`.
>
> **Guarda este archivo abierto mientras trabajas.** Vive en la raíz de tu proyecto junto con AGENTS.md.

---

## Variables globales del proyecto

Completa esto una sola vez por proyecto y úsalo como referencia para los prompts:

```
PROJECT_NAME  = {{nombre del proyecto, ej: "hila"}}
BLUEPRINT     = .claude/PRPs/BLUEPRINT-{{nombre}}.md
```

---

## PROMPT 1 — Inicio de sesión (warm start)

**Cuándo usarlo:** cada vez que abres Claude Code en un proyecto Forja después de haber cerrado la sesión anterior.

**Qué cambiar:** solo `{{PROJECT_NAME}}`.

---

```
Eres el agente de Forja trabajando en el proyecto {{PROJECT_NAME}}.

PASO 0 — Lee en orden ANTES de hacer cualquier otra cosa:
  1. AGENTS.md
  2. feature_list.json
  3. PROGRESS.md
  4. .claude/memory/decisions.md (solo las últimas 10 entradas)
  5. git log --oneline -10

REPORTA esto al terminar la lectura:
  - Feature activa: [ID de la feature con state "active", o "ninguna"]
  - Branch actual: [git rev-parse --abbrev-ref HEAD]
  - Última sesión: [fecha + resumen de PROGRESS.md]
  - Próximo paso sugerido: [según Blueprint y feature_list.json]

LUEGO:
  Si hay feature activa → pregúntame "¿Continuamos con [ID]?" antes de tocar código.
  Si no hay feature activa → muéstrame el backlog (features en "pending") y espera.

Reglas activas todo el tiempo: R1 (WIP=1) · R2 (commits convencionales) ·
R7 (three-layer verify antes de marking passing) · R10 (Brand DNA si hay UI).
```

---

## PROMPT 2 — Cierre de feature + apertura de la siguiente ⭐

**El más importante del playbook.** Úsalo cuando terminas de construir una feature y quieres pasar a la siguiente.

**Qué cambiar:** `{{PROJECT_NAME}}`, `{{FEATURE_ID}}` (ej: F1-T2), `{{FEATURE_BEHAVIOR}}` (una línea de qué hacía). El resto es automático.

---

```
Cerramos {{FEATURE_ID}} ({{FEATURE_BEHAVIOR}}) y abrimos la siguiente.

═══════════════════════════════════════════════
PARTE A — CERRAR {{FEATURE_ID}}
═══════════════════════════════════════════════

PASO A1 — Three-Layer Verification (R7). Ejecutar en orden, parar si falla alguno:

  make typecheck && make lint    # Layer 1 — Syntax
  make test                      # Layer 2 — Runtime
  make build                     # Layer 3 — System (make e2e si está configurado)

Si Layer 1 falla → STOP. No avances. Muéstrame los errores.
Si Layer 2 falla → STOP. No avances. Muéstrame los errores.
Si Layer 3 falla → STOP. No avances. Muéstrame los errores.

PASO A2 — Marcar passing (solo si R7 pasó):

  Editar feature_list.json:
    - state: "passing"
    - evidence: "three-layer verified, [FECHA HOY], Layer 1+2+3 exit 0"
    - commit: [hash del último commit de la feature]

  Commit:
    evaluator({{FEATURE_ID}}): mark passing — three-layer verified

PASO A3 — Actualizar PROGRESS.md. Agregar sección:

  ## [FECHA HOY]
  ### Feature cerrada: {{FEATURE_ID}} — {{FEATURE_BEHAVIOR}}
  **Estado:** passing ✅
  **Commits de esta sesión:**
  [git log --oneline main..HEAD o el rango de la sesión]
  **Próxima feature:** [ID de la siguiente]

  Commit:
    chore(progress): cierre sesión {{FEATURE_ID}}

═══════════════════════════════════════════════
PARTE B — ABRIR SIGUIENTE FEATURE
═══════════════════════════════════════════════

PASO B1 — Mostrarme el backlog. Leer feature_list.json y listar en formato:

  | ID | Behavior (primeras 80 chars) | Branch |
  |----|------------------------------|--------|
  | [todas las features en state "pending"] |

Esperar mi confirmación antes de B2. Si hay una sola opción obvia, sugerirla.

PASO B2 — Activar la feature elegida [esperar que yo confirme cuál]:

  git checkout main
  git checkout -b feature/{{NEXT_FEATURE_SLUG}}

  Editar feature_list.json:
    - state: "active"
    - branch: "feature/{{NEXT_FEATURE_SLUG}}"

  Commit:
    chore({{NEXT_FEATURE_ID}}): activate feature — branch feature/{{NEXT_FEATURE_SLUG}}

PASO B3 — Leer contexto de la nueva feature:

  1. BLUEPRINT-{{PROJECT_NAME}}.md → sección de {{NEXT_FEATURE_ID}}
  2. Si existe .claude/PRPs/PIEZA-{{NEXT_FEATURE_ID}}.md → leerla
  3. .claude/memory/decisions.md → decisiones relevantes para esta feature

Presentar resumen:

  "Arrancando {{NEXT_FEATURE_ID}}: [behavior]
   Dependencias: [otras features passing que esta consume]
   Primer paso concreto: [del Blueprint]
   Brand DNA: [✅ brand.json existe / ❌ falta — correr /add-ui-kit primero]"

Esperar mi "go" antes de escribir código.

═══════════════════════════════════════════════
REGLAS:
  R1: solo 1 feature "active" a la vez — verificar antes de activar.
  R2: todos los commits en formato feat/fix/chore/evaluator(SCOPE): descripción.
  R10: si la nueva feature tiene UI → leer brand.json + voice.json ANTES de generar.
  R14: si hay tools destructivas → typed confirmation, sin execute() automático.
═══════════════════════════════════════════════
```

---

## PROMPT 3 — Deploy (despachar)

**Cuándo usarlo:** cuando una feature está en "passing" y quieres crear el PR y pushear.

**Qué cambiar:** `{{FEATURE_ID}}`. El resto lo maneja `/despachar` automáticamente.

---

```
Preparar y despachar la feature {{FEATURE_ID}} a producción.

VERIFICAR ANTES DE CONTINUAR (si alguno falla, decirme cuál y parar):
  [ ] feature_list.json: {{FEATURE_ID}} tiene state "passing"
  [ ] Solo hay 1 feature en state "active" o ninguna (R1)
  [ ] Branch actual != main
  [ ] make preflight exit 0

Si todo pasa → ejecutar:

  /despachar

El protocolo es non-interactive. Solo pausar si:
  - Branch == main → ABORT + decirme
  - R1 violation (>1 active) → ABORT + decirme
  - Cualquier layer R7 falla → ABORT + mostrar errores exactos
  - Review pre-landing encuentra issue CRITICAL → pausar + mostrar cada uno con fix sugerido

Al terminar → reportar la URL del PR creado.
Después del PR → ejecutar /web-quality si hay cambios de UI.
```

---

## PROMPT 4 — Auditoría de seguridad

**Cuándo usarlo:** después de cualquier feature que toque auth, payments, API routes, RLS, webhooks, o LLM inputs. Antes de deploy en features sensibles.

**Qué cambiar:** `{{FEATURE_ID}}`, `{{FEATURE_PATH}}` (ej: `src/features/payments/`).

---

```
Auditoría de seguridad pre-deploy para {{FEATURE_ID}}.

INVOCAR:
  /el-guardian

El audit usa Codex como segundo cerebro independiente del agente que generó el código.

SCOPE — cubrir las 3 capas:
  1. OWASP Top 10 2025 — foco en el path {{FEATURE_PATH}}/**
  2. Vibe-coding risks:
     - Prompt injection en inputs que llegan a LLMs
     - Secrets en logs o error messages
     - Ghost packages (deps AI-suggested no verificadas)
  3. Forja gates:
     - RLS en cada tabla nueva con user_id (L-001)
     - R14: tools destructivas sin execute() automático
     - Brand DNA leak: tokens hardcoded fuera de brand.css

CRITERIO DE PASO:
  Critical = 0 AND High = 0
  
Si hay Critical o High → NO proceder con deploy.
El output es SECURITY-AUDIT-{{FEATURE_ID}}.md.

Si el audit pasa → continuar con PROMPT 3 (deploy).
Si el audit falla → mostrarme los findings con severidad y fix recomendado.
```

---

## PROMPT 5 — Planificación de feature nueva (Blueprint)

**Cuándo usarlo:** cuando vas a comenzar un proyecto desde cero o quieres planificar una feature nueva que no está en el Blueprint.

**Qué cambiar:** nada. La Herrería te guía con preguntas.

---

```
Quiero planificar un proyecto/feature nuevo.

Invocar: /plan

La Herrería va a guiarme con el Mode Selector (SaaS completo, MVP,
Landing Page, etc.) y el pipeline de assets hasta producir un Blueprint.

Antes de empezar, verificar:
  [ ] make preflight exit 0 (o /forge-check para diagnóstico)
  [ ] feature_list.json existe (aunque sea vacío)

No generar código hasta tener Blueprint aprobado.
```

---

## PROMPT 6 — Diagnóstico del entorno

**Cuándo usarlo:** primera vez en un proyecto, después de instalar Forja en un proyecto existente, o cuando algo no funciona como esperas.

**Qué cambiar:** nada.

---

```
Diagnosticar el entorno Forja de este proyecto.

Ejecutar: /forge-check

Luego reportar el resultado con esta estructura:
  ✅ / ❌ Cada gate del Bootstrap Contract (R11)
  ✅ / ❌ Dependencias Node (next, zod, zustand, @supabase/supabase-js)
  ✅ / ❌ Brand DNA (brand.json + voice.json)
  ✅ / ❌ Skills disponibles (la-herreria, el-evaluador, el-guardian, etc.)

Por cada ❌ → sugerir el fix exacto con el comando a correr.
Por cada ⚠️ → explicar el impacto y si bloquea o no el flujo.
```

---

## Flujo de un día típico de trabajo

```
Mañana
  └── PROMPT 1 (warm start) → ver en qué quedé, confirmar feature activa

Durante el día
  └── trabajar en la feature activa (la-forja / el-yunque)
  └── make typecheck después de cada cambio grande
  └── commits atómicos: feat(ID): descripción

Al terminar una feature
  └── PROMPT 2 (cierre + apertura) ← el más importante, 6 pasos

Antes de subir a producción
  └── PROMPT 4 (security audit) si la feature toca auth/payments/API
  └── PROMPT 3 (deploy) → PR creado + URL reportada

Cada semana
  └── PROMPT 5 (planificación) si hay features nuevas que no están en el Blueprint
```

---

## Cheat sheet de comandos rápidos

| Qué quiero hacer | Comando / Skill |
|------------------|-----------------|
| Empezar proyecto desde cero | `/forge-check` → `/plan` |
| Retomar sesión | `/avivar` (carga contexto rápido) |
| Construir feature (manual) | `/build` → elige "Build Manual" → `el-yunque` |
| Construir feature (paralelo) | `/build` → elige "Modo Forja" → `la-forja` |
| Microtarea < 5 min | `el-tajo` |
| Feature mediana < 30 min | `el-golpe` |
| Iterar sobre código existente | `/sprint` |
| Auditar antes de deploy | `/el-guardian` |
| Calidad web (Lighthouse) | `/web-quality` |
| Setup auth | `/add-login` |
| Setup pagos | `/add-payments` |
| Setup emails | `/add-emails` |
| Setup todo SaaS de una | `/init-saas` |
| Setup enterprise completo | `/enterprise-stack` |
| Ver estado de features | abrir `tasks.html` o leer `feature_list.json` |

---

*Forja Playbook — actualizar cuando el flujo personal cambie.*
