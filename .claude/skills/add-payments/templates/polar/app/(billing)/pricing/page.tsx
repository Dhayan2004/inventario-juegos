/**
 * /pricing — server component (Polar mode)
 *
 * Polar default es single-tier. Si el Tech Spec declara multi-tier,
 * extender ALLOWED_PRODUCT_IDS y agregar tier configs adicionales.
 *
 * R10 Brand DNA gate enforced.
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
import { Card, Button, Badge } from '@/shared/components/ui';
import type { PricingTier } from '@/types/billing';

const TIERS: PricingTier[] = [
  {
    id: 'pro',
    name: 'Pro',
    label: 'Acceso completo',
    featured: true,
    amountCents: 1900,
    currency: 'usd',
    interval: 'month',
    features: [
      'Todas las features',
      'Soporte por email',
      'Tax incluido (Polar MoR)',
    ],
    priceId: process.env.POLAR_PRODUCT_ID ?? '',
  },
];

function formatPrice(cents: number, currency: string, interval: string): string {
  if (cents === 0) return 'Gratis';
  const amount = (cents / 100).toFixed(0);
  const symbol = currency === 'usd' ? 'US$' : currency.toUpperCase() + ' ';
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
              <p className="price">
                {formatPrice(tier.amountCents, tier.currency, tier.interval)}
              </p>
            </header>
            <ul aria-label="Incluido">
              {tier.features.map((f, i) => (
                <li key={i}>{f}</li>
              ))}
            </ul>
            <form action="/api/polar/checkout" method="POST">
              <input type="hidden" name="productId" value={tier.priceId} />
              <Button type="submit" variant="primary" disabled={!tier.priceId}>
                {'{{ COPY_PRICING_CTA }}'}
              </Button>
            </form>
          </Card>
        ))}
      </section>
    </main>
  );
}
