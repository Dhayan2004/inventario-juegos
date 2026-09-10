/**
 * /billing — server component (Polar customer portal entry)
 *
 * El customer portal de Polar es URL externa polar.sh/<merchant>/portal/...
 * NO embed iframe — full redirect.
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
    canceled: 'Cancelada',
    revoked: 'Revocada',
    past_due: 'Pago vencido',
  };
  return map[status] ?? status;
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
    .order('current_period_end', { ascending: false })
    .limit(1)
    .maybeSingle();

  return (
    <main aria-labelledby="billing-title">
      <h1 id="billing-title">{'{{ COPY_BILLING_TITLE }}'}</h1>

      {!sub ? (
        <Card>
          <p>No tenés una suscripción activa.</p>
          <Button as="a" href="/pricing" variant="primary">Ver planes</Button>
        </Card>
      ) : (
        <Card data-state={sub.status}>
          <header>
            <Badge
              variant={
                sub.status === 'active' || sub.status === 'trialing'
                  ? 'success'
                  : 'warning'
              }
            >
              {labelForStatus(sub.status)}
            </Badge>
            <h2>{sub.plan_id ?? 'Suscripción'}</h2>
          </header>

          <dl>
            <dt>Próxima fecha</dt>
            <dd>{formatDate(sub.current_period_end)}</dd>
            <dt>Importe</dt>
            <dd>
              {sub.amount_cents != null
                ? `${(sub.amount_cents / 100).toFixed(2)} ${sub.currency?.toUpperCase()}`
                : '—'}
            </dd>
            <dt>Provider</dt>
            <dd>Polar (Merchant of Record)</dd>
          </dl>

          {sub.cancel_at_period_end && (
            <p role="alert" data-state="warning">
              Tu suscripción se cancelará el {formatDate(sub.current_period_end)}.
            </p>
          )}

          <p data-state="info">
            Te redirigimos al portal de facturación de Polar para gestionar
            tu suscripción.
          </p>

          <form action="/api/polar/portal" method="POST">
            <Button type="submit" variant="primary">
              {'{{ COPY_PORTAL_CTA }}'}
            </Button>
          </form>
        </Card>
      )}
    </main>
  );
}
