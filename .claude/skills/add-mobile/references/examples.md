# add-mobile Examples — 3 Escenarios

> Cita: [memory:decisions#D-010] · [memory:decisions#D-011] · [memory:decisions#D-012]

## Escenario 1 — SaaS B2B web (PWA Mode A)

### Context

- Producto: dashboard SaaS para PYMEs LATAM
- Audience: web Chrome desktop (60%) + Android Chrome (35%) + iOS Safari (5%)
- Compliance: ninguno estricto, GDPR estándar
- Volumen: <10K users
- Equipo: web React + Next.js, no React Native experience
- Distribución: web only — no app store deseado
- Push use case: alerts cuando un workflow completa, recordatorios de billing

### Decision

PWA (Mode A). Default fuerte:
- Setup speed (10 min)
- No store distribution requerida
- Audience LATAM Android-mayoritaria → Chrome PWA install excelente
- iOS minoritaria → fallback graceful sin push (manifest only)
- Free tier infinito en Vercel

### Output

```
.claude/skills/add-mobile/templates/pwa/* aplicado
- 14 archivos generados
- VAPID keys en .env.local
- 0004_push_subscriptions.sql aplicada
- Brand contract: theme_color desde brand.json (color azul corporate)
- Permission flow: post-action (después de "Conectar workflow")
- Rate limit: 10 push/user/hour
- iOS Safari quirks documented en handoff
```

### Brand Score per surface

| Surface | Score |
|---------|-------|
| Manifest | 88/100 |
| InstallPromptUI page | 85/100 |
| PushPermissionPrompt | 82/100 |
| Push notification copy | 80/100 |
| Avg | 84/100 |

PASS (≥75 threshold).

## Escenario 2 — Marketplace LATAM (Capacitor Mode B)

### Context

- Producto: marketplace de servicios profesionales (estilo Workana / Fiverr LATAM)
- Audience: 70% Android + 30% iOS, distribución vía stores deseada
- Compliance: PCI-DSS para pagos (Stripe), GDPR estándar
- Volumen: ~50K users
- Equipo: Next.js + React, NO React Native experience
- Distribución: App Store + Play Store mandatory (branding + trust)
- Push use case: nuevos pedidos, mensajes de cliente, notificaciones de pago
- Native features: camera (subir portfolio), geolocalización approximate, deep linking

### Decision

Capacitor (Mode B). Web codebase Next.js existente envuelto + native shell:
- Reusa templates/pwa/ como source of truth web
- Native push via FCM/APNs uniforme (Capacitor bridge)
- Camera plugin oficial Capacitor para subir portfolio
- Deep linking via Capacitor App URLs
- Update OTA web part vía Capacitor Live Updates (paid tier opcional)

NO RN+Expo: equipo no quiere learning curve RN, web codebase ya tiene 6 meses de iteración.

### Output

```
.claude/skills/add-mobile/templates/pwa/* (Mode A re-corrió)
.claude/skills/add-mobile/templates/capacitor/* aplicado
- 14 archivos PWA + 6 archivos Capacitor config + 5 archivos integration
- capacitor.config.ts + native bridge en lib/native/push.ts
- iOS: APNs key + Firebase setup + Apple Developer $99/año
- Android: google-services.json + Firebase project + Play Console $25
- Build pipeline: next build + cap sync + Xcode/Android Studio
- Store submit cycles ~3-7 días primer-time, ~1-2 días subsequent
- Native push provider: FCM (Android direct) + APNs via FCM bridge (iOS)
```

### Brand Score per surface

| Surface | Score |
|---------|-------|
| Manifest + native icons | 90/100 |
| InstallPromptUI (web only) | 85/100 |
| PushPermissionPrompt (Capacitor + Web) | 86/100 |
| Push notification copy (FCM/APNs) | 84/100 |
| Avg | 86/100 |

PASS.

## Escenario 3 — App nativa fitness (RN+Expo Mode C)

### Context

- Producto: app fitness con tracking de workouts + push reminders
- Audience: 90% iOS + 10% Android (premium fitness segment)
- Compliance: HIPAA-adjacent (datos de salud) — NO BAA mandatory pero best-practice
- Volumen: ~5K users beta
- Equipo: React Native + Expo, web es secundario
- Distribución: App Store + Play Store mandatory
- Push use case: workout reminders, achievement notifications, social challenges
- Native features: HealthKit/Google Fit (read workout data), background timer, deep linking, Apple Watch companion (futuro)

### Decision

React Native + Expo (Mode C). Mobile-first stack:
- Codebase greenfield + native UX prioritario
- HealthKit integration requiere native modules (Capacitor plugin existe pero menos maduro)
- Apple Watch companion futuro → RN + watchOS extension easier que Capacitor
- expo-notifications + Expo Push Service (no FCM/APNs config manual)
- EAS Build cloud (no local Xcode setup)
- Web companion opcional → web SaaS con Next.js (separate codebase, share Supabase backend)

NO Capacitor: HealthKit y Apple Watch son native-first features.
NO PWA-only: store distribution premium positioning + native UX nativo importa.

### Output

```
.claude/skills/add-mobile/templates/react-native-expo/* aplicado
- 7 archivos config + 4 archivos integration
- Codebase paralelo en forja-mobile/ (separate del web )
- expo-notifications setup
- expo_push_tokens table (paralela a push_subscriptions del web app)
- EAS Build profiles (development + preview + production)
- iOS: Apple Developer $99/año + EAS managed credentials
- Android: Play Console $25 + Firebase project (FCM via Expo Push Service)
- Backend Next.js () sirve API para ambos: web + mobile
- HealthKit integration usa native module RN (futuro, fuera de scope add-mobile)
```

### Brand Score per surface

| Surface | Score |
|---------|-------|
| App icon + splash (RN) | 85/100 |
| Push notification copy (Expo) | 82/100 |
| Permission prompt screen | 78/100 |
| In-app notifications (foreground) | 80/100 |
| Avg | 81/100 |

PASS.

## Cross-scenarios summary

| Scenario | Mode | Setup time | Cost (Year 1) | Iteration | Native features |
|----------|------|-----------|----------------|-----------|------------------|
| 1 — B2B SaaS web | PWA | 10 min | $0 (Vercel free tier) | instant | Web APIs only |
| 2 — Marketplace | Capacitor | 4-6h primer | $124 ($99 Apple + $25 Google) | minutos a hours (rebuild + review) | Capacitor plugins (camera, deep linking, geo, push) |
| 3 — Fitness app | RN+Expo | 8-12h primer | $124+ ($99 Apple + $25 Google + EAS premium opcional) | hours a days (review + EAS limits) | HealthKit, Apple Watch, RN ecosystem completo |

## Anti-pattern: PAUSE attempted

```
Scenario: Government healthcare app con HIPAA on-prem mandatory + sin developer accounts
```

Tentación: PAUSE (como D-010 / D-011).

**Decisión correcta (D-012):** PWA con caveats documentados. NO halt skill.

Razón:
- HIPAA on-prem se aplica a backend (data storage) — el frontend mobile no rompe HIPAA
- Sin developer accounts → PWA installable es path válido
- Sin store distribution → PWA + TWA (Trusted Web Activity) opcional para Android
- iOS Safari install instructions vía manual flow

Si el target genuinamente NO puede usar PWA (ej: needs native HealthKit integration mandatory), ahí Capacitor o Expo aplican — pero eso requiere developer accounts, que es **assumption del proyecto**, no PAUSE del skill.

D-012 capture: PAUSE no aplica universalmente. Mobile es binary.

## Citations

- [memory:decisions#D-010] · [memory:decisions#D-011] · [memory:decisions#D-012]
- [memory:references#R-005]
- [memory:CONSTRAINTS.md#R10..14]
