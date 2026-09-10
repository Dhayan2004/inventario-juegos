/**
 * Mercado Pago — client side.
 *
 * Solo expone la public key (NEXT_PUBLIC_*). El flujo default es Checkout Pro
 * (redirect a `init_point`), así que el cliente no necesita SDK: la public key
 * solo hace falta si el Tech Spec pide Bricks (checkout embebido).
 *
 * Cita: [docs:mercadopago@v2]
 */
'use client';

export function getMercadoPagoPublicKey(): string | null {
  const pk = process.env.NEXT_PUBLIC_MP_PUBLIC_KEY;
  if (!pk) {
    console.error('NEXT_PUBLIC_MP_PUBLIC_KEY missing (solo necesaria para Bricks embebido)');
    return null;
  }
  return pk;
}
