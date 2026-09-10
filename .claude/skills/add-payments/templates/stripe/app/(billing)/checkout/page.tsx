/**
 * /checkout — client component
 *
 * Intermediate page si querés agregar UI custom antes del Stripe Hosted Checkout.
 * Por defecto, /pricing redirige directo a Stripe. Esta page es opcional —
 * solo si Tech Spec pide checkout intermedio (ej: agregar coupon, ToS).
 *
 * R10 Brand DNA gate enforced.
 * Cita: [memory:CONSTRAINTS.md#R10]
 */
'use client';
import { useSearchParams } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Button, Card, Input } from '@/shared/components/ui';

export default function CheckoutPage() {
  const params = useSearchParams();
  const priceId = params.get('priceId');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCheckout() {
    if (!priceId) {
      setError('Plan no seleccionado.');
      return;
    }
    setLoading(true);
    setError(null);

    try {
      const res = await fetch('/api/stripe/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ priceId }),
      });
      const data = await res.json();
      if (!res.ok || !data.url) {
        throw new Error(data.error ?? 'Error creando checkout');
      }
      window.location.href = data.url;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido.');
      setLoading(false);
    }
  }

  return (
    <main aria-labelledby="checkout-title">
      <Card>
        <h1 id="checkout-title">{'{{ COPY_CHECKOUT_TITLE }}'}</h1>
        <p>Te redirigimos a Stripe para completar el pago de forma segura.</p>
        {error && (
          <p role="alert" data-state="error">
            {error}
          </p>
        )}
        <Button
          type="button"
          variant="primary"
          onClick={handleCheckout}
          disabled={loading || !priceId}
        >
          {loading ? 'Redirigiendo...' : '{{ COPY_CHECKOUT_CTA }}'}
        </Button>
      </Card>
    </main>
  );
}
