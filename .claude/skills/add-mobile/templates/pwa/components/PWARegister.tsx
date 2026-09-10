/**
 * PWARegister — register service worker + handle updates.
 *
 * CRITICO: usar window.location.origin (iOS rechaza redirects 307).
 * DEBE estar incluido en el layout principal — sin él, push y SW NO funcionan.
 *
 * Cita: [docs:nextjs] · [docs:web-push]
 */
'use client';

import { useEffect } from 'react';

export default function PWARegister() {
  useEffect(() => {
    if (typeof window === 'undefined' || !('serviceWorker' in navigator)) {
      return;
    }

    const swUrl = `${window.location.origin}/sw.js`;

    navigator.serviceWorker
      .register(swUrl, { scope: '/' })
      .then((registration) => {
        // Verificar updates cada 60 minutos
        const updateInterval = setInterval(
          () => registration.update(),
          60 * 60 * 1000
        );

        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (!newWorker) return;

          newWorker.addEventListener('statechange', () => {
            if (
              newWorker.state === 'activated' &&
              navigator.serviceWorker.controller
            ) {
              newWorker.postMessage({ type: 'SKIP_WAITING' });
              setTimeout(() => window.location.reload(), 1000);
            }
          });
        });

        return () => clearInterval(updateInterval);
      })
      .catch((err) => console.error('[PWA] Registration failed:', err));
  }, []);

  return null;
}
