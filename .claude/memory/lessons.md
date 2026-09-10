# Lessons — Forja Memory

> Append-only knowledge base of positive lessons learned during Forja work.
> **Single writer:** `el-evaluador`. Other agents READ ONLY.
>
> **Format per entry:**
> - ID `L-NNN` (zero-padded, monotonic)
> - Date in ISO format
> - Context (1 line: where the lesson came from)
> - Lesson (1-3 sentences, declarative)
> - Cite from other docs as `[memory:lessons#L-NNN]`

---

## L-001 — RLS por user_id es default en cualquier tabla de datos del usuario

**Date:** 2026-05-07
**Context:** detectado en `06-rag-basico.md` durante F2-port-ai. Upstream saas-factory tenía las tablas `resources` + `embeddings` SIN `user_id` y SIN RLS habilitado — leak cross-user inmediato si dos usuarios indexaban contenido en la misma DB.

**Lesson:** cualquier tabla que persiste datos derivados de input del usuario lleva `user_id uuid references auth.users(id) on delete cascade` + `enable row level security` + al menos una policy `using (auth.uid() = user_id)` o equivalente transitivo (vía join). La intuición "este es un knowledge base compartido / es contenido público" suele estar equivocada — si un usuario lo subió, otro usuario no debería verlo por default.

**Aplicabilidad:** RAG, historial de conversaciones, embeddings, files, drafts, search index, cualquier tabla "user data". Funciones SQL que consultan estas tablas declaradas `security invoker` (no `security definer`) para que respeten RLS del caller.

**Cita:** `[memory:lessons#L-001]`

---

## L-002 — System prompts anti-prompt-injection son obligatorios cuando un agent consume contenido externo

**Date:** 2026-05-07
**Context:** detectado en `02-web-search.md` (resultados de páginas scraped pueden contener "ignora todas las instrucciones anteriores") y `04-vision-analysis.md` (texto incrustado en imágenes — meme con "delete all users" — puede ser leído por un model vision como instrucción) durante F2-port-ai.

**Lesson:** cualquier agente que procesa contenido NO controlado por el operador (web pages, archivos subidos por usuarios, imágenes con texto, emails parseados, mensajes de un canal externo) debe llevar en su system prompt una instrucción explícita que defina ese contenido como "datos a analizar", NO como "instrucciones a obedecer". Si la página/imagen/email contiene texto que parece dar órdenes, el modelo debe reportarlo, no seguirlo.

**Aplicabilidad:** web scraping, RAG sobre documentos del usuario, vision (image inputs), file uploads procesados por LLM, indirect tool inputs, email parsing, ingest de feeds externos.

**Cita:** `[memory:lessons#L-002]`

---

## L-003 — Validación de inputs externos por whitelist explícita, nunca `z.record(z.any())`

**Date:** 2026-05-07
**Context:** detectado en `04-vision-analysis.md` (upstream usaba `file.type.startsWith('image/')` que acepta MIME types raros que el LLM puede no manejar bien) y `05-tools-funciones.md` (upstream tenía tools con `data: z.record(z.any())` para "create record" — vector de mass assignment) durante F2-port-ai.

**Lesson:** los inputs estructurados que cruzan boundaries (cliente → server, LLM → tool, user → API) llevan whitelist explícita en su schema:
- MIME types como `set` cerrado: `ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif'])`
- Enums Zod en lugar de strings libres: `category: z.enum(['shirts', 'pants', 'shoes'])`
- Tools que escriben a DB con campos individuales tipados, NO `data: z.record(z.any())`
- Bounded ranges: `price: z.number().min(0).max(1000000)`

**Aplicabilidad:** API routes, server actions, LLM tools con `inputSchema`, file upload handlers, search filters, cualquier endpoint público que recibe datos estructurados.

**Cita:** `[memory:lessons#L-003]`

---

## L-004 — Test diagnóstico binario-vs-trinario para el patrón "default friction-reducer + override explícito"

**Date:** 2026-05-08
**Context:** detectado durante F3-S6 (add-mobile) tras aplicar el patrón D-009/D-010/D-011 a un cuarto skill. Mientras D-010 y D-011 emergieron trinarios (con PAUSE para casos degenerados que requieren acción upstream — constituir empresa MoR, constituir SMTP self-hosted), D-012 emergió binario (sin PAUSE — PWA es siempre fallback graceful válido). Análisis empírico mostró que la trinaridad NO es universal del patrón. Antes de force-fit a trinario en futuros skills, hay que aplicar un test diagnóstico explícito.

**Lesson:** el patrón "default friction-reducer + override explícito por decision tree" es UNIVERSAL para skills de selección entre N providers. La cláusula PAUSE es OPCIONAL según dominio. Para decidir cuál shape aplica:

> **Test diagnóstico:**
> ¿Existe un degenerate case que requiera acción **upstream** del usuario (constituir entidad legal, infra propia, accounts developer, etc.) **antes** de poder re-invocar el skill productivamente?
>
> - Si **SÍ** → trinario (default + override + PAUSE)
>   - Ejemplos: D-010 payments (PAUSE = constituir empresa MoR), D-011 emails (PAUSE = constituir SMTP self-hosted)
> - Si **NO** → binario (default + override solo)
>   - Ejemplos: D-009 login (Supabase/Insforge ambos disponibles sin upstream action), D-012 mobile (PWA siempre fallback graceful)

**NUNCA force-fit a trinario sin aplicar el test.** Si el agente duda sobre si un caso aplica, default a binario y documenta en ADR que el test mostró NO degenerate case que requiere upstream action — esto es más honesto que inventar un PAUSE artificial.

**Aplicabilidad:** cualquier skill futuro de Forja que use el patrón default+override (potencialmente: web-quality con Lighthouse vs Playwright custom; futuros add-* skills Phase 5+; cualquier baas extension; orchestrator wizards que componen cadenas de skills con providers múltiples).

**Generalización del patrón post-bloque D:**

> "Default friction-reducer + override explícito por decision tree" es la parte universal del patrón D-009 → D-012. PAUSE es opcional, depende del dominio.
>
> PAUSE existe cuando el degenerate case requiere acción upstream del usuario antes de re-invocar el skill productivamente. NO existe cuando el degenerate case es siempre subset del default disponible (PWA siempre sirve, aunque sub-óptimamente, vs. native shell con full native UX).

**Cita:** `[memory:lessons#L-004]`

---

## L-005 — RLS por tenant (`organization_id` + membresía) generaliza L-001 en apps multi-tenant

**Date:** 2026-06-30
**Context:** detectado durante M6 (Multi-tenant). La base RLS de Forja es single-tenant
(`auth.uid() = user_id`, `[memory:lessons#L-001]`). Las apps que genera Forge Enterprise son
multi-tenant (B1): varias organizaciones comparten DB y el aislamiento entre ellas debe ser real.
`auth.uid() = user_id` no aísla por organización — un member podría ver/escribir datos de otra org.

**Lesson:** cuando una app sirve a **organizaciones** (no a individuos), toda tabla de dominio lleva
`organization_id uuid not null references organizations(id) on delete cascade` + RLS por **membresía**:
`using (organization_id in (select public.auth_org_ids()))` para lectura y el **mismo predicado en
`WITH CHECK`** para escritura. El helper `auth_org_ids()` es `security definer` + `stable` +
`set search_path = public` (evita la recursión de RLS sobre `memberships`). Tres invariantes
no-negociables: (1) `organization_id NOT NULL` en toda tabla tenant-scoped; (2) `WITH CHECK` en toda
policy de escritura (sin esto = IDOR cross-tenant); (3) el `organization_id` del cliente nunca se confía
— lo valida `WITH CHECK` contra la membresía real. `profiles` NO lleva `organization_id` (identidad
global 1:1 con `auth.users`; la pertenencia vive en `memberships`). El criterio de "listo para liberar"
gana un test negativo cross-tenant con ≥2 tenants sobre DB real (R7 Layer 4).

**Aplicabilidad:** cualquier app multi-tenant generada con Forge Enterprise (`tenant_model.multi_tenant:
true`). En apps single-tenant gobierna L-001 sin cambios (degradación segura). Enforce: R16. Doctrina:
`.claude/references/MULTI_TENANCY.md`. ADR: `[memory:decisions#D-028]`. El término del tenant
(`organization`/`workspace`/`account`/`team`) lo fija el Tech Spec; el patrón es el mismo.

**Cita:** `[memory:lessons#L-005]`

---

## L-006 — En gestión de equipo, la autoridad de roles vive en la DB (RLS + definer + triggers), no en el código

**Date:** 2026-06-30
**Context:** detectado durante S2 (`add-teams`, gestión de tenants). Una UI de equipos tiene operaciones de
**autoridad** (invitar, cambiar rol, expulsar, transferir propiedad, borrar org). La tentación es gatearlas
en el cliente/server action ("oculto el botón si no es admin"). Pero un cliente que llame la API directo
rebota sólo si la **DB** lo impide. La verificación adversarial (El Infiltrado) encontró tres vectores que
el código por sí solo no cierra: (1) un admin ascendiéndose a `owner`; (2) un admin tocando/expulsando al
`owner`, o la org quedando sin owner; (3) aceptar una invitación con un email que coincide pero **no está
verificado** (instancia con "Confirm email" off → registro con el email de la víctima).

**Lesson:** las guardas de autoridad de equipo se enforzan en **Postgres**, generalizando
`[memory:lessons#L-005]`: (a) **`WITH CHECK`** en la policy de UPDATE de membresías que prohíbe fijar
`role='owner'` salvo que el caller ya sea owner (anti auto-ascenso); (b) policies update/delete que exigen
ser owner para tocar una fila `role='owner'`; (c) un **trigger** `before update/delete` que aborta si la
operación dejaría 0 owners (protección del último owner); (d) la propiedad se mueve sólo por una función
**`security definer` owner-only y atómica** (`transfer_org_ownership`: demote+promote en una transacción);
(e) el alta de miembros NO tiene policy de INSERT del cliente — entra por el trigger creator→owner o por
`accept_invitation` (definer), que valida token + expiración + **match de email + `email_confirmed_at`
real de `auth.users`** (no un claim del JWT, que es spoofeable). La UI sólo **refleja** el rol (oculta
botones); la frontera real es la DB. El criterio de "listo para liberar" añade un test negativo de
escalación/robo además del cross-tenant de M6 (R7 Layer 4: T-TEAM-1..6 + kill-mutation).

**Aplicabilidad:** cualquier app multi-tenant con gestión de equipo generada con `add-teams`. Enforce: R16
+ R7 Layer 4; auditado por `el-guardian` (El Infiltrado). Doctrina:
`.claude/skills/add-teams/references/teams-model.md`. ADR: `[memory:decisions#D-029]`.

**Cita:** `[memory:lessons#L-006]`

## L-007 — Absorber la metodología, no la dependencia: la calidad se gana por doctrina sistémica, no acumulando herramientas

**Date:** 2026-06-30
**Context:** durante la Fase 4 Calidad (S4 + C1–C6) había fuerte presión a "portar todo": los 12 comandos +
12 subagents + autoresearch de Forge Pro, e instalar Ponytail, Graphify y las 817 Anthropic-Cybersecurity-
Skills. Medido contra la tesis del proyecto (**lección Vercel: -80% tools = +3× rendimiento**), eso habría
inflado la superficie y bajado el rendimiento — el anti-patrón exacto que Forge combate.

**Lesson:** ante un recurso externo o un activo de otro harness, la pregunta correcta NO es "¿lo porto/
instalo?" sino "¿cuál es la **metodología** destilable, y qué de eso ya cubre el sistema?". Patrón aplicado:
(1) **absorber la metodología, no la dependencia** — Ponytail → doctrina de minimalismo + eje en el-evaluador
(no el plugin); Graphify → spec de un gate opcional (no un store ni una dep dura); cybersec skills → protocolo
de vetting + subconjunto curado de referencias (no las 817). (2) **Consolidar antes de multiplicar** — 4
comandos de UI de Pro → 1 skill con modos (el-pulidor); mapear los solapes a lo que ya existe
(web-audit→web-quality) en vez de duplicar. (3) **Lo peligroso entra sólo capado** — autoresearch (un loop que
hace `git reset --hard`) se re-admite hidden + opt-in + con safety caps + juez independiente (AP3), nunca core
ni auto-invocable. (4) **La verificación adversarial gana su sueldo justo en lo destructivo** — los 6 hallazgos
de la fase estuvieron TODOS en autoresearch (discard que borraba un commit legítimo, guard sin re-chequeo de
rama): fan-out de escépticos > una sola pasada, sobre todo cuando el artefacto puede corromper el repo.

**Aplicabilidad:** toda decisión de "adoptar X externo" en el harness. Antídoto contra el bloat que
degrada el rendimiento del agente. Enforce: la doctrina de minimalismo (`references/MINIMALISM.md`) + el eje
que `el-evaluador` aplica. ADR: `[memory:decisions#D-030]`.

**Cita:** `[memory:lessons#L-007]`

## L-008 — Cerrar un Should es a veces reconciliar, no construir: verificá qué ya lo cubre antes de portar

**Date:** 2026-07-01
**Context:** al cerrar S3/S5, el roadmap listaba residuales ("tiering/explorer-fork" para S5; "infra de
migración" para S3) escritos ANTES de que otras fases avanzaran. Verificando contra el código real: el
*tiering* de S5 ya lo había entregado C6 (`MODEL_PER_ROLE.md`), y el *explorer-fork* ya existía en
`explorer.md` con marcas de confianza + `context:fork` documentado. Construir "lo que falta" al pie de la
letra habría duplicado C6 y habría forzado un fork real con Q-FORK-VER sin resolver (rompiendo la
degradación segura).

**Lesson:** un ítem de roadmap marcado 🚧 describe el estado **del día que se escribió**, no el de hoy.
Antes de construir para cerrarlo: (1) **releé el residual contra el código actual** — otra fase pudo haberlo
absorbido (aquí, C6 tapó el tiering de S5). (2) **Distinguí "falta infra" de "falta reconciliar"** — S3 sí
necesitaba build (runner net-new con gancho listo); S5 solo necesitaba cruzar referencias + formalizar una
opción ya presente. Cerrar ≠ siempre construir. (3) **Respetá los gates abiertos** — cuando una pieza
depende de una pregunta sin resolver (Q-FORK-VER), la cierre correcta es documentar la opción degradada a lo
seguro, no forzar la dependencia. (4) **Elegí la toolchain del anfitrión** — al portar el runner de Estudio
(Python) se reescribió en Node zero-dep para no meter una segunda toolchain (consistencia > fidelidad 1:1).

**Aplicabilidad:** todo cierre de backlog parcial y todo port desde otro harness. Antídoto contra construir
de más (duplicar lo ya hecho) y contra forzar dependencias no validadas. ADR: `[memory:decisions#D-031]`.
Emparenta con `[memory:lessons#L-007]` (absorber metodología, no dependencia).

**Cita:** `[memory:lessons#L-008]`

## L-009 — El self-report de un agente no es evidencia; validá el mecanismo por el harness/transcript

**Date:** 2026-07-01
**Context:** al validar Q-FORK-VER (¿`context: fork` despacha a un subagente?), se invocó `el-migrador` por
el Skill tool. El **harness** reportó "completed (**forked execution**)" y el **transcript** registró el
dispatch (`subagent_type` subió). Pero el **subagente**, en su respuesta, afirmó lo contrario: "esto cargó
inline, me estás leyendo directamente a mí". Confabuló: un subagente no percibe su propio límite de fork —
recibe un prompt y responde, así que "razona" que es inline. Si se le hubiera creído, se habría concluido
que el fork está roto (falso) y migrado 3 skills sin causa.

**Lesson:** cuando validás un MECANISMO del runtime (fork, dispatch, aislamiento de contexto, qué modelo
corrió, si un check pasó), la fuente de verdad es el **harness y el transcript**, nunca la introspección
del propio agente. Es exactamente la doctrina de `verificar-ci` extendida al harness: *"el `conclusion` lo
emite el sistema, el agente no puede fabricarlo"*. Corolario operativo: (1) para preguntas de mecanismo,
diseñá un test cuya evidencia sea observable desde afuera (label del tool, conteo en el `.jsonl`, exit code)
— no le preguntes al agente "¿te forkeaste?". (2) Desconfiá de la investigación que se apoya en docs/issues
viejos cuando podés correr el experimento real: acá la búsqueda web sospechaba "fork roto" (issues
#17283/#49559 de versiones viejas) y el test empírico probó lo contrario en 2.1.197.

**Aplicabilidad:** toda validación de comportamiento del runtime/harness (fork, subagentes, model-per-role,
gates de CI). Antídoto contra cerrar una pregunta técnica con el self-report de un agente. ADR:
`[memory:decisions#D-032]`. Emparenta con la doctrina de `verificar-ci` (AP5/AP8: árbitro independiente).

**Cita:** `[memory:lessons#L-009]`

<!-- L-010 onwards: populated as new lessons emerge -->

## L-010 — Un gate que grita y deja pasar es peor que no tenerlo: valida el enforcement de punta a punta, no en disco

**Date:** 2026-08-18
**Context:** el hallazgo mayor del handoff informatix (2026-08-18): los hooks del harness estaban
perfectos en disco y sus suites verdes, pero un `core.hooksPath` global (instalado por
`setup-identidades.sh`) reemplazaba el directorio de hooks completo en TODOS los repos de la máquina —
`commit-msg`/`post-commit` (R2/R5/R17) jamás corrían, y el pre-commit global descartaba el exit code
del local: R15 imprimió una violación de `sk_live_` en rojo y el commit **entró igual**. Meses de
"enforcement activo" que en la práctica era decorativo, produciendo confianza falsa (peor que la
ausencia del gate, porque nadie busca lo que cree tener).

**Lesson:** la unidad de verificación de un gate NO es "el hook existe y su test pasa en sandbox" —
es **un commit real atravesando git en ESTA máquina y siendo rechazado**. Todo entorno tiene capas
que pueden interceptar el enforcement (hooksPath global, wrappers, CI que no corre el job). Corolarios:
(1) tras instalar/cambiar hooks, probar con una violación deliberada end-to-end; (2) configuración
global de máquina es parte de la superficie del harness → `/temple --harness` la audita
(`QUALITY_GATES.md` §3); (3) un dispatcher global debe PROPAGAR exit codes y delegar cada hook, no
solo el que le interesa. Es el gemelo de L-009 (validar por el harness, no por el self-report) aplicado
al enforcement: valida por el efecto observado, no por la presencia del artefacto.

## L-011 — El sesgo de un juez vive en el formato del turno, no en el texto: aislar por construcción, no por prompt

**Date:** 2026-09-02
**Context:** al integrar el proceso de diseño de Anshu (D-037) apareció la tentación obvia — pedirle a
`el-pulidor` "sé objetivo, juzgá tu diseño como un estudio top". Khullar, Hopkins, Wang y Roger (2026,
*Self-Attribution Bias*, arXiv 2603.04582) miden justo eso: decirle al monitor "esto lo hizo tu mismo
modelo" NO induce el sesgo; poner la acción en un turno assistant anterior, SÍ (hasta ~5× más laxo
aprobando un patch que siguió un prompt injection). El mismo mecanismo que Anshu resuelve a mano
(screenshot + contexto vacío + modelo caro) y que Forja ya tenía escrito para seguridad (AP3, D-033,
`QUALITY_GATES.md` §2) pero no para estética.

**Lesson:** un juez que ve el hilo del generador deja de ser juez y se vuelve abogado — sin importar
cuán "objetivo" le pidas ser. La independencia se garantiza **estructuralmente**: (1) subagente nuevo por
cada juicio, con SOLO el artefacto (screenshot, diff) en un turno *user*; (2) tool filter sin capacidad de
mutar ni de "explorar un momento" (`Read, Bash` para el crítico visual — sin Grep/Glob); (3) el criterio
de parada fuera del prompt del juez, en el orquestador, para no anclarlo; (4) ranking pairwise en vez de
score absoluto (los /10 driftean e inflan). Corolario para todo Forja: cuando una doctrina dice "quien
audita no edita" (AP3), la unidad de verificación es la whitelist del agente y el transcript del fork
(L-009), no la frase en el SKILL.md. Gemelo de L-010 aplicado al juicio: valida por el mecanismo, no por
la promesa.
