# build-report

> Template del reporte final de auditoría. Estructurado por categoría + severity. Issues con line numbers + code snippets en Critical/High. Pre-deploy gate explícito + prioridad recomendada.

## Inputs

```yaml
audit_result:                   # output de run-audit.md
  mode: live | static
  lighthouse_scores: { ... } | null
  core_web_vitals: { ... } | null
  issues: [...]
  
project:
  name: <string>
  url: <string> | null
```

## Output

`.claude/reports/web-audit-{nombre}-{timestamp}.md` (o stdout si one-shot interactivo).

## Estructura del reporte

```markdown
# Web Quality Audit — {nombre del proyecto}

> Generado por web-quality · {fecha ISO}
> Modo: {live | static}
> {URL: https://...} (live only)
> {Caveat: Static analysis — para scores numéricos correr live audit con URL/server.} (static only)

---

## Lighthouse Scores

(live only)

| Categoría | Score | Target | Status |
|-----------|-------|--------|--------|
| Performance | {X}/100 | ≥90 | {ok / warning / critical} |
| Accessibility | {X}/100 | 100 | {ok / warning / critical} |
| Best Practices | {X}/100 | ≥95 | {ok / warning / critical} |
| SEO | {X}/100 | ≥95 | {ok / warning / critical} |

## Core Web Vitals

(live only)

| Métrica | Valor | Target | Status |
|---------|-------|--------|--------|
| LCP (Largest Contentful Paint) | {X}s | ≤2.5s | {ok / warning / critical} |
| INP (Interaction to Next Paint) | {X}ms | ≤200ms | {ok / warning / critical} |
| CLS (Cumulative Layout Shift) | {X} | ≤0.1 | {ok / warning / critical} |

---

## Issues Críticos ({N} encontrados)

(Vulnerabilidades de seguridad, fallos completos de funcionalidad. Fix inmediato.)

### 1. [Accessibility] `<html>` sin atributo `lang`

- **Archivo:** `app/layout.tsx:8`
- **Impacto:** Screen readers no detectan el idioma del documento. Critical para usuarios con lectores de pantalla. Bloquea Lighthouse Accessibility 100.
- **Fix:**

  ```tsx
  // ANTES
  export default function RootLayout({ children }) {
    return (
      <html>
        <body>{children}</body>
      </html>
    )
  }
  
  // DESPUÉS
  export default function RootLayout({ children }) {
    return (
      <html lang="es">
        <body>{children}</body>
      </html>
    )
  }
  ```

### 2. [Best Practices] `brand/brand.json` importado en `'use client'` file

- **Archivo:** `app/(marketing)/landing/HeroBrand.tsx:3`
- **Impacto:** Brand contract expuesto en bundle cliente. Potencial leak de tokens internos. Rompe contrato D9 (brand.json es server-only).
- **Fix:** mover lectura de brand.json a server component (Server Component padre) y pasar tokens necesarios via props, o usar `next/dynamic` con `{ ssr: true }`.

  ```tsx
  // ANTES (cliente)
  'use client'
  import brand from '@/brand/brand.json'  // ❌ expone bundle
  
  // DESPUÉS (server padre + client hijo con props)
  // Server: app/(marketing)/landing/page.tsx
  import brand from '@/brand/brand.json'
  
  export default function Page() {
    return <HeroBrand primaryColor={brand.tokens.colors.primary} />
  }
  
  // Client: HeroBrand.tsx
  'use client'
  export function HeroBrand({ primaryColor }: { primaryColor: string }) {
    // usar primaryColor sin importar brand.json
  }
  ```

---

## Alta Prioridad ({N} encontrados)

(Core Web Vitals fallan, barreras de a11y mayores. Fix antes de launch.)

### 1. [Performance] LCP image sin `priority`

- **Archivo:** `app/(marketing)/landing/Hero.tsx:42`
- **Impacto:** LCP medido {X}s (target ≤2.5s). Sin `priority`, Next.js lazy-loads la imagen above-fold.
- **Fix:**

  ```tsx
  // ANTES
  <Image src="/hero.webp" alt="..." width={1200} height={600} />
  
  // DESPUÉS
  <Image src="/hero.webp" alt="..." width={1200} height={600} priority />
  ```

### 2. [Accessibility] Botón icon-only sin `aria-label`

- **Archivo:** `components/ui/Toolbar.tsx:18`
- **Impacto:** Screen readers anuncian "button" sin contexto. Usuarios con asistivas no pueden identificar la función.
- **Fix:**

  ```tsx
  // ANTES
  <button onClick={openMenu}>
    <MenuIcon />
  </button>
  
  // DESPUÉS
  <button onClick={openMenu} aria-label="Abrir menú">
    <MenuIcon aria-hidden="true" />
  </button>
  ```

---

## Media Prioridad ({N} encontrados)

(Oportunidades de performance, mejoras SEO. Fix en el sprint.)

### 1. [SEO] Meta description ausente en `app/(marketing)/landing/page.tsx`

- **Archivo:** `app/(marketing)/landing/page.tsx`
- **Impacto:** Google genera description automática (a menudo subóptima). CTR en SERP cae típico 5-10%.
- **Fix:**

  ```tsx
  export const metadata: Metadata = {
    title: 'Landing — {nombre proyecto}',
    description: 'Descripción de hasta 160 caracteres con keyword principal y CTA implícito.',
  }
  ```

### 2. [Performance] Sin `preconnect` a CDN externo

- **Archivo:** `app/layout.tsx:15`
- **Impacto:** Conexión TCP + TLS handshake ~150-300ms en primer request a CDN. Visible en TTFB.
- **Fix:**

  ```tsx
  // En app/layout.tsx <head>
  <link rel="preconnect" href="https://cdn.example.com" crossOrigin="" />
  ```

---

## Baja Prioridad ({N} encontrados)

(Optimizaciones menores, calidad de código. Fix cuando convenga.)

### 1. [Code Quality] `console.log` detectado

- **Archivo:** `lib/utils/format.ts:12`
- **Impacto:** Logs en producción aumentan bundle size mínimo + ruido en console del usuario.
- **Fix:** envolver en condicional `process.env.NODE_ENV === 'development'` o eliminar.

---

## Resumen

| Categoría | Total | Critical | High | Medium | Low |
|-----------|-------|----------|------|--------|-----|
| Performance | {N} | {N} | {N} | {N} | {N} |
| Accessibility | {N} | {N} | {N} | {N} | {N} |
| SEO | {N} | {N} | {N} | {N} | {N} |
| Best Practices | {N} | {N} | {N} | {N} | {N} |
| **Total** | **{N}** | **{N}** | **{N}** | **{N}** | **{N}** |

---

## Pre-deploy Gate

**Status:** {PASS ✅ / NEEDS_FIX ❌}

Criterio:
- PASS = sin Critical/High Y Lighthouse targets cumplidos (Performance ≥90, Accessibility 100, BP ≥95, SEO ≥95)
- NEEDS_FIX = al menos 1 Critical/High o algún score < target

(Live mode):
- ✅ Performance {X}/100 (target ≥90)
- ✅ Accessibility {X}/100 (target 100)
- ❌ Best Practices {X}/100 (target ≥95) — falta {N} puntos por {issue}
- ✅ SEO {X}/100 (target ≥95)

(Static mode):
- N/A scores — gate evaluado solo por count de Critical/High

---

## Prioridad Recomendada

(Orden de aplicación de fixes por impacto + esfuerzo)

1. **`<html lang>`** — fix de 1 línea, desbloquea Accessibility 100. Hacer primero.
2. **`brand.json` en client bundle** — refactor moderado, crítico para D9 contract. Hacer antes de deploy.
3. **LCP image priority** — fix de 1 línea, impacto fuerte en Performance score.
4. **Meta description** — fix rápido, impacto SEO.
5. **preconnect CDN** — optimización menor.
6. **console.log cleanup** — rutinario.

---

## Checklist Pre-Deploy

- [ ] Core Web Vitals pasando (LCP ≤2.5s, INP ≤200ms, CLS ≤0.1)
- [ ] Lighthouse Accessibility 100
- [ ] Lighthouse Performance ≥90
- [ ] Lighthouse Best Practices ≥95
- [ ] Lighthouse SEO ≥95
- [ ] Sin console errors
- [ ] HTTPS funcionando
- [ ] Meta tags presentes (title + description + OG)
- [ ] `npm audit` sin vulnerabilidades high/critical
- [ ] brand/brand.css cargado en root layout
- [ ] brand/brand.json NO en bundle cliente
- [ ] Anti-slop hue range respetado en componentes (post-impeccable validation)

---

## Documentos de Referencia

| Tema | Doc |
|------|-----|
| Performance optimization (Next.js + Core Web Vitals) | [`.claude/skills/web-quality/references/performance.md`](../references/performance.md) |
| Accessibility (WCAG 2.1 AA) | [`.claude/skills/web-quality/references/accessibility.md`](../references/accessibility.md) |
| SEO (Next.js metadata API + structured data) | [`.claude/skills/web-quality/references/seo.md`](../references/seo.md) |
| Best Practices (security + modern + code quality) | [`.claude/skills/web-quality/references/best-practices.md`](../references/best-practices.md) |
| Mode selector rationale (binary D-015) | [`.claude/skills/web-quality/references/audit-mode-rationale.md`](../references/audit-mode-rationale.md) |

---

## Handoff

**Modo aplicado:** {live | static}
**Pre-deploy gate:** {PASS / NEEDS_FIX}

**Siguiente paso:**
- Si PASS y full pipeline → invocá el-guardian para complementar con OWASP/RLS/R14 audit
- Si PASS y solo build → handoff a humano para deploy (`/despachar`)
- Si NEEDS_FIX → fix los Critical/High primero, re-corré web-quality, después el-guardian
```

## Reglas de generación del reporte

1. **Code snippets en Critical/High obligatorios.** Cada issue Critical/High incluye snippet ANTES/DESPUÉS para clarificar fix. Medium/Low pueden omitir si fix es one-line obvio.

2. **Line numbers cuando localizable.** Pattern detection en static mode debe localizar `path/to/file.tsx:123`. Live mode usa source maps de Lighthouse para mapear.

3. **Status semáforo coherente.** Lighthouse score que cumple target → `ok`. Cerca del límite (≤5 puntos por debajo) → `warning`. Por debajo → `critical`. NO redondear hacia arriba.

4. **Pre-deploy gate explícito.** Sin gate, el reporte es informativo pero no accionable como pre-deploy check. Gate = PASS o NEEDS_FIX, sin "casi pass".

5. **Prioridad recomendada por impacto + esfuerzo.** No solo por severity — un Critical de 1 línea va antes que un Medium que requiere refactor moderado.

6. **Static mode sin scores numéricos explícito.** Caveat al inicio del reporte: "Static analysis — para scores numéricos correr live audit". Tabla de Lighthouse Scores omitida (o "N/A — modo static").

7. **Forja-specific checks visibles.** brand.css cargado + brand.json NO en cliente son Critical/High en categoría Best Practices. Citar D9 en impact statement.

8. **Cita docs en fixes contra libs externas.** Si fix involucra Next.js metadata API → cita `[docs:nextjs]` (asume find-docs invocado durante audit).

## Citation grammar

- [memory:CONSTRAINTS.md#R8] análogo — issues con location + impact + fix concretos.
- [memory:CONSTRAINTS.md#R13] — fixes contra libs externas citan `[docs:nextjs]` o `[docs:lighthouse]`.
- [memory:references#R-003] — agent-browser invocation referenced.
- [memory:decisions#D-015] — binary mode reflected en reporte (live scores vs static N/A).

## Refusals

- ❌ Reporte sin pre-deploy gate explícito (PASS o NEEDS_FIX, no "casi pass").
- ❌ Critical/High sin code snippet (gate de utilidad).
- ❌ Static mode con tabla Lighthouse Scores poblada (incoherente — no hay scores).
- ❌ Inventar line numbers cuando issue no es localizable.
- ❌ "No issues found" sin haber ejecutado las 4 categorías canónicas.
- ❌ Recomendar fix que viola Brand DNA contract (R10 — todo fix UI consume brand.json/css).
