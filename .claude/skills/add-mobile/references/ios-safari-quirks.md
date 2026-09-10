# iOS Safari Quirks — PWA + Push

> **find-docs first.** [docs:web-push] · Apple HIG · webkit.org/blog

## Resumen ejecutivo

iOS Safari es la plataforma más restrictiva para PWA. Las features funcionan **solo cuando la PWA está instalada** (Add to Home Screen) y **solo desde Safari ≥ 16.4** (marzo 2023). Antes de 16.4, push no existía en iOS Safari.

Si tu audiencia es iOS-mayoritaria con push como feature crítica, considerar Capacitor (Mode B) o RN+Expo (Mode C) para garantizar reliability. Si push es nice-to-have, PWA con caveats es viable.

## Quirk 1 — Push web requires PWA-installed-state

```
iOS Safari (en browser, NO instalada):  push NO funciona
iOS PWA (instalada via Add to Home Screen): push funciona desde 16.4+
```

**Implicación UX:**
- Si user llega a la web app en iOS Safari, NO se puede pedir push permission directly.
- Primero hay que mostrar **install prompt** ("Agregá la app a tu pantalla de inicio").
- Después de install, **al abrir la PWA instalada**, ahí sí se puede pedir push permission.
- Esto es 2-step UX que iOS Safari **no ayuda a guiar** — manual instructions necesarias.

**Fix:** InstallPromptUI detecta iOS Safari + NO instalada y muestra instructions:
```
1. Tocá el botón Compartir (cuadrado con flecha)
2. Tocá "Agregar a pantalla de inicio"
3. Confirmá tocando "Agregar"
4. Abre la app desde tu pantalla de inicio
5. Activá notificaciones desde Configuración
```

## Quirk 2 — `BeforeInstallPromptEvent` NO existe

Chrome/Edge dispatchan `beforeinstallprompt` event que permite custom UI con auto-trigger del install dialog. Safari NO lo hace. Solo "Add to Home Screen" manual.

**Fix:** detectar Safari + render manual instructions UI (vs. button con `prompt.prompt()` de Chrome).

```typescript
const isIOSSafari = /iPad|iPhone|iPod/.test(navigator.userAgent) &&
  !(window as any).MSStream &&
  /Safari/.test(navigator.userAgent) &&
  !/CriOS/.test(navigator.userAgent);
```

`!CriOS` excluye Chrome iOS (que se identifica como Safari en algunos checks pero NO es Safari real — es Chrome usando WebKit obligatorio en iOS).

## Quirk 3 — Service Worker NO puede tener fetch handler

Si el SW intercepta `fetch` events, iOS Safari **rompe la PWA install** silenciosamente. La install prompt nunca aparece, o aparece y al instalar la app lanza pantalla blanca.

**Fix:** SW solo debe tener:
- `install` (skipWaiting)
- `activate` (clients.claim + cleanup caches)
- `push` (showNotification)
- `notificationclick`
- `pushsubscriptionchange`
- `message` (SKIP_WAITING handler)

NO `fetch`. Lección crítica del upstream saas-factory (14 commits debug en producción).

## Quirk 4 — `start_url` debe ser cacheable + match scope

Si tu manifest declara `"start_url": "/dashboard"` pero `/dashboard` requiere auth (redirect to /login), iOS rechaza la install. La página debe ser cacheable + return 200 sin auth.

**Fix:** usar `"start_url": "/"` y manejar redirect post-auth en client. O `"start_url": "/welcome"` que funcione sin auth.

## Quirk 5 — Manifest validation strict

Safari valida manifest más estrictamente que Chrome. Errores comunes:
- `display: "minimal-ui"` → Safari ignora (usa `standalone` por default)
- Icons sin `purpose` → Safari acepta pero recorta mal en algunos contextos
- `theme_color` formato hex inválido (`#000` vs `#000000`) → Safari ignora

**Fix:** usar `display: "standalone"`, icons con `purpose: "any maskable"`, hex 6-digit.

## Quirk 6 — Apple endpoints fallan silenciosamente

Cuando enviás push a un Apple endpoint (api.push.apple.com vía Web Push), si la subscripción ya no es válida, Apple **no retorna statusCode coherente**. A veces 410 Gone, a veces undefined, a veces 200 OK con silent drop.

**Fix:** detectar Apple endpoints + ser conservativo con cleanup:
```typescript
function isAppleEndpoint(endpoint: string): boolean {
  return endpoint.startsWith('https://web.push.apple.com/');
}

if (err.statusCode === 410 ||
    (!err.statusCode && isAppleEndpoint(sub.endpoint))) {
  await deleteSubscription(sub.id);
}
```

Sin esto, las subscripciones inválidas se acumulan y bombardean al endpoint inutilemente.

## Quirk 7 — `Notification.permission === 'default'` puede engañar

En iOS Safari (PWA installed state), el permission status puede reportar `'default'` incluso después de denegado. Esto pasa cuando el user dismissed el prompt sin clickear permitir/denegar.

**Fix:** trackear via localStorage flag adicional (independiente de `Notification.permission`):
```typescript
const dismissed = localStorage.getItem('forja:push-prompt-dismissed');
if (dismissed === 'true') return null; // Don't show prompt again
```

## Quirk 8 — Deep link from notification puede romper

Cuando user tap notification, `notificationclick` event handler llama `openWindow(url)`. En iOS PWA, si la app ya está abierta en background, el `openWindow` puede crear una segunda instancia o navigate incorrectly.

**Fix:** usar `clients.matchAll` + `client.focus() + client.navigate()`:
```javascript
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window' }).then((clients) => {
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
```

Esto reusa el window/tab existente si está en scope, falls back a `openWindow` solo si no hay matching client.

## Quirk 9 — Storage quotas más bajos

iOS Safari da menos storage a PWA que Chrome (típicamente 50-200MB vs Chrome's GBs). Si tu PWA cachea mucho, watch out.

**Fix:** usar `navigator.storage.estimate()` para check + cleanup proactivo. NO cachear assets pesados (videos, imágenes hi-res) sin gating.

## Quirk 10 — Splash screen requiere PNG sizes específicos

iOS PWA no usa el manifest `splash` automáticamente. Usa `apple-touch-startup-image` meta tags con exact sizes per device. Es tedious mantener.

**Fix:** considerar herramientas como `pwa-asset-generator` o aceptar default white splash en iOS.

## Citations

- [docs:web-push]
- Apple Human Interface Guidelines — Web Apps
- webkit.org/blog/13878 (iOS 16.4 Web Push announcement)
- [memory:CONSTRAINTS.md#R13]
