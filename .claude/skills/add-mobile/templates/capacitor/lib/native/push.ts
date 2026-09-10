/**
 * Native push bridge — Capacitor (Mode B).
 *
 * Detect runtime: si Capacitor.isNativePlatform() → Capacitor Push (FCM/APNs).
 * Sino → web-push fallback (Mode A flow).
 *
 * Cita: [docs:capacitor] · [docs:capacitor-push-notifications]
 */
import { Capacitor } from '@capacitor/core';
import { PushNotifications } from '@capacitor/push-notifications';

interface RegisterResult {
  success: boolean;
  token?: string;
  platform?: string;
  error?: string;
}

export async function registerNativePush(
  userId: string
): Promise<RegisterResult> {
  if (!Capacitor.isNativePlatform()) {
    return { success: false, error: 'Not native platform — use web-push flow' };
  }

  // Request permission
  const permission = await PushNotifications.requestPermissions();
  if (permission.receive !== 'granted') {
    return { success: false, error: 'Permission denied' };
  }

  // Register with FCM/APNs
  await PushNotifications.register();

  return new Promise((resolve) => {
    // Capture registration token
    const registrationListener = PushNotifications.addListener(
      'registration',
      async (token) => {
        try {
          await fetch('/api/push/register-native', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              userId,
              token: token.value,
              platform: Capacitor.getPlatform(), // 'ios' | 'android' | 'web'
            }),
          });
          resolve({
            success: true,
            token: token.value,
            platform: Capacitor.getPlatform(),
          });
        } catch (err) {
          resolve({ success: false, error: String(err) });
        }
      }
    );

    PushNotifications.addListener('registrationError', (err) => {
      resolve({ success: false, error: String(err.error) });
    });
  });
}

export function setupForegroundListener(
  handler: (notification: { title?: string; body?: string; data?: any }) => void
) {
  return PushNotifications.addListener(
    'pushNotificationReceived',
    (notification) => {
      handler({
        title: notification.title,
        body: notification.body,
        data: notification.data,
      });
    }
  );
}

export function setupTapListener(handler: (url: string) => void) {
  return PushNotifications.addListener(
    'pushNotificationActionPerformed',
    (action) => {
      const url = action.notification.data?.url || '/';
      handler(url);
    }
  );
}
