# detect-state

> Fase 0 de el-crisol. Scan de docs estratégicos existentes en raíz proyecto + `.claude/reports/`. Determina `{nombre}` del proyecto, presenta tabla de estado, pregunta opciones de Perplexity, confirma modo de inicio.

## Inputs

- Raíz del proyecto target (working directory).
- `.claude/reports/` (path opcional pero estándar Forja).
- BLUEPRINT-*.md (PREFLIGHT pasó — Blueprint existe).

## Output

```yaml
detection:
  project_name: <string>          # extraído de BLUEPRINT o consenso entre docs
  blueprint: <path>               # path al BLUEPRINT-{nombre}.md
  
  existing_docs:                  # los que ya existen — Fase 1 los skipea
    - step: brujula
      path: <path>
      detected_in: root | reports
    - step: estrella
      path: <path>
      detected_in: reports
    # ... up to 7 entries
  
  pending_steps:                  # los que faltan — Fase 1 los ejecuta en orden
    - brujula
    - precio
    - lanzamiento
  
  perplexity_available: bool      # si MCP de Perplexity está disponible
  enrichment_opt_in: bool         # decisión del usuario (default false)
  
  start_mode: go | saltar-N | desde-N | solo-dashboard
  estimated_time_min: <number>    # ~25min × pending_steps
```

## Step-by-step

### Paso 1 — Detectar BLUEPRINT y nombre

```bash
# Glob para BLUEPRINT
ls .claude/PRPs/BLUEPRINT-*.md 2>/dev/null

# Si encuentra exactamente 1 → extraer {nombre}
# Si encuentra >1 → usuario tiene múltiples Blueprints, preguntar UNA pregunta cuál usar
# Si encuentra 0 → halt PREFLIGHT (ya cubierto por SKILL.md PREFLIGHT)
```

Extracción: del filename `BLUEPRINT-saas-mvp.md` → `{nombre} = saas-mvp`.

### Paso 2 — Scan de los 7 docs estratégicos

Para cada uno de los 7 patterns, glob en raíz Y en `.claude/reports/`:

| # | Step | Glob raíz | Glob reports |
|---|------|-----------|--------------|
| 1 | brujula | `STRATEGY-CANVAS-*.md` | `.claude/reports/STRATEGY-CANVAS-*.md` |
| 2 | estrella | `NORTH-STAR-*.md` | `.claude/reports/NORTH-STAR-*.md` |
| 3 | rivales | `COMPETITIVE-ANALYSIS-*.md` | `.claude/reports/COMPETITIVE-ANALYSIS-*.md` |
| 4 | precio | `PRICING-STRATEGY-*.md` | `.claude/reports/PRICING-STRATEGY-*.md` |
| 5 | roi | `saas-analysis-*.md` | `.claude/reports/saas-analysis-*.md` |
| 6 | metas | `OKRS-*.md` | `.claude/reports/OKRS-*.md` |
| 7 | lanzamiento | `GTM-STRATEGY-*.md` | `.claude/reports/GTM-STRATEGY-*.md` |

Para cada match:
- Si filename tiene `{nombre}` consistente con BLUEPRINT → marcar `existing_docs`
- Si filename tiene OTRO nombre → reportar al usuario "detecté {OTRO-doc}.md, ¿es del mismo proyecto?"
- Si no hay match → marcar `pending_steps`

### Paso 3 — Determinar start mode

Si NO hay docs existentes (los 7 pending) → **cold start**, default `go` (ejecutar todo).

Si HAY docs existentes (resume parcial) → presentar tabla y preguntar al usuario qué hacer.

Si los 7 docs existen → ofrecer modo `solo dashboard` como default (saltar Fase 1, ir directo a Fase 2).

### Paso 4 — Determinar contexto base

Buscar adicionales que el-crisol puede usar como contexto (no son los 7 pasos pero son útiles):

```bash
ls BLUEPRINT-*.md BMC-*.md PDR-*.md LEAN-CANVAS-*.md TECH-SPEC-*.md 2>/dev/null
```

Reportar al usuario cuáles encontró (informativo, no bloquea).

### Paso 5 — Preguntar Perplexity availability

```
🔍 Perplexity está disponible. ¿Querés enriquecer los análisis con
   investigación de mercado real? (competidores, benchmarks, TAM)
   
   Esto mejora la calidad pero añade ~15-20 min al total.
   
   - "sí" → activar Perplexity en pasos que lo soportan (rivales, precio, lanzamiento)
   - "no" → continuar sin enrichment
```

Recordar la preferencia y pasarla a cada paso de Fase 1 que ofrezca research.

Si Perplexity NO está disponible → no preguntar, continuar sin enrichment.

### Paso 6 — Confirmar inicio

Presentar tabla de estado:

```
🔥 El Crisol — Validación Estratégica

Proyecto: {nombre}
Blueprint: .claude/PRPs/BLUEPRINT-{nombre}.md

  #  Análisis       Qué produce                       Estado
  1  Brujula        Vision + posicionamiento          ✅ ya existe / ⬜ pendiente
  2  Estrella       North Star Metric                 ✅ / ⬜
  3  Rivales        Landscape competitivo             ✅ / ⬜
  4  Precio         Modelo de monetización            ✅ / ⬜
  5  ROI            Unit economics + proyecciones     ✅ / ⬜
  6  Metas          OKRs + Outcome Roadmap            ✅ / ⬜
  7  Lanzamiento    Go-to-Market strategy             ✅ / ⬜
  ─────────────────────────────────────────────────────────
  Final  Dashboard   Panel ejecutivo consolidado       ⬜

  Pendientes: {N} de 7  ·  Tiempo estimado: ~{N × 25}min
  Existentes: {M} de 7  (se reutilizan)
  Perplexity: {sí/no/no disponible}
```

Y preguntar:

```
Arrancamos? Podés:
  - "go"            → Ejecutar todo lo pendiente en orden
  - "saltar N"      → Saltar un paso específico (N = 1..7)
  - "desde N"       → Empezar desde un paso concreto
  - "solo dashboard" → Generar dashboard con los docs que existen
```

## Edge cases

### Edge: BLUEPRINT ambiguo (>1 match)

→ Listar los Blueprints encontrados con timestamps + preguntar cuál usar. NO la-forja-style force-pick — humano confirma.

### Edge: Docs existentes con nombre {OTRO} distinto al BLUEPRINT

→ Reportar al usuario: "Detecté STRATEGY-CANVAS-{OTRO}.md (no coincide con BLUEPRINT-{nombre}). ¿Es del mismo proyecto bajo otro alias, o de un proyecto distinto?". Si distinto → ignorar; si mismo → renombrar o usar bajo override.

### Edge: 7 docs existen pero algunos están desactualizados

→ Detección no valida freshness. Reportar al usuario la fecha de modificación de cada doc + ofrecer override "re-generar paso N aunque exista". Default conservador: usar lo existente.

### Edge: Cold start (0 docs)

→ Default `go`. Tiempo estimado: ~175min (7 × 25min) sin Perplexity, ~250min con. Reportar y pedir confirmación antes de arrancar pipeline largo.

### Edge: Perplexity disponible pero quota bajo

→ MCP responde con error de quota. Continuar sin enrichment + reportar al usuario.

### Edge: nombre indeterminable (sin BLUEPRINT y sin docs)

→ Esta situación NO debería pasar (PREFLIGHT halt si no hay BLUEPRINT). Si pasa → preguntar UNA pregunta al usuario. Si no responde → halt.

## R4/R5 enforcement

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

`detect-state.md` es lectura + análisis + presentación de tabla. NO Edit/Write a archivos de aplicación. NO invoca skills directo.

> [memory:CONSTRAINTS.md#R5] — Workers no escriben a memory.

Detección NO escribe a memory store. Outputs van a stdout (presentación al usuario) y a la "memoria de sesión" del orchestrator (estructura YAML interna).

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — el-crisol thin durante detección.
- [memory:CONSTRAINTS.md#R5] — workers no escriben memory.
- [memory:decisions#D-014] — pipeline shape vs selector shape (informativo si usuario pregunta por qué no hay default+override).

## Refusals

- ❌ Force-pick BLUEPRINT si hay >1 (humano decide).
- ❌ Asumir que docs con nombre distinto son del mismo proyecto (puede causar mezcla cross-proyecto).
- ❌ Saltar Paso 5 (Perplexity) por "obvio" — la opt-in del usuario es importante para auditoría posterior.
- ❌ Iniciar Fase 1 sin confirmation explícita del usuario sobre `start_mode`.
