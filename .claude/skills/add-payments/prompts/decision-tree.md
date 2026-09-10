# add-payments — Decision tree = ranking determinista (advise.js)

> Cita: [memory:decisions#D-038] (el proveedor lo decide un programa, el agente lo narra — misma filosofía
> que `verificar-ci`; supersede parcial de D-010) · [memory:decisions#D-010] (Stripe default + Polar MoR +
> PAUSE siguen vigentes como *salidas* del ranking) · [memory:lessons#L-004] (trinario: PAUSE = acción
> upstream del usuario) · [memory:references#R-012] (catálogo PagoKit 0.2.2, MIT: 42 proveedores · 136
> métodos · 106 monedas con exponente · rails por país · obligaciones fiscales) ·
> [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra cualquier SDK).

## Por qué un programa y no una tabla de prosa

La tabla Stripe-vs-Polar de D-010 era un ranking ejecutado a mano: no reproducible, sin razón exacta
para cada rechazo, ciego a LATAM (OXXO, SPEI, Pix, PSE) y a los exponentes de moneda. `advise.js` es
una **función pura**: misma situación → misma respuesta; cada proveedor rechazado trae el filtro que lo
rechazó; la comisión sale en dinero real para la transacción típica; y siempre dice si Forja puede
**construir** la integración (`build`) o solo **aconsejar** (`advise`).

## Cuándo correr el ranking

Antes de elegir Mode A/B/C. Si el Tech Spec ya declara `payments.provider` explícito, el ranking es
informativo (se cita como verificación del rationale). Si no declara, el ranking decide y se loggea
`assumed_default = true` cuando la salida es `stripe` sin señales fuertes.

## Inputs (los mismos 3 del PREFLIGHT + los que cambian la respuesta)

| Input | De dónde sale | Flag |
|---|---|---|
| País del vendedor + países de compradores | ONTOLOGY.md / SPEC / Tech Spec | `--country MX --buyers MX,US` |
| One-time vs recurrente | User Stories / pricing del Tech Spec | `--billing one_time\|subscription` |
| Rails locales requeridos | `regions[país].instant_rail` + pedido del cliente (OXXO, SPEI, Pix, PSE, Bizum…) | `--methods oxxo,spei` |
| Entidad legal | `el-ontologo` (persona moral / individual) | `--entity individual\|solo\|smb\|company` |
| Tipo de producto | Tech Spec (saas · digital_goods · physical · service · marketplace · donations) | `--product saas` |
| Plataforma | Tech Spec (web · ios · android · pos — iOS digital = IAP obligatorio) | `--platform web` |
| ¿Quiere que el proveedor maneje impuestos? | `el-ontologo` requisitos legales | `--tax-automation` |
| **Días hasta necesitar llaves live** (G7) | fecha del hito en `.plan/` | `--keys-within 14` |
| Transacción típica (G8) | pricing del Tech Spec / `/precio` | `--amount 499 --currency MXN` |

**Nunca preguntar:** volumen mensual estimado (ruido) ni "¿quieres un merchant of record?" (el usuario
no sabe qué es — se infiere de entidad + audiencia).

## Cómo correrlo

```bash
node .claude/skills/add-payments/vendor/pagokit/scripts/advise.js \
  --country MX --buyers MX --billing subscription --methods oxxo,spei \
  --entity company --product saas --platform web --keys-within 14 \
  --amount 499 --currency MXN --explain        # --explain = prosa; sin él = JSON
```

Salida (JSON): `recommendation` · `candidates[]` (score + modificadores activos) · `rejected[]`
(`{ id, filter, reason }`) · `fallback_used` · `refused` (mercados sancionados: se rechaza, no se
rankea) · `disclosures[]` (p. ej. *"MX mandates CFDI e-invoicing — 'the payment worked' is not 'you can
invoice it'"*) · por proveedor: `integration_level`, `webhook_confidence`, `onboarding_model`,
`last_verified_at`, fee `{ percent, fixed, total, net }`.

## Qué hace el agente con la salida (narrar, no recomputar)

1. **Recomendación única** en prosa, con la comisión en dinero real de la transacción típica y el
   disclaimer `last_verified_at` (los catálogos se pudren; decirlo es honestidad, no debilidad).
2. **Por qué no X** — para los 1–2 rivales obvios, citar el `filter`/`reason` del `rejected[]`.
3. **Nivel**: `build` → Mode A/B/C con templates; `advise` → recomendación + fee + checklist, y decirlo
   plano: el código es del usuario. **Nunca** emitir un verificador de webhook para un proveedor con
   `webhook_confidence != high`.
4. **Lead time** (`onboarding_model` + `--keys-within`): si el proveedor recomendado no entrega llaves
   a tiempo, el ranking ya lo filtró; registrar `payments.onboarding_lead_time` en el Tech Spec y, si
   excede el hito, un `blocker` en `.plan/` (G7).
5. **Fee → `/precio`**: la comisión calculada entra como input citable del paso 4 de `el-crisol` (G8).
6. **Fiscal**: si `disclosures[]` trae un mandato (CFDI/DIAN/NF-e/DTE/SUNAT), el checkout debe capturar
   el identificador fiscal antes del pago — `references/subscription-lifecycle.md` §7.

## Salidas del árbol

```
1. STRIPE       → Mode A (templates/stripe/**)        — default cuando el ranking lo da o no hay señales
2. POLAR        → Mode B (templates/polar/**)         — MoR: sin empresa + audiencia global + digital
3. MERCADOPAGO  → Mode C (templates/mercadopago/**)   — LATAM: rails locales / moneda local / cash
4. ADVISE       → sin código: recomendación + fee + checklist (proveedor build: false)
5. PAUSE        → halt + handoff: constituir empresa / MoR cross-border antes de continuar
```

## Bloque `## Payments Decision` para `TECH-SPEC-<nombre>.md`

```markdown
## Payments Decision

- **Provider:** mercadopago (Mode C)   ← `recommendation.id`
- **Level:** build                     ← `integration_level` (build | advise)
- **Rationale:** <3–5 bullets narrados desde candidates/rejected>
- **Rejected:** stripe — <filter/reason> · polar — <filter/reason>
- **Fee típica:** <total> MXN sobre <amount> (<percent>% + <fixed>) · neto <net>
- **Rails:** oxxo, spei, card                        ← `--methods` + `regions[MX].instant_rail`
- **Onboarding lead time:** self_serve, <N> días  ← G7 (bloqueador en .plan/ si excede el hito)
- **Fiscal:** CFDI 4.0 (capturar RFC en checkout)  ← `disclosures[]`
- **Catálogo:** PagoKit 0.2.2 · last_verified_at <fecha> · [memory:references#R-012]
- **Assumed default:** false
```

## Refusals del árbol

- ❌ Decidir el proveedor "a ojo" sin correr `advise.js` (o citar por qué el Tech Spec lo fija).
- ❌ Ocultar `last_verified_at` o presentar `advise` como si Forja fuera a generar el código.
- ❌ Preguntar volumen mensual o "¿quieres MoR?".
- ❌ Default Polar cuando ambiguo. Default es STRIPE (D-009/D-010) — salvo que el ranking diga otra cosa.
- ❌ Editar el catálogo a mano: `scripts/sync-pagokit-catalog.sh <tag>` + re-vetting.

## Cross-skill applicability

El patrón "un programa decide, el agente narra" (aquí `advise.js`, en CI `verificar-ci`, en diseño
`design-diversity.mjs`) es la regla general de Forja para decisiones con muchas restricciones: el LLM no
recomputa lo que un programa puede calcular con razón exacta.
