# Brand Score Delta — F3-S2 vs F3-tighten-brand-dna

> Comparison of per-component Brand Score before and after R-005
> v1.0 → v1.1.0 schema bump and downstream regen.
>
> **Threshold:** ≥ 75 per component, ≥ 75 average.
> **F3-tighten goal:** maintain or improve scores; zero regression.

## Per-component delta

| Component | F3-S2 (v1.0) | F3-tighten (v1.1.0) | Δ | Notes |
|------------|------:|------:|---:|-------|
| Button | 93 | 93 | 0 | unchanged — consumes tokens.colors + shape only |
| Card | 85 | 85 | 0 | unchanged |
| Input | 94 | 94 | 0 | unchanged |
| Textarea | 94 | 94 | 0 | unchanged |
| Select | 94 | 94 | 0 | unchanged |
| Modal | 90 | 90 | 0 | unchanged |
| Sidebar | 94 | 94 | 0 | unchanged |
| Topbar | 84 | 84 | 0 | unchanged |
| Tabs | 90 | 90 | 0 | unchanged |
| Breadcrumb | 84 | 84 | 0 | unchanged |
| DataTable | 92 | 92 | 0 | unchanged — Mode B rationale block intact |
| **Average** | **90.4** | **90.4** | **0** | **no regression** |

## Interpretation

Zero delta is the expected outcome. None of the 11 components
reference `var(--section-y-*)` or `var(--gap-*)` arbitrary values
— they use Tailwind core scale (h-10, p-4, gap-2) for ad-hoc
spacing. The R-005 v1.1.0 changes affected:

- `tokens.spacing.section_y/component_gap` shape (array → keyed)
- `motion.personality.*` enum closures
- `archetype.*_behaviors` documentation clarification

None of these changed the spacing/sizing utility classes used by
the components. The brand.json keyed spacing surfaces NEW
utilities (`py-section-md`, `gap-gap-md`) that future components
or re-baselined existing ones can adopt — but adoption is
opt-in, not blocking.

## Future improvement opportunity

When a component adopts the semantic spacing utilities (e.g.,
Page-level layouts in F3-S5 add-login forms using `py-section-lg`
for hero sections, or DataTable using `gap-gap-md` for column
spacing), the `token_compliance` dimension may bump from 25 to
25 (no change — already at max; the new vars don't add new
penalties). The semantic clarity gain is qualitative, not
quantitative for Brand Score.

## Citation

Full Brand Score breakdown at run-time: `bash .claude/
skills/impeccable/tests/brand-score.sh`. This delta document
serves as the F3-tighten-brand-dna closure evidence.

[memory:decisions#D-008] documents the schema evolution rationale.
