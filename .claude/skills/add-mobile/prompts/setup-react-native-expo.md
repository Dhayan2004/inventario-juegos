# Setup React Native + Expo — Mode C (override por native shell, mobile-first)

## Antes de empezar (R13)

```
1. resolve-library-id("expo") → query-docs
   query: "Expo SDK 51 init create-expo-app router managed workflow"
2. resolve-library-id("expo-notifications") → query-docs
   query: "expo-notifications setNotificationHandler scheduleNotification
           getExpoPushTokenAsync setBadgeCountAsync"
3. resolve-library-id("eas-cli") → query-docs
   query: "EAS Build EAS Submit eas.json profiles managed credentials"
```

**Razón:** Expo SDK 51 deprecated push tokens legacy (FCM/APNs direct) — ahora todos van via Expo Push Service. expo-notifications API cambió `requestPermissionsAsync` shape vs SDK 49. EAS workflow es el canónico desde 2024 (Classic Build deprecated).

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json | R-005 |
| Auth | add-login output | required (push tokens FK user_id) |
| App Name | brand.json.brand.product | required |
| App slug | derivado de brand.json.brand.product | required |
| Apple Developer Account | $99/año | required para iOS distribution |
| Google Play Console | $25 | required para Android distribution |
| Expo Account | gratis (paid for managed credentials) | required para EAS |

## Cuándo usar Mode C vs Mode B

| Scenario | Decision |
|----------|----------|
| Codebase ya es React Native | **Mode C** (Expo) — natural fit |
| Codebase Next.js + quiere store distribution | **Mode B** (Capacitor) — wraps web, no rewrite |
| Greenfield + native UX prioritario | **Mode C** — RN+Expo es stack maduro mobile-first |
| Greenfield + web también necesario | **Mode B** — Capacitor permite reusar web codebase |
| Equipo experimentado en RN | **Mode C** |
| Equipo web React | **Mode B** |

Si Mode C aplica, **NO** se reusan templates/pwa/. RN+Expo es codebase paralelo standalone.

## Pasos

### 1. Init Expo project (codebase paralelo)

```bash
# Asume codebase web vive en . Mobile codebase vive en forja-mobile/ o
# similar — paralelo, no nested.
npx create-expo-app forja-mobile --template blank-typescript
cd forja-mobile
npm install expo-notifications expo-device
npm install @supabase/supabase-js  # o equivalente Insforge SDK
```

### 2. Substitute templates → forja-mobile/

| Template | Target | Substitutions |
|----------|--------|---------------|
| `app.json` | `forja-mobile/app.json` | `{{ APP_NAME }}`, `{{ APP_SLUG }}`, `{{ APP_ID }}` ← brand.json + Tech Spec |
| `eas.json` | `forja-mobile/eas.json` | EAS Build profiles (development, preview, production) |
| `lib/push/notifications.ts` | `forja-mobile/lib/push/notifications.ts` | expo-notifications setup + getExpoPushTokenAsync |
| `lib/push/server-send.ts` | `forja-mobile/lib/push/server-send.ts` | (server-side helper para enviar via Expo Push Service) |
| `App.tsx` o `app/_layout.tsx` | mismo path | inicializar push handler global |
| `screens/PushPermissionPrompt.tsx` | mismo path | UX permission flow (NO on app launch — post-action) |
| `package.json.scripts` | manual merge | `"start": "expo start"`, `"build:ios": "eas build --platform ios --profile production"`, `"submit:ios": "eas submit --platform ios"` |

### 3. Configure expo-notifications

```typescript
// forja-mobile/lib/push/notifications.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotifications(): Promise<string | null> {
  if (!Device.isDevice) {
    // Push notifications NO funcionan en simulator/emulator
    return null;
  }

  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') return null;

  // SDK 51+: Expo Push Service token (NO FCM/APNs direct)
  const token = (await Notifications.getExpoPushTokenAsync()).data;

  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.DEFAULT,
    });
  }

  return token;
}
```

### 4. Server-side send via Expo Push Service

```typescript
// forja-mobile/lib/push/server-send.ts (también puede vivir en backend Next.js)
const EXPO_PUSH_API = 'https://exp.host/--/api/v2/push/send';

export async function sendPushExpo(tokens: string[], notification: {
  title: string;
  body: string;
  data?: Record<string, unknown>;
}) {
  const messages = tokens.map((token) => ({
    to: token,
    sound: 'default',
    title: notification.title,
    body: notification.body,
    data: notification.data ?? {},
  }));

  const response = await fetch(EXPO_PUSH_API, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Accept-encoding': 'gzip, deflate',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(messages),
  });

  return response.json();
}
```

NO requiere VAPID (Web Push) ni FCM Server Key (Capacitor). Expo Push Service es intermediario que el equipo Expo mantiene gratis.

### 5. EAS Build setup

```bash
# Login
eas login

# Configure (esto crea eas.json si no existe)
eas build:configure

# Build de development
eas build --platform ios --profile development
eas build --platform android --profile development

# Build de production
eas build --platform ios --profile production
eas build --platform android --profile production

# Submit a stores
eas submit --platform ios
eas submit --platform android
```

### 6. Push token storage en backend

Schema diferente al PWA mode (Web Push subscription endpoint vs Expo Push Token):

```sql
-- forja-mobile/supabase/migrations/0004b_expo_push_tokens.sql
-- (paralelo a 0004_push_subscriptions.sql del Mode A)

create table if not exists public.expo_push_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android')),
  device_name text,
  app_version text,
  created_at timestamptz default now(),
  last_used_at timestamptz default now(),
  unique (user_id, token)
);

alter table public.expo_push_tokens enable row level security;

create policy "users read own tokens" on public.expo_push_tokens
  for select using (auth.uid() = user_id);

create policy "users insert own tokens" on public.expo_push_tokens
  for insert with check (auth.uid() = user_id);

create policy "users delete own tokens" on public.expo_push_tokens
  for delete using (auth.uid() = user_id);
```

Si Mode A también corrió, ambas tablas coexisten — backend chequea ambas al enviar push (web → web-push.sendNotification, native → Expo Push Service).

### 7. Update .env (mobile + backend)

```bash
# forja-mobile/.env
EXPO_PUBLIC_SUPABASE_URL=...
EXPO_PUBLIC_SUPABASE_ANON_KEY=...

# .env.local (backend que envía pushes)
# NO secrets requeridos por Expo Push Service (es free + open)
# Pero mantener el token storage en mismo backend Supabase
```

### 8. Verificación pre-handoff

```bash
# app.json valid
test -f forja-mobile/app.json
node -e "JSON.parse(require('fs').readFileSync('forja-mobile/app.json'))"

# eas.json valid
test -f forja-mobile/eas.json
node -e "JSON.parse(require('fs').readFileSync('forja-mobile/eas.json'))"

# expo-notifications imported
grep -q "expo-notifications" forja-mobile/package.json
grep -q "from 'expo-notifications'" forja-mobile/lib/push/notifications.ts

# RLS habilitado en expo_push_tokens
grep -q "enable row level security" forja-mobile/supabase/migrations/0004b_expo_push_tokens.sql

# Permission flow NO on app launch — solo post-action
! grep -q "registerForPushNotifications" forja-mobile/App.tsx
! grep -q "registerForPushNotifications" forja-mobile/app/_layout.tsx
```

### 9. Output handoff

Imprimir bloque `## add-mobile handoff` con Mode RN_EXPO + advisory:
- Apple Developer Account ($99/año)
- Google Play Console ($25 one-time)
- Expo Account (free for personal, paid for managed credentials at scale)
- EAS Build minutes ($0 free tier 30/month, paid plans)
- Store review cycles (iOS 24-72h, Android 1-3h typically)

## Diferencias relevantes vs Mode A/B

| Aspecto | PWA (Mode A) | Capacitor (Mode B) | RN+Expo (Mode C) |
|---------|--------------|--------------------|--------------------|
| Codebase | web Next.js | web Next.js + native wrapper | React Native standalone |
| Source of truth | una codebase | web codebase (Capacitor envuelve) | mobile codebase paralelo |
| Push provider | Web Push (VAPID) | FCM/APNs | Expo Push Service |
| Build pipeline | Vercel deploy | next build + cap sync + Xcode/AS | EAS Build cloud |
| Setup time | 10 min | 2-4h | 4-8h |
| Native features | Web APIs only | Capacitor plugins (60+ official + ecosystem) | Expo SDK + native modules + RN ecosystem |
| Iteration | instant | minutos | hours (review) |
| Free tier | infinito | $99/año mínimo | $99/año + EAS limits |

## Citations

- [docs:expo] · [docs:expo-notifications] · [docs:eas-cli] (R13)
- [memory:references#R-005] · [memory:CONSTRAINTS.md#R10..14]
- [memory:lessons#L-001..3]
- [memory:decisions#D-010..D-012]
