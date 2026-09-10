---
description: "Análisis competitivo profundo + battlecards — paso 3 de el-crisol."
---

# /rivales — Competitive Analysis & Battlecards

Análisis competitivo profundo: posicionamiento, features, pricing, GTM, moat. Sub-análisis individual de `el-crisol` (paso 3 de 7).

## Ejecución

Lee `.claude/skills/el-crisol/SKILL.md` y ejecuta **solo el paso `rivales`** del pipeline.

## Análisis

Genera `COMPETITIVE-ANALYSIS-<nombre>.md` con:

1. **Competitor landscape** — directos (mismo problema, mismo segmento), indirectos (mismo problema, segmento adyacente), substitutos (workarounds del usuario hoy).
2. **Battlecard por competidor (top 3-5):**
   - Tagline + UVP
   - Pricing y modelo
   - Top 3 features y top 3 gaps
   - Public reviews highlights (G2, Capterra, Reddit) — citados con `[web:dominio.com](url)`
   - Estrategia GTM observable (canales, mensajes, partnerships)
   - Moat real (datos, red, switching cost, marca)
3. **Positioning map** — 2 ejes que importan en este segmento (ej: simplicidad vs poder, precio vs valor).
4. **Where do we win** — 3 vectores donde Forja-built supera al incumbente.
5. **Where do we lose** — 3 vectores donde el incumbente domina (sin auto-engaño).
6. **Honest moat assessment** — defensibilidad real a 12 meses (no aspirations).

## Pre-flight

Citation grammar **obligatoria** (R8): cada claim sobre competidor lleva `[web:dominio.com](url)` + sección `## Sources` final. Si Perplexity MCP disponible, úsalo para enriquecer; si no, WebFetch a páginas oficiales y reviews públicos.

## Output

`.claude/reports/COMPETITIVE-ANALYSIS-<nombre>.md`

## Siguiente paso sugerido

`/precio` (pricing competitivo) · `/lanzamiento` (GTM diferenciado) · o `/crisol go`.
