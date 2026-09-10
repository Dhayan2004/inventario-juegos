---
description: "PWA + Web Push drop-in (manifest + service worker + VAPID); native shell opcional."
---

# /add-mobile

Lee y ejecuta `.claude/skills/add-mobile/SKILL.md`.

Templates pre-armados (D-012 binary):

- **PWA (default):** `manifest.json` + `public/sw.js` (sin fetch handler — iOS Safari quirk crítico) + Web Push API + VAPID + `PushPermissionPrompt.tsx` + `InstallPromptUI.tsx` + hooks + actions con whitelist L-003 + R14 strict en bulk (`sendBroadcast` / `revokeAllSubscriptions`) + migration `0004_push_subscriptions.sql` con RLS L-001.
- **Native shell (override):** Capacitor web-first o React Native + Expo mobile-first.

**Pre-requisitos:**
- `add-login` completado (push_subscriptions tied to user_id).
- Brand DNA presente — `manifest.theme_color` + icons derivan de `brand.json`.
- `.env.local` writable para VAPID keys (público + privado).

**UX best practice:** permission prompt NO on page load — post-action que justifica notifications.
