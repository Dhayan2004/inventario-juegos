# Fork pattern — referencia (PATTERN PRINCIPAL)

> Paralelización con git worktrees. **Default de la-forja.** N=2-5 sandboxes con personality variants; cherry-pick lo mejor cross-worktree.

## Cuándo usar

- Blueprint con 2-5 features independientes paralelizables sin dependencias mandatorias.
- Exploración de approaches alternativos para una sola feature (literal vs creativo vs disruptivo).
- Usuario explícitamente pidió "modo forja", "agentes paralelos", "explorá N approaches".

## Cuándo NO usar

- N=1 (no paraleliza — degradar a Swarm o ejecutar en main).
- N>5 (satura disco/RAM + cherry-pick conflicts super-lineales).
- Blueprint con dependencias secuenciales fuertes → Coordinator.
- Disco libre <N×2GB → degradar o reducir N.

## Sweet spot N=2-5

Validación empírica de Forge legacy v3.3:

| N | Wallclock vs Coordinator | Cherry-pick complexity | Sweet spot |
|---|-------------------------|------------------------|-----------|
| 1 | igual | trivial | NO — degenerate, no paraleliza |
| 2 | 1.7-2× faster | bajo (compare 2) | ✅ |
| 3 | 2.4-2.8× faster | medio (compare 3, default) | ✅ DEFAULT |
| 4 | 2.8-3.4× faster | medio-alto | ✅ |
| 5 | 3.0-3.8× faster | alto (5 worktrees compare) | ✅ pero límite |
| 6+ | retornos decrecientes | conflicts super-lineal | ❌ — reducir o Coordinator |

Dependiente del recurso (CPU/RAM/disco), pero patrón canónico.

## Personalidades por N

Asignación canónica (ordenada de strict-fidelity → exploration):

### N=2

| Sandbox | Variant | Prioridad |
|---------|---------|-----------|
| 1 | **Literal** | Apego estricto al Blueprint, sin desviaciones |
| 2 | **Creativo** | Mejora pragmática moderada (UX, patterns) |

### N=3 (DEFAULT)

| Sandbox | Variant | Prioridad |
|---------|---------|-----------|
| 1 | **Literal** | Apego estricto |
| 2 | **Creativo** | Mejora pragmática |
| 3 | **Disruptivo** | Innovación arquitectónica, libertad total en CÓMO |

### N=4

| Sandbox | Variant | Prioridad |
|---------|---------|-----------|
| 1 | **Literal** | Apego estricto |
| 2 | **Quality** | TDD-first, cobertura tests exhaustiva |
| 3 | **Creativo** | Mejora pragmática |
| 4 | **Disruptivo** | Innovación arquitectónica |

### N=5

| Sandbox | Variant | Prioridad |
|---------|---------|-----------|
| 1 | **Literal** | Apego estricto |
| 2 | **Speed** | Velocidad, implementación directa |
| 3 | **Quality** | TDD-first |
| 4 | **Creativo** | Mejora pragmática |
| 5 | **Disruptivo** | Innovación arquitectónica |

## Personality system prompts (verbatim)

Inyectados en cada sub-agent:

### Literal
```
Tu prioridad es FIDELIDAD AL PLAN. Implementá exactamente lo que dice el
Blueprint sin desviaciones. NO agregues features, patterns, ni abstracciones
que no estén explícitamente en el plan. Si hay ambigüedad, elegí la
interpretación más simple y directa. Tu valor es producir exactamente lo
que se planeó — el baseline confiable contra el que se comparan los demás.
```

### Speed
```
Tu prioridad es VELOCIDAD. Implementá cada fase de la forma más directa y
eficiente posible. Evitá sobre-ingeniería. Si el Blueprint pide CRUD, hacé
CRUD simple que funcione, no pattern repository con abstracciones. Tu
valor es producir resultado rápido para validar que el Blueprint funciona.
```

### Quality
```
Tu prioridad es CALIDAD y COBERTURA DE TESTS. Cada feature debe tener
tests exhaustivos. TDD: escribí los tests PRIMERO, luego implementá hasta
que pasen. Agregá tests de edge cases, error handling, happy paths. Tu
valor es producir código con alta confianza de que funciona correctamente.
```

### Creativo
```
Tu prioridad es MEJORA PRAGMÁTICA. Seguí el Blueprint pero tomá libertades
moderadas para mejorar la implementación: mejores patterns, mejor UX,
abstracciones útiles que el Blueprint no consideró pero que hacen el código
más mantenible. Documentá cada mejora en MEJORAS.md explicando qué
cambiaste y por qué. Tu valor es producir una versión mejorada del plan.
```

### Disruptivo
```
Tu prioridad es INNOVACIÓN ARQUITECTÓNICA. Usá el Blueprint como guía de
QUÉ construir, pero tomá libertad total en CÓMO. Experimentá con patterns
diferentes, estructuras alternativas, libraries que el Blueprint no
consideró. Antes de implementar cada fase, documentá tu approach
alternativo en ARQUITECTURA.md. Tu valor es descubrir approaches superiores
que no se consideraron en la planeación.
```

## Cherry-pick decision matrix

Después de que los N workers terminan, la-forja produce recomendación con esta heurística:

| Aspecto | Worktree preferido (default) | Override si... |
|---------|------------------------------|----------------|
| Setup base, infra, scaffolding | Literal | Creativo aporta cleanup obvio |
| Lógica core (auth flow, checkout flow) | Creativo (mejor UX/patterns) | Literal si Creativo introdujo bugs sutiles |
| Tests, edge cases | Quality (si N≥4) o Creativo | — |
| Patterns nuevos, refactor estructural | Disruptivo | Pero solo si pasa el-evaluador R7 sin gaps |
| Copy, styling | Creativo | — |
| Performance optimizations | Speed (si N=5) o Disruptivo | Si Disruptivo agrega complexity sin benchmark |

Heurísticas, no reglas. Cherry-pick es decisión humana con la-forja recomendando.

## Output structure por worktree

Cada worker debe producir en su sandbox:

| Archivo | Quién | Qué |
|---------|-------|-----|
| Commits | worker | trabajo aplicado, atomic per R2 |
| `RESUMEN.md` | worker (mandatory) | qué hizo cada fase, decisiones tomadas |
| `MEJORAS.md` | Creativo only | mejoras pragmáticas con rationale |
| `ARQUITECTURA.md` | Disruptivo only | approach alternativo + rationale |
| `PROBLEMAS.md` | worker (si aplica) | bloqueos encontrados, decisions deferred |
| `.worktrees/sandbox-N/` | la-forja inicializa | path del worktree |

la-forja recolecta los archivos al cierre + `git log <branch>` para producir cherry-pick recommendation.

## Ventajas

- **Wallclock 2-5× más rápido** que Coordinator para Blueprints paralelizables.
- **Exploración:** comparás N approaches para una misma feature, no estás casado con la primera solución.
- **Fail-isolation:** un worker que se atora no bloquea los demás.
- **Cherry-pick + variant insights:** mantenés mejoras de Creativo/Disruptivo que el Blueprint no anticipó.

## Desventajas

- **Disco:** N×2GB típico por worktree (Next.js con node_modules infla rápido).
- **RAM:** N×3GB durante ejecución (+ Supabase Docker si usado).
- **Cherry-pick complexity:** N≥4 conflicts comienzan a sumar overhead de resolución.
- **Coherencia post-merge:** el merged result puede tener "personality drift" si cherry-pick mezcla aproachs incompatibles.

## Mitigations

- **Disco:** PREFLIGHT chequea `df -k` con margen N×2GB. Si fail, sugerir N reducido o Coordinator.
- **RAM:** documentar requirement en advertencia. Sugerir reducir N si <16GB total.
- **Cherry-pick complexity:** tabla de orden recomendado (Literal baseline → +Creativo/Quality → ?Disruptivo case-by-case).
- **Coherencia:** el-evaluador post-merge corre R7 three-layer; si gaps, mini-Swarm para fixear.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja Bash limitado a git worktree ops; workers escriben en sus worktrees.
- [memory:CONSTRAINTS.md#R5] — workers no escriben a `.claude/memory/*`.
- [memory:CONSTRAINTS.md#R6] — registry validation antes de lanzar cada worker.
- [memory:CONSTRAINTS.md#R13] — find-docs antes de generar git worktree commands.
- [memory:lessons#L-004] — Fork es default del binary pattern selector.
- [memory:decisions#D-013] — la-forja confirma binary cross-skill.
- [docs:git] — git worktree commands canónicos.

## Anti-patterns

- ❌ Fork con N=1 (degenerate).
- ❌ Fork con N>5 (saturación).
- ❌ Cherry-pick automático sin confirmation humana.
- ❌ Force-fit Fork a Blueprint con dependencias secuenciales (anti-pattern del pattern selector).
- ❌ Workers tocan archivos cross-worktree (rompe aislamiento).
- ❌ Workers escriben a memory (R5 violation).
- ❌ la-forja MISMA hace cherry-pick sin pasar por confirmation humana (cobardía con la confirmation = riesgo).
