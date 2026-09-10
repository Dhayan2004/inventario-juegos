/**
 * /billing — server component (Mode C, Mercado Pago)
 *
 * Lee active subscription via RLS-protected query.
 * MP no tiene Customer Portal embebible: el botón lleva al portal de
 * suscripciones del payer en Mercado Pago; pausar/cancelar desde la app va
 * por el server action (R14, confirmación tipada).
 *
 * R10 Brand DNA gate enforced.
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:lessons#L-001]
 */
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { Card, Button, Badge } from '@/shared/components/ui';

function labelForStatus(status: string): string {
  const map: Record<string, string> = {
    active: 'Activa',
    trialing: 'En prueba',
    past_due: 'Pago vencido',
    paused: 'Pausada',
    canceled: 'Cancelada',
    unpaid: 'Sin pago',
    incomplete: 'Pendiente de autorización',
  };
  return map[status] ?? status;
}

/** Exponente ISO 4217 — mantener en sync con lib/mercadopago/server.ts (references/currencies.md). */
const EXPONENT: Record<string, number> = { mxn: 2, usd: 2, brl: 2, ars: 2, cop: 2, pen: 2, uyu: 2, clp: 0 };

function formatAmount(amountMinor: number | null, currency: string | null): string {
  if (amountMinor == null || !currency) return '—';
  const exp = EXPONENT[currency] ?? 2;
  return `${(amountMinor / 10 ** exp).toFixed(exp)} ${currency.toUpperCase()}`;
}

function formatDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('es-MX', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export default async function BillingPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/sign-in?next=/billing');

  const { data: sub } = await supabase
    .from('subscriptions')
    .select('*')
    .eq('user_id', user.id)
    .in('status', ['active', 'trialing', 'past_due', 'paused', 'canceled'])
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  return (
    <main aria-labelledby="billing-title">
      <h1 id="billing-title">{'{{ COPY_BILLING_TITLE }}'}</h1>

      {!sub ? (
        <Card>
          <p>No tienes una suscripción activa.</p>
          <Button as="a" href="/pricing" variant="primary">
            Ver planes
          </Button>
        </Card>
      ) : (
        <Card data-state={sub.status}>
          <header>
            <Badge variant={sub.status === 'active' || sub.status === 'trialing' ? 'success' : 'warning'}>
              {labelForStatus(sub.status)}
            </Badge>
            <h2>Plan: {sub.plan_id ?? '—'}</h2>
          </header>

          <dl>
            <dt>Próxima fecha de cobro</dt>
            <dd>{formatDate(sub.current_period_end)}</dd>
            <dt>Importe</dt>
            <dd>{formatAmount(sub.amount_cents, sub.currency)}</dd>
          </dl>

          {sub.status === 'paused' && (
            <p role="alert" data-state="warning">
              Tu suscripción está pausada: no se cobrará hasta que la reanudes desde Mercado Pago.
            </p>
          )}

          <form action="/api/mercadopago/portal" method="POST">
            <Button type="submit" variant="primary">
              {'{{ COPY_PORTAL_CTA }}'}
            </Button>
          </form>
        </Card>
      )}
    </main>
  );
}
