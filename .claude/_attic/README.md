# `_attic/` — ático de ablación (3R · D-036)

Skills y comandos **fuera del catálogo vivo**, movidos aquí por la rutina de ablación 3R
(Boris Cherny, YC 2026 → `docs/10-ablation-3r.md`): no pasan ninguna R (**R**epetible >3×/mes igual ·
**R**equisito = dato que el modelo no puede adivinar · **R**epartible = SOP para equipo/cliente) o
son *receta* de un proceso ajeno que el modelo actual ya ejecuta sin guía.

Reglas:

- Lo que está aquí **no se despacha**: `inventory.js` y `check-ceilings.mjs` ignoran dirs `_*`, y
  Claude Code no lo escanea (está fuera de `.claude/skills/` y `.claude/commands/`). Ablación de
  **contexto**, no solo documental.
- La historia git se conserva (`git mv`). Restaurar = `git mv` de vuelta + re-registrar en
  `.claude/memory/skills.md` (R6) + `node scripts/inventory.js`.
- Cada pieza aquí tiene una entrada en la sección **Ático** de `skills.md` con fecha, motivo y
  **expiry** ("revisar con el próximo salto de modelo"). Si el dogfooding demuestra que faltaba, vuelve
  con esa evidencia registrada en `decisions.md`.
- El techo del catálogo se mide, no se cuenta: `node scripts/check-ceilings.mjs`.

| Pieza | Desde | Motivo | Expiry |
|---|---|---|---|
| `skills/add-marketing` + `commands/add-marketing.md` | 2026-09-02 | Experimento de ablación D-036: proceso de otro (marketingskills), <3×/mes, sin referencias desde `la-herreria`/`landing-page`. Mide el delta de scan (≈ −2.6 KB descriptions+comando) y sirve de control para el fixture de landing. | próximo salto de modelo o evidencia de dogfooding |
