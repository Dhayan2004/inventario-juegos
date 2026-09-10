---
name: project-auditor
context: fork
description: "Auditoría full-project (TODO src/, no solo el diff) en 4 dimensiones — Seguridad, Datos/RLS, Cache & Rendimiento, Calidad Web — con UN reporte priorizado y un Audit Score compuesto (0-100). Cruza la threat-db (85 amenazas, corre sus golden_path_check como ripgrep) + los requisitos_seguridad de ONTOLOGY.md + la Sección 6 del SPEC, consulta get_advisors de Supabase, y delega calidad web a web-quality. Es el gate de seguridad PRE-RELEASE (full-project), complementario a el-guardian (feature-diff). Úsalo cuando el usuario pida 'audita todo el proyecto', 'auditoría completa', '¿está listo para producción?', o ejecute /temple."
allowed-tools: Read, Grep, Glob, Bash, Task
tier: core
requires: raíz del proyecto accesible. Supabase MCP y Codex (para --deep) son opcionales (degradación segura).
fallback: sin Supabase MCP → no penaliza lo no observable; sin Codex → omite la capa --deep.
dependencies: [web-quality, el-guardian]
metadata:
  author: forge-enterprise
  ported_from: "forge-pro@5.1.0"
  version: "1.1.0-fe"
---

# Project Auditor — Auditoría Full-Project (motor de `/temple`)

> *"El herrero no entrega la pieza por verla brillar. La templa, la golpea, y mide si aguanta."*

## Propósito

Un solo comando (`/temple`) que audita **TODO el proyecto** — ripgrep sobre `src/` completo, no
solo el diff — en 4 dimensiones y entrega **un reporte priorizado con un Audit Score compuesto**. Es
el gate de seguridad **pre-release** de la doctrina shift-left de Forge Enterprise (`CONSTRAINTS.md`
§ DevSecOps): el último filtro antes de soltar a producción.

**Reutiliza piezas que ya existen en Forja — NO duplica su lógica:**

- **threat-db.yaml** (`.claude/skills/la-herreria/references/threat-db.yaml`, 85 amenazas — incluye `payments` PAY-001..008) — corre cada `golden_path_check` automatizable como ripgrep; para pagos, el ejecutable canónico es `.claude/skills/add-payments/tests/payments-gate.sh <dir>`.
- **hook `pre-commit`** (`scripts/hooks/pre-commit`, sección secrets R15) — mismos regex de secrets, pero full-project (el hook solo mira staged).
- **web-quality skill** — la dimensión Calidad Web se delega ahí.
- **baas / Supabase MCP** — `get_advisors(type:"security"|"performance")`.
- **el-guardian** — la capa adversarial `--deep` (Codex como segundo cerebro).

> **Diferencia con `el-guardian`:** `el-guardian` audita la **feature activa (el diff)** pre-deploy
> con Codex; `project-auditor`/`/temple` audita **TODO `src/`** pre-release con score compuesto. Son
> complementarios — el guardián vigila cada feature; el temple, el proyecto entero antes de soltar.

## El contrato que consume (atado a la ontología — el diferenciador)

Antes de puntuar, carga el **contrato de seguridad de la empresa** (si existe; degradación segura si no):

1. **`ONTOLOGY.md › requisitos_seguridad`** (Fase −1) — los requisitos específicos del negocio
   (regulaciones, datos sensibles). **Cada `requisito` con `severidad: critico` que NO esté satisfecho
   en el código es un hallazgo `critical` automático** — aunque la threat-db genérica no lo marque.
2. **`SPEC.md` Sección 6 (Requisitos No Funcionales)** (Fase 0) — datos sensibles, hosting/región, SLAs.

La threat-db es el catálogo **genérico**; el contrato es lo **específico de esta empresa**. El audit
cruza ambos. Reportar cobertura del contrato: `requisitos_seguridad verificados: X/N`.

## Cuándo activarse

- Usuario ejecuta `/temple` (full / `quick` / `security` / `datos` / `cache` / `web` / `compare` / `--deep` / `--harness`).
- Usuario pregunta: "¿está listo para producción?", "audita todo el proyecto", "revisa seguridad y performance".
- **NO** para revisar solo el diff de una feature — eso es `el-guardian` (pre-deploy adversarial).

### Modo `--harness` — auditar el harness mismo (doctrina AgentShield)

Fuera del Audit Score (no puntúa la app): audita la **herramienta** con el checklist de
[`QUALITY_GATES.md §3`](../../references/QUALITY_GATES.md) — (1) hooks vivos DE VERDAD (suite verde +
commit de prueba en sandbox que confirme que git los ejecuta; un `core.hooksPath` global puede
apagarlos todos sin que nada avise), (2) tool-filters de forks intactos (`fork-agents.test.sh`),
(3) superficie de prompt-injection en skills que consumen contenido externo, (4) diff de
`.claude/settings.json` + MCP servers contra el último snapshot auditado (CYBERSEC_VETTING),
(5) R15 sobre el propio `.claude/`. Cadencia: pre-release y tras tocar hooks/agents/MCP.

## Las 4 Dimensiones

### 🔒 Dimensión 1 — Seguridad (peso 30%)

Cruza la threat-db + el contrato de la empresa y corre los checks automatizables sobre `src/` completo.

1. **Contrato primero (ontología/spec):** por cada `ONTOLOGY.md › requisitos_seguridad[]`, verificar
   que el código lo satisface. Requisito `critico` no satisfecho → hallazgo `critical`. Si no hay
   `ONTOLOGY.md`, saltar este paso (no penalizar) y anotar "sin contrato de empresa — solo catálogo genérico".
2. **threat-db:** leer `.claude/skills/la-herreria/references/threat-db.yaml`. Para cada threat cuyo
   `golden_path_check` sea un `grep`/`grep -r`/`grep -rE`, correrlo como ripgrep sobre `src/`. Checks
   clave (verbatim de la threat-db):

   | id | severity | ripgrep |
   |----|----------|---------|
   | GP-008 service_role en client | critical | `rg -n 'service_role\|SUPABASE_SERVICE' src/` → flag si NO está en archivo server-only |
   | GP-006 API key IA en bundle | critical | `rg -n 'OPENROUTER\|OPENAI\|ANTHROPIC' src/` → flag fuera de server |
   | OWASP-A01-002 userId del cliente confiado | critical | `rg -n 'body\.userId\|req\.query\.userId\|params\.userId' src/` |
   | OWASP-A03-001 SQL injection por interpolación | critical | `rg -nE 'execute_sql.*\$\{\|rpc.*\+' src/` |
   | OWASP-A03-003 command injection | critical | `rg -nE '(exec\|spawn\|execSync)\(' src/app src/features` |
   | OWASP-A02-001 secrets en localStorage | high | `rg -n 'localStorage' src/ \| rg -i 'token\|auth\|session\|key'` |
   | OWASP-A02-002 secrets en console | high | `rg -ni 'console\.log' src/ \| rg -i 'token\|password\|secret\|key'` |
   | OWASP-A03-002 XSS innerHTML | high | `rg -n 'dangerouslySetInnerHTML' src/` |
   | OWASP-A07-001 getSession en data code | high | `rg -n 'getSession' src/` → solo debe aparecer en middleware |
   | OWASP-A10-001 SSRF | high | `rg -nE 'fetch\(.*req\.\|fetch\(.*body\.' src/app` |
   | GP-011 Supabase URL hardcoded | high | `rg -n 'supabase\.co' src/` → solo `process.env` |
   | BLOG-001 CORS wildcard | high | `rg -nE "Access-Control-Allow-Origin.*['\"]\*['\"]" src/ next.config.ts` |
   | PRIV-006 PII en URL | medium | `rg -nE 'router\.push.*(token\|email)' src/` |

3. **Secrets full-project** (mismos patrones que el hook `pre-commit` R15, sobre TODO `src/`):
   `AKIA[0-9A-Z]{16}`, `(sk-[a-zA-Z0-9]{20,}\|pk_live_\|sk_live_\|sk_test_)`, asignaciones
   `(password|secret|api_key|access_token|private_key) = "…"` (excluir `process.env`, `YOUR_`,
   `CHANGE_ME`, `example`, `placeholder`), y JWT crudos fuera de `.env`.
4. **R14 destructivas:** `rg -nE "tool\(\{[^}]*execute:" src/ | rg -iE "delete|send|transfer|cancel|refund"`
   → si hay `execute()` automático en destructiva sin confirmación → `critical` (R14).
5. **Categorías CRITICAL full-project:** glob `src/app/api/**/route.ts` y verificar `getUser()`/auth
   antes de tocar datos; `"use client"` con imports de secrets; `as` casts sin validación Zod.

**Sub-score 0-100:** empezar en 100. Por hallazgo: `critical −20`, `high −10`, `medium −4`, `low −1`.
Floor 0. Reportar cobertura: `threats automatizables corridos: X/N` + `requisitos_seguridad: X/N`.

### 🗄️ Dimensión 2 — Datos & Supabase/RLS (peso 25%)

1. **Supabase conectado (MCP):** `get_advisors(type:"security")` → tablas sin RLS + políticas
   permisivas; `get_advisors(type:"performance")` → índices faltantes (alimenta también Cache).
2. **InsForge** (`NEXT_PUBLIC_INSFORGE_URL` en `.env`): fallback estático — por cada `CREATE TABLE`
   en migraciones, verificar su `ALTER TABLE … ENABLE ROW LEVEL SECURITY`.
3. **Estático siempre:** `.single()` sin manejo de `null`; queries sin filtro `user_id` en tablas de
   usuario; `service_role`/`supabaseAdmin` en client (ya cubierto por GP-008); políticas `USING (true)`.

**Sub-score:** mismo decremento. Reportar `tablas con RLS: X/Y`. **Sin MCP:** marcar "no verificado
vía MCP" y **NO penalizar** lo no observable (patrón token-auditor con logs ausentes).

### ⚡ Dimensión 3 — Cache & Rendimiento (peso 25%)

| Check | ripgrep / fuente | Severidad |
|-------|------------------|-----------|
| Client fetch sin cache | archivos `"use client"` con `fetch(` sin `useSWR`/`useQuery` | medium |
| Sin estrategia de cache | `rg -c 'useSWR\|@tanstack/react-query' src/` == 0 pero hay fetch en client | medium |
| Next fetch sin cache config | `fetch(` en `src/app` sin `next:`/`cache:`/`revalidate` | low |
| `force-dynamic` excesivo | `rg -n "force-dynamic" src/app` | medium |
| N+1 queries | query dentro de `.map(async`/`for … of {` | high |
| Índices faltantes | `get_advisors(type:"performance")` (Supabase) | high |
| Sin cache headers / CDN | `rg -n 'Cache-Control\|s-maxage\|stale-while-revalidate'` == 0 en API | medium |
| `<img>` crudo | `rg -n '<img ' src/` | low |
| Imports pesados sin lazy | `rg -nE "from ['\"](recharts\|three\|monaco)" src/` sin `dynamic(` | medium |
| Web Vitals / bundle | delegar a **web-quality** (bloque Performance) y plegar su veredicto aquí | — |

> **Regla anti-doble-conteo:** el bloque **Performance** de web-quality cuenta AQUÍ (Cache), no en
> Calidad Web. Cada hallazgo vive en exactamente una dimensión.

### 🌐 Dimensión 4 — Calidad Web (peso 20%)

**Delegar a web-quality** — leer `.claude/skills/web-quality/SKILL.md` y aplicar SOLO **Accessibility
(WCAG 2.1 AA)**, **SEO**, **Best Practices** + `npm audit` (OWASP-A06 deps vulnerables). El bloque
Performance va en Cache. Mapear severidades de web-quality al mismo decremento (`−20/−10/−4/−1`).

## Cálculo del Audit Score compuesto

```
Composite = 0.30·Seguridad + 0.25·Datos + 0.25·Cache + 0.20·CalidadWeb
```

- **85-100** → 🟢 Excelente. Listo para producción.
- **70-84** → 🟡 Bueno. 2-3 fixes antes de deploy.
- **50-69** → 🟠 Mejorable. Al menos un área crítica.
- **< 50** → 🔴 Crítico. Bloquear deploy hasta remediar.

**Regla de bloqueo (fail-closed):** cualquier hallazgo `critical` marca **"⛔ BLOQUEA DEPLOY"** sin
importar el número — un score de 88 con un `service_role` expuesto sigue siendo deploy-blocker.
Igualmente bloquea cualquier `requisito_seguridad: critico` del contrato no satisfecho.

## Orquestación

- **`quick` y single-dimension → inline.** No se justifica forkear para un pase rápido o una dimensión.
- **`full` → subagents en paralelo** vía `Task` + síntesis (mantiene el contexto principal ligero):
  worker de Calidad Web (a11y/SEO/Lighthouse vía web-quality) + worker de Datos/RLS (Supabase advisors
  / N+1 / índices). Seguridad (threat-db + contrato) corre inline o vía `Agent(Explore)`. El contexto
  principal recibe solo los **resúmenes** y produce el reporte + score.

## Capa profunda `--deep` (opt-in, NO hard-depend de Codex)

```bash
command -v codex >/dev/null 2>&1
```
- **Si disponible:** invocar **`el-guardian`** (el auditor adversarial Codex de Forja) sobre `src/`
  completo, leer su veredicto/severidades y **plegarlo en la dimensión Seguridad**:
  `Seguridad_final = 0.6·Seguridad_estático + 0.4·Adversarial`. Anotar en cobertura.
- **Si NO disponible:** continuar static-only. **Nunca fallar ni bloquear** por ausencia de Codex.
  Mensaje: *"Capa profunda omitida — instala Codex para activarla (opcional)."*

> Cambio respecto a Pro: la capa `--deep` invoca **`el-guardian`** (gate Codex de Forja), no el
> comando `/adversarial-review` de Pro (que es C1/paso 6, no portado aún). El-guardian ya implementa
> los 4 modos de ataque (El Intruso · El Caos · El Destructor · El Saboteador).

## Destino del output

1. **`AUDIT-<YYYY-MM-DD>.md`** en la raíz del proyecto (precedente: `/plan` escribe `SECURITY-AUDIT-*.md`).
2. **`.forja/audits/<YYYY-MM-DD>.json`** — snapshot para `/temple compare` (Forja usa `.forja/` para estado).

Schema del JSON:
```json
{
  "date": "YYYY-MM-DD",
  "composite": 78,
  "dimensions": { "seguridad": 72, "datos": 80, "cache": 65, "web": 88 },
  "findings": { "critical": 1, "high": 4, "medium": 9, "low": 6 },
  "coverage": { "owasp": "7/10", "threatdb_run": "14/27", "rls_tables": "5/6", "requisitos_seguridad": "3/4" },
  "deep_layer": { "ran": false, "verdict": null }
}
```

**`compare`:** `ls -t .forja/audits/*.json` → cargar el más reciente → tabla de deltas por dimensión (↑/↓ pp).

## Plantilla del reporte

```markdown
# 🔨 Temple — Auditoría Full-Project — [YYYY-MM-DD]

**Audit Score: XX/100** — [🟢 Excelente / 🟡 Bueno / 🟠 Mejorable / 🔴 Crítico]
[⛔ BLOQUEA DEPLOY — si hay críticos o requisito_seguridad crítico no satisfecho]

## 📋 Resumen ejecutivo
[2-3 líneas: dónde sangra más, el fix de mayor ROI, veredicto de deploy]

## Score por dimensión
| Dimensión | Peso | Sub-score | Hallazgos (C/H/M/L) | Estado |
|-----------|------|-----------|---------------------|--------|
| 🔒 Seguridad | 30% | XX/100 | x/x/x/x | 🟢/🟡/🔴 |
| 🗄️ Datos & RLS | 25% | XX/100 | x/x/x/x | 🟢/🟡/🔴 |
| ⚡ Cache & Rend. | 25% | XX/100 | x/x/x/x | 🟢/🟡/🔴 |
| 🌐 Calidad Web | 20% | XX/100 | x/x/x/x | 🟢/🟡/🔴 |

## 🔴 Críticos (bloquean deploy)
- **[dim][threat-id o requisito_seguridad]** Descripción. `archivo:línea`
  - **Impacto:** por qué importa · **Fix:** cambio concreto

## 🟠 Alta · 🟡 Media

## 🎯 Top fixes (priorizados por impacto)

## 📊 Cobertura
- OWASP: X/10 · threat-db: X/N checks corridos · RLS: X/Y tablas
- requisitos_seguridad (contrato ONTOLOGY/SPEC): X/N verificados
- web-quality: [Lighthouse / estático] · Capa profunda (el-guardian): [no corrida / veredicto]
```

## Instrucciones al auditor

1. **Medir antes de juzgar.** Correr cada ripgrep / MCP real antes de asignar 🔴/🟡/🟢. No inventar hallazgos.
2. **Reusar, no reimplementar.** threat-db, el hook de secrets, web-quality y el-guardian son la fuente.
3. **No penalizar lo no observable.** Sin MCP Supabase → "no verificado", no restar puntos.
4. **Un hallazgo, una dimensión.** Performance cuenta en Cache, no en Calidad Web.
5. **El contrato manda.** Un `requisito_seguridad: critico` del `ONTOLOGY.md` no satisfecho bloquea,
   aunque la threat-db genérica no lo marque.
6. **Read-only.** Solo audita. Los fixes los aprueba el usuario. Nunca commitear/pushear/editar `src/`.
7. **Paths absolutos** en todo hallazgo accionable. **`quick`** = solo críticos, sin score detallado ni subagents.

## Relacionado

- `el-guardian` — auditor adversarial de la **feature activa (diff)** pre-deploy; la capa `--deep` de aquí.
- `la-herreria` asset #9 (Security Audit) — el gate **pre-Blueprint** que usa la misma threat-db + contrato.
- `web-quality` — la dimensión Calidad Web en detalle.
- `CONSTRAINTS.md` § DevSecOps shift-left — la doctrina de los 5 gates por fase.
