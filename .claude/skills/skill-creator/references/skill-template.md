# SKILL.md template canónico — anotado

> Referencia interna del skill-creator. Cada sección anotada con qué placeholder substituir y qué shape genera variantes. NO es el SKILL.md final del usuario — es el template.

## Frontmatter YAML completo

```yaml
---
name: {{NAME}}
description: >
  {{DESCRIPTION_LINE_1}}
  {{DESCRIPTION_LINE_2_OPTIONAL}}
  {{DESCRIPTION_LINE_3_OPTIONAL}}
tier: {{TIER}}
requires: {{REQUIRES — texto del interview o placeholder específico al shape}}
fallback: {{FALLBACK — texto del interview o placeholder específico}}
dependencies: {{DEPENDENCIES — [] vacío o [find-docs] si shape requiere R13}}
---
```

**Reglas del frontmatter:**

- `name` debe matchear el folder name exactamente.
- `description` puede ser multi-line con `> ` syntax.
- `tier` formato según convención: `core`, `core (lightweight)`, `core (meta)`, `optional`, `hidden`.
- `requires` describe gates duros (PREFLIGHT). Sin gates duros → "directorio target con git inicializado" como mínimo.
- `fallback` describe behavior si requires fallan o si scope excede.
- `dependencies` array: `[]` si no requiere otros skills upstream, `[find-docs]` si genera código contra libs externas (R13), `[<otros skills>]` si depende de outputs de otros.

## Header H1 + epígrafe

```markdown
# {{NAME}}

> *"{{EPIGRAFE_OPTIONAL}}"*

{{INTRO_PARAGRAPH}}

**No genera {{LO_QUE_NO_GENERA}}.** No tiene `{{TEMPLATES_OR_OTHER}}` folder.
{{R10_R14_GUARDIAN_DECLARATION}}
```

Variantes por shape:
- **lightweight**: epígrafe corto, intro 2-3 líneas, declarar "No genera código nuevo". NO templates folder.
- **orchestrator**: epígrafe sobre orquestación, intro con menciones a R4. NO Edit/Write directo.
- **pipeline**: epígrafe sobre secuencialidad, intro con resume-aware mention.
- **validator**: epígrafe sobre validación, intro con R7 o checks específicos.
- **meta**: epígrafe sobre meta-action, intro con clarificación "actúa sobre el harness".

## PREFLIGHT

```markdown
## PREFLIGHT — {{HALT_TYPE}} ({{GATE_COUNT}} gates)

```
1. {{GATE_1_DESCRIPCION}}
   - {{GATE_1_PASS_BEHAVIOR}}
   - {{GATE_1_FAIL_BEHAVIOR}}

2. {{GATE_2_DESCRIPCION}}
   - {{GATE_2_PASS_BEHAVIOR}}
   - {{GATE_2_FAIL_BEHAVIOR}}

{{GATES_3_4_OPTIONAL}}
```

{{NAME}} halt-blocked SOLO en {{BLOCKERS_REALES}}. NO halt en archivos opcionales.
```

Variantes por shape:
- **lightweight**: 2-3 gates duros (active feature, tests passing, etc.).
- **orchestrator**: 4-5 gates (Blueprint aprobado, registry validation, disk space, etc.).
- **pipeline**: 3-4 gates (input file existence, scope detection, dependencies).
- **validator**: 2-3 gates suaves (target accessible, tools available, etc.).
- **meta**: 2-3 gates suaves (estructura existing, naming no collision).

## Activación tabla

```markdown
## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| {{TRIGGER_1}} | Coordinator / agente / humano |
| {{TRIGGER_2}} | Coordinator |
| {{TRIGGER_3}} | {{ESPECIFICO_QUIEN}} |

NO se invoca para: {{LISTA_DE_NO_USE_CASES}}.
```

Mínimo 3 triggers + lista de NO use cases (boundaries con otros skills).

## Mode selector (solo si has_selector=true)

```markdown
## Mode selector (binary | trinary | D-{{ADR_ID}})

| Modo | Trigger | Use case |
|------|---------|----------|
| **{{MODE_DEFAULT}}** | {{TRIGGER_DEFAULT}} | DEFAULT |
| **{{MODE_OVERRIDE_1}}** | {{TRIGGER_OVERRIDE_1}} | Override |
| {{MODE_OVERRIDE_2_OR_PAUSE}} | {{TRIGGER}} | Override / PAUSE |

`prompts/{{SELECTOR_PROMPT}}.md` implementa el selector con L-004 test aplicado.

**L-004 test outcome:** {{BINARY_OR_TRINARY}} confirmed. {{REASONING}}.
```

Si trinary → 3 filas. Si binary → 2 filas (default + override).

## Shape rationale (solo si has_selector=false)

```markdown
## Shape rationale

{{NAME}} es {{SHAPE_NAME_DETAILED}} — NO selector entre N providers/approaches.
[memory:decisions#D-014] establece doctrine boundary case: skills sin selector
requieren ADR propio.

**Análisis caso por caso:**

| Decisión potencial | ¿Selector entre N providers? | ¿Aplica L-004? |
|--------------------|------------------------------|----------------|
| {{POTENTIAL_DECISION_1}} | {{YES_OR_NO}} | {{YES_OR_NO}} |
| {{POTENTIAL_DECISION_2}} | {{YES_OR_NO}} | {{YES_OR_NO}} |

**Conclusión:** {{NAME}} {{NO_SELECTOR_REASON}}. Detalle en
[`references/{{NAME}}-rationale.md`](references/{{NAME}}-rationale.md) y
[memory:decisions#D-{{ADR_ID}}].
```

## Loop o flujo principal

Variantes por shape:

**lightweight** (4-step loop):
```markdown
## Loop de ejecución (~{{TIME_BUDGET}} total)

```
1. {{PHASE_1}} (~{{TIME_1}})
2. {{PHASE_2}} (~{{TIME_2}})
3. {{PHASE_3}} (~{{TIME_3}})
4. {{PHASE_4}} (~{{TIME_4}})

Total típico: {{TYPICAL_TIME}}.
```
```

**orchestrator** (dispatch flow):
```markdown
## Cómo opera {{NAME}} MISMA — flow canónico

```
1. PREFLIGHT
   ↓
2. SELECT-PATTERN (prompts/select-pattern.md)
   ↓
3. VALIDATE-REGISTRY (R6)
   ↓
4. DISPATCH (sub-agents)
   ↓
5. ORCHESTRATE (workers ejecutan, NO {{NAME}})
   ↓
6. HANDOFF
```
```

**pipeline** (sequential steps):
```markdown
## Fase 0 — Detección de estado (resume-aware)
## Fase 1 — Ejecución secuencial
## Fase 2 — Consolidación
## Fase 3 — Handoff
```

**validator** (audit flow):
```markdown
## Cómo opera el audit

```
[{{NAME}}] PREFLIGHT
   ↓
[{{NAME}}] {{MODE_SELECTOR}} (si has_selector)
   ↓
[{{NAME}}] Sub-agent dispatch
   ↓
[Sub-agent ejecuta audit]
   ↓
[{{NAME}}] Reporte estructurado
```
```

**meta** (wizard flow):
```markdown
## Flujo {{MODE}}: 5-step canónico

```
1. PREFLIGHT
   ↓
2. {{INTERVIEW_OR_INPUT}}
   ↓
3. CONFIRM
   ↓
4. EXECUTE
   ↓
5. INSTRUCCIÓN FINAL
```
```

## Output shape

```markdown
## Output shape

```{{LANGUAGE — markdown / yaml}}
{{TEMPLATE_DEL_OUTPUT}}
```

Si {{EDGE_CASE_DEL_OUTPUT}}, el output cambia: {{VARIANTE}}.
```

## Reglas operativas

```markdown
## Reglas operativas

1. **{{RULE_1_TITULO}}.** {{RULE_1_BODY}}
2. **{{RULE_2_TITULO}}.** {{RULE_2_BODY}}
3. **{{RULE_3_TITULO}}.** {{RULE_3_BODY}}
4. **{{RULE_4_TITULO}}.** {{RULE_4_BODY}}
5. **{{RULE_5_TITULO}}.** {{RULE_5_BODY}}
{{RULES_6_TO_N_OPTIONAL}}
```

Mínimo 5 numeradas. Cada regla menciona R/L/D apropiado si aplica.

## Refusals

```markdown
## Refusals

- ❌ {{REFUSAL_1}}
- ❌ {{REFUSAL_2}}
- ❌ {{REFUSAL_3}}
- ❌ {{REFUSAL_4}}
- ❌ {{REFUSAL_5}}
{{REFUSALS_6_TO_N_OPTIONAL}}
```

Mínimo 5. Cada refusal específica + accionable.

## Tool filter

```markdown
## Tool filter

`{{TOOLS_PERMITIDAS}}`

NO {{TOOLS_BLOQUEADAS}}.

{{BASH_LIMITED_LIST_IF_APPLICABLE}}
```

Variantes por shape:
- **lightweight**: `Read · Edit · Write · Grep · Glob · Bash` (typecheck + git).
- **orchestrator**: `Read · Grep · Glob · Bash (limited)`. NO Edit · NO Write · NO Skill.
- **pipeline**: similar a orchestrator pero con sub-agent writes a outputs específicos.
- **validator**: `Read · Grep · Glob · Bash (limited)`. NO Edit · NO Write directo.
- **meta**: `Read · Edit · Write · Grep · Glob · Bash (limited)`. Skip Skill.

## Citation grammar tabla

```markdown
## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R{{N}}]` | {{CUANDO}} |
| Lesson | `[memory:lessons#L-{{NNN}}]` | {{CUANDO}} |
| Decision | `[memory:decisions#D-{{ADR_ID}}]` | en SKILL.md (binary | trinary | boundary case) |
| Reference | `[memory:references#R-{{NNN}}]` | {{CUANDO}} |
| External docs | `[docs:{{LIB}}]` | {{CUANDO}} |
```

Mínimo: D-{{ADR_ID}} + L-004 (informativo). Otros R/L/refs según shape.

## Integración con otros skills

```markdown
## Integración con otros skills

| Skill | Relación |
|-------|----------|
| {{SKILL_1}} | {{RELACION_1}} |
| {{SKILL_2}} | {{RELACION_2}} |
| {{SKILL_N}} | {{RELACION_N}} |
```

Mínimo 4 boundaries. Foco en upstream/downstream + casos NO direct.

## Output handoff

```markdown
## Output handoff

```markdown
## {{NAME}} handoff

**{{KEY_METADATA_1}}:** {{VALUE}}
**{{KEY_METADATA_2}}:** {{VALUE}}

**{{OUTPUTS}}:**
- {{OUTPUT_1}}
- {{OUTPUT_2}}

**Próximo paso:** {{NEXT_STEP}}
```
```

## Closing italic

```markdown
---

*"{{CLOSING_LINE_OPTIONAL}}"*
```

## Comentario TODO post-authoring

```markdown
<!-- TODO post-authoring:
1. Llenar PREFLIGHT con gates específicos.
2. Authorizar prompts/ y references/.
3. Completar tests/dry-run.sh con checks reales.
4. Invocar el-evaluador para registrar entry en skills.md + ADR D-{{ADR_ID}}
   ({{BINARY_TRINARY_BOUNDARY}}).
5. Cerrar feature en feature_list.json.
-->
```

## Verificación pre-write

Antes de escribir el archivo, validar:

1. Todos los `{{PLACEHOLDERS}}` tienen valor (NO `{{VARIABLE}}` literal en output).
2. Frontmatter YAML parsea correctamente.
3. Markdown estructura válida (headings consecutivos sin saltos).

Si validación falla → halt + reportar bug en el template.

## Citation grammar

- [memory:CONSTRAINTS.md#R5] — skill-creator NO escribe memory.
- [memory:decisions#D-014] — boundary case template (skills sin selector).
- [memory:decisions#D-015] — doctrine refinada.
- [memory:decisions#D-018] — skill-creator binary mode.
