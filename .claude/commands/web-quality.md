---
description: "Auditoría integral pre-deploy: Performance + Core Web Vitals + A11y + SEO + Best Practices."
---

# /web-quality

Lee y ejecuta `.claude/skills/web-quality/SKILL.md`.

Auditoría Lighthouse-based (150+ checks) cubriendo:

- **Performance** + Core Web Vitals (LCP / INP / CLS)
- **Accessibility** (WCAG 2.1 AA mandatory)
- **SEO** (Next.js metadata API + structured data)
- **Best Practices** (security + modern + code quality)
- **Forja-specific:** brand.css cargado en root layout, brand.json NO en bundle cliente, anti-slop hue range respetado.

**Modos D-015 binary:**
- **live audit** (default) — agent-browser CLI por D4, Lighthouse fallback. Requiere URL o `npm run dev`/`start` corriendo.
- **static analysis** (fallback graceful) — lectura de código + pattern detection sin scores numéricos pero con line numbers. NO requiere URL ni server.

**Pre-deploy gate** complementario a `el-guardian` (security audit).
