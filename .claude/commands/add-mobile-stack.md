---
description: "Wizard pipeline: add-ui-kit → impeccable → add-login → add-mobile. Setup completo de SaaS con PWA y push notifications."
---

# /add-mobile-stack

Lee y ejecuta `.claude/skills/add-mobile-stack/SKILL.md`.

Wizard que extiende `init-saas` agregando el 4to paso (`add-mobile`) — D-021 binary, hereda D-019:

1. **add-ui-kit** — Brand DNA contract (brand.json + voice.json + brand.css + showcase)
2. **impeccable** — Componentes UI base
3. **add-login** — Auth completa (Supabase default + RLS + profiles)
4. **add-mobile** — PWA (manifest + service worker) + Web Push API + VAPID keys

**Resume-aware:** escanea estado del proyecto (brand, components, auth, manifest + sw + push migration) y skipea pasos completados.

**Pre-requisito:** Next.js project con `AGENTS.md` instalado. `.env.local` writable para VAPID keys.

**Modos:** `FRESH` (default — chain completa de 4 pasos) / `EXISTING` (resume desde donde quedó).

Hereda doctrine: D-019 (init-saas patrón base) + D-020 (PAUSE-interno-delegado NO escala) + D-012 (add-mobile binary interno PWA/Native).
