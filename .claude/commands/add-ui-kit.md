---
description: "Inicializa el Brand DNA contract: brand.json + voice.json + brand.css + showcase."
---

# /add-ui-kit

Lee y ejecuta `.claude/skills/add-ui-kit/SKILL.md`.

Discovery interactivo que produce 4 outputs según R-005:

1. `brand/brand.json` — secciones 1-9 del schema (tokens, posture, archetype, component_rules, anti-slop)
2. `brand/voice.json` — sección 9.2 (tone, cta_examples, microcopy patterns)
3. `brand/brand.css` — CSS vars derivadas 1:1 de tokens
4. Visual showcase Next.js que renderiza todos los componentes declarados

**Modos:**
- **FRESH** (greenfield) — Discovery con 5 presets como starting points (Editorial Monocle / Modern Minimal / Warm & Soft / Tech Utility / Brutalist Experimental).
- **REDESIGN** (proyecto existente con ≥3 archivos UI en `src/`) — scan + report + migration plan.

**Crítico:** sin Brand DNA operacional, R10 falla — todo skill UI-generator (`impeccable`, los add-* en bloque D, los 5 templates UI del catálogo `ai/`) queda bloqueado.
