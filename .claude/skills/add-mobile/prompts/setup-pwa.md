# Setup PWA — Mode A (default)

## Antes de empezar (R13)

```
1. resolve-library-id("web-push") → query-docs
   query: "web-push npm VAPID keys generate setVapidDetails sendNotification
           statusCode 410 411 cleanup invalid subscriptions"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router 16 service worker registration manifest.json metadata
           apple-mobile-web-app-capable theme-color"
```

**Razón:** Web Push API tiene quirks por browser (iOS Safari 16.4+ cambió mucho, Chrome cambió `pushsubscriptionchange` semantics, web-push npm package status codes 410/411 vs 4xx). Sin find-docs runtime falla con cryptic errors o silent breakage en iOS.

**Lección crítica del upstream saas-factory (14 commits debug en producción):**
- NO instalar `next-pwa`, `Serwist`, `Workbox`. Hazlo manual.
- Service Worker NUNCA intercepta fetch. Rompe iOS Safari PWA.
- VAPID keys se generan UNA VEZ y van en .env. No regenerar.
- Apple endpoints fallan silenciosamente — detectar via 4xx (excepto 429) y limpiar suscripción.

## Inputs requeridos

| Input | Source | Validation |
|-------|--------|------------|
| Brand DNA | brand/brand.json + voice.json | R-005 v1.1.0 + tokens.colors.primary |
| Auth | src/lib/{supabase,insforge}/server.ts + 0001_profiles.sql | add-login output |
| impeccable Card + Button | src/shared/components/ui/{Card,Button}.tsx | impeccable Mode C output |
| App name | brand.json.brand.product | Required (manifest.name) |
| Icons | brand.json.assets.icon_source | Optional (placeholders si ausente) |

## Pasos

### 1. PREFLIGHT (R10 + add-login chain + impeccable chain)

Validar 8 gates ya documentados en SKILL.md. Si alguno falla, halt + handoff explícito.

### 2. Generate VAPID keys (UNA VEZ)

```bash
npx web-push generate-vapid-keys --json
```

Output:
```json
{
  "publicKey": "BDx...",
  "privateKey": "abc..."
}
```

Estas keys van en `.env.local` y NO se regeneran. Si se pierden, todas las suscripciones existentes quedan inválidas y hay que resuscribir todos los usuarios.

### 3. Substitute templates → src/

| Template | Target | Substitutions |
|----------|--------|---------------|
| `public/manifest.json` | `public/manifest.json` | `{{ APP_NAME }}` ← brand.json.brand.product, `{{ APP_SHORT_NAME }}` ← derivado, `{{ THEME_COLOR }}` ← brand.json.tokens.colors.primary, `{{ BACKGROUND_COLOR }}` ← brand.json.tokens.colors.surface |
| `public/sw.js` | `public/sw.js` | none (sin substitutions — code es shape-agnostic) |
| `public/icons/icon-{72,96,128,144,192,512}.png` | mismo path | placeholders si brand.json no declara icon_source — warning a usuario |
| `lib/push/{client,server}.ts` | `src/lib/push/...` | `{{ VAPID_SUBJECT_DEFAULT }}` ← `mailto:noreply@<domain>` |
| `app/api/push/{subscribe,unsubscribe,send}/route.ts` | mismo path | none |
| `app/(mobile)/install/page.tsx` | mismo path | `{{ COPY_INSTALL_HEADING }}` ← voice.cta_examples derivado, `{{ COPY_INSTALL_BODY }}` ← voice |
| `components/PWARegister.tsx` | `src/components/PWARegister.tsx` | none (logic es generic) |
| `components/PushPermissionPrompt.tsx` | mismo path | `{{ COPY_PERMISSION_HEADING }}`, `{{ COPY_PERMISSION_BODY }}`, `{{ COPY_PERMISSION_CTA_ALLOW }}`, `{{ COPY_PERMISSION_CTA_DISMISS }}` ← voice.json |
| `components/InstallPromptUI.tsx` | mismo path | mismas substitutions que install/page.tsx |
| `hooks/usePushSubscription.ts` | mismo path | none |
| `actions/notifications.ts` | mismo path | none |
| `migrations/0004_push_subscriptions.sql` | `supabase/migrations/0004_push_subscriptions.sql` | none |

### 4. Update layout (manual instruction al usuario)

Después de generar archivos, instruir al usuario para que actualice el layout principal:

```tsx
// src/app/layout.tsx (o equivalente)
import PWARegister from '@/components/PWARegister';
import { PushPermissionPrompt } from '@/components/PushPermissionPrompt';

export const metadata = {
  // ... existing metadata
  manifest: '/manifest.json',
  themeColor: '<TOKEN_COLORS_PRIMARY>',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: '<APP_NAME>',
  },
};

// Dentro del body, al final:
<PWARegister />
<PushPermissionPrompt userId={user?.id} />
```

NO automático — el layout es shared con otras features (auth UI, navigation, footer). add-mobile imprime las instrucciones pero NO sobreescribe layout.tsx.

### 5. Append .env.local

```bash
cat >> .env.local <<'EOF'

# PWA + Push (added by add-mobile Mode A)
# Public — exposed to client (intencional para pushManager.subscribe)
NEXT_PUBLIC_VAPID_PUBLIC_KEY=BDx...REPLACE_WITH_GENERATED_PUBLIC_KEY

# Server-only — NEVER expose
VAPID_PRIVATE_KEY=abc...REPLACE_WITH_GENERATED_PRIVATE_KEY
VAPID_SUBJECT=mailto:noreply@yourdomain.com
EOF
```

### 6. Apply migration

```bash
.claude/skills/el-migrador/SKILL.md invocation:
- migration name: 0004_push_subscriptions
- file: supabase/migrations/0004_push_subscriptions.sql
- target: local + remote (post-validation)
```

el-migrador handles the apply. Sin él, instruir al usuario:
```bash
supabase migration up
```

### 7. Verificación pre-handoff

```bash
# Manifest valida JSON
node -e "JSON.parse(require('fs').readFileSync('public/manifest.json'))"

# SW NO tiene fetch handler (iOS Safari quirk)
! grep -q "addEventListener('fetch'" public/sw.js
! grep -q "addEventListener(\"fetch\"" public/sw.js

# VAPID_PRIVATE_KEY NO en client / NO en SW
! grep "VAPID_PRIVATE_KEY" public/sw.js
! grep "VAPID_PRIVATE_KEY" src/components/

# VAPID_PRIVATE_KEY EN server lib + api routes
grep "VAPID_PRIVATE_KEY" src/lib/push/server.ts
grep "VAPID_PRIVATE_KEY" src/app/api/push/send/route.ts

# RLS habilitado
grep "enable row level security" supabase/migrations/0004_push_subscriptions.sql
grep "auth.uid() = user_id" supabase/migrations/0004_push_subscriptions.sql

# R14: NO tool({execute}) en bulk
! grep -E "^export.*tool\(.*execute.*async.*(broadcast|sendToTopic|revokeAll)" src/actions/notifications.ts

# Permission flow NO on page load (autoShowDelay configurable)
grep "autoShowDelay" src/components/PushPermissionPrompt.tsx
```

### 8. Output handoff

Imprimir bloque `## add-mobile handoff` con Mode PWA + 4 surfaces R10 score + 10-check security.

## Diferencias relevantes vs Mode B/C

| Aspecto | PWA (Mode A) | Capacitor (Mode B) | RN+Expo (Mode C) |
|---------|--------------|--------------------|--------------------|
| Setup time típico | ~10 min | ~2-4h | ~4-8h con EAS |
| Developer accounts | $0 | $99/año Apple + $25 Google | mismo que Capacitor |
| Store distribution | NO (TWA opcional para Android) | SÍ | SÍ |
| Update deploy | instant (vercel push) | rebuild + store review | rebuild + EAS submit + store review |
| Iteration speed | <1 min | minutos a hours | hours a days (review) |
| Native features | Web APIs only | Capacitor plugins (camera, biometrics, etc.) | Expo SDK + native modules |
| Codebase | web Next.js | web Next.js + Capacitor wrapper | React Native standalone |
| Push provider | Web Push (VAPID) | Capacitor Push (FCM/APNs) | expo-notifications (FCM/APNs) |
| Free tier | infinito | $99/año mínimo | $99/año mínimo + EAS limits |
| iOS Safari quirks | sí (16.4+ requirements) | no (es app nativa) | no |

## Citations

- [docs:web-push] · [docs:web-push-libs] · [docs:nextjs] (R13)
- [memory:references#R-005] · [memory:CONSTRAINTS.md#R10..14]
- [memory:lessons#L-001..3]
- [memory:decisions#D-010] · [memory:decisions#D-011] · [memory:decisions#D-012]
