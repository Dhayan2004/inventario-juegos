# vendor/pagokit — procedencia (D-038 · `docs/11` §1.4 Capa 1)

- **Upstream:** https://github.com/Hainrixz/agente-pagokit · tag **0.2.2** (CHANGELOG 2026-08-31) · MIT (© 2026 Hainrixz / Enrique Rocha). `LICENSE` copiado sin cambios.
- **Qué se vendoreó:** `data/` (= `skills/payment-advisor/data/**`: proveedores, métodos, monedas con exponente ISO 4217, regiones, casos de uso, índice), `schemas/` (JSON Schema de los datos), `scripts/advise.js` + `scripts/lib/advisor.js` (ranking determinista), `scripts/sign-event.js` + `scripts/lib/{webhook-sign,catalog}.js` + `scripts/fixtures/` (firmador de eventos por proveedor).
- **Qué NO:** comandos, skills, subagente, hooks de turno. Los validadores se **portaron** como regex a `tests/payments-gate.sh` + amenazas `PAY-*` del `threat-db` (con cita), no se ejecuta su código.
- **Cambio local único:** `scripts/lib/catalog.js` — `DATA` apunta a `vendor/pagokit/data` (override `PAGOKIT_DATA`). Nada más se edita a mano: se re-sincroniza con `scripts/sync-pagokit-catalog.sh <tag>`.
- **Vetting:** `docs/security/VETTING-pagokit-0.2.2.md` (5 pasos; esquemas Stripe + Mercado Pago re-verificados contra fuente primaria). Cita: `[memory:references#R-012]`.
- **Regla de honestidad heredada:** `webhook_confidence != "high"` ⇒ no se emite verificador. `last_verified_at` de cada proveedor se muestra como disclaimer en toda recomendación.
