# Strategy summary — template

> Template para STRATEGY-REPORT-{nombre}.md (Fase 2 paso 1 de el-crisol). Resumen ejecutivo consolidado de los 7 análisis estratégicos en un solo documento markdown legible. NO inventar datos — cada campo viene de un doc específico.

## Estructura del documento

```markdown
# STRATEGY-REPORT-{nombre}

> Reporte estratégico consolidado · Generado por el-crisol · {fecha ISO}
> Build Confidence Score: {X.X}/10 — {Go / Caution / No-Go}

---

## Executive Summary

[1 párrafo que responde: Qué es, para quién, por qué ahora, y si vale la pena
construir. Incluir UVP, segmento principal, modelo de monetización, NSM, y
veredicto.]

---

## Métricas Clave

| Métrica | Valor | Benchmark | Status |
|---------|-------|-----------|--------|
| North Star Metric | {nombre}: {target 12m} | — | — |
| LTV:CAC Ratio | {X:1} | >3:1 | {ok/warning/critical} |
| Gross Margin | {X%} | >70% | {ok/warning/critical} |
| Payback Period | {X meses} | <12m | {ok/warning/critical} |
| Break-even | Mes {X} | <18m | {ok/warning/critical} |
| MRR Mes 12 (moderado) | ${X} | — | — |
| Churn Rate | {X%} | <5% | {ok/warning/critical} |

---

## Visión y Posicionamiento

**Visión:** "{declaración de visión}"

**UVP:** {propuesta de valor en una frase}

**Target Customer:** {segmento primario}

**Moat:** {competitive advantage en una frase}

**Defensibilidad a 12 meses:** {evaluación}

---

## Competencia

**Posición:** {resumen de la posición competitiva en 2-3 líneas}

**Ventajas clave:**
1. {ventaja 1}
2. {ventaja 2}
3. {ventaja 3}

**Gaps explotables:**
- {gap 1}: {oportunidad}
- {gap 2}: {oportunidad}

---

## Monetización

**Modelo:** {modelo elegido}

**Tiers:**

| Tier | Precio | Target |
|------|--------|--------|
| {Free} | $0 | {quién} |
| {Pro} | ${X}/mes | {quién} |
| {Team} | ${Y}/mes | {quién} |

**Unit Economics:** ARPU ${X} · COGS ${Y} · LTV ${Z} · CAC ${W}

---

## Proyección Financiera

| Mes | MRR (Conservador) | MRR (Moderado) | MRR (Optimista) |
|-----|-------------------|----------------|-----------------|
| 3 | ${X} | ${X} | ${X} |
| 6 | ${X} | ${X} | ${X} |
| 12 | ${X} | ${X} | ${X} |

**Break-even:** Mes {X} (escenario moderado)

---

## Metas Q1

**Objective 1:** {título}
- KR1: {métrica} — {baseline} → {target}
- KR2: {métrica} — {baseline} → {target}
- KR3: {métrica} — {baseline} → {target}

**Objective 2:** {título}
- KR1: {métrica} → {target}
- KR2: {métrica} → {target}

---

## Go-to-Market

**Motion:** {PLG / Sales-Led / Community-Led / Content-Led}
**Beachhead:** {segmento}
**Growth Loop:** {tipo principal}
**Launch Timeline:** {Pre-launch X semanas → Launch → Post-launch}

---

## Riesgos Top 3

| # | Tipo | Riesgo | Mitigación |
|---|------|--------|------------|
| 1 | {Tiger/Elephant/Paper Tiger} | {riesgo} | {acción} |
| 2 | {Tiger/Elephant/Paper Tiger} | {riesgo} | {acción} |
| 3 | {Tiger/Elephant/Paper Tiger} | {riesgo} | {acción} |

---

## Build Confidence Score

| Dimension | Score | Peso | Justificación |
|-----------|-------|------|---------------|
| Market Fit | {X}/10 | 20% | {1 línea citando doc} |
| Metric Clarity | {X}/10 | 10% | {1 línea} |
| Competitive Position | {X}/10 | 15% | {1 línea} |
| Monetization | {X}/10 | 15% | {1 línea} |
| Financial Viability | {X}/10 | 20% | {1 línea} |
| Execution Plan | {X}/10 | 10% | {1 línea} |
| GTM Feasibility | {X}/10 | 10% | {1 línea} |
| **Total** | **{X.X}/10** | **100%** | **{Go / Caution / No-Go}** |

---

## Siguiente Paso

[Según veredicto:]
- Go → "Estrategia validada. Usá /la-forja para construir (Fork default por exploración paralela, o Coordinator si dependencias secuenciales) o /el-yunque manual."
- Caution → "Revisar {áreas} antes de construir. Re-ejecutar el-crisol post-ajuste o proceder con /la-forja aceptando riesgos documentados."
- No-Go → "Replantear {gaps fundamentales}. Re-ejecutar el-crisol tras ajustes — NO build hasta resolver gaps."

---

## Documentos de Referencia

| Análisis | Documento |
|----------|-----------|
| Visión + Strategy | STRATEGY-CANVAS-{nombre}.md |
| North Star Metric | NORTH-STAR-{nombre}.md |
| Competencia | COMPETITIVE-ANALYSIS-{nombre}.md |
| Pricing | PRICING-STRATEGY-{nombre}.md |
| Finanzas | .claude/reports/saas-analysis-{nombre}.md |
| Dashboard financiero | .claude/reports/saas-dashboard-{nombre}.html |
| OKRs | OKRS-{nombre}.md |
| Go-to-Market | GTM-STRATEGY-{nombre}.md |
| **Dashboard consolidado** | **.claude/reports/strategy-dashboard-{nombre}.html** |
```

## Notas para el sub-agent que genera el reporte

1. **Extraer datos reales.** Cada campo viene de un doc específico — NO inventar.
2. **Ser conciso.** Resumen ejecutivo, una página ideal, max dos.
3. **Status column.** Usar: `ok` (verde, dentro de benchmark), `warning` (amarillo, cerca del límite), `critical` (rojo, fuera de benchmark).
4. **Si falta un documento.** Marcar la sección como "[Análisis no realizado]" y omitir del scoring.
5. **Links.** Documentos de referencia al final permiten drill-down para más detalle.
6. **Cita doc fuente** si el dato es ambiguo o requiere clarificación al lector ejecutivo.

## Citation grammar

- [memory:CONSTRAINTS.md#R8] análogo — Status column con datos concretos, no inventados.
- [memory:decisions#D-014] — pipeline shape (informativo si humano pregunta por qué reporte único, no comparativo cross-providers).

## Refusals

- ❌ Inventar Gross Margin / LTV / CAC si docs fuente no los tienen.
- ❌ Status `ok` para métrica fuera de benchmark (status debe matchear datos reales).
- ❌ Reporte sin "Siguiente Paso" claro según veredicto (riesgo: usuario no sabe qué hacer post-validación).
- ❌ "Análisis no realizado" sin documentar qué doc falta y cómo generarlo.
