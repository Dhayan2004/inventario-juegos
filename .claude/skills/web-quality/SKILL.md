---
name: web-quality
description: >
  Auditoría integral de calidad web basada en Google Lighthouse (150+ checks).
  Cubre Performance + Core Web Vitals (LCP / INP / CLS), Accessibility (WCAG
  2.1 nivel AA mínimo), SEO (crawlability + on-page + Next.js metadata API),
  y Best Practices (security + modern standards + code quality). Adaptado al
  Golden Path Forja (Next.js 16 + Tailwind 3.4 + Vercel). Binary mode selector
  (D-015 — L-004 aplica): "live audit" (default — requiere URL o server
  corriendo, usa agent-browser CLI [memory:references#R-003] como default
  por D4 ARCHITECTURE.md, ~4× ahorro tokens vs Playwright MCP, fallback
  Lighthouse CLI estándar) y "static analysis" (fallback graceful — sin URL
  ni server, lectura de src/ o pages/ con pattern detection sin scores
  numéricos pero con issues accionables localizados a line numbers). NO
  PAUSE — static siempre disponible cuando live no, no requiere acción
  upstream del usuario. 4 categorías × 4 niveles de severidad
  (Critical/High/Medium/Low). Lighthouse Score Targets canónicos
  (Performance ≥90, Accessibility 100, Best Practices ≥95, SEO ≥95).
  Reporte estructurado por categoría + severity + checklist pre-deploy +
  prioridad recomendada. Citas: [memory:references#R-003] (agent-browser
  default), [memory:CONSTRAINTS.md#R13] (find-docs antes de lighthouse /
  agent-browser commands), [memory:decisions#D-015] (binary selector).
tier: core
requires: proyecto Next.js con `src/` o `pages/` accesible (PREFLIGHT suave). Para live audit (default) — URL o `npm run dev`/`npm run start` corriendo. Si live no es viable → static analysis fallback graceful (no requiere URL, lee código). agent-browser CLI instalado para live audit (default por D4); fallback Lighthouse CLI estándar si agent-browser ausente.
fallback: Sin proyecto Next.js detectable (`src/` ni `pages/`) → halt informativo: "no parece un proyecto Next.js — web-quality requiere proyecto target con código accesible". Sin URL ni server para live → static analysis (graceful, no halt). Sin agent-browser ni Lighthouse CLI ni node disponibles → halt: "ningún audit tool disponible — instalá agent-browser o lighthouse CLI". Si live audit produce error inesperado durante crawling → degradar a static + reportar.
dependencies: [find-docs]
---

# web-quality

> *"150+ checks. 4 categorías. 2 modos. Cero excusas para ship slop visible."*

Auditoría integral pre-deploy basada en Google Lighthouse. Adaptado al Golden Path Forja: Next.js 16 + Tailwind 3.4 + Vercel + agent-browser CLI default (D4 ARCHITECTURE.md). 4 categorías canónicas (Performance / Accessibility / SEO / Best Practices) con niveles de severidad documentados. **Binary mode selector** (D-015 — L-004 aplica): live audit (default) o static analysis (fallback graceful sin PAUSE).

## PREFLIGHT — suave, no halt en faltantes operacionales

```
1. ¿Es un proyecto Next.js accesible?
   - Detectar src/ o pages/ + package.json con next como dep
   - Si ninguno → halt informativo: "no parece un proyecto Next.js. web-quality
     requiere proyecto target con código accesible. Si tu proyecto NO es
     Next.js, los patterns de detección estática serán parciales — útiles pero
     no exhaustivos. Confirmá si querés correr en modo best-effort."
   - Si ambos OK → continuar

2. ¿Hay URL o server corriendo (live audit)?
   - Sí → modo live (default)
   - No → preguntar al usuario UNA pregunta:
     "¿Tenés URL o server corriendo? (sí → live audit Lighthouse-based |
      no → static analysis fallback)"
   - Si usuario dice no o ambiguo → modo static fallback graceful

3. ¿Tools disponibles para modo seleccionado?
   - Live: agent-browser CLI (default D4) o Lighthouse CLI fallback
     - Si ambos ausentes → halt: "ningún audit tool disponible — instalá
       agent-browser o lighthouse CLI primero"
   - Static: solo lectura de filesystem (siempre disponible)

4. ¿find-docs disponible (R13)?
   - Sí → invocar antes de generar comandos lighthouse / agent-browser
   - No → fallback con caveat informativo "[docs:agent-browser] cited from
     training data, Context7 unavailable"
```

PREFLIGHT halt-blocked SOLO en casos críticos (no es proyecto + ningún tool disponible para modo elegido). Resto se reporta como warning + degradación graceful.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide auditoría pre-deploy ("web audit", "quality check", "lighthouse audit") | Coordinator |
| Usuario pide mejorar performance / SEO / accessibility específico | Coordinator |
| Pre-deploy gate (junto a el-guardian) en pipeline orquestado por la-forja Fork | Coordinator post-implementación |
| Usuario dice "antes de deploy revisá calidad" / "verificá que esté listo para producción" | Coordinator |

NO se invoca para: planificar features (la-herreria), ejecutar build paralelo (la-forja), validación estratégica (el-crisol), audit de seguridad pre-deploy específico (el-guardian — complementa, no reemplaza). web-quality y el-guardian se complementan: web-quality cubre Lighthouse + a11y + SEO + perf; el-guardian cubre OWASP Top 10 + RLS + R14 + secrets.

## Mode selector (binary, D-015)

[`prompts/run-audit.md`](prompts/run-audit.md) implementa el selector con L-004 test aplicado:

| Modo | Trigger | Output | Use case |
|------|---------|--------|----------|
| **Live audit** (default) | URL o server corriendo + tools disponibles | Lighthouse scores numéricos + Core Web Vitals reales medidos + screenshots opcional | Pre-deploy con app corriendo localmente o en preview |
| **Static analysis** (fallback) | Sin URL ni server, o tools indisponibles | Issues accionables localizados a line numbers + recomendaciones, **sin scores numéricos** | Cold review de código, CI sin server, decisiones tempranas pre-build |

Detalle del selector + L-004 application en [`references/audit-mode-rationale.md`](references/audit-mode-rationale.md). D-015 documenta:

- BINARY shape: live default + static fallback, NO PAUSE.
- L-004 aplica (a diferencia de el-crisol D-014 que era pipeline shape sin selector).
- D-015 refina D-014 doctrine: validators **CON** selector → L-004 aplica normalmente; validators **SIN** selector (o pipelines como el-crisol) → ADR propio dedicado.

## Cómo opera el audit

```
[web-quality] PREFLIGHT (4 checks above)
   ↓
[web-quality] Mode selector (live | static)
   ↓
[web-quality] R6 validation (find-docs en skills.md)
   ↓
[web-quality] Sub-agent dispatch
   ├── LIVE: sub-agent invoca find-docs → agent-browser CLI o lighthouse CLI
   └── STATIC: sub-agent lee src/ o pages/ + pattern detection
   ↓
[Sub-agent ejecuta audit]
   ├── 4 categorías canónicas analizadas
   └── Issues clasificados por severity (Critical/High/Medium/Low)
   ↓
[web-quality] Recolección de output → build-report.md template
   ↓
[web-quality] Reporte estructurado al usuario
   ├── Resumen de Lighthouse scores (live only)
   ├── Issues por categoría con line numbers + code snippets
   ├── Severity buckets
   └── Checklist pre-deploy + Prioridad recomendada
```

## 4 categorías canónicas

### Performance (40% de issues típicos)

**Core Web Vitals** — deben pasar para buena page experience:

| Métrica | Bueno | Necesita Mejora | Pobre |
|---------|-------|-----------------|-------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | 2.5s – 4s | > 4s |
| **INP** (Interaction to Next Paint) | ≤ 200ms | 200ms – 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | 0.1 – 0.25 | > 0.25 |

**Performance Budget:**

| Recurso | Budget | Notas Next.js |
|---------|--------|---------------|
| Página total | < 1.5 MB | Vercel Edge Cache ayuda |
| JavaScript (comprimido) | < 300 KB | `next/dynamic` para code split |
| CSS (comprimido) | < 100 KB | Tailwind purge elimina unused |
| Imágenes above-fold | < 500 KB | `next/image` con `priority` |
| Fonts | < 100 KB | `next/font` (auto-optimized) |
| Third-party | < 200 KB | Lazy-load con `next/script` |

**Optimizaciones Next.js específicas:**
- `next/image` con `priority` para LCP images
- `next/font` para font optimization automática (NO Google Fonts CDN)
- `next/dynamic` con `{ ssr: false }` para componentes pesados
- `React.memo`, `useMemo`, `useCallback` para INP
- `useTransition` para state updates no urgentes
- Server Components por default — solo `'use client'` cuando necesario

→ ver [`references/performance.md`](references/performance.md) para guía completa con agent-browser CLI commands.

### Accessibility (30% de issues típicos)

**WCAG 2.1 AA obligatorio.** WCAG 2.2 cuando find-docs confirme soporte upstream.

**Perceivable:**
- Todo `<img>` con `alt` descriptivo. Decorativos: `alt=""`
- Contraste mínimo 4.5:1 (normal text), 3:1 (large text)
- No depender solo del color para comunicar información
- Video con captions, audio con transcripts

**Operable:**
- Todo accesible por teclado. Sin keyboard traps
- Focus visible en elementos interactivos
- Skip links para navegación
- `prefers-reduced-motion` respetado

**Understandable:**
- `lang` en `<html>` (Critical si falta)
- Navegación consistente entre páginas
- Errores de form claramente descritos y asociados (aria-describedby)
- Labels en todos los inputs

**Robust:**
- HTML válido (sin IDs duplicados)
- ARIA usado correctamente (preferir elementos nativos)
- Elementos interactivos con accessible names

→ ver [`references/accessibility.md`](references/accessibility.md) para guía WCAG completa.

### SEO (15% de issues típicos)

**Crawlability:**
- `robots.txt` válido, no bloquea recursos importantes
- XML sitemap actualizado
- Canonical URLs para evitar contenido duplicado
- No `noindex` en páginas importantes

**On-Page SEO:**
- Title tags únicos (50-60 chars), keyword al inicio
- Meta descriptions únicas (150-160 chars)
- Heading hierarchy: un solo `<h1>`, estructura lógica
- Link text descriptivo (no "click here")

**Structured Data:**
- JSON-LD para rich snippets (Article, Product, FAQ, Breadcrumbs)
- Validar en Google Rich Results Test

**Next.js 16 específico (App Router metadata API):**
- `metadata` export estático en `layout.tsx` / `page.tsx`
- `generateMetadata()` async para meta dinámico
- `app/sitemap.ts` para sitemap automático
- `app/robots.ts` para robots.txt programático
- `app/icon.tsx` / `app/apple-icon.tsx` para favicons

→ ver [`references/seo.md`](references/seo.md) para guía SEO completa.

### Best Practices (15% de issues típicos)

**Security:**
- HTTPS everywhere, sin mixed content
- No librerías vulnerables (`npm audit`)
- CSP headers configurados
- Sin source maps expuestos en producción

**Modern Standards:**
- HTML5 doctype, charset UTF-8 primero en `<head>`
- Viewport meta tag responsive
- No APIs deprecated (`document.write`, XHR síncrono)
- Passive event listeners para scroll/touch

**Code Quality:**
- Console limpia, sin errores
- HTML semántico (`<main>`, `<nav>`, `<article>`)
- Error handling apropiado (Error Boundaries en React)
- Memory cleanup en componentes

**Forja-specific:**
- `brand/brand.css` cargado correctamente en root layout
- `brand/brand.json` NO expuesto en bundle cliente (server-only)
- Anti-slop hue range respetado en componentes deployados (post-impeccable check)

→ ver [`references/best-practices.md`](references/best-practices.md) para guía completa.

## Niveles de severidad

| Nivel | Descripción | Acción |
|-------|-------------|--------|
| **Critical** | Vulnerabilidades de seguridad, fallos completos (lang missing en html, mixed content) | Fix inmediato |
| **High** | Core Web Vitals fallan, barreras de a11y mayores (LCP > 4s, sin alt en imágenes informativas) | Fix antes de launch |
| **Medium** | Oportunidades de performance, mejoras SEO (no preconnect, meta description ausente) | Fix en el sprint |
| **Low** | Optimizaciones menores, calidad de código (orden de preconnect subóptimo, h2 antes de h1) | Fix cuando convenga |

## Lighthouse Score Targets

| Categoría | Target | Notas |
|-----------|--------|-------|
| Performance | ≥ 90 | Core Web Vitals deben pasar |
| Accessibility | 100 | WCAG 2.1 AA mínimo, sin excusas |
| Best Practices | ≥ 95 | Security + modern standards |
| SEO | ≥ 95 | Metadata + crawlability |

## Formato del reporte

Detalle completo en [`prompts/build-report.md`](prompts/build-report.md). Resumen:

```markdown
## Resultados de Auditoría — {nombre del proyecto}

**Modo:** live | static
**Lighthouse scores** (live only): Performance X / A11y X / BP X / SEO X
**URL auditada** (live only): {URL}

### Issues Críticos ({N} encontrados)

- **[Categoría]** Descripción del issue.
  - Archivo: `path/to/file.tsx:123`
  - **Impacto:** Por qué importa
  - **Fix:** Cambio específico de código (snippet incluido)

  ```tsx
  // ANTES
  <html>
  
  // DESPUÉS
  <html lang="es">
  ```

### Alta Prioridad ({N} encontrados)
...

### Resumen
- Performance: X issues (Y críticos)
- Accessibility: X issues (Y críticos)
- SEO: X issues
- Best Practices: X issues

### Prioridad Recomendada
1. Primero arreglar {issue} porque {razón}
2. Luego abordar {issue}
3. Finalmente optimizar {issue}
```

## Checklist pre-deploy

- [ ] Core Web Vitals pasando (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- [ ] Sin errores de accessibility (Lighthouse score 100)
- [ ] Sin console errors
- [ ] HTTPS funcionando
- [ ] Meta tags presentes (title + description + OG)
- [ ] `npm audit` sin vulnerabilidades high/critical
- [ ] brand/brand.css cargado en root layout
- [ ] brand/brand.json NO en bundle cliente

## agent-browser CLI default (D4)

> [memory:references#R-003] — vercel-labs/agent-browser. Default de Forja para QA + visual diff. ~4× ahorro de tokens vs Playwright MCP.

Para live audit, **invocar agent-browser primero** (R13: find-docs antes de generar commands). Detalle en [`references/performance.md`](references/performance.md) sección "Measuring with agent-browser".

Fallback Lighthouse CLI estándar si agent-browser ausente. NO usar Playwright MCP por default — es opcional cross-browser, agent-browser es Default por D4.

## Hard rules — R4/R5/R13 enforcement

### R4 — Orchestrator stays thin

> [memory:CONSTRAINTS.md#R4] — Orchestrator stays thin.

web-quality MISMA es **thin**:
- Lee (Read, Grep, Glob) src/ o pages/, package.json, app/layout.tsx.
- Bash limitado a file globs (detección) + `npm list` (informativo).
- Dispatch a sub-agents para audit ejecución (live o static).
- NO invoca agent-browser ni lighthouse directamente — sub-agent lo hace.

### R5 — Memory writers

Sub-agents en audit NO escriben a `.claude/memory/*.md`. Outputs van al reporte (state, no memory). Si emerge lesson/error/decision durante audit, propagar al handoff de el-evaluador.

### R13 — find-docs antes de generar lighthouse / agent-browser commands

> [memory:CONSTRAINTS.md#R13] — External docs citation.

ANTES de emitir comandos `lighthouse` o `agent-browser`, invocar find-docs:

```
ctx7 library agent-browser "agent-browser CLI commands lighthouse audit Next.js"
ctx7 docs <id> "agent-browser audit lighthouse score Core Web Vitals INP CLS"
```

Cita: `[docs:agent-browser]` o `[docs:lighthouse]` cuando aplica. Si find-docs no responde → fallback con caveat informativo.

## Reglas operativas

1. **web-quality MISMA es thin (R4).** NUNCA invoca agent-browser/lighthouse directo. Solo dispatch a sub-agent.

2. **Mode selector binary (D-015).** Live default + static fallback. NO PAUSE. Si live no viable → static graceful, no halt.

3. **find-docs antes de commands externos (R13).** agent-browser y lighthouse son tools externas — sus flags pueden cambiar entre versiones.

4. **WCAG 2.1 AA es mínimo no-negociable.** Lighthouse Accessibility 100 target. Si el-evaluador encuentra <100, NEEDS_FIX.

5. **Severity matters.** Critical y High deben fixarse antes de deploy. Medium en el sprint. Low cuando convenga.

6. **agent-browser default (D4).** NO Playwright MCP por default — agent-browser ahorra ~4× tokens. Playwright MCP solo si cross-browser específicamente requerido.

7. **Static analysis tiene line numbers.** Cada issue localizado debe incluir `path/to/file.tsx:123`. Sin localización → recomendación general (acción menos clara).

8. **Code snippets en Critical/High.** Cada issue Critical/High incluye snippet ANTES/DESPUÉS para clarificar el fix.

9. **Forja-specific checks.** Validar `brand/brand.css` en root layout + `brand/brand.json` NO en bundle cliente. Si fallan → Best Practices Critical.

10. **el-guardian complementa, no reemplaza.** web-quality cubre Lighthouse + a11y + SEO + perf. el-guardian cubre OWASP + RLS + R14 + secrets. Pre-deploy serio invoca AMBOS.

11. **L-004 aplica (D-015).** A diferencia de el-crisol (D-014 pipeline shape), web-quality SÍ tiene selector binary. D-015 refina D-014 doctrine.

## Refusals (lo que NUNCA hace)

- ❌ Ejecutar audit sin proyecto target accesible (PREFLIGHT halt — sin código, no hay qué auditar).
- ❌ Force live audit cuando no hay URL ni server (degradar a static graceful).
- ❌ Invocar agent-browser sin find-docs primero (R13 violation).
- ❌ Score Performance ≥90 sin Core Web Vitals pasando (incoherencia interna).
- ❌ Marcar Accessibility 100 con WCAG violations Critical (gates cruzados).
- ❌ Inventar Lighthouse scores en static mode (static NO tiene scores numéricos — issues accionables solo).
- ❌ Skip de severity classification (Critical/High/Medium/Low es contrato, no opcional).
- ❌ Reporte sin line numbers cuando localizable (issue sin path:line es poco accionable).
- ❌ Recomendar Playwright MCP por default cuando agent-browser está disponible (D4 violation).
- ❌ Self-eval del audit (AP3 — el-evaluador valida si el audit se invocó como gate).

## Tool filter — web-quality MISMA

`Read · Grep · Glob · Bash (limited)`

NO Edit · NO Write directo · NO Skill direct (R4).

Bash limitado a:
- File globs (detección de proyecto + assets).
- `npm list` (informativo, read-only state).
- `git status` (informativo).

Sub-agents reciben tool filter apropiado:
- Live audit sub-agent: Read + Bash (agent-browser/lighthouse) + WebFetch (Lighthouse Web API si aplica).
- Static analysis sub-agent: Read + Grep + Glob (lectura intensiva código).

Sub-agents NO Edit/Write a archivos de aplicación — el reporte es texto, no fix automatizado. El humano aplica los fixes recomendados con guía del reporte.

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en SKILL.md + run-audit.md (orchestrator thin) |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en run-audit.md (workers no escriben memory) |
| Constraint | `[memory:CONSTRAINTS.md#R13]` | en run-audit.md (find-docs antes de commands) |
| Lesson | `[memory:lessons#L-004]` | en audit-mode-rationale.md (selector binary aplicado) |
| Decision | `[memory:decisions#D-014]` | en audit-mode-rationale.md (refinement context) |
| Decision | `[memory:decisions#D-015]` | en SKILL.md + audit-mode-rationale.md (binary selector + refines D-014) |
| Reference | `[memory:references#R-003]` | en SKILL.md + performance.md (agent-browser default D4) |
| External docs | `[docs:agent-browser]` | en performance.md cuando sub-agent invoca find-docs |
| External docs | `[docs:lighthouse]` | en performance.md cuando sub-agent usa Lighthouse fallback |
| External docs | `[docs:nextjs]` | en performance.md / seo.md / best-practices.md cuando aplica |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `el-guardian` | complementario — web-quality cubre Lighthouse + a11y + SEO + perf; el-guardian cubre OWASP + RLS + R14. Pre-deploy serio invoca AMBOS. |
| `el-evaluador` | downstream opcional — el-evaluador puede invocar web-quality como parte de R7 three-layer system test si feature involucra UI o pages. |
| `la-forja` | upstream — la-forja Fork pattern puede dispatchar web-quality como sub-agent post-build cherry-pick. |
| `find-docs` | sub-tool mandatory — R13 enforced. Sub-agent invoca find-docs antes de generar comandos lighthouse/agent-browser. |
| `impeccable` | upstream complementario — impeccable genera componentes con anti-slop gates pre-render; web-quality valida post-render con Lighthouse + WCAG. |
| `add-ui-kit` | upstream complementario — define brand.json contract; web-quality valida que brand.css cargado correctamente y brand.json NO expuesto en cliente. |
| `primer` | upstream — si web-quality arranca en proyecto target sin contexto, primer carga primero. |
| `el-crisol` | NO direct — el-crisol valida estrategia pre-build; web-quality valida calidad post-build. Casos distintos en el flow. |

## Output handoff

```markdown
## web-quality handoff

**Active feature:** {F?-S?}
**Modo aplicado:** live | static
**URL auditada** (live): {URL}
**Lighthouse scores** (live):
  - Performance: {X}/100 (target ≥90)
  - Accessibility: {X}/100 (target 100)
  - Best Practices: {X}/100 (target ≥95)
  - SEO: {X}/100 (target ≥95)

**Issues encontrados:**
  - Critical: {N}
  - High: {N}
  - Medium: {N}
  - Low: {N}

**Reporte:** .claude/reports/web-audit-{nombre}-{timestamp}.md (o stdout si one-shot)

**Pre-deploy gate:** PASS | NEEDS_FIX
  - PASS = sin Critical/High Y Lighthouse targets cumplidos
  - NEEDS_FIX = al menos 1 Critical/High o algún score < target

**Memory entries propuestas (opcional):**
  - proposed_lesson: {si emerge patrón cross-proyecto}
  - proposed_error: {si Lighthouse / agent-browser falla recurrentemente}

**Handoff next:**
  - Si PASS y full pipeline → el-guardian (complementa con OWASP/RLS audit)
  - Si NEEDS_FIX → re-implementar fixes Critical/High y re-correr web-quality
  - Si solo build sin deploy → handoff queda al humano para `/despachar`
```

---

*"Ningún site se ship sin pasar por web-quality. Lighthouse 100 en a11y no es ornamento — es el mínimo no-negociable de respeto al usuario."*
