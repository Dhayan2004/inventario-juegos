/**
 * CapacitorPWABridge — runtime detection + native push setup.
 *
 * Reemplaza PushPermissionPrompt en runtime nativo. Web continúa
 * usando flow PWA (Mode A) sin cambios.
 *
 * Cita: [docs:capacitor] · [memory:CONSTRAINTS.md#R10]
 */
'use client';

import { useEffect } from 'react';
import { Capacitor } from '@capacitor/core';
import {
  registerNativePush,
  setupForegroundListener,
  setupTapListener,
} from '@/lib/native/push';

interface CapacitorPWABridgeProps {
  userId?: string;
}

export function CapacitorPWABridge({ userId }: CapacitorPWABridgeProps) {
  useEffect(() => {
    if (!Capacitor.isNativePlatform() || !userId) return;

    let foregroundListener: any;
    let tapListener: any;

    (async () => {
      const result = await registerNativePush(userId);
      if (!result.success) {
        console.error('[Capacitor Push] Failed:', result.error);
        return;
      }

      foregroundListener = await setupForegroundListener((notification) => {
        // Notification received while app is open. Handler depends on UX:
        // some apps show in-app banner, others just rely on system notification.
        console.log('[Capacitor Push] Foreground:', notification);
      });

      tapListener = await setupTapListener((url) => {
        // User tapped notification → navigate
        if (typeof window !== 'undefined') {
          window.location.href = url;
        }
      });
    })();

    return () => {
      foregroundListener?.remove?.();
      tapListener?.remove?.();
    };
  }, [userId]);

  return null;
}
