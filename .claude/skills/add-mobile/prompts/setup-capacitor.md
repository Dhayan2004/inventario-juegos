# Setup Capacitor — Mode B (override por native shell, web-first)

## Antes de empezar (R13)

```
1. resolve-library-id("capacitor") → query-docs
   query: "@capacitor/core init config Next.js export static
           ios android platform add"
2. resolve-library-id("capacitor-push-notifications") → query-docs
   query: "@capacitor/push-notifications register addListener
           pushNotificationReceived FCM APNs setup"
3. resolve-library-id("nextjs") → query-docs
   query: "App Router static export output: 'export' Capacitor compatible"
```

**Razón:** Capacitor 6 cambió plugin shape vs 5. `@capacitor/push-notifications` v7 introduces breaking changes en `requestPermissions`. Next.js static export semantics cambiaron en App Router 16. Sin find-docs runtime falla.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json | R-005 |
| Auth | add-login output | required |
| PWA setup | Mode A completado | required (Capacitor envuelve PWA existente, NO regenera) |
| App ID | Tech Spec o user input (`com.yourcompany.appname`) | required (reverse-DNS format) |
| App Name | brand.json.brand.product | required |
| Apple Developer Account | $99/año | required para distribución iOS |
| Google Play Console Account | $25 one-time | required para distribución Android |

## Pre-requisito: Mode A completado

**Capacitor envuelve la PWA existente.** Si Mode A no corrió, primero correr setup-pwa.md.

```
PREFLIGHT Mode B:
1. ¿Existe public/manifest.json? Si no → halt: "Corré /add-mobile Mode A primero. Capacitor reuses la PWA existente."
2. ¿Existe public/sw.js? Si no → halt: "Idem."
3. ¿Existe src/app/api/push/{subscribe,unsubscribe,send}/route.ts? Si no → halt: "Idem."
```

## Pasos

### 1. Install Capacitor

```bash
npm install @capacitor/core @capacitor/cli
npm install @capacitor/ios @capacitor/android
npm install @capacitor/push-notifications
npx cap init <APP_NAME> <APP_ID> --web-dir=out
```

`--web-dir=out` asume Next.js `output: 'export'` config. Si proyecto usa standard build, ajustar.

### 2. Substitute templates → 

| Template | Target | Substitutions |
|----------|--------|---------------|
| `capacitor.config.ts` | `capacitor.config.ts` | `{{ APP_ID }}`, `{{ APP_NAME }}`, `{{ THEME_COLOR }}` ← brand.json |
| `next.config.mjs.patch` | `next.config.mjs` (manual merge) | adds `output: 'export'` + `images.unoptimized: true` |
| `lib/native/push.ts` | `src/lib/native/push.ts` | bridge entre web-push (PWA) y Capacitor Push Notifications (native) |
| `components/CapacitorPWABridge.tsx` | `src/components/CapacitorPWABridge.tsx` | detect Capacitor.isNativePlatform() vs web, route subscribe call |
| `app/(mobile)/install/page.tsx.patch` | manual merge | hide install prompt si Capacitor.isNativePlatform() (ya instalada) |
| `package.json.scripts` | manual merge | `"cap:ios": "cap sync ios && cap open ios"`, `"cap:android": "cap sync android && cap open android"`, `"cap:build": "next build && next export && cap sync"` |

### 3. Add iOS + Android platforms

```bash
npx cap add ios
npx cap add android
```

Esto crea `ios/` y `android/` directories en repo root con native projects. Estos NO se commitean por default a  — son artifacts. Documentar en `.gitignore` o commitear según preferencia del usuario.

### 4. Configure native push

#### iOS (APNs):
1. Apple Developer account → enable Push Notifications capability
2. Generate APNs key (.p8) → upload to Firebase project (FCM)
3. `ios/App/App.entitlements` → agregar `aps-environment: production`
4. `ios/App/AppDelegate.swift` → ya viene con Capacitor push ready

#### Android (FCM):
1. Firebase project setup → download `google-services.json`
2. Place en `android/app/google-services.json`
3. `android/app/build.gradle` → ya viene con FCM dep via Capacitor

### 5. Bridge web-push ↔ native push

`lib/native/push.ts` detecta runtime:

```typescript
import { Capacitor } from '@capacitor/core';
import { PushNotifications } from '@capacitor/push-notifications';

export async function subscribePush(userId: string) {
  if (Capacitor.isNativePlatform()) {
    // Native: usa Capacitor Push Notifications
    const permission = await PushNotifications.requestPermissions();
    if (permission.receive !== 'granted') return null;
    await PushNotifications.register();
    PushNotifications.addListener('registration', async (token) => {
      // Send token.value to backend (FCM/APNs token, no Web Push subscription)
      await fetch('/api/push/subscribe-native', {
        method: 'POST',
        body: JSON.stringify({ userId, token: token.value, platform: Capacitor.getPlatform() }),
      });
    });
  } else {
    // Web: usa web-push (PWA Mode A flow)
    return subscribePushWeb(userId);
  }
}
```

NO se reescribe el flow PWA — se complementa con el flow native cuando running en Capacitor.

### 6. Update .env.local

```bash
cat >> .env.local <<'EOF'

# Capacitor native (added by add-mobile Mode B)
# FCM Server Key (server-only)
FCM_SERVER_KEY=REPLACE_WITH_FCM_SERVER_KEY

# APNs key (.p8 file path or contents)
APNS_KEY_ID=REPLACE
APNS_TEAM_ID=REPLACE
APNS_KEY_PATH=./keys/AuthKey_XXXX.p8

# Capacitor app metadata
CAPACITOR_APP_ID=com.yourcompany.appname
EOF
```

### 7. Build + sync

```bash
# Build web
next build && next export

# Sync to native
npx cap sync

# Open in IDE
npx cap open ios     # Xcode
npx cap open android # Android Studio
```

### 8. Verificación pre-handoff

Mismos checks que Mode A más:

```bash
# Capacitor config existe + valid
test -f capacitor.config.ts
grep -q "appId:" capacitor.config.ts

# Native push bridge presente
test -f src/lib/native/push.ts
grep -q "Capacitor.isNativePlatform" src/lib/native/push.ts

# FCM_SERVER_KEY NO en client
! grep -r "FCM_SERVER_KEY" src/components/

# Bridge detecta runtime correctamente
grep -q "Capacitor.getPlatform()" src/lib/native/push.ts
```

### 9. Output handoff

Imprimir bloque `## add-mobile handoff` con Mode CAPACITOR + advisory de Apple Developer ($99/año) + Google Play ($25) requirements + manual native config steps (entitlements, google-services.json) + post-deploy review cycles.

## Diferencias relevantes vs Mode A

| Aspecto | PWA (Mode A) | Capacitor (Mode B) |
|---------|--------------|---------------------|
| Source of truth | web Next.js | web Next.js + Capacitor wrapper |
| Push runtime | Web Push API (VAPID) | Capacitor Push (FCM/APNs) cuando native, Web Push cuando web |
| Build | next build → vercel deploy | next build + cap sync → Xcode/Android Studio → store submit |
| Update users | instant | rebuild + store review (días) |
| Native features | Web APIs only | Capacitor plugins disponibles |
| Setup | 10 min | 2-4h primer-time + native account setup |

## Citations

- [docs:capacitor] · [docs:capacitor-push-notifications] · [docs:nextjs] (R13)
- [memory:references#R-005] · [memory:CONSTRAINTS.md#R10..14]
- [memory:lessons#L-001..3]
- [memory:decisions#D-010..D-012]
