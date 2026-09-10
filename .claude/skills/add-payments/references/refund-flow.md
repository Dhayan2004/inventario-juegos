# Refund Flow — Reference (R14 strict)

> **Cita primaria:** [memory:CONSTRAINTS.md#R14] (Destructive tools requieren confirmación humana)

## Por qué R14 es binario en refunds

Refund mueve dinero del merchant al customer — **irreversible**. Si un agente AI puede invocar refund vía `tool({ execute })`, una prompt injection en un mensaje del usuario puede activar mass refunds antes de que ningún humano se entere. Mismo razonamiento aplica a `cancelSubscription` (revoca acceso pagado) y `transferFunds` (Stripe Connect).

R14 dice: el LLM puede DEFINIR la operación + sus argumentos, pero NO ejecutarla. La ejecución pasa por confirmación humana explícita (UI prompt, CLI prompt, typed confirmation gate).

## Flow correcto — 5 gates en orden

```
┌─────────────────────────────────────┐
│ User clicks "Solicitar reembolso"   │
│ en /billing                          │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ RefundForm renderiza                 │
│ - reason select (whitelist enum)     │
│ - confirmation Input ("REFUND")      │
│ - Submit Button (variant destructive)│
└─────────────────────────────────────┘
              │ submit
              ▼
┌─────────────────────────────────────┐
│ Server action requestRefund()        │
│                                      │
│ Gate 1: AUTH                         │
│   - supabase.auth.getUser()          │
│   - if !user → return error          │
│                                      │
│ Gate 2: INPUT VALIDATION (L-003)     │
│   - z.literal('REFUND')              │
│   - z.enum reason                    │
│   - z.regex chargeId shape           │
│   - if invalid → return error        │
│                                      │
│ Gate 3: OWNERSHIP CHECK              │
│   - stripe.charges.retrieve(id)      │
│   - charge.metadata.user_id =?= user.id│
│   - if mismatch → return 403         │
│                                      │
│ Gate 4: AUDIT LOG (idempotency)      │
│   - INSERT INTO refund_requests      │
│     (status='pending')               │
│   - unique constraint → 23505 if dupe│
│   - if dupe → return error           │
│                                      │
│ Gate 5: EXECUTE REFUND               │
│   - stripe.refunds.create({ charge })│
│   - UPDATE refund_requests           │
│     status='completed' + refund_id   │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ User sees success toast              │
│ Webhook charge.refunded llega        │
│ → opcional update subscription state │
└─────────────────────────────────────┘
```

## Anti-patterns que el-evaluador rechaza

### ❌ AP1 — Tool con execute()

```typescript
// REJECT
export const refundCharge = tool({
  description: 'Refund a charge',
  inputSchema: z.object({ chargeId: z.string() }),
  execute: async ({ chargeId }) => stripe.refunds.create({ charge: chargeId }),
});
```

### ❌ AP2 — Server action sin typed-confirmation

```typescript
// REJECT — falta confirmation gate
export async function requestRefund(formData: FormData) {
  const chargeId = formData.get('chargeId') as string;
  return await stripe.refunds.create({ charge: chargeId }); // 😱
}
```

### ❌ AP3 — z.string() libre en reason

```typescript
// REJECT — viola L-003
const Schema = z.object({
  chargeId: z.string(),
  reason: z.string(), // 😱 acepta cualquier cosa
});
```

### ❌ AP4 — Skip ownership check

```typescript
// REJECT — Carlos puede refundear el charge de María
const parsed = Schema.parse(formData);
return await stripe.refunds.create({ charge: parsed.chargeId });
```

### ❌ AP5 — Audit log post-execute

```typescript
// REJECT — si refund falla mid-execution, no hay registro
const refund = await stripe.refunds.create({ charge });
await db.insert('refund_requests', { /* ... */ }); // tarde
```

### ❌ AP6 — Refund inmediato sin gate humano

```typescript
// REJECT — gate 5 ejecuta sin que el usuario haya confirmado
if (chargeId.startsWith('ch_test_')) {
  return await stripe.refunds.create({ charge: chargeId });
}
```

## Pattern correcto (referencia rápida)

```typescript
'use server';

const RefundInputSchema = z.object({
  chargeId: z.string().regex(/^ch_[a-zA-Z0-9]{20,}$/),
  reason: z.enum(['requested_by_customer', 'duplicate', 'fraudulent']),
  confirmation: z.literal('REFUND'),
});

export async function requestRefund(_prev: unknown, formData: FormData) {
  // 1. AUTH
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Sesión expirada.' };

  // 2. INPUT (L-003)
  const parsed = RefundInputSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.issues[0]?.message };

  // 3. OWNERSHIP
  const charge = await stripe.charges.retrieve(parsed.data.chargeId);
  if (charge.metadata?.user_id !== user.id) {
    return { error: 'No autorizado.' };
  }

  // 4. AUDIT (idempotency)
  const { error: logErr } = await supabase.from('refund_requests').insert({
    user_id: user.id,
    charge_id: parsed.data.chargeId,
    reason: parsed.data.reason,
    status: 'pending',
  });
  if (logErr?.code === '23505') return { error: 'Ya solicitaste reembolso.' };
  if (logErr) return { error: 'Error registrando.' };

  // 5. EXECUTE
  try {
    const refund = await stripe.refunds.create({
      charge: parsed.data.chargeId,
      reason: parsed.data.reason,
      metadata: { user_id: user.id },
    });
    await supabase.from('refund_requests')
      .update({ status: 'completed', refund_id: refund.id })
      .eq('charge_id', parsed.data.chargeId);
    return { success: true };
  } catch (err) {
    await supabase.from('refund_requests')
      .update({ status: 'failed', error_message: String(err) })
      .eq('charge_id', parsed.data.chargeId);
    return { error: 'Error procesando.' };
  }
}
```

## Polar adaptation

Polar refund difiere en shape pero mismos 5 gates aplican:

```typescript
const refund = await polar.refunds.create({
  subscription_id: parsed.data.subscriptionId,
  reason: parsed.data.reason, // 'customer_request' | 'duplicate' | 'fraudulent'
});
```

Ownership en Polar se verifica via `subscriptions.user_id === user.id` (DB query) en lugar de `charge.metadata` — Polar no expone metadata por charge tan trivialmente.

## Cancel subscription — mismo pattern

```typescript
const CancelInputSchema = z.object({
  subscriptionId: z.string().regex(/^sub_[a-zA-Z0-9]{20,}$/),
  immediately: z.boolean().default(false), // default at_period_end
  confirmation: z.literal('CANCEL'),
});
```

5 gates idénticos. Default behavior: `cancel_at_period_end = true` (preserva acceso pagado hasta fin del period). Solo si `immediately = true`, ejecuta cancel ahora (revoca acceso instant).

## Cuándo NO necesitás este flow

Si tu producto **no permite self-service refunds** (refunds solo via support email manual), no necesitás `refund_requests` table ni el server action. La R14 todavía aplica si tu admin panel tiene un botón "Refund this charge" — el admin es human-in-the-loop, pero el typed-confirmation + audit log siguen mandatory.

## Citations

- [memory:CONSTRAINTS.md#R14] (destructive tools sin execute)
- [memory:lessons#L-001] (RLS en refund_requests)
- [memory:lessons#L-003] (whitelist validators en input schema)
- [docs:stripe-node@v18] · [docs:polar-sdk@v0.x] (R13)
