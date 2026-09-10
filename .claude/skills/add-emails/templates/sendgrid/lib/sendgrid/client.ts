/**
 * SendGrid — client side helpers (placeholder).
 *
 * SendGrid NO expone SDK client (todo via server). Esta file existe por shape
 * parity con add-payments + Mode A (Resend). Si necesitás invocar
 * /api/email/send desde un client component, hacelo via fetch.
 *
 * Cita: [docs:sendgrid]
 */
'use client';

export async function triggerSendEmail(input: {
  templateId: string;
  to: string;
  data: Record<string, unknown>;
}): Promise<{ success: boolean; error?: string }> {
  const res = await fetch('/api/email/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  });
  return res.json();
}
