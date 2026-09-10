/**
 * /pricing — server component
 *
 * R10 Brand DNA gate enforced.
 * Tokens leídos de brand/brand.json (vía CSS vars en brand.css).
 * CTAs derivan de brand/voice.json#cta_examples (gate 7 con fallback
 * conservador si genéricos sin orientación payment).
 * Componentes de @/shared/components/ui (impeccable output).
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
import { Card, Button, Badge } from '@/shared/components/ui';
import type { PricingTier } from '@/types/billing';

const TIERS: PricingTier[] = [
  {
    id: 'hobby',
    name: 'Hobby',
    label: 'Empezá gratis',
    amountCents: 0,
    currency: 'usd',
    interval: 'month',
    features: ['Hasta 100 usuarios', 'Soporte por email', 'Updates'],
    priceId: process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_HOBBY ?? '',
  },
  {
    id: 'pro',
    name: 'Pro',
    label: 'Más popular',
    featured: true,
    amountCents: 2900,
    currency: 'usd',
    interval: 'month',
    features: ['Usuarios ilimitados', 'Soporte prioritario', 'API access'],
    priceId: process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_PRO ?? '',
  },
  {
    id: 'team',
    name: 'Team',
    label: 'Para equipos',
    amountCents: 9900,
    currency: 'usd',
    interval: 'month',
    features: ['Todo de Pro', 'SSO', 'Audit log', 'Soporte dedicado'],
    priceId: process.env.NEXT_PUBLIC_STRIPE_PRICE_ID_TEAM ?? '',
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
              <p className="price" aria-label={`Precio: ${formatPrice(tier.amountCents, tier.currency, tier.interval)}`}>
                {formatPrice(tier.amountCents, tier.currency, tier.interval)}
              </p>
            </header>
            <ul aria-label="Incluido">
              {tier.features.map((f, i) => (
                <li key={i}>{f}</li>
              ))}
            </ul>
            <form action={`/api/stripe/checkout`} method="POST">
              <input type="hidden" name="priceId" value={tier.priceId} />
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
    </main>
  );
}
