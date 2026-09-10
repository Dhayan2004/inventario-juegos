# site-architecture — Planeación de estructura de sitio: jerarquía de páginas, navegación, URLs y enlazado interno
> Destilado de coreyhaines31/marketingskills (MIT) · skill original: site-architecture · fetched 2026-08-18

## Discovery questions
1. New site or restructure? 2. Site type? 3. Planned page count? 4. Top 5
priority pages? 5. URLs to preserve/redirect? 6. Primary audiences and goals?
(Read product-marketing.md context first if available.)

## Site type templates
| Type | Depth | URL pattern examples |
|---|---|---|
| SaaS marketing | 2-3 levels | `/features/name`, `/blog/slug` |
| Content/blog | 2-3 levels | `/blog/slug`, `/category/slug` |
| E-commerce | 3-4 levels | `/category/subcategory/product` |
| Documentation | 3-4 levels | `/docs/section/page` |
| Hybrid SaaS+content | 3-4 levels | mixed |
| Small business | 1-2 levels | `/services/name` |

## Hierarchy
- L0 homepage (`/`) · L1 primary sections (`/features`) · L2 section pages
  (`/features/analytics`) · L3+ detail (`/docs/api/authentication`).
- **3-click rule**: any important page reachable within 3 clicks from home.

## Navigation
Header (primary, always visible) · dropdowns (sub-pages) · footer (secondary,
legal) · sidebar (section nav) · breadcrumbs (location) · contextual links.

Header rules: max 4-7 items · CTA button rightmost · ordered by priority ·
mega menus max 3-4 columns.

## URL design principles
1. Human-readable (`/features/analytics`, not `/f/a123`)
2. Hyphens, never underscores
3. Mirror the hierarchy
4. Consistent trailing-slash policy
5. Always lowercase
6. Short but descriptive

Common mistakes: dates in blog URLs (kills evergreen value) · over-nesting ·
missing 301 redirects (lost backlink equity) · IDs instead of slugs · query
params for content · inconsistent patterns.

## Internal linking
- Link types: navigational, contextual, hub-and-spoke, cross-section.
- Rules: every page ≥1 inbound link · descriptive anchor text · ~5-10 links per
  1000 words · important pages get more links · breadcrumbs site-wide.
- Hub-and-spoke: pillar page links to spokes; spokes link back and cross-reference.

## Deliverables checklist
- [ ] Page hierarchy (ASCII tree with URLs)
- [ ] Visual sitemap (Mermaid `graph TD` with navigation zones)
- [ ] URL map table (page, URL, parent, nav location, priority)
- [ ] Navigation spec (header, footer, sidebar)
- [ ] Internal linking plan (hubs, cross-section opportunities)

## Related distilled refs
programmatic-seo.md, seo-audit.md, cro.md, schema.md (breadcrumbs),
product-marketing.md (context).
