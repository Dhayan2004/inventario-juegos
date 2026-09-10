# Mercado Pago — patrones canónicos (Mode C)

> Cita: [memory:decisions#D-038] · [memory:references#R-012] (PagoKit, MIT — `templates/mercadopago/*.md`
> destilados) · `docs/security/VETTING-pagokit-0.2.2.md` · [docs:mercadopago@v2].
> Hermano de `stripe-patterns.md` / `polar-patterns.md`. LATAM default: MX · AR · BR · CL · CO · PE · UY.

## 1. Dos flujos, una regla

| Flujo | API | Cuándo |
|---|---|---|
| **Checkout Pro** (hosted, default) | `Preference.create()` → redirect a `init_point` | pago único; menor fricción; OXXO/SPEI/Pix salen solos |
| **Suscripciones** | `PreApproval.create()` → el payer autoriza en `init_point` | recurrente; estados `pending → authorized → paused/cancelled` |
| Bricks (embebido) | `Payment.create()` con token de tarjeta del frontend | solo si el Tech Spec lo pide; requiere `NEXT_PUBLIC_MP_PUBLIC_KEY` + inventario PCI |

**La regla:** el cliente nombra QUÉ plan; el precio, la moneda y los rails salen del servidor
(`lib/mercadopago/plans.ts`, `MP_ALLOWED_PAYMENT_TYPES`). PAY-008.

## 2. Montos: unidad MAYOR en la API, unidades MENORES en la DB

MP recibe `transaction_amount: 199.00` (no `19900`) — al revés de Stripe. La DB guarda `amount_minor`
con el exponente ISO 4217 de la moneda (`references/currencies.md`): MXN 2, CLP **0**. Conversión
solo por `toMajorUnits` / `toMinorUnits` (`lib/mercadopago/server.ts`). Nunca `* 100` a ciegas (PAY-004).

## 3. Webhook: firma sobre el manifest, no sobre el body

```
x-signature:  ts=<unix>,v1=<hmac_hex>
x-request-id: <uuid>
query:        ?data.id=<id>
manifest    = id:{data.id};request-id:{x-request-id};ts:{ts};     ← termina en ';'
hmac        = HMAC-SHA256(MP_WEBHOOK_SECRET, manifest) hex, comparado con timingSafeEqual
```

Consecuencias que el handler ya implementa:
- **El body no está firmado** → solo se usan `type`, `action`, `data.id`; el estado real se **re-fetchea**
  (`mpPayment.get` / `mpPreApproval.get`). `payload_authoritative = false`.
- **Ventana 300 s** + **dedup por event id** (`webhook_events_processed`, G2): dos controles distintos del replay.
- **200/201 en ≤22 s** o MP reintenta cada 15 min. Nada pesado en el handler.
- **Las notificaciones QR no van firmadas** → no validar esas (no aplican a este template).
- Anti-patrón que mata integraciones: `createHmac(secret).update(rawBody)` → "invalid signature" en el
  100 % de los eventos → rotación de secrets en loop. El verificador vive en `lib/mercadopago/verify.ts`
  (puro) y lo prueba la Layer 3.

## 4. Rails LATAM (MX)

| Rail | `payment_type_id` | Reversible | Confirmación |
|---|---|---|---|
| Tarjeta | `credit_card` / `debit_card` | sí (refund API) | inmediata |
| **OXXO** | `ticket` | **no** — payout manual (R14, PAY-006) | webhook 1–48 h (efectivo) |
| **SPEI** | `bank_transfer` | **no** — payout manual | minutos–horas |
| Cuenta MP | `account_money` | sí | inmediata |

Configuración: `MP_ALLOWED_PAYMENT_TYPES` (default MX `credit_card,debit_card,ticket,bank_transfer`) →
`excluded_payment_types` en la Preference. `/success?pending=1` muestra "pendiente" para rails lentos;
**nunca** acceso anticipado — el webhook `payment.updated → approved` es la única fuente de verdad.

## 5. Suscripciones (PreApproval) — límites vs Stripe

- Estados: `pending` (creada) → `authorized` (cobra) → `paused` / `cancelled`. Cada cobro genera un
  `payment` (llega por `payment.*`); el estado de la suscripción llega por `subscription_preapproval`.
- **No hay `cancel_at_period_end`.** Default del action `cancelSubscription` = `paused` (se conserva la
  suscripción y el método; el webhook `paused` revoca acceso); `immediately = true` = `cancelled`.
  Si el producto exige "acceso hasta fin de periodo", la app guarda `current_period_end` y un job
  diario aplica `cancelled` al vencer — fuera del template (documentar en el Tech Spec).
- **No hay Customer Portal embebible.** `/billing` enlaza a `MP_SUBSCRIPTIONS_PORTAL_URL` (dominio por
  país: `.com.mx`, `.com.ar`, `.com.br`…).
- Acceso: `has_access = true` **solo** con `authorized`; `paused`/`cancelled` revocan (salvo otra sub activa).

## 6. Refunds y payouts

- Tarjeta: `PaymentRefund.create({ payment_id, requestOptions: { idempotencyKey: randomUUID() } })`
  (total; parcial = `body.amount` en unidad mayor).
- OXXO / SPEI / Pix: **no existe refund**; el action deja `refund_requests.status = failed` con
  `error_message = payout_required…` y un humano ejecuta la devolución (transferencia). R14: nunca
  automático.
- El webhook `payment.updated` con `status: refunded` reconcilia el ledger.

## 7. Errores (taxonomía cross-provider)

`status_detail` de MP → códigos comunes: `cc_rejected_insufficient_amount → insufficient_funds`,
`cc_rejected_bad_filled_security_code → incorrect_cvc`, `cc_rejected_high_risk → fraud_suspected`,
`cc_rejected_max_attempts → rate_limited`, `cc_rejected_3ds_* → requires_action`. Los mensajes al
usuario salen de `voice.json` (R10), no del proveedor.

## 8. Fiscal (MX): pago exitoso ≠ CFDI emitido

El catálogo marca `regions.MX.tax.einvoice = cfdi` (CFDI 4.0, B2B y B2C). Si el negocio debe facturar,
el checkout captura **RFC + uso de CFDI** antes del pago (no se puede retro-fitear) y un proveedor de
timbrado (Facturama/Facturapi/…) emite el comprobante. Ni MP ni este template lo hacen; `el-ontologo`
lo pregunta en Fase −1 y el Tech Spec lo decide. Mismo patrón: CO (DIAN), BR (NF-e), CL (DTE), PE (SUNAT).

## 9. Test cards / sandbox

Credenciales `TEST-…` → `MP_IS_SANDBOX = true` → `init_point` de prueba. Tarjetas de prueba varían por
país (docs de MP → "Tarjetas de prueba"); el titular `APRO` aprueba, `OTHE` rechaza. Webhook en sandbox
requiere URL pública (`cloudflared tunnel`). Layer 3 sin red: `tests/payments/webhook-mercadopago.test.mjs`.
