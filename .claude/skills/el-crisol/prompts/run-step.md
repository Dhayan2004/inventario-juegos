# run-step

> Fase 1 de el-crisol. Protocolo genérico para ejecutar UN paso individual del pipeline (1 de 7). Cada paso delega a un sub-agent con tool filter apropiado. R4/R5 enforced.

## Inputs

```yaml
step:
  number: 1..7
  name: brujula | estrella | rivales | precio | roi | metas | lanzamiento
  produces: STRATEGY-CANVAS-{nombre}.md | NORTH-STAR-{nombre}.md | ...
  needs_before:
    - <list de docs previos del pipeline>

context_acumulado:
  blueprint: <path al BLUEPRINT>
  existing_docs:
    - <docs estratégicos previos del pipeline ya generados>
  perplexity_enabled: bool
  project_name: <{nombre}>
```

## Output

```yaml
step_result:
  step: <name>
  output_path: <path>             # archivo generado
  output_summary:
    key_data: <dato clave extraído — ej "NSM: Weekly Active Projects">
    rationale: <1-2 frases sobre la decisión>
  next_step_context:
    propagate_to_next:
      - <variables que el próximo paso debe heredar>

  user_decision:
    continue: bool                # ¿usuario aprobó continuar al paso N+1?
    skip_next: number | null      # si saltó algún paso
    abort: bool                   # si abortó el pipeline
```

## Step-by-step

### Paso 1 — Anunciar el paso

```
━━━ Paso {N}/7: {nombre} ━━━
{Qué hará en una línea — ej: "Definir vision + posicionamiento + estructura BMC"}
Dependencias: {listar docs previos que usará como input — ej: "BLUEPRINT.md"}
Tiempo estimado: ~25min
Perplexity: {sí/no — solo informativo si el step lo soporta}
```

### Paso 2 — Dispatch sub-agent con tool filter apropiado

el-crisol MISMA NO ejecuta el análisis (R4 enforced). Dispatcha sub-agent:

```
[Sub-agent dispatched by el-crisol]
  Role: Strategy analyst (paso {N})
  Tool filter:
    - Read · Grep · Glob · WebFetch (research opt-in)
    - Edit · Write (solo para output: el doc específico de este paso)
    - Bash limitado: file ops + opcionalmente find-docs invocation
  System prompt:
    "Sos el strategy analyst para el paso {N} ({nombre}). Inputs: 
     {context_acumulado}. Tu output va a {output_path}. Seguí el
     template canónico de saas-factory upstream para este paso.
     NO modifiques otros docs (solo el output_path tuyo). NO escribas
     a .claude/memory/* (R5). Si Perplexity está enabled y este
     paso lo soporta, invocalo para enrichment."
```

### Paso 3 — Sub-agent ejecuta el análisis

Sub-agent:
1. Lee BLUEPRINT + docs existentes del context_acumulado.
2. Si paso es de tipo "interview-driven" (ej: brujula, estrella) → presenta preguntas al usuario hasta tener inputs suficientes.
3. Si paso es de tipo "data-driven" (ej: roi, metas) → calcula directamente desde docs previos sin re-preguntar.
4. Genera el doc específico (STRATEGY-CANVAS, NORTH-STAR, etc.) en `output_path`.
5. Retorna `step_result` a el-crisol.

### Paso 4 — Confirmar output al usuario

```
✅ Paso {N}/7 completado → {output_path}
   {Dato clave extraído — ej: "NSM: Weekly Active Projects, target 12m: 1000 WAP"}

Siguiente: {Nombre del paso N+1} — {qué hará en una línea}

Continuar, saltar siguiente, o ajustar este paso?
  - "continúa"  → Paso N+1
  - "saltar"    → Paso N+2 (saltar el N+1)
  - "ajustar"   → Re-ejecutar paso N con inputs nuevos
  - "abortar"   → Salir del pipeline (Fase 2 puede correr con docs parciales si hay ≥1)
```

### Paso 5 — Transición al siguiente paso

Según decisión del usuario:

| Decisión | Transición |
|----------|-----------|
| continúa | Paso N+1 con context_acumulado actualizado |
| saltar | Paso N+2; el step saltado se marca `skipped` para Fase 2 scoring N/A |
| ajustar | Re-ejecutar paso N con prompt extendido (qué cambiar) |
| abortar | Salir del pipeline; el-crisol pregunta si correr Fase 2 con docs parciales |

## Reglas de ejecución cross-pasos

### 1. No re-preguntar (propagación de contexto)

Si Brujula definió `target_customer = "indie SaaS founders"`, Rivales NO vuelve a preguntar el target. Sub-agent del paso N+1 recibe TODOS los outputs de pasos previos como input estructurado.

### 2. No contradecir

Si Precio definió tiers `{Free, Pro 49, Team 149}`, ROI los usa tal cual en sus proyecciones. Si emerge inconsistencia (ej: ROI quiere recalcular tiers desde sensitivity analysis), halt + reportar al humano para resolución manual. NO sub-agent sobreescribe decisión de paso previo silenciosamente.

### 3. Docs existentes = contexto

Si ya existía `STRATEGY-CANVAS-{nombre}.md` (resume mode), todos los pasos posteriores la leen como input — NO la regeneran. Detección Fase 0 lo determinó.

### 4. Sub-agents NO escriben a memory (R5)

Outputs van a `.claude/reports/` o raíz proyecto (state, no memory). Si emerge lesson/error/decision durante el paso, sub-agent reporta a el-crisol → el-crisol propaga al handoff de Fase 3 con shape `proposed_memory_entries`. el-evaluador post-pipeline (si invocado) hace el record.

### 5. R4 enforcement por paso

el-crisol MISMA NO genera el doc del paso. Solo dispatcha sub-agent. Si te ves haciendo Edit/Write directo dentro de run-step.md → R4 violation, refactor a sub-agent dispatch.

## Mapeo paso → template

Forja Phase 5+ (orchestrator wizard scope) implementará sub-prompts canónicos por paso. En la versión actual, sub-agents usan los templates de saas-factory upstream:

| Paso | Template upstream | Output |
|------|-------------------|--------|
| brujula | saas-factory `commands/brujula.md` | `STRATEGY-CANVAS-{nombre}.md` |
| estrella | saas-factory `commands/estrella.md` | `NORTH-STAR-{nombre}.md` |
| rivales | saas-factory `commands/rivales.md` | `COMPETITIVE-ANALYSIS-{nombre}.md` |
| precio | saas-factory `commands/precio.md` | `PRICING-STRATEGY-{nombre}.md` |
| roi | saas-factory `commands/roi.md` | `.claude/reports/saas-analysis-{nombre}.md` + `.html` |
| metas | saas-factory `commands/metas.md` | `OKRS-{nombre}.md` |
| lanzamiento | saas-factory `commands/lanzamiento.md` | `GTM-STRATEGY-{nombre}.md` |

Si el template upstream no está disponible en el repo target, sub-agent usa heurísticas estándar de strategy consulting + cita al usuario "template upstream no encontrado, generando con shape canónico saas-factory".

## Edge cases

### Edge: Sub-agent reporta error de research (Perplexity quota / API down)

→ Sub-agent retry sin Perplexity (graceful degradation). Reportar al usuario que research enrichment falló pero el paso continúa con datos del Blueprint + docs previos.

### Edge: Sub-agent encuentra ambigüedad en input (ej: BLUEPRINT no define target customer claro)

→ Sub-agent pregunta UNA pregunta al usuario antes de proceder. NO sub-agent inventa el dato — eso lleva a scores inflados en Fase 2.

### Edge: Usuario abortó mid-pipeline (paso 4 de 7 completado)

→ el-crisol pregunta: "Tenés 4 docs estratégicos. ¿Querés generar dashboard con lo que hay (Fase 2 graceful), o pause completo?". Default: ofrecer dashboard parcial con secciones marcadas "no realizado".

### Edge: Paso re-ajustado pero el cambio invalida un paso posterior ya hecho

→ Si Brujula re-ajusta target customer y Rivales ya estaba hecho con el target previo → halt + reportar al usuario: "Re-ajuste de Brujula invalida Rivales. ¿Re-generar Rivales con nuevo target o aceptar inconsistencia?". Default conservador: re-generar Rivales.

### Edge: Sub-agent tarda >40min en un solo paso

→ Reportar al usuario como progress check. NO matar el sub-agent silenciosamente — puede haber WIP valioso.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — el-crisol thin, sub-agents ejecutan.
- [memory:CONSTRAINTS.md#R5] — sub-agents no escriben memory.
- [memory:decisions#D-014] — pipeline shape (informativo).

## Refusals

- ❌ el-crisol MISMA escribe el doc del paso (R4 violation — sub-agent escribe).
- ❌ Sub-agent escribe a memory durante el paso (R5 — solo el-evaluador post-pipeline).
- ❌ Sub-agent contradice decisiones de pasos previos sin halt + reportar.
- ❌ Sub-agent inventa datos para llenar gaps del Blueprint (R8 análogo — datos vacíos NO compensan).
- ❌ Avanzar paso N+1 sin confirmation del usuario (silent divergence anti-pattern).
- ❌ Saltar 2+ pasos consecutivos sin halt + reportar (puede ser scope creep o señal de pipeline mal pensado).
