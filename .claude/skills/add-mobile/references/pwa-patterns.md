# PWA Patterns — Reference

> **find-docs first.** [docs:web-push] · [docs:web-push-libs] · [docs:nextjs]

## Manifest essentials

```json
{
  "name": "App Name",
  "short_name": "AppShort",
  "description": "Short description",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "lang": "es",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ]
}
```

`purpose: "any maskable"` permite que iconos respeten safe area en Android (recortados a círculo en algunos launchers). Sin maskable, los iconos se cortan mal.

## Layout integration

```tsx
// app/layout.tsx
export const metadata = {
  manifest: '/manifest.json',
  themeColor: '<TOKEN_PRIMARY>',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: '<APP_NAME>',
  },
};
```

Apple-specific tags: `apple-mobile-web-app-capable` (legacy alias mantenido), `apple-mobile-web-app-status-bar-style`, `apple-touch-icon`. Next.js metadata API genera todos automáticamente desde `appleWebApp` config.

## Service Worker patterns

### Lifecycle
```javascript
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
```

`skipWaiting` = nueva versión activa inmediatamente sin esperar tabs cerrados. `clients.claim` = controla todos los clients abiertos sin reload.

### Push handler
```javascript
self.addEventListener('push', (event) => {
  if (!event.data) return;
  const payload = event.data.json();
  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: '/icons/icon-192.png',
      badge: '/icons/icon-72.png',
      data: { url: payload.url || '/' },
    })
  );
});
```

### Click handler
```javascript
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window' }).then((clients) => {
      for (const client of clients) {
        if (client.url.includes(url) && 'focus' in client) return client.focus();
      }
      return self.clients.openWindow(url);
    })
  );
});
```

### Subscription change (auto-resuscribir)
```javascript
self.addEventListener('pushsubscriptionchange', (event) => {
  event.waitUntil(
    self.registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: event.oldSubscription?.options?.applicationServerKey,
    }).then((newSub) =>
      fetch('/api/push/subscribe', {
        method: 'POST',
        body: JSON.stringify({ subscription: newSub.toJSON() }),
      })
    )
  );
});
```

## VAPID keys

```bash
npx web-push generate-vapid-keys --json
```

Output:
```json
{ "publicKey": "BDx...", "privateKey": "abc..." }
```

- `publicKey` → `NEXT_PUBLIC_VAPID_PUBLIC_KEY` (client OK, va al SW)
- `privateKey` → `VAPID_PRIVATE_KEY` (server only, NEVER expose)
- `VAPID_SUBJECT` → `mailto:noreply@yourdomain.com` (contact for push providers)

## VAPID public key conversion (client → Uint8Array)

```typescript
const vapidKey = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY!;
const padding = '='.repeat((4 - (vapidKey.length % 4)) % 4);
const base64 = (vapidKey + padding).replace(/-/g, '+').replace(/_/g, '/');
const rawData = atob(base64);
const applicationServerKey = new Uint8Array(rawData.length);
for (let i = 0; i < rawData.length; i++) {
  applicationServerKey[i] = rawData.charCodeAt(i);
}
```

Esto es crítico — `pushManager.subscribe` requiere `Uint8Array`, no string base64. Sin la conversión, runtime rompe silenciosamente en algunos browsers.

## web-push npm send pattern

```typescript
import webpush from 'web-push';

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT!,
  process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!
);

try {
  await webpush.sendNotification(
    { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
    JSON.stringify({ title, body, url })
  );
} catch (err: any) {
  // Status codes:
  // - 410 Gone: subscription expired/invalidated → delete from DB
  // - 411 Length Required: payload too large → split
  // - 429 Too Many Requests: rate limit → retry later (NO delete)
  // - undefined: Apple silent failure → conservative delete
  if (err.statusCode === 410 || (!err.statusCode && isAppleEndpoint(sub.endpoint))) {
    await deleteSubscription(sub.id);
  }
}
```

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| iOS Safari: PWA install prompt no aparece | Manifest invalid, start_url not cacheable, OR Safari < 16.4 | Validate manifest, ensure start_url returns 200, check Safari version |
| iOS push: notifications nunca llegan | PWA NO instalada (push web requires installed-state en iOS) | Show install prompt + only request push permission post-install |
| Chrome push: subscription expira post-update browser | `pushsubscriptionchange` no implementado | Add handler que resuscribe y notifica al backend |
| Android: app icon muestra default Lighthouse | Manifest icons missing `purpose: "any maskable"` | Add maskable purpose |
| Push: 410 Gone | Subscription invalidada | Delete from push_subscriptions |
| Push: 413 Payload Too Large | Payload >4KB | Reduce body or send id + URL para fetch on click |

## Citations

- [docs:web-push] · [docs:web-push-libs] · [docs:nextjs]
- [memory:CONSTRAINTS.md#R13]
- [memory:lessons#L-001..3]
