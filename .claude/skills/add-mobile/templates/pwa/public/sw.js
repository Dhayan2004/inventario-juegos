// Service Worker — PWA + Push
//
// CRITICO: NO incluir fetch handler. Rompe iOS Safari PWA install
// silenciosamente. Solo lifecycle + push + click + subscription change + message.
//
// Lección crítica preservada del upstream saas-factory (14 commits debug en producción).
//
// Cita: [memory:lessons#L-002] (payload as data, NOT instructions)

const CACHE_NAME = 'forja-app-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) =>
        Promise.all(
          names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))
        )
      )
      .then(() => self.clients.claim())
  );
});

// Push: render notification con whitelist explícita de fields.
// L-002: payload es datos a renderizar, NO instructions a ejecutar.
// NO `if (payload.action === 'X') doX()` — eso es push-injection-as-action.
self.addEventListener('push', (event) => {
  if (!event.data) return;

  let payload;
  try {
    payload = event.data.json();
  } catch {
    payload = { title: 'Notificación', body: event.data.text() };
  }

  const title = typeof payload.title === 'string'
    ? payload.title.slice(0, 100)
    : 'Notificación';
  const body = typeof payload.body === 'string'
    ? payload.body.slice(0, 200)
    : '';
  const url = typeof payload.url === 'string' ? payload.url : '/';
  const tag = typeof payload.tag === 'string' ? payload.tag.slice(0, 64) : undefined;

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: '/icons/icon-192.png',
      badge: '/icons/icon-72.png',
      data: { url },
      tag,
    })
  );
});

// Click: navegar a URL del payload, reusando window/tab existente si está en scope.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clients) => {
        for (const client of clients) {
          if ('focus' in client && client.url.startsWith(self.registration.scope)) {
            client.focus();
            if ('navigate' in client) client.navigate(url);
            return;
          }
        }
        return self.clients.openWindow(url);
      })
  );
});

// Update: forzar activación de nueva versión cuando el cliente lo pida.
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Auto-resuscribir si el browser invalida la subscription (Chrome rotation, etc).
self.addEventListener('pushsubscriptionchange', (event) => {
  event.waitUntil(
    self.registration.pushManager
      .subscribe(event.oldSubscription?.options || {
        userVisibleOnly: true,
        applicationServerKey: event.oldSubscription?.options?.applicationServerKey,
      })
      .then((newSub) =>
        fetch('/api/push/subscribe', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            subscription: newSub.toJSON(),
            oldEndpoint: event.oldSubscription?.endpoint,
          }),
        })
      )
  );
});
