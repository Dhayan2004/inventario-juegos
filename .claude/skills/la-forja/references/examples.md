# Examples — 3 escenarios canónicos

> Uno por pattern. Cada escenario muestra Blueprint input → pattern selector → orchestration → handoff. Los outputs son ilustrativos.

## Escenario 1 — Coordinator pattern

### Input

Blueprint del usuario `.claude/PRPs/BLUEPRINT-saas-mvp.md`:

```yaml
features:
  - F1: setup auth con Supabase (lib/supabase, middleware, 4 auth pages, profiles SQL)
  - F2: integrar Stripe (depende de F1 — subscriptions.user_id FK profiles)
  - F3: emails transaccionales (depende de F1 + F2 — auth events + checkout events disparan emails)
```

Active feature: F2 (assume user pickeó la chain completa).

### Pattern selector

```yaml
pattern: coordinator
rationale: |
  Blueprint con 3 fases en grafo lineal: F1 → F2 → F3. F2 consume profiles
  schema generado por F1; F3 consume auth+checkout events. NO paralelizable
  sin perder coherencia. L-004 test: NO degenerate case requiere upstream
  user action — default Fork no aplica por dependencias secuenciales.
sub_agents_planned: 3 (uno por fase, secuencial)
risk_flags: []
fallback_path: el-yunque manual si Coordinator se atora
```

### Orchestration

```
[Fase 1 — add-login Mode A]
  Sub-agent invoca find-docs → genera lib/supabase, middleware, 4 pages, profiles SQL
  Output: 24 archivos modificados, RESUMEN: profiles.user_id UUID, RLS L-001 enforced
   ↓
[Synthesis Fase 1]
  - profiles.user_id es UUID
  - middleware en /app y /api con SSR helpers
  - voice.json copy aplicado
   ↓
[Fase 2 — add-payments Mode A]
  Sub-agent recibe synthesis Fase 1 como context
  Invoca find-docs → genera lib/stripe, webhook con signature verify, /pricing /checkout /success, subscriptions SQL
  Output: 13 archivos, RESUMEN: subscriptions.user_id FK profiles, R14 strict en refund/cancel
   ↓
[Synthesis Fase 2]
  - subscriptions schema con RLS L-001
  - Stripe webhook idempotency
  - pricing page consume voice.cta_examples
   ↓
[Fase 3 — add-emails Mode A]
  Sub-agent recibe synthesis acumulada Fases 1+2
  Invoca find-docs → genera 7 React Email components, send route, suppression-webhook
  Output: 15 archivos, RESUMEN: triggers welcome (post auth), invoice-receipt (post checkout)
   ↓
[Synthesis final acumulada]
   ↓
[handoff-evaluador]
   ├── el-evaluador R7 three-layer: PASS
   └── Memory: 0 nuevas lessons (patrones ya documentados)
   ↓
[la-forja] feature passing
```

Wallclock total: ~45-60min (3 fases secuenciales con find-docs invocations).

### Anti-pattern observable: forzar Fork

Si la-forja hubiera elegido Fork con N=3 (un sandbox por feature):
- Sandbox-2 (payments) intentaría generar `subscriptions.user_id FK profiles.id` SIN saber el shape exacto que Sandbox-1 (auth) produjo.
- Sandbox-3 (emails) referenciaría event types de Stripe que Sandbox-2 aún no implementó.
- Cherry-pick post-merge encontraría conflictos en migrations + import paths.
- Output mergeado probablemente roto en cohesión.

Force-fit Fork era la trampa. Coordinator es el path correcto.

## Escenario 2 — Fork pattern (PATTERN PRINCIPAL)

### Input

Blueprint `.claude/PRPs/BLUEPRINT-landing-redesign.md`:

```yaml
features:
  - F1: rediseñar /landing con hero + features + pricing + footer
  - exploración: 3 approaches alternativos (literal vs creativo vs disruptivo)
```

Active feature: F1.

### Pattern selector

```yaml
pattern: fork
rationale: |
  Blueprint pide explícitamente exploración de 3 approaches alternativos
  para una sola feature. Default Fork con N=3 + personality variants es
  el path canónico. L-004 test: NO degenerate case — los 3 patterns
  siempre disponibles [memory:lessons#L-004]. la-forja sexta validación
  binary cross-skill [memory:decisions#D-013].
sub_agents_planned: 3
personality_variants: [literal, creativo, disruptivo]
risk_flags: ["disco ~6GB requerido para 3 worktrees"]
fallback_path: coordinator si disco bajo persiste
```

### Orchestration

```
[la-forja PREFLIGHT]
  ├── Blueprint OK, active feature F1, skills.md valida
  ├── git --version 2.42.0 ≥ 2.5 OK
  └── df -k .worktrees → 12GB libre, OK para N=3
   ↓
[manage-worktrees setup]
  ├── git worktree add .worktrees/sandbox-1 -b la-forja/sandbox-1-literal
  ├── git worktree add .worktrees/sandbox-2 -b la-forja/sandbox-2-creativo
  └── git worktree add .worktrees/sandbox-3 -b la-forja/sandbox-3-disruptivo
   ↓
[Workers en paralelo]
  Sandbox 1 (literal):
    - Implementa exactamente lo que dice el Blueprint
    - 4 commits: hero+features+pricing+footer
    - RESUMEN: "Implementación fiel. Spacing y copy del Blueprint sin cambios."
  
  Sandbox 2 (creativo):
    - Mejoras pragmáticas: bento grid en features, pricing con toggle anual/mensual
    - 5 commits + MEJORAS.md
    - MEJORAS: "bento grid mejora densidad info; toggle reduce friction de elección anual"
  
  Sandbox 3 (disruptivo):
    - Approach radical: hero scrolly-telling con interactive demo, pricing como configurador
    - 6 commits + ARQUITECTURA.md
    - ARQUITECTURA: "scrolly-telling vs static hero — riesgo: cognitive load, beneficio: engagement"
   ↓
[Recolección de outputs]
  - 3 RESUMEN.md leídos
  - git log de cada branch
   ↓
[Cherry-pick recomendación]
  
  | Sección | Worktree ganador | Commits | Razón |
  |---------|------------------|---------|-------|
  | Hero | Literal (sandbox-1) | abc123 | Limpio, sin scrolly experimental |
  | Features | Creativo (sandbox-2) | def456 | Bento grid mejora información density |
  | Pricing | Creativo (sandbox-2) | ghi789 | Toggle anual/mensual reduce friction |
  | Footer | Literal (sandbox-1) | jkl012 | Sin necesidad de variation |
  
  Conflictos anticipados:
  - app/(marketing)/landing/page.tsx entre sandbox-1 y sandbox-2 (ambos modificaron)
    Resolver: cherry-pick orden Literal → +Creativo, conflicto manual en imports
  
  Disruptivo descartado:
  - scrolly-telling agrega complexity (300 LOC + framer-motion dep) sin benchmark de engagement
  - Recomendar: NO adoptar en este feature, considerar para landing v2 con A/B test
   ↓
[Humano confirma cherry-pick]
   ↓
[la-forja ejecuta cherry-pick]
  git checkout feature/landing-redesign
  git cherry-pick abc123                    # Sandbox-1 hero
  git cherry-pick def456 ghi789             # Sandbox-2 features+pricing (resolver conflicto)
  git cherry-pick jkl012                    # Sandbox-1 footer
   ↓
[Cleanup]
  git worktree remove .worktrees/sandbox-{1,2,3}
  git branch -D la-forja/sandbox-{1,2,3}-*
  git worktree prune
   ↓
[handoff-evaluador]
  - el-evaluador R7: PASS
  - Brand Score: 87/100 (target ≥75)
   ↓
[la-forja] feature passing
```

Wallclock total: ~25min wallclock (3 sandboxes en paralelo) vs ~70min Coordinator equivalente — **2.8× más rápido**.

### Insight Disruptivo descartado pero documentado

ARQUITECTURA.md de Sandbox-3 queda en branch (NO se borra `la-forja/sandbox-3-disruptivo` por si emerge ROI futuro). Documentado en cherry-pick recommendation: "Disruptivo descartado en este sprint, considerar para landing v2 con A/B test."

## Escenario 3 — Swarm pattern

### Input

Active feature: F2-add-tracking-to-pricing.

Task description: "Agregá tracking analytics a /pricing usando el SDK PostHog ya integrado, eventos `pricing_cta_clicked` con source distinguishing free/pro tiers."

### Pattern selector

```yaml
pattern: swarm
rationale: |
  Task atómico bien definido (1 archivo modificado, <15min, sin dependencias
  arquitectónicas). Fork overkill (no necesitamos exploración paralela —
  approach es obvio). Coordinator overkill (no hay dependencias secuenciales).
  Forma B: delegar a el-tajo (atómico <5min) o el-golpe (mediano <30min).
  Estimación inicial: el-golpe (multi-archivo posible si hay tests).
  L-004 test: NO degenerate case requiere upstream action.
sub_agents_planned: 3 (Researcher + Implementer + Reviewer via el-golpe Swarm interno)
risk_flags: []
fallback_path: Forma A (Swarm directo) si el-golpe R6 falla
```

### Orchestration

```
[la-forja PREFLIGHT]
  - Active feature OK
  - Skills.md valida el-golpe + el-evaluador + find-docs
   ↓
[Sub-agent dispatcher invoca el-golpe]
  el-golpe internamente usa Swarm:
  
  [Researcher]
    - Grep "PostHog|track\\(|@/lib/analytics" en codebase
    - Lee lib/analytics/posthog.ts (SDK detectado)
    - Lee app/(marketing)/pricing/page.tsx
    - Reporta: "patrón existente: track(event, payload). Páginas similares
       usan track('cta_clicked', { source }). Approach: onClick handlers en
       2 CTAs (free + pro) con event 'pricing_cta_clicked' + source distinct.
       1 archivo modificado, 8 LOC delta. Riesgos: posthog ya init en root."
   ↓
  [Implementer]
    - Read app/(marketing)/pricing/page.tsx
    - Edit: import + 2 onClick handlers
    - Run npm run typecheck → PASS
    - Run npm run test:e2e:pricing → PASS (existing test cubre tracking)
    - Reporta: "diff aplicado, +8 LOC, tests PASS."
   ↓
  [Reviewer]
    - Read del diff
    - Grep ningún hardcoded 'pricing_cta_clicked' fuera del cambio
    - Invoca el-evaluador (R7 three-layer):
      L1 syntax: PASS
      L2 runtime: PASS  
      L3 system: PASS (e2e:pricing valida event tracked)
    - Reporta: "PASS"
   ↓
[el-golpe → la-forja] PASS
   ↓
[handoff-evaluador]
  - el-evaluador post-orchestration confirma PASS (R7 ya corrió inline)
  - Memory: 0 nuevas lessons (patrón estándar)
   ↓
[la-forja] feature passing
```

Wallclock total: ~5-8min (Swarm Forma B vía el-golpe es el path optimizado).

### Anti-pattern observable: Fork forzado

Si la-forja hubiera elegido Fork con N=3:
- 3 worktrees con la misma task atómica → cherry-pick trivial pero overhead de setup (3 npm install) > beneficio de exploración (no hay alternativas reales).
- Wallclock: ~15min Fork vs ~6min Swarm.
- Conclusion: Swarm correcto. Fork era over-engineering.

## Tabla resumen de los 3 escenarios

| Escenario | Input shape | Pattern | N sub-agents | Wallclock | Cherry-pick? |
|-----------|-------------|---------|--------------|-----------|--------------|
| 1 — saas-mvp | Blueprint con dependencias secuenciales | Coordinator | 3 fases secuenciales | ~45-60min | No |
| 2 — landing-redesign | Blueprint con exploración 3 approaches | Fork | 3 worktrees paralelos | ~25min | Sí (con confirmation) |
| 3 — pricing-tracking | Task atómico 1 archivo | Swarm (Forma B) | 3 workers el-golpe | ~5-8min | No |

## Anti-pattern global: pattern force-fit

NO force-fit pattern por preferencia personal. El selector empírico (decision tree en `prompts/select-pattern.md`):

```
¿1 sub-task atómico bien definido? → Swarm
¿Dependencias secuenciales fuertes? → Coordinator
¿2-5 features independientes paralelizables? → Fork (DEFAULT)
```

Si dudás entre Fork y Coordinator: Fork (default). Si Fork emerge problemas, degradación graceful a Coordinator. Esto es la línea L-004 binary.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO escribe código, sub-agents lo hacen.
- [memory:CONSTRAINTS.md#R5] — workers no escriben memory.
- [memory:CONSTRAINTS.md#R6] — registry validation antes de cada dispatch.
- [memory:CONSTRAINTS.md#R7] — three-layer post-orchestration mandatory.
- [memory:lessons#L-004] — pattern selector binary aplicado.
- [memory:decisions#D-013] — la-forja sexta validación binary cross-skill.
