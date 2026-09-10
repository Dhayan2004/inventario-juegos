---
name: front-end-design
description: >
  Principios de diseño visual distintivo + anti-AI-slop guidelines. En Forja, este asset
  delega a los skills nativos `add-ui-kit` (Brand DNA contract) e `impeccable` (componentes
  consumiendo el contrato). Leer `.claude/skills/impeccable/SKILL.md` y sus references
  para guidelines completas.
---

> **Forja-native:** este asset es referencia rápida. Las guidelines completas viven en `impeccable` y `add-ui-kit` (R-005 schema). Para implementación, delegar a esos skills.

## Design Thinking

Antes de generar UI, comprometerse con una dirección estética BOLD:

- **Purpose:** ¿qué problema resuelve esta interfaz? ¿quién la usa?
- **Tone:** elegir un extremo — brutally minimal, refined luxury, retro-futuristic, organic, editorial, brutalist, art deco, soft pastel, industrial. Forja `add-ui-kit` ofrece 5 presets como starting points: Editorial Monocle, Modern Minimal, Warm & Soft, Tech Utility, Brutalist Experimental.
- **Constraints:** framework (Next.js 16), accesibilidad (WCAG 2.1 AA), Brand DNA contract (R10).
- **Differentiation:** ¿qué hace esto MEMORABLE? un detalle, una tipografía, un color, un patrón.

**CRITICAL:** elegir UNA dirección con precisión. Bold maximalism y refined minimalism funcionan ambos — la clave es intencionalidad.

## Frontend Aesthetics Guidelines (resumen)

- **Typography:** fuentes con personalidad. Evitar Inter/Roboto/Arial defaults. Pareo: display fuerte + body refinado. `brand.json typography.font_pairings` declara la combinación elegida.
- **Color & Theme:** tokens del `brand.json` verbatim. CSS vars en `brand.css`. Dominancia > equidistancia. NO Tailwind defaults.
- **Motion:** Motion library para React, CSS-only para HTML estático. Foco en momentos de alto impacto: una orquestación bien hecha de page load > micro-interactions dispersas.
- **Spatial Composition:** asimetría, overlap, diagonal flow, grid-breaking. Negative space generoso O controlled density.
- **Backgrounds & Detail:** gradient meshes, noise textures, geometric patterns, shadows dramáticas, decorative borders. Atmósfera sobre flat default.

## Anti-Slop Rules (R10 enforced)

- ❌ Inter / Roboto / Arial / system-ui como fuente principal.
- ❌ Purple gradients on white (#6366F1, #8B5CF6, #A855F7 — hue range 235–285 sin justificación).
- ❌ Tailwind defaults para colors/typography/radius/spacing.
- ❌ "Claude default": purple-500 + Inter + 3 cards centradas + gradiente diagonal.
- ❌ Layouts predecibles, component patterns cookie-cutter.
- ❌ Variar entre light/dark sin coherencia.
- ❌ Convergencia en common choices (Space Grotesk, etc.) cross-projects.

## Cómo se usa en Forja

1. **add-ui-kit Discovery** captura la dirección estética → produce `brand.json` + `voice.json` + `brand.css`.
2. **impeccable** consume el contrato → produce componentes verbatim de tokens.
3. **Anti-Slop Gate** post-generación: visual diff vs `brand.json` rules. Brand Score ≥75 mandatory.

## Match Implementation Complexity to Vision

- **Maximalist designs** → código elaborado con animations + effects extensivos.
- **Minimalist/refined designs** → restraint, precisión, atención cuidada a spacing/typography/sutil.

La elegancia viene de ejecutar la visión bien, no de la intensidad.

## Referencias detalladas

- `.claude/skills/add-ui-kit/SKILL.md` — Discovery + presets + R-005 schema.
- `.claude/skills/impeccable/SKILL.md` — generación de componentes.
- `.claude/skills/impeccable/references/landing-anti-slop.md` — anti-patrones específicos a landing pages (deferred F-tighten).
- `.claude/references/BRAND_DNA_SCHEMA.md` — schema R-005 completo.
