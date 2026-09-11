# Decisions — Forja Memory (ADRs)

> Architecture Decision Records. Append-only.
> **Single writer:** `el-evaluador`. Other agents READ ONLY.
>
> **Format per entry:**
> - ID `D-NNN` (zero-padded, monotonic)
> - Date in ISO format
> - Title (short)
> - Context (the problem being solved)
> - Decision (what was chosen)
> - Alternatives considered (briefly)
> - Consequences (positive and negative)
> - Status: `proposed | accepted | superseded by D-XXX`
> - Cite as `[memory:decisions#D-NNN]`

---

## D-001 — Forja es repo nuevo, no fork de Forge open

**Date:** 2026-05-07
**Status:** accepted

**Context:** Después de 3 meses de uso de Forge v3.3, se acumularon capas de skills, comandos y reglas que se contradicen entre sí. Modificar incrementalmente arrastra deuda técnica.

**Decision:** Forja se construye como repo nuevo en `getforja/forja` privado. NO es fork de `getforja/forge-free` ni de `getforja/forge-pro`. Cherry-pick selectivo de patrones validados en Forge, walkinglabs/learn-harness-engineering, vincentconace/relay-kit, y saas-factory upstream.

**Alternatives considered:**
- Continuar evolución de Forge a v3.4, v3.5: rechazado por arrastre de deuda.
- Fork de Forge con cleanup: rechazado, similar problema.
- Reescritura completa con upstream: aceptado.

**Consequences:**
- (+) Arquitectura limpia, libre de contradicciones legacy.
- (+) Permite optimizar para Opus 4.7 desde día 1.
- (-) Pérdida de historia de commits de Forge.
- (-) Compradores actuales de forge-pro mantienen v3.3, no migración automática.

**Mitigación:** Forge open queda en bugfix-only por 6 meses, decidir continuidad post-Forja v1.0.

---

## D-002 — `feature_list.json` + git branch como state machine dual

**Date:** 2026-05-07
**Status:** accepted

**Context:** walkinglabs propone `feature_list.json` como single source of truth. relay-kit propone git branch + `.relay/HEAD`. Cada uno tiene fortalezas.

**Decision:** Combinar ambos. `feature_list.json` mantiene la queue/backlog de features. Active feature se resuelve desde `git rev-parse --abbrev-ref HEAD` matching `^(feature|fix|refactor|chore|docs)/.+$`, fallback a `.forja/HEAD` si no hay branch matching.

**Alternatives considered:**
- Solo `feature_list.json`: rechazado, susceptible a corrupción + sincronización con git.
- Solo branch: rechazado, no permite queue/backlog visible.
- Combinado: aceptado.

**Consequences:**
- (+) Active feature es siempre el branch actual — git es source of truth.
- (+) Queue/backlog visible como JSON estructurado.
- (+) `.forja/HEAD` permite trabajo en non-git workflows.
- (-) Dos lugares para mantener sincronizados (feature_list + branch).

**Mitigación:** hook `pre-commit` valida que branch match con feature en estado `active` en feature_list.

---

## D-003 — Fase 4 (hooks de enforcement) ejecutada antes de Fase 3 y antes del port de references/assets

**Date:** 2026-05-07
**Status:** accepted

**Context:** Tras cerrar Fase 2 con 7/7 skills, el inventario reveló 4 caminos pendientes paralelos: (a) `git push origin main` (29 commits ahead), (b) port de references/assets de Fase 2 (la-herreria 55 archivos + ai 12 archivos), (c) Fase 4 hooks de enforcement (R1/R2/R5/R11/R13), (d) Fase 3 skills migración. Las reglas R1, R2, R5, R11, R13 estaban definidas en CONSTRAINTS.md pero no enforced — ningún hook instalado. Cada nuevo skill construido sin enforcement acumulaba deuda silenciosa de regla no validada.

**Decision:** ejecutar Fase 4 inmediatamente después del cierre de Fase 2, antes de tocar Fase 3 o portar references. Sequencing aprobado por Carlos 2026-05-07: c → push → b(ai port) → d(Fase 3) → push intermedios → b(la-herreria port) → Fase 6.

**Alternatives considered:**
- Saltar Fase 4 hasta después de Fase 3: rechazado, las reglas se vuelven aspiracionales y al refactorizar después se tocan más archivos.
- Hooks vía husky / lefthook / simple-git-hooks: rechazado, deps node innecesarias para shell scripts simples; Forja prefiere stack mínimo.
- Hooks via core.hooksPath en git config en lugar de cp a .git/hooks/: defensible pero más opaco para nuevos desarrolladores; cp es más visible.

**Consequences:**
- (+) R1, R2, R5, R11, R13 son ahora enforcement por harness, no por disciplina del agente.
- (+) Stack mínimo (plain shell + cp) — sin deps, portátil, visible.
- (+) Tests por hook (12 unit + 7 integration) garantizan que las reglas no se rompen al evolucionar los scripts.
- (-) R5 enforcement vive solo en `commit-msg`, no en `pre-commit` — el spec original de Carlos pidió ambos pero estructuralmente pre-commit corre antes de que git escriba el `-m` message a `.git/COMMIT_EDITMSG`, así que cualquier check de R5 en pre-commit lee el msg del commit anterior. Documentado como deviation en `fix(F4-T2)` + comentario en el script.
- (-) R2 regex extiende los 10 types originales con `evaluator` y `memory` — necesario para soportar shapes `evaluator(D-NNN)` y `memory(E-NNN)`. CONSTRAINTS.md R2 actualizada para reflejar esto.
- (-) R2 scope class relajada de `[a-z0-9-]+` a `[A-Za-z0-9-]+` — necesario para IDs `F2-S7`, `D-003`, `E-001` ya en uso. CONSTRAINTS.md R2 actualizada.

**Mitigación de R5 deviation:** commit-msg es la única autoridad para R5; cubre todos los casos del spec. La pérdida es teórica (pre-commit "warning previo") sin impacto funcional.

---

## D-004 — Renombrar `03-historial-supabase.md` → `03-historial-baas.md`

**Date:** 2026-05-07
**Status:** accepted

**Context:** Durante F2-port-ai (port del catalog Vercel AI SDK desde saas-factory) detecté que el template `03-historial-supabase.md` upstream está hardcoded a Supabase como BaaS. Forja tiene la decisión D11 (`baas` skill con decision tree Supabase vs InsForge) que explícitamente abstrae el BaaS por proyecto. Mantener un template "supabase-only" contradice D11 y obliga a re-portar el archivo si el proyecto target eligió InsForge.

**Decision:** renombrar a `03-historial-baas.md` y restructurar con 2 sub-secciones (Supabase adapter + InsForge adapter) que comparten la misma interface. La elección runtime se hace en `features/agent/services/historyService.ts` que re-exporta del adapter según `baas` decision aplicada al proyecto.

**Alternatives considered:**
- Mantener nombre original y agregar nota "Para InsForge, ver…": rechazado, contradice D11 explícitamente y sigue ocultando la abstracción.
- Crear archivo separado `03-historial-insforge.md` paralelo: rechazado, duplica el 80% del contenido (interface idéntica) y obliga al usuario a elegir archivo según BaaS antes de saber qué BaaS necesita.
- Pluralizar a `03-historial-baas.md` con dos sub-secciones: aceptado.

**Consequences:**
- (+) Coherente con D11 — un solo template sirve ambos paths.
- (+) Ambos adapters exportan la misma interface — el componente consumidor no cambia.
- (+) Reduces 1118 LOC upstream → 831 LOC en Forja, mantiene todo el contenido funcional Supabase y agrega el InsForge equivalent comprimido.
- (-) Nombre del archivo difiere de la fuente upstream (saas-factory). Cualquier futuro re-pull de upstream require rebase manual; el renombrado se documenta acá.
- (-) El InsForge adapter del template tiene los métodos comprimidos (referencia al body del Supabase adapter para evitar 100 LOC duplicadas). Cuando InsForge SDK diverge significativamente de Supabase, ese template necesita expansión.

**Mitigación:**
- Apertura E-NNN si surge confusión por la inconsistencia de nombre vs upstream.
- Cuando InsForge SDK diverge >30% del Supabase shape, expandir explícitamente (audit anual).

---

## D-005 — Promoción retroactiva de las security mitigations de F2-port-ai a memoria + CONSTRAINTS

**Date:** 2026-05-07
**Status:** accepted

**Context:** durante F2-port-ai detecté 4 mejoras de seguridad ausentes en saas-factory upstream y las apliqué localmente a 4 templates portados (02-web-search, 04-vision-analysis, 05-tools-funciones, 06-rag-basico). Las mitigaciones eran:
1. RLS por user_id en tablas de datos derivados de input del usuario (06-rag-basico)
2. System prompts anti-prompt-injection para contenido externo (02-web-search, 04-vision-analysis)
3. Validación de inputs por whitelist explícita (04-vision MIME types + 05-tools enums)
4. Convención "destructivas SIN execute" para tools agentic (05-tools-funciones)

Sin promoción a memoria + reglas, futuros skills (add-login con auth callbacks, add-payments con webhooks, otra implementación de RAG, etc.) reinventan o más probable: olvidan, las mitigaciones. El catálogo local de un template no es enforceable cross-skill.

**Decision:** promover los 4 patrones a Forja memory + CONSTRAINTS según su escalation natural:
- 1, 2, 3 → lessons (`L-001`, `L-002`, `L-003`) — son patrones generalizables, no reglas universales todavía. Si recurren en >2 skills, promover a regla.
- 4 → regla universal `R14` — el patrón de "destructivas con confirmación humana" aplica a todo skill que genere agentic tools, sin matiz. Es enforcement gate, no guideline.

Cierre del loop: los 4 templates afectados (02/04/05/06) reciben citation grammar inline a las lessons/reglas promovidas en commits subsiguientes (`feat(ai-port-cite)`).

**Alternatives considered:**
- Dejar las mitigaciones como conocimiento tácito en los 4 templates: rechazado, el conocimiento no es heredable cross-skill.
- Promover los 4 a regla universal: rechazado, los 3 primeros son contextuales (RAG, agents que consumen externo, validación de inputs específicos) — son lessons que aplicar con criterio, no checkboxes binarios. Solo "destructivas requieren confirmación" es binary.
- Promover los 4 a CONSTRAINTS: rechazado por la misma razón.

**Consequences:**
- (+) Los próximos skills (Fase 3: add-login, add-payments, add-emails, add-mobile + bloque A: add-ui-kit, impeccable) heredan automáticamente los 4 patrones. el-evaluador puede citar `[memory:lessons#L-001]` etc. al validar outputs.
- (+) R14 es enforceable: el-evaluador rechaza skill outputs con destructivas que tienen `execute()`.
- (+) Los 4 templates ai/ ahora citan las lessons → trazabilidad bidireccional (template → lesson + lesson → templates).
- (-) Crece el footprint de memoria de Forja (3 lessons + 1 regla nueva). Hay que mantenerlas vigentes — auditoría anual.
- (-) Cuando varias features simultáneas violen una lesson, escalation a regla pasa por el-evaluador audit, no automático.

**Mitigación:** auditoría trimestral de el-evaluador revisa qué lessons recurren cross-skill y cuáles candidatean a promoverse a CONSTRAINTS.

---

## D-006 — Los 5 presets de Forge v3.3 se mantienen como starting points en add-ui-kit, NO como contrato

**Date:** 2026-05-07
**Status:** accepted

**Context:** durante F3-S1 (autoría del skill `add-ui-kit`) emergió una pregunta arquitectural: el schema R-005 sección 1.1 declara que el contrato de Brand DNA opera con 6 ejes canónicos (density, expression, geometry, warmth, editoriality, materiality), cada uno con escala 1-5. Forge v3.3 históricamente operó con 5 visual directions nombrados (Editorial Monocle, Modern Minimal, Warm & Soft, Tech Utility, Brutalist Experimental) que el discovery interactivo ofrecía al usuario como puntos de entrada. El conflicto: ¿qué pasa con los 5 presets en Forja? ¿Se descartan en favor del schema de 6 ejes (que es estrictamente más expresivo: 5⁶ = 15,625 combinaciones posibles vs 5 categóricas)? ¿Se mantienen como vocabulario y dejamos que coexistan?

**Decision:** mantener los 5 presets como **starting points** (vocabulario de entrada) en `add-ui-kit/references/presets.md`, pero el output canónico siempre son los 6 ejes numéricos + tokens explícitos en `brand/brand.json`. Los presets son atajo de descubrimiento, NO el contrato.

Implementación operativa:
- Discovery FRESH bloque (c) ofrece 3 caminos: (i) elegir uno de los 5 presets como baseline + ajustar ejes, (ii) responder los 6 ejes uno por uno, (iii) usar default Modern Minimal.
- El YAML output del Discovery captura `_baseline_preset` como metadata informativo + los 6 ejes como source of truth.
- `generate-brand-json.md` rellena el JSON con los 6 ejes; el preset name vive solo en `$generated_by` provenance metadata.
- `el-evaluador` valida contra los ejes, NO contra el preset. Override de un eje individual NO se considera "violar el preset" — es la operación esperada.

**Alternatives considered:**
- Descartar los 5 presets, exigir que el usuario responda los 6 ejes uno por uno: rechazado, fricción cognitiva alta. Un usuario que no es designer no tiene intuición numérica de "warmth: 3 vs 4" sin referente.
- Hacer los presets el contrato, mantener los 6 ejes como métrica derivada: rechazado, demasiado restrictivo (15,625 combinaciones colapsan a 5).
- Coexistir: aceptado.

**Consequences:**
- (+) UX de Discovery rápido — usuario llega al 80% del Brand DNA en 5 minutos eligiendo preset + ajustando 1-2 ejes.
- (+) Output canónico es expresivo: combinaciones impensadas posibles (ej: Tech Utility con warmth: 5 — un dev tool human-first).
- (+) Validación de Anti-Slop opera contra los ejes, no contra el preset name — más robusta.
- (+) Los 5 presets son extensibles: agregar uno nuevo no requiere cambiar el contrato, solo extender `references/presets.md`.
- (-) Documentación dual: el-evaluador necesita conocer ambos vocabularios (preset name para Discovery, ejes para validación).
- (-) Posible confusión usuario si el output muestra el preset name (en `$generated_by`) Y los ejes (en el JSON) — necesita explicar la distinción al menos una vez.

**Mitigación:** la SKILL.md de add-ui-kit cita explícitamente esta decisión (paso 2 de "Reglas operativas"), y `references/presets.md` cierra con la frase canónica: *"5 atajos para no empezar de cero. 6 ejes para terminar afilado."*

**Lecciones cross-skill aplicables:** este patrón "vocabulario de entrada amigable + contrato canónico expresivo" es un blueprint reutilizable. Si en el futuro F3-S2 (`impeccable`) o F3-S3 (`web-quality`) enfrentan tensión similar entre input UX y output schema, esta decisión sirve como precedente.

---

## D-007 — `impeccable` usa shadcn-customizado por default; from-scratch como fallback

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S2 (autoría del skill `impeccable`) emergió la pregunta de cómo generar componentes UI cuando el target ya tiene shadcn-ui instalado vs cuando no. Dos opciones extremas:
1. **From-scratch always**: impeccable genera Tailwind primitives desde cero ignorando shadcn aunque esté instalado. Cero deps Radix (todos los modals + tabs + select se implementan manualmente con focus-trap + Esc handler + ARIA).
2. **shadcn always**: requerir que el target tenga shadcn antes de invocar impeccable. Bloquear si no lo tiene.

Ambos extremos tienen problemas. From-scratch always duplica trabajo cuando shadcn ya está y obliga a impeccable a mantener implementaciones a11y de modal/tabs/select que Radix ya hace mejor. shadcn always force-couplea Forja a una dep externa que algunos proyectos legítimamente quieren evitar (por bundle size, por avoid Radix, por usar otro headless lib como Ark UI).

**Decision:** modo dual selectivo:
- Si `package.json` declara `class-variance-authority` + `tailwind-merge` AND existe `components.json` (shadcn-ui marker) AND existe `@/lib/cn` (o equivalente) AND alias path está configurado → modo **shadcn-customizado** (default cuando todo está). impeccable importa primitives shadcn (Button, Input, Card si shadcn las tiene; Dialog/Tabs/Select de Radix vía shadcn) y SOLO sobreescribe la cva con tokens del brand.json. Reduce LOC generado y mantiene comportamiento Radix-grade en a11y.
- Si cualquiera falta → modo **from-scratch**. impeccable genera primitives Tailwind directos, implementa focus-trap + Esc handling + ARIA manualmente para Modal/Tabs/Select. Incluye `cn` helper si falta.

El consumer puede forzar `from-scratch` aunque shadcn esté disponible (flag `--no-radix` o preferencia del proyecto). Documentar en commit message.

**Alternatives considered:**
- From-scratch always: rechazado, duplica trabajo + worse a11y default en componentes complejos.
- shadcn always: rechazado, force-couplea Forja a Radix.
- Auto-detect + dual: aceptado.

**Consequences:**
- (+) Default optimal: si shadcn está, usalo; si no, no obligues.
- (+) Componentes complejos (Modal, Tabs, Select) heredan a11y Radix-grade en modo shadcn-customizado.
- (+) Bundle size minimal en modo from-scratch (sin Radix deps).
- (+) Brand contract (cva tokens) es idéntico en ambos modos — el consumer no nota diferencia funcional.
- (-) Dual implementation paths en `references/shadcn-mapping.md` + cada template comenta cuál camino aplica.
- (-) Detection de shadcn requiere 4-step check (components.json + cva/tailwind-merge en package.json + cn helper + alias path). Si alguno cambia (ej: shadcn migra a otra config), el detection puede romper.
- (-) Cuando proyecto migra de from-scratch → shadcn (instala shadcn después), impeccable re-batch detecta la diferencia pero NO re-genera automático (preserva customizaciones manuales).

**Mitigación:**
- 4-step detection es robusto a v3.x→v4.x de shadcn (los 4 markers son canónicos).
- `references/shadcn-mapping.md` documenta el dual mode con tabla por componente.
- Cuando consumer migra → impeccable detecta drift y reporta al usuario (E-NNN si recurrente cross-project), pero NO sobreescribe sin confirmación.

**Cross-skill applicability:** este patrón "auto-detect external dep + adapt mode" es reusable para F3-S5 (`add-login`) cuando detecte si el target usa Supabase Auth UI components vs roll-its-own, y para F3-S6 (`add-payments`) cuando detecte Stripe vs Polar. impeccable D-007 es el precedente.

---

## D-008 — R-005 schema bump 1.0.0 → 1.1.0 (keyed spacing + motion enums + archetype docs/enforcement clarification)

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante el cierre de F3-S2 (`impeccable`) se detectaron 3 fricciones consumiendo el contrato Brand DNA de R-005 v1.0:
- F1 (E-002): `tokens.spacing.section_y` y `component_gap` como arrays posicionales fuerzan a los downstream skills a inventar nombres semánticos por orden, sin garantía schema-level.
- F2 (E-003): `motion.personality.*` como free-strings violan [memory:lessons#L-003] aplicado al schema mismo. El meta-issue: L-003 se aplicó a inputs runtime pero no se cerró el loop sobre el schema canónico.
- F3 (E-004): `archetype.allowed_behaviors` / `forbidden_behaviors` se confunden entre documentación humana y enforcement programático.

Las 3 fricciones son schema-level. Ignorarlas significa que F3-S3..S6 (add-login, add-payments, add-emails, add-mobile) heredarán el problema y cada uno necesitará workarounds. Documentar como E-NNN sin fix es retraso de deuda. Fix ahora aprovecha el contexto fresco de F3-S2 (recién generamos los 11 componentes y sabemos exactamente qué tokens consumen).

**Decision:** evolucionar R-005 a v1.1.0 con 4 cambios:

1. **`tokens.spacing.section_y` array → keyed object** `{sm, md, lg}`. Cada nivel declara semánticamente su nombre.
2. **`tokens.spacing.component_gap` array → keyed object** `{xs, sm, md, lg}`. Mismo principio.
3. **`motion.personality.*` enums cerrados por dimensión** (energy: 5 valores, elasticity: 4, directionality: 4, sequencing: 4, distance: 3, restraint: 3). Aplica L-003 al schema canónico.
4. **`archetype.allowed_behaviors` / `forbidden_behaviors`** documented en R-005 9.1 como **DOCUMENTACIÓN, NOT enforcement**. El enforcement vive en `tokens` + `anti_slop` + `validation` + `component_rules`.

Bump `$schema_version: "1.1.0"` en todos los ejemplos del schema y outputs de add-ui-kit.

**Alternatives considered:**
- Documentar las 3 fricciones como E-NNN sin fix de schema, esperando que recurran antes de actuar: rechazado, daría señal verde a F3-S3..S6 acumulando deuda silenciosa.
- Fix solo F1+F2 (los más graves) y dejar F3 como observación: rechazado, los 3 son del mismo bloque "schema-level cleanup post primer-consumer-validation". Hacer las 3 juntas es el costo correcto.
- Bump a v2.0 (breaking): rechazado, los cambios son aditivos en intención (mantienen el modelo de tokens + posture + archetype + anti-slop) — solo cambian shape de campos específicos. v1.1.0 (minor) es la semver correcta.
- Migration script para brand.json existing v1.0 → v1.1: rechazado por ahora — Forja todavía no tiene proyectos production con brand.json poblados (solo el dry-run de F3-S1). Si en el futuro hay >0 brand.json en circulación, agregar migration script en commit dedicado.

**Consequences:**
- (+) F3-S3..S6 heredan schema sólido, no workarounds.
- (+) E-002/003/004 cerradas en errors.md con fix concreto, no abiertas perpetuas.
- (+) L-003 cierra loop: aplica también al schema canónico, no solo a runtime inputs. Meta-lección capturada.
- (+) `motion.personality` enums permiten que `el-evaluador` valide schema-level antes de pasar a downstream — antes era ad-hoc per skill.
- (+) Distinción docs vs enforcement en archetype clarifica `el-evaluador` audit policy.
- (-) Tests dry-run de F3-S1 + F3-S2 deben regenerarse (brand.json + brand.css + 11 componentes que consumen spacing tokens + Brand Score recalculado).
- (-) `references/presets.md` (5 presets) ya emite token defaults en formato v1.0 — necesita re-pass para producir v1.1.0.
- (-) `references/examples-tech-utility.md` y `references/examples.md` (en add-ui-kit) tienen ejemplos en formato v1.0 — necesitan ajuste para mantener autoritativos.

**Mitigación:**
- Tests F3-S1 + F3-S2 regeneration en F3-tighten commits (8-10 commits).
- Brand Score re-validación en commit de cierre — debe mantenerse ≥ 75 por componente.
- L-003 strengthening (el meta-loop closure) NO se promueve aún — esperar más data points (post-F3-S6) para decidir si ampliar la lección o mantenerla como cita cross-reference.

**Cross-skill applicability:** este patrón "primer consumer (impeccable) descubre 3 fricciones del contrato (R-005), schema bumpea a versión menor con fixes concretos" es un **workflow blueprint** reusable. Los próximos primer-consumer scenarios (F3-S5 add-login será primer consumer de... ¿tablas Supabase?, F4 hooks fueron primer consumer de CONSTRAINTS R1-R13) deben adoptar el mismo flujo: detectar fricciones → registrar como E-NNN → bump schema antes de propagar downstream.

---

## D-009 — Supabase es default de `add-login`; Insforge es alternativa explícita

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S3 (autoría del skill `add-login`) emergió la decisión arquitectural sobre cuál BaaS es el path por defecto cuando el Tech Spec no documenta `baas` decision. add-login podría haber tomado tres caminos:

1. Halt si no hay baas decision documentada — exigir invocación previa de `baas` skill.
2. Insforge como default (vibe-coding-first, agentes prefieren API simple).
3. Supabase como default (madurez ecosystem + RLS + libs comunitarias).

**Decision:** Supabase como default cuando no hay baas decision documentada, con flag `assumed_default = true` loggeado en TECH-SPEC handoff. Insforge se elige solo cuando baas decision tree (cita [memory:skills#baas] señales 1-6) lo dicta explícitamente — típicamente: hosting self-hosted Coolify/Docker Compose + AI multi-provider con failover deseado + vibe-coding-first sin SLA enterprise.

**Alternatives considered:**
- Halt sin baas decision: rechazado, fricción alta para casos comunes (proyecto saas-factory típico no tiene Tech Spec formal pero quiere auth funcional). add-login con fallback default reduce friction sin sacrificar coherencia.
- Insforge como default: rechazado, el ecosystem maduro de Supabase (Studio, CLI, libs Next.js, Auth UI components, comunidad LATAM) hace que un default Insforge force a casi todos los proyectos a re-escribir si quieren bibliotecas pre-existentes. Insforge es opcional por mérito propio cuando las señales lo apuntan, NO el camino primario.
- Supabase como default con baas optional: aceptado.

**Consequences:**
- (+) Friction reducida: proyectos sin Tech Spec formal pueden invocar add-login y obtener auth funcional sin overhead de baas decision tree.
- (+) `assumed_default = true` flag traza la asunción para revisión posterior. Si el usuario quiere migrar a Insforge, baas correrá explícitamente y add-login regenerará.
- (+) Mode B (Insforge) sigue siendo first-class — no es ciudadano de segunda. Templates parallel completos en `templates/insforge/`.
- (+) RLS L-001 enforcement aplica idénticamente en ambos paths (Supabase via SQL migration con `enable row level security`, Insforge via `lib/insforge/schema.ts` declarativo con `access` policies).
- (-) Si Supabase tiene downtime / rate limiting / cambios breaking en su SDK, los proyectos con `assumed_default` heredan ese costo. Mitigación: el-evaluador audita asunciones cuando recurren cross-project.
- (-) Distinction "default por friction reduction" vs "default por superioridad técnica" debe quedar clara en docs. baas decision tree sigue siendo la autoridad — add-login solo provee fallback graceful.

**Mitigación:** SKILL.md de add-login + `prompts/setup-supabase-auth.md` documentan explícitamente que el default es por friction reduction, no por superioridad técnica. Cuando un proyecto re-evalúa con Tech Spec actualizado y baas decision tree apunta a Insforge, add-login re-corre Mode B sin cambios al SKILL.md.

**Cross-skill applicability:** este patrón "skill X con default friction-reducer + override explícito por skill upstream Y" es reusable. Próximos add-* (add-payments con Stripe vs Polar, add-emails con Resend vs SendGrid) deben adoptar el mismo flow: default cuando ambiguo, override explícito cuando la decision tree dicta lo contrario, never halt-only.

**Promoted to:** [memory:lessons#L-004] (test diagnóstico binario-vs-trinario — D-009 fue el primer caso binario del patrón, sin PAUSE porque ambos providers Supabase/Insforge son disponibles sin upstream user action).

**Cita:** `[memory:decisions#D-009]`

---

## D-010 — Stripe es default de `add-payments`; Polar es alternativa MoR explícita

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S4 (autoría del skill `add-payments`) emergió la decisión arquitectural sobre cuál payment provider es el path por defecto cuando el Tech Spec no documenta `payments.provider`. add-payments podría haber tomado tres caminos:

1. Halt si no hay payments decision documentada — exigir invocación previa de un skill upstream o input interactivo.
2. Polar como default (setup speed-first, MoR auto-handles tax + entity legal).
3. Stripe como default (madurez ecosystem + comunidad LATAM + Customer Portal robusto + features avanzados).

**Decision:** Stripe como default cuando no hay payments decision documentada, con flag `assumed_default = true` loggeado en handoff. Polar se elige solo cuando decision tree (cita `prompts/decision-tree.md` con 7 preguntas + tabla resumen + PAUSE option) lo dicta explícitamente — típicamente: operador sin empresa registrada + audiencia global + producto digital simple + setup speed prioritario.

**Alternatives considered:**
- Halt sin payments decision: rechazado, fricción alta para casos comunes (proyecto saas-factory típico no tiene Tech Spec formal pero quiere monetizar). add-payments con fallback default reduce friction sin sacrificar coherencia.
- Polar como default: rechazado. Aunque Polar es MoR (handles tax + entity), su ecosystem es más nuevo (SDK v0.x inestable, customer portal externo no embed-friendly, libs comunitarias Next.js limitadas). Default Polar fuerza a la mayoría de proyectos a re-escribir cuando crecen y necesitan Stripe Connect / Tax / Issuing.
- Stripe como default con Polar override: aceptado.

**Consequences:**
- (+) Friction reducida: proyectos sin Tech Spec formal pueden invocar add-payments y obtener checkout funcional sin overhead de decision tree completo.
- (+) `assumed_default = true` flag traza la asunción para revisión posterior. Si el usuario re-corre con Tech Spec apuntando a Polar, add-payments regenera Mode B sin cambios al SKILL.md.
- (+) Mode B (Polar) sigue siendo first-class — paridad estructural completa en `templates/polar/` con 13 archivos mirroreando Mode A. Polar NO ciudadano de segunda.
- (+) RLS L-001 enforcement aplica idénticamente en ambos paths (subscriptions table provider-agnostic con `provider in ('stripe', 'polar')` check).
- (+) Decision tree expone PAUSE option para el caso degenerado (indie sin empresa + multi-tier complex) — el árbol bloquea con recomendación de constituir empresa antes de continuar. Esto evita force-fit a uno u otro path sin solución saludable.
- (-) Si Stripe tiene downtime / rate limiting / cambios breaking en SDK, los proyectos con `assumed_default` heredan ese costo. Mitigación: el-evaluador audita asunciones cuando recurren cross-project (mismo policy que D-009).
- (-) Decision tree de add-payments es 1 capa más profunda que el de add-login (7 preguntas + PAUSE vs 6 señales binarias) — cognitive load en el-evaluador audit pasa de "binary check" a "tree traversal". Mitigado con tabla resumen 8 filas en `prompts/decision-tree.md`.

**Mitigación:** SKILL.md de add-payments + `prompts/setup-stripe.md` documentan explícitamente que el default es por friction reduction + ecosystem maturity, no por superioridad técnica universal. Cuando un proyecto re-evalúa con decision tree y resultado es Polar, add-payments re-corre Mode B sin cambios al SKILL.md. PAUSE option documentada en `references/examples.md` con caso ejemplar (indie + marketplace).

**Cross-skill applicability:** este patrón "skill X con default friction-reducer + override explícito por decision tree + PAUSE option para degenerados" extiende D-009 (que solo cubría default + override binario). F3-S5 (add-emails con Resend default + SendGrid override + PAUSE on-prem) hereda este shape evolucionado. F3-S6 (add-mobile con PWA default + native shell override) puede usar variante (no necesariamente PAUSE).

**Promoted to:** [memory:lessons#L-004] (test diagnóstico binario-vs-trinario — D-010 fue el primer caso trinario del patrón; PAUSE = constituir empresa MoR es el ejemplo canónico de degenerate case que requiere upstream user action).

**Cita:** `[memory:decisions#D-010]`

---

## D-011 — `add-emails` default Resend; SendGrid override por compliance; PAUSE on-prem

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S5 (autoría del skill `add-emails`) emergió la decisión arquitectural sobre cuál email provider es el path por defecto. add-emails extiende el patrón de D-010 (default + override + PAUSE) al dominio de transactional emails con un eje distinto: **compliance vs ecosystem fit**, vs. el eje de payments que era entity legal vs MoR (Merchant of Record). El skill podría haber tomado tres caminos:

1. Halt si no hay `emails.provider` documentado en Tech Spec — exigir invocación previa.
2. SendGrid como default (madurez enterprise, SOC 2 + HIPAA + ISO 27001 + PCI-DSS).
3. Resend como default (friction reduction, React Email ecosystem, free tier 3K/mes, setup ~5 min).

**Decision:** Resend como default cuando no hay Tech Spec con `emails.provider` documentado, con flag `assumed_default = true` loggeado en handoff. SendGrid se elige solo cuando decision tree (cita `prompts/decision-tree.md` con 6 preguntas + tabla resumen + PAUSE option) lo dicta explícitamente — típicamente: SOC 2 Type II + HIPAA con BAA cloud-hosted + volumen >100K/mes + IPs dedicadas + multi-tenant emailing. PAUSE option (Mode C) recomienda SMTP self-hosted (Postfix/Mailcow/Listmonk/Haraka) cuando el caso es degenerado: banking en jurisdicciones con data sovereignty (BCRA Argentina, AEPD UE strict, Banxico/CNBV México), government con air-gapped requirements, healthcare con HIPAA on-prem mandatory (no BAA cloud-hosted).

**Alternatives considered:**
- SendGrid default + Resend override: rechazado — SendGrid es más complejo de setup (~30 min con SPF/DKIM + Sender Auth + IP warmup); fricción para indie/startup que son la mayoría de targets de add-emails. Default debe optimizar el caso común.
- Resend default + SendGrid override sin PAUSE: rechazado — el caso degenerado (banking en jurisdicción con data sovereignty + healthcare HIPAA on-prem mandatory) requiere SMTP self-hosted; force-fit a SaaS no es solución. PAUSE preserva la posibilidad de "constituir infra antes de re-invocar el skill" — paralelo conceptual a D-010 PAUSE ("constituir empresa antes de procesar pagos como MoR").
- Default Resend con SendGrid + PAUSE como overrides: aceptado.

**Consequences:**
- (+) Patrón D-010 (default friction-reducer + override por decision tree + PAUSE para degenerados) extendido a tercer skill (D-009 binary → D-010 trinario sobre entity-legal axis → D-011 trinario sobre compliance/ecosystem axis), validando reusabilidad cross-domain.
- (+) Compliance vs ecosystem axis es genuinamente distinto al payments axis — no es el mismo eje rebautizado. add-emails permite que un mismo proyecto que usa Stripe (legal entity OK) tenga decision separada de Resend vs SendGrid (compliance budget). El patrón abstrae correctamente sobre el eje específico de cada skill.
- (+) PAUSE option preserva degenerate cases sin force-fit. Sin PAUSE, banking sovereign con regulación A 7724 BCRA terminaría con Resend cloud y violación regulatoria, o desincentivaría adoption en LATAM regulado.
- (+) Resend default optimiza el 90% case (indie/startup/SaaS sin compliance estricto) con setup <10 min y free tier amplio.
- (+) Mode B SendGrid es first-class — paridad estructural completa en `templates/sendgrid/` con 15 archivos mirroreando Mode A. Diferencias clave aisladas (dynamic templates con TEMPLATE_IDS env-driven en lugar de React Email JSX inline; ECDSA P-256 webhook signature en lugar de HMAC Svix; SendGrid v3 REST suppression API; asm unsubscribe groups managed).
- (+) RLS L-001 enforcement aplica idénticamente en ambos paths (`email_subscriptions` table provider-agnostic, idéntica SQL en Mode A + Mode B). Schema declara `scope in ('marketing', 'product_updates', 'all')`, `unique (user_id, scope)`, FK cascade.
- (-) Compliance audit es más sutil que entity-legal check — el-evaluador audit puede tener falsos negativos si el target no documenta requirements compliance explícitamente. Un proyecto healthcare-adjacent que no documente HIPAA en Tech Spec recibe Resend como default, y ese fallback puede ser técnicamente incorrecto si después emerge BAA mandatory.
  - **Mitigación:** `decision-tree.md` documenta compliance signals con preguntas explícitas (P1 sovereign, P2 cloud-OK, P3 volumen + features). Si Tech Spec no documenta, fallback Resend con flag `assumed_default` y warning a usuario que documente compliance requirements en próxima iteración. el-guardian audit pre-deploy revisa configuración real vs claims.
- (-) PAUSE message en Mode C documenta 4 stacks SMTP self-hosted (Postfix+Dovecot, Mailcow Docker, Listmonk newsletters, Haraka/Halon enterprise) como opciones — no genera infra. Usuario debe constituir infra externa antes de re-invocar; no hay shortcut. Esto es by design (paralelo a D-010 PAUSE: constituir empresa).
- (-) Decision tree de add-emails es 1 capa más profunda que el de add-login (P1+P2 compliance hierarchy + P3 volumen + P4 setup speed + P5 volumen actual + P6 ecosystem) — cognitive load mayor en el-evaluador audit. Mitigado con tabla resumen 11 filas en `prompts/decision-tree.md`.

**Mitigación:** SKILL.md de add-emails + `prompts/setup-resend.md` documentan explícitamente que el default es por friction reduction + ecosystem maturity, no por superioridad técnica universal. Cuando un proyecto re-evalúa con decision tree y resultado es SendGrid o PAUSE, add-emails re-corre Mode B sin cambios al SKILL.md. PAUSE option documentada en `prompts/decision-tree.md` con 4 stacks recomendados.

**Cross-skill applicability:** este patrón se generaliza más allá de payments + emails. F3-S6 (`add-mobile`) puede heredar D-011 con axis nuevo (push subscription requires user permission flow + native shell decision: PWA default vs Capacitor/Tauri/React Native override). Probablemente sin PAUSE option estricto — push notifications no tienen un equivalente exacto de "data sovereignty mandatory" típicamente. Pero la **estructura ternaria** (default + override + caso-degenerado-handler) permanece reusable. Generalización: el patrón D-009 (binary) → D-010 (trinary entity-legal axis) → D-011 (trinary compliance-ecosystem axis) sugiere que cualquier skill `add-*` con un axis decisional principal + un caso degenerado válido cabe en este shape.

**Promoted to:** [memory:lessons#L-004] (test diagnóstico binario-vs-trinario — D-011 fue el segundo caso trinario, validando que la trinaridad NO es one-off de payments; PAUSE = constituir SMTP self-hosted reproduce la lógica "upstream user action mandatory" en otro dominio).

**Cita:** `[memory:decisions#D-011]`

---

## D-012 — `add-mobile` PWA default + native shell override; pattern boundary (binary, NO PAUSE)

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S6 (autoría del skill `add-mobile`) emergió la decisión arquitectural sobre cuál mobile mode es el path por defecto. add-mobile podría haber tomado tres caminos:

1. PWA como default (Mode A) con native shell (Capacitor o RN+Expo) como override.
2. Native shell como default con PWA fallback.
3. Trinario completo siguiendo el patrón D-010/D-011 (default + override + PAUSE).

La pregunta clave era: ¿add-mobile sigue el patrón trinario de D-010 (entity legal vs MoR, con PAUSE = constituir empresa) y D-011 (compliance vs ecosystem, con PAUSE = constituir SMTP self-hosted), o emerge como caso binario distinto?

**Decision:** PWA como default cuando ambiguo o sin Tech Spec, con flag `assumed_default = true`. Native shell (Capacitor o React Native + Expo) como override explícito por decision tree (codebase actual + native features mandatorios + store distribution requerida). **NO PAUSE option.**

El skill es **binario** (Mode A PWA + Mode B/C native), NO trinario. add-mobile NO tiene un degenerate case que requiera acción upstream del usuario antes de re-invocar el skill — PWA es siempre fallback graceful válido. La "no PAUSE" es una decisión empírica del dominio, no un olvido de design.

**Alternatives considered:**

- Native shell como default (Capacitor o RN+Expo): rechazado. Native shell requires $99/año Apple + $25 Google + store review cycles + native build pipelines. Default native fricciona el 80% case (indie/SaaS web-first sin store distribution).
- Trinario con PAUSE: explícitamente rechazado por análisis del dominio. PAUSE en D-010 ("constituir empresa MoR") y D-011 ("constituir SMTP self-hosted") existen porque el degenerate case en esos dominios genuinamente requiere acción upstream del usuario antes de poder usar el skill productivamente. En mobile no hay equivalente:
  - ¿Sin developer accounts? → PWA sirve.
  - ¿Sin App Store distribution? → PWA sirve (TWA opcional para Android).
  - ¿Sin compliance enterprise para "real apps"? → PWA es web, no aplica.
  - ¿iOS Safari mayoritario con limitaciones de push? → PWA sirve con caveats.
  - ¿Audiencia vintage browsers sin SW support? → PWA installable sin push (manifest only).
  
  El único caso donde PWA NO sirve es proyectos que requieren features genuinamente nativas (camera con quality control fino, biometrics, in-app purchases con Apple Pay, deep linking sistema, background sync robusto). Esos casos eligen Mode B o C — no necesitan PAUSE, eligen override.
- PWA default + native shell override sin PAUSE (binario): aceptado.

**Consequences:**

- (+) **Generalización del patrón validada con boundary explícito.** D-009 (binary, technical maturity axis) → D-010 (trinario, entity-legal axis) → D-011 (trinario, compliance-ecosystem axis) → D-012 (binary, distribution + native features axis). El patrón "default + override + PAUSE" NO es universalmente trinario. La presencia de PAUSE depende del dominio: cuando el degenerate case requiere acción upstream del usuario (constituir empresa MoR / constituir SMTP self-hosted), el patrón es trinario. Cuando el degenerate case es siempre subset del default (mobile: PWA es subset funcional de native shell, siempre disponible aunque sub-óptimo), el patrón es binario. Esta es la lección estructural más importante del bloque D.
- (+) **PWA default optimiza el caso común.** Setup speed (10 min vs 2-8h), cero dependencias developer accounts ($0 vs $124+/año), cero store review cycles, iteración deploy instant, free tier infinito en Vercel/Netlify, cross-browser coverage moderna. La mayoría de proyectos que invocan add-mobile son SaaS B2B o B2C web-first que NO necesitan native UX nativo.
- (+) **Mode B y C son first-class.** Capacitor (web-first wrap) y React Native + Expo (mobile-first standalone) cubren native shell deseado sin force-fit. Capacitor reusa templates/pwa/ (web codebase no se reescribe). RN+Expo es codebase paralelo cuando mobile-first es la decisión correcta.
- (+) **D-012 captura pattern limit empíricamente.** Sin el bloque D completo (4 skills), no se podría haber escrito este boundary con confianza. El experimento triplica el patrón (D-010 + D-011 trinarios + D-012 binario) y permite generalización abstracta: "default friction-reducer + override explícito por decision tree" es la parte universal; PAUSE es opcional según dominio.
- (+) **Cross-browser coverage robusta.** PWA cubre Chrome (desktop + Android), Edge, Firefox, Safari 16.4+. Native shells cubren App Store + Play Store. Combinación complementaria.
- (-) **iOS Safari quirks documentation overhead.** Mode A (PWA) tiene 10 quirks documentados en `references/ios-safari-quirks.md`. Esto es technical debt del platform, no del skill. Mitigado con references explícitas + handoff-el-guardian gate iOS Safari quirks.
- (-) **Mode B (Capacitor) requires Mode A correctamente generado.** Si Mode A se omite o se altera manualmente, Capacitor no puede envolver coherentemente. Mitigado con PREFLIGHT Mode B verificando que templates/pwa/ archivos existen.
- (-) **Mode C (RN+Expo) NO reusa codebase web.** Es codebase paralelo standalone — duplicación de logic en client. Mitigado con backend Next.js compartido (mismo Supabase + auth) + advisory en handoff sobre coexistencia web + mobile.
- (-) **Boundary explanation requires care en docs.** Sin distinción clara, futuros maintainers podrían intentar agregar PAUSE a add-mobile pensando que "el patrón es trinario". `decision-tree.md` documenta el boundary explícito + `references/examples.md` incluye anti-pattern "PAUSE attempted" (government healthcare HIPAA → PWA, NO halt).

**Mitigación:**

- SKILL.md de add-mobile + `prompts/decision-tree.md` documentan explícitamente que el patrón es binario (NO trinario) con D-012 cita en cada lugar relevante.
- `references/examples.md` incluye 3 escenarios + anti-pattern "PAUSE attempted" para ilustrar dónde NO aplica PAUSE incluso cuando parece tentador.
- Pattern boundary tabla en `prompts/decision-tree.md` muestra D-009 → D-012 con presencia/ausencia de PAUSE explicada.

**Cross-skill applicability — generalización del patrón post-bloque D:**

Análisis de los 4 skills del bloque D:

| Skill | Decision | Axis | Estructura | PAUSE? | Razón |
|-------|----------|------|------------|--------|-------|
| add-login (D-009) | Supabase default + Insforge override | technical maturity | binary | NO | Override es alternativa técnica plena; sin halt-blocked case |
| add-payments (D-010) | Stripe default + Polar override + PAUSE | entity legal vs MoR | trinary | YES | PAUSE = constituir empresa para casos indie sin entity legal |
| add-emails (D-011) | Resend default + SendGrid override + PAUSE | compliance vs ecosystem | trinary | YES | PAUSE = constituir SMTP self-hosted para data sovereignty |
| add-mobile (D-012) | PWA default + native shell override | distribution + native features | binary | NO | PWA es subset funcional siempre disponible; native es override por feature, no halt |

**Generalización válida cross-domain:**

> "Default friction-reducer + override explícito por decision tree" es la parte universal del patrón D-009 → D-012. PAUSE es opcional, depende del dominio.
> 
> PAUSE existe cuando el degenerate case requiere acción upstream del usuario antes de re-invocar el skill productivamente (constituir entity legal, constituir infra). NO existe cuando el degenerate case es siempre subset del default disponible (PWA siempre sirve, aunque sub-óptimamente, vs. native shell con full native UX).

Esta es la lección estructural del bloque D, capturada en D-012. Futuros add-* skills (Phase 5+) pueden adoptar la estructura binaria o trinaria según el axis específico de su dominio. **El test es: ¿hay un degenerate case que requiera acción upstream del usuario antes de re-invocar el skill productivamente? Si sí, trinario con PAUSE. Si no, binario.**

**Promoted to:** [memory:lessons#L-004] (test diagnóstico binario-vs-trinario — D-012 fue el caso que CERRÓ la generalización al ser binario después de 2 trinarios consecutivos. Sin D-012 la observación habría quedado como pattern hipotético; con D-012 se prueba boundary empírico y se promueve a lesson cross-skill).

**Cita:** `[memory:decisions#D-012]`

---

## D-013 — `la-forja` pattern selector es BINARY-shaped (sexta validación cross-skill de L-004, sin PAUSE)

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S9 (autoría del skill `la-forja`) emergió la decisión arquitectural sobre la estructura del pattern selector entre los 3 patterns multi-agent (Coordinator / Fork / Swarm). Pregunta clave: ¿la-forja sigue el patrón binary (D-009 login, D-012 mobile) o trinary con PAUSE (D-010 payments, D-011 emails)?

Antes de F3-S9 se acumularon 4 ADRs cross-skill validando el patrón "default friction-reducer + override explícito" emergido en D-009. La generalización post-bloque D dejada en [memory:lessons#L-004]:

> Test diagnóstico binario-vs-trinario: ¿existe degenerate case que requiera acción **upstream** del usuario antes de re-invocar el skill productivamente? Si SÍ → trinario (default + override + PAUSE). Si NO → binario (default + override solo).

la-forja podría haber tomado tres caminos:

1. **Trinary (con PAUSE):** asumir la-forja sigue D-010/D-011 trinary, inventar un PAUSE artificial (ej: "constituir git worktree-capable git instalado para Fork").
2. **Binary (default + 2 overrides, sin PAUSE):** aplicar el L-004 test, encontrar que NO hay degenerate case que requiera upstream user action, declarar binary.
3. **Sui-generis** (no aplica L-004): argumentar que pattern selector ≠ provider selector, por lo que L-004 no aplica directamente.

**Decision:** la-forja es **BINARY-shaped**. Default Fork + overrides Coordinator/Swarm. NO PAUSE. Aplicación rigurosa del L-004 test:

| Caso del Blueprint / runtime | ¿Upstream user action requerida? | Resultado |
|------------------------------|----------------------------------|-----------|
| Sin Blueprint | Sí (correr la-herreria) | **PREFLIGHT halt, NO PAUSE genuino** del selector |
| Sin active feature | Sí (pickear backlog) | PREFLIGHT halt, NO PAUSE |
| Skills.md missing entry | Sí (audit registry) | PREFLIGHT halt, NO PAUSE |
| Blueprint con dependencias secuenciales | NO (Coordinator pattern lo maneja) | NO PAUSE |
| Blueprint con sub-tasks atómicos | NO (Swarm lo maneja) | NO PAUSE |
| Blueprint paralelizable, disco lleno | NO (degradar a Coordinator graceful) | NO PAUSE |
| Conflictos circulares en cherry-pick | NO (degradar a Coordinator + reportar) | NO PAUSE |
| git worktree no disponible | NO (degradar a Coordinator) | NO PAUSE |
| TODOS los workers fallan | NO (re-orchestrate Coordinator o el-yunque manual) | NO PAUSE |

PREFLIGHT halt (Blueprint missing → handoff la-herreria) es **gate de entrada**, NO degenerate case del selector entre Coordinator/Fork/Swarm. la-herreria es upstream del flow general (la-herreria → la-forja), no del selector entre los 3 patterns.

**Distinción crítica binary 3-options vs trinary 1-option-PAUSE:**

L-004 distingue **estructura del selector**, no cantidad de opciones. la-forja tiene 3 patterns disponibles (Coordinator/Fork/Swarm) pero la estructura es **default + override(s)**, todos siempre disponibles, sin halt-blocked-pre-upstream-action. Esa estructura es BINARY incluso con 3 opciones. Trinary requeriría un PAUSE genuino que requiere acción upstream del usuario antes de re-invocar productivamente.

**Alternatives considered:**

- Trinary con PAUSE artificial ("git worktree no disponible → constituir git ≥ 2.5"): rechazado. git es siempre instalable; degradación a Coordinator es siempre graceful. Inventar PAUSE artificial viola L-004 explícito ("nunca force-fit a trinario sin aplicar el test... default a binario y documenta en ADR que el test mostró NO degenerate case").
- Sui-generis (no aplica L-004 al pattern selector vs provider selector): rechazado. L-004 generaliza a "selector entre N opciones", no específicamente provider selector. La estructura "default + override(s)" cabe en ambos contextos.
- Binary explícito post-test rigoroso: aceptado.

**Consequences:**

- (+) **Sexta validación cross-skill de L-004** (D-009 binary, D-010 trinary, D-011 trinary, D-012 binary, D-013 binary). Total: 3 binary, 2 trinary post-bloque D + bloque ortogonal. La generalización empírica reafirmada: PAUSE existe cuando el degenerate case requiere acción upstream del usuario; NO existe cuando degenerate case es siempre subset disponible del default.
- (+) **Boundary explícito documented:** la-forja ejemplifica un caso donde múltiples opciones (3 patterns) NO necesariamente implican estructura trinary. Cantidad de opciones ≠ estructura del selector. Futuros maintainers pueden citar D-013 al evaluar si su skill es binary-with-multiple-overrides o trinary-with-PAUSE.
- (+) **Default Fork emerge naturalmente** del L-004 test — no hay halt-blocked específico de Fork; degradación graceful a Coordinator si Fork falla. Coordinator/Swarm como overrides explícitos por axes específicos (dependencias secuenciales / atomicidad).
- (+) **PREFLIGHT halt vs PAUSE distinción clarificada.** D-013 documenta explícitamente que halt-blocked en faltantes mandatorios (Blueprint, active feature, registry) es gate de entrada NO PAUSE genuino del pattern selector. Distinción importable para futuros skills cuyo PREFLIGHT puede tentarse a llamar PAUSE.
- (+) **Honesty over ornament:** L-004 explícito dice "más honesto que inventar un PAUSE artificial". D-013 sigue esa norma.
- (-) **Pattern selector con 3 opciones puede confundir a quien busca shape simétrico con D-010/D-011 trinarios.** Mitigado con `references/pattern-selector-rationale.md` que documenta la distinción binary 3-options ≠ trinary 1-option-PAUSE.
- (-) **Quinto data point binary marginal valor estadístico cross-skill.** La generalización post-bloque D ya estaba sólida (D-009 + D-012 binary, D-010 + D-011 trinary). D-013 confirma pero no descubre patrón nuevo. Trade-off aceptable: confirmation explícita > silent assumption.

**Mitigación:**
- SKILL.md de la-forja sección "3 patterns" documenta explícitamente que la-forja es BINARY-shaped con cita D-013.
- `prompts/select-pattern.md` aplica el L-004 test caso por caso con tabla 9-rows + cita D-013 en output canónico YAML.
- `references/pattern-selector-rationale.md` dedica sección entera a "¿Por qué no es trinary aunque hay 3 patterns?" con explicación verbatim de la distinción.
- `references/examples.md` 3 escenarios canónicos (uno por pattern) que ilustran cómo cada pattern aplica sin PAUSE.

**Cross-skill applicability — generalización confirmada post-D-013:**

> "Default friction-reducer + override explícito por decision tree" es la parte universal del patrón D-009 → D-013. PAUSE es opcional, depende del dominio + estructura del selector.
>
> PAUSE existe cuando el degenerate case requiere acción upstream del usuario antes de re-invocar el skill productivamente. NO existe cuando el degenerate case es siempre subset del default disponible (PWA siempre sirve, Coordinator siempre disponible si Fork falla).
>
> Cantidad de opciones del selector NO determina estructura. la-forja con 3 patterns es binary porque ningún degenerate case requiere upstream user action específica del pattern selector — los 3 patterns están siempre a la mano.

Skills futuros con pattern selector multi-option (potencialmente: orchestrator wizards Phase 5+ que componen cadenas, futuros add-* con múltiples backends paralelos) deben aplicar el mismo test antes de force-fit a trinario.

**Promoted to:** [memory:lessons#L-004] (sexta validación cross-skill — D-013 NO modifica L-004, solo confirma la generalización con un dato más. Si todas las futuras aplicaciones siguen siendo binary, eventualmente L-004 puede strengthening con observación adicional sobre "selectores con N opciones donde el shape es binary").

**Cita:** `[memory:decisions#D-013]`

---

## D-014 — `el-crisol` shape es sequential pipeline; L-004 NO aplica directo (primer boundary cross-skill)

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S10 (autoría del skill `el-crisol`) emergió la pregunta arquitectural sobre si L-004 (test diagnóstico binario-vs-trinario para el patrón "default friction-reducer + override explícito") aplica al shape de el-crisol. Pregunta clave: ¿el-crisol sigue el patrón cross-skill validado en D-009..D-013, o emerge como caso boundary donde L-004 NO aplica directo?

Antes de F3-S10 se acumularon 5 ADRs cross-skill validando L-004 (D-009 add-login binary, D-010 add-payments trinary, D-011 add-emails trinary, D-012 add-mobile binary, D-013 la-forja binary). La generalización post-bloque-D + ortogonal capturada en [memory:lessons#L-004]:

> "Default friction-reducer + override explícito por decision tree" es la parte universal del patrón D-009 → D-013. PAUSE es opcional, depende del dominio.

**Pre-condición implícita del test L-004:** existe un eje decisional entre **alternativas paralelas a comparar** (Supabase vs Insforge, Stripe vs Polar, Resend vs SendGrid, PWA vs native shell, Coordinator vs Fork vs Swarm).

el-crisol podría haber tomado tres caminos:

1. **Force-fit L-004 a el-crisol** inventando un selector artificial (ej: "default = ejecutar 7 pasos / override = solo dashboard / PAUSE = Blueprint missing"). Eso violaría verbatim L-004: "NUNCA force-fit a trinario sin aplicar el test... default a binario y documenta en ADR que el test mostró NO degenerate case".
2. **Saltar el análisis L-004** y autoría sin documentar shape. Riesgo: futuros maintainers asumen que TODOS los skills tienen shape selector, generalización del patrón se infla y pierde precisión.
3. **Documentar explícitamente que L-004 NO aplica directo** + razón estructural + boundary del patrón generalizado. Honesty-over-ornament.

**Decision:** **L-004 NO aplica directo a el-crisol.** Documentado explícitamente como primer boundary cross-skill del patrón emergido en D-009..D-013.

el-crisol shape estructural: **sequential pipeline con resume-aware state detection.**

- **Sequential:** 7 pasos en orden de dependencia fijo (brujula → estrella → rivales → precio → roi → metas → lanzamiento). NO se eligen paths alternativos — el orden está dictado por las dependencias entre los outputs.
- **Resume-aware:** detección Fase 0 escanea docs existentes en raíz proyecto + `.claude/reports/` y skipea los que ya están. NO es selector — es detector + skipper.
- **State detection:** estado del pipeline = qué docs existen, no qué provider se eligió.

**Análisis caso por caso de "decisiones potenciales" dentro de el-crisol:**

| Decisión potencial | ¿Es selector entre N providers? | ¿Aplica L-004? |
|--------------------|--------------------------------|----------------|
| 4 modos de invocación (`go` / `saltar N` / `desde N` / `solo dashboard`) | NO — son modos de control de flow del MISMO pipeline, no providers alternativos | NO |
| Perplexity research opt-in (sí/no) | NO — feature flag enrichment, no elección entre providers de research | NO |
| Veredicto Go/Caution/No-Go | NO — son outputs del scoring, no decisiones del usuario sobre qué path tomar | NO |
| Handoff post-Go (la-forja vs el-yunque) | Borderline — selector entre orquestadores | Aplica L-004 EN la-forja level (D-013), NO en el-crisol |
| 7 pasos del pipeline | NO — secuenciales con dependencias, no alternativas paralelas | NO |

el-crisol NO contiene un selector entre N providers que requiera L-004 test.

**Análisis de degenerate cases con upstream user action (separado del test selector):**

| Caso degenerate | ¿Requiere upstream user action? | Resultado |
|-----------------|-------------------------------|-----------|
| Sin Blueprint | Sí (correr la-herreria) | **PREFLIGHT halt — gate de entrada general del flow la-herreria → el-crisol → la-forja, NO PAUSE genuino del selector (no hay selector)** |
| Sin docs estratégicos previos | NO (cold start es default `go`) | NO PAUSE |
| Algunos docs existen, otros no | NO (resume-aware detection skipea existentes) | NO PAUSE — feature explícita del skill |
| Build Confidence Score = No-Go | NO (output del scoring, usuario decide replantear) | NO PAUSE |
| Perplexity quota exhausted | NO (graceful degradation sin enrichment) | NO PAUSE |
| Inconsistencia entre docs (paso N contradice N-1) | NO (halt + reportar al humano para resolución manual) | Halt operacional, NO PAUSE-style |

Igual que la-forja en D-013, el-crisol NO tiene PAUSE genuino. Pero la diferencia estructural es **categórica**: la-forja **podría** haber tenido shape trinary (es selector entre 3 patterns); el-crisol **no puede** tener shape binary/trinary porque no es selector. **Aplicar L-004 a el-crisol es category error.**

**Alternatives considered:**

- Force-fit L-004 con selector artificial: rechazado, viola verbatim L-004 + introduce ambigüedad sobre cuándo aplica el patrón.
- Saltar análisis sin documentar: rechazado, deja el boundary del patrón implícito → futuros skills inflan generalización.
- Documentar explícitamente boundary cross-skill: aceptado.

**Consequences:**

- (+) **Primer ADR cross-skill que establece límite del patrón L-004.** Después de 5 ADRs validando L-004 en su scope canónico (D-009 binary, D-010/D-011 trinary, D-012 binary, D-013 binary con 3-options), D-014 establece el primer caso donde L-004 NO aplica. Esto NO debilita L-004 — la confirma. Las 5 ADRs previas validaron el patrón **dentro** de su scope (selectores entre N providers); D-014 establece el **borde exterior** del scope.
- (+) **Honesty-over-ornament documentado.** Force-fit L-004 a el-crisol hubiera sido más "elegante" (todos los skills bajo mismo patrón) pero engañoso. La documentación explícita del boundary es más honesta y útil para maintainers futuros.
- (+) **Generalización refinada del patrón post-D-014:** "Default friction-reducer + override explícito" aplica a skills con eje decisional entre N providers/approaches. Skills con shape distinto (sequential pipelines, resume-aware orchestrators, validation chains) NO entran en el patrón. Esto preserva la precisión analítica.
- (+) **Implicación clara para futuros skills:** orchestrator wizards (Phase 5+) que sean composers de skills (pipelines), validation chains (que sean sequenced check), o detection skills, deben aplicar el L-004 test rigurosamente para confirmar que NO hay selector dentro, y si NO hay → documentar en ADR análogo a D-014.
- (+) **Boundary protege la utilidad del patrón.** Sin D-014, future maintainers podrían over-aplicar L-004 a todo skill (riesgo: patrón se vuelve genérico "todo skill tiene default+override" → pierde poder de distinción analítica).
- (-) **Asimetría con D-009..D-013** (5 ADRs aplicaban L-004, D-014 no). Mitigado con `references/strategy-pipeline-rationale.md` que documenta análisis explícito de por qué + tabla de generalización post-D-014.
- (-) **Cognitive load adicional.** Maintainers ahora deben primero clasificar el shape del skill (selector vs pipeline vs validator vs ...) antes de aplicar L-004. Trade-off aceptable: precisión analítica > simplicidad superficial.
- (-) **Posible confusión** "PREFLIGHT halt vs PAUSE genuino". Mitigado en `references/strategy-pipeline-rationale.md` con tabla explícita: PREFLIGHT halt (Blueprint missing → handoff la-herreria) es gate de entrada del flow, NO degenerate case del pattern selector (no hay selector).

**Mitigación:**

- SKILL.md de el-crisol regla operativa 9 documenta explícitamente que "L-004 NO aplica directo. Documentado en `references/strategy-pipeline-rationale.md` y D-014".
- `references/strategy-pipeline-rationale.md` (110+ LOC) dedicado a la explicación detallada con tabla de análisis caso por caso, distinción shape categórica, y tabla de generalización D-009..D-014.
- skills.md el-crisol entry cita D-014 en sección Cita (post-este commit).
- `references/strategy-pipeline-rationale.md` cita las 5 ADRs previas (D-009..D-013) cross-cited para que el lector pueda navegar el contexto completo.

**Cross-skill applicability — pattern boundary establecido post-D-014:**

> **L-004 aplica solo a skills con eje decisional entre N providers/approaches alternativos. Skills con shape distinto (sequential pipelines, resume-aware orchestrators, validation chains, detection skills) requieren ADR análogo a D-014 que documente shape + razón por la que L-004 NO aplica directo.**

Skills futuros deben aplicar el siguiente flow:

```
1. ¿Hay un selector entre N providers/approaches alternativos dentro del skill?
   ├── Sí → aplicar L-004 test → binary o trinary según degenerate case requiere upstream user action
   └── No → documentar en ADR análogo a D-014:
       a. Identificar shape estructural (pipeline / validator / detector / orchestrator-composer / ...).
       b. Análisis caso por caso de "decisiones potenciales" dentro del skill (NO selectores).
       c. Análisis separado de degenerate cases (PREFLIGHT halt vs PAUSE-style).
       d. Tabla de generalización ubicando el ADR en el patrón cross-skill.
       e. Boundary explícito al final.
```

Phase 5+ orchestrator wizards (composers de skills) probablemente serán pipelines + tendrán selectores internos. Aplicar L-004 al selector específico, NO al wizard entero — ese es el patrón correcto, no force-fit del wizard.

**Promoted to:** [memory:lessons#L-004] (boundary case — D-014 NO modifica L-004, documenta el primer caso donde NO aplica directo. Si emergen >2 casos boundary cross-skill, eventualmente L-004 puede strengthening con observación adicional sobre "el patrón aplica a selectores; pipelines/validators/composers requieren ADR análogo dedicado").

**Cita:** `[memory:decisions#D-014]`

---

## D-015 — `web-quality` BINARY-shaped (live default + static fallback) y refina D-014 doctrine: presencia del selector determina aplicabilidad de L-004

**Date:** 2026-05-08
**Status:** accepted

**Context:** durante F3-S11 (autoría del skill `web-quality` — el último, 18/18) emergió la decisión arquitectural sobre cómo aplicar L-004 a un skill que es validator (similar a el-evaluador) pero **con selector explícito** entre dos modos de operación: live audit (Lighthouse-based, default por D4 con agent-browser CLI) y static analysis (lectura de código, fallback graceful).

D-014 había establecido el primer boundary cross-skill del patrón L-004 (el-crisol pipeline shape sin selector). La doctrine declarada:

> "L-004 aplica solo a skills con eje decisional entre N providers/approaches alternativos. Skills con shape distinto (sequential pipelines, resume-aware orchestrators, **validation chains**, detection skills) requieren ADR análogo a D-014 que documente shape + razón por la que L-004 NO aplica directo."

D-014 mencionó **"validation chains"** como ejemplo de shape donde L-004 podría no aplicar. web-quality es validator pero CON selector (live vs static). Sin D-015, dos lecturas posibles:

1. **Lectura literal de D-014:** "validators son ADR propio, L-004 NO aplica" → force-fit al shape categórico, ignorando la presencia real del selector dentro del skill.
2. **Lectura refinada:** "L-004 aplica si y solo si el skill tiene selector entre N providers/approaches, independientemente de la categoría del skill (validator/pipeline/orchestrator/composer)".

web-quality podría haber tomado tres caminos:

1. **Force-fit doctrine D-014 a web-quality "porque es validator":** rechazado, viola la lógica empírica del patrón L-004 (ignora que el selector existe).
2. **Tratar web-quality como excepción ad-hoc sin formalizar:** rechazado, deja la doctrine ambigua para futuros skills.
3. **Refinar D-014 doctrine explícitamente** + aplicar L-004 al selector binary live vs static: aceptado.

**Decision:** **L-004 aplica a web-quality.** El skill es **BINARY-shaped** con live audit default + static analysis fallback graceful, sin PAUSE.

D-015 **refina** D-014 doctrine:

> **D-014 original (post-el-crisol):** "L-004 aplica solo a skills con eje decisional entre N providers/approaches alternativos. Skills con shape distinto requieren ADR propio."
>
> **D-015 refinamiento:** **L-004 aplica si y solo si el skill tiene un selector entre N providers/approaches alternativos. La presencia o ausencia del selector — no la categoría del skill — determina si L-004 aplica.** Pipelines, validators, composers, detectors, orchestrators — cualquier shape — siguen la misma regla: ¿hay un selector dentro? Si sí → L-004 aplica. Si no → ADR propio análogo a D-014.

**L-004 test aplicado a web-quality:**

| Caso | ¿Upstream user action requerida? | Resultado |
|------|---------------------------------|-----------|
| Sin URL ni server (live no viable) | NO — static SIEMPRE disponible (basta leer `src/` o `pages/`) | NO PAUSE |
| Sin proyecto Next.js detectable | Sí (constituir proyecto target) | **PREFLIGHT halt, NO PAUSE genuino del selector** (no es decisión live vs static, es gate de entrada) |
| agent-browser CLI no instalado | NO — Lighthouse CLI fallback o degradar a static | NO PAUSE |
| Lighthouse CLI no instalado tampoco | NO — degradar a static graceful | NO PAUSE |
| Build dist o `.next` ausente | NO — static analysis funciona sobre `src/` | NO PAUSE |
| Network blocked (CDN inaccesible) | NO — agent-browser puede correr headless local | NO PAUSE |

**Conclusión:** **BINARY** confirmado. live default + static fallback, sin PAUSE genuino.

**Alternatives considered:**

- **Force-fit doctrine D-014 a web-quality:** rechazado porque ignora la presencia real del selector. La lógica del patrón L-004 (D-009..D-013) emerge de la pregunta "¿hay alternatives entre providers?" — esa pregunta tiene respuesta SÍ en web-quality (live vs static son técnicas distintas con outputs distintos).
- **Force-fit trinary inventando un PAUSE artificial** ("live offline → constituir server local"): rechazado, agent-browser puede correr headless contra static HTML, fallback a static siempre disponible. Ningún caso requiere upstream user action específica del selector.
- **Tratar como excepción ad-hoc:** rechazado, deja la doctrine ambigua. Refinar formalmente D-014 con D-015 es la solución analíticamente honesta.
- **BINARY con D-015 refinement formal:** aceptado.

**Consequences:**

- (+) **Doctrine D-014 refinada con regla operacional clara post-D-015.** "Presencia del selector determina aplicabilidad" es regla universal aplicable a cualquier shape (pipeline/validator/orchestrator/composer). NO hay categorías del skill que automáticamente impliquen no-L-004.
- (+) **Scoreboard cross-skill final completo (post-bloque-D + ortogonal completo + 18/18 skills authored):**
  - Binary (4): D-009 add-login, D-012 add-mobile, D-013 la-forja, D-015 web-quality
  - Trinary (2): D-010 add-payments, D-011 add-emails
  - Boundary case (1): D-014 el-crisol (sin selector, ADR propio)
  - Total: 7 ADRs cross-skill cubriendo el patrón en su totalidad. Milestone F3 cerrado.
- (+) **Honesty-over-ornament reaffirmed.** D-014 mencionó "validation chains" como ejemplo, no como regla absoluta. D-015 muestra que validators NO son uniformes — algunos sin selector (el-evaluador, futuros validation skills sin alternatives), otros con selector (web-quality). La doctrine refinada captura esta heterogeneidad sin force-fit.
- (+) **Implicación clara para Phase 5+ (orchestrator wizards, composers).** Esos skills probablemente combinarán múltiples selectors + pipelines + validators. Aplicar L-004 al selector específico, NO al wizard entero (que puede contener múltiples selectores con shapes distintos). Cada selector se evalúa independientemente.
- (+) **Distinción binary 2-options vs trinary 3-options-PAUSE definitivamente clara.** L-004 distingue **estructura del selector**, no cantidad de opciones. web-quality tiene 2 modos (binary obvio). la-forja tenía 3 patterns (binary porque ningún degenerate case). Trinary requiere PAUSE genuino (degenerate case con upstream user action específica).
- (+) **Cierra el análisis cross-skill del patrón L-004.** 7 ADRs (D-009 → D-015), 18/18 skills. La generalización está sólida y aplicable a futuros skills.
- (-) **D-015 representa un refinamiento sobre D-014 (no nuevo descubrimiento puro).** Algunos podrían argumentar que la doctrine D-014 ya implicaba esta refinement implícitamente. Mitigado al hacer explícita la regla "presencia del selector determina aplicabilidad" — futuros maintainers no deben inferir, leen la regla directa.
- (-) **Cognitive load aumenta marginalmente.** Maintainers ahora deben: (1) clasificar shape del skill, (2) detectar selector dentro del skill (si lo hay), (3) si selector → L-004 binary/trinary; (4) si NO selector → ADR propio. Trade-off aceptable: precisión analítica > simplicidad superficial.

**Mitigación:**

- SKILL.md de web-quality regla operativa 11 documenta: "L-004 aplica (D-015). A diferencia de el-crisol (D-014 pipeline shape sin selector), web-quality SÍ tiene selector binary. D-015 refina D-014 doctrine."
- `references/audit-mode-rationale.md` (130+ LOC) dedicado a la explicación + tabla de aplicación L-004 caso por caso + scoreboard 7 ADRs cross-skill final + regla operacional definitiva.
- skills.md web-quality entry cita D-015 en sección Cita (post-este commit).
- skills.md milestone note: "F3 skills authoring completado — 18/18 skills en registry. Patrón L-004 cross-skill: 7 ADRs (D-009..D-015), 4 binary + 2 trinary + 1 boundary case."

**Cross-skill applicability — pattern boundary final post-D-015:**

> **Regla operacional definitiva (post-bloque-D + ortogonal completo):**
>
> 1. **¿El skill tiene un selector entre N providers/approaches alternativos dentro?**
>    - Sí → aplicar L-004 test → binary o trinary según degenerate case requiere upstream user action específica del selector.
>    - No → ADR propio análogo a D-014:
>      - Documentar shape estructural (pipeline / validator-fijo / composer / detector / etc.)
>      - Análisis caso por caso de "decisiones potenciales" descartando que sean selectores reales.
>      - Análisis separado de degenerate cases (PREFLIGHT halt vs PAUSE-style del selector).
>      - Ubicación en scoreboard cross-skill.
>
> 2. **La categoría del skill (validator/pipeline/orchestrator/...) NO determina aplicabilidad.** Solo la presencia del selector determina. validators con selector → L-004 aplica; validators sin selector → ADR propio.
>
> 3. **Si en evolución futura emerge selector dentro de un skill que originalmente NO lo tenía** (ej: el-crisol Phase 6+ agrega selector entre 2 templates de scoring) → ADR follow-up aplicando L-004 al selector específico, sin invalidar el ADR original que documentó el shape sin selector.

Skills futuros (Phase 5+ orchestrator wizards, composers, futuros add-* extensions) deben aplicar este flow rigurosamente.

**Final scoreboard cross-skill (D-009..D-015):**

| ADR | Skill | Tiene selector? | L-004 aplica? | Resultado |
|-----|-------|-----------------|---------------|-----------|
| D-009 | add-login | Sí (Supabase / Insforge) | SÍ | binary |
| D-010 | add-payments | Sí (Stripe / Polar / PAUSE empresa MoR) | SÍ | trinary |
| D-011 | add-emails | Sí (Resend / SendGrid / PAUSE SMTP) | SÍ | trinary |
| D-012 | add-mobile | Sí (PWA / native shell) | SÍ | binary |
| D-013 | la-forja | Sí (Coordinator / Fork / Swarm — 3 opciones binary-shape) | SÍ | binary |
| D-014 | el-crisol | NO (sequential pipeline + resume-aware) | NO | boundary case (ADR propio) |
| D-015 | web-quality | Sí (live / static) | SÍ | binary |

7 ADRs total. 4 binary, 2 trinary, 1 boundary case. **Patrón L-004 cubierto en su totalidad para Forja Phase 3 (18/18 skills authored).**

**Promoted to:** [memory:lessons#L-004] (refinement — D-015 NO modifica L-004 verbatim, refina D-014 doctrine. La lesson L-004 puede beneficiarse de strengthening en futuro post-Phase 5+ con observación adicional sobre "presencia del selector como criterio universal — no la categoría del skill"). Se evaluará promotion explícita cuando Phase 5+ tenga datos cross-orchestrator-wizards.

**Cita:** `[memory:decisions#D-015]`

---

## D-016 — `el-tajo` BINARY (execute / escalate-graceful a el-golpe, sin PAUSE)

**Date:** 2026-05-09
**Status:** accepted

**Context:** durante F3-S12 (autoría de el-tajo, microtarea atómica one-shot <5min/<500 LOC/1-3 archivos) emergió la pregunta sobre la shape del selector entre "execute" (default si scope califica como tajo) y "escalate" (si scope excede los criterios atómicos). Pregunta clave: ¿es binary o trinary el selector?

**L-004 test aplicado:**

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Sin active feature (PREFLIGHT) | Sí (pickear backlog o correr la-herreria) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Tests rojos pre-arranque (PREFLIGHT) | Sí (fixar tests primero) | **PREFLIGHT halt, NO PAUSE genuino** |
| Scope excede criterios atómicos | NO — escalate a el-golpe SIEMPRE disponible | NO PAUSE |
| el-golpe también excede (>30min) | NO — escalate a /build (la-forja) SIEMPRE disponible | NO PAUSE |

**Decision:** **BINARY** confirmed. Default = execute (si los 3 criterios atómicos califican: <5min wallclock, <500 LOC delta, 1-3 archivos). Override = escalate-graceful a el-golpe (si scope excede, siempre disponible). NO PAUSE genuino — el-golpe / /build siempre disponibles, no requieren upstream user action específica del selector.

**Razón estructural:** el patrón "escalate up the lightweight ladder" (el-tajo → el-golpe → /build) es BINARY by structure — cada nivel del ladder tiene fallback graceful al siguiente sin halt-blocked-pre-upstream-action.

**Alternatives considered:**
- Trinary con PAUSE artificial ("scope ambiguo → constituir spec más detallada"): rechazado, viola verbatim L-004 ("nunca force-fit a trinario sin aplicar el test"). Spec ambigua = halt operacional, NO PAUSE genuino.
- Sui-generis: rechazado, el patrón ladder es BINARY claro.
- Binary explícito: aceptado.

**Consequences:**
- (+) Confirmación cross-skill #5 binary del patrón D-009..D-018 (4 binary previas: D-009 login, D-012 mobile, D-013 la-forja, D-015 web-quality).
- (+) Establece patrón ladder reusable: el-tajo → el-golpe (D-017 paralelo) → /build siempre disponible.
- (+) PREFLIGHT halt vs PAUSE distinción clara: PREFLIGHT (sin active feature, tests rojos) son gates de entrada, NO degenerate cases del selector.
- (-) Asimetría con D-014 (el-crisol pipeline sin selector). Mitigado: D-016 cita D-014 doctrine refinada en D-015 — el-tajo TIENE selector, D-014 boundary case NO aplica.

**Cross-skill applicability:** patrón ladder "execute / escalate-graceful" es reusable. D-017 lo aplica a el-golpe (escalate a /build). Phase 5+ orchestrator wizards pueden tener escalate ladders multi-nivel — aplicar L-004 al selector específico, NO al wizard entero (consistente con D-015 doctrine).

**Cita:** `[memory:decisions#D-016]`

---

## D-017 — `el-golpe` BINARY (execute / escalate-graceful a /build, sin PAUSE)

**Date:** 2026-05-09
**Status:** accepted

**Context:** durante F3-S12 (autoría de el-golpe, feature mediano one-shot <30min con brief-plan visible) emergió pregunta paralela a D-016: ¿binary o trinary el selector entre "execute" y "escalate a /build"?

**L-004 test aplicado:**

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Sin active feature (PREFLIGHT) | Sí (pickear backlog) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Sin brand.json + UI requerida (PREFLIGHT) | Sí (correr add-ui-kit) | **PREFLIGHT halt, NO PAUSE genuino** (gate de entrada) |
| Tests rojos (PREFLIGHT) | Sí (fixar tests) | **PREFLIGHT halt, NO PAUSE genuino** |
| Scope excede 30min | NO — escalate a /build (la-forja) SIEMPRE disponible | NO PAUSE |
| Scope excede mid-execution | NO — commit lo hecho + escalate (graceful) | NO PAUSE |
| Iteración con feedback emerge | NO — escalate a sprint SIEMPRE disponible | NO PAUSE |
| Paralelización requerida | NO — escalate a la-forja Fork | NO PAUSE |

**Decision:** **BINARY** confirmed. Default = execute con brief-plan visible (si scope califica: <30min, ≤3 commits, sin paralelización, sin iteración). Override = escalate-graceful a /build (si excede). NO PAUSE — múltiples paths de escalate (sprint, /build) SIEMPRE disponibles.

**Razón estructural:** mismo patrón ladder de D-016. el-golpe puede escalate a /build, sprint, o la-forja Fork según razón de exceso. Todos son fallbacks graceful, ninguno requiere upstream user action específica del selector.

**Alternatives considered:**
- Trinary con PAUSE para feature multi-domain (auth + RBAC + audit): rechazado. Multi-domain → escalate a /build (Coordinator pattern de la-forja maneja secuencias). NO PAUSE.
- Trinary con PAUSE para feature requiring nuevo SDK install: rechazado. Install dep → confirmation explícita en brief-plan + execute. NO upstream user action separada.
- Binary: aceptado.

**Consequences:**
- (+) Confirmación cross-skill #6 binary (D-009, D-012, D-013, D-015, D-016, D-017). Total post-F3-S12: 6 binary + 2 trinary + 1 boundary case + 1 binary D-018 = ver D-018 para scoreboard final.
- (+) Establece **doctrine sub-pattern "ladder lightweight → orchestrator"**: el-tajo → el-golpe (lightweight tier) → /build (la-forja, orchestrator tier). Cada nivel binary, escalate up siempre disponible.
- (+) Brief-plan visible es feature distintivo de el-golpe vs el-tajo (que arranca directo). NO es selector entre approaches — es protocolo del único modo execute.
- (-) Cognitive load potencial: usuario podría confundir "modos de control de flow" (brief-plan) con "selector entre N providers" (no aplica acá). Mitigado en `references/examples.md` con anti-pattern observable.

**Cita:** `[memory:decisions#D-017]`

---

## D-018 — `skill-creator` BINARY (guided default / template-only override, sin PAUSE)

**Date:** 2026-05-09
**Status:** accepted

**Context:** durante F3-S12 (autoría de skill-creator, meta wizard que scaffolda nuevos skills) emergió la pregunta sobre el selector entre dos modos de invocación del wizard: "guided" (entrevista interactiva 5 preguntas) y "template-only" (scaffold directo a partir de YAML structured input, sin entrevista — útil para CI/automation).

**L-004 test aplicado:**

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Sin .claude/skills/ (PREFLIGHT) | Sí (cd a Forja repo) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Nombre colisiona (PREFLIGHT) | Sí (rename) | **PREFLIGHT halt, NO PAUSE genuino** |
| Usuario quiere template-only sin inputs preparados | NO — guided siempre disponible (degrada graceful) | NO PAUSE |
| Usuario quiere guided pero responde "no sé" a Q3 (tier) | NO — guided extendido con ejemplos | NO PAUSE |
| Usuario interrumpe mid-interview ("stop") | NO — stash inputs parciales y abortar (no requiere setup separado) | NO PAUSE |

**Decision:** **BINARY** confirmed. Default = guided (entrevista interactiva 5 preguntas con sub-pregunta clave Q5 selector presence). Override = template-only (scaffold directo si usuario provee YAML structured input). NO PAUSE — ambos modos siempre disponibles.

**Razón estructural:** los 2 modos son alternatives reales de invocación (guided = humano interactivo, template-only = CI/automation con inputs preparados). Cada modo aplica al mismo flow de scaffold downstream. El test L-004 confirma binary porque ningún caso requiere upstream user action específica del selector.

**Alternatives considered:**
- Trinary con PAUSE artificial ("usuario sin context Forja → constituir context primero"): rechazado, primer (skill upstream) carga context, no es PAUSE del selector skill-creator.
- Sui-generis (no aplica L-004 a meta skills): rechazado, el patrón D-015 doctrine refinada aplica universalmente — meta skills con selector siguen L-004 normal.
- Binary: aceptado.

**Consequences:**
- (+) Cierra cross-skill scoreboard L-004 con 7 binary + 2 trinary + 1 boundary case post-F3-S12.
- (+) skill-creator garantiza que skills futuros arranquen con la doctrine D-014/D-015 absorbida desde Q5 de la entrevista (selector presence as definitive principle).
- (+) Modo template-only es first-class — paridad con guided. Útil para CI/automation que scaffolda skills programáticamente.
- (-) Q5 cognitive load alto en usuario sin contexto cross-skill. Mitigado con `references/skill-template.md` + tabla de scoreboard D-009..D-018 visible en interview.md.

**Cross-skill applicability — scoreboard FINAL post-F3-S12:**

| ADR | Skill | Tiene selector? | L-004 aplica? | Resultado |
|-----|-------|-----------------|---------------|-----------|
| D-009 | add-login | Sí | SÍ | binary |
| D-010 | add-payments | Sí | SÍ | trinary |
| D-011 | add-emails | Sí | SÍ | trinary |
| D-012 | add-mobile | Sí | SÍ | binary |
| D-013 | la-forja | Sí | SÍ | binary |
| D-014 | el-crisol | NO | NO | boundary case |
| D-015 | web-quality | Sí | SÍ | binary (refina D-014 doctrine) |
| **D-016** | **el-tajo** | **Sí** | **SÍ** | **binary** |
| **D-017** | **el-golpe** | **Sí** | **SÍ** | **binary** |
| **D-018** | **skill-creator** | **Sí** | **SÍ** | **binary** |

Total: 10 ADRs cross-skill. **7 binary + 2 trinary + 1 boundary case.** Patrón cubierto en su totalidad post-F3-S12. **21/21 skills core con SKILL.md authoring + ADR registrado.**

**Doctrine final post-D-018:** "Presencia del selector dentro del skill determina aplicabilidad de L-004, NO categoría del skill" (D-015) + "ladder de escalation lightweight → orchestrator es BINARY by structure" (D-016/D-017) + "meta skills siguen L-004 normal si tienen selector" (D-018). Aplicable universalmente a Phase 5+ orchestrator wizards/composers.

**Cita:** `[memory:decisions#D-018]`

---

## D-019 — `init-saas` wizard BINARY (FRESH default / EXISTING resume-aware, sin PAUSE)

**Date:** 2026-05-09
**Status:** accepted

**Context:** durante F5-S1 (autoría de init-saas wizard que compone add-ui-kit → impeccable → add-login para resolver E-006 chicken-egg de cadena de skills) emergió la pregunta sobre la shape del selector entre los modos de invocación del wizard.

**L-004 test aplicado:**

| Caso | ¿Upstream user action requerida del selector wizard? | Resultado |
|------|---------------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí (correr forge-init / migrar a Next.js) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| 0 de 3 pasos completados (FRESH path) | NO — chain completa siempre disponible | NO PAUSE |
| 1-2 de 3 pasos completados (EXISTING resume-aware) | NO — wizard saltea pasos completados, sigue desde pendiente | NO PAUSE |
| 3 de 3 completados (already-complete) | NO — wizard reporta "todo listo, nada que hacer" | NO PAUSE |
| Sub-skill add-ui-kit/impeccable/add-login con PAUSE interno | NO — los 3 son binary internamente (D-009 add-login binary, add-ui-kit y impeccable binary sin PAUSE) | NO PAUSE wizard |

**Decision:** **BINARY** confirmed. FRESH (default — chain completa add-ui-kit → impeccable → add-login con todos los pasos pendientes) + EXISTING (override resume-aware — saltea pasos completados, sigue desde donde quedó). NO PAUSE genuino.

**Razón estructural:** init-saas es paralelo conceptual de el-crisol (sequential pipeline + resume-aware state detection). Pero el-crisol es **boundary case** (D-014 — sin selector entre approaches, simplemente ejecuta el pipeline canónico). init-saas SÍ tiene selector entre FRESH (todo desde cero) vs EXISTING (resume-aware) — por lo tanto L-004 aplica y resultado es BINARY.

Distinción cross-skill:
- **el-crisol (D-014):** pipeline shape sin selector — boundary case, L-004 NO aplica directo.
- **init-saas (D-019):** mismo shape estructural pero CON selector (FRESH/EXISTING) — L-004 aplica, BINARY confirmed.

Esto refuerza la doctrine D-015: presencia del selector dentro del skill determina aplicabilidad de L-004, NO categoría del skill (sequential pipeline en este caso).

**Alternatives considered:**

- Trinary con PAUSE artificial ("usuario sin Next.js → constituir proyecto Next.js"): rechazado, eso es PREFLIGHT halt no degenerate del selector wizard.
- Sui-generis: rechazado, init-saas tiene selector claro y cabe en L-004 normal.
- Boundary case análogo a D-014: rechazado, init-saas TIENE selector (a diferencia de el-crisol que no).
- BINARY explícito: aceptado.

**Consequences:**

- (+) **Confirmación cross-skill #8 binary** post-D-009..D-018. Total binary: 8 (D-009, D-012, D-013, D-015, D-016, D-017, D-018, D-019).
- (+) **Resuelve E-006 paralelo a estructura el-crisol.** init-saas establece patrón canónico para wizards Forja: cadena de 2-3 skills BUILD con resume-aware state detection. add-monetization (D-020) hereda este patrón.
- (+) **Refuerza doctrine D-015.** init-saas y el-crisol comparten shape estructural (sequential pipeline) pero ADRs distintos (binary vs boundary case) según presencia del selector. Cross-skill validación de la regla "presencia del selector determina, NO categoría".
- (+) **Resume-aware feature distintiva.** Wizard idempotente: re-invocaciones múltiples son seguras y eficientes (skipea pasos ya completados).
- (-) Cognitive load para distinguir init-saas (binary D-019) de el-crisol (boundary D-014). Mitigado en `references/chain-rationale.md` con tabla de comparación shape-par.

**Cross-skill applicability — patrón wizard establecido:**

init-saas establece el patrón canónico para wizards Forja:
1. Frontmatter con dependencies = lista de skills compuestos.
2. PREFLIGHT con gates duros para precondiciones del primer paso.
3. Fase 0 detect-state.md (resume-aware scan de outputs canónicos).
4. Fase 1 run-step.md (dispatch sub-agents por paso, R4 enforced).
5. references/chain-rationale.md (rationale del orden + comparación shape-par + cross-skill applicability).
6. tests/dry-run.sh (S1-S6 escenarios canónicos).
7. ADR del wizard documenta shape (binary/trinary/boundary) según L-004.

D-020 (add-monetization) hereda este patrón. Phase 5+ wizards futuros también.

**Cita:** `[memory:decisions#D-019]`

---

## D-020 — `add-monetization` wizard BINARY + distinción crítica PAUSE-interno-delegado ≠ PAUSE-wizard

**Date:** 2026-05-09
**Status:** accepted

**Context:** durante F5-S1 (autoría de add-monetization wizard que compone add-payments → add-emails → web-quality para resolver E-006 cadena de monetización) emergió la pregunta arquitectural sobre la shape del selector wizard, complicada por el hecho de que **dos sub-skills compuestos tienen PAUSE genuino interno**: add-payments (D-010 trinary — Polar requiere empresa MoR) y add-emails (D-011 trinary — on-prem SMTP requerido por compliance).

La pregunta clave: ¿el PAUSE de un sub-skill trinariza el wizard que lo compone?

**Razonamiento posible (incorrecto sin D-020):**

> "add-payments es trinary (D-010), add-monetization compone add-payments, por lo tanto add-monetization es trinary (al wizard level)."

Esto sería **force-fit incorrecto**. L-004 al wizard level pregunta: ¿hay degenerate case que requiera upstream user action ESPECÍFICA DEL SELECTOR WIZARD?

**L-004 test aplicado al SELECTOR WIZARD de add-monetization:**

| Caso | ¿Upstream user action requerida del **selector wizard** (full chain vs partial)? | Resultado |
|------|--------------------------------------------------------------------------------|-----------|
| Sin add-login (PREFLIGHT) | Sí — correr init-saas | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Sin Brand DNA / sin impeccable (PREFLIGHT) | Sí — handoff add-ui-kit / impeccable | **PREFLIGHT halt, NO PAUSE genuino** |
| Full chain con scope ambiguo | NO — partial mode siempre disponible | NO PAUSE |
| Partial mode → después usuario quiere full | NO — re-invocar wizard, resume-aware retoma | NO PAUSE |
| **add-payments retorna PAUSE interno (D-010 — empresa MoR Polar)** | **NO desde el selector wizard** — el PAUSE es **interno al sub-skill add-payments**. El usuario lo resuelve **dentro del scope de add-payments** (constituyendo empresa O cambiando provider). NO afecta la elección "full chain vs partial" del selector wizard. | **NO PAUSE wizard** |
| **add-emails retorna PAUSE interno (D-011 — on-prem SMTP)** | **NO desde el selector wizard** — mismo razonamiento. PAUSE interno al sub-skill add-emails. | **NO PAUSE wizard** |
| web-quality auto-degrada live → static | NO — graceful degradation, no halt | NO PAUSE |

**Decision:** **BINARY** confirmed. Full chain (default) + partial payments-only (override). NO PAUSE genuino al wizard level.

**Distinción CRÍTICA — PAUSE-interno-delegado ≠ PAUSE-wizard:**

D-020 codifica la distinción para que cross-skill sea analítico, no force-fit:

- **PAUSE-wizard genuino:** degenerate case del selector wizard que requiere upstream user action ESPECÍFICA del selector. Ej: si emergiera un caso donde el usuario debe elegir entre full chain Stripe y partial Polar y eso requiriera constituir empresa antes de decidir el selector — eso sería PAUSE genuino. NO existe en add-monetization.

- **PAUSE-interno-delegado:** un sub-skill compuesto tiene PAUSE genuino propio (D-010 add-payments / D-011 add-emails), pero el PAUSE es **interno al sub-skill** y se resuelve **dentro del scope del sub-skill** (constituyendo empresa O cambiando provider, constituyendo SMTP). NO afecta el selector wizard. El wizard:
  1. Reporta el PAUSE-interno-delegado al usuario con shape `step_result.outcome = paused-internal` + `pause_resolution`.
  2. NO escala el PAUSE al nivel selector wizard.
  3. Halt graceful — usuario resuelve.
  4. Resume-aware: re-invocación retoma desde paso N (si quedó completado post-resolución) o N+1 (si paso completó durante resolución del PAUSE).

**Alternatives considered:**

- **Trinary con PAUSE wizard escalado de sub-skill:** rechazado, viola lógica L-004 al wizard level. El selector wizard es independiente del PAUSE de sub-skills.
- **Sui-generis (no aplicar L-004 al wizard porque tiene sub-skills con PAUSE):** rechazado, doctrine D-015 aplica universalmente — wizards con selector siguen L-004 normal.
- **BINARY con distinción explícita PAUSE-interno-delegado ≠ PAUSE-wizard:** aceptado. Codifica el principio para wizards futuros.

**Consequences:**

- (+) **Confirmación cross-skill #9 binary** post-D-009..D-019. Total binary: 9 (D-009, D-012, D-013, D-015, D-016, D-017, D-018, D-019, D-020).
- (+) **Distinción cross-wizards codificada como principio.** D-020 es el primer ADR cross-skill que documenta verbatim PAUSE-interno-delegado ≠ PAUSE-wizard. Aplicable universalmente a wizards futuros que compongan sub-skills con PAUSE genuino.
- (+) **Resume-aware feature confirma BINARY.** Re-invocación post-resolución del PAUSE-interno es seguro y eficiente — el wizard NUNCA está "stuck" al wizard level por PAUSE de sub-skill.
- (+) **Refuerza doctrine D-015 + extiende para wizards.** D-015 dijo "presencia del selector dentro del skill determina". D-020 agrega: "PAUSE de sub-skills compuestos NO se escala al wizard level a menos que afecte el selector wizard específicamente".
- (+) **Resuelve E-006 paralelo a init-saas para cadena de monetización.** Patrón wizard heredado de D-019 + extendido con manejo de PAUSE-interno-delegado.
- (-) **Cognitive load alto** para distinguir PAUSE-interno-delegado de PAUSE-wizard. Mitigado con:
  - SKILL.md sección dedicada a la distinción.
  - run-step.md con manejo paused-internal explícito.
  - chain-rationale.md sección "Distinción CRÍTICA D-020" con ejemplo concreto.
- (-) **Posible mis-interpretación futura** ("add-monetization debería ser trinary porque sub-skills son trinary"). Mitigado con D-020 verbatim documentation + tabla de razonamiento incorrecto explicada.

**Cross-skill applicability — principio establecido:**

> **Wizards que componen sub-skills con PAUSE genuino aplican L-004 al wizard level independientemente del PAUSE interno de sub-skills. El PAUSE-interno-delegado se reporta al usuario y resume-aware retoma post-resolución, pero NO escala como PAUSE-wizard.**

Aplicable a futuros wizards (Phase 5+/F6+):
- **add-mobile-stack** (futuro): si compone sub-skills con PAUSE, mismo manejo.
- **enterprise-stack** (F6+): wizards multi-domain (auth + payments + admin + audit), mismo manejo.
- **migration-wizard** (futuro): wizards de migración entre versiones, si emergen sub-skills con PAUSE.

**Distinción técnica que se mantiene:**

Si en evolución futura emerge un wizard donde el PAUSE de un sub-skill SÍ afecta el selector wizard ESPECÍFICAMENTE (ej: el PAUSE bloquea la posibilidad misma de elegir entre los modos del wizard, no solo el progreso del paso), entonces aplicar L-004 estrictamente y considerar trinary al wizard level. Pero ese caso es **distinto** al PAUSE-interno-delegado y debe documentarse en su propio ADR.

**Scoreboard cross-skill FINAL post-F5-S1:**

| ADR | Skill / wizard | Tiene selector? | L-004 aplica? | Resultado | Notas |
|-----|----------------|-----------------|---------------|-----------|-------|
| D-009 | add-login | Sí | SÍ | binary | — |
| D-010 | add-payments | Sí | SÍ | trinary (PAUSE empresa MoR) | — |
| D-011 | add-emails | Sí | SÍ | trinary (PAUSE on-prem SMTP) | — |
| D-012 | add-mobile | Sí | SÍ | binary | — |
| D-013 | la-forja | Sí | SÍ | binary | — |
| D-014 | el-crisol | NO | NO | boundary case | sin selector |
| D-015 | web-quality | Sí | SÍ | binary | refina D-014 doctrine |
| D-016 | el-tajo | Sí | SÍ | binary | — |
| D-017 | el-golpe | Sí | SÍ | binary | — |
| D-018 | skill-creator | Sí | SÍ | binary | — |
| D-019 | **init-saas wizard** | **Sí** | **SÍ** | **binary** | resume-aware, paralelo a el-crisol shape |
| D-020 | **add-monetization wizard** | **Sí** | **SÍ** | **binary** | + distinción PAUSE-interno-delegado |

Total: **12 ADRs cross-skill** post-F5-S1. **9 binary + 2 trinary + 1 boundary case.**

**Doctrine final post-D-020 (4 reglas operacionales):**

1. **D-015 (regla universal):** Presencia del selector dentro del skill determina aplicabilidad de L-004 — NO categoría del skill.
2. **D-016 + D-017 (sub-pattern lightweight ladder):** Ladder de escalation lightweight → orchestrator es BINARY by structure.
3. **D-018 (meta skills):** Meta skills siguen L-004 normal si tienen selector.
4. **D-020 (wizards con PAUSE-aware sub-skills):** PAUSE-interno-delegado de sub-skills NO se escala como PAUSE-wizard. Wizards aplican L-004 al wizard level independientemente del PAUSE interno de sub-skills compuestos.

**Cita:** `[memory:decisions#D-020]`

---

## D-021 — `add-mobile-stack` wizard binary (hereda D-019)

**Date:** 2026-05-09
**Status:** accepted
**ADR class:** wizard pipeline binary application — extiende D-019.

**Context:** durante F5-S2 (autoría de wizards mayores: add-mobile-stack, enterprise-stack, migration-wizard) emergió la pregunta de qué shape aplicar a `add-mobile-stack` — wizard que extiende `init-saas` agregando un 4to paso (`add-mobile`) para proyectos que necesitan PWA + push notifications desde el bootstrap.

`add-mobile-stack` cadena: `add-ui-kit → impeccable → add-login → add-mobile`.

Particularidades:
- **add-mobile (D-012) es binary internamente** — PWA default / Native shell override.
- **No tiene PAUSE genuino interno** (a diferencia de add-payments D-010 / add-emails D-011 trinary).
- **Es superconjunto de init-saas** — los 3 primeros pasos son los mismos. Resume-aware del wizard hijo manage el skip.

**L-004 test aplicado al SELECTOR WIZARD de add-mobile-stack:**

| Caso | ¿Upstream user action requerida del selector wizard (FRESH vs EXISTING)? | Resultado |
|------|-------------------------------------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí — correr forge-init / migrar a Next.js | **PREFLIGHT halt, NO PAUSE genuino** |
| FRESH path con sub-skill PAUSE interno | NO — D-020 doctrine: PAUSE-interno-delegado NO escala | NO PAUSE wizard |
| EXISTING parcial (1 de 4 pasos completados) | NO — resume-aware procede desde paso 2 | NO PAUSE |
| add-mobile (D-012) PWA-only graceful fallback | NO — add-mobile internamente decide PWA vs Native | NO PAUSE wizard |

**Decision:** **BINARY** confirmed. FRESH default + EXISTING resume-aware (override por state detection), NO PAUSE genuino. Patrón heredado de D-019 (init-saas) + D-020 doctrine (PAUSE-interno-delegado NO escala).

**Alternatives considered:**
- **Trinary con PAUSE wizard escalado de add-mobile (D-012 binary):** rechazado, D-012 es binary internamente, no tiene PAUSE genuino.
- **BINARY con cita explícita de D-019 como patrón heredado:** aceptado.

**Consequences:**
- (+) **Confirmación cross-skill #10 binary** post-D-009..D-020. Total binary: 10.
- (+) **Demostración del patrón heredado.** Wizards futuros que extiendan init-saas pattern (agregando pasos) heredan D-019 sin re-discutir shape — D-021 es la prueba.
- (+) **Resume-aware feature confirma BINARY.** Re-invocación es idempotente.
- (-) **Sin trinary signal.** Si en evolución futura emerge un wizard mobile con PAUSE genuino (ej: native shell requiere account approval upstream), aplicar L-004 estrictamente y considerar trinary — pero ese sería caso distinto.

**Cross-skill applicability — patrón heredado:**

> **Wizards que extienden init-saas pattern (composición secuencial sin selector entre N approaches, con resume-aware) heredan D-019 binary shape automáticamente. D-021 es el primer ejemplo del patrón heredado.**

Aplicable a wizards futuros del mismo pattern.

**Cita:** `[memory:decisions#D-021]`

---

## D-022 — `enterprise-stack` wizard de wizards binary (full + custom override)

**Date:** 2026-05-09
**Status:** accepted
**ADR class:** meta-wizard composition pattern — wizard de wizards.

**Context:** durante F5-S2 emergió la necesidad de un wizard top-level que compusiera los 3 wizards core de Forja (init-saas + add-monetization + add-mobile-stack) en una sola invocación, para usuarios que quieren setup enterprise completo de una sola vez.

A diferencia de wizards binary que componen skills, `enterprise-stack` compone **wizards** que a su vez invocan skills — un nivel de abstracción superior.

Particularidades:
- **R6 enforced explícito en PREFLIGHT** — valida que init-saas, add-monetization, add-mobile-stack existan en `skills.md` antes de cualquier dispatch.
- **Hereda D-019, D-020, D-021** doctrine completa.
- **CUSTOM mode override válido** — usuario puede skipear wizards específicos (`sin mobile`, `solo init-saas + add-monetization`).
- **add-mobile-stack es superconjunto de init-saas** — caso especial donde el orden importa pero NO hay redundancia (resume-aware del wizard hijo lo maneja).

**L-004 test aplicado al SELECTOR WIZARD DE WIZARDS de enterprise-stack:**

| Caso | ¿Upstream user action requerida del selector wizard (FULL vs CUSTOM)? | Resultado |
|------|--------------------------------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí — correr forge-init | PREFLIGHT halt, NO PAUSE selector |
| Sub-wizard PAUSE-interno (ej: add-monetization → add-payments PAUSE on-prem D-010) | NO — D-020 doctrine: PAUSE-interno-delegado NO escala | NO PAUSE wizard |
| EXISTING parcial (1 de 3 wizards completados) | NO — resume-aware procede | NO PAUSE |
| CUSTOM override (usuario excluye add-mobile-stack) | NO — override es elección del usuario, no degenerate case | NO PAUSE |
| Wizards faltantes en skills.md (R6 fail) | Sí — re-instalar Forja | PREFLIGHT halt R6, NO PAUSE selector |

**Decision:** **BINARY** confirmed (FULL default + CUSTOM override). Wizard de wizards. Hereda D-019/D-020/D-021 + agrega R6 validation explícito.

**Alternatives considered:**
- **Sui-generis (no aplicar L-004 porque es meta-wizard):** rechazado, doctrine D-015 universal aplica.
- **Trinary con PAUSE wizard escalado de sub-wizards:** rechazado, D-020 doctrine: PAUSE-interno-delegado NO escala.
- **BINARY con CUSTOM mode override + R6 validation:** aceptado.

**Consequences:**
- (+) **Confirmación cross-skill #11 binary** post-D-009..D-021. Total binary: 11.
- (+) **Patrón meta-wizard establecido.** Cualquier wizard que componga otros wizards puede heredar D-022 + sub-wizard ADRs.
- (+) **R6 validation pre-dispatch** codificado en PREFLIGHT — refuerzo importante para meta-wizards.
- (+) **CUSTOM override demostrado** — wizards permiten skipear sub-componentes según elección del usuario sin trinarizar.
- (-) **Cognitive load** del wizard de wizards (3 niveles: meta-wizard → wizard hijo → skill). Mitigado con detect-state.md presentando state de los 3 wizards en una tabla unificada.

**Cross-skill applicability — meta-wizard pattern:**

> **Wizards que componen otros wizards (no skills directamente) son válidos y aplican L-004 al meta-wizard level. R6 enforcement es crítico (validar wizards hijos en skills.md). PAUSE-interno-delegado de sub-wizards NO escala (D-020 heredada). CUSTOM override permitido sin trinarizar.**

Aplicable a meta-wizards futuros.

**Cita:** `[memory:decisions#D-022]`

---

## D-023 — `migration-wizard` pipeline shape (sin selector — boundary case)

**Date:** 2026-05-09
**Status:** accepted
**ADR class:** boundary case (análogo a D-014) — pipeline shape sin selector entre N approaches.

**Context:** durante F5-S2 emergió la necesidad de un wizard que detecte un proyecto existente, analice su estado vs Bootstrap Contract de Forja, y produzca un MIGRATION-PLAN paso a paso. Casos: Forge V3.x → Forja Enterprise, Forge V2 → Forja, Next.js custom → Forja, otro framework → Forja, greenfield con código → Forja.

A diferencia de wizards que ejecutan migración (init-saas, add-monetization, add-mobile-stack, enterprise-stack), `migration-wizard` **NO ejecuta** — solo detecta, analiza y produce un plan. La ejecución del plan es responsabilidad del usuario.

**L-004 test aplicado a migration-wizard:**

| Pregunta | Respuesta |
|----------|-----------|
| ¿Hay selector entre N approaches dentro del wizard? | NO. El "approach" se determina por el estado detectado (Tipo A/B/C/D/E). El usuario NO elige — el wizard auto-detecta. |
| ¿Hay degenerate case que requiera upstream user action? | NO. El usuario puede provisionar path o cancelar; pero ningún caso requiere acción específica del selector (porque NO hay selector). |

**Conclusión:** **L-004 NO aplica directo.** migration-wizard es **pipeline shape sin selector** entre N providers/approaches — análogo a `el-crisol` (D-014 boundary case).

**Decision:** **PIPELINE SHAPE — boundary case análogo a D-014.** D-023 documenta esto explícitamente como pipeline DETECT → ANALYZE → PLAN.

**Pipeline shape:**
```
Fase 0 (DETECT) ──→ Fase 1 (ANALYZE) ──→ Fase 2 (PLAN)
```

5 tipos de origen auto-detectados (no elegibles por el usuario):
- Tipo A — Forge V3.x.
- Tipo B — Forge V2.
- Tipo C — Next.js custom (sin Forge/Forja previo).
- Tipo D — Otro framework.
- Tipo E — Greenfield con código.

El "approach" del plan generado se determina automáticamente por el tipo de origen. NO hay selector que el usuario elija → L-004 NO aplica.

**Alternatives considered:**
- **Force-fit como BINARY (auto-detect / manual-override):** rechazado, sería sui-generis y violaría L-004 doctrine. No hay degenerate case del selector.
- **Force-fit como TRINARY (Forge V3 / Forge V2 / greenfield):** rechazado, los "modos" no son elección del usuario sino auto-detección.
- **Boundary case análogo a D-014:** aceptado. Pipeline shape sin selector → L-004 NO aplica directo.

**Consequences:**
- (+) **Segundo boundary case post-D-014** (el-crisol). Refuerza doctrine D-015: presencia del selector dentro del skill determina aplicabilidad de L-004.
- (+) **NO ejecuta clarification.** migration-wizard es pure planner — separación de concerns clara entre planning (este wizard) y execution (el usuario corre los comandos).
- (+) **Cross-skill applicability:** wizards futuros que sean pure planners (sin selector entre approaches) heredan D-023 boundary case shape.
- (-) **Cognitive load:** distinguir wizards de "ejecución" (binary L-004) de wizards de "planificación" (D-023 boundary case). Mitigado con SKILL.md sección "Shape (D-023)" explícita.

**Cross-skill applicability — boundary case pure planner:**

> **Wizards que detectan + analizan + planifican (sin ejecutar y sin selector entre N approaches) son boundary case shape D-023, análogo a D-014. L-004 NO aplica directo. Aplican pipeline shape.**

Aplicable a planners futuros (ej: feature-priority-wizard, audit-planner, refactor-wizard).

**Scoreboard cross-skill FINAL post-F5-S2:**

| ADR | Skill / wizard | Tiene selector? | L-004 aplica? | Resultado | Notas |
|-----|----------------|-----------------|---------------|-----------|-------|
| D-009 | add-login | Sí | SÍ | binary | — |
| D-010 | add-payments | Sí | SÍ | trinary (PAUSE empresa MoR) | — |
| D-011 | add-emails | Sí | SÍ | trinary (PAUSE on-prem SMTP) | — |
| D-012 | add-mobile | Sí | SÍ | binary | — |
| D-013 | la-forja | Sí | SÍ | binary | — |
| D-014 | el-crisol | NO | NO | boundary case (pipeline) | sin selector |
| D-015 | web-quality | Sí | SÍ | binary | refina D-014 doctrine |
| D-016 | el-tajo | Sí | SÍ | binary | — |
| D-017 | el-golpe | Sí | SÍ | binary | — |
| D-018 | skill-creator | Sí | SÍ | binary | — |
| D-019 | init-saas wizard | Sí | SÍ | binary | resume-aware, paralelo a el-crisol shape |
| D-020 | add-monetization wizard | Sí | SÍ | binary | + distinción PAUSE-interno-delegado |
| D-021 | **add-mobile-stack wizard** | **Sí** | **SÍ** | **binary** | hereda D-019 patrón |
| D-022 | **enterprise-stack wizard** | **Sí** | **SÍ** | **binary (FULL/CUSTOM)** | wizard de wizards, hereda D-019/D-020/D-021 |
| D-023 | **migration-wizard** | **NO** | **NO** | **boundary case (pipeline)** | pipeline DETECT→ANALYZE→PLAN, análogo a D-014 |

Total: **15 ADRs cross-skill** post-F5-S2. **11 binary + 2 trinary + 2 boundary case.**

**Doctrine final post-D-023 (5 reglas operacionales):**

1. **D-015 (regla universal):** Presencia del selector dentro del skill determina aplicabilidad de L-004 — NO categoría del skill.
2. **D-016 + D-017 (sub-pattern lightweight ladder):** Ladder de escalation lightweight → orchestrator es BINARY by structure.
3. **D-018 (meta skills):** Meta skills siguen L-004 normal si tienen selector.
4. **D-020 (wizards con PAUSE-aware sub-skills):** PAUSE-interno-delegado de sub-skills/wizards NO se escala como PAUSE-wizard. Wizards aplican L-004 al wizard level independientemente del PAUSE interno de sub-componentes.
5. **D-023 (pure planner wizards):** Wizards sin selector entre N approaches (auto-detect del approach por estado del proyecto) son boundary case shape, análogo a D-014. L-004 NO aplica directo.

**Cita:** `[memory:decisions#D-023]`

---

## D-024 — autoresearch: descartado de Forja (intencionalmente no portado)

**Date:** 2026-05-11
**Status:** superseded by D-030 (re-admitido como opt-in hidden con safety caps duros)

**Context:** En Forge v3.3 existía un skill `autoresearch` para auto-mejora autónoma de otros skills (evals binarias, loop de mutación de prompts, benchmark de calidad). Detectado como GAP REAL en auditoría independiente (DeepSeek V4 Pro, 2026-05-11) — ausente en Forja sin decisión documentada.

**Decision:** autoresearch NO se porta a Forja en esta fase.

**Alternatives considered:** portar autoresearch como skill core; portar como skill `_opcionales/`.

**Consequences:**
- (+) No viola AP3 (self-eval del agente generador prohibido) ni R4 (orchestrator stays thin). El loop autónomo de autoresearch sin humano en el loop es incompatible con ambas reglas.
- (+) El patrón de auto-mejora está cubierto por `el-evaluador` (valida y documenta calidad de output) + `skill-creator` (guía creación y refinamiento de skills nuevos).
- (-) Si el dogfood genera fricción de calidad en skills específicos que requiera iteración autónoma sistemática, habrá que re-evaluar.

**Mitigation:** Si dogfood con Hila genera fricción de calidad en skills específicos, evaluar portar autoresearch como skill `_opcionales/` con AP3 explícito documentado.

**Cita:** `[memory:decisions#D-024]`

---

## D-025 — Showcase Forge-Pro port: deuda explícita post-dogfood

**Date:** 2026-05-12
**Status:** resolved — ported 2026-05-28 (8/8 gaps, vía Dynamic Workflow). Ver Resolution al final.

**Context:** El showcase actual de `add-ui-kit` en Forja (output: `src/app/(brand)/showcase/page.tsx + sections/*`) es una versión mínima portada de Forge v3.3. La versión robusta de Forge-Pro (commits `9e9a77f` + `2a7951a`) tiene 8 gaps documentados en la auditoría posterior al cierre de E-009. Sin cierre formal de esta deuda, el showcase queda "good enough" pero no es paridad con Forge-Pro.

**Decision:** Aceptar la deuda como ADR explícito. Diferir el port a post-dogfood con Hila (proyecto target real). Si Hila no requiere los SaaS patterns inmediatamente, defer a feature request explícito antes de programar el sprint del port.

**Gaps documentados (8):**

1. **Part 1 sections:** actualmente 5 (palette, typography, voice, components, motion) → Forge-Pro tiene **13 categorías completas** (incluye micro-interactions, depth/elevation, anatomy, etc.).
2. **Part 2 SaaS patterns:** **ausente** → Forge-Pro tiene **7 patrones** (KPI cards, DataTable, Onboarding, Sidebar, Empty States, Auth Form, Navbar).
3. **Viewport toggle:** ausente → Forge-Pro tiene Desktop / 768px / 375px con persistencia en localStorage.
4. **Feedback loop:** ausente → Forge-Pro tiene Pencil icon → `UI_FEEDBACK.md` vía Server Action para que el humano marque cosas a refinar in-situ.
5. **COMPONENT_RULES.md:** ausente → Forge-Pro lo emite con 10 reglas de enforcement para los agentes downstream (impeccable consumer).
6. **Anti-Slop Gate:** actualmente 6 checks → Forge-Pro tiene **8 checks** (incluye modales, dark mode, empty states).
7. **Motion system:** inline en componentes → Forge-Pro tiene `motion.ts` separado con duraciones tipadas + curves canónicas.
8. **Design Discovery:** 6 preguntas → Forge-Pro tiene sesión con referencias reales + 5 visual directions pre-curadas que el usuario elige antes de las 6 preguntas.

**Estimación:** ~500 LOC en templates de `add-ui-kit/templates/showcase/` + reescritura de `prompts/discovery-fresh.md` para incorporar las 5 visual directions + nuevo asset `prompts/feedback-loop.md` + script para emitir `COMPONENT_RULES.md`.

**Alternatives considered:**

- **Port inmediato:** rechazado. Sin dogfood real, no sabemos cuáles de los 8 gaps duelen primero. Riesgo de over-engineering.
- **Descartar el port:** rechazado. Forge-Pro showcase resolvía fricciones reales que el mínimo actual va a re-introducir cuando los proyectos target crezcan.
- **Port parcial (solo Part 2 SaaS patterns + viewport toggle):** rechazado por ahora. Si dogfood Hila lo demanda, se reabre como D-NNN nuevo.

**Trigger de revisión:** post-dogfood Hila. Si Hila no requiere los SaaS patterns inmediatamente, defer. Si los requiere → priorizar Part 2 + viewport toggle + feedback loop (los 3 que más fricción introducen sin port).

**Consequences:**
- (+) El equipo arranca dogfood con Hila sin gastar ~1-2 días portando showcase robusto que puede no ser necesario.
- (+) La deuda queda visible en `decisions.md`, citable desde issues futuros.
- (-) Si un usuario externo adopta Forja y compara contra Forge-Pro, el showcase parece menos pulido.
- (-) Cuando el port se haga, los proyectos target ya generados con showcase mínimo no se benefician retroactivamente (no hay migration path automático).

**Mitigation:** Documentar en `add-ui-kit` SKILL.md (próxima iteración) un caveat tipo "showcase mínimo — version robusta pendiente, ver D-025" para que el usuario sepa que no es la implementación final.

**Resolution (2026-05-28):** Trigger disparado por el primer dogfood real — `movinsa-dashboard` corrió `/add-ui-kit` y faltaron exactamente los gaps #2 (SaaS patterns), #3 (viewport) y #4 (feedback loop), los 3 que esta ADR nombró como los de mayor fricción. Port completo de los **8 gaps** vía Dynamic Workflow (26 agentes): 23 archivos nuevos (motion.ts, viewport-toggle, feedback actions+panel, COMPONENT_RULES, directions.md, 11 secciones Part 1, 7 SaaS patterns) + integración (page.tsx, generate-showcase.md, discovery-fresh.md, SKILL.md). Revisión adversarial encontró 1 HIGH (onboarding.tsx server-component onSubmit) + 1 MEDIUM (components.tsx huérfano → borrado) + 2 LOW (viewport/motion UNSAFE props), todos corregidos. Verificación: anti-slop 8/8, dry-run 22/0. Caveat de migración sigue vigente: targets ya generados con showcase mínimo necesitan re-correr `/add-ui-kit` REDESIGN para beneficiarse.

**Cita:** `[memory:decisions#D-025]`, `[memory:errors#E-009]`

---

## D-026 — add-e2e-tests BINARY (minimal / full)

**Date:** 2026-05-12
**Status:** accepted

**Context:** Dogfood en Hirezia (proyecto target) reveló un gap operacional: tenía specs Playwright pre-existentes sin `@playwright/test` instalado, y el patch parcial de E-009 (commit `66ea47f`) lo detectó vía Gate 8 (typecheck baseline). El skill `web-quality` no es el sustituto correcto — su default es agent-browser (live audit, D4) y su shape no cubre instalación de framework de tests. Se necesitaba un skill opt-in dedicado que coexista con D4 sin contradecirlo.

**Decision:** `add-e2e-tests` es **BINARY** shape.

- **minimal** (default): Chromium-only, sin GitHub Actions.
  Browsers: ~80 MB. Install: ~30s. Ideal para desarrollo local + smoke tests pre-deploy manual.
- **full** (override): Chromium + Firefox + WebKit + workflow GitHub Actions con matrix por browser.
  Browsers: ~280 MB. Install: ~90s. Ideal para apps con compromiso cross-browser real (B2C público, marketplace).

**L-004 test:** ¿hay degenerate case que requiera upstream user action específica del selector?

| Caso | Acción upstream requerida del selector | Resultado |
|------|----------------------------------------|-----------|
| PREFLIGHT halt (no Next.js, no npm, typecheck roto) | Sí (instalar Node / fixear typecheck) | **PREFLIGHT halt, NO PAUSE del selector** |
| Usuario quiere full pero no tiene `.github/workflows/` writable | No — caer a `minimal` graceful o pedir setup repo manual | **NO PAUSE — minimal sirve siempre como fallback** |
| Resume-aware: `tests/e2e/` ya existe | No — halt + reporte + sugerir APPEND | **NO PAUSE del selector** |

→ **BINARY confirmed.** minimal siempre disponible como fallback graceful (Chromium es subset de full; sin browsers extra no se rompe nada). No hay degenerate case que requiera acción upstream específica del selector.

**Coexistencia con D4 (agent-browser default, Playwright MCP opcional):**

`add-e2e-tests` NO contradice D4 — agente-browser sigue siendo el default Forja para QA agentic durante development. add-e2e-tests resuelve un caso de uso **ortogonal**: specs CI/CD que corren **sin agente** en el loop.

| Herramienta              | Caso de uso canónico                         |
|--------------------------|----------------------------------------------|
| `agent-browser` CLI      | QA agentic en development (default, D4)      |
| Playwright **MCP**       | Cross-browser checks vía agente (D4 opcional)|
| `@playwright/test` (este)| Specs CI/CD sin agente (`add-e2e-tests`)     |

Las tres coexisten porque cubren regiones operacionales distintas (ver `.claude/skills/add-e2e-tests/references/playwright-vs-agent-browser.md` para matriz de decisión completa).

**Alternatives considered:**

- **Reescribir web-quality para que también haga setup CI/CD:** rechazado. web-quality es un audit skill (Lighthouse-based, D-015 binary live/static). Mezclar setup de framework con audit rompe la responsabilidad clara del skill.
- **Hacer add-e2e-tests trinary con un "MCP-only" mode:** rechazado. Playwright MCP es responsabilidad de la config del agente (`.mcp.json`), no de un skill que escribe archivos al proyecto target.
- **Skill core en lugar de optional:** rechazado. La mayoría de los proyectos Forja arrancan con agent-browser y nunca necesitan @playwright/test. Forzar la dep aumenta install time y disk footprint sin beneficio. Opt-in es lo correcto.

**Trigger contextual (E-009 dogfood):**

Hirezia (proyecto target) tenía:
- `tests/e2e/login.spec.ts` heredado de un setup previo.
- Sin `@playwright/test` instalado.
- Sin `playwright.config.ts`.

Gate 8 de add-ui-kit (E-009 causa 3) detectó el problema porque el typecheck rompía sobre los imports de Playwright faltantes. El usuario no debería tener que setup Playwright a mano cada vez que pasa esto — y agent-browser no resuelve el caso (porque el problema NO es QA agentic, es CI gate sin agente).

**Hereda Gate 8 de E-009 causa 3:** PREFLIGHT incluye `npm run typecheck` exit 0 antes de instalar nada. Si el baseline está roto, los specs heredan el roto y no podés distinguir regresiones de errores pre-existentes. Mismo patrón que add-ui-kit aplicó post-E-009.

**Consequences:**
- (+) Resuelve el gap operacional detectado en E-009 dogfood Hirezia.
- (+) Coexistencia limpia con D4 — no fuerza al usuario a elegir entre agent-browser y Playwright tests.
- (+) Mode minimal es conservador (Chromium-only, sin CI) — minimiza fricción del primer uso.
- (-) Adds a 4th surface that needs to stay consistent con D4 + D-015 (web-quality) + ARCHITECTURE.md#D4. Coexistencia explícita documentada en `references/playwright-vs-agent-browser.md`.
- (-) Mode full descarga ~280 MB de browsers — usuarios sin disco / bandwidth deben elegir minimal.

**Mitigation:** Documentar coexistencia con D4 en references/playwright-vs-agent-browser.md. Mode full es opt-in explícito, nunca implícito.

**Cita:** `[memory:decisions#D-026]`, `[memory:decisions#D-004]` ↔ `[ARCHITECTURE.md#D4]` (agent-browser default heredado), `[memory:references#R-003]` (agent-browser tool), `[memory:errors#E-009]` (Gate 8 herencia, causa 3), `[memory:lessons#L-004]` (binary test diagnostic aplicado).

---

## D-027 — `update-forja`: pipeline shape sin selector (boundary case)

**Date:** 2026-05-12
**Status:** accepted
**ADR class:** boundary case (análogo a D-014 + D-023) — pipeline shape sin selector entre N approaches.

**Context:** durante v0.1.9 emergió la necesidad de un skill para actualizar proyectos Forja existentes con la última versión del template, preservando archivos del proyecto. El predecesor `/update-forge` (Forge legacy) ya había resuelto los problemas clave — auto-detección de REPO_PATH desde alias del shell, soporte flat/dual-tree, marker `FORGE:PRESERVE:START` para CLAUDE.md merge inteligente, auto-delegación post-pull para resolver el bootstrap problem. `update-forja` hereda los 3 patrones (renombrando marker a `FORJA:PRESERVE:START`) y los extiende con NEVER TOUCH list explícita para archivos de proyecto Forja-specific (`memory/`, `feature_list.json`, `brand/*.json`, `src/features|shared`).

A diferencia de skills BINARY/TRINARY (D-009..D-026 con selector entre N approaches), `update-forja` NO presenta selector al usuario — auto-detecta todo (estructura del repo, presencia del marker, drift de configs).

**L-004 test aplicado a `update-forja`:**

| Pregunta | Respuesta |
|----------|-----------|
| ¿Hay selector entre N approaches dentro del skill? | NO. El "approach" se determina por el estado detectado (flat/dual-tree, marker/no-marker, drift/no-drift). El usuario NO elige — el skill auto-detecta. |
| ¿Hay degenerate case que requiera upstream user action específica del selector? | NO. Sin alias → prompt one-time por REPO_PATH (no selector de approach). Sin marker → skip + warning (no selector). PREFLIGHT halts son halts del pipeline, no PAUSE del selector. |

**Conclusión:** **L-004 NO aplica directo.** `update-forja` es **pipeline shape sin selector** entre N providers/approaches — análogo a D-014 (`el-crisol`) y D-023 (`migration-wizard`).

**Decision:** **PIPELINE SHAPE — boundary case análogo a D-014 + D-023.** D-027 documenta esto explícitamente como pipeline DETECT → PULL → BACKUP → MERGE → REPORT (5 fases secuenciales fijas + auto-delegación post-pull intercalada como FASE 3b).

**Pipeline shape:**
```
PREFLIGHT (3 gates)
   ↓
FASE 1 (DETECT REPO_PATH desde alias)
   ↓
FASE 2 (DETECT estructura flat vs dual-tree)
   ↓
FASE 3 (PULL desde source)
   ↓
FASE 3b (AUTO-DELEGATE — resuelve bootstrap problem)
   ↓
FASE 4 (BACKUP archivos críticos)
   ↓
FASE 5 (MERGE wholesale framework + DETECT-AND-REPORT config drift)
   ↓
FASE 6 (MERGE inteligente CLAUDE.md con marker)
   ↓
FASE 7 (REPORT)
```

Ninguna de estas fases presenta un selector. Todas las "decisiones" se auto-determinan por estado detectado:
- Estructura: `$REPO_PATH/.claude/` vs `$REPO_PATH/forja/.claude/` → auto.
- Marker: `grep -q "FORJA:PRESERVE:START" CLAUDE.md` → auto.
- Drift: `diff` por archivo → auto (informa, no decide).
- Alias: `grep "^alias forja=" ~/.zshrc` → auto; fallback prompt one-time (no selector).

**Patrones heredados de `/update-forge` (Forge legacy):**

1. **Auto-detección de REPO_PATH desde alias del shell** — no hardcoding de paths absolutos.
2. **Soporte flat (forge-pro v3.x) vs dual-tree (meta-repo v2.x legacy)** — adaptado a Forja: flat (proyecto target) vs dual-tree (meta-repo Forja).
3. **Auto-delegación post-`git pull` (resuelve bootstrap problem)** — la versión más nueva del skill se carga del source después del pull, garantizando que cada `/update-forja` corre con la lógica más actual.
4. **Marker `FORJA:PRESERVE:START` para CLAUDE.md merge** — renombrado del predecesor `FORGE:PRESERVE:START`. Zona framework actualizable + zona proyecto preservada.

**Extensiones Forja-specific (no en `/update-forge`):**

1. **NEVER TOUCH list explícita** — `memory/*.md`, `feature_list.json`, `PROGRESS.md`, `brand/*.json`, `src/features|shared`, `.mcp.json`, `src/app/page.tsx|layout.tsx|globals.css`. La Forja Enterprise tiene más archivos de proyecto que Forge — esta lista los enumera y los protege.
2. **DETECT-AND-REPORT para config drift** — `package.json`, `next.config.ts`, `tailwind.config.ts`, `tsconfig.json`, `components.json`, `postcss.config.js` se comparan y reportan diff, NO se sobreescriben (lección E-009 extendida a configs).
3. **Backup automático en `.forja-backup-{timestamp}/`** — FASE 4 mandatory. Sin backup, halt antes de FASE 5.

**Lección aplicada de E-009:** "no destruir contenido del usuario" se extiende a:
- `CLAUDE.md` (vía marker `FORJA:PRESERVE:START`).
- Configs del proyecto (detect-and-report, no sobreescritura silenciosa).
- Archivos de proyecto (NEVER TOUCH list explícita).

**Alternatives considered:**

- **Force-fit como BINARY (auto-detect / manual-override):** rechazado, sería sui-generis y violaría L-004 doctrine. No hay degenerate case del selector.
- **Force-fit como TRINARY (flat / dual-tree / mixed):** rechazado, los "modos" no son elección del usuario sino auto-detección por estado del repo.
- **Sobreescribir configs como wholesale framework:** rechazado. Configs del proyecto se customizan en proyectos productivos — sobreescribirlas rompe el proyecto silenciosamente. Detect-and-report respeta el principio de E-009.
- **Sobreescribir CLAUDE.md sin marker:** rechazado. CLAUDE.md sin marker representa contenido pre-v0.1.9 — defaulteamos a no tocar (warning + skip).
- **Hacer `update-forja` boundary del wizard-de-wizards (D-022 enterprise-stack):** rechazado. update-forja NO compone otros wizards — es un pipeline de mantenimiento, no de bootstrapping.
- **Boundary case análogo a D-014/D-023:** aceptado. Pipeline shape sin selector → L-004 NO aplica directo.

**Consequences:**

- (+) **Tercer boundary case post-D-014 / D-023.** Refuerza doctrine D-015: presencia del selector dentro del skill determina aplicabilidad de L-004, NO categoría del skill.
- (+) **Auto-delegación post-pull resuelve bootstrap problem genérico.** Patrón citable desde otros skills futuros que necesiten "actualizarse a sí mismos" (ej: un `update-skills` hipotético).
- (+) **NEVER TOUCH list explícita prevenible.** Cada item de la lista cita su constraint origen ([memory:CONSTRAINTS.md#R5] para `memory/`, [memory:CONSTRAINTS.md#R10] para `brand/`). Trazabilidad completa.
- (+) **Backup automático mandatory.** Sin backup el rollback depende solo de `git restore` — backup explícito permite rescate aunque el usuario haya comiteado tras el update.
- (-) **Cognitive load para usuarios.** El reporte final lista qué se actualizó, qué NO, drift detectado, y status de CLAUDE.md. Mitigado con formato visual estructurado en FASE 7.

**Cross-skill applicability:**

> **Skills de mantenimiento de framework (que actualizan archivos del harness en proyectos target sin tocar archivos de proyecto) son pipeline shape boundary case D-027, análogo a D-014 + D-023. L-004 NO aplica directo. Aplican pipeline shape con NEVER TOUCH list explícita + detect-and-report para configs ambiguas.**

Aplicable a skills futuros: `update-skills-only`, `update-memory-conventions`, `sync-references`, cualquier mantenedor de assets framework-side.

**Scoreboard cross-skill post-D-027:**

| ADR | Skill / wizard | Tiene selector? | L-004 aplica? | Resultado | Notas |
|-----|----------------|-----------------|---------------|-----------|-------|
| D-014 | el-crisol | NO | NO | boundary case (pipeline) | primer boundary case, sin selector |
| D-023 | migration-wizard | NO | NO | boundary case (pipeline DETECT→ANALYZE→PLAN) | segundo boundary case |
| D-027 | **update-forja** | **NO** | **NO** | **boundary case (pipeline DETECT→PULL→MERGE)** | **tercer boundary case; auto-delegación post-pull patrón nuevo** |

Total post-D-027: **17 ADRs cross-skill.** **11 binary** + **2 trinary** + **3 boundary case** + **1 deuda explícita** (D-025 showcase port) + **1 descarte intencional** (D-024 autoresearch).

**Cita:** `[memory:decisions#D-027]`, `[memory:decisions#D-014]` (pipeline shape pattern), `[memory:decisions#D-023]` (pipeline DETECT pattern), `[memory:errors#E-009]` (lección "no destruir contenido del usuario"), `[memory:CONSTRAINTS.md#R5]` (memory/ es sole-writer evaluador), `[memory:CONSTRAINTS.md#R10]` (brand/ es Brand DNA del proyecto).

---

## D-028 — Multi-tenancy de apps generadas = shared-DB + RLS por `organization_id` (membresía)

**Date:** 2026-06-30
**Status:** accepted

**Context:** M6 (Multi-tenant) es el único MUST que requería una decisión de producto antes de diseñar
(`docs/06` §9-B): ¿multi-tenant del *harness/plataforma* (varios clientes en un servidor, estilo Forge
Cloud) o de las *apps generadas*? Y dado el segundo, ¿con qué modelo de aislamiento? La base de Forja es
single-tenant (`auth.uid() = user_id`, `[memory:lessons#L-001]`); multi-tenant está ausente de Forja y
de Forge Pro (verificado por grep en `docs/01` §5.1).

**Decision:** **B1 — las apps generadas son multi-tenant; el harness sigue single-tenant/local** (un
`ONTOLOGY.md` por empresa cliente; la plataforma hospedada multi-cliente es Forge Cloud, W5, fuera de
Enterprise). Para el aislamiento de las apps generadas se adopta **A — shared-DB + shared-schema + RLS
por `organization_id` vía membresía** como Golden Path. Materialización: foundation `0000_tenancy.sql`
(`organizations` + `memberships` con `role` + helpers `auth_org_ids()`/`auth_has_org_role()`
`security definer`), `organization_id` + RLS por membresía + `WITH CHECK` en cada entidad de dominio
(`[memory:lessons#L-005]`), enforce por R16, auditado por `el-guardian` (persona **El Infiltrado**),
validado por `el-migrador`, y verificado por un test negativo cross-tenant ≥2 tenants (R7 Layer 4).
Alcance M6 = **diseño + enforcement del harness** (MUST); el build per-app (gestión de orgs/invitaciones
= S2; billing por org en `add-*`) es **fasable** (`docs/06` §12). Doctrina:
`.claude/references/MULTI_TENANCY.md`.

**Alternatives considered:**
- **Multi-tenant del harness/plataforma** (varios clientes Forge en un servidor): rechazado — es Forge
  Cloud (W5), no Enterprise. El arnés sigue Claude-first/local.
- **B — shared-DB + schema-per-tenant:** rechazado como default — N schemas multiplican las migraciones y
  no escalan a miles de tenants. Queda como override documentado (compliance fuerte).
- **C — database-per-tenant:** rechazado como default — sólo para residencia de datos por cliente /
  air-gap (un `requisito_seguridad: critico` lo activaría). Override en el Tech Spec, nunca por default.

**Consequences:**
- (+) Extiende L-001 en vez de reemplazarlo; el aislamiento lo enforce Postgres (RLS), no el código.
- (+) Una migración por cambio de schema; consistente con el Golden Path (Supabase + RLS).
- (+) Degradación segura: apps single-tenant siguen con L-001 sin tocar nada; M6 es opt-in por la
  naturaleza de la app (lo decide el Tech Spec / `tenant_model`).
- (−) `security definer` en los helpers requiere disciplina (search_path fijo, filtrar por `auth.uid()`)
  para no introducir un bypass — cubierto por el modelo de amenazas T4 y el test negativo.
- (−) El build per-app de la gestión de tenants queda diferido (S2); M6 entrega el diseño + enforcement,
  no la UI de orgs.

**Cita:** `[memory:decisions#D-028]`, `[memory:lessons#L-005]` (patrón RLS por tenant), `[memory:lessons#L-001]` (base single-tenant que generaliza), `[memory:CONSTRAINTS.md#R16]` (enforcement), `[memory:CONSTRAINTS.md#R7]` (Layer 4 cross-tenant).

---

## D-029 — Equipos = GitHub-native (espejo de una sola vía) + gestión de tenants per-app (`add-teams`)

**Date:** 2026-06-30
**Status:** accepted

**Context:** S2 (pilar ② equipos/gestión) es net-new. `ARCHITECTURE.md` D12 declaró "Enterprise GitHub
features (Issues sync, PR templates, CODEOWNERS, branch protection)" pero nunca se implementó (`docs/01`
§5.2). `docs/06` §9-C dejó abierta la pregunta de producto: ¿GitHub-native basta, o se requiere un plano
de gestión propio (dashboard de roles/permisos)? Y M6 marcó la **gestión de tenants** (UI de orgs,
invitaciones, roles) como "build per-app fasable" de S2 (`MULTI_TENANCY.md` §234).

**Decision:** **GitHub-native** (recomendación MVP de §9-C). S2 = **dos piezas** con tiers distintos:
1. **`el-capataz`** (core) — gobierna el **repo del equipo de desarrollo**: CODEOWNERS (desde el roster
   `.forja/team.json` + `modules[]` del plano), branch protection en `main` (required checks = los jobs de
   CI de A2), PR/Issue templates, y sync `feature_list`/`plan` → GitHub Issues.
2. **`add-teams`** (optional) — genera la **UI de gestión de tenants** en las apps target multi-tenant
   (orgs/invitaciones/roles) sobre la fundación M6 (`0000_tenancy.sql`). Cierra el build per-app fasable.

Invariante maestro **R18 — GitHub es un espejo de una sola vía:** la autoridad de las transiciones de
build sigue en `feature_list.json` + hooks (R1/AP8/R7, ADR D1); GitHub es proyección read-only (cerrar un
Issue/mergear un PR NUNCA marca `passing`; `el-capataz` jamás escribe el estado — R5). Los roles **reusan
`owner`/`admin`/`member` de M6** (un solo modelo gobierna a la vez el aislamiento de datos por RLS y la
autoridad de review). Branch protection **refuerza A2** (los checks de CI como required → bloquea el merge
remoto, en paralelo a AP8 que bloquea el commit local). Implementa `[ARCHITECTURE.md#D12]`.

**Alternatives considered:**
- **Plano de gestión propio (dashboard de roles/permisos)** — rechazado para el MVP (§9-C, queda COULD):
  GitHub-native da el 80% de "equipos" con esfuerzo medio sobre infraestructura que el cliente ya tiene.
- **Sync bidireccional (los Issues escriben el estado de build)** — rechazado: viola D1/R5/R18
  (reintroduce transiciones por UI). El sync es estrictamente una vía; el Issue se cierra como *efecto* de
  `passing`, nunca como causa.
- **Multi-usuario en tiempo real** (servidor compartido en vivo) — rechazado: es Forge Cloud (W5). La
  sincronización de equipo es **vía git/`gh`** (`docs/07` §7.5), no un backend compartido.
- **Inventar un segundo modelo de roles** para el equipo dev — rechazado: se reusa el de M6 (coherencia
  RLS↔review).

**Source:** `docs/06` §S2 + §9-C · `docs/07` §7.5 + Punto 3 §6 · `docs/01` §5.2 (D12) · `MULTI_TENANCY.md`
§234. Enforce: `[memory:CONSTRAINTS.md#R18]`. Lección asociada: `[memory:lessons#L-006]`.

---

## D-030 — Calidad (S4 + C1–C6) = absorber doctrina y consolidar, NO portar/instalar; autoresearch re-admitido

**Date:** 2026-06-30
**Status:** accepted (supersede la Decision de no-port de autoresearch en `[memory:decisions#D-024]`)

**Context:** paso 6 (último) de la secuencia de build (`docs/06` §10). La tentación era portar 1:1 los
activos de calidad de Forge Pro (12 comandos + 12 subagents + autoresearch) e instalar los externos
(Ponytail, Graphify, las 817 Anthropic-Cybersecurity-Skills). Eso choca de frente con la tesis del proyecto:
la **lección Vercel "-80% tools = +3× rendimiento"**. La propia investigación (docs/05, docs/06 §C) ya había
emitido veredictos anti-bloat por pieza.

**Decision:** Calidad se construye como **doctrina + consolidación**, no como ports/instalaciones:
- **S4** — estándar de autoría `SKILL_AUTHORING.md` (mattpocock + plantilla fija + progressive disclosure +
  failure modes); lo enforza `skill-creator` (scaffold) + `el-evaluador` (audit).
- **C1** — `el-pulidor` (1 skill, 4 modos read-only critique/polish/normalize/redesign; AP3: critica, no
  arregla) + `/fragua-review` (rúbrica de arquitectura en `el-crisol`). Solapes MAPEADOS a lo existente
  (web-audit→web-quality, inspeccionar→despachar/el-guardian, adversarial→4 modos de el-guardian), no duplicados.
- **C2** — `SUBAGENT_TOOL_FILTERS.md`: **mantener Coordinator/Fork/Swarm, NO adoptar los 12 subagents de Pro**
  (Q25; sus QA con Write violan AP3). Especialistas de Pro, si se usan, van como consultores read-only.
- **C3** — `CYBERSEC_VETTING.md`: protocolo de 5 pasos + subconjunto **curado de referencias** defensivas,
  NO import de las 817. Alimenta los gates DevSecOps por fase que ya existen (S1/A3).
- **C4** — `DRIFT_GATE.md`: gate de drift ontología↔código como **integration-point OPCIONAL** (Graphify MCP,
  madurez a evaluar), NO store ni dependencia dura; degradación segura.
- **C5** — `MINIMALISM.md`: absorber la metodología de Ponytail (**NO instalar el plugin**) — escalera YAGNI +
  Peldaño 0 ontológico + eje minimalismo (Minimalism Score con veto de seguridad) en `el-evaluador`.
- **C6** — `autoresearch` **re-admitido** (tier hidden, opt-in) como la mitigación que dejó abierta D-024:
  loop self-improving bajo caps duros (30 iter · $5 · 2× · rama dedicada · `reset --hard $BASE` · juez
  independiente el-evaluador, AP3). + `MODEL_PER_ROLE.md` doctrina OPCIONAL (default heredar sesión — Q28).

**Alternatives considered:**
- **Portar todo 1:1 de Pro / instalar los externos:** rechazado — viola la lección Vercel (bloat = -rendimiento),
  que es tesis fundacional. La calidad se gana por doctrina sistémica, no por acumular herramientas.
- **autoresearch como core/auto-invocable:** rechazado — D-024 lo vetó por riesgo; sólo es admisible hidden +
  opt-in + caps + AP3. Un loop de auto-mutación sin frenos es auto-sabotaje.
- **12 subagents tipados con Write:** rechazado — choca con AP3 (self-eval). Los patrones de Forja ya cubren
  el caso con tool-filter que hace AP3 estructural.

**Consequences:** cierra la Fase 4. +6 referencias-doctrina, +2 skills (el-pulidor core, autoresearch hidden),
+3 comandos, upgrades a el-evaluador/skill-creator. Sin nuevas reglas duras (R/AP) — los ejes los enforza
el-evaluador. **Source:** `docs/06` §S4/§C1–C6 + §9-G/§9-H · `docs/05` §1/§2/§5/§7 · `docs/01` §4.2–4.4.
Lección: `[memory:lessons#L-007]`.

---

## D-031 — S3 = construir el runner de migración de ontología en Node zero-dep; S5 = reconciliar, no construir

**Date:** 2026-07-01
**Status:** accepted (cierra los dos Should parciales; backlog post-build, fuera del ciclo de Fase 4)

**Context:** quedaban S3 (infra de versionado del `ONTOLOGY.md`) y S5 (patrones SpecFounder). Carlos aprobó
JIT (B-meta) el alcance de cada uno por separado. El lente de marca de S3 y los patrones spec/context/
checkpoint/brownfield de S5 **ya estaban** (M3/M4); lo residual era, en S3, la infra de migración de esquema
que `docs/04`/`06`/`07` marcaban reutilizable, y en S5, "tiering/explorer-fork".

**Decision:**
- **S3 — construir.** Port de `apply-brand-migrations.py` de Estudio a **Node zero-dep**
  (`scripts/apply-ontology-migrations.mjs`), NO Python — por consistencia con el tooling del harness
  (`inventory.js`, `plan-server.mjs`, `md-to-html.js` son todos Node zero-dep; evita asumir `python3`).
  Migraciones `.claude/ontology-migrations/NNNN_slug.md` (`ontology_md` con anchor + `create_path`),
  idempotencia por `check_line`, **ledger versionado** `.forja/ontology.migrations`, **backup** efímero
  gitignored, dry-run default + `--apply`, y **gobierno de `ontology_version`** (sella el frontmatter). El
  dir ships **sin migraciones vivas** (schema en 0.1) — MINIMALISM: infra lista + test, sin migrar contenido
  antes de que el schema evolucione. Wire-in: `make ontology-migrate`, `el-ontologo` (re-levantamiento),
  `update-forja` (FASE 5b). Test 17/17. Cierra el gancho que §9 del schema había dejado.
- **S5 — reconciliar, NO construir.** (a) *tiering* ya lo entregó C6 (`MODEL_PER_ROLE.md`, Q28); se agregó
  §1.1 (mapa de los sombreros de descubrimiento). (b) *explorer-fork* ya existe en `explorer.md`; se
  formalizó como **opción documentada gated por Q-FORK-VER** (inline seguro hasta validar el fork en la
  versión pineada). Construir un fork de primera clase con Q-FORK-VER abierto violaría la degradación segura.

**Alternatives considered:**
- **S3 en Python (1:1 con la fuente):** rechazado — introduce una segunda toolchain; Node es consistente.
- **S3 diferir el runner (YAGNI, no hay ONTOLOGY.md aún):** considerado y rechazado por Carlos — el runner
  es infra reutilizable pequeña con gancho listo; se prefiere cerrar S3 con herramienta funcional + test.
- **S5 promover el explorer a fork real ahora:** rechazado — Q-FORK-VER sin resolver; inline es lo correcto.

**Consequences:** secuencia MoSCoW al 100% (S1–S6 ✅). +1 script + 1 dir de migraciones + 1 target Makefile
+ 1 test (forge 23→40). Sin skills/comandos nuevos (inventory 37/37). Sin reglas duras nuevas.
**Source:** `docs/04` (pipeline de marca) · `docs/02` §3.10 (RENDIMIENTO SpecFounder) · `docs/06` §S3/§S5.
Lección: `[memory:lessons#L-008]`.

---

## D-032 — Resolución de las 4 preguntas abiertas del Cimiento (Q-FORK-VER/Q-RENAME/Q-MEM-DIR/Q-FORK-AGENT)

**Date:** 2026-07-01
**Status:** accepted (sesión conjunta con Carlos; backlog post-build)

**Context:** quedaban abiertas las 4 preguntas del Cimiento (IMPLEMENTATION-NOTES §6). Se investigaron con
un Workflow (4 investigadores en paralelo + 1 verificador adversarial en Opus sobre el blast-radius de
Q-RENAME) → tablero de decisión → Carlos decidió las 4.

**Decision:**
- **Q-FORK-VER → VALIDADA (fork funciona).** Test empírico en Claude Code **2.1.197**: invocar `el-migrador`
  (declara `context: fork`) por el Skill tool devolvió **"completed (forked execution)"** + el transcript
  registró el dispatch (`subagent_type` subió). Los issues #17283/#49559 eran de versiones viejas, ya
  superados. Consecuencia: los 3 skills forkeados aíslan contexto como se diseñó; el explorer-fork de S5
  pasa de gated a **opción viva**. La investigación web se apoyaba en issues viejos y sospechaba lo
  contrario — el test empírico mandó (ver `[memory:lessons#L-009]`).
- **Q-RENAME → NO renombrar** (default confirmado v0.1.9–v0.2.x). El verificador adversarial confirmó el
  veredicto y corrigió el blast-radius: el peligro real son **~9 refs ejecutables** (no las ~600 de prosa).
  La #1: `apply-ontology-migrations.mjs` hardcodea `.forja/ontology.migrations` + `.forja/ontology-backups/`
  → un rename re-correría migraciones sobre proyectos ya desplegados (corrupción). Otras: parser de alias +
  detector dual-tree de `update-forja` acoplados al literal `forja/`; asserts de string en tests que gatean
  CI. Ortogonales (NO tocar): matcher de rama `^(feature|fix|…)` y `.plan/`. Si algún día se rebrandea, es
  un **migration-wizard** (detecta `.forja/` legacy, mueve estado, puente de ledger, rename atómico
  script+tests+marker), NO un search-replace.
- **Q-MEM-DIR → intencional-inline.** `memory-manager` está en `skills.md` sin dir y nadie lo invoca; la
  gestión de memoria es inline en `el-evaluador` (R5), enforzada por el hook `commit-msg`. Se **reformuló la
  entrada de `skills.md`** a "concepto, no skill invocable" (honesta, no borrada → nadie recrea el faltante).
- **Q-FORK-AGENT → desbloqueada, no implementada.** Q-FORK-VER validó ⇒ **Opción B** viable (skills con
  `context: fork` + `agent: custom` tool-filtered en `.claude/agents/`, cristaliza AP3 por construcción).
  Es *enhancement* opcional, no fix (el subagente default + tool-filter de C2 ya es correcto). Se hace JIT
  cuando Carlos lo decida.

**Alternatives considered:**
- **Q-FORK-VER: asumir roto y migrar a `.claude/agents/`+Task:** rechazado — el test empírico probó que fork
  funciona; migrar sería trabajo sin causa.
- **Q-RENAME opción (b) "solo renombrar update-forja":** rechazada — es el skill MÁS acoplado al literal
  `forja/` (su propio parser de alias), self-defeating.
- **Q-MEM-DIR borrar la entrada:** rechazado — reformular preserva el marcador del invariante sole-writer.

**Consequences:** las 4 del Cimiento cerradas; solo quedan las 53 de investigación (JIT). Sin código nuevo
(salvo la reformulación de skills.md + notas de doctrina); el fork validado habilita futuros Fork/Swarm y la
promoción del explorer-fork. **Source:** Workflow de investigación 2026-07-01 · IMPLEMENTATION-NOTES §6.
Lección: `[memory:lessons#L-009]`.

---

## D-033 — Q-FORK-AGENT implementada: tool-filter estructural en los skills forkeados (Opción B)

**Date:** 2026-07-02
**Status:** accepted

**Context:** D-032 dejó Q-FORK-AGENT desbloqueada (Q-FORK-VER validó que `context: fork` SÍ forkea en
CC 2.1.197) con recomendación Opción B. El tool-filter de C2 (`SUBAGENT_TOOL_FILTERS.md`) era doctrina de
prosa: AP3 ("el que audita no edita") se prometía en el prompt de cada skill, no lo imponía el mecanismo.

**Decision:** implementar Opción B con el mecanismo honrado por el runtime, validado empíricamente por
harness/transcript — no self-report (`[memory:lessons#L-009]`):
- **Mecanismo:** `agent: <nombre>` en el frontmatter del SKILL.md (junto a `context: fork`) despacha el
  fork al subagente `.claude/agents/<nombre>.md`, cuyo `tools:` es **whitelist dura** enforced en la capa
  de ejecución (tool fuera de la lista → `tool_use_error` "No such tool available … not enabled in this
  context"). **`allowed-tools` del skill NO sirve como filtro** — los docs son explícitos: solo pre-aprueba
  permisos, *"It does not restrict which tools are available"*
  [web:code.claude.com](https://code.claude.com/docs/en/skills.md).
- **Sets:** `el-guardian` y `el-migrador` = Read·Grep·Glob·Bash·Write·Skill (**sin Edit** — el auditor no
  puede editar lo que audita; el migrador crea migraciones y nunca edita las aplicadas: AP3/append-only
  por construcción). `el-evaluador` = Read·Grep·Glob·Bash·Edit·Write (único writer legítimo de estado, R5
  — quitarle Edit/Write rompería memoria + `passing`; su path-scope lo siguen enforzando el hook
  `commit-msg` + prompt). `Skill` se incluye en guardian/migrador porque el perfil Reviewer de C2 incluye
  "skill `el-evaluador`", el guardian invoca `/codex:adversarial-review` y el migrador depende de
  `find-docs` (R13).
- **Evidencia (harness):** experimento controlado deny-vs-control en proyecto scratch + sonda a los 3
  skills reales. `meta.json` del dispatch = agentType custom en los 3; llamada a `Edit` en
  guardian/migrador → `tool_use_error` en el transcript con el archivo target intacto; en el-evaluador la
  misma llamada **atraviesa** el gate de tools y llega a la capa de permisos por path → Edit/Write siguen
  habilitadas. Sin bypass: dentro del fork filtrado, ToolSearch no carga schemas de tools fuera de la
  whitelist.

**Alternatives considered:**
- **`allowed-tools` en el SKILL.md (Opción A):** rechazada — no restringe (solo permission pre-approval);
  habría sido implementación falsa.
- **Quitar Edit/Write también a el-evaluador (Reviewer puro):** rechazada — rompería R5 y el marcado de
  `passing`; su invariante la cubren hook + prompt, y el filtro solo le niega lo que no usa.
- **Agregar ToolSearch a las whitelists (por Grep/Glob deferred):** rechazada — probado que dentro del
  fork filtrado no carga ni siquiera tools whitelisted-deferred; superficie extra sin beneficio.

**Consequences:**
- (+) AP3 pasa de promesa a **propiedad del mecanismo** en guardian/migrador; superficie de tools mínima
  en los 3 forks; `fork-agents.test.sh` (15 casos) gatea el contrato en `make test-hooks`/meta-CI (suite
  forge 40→55).
- (-) El filtro es grueso (tool sí/no): el path-scope (reporte / migrations / memoria) sigue en
  prompt+hook. En entornos con deferred-tools, Grep/Glob pueden no servirse dentro del fork (fallback:
  `grep`/`rg` vía Bash).
- (-) `project-auditor` (4º skill forkeado) queda fuera de alcance: su `allowed-tools` es pre-aprobación,
  no filtro — candidato a la misma conversión cuando se decida.

**Mitigation:** doctrina actualizada (`SUBAGENT_TOOL_FILTERS.md` v0.2.0 §2 documenta el matiz grueso y la
trampa de `allowed-tools`); las secciones "## Tool filter" de los 3 SKILL.md reflejan el enforcement real.
**Source:** validación empírica 2026-07-02 (transcripts + meta.json, CC 2.1.197) ·
[web:code.claude.com](https://code.claude.com/docs/en/sub-agents.md) · `[memory:decisions#D-032]` ·
`[memory:lessons#L-009]` · IMPLEMENTATION-NOTES §7 (2026-07-02).

---

## D-034 — RC de Joaco: disposición de la franja addendum (06 §12.2–12.3) + pin doctrinal AI SDK v5

**Date:** 2026-07-02
**Status:** accepted

**Context:** la auditoría final plan-vs-implementado (`AUDIT-FINAL.md`, commit `9a19c79`) confirmó que
los 8 GAPs + drifts reales del repo provienen TODOS de la misma franja: los deltas del addendum de
feedback (`docs/06` §12.2 "Deltas a la arquitectura" + §12.3 MoSCoW del feedback) que se integraron a la
vara al final y nunca recibieron fila en el tracking M/A/S/C del ROADMAP — el registro declaraba
"MoSCoW 100%" sin cubrirlos. Esta decisión los dispone uno a uno para poder taggear el RC en estado
honesto: todo implementado, diferido con registro, o descartado a propósito.

**Decision (por grupo):**
- **F-P5.1 (Must) + F-P5.2 (Should) → IMPLEMENTADOS** (commit `eeccbcb`): patrón de conciencia de
  contexto = hook `PreCompact` (`scripts/handoff.mjs` → `.forja/HANDOFF.md`) + statusline
  (`scripts/statusline.mjs`, en `.claude/settings.json`) + `/handoff` manual enriquecido consciente de
  la fase SDD; `primer` lo lee primero al reanudar. Límite de viabilidad de `docs/07` intacto: no hay
  trigger fiable a 50% — el hook dispara al compactar. Test `handoff.test.sh` (6 casos).
- **F-P1.1/1.2/1.3 (Must: form-factor gate + `surface` en `feature_list.json` + check
  `surface_compliance` en el-evaluador) → DIFERIDOS con trigger explícito:** si el proyecto piloto de
  validación (Joaco) es **mobile-first o híbrido → implementar ANTES del build piloto** (el gate
  cascadea a tokens/componentes/navegación desde Fase −1/0); si es web desktop → backlog
  post-validación. El default implícito actual del Golden Path es web desktop; construir el gate sin un
  proyecto mobile que lo ejercite violaría la escalera YAGNI (`MINIMALISM.md`).
- **F-P2.1 (Must: Anti-Slop Gate 8→12 checks sobre el JSX renderizado) → DIFERIDO post-dogfooding.**
  Mitigación vigente: los checks 7–8 del gate + la hue blacklist de el-evaluador ya tocan el TSX; el
  salto a AST-sobre-JSX se calibra mejor con los falsos negativos que arroje el dogfooding real.
- **F-P2.3 (Must: Brand DNA versionado con golden screens como baseline + visual-diff
  candidate-vs-golden) → DIFERIDO post-dogfooding.** Mitigación vigente: `brand.json`/`voice.json`
  versionados en git + protección anti-sobrescritura de add-ui-kit + Anti-Slop Gate. El set de golden
  screens necesita un proyecto real que los produzca — se diseña sobre el piloto.
- **Vínculo `implementation_notes` → `feature_list.json` (sub-elemento de M5, 06 §M5) → DIFERIDO.**
  Mitigación vigente: contadores en el trailer de commit (`el-yunque.md`) + `open_questions` en el
  handoff a el-evaluador. Se agrega el bloque al schema cuando el dashboard lo consuma (mismo cambio,
  un solo bump de schema).
- **AI SDK → doctrina v5 CONFIRMADA como pin** (commit `c558f17`): `ai@^5 @ai-sdk/react@^2
  @openrouter/ai-sdk-provider@^1 zod@^3` (antes `ai@latest` → resolvía v7 contra templates escritos
  para la API v5). Catálogo duplicado `\.claude/ai_templates/` ELIMINADO — la copia canónica es
  `.claude/skills/ai/references/` (post-D-004); router y la-herreria redirigidos. La migración v5→v7 es
  deuda de Ola 2 (`docs/08` §5) gobernada por el drift-gate, no un upgrade silencioso.

**Alternatives considered:**
- Implementar TODA la franja antes del RC: rechazada — retrasa la validación real semanas y construye
  F-P1.x/F-P2.x sin un proyecto que los ejercite (anti-YAGNI); el valor del RC es el feedback de Joaco.
- Adoptar AI SDK v7 ya: rechazada — invalidaría los 12 templates v5 verificados sin ganancia inmediata;
  v7 entra por la Ola 2 con regen + verificación completa.
- Dejar la franja sin registro (status quo): rechazada — es exactamente el hallazgo H-1 de la
  auditoría; "MoSCoW 100%" sería prosa no verificable (L-009).

**Consequences:**
- (+) Los 8 GAPs de `AUDIT-FINAL.md` §4 quedan dispuestos: G-1/G-8 implementados, G-2..G-7 diferidos
  con trigger y mitigación citables; el RC se puede taggear en estado honesto.
- (+) ROADMAP gana la sección §1b (addendum del feedback) — la franja ya no vive fuera del tracking.
- (-) Tres Musts del addendum quedan diferidos por decisión (no implementados); el trigger de F-P1.x
  depende de conocer el proyecto piloto — preguntar a Joaco ANTES del kickoff.

**Source:** `AUDIT-FINAL.md` §4–§7 (auditoría 2026-07-02, HEAD `2f1bf7b`) · `docs/06` §12.2–12.3 ·
`docs/07` §2 · `[memory:decisions#D-030]` (patrón de re-disposición) · `[memory:lessons#L-009]`
(el harness manda, no la prosa) · IMPLEMENTATION-NOTES §7 (2026-07-02).

---

## D-035 — Ciclo de feedback dogfooding 2026-08-18: propiedad del spec (R19), decisiones en el plano, y absorción ECC

**Date:** 2026-08-18
**Status:** accepted

**Context:** primer feedback de dogfooding real multi-proyecto (11 puntos de Carlos) + el handoff de
la instanciación informatix-evidencia (`HANDOFF-harness-2026-08-18.md`), que documentó 3 bugs del
template (U-01/U-10/U-14) y un hallazgo de máquina (`core.hooksPath` global que apagaba commit-msg/
post-commit y tragaba exit codes en TODOS los repos). Patrones observados: el agente "olvida" contrato
que nunca quedó en el spec; las decisiones tomadas en sesión se pierden al avanzar; el output se volvió
demasiado técnico justo cuando entran colaboradores.

**Decision:**
- **R19** — el humano es dueño del SPEC (`SPEC.md`/`CONTEXT.md`/`docs/adr/**`); la IA es dueña del
  código. Enforcement estructural: pre-commit rechaza mezclar spec↔código; commit-msg exige type|scope
  `spec` (type nuevo en R2). Cambiar el spec = re-entrada a `/descubrir`; spec equivocado en build =
  halt + surfacear.
- **`decisions[]` en `.plan/`** (PLAN_SCHEMA v0.2 / schema 2.1) — las decisiones son estado de primera
  clase del plano (D-nnn, vigente|superseded, eventos `decision_add`/`decision_supersede`, panel en la
  UI). `decisions.md` (R5) sigue siendo el registro narrativo canónico; el plano es la vista de gestión.
- **Absorción ECC sin instalación** (`QUALITY_GATES.md`, coherente con L-007): evidencia RED como
  Layer 0 de el-evaluador · fresh-context review para features critical · `/temple --harness`
  (AgentShield) para auditar el harness mismo.
- **`COMMUNICATION.md`** — Cierre Ejecutivo + Decisión Guiada como estándar de toda salida mayor
  (registro Forge-Pro, dos capas negocio-primero).
- **`/design` (host Claude Code)** como paso opcional del asset #7 con degradación segura.
- **`add-marketing`** — 11/47 métodos de coreyhaines31/marketingskills (MIT) destilados con vetting
  CYBERSEC; fundación derivada de ONTOLOGY/SPEC; NO plugin, NO los 47.
- **Graph/memoria externa DIFERIDOS con gate** (B7 Graphiti · B8 OpenViking · B9 Stagehand ⛔):
  primero dogfoodear lo zero-dep (`decisions[]`) antes de aceptar infraestructura corriendo.

**Consequences:** commits `126da8d..d5f4a68` (meta-CI verde run#32189745905); suites raíz 20 · forge 67;
39 comandos / 38 skills; fix hooksPath aplicado en la máquina con backup. Ver L-010.

## D-036 — Ablación 3R medida: el harness se pesa antes de crecer (rutina Boris Cherny)

**Date:** 2026-09-02
**Status:** accepted

**Context:** Boris Cherny (YC, *Building Claude Code*): con Opus 5 cortaron ~80% del system prompt —
eran parches de conductas que el modelo ya tiene; "ablation, no opinión: borrar todo y devolver línea a
línea midiendo"; el error #1 del usuario es la instrucción demasiado específica (*hobbling*). Forja es
exactamente ese objeto: R1–R19, AP1–AP8, 38 skills, 39 comandos. Al medir por primera vez
(`scripts/check-ceilings.mjs`): 37/38 SKILL.md exceden el techo 500–2000 tokens que SKILL_AUTHORING §3
declara; descripciones ≈ 7× el techo de escaneo; `skills.md` ≈ 14k tokens leídos en cada dispatch (R6);
`forge/CLAUDE.md` 195 líneas always-on; el registro prometía 4 skills sin directorio. Nadie lo medía:
`inventory.js` contaba, no pesaba. Justo cuando entra la spec de diseño de Anshu (D-037), que proponía
+5 skills +5 comandos.

**Decision:**
- **Partir por función, no por bando** (doc 03 §3): lo que aporta un acto que el modelo *no puede* hacer
  (PRNG externo, juez fresco sin Edit, confirm de gasto) = guardrail/herramienta; lo que define *cuándo
  está listo* = criterio de término; lo que dice *cómo pintar* = hobbling, NO entra. Superficie neta de
  comandos/skills en el ciclo de diseño: **0**.
- **Techo medido en meta-CI**: `check-ceilings.mjs` corre en `make meta-check` (WARN; cap de
  `AGENTS.md` = FAIL duro; `--strict` cuando el catálogo baje del techo). `inventory.js` gana columna KB.
- **Cuatro cajones 3R** (`docs/10-ablation-3r.md`): contexto irreplicable · guardrail estructural ·
  SOP/receta · ático. Guardrails de código (tool filters, hooks fail-closed) NO se ablacionan: AP3 es
  seguridad, no parche de inteligencia.
- **Ático real** (`forge/.claude/_attic/`, fuera del glob de Claude Code = ablación de contexto):
  `add-marketing` es el primer experimento — proceso de otro, <3×/mes, el Requisito (voz) ya vive en
  `voice.json`. Restaurable con evidencia; expiry = próximo salto de modelo.
- **Higiene**: 4 fantasmas fuera de `skills.md`; contadores reales; `forge/CLAUDE.md` 195→155 líneas
  (pruning §6: no-ops, duplicados de `AGENTS.md`, conteos hardcodeados); fila colgante `el-supervisor`
  fuera de ambos `AGENTS.md`.
- **Rutina**: cada ~6 meses o salto de modelo — medir → clasificar → UN experimento → `decisions[]`.

**Consequences:** scan antes de la primera tecla ≈ 28.7k → 28.0k tokens (la ablación de un skill mueve
~2.5%; el peso real está en los cuerpos y en `skills.md` — siguientes experimentos: `web-quality`,
wizards, `/context` real). 38 comandos / 37 skills vivos + 1 en ático. Ver `docs/10-ablation-3r.md` §5.

## D-037 — Diseño world-class sin slop de comité: separación de poderes (entropía · juicio · gasto · marca · motion)

**Date:** 2026-09-02
**Status:** accepted

**Context:** tres documentos de Carlos (1–2 sep 2026): la spec de Anshu Chimala (Lenny's, *How to turn
your AI into a world-class designer*: 6 técnicas → proponía 5 skills `design-*` + 5 comandos + 1 agente),
su amplificación con papers (Sakana SSoT · Gu 2026 *Illusion of Stochasticity* · Khullar 2026
*Self-Attribution Bias* · NoveltyBench · Zheng 2023 · WiserUI-Bench · HIG/WCAG 2.2.2 · Nate Herk 2 sep) y
el recap de Boris Cherny (ablación, hobbling, 3R — D-036). Tesis: los LLM diseñan por comité (next-token
+ RLHF → el púrpura es el centro de masa); el gusto no se prompta, se **aísla**. Forja ya tenía los nombres
(AP3, R7, R19, `el-pulidor`, F-P2.1/F-P2.3 diferidos por D-034); faltaban píxeles, semillas y un juez que
no toque el repo.

**Decision (partir por función, no por bando — 0 skills/comandos nuevos):**
- **Juicio aislado:** agente `el-critico-de-diseno` (`Read, Bash`, `model: opus`; sin Write/Edit/Grep/Glob)
  despachado por `el-pulidor` modo `critique` con SOLO screenshots desktop+mobile (+ refs del tenant). El
  sesgo vive en el formato del turno (Khullar): contexto fresco por construcción, no por prosa. **Crítico ≠
  `el-evaluador`** (píxeles vs AST/tokens/gates) ≠ `el-guardian` ≠ humano.
- **Stop fuera del prompt:** `QUALITY_GATES.md` §4 — `MAX_CRITIC_ITERS=2`, parada = gana/empata pairwise vs
  refs (position swap), no-progreso, R19; `score`/10 = telemetría, nunca gate; "9/10" jamás en el prompt
  (los scores absolutos driftean — Zheng, WiserUI-Bench).
- **Entropía externa:** `scripts/design-seed.sh` (PRNG del SO, 128 chars) + `design-diversity.mjs`
  (aHash de pantallas, `COLLAPSE` si ≥3/5 comparten composición). "Sé único" prohibido como único mecanismo.
  Opción `semilla` junto a las 5 direcciones canónicas (cierra el "Design Discovery" de D-025). Un solo
  writer registra `CHOSEN.md` en `decisions[]` (R1/R5/R19).
- **Cut antes del golden:** `el-pulidor` modo `cut` (sustracción con mandato humano) → screenshot post-cut =
  candidato golden `brand/golden/` → humano acepta (F-P2.3). Comparación pairwise + checks deterministas,
  **no pixel-diff** (resuelve P2-D). `el-evaluador` deja de prometer un visual diff sin baseline (G-6/H-12).
- **Gate 8→12 (F-P2.1):** `anti-slop-gate.sh` única fuente ejecutable (3 listas divergentes → 1); checks
  `glow_stack` · `reduced_motion` · `layout_prop_animation` · `hero_default`; fixture negativo obligatorio
  (L-010). Penalty mecanizable del crítico ⇒ check.
- **Gasto y a11y (AP9):** imagen/video de pago solo con frase de autorización en el turno, un job, keys en
  `.env.agents`; default dry-run; Higgsfield/Forge Studio nunca implícito; gate a11y post-enrich
  (`DESIGN_ENRICH.md`: reduced-motion, pause on-page, autoplay muted, solo transform/opacity). Motion
  Lottie/Rive/CSS primero (B2: `signature_element`, `hero_layout`, `motion.*` en el schema).
- **Lo que NO se hizo (a propósito):** no 5 skills `design-*`, no comandos nuevos, no fusionar Discover con
  `/descubrir`, no meter estética en `el-evaluador`, no renombrar Forja→Forge (D-032), no snippet en la
  zona `FORJA:PRESERVE` (es del usuario; el doc 01 se equivocaba de archivo).

**Consequences:** F-P2.1 y F-P2.3 → ✅; B1/B2 → ✅; D-025 "Design Discovery" cerrado con semillas; AP9 nuevo;
suite forge 67 → 105 (fork-agents 24 · critic-agent 16 · design-lab 13); 38 comandos / 37 skills + 1 en
ático. Pendiente de dogfooding: T1 (landing fixture real con 5 semillas) y T2 (loop del crítico sobre UI
viva) — el harness está listo; la evidencia la da el piloto. Ver L-011.

## D-038 — `add-payments`: ranking determinista + Mercado Pago como Mode C + ledger + gate PAY-* (PagoKit absorbido, no instalado)

**Date:** 2026-09-03
**Status:** accepted · **supersede parcial de D-010** (Stripe default + Polar MoR + PAUSE siguen vigentes como *salidas*; lo que muere es el árbol de prosa Stripe-vs-Polar y la ceguera LATAM)

**Context:** Carlos trajo `github.com/Hainrixz/agente-pagokit` (plugin de Claude Code, MIT, v0.2.2):
42 proveedores / 136 métodos / 106 monedas con exponente ISO 4217, un ranking puro (`advise.js`), un
firmador de eventos (`sign-event.js`) y 24 validadores fail-closed en hooks de turno. Forja tenía
`add-payments` con Stripe/Polar y ninguna respuesta para MX/LATAM (OXXO, SPEI, Pix, PSE, Mercado
Pago). Revisión G1–G10 (`docs/11`): sin tabla de eventos procesados ni idempotencia en DB; el escáner
R15 solo conocía prefijos de Stripe; sin dunning; sin auditoría de integraciones existentes; sin
inventario PCI §6.4.3. Vetting de 5 pasos ejecutado (`docs/security/VETTING-pagokit-0.2.2.md`): sin
red ni exec, suite propia verde, esquemas de firma de Stripe y Mercado Pago re-verificados contra
fuente primaria (docs de Stripe; SDK oficial de MP). Polar figura `unverified` en su catálogo.

**Decision (L-007: absorber la metodología, no la dependencia · 3R de D-036):**
- **Vendor, no plugin.** `add-payments/vendor/pagokit/` = datos + schemas + `advise.js` + `sign-event.js`
  + libs (MIT, `PROVENANCE.md`, un solo parche local: ruta del catálogo). Sync pineado a tag por
  `scripts/sync-pagokit-catalog.sh` (regenera `references/currencies.md`). Sus comandos, skills,
  subagente y hooks de turno **no entran** (0 comandos / 0 skills nuevos).
- **El proveedor lo decide un programa, el agente lo narra** (`prompts/decision-tree.md`): `advise.js`
  → `recommendation` + `rejected[]` con razón + fee real + `integration_level` + `last_verified_at`
  (disclaimer obligatorio). Salidas: STRIPE (A) · POLAR (B) · **MERCADOPAGO (C)** · ADVISE · PAUSE.
  Lead time de llaves → Tech Spec + bloqueador en `.plan/` (G7); fee → input de `/precio` (G8).
- **Mode C con paridad estructural** (`templates/mercadopago/`, 15 archivos): verificador puro del
  manifest `id;request-id;ts;` (familia `hmac_field_concat` — MP no firma el body), ventana 300 s +
  dedup + re-fetch, montos en unidad mayor hacia la API y menores en DB con exponente, rails
  irreversibles marcados (`refundable = false` → `payout_required`, R14), sin `cancel_at_period_end`
  (default `paused`), sin Customer Portal embebido.
- **Ledger compartido** `0003_payments_ledger.sql` (G1/G2): `payments` + `webhook_events_processed`
  (unique provider,event_id) + `idempotency_keys`; `organization_id` nullable con policy por org
  **solo si existe `auth_org_ids()`** (R16, degradación segura).
- **Gate mecánico PAY-001..008** en `threat-db.yaml` (categoría `payments`, 77→85 amenazas,
  `automated: true`) + `tests/payments-gate.sh` (templates deben pasar; `fixtures/insecure/` debe fallar
  8/8 — L-010) que corren `el-guardian` (lente **El Cobrador**), `/temple`, `migration-wizard` (brownfield)
  y el job `payments` de `ci.yml` (G9).
- **Layer 3 real:** `tests/payments/webhook-mercadopago.test.mjs` firma eventos inline y exige que el
  `verify.ts` del template rechace forjado / secret incorrecto / sin header / replay / request-id alterado.
- **R15 (G3):** prefijos live `APP_USR-` (MP), `lmnsq_` (Lemon Squeezy), `prv_` (Wompi) curados del
  catálogo en ambos pre-commit; la llave de ejemplo de la doc de Stripe/PayMongo (`BQokikJOvBi`)
  allowlisted porque el catálogo la trae. Polar no tiene patrón confirmado — no se inventa.
- **Doctrina heredada:** `webhook_confidence != high` ⇒ no se emite verificador (honestidad del build);
  `references/subscription-lifecycle.md` (dunning/gracia/downgrade, G5); `payment-page-scripts.json`
  (PCI DSS 4.0.1 §6.4.3, G6); "pago exitoso ≠ CFDI emitido" al Tech Spec/ontología.
- **Pendiente (gated, medido):** hook de turno `PreToolUse` acotado a rutas de pago (docs/11 paso 6);
  sandbox real de MP en el primer cliente que cobre en MX; contrafirma de `el-guardian` en `/temple --harness`.

**Consequences:** `add-payments` 3 modos; suites: dry-run stripe 72 · polar 56 · mercadopago 94 ·
security-pre-handoff 80 (10 gates × 3) · payments-gate 4/4 · pre-commit +1 caso por árbol; threat-db 85;
`el-guardian` 6 lentes; `ci.yml` 7 jobs. Superficie de comandos/skills: sin cambio (38/37). Ver
R-012, `docs/11`, `docs/security/VETTING-pagokit-0.2.2.md`.

---

## D-039 — BaaS de `inventario-juegos` = Supabase (assumed_default, sin Tech Spec formal de la-herreria Fase 3)

**Date:** 2026-09-11
**Status:** accepted

**Context:** Fase 1 (Cimientos y datos) de `inventario-juegos` necesitaba backend persistente para la
entidad `game` (F1-02, F1-03) antes de que existiera un Tech Spec formal producido por `la-herreria`
Fase 3 — este proyecto arrancó directo desde el Blueprint sin pasar por el pipeline completo de
planificación. El skill `baas` exige una decisión documentada de BaaS antes de que `el-migrador` y la
capa de acceso a datos puedan avanzar, con fallback explícito para el caso "sin Tech Spec formal"
([memory:decisions#D-009]).

**Decision:** Supabase, documentada en `.claude/PRPs/TECH-SPEC-inventario-juegos.md` sección
"BaaS Decision" (2026-09-11). Score Supabase 8 · InsForge 5 (diff 3, decisión cerrada sin
tie-breaker). Señales decisivas: (1) Supabase ya era el default declarado en el Golden Path de
`CLAUDE.md` del proyecto ("Backend: Supabase (Auth + PostgreSQL + RLS) | InsForge según Tech Spec");
(2) el scaffold llegó con `@supabase/supabase-js` + `@supabase/ssr` ya instalados antes de que
arrancara Fase 1 — no había ninguna señal en contra de cambiar de BaaS; (3) Supabase CLI + Docker
local permitieron levantar una DB de prueba real (`supabase start`) y probar la migración `up`/`down`
de F1-02 contra Postgres real en vez de mocks, sin pedirle a Carlos acceso a un proyecto externo
(evita `[CONSTRAINTS.md#AP1]`). Flag `baas.assumed_default = true` explícito en el TECH-SPEC: aplica
el fallback documentado en `.claude/skills/baas/SKILL.md` ("Supabase como default cuando no hay Tech
Spec"), consistente con el precedente de `add-login` ([memory:decisions#D-009]).

**Alternatives considered:**
- InsForge: puntuó más alto solo en operating mode (agents-primary) y SLA/real-time/edge (ninguno de
  los cuales aplica — el MVP es CRUD básico sin real-time). Rechazado por el diff de 3 puntos y por
  desinstalar dependencias ya presentes sin justificación.
- Halt hasta que `la-herreria` produjera un Tech Spec formal: rechazado por la misma razón que D-009 —
  fricción alta para un proyecto interno de un solo cliente/revisor; el fallback `assumed_default` con
  flag explícito preserva trazabilidad sin bloquear Fase 1.

**Consequences:**
- (+) F1-02 (migración `game`) y F1-03 (capa de acceso a datos) pudieron construirse y verificarse
  localmente contra Postgres real (Docker) en la misma sesión, sin dependencia externa.
- (+) RLS deny-all en `game` para `anon`/`authenticated` (L-001 degradado: sin auth en v1, acceso real
  solo server-side vía `createServiceClient()` con `import "server-only"`) queda alineado con el patrón
  Supabase ya validado en Forja.
- (-) La decisión no pasó por el Tech Spec formal de Fase 3 — si el proyecto crece a multi-usuario o
  requiere auth, hay que re-evaluar contra un Tech Spec real (el flag `assumed_default` señala esto
  explícitamente para auditoría futura, mismo patrón de riesgo documentado en D-009).

**Mitigation:** cuando `inventario-juegos` pase por `la-herreria` Fase 3 (si el alcance crece más allá
del MVP de un solo cliente), re-validar la decisión de BaaS contra el Tech Spec formal; el flag
`assumed_default = true` en `TECH-SPEC-inventario-juegos.md` deja la asunción trazable para esa
revisión, siguiendo la política de auditoría de D-009.

**Fuente:** `.claude/PRPs/TECH-SPEC-inventario-juegos.md` sección "BaaS Decision". Emparenta con
[memory:lessons#L-001] (RLS por user_id/degradado como default en tablas de datos) y
[memory:decisions#D-009] (Supabase default de `add-login`, mismo patrón `assumed_default`).

**Cita:** `[memory:decisions#D-039]`

<!-- D-040 onwards: populated as architectural decisions emerge -->
