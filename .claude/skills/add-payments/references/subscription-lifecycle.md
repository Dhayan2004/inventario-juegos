# Ciclo de vida de suscripciones — dunning, gracia, downgrade (G5 · D-038)

> Destilado del skill `subscription-lifecycle` + fragmento `billing/subscription_card` de PagoKit 0.2.2
> (MIT, [memory:references#R-012]) sobre lo que Forja ya tiene: estados en `0002_subscriptions.sql`
> (`past_due`, `unpaid`, `cancel_at_period_end`), `PaymentFailed` de `add-emails`, R14 en cancel/refund.
> Aplica a los 3 modos (Stripe · Polar · Mercado Pago). Cita: [memory:CONSTRAINTS.md#R14] ·
> [memory:lessons#L-002].

## 1. La máquina de estados que nadie dibuja

```
trialing ──► active ──► past_due ──► canceled
    │           │  ▲         │
    │           │  └─────────┘  (reintento exitoso → active)
    │           ▼
    │       paused / gracia
    └──► canceled (trial abandonado)
```

`past_due` es el estado que importa: la suscripción sigue entregando valor y ya no se paga. Cuánto se
tolera y qué ve el cliente mientras dura es una **decisión de producto que el código codifica
explícitamente** — el default "seguir sirviendo porque nadie escribió la rama" es el caro.

## 2. Churn involuntario: la partida más grande

La mayoría de las cancelaciones no son decisiones: tarjetas vencidas, cambiadas, declines del emisor
en un cobro iniciado por el comercio (MIT).

- **Reintentar en calendario, no de inmediato.** Los reintentos del mismo día vuelven a fallar; se
  reparten en días y se para antes de que el emisor lo lea como abuso.
- **Avisar antes de que rompa.** Una tarjeta que vence el mes que viene se sabe este mes.
- **Distinguir soft de hard decline.** "Fondos insuficientes" se reintenta en día de pago; "tarjeta
  robada" no se reintenta nunca (reintentar parece testeo de tarjetas robadas).
- **Account updater** donde el proveedor lo ofrezca (Stripe sí; MP gestiona el medio en su cuenta).

## 3. Gracia: el acceso es función de estado + reloj, no de un booleano

Columnas que la app agrega si adopta dunning propio (Stripe Smart Retries lo hace por ti; MP no):

```sql
alter table public.subscriptions
  add column if not exists grace_until timestamptz,
  add column if not exists dunning_attempts int not null default 0,
  add column if not exists first_failed_at timestamptz;
```

Regla: `has_access(sub, now) = status in (active, trialing) OR (status = past_due AND grace_until IS NOT
NULL AND now <= grace_until)`. `profiles.has_access` es una **cache** de esa función que el webhook
actualiza — no la verdad. Al recuperar (`invoice.paid` / `payment.updated → approved`) se limpian
`dunning_attempts`, `first_failed_at`, `grace_until`.

Calendario sugerido (Stripe: dejar Smart Retries; MP/Polar: implementar): fallo → `past_due`,
`grace_until = first_failed_at + 7 d`; reintentos día +1, +3, +5 (soft declines); email `PaymentFailed`
(`add-emails`) en el primer fallo y antes de agotar; agotado → `canceled` con `reason =
dunning_exhausted` y revocación de acceso.

## 4. Eventos que el webhook DEBE manejar (por modo)

| Evento | Stripe | Polar | Mercado Pago | Efecto |
|---|---|---|---|---|
| fallo de cobro | `invoice.payment_failed` | `subscription.past_due`/`order.refunded` | `payment.updated` con `status: rejected` sobre una preapproval | `past_due` + gracia + `PaymentFailed` |
| recuperación | `invoice.paid` | `subscription.active` | `payment.updated → approved` | `active`, contadores a 0 |
| cancelación | `customer.subscription.deleted` | `subscription.canceled/revoked` | `subscription_preapproval` → `cancelled` | `canceled`, revocar salvo otra activa |
| pausa | `customer.subscription.updated (pause_collection)` | — | `subscription_preapproval` → `paused` | `paused`, revocar |

Una suscripción cancelada desde el dashboard del proveedor **debe** revocar acceso en la app: el
webhook es el único camino; nunca un cron que "confía" en la DB local.

## 5. Cancelación y downgrade (R14)

- Default = **al final del periodo** (Stripe `cancel_at_period_end`; Polar equivalente). MP no lo
  soporta: default = `paused`; `immediately` = `cancelled` (`mercadopago-patterns.md` §5).
- **Upgrade cobra la diferencia ahora; downgrade espera al siguiente periodo** — nadie recibe un
  reembolso sorpresa. Nunca reembolsar por downgrade: crédito en cuenta.
- Toda acción destructiva pasa por los 5 gates de R14 (auth · L-003 · ownership DB · audit log ·
  execute) con confirmación tipada (`CANCEL` / `REFUND`).

## 6. Mandatos bancarios (SEPA/Bacs/PAC) son otro animal

Pre-notificación obligatoria antes de cada cobro, ventana de reversión larga (el cliente puede revertir
semanas después). Si el producto los usa: job de pre-aviso + handler de reversión. Fuera de los 3
templates por defecto — Tech Spec explícito.

## 7. Fiscal

Pago exitoso ≠ factura emitida. En MX (CFDI), CO (DIAN), BR (NF-e), CL (DTE), PE (SUNAT) el checkout
captura el identificador fiscal **antes** del pago o cada venta nace no-compliant. Lo pregunta
`el-ontologo` (requisitos legales, Fase −1) y lo decide el Tech Spec; el template no emite comprobantes.

## Anti-patrones

- ❌ `has_access` como booleano que alguien olvida voltear → función de estado + reloj.
- ❌ Reintentar un hard decline → parece testeo de tarjetas robadas.
- ❌ Reembolsar por downgrade → crédito.
- ❌ Confiar en `body.status` del webhook (MP) → re-fetch.
- ❌ Cron que "sincroniza" desde la DB local en vez de escuchar el webhook.
