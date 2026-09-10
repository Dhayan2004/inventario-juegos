---
description: "Unit economics + proyecciones financieras + sensitivity analysis — paso 5 de el-crisol."
---

# /roi — ROI & Financial Projections

Calcula unit economics, proyecciones a 12-36 meses, sensitivity analysis. Sub-análisis individual de `el-crisol` (paso 5 de 7).

## Ejecución

Lee `.claude/skills/el-crisol/SKILL.md` y ejecuta **solo el paso `roi`** del pipeline.

## Análisis

Genera `ROI-PROJECTIONS-<nombre>.md` con:

1. **Unit economics:**
   - LTV (gross margin × ARPU × 1/churn)
   - CAC por canal (paid + organic blended)
   - LTV:CAC ratio (target ≥3:1, healthy ≥4:1)
   - Payback period (target <12 meses, ideal <6)
   - Gross margin (target SaaS ≥75%)
2. **Cost structure** — fixed (infra, salarios) vs variable (transactional fees, AI tokens, soporte).
3. **Revenue projection (12 / 24 / 36 meses):**
   - 3 escenarios (conservador / base / optimista)
   - Drivers explícitos (CAC, conversion, churn, ARPU)
   - MRR / ARR / cash flow
4. **Sensitivity analysis** — qué passa si CAC sube 50% / churn sube 30% / pricing baja 20%.
5. **Funding requirement** — runway necesario para llegar a profitability o siguiente milestone.
6. **Break-even** — cuándo y bajo qué supuestos.

## Pre-flight

Idealmente después de `/precio` (necesitás ARPU) y `/brujula` (Channels para CAC).

## Output

`.claude/reports/ROI-PROJECTIONS-<nombre>.md`

## Siguiente paso sugerido

`/metas` (OKRs alineados a financials) · o `/crisol go`.
