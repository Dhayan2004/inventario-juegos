# interview

> Modo guided: 5 preguntas que el-skill-creator hace al usuario para producir scaffold con shape correcto. Q5 (selector presence) es CLAVE — determina shape ADR (binary/trinary vs ADR propio análogo a D-014).

## Inputs

- Usuario invoca `/skill-creator` (modo guided, default).
- PREFLIGHT pasó (.claude/skills/ existe + nombre no colisiona).

## Output

```yaml
interview_result:
  name: <kebab-case>                      # Q1
  description: <multi-line OK>             # Q2
  tier: core | optional | hidden           # Q3
  shape: lightweight | orchestrator | pipeline | validator | meta  # Q4
  has_selector: bool                       # Q5
  
  # si has_selector=true
  selector_dimensions:
    - name: <eje del selector>
      options: [<list>]
      degenerate_case: <descripción si aplica>
      l_004_outcome: binary | trinary | unknown
  
  # si has_selector=false
  shape_rationale: <texto explicando por qué NO selector>
  expected_adr_reference: D-014           # boundary case template

  # always
  reserved_adr_id: D-019                  # siguiente disponible (post-D-018)
```

## Q1 — Nombre del skill

```markdown
## Q1: ¿Cuál es el nombre del skill nuevo?

Reglas:
- Kebab-case obligatorio (ej: `add-payments`, `el-yunque`).
- Si tier es **core**, preferí nombre metalúrgico coherente con la metáfora
  Forja: la-X (la-herreria, la-forja), el-X (el-tajo, el-golpe, el-evaluador,
  el-crisol, el-guardian, el-migrador, el-yunque), o palabra técnica con
  resonancia (impeccable, sprint, primer, find-docs, web-quality).
- Si tier es **optional**, nombre descriptivo en inglés (add-X, build-X).
- Si tier es **hidden**, convención específica (el-supervisor, etc.).

Skills ya existentes (NO usar — colisión):
<list de skills.md actual>

Tu nombre:
```

Validación:
- Confirmar contra `.claude/memory/skills.md` + `ls .claude/skills/`.
- Si colisiona → halt + sugerir variant.
- Si convención metalúrgica + tier=core pero el nombre es descriptivo → recordar la convención sin forzar (el usuario decide).

## Q2 — Descripción

```markdown
## Q2: Descripción 1 línea (qué hace, cuándo se usa, output esperado)

Multi-line YAML permitido en el frontmatter (description: > syntax).

Ejemplos canónicos (cortos pero accionables):
- el-tajo: "Microtarea atómica one-shot. Scope: <5min, <500 LOC, 1-3 archivos."
- web-quality: "Auditoría integral pre-deploy Lighthouse-based (150+ checks)..."
- skill-creator: "Skill meta wizard que guía la creación de un nuevo skill..."

Anti-pattern (vago):
- "Ayuda al usuario con X."
- "Hace cosas relacionadas a Y."

Tu descripción:
```

Validación:
- Si descripción es vaga (<20 chars o solo "ayuda al usuario") → re-preguntar con ejemplos canónicos visibles.
- Si tiene >300 chars → sugerir extender al frontmatter multi-line + acortar la línea principal.

## Q3 — Tier

```markdown
## Q3: Tier del skill

| Tier | Definición | Skills ejemplo |
|------|------------|----------------|
| **core** | Skill que cualquier proyecto generado con Forja necesita o puede invocar. 21 actuales (post-F3-S12). | la-herreria, el-evaluador, primer, sprint, el-tajo, el-golpe |
| **optional** | Solo se invoca si proyecto requiere específicamente. | add-login, add-payments, add-emails, add-mobile |
| **hidden** | Requiere instalación adicional (Hermes, agente externo, dep no estándar). | el-supervisor (Hermes-dependent) |

Tu tier:
```

Validación:
- Si usuario duda → modo guided extendido: pedir más context sobre el use case.
- Si tier=hidden pero shape no requiere install adicional → re-considerar.

## Q4 — Shape estructural

```markdown
## Q4: Shape estructural del skill

| Shape | Definición | Skills ejemplo |
|-------|------------|----------------|
| **lightweight** | Prompt-only, NO templates folder, <250 LOC SKILL.md, 1-3 prompts. | primer, sprint, el-tajo, el-golpe, skill-creator |
| **orchestrator** | Dispatcha sub-agents, R4 enforced, 3 patterns posibles (Coordinator/Fork/Swarm). | la-forja |
| **pipeline** | Secuencial con resume detection, sin selector entre providers. | el-crisol |
| **validator** | Audita output, R7 three-layer o checks específicos. | el-evaluador, web-quality, el-guardian |
| **meta** | Actúa sobre el harness mismo, no sobre código de aplicación. | skill-creator |

Tu shape:
```

Validación:
- Cada shape implica defaults distintos en el SKILL.md template (PREFLIGHT, tool filter, citation grammar).
- Si shape=lightweight pero descripción menciona "templates pre-armados" → flag inconsistencia.

## Q5 — Selector presence (CLAVE para D-NNN)

```markdown
## Q5: ¿El skill tiene un selector entre N providers/approaches alternativos?

Esta pregunta determina la shape del ADR (decision record) que vas a registrar
al cerrar el authoring.

**Definición de selector:**
- Existen 2+ alternativas reales que el skill puede ejecutar.
- Cada alternativa es un "provider" o "approach" técnicamente distinto.
- El skill elige una al runtime según context (default + override(s)).

**Ejemplos cross-skill ya validados (D-009..D-018):**

| Skill | Selector? | ADR shape |
|-------|-----------|-----------|
| add-login | SÍ — Supabase / Insforge | binary (D-009) |
| add-payments | SÍ — Stripe / Polar / PAUSE empresa MoR | trinary (D-010) |
| add-emails | SÍ — Resend / SendGrid / PAUSE SMTP | trinary (D-011) |
| add-mobile | SÍ — PWA / native shell | binary (D-012) |
| la-forja | SÍ — Coordinator / Fork / Swarm | binary (D-013) |
| el-crisol | NO — sequential pipeline | boundary case (D-014) |
| web-quality | SÍ — live / static | binary (D-015) — refina D-014 |
| el-tajo | SÍ — execute / escalate-graceful | binary (D-016) |
| el-golpe | SÍ — execute / escalate-graceful | binary (D-017) |
| skill-creator | SÍ — guided / template-only | binary (D-018) |

**Doctrine post-D-015 (REGLA OPERACIONAL):**
> Presencia del selector dentro del skill determina aplicabilidad de L-004,
> NO categoría del skill. Si SÍ → L-004 binary/trinary. Si NO → ADR propio
> análogo a D-014.

**Tu respuesta:**

¿Tu skill tiene selector entre N providers/approaches alternativos?
- Sí → continuar a sub-pregunta Q5a (test L-004 binary vs trinary)
- No → continuar a sub-pregunta Q5b (shape ADR boundary case)
- No sé → modo guided extendido: explicame qué hace tu skill y discutamos
```

### Q5a — Si SÍ selector (test L-004)

```markdown
**L-004 test:** ¿Existe degenerate case que requiera acción upstream del usuario
(constituir entidad legal, infra propia, etc.) ANTES de poder re-invocar el
skill productivamente?

- Sí → trinario (default + override + PAUSE)
  Ejemplos: D-010 (PAUSE constituir empresa MoR), D-011 (PAUSE constituir SMTP).

- No → binary (default + override(s) sin PAUSE)
  Ejemplos: D-009, D-012, D-013, D-015, D-016, D-017, D-018.

¿PAUSE genuino existe en tu skill?
- Sí → expected D-NNN trinary. Documentá el degenerate case.
- No → expected D-NNN binary. Documentá overrides disponibles.
```

### Q5b — Si NO selector (shape ADR propio)

```markdown
**Shape estructural sin selector:**

¿Cuál es el shape específico?
- Sequential pipeline con resume detection (ej: el-crisol).
- Validator-fijo con checks predefinidos (ej: el-evaluador).
- Composer/orchestrator wizard (Phase 5+).
- Other — describí.

Razón clave (por qué NO hay selector):
- Sub-decisiones potenciales son control de flow del MISMO procedimiento, NO
  alternatives entre providers/approaches.
- Sub-decisiones son feature flags / opt-in (NO selectores entre providers).

Esperado D-NNN (boundary case análogo a D-014):
- Documentar shape estructural.
- Análisis caso por caso de "decisiones potenciales" descartando que sean selectores reales.
- Análisis separado de degenerate cases (PREFLIGHT halt vs PAUSE-style).
- Ubicación en scoreboard cross-skill.
```

## CONFIRM block

Después de las 5 preguntas, mostrar al usuario:

```markdown
## Confirmación de inputs

| Campo | Valor |
|-------|-------|
| Nombre | <name> |
| Descripción | <description truncada a 80 chars> |
| Tier | <tier> |
| Shape | <shape> |
| Selector | <YES — binary/trinary | NO — boundary case> |
| ADR reservado | D-NNN (siguiente disponible) |

¿Confirmás los inputs y procedo al scaffold?
- "go" → ejecuto scaffold.md
- "ajustá Q?" → re-emitir esa pregunta
- "stop" → guardar inputs parciales y abortar
```

## Edge cases

### Edge: usuario responde "no sé" a Q3 (tier)

→ Modo guided extendido: pedir más context sobre el use case (¿es para todo proyecto Forja? ¿solo cuando hay X feature? ¿requiere install adicional?). Inferir tier de las respuestas.

### Edge: usuario responde "no sé" a Q5 (selector)

→ Sub-preguntas: "¿el skill elige entre 2+ tools/libs/approaches al runtime?" + "¿esa elección está documentada en el SKILL.md como modos?" Si ambas SÍ → SÍ selector. Si ambas NO → NO selector. Si ambiguo → describir use case y discutir.

### Edge: nombre colisiona con skill existente

→ Halt en PREFLIGHT antes de Q1. Pero si emerge mid-interview (raro), abortar + sugerir rename.

### Edge: descripción tiene >500 chars

→ Re-pedir versión corta para línea principal del frontmatter, dejando contenido extendido para SKILL.md body.

### Edge: shape=meta pero el skill toca código de aplicación

→ Inconsistencia. Re-clarificar: meta = actúa sobre el harness (skills, memory, hooks). Si toca código de aplicación → shape distinto (validator, orchestrator, etc.).

### Edge: usuario interrumpe mid-interview ("stop")

→ Guardar inputs parciales en stash + reportar gap. NO ejecutar scaffold incompleto.

## Citation grammar

- [memory:lessons#L-004] — test diagnóstico binario-vs-trinario.
- [memory:decisions#D-014] — boundary case template (skill SIN selector).
- [memory:decisions#D-015] — doctrine refinada (selector presence determina).
- [memory:decisions#D-018] — skill-creator binary mode (guided / template-only).

## Refusals

- ❌ Saltar Q5 (es la CLAVE para shape ADR).
- ❌ Force-fit L-004 si Q5 = NO (D-014/D-015 doctrine refinada aplica).
- ❌ Aceptar nombre que colisiona (halt en PREFLIGHT antes de scaffold).
- ❌ Ejecutar scaffold con inputs incompletos (esperar CONFIRM).
- ❌ Asumir tier=core sin context — el usuario debe confirmar.
- ❌ Aceptar descripción vaga sin re-preguntar.
