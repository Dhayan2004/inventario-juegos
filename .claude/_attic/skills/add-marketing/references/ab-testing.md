# ab-testing — Diseño de experimentos A/B estadísticamente válidos y programa de experimentación continua
> Destilado de coreyhaines31/marketingskills (MIT) · skill original: ab-testing · fetched 2026-08-18

## Hypothesis structure (mandatory)
> "Because **[observation]**, we believe **[change]** will cause
> **[expected outcome]** for **[audience]**."

No exploratory "let's see what happens" tests — every test needs a specific
prediction grounded in data or reasoning.

## Statistical rigor
- **Pre-determine sample size** before launching; commit to the methodology.
- **No early stopping / no peeking** — wait for the planned sample.
- Reference point: detecting a 20% lift at 5% baseline conversion needs
  ~7,000 users per variant. Use a sample-size calculator before every test.
- Significance threshold: p < 0.05, evaluated only at planned sample size.

## Metrics framework
- **Primary metric** — one, tied directly to the hypothesis.
- **Secondary metrics** — support interpretation.
- **Guardrail metrics** — catch negative side effects (e.g. revenue, churn).

## Test types
A/B (two versions) · A/B/n (multiple variants) · MVT (combinations) ·
split-URL. Traffic requirements scale with variant count and complexity.

## Program loop
hypothesis generation → ICE prioritization → test execution → analysis →
playbook documentation.

**ICE score** = (Impact + Confidence + Ease) / 3, each on a 10-point scale.
**Mature program benchmarks**: 4-8 experiments/month, 20-30% win rate.

## Pre-launch checklist
- [ ] Hypothesis documented · [ ] primary/secondary/guardrail metrics defined
- [ ] Sample size calculated · [ ] variants implemented and QA'd
- [ ] Tracking verified (see analytics.md)

## During the test
Monitor only for technical issues; document external factors (campaigns,
seasonality). Never modify variants mid-test.

## Analysis checklist
1. Planned sample size reached?
2. Statistical significance (p < 0.05)?
3. Effect size meaningful (not just significant)?
4. Secondary metrics consistent with the story?
5. Guardrails unharmed?
6. Segment-specific patterns worth follow-up tests?

Document every result (win, loss, flat) in a playbook — losses teach too.

## Related distilled refs
cro.md (hypothesis source), analytics.md (measurement setup),
copywriting.md (variant creation), product-marketing.md (context).
