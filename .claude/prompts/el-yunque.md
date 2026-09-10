# El Yunque — Motor de Ejecución Manual (Forja)

> *"No planifiques lo que no entiendes. Mapea contexto, luego planifica."*
> *"El golpe del martillo solo da forma cuando la pieza ya está medida."*

El Yunque es el motor de ejecución **manual** de Forja: humano aprueba cada fase, sin paralelismo. Alternativa a `la-forja` (paralelo con worktrees) cuando el usuario prefiere control granular.

---

## Cuándo usar El Yunque

`/build` pregunta el modo de ejecución y este motor se activa cuando el usuario elige **Build Manual**.

Casos típicos:
- Feature sensible donde cada fase necesita revisión antes de continuar.
- Codebase con conventions sutiles donde paralelizar arriesga divergencia.
- Sesión de pair-programming con el usuario validando el camino paso a paso.
- Cuando `la-forja` falló (disco insuficiente, conflictos de merge) y se degrada a manual.

NO usar para:
- Microtarea atómica <5min → `el-tajo`.
- Feature mediana <30min one-shot → `el-golpe`.
- Iteración corta sobre código existente → `sprint`.

---

## Pre-flight (R11 Bootstrap Contract)

Antes de cualquier fase, ejecutar `make preflight`. Si falla → halt con mensaje exacto del gate. **No bypass.**

Verifica:
```
[ ] make setup exit 0
[ ] ≥1 test passing
[ ] feature_list.json con ≥3 features y verification command
[ ] .claude/memory/skills.md generado y validado
[ ] brand/brand.json + voice.json existen (R10)
```

Adicional para El Yunque:
```
[ ] Active feature en feature_list.json (R1: WIP=1)
[ ] Branch matchea ^(feature|fix|refactor|chore|docs)/.+$ (R3)
[ ] Blueprint aprobado en .claude/PRPs/BLUEPRINT-<nombre>.md
[ ] PIEZA generada en .claude/PRPs/PIEZA-<nombre>.md (ver template al final)
```

Cualquiera fallando → halt + mensaje exacto + handoff sugerido.

---

## La Innovación: Mapeo de Contexto Just-In-Time

### Anti-pattern (lo que NO hacemos)

```
Recibir Blueprint
    ↓
Generar TODAS las fases + todas las subtareas de cada fase
    ↓
Ejecutar linealmente
```

Las subtareas de Fase 2+ se generan basándose en cómo IMAGINÁS que va a quedar Fase 1 — no en lo que realmente quedó.

### El Yunque (lo que SÍ hacemos)

```
Recibir Blueprint
    ↓
Generar solo FASES (sin subtareas)
    ↓
ENTRAR en Fase N
    ↓
MAPEAR contexto real del codebase + DB + dependencias previas
    ↓
GENERAR subtareas basadas en contexto REAL
    ↓
Ejecutar Fase N (subtarea por subtarea, validando)
    ↓
Verificar fase (R7 layers aplicables)
    ↓
Commit atómico + presentar diff + ESPERAR "continuar a Fase N+1"
    ↓
... repetir hasta cerrar todas las fases ...
    ↓
Three-Layer Verification completa antes de marcar passing (R7)
```

Cada fase se planifica con información real del estado actual, incluyendo lo que se construyó en fases anteriores.

---

## Flujo por Fase

### 1. Anunciar fase

```
Fase N de M — <descripción 1 línea>
Objetivo verificable: <criterio de éxito>
```

### 2. Mapear contexto

ANTES de generar subtareas, explorar (con tools dedicados, no Bash genérico):

**Codebase:**
- `Grep`/`Glob` para archivos relacionados con esta fase.
- `Read` para entender patrones existentes y código reutilizable.
- ¿Qué dejó la Fase N-1 ya construido?

**Base de datos (si aplica):**
- Supabase MCP `list_tables` para ver tablas actuales.
- `execute_sql` para verificar estructura, RLS, funciones existentes.

**Dependencias y restricciones:**
- ¿Hay `.env` keys necesarias? ¿Están presentes?
- ¿Qué imports/libs son nuevos? → invocar `find-docs` para `[docs:libname@version]` (R13).

**Brand DNA (cualquier fase con UI):**
- `Read brand/brand.json` + `voice.json`.
- Si NO existen → halt: *"Brand DNA ausente. Corré /add-ui-kit primero."* (R10).

**Decision Check** — preguntar si hay decisiones de producto/UX/negocio NO resueltas para esta fase. Listar al usuario y pausar antes de generar subtareas si hay ambigüedad.

### 3. Generar subtareas

Solo después de mapear. Subtareas:
- Concretas (incluir paths, nombres de archivo, función signature).
- Atómicas (cada una termina en un commit).
- Ordenadas por dependencias internas de la fase.
- Registradas vía `TodoWrite` para visibilidad.

### 4. Ejecutar subtareas

Una por una:
1. Marcar `in_progress`.
2. Ejecutar (Edit, Write, Bash según corresponda).
3. Validar inmediatamente:
   - **Layer 1 (Syntax):** `make typecheck` o `npm run typecheck` después de cambios de código.
   - **Layer 2 (Runtime):** `make test` si la subtarea toca lógica testeable.
4. Si error → **Auto-Blindaje** (ver sección dedicada). Sin documentar el error en `errors.md`, no avanzar.
5. Si OK → marcar `completed`.
6. **Commit atómico (R2):** `<type>(F<N>-T<n>): <description>` — ej: `feat(F1-T1): create auth service with signUp and signIn`.

### 5. Verificar fase completa

Antes de cerrar la fase:
- Layer 1 (`make typecheck`) exit 0 sobre todos los archivos tocados.
- Layer 2 (`make test`) exit 0 si la fase introduce código testeable.
- Si la fase incluye UI → screenshot con agent-browser CLI o Playwright MCP, comparar visualmente contra `brand.json` (Anti-Slop Gate).

### 6. Actualizar Implementation Notes + presentar diff y esperar

Antes de presentar el diff, actualizar `IMPLEMENTATION-NOTES-<nombre>.html` con lo que surgió en esta fase: decisiones de diseño (donde el spec era ambiguo), desviaciones intencionales del Blueprint, trade-offs considerados, y preguntas abiertas para el usuario. Si no hubo desviaciones ni preguntas, anotar "Sin desviaciones en esta fase" — no inventar entradas. Protocolo: `.claude/references/implementation-notes.md`.

```
✅ Fase N completada — <resumen 1 línea>

Subtareas: N/N completadas
Commits: <count>
Verificación: Layer 1 ✅ · Layer 2 ✅ · UI screenshots OK
Notes: IMPLEMENTATION-NOTES-<nombre>.html actualizado (<X decisiones · Y desviaciones · Z preguntas abiertas>)

Diff preview:
<resumen de archivos tocados>

¿Continuar a Fase N+1: <descripción>? (responder "continuar" o "pausar")
```

**No avanzar sin "continuar".** Si el usuario pide ajustes, aplicar y re-presentar. Si hay **preguntas abiertas** en las notes que bloquean la fase siguiente, listarlas explícitamente en este punto.

### 7. Transición

Al recibir "continuar" → volver al paso 1 con Fase N+1. El contexto a mapear ahora INCLUYE lo construido en Fase N.

---

## Three-Layer Verification (R7) — Pre-Passing

Cuando todas las fases del Blueprint están completas, **antes** de marcar la feature `passing` en `feature_list.json`:

| Layer | Comando | Pass criteria | Quién firma |
|-------|---------|---------------|-------------|
| 1. Syntax | `make typecheck && make lint` | exit 0, sin warnings críticos | el-evaluador |
| 2. Runtime | `make test` | exit 0, todos los tests verdes | el-evaluador |
| 3. System | `make e2e` | happy path verde + visual diff vs `brand.json` verde | el-evaluador |

**No bypass.** Si Layer N falla, Layer N+1 ni se intenta. el-evaluador es el único firmante.

Handoff explícito al cerrar:
```
Build manual completado. Las 3 capas firmadas por el-evaluador:
  Layer 1 (Syntax) ✅
  Layer 2 (Runtime) ✅
  Layer 3 (System) ✅

Feature <ID> marcada como passing en feature_list.json.
Próximo: /web-quality (auditoría pre-deploy) o el-guardian (security audit).
```

---

## Auto-Blindaje

```
Error ocurre
   ↓
Capturar root cause exacto (no descripción genérica)
   ↓
Documentar via el-evaluador en .claude/memory/errors.md (E-NNN)
   ↓
Fix
   ↓
Si recurrente (>2 veces) → el-evaluador lo promueve a:
   - lessons.md (L-NNN), o
   - rule en CONSTRAINTS.md, o
   - check automatizado en hook
   ↓
Próxima sesión NUNCA repite el error
```

**Crítico (R5):** El Yunque NO escribe directo a `memory/`. Si encontrás un error que merece ser documentado, instruir al usuario a invocar `el-evaluador` con el contexto exacto, o el motor mismo dispatcha al sub-agent `el-evaluador` post-fase.

**Tabla de promoción:**

| Tipo de error | Dónde |
|---------------|-------|
| Específico de la PIEZA actual | `.claude/PRPs/PIEZA-<nombre>.md` sección "Aprendizajes" |
| Aplica a múltiples features | `.claude/memory/errors.md` (vía el-evaluador) |
| Aplica universal al harness | promover a regla en `CONSTRAINTS.md` (vía el-evaluador) |

---

## Brand DNA Enforcement (R10)

Cualquier fase que toque UI:

1. `Read brand/brand.json` + `brand/voice.json` ANTES de generar componentes.
2. Aplicar tokens (colors, fonts, radius, spacing) verbatim — NO Tailwind defaults.
3. Posture y archetype del brand son contrato; combinaciones no autorizadas → reject.
4. CTAs y copy desde `voice.cta_examples` y `voice.tone` — NO marketing slop genérico.
5. Post-generación: Anti-Slop Gate (visual diff vs `brand.json`):
   - ✅ Tokens compliance.
   - ❌ Colores blacklisted (#6366F1, #8B5CF6, #A855F7, hue 235-285 sin justificación).
   - ❌ "Claude default": purple-500 + Inter + 3 cards centradas + gradiente diagonal.

Si Anti-Slop Gate falla → regenerate hasta 3 intentos. Si los 3 fallan → halt + handoff a `impeccable` Mode UNKNOWN para derivación R-005 sec 8.2.

---

## Decision Check (en mapeo de contexto)

En cada Fase N, después de mapear codebase + DB, ANTES de generar subtareas:

```
¿Hay decisiones de producto, UX o negocio NO resueltas para esta fase?

Ejemplos:
- ¿El usuario puede editar X o es read-only?
- ¿Los roles son fijos o configurables por el admin?
- ¿Las notificaciones son email, in-app, o ambas?
- ¿El dashboard muestra datos en tiempo real o con refresh manual?
```

**Si hay ambigüedad:** PAUSE — listar las decisiones pendientes al usuario, esperar respuesta antes de continuar.

**Si todo está claro en el Blueprint/PIEZA:** continuar silenciosamente.

Este paso previene re-trabajo por suposiciones implícitas.

---

## Citation Grammar (R8 + R13)

- Web claims: `[web:dominio.com](url-completa)` + sección `## Sources` final.
- Memory: `[memory:lessons#L-001]` / `[memory:errors#E-005]` / `[memory:decisions#D-012]`.
- Docs externos (cualquier import/API/CLI de lib externa): `[docs:libname]` o `[docs:libname@version]` vía `find-docs` (Context7 MCP). Sin citación → automatic reject por `el-evaluador`.

---

## Context Hygiene

| Uso de contexto | Calidad | Acción |
|-----------------|---------|--------|
| 0–30% | PEAK | Trabajar normal |
| 30–50% | BUENA | Considerar delegar fases pesadas a `Agent` tool |
| 50–70% | DEGRADANDO | Usar `Agent` tool para subtareas complejas |
| 70%+ | POBRE | Cerrar fase actual, actualizar `PROGRESS.md`, sugerir nueva sesión con `/avivar` |

Señales de degradación: errores ya resueltos reaparecen, olvidás decisiones tomadas, generás código que contradice lo construido.

Al detectar 70%+: cerrar fase con commit limpio, sintetizar estado en `PROGRESS.md`, decir al usuario:

```
⚠️ Contexto saturado. Cerrá esta sesión y abrí una nueva con /avivar.
Estado guardado en PROGRESS.md. la-forja sería una alternativa que evita esto (sandboxes con contexto fresco por fase).
```

---

## Clean-State Exit (R12)

Al terminar el Blueprint completo:

```
[ ] make build exit 0
[ ] make test exit 0
[ ] PROGRESS.md actualizado con resumen de sesión
[ ] tasks.html regenerado desde feature_list.json
[ ] IMPLEMENTATION-NOTES-<nombre>.html cerrado — preguntas abiertas sin resolver listadas al usuario
[ ] git status clean (o uncommitted changes son WIP intencional documentado)
[ ] Próximo paso definido (en feature_list.json o PROGRESS.md)
[ ] Three-Layer Verification firmada por el-evaluador
```

Si alguno falla → rollback al último estado consistente (`git reset --hard <último commit verde>`). NO commits a medio camino.

### Regenerar el task dashboard

Antes de cerrar la sesión, invocar (vía sub-agent, R4):

→ `.claude/prompts/render-tasks-html.md`
   con `feature_list_path: feature_list.json`

Output: `tasks.html` (sobreescribir). Standalone, dark mode, kanban con KPIs + cards por feature. El humano abre el .html para revisar el board sin parsear el JSON.

Reportar inline: `✅ tasks.html actualizado — {passing}/{total} features passing`.

### Reporte final de cierre

```
Sesión cerrada. Feature <ID>: <state>.
Commits: <count>. Tests: <pass/total>. Layer 3 evidence: <path>.
Dashboard: tasks.html ({passing}/{total} passing).
Próximo paso: <descripción>.
```

---

## Boundaries (qué El Yunque NO hace)

- ❌ El Yunque NO genera componentes UI desde cero — delega a `impeccable` vía sub-agent.
- ❌ NO setup auth manual — delega a `add-login`.
- ❌ NO setup pagos manual — delega a `add-payments`.
- ❌ NO escribe a `memory/` — solo `el-evaluador` (R5).
- ❌ NO ejecuta deploy — `el-guardian` audit primero, después `make deploy` con confirmación humana (R14).
- ❌ NO replaza `la-forja` (modo paralelo con N worktrees) — son alternativos en `/build`.

El Yunque es **el motor**: fases + mapeo + subtareas + verificación + commits. Los **ejecutores** son los skills especializados.

---

## Errores Comunes a Evitar

### ❌ Generar todas las subtareas al inicio

Las subtareas de Fase 2+ basadas en suposiciones de Fase 1 — invariablemente desactualizadas cuando llegás. Solo generá subtareas al ENTRAR en la fase.

### ❌ Saltar el mapeo entre fases

Fase N completa → ir directo a ejecutar Fase N+1 sin re-mapear. El contexto cambió: Fase N construyó archivos, tablas, tipos. Re-mapear es obligatorio.

### ❌ Continuar sin "go" del usuario

El Yunque es manual por definición. Si el usuario no respondió "continuar", no avanzar. Si en duda, preguntar.

### ❌ Verificar solo Layer 1

`make typecheck` pasa pero el código está roto en runtime. Las 3 capas existen para algo (R7). No bypass.

### ❌ Commit gigante de toda la fase

R2: atomic commits. Cada subtarea termina en un commit. `feat(F1-T1):`, `feat(F1-T2):`, etc. — no `feat(F1): all phase 1`.

---

## Template de La Pieza (PIEZA-\<nombre\>.md)

`/build` genera este archivo a partir del Blueprint. El Yunque lo lee como spec ejecutable.

```markdown
# PIEZA — <Nombre de la feature>

> Spec ejecutable de la feature. Generada por /build desde BLUEPRINT-<nombre>.md.

## Identidad
- **Feature ID:** <F1-T1 / mismo que feature_list.json>
- **Branch:** <feature/...>
- **Verification command:** <comando exacto, ej: npm run test:e2e -- google-oauth>
- **Build mode:** SaaS / MVP / Tool / Landing / AI Feature

## Contexto del Blueprint
- **Behavior:** <qué se construye en una frase>
- **Justificación:** <por qué esta feature, link al Blueprint>
- **Dependencias:** <otras features ya passing que esta consume>

## Fases (sin subtareas — se generan al entrar a cada fase)

### Fase 1 — <descripción>
- Objetivo verificable: <criterio>
- Mapeo a hacer al entrar: <qué leer/explorar>
- Estimado: <wallclock>

### Fase 2 — <descripción>
- Objetivo verificable: <criterio>
- Mapeo: <...>
- Depende de: Fase 1 produciendo <X>

<... más fases ...>

## Brand DNA aplicable (R10)
- Componentes UI esperados: <lista>
- Tokens críticos: <colors, fonts, radius>
- Voice context: <cta_examples relevantes>

## Tools/skills delegados durante el build
- Fase con UI → impeccable
- Fase con auth → add-login
- Fase con pagos → add-payments
- Fase con migration → el-migrador
- Pre-deploy → el-guardian + web-quality

## Three-Layer Verification (R7)
- Layer 1: make typecheck && make lint
- Layer 2: make test (specific suite: <...>)
- Layer 3: make e2e (E2E: <happy path script path>) + visual diff vs brand.json

## Aprendizajes (auto-blindaje activo de la feature)

<!-- Errores y fixes específicos de esta feature van acá. el-evaluador escribe. -->
```

---

*"La precisión viene de mapear la realidad, no de imaginar el futuro."*
*"El sistema que se blinda solo es invencible."*
