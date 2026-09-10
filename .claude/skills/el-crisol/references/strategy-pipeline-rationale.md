# Strategy pipeline rationale — por qué L-004 NO aplica directo a el-crisol

> el-crisol es shape estructural distinto al de los skills de los bloques D y ortogonal binary/trinary. **L-004 NO aplica directo.** Documentado en [memory:decisions#D-014].

## El test L-004 (verbatim)

> [memory:lessons#L-004]:
>
> ¿Existe un degenerate case que requiera acción **upstream** del usuario antes de re-invocar el skill productivamente?
>
> - Si SÍ → trinario (default + override + PAUSE)
> - Si NO → binario (default + override solo)

L-004 está formulado para **selectores entre N providers/approaches** — es la generalización del patrón emergido en D-009 (Supabase vs Insforge), D-010 (Stripe vs Polar), D-011 (Resend vs SendGrid), D-012 (PWA vs native shell), D-013 (Coordinator vs Fork vs Swarm).

**Pre-condición implícita del test:** existe un eje decisional entre alternativas paralelas a comparar.

## Shape estructural de el-crisol

el-crisol NO tiene un eje decisional entre N providers. Su shape es:

> **Sequential pipeline con resume-aware state detection**

- **Sequential:** 7 pasos en orden de dependencia fijo (brujula → estrella → rivales → precio → roi → metas → lanzamiento). NO se eligen paths alternativos — el orden está dictado por las dependencias.
- **Resume-aware:** detección Fase 0 escanea docs existentes y skipea los que ya están. NO es un selector — es un detector + skipper.
- **State detection:** estado del pipeline = qué docs existen, no qué provider se eligió.

## Análisis: ¿hay un selector escondido en el-crisol?

Aplico el L-004 test a cada decisión potencial dentro de el-crisol:

| Decisión potencial | ¿Es selector entre N providers? | ¿Aplica L-004? |
|--------------------|--------------------------------|----------------|
| 4 modos de invocación (`go` / `saltar N` / `desde N` / `solo dashboard`) | NO — son modos de control de flow del MISMO pipeline, no providers alternativos | NO |
| Perplexity research opt-in (sí/no) | Borderline — sí/no es binario, pero NO es elección entre providers, es enriquecimiento opcional | NO (es feature flag, no selector) |
| Veredicto Go/Caution/No-Go | NO — son outputs del scoring, no decisiones del usuario sobre qué path tomar | NO |
| Handoff post-Go (la-forja vs el-yunque) | Borderline — es selector entre orquestadores | Aplica L-004 EN la-forja level (D-013), no en el-crisol |
| 7 pasos del pipeline | NO — son secuenciales con dependencias, no alternativas paralelas | NO |

**Conclusión:** el-crisol NO contiene un selector entre N providers que requiera L-004 test. Los 4 modos de invocación son control de flow, no decisiones provider-style. El handoff post-Go a la-forja vs el-yunque es decisión del usuario fuera del scope de el-crisol (la-forja MISMA aplica L-004 en su pattern selector — D-013).

## ¿Hay degenerate case con upstream user action requerida?

Aún sin selector, el test diagnóstico podría aplicar a otros aspectos del skill. Análisis case-by-case:

| Caso degenerate de el-crisol | ¿Requiere upstream user action? | Resultado |
|------------------------------|-------------------------------|-----------|
| Sin Blueprint | Sí (correr la-herreria) | **PREFLIGHT halt, NO PAUSE genuino del selector** (no hay selector) |
| Sin docs estratégicos previos | NO (cold start es default `go`) | NO PAUSE — pipeline corre desde paso 1 |
| Algunos docs existen, otros no | NO (resume-aware detection skipea existentes) | NO PAUSE — feature explícita del skill |
| Build Confidence Score = No-Go | NO (es output del scoring, no halt) | NO PAUSE — usuario decide replantear |
| Perplexity quota exhausted | NO (graceful degradation sin enrichment) | NO PAUSE — feature opt-in |
| Inconsistencia entre docs (paso N contradice paso N-1) | NO (halt + reportar al humano para resolución manual) | Halt operacional, NO PAUSE-style upstream-user-action |
| Chart.js CDN bloqueado | NO (sub-agent reporta + fallback markdown) | NO PAUSE |

Igual que la-forja en D-013, el-crisol NO tiene PAUSE genuino. Pero la diferencia es estructural: la-forja **podría** haber tenido shape trinary (es selector entre 3 patterns); el-crisol **no puede** tener shape binary/trinary porque no es selector. **Aplicar L-004 a el-crisol es category error.**

## D-014 outcome

Documentado en [memory:decisions#D-014]:

- el-crisol es **sequential pipeline con resume-aware state detection** — shape distinto al de los selectores D-009..D-013.
- L-004 NO aplica directo. **Cita informativa al humano** si pregunta por qué no hay default+override en este skill.
- El patrón de el-crisol es reusable para futuros skills que sean pipelines secuenciales (potencialmente: orchestrator wizards Phase 5+ que componen cadenas de skills, futuros analysis pipelines).
- Si emerge un selector dentro de el-crisol en evolución futura (ej: 2 templates de scoring distintos para distintos tipos de proyecto), aplicar L-004 EN ese selector específico, NO en el-crisol entero.

## Generalización post-bloque D + ortogonal

| ADR | Skill | Shape | L-004 aplica? |
|-----|-------|-------|---------------|
| D-009 | add-login | binary selector (Supabase vs Insforge) | SÍ — binary |
| D-010 | add-payments | trinary selector (Stripe / Polar / PAUSE empresa MoR) | SÍ — trinary |
| D-011 | add-emails | trinary selector (Resend / SendGrid / PAUSE SMTP) | SÍ — trinary |
| D-012 | add-mobile | binary selector (PWA / native shell) | SÍ — binary |
| D-013 | la-forja | binary selector con 3 opciones (Fork default / Coordinator / Swarm) | SÍ — binary |
| **D-014** | **el-crisol** | **sequential pipeline + resume-aware** | **NO — shape distinto** |

D-014 es el **primer ADR cross-skill** donde L-004 NO aplica directo. Establece boundary del patrón generalizado:

> "Default friction-reducer + override explícito por decision tree" es la parte universal del patrón D-009 → D-013. **PERO solo aplica a skills con eje decisional entre N providers/approaches.** Skills con shape distinto (sequential pipelines, resume-aware orchestrators, validation chains) NO entran en el patrón.

Esto NO debilita L-004 — la confirma. Las 5 ADRs previas validaron el patrón en su scope canónico (selector entre alternativas paralelas). D-014 muestra el límite del scope: cuando NO hay selector, NO hay test L-004 que aplicar.

## ¿Por qué documentar esto explícitamente?

Sin D-014, futuros maintainers podrían:

1. **Force-fit L-004 a el-crisol** inventando un selector artificial (ej: "default = ejecutar 7 pasos / override = solo dashboard / PAUSE = Blueprint missing"). Eso sería violación verbatim de L-004 que dice "NUNCA force-fit a trinario sin aplicar el test... default a binario y documenta en ADR que el test mostró NO degenerate case".

2. **Confundir PREFLIGHT halt con PAUSE.** El test debe documentar que halt en faltantes mandatorios (Blueprint missing → handoff la-herreria) es **gate de entrada general del flow** la-herreria → el-crisol → la-forja, NO degenerate case del pattern selector.

3. **Asumir que TODOS los skills tienen shape selector.** Forja Phase 5+ tendrá orchestrator wizards y composers que pueden ser pipelines. Si todos los maintainers asumen "todo skill tiene default+override", el patrón se infla en interpretación y pierde precisión analítica.

D-014 establece límite claro: **el patrón L-004 aplica solo a selectores. Pipelines son shape distinto, requieren su propia documentación rationale.**

## Citation grammar

- [memory:lessons#L-004] — test diagnóstico verbatim (informativo, NO aplica directo).
- [memory:decisions#D-009] hasta [memory:decisions#D-013] — 5 ADRs cross-skill que validan L-004 en su scope canónico.
- [memory:decisions#D-014] — primer caso cross-skill donde L-004 NO aplica directo (boundary explícito).
- [memory:CONSTRAINTS.md#R4] — orchestrator stays thin (aplica universalmente, no requiere L-004).
- [memory:CONSTRAINTS.md#R5] — workers no escriben memory (aplica universalmente).

## Implicación para el-crisol SKILL.md

SKILL.md regla operativa 9 documenta explícitamente:

> "L-004 NO aplica directo. Documentado en [`references/strategy-pipeline-rationale.md`](strategy-pipeline-rationale.md) y [memory:decisions#D-014]. el-crisol shape es sequential-pipeline-con-resume-detection, NO selector entre N providers. Cita informativa al humano si pregunta por qué no hay default+override en este skill."

Esto es **honestidad analítica**: aplicar L-004 a un shape donde no aplica es category error. D-014 explicita el límite.

## Implicaciones futuras

Skills futuros con shape NO-selector deben:

1. Aplicar el L-004 test rigurosamente para confirmar que NO hay selector dentro del skill.
2. Si NO hay selector → documentar en ADR análogo a D-014 que L-004 NO aplica directo + razón.
3. Si HAY selector escondido → aplicar L-004 al selector específico, NO al skill entero (binary o trinary según el test).

Esto preserva la precisión del patrón generalizado y evita over-application a casos donde no es relevante.

## Refusals

- ❌ Force-fit L-004 a el-crisol (category error — no es selector).
- ❌ Inventar un "default vs override" artificial dentro de el-crisol para parecerse a D-009..D-013.
- ❌ Confundir PREFLIGHT halt (gate de entrada) con PAUSE (degenerate case del selector que requiere upstream user action).
- ❌ Asumir que TODOS los skills tienen shape selector (Forja tiene shapes distintos: pipelines, validators, orchestrators).
