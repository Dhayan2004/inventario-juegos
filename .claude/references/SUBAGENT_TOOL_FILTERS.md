# Tool-filtering de sub-agentes de Forge Enterprise (C2)

> **Qué es esto.** La doctrina de **tool-filtering por rol de worker**: qué tools ve cada sub-agente que
> despacha un orchestrator (Coordinator, La Forja, el-tajo, el-golpe, el-crisol). Es el contrato que hace
> que el multi-agente de Forge sea **seguro por construcción** — un Reviewer nunca puede editar lo que
> revisa, un Researcher nunca escribe. Formaliza el tool-filter ya esbozado en `AGENTS.md § Multi-Agent`
> y lo eleva a referencia citable.
>
> **Decisión (`docs/06` §9-H, Q25 — `[rec]`, tomada por Carlos):** **MANTENER los patrones
> Coordinator/Fork/Swarm de Forja; NO adoptar los 12 subagents tipados de Forge Pro** (`db-architect`,
> `frontend-specialist`, `backend-specialist`, `qa-auditor`, `design-critic`, `testing-engineer`,
> `validacion-calidad`, `supabase-admin`, `observability-engineer`, `vercel-deployer`, `codebase-analyst`,
> `gestor-documentacion`). El motivo es un choque de seguridad concreto, no una preferencia estética
> (§1). Fuente: `docs/06` §C2/§9-H · `docs/01` §4.4.

- **Versión:** v0.2.0 (2026-07-02, Q-FORK-AGENT · D-033 — enforcement estructural vía `agent:` + `.claude/agents/`) · v0.1.0 (2026-06-30, C2 · Calidad — tool-filtering de sub-agentes)
- **Formaliza:** `AGENTS.md § Multi-Agent` (tool-filter por rol) → contrato citable.
- **Regla de enforcement:** `[memory:CONSTRAINTS.md#R4]` (orchestrator thin) + `[memory:CONSTRAINTS.md]` AP3 (el que genera no se auto-evalúa) + R5 (sole writer de memoria = `el-evaluador`).

---

## 1. Por qué NO los 12 subagents tipados de Pro (el choque con AP3)

Forge Pro trae una carpeta `core/agents/` con 12 subagents tipados. El **hallazgo de riesgo** (`docs/01`
§4.4): sus agentes de QA declaran tools **sin filtro de escritura** — `qa-auditor.md` línea 5 y
`validacion-calidad.md` línea 4 listan `tools: …, Write, Edit, …`. Es decir, **el validador puede
escribir código**. Eso choca de frente con la doctrina de Forge:

| Regla de Forge | Qué exige | Cómo la rompe un QA con `Write` |
|----------------|-----------|---------------------------------|
| **AP3** (self-eval prohibido) | el agente que **genera** NO **valida** (Implementer ≠ Reviewer) | un QA que puede editar puede "arreglar" lo que audita → se auto-evalúa |
| **R5** (sole writer de memoria) | sólo `el-evaluador` escribe `.claude/memory/**` | un QA tipado con `Write` amplio puede tocar la memoria del harness |
| **R4** (orchestrator thin) | el orchestrator sólo despacha; los workers ejecutan | 12 roles tipados invitan a un "fat orchestrator" que rutea por tipo en vez de por patrón |

El multi-agente de Forge **no vive en una carpeta `agents/`**: vive como **patrones** (Coordinator /
Fork / Swarm) dentro del skill `la-forja`, con workers cuyo **tool-filter es el mecanismo de
enforcement**. No hay 12 tipos rígidos; hay **3 roles con tool-filter** que se instancian según el
patrón. Menos superficie, misma expresividad — la lección Vercel aplicada al multi-agente.

---

## 2. El tool-filter canónico por rol de worker

Todo sub-agente despachado por un orchestrator recibe **exactamente uno** de estos cuatro perfiles. El
filtro es la garantía: un rol **no puede** hacer lo que su perfil no incluye, aunque el prompt se lo
pida (o lo induzca un prompt injection).

| Rol | Tools permitidos | Prohibido explícito | Por qué |
|-----|------------------|---------------------|---------|
| **Researcher** | `Read` · `Grep` · `Glob` · `WebFetch` (+ `find-docs` para libs externas) | **NO `Write`** · NO `Edit` · NO `Bash` | Investiga y devuelve un informe; no muta el árbol. Sin `Write` no puede "dejar rastro" fuera de su output. |
| **Implementer** | `Read` · `Write` · `Edit` · `Bash` | NO escribir `.claude/memory/**` (R5) · NO auto-marcar `passing` (AP5/AP8) | Es el único que **genera código**. Tiene el set completo de mutación acotado al target de la feature. |
| **Reviewer** | `Read` · `Grep` · skill `el-evaluador` | **NO `Write`** · **NO `Edit`** — enforce AP3 | Revisa y **nunca edita lo que revisa**. Si algo no pasa, marca `NEEDS_FIX` y devuelve al Implementer. |
| **Critic** (`el-critico-de-diseno`, D-037) | `Read` (imágenes) · `Bash` (solo inspección de imagen) | **NO `Write`** · **NO `Edit`** · **NO `Grep`/`Glob`** — ve píxeles, no repo | Juez visual en contexto **fresco**: recibe screenshots, nunca código ni el hilo. Sin `Grep`/`Glob` no puede "explorar un momento". Devuelve JSON (`gaps`, `penalties`, `score`); el orquestador (`el-pulidor`) escribe el reporte y aplica el cap (`QUALITY_GATES.md` §4). |

**La invariante que enforcea AP3 por construcción:** el **Reviewer no tiene `Write`/`Edit`**. No es una
promesa de comportamiento del prompt — es una ausencia de capacidad. Un Reviewer que quisiera "arreglar"
lo que audita **no tiene la herramienta para hacerlo**; su único camino es devolver `NEEDS_FIX` al
Implementer. Así, Implementer ≠ Reviewer no es una convención frágil, es una propiedad del tool-filter.

> Coincide 1:1 con `AGENTS.md § Multi-Agent`: *"Researcher: Read+Grep+Glob+WebFetch · Implementer:
> Read+Write+Edit+Bash · Reviewer: Read+Grep + skill `el-evaluador`."* Este doc es la versión citable.

### El enforcement estructural en los skills forkeados (Q-FORK-AGENT · `[memory:decisions#D-033]`)

Desde D-033 el filtro de los **3 skills forkeados** ya **no es prosa: es ESTRUCTURAL**, enforced por el
runtime de Claude Code. Habilitador: D-032 validó Q-FORK-VER (`context: fork` SÍ despacha a subagente en
CC 2.1.197). Mecanismo (validado empíricamente por harness/transcript, disciplina
`[memory:lessons#L-009]`):

- El frontmatter del SKILL.md declara `agent: <nombre>` (junto a `context: fork`) → el fork se despacha
  al subagente [`../agents/<nombre>.md`](../agents/), cuyo campo `tools:` es **whitelist dura**: una tool
  fuera de la lista no existe en ese contexto — el runtime rechaza la llamada con `tool_use_error`
  *"No such tool available: Edit. Edit exists but is not enabled in this context."*
  [web:code.claude.com](https://code.claude.com/docs/en/sub-agents.md)
- **`allowed-tools` del SKILL.md NO es el mecanismo** — trampa conocida: los docs son explícitos en que
  solo pre-aprueba permisos (*"It does not restrict which tools are available"*)
  [web:code.claude.com](https://code.claude.com/docs/en/skills.md). Por eso `project-auditor` (el 4º skill
  forkeado, que declara `allowed-tools`) sigue con filtro de prosa — candidato a la misma conversión.

| Skill forkeado | Rol (§2) | `tools:` del agente | Lo que NO tiene y por qué |
|---|---|---|---|
| `el-guardian` | Reviewer | Read · Grep · Glob · Bash · Write · Skill | **Sin `Edit`** — no puede editar lo que audita (AP3 por construcción). Write = solo su reporte |
| `el-migrador` | Implementer acotado | Read · Grep · Glob · Bash · Write · Skill | **Sin `Edit`** — crea migraciones nuevas, nunca edita las aplicadas (append-only por construcción) |
| `el-evaluador` | Evaluator / sole writer | Read · Grep · Glob · Bash · Edit · Write | Sin WebFetch/NotebookEdit/Agent/Skill. **Conserva Edit/Write**: es el único writer legítimo de estado (R5, memoria + `feature_list.json`) — quitárselos rompería el harness. Su AP3/path-scope lo enforzan el hook `commit-msg` + prompt, no el filtro |

**Matices honestos del mecanismo:**

1. **El filtro es grueso** (tool sí/no, sin path-scoping): el scope por ruta (reporte en `docs/security/`,
   `supabase/migrations/**`, `.claude/memory/**`) sigue siendo regla de prompt + hook (R5 vía `commit-msg`).
   Capa complementaria: el permission-layer del host trata `.claude/**` como *sensitive files*.
2. **`Skill` se incluye en guardian/migrador** porque el perfil Reviewer (§2) incluye "skill `el-evaluador`",
   el guardian invoca `/codex:adversarial-review`, y el migrador depende de `find-docs` (R13).
3. **Entornos con deferred-tools:** dentro del fork filtrado, `Grep`/`Glob` pueden no servirse aunque estén
   whitelisted (y ToolSearch no carga schemas ahí — tampoco de tools fuera de la lista: **no hay bypass**).
   Fallback operativo: `grep`/`rg` vía Bash. La invariante (Edit ausente) no depende de esto.
4. El agente custom también admite `model:` (cruza con `MODEL_PER_ROLE.md`) — hoy no se fija: heredan el
   modelo de la sesión.

El contrato lo gatea `scripts/hooks/tests/fork-agents.test.sh` (15 casos: binding + whitelist + invariante
Edit) dentro de `make test-hooks` / meta-CI.

---

## 3. Cómo mapean los roles a los tres patrones (Coordinator / Fork / Swarm)

Los roles del §2 son **estables**; el patrón decide cuántos y cómo se coordinan (`AGENTS.md § Multi-Agent`,
`[memory:decisions#D-013]` para Swarm):

| Patrón | Caso de uso | Cómo instancia los roles |
|--------|-------------|--------------------------|
| **Coordinator** (síntesis secuencial) | sesiones largas | el orchestrator despacha Researcher → Implementer → Reviewer en serie, sintetiza entre fases |
| **Fork** (paralelo con worktrees) | `la-forja` con N sandboxes | N Implementers en paralelo (uno por worktree), cherry-pick al final con confirmación humana |
| **Swarm** (workers tool-filtered one-shot) | `el-tajo` / `el-golpe` | un puñado de workers tool-filtered para una tarea acotada; sin worktrees |

En **todos** los patrones el orchestrator permanece **thin** (R4): lee la feature, decide el patrón,
**despacha** — nunca invoca un skill ni edita código de producción directamente. El único que escribe
memoria sigue siendo `el-evaluador` (R5), al que el Reviewer llama vía skill.

---

## 4. La regla de conversión — importar un especialista de Pro sin romper AP3

Si alguna vez un cliente enterprise justifica traer un **agente especialista** de Forge Pro
(`db-architect`, `qa-auditor`, `design-critic`, `supabase-admin`…), **no se adopta tal cual**. Se
**convierte a consultor read-only** con este protocolo:

1. **Quitar `Write` y `Edit`** de su tool-filter. Un especialista importado es, por default, un
   **Researcher** (§2): `Read + Grep + Glob + WebFetch`.
2. **Su output es un `.md`**, no un diff. El especialista **recomienda**; no aplica. (Ej.: `db-architect`
   produce un informe de esquema, no una migración; `el-migrador` decide si la estampa.)
3. **`el-evaluador` decide si aplicar.** El consultor no marca `passing` ni escribe memoria (R5/AP3/AP5).
   Un Implementer materializa la recomendación **si** el evaluador la aprueba; el especialista jamás
   cierra su propio loop.
4. **Los especialistas QA de Pro (`qa-auditor`, `validacion-calidad`) NO se importan como escritores** —
   su función ya la cubre el **Reviewer + `el-evaluador`** (§2), que es el único firmante de `PASS`.
   Importarlos con `Write` sería exactamente el anti-patrón AP3 que esta doctrina existe para prevenir.

> **La frontera con `impeccable` (analogía de generación vs crítica).** Igual que `impeccable` **genera**
> UI y un evaluador/crítico la **audita** sin generar, un especialista importado **critica/asesora** sin
> mutar. La generación y la crítica **nunca las hace el mismo agente** — es AP3 aplicado al import.

---

## 5. Refusals (lo que esta doctrina prohíbe)

- ❌ Un Reviewer con `Write` o `Edit` (viola AP3 por construcción).
- ❌ Un Researcher con `Write` (rompe la separación investigar/mutar).
- ❌ Un worker cualquiera (que no sea `el-evaluador`) con capacidad de escribir `.claude/memory/**` (R5).
- ❌ Importar un agente tipado de Pro **conservando** su tool-filter permisivo (`…, Write, Edit`).
- ❌ Un orchestrator que edite código de producción o invoque un skill directamente (R4 — fat orchestrator).
- ❌ Un especialista importado que aplique su propia recomendación o marque `passing` (AP3 + AP5).

---

## 6. El contrato en una frase

Forge no tiene 12 agentes tipados; tiene **3 roles con tool-filter** (Researcher read-only, Implementer
que muta, Reviewer que audita **sin poder editar**) que se instancian en 3 patrones (Coordinator / Fork /
Swarm). El filtro **es** el enforcement: AP3 (Implementer ≠ Reviewer) no se promete, se hace imposible de
violar quitándole `Write` al que revisa. Cualquier especialista que se importe entra como **consultor
read-only** que produce un `.md`, y `el-evaluador` decide si se aplica.

## Sources
- [Claude Code docs — Agent Skills (`allowed-tools` ≠ restricción)](https://code.claude.com/docs/en/skills.md) ·
  [Subagents (`tools:` = allowlist)](https://code.claude.com/docs/en/sub-agents.md) — mecanismo D-033.
- `[memory:decisions#D-032]` (Q-FORK-VER validada — habilitador) · `[memory:decisions#D-033]` (Opción B
  implementada) · `[memory:lessons#L-009]` (harness > self-report).
- `docs/06` §C2 + §9-H (Q25 — decisión: mantener Coordinator/Fork/Swarm, `[rec]`).
- `docs/01` §4.4 — los 12 subagents tipados de Pro + el hallazgo de riesgo (`qa-auditor.md`:5,
  `validacion-calidad.md`:4 declaran `Write`/`Edit` → choca con AP3).
- `AGENTS.md § Multi-Agent` — tool-filter por rol (Researcher / Implementer / Reviewer) que este doc formaliza.
- `[memory:CONSTRAINTS.md#R4]` (orchestrator thin) · `[memory:CONSTRAINTS.md]` AP3 (self-eval prohibido) · R5 (sole writer de memoria).
