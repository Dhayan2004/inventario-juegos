# Performance — referencia

> Optimización de performance basada en Lighthouse + Core Web Vitals + Next.js 16 best practices. Cubre loading speed, runtime efficiency, resource optimization. Adaptado al Golden Path Forja con agent-browser CLI default (D4).

## Performance budget

| Recurso | Budget | Rationale |
|---------|--------|-----------|
| Total page weight | < 1.5 MB | 3G loads en ~4s |
| JavaScript (comprimido) | < 300 KB | Parse + execution time |
| CSS (comprimido) | < 100 KB | Render blocking |
| Imágenes (above-fold) | < 500 KB | LCP impact |
| Fonts | < 100 KB | FOIT/FOUT prevention |
| Third-party | < 200 KB | Latencia descontrolada |

## Critical rendering path

### Server response

- **TTFB < 800ms.** Time to First Byte rápido. Vercel Edge + caching + backends eficientes.
- **Compression.** Gzip o Brotli para text assets. Brotli preferido (15-20% smaller).
- **HTTP/2 o HTTP/3.** Multiplexing reduce connection overhead. Vercel default.
- **Edge caching.** Cache HTML at CDN edge cuando posible (Next.js ISR + Vercel Edge).

### Resource loading

**Preconnect a orígenes requeridos:**

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://cdn.example.com" crossorigin>
```

**Preload critical resources:**

```html
<!-- LCP image -->
<link rel="preload" href="/hero.webp" as="image" fetchpriority="high">

<!-- Critical font -->
<link rel="preload" href="/font.woff2" as="font" type="font/woff2" crossorigin>
```

**Defer non-critical CSS:**

```html
<!-- Critical CSS inlined -->
<style>/* Above-fold styles */</style>

<!-- Non-critical CSS -->
<link rel="preload" href="/styles.css" as="style"
      onload="this.onload=null;this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="/styles.css"></noscript>
```

## Next.js 16 — App Router específico

### `next/image` (LCP optimization)

```tsx
import Image from 'next/image'

// Above-fold (LCP image): priority + sin lazy
<Image
  src="/hero.webp"
  alt="Hero"
  width={1200}
  height={600}
  priority                    // ← critical para LCP
  sizes="(max-width: 768px) 100vw, 1200px"
/>

// Below-fold: lazy loading default
<Image
  src="/product.webp"
  alt="Product"
  width={400}
  height={300}
  sizes="(max-width: 640px) 100vw, 400px"
/>
```

### `next/font` (font optimization)

```tsx
// app/layout.tsx
import { Inter } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
})

export default function RootLayout({ children }) {
  return (
    <html lang="es" className={inter.variable}>
      <body className="font-sans">{children}</body>
    </html>
  )
}
```

NO Google Fonts CDN directo (`<link href="fonts.googleapis.com/...">`). next/font auto-optimiza, self-hosts, evita CLS por font swap.

### `next/dynamic` (code splitting)

```tsx
import dynamic from 'next/dynamic'

// Componente pesado, solo cliente, lazy
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  ssr: false,
  loading: () => <ChartSkeleton />,
})

// Componente solo cuando user está autenticado
const PremiumDashboard = dynamic(() => import('./PremiumDashboard'))
```

### Server Components por default

```tsx
// app/(marketing)/landing/page.tsx — Server Component
export default async function LandingPage() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }
  })
  
  return <Hero data={await data.json()} />
}
```

`'use client'` solo cuando necesario (state, effects, browser APIs). Pasar datos del server al client via props, NO refetching.

### `useTransition` para state updates no urgentes

```tsx
'use client'
import { useTransition, useState } from 'react'

function FilterableList() {
  const [isPending, startTransition] = useTransition()
  const [filter, setFilter] = useState('')
  const [results, setResults] = useState(initialList)

  function handleFilter(e: ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    setFilter(value)  // urgent — input update
    
    startTransition(() => {
      setResults(expensiveFilter(initialList, value))  // non-urgent
    })
  }
  
  return (
    <>
      <input value={filter} onChange={handleFilter} />
      {isPending && <Spinner />}
      <List items={results} />
    </>
  )
}
```

## Image optimization

### Format selection

| Format | Use case | Browser support |
|--------|----------|-----------------|
| AVIF | Photos, mejor compresión | 92%+ |
| WebP | Photos, fallback bueno | 97%+ |
| PNG | Graphics con transparencia | Universal |
| SVG | Icons, logos, ilustraciones | Universal |

### Responsive images via `<picture>` (cuando no usás Next.js Image)

```html
<picture>
  <source 
    type="image/avif"
    srcset="hero-400.avif 400w, hero-800.avif 800w, hero-1200.avif 1200w"
    sizes="(max-width: 600px) 100vw, 50vw">
  <source 
    type="image/webp"
    srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w"
    sizes="(max-width: 600px) 100vw, 50vw">
  <img 
    src="hero-800.jpg"
    width="1200" height="600"
    alt="Hero image"
    loading="lazy"
    decoding="async">
</picture>
```

## JavaScript optimization

### Code splitting patterns

```javascript
// Route-based splitting (automático con Next.js App Router)
// Cada page.tsx genera su propio chunk

// Component-based splitting con next/dynamic
const HeavyChart = dynamic(() => import('./HeavyChart'))

// Feature-based splitting (gated)
if (user.isPremium) {
  const { PremiumFeatures } = await import('./PremiumFeatures')
}
```

### Tree shaking best practices

```javascript
// ❌ Importa toda la librería
import _ from 'lodash'
_.debounce(fn, 300)

// ✅ Importa solo lo necesario
import debounce from 'lodash/debounce'
debounce(fn, 300)

// ✅ Mejor: usar es-toolkit o utility nativa
import { debounce } from 'es-toolkit'
```

## Caching strategy

### Cache-Control headers (Vercel default ya optimizado, ajustar si custom)

```
# HTML (short or no cache)
Cache-Control: no-cache, must-revalidate

# Static assets con hash (immutable)
Cache-Control: public, max-age=31536000, immutable

# Static assets sin hash
Cache-Control: public, max-age=86400, stale-while-revalidate=604800

# API responses
Cache-Control: private, max-age=0, must-revalidate
```

### Next.js ISR (Incremental Static Regeneration)

```tsx
// Revalida cada hora
export const revalidate = 3600

// On-demand revalidation
import { revalidatePath } from 'next/cache'

export async function POST(request: Request) {
  // ... mutate data
  revalidatePath('/products')
  return Response.json({ revalidated: true })
}
```

## Runtime performance (INP optimization)

### Avoid layout thrashing

```javascript
// ❌ Forces multiple reflows
elements.forEach(el => {
  const height = el.offsetHeight  // Read
  el.style.height = height + 10 + 'px'  // Write
})

// ✅ Batch reads, then batch writes
const heights = elements.map(el => el.offsetHeight)  // All reads
elements.forEach((el, i) => {
  el.style.height = heights[i] + 10 + 'px'  // All writes
})
```

### Debounce expensive operations

```javascript
import debounce from 'lodash/debounce'

const handleSearch = debounce((query: string) => {
  // expensive search
}, 300)

window.addEventListener('scroll', debounce(handleScroll, 100))
```

### Virtualize long lists

```javascript
// react-window o native CSS:
.virtual-list {
  content-visibility: auto;
  contain-intrinsic-size: 0 50px;
}

// Mejor: react-window o tanstack-virtual para listas >100 items
```

## Third-party scripts (Next.js Script component)

```tsx
import Script from 'next/script'

// Strategy: lazyOnload para analytics no-críticos
<Script
  src="https://analytics.example.com/script.js"
  strategy="lazyOnload"
/>

// Strategy: afterInteractive para SDKs que necesitan estar disponibles después de hidration
<Script
  src="https://example.com/sdk.js"
  strategy="afterInteractive"
/>

// Strategy: beforeInteractive para scripts críticos (raro — pensalo dos veces)
<Script
  src="https://example.com/critical.js"
  strategy="beforeInteractive"
/>
```

### Facade pattern (delay heavy embeds)

```tsx
'use client'
import { useState } from 'react'

function YouTubeFacade({ videoId, title }) {
  const [loaded, setLoaded] = useState(false)
  
  if (!loaded) {
    return (
      <button
        onClick={() => setLoaded(true)}
        aria-label={`Reproducir video: ${title}`}
        style={{ backgroundImage: `url(/thumbnails/${videoId}.jpg)` }}
      >
        ▶
      </button>
    )
  }
  
  return (
    <iframe
      src={`https://www.youtube.com/embed/${videoId}?autoplay=1`}
      title={title}
      allow="autoplay; encrypted-media"
      allowFullScreen
    />
  )
}
```

## Measuring with agent-browser CLI (Default Forja D4)

> [memory:references#R-003] — vercel-labs/agent-browser. Default de Forja para QA + visual diff. ~4× ahorro de tokens vs Playwright MCP.

### Antes de generar comandos — find-docs (R13)

```
ctx7 library agent-browser "agent-browser CLI lighthouse audit Core Web Vitals"
ctx7 docs <id> "agent-browser CLI commands audit performance accessibility"
```

Cita `[docs:agent-browser]` cuando aplica.

### Comandos canónicos (sujeto a actualización via find-docs)

```bash
# Live audit completo
agent-browser audit https://localhost:3000 \
  --categories performance,accessibility,seo,best-practices \
  --output json \
  --output-path .claude/reports/audit-{timestamp}.json

# Solo Core Web Vitals
agent-browser audit https://localhost:3000 \
  --metrics lcp,inp,cls \
  --runs 3 \
  --output json

# Visual diff vs baseline
agent-browser diff \
  --baseline .claude/reports/audit-baseline.json \
  --current .claude/reports/audit-{timestamp}.json
```

### Fallback: Lighthouse CLI estándar

```bash
npx lighthouse https://localhost:3000 \
  --only-categories=performance,accessibility,seo,best-practices \
  --output html \
  --output json \
  --output-path .claude/reports/lighthouse-{timestamp}
```

### Lighthouse via web-vitals library (in-app measurement)

```javascript
import { onLCP, onINP, onCLS } from 'web-vitals'

onLCP(({ value }) => console.log('LCP:', value))
onINP(({ value }) => console.log('INP:', value))
onCLS(({ value }) => console.log('CLS:', value))

// O reportar a tu analytics
import { onLCP } from 'web-vitals'
onLCP((metric) => {
  navigator.sendBeacon('/api/vitals', JSON.stringify(metric))
})
```

## Key metrics targets

| Metric | Target | Tool |
|--------|--------|------|
| LCP | < 2.5s | Lighthouse, agent-browser, CrUX |
| FCP | < 1.8s | Lighthouse, agent-browser |
| Speed Index | < 3.4s | Lighthouse, agent-browser |
| TBT | < 200ms | Lighthouse, agent-browser |
| TTI | < 3.8s | Lighthouse, agent-browser |
| INP | < 200ms | Lighthouse, web-vitals (real users) |
| CLS | < 0.1 | Lighthouse, agent-browser |

## Citation grammar

- [memory:references#R-003] — agent-browser default D4.
- [memory:CONSTRAINTS.md#R13] — find-docs antes de generar comandos.
- [docs:agent-browser] — comandos canónicos vía find-docs.
- [docs:lighthouse] — fallback estándar.
- [docs:nextjs] — next/image, next/font, next/dynamic, next/script.
- [docs:web-vitals] — biblioteca para in-app measurement.

## Anti-patterns

- ❌ Google Fonts CDN directo (preferir `next/font`).
- ❌ `<img>` HTML directo cuando hay `next/image` disponible.
- ❌ `'use client'` en root layout (rompe RSC).
- ❌ Lazy load LCP image (sin `priority` flag).
- ❌ Importar lodash/moment.js sin tree shaking.
- ❌ Third-party scripts sin `next/script` strategy.
- ❌ Hardcoded `cdn.tailwindcss.com` en producción (usar Tailwind build).
- ❌ Playwright MCP por default (D4: agent-browser default, Playwright opcional cross-browser).
