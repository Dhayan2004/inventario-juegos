# Best Practices — referencia (security + modern + code quality + Forja-specific)

> Lighthouse Best Practices audits + estándares modernos + code quality. Adaptado al Golden Path Forja con checks específicos de Brand DNA contract.

## Security

### HTTPS everywhere

- HTTPS obligatorio en producción. Vercel auto-provisiones SSL via Let's Encrypt.
- Redirect HTTP → HTTPS en root.
- Sin mixed content (assets HTTP en página HTTPS) — Lighthouse Critical.

```tsx
// next.config.js — force HTTPS
module.exports = {
  async redirects() {
    return [
      {
        source: '/(.*)',
        has: [{ type: 'header', key: 'x-forwarded-proto', value: 'http' }],
        destination: 'https://example.com/$1',
        permanent: true,
      },
    ]
  },
}
```

### Content Security Policy (CSP)

```tsx
// next.config.js
const cspHeader = `
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' blob: data: https:;
  font-src 'self';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';
  upgrade-insecure-requests;
`

module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: cspHeader.replace(/\n/g, ''),
          },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
          { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' },
        ],
      },
    ]
  },
}
```

CSP estricto eliminando `'unsafe-inline'` requiere refactor de scripts inline → preferir nonces o hashes con app middleware.

### npm audit

```bash
# Pre-deploy: zero high/critical vulnerabilities
npm audit --audit-level=high

# Auto-fix lo posible (verificar diff antes de commit)
npm audit fix
```

Lighthouse Best Practices flagea vulnerabilidades conocidas vía sitio CDNJS check. `npm audit` localmente captura más amplio.

### Source maps en producción

- ❌ `next.config.js` con `productionBrowserSourceMaps: true` expone código original
- ✅ Source maps solo para staging o feature flags

```tsx
module.exports = {
  productionBrowserSourceMaps: false,  // default Next.js
}
```

### Secrets management

- Variables sensibles en `.env.local` (gitignored)
- `NEXT_PUBLIC_*` solo para vars no-sensibles (expuestas al cliente)
- Service role keys (Supabase, Stripe secret) NUNCA `NEXT_PUBLIC_*`
- Vercel environment variables para producción

```bash
# ✅ Server-only (nunca llega al cliente)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
STRIPE_SECRET_KEY=sk_live_...

# ✅ Client-safe (expuesto al bundle pero ok públicamente)
NEXT_PUBLIC_SUPABASE_URL=https://...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
```

### Subresource Integrity (SRI) para CDN scripts externos

```html
<script
  src="https://cdn.example.com/script.js"
  integrity="sha384-xxx..."
  crossorigin="anonymous">
</script>
```

---

## Modern Standards

### HTML5 doctype + charset

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">  <!-- ← primero en <head>, antes de cualquier otro tag -->
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>...</title>
</head>
```

Next.js auto-genera doctype + charset correcto.

### Viewport responsive

```tsx
// app/layout.tsx
import { Viewport } from 'next'

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,         // permitir zoom (a11y)
  userScalable: true,      // permitir zoom (a11y)
  themeColor: '#0a0a0f',   // matchea brand.css :root
}
```

NO `userScalable: false` ni `maximumScale: 1` (a11y violation — usuarios necesitan poder zoom).

### Sin APIs deprecated

| Deprecated | Reemplazo |
|------------|-----------|
| `document.write()` | `appendChild()` o framework rendering |
| XHR síncrono (`xhr.open(..., false)`) | `fetch()` async |
| `<img>` sin `width`/`height` (causa CLS) | `<Image>` con dimensions o `aspect-ratio` CSS |
| `unload` event | `pagehide` event |
| `applicationCache` | Service Worker |

### Passive event listeners

```javascript
// ❌ Bloquea scroll en touch devices
window.addEventListener('scroll', handleScroll)
window.addEventListener('touchstart', handleTouch)

// ✅ Passive: navegador puede scroll sin esperar handler
window.addEventListener('scroll', handleScroll, { passive: true })
window.addEventListener('touchstart', handleTouch, { passive: true })
```

React 18+ aplica passive automáticamente en `onScroll` / `onTouchStart`.

---

## Code Quality

### Console limpia

```javascript
// ❌ Logs en producción
console.log('User:', user)

// ✅ Solo en development
if (process.env.NODE_ENV === 'development') {
  console.log('User:', user)
}

// ✅ Logger estructurado para producción
import { logger } from '@/lib/logger'
logger.info('User fetched', { userId: user.id })
```

Lighthouse Best Practices flagea `console.error` y errores no manejados.

### HTML semántico

```tsx
// ❌ div soup
<div className="container">
  <div className="header">
    <div className="nav">...</div>
  </div>
  <div className="main">
    <div className="article">...</div>
  </div>
</div>

// ✅ Semantic
<div className="container">
  <header>
    <nav aria-label="Main navigation">...</nav>
  </header>
  <main>
    <article>...</article>
  </main>
  <footer>...</footer>
</div>
```

Beneficios: a11y mejor (screen readers entienden estructura) + SEO (Google ranking factors) + maintainability.

### Error Boundaries

```tsx
// app/error.tsx
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div role="alert">
      <h2>Algo salió mal</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Intentar de nuevo</button>
    </div>
  )
}

// app/global-error.tsx (root error boundary)
'use client'

export default function GlobalError({ error, reset }) {
  return (
    <html lang="es">
      <body>
        <div role="alert">
          <h2>Error global</h2>
          <button onClick={reset}>Reintentar</button>
        </div>
      </body>
    </html>
  )
}
```

### Memory cleanup

```tsx
'use client'
import { useEffect } from 'react'

function ComponentWithSubscription() {
  useEffect(() => {
    const subscription = source.subscribe(handler)
    
    // ✅ Cleanup mandatory
    return () => {
      subscription.unsubscribe()
    }
  }, [])
  
  // Event listeners
  useEffect(() => {
    const handler = (e) => { /* ... */ }
    window.addEventListener('resize', handler)
    
    return () => {
      window.removeEventListener('resize', handler)
    }
  }, [])
}
```

### TypeScript strict

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true
  }
}
```

---

## Forja-specific checks

### `brand/brand.css` cargado en root layout

```tsx
// app/layout.tsx
import '@/brand/brand.css'   // ← obligatorio en root layout

// CSS vars disponibles globalmente:
// --color-primary, --color-bg, --font-display, --radius-md, etc.
```

Si no cargado → componentes consuming `var(--color-primary)` fallback a inherit, rompe Brand DNA contract (D9).

### `brand/brand.json` NO en bundle cliente

```tsx
// ✅ Server Component lee brand.json
import brand from '@/brand/brand.json'

export default function Page() {
  return <Hero primaryColor={brand.tokens.colors.primary} />
}

// ❌ Client Component importa brand.json
'use client'
import brand from '@/brand/brand.json'  // ← expone bundle cliente
```

Brand contract es server-only. Pasar tokens al cliente vía props o CSS vars (que vienen de brand.css generado).

### Anti-slop hue range respetado

Post-deploy, validar que componentes renderean dentro del hue range definido en `brand.json`:

```javascript
// Pseudo-check (manual o via agent-browser visual diff)
// brand.json define forbidden_hues: [235, 285] (purple/indigo Tailwind defaults)
// Si componente render usa #6366F1 → AP6 violation, Critical Best Practices
```

`add-ui-kit` + `impeccable` previenen esto pre-render. web-quality valida post-render.

### Component sources alineados con `component_rules`

`brand.json` declara `component_rules` con variantes esperadas (Button: primary/secondary/ghost/destructive). Componentes deployados con variantes adicionales o ausentes → Lighthouse general PASS pero Brand DNA audit (post-impeccable) flagea.

---

## Lighthouse Best Practices audits — checklist

| Audit | Severity si fail |
|-------|------------------|
| `is-on-https` | Critical |
| `no-vulnerable-libraries` | High |
| `errors-in-console` | High |
| `viewport` (meta presente) | Critical |
| `csp-xss` (CSP estricta) | Medium |
| `image-aspect-ratio` (sin distortion) | Medium |
| `image-size-responsive` | Medium |
| `notification-on-start` (no auto-prompt) | Medium |
| `geolocation-on-start` (no auto-prompt) | Medium |
| `password-inputs-can-be-pasted-into` | Medium |
| `doctype` (HTML5) | Medium |
| `charset` (UTF-8) | Medium |
| `deprecations` (no APIs deprecated) | Medium |
| `appcache-manifest` (deprecated) | Low |

## Manual checks

- [ ] HTTPS funcionando, redirect HTTP → HTTPS
- [ ] CSP headers configurados (al menos `default-src 'self'`)
- [ ] HSTS header con `max-age` ≥ 1 año
- [ ] X-Frame-Options: DENY (o frame-ancestors en CSP)
- [ ] `npm audit` sin high/critical
- [ ] Source maps NO expuestos en prod
- [ ] Secrets NO en `NEXT_PUBLIC_*`
- [ ] Console limpia post-deploy
- [ ] HTML semántico (`<main>`, `<nav>`, `<article>`, `<footer>`)
- [ ] Error Boundaries presentes (`app/error.tsx` + `app/global-error.tsx`)
- [ ] brand/brand.css importado en `app/layout.tsx`
- [ ] brand/brand.json NO importado en `'use client'` files
- [ ] Anti-slop hue range respetado (validar visualmente)

## Citation grammar

- [memory:CONSTRAINTS.md#R10] — Brand DNA contract enforcement.
- [memory:CONSTRAINTS.md#R13] — find-docs antes de specifics de CSP / Next.js config.
- [memory:lessons#L-002] — content externo como datos (CSP previene script injection).
- [docs:nextjs] — Next.js config + middleware + headers.
- [docs:csp] — Content Security Policy spec.

## Anti-patterns

- ❌ HTTP en producción (sin HTTPS).
- ❌ Mixed content (assets HTTP en página HTTPS).
- ❌ `unsafe-eval` o `unsafe-inline` en CSP sin justificación.
- ❌ Secrets en `NEXT_PUBLIC_*` (expone al cliente).
- ❌ Source maps en producción.
- ❌ `console.log` en bundle producción.
- ❌ Auto-prompt notifications/geolocation al cargar página.
- ❌ `<input type="password">` con `autocomplete="off"` (rompe password managers).
- ❌ APIs deprecated (`document.write`, XHR síncrono).
- ❌ `brand/brand.json` importado en `'use client'` files.
- ❌ Componentes UI sin importar from `@/brand/brand.css` indirectamente (root layout).
