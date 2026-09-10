# Audit mode rationale — D-015 binary selector + refines D-014 doctrine

> web-quality es BINARY-shaped. Live audit (default) + static analysis (fallback graceful sin PAUSE). D-015 documenta el outcome del L-004 test + **refina** la doctrine de D-014 sobre cuándo L-004 aplica vs no.

## El test L-004 (verbatim)

> [memory:lessons#L-004]:
>
> ¿Existe un degenerate case que requiera acción **upstream** del usuario antes de re-invocar el skill productivamente?
>
> - Si SÍ → trinario (default + override + PAUSE)
> - Si NO → binario (default + override solo)

L-004 aplica a **selectores entre N providers/approaches alternativos**. D-014 (el-crisol) estableció el primer boundary: pipelines/validators **sin selector** requieren ADR propio dedicado, NO force-fit L-004.

## ¿web-quality tiene selector?

**Sí.** Selector binary explícito:

| Modo | Trigger | Default? |
|------|---------|----------|
| **Live audit** | URL o server corriendo + tools (agent-browser default D4 / lighthouse fallback) | DEFAULT |
| **Static analysis** | Sin URL ni server, o tools indisponibles | OVERRIDE (fallback graceful) |

Diferencia con el-crisol (D-014): el-crisol tiene **modos de control de flow** (`go` / `saltar N` / `desde N` / `solo dashboard`) sobre el MISMO pipeline secuencial — no son alternatives between providers/approaches. web-quality tiene **alternatives genuinos** entre live audit y static analysis con técnicas distintas (Lighthouse runtime measurement vs static pattern detection).

→ **L-004 aplica** a web-quality. D-014 doctrine NO bloquea — D-014 dice "validators SIN selector requieren ADR propio". web-quality es validator CON selector.

## L-004 test aplicado

| Caso | ¿Upstream user action requerida? | Resultado |
|------|---------------------------------|-----------|
| Sin URL ni server (live no viable) | NO — static SIEMPRE disponible (basta leer `src/`) | NO PAUSE |
| Sin proyecto Next.js detectable | Sí (constituir proyecto target) | **PREFLIGHT halt, NO PAUSE genuino del selector** (no es decisión live vs static) |
| agent-browser CLI no instalado | NO — Lighthouse CLI fallback o degradar a static | NO PAUSE |
| Lighthouse CLI no instalado tampoco | NO — degradar a static graceful | NO PAUSE |
| Build dist o `.next` ausente | NO — static analysis funciona sobre `src/` | NO PAUSE |
| Network blocked (CDN inaccesible para Chart.js Lighthouse internals) | NO — agent-browser puede operar headless local | NO PAUSE |

**Conclusión:** **BINARY** confirmado. live default + static fallback, sin PAUSE genuino.

## D-015 refinamiento de D-014 doctrine

### D-014 original (post-el-crisol)

> "L-004 aplica solo a skills con eje decisional entre N providers/approaches alternativos. Skills con shape distinto (sequential pipelines, resume-aware orchestrators, validation chains, detection skills) requieren ADR análogo a D-014 que documente shape + razón por la que L-004 NO aplica directo."

### D-015 refinamiento

D-014 mencionó "validation chains" como ejemplo de shape donde L-004 podría no aplicar. **Pero D-015 muestra que validators NO son uniformes:**

- **Validator SIN selector** (ej: el-evaluador — corre R7 three-layer fijo, no elige technique alternative): doctrine D-014 aplica → ADR propio sin L-004.
- **Validator CON selector** (web-quality — elige live vs static): L-004 aplica normalmente como cualquier skill con selector.

D-015 refina la doctrine:

> **L-004 aplica si y solo si el skill tiene un selector entre N providers/approaches alternativos. La presencia o ausencia del selector — no la categoría del skill — determina si L-004 aplica.**
>
> Pipelines, validators, composers, detectors, orchestrators — cualquier shape — siguen la misma regla: ¿hay un selector dentro? Si sí → L-004 aplica. Si no → ADR propio análogo a D-014.

Esta es la generalización **definitiva** post-bloque D + ortogonal completo.

## Generalización post-D-015 (final)

| ADR | Skill | Tiene selector? | L-004 aplica? | Resultado |
|-----|-------|-----------------|---------------|-----------|
| D-009 | add-login | Sí (Supabase / Insforge) | SÍ | binary |
| D-010 | add-payments | Sí (Stripe / Polar / PAUSE empresa MoR) | SÍ | trinary |
| D-011 | add-emails | Sí (Resend / SendGrid / PAUSE SMTP) | SÍ | trinary |
| D-012 | add-mobile | Sí (PWA / native shell) | SÍ | binary |
| D-013 | la-forja | Sí (Coordinator / Fork / Swarm — 3 opciones binary-shape) | SÍ | binary |
| D-014 | el-crisol | NO (sequential pipeline + resume-aware) | NO | boundary case (ADR propio) |
| **D-015** | **web-quality** | **Sí (live / static)** | **SÍ** | **binary** |

Scoreboard final post-bloque-D + ortogonal completo:

- **Binary (4):** D-009 login, D-012 mobile, D-013 la-forja, D-015 web-quality
- **Trinary (2):** D-010 payments, D-011 emails
- **Boundary case (1):** D-014 el-crisol (sin selector, ADR propio)

Total: 7 ADRs cross-skill cubriendo el patrón en su totalidad. **18/18 skills authored**, milestone F3 cerrado.

## Por qué D-015 es importante

Sin D-015, D-014 podría leerse como "todos los validators son ADR propio". web-quality muestra que **NO** — validators con selector siguen el patrón L-004 normal.

D-015 establece la **regla operacional** definitiva para futuros skills:

```
1. ¿El skill tiene un selector entre N providers/approaches dentro?
   ├── Sí → aplicar L-004 test → binary o trinary
   └── No → ADR propio análogo a D-014
       ├── Documentar shape estructural (pipeline, validator-fijo, composer, ...)
       ├── Análisis caso por caso de "decisiones potenciales" (descartando que sean selectores reales)
       ├── Análisis separado de degenerate cases (PREFLIGHT halt vs PAUSE)
       └── Ubicación en scoreboard cross-skill
```

Phase 5+ (orchestrator wizards, composers, futuros add-* extensions) probablemente combinarán selectors + pipelines + validators. Aplicar L-004 al selector específico, NO al wizard entero — que puede contener múltiples selectores con shapes binary/trinary distintos.

## Distinción crítica binary 2-options vs trinary 3-options-PAUSE

Heredado de D-013 + reaffirmed acá:

L-004 distingue **estructura del selector**, no cantidad de opciones. web-quality tiene 2 modos (live / static) — clearly binary. Pero la forma del shape sería binary aun si hubiera 3 modos (ej: live-headless / live-headful / static), siempre que ningún degenerate case requiera upstream user action **específica del selector**.

Trinary requiere PAUSE genuino: caso degenerate donde el usuario debe constituir algo upstream antes de poder usar el skill productivamente (constituir empresa MoR para D-010, constituir SMTP para D-011). web-quality NO tiene equivalente — sin URL/server → static; sin proyecto → PREFLIGHT halt (no PAUSE del selector).

## Citation grammar

- [memory:lessons#L-004] — test diagnóstico verbatim.
- [memory:decisions#D-009] hasta [memory:decisions#D-013] — 5 ADRs cross-skill validando L-004 con selector.
- [memory:decisions#D-014] — primer boundary case (el-crisol pipeline sin selector).
- [memory:decisions#D-015] — refinamiento doctrine: selector presence determina aplicabilidad, no categoría del skill.
- [memory:CONSTRAINTS.md#R4] — orchestrator stays thin (aplica universalmente).
- [memory:CONSTRAINTS.md#R5] — workers no escriben memory.

## Implicación para web-quality SKILL.md

SKILL.md regla operativa 11 documenta:

> "L-004 aplica (D-015). A diferencia de el-crisol (D-014 pipeline shape sin selector), web-quality SÍ tiene selector binary. D-015 refina D-014 doctrine."

`prompts/run-audit.md` implementa el selector concreto. Si en evolución futura emerge 3er modo (ej: "Lighthouse CI mode" para CI/CD pipelines), aplicar L-004 al selector ampliado y documentar en ADR follow-up — probable binary aún (ningún modo requeriría PAUSE genuino).

## Refusals

- ❌ Force-fit trinary inventando un PAUSE artificial (live offline → "constituir server local"). NO — agent-browser puede correr headless contra static HTML, fallback a static siempre disponible, no requiere upstream user action.
- ❌ Force-fit la doctrine D-014 a web-quality "porque es validator". D-015 refina: validators **CON** selector siguen L-004.
- ❌ Confundir PREFLIGHT halt (sin proyecto Next.js) con PAUSE del selector. PREFLIGHT halt es gate de entrada general, no degenerate case del selector live vs static.
- ❌ Asumir que cantidad de opciones determina shape. 2 opciones (binary) vs 3+ opciones (puede ser binary o trinary). El test L-004 es estructural, no cuantitativo.
