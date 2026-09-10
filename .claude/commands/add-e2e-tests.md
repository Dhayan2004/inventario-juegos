---
description: "Skill opt-in para configurar Playwright como framework de tests CI/CD. Coexiste con agent-browser (default QA agentic). Modos: minimal (Chromium-only) / full (3 browsers + GitHub Actions)."
---

# /add-e2e-tests

Lee y ejecuta `.claude/skills/add-e2e-tests/SKILL.md`.

Configura Playwright (`@playwright/test`) como framework de tests CI/CD automatizados, complementando — NO reemplazando — agent-browser (default Forja para QA agentic durante development, D4).

**Precondición:**
- Proyecto Next.js (`next` en `package.json` deps).
- `npm` disponible.
- typecheck baseline sano (Gate 8 heredado de E-009 causa 3 — sin baseline limpio los specs heredan el roto).

**Modos (BINARY — D-026):**
- **minimal** (default): Chromium-only, sin GitHub Actions. Ideal para desarrollo local + smoke tests pre-deploy.
- **full** (override): Chromium + Firefox + WebKit + workflow GitHub Actions. Ideal para apps con compromiso cross-browser real.

**Resume-aware:** si `tests/e2e/` ya existe con specs, halt + reporta inventario + sugiere modo APPEND. Si `playwright.config.ts` existe, halt + diff + esperar confirmación humana.

**Tip:** este skill NO reemplaza `agent-browser` (D4 sigue intacto). Para QA agentic durante development seguí usando agent-browser. `add-e2e-tests` resuelve el caso ortogonal de specs CI/CD que corren sin agente en el loop. Ver `.claude/skills/add-e2e-tests/references/playwright-vs-agent-browser.md`.
