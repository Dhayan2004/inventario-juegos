/**
 * Web Push — client helpers.
 *
 * VAPID public key conversion (base64url string → Uint8Array) — crítico
 * para `pushManager.subscribe`, que NO acepta string base64.
 *
 * Cita: [docs:web-push]
 */
'use client';

export function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export async function triggerSendNotification(input: {
  templateId: string;
  data: Record<string, unknown>;
}): Promise<{ success: boolean; error?: string }> {
  const res = await fetch('/api/push/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(input),
  });
  return res.json();
}
