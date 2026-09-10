/**
 * Web Push — server side.
 *
 * VAPID setup. NEVER expose VAPID_PRIVATE_KEY al client.
 *
 * Cita: [memory:CONSTRAINTS.md#R13] · [memory:lessons#L-002..3] · [docs:web-push-libs]
 */
import 'server-only';
import webpush from 'web-push';

if (!process.env.VAPID_PRIVATE_KEY) {
  throw new Error('VAPID_PRIVATE_KEY missing');
}
if (!process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY) {
  throw new Error('NEXT_PUBLIC_VAPID_PUBLIC_KEY missing');
}

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT || 'mailto:noreply@example.com',
  process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY.trim(),
  process.env.VAPID_PRIVATE_KEY.trim()
);

export { webpush };

export const ALLOWED_TOPICS = [
  'system',
  'alerts',
  'updates',
  'social',
  'marketing',
] as const;
export type AllowedTopic = typeof ALLOWED_TOPICS[number];

export interface PushPayload {
  title: string;
  body: string;
  url?: string;
  tag?: string;
}

export function isAppleEndpoint(endpoint: string): boolean {
  return endpoint.startsWith('https://web.push.apple.com/');
}
