# schema — Structured data (schema.org / JSON-LD) para rich results en Google
> Destilado de coreyhaines31/marketingskills (MIT) · skill original: schema · fetched 2026-08-18

## When to use
User mentions "schema markup", "JSON-LD", "rich snippets", or wants enhanced
search visibility. Read product-marketing.md context first if available.

## Key principles
1. **Accuracy first** — schema must match the actual visible page content.
2. **Use JSON-LD** — Google's recommended format; place in `<head>` or before
   `</body>`.
3. **Follow Google guidelines** — only supported markup; no spammy/irrelevant
   structured data.
4. **Validate everything** — test before deployment (Rich Results Test).

## Common schema types & required properties
| Type | Use on | Required |
|---|---|---|
| Organization | company pages | name, url |
| Article / BlogPosting | blog content | headline, image, datePublished, author |
| Product | e-commerce pages | name, image, offers |
| FAQPage | FAQ sections | mainEntity array |
| BreadcrumbList | navigation paths | itemListElement |
| LocalBusiness / Event / SoftwareApplication | specialized pages | per type |

## Implementation approaches
- **Static sites** — add JSON-LD directly to templates.
- **Dynamic/React** — server-side render schema as components (must be in the
  HTML Google receives).
- **CMS/WordPress** — plugins (Yoast, Rank Math) or custom fields.

## Validation
- Google Rich Results Test (renders JavaScript)
- Schema.org Validator
- Search Console → Enhancements reports (post-deploy monitoring)

Note (from seo-audit.md): client-side-injected JSON-LD is invisible to static
HTML fetches — validate with a rendering tool before claiming schema is missing.

## Related distilled refs
seo-audit.md (schema review within broader audit), programmatic-seo.md
(templated schema at scale), site-architecture.md (breadcrumb planning).
