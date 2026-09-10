---
description: "Wizard SaaS bootstrap: add-ui-kit → impeccable → add-login (resume-aware)."
---

# /init-saas

Lee y ejecuta `.claude/skills/init-saas/SKILL.md`.

Wizard que compone la cadena canónica de bootstrapping SaaS (D-019 binary):

1. **add-ui-kit** — Discovery + brand.json + voice.json + brand.css + showcase
2. **impeccable** — Componentes UI base (Button + Input + Card)
3. **add-login** — Auth completa (Supabase default, OAuth Google, RLS, profiles)

**Resume-aware:** escanea estado del proyecto y skipea pasos completados (estilo `el-crisol`). Resuelve E-006 (chicken-egg de cadena de skills).

**Pre-requisito:** Next.js project con `AGENTS.md` instalado.

**Modos:** `FRESH` (default — chain completa) / `EXISTING` (resume desde donde quedó).
