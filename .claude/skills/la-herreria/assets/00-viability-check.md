# Asset #0 — Viability Check (Go/No-Go Gate)

> *"La mejor feature es la que no construís porque no tiene mercado."*

## Qué Hace

Evalúa rápidamente si una idea vale la pena ANTES de invertir horas en planificación completa. Cubre tres dimensiones: **Viabilidad Técnica (Forja Golden Path fit)**, **Viabilidad de Negocio** y **Viabilidad de Marketing**. Resultado: GO / CAUTION / NO-GO.

**Tiempo:** ~20 minutos
**Input:** la idea del usuario (sin documentos previos)
**Output:** `VIABILITY-[nombre].md`

---

## Referencias (deferred F-tighten — usar las inline)

- `.claude/skills/la-herreria/references/business-model-canvas.md`
- `.claude/skills/la-herreria/references/canvas-alignment.md`
- `.claude/skills/la-herreria/references/scalability-patterns.md`
- `.claude/skills/la-herreria/references/vibe-coding-risks.md`

---

## Workflow

### Fase 1: Entrevista Rápida (~5 min)

Si el usuario ya proporcionó contexto, extraé sin repreguntar.

**Sobre el problema:**
1. ¿Qué problema resuelve? (en una oración)
2. ¿Quién tiene este problema? (persona específica, no "todos")
3. ¿Cómo lo resuelven HOY sin tu producto?

**Sobre el mercado:**
4. ¿Conocés competidores directos? ¿Cuáles?
5. ¿Hablaste con usuarios potenciales? ¿Cuántos?
6. ¿Estarían dispuestos a pagar? ¿Cuánto creés?

**Sobre la ejecución:**
7. ¿Tenés deadline o presión de tiempo?
8. ¿Esto es proyecto personal, startup, o para cliente?

> **Regla:** si el usuario no sabe responder #1 y #2, señal fuerte de NO-GO. Ayudalo a refinar antes de continuar.

---

### Fase 2: Análisis de Viabilidad (~10 min)

#### 2A. Viabilidad Técnica (Forja Golden Path Fit)

| Criterio | Pregunta clave | Peso |
|----------|----------------|------|
| **Golden Path Fit** | ¿Se puede construir con Next.js + Supabase/Insforge + Vercel/Coolify + Vercel AI SDK v5? | 30% |
| **APIs externas** | ¿Necesita integraciones que no existen o son inestables? | 25% |
| **Complejidad** | ¿Cuántas features core necesita el MVP? (ideal: 1-3) | 25% |
| **Datos** | ¿Necesita datos que no se pueden conseguir fácilmente? | 20% |

**Scoring:**
- 5: Todo en Golden Path, 1-2 features core, sin APIs raras.
- 4: Golden Path + 1-2 integraciones estándar (Stripe, OpenAI, Resend, etc.).
- 3: Necesita alguna integración no trivial pero factible.
- 2: Requiere infra fuera del Golden Path (ML custom, real-time heavy, etc.).
- 1: Imposible o extremadamente complejo con el stack actual.

**Forja-specific check:** ¿el feature lista alguno de estos red flags?
- Real-time multi-user > 100 concurrent (requiere infra extra) → -1 a Golden Path Fit.
- Compliance HIPAA/SOC2 mandatory desde día 1 (requiere Insforge override + audit) → -1 a Golden Path Fit.
- ML model training propio (no inference vía API) → -2 a Golden Path Fit.

#### 2B. Viabilidad de Negocio

| Criterio | Pregunta clave | Peso |
|----------|----------------|------|
| **Problema claro** | ¿El problema es específico y doloroso? | 30% |
| **Mercado identificable** | ¿Podés nombrar dónde están los usuarios? | 25% |
| **Monetización** | ¿Hay un modelo de cobro obvio? | 25% |
| **Diferenciación** | ¿Por qué esto y no la competencia? | 20% |

**Scoring:**
- 5: problema burning, mercado claro, monetización obvia, diferenciación fuerte.
- 4: problema real, mercado definido, monetización plausible.
- 3: problema existe pero no urgente, mercado difuso.
- 2: problema débil, no claro quién paga.
- 1: solución buscando problema.

#### 2C. Viabilidad de Marketing

| Criterio | Pregunta clave | Peso |
|----------|----------------|------|
| **Canal de adquisición** | ¿Cómo llegan los primeros 100 usuarios? | 35% |
| **Explicabilidad** | ¿Se entiende en 10 segundos qué hace? | 30% |
| **Timing** | ¿Por qué ahora y no hace 2 años? | 20% |
| **Viral potential** | ¿Los usuarios lo compartirían orgánicamente? | 15% |

**Scoring:**
- 5: canal claro, producto self-explanatory, timing perfecto.
- 4: canal identificado, producto entendible con demo.
- 3: canal posible pero requiere inversión, messaging confuso.
- 2: no hay canal claro, requiere mucha educación de mercado.
- 1: no se puede explicar fácilmente, no hay canal viable.

---

### Fase 3: Veredicto (~5 min)

```
Score = (Técnica × 0.30) + (Negocio × 0.40) + (Marketing × 0.30)
```

| Score | Veredicto | Acción |
|-------|-----------|--------|
| **4.0 – 5.0** | 🟢 **GO** | Proceder con `routes/saas-completo.md`. Idea con potencial claro. |
| **2.5 – 3.9** | 🟡 **CAUTION** | Proceder con precauciones. Listar riesgos + mitigation. Recomendar `routes/mvp.md`. |
| **1.0 – 2.4** | 🔴 **NO-GO** | Detener. Explicar por qué. Sugerir pivots o alternativas. |

---

## Output Format

```markdown
# VIABILITY-[nombre]

> Análisis de viabilidad generado por Forja · [fecha]

## Resumen Ejecutivo

**Idea:** [una línea]
**Veredicto:** [🟢 GO | 🟡 CAUTION | 🔴 NO-GO]
**Score:** [X.X / 5.0]
**Ruta recomendada:** [🏗️ SaaS Completo | 🚀 MVP | 🔧 Herramienta Interna | 🎯 Landing | 🤖 AI Feature]

---

## Análisis por Dimensión

### Viabilidad Técnica: [X/5]
- **Golden Path Fit (Forja):** [evaluación]
- **APIs Externas:** [evaluación]
- **Complejidad:** [evaluación]
- **Datos:** [evaluación]

### Viabilidad de Negocio: [X/5]
- **Problema:** [evaluación]
- **Mercado:** [evaluación]
- **Monetización:** [evaluación]
- **Diferenciación:** [evaluación]

### Viabilidad de Marketing: [X/5]
- **Canal de adquisición:** [evaluación]
- **Explicabilidad:** [evaluación]
- **Timing:** [evaluación]
- **Viral potential:** [evaluación]

---

## Riesgos Identificados

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| 1 | [riesgo] | Alta/Media/Baja | Alto/Medio/Bajo | [cómo mitigar] |

---

## Recomendación

[Párrafo con la recomendación clara: proceder, pivotar, o detenerse. Si CAUTION, incluir qué validar antes de invertir más tiempo.]

### Si GO → Siguiente paso
Proceder con **Step 1 (BMC)** del pipeline `routes/[ruta-recomendada].md`.

### Si CAUTION → Qué validar primero
1. [acción de validación 1]
2. [acción de validación 2]
3. [acción de validación 3]

### Si NO-GO → Alternativas sugeridas
1. [pivot idea 1]
2. [pivot idea 2]
```

---

## Reglas

1. **Sé honesto, no complaciente.** Si la idea no es viable, decilo con respeto pero sin suavizar.
2. **Siempre sugiere alternativas.** Un NO-GO no es callejón sin salida — es redirección.
3. **No adivines datos de mercado.** Si no tenés info, marcá como "Requiere validación" y sugerí cómo obtenerla.
4. **El score más bajo de las 3 dimensiones es el techo.** Un 5 en técnica y 1 en negocio = NO-GO.
5. **Sesgo hacia la acción.** En duda entre CAUTION y GO, elegí CAUTION con plan de validación, no NO-GO.
6. **Citation grammar (R8):** si citás datos de mercado externos, formato `[web:dominio.com](url)` + sección `## Sources` final.

---

## Paso final — Generar HTML

Después de guardar `VIABILITY-{nombre}.md`, invocar:

→ `.claude/skills/la-herreria/prompts/render-doc-html.md`
  con `doc_type: VIABILITY`, `project_name: {nombre}`

El veredicto extraído del doc (GO / CAUTION / NO-GO) determina el color del header badge: verde / amarillo / rojo.

Output adicional: `VIABILITY-{nombre}.html` (standalone, dark mode, navegable, print-friendly).

Reportar al usuario: "✅ VIABILITY-{nombre}.md + VIABILITY-{nombre}.html generados".
