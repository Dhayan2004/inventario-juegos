/**
 * /pricing — server component (Mode C, Mercado Pago)
 *
 * R10 Brand DNA gate enforced.
 * Tokens leídos de brand/brand.json (vía CSS vars en brand.css).
 * CTAs derivan de brand/voice.json#cta_examples (gate 7 con fallback
 * conservador si genéricos sin orientación payment).
 * Componentes de @/shared/components/ui (impeccable output).
 *
 * Precios en UNIDADES MENORES + exponente ISO 4217 (PAY-004): MXN 2, CLP 0.
 * El servidor es dueño del precio (PAY-008): el form solo manda `planId`.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005] · [memory:references#R-012]
 */
import { Card, Button, Badge } from '@/shared/components/ui';
import type { PricingTier } from '@/types/billing';

const TIERS: PricingTier[] = [
  {
    id: 'hobby',
    name: 'Hobby',
    label: 'Empieza gratis',
    amountCents: 0,
    currency: 'mxn',
    interval: 'month',
    features: ['Hasta 100 usuarios', 'Soporte por email', 'Updates'],
    priceId: process.env.NEXT_PUBLIC_MP_PLAN_ID_HOBBY ?? '',
  },
  {
    id: 'pro',
    name: 'Pro',
    label: 'Más popular',
    featured: true,
    amountCents: 49900,
    currency: 'mxn',
    interval: 'month',
    features: ['Usuarios ilimitados', 'Soporte prioritario', 'API access'],
    priceId: process.env.NEXT_PUBLIC_MP_PLAN_ID_PRO ?? '',
  },
  {
    id: 'team',
    name: 'Team',
    label: 'Para equipos',
    amountCents: 149900,
    currency: 'mxn',
    interval: 'month',
    features: ['Todo de Pro', 'SSO', 'Audit log', 'Soporte dedicado'],
    priceId: process.env.NEXT_PUBLIC_MP_PLAN_ID_TEAM ?? '',
  },
];

/** Exponente ISO 4217 — mantener en sync con lib/mercadopago/server.ts (references/currencies.md). */
const EXPONENT: Record<string, number> = { mxn: 2, usd: 2, brl: 2, ars: 2, cop: 2, pen: 2, uyu: 2, clp: 0 };

function formatPrice(amountMinor: number, currency: string, interval: string): string {
  if (amountMinor === 0) return 'Gratis';
  const exp = EXPONENT[currency] ?? 2;
  const amount = (amountMinor / 10 ** exp).toFixed(0);
  const symbol = currency === 'usd' ? 'US$' : currency === 'mxn' ? 'MX$' : currency.toUpperCase() + ' ';
  return `${symbol}${amount}/${interval === 'month' ? 'mes' : 'año'}`;
}

export default function PricingPage() {
  return (
    <main aria-labelledby="pricing-title" className="pricing-page">
      <header>
        <h1 id="pricing-title">{'{{ COPY_PRICING_TITLE }}'}</h1>
      </header>

      <section role="region" aria-label="Planes disponibles" className="tiers">
        {TIERS.map((tier) => (
          <Card
            key={tier.id}
            data-tier={tier.id}
            data-featured={tier.featured ? 'true' : undefined}
            variant={tier.featured ? 'elevated' : 'default'}
          >
            <header>
              <Badge variant={tier.featured ? 'primary' : 'subtle'}>
                {tier.label}
              </Badge>
              <h2>{tier.name}</h2>
              <p className="price" aria-label={`Precio: ${formatPrice(tier.amountCents, tier.currency, tier.interval)}`}>
                {formatPrice(tier.amountCents, tier.currency, tier.interval)}
              </p>
            </header>
            <ul aria-label="Incluido">
              {tier.features.map((f, i) => (
                <li key={i}>{f}</li>
              ))}
            </ul>
            <form action={`/api/mercadopago/checkout`} method="POST">
              <input type="hidden" name="planId" value={tier.priceId} />
              <Button
                type="submit"
                variant={tier.featured ? 'primary' : 'secondary'}
                disabled={!tier.priceId}
              >
                {'{{ COPY_PRICING_CTA }}'}
              </Button>
            </form>
          </Card>
        ))}
      </section>
      <p className="rails" aria-label="Métodos de pago">
        Tarjeta · OXXO · SPEI — vía Mercado Pago
      </p>
    </main>
  );
}
