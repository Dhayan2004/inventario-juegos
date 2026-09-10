# tool-filter-workers

> Tool filter explícito por rol de worker en cada pattern. Lección Vercel: -80% tools = +3× rendimiento. Tool filter ESTRICTO previene drift, reduce blast radius, y mantiene a cada worker en su responsabilidad.

## Por qué tool filter

Un agente con todas las tools disponibles tiende a:
- Mezclar research con implementation (Researcher escribe código sin validar primero).
- Mezclar implementation con validation (Implementer marca passing sin Reviewer independent).
- Modificar archivos fuera de su scope (eg: tocar `.claude/memory/*` aunque no debería — R5 violation silenciosa).

Tool filter explícito por rol previene esto **a nivel de capability**, no de discipline. El agente literalmente no puede invocar tools fuera de su filter.

## Filters por pattern

### Pattern Coordinator

Coordinator dispatcha sub-agents secuencialmente, uno por fase. Cada fase tiene un sub-agent con tool filter según el skill que invoca:

| Fase del Blueprint | Sub-agent role | Tool filter |
|-------------------|----------------|-------------|
| Fase de planning | Researcher analytical | `Read · Grep · Glob · WebFetch` |
| Fase de generación de UI | Generator | `Read · Edit · Write · Bash` (skill = impeccable o add-ui-kit) |
| Fase de schema/migration | DB worker | `Read · Edit · Write · Bash` (skill = el-migrador) |
| Fase de auth/payments/etc | Add-* worker | `Read · Edit · Write · Bash` (skill = add-login/add-payments/...) |
| Fase de validation | Reviewer | `Read · Grep` + invocación de el-evaluador |
| Fase de security audit | Auditor | invocación de el-guardian |

NO mezclar — cada fase, un sub-agent, un tool filter.

### Pattern Fork

Fork lanza N workers en paralelo (uno por worktree). Cada worker es full-stack pero **solo dentro de su worktree**:

| Aspecto | Filter |
|---------|--------|
| Read | Cualquier path (worker necesita leer todo el repo para context) |
| Edit/Write | **Solo dentro de `.worktrees/sandbox-N/`** y archivos del active feature |
| Bash | git status/log/diff (read-only); npm/yarn/pnpm runs; tests; build; NO git push, NO git branch operations en main |
| Skill invocation | Cualquiera registrado en skills.md (worker invoca según necesidad de su personality + Blueprint phase) |
| Memory write | **Bloqueado** — `.claude/memory/*.md` NO writable (R5) |
| feature_list.json | **Bloqueado** — la-forja maneja state machine post-merge |

Workers en Fork son intencionalmente full-stack (no Researcher+Implementer+Reviewer separados) porque la paralelización viene de los N worktrees, no de roles separados dentro de cada worktree. Cada worker ES Researcher+Implementer+Reviewer secuenciales para SU sandbox.

### Pattern Swarm

Swarm es donde el tool filter cross-role es más estricto. 3 workers, 3 filters distintos:

#### Researcher

```
Tools permitidas:
  - Read    : leer cualquier archivo del repo (target codebase analysis)
  - Grep    : búsqueda de patrones en codebase
  - Glob    : descubrir archivos por pattern
  - WebFetch: research externo si necesario
  - Skill: find-docs (research de libs externas, R13)

Tools bloqueadas:
  - Edit, Write     : NO escribe código
  - Bash            : NO ejecuta nada (read-only role)
  - Skill: cualquier otro (excepto find-docs)
```

Output del Researcher: documento estructurado con approach + paths + riesgos. Texto, NO código.

#### Implementer

```
Tools permitidas:
  - Read           : context y diffs
  - Write, Edit    : crea/modifica archivos según approach del Researcher
  - Bash           : git status/diff (read-only); npm test/build/lint; verification command
  - Skill: ninguna (Implementer NO invoca otros skills — si necesita "skill plumbing", no es atómico → escalar)

Tools bloqueadas:
  - Grep, Glob     : opcional debate, en práctica permitidas para context (no son writes)
  - WebFetch       : NO research — eso era Researcher's job
  - Skill: el-evaluador (NO valida solo — Reviewer separate)
  - Skill: la-forja, la-herreria, etc — meta orchestration, fuera de scope
```

Output del Implementer: diff aplicado + tests run + report estructurado.

#### Reviewer

```
Tools permitidas:
  - Read           : leer diff y outputs del Implementer
  - Grep           : búsqueda de patrones para validación cross-file
  - Skill: el-evaluador  (R7 three-layer validation)

Tools bloqueadas:
  - Edit, Write    : NO modifica nada — solo valida
  - Bash           : NO ejecuta cambios; el-evaluador internamente puede ejecutar verification commands, pero Reviewer MISMO no
  - Skill: cualquier otro (Reviewer es validation-only)
```

Output del Reviewer: PASS o NEEDS_FIX con gap específico.

## R4 enforcement cross-roles

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

**la-forja MISMA** (orchestrator) tiene su propio filter, ya documentado en `SKILL.md`:

```
Tools permitidas:
  - Read, Grep, Glob: lectura de Blueprint, skills.md, outputs de workers
  - Bash limitado:
    * git worktree (Fork)
    * git status/log/rev-parse (todos los patterns)
    * git cherry-pick (Fork merge phase, con confirmation)
    * df -k (PREFLIGHT)
  - Skill: ninguna directa (R4)

Tools bloqueadas:
  - Edit, Write    : NO toca archivos de aplicación
  - Skill          : NO invoca skills directo — solo dispatcha sub-agents que invocan
```

## R5 enforcement

> [memory:CONSTRAINTS.md#R5] — Workers no escriben a memory.

Aplica a TODOS los workers en TODOS los patterns:

- `.claude/memory/*.md` — NO writable.
- Si worker descubre lesson/error/decision → reporta a la-forja → handoff a el-evaluador.
- el-evaluador post-orchestration hace el record.

Filesystem-level check: workers reciben tool filter Edit/Write con scope path explícito que excluye `.claude/memory/`. Si el harness no soporta path-scope filter, dependemos de la disciplina del prompt (instrucción explícita en el system prompt del worker: "NO modifiques .claude/memory/* — eso es responsabilidad de el-evaluador post-orchestration").

## Tabla canónica resumen

| Pattern | Worker | Read | Grep/Glob | Edit/Write | Bash | Skill |
|---------|--------|------|-----------|------------|------|-------|
| Coordinator | (varía por fase) | ✅ | ✅ | ✅ (skill-driven) | ✅ (skill-driven) | el skill de la fase |
| Fork | sandbox-N (full-stack) | ✅ | ✅ | ✅ (worktree only) | ✅ (limitado) | cualquiera registrado |
| Swarm — Researcher | | ✅ | ✅ | ❌ | ❌ | find-docs only |
| Swarm — Implementer | | ✅ | ✅ | ✅ | ✅ | ninguna |
| Swarm — Reviewer | | ✅ | ✅ | ❌ | ❌ | el-evaluador only |
| la-forja MISMA | | ✅ | ✅ | ❌ | git ops only | ninguna (R4) |

## Edge cases

### Edge: Worker en Fork necesita modificar `package.json` en main (no solo en worktree)

→ Refusal. Cambios cross-worktree son responsabilidad del cherry-pick post-merge, NO del worker individual. Si el cambio en `package.json` es esencial para el approach, el worker lo modifica DENTRO de su worktree, y se cherry-pickea como cualquier otro commit.

### Edge: Researcher descubre que el approach require modificación previa al codebase

→ Researcher reporta a la-forja como output. la-forja decide: degradar a Coordinator (fase de prep + fase de implementation), o ampliar scope del Swarm a 4 workers (PrepImplementer + Researcher + Implementer + Reviewer), o escalar a Fork si el approach diverge entre alternativas.

### Edge: Implementer encuentra que el verification command está roto

→ Implementer NO modifica el verification command (eso es scope cambio). Reporta a la-forja, la-forja decide: halt + reportar al humano, o si el fix es trivial, sub-task adicional.

### Edge: Reviewer valida PASS pero el-evaluador internamente reporta L3 system test missing

→ NEEDS_FIX, NO Reviewer override. Reviewer es delegate de el-evaluador — si el-evaluador reporta gap, Reviewer transmite NEEDS_FIX al Implementer.

### Edge: Worker en Fork intenta `npm install <new-package>`

→ Permitido dentro del worktree (modifica `package.json` y `node_modules` del worktree). Pero documentar en RESUMEN.md del worktree para que cherry-pick recommendation lo capture explícitamente — `package.json` cambios cruzan worktrees implícitamente vía cherry-pick.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — orchestrator stays thin (la-forja filter).
- [memory:CONSTRAINTS.md#R5] — workers no escriben a memory (filesystem o discipline filter).
- [memory:lessons#L-004] — pattern selector binary, tool filter es ortogonal al pattern shape.
- [memory:decisions#D5] — Skills Registry validado (R6) + tool filter explícito (lección Vercel).

## Refusals

- ❌ Researcher escribe código (Edit/Write bloqueados — su rol es analytical).
- ❌ Implementer invoca el-evaluador para self-validation (AP3 anti-pattern + R4 — Reviewer separate).
- ❌ Reviewer ejecuta cambios (Edit/Write bloqueados — su rol es validation-only).
- ❌ Cualquier worker escribe a `.claude/memory/*.md` (R5).
- ❌ la-forja MISMA invoca skills directo (R4 — solo dispatch).
- ❌ Tool filter laxo "por practicidad" — la rigidez del filter ES la garantía.
