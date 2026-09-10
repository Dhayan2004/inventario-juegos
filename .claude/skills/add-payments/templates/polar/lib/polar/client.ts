/**
 * Polar — client side helpers.
 *
 * Polar checkout es full URL redirect (no embed JS SDK como Stripe Elements).
 * Esta file existe solo para shape parity con Stripe — no necesita SDK client.
 *
 * Cita: [docs:polar]
 */
'use client';

/**
 * Redirige al checkout URL devuelto por /api/polar/checkout.
 * Polar no requiere loadStripe-style init — el URL es self-contained.
 */
export function redirectToCheckout(url: string): void {
  window.location.href = url;
}
