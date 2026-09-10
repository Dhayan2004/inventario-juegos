/**
 * Server-side push send via Expo Push Service — Mode C.
 *
 * Vive en backend (Next.js API route o cualquier server). Recibe Expo
 * push tokens + envía via https://exp.host/--/api/v2/push/send.
 *
 * Cita: [docs:expo-notifications]
 */

const EXPO_PUSH_API = 'https://exp.host/--/api/v2/push/send';
const EXPO_RECEIPTS_API = 'https://exp.host/--/api/v2/push/getReceipts';

export interface ExpoMessage {
  to: string;
  sound?: 'default' | null;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  badge?: number;
  channelId?: string;
}

export async function sendExpoPush(messages: ExpoMessage[]) {
  // Expo Push Service supports up to 100 messages per request
  const chunks: ExpoMessage[][] = [];
  for (let i = 0; i < messages.length; i += 100) {
    chunks.push(messages.slice(i, i + 100));
  }

  const tickets = [];
  for (const chunk of chunks) {
    const response = await fetch(EXPO_PUSH_API, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Accept-encoding': 'gzip, deflate',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(chunk),
    });
    const json = await response.json();
    tickets.push(json);
  }

  return tickets;
}

export async function getExpoReceipts(receiptIds: string[]) {
  const response = await fetch(EXPO_RECEIPTS_API, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ ids: receiptIds }),
  });
  return response.json();
  // Response: { data: { [receiptId]: { status: 'ok' | 'error', ... } } }
  // Errors:
  // - DeviceNotRegistered → delete token
  // - MessageTooBig → split payload
  // - MessageRateExceeded → retry later
  // - InvalidCredentials → APNs/FCM creds wrong
}
