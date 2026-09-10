# Pattern selector rationale

> Por qué la-forja es BINARY-shaped (default + 2 overrides, sin PAUSE). Aplicación del [memory:lessons#L-004] test diagnóstico cross-skill, sexta validación.

## El test diagnóstico (L-004 verbatim)

> [memory:lessons#L-004]:
>
> ¿Existe un degenerate case que requiera acción **upstream** del usuario (constituir entidad legal, infra propia, accounts developer, etc.) **antes** de poder re-invocar el skill productivamente?
>
> - Si **SÍ** → trinario (default + override + PAUSE)
> - Si **NO** → binario (default + override solo)

## Aplicación a la-forja

la-forja selector entre 3 patterns: Coordinator, Fork (default), Swarm. Aplico el test caso por caso:

| Caso del Blueprint | ¿Upstream user action requerida? | Resultado |
|---|---|---|
| Sin Blueprint | Sí — correr la-herreria primero | **PREFLIGHT halt, NO PAUSE genuino** |
| Sin active feature | Sí — pickear del backlog | PREFLIGHT halt, NO PAUSE |
| Skills.md missing entry | Sí — registry incoherente | PREFLIGHT halt, NO PAUSE |
| Blueprint con dependencias secuenciales | NO — Coordinator pattern lo maneja | NO PAUSE |
| Blueprint con sub-tasks atómicos | NO — Swarm lo maneja | NO PAUSE |
| Blueprint paralelizable, disco lleno | NO — degradar a Coordinator graceful | NO PAUSE |
| Conflictos circulares en cherry-pick | NO — degradar a Coordinator + reportar | NO PAUSE |
| git worktree no disponible | NO — degradar a Coordinator | NO PAUSE |
| Worker stuck N>5 minutos | NO — descartar worktree, reportar | NO PAUSE |
| TODOS los workers fallan | NO — re-orchestrate con Coordinator o el-yunque manual | NO PAUSE |

## Distinción crítica: PREFLIGHT halt ≠ PAUSE

PREFLIGHT halt cubre faltantes mandatorios para que la-forja arranque:
- Sin Blueprint → halt + handoff a la-herreria.
- Sin active feature → halt + sugerir backlog.

Estos son **gates de entrada**, no PAUSE del pattern selector. La-herreria es upstream del flow general (la-herreria → la-forja), no del selector entre Coordinator/Fork/Swarm.

PAUSE en L-004 sentido es: "el usuario debe constituir algo upstream **antes** de poder re-invocar este skill productivamente". Ej:
- D-010 add-payments PAUSE: "constituir empresa registrada para usar Stripe como Merchant of Record".
- D-011 add-emails PAUSE: "constituir SMTP self-hosted para data sovereignty banking/healthcare".

la-forja NO tiene equivalente. Los 3 patterns están siempre disponibles. El usuario nunca debe "constituir" Coordinator antes de re-invocar — Coordinator existe siempre como graceful fallback de Fork.

## Validación cross-skill (D-009 → D-013)

| ADR | Skill | Estructura | PAUSE? | Razón |
|-----|-------|------------|--------|-------|
| D-009 | add-login | binary | NO | Supabase/Insforge ambos disponibles sin upstream action |
| D-010 | add-payments | trinary | YES | PAUSE = constituir empresa MoR |
| D-011 | add-emails | trinary | YES | PAUSE = constituir SMTP self-hosted |
| D-012 | add-mobile | binary | NO | PWA siempre fallback graceful |
| **D-013** | **la-forja** | **binary** | **NO** | **Los 3 patterns siempre disponibles, ningún degenerate case requiere upstream user action** |

D-013 confirma L-004 cross-skill por sexta vez. Pattern: 3 binary, 2 trinary. La generalización empírica: PAUSE existe cuando el degenerate case requiere acción upstream del usuario (entidad legal, infra propia); NO existe cuando el degenerate case es siempre subset disponible del default (PWA es subset de native, Coordinator es subset disponible si Fork falla).

## ¿Por qué no es trinary aunque hay 3 patterns?

Pregunta natural: "Hay 3 patterns (Coordinator/Fork/Swarm). ¿No es 'trinary'?"

Respuesta: L-004 distingue **estructura del selector**, no cantidad de opciones. La estructura es:

- **Binary:** default + override(s), todos siempre disponibles, NO hay halt-blocked-pre-upstream-action.
- **Trinary:** default + override + **PAUSE** halt-blocked específico que requiere upstream user action.

la-forja tiene 1 default (Fork) + 2 overrides (Coordinator, Swarm), todos siempre disponibles. La estructura es BINARY incluso con 3 opciones, porque el shape es "default + alternativas no-halt-blocked".

Si la-forja tuviera un caso "PAUSE = el usuario debe constituir worktree-capable git instalado para re-invocar Fork", eso sería trinary. Pero git worktree es siempre instalable, y Fork degrada graceful a Coordinator si falla. NO PAUSE genuino.

## Predicción vs outcome

**Predicción** (durante session kickoff, antes del build): la-forja es binary, NO PAUSE.

**Outcome** (post-build de los prompts y references): la-forja confirma binary. NO emergió ningún caso degenerate genuino que requiera upstream user action específica del pattern selector.

Single match esperado. D-013 documenta confirmación, NO descubrimiento de trinary inesperado.

## Implicación para futuros skills

Skills futuros con pattern selector multi-option deben aplicar el mismo test:

```
1. Listar todos los degenerate cases del selector.
2. Para cada uno, preguntar: ¿requiere acción upstream del usuario antes de re-invocar productivamente?
3. Si TODOS son NO → binary (default + override(s) sin PAUSE).
4. Si ALGUNO es SÍ → trinary (default + override + PAUSE).
```

NUNCA force-fit trinary "porque parece más completo". L-004 verbatim:

> NUNCA force-fit a trinario sin aplicar el test. Si el agente duda sobre si un caso aplica, default a binario y documenta en ADR que el test mostró NO degenerate case que requiere upstream action — esto es más honesto que inventar un PAUSE artificial.

## Citation grammar

- [memory:lessons#L-004] — test diagnóstico verbatim.
- [memory:decisions#D-009] — primer caso binary (login).
- [memory:decisions#D-010] — primer caso trinary (payments).
- [memory:decisions#D-011] — segundo caso trinary (emails).
- [memory:decisions#D-012] — segundo caso binary (mobile) — boundary que cerró generalización.
- [memory:decisions#D-013] — tercer caso binary (la-forja) — sexta validación cross-skill.

## Anti-patterns

- ❌ Force-fit trinary "porque hay 3 opciones" (confunde cantidad con estructura).
- ❌ PREFLIGHT halt llamado "PAUSE" (es gate de entrada, no degenerate case del selector).
- ❌ Inventar PAUSE artificial para "completar el patrón D-010/D-011" (force-fit).
- ❌ Saltar el test diagnóstico y asumir binary por default (debe documentarse explícitamente que el test corrió y dio NO).
