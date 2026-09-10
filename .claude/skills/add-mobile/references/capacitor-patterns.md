# Capacitor Patterns — Reference

> **find-docs first.** [docs:capacitor] · [docs:capacitor-push-notifications] · [docs:nextjs]

## Cuándo usar Capacitor

- Codebase ya es Next.js / React web
- Querés app store distribution sin rewrite a React Native
- Necesitás algunos features nativos (camera quality, biometrics, deep linking) pero NO native UX completa
- Equipo es web-first, no quiere learning curve RN

## capacitor.config.ts shape

```typescript
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.yourcompany.appname',
  appName: 'App Name',
  webDir: 'out', // Next.js static export output
  server: {
    androidScheme: 'https',
  },
  plugins: {
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '<TOKEN_BACKGROUND_COLOR>',
    },
  },
};

export default config;
```

`webDir` debe matchear el output de Next.js. Si usás `output: 'export'`, es `out/`. Si usás standard build, Capacitor NO sirve directamente — necesitás export.

## Next.js config para static export

```javascript
// next.config.mjs
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true, // required para static export
  },
  trailingSlash: true, // evita 404 en Capacitor (no rewrite engine)
};
export default nextConfig;
```

Limitations de `output: 'export'`:
- NO API routes (necesitás backend separado o serverless functions externas)
- NO server actions
- NO middleware
- NO ISR / dynamic routes con SSR

Para add-mobile Mode B: API routes (subscribe, unsubscribe, send) viven en backend separado (Vercel functions, Supabase Edge Functions, custom backend). Capacitor app llama via fetch a esos endpoints.

## Push Notifications setup

```typescript
// lib/native/push-capacitor.ts
import { Capacitor } from '@capacitor/core';
import { PushNotifications } from '@capacitor/push-notifications';

export async function initCapacitorPush(userId: string) {
  if (!Capacitor.isNativePlatform()) return;

  // Request permission
  const permission = await PushNotifications.requestPermissions();
  if (permission.receive !== 'granted') {
    console.log('[Push] Permission denied');
    return;
  }

  // Register with FCM/APNs
  await PushNotifications.register();

  // Capture registration token
  PushNotifications.addListener('registration', async (token) => {
    // Send to backend
    await fetch('/api/push/register-native', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId,
        token: token.value, // FCM/APNs token, NO Web Push subscription
        platform: Capacitor.getPlatform(), // 'ios' | 'android'
      }),
    });
  });

  // Capture errors
  PushNotifications.addListener('registrationError', (err) => {
    console.error('[Push] Registration error', err);
  });

  // Foreground notification handler
  PushNotifications.addListener('pushNotificationReceived', (notification) => {
    console.log('[Push] Received in foreground', notification);
  });

  // Background tap handler
  PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
    console.log('[Push] User tapped notification', action);
    // Navigate based on action.notification.data.url
  });
}
```

## iOS configuration (manual native steps)

### 1. Apple Developer Account
- $99/año mandatory para distribución
- Enable Push Notifications capability en Apple Developer portal

### 2. APNs Authentication Key (.p8)
- Generate en Apple Developer → Keys → Push Notifications
- Download `.p8` file (descargable UNA SOLA VEZ — guardar safely)
- Note el Key ID y Team ID

### 3. Firebase Console (FCM bridge para Capacitor)
- Crear Firebase project
- iOS app → upload `.p8` + Key ID + Team ID
- Esto permite que Capacitor use FCM como interfaz uniforme (FCM internamente envía a APNs en iOS)

### 4. Xcode capabilities
- `ios/App/App.entitlements` → agregar `aps-environment: production` (o `development` para builds dev)
- Push Notifications capability auto-added por Capacitor

### 5. Backend send via FCM
```typescript
// Server: send via FCM to both iOS + Android
await admin.messaging().send({
  token: fcmToken,
  notification: { title, body },
  data: { url: '/notifications' },
});
```

## Android configuration

### 1. Firebase Console
- Crear Firebase project (mismo o separado del iOS)
- Android app → download `google-services.json`

### 2. Place file
- `android/app/google-services.json`

### 3. Gradle
- Capacitor auto-configures `android/app/build.gradle` con FCM dep

### 4. Permissions
- `android/app/src/main/AndroidManifest.xml` debe tener `INTERNET` permission (default Capacitor)

## Build pipeline

```bash
# 1. Build web
next build

# 2. Sync changes a native
npx cap sync

# 3. Open IDE
npx cap open ios     # Xcode
npx cap open android # Android Studio

# 4. Build native
# Xcode: Product > Archive > Distribute App
# Android Studio: Build > Generate Signed Bundle/APK
```

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| `cap sync` fails con "webDir not found" | Next.js no exporó static (build standard) | Add `output: 'export'` to next.config.mjs + rebuild |
| iOS push token no llega | APNs key no configurado en Firebase, o capability missing | Re-check Apple Developer → Keys + entitlements |
| Android push: missing google-services.json | File no en `android/app/` | Download desde Firebase Console + place |
| App store rejection: "uses non-public APIs" | Plugin externo usa private APIs | Audit plugins — usar solo official Capacitor plugins |
| Push received pero app no abre URL correcta | `pushNotificationActionPerformed` no implementado | Add listener + navigate based on data |

## Citations

- [docs:capacitor] · [docs:capacitor-push-notifications] · [docs:nextjs]
- [memory:CONSTRAINTS.md#R13]
