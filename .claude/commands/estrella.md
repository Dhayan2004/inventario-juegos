---
description: "North Star Metric + métricas operacionales (input/output, leading/lagging) — paso 2 de el-crisol."
---

# /estrella — North Star Metric

Define la métrica que captura el valor que el producto entrega a los usuarios. Sub-análisis individual de `el-crisol` (paso 2 de 7).

## Ejecución

Lee `.claude/skills/el-crisol/SKILL.md` y ejecuta **solo el paso `estrella`** del pipeline.

## Análisis

Genera `NORTH-STAR-<nombre>.md` con:

1. **North Star definition** — una métrica que capture valor entregado (no vanity).
   - Formato: "[Verbo] [Objeto significativo] [Por unidad de tiempo]"
   - Ejemplos: Spotify "Time spent listening", Airbnb "Nights booked", Stripe "Volume processed".
2. **Input metrics (3-5)** — métricas accionables que mueven el North Star.
3. **Output / lagging metrics** — qué se mueve después (revenue, retention).
4. **Counter-metrics** — qué chequear que NO empeore (churn, NPS).
5. **Targets** — 3 meses / 12 meses / 36 meses.
6. **Instrumentation plan** — qué tooling (PostHog, Mixpanel, custom) y dónde se trackean.

## Pre-flight

Si existe `STRATEGY-CANVAS-*.md` (de `/brujula`) — leerlo. La sección 6 (Key Metrics) es el punto de partida.

## Output

`.claude/reports/NORTH-STAR-<nombre>.md`

## Siguiente paso sugerido

`/metas` (OKRs derivados) · `/roi` (proyecciones) · o `/crisol go`.
