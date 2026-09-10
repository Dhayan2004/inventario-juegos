---
description: "Estrategia de pricing: modelo, tiers, pricing page — paso 4 de el-crisol."
---

# /precio — Pricing Strategy

Diseña pricing model, tiers, anclaje psicológico, pricing page. Sub-análisis individual de `el-crisol` (paso 4 de 7).

**Input de comisiones reales (G8, D-038):** si existe `TECH-SPEC-*.md › Payments Decision` (o se puede correr `node .claude/skills/add-payments/vendor/pagokit/scripts/advise.js --amount <ticket> --currency <MXN> …`), usa la **fee típica del proveedor** (porcentaje + fijo, neto) en los unit economics de cada tier — no una comisión estimada. Cita `[memory:references#R-012]` y el `last_verified_at` del catálogo.

## Ejecución

Lee `.claude/skills/el-crisol/SKILL.md` y ejecuta **solo el paso `precio`** del pipeline.

## Análisis

Genera `PRICING-STRATEGY-<nombre>.md` con:

1. **Pricing model** — flat / tiered / usage-based / per-seat / freemium / outcome-based — con justificación según tipo de producto.
2. **Tiers (típicamente 3, máx 4):**
   - Nombre + tagline + target customer por tier
   - Precio mensual + anual (descuento típico 15-20%)
   - Features incluidos vs excluidos (la frontera importa más que la lista)
   - Límites cuantitativos (seats, requests, storage)
3. **Anchoring** — qué tier está diseñado para hacer ver al middle como obvio (decoy effect).
4. **Free trial / freemium policy** — duración, qué incluye, qué obliga al upgrade.
5. **Enterprise tier** — "Contact sales" vs precio público (cuándo conviene cada uno).
6. **Discount policy** — annual / nonprofits / startups / volumen.
7. **Competitive pricing context** — comparativa con top 3 rivales (output de `/rivales`).
8. **Pricing page copy** — headline, sub-headline, FAQ obligatorias (cancellation, taxes, refund).

## Pre-flight

Idealmente correr después de `/rivales` (necesitás contexto competitivo) y `/brujula` (Revenue Model sección 8).

## Output

`.claude/reports/PRICING-STRATEGY-<nombre>.md`

## Siguiente paso sugerido

`/roi` (unit economics + proyecciones financieras) · `/lanzamiento` · o `/crisol go`.
