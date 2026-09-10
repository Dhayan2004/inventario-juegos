# React Native + Expo Patterns — Reference

> **find-docs first.** [docs:expo] · [docs:expo-notifications] · [docs:eas-cli]

## Cuándo usar RN+Expo

- Codebase ya es React Native (no migrar)
- Greenfield mobile-first (web NO crítico, mobile UX prioritario)
- Equipo experimentado en RN
- App store distribution mandatory + native UX

## Init project (Expo SDK 51+)

```bash
npx create-expo-app forja-mobile --template blank-typescript
cd forja-mobile
npm install expo-notifications expo-device
npm install @supabase/supabase-js
```

## app.json shape

```json
{
  "expo": {
    "name": "App Name",
    "slug": "app-slug",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.yourcompany.appname"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.yourcompany.appname"
    },
    "plugins": [
      [
        "expo-notifications",
        {
          "icon": "./assets/notification-icon.png",
          "color": "#000000",
          "defaultChannel": "default"
        }
      ]
    ]
  }
}
```

## eas.json (EAS Build profiles)

```json
{
  "cli": {
    "version": ">= 5.9.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": { "simulator": true }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

3 profiles canónicos: `development` (dev client + simulator), `preview` (internal distribution para testers), `production` (store builds con auto-increment de version).

## expo-notifications setup

```typescript
// lib/push/notifications.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

// Configure foreground behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotifications(): Promise<string | null> {
  // Push notifications NO funcionan en simulator/emulator
  if (!Device.isDevice) {
    console.log('[Push] Must use physical device');
    return null;
  }

  // Request permission
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') return null;

  // SDK 51+: Expo Push Service token (NO FCM/APNs direct)
  const token = (await Notifications.getExpoPushTokenAsync({
    projectId: 'your-expo-project-id', // de app.json o EAS config
  })).data;

  // Android channel setup (required SDK 51+)
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.DEFAULT,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#FF231F7C',
    });
  }

  return token;
}

// Listen for notifications received while app is foregrounded
export function setupForegroundListener(handler: (notification: Notifications.Notification) => void) {
  return Notifications.addNotificationReceivedListener(handler);
}

// Listen for notification taps (background or quit state)
export function setupTapListener(handler: (response: Notifications.NotificationResponse) => void) {
  return Notifications.addNotificationResponseReceivedListener(handler);
}
```

## Server-side send (Expo Push Service)

```typescript
// Backend (Next.js API route o cualquier server)
const EXPO_PUSH_API = 'https://exp.host/--/api/v2/push/send';

interface ExpoMessage {
  to: string; // Expo push token
  sound?: 'default' | null;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  badge?: number;
  channelId?: string; // Android only
}

export async function sendExpoPush(messages: ExpoMessage[]) {
  // Expo Push Service supports up to 100 messages per request
  const chunks = [];
  for (let i = 0; i < messages.length; i += 100) {
    chunks.push(messages.slice(i, i + 100));
  }

  const results = [];
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
    results.push(await response.json());
  }

  return results;
}
```

NO requiere VAPID (Web Push) ni FCM Server Key. Expo Push Service es intermediario gratuito que el equipo Expo mantiene — recibe el `expoPushToken` y se encarga de enviar via APNs (iOS) o FCM (Android) según el token.

## Receipts (delivery confirmation)

```typescript
const RECEIPTS_API = 'https://exp.host/--/api/v2/push/getReceipts';

// Después de send, get tickets
// Then check receipts para confirmar delivery o detect errors
const receiptResponse = await fetch(RECEIPTS_API, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ ids: ticketIds }),
});

const { data } = await receiptResponse.json();
// data is { [receiptId]: { status: 'ok' | 'error', message?: string, details?: ... } }
// Errors: 'DeviceNotRegistered' → delete token from DB
//         'MessageTooBig' → split payload
//         'MessageRateExceeded' → retry later
//         'MismatchSenderId' → token está asociado a otro Expo project
//         'InvalidCredentials' → APNs/FCM creds wrong
```

## EAS Build pipeline

```bash
# 1. Login
eas login

# 2. Configure (if not done)
eas build:configure

# 3. Build dev (primero, para ver setup OK)
eas build --platform ios --profile development
eas build --platform android --profile development

# 4. Build production
eas build --platform ios --profile production
eas build --platform android --profile production

# 5. Submit a stores
eas submit --platform ios
eas submit --platform android

# 6. Update OTA (sin store review, solo JS bundle changes)
eas update --branch production --message "Bug fix"
```

## Common errors

| Error | Causa | Fix |
|-------|-------|-----|
| `getExpoPushTokenAsync` fails con "Project ID required" | SDK 51+ requiere projectId explícito | Add `projectId` desde EAS config (`app.json` extra.eas.projectId) |
| Android push: nada llega | NO Notification Channel set | `setNotificationChannelAsync('default', ...)` antes de send |
| iOS push: nada llega | Device es simulator (no soporta push) | Test en physical device |
| EAS Build fails: "credentials not found" | Apple/Google certs no configurados | Run `eas credentials` para configure |
| OTA update no toma efecto | App version differs (binary changes) | Si cambió código nativo, NO OTA — necesita store submit |
| `DeviceNotRegistered` en receipts | Token expirado / app desinstalada | Delete token de DB |

## Citations

- [docs:expo] · [docs:expo-notifications] · [docs:eas-cli]
- [memory:CONSTRAINTS.md#R13]
