# Generate Customer Portal — /billing entry

## Antes de empezar (R13)

```
Stripe mode:
  resolve-library-id("stripe-node") → query-docs
  query: "stripe.billingPortal.sessions.create return_url customer
          customer_portal Stripe v18"

Polar mode:
  resolve-library-id("polar-sdk") → query-docs
  query: "polar.customerSessions.create customer portal redirect URL"
```

**Razón:** Customer portal API shape difiere entre providers — Stripe expone `billingPortal.sessions.create({ customer, return_url })`, Polar expone `customerSessions.create({ customer_id })` con URL devuelta diferente. Sin find-docs, generar contra shape viejo falla en runtime al primer click.

## /billing page (server component)

`src/app/(billing)/billing/page.tsx` es la entry al customer portal:
- Lee la subscription activa del usuario actual (RLS-protected query a `subscriptions` table).
- Renderiza un summary card (plan, próxima fecha de cobro, estado).
- Botón "Gestionar facturación" invoca server action que crea portal session y redirige.

```tsx
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { Card, Button, Badge } from '@/shared/components/ui';
import { createPortalSession } from '@/actions/stripe';
// (Polar mode: importa de @/actions/polar)

/**
 * /billing — customer portal entry
 *
 * R10 Brand DNA gate enforced.
 * Server component — reads subscription via RLS-protected query.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:lessons#L-001]
 */
export default async function BillingPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/sign-in?next=/billing');

  // RLS garantiza que solo trae la sub del user actual
  const { data: sub } = await supabase
    .from('subscriptions')
    .select('*')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing', 'past_due'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .single();

  return (
    <main aria-labelledby="billing-title">
      <h1 id="billing-title">{COPY_BILLING_TITLE}</h1>

      {!sub ? (
        <Card>
          <p>No tenés una suscripción activa.</p>
          <Button as="a" href="/pricing" variant="primary">
            Ver planes
          </Button>
        </Card>
      ) : (
        <Card data-state={sub.status}>
          <Badge variant={sub.status === 'active' ? 'success' : 'warning'}>
            {labelForStatus(sub.status)}
          </Badge>
          <p>Plan: {sub.plan_id}</p>
          <p>Próxima fecha: {formatDate(sub.current_period_end)}</p>
          {sub.cancel_at_period_end && (
            <p role="alert">
              Tu suscripción se cancelará el {formatDate(sub.current_period_end)}.
            </p>
          )}
          <form action={createPortalSession}>
            <Button type="submit" variant="primary">
              {COPY_PORTAL_CTA}
            </Button>
          </form>
        </Card>
      )}
    </main>
  );
}
```

## Server action `createPortalSession`

En `src/actions/{stripe,polar}.ts`:

### Stripe

```typescript
'use server';
import { redirect } from 'next/navigation';
import { stripe } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';

export async function createPortalSession() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/sign-in');

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_customer_id')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing', 'past_due'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .single();

  if (!sub?.external_customer_id) {
    redirect('/pricing?reason=no_active_sub');
  }

  const session = await stripe.billingPortal.sessions.create({
    customer: sub.external_customer_id,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/billing`,
  });

  redirect(session.url);
}
```

### Polar

```typescript
'use server';
import { redirect } from 'next/navigation';
import { polar } from '@/lib/polar/server';
import { createClient } from '@/lib/supabase/server';

export async function createPortalSession() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/sign-in');

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('external_customer_id')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing'])
    .limit(1)
    .single();

  if (!sub?.external_customer_id) {
    redirect('/pricing?reason=no_active_sub');
  }

  // Polar customer portal es URL externa (polar.sh)
  const session = await polar.customerSessions.create({
    customer_id: sub.external_customer_id,
  });

  redirect(session.customer_portal_url);
}
```

## R10 contract

| Componente | Source |
|------------|--------|
| `<Card>` | impeccable output (R10 — NO Tailwind blue/gray) |
| `<Button>` | impeccable, variant primary derivado de brand.json.tokens.colors.accent |
| `<Badge>` | impeccable, variant success/warning/destructive |
| `COPY_BILLING_TITLE` | hardcoded simple "Tu suscripción" — voice.json no aplica acá si genérico |
| `COPY_PORTAL_CTA` | voice.cta_examples → fallback "Gestionar facturación" |

## Status labels

```typescript
function labelForStatus(status: string): string {
  const map: Record<string, string> = {
    active:   'Activa',
    trialing: 'En prueba',
    past_due: 'Pago vencido',
    canceled: 'Cancelada',
    unpaid:   'Sin pago',
  };
  return map[status] ?? status;
}
```

NO traducir status keys del DB (keep `active`, `trialing`, etc. exactos como vienen del provider). Solo el label visible.

## Verificación post-gen

```bash
# 1. Server component (no 'use client' en page)
! grep -q "'use client'" src/app/(billing)/billing/page.tsx

# 2. RLS-aware query (filtra por user_id, no .from('subscriptions') sin filtro)
grep -A5 "from('subscriptions')" src/app/(billing)/billing/page.tsx \
  | grep -q "eq('user_id', user.id)"

# 3. createPortalSession server action declared
grep -q "'use server'" src/actions/{stripe,polar}.ts
grep -q "export async function createPortalSession" src/actions/{stripe,polar}.ts

# 4. Auth guard
grep -B2 "createPortalSession\|BillingPage" src/app/(billing)/billing/page.tsx \
  | grep -q "redirect.*sign-in"

# 5. R10 imports
grep -q "@/shared/components/ui" src/app/(billing)/billing/page.tsx

# 6. NO Tailwind hardcoded colors
! grep -E "bg-(blue|purple|gray|red)-(400|500|600|700)" src/app/(billing)/billing/page.tsx
```

6/6 checks → PASS.

## Refusals

- ❌ /billing como client component (rompe RLS — la query tiene que correr server-side con auth cookies).
- ❌ Query `subscriptions` sin `eq('user_id', user.id)`. Aún con RLS habilitado, defense-in-depth.
- ❌ Embed iframe del Stripe/Polar portal (ambos requieren full redirect).
- ❌ Hardcodear `customer_id` del provider en el código. Siempre vía `subscriptions.external_customer_id`.
- ❌ Conceder acceso a /billing si user no tiene auth. `redirect('/sign-in?next=/billing')`.

## Citations

- [docs:stripe@v18] · [docs:stripe-node] (R13 — billingPortal.sessions.create shape)
- [docs:polar-sdk@v0.x] (R13 — customerSessions.create shape)
- [docs:nextjs] (server actions, redirect)
- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract — /billing consume Card/Button/Badge)
- [memory:lessons#L-001] (RLS-protected query)
