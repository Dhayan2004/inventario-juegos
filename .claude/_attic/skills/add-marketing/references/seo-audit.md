# seo-audit — Auditoría SEO técnica y de contenido: diagnóstico de problemas de ranking/tráfico con plan de acción priorizado
> Destilado de coreyhaines31/marketingskills (MIT) · skill original: seo-audit · fetched 2026-08-18

## Pre-audit
Read product-marketing context (product-marketing.md) first. Then ask: site type &
goal · current organic traffic & known issues · scope (full / technical+on-page /
specific area) · Search Console/analytics access?

## Audit framework (priority order)
1. Crawlability & indexation → 2. Technical foundations → 3. On-page →
4. Content quality → 5. Authority & links

## Technical checklist
- **Crawlability**: robots.txt correct + references sitemap; XML sitemap with only
  canonical URLs, submitted to GSC; important pages ≤3 clicks from home; crawl
  budget (parameterized URLs controlled, no infinite traps).
- **Indexation**: `site:domain.com` vs GSC coverage; no unintended noindex;
  canonicals self-referencing or correct; no redirect chains/loops; soft 404s.
- **Core Web Vitals**: LCP < 2.5s · INP < 200ms · CLS < 0.1; TTFB, image
  optimization, JS/CSS delivery, caching + CDN.
- **Mobile**: responsive (no m. subdomain), tap targets, viewport, no horizontal
  scroll, feature parity.
- **Security**: full HTTPS, valid SSL, no mixed content, HTTP→HTTPS redirects.
- **URLs**: readable, lowercase, hyphens, consistent, no junk parameters.

## On-page checklist
- **Titles**: unique; primary keyword near start; 50-60 chars; brand at end.
- **Meta descriptions**: unique; 150-160 chars; keyword + value prop + CTA.
- **Headings**: one H1 (with primary keyword); logical H1→H2→H3, no skips.
- **Content**: keyword in first 100 words; satisfies intent; deeper than
  competitors; flag thin content (tag/category/doorway pages).
- **Images**: descriptive filenames + alt text (describe, don't stuff); WebP,
  compression, lazy loading.
- **Internal linking**: important pages well-linked; descriptive anchors; no
  orphans; no broken links.
- **Keyword targeting**: one clear primary keyword per page; title/H1/URL aligned;
  no cannibalization; topical clusters mapped.

## Content quality (E-E-A-T)
Experience (first-hand, original examples) · Expertise (credentials, accuracy) ·
Authoritativeness (cited by others) · Trustworthiness (transparent, contact/
privacy/terms, HTTPS). Compare depth vs top-ranking competitors; keep updated.

## International SEO (if multilingual)
- Hreflang: self-referencing entry on every page; reciprocal links; valid ISO
  codes (`en-GB`, never `en-UK`); `x-default` present; targets 200/indexable/
  canonical. One missing self-reference invalidates the whole set.
- Canonicals: each locale self-canonicals; NEVER cross-locale canonical;
  canonical URL must appear in the hreflang set.
- Sitemaps: `xmlns:xhtml` namespace, each URL lists all locales incl. itself.
  Next.js caveat: `alternates.languages` does NOT auto-include self-reference.
- URL structure: subdirectories (`/en/`) recommended; never `?lang=` params;
  no IP/Accept-Language redirects. Translate ALL content, not just chrome.

## Site-type-specific issues
SaaS: thin product/feature pages, missing comparison pages · E-commerce: thin
categories, duplicate descriptions, missing Product schema, faceted duplication ·
Blog: stale content, cannibalization, no clustering · Local: inconsistent NAP,
missing LocalBusiness schema, neglected Google Business Profile.

## Report format
Executive summary (health, top 3-5 issues, quick wins) → findings per area
(What's wrong | Impact | Evidence | Fix | Priority) → action plan: 1) critical
fixes 2) high-impact 3) quick wins 4) long-term.

## Schema detection caveat
JSON-LD injected client-side won't appear in static HTML fetches. Validate with
a real browser (`document.querySelectorAll('script[type="application/ld+json"]')`),
Google Rich Results Test, or Screaming Frog — never report "no schema" from a
static fetch alone.

## Related distilled refs
programmatic-seo.md, site-architecture.md, schema.md, cro.md, analytics.md.
