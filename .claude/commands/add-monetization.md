---
description: "Wizard monetización: add-payments → add-emails → web-quality (resume-aware)."
---

# /add-monetization

Lee y ejecuta `.claude/skills/add-monetization/SKILL.md`.

Wizard que compone la cadena de monetización (D-020 binary al wizard level):

1. **add-payments** — Stripe (default) o Polar (override) — checkout + portal + webhooks
2. **add-emails** — Resend + React Email — transaccionales (welcome, receipt, magic link, etc.)
3. **web-quality** — Auditoría pre-deploy (Lighthouse + agent-browser CLI)

**Resume-aware:** detecta y skipea pasos completados.

**Pre-requisitos:** `add-login` completado, Brand DNA presente, impeccable components base.

**Importante (D-020):** PAUSE-interno-delegado (D-010 add-payments / D-011 add-emails) NO escala como PAUSE-wizard. El wizard reporta el PAUSE al usuario, halt graceful, NO bloquea.
