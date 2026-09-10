/**
 * /checkout — client component (Mode C, Mercado Pago)
 *
 * Intermediate page si querés agregar UI custom antes del Checkout Pro de MP.
 * Por defecto, /pricing redirige directo a MP (init_point). Esta page es
 * opcional — solo si Tech Spec pide checkout intermedio (ej: elegir OXXO vs
 * tarjeta, aceptar ToS, capturar RFC para CFDI).
 *
 * R10 Brand DNA gate enforced.
 * Cita: [memory:CONSTRAINTS.md#R10]
 */
'use client';
import { useSearchParams } from 'next/navigation';
import { useState } from 'react';
import { Button, Card } from '@/shared/components/ui';

export default function CheckoutPage() {
  const params = useSearchParams();
  const planId = params.get('planId');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCheckout() {
    if (!planId) {
      setError('Plan no seleccionado.');
      return;
    }
    setLoading(true);
    setError(null);

    try {
      const res = await fetch('/api/mercadopago/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ planId }),
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
        <p>Te redirigimos a Mercado Pago para completar el pago de forma segura (tarjeta, OXXO o SPEI).</p>
        {error && (
          <p role="alert" data-state="error">
            {error}
          </p>
        )}
        <Button
          type="button"
          variant="primary"
          onClick={handleCheckout}
          disabled={loading || !planId}
        >
          {loading ? 'Redirigiendo...' : '{{ COPY_CHECKOUT_CTA }}'}
        </Button>
      </Card>
    </main>
  );
}
