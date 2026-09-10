# Swarm pattern — referencia

> Workers tool-filtered para one-shot atómico. Researcher + Implementer + Reviewer con tool filter estricto. Use case: task <30min con sub-tasks bien definidos.

## Cuándo usar

- 1 sub-task atómico bien definido (<30min, 1-3 archivos típicamente).
- Fork es overkill (no necesitamos exploración paralela; hay 1 solución correcta).
- Coordinator es overkill (no hay dependencias secuenciales múltiples).
- Delegación a el-tajo (atómico <5min) o el-golpe (mediano <30min) — ambos usan Swarm internamente.

## Cuándo NO usar

- Task no atómico (>30min, >3 archivos) → Fork o /build.
- Múltiples sub-decisiones independientes paralelizables → Fork.
- Dependencias secuenciales → Coordinator.

## Shape canónico

```
[la-forja] Validate registry: el-tajo|el-golpe|el-evaluador|find-docs (R6)
   ↓
[la-forja] Setup 3 workers con tool filter explícito
   ↓
   ├── Researcher (Read+Grep+Glob+WebFetch) ─→ "approach + paths + riesgos"
   │              ↓ output a la-forja
   │              ↓ la-forja synthesis
   │              ↓
   ├── Implementer (Read+Write+Edit+Bash)   ─→ "diff aplicado + tests passing"
   │              ↓ output a la-forja
   │              ↓ la-forja synthesis
   │              ↓
   └── Reviewer (Read+Grep + el-evaluador)  ─→ "PASS o NEEDS_FIX <gap>"
                  ↓ output a la-forja
                  ↓
                  PASS → handoff-evaluador (post-orchestration record)
                  NEEDS_FIX → loop a Implementer (max 2 retries)
```

## 3 roles, 3 tool filters

| Role | Tool filter | Responsabilidad |
|------|-------------|-----------------|
| **Researcher** | `Read · Grep · Glob · WebFetch` + skill `find-docs` | Investigar contexto, buscar patrones existentes, documentar approach. NO escribe código. |
| **Implementer** | `Read · Write · Edit · Bash` | Ejecutar el cambio: Edit archivos, run tests, verificar build. NO valida solo. |
| **Reviewer** | `Read · Grep` + skill `el-evaluador` | Validar output. R7 three-layer inline. PASS o NEEDS_FIX. |

Detalle exhaustivo en `prompts/tool-filter-workers.md`.

## Forma A — Swarm directo

la-forja lanza Researcher + Implementer + Reviewer manualmente. Útil cuando el sub-task no encaja en el-tajo/el-golpe (ej: refactor cruzando módulos no-encapsulados).

## Forma B — Delegación a el-tajo / el-golpe

la-forja invoca el-tajo (atómico <5min, <500 LOC, 1-3 archivos) o el-golpe (mediano <30min, multi-archivo). Estos skills usan Swarm internamente con su propia configuración. la-forja MISMA NO invoca directo (R4) — un sub-agent dispatchador hace la invocación.

**Forma B es preferida cuando aplica** — el-tajo/el-golpe ya tienen Swarm pattern probado y configurado.

## Ejemplo concreto — Forma A

Task: "Agregá tracking analytics a /pricing usando el SDK existente."

```
[la-forja] PREFLIGHT pasa, registry valida (R6)
   ↓
[Researcher]
   ├── Grep para "PostHog|track(|analytics" en codebase
   ├── Lee lib/analytics/posthog.ts (SDK existente detectado)
   ├── Lee app/(marketing)/pricing/page.tsx
   └── Reporta: "patrón existente: import { track } from '@/lib/analytics/posthog'.
                 Páginas similares (landing, blog) usan track('cta_clicked', { source }).
                 Approach: agregar onClick handlers a los CTAs de pricing/page.tsx
                 con event 'pricing_cta_clicked'. 1 archivo modificado.
                 Riesgos: posthog ya inicializado en root layout, no re-init."
   ↓
[la-forja] synthesis → prompt Implementer
   ↓
[Implementer]
   ├── Read app/(marketing)/pricing/page.tsx
   ├── Edit: import + onClick handlers en 2 CTAs (free, pro)
   ├── Run: npm run typecheck → PASS
   ├── Run: npm run test:e2e:pricing → PASS
   └── Reporta: "diff: app/(marketing)/pricing/page.tsx (+8 LOC).
                 Tests: typecheck + e2e:pricing PASS."
   ↓
[la-forja] synthesis → prompt Reviewer
   ↓
[Reviewer]
   ├── Read del diff
   ├── Grep: ningún hardcoded 'pricing_cta_clicked' fuera del cambio (sin duplicación)
   ├── Invoca el-evaluador (R7 three-layer):
   │     L1 syntax: PASS
   │     L2 runtime: PASS
   │     L3 system: PASS (e2e:pricing valida tracking event)
   └── Reporta: "PASS"
   ↓
[handoff-evaluador]  ← R7 ya corrió, el-evaluador confirma + memory promotion (probablemente nada)
   ↓
[la-forja] feature passing
```

Total wallclock: ~5min (probable cualquier degradación: el-tajo Forma B reduciría a <2min con sus Swarm internals optimizados).

## Ejemplo Forma B — Delegación a el-golpe

Task: "Implementar dashboard admin con 4 KPI cards (users, MRR, churn, signups-this-week)."

```
[la-forja] PREFLIGHT pasa, registry valida (R6 — el-golpe existe)
   ↓
[Sub-agent dispatcher]
   ├── Invoca el-golpe con context del active feature
   └── el-golpe internamente usa Swarm:
       ├── Researcher: lee schema, identifica queries necesarias, encuentra patrón "Card" de impeccable
       ├── Implementer: genera app/(admin)/dashboard/page.tsx + lib/queries/admin-stats.ts + tests
       └── Reviewer: invoca el-evaluador (R7) → PASS
   ↓
[el-golpe → la-forja] PASS + handoff
   ↓
[handoff-evaluador]
   ↓
[la-forja] feature passing
```

la-forja MISMA NO invocó el-golpe — el sub-agent dispatcher hizo la invocación. R4 enforced.

## Ventajas

- **Tool filter estricto = blast radius mínimo.** Lección Vercel: -80% tools = +3× rendimiento.
- **Researcher independent del Implementer:** mejor approach analysis sin sesgo de "ya tengo que escribir código".
- **Reviewer independent del Implementer:** AP3 evitado, el-evaluador autoritativo.
- **Atómico = predecible:** wallclock típico 2-15min, sin orchestration overhead.

## Desventajas

- **No paraleliza alternativas:** una sola solución, no exploración (eso es Fork).
- **Overkill para tareas truly trivial** (<2min, <50 LOC): el-tajo directo sin la-forja envolvente es más simple.
- **Delegación cross-skill** (Forma B) require que el-tajo/el-golpe estén bien configurados — si fallan en R6, fallback a Forma A.

## Sweet spot

- Sub-task atómico bien definido (<30min, 1-3 archivos).
- Approach NO obvio (Researcher aporta valor — si approach es trivial, el-tajo solo basta).
- Verification command claro y rápido (Reviewer puede correr R7 en <2min).

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO invoca skills; workers invocan dentro de su rol filtrado.
- [memory:CONSTRAINTS.md#R5] — workers no escriben memory.
- [memory:CONSTRAINTS.md#R6] — registry validation pre-Swarm.
- [memory:CONSTRAINTS.md#R7] — Reviewer corre R7 inline, el-evaluador valida.
- [memory:CONSTRAINTS.md#AP3] — self-eval prohibido (Reviewer separate del Implementer).
- [memory:lessons#L-004] — Swarm es override del binary pattern selector.
- [memory:decisions#D-013] — la-forja sexta validación binary.

## Anti-patterns

- ❌ Researcher escribe código (rompe tool filter).
- ❌ Implementer auto-valida (AP3 + R4 violation).
- ❌ Reviewer ejecuta nuevos cambios (rompe role).
- ❌ Mix de tool filter cross-role "por practicidad" — la rigidez ES la garantía.
- ❌ NEEDS_FIX loop infinito sin halt (max 2 retries).
- ❌ Swarm para task no atómico (force-fit anti-pattern).
