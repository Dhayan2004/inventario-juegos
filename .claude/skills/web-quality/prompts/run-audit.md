# run-audit

> Protocolo de ejecución del audit según el modo seleccionado (live | static). Binary selector D-015 aplicado. R4/R5/R13 enforced.

## Inputs

```yaml
mode: live | static            # determinado por mode selector binary

project:
  root: <path>                  # raíz del proyecto target
  src_or_pages_dir: <path>      # src/ o pages/ detectado
  next_version: <string>        # de package.json
  
target_url: <url> | null        # solo para live
target_server: <port> | null    # solo para live (ej: 3000 si npm run dev)

tools_available:
  agent_browser: bool           # default D4
  lighthouse_cli: bool          # fallback estándar
```

## Output

```yaml
audit_result:
  mode: live | static
  
  # solo live mode
  lighthouse_scores:
    performance: <0-100>
    accessibility: <0-100>
    best_practices: <0-100>
    seo: <0-100>
  core_web_vitals:
    lcp: <ms>
    inp: <ms>
    cls: <number>
  
  # ambos modes
  issues:
    - severity: critical | high | medium | medium | low
      category: performance | accessibility | seo | best_practices
      description: <string>
      location:
        file: <path> | null     # null si solo medible en live
        line: <number> | null
      impact: <string>
      fix: <string>             # con code snippet si applicable
      snippet_before: <string> | null
      snippet_after: <string> | null
  
  pre_deploy_gate: pass | needs_fix
  recommended_priority: [<list de issues en orden recomendado>]
```

## Antes de empezar — find-docs (R13 enforced)

> [memory:CONSTRAINTS.md#R13] — External docs citation antes de generar comandos contra libs externas.

ANTES de emitir cualquier comando `agent-browser` o `lighthouse`, sub-agent invoca find-docs:

```
ctx7 library agent-browser "agent-browser CLI commands lighthouse audit Next.js"
ctx7 docs <id> "agent-browser audit lighthouse score Core Web Vitals INP CLS"
```

O para Lighthouse fallback:

```
ctx7 library lighthouse "lighthouse CLI command --output --only-categories Next.js"
ctx7 docs <id> "lighthouse CLI flags performance accessibility seo best-practices"
```

Cita: `[docs:agent-browser]` o `[docs:lighthouse]` cuando aplica. Si find-docs no responde → fallback con caveat informativo "[docs:agent-browser] cited from training data, Context7 unavailable".

## Mode LIVE — protocolo

### Paso 1 — Validar URL o server

```bash
# Si target_url provided → audit directo en URL
# Si target_server provided → audit en http://localhost:{port}
# Si ninguno → degradar a STATIC (NO halt — fallback graceful, D-015 binary)
```

### Paso 2 — Dispatch sub-agent con tool filter live

```
[Sub-agent dispatched by web-quality]
  Role: Live web auditor
  Tool filter:
    - Read · Grep · Glob (context lectura)
    - Bash: agent-browser CLI o lighthouse CLI
    - WebFetch: opcional para Lighthouse Web API
    - Skill: find-docs (R13)
  System prompt:
    "Sos el live web auditor. Invocá find-docs primero (R13). Luego agent-browser
     CLI (default D4 — ver references/performance.md sección 'Measuring with
     agent-browser') o lighthouse CLI fallback. Audita las 4 categorías
     (Performance/Accessibility/SEO/Best Practices). Mapeá hallazgos a niveles
     de severidad (Critical/High/Medium/Low). NO escribas a memory (R5).
     Reportá lighthouse_scores + core_web_vitals + issues estructurados a
     web-quality."
```

### Paso 3 — Sub-agent ejecuta audit live

Sub-agent corre (después de find-docs):

```bash
# Default D4 — agent-browser CLI
agent-browser audit {target_url} \
  --categories performance,accessibility,seo,best-practices \
  --output json \
  --output-path .claude/reports/web-audit-{nombre}-{timestamp}.json

# Fallback estándar
lighthouse {target_url} \
  --only-categories=performance,accessibility,seo,best-practices \
  --output json \
  --output-path .claude/reports/lighthouse-{nombre}-{timestamp}.json
```

Parsea el JSON output:
- `categories.performance.score × 100` → Performance score
- `categories.accessibility.score × 100` → Accessibility score
- `audits.largest-contentful-paint.numericValue` → LCP ms
- `audits.interaction-to-next-paint.numericValue` → INP ms
- `audits.cumulative-layout-shift.numericValue` → CLS

### Paso 4 — Mapear hallazgos a severity

Cada audit fail (`audits[*].score < 1` excepto los manuales) se clasifica:

| Audit failed | Severity default | Categoría |
|--------------|------------------|-----------|
| `is-on-https` (mixed content detectado) | Critical | Best Practices |
| `html-has-lang` (lang missing en `<html>`) | Critical | Accessibility |
| `largest-contentful-paint > 4000ms` | High | Performance |
| `cumulative-layout-shift > 0.25` | High | Performance |
| `interaction-to-next-paint > 500ms` | High | Performance |
| `image-alt` (imágenes sin alt informativo) | High | Accessibility |
| `color-contrast` (contraste < 4.5:1) | High | Accessibility |
| `meta-description` ausente | Medium | SEO |
| `hreflang` mal configurado | Medium | SEO |
| `uses-rel-preconnect` ausente | Medium | Performance |
| `image-size-responsive` (img sin srcset) | Medium | Performance |
| `unsized-images` (sin width/height) | Medium | Performance |
| `heading-order` mal | Low | Accessibility |
| `tap-targets` pequeños | Low | Accessibility |

Sub-agent reporta cada issue con `location` (file/line si Lighthouse lo identifica vía source maps) + `impact` + `fix` con snippet.

## Mode STATIC — protocolo

### Paso 1 — Confirmar fallback graceful

Static activado cuando:
- Sin URL ni server target_*
- O agent-browser y lighthouse ambos no disponibles
- O usuario explícitamente prefirió static

NO halt — D-015 binary fallback graceful.

### Paso 2 — Dispatch sub-agent con tool filter static

```
[Sub-agent dispatched by web-quality]
  Role: Static code auditor
  Tool filter:
    - Read · Grep · Glob (lectura intensiva)
    - Bash: solo `npm list` / `npm audit` informativo
    - Skill: ninguna (static no requiere find-docs — ya conocemos los patterns)
  System prompt:
    "Sos el static code auditor. Lee src/ o pages/ + app/layout.tsx +
     package.json. Aplicá pattern detection sobre los issues conocidos
     (ver lista abajo). Reportá issues con line numbers + recomendaciones,
     SIN scores numéricos (no hay measurement live). NO escribas a memory
     (R5). Reportá issues estructurados a web-quality."
```

### Paso 3 — Pattern detection static

Sub-agent ejecuta grep/lectura sobre patterns conocidos:

#### Performance

| Pattern | Detección | Severity |
|---------|-----------|----------|
| `<img src=` sin `next/image` import en archivo | grep `import Image from 'next/image'` ausente | High |
| Google Fonts CDN en `<link>` | grep `fonts.googleapis.com` en layout | Medium (preferir `next/font`) |
| Importación full lib (`import _ from 'lodash'`) | grep `^import \w from '[a-z]+'` (no submodule) | Medium |
| Componente client-side `'use client'` en root layout | grep `^'use client'` en `app/layout.tsx` | Critical (rompe RSC) |
| Sin `priority` en LCP image | grep `<Image` sin `priority` en hero | High |

#### Accessibility

| Pattern | Detección | Severity |
|---------|-----------|----------|
| `<html>` sin `lang` | grep `^<html>` o `<html className=` (Next.js layout) | Critical |
| Imágenes sin `alt` | grep `<img src=` sin `alt=` o `<Image` sin `alt=` | High |
| Botones con solo icon (sin aria-label) | grep `<button>` con `<svg>` sin `aria-label` | High |
| Forms sin `<label>` | grep `<input` sin `<label` cercano | High |
| Headings non-secuenciales | parse `<h1>`-`<h6>` order | Medium |
| Color contrast hardcoded `text-gray-300` sobre `bg-white` | grep classes de bajo contraste | Medium |

#### SEO

| Pattern | Detección | Severity |
|---------|-----------|----------|
| Sin `metadata` export en `app/page.tsx` | grep `export const metadata` ausente | High |
| Sin `app/sitemap.ts` | file existence check | Medium |
| Sin `app/robots.ts` | file existence check | Medium |
| Title hardcoded > 60 chars | parse metadata.title length | Medium |
| Meta description ausente | grep `description:` en metadata | Medium |
| Más de un `<h1>` | grep count `<h1>` por archivo | Medium |

#### Best Practices

| Pattern | Detección | Severity |
|---------|-----------|----------|
| `console.log` en código deployado | grep `console\.(log|debug|info)` excluyendo dev logs | Low |
| `npm audit` con high/critical | shell `npm audit --audit-level=high` | Critical |
| Source maps en prod build | check `.next/static/**/*.map` | High |
| Sin `next/script` para third-party | grep `<script` directo en components | Medium |
| `brand/brand.css` no cargado en root layout | grep `import '../brand/brand.css'` ausente | High |
| `brand/brand.json` en bundle cliente | grep `import.*brand\.json` en `'use client'` files | Critical |

### Paso 4 — Reportar issues sin scores numéricos

Static mode NO produce Lighthouse scores. Output:

```yaml
audit_result:
  mode: static
  lighthouse_scores: null      # explícito null
  core_web_vitals: null
  issues: [...]                # con location.file/line
  pre_deploy_gate: pass | needs_fix
  caveat: "Static analysis — para scores numéricos correr live audit con URL/server."
```

## R4 enforcement

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

web-quality MISMA NO ejecuta audit. Sub-agent invoca tools (live) o lee código (static). web-quality solo recolecta el output estructurado y arma el reporte vía build-report.md.

## R5 enforcement

> [memory:CONSTRAINTS.md#R5] — Workers no escriben a memory.

Sub-agents NO escriben a `.claude/memory/*.md`. Reportes van a `.claude/reports/` (state) o stdout. Si emerge lesson/error/decision durante audit, reportar a web-quality → handoff a el-evaluador post-audit (si invocado por la-forja Fork pattern como gate).

## Edge cases

### Edge: agent-browser instalado pero target URL inaccesible (404, network error)

→ Sub-agent reporta a web-quality. Opciones: retry con timeout extendido, o degradar a static + reportar al usuario "URL inaccesible, fallback a static". NO halt forzado — D-015 graceful.

### Edge: Lighthouse JSON output con campos missing (versión nueva del CLI)

→ Sub-agent invoca find-docs para confirmar shape canónico actual. Si shape divergió, parse adapta + reportar al usuario "Lighthouse v{X} — detectados campos nuevos, parsing adaptado".

### Edge: Static mode encuentra `app/page.tsx` ausente (proyecto Pages Router antiguo)

→ Pattern detection adapta a Pages Router (`pages/_app.tsx`, `pages/_document.tsx`). Reportar al usuario que el proyecto usa Pages Router (legacy) — algunos checks (sitemap.ts, robots.ts) NO aplican.

### Edge: Mixed content detectado en live (CRITICAL)

→ Pre-deploy gate = NEEDS_FIX automático. Audit continúa para reporte completo, pero `pre_deploy_gate: needs_fix` flag explicit.

### Edge: Lighthouse Performance 89 con LCP > 2.5s

→ Score < 90 target = NEEDS_FIX. Issue High por LCP. NO redondear hacia arriba — 89 ≠ 90.

### Edge: Multiple URL targets (multi-page audit)

→ Sub-agent itera URLs + agrega scores promedio + reporta peor-case por categoría. Reportar al usuario "audit cubrió N URLs, peor score por categoría reportado".

### Edge: brand/brand.json detectado en `'use client'` file

→ Critical. Bundle cliente expone brand contract → potencial leak de tokens internos. Issue inmediato + recomendar mover import a server component o `import` dynamic.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — web-quality thin, sub-agent ejecuta audit.
- [memory:CONSTRAINTS.md#R5] — sub-agents no escriben memory.
- [memory:CONSTRAINTS.md#R13] — find-docs antes de generar agent-browser/lighthouse commands.
- [memory:references#R-003] — agent-browser default D4.
- [memory:decisions#D-015] — binary mode selector.
- [docs:agent-browser] — invocado por sub-agent vía find-docs.
- [docs:lighthouse] — fallback estándar.

## Refusals

- ❌ Generar agent-browser/lighthouse commands sin invocar find-docs primero (R13).
- ❌ Force live cuando no hay URL/server (degradar a static, NO halt).
- ❌ Inventar scores en static mode (NO scores — issues accionables solo).
- ❌ Sub-agent escribe a memory (R5).
- ❌ web-quality MISMA invoca tools directo (R4 — sub-agent invoca).
- ❌ Recomendar Playwright MCP por default (D4 — agent-browser default).
- ❌ Reporte sin classification de severity (Critical/High/Medium/Low es contrato).
