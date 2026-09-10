# analytics — Setup y auditoría de tracking (GA4, GTM, eventos, UTMs): plan de medición orientado a decisiones
> Destilado de coreyhaines31/marketingskills (MIT) · skill original: analytics · fetched 2026-08-18

## Core principles
1. **Track for decisions, not data** — every event must inform a decision; no
   vanity metrics; quality over quantity.
2. **Start with the questions** — work backwards from decisions to events.
3. **Name things consistently** — establish conventions BEFORE implementing.
4. **Maintain data quality** — validate, monitor, prefer clean over abundant.

Pre-work: read product-marketing.md context; ask: what decisions will data
inform? key conversions? existing tracking/tools? tech stack? privacy needs?

## Naming conventions (object_action format)
`signup_completed`, `button_clicked`, `form_submitted`, `checkout_payment_completed`
- lowercase_with_underscores · specific (`cta_hero_clicked` > `button_clicked`)
- context goes in properties, not the event name · document every decision.

## Essential events
Marketing site: `cta_clicked` (button_text, location) · `form_submitted`
(form_type) · `signup_completed` (method, source) · `demo_requested`.
Product/app: `onboarding_step_completed` (step_number, step_name) ·
`feature_used` (feature_name) · `purchase_completed` (plan, value) ·
`subscription_cancelled` (reason).

Standard properties: Page (title, location, referrer) · User (user_id, user_type,
plan_type) · Campaign (source, medium, campaign, content, term) · Product (id,
name, category, price). Never duplicate automatic properties; **never PII**.

## Tracking plan template
```
# [Site] Tracking Plan
Tools: GA4, GTM · Last updated: [date]
| Event Name | Description | Properties | Trigger |
| Custom Dimension | Scope | Parameter |
| Conversion | Event | Counting (once/session vs every) |
```

## GA4 quick setup
1. Create property + data stream 2. Install gtag.js or GTM 3. Enable enhanced
measurement 4. Configure custom events 5. Mark conversions in Admin.
```javascript
gtag('event', 'signup_completed', { method: 'email', plan: 'free' });
```

## GTM model
Tags (code that executes) · Triggers (when they fire) · Variables (dynamic values).
```javascript
dataLayer.push({ event: 'form_submitted', form_name: 'contact', form_location: 'footer' });
```

## UTM strategy
utm_source (google, newsletter) · utm_medium (cpc, email, social) · utm_campaign
(spring_sale) · utm_content (hero_cta) · utm_term (paid keywords).
Lowercase everything; consistent separators; log all UTMs in a shared sheet.

## Validation checklist
- [ ] Events fire on correct triggers · [ ] property values correct
- [ ] No duplicate events (multiple containers, double triggers)
- [ ] Works across browsers/mobile · [ ] conversions recorded · [ ] no PII
Debug with: GA4 DebugView, GTM Preview Mode, Tag Assistant.

## Privacy
Cookie consent (EU/UK/CA) · consent mode · IP anonymization · data retention
settings · user deletion capability · collect only what's needed.

## Tool fit
GA4 (web, Google ecosystem) · Mixpanel/Amplitude (product analytics) · PostHog
(open-source + session replay) · Segment (CDP/routing).

## Related distilled refs
ab-testing.md (experiment tracking), cro.md (uses this data),
seo-audit.md (organic traffic), product-marketing.md (context).
