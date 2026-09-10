# scope-check

> Decide si una tarea califica como tajo atómico (execute) o excede el scope (escalate-graceful a el-golpe). Aplica L-004 test diagnóstico — outcome documented en `[memory:decisions#D-016]`: BINARY (execute / escalate sin PAUSE).

## Inputs

- Descripción de la tarea (usuario o sub-agent dispatcher).
- Active feature actual del `feature_list.json`.
- Estado del repo (tests/lint passing — PREFLIGHT pasó).

## Output

```yaml
scope_decision:
  outcome: execute | escalate
  
  # si execute
  scope_estimate:
    wallclock_min: <number>      # <5
    loc_delta: <number>          # <500
    files_modified: <number>     # 1-3
  
  # si escalate
  escalation_reason: <texto>
  next_skill: el-golpe | /build
```

## Criterios atómicos (los 3 deben cumplirse)

| Criterio | Tajo (execute) | Excede |
|----------|----------------|--------|
| **Wallclock estimado** | <5min | ≥5min → escalate |
| **LOC delta** | <500 | ≥500 → escalate |
| **Archivos modificados** | 1-3 | >3 → escalate |

Si CUALQUIERA excede → escalate. Los 3 criterios son AND, no OR.

## Heurísticas adicionales (señales de "no es tajo")

- ¿Requiere brief-plan visible al usuario antes de ejecutar? → NO es tajo (el-golpe sí).
- ¿Requiere multi-step verification (varios tests, e2e, visual diff)? → NO es tajo (el-golpe o /build).
- ¿Toca UI consumiendo brand.json (R10 enforcement)? → Excepcional. Solo si es typo en JSX literal o rename componente. Refactor visual pertenece a el-golpe.
- ¿Requiere refactor de patterns cross-archivos? → NO es tajo.
- ¿Es feature nueva (no fix/refactor/extract)? → NO es tajo (la-forja / /build).
- ¿Requiere planning de pasos secuenciales? → NO es tajo (la-forja Coordinator).
- ¿Requiere exploración de approaches alternativos? → NO es tajo (la-forja Fork).
- ¿Tarea iterativa con feedback humano entre ciclos? → NO es tajo (sprint).

Si CUALQUIERA de estas heurísticas matchea → escalate, aún si los 3 criterios primarios están dentro de rango.

## Decision tree (D-016 binary)

```
¿wallclock <5min Y loc <500 Y files ≤3 Y heurísticas todas NO?
├── Sí → execute (default)
└── No → escalate graceful a el-golpe
```

**L-004 test aplicado:**

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Sin active feature (PREFLIGHT) | Sí (pickear backlog) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Tests rojos (PREFLIGHT) | Sí (fixar tests primero) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Scope excede criterios | NO — escalate a el-golpe SIEMPRE disponible | NO PAUSE |
| el-golpe no aplica (excede 30min también) | NO — escalate a /build SIEMPRE disponible | NO PAUSE |

**Conclusión D-016:** **BINARY** confirmed. execute (default si scope califica) o escalate-graceful (si scope excede). NO PAUSE genuino — el-golpe / /build siempre disponibles, no requieren upstream user action específica del selector.

## Escalation messaging

Si decisión = escalate, output al usuario debe ser claro y no condescendiente:

```markdown
## Tajo escalation → el-golpe

**Razón:** <causa concreta>
- Scope estimado: ~12min wallclock, ~700 LOC delta, 5 archivos.
- Excede criterios atómicos (<5min, <500 LOC, ≤3 archivos).

**Próximo paso:**
→ Invocá `/el-golpe` con la misma tarea. el-golpe acepta scope mediano
  (<30min, brief-plan visible, 1-3 commits).

NO es escalación negativa — es match correcto del skill al scope.
```

Heurística: si escalation a el-golpe ALSO excede su scope (>30min o feature nueva planificable), escalate a `/build` (la-forja) directo, saltando el-golpe.

## Edge cases

### Edge: tarea de scope mixto (1 archivo grande + 2 archivos chicos = 3 archivos pero 700 LOC)

→ Si LOC excede 500 → escalate, aún si archivos están en rango. Los 3 criterios son AND.

### Edge: refactor que toca 2 archivos pero requiere lectura de 10+ para entender

→ Discovery extendida = NO es tajo. Escalate a el-golpe (que tiene brief-plan visible donde podés mostrar el approach).

### Edge: tarea es trivial pero el verification es costoso (e2e suite completo)

→ Si verification require multi-step más allá de typecheck local → escalate. Tajo es 1 typecheck + 1 commit.

### Edge: usuario pide "agregá tracking" pero el codebase NO tiene SDK analytics

→ Eso es feature nueva (instalar SDK + configurar + agregar tracking) — escalate a el-golpe o /build.

### Edge: usuario pide cambiar 5 strings de copy en 5 archivos distintos

→ Files >3 → escalate. Aunque cada cambio sea atómico, el conjunto es scope mediano.

### Edge: typo en brand.json (1 archivo, <10 LOC delta, <1min)

→ Califica como tajo. Pero atención: brand.json es contrato (D9), R10 aplica — leer schema antes para confirmar que el typo no rompe enums declarados. Si sí rompe → escalate (puede requerir cascade en componentes).

## Citation grammar

- [memory:CONSTRAINTS.md#R1] — active feature requirement (PREFLIGHT).
- [memory:CONSTRAINTS.md#R2] — atomic commit en cierre.
- [memory:lessons#L-004] — binary-vs-trinary test diagnóstico (informativo).
- [memory:decisions#D-016] — el-tajo binary shape, NO PAUSE.

## Refusals

- ❌ Force-fit tajo si los 3 criterios no califican (escalate sin pena).
- ❌ Escalation con mensaje condescendiente ("es muy grande para vos") — escalation es match correcto, no juicio.
- ❌ Saltar PREFLIGHT (active feature + tests passing son gates duros).
- ❌ Inventar PAUSE artificial — D-016 documenta binary explícito.
