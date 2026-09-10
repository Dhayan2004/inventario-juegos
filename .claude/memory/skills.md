# Skills Registry — Forja Memory

> Single source of truth for skill dispatch. **Orchestrators MUST validate skill name against this registry BEFORE dispatching.**
>
> **Single writer:** `el-evaluador`. Updated when a skill is added, deprecated, or modified.
>
> **Format per skill:**
> ```
> ## <skill-name>
> - **Tier:** core | optional
> - **Usar cuando:** <triggers — when this skill should be invoked>
> - **Requiere:** <preconditions — what must be true before invocation>
> - **Fallback:** <what to do if requirements not met or skill unavailable>
> ```
>
> Cite as `[memory:skills#skill-name]`.

---

> **Status (post-F5-S2, 2026-05-09):** **Phase 5-S2 wizards mayores landed — 26/26 skills en registry CON SKILL.md authoring.**
>
> **F5-S2 milestone:** la-herreria assets/routes portados (5 routes + 15 assets) + 3 wizards mayores authored (add-mobile-stack D-021, enterprise-stack D-022, migration-wizard D-023). Total ADRs cross-skill: 15 (D-009..D-023).
>
> **L-004 cross-skill scoreboard FINAL post-F5-S2:** 15 ADRs. **11 binary** (D-009 add-login, D-012 add-mobile, D-013 la-forja, D-015 web-quality, D-016 el-tajo, D-017 el-golpe, D-018 skill-creator, D-019 init-saas, D-020 add-monetization, **D-021 add-mobile-stack**, **D-022 enterprise-stack**) + **2 trinary** (D-010 add-payments — desde D-038 la forma es *default + N overrides + ADVISE + PAUSE* con el override decidido por programa, sigue siendo trinaria en su shape L-004, D-011 add-emails) + **2 boundary case** (D-014 el-crisol pipeline, **D-023 migration-wizard pipeline DETECT→ANALYZE→PLAN**).
>
> **Doctrine final post-D-023 (5 reglas operacionales):** ver `decisions.md#D-023` sección final.

---

> **Status (post-F5-S1, 2026-05-09):** **Phase 5 wizards landed — 23/23 skills en registry CON SKILL.md authoring.**
>
> **Milestone:** Phase 5-S1 closed. 21 core skills (Phase 3) + 2 wizard skills (Phase 5): **init-saas** (compone add-ui-kit → impeccable → add-login, resume-aware, D-019 binary) + **add-monetization** (compone add-payments → add-emails → web-quality, resume-aware, D-020 binary + PAUSE-interno-delegado distinction).
>
> **E-006 cerrado:** init-saas + add-monetization resuelven el chicken-egg de cadenas de skills (UX gap conocido desde F3-S3). Usuarios ya no descubren PREFLIGHT halts en cadena al invocar add-login/add-payments — los wizards componen la cadena automáticamente.
>
> **E-007 mitigado:** impeccable/tests/component-contract.sh valida cross-skill que brand.json declara los componentes que add-login/add-payments/add-emails consumen. Skip graceful si brand.json absent (informativo, no fail).
>
> **Patrón L-004 cross-skill FINAL post-F5-S1:** 12 ADRs cubren el patrón en su totalidad — D-009..D-020. Distribución: **9 binary** (D-009 add-login, D-012 add-mobile, D-013 la-forja, D-015 web-quality, D-016 el-tajo, D-017 el-golpe, D-018 skill-creator, **D-019 init-saas, D-020 add-monetization**) + **2 trinary** (D-010 add-payments, D-011 add-emails) + **1 boundary case** (D-014 el-crisol pipeline sin selector). Doctrine final post-D-020 (4 reglas operacionales): (1) "Presencia del selector determina aplicabilidad" (D-015). (2) "Ladder lightweight → orchestrator es binary by structure" (D-016/D-017). (3) "Meta skills siguen L-004 normal si tienen selector" (D-018). (4) **"Wizards con sub-skills PAUSE-aware: PAUSE-interno-delegado NO escala como PAUSE-wizard"** (D-020). Aplicable universalmente.

---

## Core skills (29)

### el-ontologo
- **Tier:** core
- **Usar cuando:** Fase −1 — levantamiento ontológico de la EMPRESA (su "ser"), ANTES de `/descubrir` y `/plan`. Entrevista grill-me con dos lentes: NEGOCIO (método Founder OS — segmento, JTBD, problema priorizado con evidencia, propuesta de valor, modelo operativo) y MARCA (método Estudio — arquetipo, código simbólico, lenguaje propio). Produce `ONTOLOGY.md` (frontmatter machine-readable + narrativa) regido por `references/ONTOLOGY_SCHEMA.md` (extiende Brand DNA), que se inyecta en cada generación downstream igual que `brand.json`. Reusa el motor de `el-entrevistador` con perfil de dominio `ontologia`. Resume-aware vía `.ontologia/session.md`. Triggers: "levantemos la empresa", "haz la ontología", "perfilemos el negocio", "Fase −1".
- **Requiere:** raíz del proyecto escribible (crea `.ontologia/`). NO requiere Bootstrap Contract (corre antes de Fase 0 y de `/plan`).
- **Fallback:** si ya hay `ONTOLOGY.md` vigente, sugerir `/descubrir` (Fase 0). Si es una feature suelta sobre un producto conocido, ir a `/plan`.
- **Dependencies:** [el-entrevistador, la-herreria, add-ui-kit] (handoff: el `CONTEXT.md` de Fase 0 deriva del glosario de empresa; la-herreria orbita la ontología en PREFLIGHT; add-ui-kit hereda `marca.*`). Método destilado de Founder OS (negocio) + Estudio (marca), ambos SOLO LECTURA.

### el-entrevistador
- **Tier:** core
- **Usar cuando:** Fase 0 de descubrimiento — la idea aún no está clara, o ANTES de `/plan`. Entrevista grill-me (1 pregunta/turno + recomendación) que levanta `SPEC.md` (6 secciones) + `CONTEXT.md` (glosario del dominio del cliente, igualdad semántica) + ADRs (3 criterios). Resume-aware vía `.specfounder/session.md`. Triggers: "tengo una idea (borrosa)", "descúbreme el proyecto", "entrevístame", "levanta el spec".
- **Requiere:** raíz del proyecto escribible (crea `.specfounder/`). NO requiere Bootstrap Contract (corre antes de `/plan`).
- **Fallback:** si ya hay spec/blueprint claro, sugerir saltar a `/plan` (la-herreria, modo B "trabajo previo").
- **Dependencies:** [la-herreria, migration-wizard] (handoff a `/plan` vía adaptador "forge" en `references/emit-forge.md`; `migration-wizard` para brownfield de stack). Portado de SpecFounder v2 (MIT, Oscar Lobo).

### la-herreria
- **Tier:** core
- **Usar cuando:** usuario quiere planificar un proyecto nuevo desde idea hasta Blueprint ejecutable
- **Requiere:** PREFLIGHT pasa (AGENTS.md existe, repo accesible)
- **Fallback:** halt con mensaje "Falta /forge-init para inicializar el repo"
- **Dependencies:** [find-docs, add-ui-kit, baas, el-guardian, impeccable] (delegados via assets: `add-ui-kit` Fase 8, `baas` Fase 3, `el-guardian` opcional Fase 9, `impeccable` UI gen).

### el-crisol
- **Tier:** core
- **Usar cuando:** Blueprint aprobado y usuario pide validación estratégica antes de invertir en `/build` (entre la-herreria y la-forja). Casos: "crisol", "validación estratégica", "vale la pena construir", "pitch deck", "dashboard estratégico", post-Blueprint con inversión >2 semanas justificable. 4 modos: `go` (ejecutar 7 análisis pendientes), `saltar N` (saltar paso), `desde N` (empezar desde paso concreto), `solo dashboard` (consolidar docs existentes). **Además `/fragua-review` (C1):** rúbrica read-only de revisión de ARQUITECTURA del Blueprint (5 fases → EXPANSIÓN/MANTENER/REDUCCIÓN), en `references/fragua-review.md` — complementa la validación de NEGOCIO de el-crisol y la de CÓDIGO de el-guardian.
- **Requiere:** Blueprint aprobado en `.claude/PRPs/BLUEPRINT-*.md` (PREFLIGHT halt-line). Acceso lectura raíz proyecto + `.claude/reports/` para detección Fase 0. Active feature en feature_list.json (R1) opcional pero recomendado para tracking. Para Fase 2 dashboard — capacidad de generar HTML standalone.
- **Fallback:** Sin Blueprint → halt + handoff `la-herreria`. Sin Blueprint pero usuario pide "solo dashboard" con 0 docs → halt informativo. Si Perplexity MCP no disponible → seguir sin enrichment (no halt). Si dashboard HTML falla generación → fallback a STRATEGY-REPORT.md sin HTML. Veredicto No-Go → no force-fit handoff a la-forja, recomendar replantear estrategia.
- **Dependencies:** [].
- **Cita:** [memory:CONSTRAINTS.md#R4] (el-crisol thin orchestrator, sub-agents ejecutan análisis vía dispatch), [memory:CONSTRAINTS.md#R5] (sub-agents no escriben memory; solo el-evaluador post-pipeline si invocado), [memory:CONSTRAINTS.md#R8] análogo (Build Confidence Score cita doc fuente; NO scores inventados), [memory:CONSTRAINTS.md#R13] condicional (find-docs invocable ad-hoc en Fase 2 si Chart.js API freshness needed; [docs:chart-js@v4] cuando aplica), [memory:lessons#L-004] (informativa — NO aplica directo, shape distinto), [memory:decisions#D-014] (el-crisol pipeline shape; primer boundary cross-skill donde L-004 NO aplica — sequential-pipeline-con-resume-detection, NO selector entre N providers; PREFLIGHT halt ≠ PAUSE genuino), [memory:decisions#D-013] (handoff post-Go a la-forja aplica L-004 EN la-forja level, no en el-crisol), [docs:chart-js@v4] (cuando sub-agent invoca find-docs en build-dashboard.md).

### la-forja
- **Tier:** core
- **Usar cuando:** ejecución de feature aprobado con paralelización (Fork, default, 2-5 worktrees) o sequential synthesis con dependencias entre fases (Coordinator override) o one-shot atómico con workers tool-filtered (Swarm override, delega a el-tajo / el-golpe). Único skill core que implementa el bloque D8 ARCHITECTURE.md con los 3 patterns.
- **Requiere:** Blueprint aprobado en `.claude/PRPs/BLUEPRINT-*.md`. feature_list.json con feature en `active` (R1). Para Fork — git ≥ 2.5 + ≥2GB libre por worktree. Para Swarm — sub-tasks atómicos definibles. PREFLIGHT 5-gates antes de orchestrate.
- **Fallback:** Sin Blueprint → halt + handoff `la-herreria`. Sin active feature → halt + sugerir pickear backlog. Si Fork falla por disco/conflictos → degradar a Coordinator. Si Coordinator también falla → handoff a `el-yunque` (manual humano-en-loop).
- **Dependencies:** [find-docs] (R13 antes de generar git worktree commands).
- **Cita:** [memory:CONSTRAINTS.md#R4] (la-forja MISMA NO invoca skills, solo dispatch a sub-agents), [memory:CONSTRAINTS.md#R5] (workers no escriben memory; el-evaluador post-orchestration), [memory:CONSTRAINTS.md#R6] (registry validation pre-dispatch), [memory:CONSTRAINTS.md#R7] (handoff el-evaluador post-orchestration mandatory para R7 three-layer), [memory:CONSTRAINTS.md#R13] (find-docs antes de git worktree, [docs:git]), [memory:CONSTRAINTS.md#R14] (deploy NUNCA automático — handoff el-guardian condicional + confirmation humana), [memory:CONSTRAINTS.md#AP3] (self-eval prohibido, Reviewer en Swarm separate del Implementer), [memory:lessons#L-004] (binary pattern selector aplicado), [memory:decisions#D-008] (informativo R-005 v1.1.0 si la-forja orquesta UI), [memory:decisions#D-013] (la-forja confirma binary cross-skill, sexta validación L-004 — 3 binary, 2 trinary post-bloque-D + ortogonal), [docs:git] (git worktree commands canónicos vía find-docs).

### el-evaluador
- **Tier:** core
- **Usar cuando:** validar output de cualquier otro skill antes de marcar feature `passing` (Three-Layer Verification)
- **Requiere:** verification command definido en feature_list.json
- **Fallback:** halt — no se permite skip de evaluator
- **Dependencies:** [] (standalone — no delega a otros skills).

### el-guardian
- **Tier:** core
- **Usar cuando:** pre-deploy security audit con Codex como segundo cerebro
- **Requiere:** Codex CLI instalado y configurado
- **Fallback:** advertir + permitir deploy con `--skip-security` solo si usuario lo confirma explícitamente
- **Dependencies:** [] (usa Codex CLI externo, no skills Forja).

### project-auditor
- **Tier:** core
- **Usar cuando:** auditoría **full-project** pre-release (TODO `src/`, no solo el diff) en 4 dimensiones (Seguridad 30% · Datos/RLS 25% · Cache/Rend 25% · Calidad Web 20%) con Audit Score compuesto 0-100. Cruza `threat-db.yaml` (77 amenazas) + el contrato de la empresa (`ONTOLOGY.md › requisitos_seguridad` + `SPEC.md` Sección 6) + `get_advisors` de Supabase, delega Calidad Web a `web-quality`, y `--deep` invoca `el-guardian` (Codex). Comando `/temple` (full/quick/security/datos/cache/web/compare/--deep). Bloquea deploy ante críticos (fail-closed). Es el gate **pre-release** de la doctrina shift-left; complementa a `el-guardian` (que audita la feature/diff). Portado de Forge Pro v5.1.0 (motor de `/temple`).
- **Requiere:** raíz del proyecto accesible. Supabase MCP y Codex (`--deep`) opcionales (degradación segura).
- **Fallback:** sin MCP → no penaliza lo no observable; sin Codex → omite la capa `--deep`.
- **Dependencies:** [web-quality, el-guardian] (Calidad Web vía web-quality; capa adversarial `--deep` vía el-guardian).

### el-migrador
- **Tier:** core
- **Usar cuando:** crear/aplicar/rollback migrations de Supabase
- **Requiere:** Supabase CLI instalado, project linked
- **Fallback:** generar SQL manual + instrucciones para correr a mano

### el-tajo
- **Tier:** core (lightweight)
- **Usar cuando:** microtarea atómica one-shot <5min wallclock, <500 LOC delta, 1-3 archivos. Sin discovery, sin planning, sin loop iterativo. Ejemplos: extraer componente, bumpear dep patch, agregar tracking event, fix typo, rename variable. Triage natural desde sprint o desde la-forja Swarm pattern.
- **Requiere:** active feature en feature_list.json (R1 — opera dentro del active actual). Tests + lint pasando antes de tocar código (PREFLIGHT halt si rojos). Git accesible para atomic commit.
- **Fallback:** Sin active feature → halt + sugerir pickear backlog. Tests rojos → halt: "fixá tests primero". Si scope excede criterios atómicos → escalate-graceful a el-golpe con razón explícita.
- **Dependencies:** [].
- **Cita:** [memory:CONSTRAINTS.md#R1] (active feature requirement), [memory:CONSTRAINTS.md#R2] (atomic commit cierre), [memory:CONSTRAINTS.md#R10] condicional (si tajo toca UI con tokens), [memory:CONSTRAINTS.md#R14] condicional (si genera tools destructivas), [memory:lessons#L-003] condicional (si toca inputs externos), [memory:lessons#L-004] (binary D-016 informativo), [memory:decisions#D-016] (BINARY shape: execute / escalate-graceful a el-golpe sin PAUSE — ladder lightweight → orchestrator).

### el-golpe
- **Tier:** core (lightweight)
- **Usar cuando:** feature mediano one-shot <30min wallclock, 1-3 commits atómicos, brief-plan visible (3-5 líneas) antes de ejecutar. Ejemplos: implementar flujo invitar miembros, dashboard 4 KPIs admin, customizar SignInForm. Más estructura que el-tajo (brief-plan visible) pero sin loop iterativo (a diferencia de sprint). Triage desde sprint, el-tajo, o la-forja Swarm pattern.
- **Requiere:** active feature en feature_list.json (R1). Si feature requiere UI → brand/brand.json existe (R10 PREFLIGHT halt). Tests + lint pasando antes de tocar código. Git accesible.
- **Fallback:** Sin active feature → halt. Sin brand.json + UI requerida → halt + handoff add-ui-kit. Tests rojos → halt: "fixá tests primero". Si scope excede 30min durante ejecución → commit lo hecho, halt, sugerir /build (la-forja). Si emerge necesidad de iteración con feedback humano → halt + escalate a sprint.
- **Dependencies:** [].
- **Cita:** [memory:CONSTRAINTS.md#R1] (active feature), [memory:CONSTRAINTS.md#R2] (atomic commits), [memory:CONSTRAINTS.md#R10] condicional (si UI), [memory:CONSTRAINTS.md#R14] condicional (si tools destructivas), [memory:lessons#L-001] condicional (si tabla user data → RLS user_id), [memory:lessons#L-003] condicional (si inputs externos → whitelist Zod), [memory:lessons#L-004] (binary D-017 informativo), [memory:decisions#D-017] (BINARY shape: execute / escalate-graceful a /build sin PAUSE — ladder lightweight → orchestrator paralelo a D-016).

### impeccable
- **Tier:** core
- **Usar cuando:** generar componentes UI production-grade que CONSUMEN el contrato Brand DNA producido por add-ui-kit. 3 modos: KNOWN (variant declarado en `component_rules`), UNKNOWN (derivación R-005 sec 8.2), BATCH (init core component set).
- **Requiere:** brand/brand.json + voice.json + brand.css existen y cumplen R-005. TypeScript + Tailwind v3+ instalados. (Opcional: shadcn-ui detected → modo shadcn-customizado; sino from-scratch).
- **Fallback:** sin Brand DNA → halt + handoff a `add-ui-kit`. Si shadcn no instalado → modo from-scratch (Tailwind primitives directo). Si Tailwind ausente → halt.
- **Dependencies:** [find-docs, add-ui-kit].
- **Cita:** [memory:references#R-005] (schema + sec 8.2 derivation), [memory:CONSTRAINTS.md#R10] (Brand DNA contract gate), [memory:lessons#L-002] (componentes que reciben contenido externo), [memory:lessons#L-003] (whitelist validation en form inputs), [memory:decisions#D-007] (shadcn-customizado por default).

### add-ui-kit
- **Tier:** core
- **Usar cuando:** inicializar el design system del proyecto (Discovery FRESH → brand.json + voice.json + brand.css + showcase) o consolidar UI inconsistente (REDESIGN scan + report + migration plan)
- **Requiere:** PREFLIGHT pasa. Para REDESIGN, además, repo target con código UI ya escrito (≥3 archivos en src/).
- **Fallback:** si el repo no tiene `AGENTS.md` → halt. Si Discovery REDESIGN scan reporta <3 archivos UI → switch a Mode FRESH.
- **Dependencies:** [find-docs] (para [docs:nextjs|tailwindcss|shadcn-ui] antes de generar showcase + brand.css).
- **Cita:** [memory:references#R-005] (schema canónico), [memory:CONSTRAINTS.md#R10] (Brand DNA contract gate), [memory:lessons#L-003] (whitelist validation en inputs Discovery), [memory:decisions#D-006] (rationale 5 presets).

### web-quality
- **Tier:** core
- **Usar cuando:** auditoría integral pre-deploy Lighthouse-based (150+ checks) cubriendo Performance + Core Web Vitals (LCP/INP/CLS) + Accessibility (WCAG 2.1 AA mandatory) + SEO (Next.js metadata API + structured data) + Best Practices (security + modern + code quality + Forja-specific brand checks). Binary mode selector (D-015): "live audit" (default — agent-browser CLI por D4, Lighthouse fallback) o "static analysis" (fallback graceful sin URL/server, lectura de código + pattern detection sin scores numéricos pero con line numbers). Casos: "web audit", "quality check", "lighthouse audit", "antes de deploy verificá calidad", pre-deploy gate complementario a el-guardian.
- **Requiere:** proyecto Next.js con `src/` o `pages/` accesible (PREFLIGHT suave). Para live audit (default) — URL o `npm run dev`/`npm run start` corriendo + agent-browser CLI o Lighthouse CLI instalado. Static fallback NO requiere URL ni server.
- **Fallback:** Sin proyecto Next.js detectable → halt informativo. Sin URL ni server para live → static analysis graceful (NO PAUSE). Sin agent-browser ni Lighthouse CLI → halt: "ningún audit tool disponible". Si live audit produce error inesperado → degradar a static + reportar.
- **Dependencies:** [find-docs] (R13 antes de generar comandos lighthouse / agent-browser).
- **Cita:** [memory:CONSTRAINTS.md#R4] (web-quality MISMA NO invoca tools, sub-agents ejecutan audit), [memory:CONSTRAINTS.md#R5] (sub-agents no escriben memory; reporte va a `.claude/reports/` state, no memory), [memory:CONSTRAINTS.md#R10] (Brand DNA contract — checks Forja-specific: brand.css cargado en root layout, brand.json NO en bundle cliente, anti-slop hue range respetado), [memory:CONSTRAINTS.md#R13] (find-docs antes de generar agent-browser/lighthouse commands; [docs:agent-browser], [docs:lighthouse] cuando aplica), [memory:lessons#L-002] (CSP previene script injection en best-practices.md), [memory:references#R-003] (agent-browser default por D4 ARCHITECTURE.md — ~4× ahorro tokens vs Playwright MCP), [memory:decisions#D-014] (refinement context — el-crisol pipeline shape sin selector), [memory:decisions#D-015] (web-quality binary selector + refina D-014 doctrine: presencia del selector determina aplicabilidad de L-004, NO categoría del skill — validators CON selector siguen L-004 normal), [docs:agent-browser] (CLI commands canónicos vía find-docs), [docs:lighthouse] (fallback estándar), [docs:nextjs] (metadata API para SEO + next/image+next/font para Performance + middleware/headers para Best Practices), [docs:wcag] (WCAG 2.1 AA guidelines).

### baas
- **Tier:** core
- **Usar cuando:** decidir/configurar BaaS (Supabase vs InsForge) según Tech Spec
- **Requiere:** Tech Spec del proyecto generado por la-herreria
- **Fallback:** Supabase como default si no hay Tech Spec

### ai
- **Tier:** core
- **Usar cuando:** integrar features de IA (chat, RAG, vision, tools, generative-ui, structured-outputs) con Vercel AI SDK v5
- **Requiere:** OPENROUTER_API_KEY o equivalente en .env
- **Fallback:** OpenAI API directa si Vercel AI SDK no es opción

### memory-manager  _(concepto — NO es un skill invocable · Q-MEM-DIR resuelto)_
- **Qué es:** la gestión de `.claude/memory/*.md` es una capacidad **inline de `el-evaluador`**, no un
  skill con dir propio. No existe `skills/memory-manager/` y no se invoca por su nombre (por eso el
  inventario auto-generado no lo cuenta).
- **Autoridad (R5):** solo `el-evaluador` escribe la memoria; el enforcement lo pone el hook `commit-msg`
  (scope `evaluator`/`memory` requerido), NO un dispatcher. Doctrina en `el-evaluador/SKILL.md`
  §"Memory write protocol (R5)".
- **Por qué queda registrado:** marca el invariante de sole-writer y evita que alguien "cree" el skill
  faltante. Q-MEM-DIR (2026-07-01): decisión = intencional-inline, entrada honesta en vez de borrada.

### find-docs
- **Tier:** core
- **Usar cuando:** necesitas docs actualizadas de una lib externa antes de escribir código (cualquier import, API call, config, o sintaxis de lib que NO sea estándar JS/TS y pueda haber cambiado post-cutoff)
- **Requiere:** Context7 MCP configurado en `.mcp.json` (entry `context7`, ver `example.mcp.json`)
- **Fallback:** WebFetch a docs oficiales del lib si Context7 no responde o no encuentra el lib; documentar miss en `errors.md` para futura promoción al cache

### init-saas
- **Tier:** core
- **Usar cuando:** wizard que compone la cadena canónica de bootstrapping SaaS (add-ui-kit → impeccable → add-login). Resume-aware con detección de estado al estilo el-crisol — escanea brand.json + components + auth y skipea pasos completados. Resuelve E-006 (chicken-egg de cadena de skills). Casos: usuario greenfield Forja quiere "auth completa", "init saas", "setup completo"; triage de la-herreria post-Blueprint detecta SaaS feature; o usuario corre add-login directo y recibe halt → handoff sugiere init-saas. Binary mode (D-019): FRESH default (chain completa) / EXISTING resume-aware (skipea pasos completados, sigue desde donde quedó).
- **Requiere:** directorio Next.js con src/ o pages/ accesible (PREFLIGHT halt si ninguno). AGENTS.md en raíz (Forja installed). Para add-login (paso 3) — baas decision documentada o fallback Supabase default. Active feature en feature_list.json (R1) recomendado pero soft warning si falta.
- **Fallback:** Sin AGENTS.md → halt: "proyecto no inicializado con Forja". Sin Next.js → halt informativo. Si paso N falla durante ejecución → halt + handoff explícito al sub-skill que falló. Cuando se resuelve, re-invocar init-saas → resume-aware retoma desde paso N+1.
- **Dependencies:** [find-docs, add-ui-kit, impeccable, add-login, baas].
- **Cita:** [memory:CONSTRAINTS.md#R4] (wizard MISMA NO invoca skills directo, dispatch a sub-agents que invocan), [memory:CONSTRAINTS.md#R5] (workers no escriben memory; el-evaluador post-pipeline), [memory:CONSTRAINTS.md#R10] (Brand DNA gate enforced via add-ui-kit paso 1), [memory:errors#E-006] (resuelve gap UX cadena de skills), [memory:lessons#L-004] (binary D-019 informativo), [memory:decisions#D-014] (boundary case shape-par estructural), [memory:decisions#D-019] (BINARY shape: FRESH default + EXISTING resume-aware sin PAUSE; resume-aware feature distintiva — wizard idempotente).

### add-monetization
- **Tier:** core
- **Usar cuando:** wizard que compone la cadena de monetización (add-payments → add-emails → web-quality). Resume-aware con detección al estilo el-crisol/init-saas. Casos: usuario quiere integrar pagos en proyecto con auth listo, "monetización", "pagos + emails + audit"; triage post-Blueprint detecta monetization. Binary mode (D-020): full chain default / partial payments-only override. **CRÍTICO — distinción PAUSE-interno-delegado ≠ PAUSE-wizard:** add-payments (D-010 trinary) y add-emails (D-011 trinary) tienen PAUSE genuino interno, pero el PAUSE NO escala al nivel wizard. add-monetization sigue siendo BINARY al wizard level — D-020 documenta esta distinción como principio cross-wizards aplicable universalmente.
- **Requiere:** add-login completado en proyecto target (PREFLIGHT halt si missing). Brand DNA presente (brand.json + voice.json). impeccable components base (Button + Input + Card mínimo). Active feature en feature_list.json recomendado.
- **Fallback:** Sin add-login → halt + sugerir init-saas. Sin Brand DNA → halt + handoff add-ui-kit. Sin impeccable components → halt + handoff impeccable Mode C. **Si add-payments retorna PAUSE-interno (D-010)** → wizard reporta PAUSE-interno-delegado al usuario, halt graceful, NO escala como PAUSE-wizard. Mismo manejo para add-emails PAUSE-interno (D-011). Si web-quality (paso 3) sin URL/server → auto-degrada a static analysis (D-015 binary), NO halt.
- **Dependencies:** [find-docs, add-payments, add-emails, web-quality, add-login, impeccable].
- **Cita:** [memory:CONSTRAINTS.md#R4] (wizard thin, R4 enforced), [memory:CONSTRAINTS.md#R5] (workers no memory), [memory:CONSTRAINTS.md#R10] (Brand DNA via sub-skills), [memory:errors#E-006] (resuelve gap UX paralelo a init-saas para cadena monetización), [memory:lessons#L-004] (binary D-020 informativo), [memory:decisions#D-010] (add-payments PAUSE interno trinary — relevante para paso 1), [memory:decisions#D-011] (add-emails PAUSE interno trinary — relevante para paso 2), [memory:decisions#D-015] (web-quality binary live/static — relevante para paso 3), [memory:decisions#D-019] (init-saas paralelo, mismo shape wizard), [memory:decisions#D-020] (BINARY al wizard level + **distinción PAUSE-interno-delegado ≠ PAUSE-wizard** codificada como principio cross-wizards).

### add-mobile-stack
- **Tier:** core
- **Usar cuando:** wizard que extiende init-saas agregando mobile/PWA. Compone la cadena add-ui-kit → impeccable → add-login → add-mobile (4 pasos). Resume-aware con detección al estilo el-crisol/init-saas — escanea brand.json, components, auth feature, manifest.json + sw.js + push migration. Casos: usuario greenfield Forja quiere setup completo SaaS + Mobile, "init mobile saas", "setup completo con PWA"; triage post-Blueprint detecta SaaS + Mobile feature. Binary mode (D-021): FRESH (chain completa de 4 pasos) / EXISTING (resume desde donde quedó). Hereda D-019 (init-saas patrón) + D-020 doctrine (PAUSE-interno-delegado NO escala). add-mobile (D-012) es binary internamente PWA/Native — el wizard hereda sin modificar.
- **Requiere:** directorio Next.js con `src/` o `pages/` accesible (PREFLIGHT halt si ninguno). AGENTS.md en raíz (Forja installed). Para add-login (paso 3) — baas decision o fallback Supabase default. Para add-mobile (paso 4) — `.env.local` writable para VAPID keys. Active feature en feature_list.json recomendado.
- **Fallback:** Sin AGENTS.md → halt: "proyecto no inicializado con Forja". Sin Next.js → halt informativo. Si paso N falla durante ejecución → halt + handoff explícito (ej: "add-mobile halt — VAPID keys missing"). Re-invocar add-mobile-stack post-resolución → resume-aware retoma desde paso N o N+1.
- **Dependencies:** [find-docs, add-ui-kit, impeccable, add-login, add-mobile, baas].
- **Cita:** [memory:CONSTRAINTS.md#R4] (wizard thin), [memory:CONSTRAINTS.md#R5] (workers no memory), [memory:CONSTRAINTS.md#R10] (Brand DNA gate via add-ui-kit), [memory:errors#E-006] (chicken-egg cadena de skills — extensión 4-step), [memory:lessons#L-004] (binary D-021 informativo), [memory:decisions#D-021] (BINARY shape, patrón heredado), [memory:decisions#D-019] (init-saas patrón base), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine), [memory:decisions#D-012] (add-mobile binary interno PWA/Native), [memory:decisions#D-009] (add-login Supabase default heredado).

### enterprise-stack
- **Tier:** core
- **Usar cuando:** wizard de wizards. Compone init-saas → add-monetization → add-mobile-stack para setup enterprise completo en una sola invocación. Resume-aware con detección de outputs de cada wizard hijo. Casos: usuario greenfield quiere setup enterprise completo, "enterprise stack", "setup completo", "todo de una", "production-ready"; triage post-Blueprint detecta SaaS + Mobile + Monetization. Binary mode (D-022): FULL chain default (3 wizards) / CUSTOM override (skip wizards específicos: "sin mobile", "sin pagos"). Hereda D-019 (init-saas) + D-020 (PAUSE-interno-delegado doctrine) + D-021 (add-mobile-stack). R6 enforcement explícito en PREFLIGHT — valida que init-saas, add-monetization, add-mobile-stack existan en skills.md antes de cualquier dispatch.
- **Requiere:** directorio Next.js + AGENTS.md en raíz. **R6 mandatory:** init-saas, add-monetization, add-mobile-stack disponibles en `.claude/memory/skills.md`. Active feature en feature_list.json recomendado.
- **Fallback:** Sin AGENTS.md → halt: "proyecto no inicializado con Forja". Sin Next.js → halt informativo. **Si init-saas/add-monetization/add-mobile-stack NO existen en skills.md (R6 fail)** → halt: "wizard {nombre} no disponible — re-instalar Forja". Si sub-wizard halt durante ejecución → halt + handoff explícito; resume-aware retoma cuando se resuelve. Si sub-wizard reporta PAUSE-interno-delegado (D-020 heredado) → wizard reporta al usuario, halt graceful, NO escala como PAUSE-wizard.
- **Dependencies:** [init-saas, add-monetization, add-mobile-stack].
- **Cita:** [memory:CONSTRAINTS.md#R4] (orchestrator thin a 2 niveles — meta-wizard + wizards hijos), [memory:CONSTRAINTS.md#R5] (workers no memory cross-wizards), [memory:CONSTRAINTS.md#R6] (skills.md registry validation pre-dispatch — CRÍTICO en wizard de wizards), [memory:CONSTRAINTS.md#R10] (Brand DNA gate via init-saas), [memory:lessons#L-004] (binary D-022 informativo), [memory:decisions#D-022] (BINARY wizard de wizards FULL/CUSTOM), [memory:decisions#D-019] (init-saas patrón heredado), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine — aplicada cross-wizards), [memory:decisions#D-021] (add-mobile-stack patrón heredado).

### migration-wizard
- **Tier:** core
- **Usar cuando:** pipeline DETECT → ANALYZE → PLAN para migrar proyectos existentes a Forja Enterprise. Detecta tipo de origen del proyecto (5 tipos auto-detectados: Forge V3.x, Forge V2, Next.js custom, otro framework, greenfield con código). Analiza estado actual vs Bootstrap Contract de Forja (R11) + extras Forja Enterprise. Identifica gaps críticos que bloquean `/build` y reusable existente. Produce `MIGRATION-PLAN-{nombre}.md` con pasos priorizados, comandos Forja exactos, y estimación de tiempo. **NO ejecuta la migración — solo planifica.** La ejecución es responsabilidad del usuario (corre los comandos del plan en orden). Casos: usuario tiene proyecto Next.js custom y quiere adoptar Forja, proyecto Forge V3.x → Forja Enterprise, greenfield con código que quiere instalar el harness. Shape: pipeline DETECT → ANALYZE → PLAN (D-023 — boundary case análogo a D-014, NO selector entre N approaches).
- **Requiere:** directorio del proyecto a migrar accesible (cwd o path provisto). NO requiere otros skills (dependencies vacío — solo lee y planifica).
- **Fallback:** Si no hay proyecto detectable (no `package.json`, no `.git`) → halt informativo: "No se detecta proyecto. Indicá path con `migration-wizard /path/to/project`." **Si ya está en Forja Enterprise** (AGENTS.md + feature_list.json + .claude/memory/skills.md existen) → halt: "Proyecto ya migrado. Corré /forge-check para diagnóstico."
- **Dependencies:** [].
- **Cita:** [memory:CONSTRAINTS.md#R4] (orchestrator thin — NO ejecuta, solo lee + analiza + Write del plan), [memory:CONSTRAINTS.md#R5] (workers no memory), [memory:CONSTRAINTS.md#R11] (Bootstrap Contract gates analizados), [memory:decisions#D-023] (pipeline shape, boundary case análogo a D-014), [memory:decisions#D-014] (el-crisol pipeline resume-aware sin selector — patrón heredado), [memory:lessons#L-001] (RLS user_id check), [memory:CONSTRAINTS.md#R14] (destructive tools check).

### update-forja
- **Tier:** core
- **Usar cuando:** actualizar proyecto Forja existente a versión más nueva del template upstream. Pipeline DETECT → PULL → BACKUP → MERGE → REPORT (5 fases secuenciales + auto-delegación post-pull intercalada). Auto-detecta REPO_PATH desde alias `forja` del shell (no hardcoding). Soporta estructuras flat y dual-tree del source. Hace `git pull` del source, luego actualiza framework files (`.claude/{commands,skills,prompts,references}/`, `scripts/`, `Makefile`, `AGENTS.md`, `CONSTRAINTS.md`, `example.mcp.json`) wholesale; preserva archivos del proyecto (`.claude/memory/*.md`, `feature_list.json`, `PROGRESS.md`, `brand/*.json`, `src/features|shared`, `.mcp.json`, rutas custom de `src/app/`); CLAUDE.md usa merge inteligente con marker `FORJA:PRESERVE:START` (zona framework renovada, zona proyecto preservada). Config drift en `package.json`/`next.config.ts`/`tailwind.config.ts`/`tsconfig.json`/`components.json`/`postcss.config.js` se detecta y reporta (no sobreescribe). Backup automático en `.forja-backup-{timestamp}/` antes de modificar. Auto-delegación post-`git pull` carga la versión más reciente del propio skill del source (resuelve bootstrap problem — el `/update-forja` siempre corre con la lógica más actual). Shape: pipeline DETECT-PULL-MERGE (D-027 — boundary case análogo a D-014 + D-023, NO selector entre N approaches).
- **Requiere:** shell con alias `forja` configurado en `~/.zshrc` o `~/.bashrc` (o REPO_PATH manual si no existe). Git instalado. Proyecto Forja existente (`.claude/` o `.claude/` presente). Working tree limpio (`git status --porcelain | wc -l == 0`). Git inicializado en el proyecto target.
- **Fallback:** Sin alias `forja` → prompt one-time pidiendo REPO_PATH (no halt, no selector). Sin `.claude/` ni `.claude/` → halt: "No detecté proyecto Forja en este directorio." Working tree dirty → halt: "Hacé commit o stash antes de actualizar." Sin git → halt: "Proyecto sin git. Iniciá git antes." Sin marker en CLAUDE.md → warning + skip update de CLAUDE.md (no destruir contenido del usuario). `git pull` failure → halt con stdout del error.
- **Dependencies:** [].
- **Cita:** [memory:CONSTRAINTS.md#R5] (memory/ es sole-writer evaluador — NEVER TOUCH list lo respeta), [memory:CONSTRAINTS.md#R10] (Brand DNA del proyecto — `brand/*.json` NEVER TOUCH), [memory:decisions#D-027] (pipeline shape boundary case, auto-delegación post-pull patrón), [memory:decisions#D-014] (pipeline shape pattern heredado — `el-crisol`), [memory:decisions#D-023] (pipeline DETECT pattern heredado — `migration-wizard`), [memory:errors#E-009] (lección "no destruir contenido del usuario" — extendida a CLAUDE.md vía marker + configs vía detect-and-report), [memory:lessons#L-004] (binary test diagnostic informativo — NO aplica directo por ausencia de selector).

## Optional skills (7)

### add-login
- **Tier:** optional (no se invoca si proyecto no tiene auth)
- **Usar cuando:** usuario pide setup completo de auth — email/password + OAuth Google + profiles + RLS. 2 modos: Supabase (default) + Insforge (alternativa). Templates pre-armados con substitución de placeholders desde brand.json + voice.json.
- **Requiere:** baas decision documentada (o fallback Supabase), Brand DNA presente (brand/brand.json + voice.json), impeccable corrió previamente (componentes UI base existen). .env.local writable.
- **Fallback:** Sin Brand DNA → halt + handoff a add-ui-kit. Sin impeccable components → halt + handoff a impeccable Mode C. Sin baas decision → fallback Supabase con flag `assumed_default`.
- **Dependencies:** [find-docs, baas, impeccable, add-ui-kit].
- **Cita:** [memory:references#R-005] (Brand DNA schema), [memory:CONSTRAINTS.md#R10] (Brand DNA contract gate en auth pages), [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra Supabase/Insforge), [memory:CONSTRAINTS.md#R14] (deleteAccount con typed confirmation, no execute() agentic), [memory:lessons#L-001] (RLS en profiles), [memory:lessons#L-002] (oauth callback payload as data), [memory:lessons#L-003] (whitelist validators en actions/auth.ts), [memory:decisions#D-007] (impeccable shadcn-customizado-default reuse), [memory:decisions#D-009] (Supabase como default vs Insforge), [docs:supabase] · [docs:supabase-ssr] · [docs:nextjs] · [docs:insforge].

### add-payments
- **Tier:** optional
- **Usar cuando:** la app cobra — checkout + customer portal + webhooks firmados + ledger + subscriptions. El proveedor lo decide el **ranking determinista** `vendor/pagokit/advise.js` (42 proveedores, país/compradores/billing/rails/entidad/lead time; D-038): **Stripe** (Mode A, default) · **Polar** (Mode B, MoR) · **Mercado Pago** (Mode C, LATAM: OXXO/SPEI/Pix/PSE, moneda local con exponente ISO 4217) · ADVISE (proveedor sin build: el código es del usuario) · PAUSE. Triggers: "agregame pagos / billing / checkout / suscripciones", "cobrar en México/LATAM", "OXXO", "SPEI", "Mercado Pago".
- **Requiere:** add-login completado (profiles), Brand DNA presente (brand/brand.json + voice.json), impeccable components base. Para Mode C: credenciales `TEST-` de MP (nunca `APP_USR-` en el repo — R15).
- **Fallback:** sin Tech Spec → correr el ranking (default Stripe con `assumed_default`). Sin Brand DNA → halt + handoff a add-ui-kit. Sin add-login → halt + handoff a add-login. Proveedor con `webhook_confidence != high` → ADVISE, nunca un verificador inventado. Brownfield con pagos existentes → lente El Cobrador de el-guardian (`tests/payments-gate.sh`) vía migration-wizard.
- **Dependencies:** [find-docs, baas, add-login, impeccable, add-ui-kit] + `vendor/pagokit` (datos + motores, MIT; sync desde el meta-repo). Downstream: add-emails (PaymentFailed/dunning), el-crisol `/precio` (fee real), el-guardian (gate 0 = PAY-001..008), ci.yml job `payments`.
- **Cita:** [memory:references#R-005] (Brand DNA en pricing/billing), [memory:CONSTRAINTS.md#R10], [memory:CONSTRAINTS.md#R13], [memory:CONSTRAINTS.md#R14] (refund/cancel destructivos; rails irreversibles → payout manual), [memory:CONSTRAINTS.md#R16] (ledger tenant-aware), [memory:lessons#L-001], [memory:lessons#L-002], [memory:lessons#L-003], [memory:lessons#L-010] (Layer 3 con eventos forjados/replay), [memory:decisions#D-009], [memory:decisions#D-010] (Stripe default + Polar MoR + PAUSE), [memory:decisions#D-038] (ranking + Mode C + ledger + PAY-*), [memory:references#R-012] (PagoKit), threat-db `PAY-001..008`, [docs:stripe], [docs:stripe-node@v18], [docs:polar], [docs:polar-sdk@v0.x], [docs:mercadopago@v2], [docs:nextjs].

### add-emails
- **Tier:** optional
- **Usar cuando:** integrar Resend + React Email para transaccionales (welcome, password reset confirm, invoice receipts, magic links). Decision tree similar a D-009: Resend default + SendGrid override cuando Tech Spec lo dicta.
- **Requiere:** add-login completado, Brand DNA presente, impeccable components base (para email templates con tokens consistentes).
- **Fallback:** documentar setup manual con SendGrid u otro SMTP cuando Resend no esté disponible. Sin Brand DNA → halt + handoff a add-ui-kit.
- **Dependencies:** [find-docs, baas, add-login, impeccable, add-ui-kit].
- **Cita:** [memory:references#R-005] (Brand DNA schema — email templates respetan tokens), [memory:CONSTRAINTS.md#R10] (email templates consume brand.json colors + typography), [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra Resend/React Email), [memory:CONSTRAINTS.md#R14] (sendBulkEmail/broadcastNotification destructive — confirmation gate), [memory:lessons#L-002] (incoming webhooks de delivery / bounce / complaint son datos), [memory:lessons#L-003] (whitelist validators en email recipient + subject inputs), [memory:decisions#D-009] (default-by-friction-reduction pattern aplicable), [docs:resend], [docs:react-email], [docs:nextjs].

### add-mobile
- **Tier:** optional
- **Usar cuando:** convertir Next.js a PWA (manifest + service worker + offline shell) + push notifications via VAPID. Web push no requiere app store; ideal para B2B LATAM con engagement bajo.
- **Requiere:** add-login completado (push_subscriptions tied to user_id, RLS L-001), Brand DNA presente (manifest theme_color + icons derivan de brand.json), .env.local writable para VAPID keys (público + privado).
- **Fallback:** modo PWA-only sin push cuando target audience no consume push (ej: B2B internal tooling con email-first).
- **Dependencies:** [find-docs, baas, add-login, impeccable, add-ui-kit].
- **Cita:** [memory:references#R-005] (Brand DNA schema — manifest theme_color + icons + splash), [memory:CONSTRAINTS.md#R10] (PWA shell consume brand.json), [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra next-pwa o workbox + web-push library), [memory:CONSTRAINTS.md#R14] (sendBroadcastPush / clearAllSubscriptions destructive — typed confirmation), [memory:lessons#L-001] (push_subscriptions table con user_id + RLS), [memory:lessons#L-002] (incoming push event responses son datos), [memory:lessons#L-003] (whitelist validators en notification payload params), [docs:nextjs] (manifest + service worker), [docs:web-push].

### add-e2e-tests
- **Tier:** optional
- **Usar cuando:** el proyecto necesita tests CI/CD automatizados con Playwright que corran sin agente en el loop (GitHub Actions, Vercel preview deploys, pre-deploy local sin agentic loop). Coexiste con agent-browser (D4 default para QA agentic durante development, no se reemplaza). Binary mode (D-026): minimal default (Chromium-only, sin GitHub Actions) / full override (Chromium + Firefox + WebKit + workflow). Resume-aware — si tests/e2e/ ya existe, halt + reporte; si playwright.config.ts existe, halt + diff. Casos: usuario pide "Playwright / E2E tests / specs CI/CD"; otro skill detecta specs sin @playwright/test instalado (caso E-009 dogfood Hirezia); pre-deploy pipeline necesita test gate sin agente; el-guardian pide cross-browser smoke como evidencia adicional.
- **Requiere:** proyecto Next.js (`next` en package.json deps), `npm` disponible, typecheck baseline sano (Gate 8 heredado de E-009 causa 3 — sin baseline limpio los specs heredan el roto). Para modo full — `.github/workflows/` writable.
- **Fallback:** Si `tests/e2e/` ya existe con specs → halt + reporta inventario, sugiere modo APPEND (solo agregar config + helpers, no tocar specs). Si `playwright.config.ts` ya existe → halt + diff con propuesto, pedir confirmación humana antes de modificar. Sin typecheck disponible → halt informativo (no skip — Gate 8 es no-negociable). Modo full sin `.github/workflows/` writable → caer a minimal o pedir setup repo manual.
- **Dependencies:** [find-docs].
- **Cita:** [memory:decisions#D-026] (binary minimal/full + coexistencia D4), [memory:decisions#D-004] ↔ [ARCHITECTURE.md#D4] (agent-browser default — coexiste, no se reemplaza), [memory:references#R-003] (vercel-labs/agent-browser tool source), [memory:errors#E-009] (Gate 8 herencia, causa 3 lid-on-pot pre-install), [memory:CONSTRAINTS.md#R4] (sub-agent invoca npm/npx, no la SKILL directo), [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra Playwright), [memory:lessons#L-004] (binary test diagnostic aplicado), [docs:playwright], [docs:playwright-test], [docs:nextjs].

### add-teams
- **Tier:** optional
- **Usar cuando:** generar la **UI de gestión de tenants** en una app target **multi-tenant** (S2): organizaciones, invitaciones por email, roles `owner`/`admin`/`member`, sobre la fundación de M6 (`0000_tenancy.sql`). Drop-in análogo a `add-login` para auth. Migración `0005_teams.sql` (invitaciones + guardas anti-escalación + `accept_invitation`/`transfer_org_ownership` definer + email verificado) + `0005_teams-isolation.test.sql` (6 tests negativos, R7 Layer 4) + 13 server actions (R14 confirmación tipada server-side + L-003) + UI R10 (consume impeccable) + route `/api/teams/my-organizations`. Triggers: "/add-teams", "gestión de organizaciones/equipos en la app", "invitaciones", "roles de miembros", "cambiar de org". Cierra el "build per-app fasable" de M6 (`MULTI_TENANCY.md` §234).
- **Requiere:** AGENTS.md; app declarada multi-tenant (`tenant_model.multi_tenant: true`); `0000_tenancy.sql` aplicado (handoff de `el-migrador`); `add-login` corrió (auth + `auth.users`); Brand DNA + componentes `impeccable`. Doctrina: `references/teams-model.md`.
- **Fallback:** app single-tenant → halt (add-teams es exclusivo multi-tenant; gobierna L-001). Sin fundación `0000_tenancy.sql` → halt + handoff a `el-migrador`. Sin `add-login` → halt + handoff a `add-login`. Sin Brand DNA → halt + handoff a `add-ui-kit`. Sin componentes impeccable → halt + handoff a `impeccable`.
- **Dependencies:** [el-migrador, add-login, impeccable, add-ui-kit, el-guardian].
- **Cita:** [memory:CONSTRAINTS.md#R16] (3 invariantes de tenant), [memory:lessons#L-005] (RLS por tenant), [memory:CONSTRAINTS.md#R14] (server actions destructivas con confirmación tipada server-side, sin execute()), [memory:CONSTRAINTS.md#R10] (UI vía impeccable + voice.json), [memory:CONSTRAINTS.md#R7] (Layer 4: test negativo cross-tenant + escalación), [memory:decisions#D-029] (la decisión de S2), [docs:supabase], [docs:postgres].

## Auxiliary (7)

### primer
- **Tier:** core (lightweight)
- **Usar cuando:** inicio de sesión, cargar contexto del proyecto en <30s
- **Requiere:** AGENTS.md existe
- **Fallback:** modo cold-start (lee README + estructura)

### sprint
- **Tier:** core (lightweight)
- **Usar cuando:** tarea pequeña iterativa que no amerita `/plan` completo (5-15min)
- **Requiere:** PREFLIGHT pasa
- **Fallback:** sugerir el-tajo si es atómico, o /plan si es feature

### skill-creator
- **Tier:** core (meta)
- **Usar cuando:** crear scaffold de skill nuevo de Forja. Binary mode (D-018): guided (default — entrevista 5 preguntas: name/description/tier/shape/Q5 selector presence) o template-only (override — scaffold directo desde YAML structured input para CI/automation). Q5 (selector presence) es CLAVE — determina shape del ADR (binary/trinary vs ADR propio análogo a D-014). Output: scaffold listo para authoring real (SKILL.md template + prompts/ + references/ + tests/dry-run.sh boilerplate con E-008 + F3-S10/S11 frictions absorbidas preventivamente). NO genera el skill terminado.
- **Requiere:** directorio Forja base accesible (.claude/skills/ existe). Nombre del skill nuevo NO debe colisionar con skills.md registry actual.
- **Fallback:** Sin .claude/skills/ → halt: "estructura  no detectada". Si nombre colisiona → halt + sugerir rename. Si entrevista interrumpida ("stop") → guardar inputs parciales en stash y reportar gap. NO sobrescribir skill folder existente sin confirmation explícita.
- **Dependencies:** [].
- **Cita:** [memory:CONSTRAINTS.md#R5] (skill-creator NO escribe a memory; el-evaluador post-authoring registra entry en skills.md + ADR), [memory:errors#E-008] (boilerplate dry-run.sh con awareness from birth), [memory:lessons#L-004] (Q5 selector presence determina aplicabilidad — binary/trinary vs boundary case), [memory:decisions#D-014] (boundary case template para skills sin selector — sequential pipeline / validator-fijo), [memory:decisions#D-015] (doctrine refinada: presencia del selector dentro del skill determina aplicabilidad, NO categoría del skill), [memory:decisions#D-018] (skill-creator BINARY shape: guided default + template-only override sin PAUSE).

### el-cartografo
- **Tier:** core
- **Usar cuando:** generar o mantener el PLANO DE CONTROL (`.plan/`) — la capa de gestión del proyecto (fases → subfases → user stories, fechas, módulos, bloqueadores, anotaciones), versionada en git y bidireccional (humano por UI `plan.html` vía `plan-server.mjs`, agente por filesystem/eventos). Modos: GENERAR (al cerrar `/plan`, nace desde Blueprint + SPEC + ONTOLOGY), MANTENER (eventos durante el build, R-plan/R17), SERVIR (`make plan` → localhost:4317). Triggers: "creá el plano", "dashboard del proyecto", "mapeá el avance", "/cartografo", handoff post-Blueprint de `la-herreria`.
- **Requiere:** Node (server-lite zero-dep). Un Blueprint o `feature_list.json` para mapear. Regido por `references/PLAN_SCHEMA.md`.
- **Fallback:** sin Blueprint → genera `.plan/` mínimo (project + 1 fase) desde el template y pide al humano completarlo por UI. Sin Node → halt.
- **Dependencies:** [] (LEE `feature_list.json` read-only por `featureRefs[]`; sincroniza por hooks `post-commit`/`pre-commit`).
- **Cita:** [memory:CONSTRAINTS.md#R17] (R-plan: el plano es parte del commit atómico; pre-commit fail-closed + post-commit sella eventos), [memory:CONSTRAINTS.md#R1] (NUNCA escribe `feature_list.json` — transiciones por hook, ADR D1), [memory:CONSTRAINTS.md#R12] (Clean-State Exit: sin eventos sin sellar al cerrar sesión).

### verificar-ci
- **Tier:** core
- **Usar cuando:** validar una feature contra el resultado REAL de CI antes de marcarla `passing` — tras `git push`/abrir PR, o antes de `/despachar`. Ejecuta `gh pr checks`/`gh run view`/`gh api check-runs` y devuelve un boolean anti-spoof: una feature NO pasa a `passing` mientras el check-run del commit HEAD no sea `conclusion == "success"` (el `conclusion` lo emite GitHub, no el agente). Triggers: "verificá el CI", "¿pasó el CI?", "/verificar-ci", paso previo a marcar `passing`/deploy.
- **Requiere:** `gh` instalado + autenticado (`gh auth status`) + repo con remote GitHub + `.github/workflows/ci.yml` presente.
- **Fallback:** sin `gh`/remote/CI → degradar a verificación local (R7) y advertir que AP8 no se puede enforzar sin CI.
- **Dependencies:** [] (lo consume `el-evaluador` para la transición; produce el objeto `ci_run` para registrar en `feature_list.json`).
- **Cita:** [memory:CONSTRAINTS.md#AP8] (no `passing` sin CI verde — la regla que materializa), [memory:CONSTRAINTS.md#R7] (doble condición: local exit 0 + ci_run.success), [memory:CONSTRAINTS.md#AP5] (extensión de narrative-completion al plano de CI), [memory:CONSTRAINTS.md#AP3] (árbitro independiente: del agente al runner).

### el-capataz
- **Tier:** core
- **Usar cuando:** gobernanza GitHub-native del **equipo de desarrollo** (S2, pilar ②). 3 modos: INIT ((re)genera `.github/CODEOWNERS` desde el roster `.forja/team.json` + `modules[]` del plano; setea branch protection en `main` vía `scripts/protect-branch.sh`/`gh api` con required checks = jobs de A2; siembra PR/Issue templates si faltan), SYNC (proyecta `feature_list.json`+`plan.json` → GitHub Issues en UNA SOLA VÍA, idempotente por marca HTML), STATUS (read-only: gaps de CODEOWNERS, required checks faltantes, drift de sync). Triggers: "/capataz", "gestión de equipo", "CODEOWNERS", "branch protection", "sincronizá los Issues", "protegé main".
- **Requiere:** `gh` instalado + autenticado + repo con remote GitHub + workflows ci.yml/security.yml (de A2). Roster `.forja/team.json` (lo crea en INIT si falta). Doctrina: `references/github-native.md`.
- **Fallback:** sin `gh`/auth/remote/CI → degradar a setup MANUAL documentado (CODEOWNERS + pasos de branch protection + Issues listados) + advertir que la protección/sync remoto no se aplica; NO rompe el harness (patrón verificar-ci). El gobierno local (R1/AP8/hooks) sigue vigente.
- **Dependencies:** [] (upstream READ-ONLY de `feature_list.json`/`plan.json` y de los `name:` de ci.yml/security.yml; comparte roles M6 con `add-teams`; siembra el PR template que usa `/despachar`).
- **Cita:** [memory:CONSTRAINTS.md#R18] (espejo de una sola vía — NUNCA escribe `feature_list.json` ni marca `passing` desde GitHub), [memory:CONSTRAINTS.md#R5] (NUNCA escribe memoria; sole writer = el-evaluador), [memory:CONSTRAINTS.md#AP8] (los checks de A2 son required en branch protection), [ARCHITECTURE.md#D12] (la decisión que implementa), [memory:decisions#D-029] (la decisión de S2), [memory:errors#E-009] (no sobrescribir templates con contenido propio), [docs:gh].

### el-pulidor
- **Tier:** core
- **Usar cuando:** auditar la CALIDAD DE ACABADO de UI/UX de un proyecto (C1) — read-only advisory. 5 modos: critique (rúbrica ~10 dims con código + **juez visual fresco**: despacha `Agent(el-critico-de-diseno)` screenshot-only desktop+mobile en contexto vacío, cap 2, score = telemetría — D-037), polish (pixel-perfect: spacing/typography/8 estados/micro-interacciones/a11y), normalize (realinear con el design system: hardcoded→tokens, custom→componentes impeccable), redesign (auditoría full-project + plan, NO toca código hasta aprobación), **cut** (pase de sustracción obligatorio antes de congelar un golden screen — candidatos a borrar, el implementador resta con OK humano). Produce reportes .md + handoff a impeccable/el-golpe. Triggers: "/pulidor", "criticá/pulí/normalizá/rediseñá la UI", "dial this back", "quita lo que sobra", "calidad de acabado". FRONTERA (AP3): CRITICA, NO genera/arregla (eso es impeccable/el-golpe/sprint); el juicio estético NO lo emite en su propio contexto (Khullar 2026).
- **Requiere:** Brand DNA (brand/brand.json + voice.json, R10) + componentes de impeccable presentes. Para la capa visual fresca de critique: URL/server + agent-browser (screenshots). Doctrina de modos: `references/modes.md`; cap y paradas: `references/QUALITY_GATES.md` §4.
- **Fallback:** sin Brand DNA → halt + handoff a add-ui-kit (R10 no-negociable). Sin URL/server → critique STATIC (rúbrica con código) con caveat: la capa (b) fresca se omite, no se simula. Solapes mapeados (no duplica): web-audit→web-quality, inspeccionar→/despachar+el-guardian, adversarial→4 modos de el-guardian.
- **Dependencies:** [impeccable, el-evaluador] + subagente `.claude/agents/el-critico-de-diseno.md` (`Read, Bash`, `model: opus`; sin Write/Edit/Grep/Glob — ve píxeles, no repo).
- **Cita:** [memory:CONSTRAINTS.md#AP3] (el que critica no arregla — read-only), [memory:CONSTRAINTS.md#R10] (Brand DNA), [memory:references#R-005] (anti-slop schema), [memory:CONSTRAINTS.md#AP6] (diseño Claude-default = reject), [memory:decisions#D-037] (juez fresco ≠ evaluador; stop fuera del prompt), [docs:agent-browser] (screenshots read-only).

## Hidden tier (opt-in puro — no está en el Decision Router)

> Higiene 2026-09-02 (D-036): se borraron 4 entradas fantasma sin directorio (`el-supervisor`, `website-3d`, `video-visuals`, `image-generation`) — un registry que promete skills que no existen rompe R6 en la dirección inversa. Hermes sigue siendo opcional (D8.4) sin skill propio.

### autoresearch
- **Tier:** hidden (opt-in puro; NUNCA se auto-invoca, no está en el Decision Router)
- **Usar cuando:** el humano pide EXPLÍCITAMENTE mejorar la CALIDAD de un skill existente del harness con un loop self-improving (C6). "corré autoresearch sobre `<skill>`", "auto-tuning de `<skill>`". Loop Karpathy: una variable → mide con criterios binarios (juez = el-evaluador, AP3) → keep/discard → repite. Es la mitigación de D-024 (se re-admite sólo bajo caps duros).
- **Requiere:** working tree limpio · **rama dedicada (nunca main/master)** · target válido en el registry (R6) · budget confirmado (default $5) · backup · el-evaluador como juez. Detalle: `references/autoresearch-loop.md`.
- **Fallback:** PREFLIGHT halt-blocked en TODOS los gates (no degrada — un loop de auto-mutación sin caps es lo que D-024 vetó).
- **Dependencies:** [el-evaluador] (juez independiente de los criterios binarios; único writer de lecciones emergentes — R5).
- **Cita:** [memory:decisions#D-024] (autoresearch descartado → re-admitido como opt-in con AP3), [memory:CONSTRAINTS.md#AP3] (juez ≠ generador), [memory:CONSTRAINTS.md#R5] (NO escribe memory), [memory:CONSTRAINTS.md#AP2] (no --no-verify), [docs:git]. **Safety caps:** 30 iter · $5 · 2× prompt · backup · rama dedicada · `reset --hard $BASE`.

## Ático (ablación 3R — fuera del catálogo vivo, ver `.claude/_attic/README.md`)

### add-marketing
- **Tier:** ático (ablación 3R, D-036 · 2026-09-02) — NO despachable; vive en `.claude/_attic/skills/add-marketing/`
- **Usar cuando:** el proyecto target necesita marketing OPERATIVO sobre páginas/flujos que existen o se están construyendo: auditoría CRO, copy nuevo o edición (7 sweeps), auditoría SEO técnica+contenido, SEO programático, arquitectura del sitio, JSON-LD, plan de analytics GA4/GTM, experimentos A/B (ICE + rigor estadístico), onboarding/activación. 11 métodos destilados y vetteados de coreyhaines31/marketingskills (MIT, 2026-08-18) como references — NO los 47 skills (anti-bloat). La fundación product-marketing se DERIVA de ONTOLOGY.md/SPEC.md si existen (no re-pregunta); todo copy pasa por voice.json (R10) + Anti-Slop; cambios de código salen como handoff a el-golpe/sprint//build. Triggers: "/add-marketing", "audita el SEO", "mejora el copy", "plan de analytics", "experimento A/B", "onboarding".
- **Requiere:** nada duro. Mejora con ONTOLOGY.md, SPEC.md y brand/voice.json presentes.
- **Fallback:** sin ontología/spec → grill-me corto (≤5 preguntas) para la fundación; sin voice.json → copy en borrador marcado "sin voz de marca aplicada"; sin páginas construidas → solo estrategia/planes (nada que auditar).
- **Frontera:** NO reemplaza a el-crisol (estrategia PRE-build: precio/rivales/ROI); NO genera UI (impeccable) ni audita acabado (el-pulidor); NO toca feature_list/memoria/spec (R5, R19).
- **Cita:** [memory:CONSTRAINTS.md#R10] (voz del Brand DNA sobre el método), [memory:CONSTRAINTS.md#R19] (gaps de spec se surfacean), `.claude/references/CYBERSEC_VETTING.md` (protocolo aplicado en la destilación), `.claude/references/COMMUNICATION.md` (Cierre Ejecutivo en reportes), [web:github.com](https://github.com/coreyhaines31/marketingskills) (fuente MIT).
- **Motivo 3R:** proceso de otro (Repetible ✗ <3×/mes · Requisito ✗ no aporta dato irreplicable — la voz viene de voice.json · Repartible ~). **Expiry:** próximo salto de modelo o evidencia de dogfooding. Restaurar: `git mv` + re-registrar aquí + `node scripts/inventory.js`.

---

<!-- registry actualizado por el-evaluador en cada cambio de skills -->
