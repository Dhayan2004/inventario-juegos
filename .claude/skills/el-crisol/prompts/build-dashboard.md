# build-dashboard

> Fase 2 paso 3 de el-crisol. Genera el dashboard HTML standalone consolidado. Chart.js vía CDN + Liquid Glass + Bento Grid + dark mode + print-friendly. 9 secciones canónicas con datos extraídos de los 7 docs estratégicos.

## Inputs

```yaml
project_name: <{nombre}>

strategy_docs:
  brujula: <path STRATEGY-CANVAS-{nombre}.md>           # opcional si saltado
  estrella: <path NORTH-STAR-{nombre}.md>               # opcional
  rivales: <path COMPETITIVE-ANALYSIS-{nombre}.md>      # opcional
  precio: <path PRICING-STRATEGY-{nombre}.md>           # opcional
  roi: <path saas-analysis-{nombre}.md>                 # opcional
  metas: <path OKRS-{nombre}.md>                        # opcional
  lanzamiento: <path GTM-STRATEGY-{nombre}.md>          # opcional

build_confidence_score:           # output de Fase 2 paso 2
  total: <X.X>                    # 1.0 - 10.0
  verdict: Go | Caution | No-Go
  dimensions:
    market_fit: { score, weight, justification }
    metric_clarity: { score, weight, justification }
    competitive_position: { score, weight, justification }
    monetization: { score, weight, justification }
    financial_viability: { score, weight, justification }
    execution_plan: { score, weight, justification }
    gtm_feasibility: { score, weight, justification }
```

## Output

`.claude/reports/strategy-dashboard-{nombre}.html` — archivo standalone que abre directo en cualquier browser sin servidor.

## Antes de empezar — find-docs (R13 condicional)

Si Chart.js API ha cambiado post-cutoff, sub-agent puede invocar find-docs ad-hoc:

```
ctx7 library "chart.js" "v4 chart configuration radar doughnut line scatter"
ctx7 docs <id> "chart.js radar doughnut line scatter examples v4"
```

Cita: `[docs:chart-js@v4]` cuando aplica. Si find-docs no responde → fallback a la doc estándar de Chart.js documentada acá.

## Especificaciones técnicas

| Spec | Valor |
|------|-------|
| Formato | HTML standalone (sin servidor, abre directo en browser) |
| Charts | Chart.js v4+ vía CDN: `https://cdn.jsdelivr.net/npm/chart.js` |
| Layout | CSS Grid Bento (4 cols desktop, 2 tablet, 1 mobile) |
| Estilo | Liquid Glass (backdrop-blur, semi-transparencia, bordes sutiles) |
| Theme | Dark mode default (fondo `#0a0a0f`, cards `rgba(255,255,255,0.05)`) |
| Tipografía | `system-ui, -apple-system, sans-serif` |
| Responsive | Mobile-first con breakpoints `768px` (tablet) y `1200px` (desktop) |
| Print | `@media print` con fondo blanco, sin blur, charts visibles |
| Datos | Embebidos como `const DATA = { ... }` en `<script>` block |

## Estructura CSS canónica

```css
:root {
  --bg-primary: #0a0a0f;
  --bg-card: rgba(255, 255, 255, 0.05);
  --bg-card-hover: rgba(255, 255, 255, 0.08);
  --border-card: rgba(255, 255, 255, 0.1);
  --text-primary: #f0f0f5;
  --text-secondary: rgba(240, 240, 245, 0.6);
  --text-muted: rgba(240, 240, 245, 0.4);
  --accent-green: #34d399;
  --accent-yellow: #fbbf24;
  --accent-red: #f87171;
  --accent-blue: #60a5fa;
  --accent-purple: #a78bfa;
  --radius: 16px;
  --blur: 20px;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: system-ui, -apple-system, sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
  padding: 2rem;
}

.dashboard {
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.5rem;
}

.card {
  background: var(--bg-card);
  backdrop-filter: blur(var(--blur));
  -webkit-backdrop-filter: blur(var(--blur));
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 1.5rem;
  transition: background 0.2s;
}

.card:hover { background: var(--bg-card-hover); }
.card--full { grid-column: 1 / -1; }
.card--half { grid-column: span 2; }
.card--third { grid-column: span 1; }
.card--two-thirds { grid-column: span 3; }

.score-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 999px;
  font-weight: 700;
  font-size: 1.25rem;
}
.score-go { background: rgba(52, 211, 153, 0.15); color: var(--accent-green); }
.score-caution { background: rgba(251, 191, 36, 0.15); color: var(--accent-yellow); }
.score-nogo { background: rgba(248, 113, 113, 0.15); color: var(--accent-red); }

@media (max-width: 1200px) {
  .dashboard { grid-template-columns: repeat(2, 1fr); }
  .card--third { grid-column: span 1; }
  .card--two-thirds { grid-column: span 2; }
}

@media (max-width: 768px) {
  body { padding: 1rem; }
  .dashboard { grid-template-columns: 1fr; }
  .card--half, .card--third, .card--two-thirds { grid-column: 1 / -1; }
}

@media print {
  :root {
    --bg-primary: #fff;
    --bg-card: #f9f9f9;
    --border-card: #ddd;
    --text-primary: #111;
    --text-secondary: #555;
  }
  .card { backdrop-filter: none; break-inside: avoid; }
}
```

## 9 secciones canónicas

### Sección 1: Hero (full-width)

Layout: `card--full` con gradiente sutil en borde superior.

Contenido:
- Título h1 con `{nombre}` del proyecto
- Vision statement (cita) — de STRATEGY-CANVAS § Vision
- UVP en una línea — de STRATEGY-CANVAS § Value Proposition
- **Build Confidence Score** prominente (badge grande con color según veredicto)
- Fila de 4 stats clave con semáforos:

| Stat | Fuente | Verde / Amarillo / Rojo |
|------|--------|------------------------|
| LTV:CAC Ratio | PRICING § Unit Economics | >3 / 2-3 / <2 |
| Break-even | saas-analysis § Break-even | <12m / 12-18m / >18m |
| North Star Target | NORTH-STAR § Target 12m | siempre informativo |
| Gross Margin | PRICING § Unit Economics | >70% / 50-70% / <50% |

### Sección 2: Strategy Canvas (2 cards half + 1 card full)

**Card izquierda (half) — Target & Problem:**
- Target Customer primario (de STRATEGY-CANVAS § Target Customer)
- Top 3 problemas con magnitud (de STRATEGY-CANVAS § Problem)

**Card derecha (half) — Moat & Defensibility:**
- Competitive Advantage (de STRATEGY-CANVAS § Competitive Advantage)
- Defensibilidad a 12 meses

**Card full — Radar chart 5 ejes:**

```javascript
{
  type: 'radar',
  data: {
    labels: ['Market Fit', 'Defensibility', 'Monetization', 'GTM Clarity', 'Execution'],
    datasets: [{
      label: projectName,
      data: [marketFit, defensibility, monetization, gtmClarity, execution],
      backgroundColor: 'rgba(96, 165, 250, 0.15)',
      borderColor: 'rgba(96, 165, 250, 0.8)',
      pointBackgroundColor: 'rgba(96, 165, 250, 1)',
      borderWidth: 2,
    }]
  },
  options: {
    scales: { r: { min: 0, max: 5, ticks: { stepSize: 1 } } },
    plugins: { legend: { display: false } }
  }
}
```

| Eje | Fuente | Cómo puntuar (1-5) |
|-----|--------|--------------------|
| Market Fit | STRATEGY-CANVAS § Problem magnitudes | 5=dolor urgente, 1=nice-to-have |
| Defensibility | STRATEGY-CANVAS § Competitive Advantage | 5=moat fuerte, 1=fácilmente copiable |
| Monetization | PRICING § Unit Economics | 5=margins >80%, 1=margins <40% |
| GTM Clarity | GTM § Motion + Beachhead | 5=canal validado, 1=sin canal claro |
| Execution | OKRS § Confidence promedio | 5=alta confianza, 1=baja confianza |

### Sección 3: North Star Metric (1 half + 3 third)

**Card half — NSM Definition:**
- Nombre de la métrica (h2)
- Definición (texto)
- Fórmula (monospace, fondo rgba(255,255,255,0.05))
- Score de evaluación (de NORTH-STAR § criterios, total X.X/5.0)

**3 cards third — Input Metrics:**

Para cada input metric del árbol de descomposición:
- Nombre + descripción breve
- Target 3m y 12m
- Gauge visual (Chart.js doughnut con cutout 75%):

```javascript
{
  type: 'doughnut',
  data: {
    datasets: [{
      data: [currentValue, targetValue - currentValue],
      backgroundColor: ['rgba(52, 211, 153, 0.8)', 'rgba(255, 255, 255, 0.05)'],
      borderWidth: 0,
    }]
  },
  options: {
    circumference: 180, rotation: 270,
    cutout: '75%',
    plugins: { legend: { display: false } }
  }
}
```

### Sección 4: Competitive Landscape (full-width)

**Tabla comparativa:**
HTML table de COMPETITIVE-ANALYSIS § Landscape (matriz de features).
- Primera columna: feature names
- Resto: producto del usuario + competidores
- Celdas: ✅ (verde), 🟡 (amarillo), ❌ (rojo)

**Scatter plot (Chart.js):**
- Ejes: los 2 ejes del mapa de posicionamiento de COMPETITIVE-ANALYSIS § Landscape map
- Puntos: producto del usuario (acento azul, pointRadius 10) + competidores (gris, pointRadius 7)

```javascript
{
  type: 'scatter',
  data: {
    datasets: [
      { label: projectName, data: [{x: X, y: Y}], pointRadius: 10, backgroundColor: 'rgba(96, 165, 250, 0.8)' },
      { label: 'Competidor A', data: [{x: X, y: Y}], pointRadius: 7, backgroundColor: 'rgba(255, 255, 255, 0.3)' },
    ]
  }
}
```

### Sección 5: Pricing & Economics (3 cards third)

**Card 1 — Tier Table:**
Tabla estilizada de PRICING § Estructura de Precios. Filas = features, Columnas = tiers (Free/Pro/Team), tier recomendado destacado.

**Card 2 — Unit Economics:**
3 gauges (Chart.js doughnut, mismo estilo Sección 3):
- LTV:CAC Ratio (target 3:1)
- Gross Margin % (target 70%)
- Payback Period en meses (target <12)

**Card 3 — Sensitivity:**
Top 3 escenarios del análisis de sensibilidad de PRICING § Sensitivity.
Cada escenario con icono semáforo + impacto en una línea.

### Sección 6: Financial Projections (full-width)

**Chart principal:** Line chart con 3 líneas (MRR proyecciones), datos de saas-analysis § Proyecciones.

```javascript
{
  type: 'line',
  data: {
    labels: ['Mes 1', 'Mes 2', /* ... */ 'Mes 12'],
    datasets: [
      { label: 'Optimista', data: [...], borderColor: 'rgba(52, 211, 153, 0.8)', borderDash: [5, 5] },
      { label: 'Moderado', data: [...], borderColor: 'rgba(96, 165, 250, 0.8)', borderWidth: 3 },
      { label: 'Conservador', data: [...], borderColor: 'rgba(251, 191, 36, 0.8)', borderDash: [5, 5] },
    ]
  }
}
```

**Chart secundario:** Bar chart Revenue vs Costs (barras verdes revenue + barras rojas costs + línea horizontal break-even marker).

**Stats debajo:** MRR Mes 12 (moderado), ARR proyectado, Break-even month, Runway en meses.

### Sección 7: OKRs & Roadmap (2 cards half)

**Card izquierda — OKRs (de OKRS § OKRs Trimestre):**
Para cada Objective:
- Título h3
- Key Results como progress bars (background gris, fill coloreado por confidence opacity, labels con baseline → target)

**Card derecha — Outcome Roadmap (de OKRS § Outcome Roadmap):**
Timeline vertical por trimestres. Para cada Q: badge + outcome statement + metrics.

### Sección 8: Go-to-Market (full-width)

**Fila superior (4 elementos):**
- GTM Motion badge: PLG / Sales-Led / Community-Led / Content-Led (icon + color)
- Beachhead: segmento primario (de GTM § Segmento Beachhead)
- ICP: resumen una línea (de GTM § ICP)
- Growth Loop: tipo principal (de GTM § Growth Loops)

**Timeline de lanzamiento (3 cols):** Pre-Launch | Launch Week | Post-Launch — con max 4 action items por fase de GTM § Plan de Lanzamiento.

### Sección 9: Risks & Verdict (full-width)

**Risk Matrix (mitad izquierda):**
Tabla de riesgos con 3 tipos de STRATEGY-CANVAS § Strategic Risks:
- 🐯 Tiger (real y urgente) — borde rojo
- 🐘 Elephant (ignorado) — borde amarillo
- 📄 Paper Tiger (parece peligroso pero no lo es) — borde verde

**Build Confidence Breakdown (mitad derecha):**

| Dimension | Score | Peso | Justificación |
|-----------|-------|------|---------------|
| Market Fit | X/10 | 20% | (1 línea citando doc) |
| Metric Clarity | X/10 | 10% | ... |
| ... | ... | ... | ... |
| **Total** | **X.X/10** | **100%** | |

Badge grande con veredicto final + CTA según veredicto:

- **Go:** "Ready to build → /la-forja"
- **Caution:** "Review {areas} before building"
- **No-Go:** "Rethink strategy before investing in code"

## Mapa de extracción de datos

Sub-agent debe leer cada doc y extraer:

### De STRATEGY-CANVAS-{nombre}.md
- vision: § Vision → texto cita
- uvp: § Value Proposition → UVP en una frase
- target_customer: § Target Customer → Primario
- problems: § Problem → tabla top 3
- moat: § Competitive Advantage → texto
- defensibility: § Competitive Advantage → Defensibilidad a 12 meses
- key_metrics: § Key Metrics → tabla
- channels: § Channels → tabla
- revenue_model: § Revenue Model → modelo + pricing
- risks: § Strategic Risks → tabla (Tigers/Elephants/Paper Tigers)

### De NORTH-STAR-{nombre}.md
- nsm_name: § La Estrella → nombre
- nsm_definition: § La Estrella → definición
- nsm_formula: § La Estrella → fórmula
- nsm_score: § Por Qué Esta Métrica → total X.X/5.0
- input_metrics: § Descomposición → array {name, target_3m, target_12m}

### De COMPETITIVE-ANALYSIS-{nombre}.md
- feature_matrix: § Landscape → tabla features
- positioning_map: § Landscape → posiciones 2D de cada competidor
- battlecards: § Battlecards → resumen por competidor
- gaps: § Gaps y Oportunidades → tabla

### De PRICING-STRATEGY-{nombre}.md
- pricing_model: § Modelo de Monetización → modelo
- tiers: § Estructura de Precios → tabla
- unit_economics: § Unit Economics → ARPU/COGS/LTV/CAC/Margin/Payback
- sensitivity: § Sensitivity → tabla top 3 escenarios

### De saas-analysis-{nombre}.md
- mrr_projections: § Proyecciones → tablas mes a mes (3 escenarios)
- revenue_vs_costs: datos mensuales
- break_even: § Break-even o Executive Summary → mes
- saas_metrics: § Métricas Clave → tabla completa
- runway: § Métricas Clave → meses

### De OKRS-{nombre}.md
- nsm_current: § North Star Metric → Actual
- nsm_target: § North Star Metric → Target
- okrs: § OKRs Trimestre → array {objective, key_results: [{metric, baseline, target, confidence}]}
- outcome_roadmap: § Outcome Roadmap → array {quarter, statement, metrics, features}

### De GTM-STRATEGY-{nombre}.md
- gtm_motion: § GTM Motion → motion elegida
- beachhead: § Segmento Beachhead → descripción
- icp: § Ideal Customer Profile → resumen
- growth_loops: § Growth Loops → loops identificados
- launch_plan: § Plan de Lanzamiento → pre-launch / launch week / post-launch
- success_metrics: § Métricas de Éxito → tabla

## Graceful degradation

Si solo hay 5 de 7 docs:
- Generar dashboard con las secciones disponibles.
- Secciones sin datos: mostrar "Análisis no realizado — ejecutar /{step} para completar" con borde dashed gris.
- Build Confidence Score solo evalúa dimensiones con docs disponibles (peso redistribuido proporcionalmente).
- Veredicto se puede emitir aún con dimensiones N/A pero documenta en la nota: "Score parcial — N/A dimensiones: {list}".

## R4/R5 enforcement

- R4: el-crisol MISMA NO genera HTML. Sub-agent dispatched genera el archivo.
- R5: sub-agent NO escribe a memory. HTML va a `.claude/reports/` (state, no memory).
- R8 análogo: cada sección del dashboard cita el dato del doc fuente. NO datos inventados.

## Edge cases

### Edge: Doc fuente tiene formato distinto al esperado

→ Sub-agent adapta extracción al formato real (no rigidizar). Si falta un campo crítico, omitir esa parte del dashboard (no inventar valores). Cita en el output: "[Análisis no realizado — sección parcial]".

### Edge: Chart.js CDN bloqueado en target environment

→ Reportar al usuario. Sugerir local copy de Chart.js como override (commit del `.js` al repo). NO sub-agent decide solo — humano confirma.

### Edge: Datos de proyecciones con valores negativos en escenario conservador

→ Renderear igual con scale dinámico. Línea horizontal break-even visible. Reportar al usuario en la nota del chart: "Escenario conservador no llega a break-even en 12m — ver proyección extendida en saas-analysis-{nombre}.md".

### Edge: Veredicto Go pero Build Confidence Score es 7.9 (límite Caution)

→ Mostrar badge Caution (5-7.9) según rúbrica. Veredicto NUNCA se redondea hacia arriba. Si humano quiere override, lo hace explícito post-dashboard.

### Edge: Print version pierde charts en algunos browsers (Safari, Firefox)

→ Documentar en footer del dashboard: "Para impresión, usá Chrome/Edge. Si problemas, exportar a PDF desde browser." (workaround estándar print CSS).

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — el-crisol thin, sub-agent genera HTML.
- [memory:CONSTRAINTS.md#R5] — sub-agent no escribe memory.
- [memory:CONSTRAINTS.md#R8] análogo — cada sección cita doc fuente.
- [memory:CONSTRAINTS.md#R13] condicional — find-docs invocable si Chart.js API freshness needed.
- [docs:chart-js@v4] — Chart.js canónico (cuando find-docs invocado).
- [memory:decisions#D-014] — pipeline shape (informativo si humano pregunta por qué no hay default+override).

## Refusals

- ❌ Inventar datos para llenar gaps (R8 análogo — cita doc fuente o omitir sección).
- ❌ Charts sin Chart.js (no usar libraries alternativas — contrato canónico).
- ❌ Custom colors fuera de las CSS custom properties (paleta es contrato, no negociable).
- ❌ Embedded chart como iframe externo (rompe standalone — todo embebido en `<script>`).
- ❌ Print CSS que deje charts invisibles (validá @media print con backdrop-filter: none).
- ❌ Generar dashboard con datos del proyecto A en archivo del proyecto B (drift cross-proyecto — halt + reportar).
