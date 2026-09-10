# select-pattern

> Decide cuál de los 3 patterns (Coordinator / Fork / Swarm) la-forja debe ejecutar para el feature actual. Aplica `[memory:lessons#L-004]` test diagnóstico binary-vs-trinary y documenta el resultado para D-013 cross-citation.

## Inputs

- `.claude/PRPs/BLUEPRINT-<nombre>.md` (Blueprint aprobado, mandatory)
- `feature_list.json` (active feature, mandatory)
- `.claude/memory/skills.md` (registry, R6 validation)
- Opcional: usuario indica preferencia explícita ("usá Fork", "esto es secuencial").

## Output

Decisión documentada con shape:

```yaml
pattern: coordinator | fork | swarm
rationale: <2-3 frases con cita L-004 + razonamiento>
sub_agents_planned: N (Fork: 2-5; Coordinator: 1 secuencial; Swarm: 3 workers tool-filtered)
risk_flags: []  # ej: "disco bajo si Fork", "dependencias circulares en Blueprint"
fallback_path: <pattern de fallback si el seleccionado falla>
```

## Step-by-step

### Paso 1 — Lee el Blueprint

```bash
cat .claude/PRPs/BLUEPRINT-<nombre>.md
```

Identificá:
- **Cantidad de fases / features** numeradas en el Blueprint.
- **Dependencias entre fases** — ¿la fase 2 consume output de la fase 1? ¿Hay grafo lineal o hay ramas paralelizables?
- **Atomicidad de sub-tasks** — ¿cada task es <5min one-shot, o son features de 30min+?
- **UI generation involucrada** — ¿hay add-ui-kit/impeccable invocaciones que consumen brand.json?

### Paso 2 — Aplicá L-004 test diagnóstico

> [memory:lessons#L-004] — Test diagnóstico binario-vs-trinario:
>
> ¿Existe degenerate case que requiera acción **upstream** del usuario antes de poder re-invocar la-forja productivamente?

Para la-forja:

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Blueprint missing | Sí (correr la-herreria primero) | **NO PAUSE** — esto es PREFLIGHT halt, no degenerate case del pattern selector |
| Active feature missing | Sí (pickear del backlog) | **NO PAUSE** — PREFLIGHT halt |
| Blueprint con dependencias secuenciales | NO (Coordinator pattern lo maneja) | NO PAUSE |
| Blueprint con sub-tasks atómicos | NO (Swarm pattern lo maneja) | NO PAUSE |
| Disco lleno para Fork | NO (degradar a Coordinator graceful) | NO PAUSE |
| Conflictos circulares en cherry-pick | NO (degradar a Coordinator + reportar) | NO PAUSE |

**Conclusión del test:** la-forja es BINARY-shaped. Default + 2 overrides, sin PAUSE. Documentado en [memory:decisions#D-013] como sexta validación cross-skill de L-004 (D-009 binary, D-010 trinary, D-011 trinary, D-012 binary, D-013 binary).

### Paso 3 — Determiná el pattern

Decision tree:

```
¿Blueprint tiene 1 sub-task atómico bien definido (<30min, 1-3 archivos)?
├── Sí → Swarm
│   └── Workers tool-filtered: researcher + implementer + reviewer
└── No
    ├── ¿Blueprint tiene dependencias secuenciales fuertes
    │   (fase N+1 NO arranca sin output completo de fase N)?
    │   ├── Sí → Coordinator
    │   │   └── Sequential synthesis, 1 fase a la vez
    │   └── No (≥2 features independientes paralelizables)
    │       ├── ¿N estimado ∈ [2,5] (sweet spot Fork)?
    │       │   ├── Sí → Fork (DEFAULT)
    │       │   │   └── N worktrees con personality variants
    │       │   └── N>5 → reducir a 5 + reportar
    │       │       └── O degradar a Coordinator si features siguen siendo >5
    │       └── N=1 (no aporta paralelización) → Swarm o ejecutar en main
```

### Paso 4 — Override por preferencia explícita del usuario

Si el usuario dijo "usá Fork" o "modo coordinator" o "swarm para esto":

- Validá que la elección es coherente con el Blueprint (no force-fit Fork si hay dependencias secuenciales fuertes).
- Si el override del usuario contradice el Blueprint → ofrecé el path coherente Y el override, pedí confirmación UNA pregunta.
- Documentá la elección final con `_override: user_explicit` en el output rationale.

### Paso 5 — Validá registry (R6)

> [memory:CONSTRAINTS.md#R6] — Skill dispatch validates registry.

Para cada skill que el Blueprint cita o que el pattern dispatcha:

```
1. Lee .claude/memory/skills.md
2. Buscá nombre exacto (case-sensitive)
3. Si no existe → halt: "Skill <nombre> no registrado. Audita skills.md o corregí Blueprint."
4. Si existe → validá `requires` (preconditions cumplidas en el repo target)
5. Si requires fallan → halt con mensaje exacto del fallback definido en registry
```

R6 NO es opcional. Aún si confiás que el skill existe, validá. El registry es el contrato.

### Paso 6 — Emití decisión

Output canónico:

```yaml
pattern: fork
rationale: |
  Blueprint lista 3 features independientes (auth, payments, mobile-pwa)
  paralelizables sin dependencias cruzadas mandatorias. Default Fork
  aplica con N=3. L-004 test: NO degenerate case requiere upstream user
  action — Coordinator y Swarm están siempre disponibles como fallback
  si Fork falla [memory:lessons#L-004]. la-forja confirma binary cross-skill
  por sexta vez [memory:decisions#D-013].
sub_agents_planned: 3
personality_variants: [literal, creativo, disruptivo]
risk_flags: []
fallback_path: coordinator (si disco bajo o conflictos circulares persistentes)
```

## Edge cases

### Edge: Blueprint con grafo mixto (algunas paralelizables + algunas secuenciales)

→ Coordinator outer + Fork inner (la-forja se invoca recursivamente desde un sub-agent del Coordinator). Reportar como composición pattern al humano antes de ejecutar — costo cognitivo alto, no decidir solo.

### Edge: Blueprint dice "explorá 3 alternativas de UX para landing"

→ Fork con N=3, personality variants (literal=brief literal, creativo=brief con libertad UX, disruptivo=brief abstraído reinventando layout). Caso canónico de Fork. Cherry-pick = elegí 1 de 3 con rationale documentado.

### Edge: Active feature sin Blueprint (feature directo en feature_list.json sin BLUEPRINT-*.md)

→ halt: "Sin Blueprint, la-forja no opera coherentemente. Corré /la-herreria para generar BLUEPRINT-<nombre>.md primero, o si la feature es <30min one-shot, invocá el-golpe directo."

### Edge: Blueprint deprecated (versión antigua del Blueprint pre-cambios al feature)

→ Validá `last_modified` del Blueprint vs `last_modified` del active feature. Si Blueprint < active → warn al usuario y pedí confirmación de re-generar Blueprint o proceder.

### Edge: Usuario quiere Fork pero N=1 (un solo feature paralelizable detectado)

→ Refusal Fork. Sugerir Swarm (workers tool-filtered) o ejecutar en main. Fork con N=1 es degenerate — no es paralelización, es overhead sin beneficio. Documentado en SKILL.md regla 6.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — orchestrator stays thin: la-forja MISMA NO invoca skills, solo selecciona pattern y dispatcha.
- [memory:CONSTRAINTS.md#R6] — registry validation antes de dispatch.
- [memory:lessons#L-004] — binary-vs-trinary test diagnóstico.
- [memory:decisions#D-013] — la-forja confirma L-004 binary cross-skill (sexta validación).
- [memory:references#R-005] — informativo si Blueprint involucra UI generation que consume brand.json.

## Refusals

- ❌ Force-fit Fork cuando Blueprint tiene dependencias secuenciales fuertes — Coordinator es el path correcto, no Fork con N agentes esperándose.
- ❌ Decidir Swarm sin validar atomicidad — sub-tasks no atómicos en Swarm degradan a Implementer haciendo trabajo de Coordinator (anti-pattern).
- ❌ Dispatch sin R6 validation — aún si el skill "siempre estuvo ahí", validá registry. Es cheap check vs riesgo de halt mid-orchestration.
- ❌ Inventar PAUSE artificial — L-004 test es explícito, NO degenerate case en la-forja. Si dudás, default a binary y documentá en D-013 como confirmation.
