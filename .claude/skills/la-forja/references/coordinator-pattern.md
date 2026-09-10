# Coordinator pattern — referencia

> Sequential synthesis para sesiones largas con dependencias entre fases.

## Cuándo usar

- Blueprint con grafo lineal o casi-lineal: fase N+1 NO arranca sin output de fase N.
- Sesión larga con múltiples skills que se invocan en secuencia (la-herreria → el-crisol → la-forja, o impeccable BATCH → add-login → add-payments).
- Fork no es viable: disco bajo, conflictos circulares persistentes, target sin git worktree disponible, o el usuario explícitamente prefiere ejecución secuencial visible.

## Cuándo NO usar

- Blueprint con features independientes paralelizables → Fork (default).
- Task atómico one-shot → Swarm.
- Loop iterativo con feedback humano → sprint (no la-forja).

## Shape canónico

```
fase 1 → output 1
            ↓
   [synthesis: lo que fase 2 necesita de fase 1]
            ↓
fase 2 → output 2 consumiendo output 1
            ↓
   [synthesis: lo que fase 3 necesita de fases 1+2]
            ↓
fase 3 → output 3 consumiendo outputs 1+2
            ↓
...
            ↓
   [synthesis final acumulada]
            ↓
handoff a el-evaluador (R7 three-layer)
```

## Ejemplo concreto — Blueprint full-stack auth + payments + emails

Blueprint del usuario:

```yaml
features:
  - id: F1: setup auth con Supabase
  - id: F2: integrar Stripe payments (consume F1 — necesita user_id de auth)
  - id: F3: emails transaccionales (consume F1 + F2 — necesita auth + checkout events)
```

la-forja Coordinator flow:

```
[la-forja] PREFLIGHT pasa
   ↓
[la-forja] select-pattern: Coordinator (dependencias secuenciales fuertes)
   ↓
[la-forja] Validate registry: add-login, add-payments, add-emails, find-docs, impeccable, add-ui-kit
   ↓
[Fase 1 — Auth setup]
   ├── Sub-agent dispatched (skill: add-login Mode A)
   ├── Sub-agent invoca find-docs → add-login → genera lib/supabase, middleware, 4 auth pages, profiles SQL
   └── Output a la-forja: paths modificados + RESUMEN de decisiones
   ↓
[la-forja] Synthesis Fase 1:
   - profiles.user_id es UUID
   - middleware aplica en /app y /api
   - voice.json copy aplicado en pages
   ↓
[Fase 2 — Payments]
   ├── Sub-agent (skill: add-payments Mode A — Stripe)
   ├── Recibe context de Fase 1 synthesis (necesita profiles.user_id en subscriptions table)
   ├── Sub-agent invoca find-docs → add-payments → genera lib/stripe, webhook, /pricing, /checkout, subscriptions SQL
   └── Output a la-forja
   ↓
[la-forja] Synthesis Fase 2:
   - subscriptions.user_id FK a profiles
   - webhook signature validated
   - voice.json CTAs aplicados
   ↓
[Fase 3 — Emails]
   ├── Sub-agent (skill: add-emails Mode A — Resend)
   ├── Recibe context de Fases 1+2 (auth events + checkout events triggers de email)
   ├── Sub-agent invoca find-docs → add-emails → genera lib/resend, 7 React Email components, send route
   └── Output a la-forja
   ↓
[la-forja] Synthesis final acumulada
   ↓
[handoff-evaluador]
   ↓
[el-evaluador] R7 three-layer + memory promotion
   ↓
[la-forja] feature passing si PASS, NEEDS_FIX si gaps
```

## Ventajas

- **Dependencias respetadas:** fase N tiene context completo de fases anteriores.
- **Synthesis visible:** humano puede inspeccionar synthesis entre fases y confirmar coherencia.
- **Fail-fast:** si fase N falla, fases N+1..M no se ejecutan (no waste).
- **Memory propagation clean:** una sola línea de proposed_memory_entries, no merge cross-worktree.

## Desventajas

- **No paraleliza:** total time = suma de tiempos de cada fase. Para Blueprint con 5 fases independientes, Fork es 3-5× más rápido en wallclock.
- **Cognitive load alto en synthesis:** Blueprint con >8 fases → synthesis denso, difícil de mantener coherente.
- **Sin exploración de approaches alternativos:** una solución por fase, no comparación.

## Sweet spot

- 2-5 fases con dependencias secuenciales fuertes.
- Cada fase ≤30min de wallclock (sub-agent puede ejecutar sin atorarse).
- Synthesis entre fases ≤500 LOC (manejable).

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO escribe código en cada fase, sub-agents lo hacen.
- [memory:CONSTRAINTS.md#R5] — workers no escriben memory; el-evaluador post-orchestration.
- [memory:CONSTRAINTS.md#R6] — registry validation antes de cada fase dispatch.
- [memory:lessons#L-004] — Coordinator es override (no default) del binary pattern selector.
- [memory:decisions#D-013] — la-forja confirma binary cross-skill.

## Anti-patterns

- ❌ Sub-agent de fase N+1 ignora synthesis de fase N (silent divergence).
- ❌ la-forja MISMA hace synthesis con Edit/Write a archivos de aplicación (R4 violation — synthesis es texto).
- ❌ Saltar fase N porque "parece independiente" sin re-aplicar pattern selector.
- ❌ Coordinator forzado cuando Fork era viable (hace orchestration 3-5× más lento sin razón).
