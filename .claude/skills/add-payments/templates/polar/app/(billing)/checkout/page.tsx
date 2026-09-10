/**
 * /checkout — client component (Polar mode)
 *
 * Intermediate page opcional. Por defecto, /pricing redirige directo.
 *
 * Cita: [memory:CONSTRAINTS.md#R10]
 */
'use client';
import { useState } from 'react';
import { Button, Card } from '@/shared/components/ui';

export default function CheckoutPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCheckout() {
    setLoading(true);
    setError(null);

    try {
      const res = await fetch('/api/polar/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
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
        <p>Te redirigimos a Polar (Merchant of Record) para completar el pago.</p>
        <p data-state="info">
          Polar maneja el tax y emite la factura — tu suscripción te llega
          al email tras el pago.
        </p>
        {error && <p role="alert">{error}</p>}
        <Button type="button" variant="primary" onClick={handleCheckout} disabled={loading}>
          {loading ? 'Redirigiendo...' : '{{ COPY_CHECKOUT_CTA }}'}
        </Button>
      </Card>
    </main>
  );
}
