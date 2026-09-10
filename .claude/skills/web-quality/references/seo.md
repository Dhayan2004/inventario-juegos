# SEO — referencia (Next.js 16 metadata API canónico)

> Search engine optimization basada en Lighthouse SEO + Google Search guidelines. Focus: technical SEO + on-page + structured data. **Next.js 16 App Router metadata API es canónico en Forja.**

## SEO fundamentals

Search ranking factors (influencia aproximada):

| Factor | Influence | Cubre web-quality |
|--------|-----------|-------------------|
| Content quality & relevance | ~40% | Parcial (estructura) |
| Backlinks & authority | ~25% | ✗ (off-page, fuera de scope) |
| Technical SEO | ~15% | ✓ |
| Page experience (Core Web Vitals) | ~10% | ver [`performance.md`](performance.md) |
| On-page SEO | ~10% | ✓ |

---

## Technical SEO

### Crawlability

**`app/robots.ts` programático (Next.js 16):**

```tsx
// app/robots.ts
import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/admin/', '/api/', '/private/'],
      },
    ],
    sitemap: 'https://example.com/sitemap.xml',
  }
}
```

**Meta robots:**

```tsx
export const metadata: Metadata = {
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-snippet': 150,
      'max-image-preview': 'large',
    },
  },
}
```

**Canonical URLs:**

```tsx
export const metadata: Metadata = {
  alternates: {
    canonical: 'https://example.com/page',
  },
}
```

### XML sitemap

**`app/sitemap.ts` programático:**

```tsx
// app/sitemap.ts
import { MetadataRoute } from 'next'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const products = await fetch('https://api.example.com/products').then(r => r.json())
  
  return [
    {
      url: 'https://example.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1.0,
    },
    {
      url: 'https://example.com/about',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.5,
    },
    ...products.map((p) => ({
      url: `https://example.com/products/${p.slug}`,
      lastModified: new Date(p.updated_at),
      changeFrequency: 'weekly' as const,
      priority: 0.8,
    })),
  ]
}
```

**Sitemap best practices:**
- Máximo 50,000 URLs o 50MB por sitemap (split en index si excede)
- Solo canonical, indexable URLs
- Update `lastModified` cuando contenido cambia
- Submit a Google Search Console post-deploy

### URL structure

```
✅ Good URLs:
https://example.com/products/blue-widget
https://example.com/blog/how-to-use-widgets

❌ Poor URLs:
https://example.com/p?id=12345
https://example.com/products/item/category/subcategory/blue-widget-2024-sale-discount
```

**URL guidelines:**
- Hyphens, no underscores
- Lowercase only
- Cortas (< 75 chars)
- Target keywords naturalmente

---

## On-page SEO (Next.js metadata API)

### Title tags (50-60 chars, keyword first)

```tsx
// app/(marketing)/landing/page.tsx
export const metadata: Metadata = {
  title: 'Forja — Harness para construir SaaS con AI agentes',
}

// O dinámico
export async function generateMetadata({ params }): Promise<Metadata> {
  const product = await getProduct(params.slug)
  return {
    title: `${product.name} — Pricing & Features`,
  }
}

// Title template (en root layout)
export const metadata: Metadata = {
  title: {
    default: 'Forja',
    template: '%s — Forja',  // todas las páginas heredan
  },
}
```

### Meta descriptions (150-160 chars)

```tsx
export const metadata: Metadata = {
  description:
    'Forja es un harness agentic-first para Claude Code. Construí SaaS production-ready con WCAG 2.1 AA + Brand DNA contract. Open source, self-hosted, optimizado para Anthropic Opus 4.7.',
}
```

### Heading hierarchy

```tsx
// ✅ Un solo h1 por página
export default function Page() {
  return (
    <main>
      <h1>Page main title</h1>
      <section>
        <h2>Section title</h2>
        <h3>Subsection</h3>
      </section>
    </main>
  )
}

// ❌ Múltiples h1
<h1>Title</h1>
<h1>Another title</h1>  // Lighthouse warning
```

### Open Graph + Twitter Cards

```tsx
export const metadata: Metadata = {
  openGraph: {
    title: 'Forja — Harness para construir SaaS con AI',
    description: '...',
    url: 'https://forja.dev',
    siteName: 'Forja',
    images: [
      {
        url: 'https://forja.dev/og-image.png',
        width: 1200,
        height: 630,
        alt: 'Forja',
      },
    ],
    locale: 'es_ES',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Forja — Harness para construir SaaS con AI',
    description: '...',
    creator: '@forja_dev',
    images: ['https://forja.dev/twitter-image.png'],
  },
}
```

### Internal linking

```tsx
import Link from 'next/link'

// ✅ Link descriptivo
<Link href="/pricing">View pricing details</Link>

// ❌ Click here
<Link href="/pricing">Click here</Link>

// ✅ Title attribute para context adicional
<Link href="/blog/intro" title="Read our intro to harness engineering">
  Get started
</Link>
```

---

## Structured data (JSON-LD)

### Article schema

```tsx
// app/blog/[slug]/page.tsx
export default async function BlogPost({ params }) {
  const post = await getPost(params.slug)
  
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: post.title,
    description: post.excerpt,
    image: post.coverImage,
    datePublished: post.publishedAt,
    dateModified: post.updatedAt,
    author: {
      '@type': 'Person',
      name: post.author.name,
      url: post.author.url,
    },
  }
  
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article>{/* contenido */}</article>
    </>
  )
}
```

### Product schema

```javascript
{
  '@context': 'https://schema.org',
  '@type': 'Product',
  name: 'Forja Pro',
  description: '...',
  image: 'https://forja.dev/product-image.png',
  offers: {
    '@type': 'Offer',
    price: '49.00',
    priceCurrency: 'USD',
    availability: 'https://schema.org/InStock',
  },
  aggregateRating: {
    '@type': 'AggregateRating',
    ratingValue: '4.8',
    reviewCount: '120',
  },
}
```

### FAQ schema

```javascript
{
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: [
    {
      '@type': 'Question',
      name: '¿Qué es Forja?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'Forja es un harness agentic-first...',
      },
    },
    // más Q&A
  ],
}
```

### Breadcrumb schema

```javascript
{
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://forja.dev' },
    { '@type': 'ListItem', position: 2, name: 'Blog', item: 'https://forja.dev/blog' },
    { '@type': 'ListItem', position: 3, name: 'Post title' },
  ],
}
```

**Validar:** [Google Rich Results Test](https://search.google.com/test/rich-results) para confirmar schema válido.

---

## Image SEO

```tsx
// ✅ Next.js Image con alt + width/height + lazy
<Image
  src="/blog/post-cover.webp"
  alt="Diagrama de pipeline el-crisol con 7 pasos"
  width={1200}
  height={630}
  loading="lazy"
/>

// Filename SEO-friendly
// ✅ /products/blue-widget-mockup.webp
// ❌ /img/IMG_1234.webp
```

---

## Internationalization (i18n)

```tsx
// app/layout.tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
  alternates: {
    canonical: 'https://example.com',
    languages: {
      'es-ES': 'https://example.com/es',
      'en-US': 'https://example.com/en',
      'pt-BR': 'https://example.com/pt',
    },
  },
}
```

`hreflang` correcto previene duplicate content cross-language.

---

## Performance + SEO (overlap)

Page experience como ranking factor:

- Core Web Vitals (LCP, INP, CLS) afectan ranking
- Mobile-first indexing — mobile UX critical
- HTTPS mandatory (HTTP penalizado)
- No interstitials intrusivos en mobile

Ver [`performance.md`](performance.md) para optimización.

---

## Lighthouse SEO audits — checklist

| Audit | Severity si fail |
|-------|------------------|
| `meta-description` | High |
| `document-title` | High |
| `crawlable-anchors` (links sin href válido) | High |
| `link-text` (link descriptivo) | Medium |
| `is-crawlable` (sin noindex en páginas importantes) | High |
| `robots-txt` (válido) | Medium |
| `canonical` (presente cuando aplica) | Medium |
| `font-size` (legible en mobile, ≥12px) | Medium |
| `tap-targets` (≥48×48px) | Medium |
| `hreflang` (válido si i18n) | Medium |
| `image-alt` (alt descriptivo) | High (también A11y) |
| `viewport` (meta viewport responsive) | Critical |

## Manual SEO checks

- [ ] Title tags únicos por página (50-60 chars)
- [ ] Meta descriptions únicas (150-160 chars)
- [ ] Un solo `<h1>` por página
- [ ] Heading hierarchy lógica (h1 → h2 → h3, sin saltos)
- [ ] Internal links descriptivos (no "click here")
- [ ] Image alt descriptivos (no "image1.png")
- [ ] Canonical URLs presentes
- [ ] Sitemap.xml accesible (`/sitemap.xml`)
- [ ] Robots.txt válido (`/robots.txt`)
- [ ] OG + Twitter Cards en pages compartibles
- [ ] Structured data JSON-LD en pages aplicables (Article, Product, FAQ)
- [ ] Validado en Google Rich Results Test
- [ ] Submitted en Google Search Console post-deploy

## Citation grammar

- [memory:CONSTRAINTS.md#R13] — find-docs antes de Next.js metadata API specifics.
- [docs:nextjs] — App Router metadata API canónica.
- [docs:schema-org] — JSON-LD schemas validados.

## Anti-patterns

- ❌ Title tags duplicados cross-pages.
- ❌ Meta descriptions ausentes (Google genera automática, subóptima).
- ❌ Múltiples `<h1>` por página.
- ❌ "Click here" como link text.
- ❌ Image alt vacío en imágenes informativas (alt="" solo para decorativas).
- ❌ Canonical apuntando a URL distinta en una página self-canonical.
- ❌ Sitemap con URLs `noindex`.
- ❌ Robots.txt bloqueando `/static/` o `/_next/` (rompe rendering).
- ❌ Structured data inválido (siempre validar en Rich Results Test).
- ❌ `hreflang` sin link bidireccional en páginas alternas.
