# Generate Subscription Flows — R14 strict enforcement

> **Cita primaria:** [memory:CONSTRAINTS.md#R14] (Destructive tools requieren confirmación humana — NO `execute()` automático)
> **Cita secundaria:** [memory:lessons#L-003] (whitelist validators en inputs externos)

## Operaciones cubiertas

Estas son las flows que tocan dinero o estado destructivo. Cada una lleva R14 gate explícito:

| Flow | Tipo | R14 gate |
|------|------|----------|
| `createCheckoutSession` | NO destructive (crear session, no charge yet) | rate limit (5 req/user/hour) |
| `createPortalSession` | NO destructive | auth guard |
| `requestRefund` | DESTRUCTIVE (reverso de pago) | typed-confirmation `REFUND` + ownership + audit log |
| `cancelSubscription` | DESTRUCTIVE (revoca acceso) | typed-confirmation `CANCEL` + ownership + audit log |
| `transferFunds` | DESTRUCTIVE (Stripe Connect — fuera de scope F3-S4 default) | typed-confirmation `TRANSFER` + double-auth + audit log (NO ship en core) |

## Anti-pattern (NUNCA)

```typescript
// ❌ NO — execute automático en destructiva
import { tool } from 'ai';

export const refundCharge = tool({
  description: 'Refund a charge',
  inputSchema: z.object({ chargeId: z.string() }),
  execute: async ({ chargeId }) => {
    return await stripe.refunds.create({ charge: chargeId });
  },
});
```

R14 enforcement: el-evaluador rechaza este shape inmediatamente. NO execute en destructiva.

## Pattern correcto

### `requestRefund` — Stripe

```typescript
'use server';
import { z } from 'zod';
import { redirect } from 'next/navigation';
import { stripe } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';

/**
 * Request a refund on a charge.
 *
 * R14 enforcement: NO automatic execute. Requires:
 *   1. Authenticated user (auth guard)
 *   2. Ownership validation (charge.metadata.user_id === user.id)
 *   3. Typed confirmation gate ("REFUND" exact string)
 *   4. Audit log row in `refund_requests` BEFORE execute
 *   5. Server action invoked from form (NOT a tool with execute())
 *
 * Cita: [memory:CONSTRAINTS.md#R14]
 */

// L-003: whitelist explícito, NO z.string() libre
const RefundInputSchema = z.object({
  chargeId: z.string().regex(/^ch_[a-zA-Z0-9]{20,}$/, 'Invalid charge id'),
  reason: z.enum(['requested_by_customer', 'duplicate', 'fraudulent']),
  confirmation: z.literal('REFUND', {
    errorMap: () => ({ message: 'Tipea exactamente REFUND para confirmar.' }),
  }),
});

export async function requestRefund(_prevState: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return { error: 'Sesión expirada. Iniciá sesión de nuevo.' };
  }

  // 1. Validate input shape (L-003)
  const parsed = RefundInputSchema.safeParse({
    chargeId: formData.get('chargeId'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // 2. Ownership: charge.metadata.user_id must match user.id
  const charge = await stripe.charges.retrieve(parsed.data.chargeId);
  if (charge.metadata?.user_id !== user.id) {
    console.error('[Refund] Ownership mismatch', {
      chargeId: parsed.data.chargeId,
      requested_by: user.id,
      charge_owner: charge.metadata?.user_id,
    });
    return { error: 'No tenés permiso para reembolsar este pago.' };
  }

  // 3. Audit log BEFORE execute (idempotency — re-submit fails)
  const { error: logErr } = await supabase
    .from('refund_requests')
    .insert({
      user_id: user.id,
      charge_id: parsed.data.chargeId,
      reason: parsed.data.reason,
      requested_at: new Date().toISOString(),
      status: 'pending',
    });
  if (logErr) {
    if (logErr.code === '23505') { // unique violation
      return { error: 'Ya solicitaste un reembolso para este pago.' };
    }
    return { error: 'Error registrando la solicitud. Intentá de nuevo.' };
  }

  // 4. Execute refund (only after gates 1-3)
  try {
    const refund = await stripe.refunds.create({
      charge: parsed.data.chargeId,
      reason: parsed.data.reason,
      metadata: { user_id: user.id, requested_via: 'self_service' },
    });

    // 5. Update audit log
    await supabase
      .from('refund_requests')
      .update({ status: 'completed', refund_id: refund.id })
      .eq('charge_id', parsed.data.chargeId);

    return { success: true, refundId: refund.id };
  } catch (err) {
    console.error('[Refund] Stripe API error', err);
    await supabase
      .from('refund_requests')
      .update({ status: 'failed', error_message: String(err) })
      .eq('charge_id', parsed.data.chargeId);
    return { error: 'Error procesando el reembolso. Contactanos.' };
  }
}
```

### `cancelSubscription` — Stripe

```typescript
const CancelInputSchema = z.object({
  subscriptionId: z.string().regex(/^sub_[a-zA-Z0-9]{20,}$/),
  immediately: z.boolean().default(false),
  confirmation: z.literal('CANCEL', {
    errorMap: () => ({ message: 'Tipea exactamente CANCEL para confirmar.' }),
  }),
});

export async function cancelSubscription(_prev: unknown, formData: FormData) {
  // ... mismo shape: auth → validate input → ownership check via subscriptions table
  // ownership: subscriptions.user_id === user.id (DB-backed, not metadata)

  // Default behavior: cancel at period end (NO immediate revoke).
  // Solo si immediately=true, ejecuta cancel ahora.
  const result = parsed.data.immediately
    ? await stripe.subscriptions.cancel(parsed.data.subscriptionId)
    : await stripe.subscriptions.update(parsed.data.subscriptionId, {
        cancel_at_period_end: true,
      });

  // Webhook customer.subscription.updated llega y refleja el cambio en DB.
  return { success: true };
}
```

### Polar variantes

`refundCharge` y `cancelSubscription` en Polar siguen el mismo patrón. Diferencias:

```typescript
// Polar — refund
await polar.refunds.create({
  subscription_id: parsed.data.subscriptionId,
  reason: parsed.data.reason,
});

// Polar — cancel
await polar.subscriptions.update({
  id: parsed.data.subscriptionId,
  data: { cancel_at_period_end: true },
});
```

## UI form pattern

Las flows destructivas se invocan desde un form con `useFormState` (React 19) + typed-confirmation input:

```tsx
'use client';
import { useActionState } from 'react';
import { requestRefund } from '@/actions/stripe';
import { Button, Input } from '@/shared/components/ui';

export function RefundForm({ chargeId }: { chargeId: string }) {
  const [state, formAction, pending] = useActionState(requestRefund, null);

  return (
    <form action={formAction}>
      <input type="hidden" name="chargeId" value={chargeId} />
      <select name="reason" required>
        <option value="requested_by_customer">Decisión personal</option>
        <option value="duplicate">Cobro duplicado</option>
        <option value="fraudulent">No reconozco este cargo</option>
      </select>
      <Input
        name="confirmation"
        label="Confirmación"
        hint='Para confirmar, tipeá exactamente: REFUND'
        required
        autoComplete="off"
      />
      {state?.error && <p role="alert">{state.error}</p>}
      {state?.success && <p role="status">Reembolso solicitado.</p>}
      <Button type="submit" variant="destructive" disabled={pending}>
        {pending ? 'Procesando...' : 'Solicitar reembolso'}
      </Button>
    </form>
  );
}
```

## Migration `refund_requests` table

```sql
-- migrations/0003_refund_requests.sql (opcional, solo si refunds self-service activos)
create table public.refund_requests (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  charge_id text not null,
  refund_id text,
  reason text not null check (reason in ('requested_by_customer', 'duplicate', 'fraudulent')),
  status text not null default 'pending' check (status in ('pending', 'completed', 'failed')),
  error_message text,
  requested_at timestamptz default now(),
  completed_at timestamptz,
  unique (charge_id) -- idempotency: solo una solicitud por charge
);

alter table public.refund_requests enable row level security;

create policy "users see own refund requests" on public.refund_requests
  for select using (auth.uid() = user_id);

create index idx_refund_requests_user_id on public.refund_requests(user_id);
```

Cita en preámbulo del SQL: `[memory:lessons#L-001]` + `[memory:CONSTRAINTS.md#R14]`.

## Verificación post-gen

```bash
# 1. NO export con execute() en destructivas
! grep -E "^export.*tool\(.*execute.*async.*(refund|cancel|transfer)" \
    src/actions/{stripe,polar}.ts

# 2. Typed confirmation literal
grep -E "z\.literal\('(REFUND|CANCEL)'" src/actions/{stripe,polar}.ts

# 3. Ownership check antes de execute
grep -B3 "stripe\.refunds\.create\|polar\.refunds\.create" \
    src/actions/{stripe,polar}.ts | grep -E "user\.id|metadata\.user_id"

# 4. Audit log insert antes de execute
grep -B5 "stripe\.refunds\.create\|polar\.refunds\.create" \
    src/actions/{stripe,polar}.ts | grep -q "refund_requests"

# 5. L-003 whitelist en input schema
grep -E "z\.enum\(\[.*requested_by_customer" src/actions/{stripe,polar}.ts

# 6. Default cancel = at_period_end (no immediate)
grep -A3 "immediately:" src/actions/{stripe,polar}.ts | grep -q "default(false)"
```

6/6 → PASS.

## Refusals

- ❌ Export `refundCharge`/`cancelSubscription`/`transferFunds` como `tool({ execute })`. R14 binario.
- ❌ Skip ownership check (charge.metadata.user_id vs user.id, o subscriptions.user_id vs user.id).
- ❌ Skip typed-confirmation gate. NO usar checkbox o "are you sure?" modal soft.
- ❌ Skip audit log. Cada destructiva tiene su row en DB pre-execute.
- ❌ Default cancel inmediato. Default = `cancel_at_period_end = true` (preserva acceso pagado).
- ❌ Aceptar `reason` como `z.string()` libre. Whitelist enum L-003.

## Citations

- [memory:CONSTRAINTS.md#R14] (sin execute() en destructive tools)
- [memory:lessons#L-003] (whitelist validators en inputs)
- [memory:lessons#L-001] (RLS en refund_requests)
- [memory:CONSTRAINTS.md#R13] (find-docs)
- [docs:stripe-node@latest] · [docs:polar-sdk@v0.x] · [docs:nextjs] (R13)
