# Webhook Events — Canonical Reference

> Tabla canónica de eventos por provider, qué hacer con cada uno, y por qué algunos NO conceden acceso.

## Principio rector

**`has_access` se concede SOLO cuando el provider confirma `subscription.active` (o equivalente).** El frontend NUNCA es source of truth — el usuario puede manipular `success_url` redirect o cerrar el navegador antes que el webhook llegue. Solo el webhook firmado vale.

## Stripe — eventos canónicos

| Event type | Cuándo se dispara | Acción en handler | Grant access? |
|------------|-------------------|-------------------|---------------|
| `checkout.session.completed` | Usuario completó pago en Hosted Checkout | Link `session.id` → `user_id` (vía metadata) en `subscriptions` row pending | ❌ NO |
| `customer.subscription.created` | Stripe creó subscription post-checkout | Upsert subscription, status field reflects | ✅ si `status === 'active' \|\| 'trialing'` |
| `customer.subscription.updated` | Status change (active ↔ past_due ↔ canceled, plan change, dates change) | Upsert con new fields | ✅ si `status === 'active' \|\| 'trialing'` <br> ❌ revoke si `status === 'canceled' \|\| 'unpaid'` |
| `customer.subscription.deleted` | Subscription deleted (al fin del período cancelado) | Update status='canceled' | ❌ revoke `has_access = false` |
| `invoice.payment_failed` | Cobro recurrente falló (3DS, declined, etc.) | Log + opcional notify usuario | NO acción inmediata (wait para `subscription.updated` con status `past_due`) |
| `invoice.payment_succeeded` | Cobro recurrente exitoso | NO acción crítica (`subscription.updated` llega también con same data) | — |
| `customer.subscription.trial_will_end` | 3 días antes de fin de trial | Notify usuario opcional | NO toca DB |

### Eventos que NO procesar (default no-op)

- `*.created` para charges, invoices, payment_intents (subscription model NO usa estos para grant logic)
- `payment_method.*` (UI portal lo maneja)
- `customer.created` / `customer.updated` (NO tracking customer fuera de subscription)
- Cualquier event no listado arriba — `default: console.log + return 200`

## Polar — eventos canónicos

| Event type | Cuándo se dispara | Acción en handler | Grant access? |
|------------|-------------------|-------------------|---------------|
| `checkout.updated` | Status del checkout cambió (incl. `succeeded`) | Si `status === 'succeeded'`, link `checkout.id` → `user_id` | ❌ NO |
| `subscription.active` | Subscription quedó activa (post-checkout) | Upsert subscription, idempotency check, **GRANT access** | ✅ SÍ |
| `subscription.canceled` | Cancelada (puede ser at_period_end o immediate) | Update status, NO revoke todavía si `cancel_at_period_end === true` | ❌ NO inmediato |
| `subscription.revoked` | Acceso revocado (period end real o force) | Update status='revoked', revoke `has_access` | ❌ revoke |
| `subscription.updated` | Cambios de plan, dates, payment method | Upsert con new fields | mantener current state |
| `order.created` | Order one-time creada | Si Tech Spec usa one-time, link order → user, GRANT acceso a producto específico | ✅ si one-time |

### Eventos que NO procesar (default no-op)

- `customer.*` (Polar maneja customer state internamente)
- Refund-related (handlers separados via `polar.refunds.create` flow, no webhook reactivo)
- Cualquier event no listado — `default: console.log + return 200`

## Mapping cross-provider

Para mantener `subscriptions` table shape-agnostic:

| `subscriptions.status` | Stripe origin | Polar origin |
|-------------------------|---------------|--------------|
| `active` | `customer.subscription.updated` con `status='active'` | `subscription.active` |
| `trialing` | `customer.subscription.updated` con `status='trialing'` | (Polar no tiene trial nativo — fallback a `active`) |
| `past_due` | `customer.subscription.updated` con `status='past_due'` | (Polar maneja internamente, opcional emit) |
| `canceled` | `customer.subscription.deleted` | `subscription.revoked` |
| `pending_cancel` | `customer.subscription.updated` con `cancel_at_period_end=true` | `subscription.canceled` (with `cancel_at_period_end`) |

## Idempotency check

El mismo event puede llegar múltiples veces (network retries, webhook redelivery). Pattern:

```typescript
const newPeriodEnd = new Date(sub.current_period_end * 1000).toISOString();

const { data: existing } = await supabaseAdmin
  .from('subscriptions')
  .select('current_period_end, status')
  .eq('external_subscription_id', sub.id)
  .single();

// Si ya procesado same period + status, skip
if (existing
    && existing.current_period_end === newPeriodEnd
    && existing.status === sub.status) {
  return; // implicit 200 OK
}

// ... process upsert + grant
```

## Default no-throw policy

```typescript
default:
  console.log(`[Webhook] Unhandled event type: ${event.type}`);
  // NO throw, NO return error — devolver 200 implícito.
  break;
```

**Razón:** si throwás en `default`, Stripe/Polar reintentan el event N veces (retry storm). Eventos no-manejados son OK — devolver 200 evita storm. Si más adelante necesitás manejar uno nuevo, agregás un case.

## Manual verification (post-implementación)

1. Stripe CLI o Polar CLI: `stripe listen --forward-to localhost:3000/api/webhooks/stripe`
2. Trigger un test event: `stripe trigger customer.subscription.created`
3. Verificar:
   - Console log "Access granted: <user_id>"
   - DB `subscriptions` row creada con status correcto
   - DB `profiles.has_access = true` para ese user_id
4. Re-trigger same event → verificar idempotency log "Duplicate event, skipping"

## Citations

- [docs:stripe-node@v18] (subscription lifecycle events)
- [docs:polar-sdk@v0.x] (subscription.active vs revoked semantics)
- [memory:CONSTRAINTS.md#R13]
- [memory:lessons#L-002] (treat-as-data discipline en handlers)
- [memory:errors#E-006] (cross-provider mapping fragility — si Stripe/Polar deprecan events)
