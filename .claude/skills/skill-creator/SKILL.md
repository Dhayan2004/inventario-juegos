---
name: skill-creator
description: >
  Skill meta wizard que guía la creación de un nuevo skill de Forja. Scaffolding
  guiado vía entrevista (5 preguntas: name, description, tier, shape, selector
  presence) que produce un skill folder listo para authoring real — NO el skill
  terminado. Output: SKILL.md template con frontmatter completo + secciones
  canónicas + prompts/ con README placeholder + references/ con README placeholder
  + tests/dry-run.sh boilerplate (E-008 enforced from birth + F3-S10/S11 frictions
  absorbidas preventivamente). Binary mode (D-018): guided (default — entrevista
  interactiva) o template-only (override — scaffold directo a partir de inputs
  ya preparados, sin entrevista). NO PAUSE: ambos modos siempre disponibles, no
  requieren upstream user action específica del selector. Pregunta clave en la
  entrevista: "¿el skill nuevo tiene un selector entre N providers/approaches?"
  → si SÍ, registra D-NNN binary/trinary; si NO, registra D-NNN análogo a D-014
  (pipeline/validator-fijo/composer shape sin selector). El skill resultante
  arranca con la doctrine L-004 + D-009..D-018 incorporada desde scaffold. NO
  aplica R10 (no genera UI), R14 (no agentic tools), el-guardian (no toca
  secrets ni código de producción). Output final: instrucción "abre .claude/
  skills/<nombre>/SKILL.md y empieza a authorizar."
tier: core (meta)
requires: directorio Forja base accesible (.claude/skills/ existe). Nombre del skill nuevo NO debe colisionar con skills existentes (verificar via skills.md registry).
fallback: Sin .claude/skills/ → halt: "estructura  no detectada. ¿Estás en el repositorio Forja correcto?". Si nombre colisiona → halt: "skill 'X' ya existe en registry. Sugerir rename o explícitamente confirmar override (peligroso)". Si entrevista interrumpida (usuario dice "stop" mid-flow) → guardar inputs parciales en stash y reportar gap.
dependencies: []
---

# skill-creator

> *"El meta-skill. Genera el scaffold para que cualquier skill nuevo arranque con la doctrine Forja absorbida desde su línea 1."*

Skill meta. NO ejecuta lógica de negocio, NO genera código de aplicación, NO toca brand. Su output es un **scaffold** listo para que el autor (humano o agente) llene los placeholders y produzca un skill terminado. Garantiza que cualquier skill nuevo arranque con: frontmatter completo, PREFLIGHT explícito, R/L/D citation grammar, dry-run.sh boilerplate con E-008 + F3-S10/S11 frictions absorbidas preventivamente.

**Output: scaffold, NO skill terminado.** El authoring real (PREFLIGHT específico, prompts, references, dry-run.sh checks reales) corre después, con el agente abriendo el `SKILL.md` recién creado.

> **Estándar de autoría (S4) — no negociable.** Todo scaffold se genera **contra** [`../../references/SKILL_AUTHORING.md`](../../references/SKILL_AUTHORING.md): eje model/user-invoked, `description` de una rama-gatillo (~30 tokens, sin sprawl), techo de SKILL.md (500–2000 tokens de cuerpo) con progressive disclosure a `references/`, la plantilla de secciones fija (When-to-Use → PREFLIGHT → Workflow → Verification → Refusals → Tool filter → Citations → Integraciones), leading words de la metáfora Forja + ontología, y los failure modes que `el-evaluador` audita al registrar el skill (R6). skill-creator produce el scaffold; `el-evaluador` lo verifica contra ese estándar.

## PREFLIGHT — suave, halt en blockers reales

```
1. ¿Existe .claude/skills/?
   - Sí → continuar
   - No → halt: "estructura  no detectada. ¿Estás en el repositorio
            Forja correcto? cd al root del proyecto Forja."

2. ¿El nombre del skill nuevo ya existe?
   - Verificar contra .claude/memory/skills.md + ls .claude/skills/
   - Si existe → halt: "skill '<nombre>' ya existe en registry. Sugerir
                  rename o explícitamente confirmar override (peligroso —
                  scaffold sobrescribe SKILL.md existente)."
   - Si NO existe → continuar

3. ¿El usuario tiene contexto suficiente para responder la entrevista?
   - Si responde "no sé qué tier es" o ambigüedad alta → modo guided
     extendido (cita ejemplos de skills existentes para ayudar a decidir).
   - Si tiene claridad → modo guided estándar (entrevista directa).
```

skill-creator NO halt en archivos opcionales. Halt-blocked solo en estructura missing o nombre colisionando.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario quiere crear un skill nuevo de Forja | Coordinator / agente / humano |
| Usuario dice "creá un skill X", "necesito un skill que haga Y", "scaffold skill Z" | Coordinator |
| Triage de el-evaluador detecta gap recurrente que requiere skill nuevo | el-evaluador |
| Phase 5+ orchestrator wizards componen cadenas que requieren skill nuevo | orchestrator |

NO se invoca para: modificar skill existente (eso es authoring directo), planificar feature de aplicación (la-herreria), implementar feature (la-forja / el-golpe / el-tajo), audit (el-evaluador / el-guardian).

## Mode selector (binary D-018)

| Modo | Trigger | Use case |
|------|---------|----------|
| **Guided** (default) | Usuario invoca `/skill-creator` interactivo | Crear skill desde idea — entrevista 5 preguntas + scaffold |
| **Template-only** (override) | Usuario provee inputs ya preparados (YAML structured input) | CI/automation, scripted scaffold |

`prompts/interview.md` implementa el guided mode. `prompts/scaffold.md` implementa la generación de archivos (compartido entre ambos modes).

**L-004 test aplicado:**

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Sin .claude/skills/ (PREFLIGHT) | Sí (cd a Forja repo) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Nombre colisiona (PREFLIGHT) | Sí (rename) | **PREFLIGHT halt, NO PAUSE genuino** |
| Usuario quiere modo template-only sin inputs preparados | NO — guided siempre disponible (degrada graceful) | NO PAUSE |
| Usuario quiere modo guided pero responde "no sé" a todo | NO — modo guided extendido con ejemplos | NO PAUSE |

**Conclusión D-018:** **BINARY** confirmed. guided default + template-only override. NO PAUSE — ambos modos siempre disponibles.

## Flujo guiado canónico

```
1. PREFLIGHT (3 checks above)
   ↓
2. ENTREVISTA (prompts/interview.md, 5 preguntas)
   - Q1: nombre del skill (kebab-case, metalúrgico si core)
   - Q2: descripción 1 línea
   - Q3: tier (core | optional | hidden)
   - Q4: shape (lightweight | orchestrator | pipeline | validator | meta)
   - Q5: ¿selector entre N providers/approaches? → determina D-NNN shape
   ↓
3. CONFIRM
   - Mostrar resumen de inputs al usuario
   - Esperar "go" o ajuste
   ↓
4. SCAFFOLD (prompts/scaffold.md)
   - Crear .claude/skills/<nombre>/SKILL.md (template completo)
   - Crear .claude/skills/<nombre>/prompts/ (con README.md placeholder)
   - Crear .claude/skills/<nombre>/references/ (con README.md placeholder)
   - Crear .claude/skills/<nombre>/tests/dry-run.sh (boilerplate L1+L2+L3)
   ↓
5. INSTRUCCIÓN FINAL
   - Mensaje: "Skill scaffolded en .claude/skills/<nombre>/.
              Próximo paso: abrí SKILL.md y empezá a authorizar."
   - Si selector → recordar: "ADR D-NNN reservado, registrar shape al cerrar."
```

## Las 5 preguntas (entrevista guiada)

Detalle completo en [`prompts/interview.md`](prompts/interview.md). Resumen:

### Q1 — Nombre

- Kebab-case obligatorio.
- Si tier core → preferir nombre metalúrgico (la-X, el-X) coherente con la metáfora Forja (forja, yunque, crisol, herrería, tajo, golpe, evaluador, guardián, migrador, supervisor).
- Si tier optional → nombre descriptivo en inglés (add-X, build-X, find-X, etc.).
- Si tier hidden → nombre prefijado o convención específica.
- Verificar contra `.claude/memory/skills.md` para evitar colisión.

### Q2 — Descripción 1 línea

- Multi-line YAML permitido (description: > en frontmatter).
- Foco: qué hace, cuándo se usa, output esperado.
- Evitar lenguaje vago ("ayuda al usuario con X").

### Q3 — Tier

- **core**: skill que cualquier proyecto generado con Forja necesita. 21 skills core actuales (post-F3-S12).
- **optional**: skill que se invoca solo si proyecto requiere (add-login solo si hay auth, etc.).
- **hidden**: skill que requiere instalación adicional (Hermes, agente externo, etc.).

### Q4 — Shape

- **lightweight**: prompt-only, NO templates folder, <250 LOC SKILL.md, 1-3 prompts (primer, sprint, el-tajo, el-golpe, skill-creator son lightweight).
- **orchestrator**: dispatcha sub-agents, R4 enforced, multiple patterns posibles (la-forja).
- **pipeline**: secuencial con resume detection, sin selector entre providers (el-crisol).
- **validator**: audita output, R7 three-layer o checks específicos (el-evaluador, web-quality, el-guardian).
- **meta**: actúa sobre el harness mismo (skill-creator).

### Q5 — Selector presence (CLAVE para D-NNN)

> ¿El skill tiene un selector entre N providers/approaches alternativos dentro?
>
> - **Sí** → aplicar L-004 test → binary o trinary según degenerate case requiere upstream user action.
>   - Reservar D-NNN binary o trinary al cerrar el authoring.
> - **No** → ADR propio análogo a D-014 al cerrar (sequential pipeline / validator-fijo / etc.).

Esta pregunta determina la shape ADR. **NO force-fit L-004** si no hay selector — D-014/D-015 doctrine refinada aplica.

## Output del scaffold

`prompts/scaffold.md` genera 4 artifacts:

```
.claude/skills/<nombre>/
├── SKILL.md                       ← template completo con frontmatter + secciones
├── prompts/
│   └── README.md                  ← placeholder con instrucción
├── references/
│   └── README.md                  ← placeholder con instrucción
└── tests/
    └── dry-run.sh                 ← boilerplate L1+L2+L3 ejecutable
```

### SKILL.md template

`references/skill-template.md` documenta el contenido canónico, anotado.

Secciones generadas:

- Frontmatter completo (name/description/tier/requires/fallback/dependencies).
- PREFLIGHT placeholder (suave o duro según shape).
- Activación (tabla "cuándo se invoca + quién").
- Loop o flujo principal (placeholder específico por shape).
- Output shape (placeholder con ejemplo).
- Reglas operativas (numeradas, mínimo 5).
- Refusals (mínimo 5).
- Tool filter (estimado por shape).
- Citation grammar (tabla con R/L/D apropiados).
- Integración con otros skills (tabla de boundaries).

### tests/dry-run.sh boilerplate

`references/dry-run-template.md` documenta el contenido canónico anotado.

El boilerplate incluye:

- Header con E-008 awareness comment + F3-S10/S11 frictions cited preventivamente.
- L1 file presence checks.
- L1 frontmatter checks.
- L2 contract awareness checks (placeholders por shape).
- L3 escenarios canónicos (placeholders).
- D-NNN cita reservada.
- Summary block estándar.

## Reglas operativas

1. **NO genera el skill terminado.** Solo el scaffold. El authoring real corre después en sesiones del autor (humano o agente).

2. **Verificar nombre antes de scaffold.** Colisión = halt. NO sobrescribir SKILL.md existente sin confirmation explícita y datada.

3. **Pregunta de selector es CLAVE.** Q5 determina shape ADR. NO force-fit. Si el autor no sabe, modo guided extendido pregunta sub-preguntas hasta clarity.

4. **Boilerplate dry-run.sh con E-008 from birth.** Comentarios al header del test recordando: `grep -E` con `|` plain, `\|` PROHIBIDO, ventanas `-A` flexibles, mode patterns relax con `( N)?`, `-i` para case-insensitive, `--` separator para patterns que empiezan con `--`.

5. **No aplica R10/R14/el-guardian.** skill-creator no genera UI ni código de producción.

6. **Output instrucción final clara.** Después del scaffold: "Abre .claude/skills/<nombre>/SKILL.md y empieza a authorizar." NO ambigüedad sobre próximo paso.

7. **Modo template-only acepta YAML structured.** Si usuario invoca con inputs preparados (ej: vía CI/automation), saltar entrevista y ir directo a scaffold.

8. **D-NNN siguiente reservado al cerrar.** skill-creator NO escribe a memory (R5 — solo el-evaluador). Pero anota en el SKILL.md template el comentario "// TODO: D-NNN ADR (binary | trinary | pipeline-shape) post-authoring" para que el autor sepa qué registrar al cerrar.

9. **Forward-compatible con orchestrator wizards.** skill-creator es invocable directo por humanos Y por wizards (Phase 5+) que componen cadenas de skills nuevos.

10. **NO modificar skills.md.** El registry update lo hace el-evaluador post-authoring (R5). skill-creator solo crea el folder + archivos del skill nuevo.

11. **D-018 binary cita explícita.** En SKILL.md template generado, recordar cita L-004 + D-018 si el skill nuevo aplica el patrón.

## Refusals

- ❌ Sobrescribir skill existente sin confirmation explícita.
- ❌ Generar el skill terminado (solo scaffold).
- ❌ Modificar `.claude/memory/skills.md` (R5 — eso es el-evaluador).
- ❌ Modificar `.claude/memory/decisions.md` (R5).
- ❌ Skip de Q5 selector (es la CLAVE para shape ADR).
- ❌ Force-fit L-004 al skill nuevo si Q5 = "no" (D-014 doctrine refinada).
- ❌ Generar SKILL.md sin frontmatter completo.
- ❌ Generar dry-run.sh sin E-008 awareness comment.
- ❌ Halt en archivos opcionales (la decisión es del autor durante authoring).
- ❌ Generar templates folder en skills lightweight (anti-pattern por shape).

## Tool filter

`Read · Edit · Write · Grep · Glob · Bash` (limited).

NO Skill direct (R4 — meta wizard, no invoca otros skills).

Bash limitado a:
- `ls .claude/skills/` (verificación de colisión)
- `mkdir -p .claude/skills/<nombre>/{prompts,references,tests}` (scaffold)
- `chmod +x .claude/skills/<nombre>/tests/dry-run.sh` (executable)

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md (skill-creator NO escribe memory) |
| Lesson | `[memory:lessons#L-004]` | en interview.md Q5 (selector presence) |
| Decision | `[memory:decisions#D-014]` | en interview.md Q5 (boundary case ADR ref) |
| Decision | `[memory:decisions#D-015]` | en interview.md Q5 (refinement doctrine ref) |
| Decision | `[memory:decisions#D-018]` | en SKILL.md (skill-creator binary mode) |
| Error | `[memory:errors#E-008]` | en references/dry-run-template.md (E-008 awareness from birth) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `el-evaluador` | downstream. Post-authoring del skill nuevo, el-evaluador registra entry en skills.md + ADR D-NNN en decisions.md. |
| `find-docs` | NO direct — skill-creator no genera código contra libs externas. Pero el SKILL.md template puede recomendar [find-docs] como dependencia si el shape lo amerita. |
| `la-herreria` | NO direct. Distinct: la-herreria planifica features de aplicación. skill-creator scaffolda meta (skills del harness). |
| `la-forja` | NO direct — la-forja invoca skills, no los crea. Si Phase 5+ orchestrator wizards componen cadenas de skills nuevos, podrían invocar skill-creator como sub-tool. |
| `primer` | upstream. Si skill-creator arranca sin contexto del repo Forja, primer carga primero. |
| `sprint` | NO direct. sprint refina skills existentes; skill-creator scaffolda nuevos. |
| `el-tajo` / `el-golpe` | NO direct. Tajos y golpes operan sobre código de aplicación, no sobre skill scaffolding. |

## Output handoff

```markdown
## skill-creator handoff

**Skill name:** <nombre>
**Tier:** <core | optional | hidden>
**Shape:** <lightweight | orchestrator | pipeline | validator | meta>
**Selector presence (Q5):** <YES — binary/trinary expected | NO — pipeline/validator-fijo expected>

**Files generados:**
- .claude/skills/<nombre>/SKILL.md (template completo, ~150-250 LOC)
- .claude/skills/<nombre>/prompts/README.md (placeholder)
- .claude/skills/<nombre>/references/README.md (placeholder)
- .claude/skills/<nombre>/tests/dry-run.sh (boilerplate L1+L2+L3)

**ADR reservado:** D-NNN (siguiente disponible) — registrar al cerrar authoring.

**Próximo paso:**
→ Abrí `.claude/skills/<nombre>/SKILL.md` y empezá a authorizar.
→ Cuando termines, invocá `el-evaluador` para registrar entry en skills.md + ADR D-NNN.

**Memory entries propuestas (NONE — skill-creator no escribe memory).**
```

NO el-guardian handoff. NO el-evaluador post-validation directo (el-evaluador valida los commits del authoring posterior, no el scaffold).

---

*"skill-creator es el meta-skill que hace que cada skill nuevo arranque con la doctrine Forja absorbida desde su línea 1. Sin él, cada skill nuevo redescubre L-004, R5, E-008 desde cero."*
