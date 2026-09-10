# Forja — Constraints

> Reglas duras. Enforcement automático cuando sea posible (hooks), validación humana cuando no. Para diseño/justificación ver `ARCHITECTURE.md`.

## Reglas universales

### R1 — WIP=1

Solo una feature puede estar en estado `active` en `feature_list.json` simultáneamente.

- **Enforcement:** hook `pre-commit` lee `feature_list.json`, rechaza commit si hay >1 active.
- **Workaround:** mover una a `blocked` antes de activar otra.
- **Source:** walkinglabs L07 — empíricamente +37% completion rate vs WIP unlimited.

### R2 — Atomic commits + Conventional Commits

Cada commit toca una feature, con mensaje en formato:

```
<type>(<scope>): <description>
```

- **Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`, `ci`, `build`, `evaluator`, `memory`, `spec` (R19 — commits que tocan el spec)
- **Scope:** ID de feature, componente, o ID de memory entry. Case-insensitive alfanum + guiones (`F2-S7`, `D-003`, `E-001`, `auth`, `ui-kit`, `state`, etc.)
- **Description:** ≥10 chars, imperativo, sin punto final.
- **Enforcement:** hook `scripts/hooks/commit-msg` rechaza si no matchea regex `^(feat|fix|refactor|chore|docs|test|style|perf|ci|build|evaluator|memory|spec)\(([A-Za-z0-9-]+)\): .{10,}$` (type `spec` — R19). Skipea Merge/Revert/fixup!/squash!.
- **Source:** Forge legacy + Conventional Commits spec; extendido por D-003 (Fase 4) para soportar shapes `evaluator(D-NNN)` y `memory(E-NNN)` requeridos por R5.

### R3 — Active feature resolution

```bash
# 1. Try git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ "$BRANCH" =~ ^(feature|fix|refactor|chore|docs)/.+$ ]]; then
  ACTIVE_FEATURE="${BRANCH#*/}"
# 2. Fallback to .forja/HEAD
elif [ -f .forja/HEAD ]; then
  ACTIVE_FEATURE=$(cat .forja/HEAD)
# 3. No active feature
else
  echo "ERROR: no active feature. Set branch matching feature/* or write .forja/HEAD"
  exit 1
fi
```

- **Source:** relay-kit. Branch como source-of-truth elimina corrupción de archivo de estado.

### R4 — Orchestrator stays thin

El orchestrator (Coordinator, La Forja root, el-tajo, el-golpe) NUNCA invoca un skill directamente. Solo dispatch a sub-agentes.

- ✅ Orchestrator: lee feature, decide qué sub-agent, delega.
- ✅ Sub-agent: invoca skill apropiado.
- ❌ Orchestrator que escribe código directamente (anti-pattern: "fat orchestrator").

- **Enforcement:** review en `el-evaluador` — si orchestrator output incluye edits a archivos de producción, fail.
- **Source:** relay-kit `implementer.md`.

### R5 — el-evaluador es sole writer del memory store

Solo el skill `el-evaluador` puede escribir a archivos en `.claude/memory/*.md`.

- ✅ Otros agentes leen con citation grammar `[memory:file#anchor]`.
- ❌ Otros agentes escriben directamente.

- **Enforcement:** hook `pre-commit` valida que diffs en `.claude/memory/` solo vengan de commits con scope `evaluator` o `memory`.
- **Source:** relay-kit reviewer pattern. Single-writer evita race conditions y duplicados.

### R6 — Skill dispatch validates registry

Antes de invocar cualquier skill, el dispatcher valida que el nombre exista en `.claude/memory/skills.md`.

```
1. Lee .claude/memory/skills.md
2. Busca el skill por nombre exacto
3. Si no existe → fallback definido en registry, o halt
4. Si existe → valida `requiere` (preconditions)
5. Dispatch
```

- **Enforcement:** validación en el orchestrator de cada multi-agent pattern.
- **Source:** relay-kit `memory/skills.md` + E-001 en errores ("skill invocado sin validar registry").

### R7 — Three-Layer Verification, no skip

Para marcar feature `passing`:

| Layer | Comando | Pass criteria |
|-------|---------|---------------|
| 1. Syntax | `make typecheck && make lint` | exit 0 |
| 2. Runtime | `make test` | exit 0, sin warnings críticos |
| 3. System | `make e2e` | happy path verde + visual diff vs brand.json verde |
| 4. Tenant (sólo multi-tenant, M6) | test negativo cross-tenant sobre DB real (`tenancy-isolation.test.sql`, ≥2 tenants) | aislamiento verde: tenant A no lee/escribe datos de B |

- **Enforcement:** `el-evaluador` verifica las capas en orden. Si layer N falla, layer N+1 ni se intenta.
- **No bypass.** Aún en hotfix, las capas corren (puede simplificarse el system test pero no eliminarse).
- **Layer 4 (M6)** sólo aplica si la app es multi-tenant (`tenant_model.multi_tenant: true`); en single-tenant no existe (degradación segura). Es el "criterio de listo para liberar" del multi-tenant — ver R16 + `[memory:lessons#L-005]`.
- **Source:** walkinglabs L09; Layer 4 = `docs/06` §12 (M6).

### R8 — Web claims requieren citación

Cualquier afirmación basada en información externa requiere citación inline + sección Sources.

```markdown
agent-browser ofrece ~4× ahorro de tokens [web:ytyng.com](https://www.ytyng.com/en/blog/ai-browser-automation-tools-comparison-2026).

## Sources
- [agent-browser comparison 2026](https://www.ytyng.com/en/blog/ai-browser-automation-tools-comparison-2026)
```

- **Enforcement:** `el-evaluador` rechaza output sin Sources cuando hay claims externos.
- **Promoción:** URLs útiles (citadas en >2 sesiones) las promueve `el-evaluador` a `references.md`.
- **Source:** relay-kit research-citation grammar.

### R9 — Memory citations

Referencias a memoria interna usan `[memory:file#anchor]`:

- `[memory:lessons#L-001]`
- `[memory:errors#E-005]`
- `[memory:decisions#D-012]`

- **Source:** relay-kit citation grammar.

### R10 — Brand DNA es contrato no-negociable

Antes de generar cualquier componente UI:

1. Lee `brand/brand.json`
2. Lee `brand/voice.json`
3. Aplica tokens, posture, archetype, anti-slop rules

- ❌ Generar UI sin leer brand → automático reject por `el-evaluador`.
- ❌ Override brand tokens "por estética" → reject.
- ✅ Override solo si conflicto con accesibilidad (gana accesibilidad, ver schema sección 8.1).

- **Source:** D9 Brand DNA contract.

## Bootstrap Contract (R11)

`/build` no se permite hasta que:

```
[ ] make setup exit 0
[ ] ≥1 test passing
[ ] feature_list.json con ≥3 features con verification command
[ ] .claude/memory/skills.md generado y validado
[ ] brand/brand.json + voice.json existen
```

- **Enforcement:** comando `/build` corre preflight, halt con mensaje exacto si alguno falla.

## Clean-State Exit (R12)

Sesión NO termina hasta:

```
[ ] make build exit 0
[ ] make test exit 0
[ ] PROGRESS.md actualizado con resumen de sesión
[ ] git status clean (o uncommitted changes son WIP intencional documentado)
[ ] Próximo paso definido en feature_list.json o PROGRESS.md
```

- Si falla → rollback al último estado consistente con `git reset --hard HEAD`. No commits a medio camino.
- **Source:** walkinglabs L12.

## External docs citation (R13)

Web claims sobre libs externas requieren citation grammar:

- `[docs:libname]` o `[docs:libname@version]` cuando vienen de Context7 (vía skill `find-docs`).
- `[web:dominio.com](url)` cuando vienen de fuente abierta (WebFetch fallback).

Claims sobre sintaxis o API de libs externas SIN citation = automatic reject por `el-evaluador`.

Aplica a cualquier output de skill que genere código contra libs externas (no aplica a sintaxis JS/TS estándar). Cubre imports, API calls, config keys, CLI commands.

Ejemplo válido:
```markdown
Vercel AI SDK v5 streamText acepta `tools` como objeto con `describe + execute`
[docs:vercel-ai-sdk@v5], no como array (v4).
```

Ejemplo inválido (reject):
```markdown
Para Stripe Checkout usá session.create con line_items.
```
(falta `[docs:stripe]` o `[web:stripe.com](url)`)

- **Source:** D4 + decisión adicional 2026-05-07 (Context7 identificado como gap después de Fase 2 cerrada).
- **Applicability:** cualquier output de skill que use código contra libs externas.
- **Expiry:** never.

## Destructive tools requieren confirmación humana (R14)

Tools agentic con efectos destructivos NO se definen con `execute()` automático. La tool define la operación y los argumentos; la confirmación final pasa por humano (UI prompt, CLI prompt, o explicit reply en chat).

Operaciones cubiertas (lista no exhaustiva):
- `delete*` (deleteUser, deleteRecord, dropTable…)
- `send*` (sendEmail, sendSMS, sendNotification…)
- `transfer*` / `pay*` / `refund*` (cualquier movimiento de dinero)
- `cancel*` (subscriptions, orders, deploys)
- `deploy*` / `force*` (infra changes irreversibles)

```typescript
// ❌ NO — execute automático en destructiva
export const deleteUser = tool({
  description: 'Elimina un usuario',
  inputSchema: z.object({ userId: z.string() }),
  execute: async ({ userId }) => { /* destructive */ },
})

// ✅ SÍ — sin execute → SDK pausa esperando confirmación
export const deleteUser = tool({
  description: 'Elimina un usuario — REQUIERE CONFIRMACIÓN MANUAL',
  inputSchema: z.object({ userId: z.string() }),
  // sin execute()
})
```

- **Enforcement:** `el-evaluador` rechaza skill outputs que generen tools destructivas con `execute()`. `el-guardian` audita pre-deploy.
- **Source:** L-001..L-003 promotion + 05-tools-funciones template + L-002 (un LLM influenced by indirect prompt injection nunca debe activar destructivas sin humano in the loop).
- **Applicability:** cualquier output de skill que defina agentic tools con efectos en sistemas externos (DB, APIs, infra, mensajería).
- **Expiry:** never (regla universal).

## No secrets en commits — scan fail-closed (R15)

Ningún commit puede introducir secrets hardcodeados. El hook `pre-commit` escanea los archivos
*staged* y, a diferencia del `security-scan.sh` de Forge Pro (que era **fail-open** — ante error,
aprobaba), el de Forja es **fail-closed**: un secret detectado **aborta el commit**.

- **Detecta (bloquea):** AWS keys (`AKIA…`), API keys/tokens (`sk-…`, `pk_live_`, `sk_live_`, `sk_test_`), asignaciones `password|secret|api_key|access_token|private_key = "…"` (excluyendo `process.env`/`YOUR_`/`CHANGE_ME`/`example`/`placeholder`/`${…}`), y JWT crudos fuera de `.env`.
- **Advierte (no bloquea):** `console.*` con datos sensibles, CORS wildcard, `dangerouslySetInnerHTML`.
- **Excluye** la tooling de seguridad que documenta patrones (`threat-db.yaml`, los hooks, `project-auditor`, `el-guardian`, los `references/security-*`) para no auto-bloquearse.
- **Patrones:** los mismos `golden_path_check` con `automated: true` de `threat-db.yaml`.
- **Enforcement:** `scripts/hooks/pre-commit` (instalado por `make install-hooks`). `set -euo pipefail` ⇒ fail-closed también ante error del scan. NO usar `--no-verify` (AP2).
- **Source:** port de `security-scan.sh` (Forge Pro v5.1.0) reencuadrado fail-closed — `docs/06` §4 S1.
- **Applicability:** todo commit en un repo Forja. **Expiry:** never.

## Aislamiento de tenant en apps multi-tenant (R16)

En una app multi-tenant (`tenant_model.multi_tenant: true`), el aislamiento entre organizaciones lo
enforce **Postgres (RLS), no el código**. Generaliza `[memory:lessons#L-001]` (single-tenant) a
`[memory:lessons#L-005]` (por tenant). **Tres invariantes no-negociables:**

1. **Toda tabla tenant-scoped lleva `organization_id NOT NULL`** con FK a `organizations(id) on delete cascade` (la identidad global — `profiles` — NO; la pertenencia vive en `memberships`).
2. **Toda policy de escritura tiene `WITH CHECK`** con el predicado de tenant (no sólo `USING`) — sin esto un member mueve filas a otra org (IDOR cross-tenant).
3. **El `organization_id` del cliente nunca se confía** — lo valida `WITH CHECK` contra la membresía real; el server jamás lo lee del body y lo inserta sin que RLS lo verifique.

- **Enforcement:** `el-migrador` valida los 3 invariantes en su pre-validation pipeline; `el-guardian` los audita con el persona **El Infiltrado** (Capa 3) cruzando el modelo de amenazas T1–T9; el test negativo cross-tenant es el R7 Layer 4. Doctrina + template: `.claude/references/MULTI_TENANCY.md`.
- **Degradación segura:** si la app es single-tenant (`tenant_model.multi_tenant: false` o ausente), R16 no aplica — gobierna `[memory:lessons#L-001]` (`auth.uid() = user_id`).
- **Source:** `docs/06` §4 M6 + §9-B (B1) · `[memory:decisions#D-028]`. **Applicability:** apps generadas multi-tenant. **Expiry:** cuando cambie el modelo de tenancy del Golden Path.

## El plano de control es parte del commit atómico (R17 · R-plan)

El plano de control (`.plan/`) — la capa de gestión bidireccional (humano por UI / agente por FS) — se
mantiene **vivo y consistente en cada commit atómico**, no como artefacto aparte. Generaliza el
Clean-State Exit (R12) al plano. Contrato del artefacto: `.claude/references/PLAN_SCHEMA.md`.

- **Disciplina del agente:** al cambiar el estado de una story, registrar capturas de Playwright o
  resultados de tests, el agente **escribe un evento** (`POST /api/event` si el `plan-server` corre, o
  append directo a `activity.log.jsonl` + edición de `plan.json` con lock si no). Antes del Clean-State
  Exit verifica que `plan.json` refleja el estado real y que no hay eventos `commit:null` sin sellar.
- **Enforcement por hook:** `post-commit` sella cada evento con el hash del commit (trazabilidad por
  grep) y valida los dos JSON; si algo no parsea, deja `.plan/.inconsistent`. `pre-commit` es
  **fail-closed**: aborta si `plan.json` no parsea o si existe ese marcador.
- **Frontera (no cruzar):** el plano **LEE** `feature_list.json` por `featureRefs[]` y lo refleja
  read-only; **NUNCA lo escribe** (las transiciones de build las gobiernan los hooks — R1, ADR D1).
- **Degradación segura:** si el proyecto no tiene `.plan/`, R17 no aplica (los hooks se saltan el guard).
- **Source:** `docs/07` Punto 3 (§5) + A1. **Applicability:** proyectos con plano de control. **Expiry:** cuando cambie el modelo de sincronización del plano.

## GitHub es un espejo de una sola vía (R18)

La gobernanza de equipo es **GitHub-native** (CODEOWNERS, branch protection, PR/Issue templates, sync),
pero la autoridad sobre las transiciones de build **no se delega a GitHub**: la state machine
`feature_list.json` + los hooks (R1 WIP=1, AP8, R7 — ADR D1) son, y siguen siendo, la **única fuente de
verdad**. GitHub (Issues, PRs, project boards) es una **proyección read-only** de esa verdad, nunca su origen.

- ✅ `feature_list.json` / `plan.json` → **se reflejan** en Issues, labels, CODEOWNERS y PR body (una vía).
- ❌ **Cerrar un Issue, mergear un PR o mover una card NO marca una feature `passing`** ni muta
  `feature_list.json`. Esa transición la gobiernan los hooks (R1 + AP8 + R7), no un webhook de GitHub.
  Reintroducir "transiciones por UI/GitHub" es exactamente lo que D1 prohíbe.
- ❌ `el-capataz` (el skill de gobernanza) **nunca escribe** `feature_list.json` ni `.claude/memory/**`
  (R5). Sólo los **lee** para proyectarlos. El único writer del estado de build es `el-evaluador`.
- El sync **cierra** el Issue de una feature *cuando ya está* `passing` en el JSON (efecto, no causa).
- **Refuerzo, no reemplazo de A2:** branch protection exige los `ci_run` checks de A2 como required status
  checks → GitHub **bloquea el merge** sin CI verde, igual que AP8 bloquea el commit local. Dos capas que
  apuntan al mismo árbitro (el `conclusion` de GitHub), no a la palabra del agente.
- **Enforcement:** el tool filter de `el-capataz` (Write/Edit sólo en `.github/**` + `.forja/team.json`;
  prohibido `feature_list.json` y `.claude/memory/**`); `el-evaluador` como sole writer del estado; branch
  protection del lado remoto. Doctrina + procedimiento: `.claude/skills/el-capataz/references/github-native.md`.
- **Degradación segura:** sin `gh`/remote/CI, `el-capataz` degrada a setup manual documentado y advierte; el
  gobierno local (R1/AP8/hooks) sigue vigente. Materializa la decisión `[ARCHITECTURE.md#D12]` (S2 · `[memory:decisions#D-029]`).
- **Source:** `docs/06` §S2 + `docs/07` §7.5 + `01` §5.2 (D12). **Applicability:** repos con gobernanza
  de equipo GitHub-native. **Expiry:** cuando cambie el modelo de sincronización GitHub↔state machine.

## El humano es dueño del SPEC; la IA es dueña del código (R19)

La frontera de propiedad es **bidireccional y no-negociable**. Motivo: en dogfooding real, lo que el
agente "olvida" o "deja pasar" es casi siempre contrato que nunca quedó en el spec, o spec que el agente
mutó de paso durante el build sin que el humano lo viera.

- **El SPEC es del humano.** `SPEC.md`, `CONTEXT.md` y `docs/adr/**` capturan QUÉ se construye y por qué.
  La IA ayuda a redactarlos (grill-me de `el-entrevistador`, Fase 0) pregunta por pregunta, pero **cada
  sección entra sólo con aprobación explícita del humano**. Cerrada la Fase 0, la IA **no los edita
  unilateralmente**: un cambio de spec es una re-entrada a `/descubrir` (sesión de re-spec con el humano),
  nunca un edit de paso durante el build. Si el build descubre que el spec está mal → **halt + surfacear**,
  no "arreglar" el spec para que coincida con el código.
- **El código es de la IA.** El canal del humano hacia el código es el spec + el review — no el editor.
  Si el humano parchea código a mano, el spec y el código dejan de derivar uno del otro y el agente pierde
  la trazabilidad de qué generó y qué no. (Hotfix humano excepcional → registrarlo como evento en `.plan/`
  y reconciliar el spec en la siguiente sesión.)
- **Enforcement por hooks:**
  - `pre-commit`: un commit **no mezcla** spec (`SPEC.md` / `CONTEXT.md` / `docs/adr/**`) con código de
    aplicación (`src/**`, `app/**`, `lib/**`, `components/**`, `supabase/**`, `pages/**`). El spec cambia
    en su propio commit atómico (R2).
  - `commit-msg`: un commit que toca spec lleva type o scope `spec` — deja rastro grep-able de cada cambio
    de contrato, análogo a R5 para memoria. El diff de `git log --follow SPEC.md` ES la historia del contrato.
- **Degradación segura:** proyectos sin `SPEC.md` staged no gatillan ningún guard.
- **Source:** feedback dogfooding 2026-08-18 (punto 2) — retoma la premisa SpecFounder. **Applicability:**
  proyectos con Fase 0. **Expiry:** cuando cambie el modelo de fases.

---

## Seguridad shift-left (DevSecOps atado a la ontología) — A3

La seguridad **no es un `el-guardian` al final**: son **gates por fase** que consumen el mismo
contrato — `ONTOLOGY.md › requisitos_seguridad` (Fase −1) + `SPEC.md` Sección 6 (Fase 0) + la
`threat-db.yaml` (catálogo genérico). De más temprano (shift-left) a más tardío:

| Fase | Gate | Qué hace | Bloquea |
|------|------|----------|---------|
| **−1** Ontología | `el-ontologo` | captura `requisitos_seguridad` (el contrato de la empresa) | — (lo levanta) |
| **0** Spec | `el-entrevistador` | Sección 6 (No Funcionales) deriva del contrato | — (lo formaliza) |
| **commit** | hook `pre-commit` (R15) | secrets scan fail-closed sobre staged | ✅ secrets |
| **pre-Blueprint** | `la-herreria` asset #9 | threat-db + contrato; bloquea el Blueprint ante críticos; cross-tenant design (M6) | ✅ critical/high |
| **build** (multi-tenant, M6) | `el-migrador` + R7 Layer 4 | 3 invariantes de tenant (R16) + test negativo cross-tenant sobre DB real (≥2 tenants) | ✅ leak cross-tenant |
| **pre-deploy** | `el-guardian` (Codex, 4 modos + El Infiltrado si multi-tenant) | auditoría adversarial de la feature activa | ✅ critical/high |
| **pre-release** | `/temple` (`project-auditor`) | audit full-project + Audit Score; bloquea ante críticos | ✅ critical / requisito_seguridad crítico |
| **CI** (A2) | `ci.yml` + `security.yml` + `/verificar-ci` | el mismo scan como required check remoto; AP8 fail-closed (no `passing` sin `ci_run.conclusion == "success"`) | ✅ critical + CI rojo |

- **Regla común:** un `requisito_seguridad: critico` del contrato no satisfecho es Critical en TODOS los gates, aunque el catálogo genérico no lo marque. El catálogo es genérico; el contrato es propio de la empresa.
- **Degradación segura:** si no hay `ONTOLOGY.md`/`SPEC.md`, los gates operan solo con el catálogo genérico (no fallan por ausencia de contrato). El gate de tenant sólo corre si la app es multi-tenant.
- **Source:** `docs/06` §4 A3 + §10 paso 4 + S1 · §12 M6. **Applicability:** todo proyecto generado con Forja. **Expiry:** cuando cambie la arquitectura de fases.

## Anti-patterns prohibidos (lecciones acumuladas)

### AP1 — Mocks en tests de integración

Si el test toca DB, debe hablar con DB real (Supabase local o test branch). Mocks pasan tests pero rompen migraciones en prod.

### AP2 — `--no-verify` para skipear hooks

Nunca. Si un hook falla, fix the underlying issue, no skipees.

### AP3 — Self-eval del agente generador

El agente que genera NO valida. Siempre `el-evaluador` separado.

### AP4 — Tools "por si acaso" en MCP

Cada tool en `example.mcp.json` justifica su existencia con uso real. Auditoría trimestral, eliminar las no usadas.

### AP5 — Narrative completion ("ya está listo")

Solo `verification_command exit 0` cuenta. Texto del agente diciendo "lo terminé" sin evidencia → reject.

### AP6 — Diseño "Claude default"

Tailwind purple-500 + Inter + 3 cards centradas + gradiente diagonal = automatic reject. Brand DNA gate.

### AP7 — CLAUDE.md gigante

Routing file <200 líneas. Knowledge fuera (`ARCHITECTURE.md`, `CONSTRAINTS.md`, skills).

### AP8 — `passing` sin CI verde (entrega no validada)

Una feature **NO** pasa a `passing` mientras el check-run del commit HEAD no sea `conclusion == "success"`.
El texto del agente ("CI debería pasar", "lo terminé") no cuenta — es la extensión de AP5 (narrative
completion) al plano de CI: el `exit 0` ya no lo declara el agente en su máquina, lo certifica un runner
remoto independiente (GitHub) cuyo `conclusion` el agente no puede fabricar.

- **Doble condición para `active → passing`:** (i) `verification_command` local exit 0 (R7, ya existe)
  **y** (ii) `ci_run.conclusion == "success"` (nuevo). El campo `ci_run` (`{run_id, sha, conclusion, url}`)
  se registra en `feature_list.json` como **evidencia citable** `[ci:run#<id>]`. Lo obtiene `/verificar-ci`
  (`gh api .../check-runs`), lo escribe `el-evaluador`.
- **Enforcement (fail-closed, estilo Forja):** el `pre-commit` rechaza un commit que marque una feature
  `state: passing` si su `ci_run.conclusion != "success"`. Gateado por la presencia de
  `.github/workflows/ci.yml` (degradación segura: sin CI configurado, gobierna sólo R7 local).
- **Source:** `docs/07` Punto 4 (§3.b–§3.c) + A2. Cierra el gate **CI** de la doctrina DevSecOps (A3).
  **Applicability:** apps generadas con CI. **Expiry:** cuando cambie el modelo de verificación remota.

### AP9 — Gasto externo sin confirm (imagen / video / estudios que cobran por escena)

El agente **no dispara** generación de pago (fal.ai, Higgsfield / Forge Studio en el Mac mini vía Tailscale
MCP, Kie.ai, APIs de imagen con key) por iniciativa propia ni "para probar una vez". El loop de crítico +
"encontrá un modelo reciente" es la receta perfecta para 30 s a 720p en bucle.

- **Default = dry-run:** sin key en `.env.agents` (gitignored, plantilla `.env.agents.example`) o sin
  autorización, se escribe el storyboard / `enrich-plan.md` y se para. El resto del loop de diseño no falla.
- **Gasto real solo con frase explícita del humano en el turno** ("autorizo gasto fal.ai…", "autorizo UN
  job Higgsfield…"), **un job por autorización**, spend cap del archivo, y registro en `.plan/decisions[]`
  + `design-lab/<run>/COST.md`. Sin la frase no hay llamada MCP ni API.
- **Keys:** solo en `.env.agents`; el agente lee el path, nunca imprime ni commitea la key (R15 fail-closed),
  nunca la pide "para guardarla en el repo". Nunca en el producto.
- **A11y gana:** todo enrich pasa el gate de `references/DESIGN_ENRICH.md` §3 (`prefers-reduced-motion`,
  pause on-page WCAG 2.2.2, autoplay muted + poster). Si lo rompe, se revierte.
- **Source:** Anshu Chimala (Lenny's, 2026-09-01) Técnicas 4–5 + amplificación A9/A11 + D-037.
  **Applicability:** cualquier agente con acceso a herramientas de imagen/video. **Expiry:** never (es dinero).

