# product-marketing — Documento fundacional de posicionamiento, audiencia y messaging que los demás skills de marketing consumen como contexto
> Destilado de coreyhaines31/marketingskills (MIT) · skill original: product-marketing · fetched 2026-08-18

## Purpose
Create and maintain a single product-marketing context document that every other
marketing skill reads before doing its work. In this harness, treat it as the
project's marketing context file (e.g. `.agents/product-marketing.md` or your
project's equivalent).

## Workflow

### Step 1 — Check for existing context
- If a product-marketing context doc exists: read it, summarize current state
  (version, recent changelog entries), ask which sections need updating.
- If missing, offer two paths:
  1. **Auto-draft from the codebase** (recommended): study README, landing pages,
     marketing copy, package metadata, then present a draft for review.
  2. **From scratch**: walk through sections one at a time with targeted questions.

### Step 2 — Gather information
- Prioritize **verbatim customer language** over polished internal descriptions.
- Pull real phrases from reviews, support tickets, sales calls, testimonials.

### Step 3 — Document structure (12 sections)
1. Product Overview — what it is, category, one-line positioning
2. Target Audience — ICP, segments
3. Personas — roles, goals, context
4. Problems & Pain Points — jobs to be done, triggers
5. Competitive Landscape — direct/indirect alternatives
6. Differentiation — why us, unique capabilities
7. Objections & Anti-Personas — who it's NOT for, common pushback
8. Switching Dynamics — what they switch from, switching costs
9. Customer Language — verbatim phrases customers use
10. Brand Voice — tone, style, words to use/avoid
11. Proof Points — metrics, case studies, logos, reviews
12. Goals — business/marketing goals the messaging serves

Use markdown with tables and consistent formatting.

### Step 4 — Confirm, version, save
- New doc: v1 with a single changelog entry.
- Updates: increment version, update "Last updated" date, prepend changelog entry.
- Typo fixes do not require a version bump.
- Changelog entries must name affected sections and the reasoning, not generic
  descriptions. Good: "Repositioned from email tool to deliverability platform;
  added RevOps to ICP". Bad: "updated the doc".

## Consumed by
All other distilled skills in this set check for this context doc first:
cro.md, seo-audit.md, programmatic-seo.md, site-architecture.md, schema.md,
copywriting.md, copy-editing.md, analytics.md, ab-testing.md, onboarding.md.
