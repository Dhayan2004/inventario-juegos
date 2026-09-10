---
name: add-mobile
description: >
  Capabilities mobile drop-in para proyecto target. 2 modes (BINARIO,
  NO trinario): PWA (default — manifest + service worker sin fetch
  handler + Web Push API + VAPID) y Native shell (override — Capacitor
  web-first o React Native + Expo mobile-first). PWA-only es siempre
  graceful fallback válido cuando el target NO necesita features
  nativas — NO requiere acción upstream del usuario, así que NO PAUSE.
  D-012 documenta este pattern boundary vs. D-010/D-011 trinario.
  Templates pre-armados: manifest.json, public/sw.js (sin fetch
  handler — iOS Safari quirk crítico), lib/push/{client,server}.ts
  con VAPID, /api/push/{subscribe,unsubscribe,send} routes,
  PushPermissionPrompt.tsx + InstallPromptUI.tsx (consumen impeccable
  Card + Button), hooks/usePushSubscription.ts, actions/notifications.ts
  con whitelist L-003 + R14 strict en bulk (sendBroadcast/sendToTopic/
  revokeAllSubscriptions), 0004_push_subscriptions.sql con RLS L-001.
  Templates respetan R10: manifest theme_color + icons desde brand.json,
  copy del permission-prompt desde voice.cta_examples (NO marketing
  slop "Allow notifications to never miss out!"). UX best practice
  enforced: permission prompt NO on page load — post-action que
  justifica notifications.
tier: optional
requires: AGENTS.md exists, add-login completado (src/lib/{supabase,insforge}/* + 0001_profiles.sql aplicado — push_subscriptions.user_id depende), Brand DNA contract presente (brand/brand.json + voice.json), impeccable Mode C corrió (src/shared/components/ui/{Button,Card}.tsx — usadas en PushPermissionPrompt + InstallPromptUI), .env.local writable.
fallback: Sin add-login → halt + handoff a add-login (push_subscriptions FK user_id es no-negociable). Sin Brand DNA → halt + handoff a add-ui-kit. Sin impeccable Card/Button → halt + handoff a impeccable Mode C. Sin browser/device target con Service Worker support → modo PWA-installable-without-push (manifest only, no SW). Decision tree devuelve native shell pero el target no quiere developer accounts ni store distribution → fallback a Mode A (PWA con install prompt). NUNCA halt por "data sovereignty" — PWA-only es válido siempre (D-012 binary boundary).
dependencies: [find-docs, baas, add-login, add-ui-kit, impeccable]
---

# add-mobile

> *"La app instalable más pequeña es la que no necesita aprobarse en una store. La más completa es la que vive en el bolsillo del usuario sin permiso intermedio."*
> — Forja R10 + Web Push API + UX best practices

Skill drop-in. Setea capabilities mobile (PWA con push web por default; Capacitor o React Native + Expo como native shell override) en un proyecto target. Output Mode A (PWA): ~14 archivos. Output Mode B (Capacitor): ~6 archivos config + 5 archivos integration. Output Mode C (RN+Expo): ~7 archivos config + 4 archivos integration.

## PREFLIGHT halt (8 gates)

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Existe src/lib/{supabase|insforge}/server.ts + 0001_profiles.sql aplicado? Si no → halt: "Falta auth. Corré /add-login primero — push_subscriptions.user_id depende."
3. ¿Existe brand/brand.json + voice.json? Si no → halt: "Falta Brand DNA. Corré /add-ui-kit primero. R10 no negociable."
4. ¿Existe src/shared/components/ui/Card + Button? Si no → halt: "Falta impeccable Mode C. PushPermissionPrompt + InstallPromptUI los consumen."
5. ¿brand.json declara tokens.colors.primary? Si no → halt: "manifest.theme_color depende de brand.json.tokens.colors.primary."
6. ¿brand.json declara assets.icon_source o equivalente? Si no → fallback a placeholder /icons/icon-{72,96,128,144,192,512}.png + warning a usuario que los genere desde brand.
7. ¿voice.json cta_examples ≥3? Si sí → procedé mapeando a permission prompt CTAs. Si no → fallback conservador ("Activar notificaciones", "Ahora no", "Recordame después").
8. ¿Existe .env.local writable? Si no → crear con placeholders VAPID.
```

Sin estos 8 gates, add-mobile retorna error sin generar código.

**Note:** add-mobile NO halt-PAUSE por "data sovereignty" o equivalente. PWA-only es siempre fallback válido. Ver decision-tree.md + D-012.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide "agregame PWA / mobile / push notifications / instalable" | Coordinator |
| add-login cierra y proyecto necesita engagement push (B2C, marketplace, social) | add-login handoff |
| la-herreria fase 8 detecta mobile-first user stories | la-herreria handoff |
| add-payments cierra y proyecto necesita push de "payment success / failure" en device | add-payments handoff (combina con add-emails que ya cubre email path) |

## Decision tree (PWA / Capacitor / RN+Expo)

Detalle completo en [`prompts/decision-tree.md`](prompts/decision-tree.md). Resumen:

| Señal | Inclina hacia |
|-------|---------------|
| SaaS web-first / B2B / dashboard / marketplace + audience técnica | **PWA** |
| Setup speed prioritario (~10 min vs ~2-4h Capacitor / ~4-8h Expo) | **PWA** |
| No App Store distribution requerida | **PWA** |
| Audiencia LATAM Android-mayoritaria (Chrome PWA install excelente) | **PWA** |
| Codebase web Next.js que quiere "mismo código + native wrapper" | **Capacitor** |
| Camera / biometrics / geolocalización precisa / deep linking native | **Capacitor** o **Expo** |
| App Store + Play Store distribution mandatory | **Capacitor** o **Expo** |
| Codebase ya es React Native | **Expo** |
| In-app purchases (Apple 30% commission unavoidable) | **Capacitor** o **Expo** |
| Background sync robusto + tareas long-running | **Capacitor** o **Expo** |
| iOS Safari mayoría de usuarios + push crítico (16.4+ requirements) | **PWA con caveats** documentados |

**Default cuando ambiguo:** PWA. Cita [memory:decisions#D-010] (pattern reusado), [memory:decisions#D-011] (compliance/ecosystem axis), [memory:decisions#D-012] (mobile binary boundary). PWA gana por friction reduction + cero dependencias developer accounts + free tier infinito + cross-browser coverage moderna.

**NO PAUSE option.** A diferencia de add-payments (D-010 PAUSE = constituir empresa MoR) y add-emails (D-011 PAUSE = constituir SMTP self-hosted), add-mobile NO tiene degenerate case que requiera acción upstream del usuario antes de re-invocar. PWA-only sirve como graceful fallback siempre — incluso para usuarios sin developer accounts, sin store distribution, sin mobile experience. Ver [memory:decisions#D-012].

## 3 outcomes de operación

### MODE A — PWA (default)

Trigger:
- Tech Spec `mobile.mode = pwa`, OR
- Sin Tech Spec (fallback default), OR
- Decision tree señales: web-first SaaS + setup speed + no store distribution + audience técnica/Android-mayoritaria.

Detalle: `prompts/setup-pwa.md`.

Output: 14 archivos
- `public/manifest.json`
- `public/sw.js` (NO fetch handler — iOS Safari quirk)
- `public/icons/{72,96,128,144,192,512}.png` (placeholders, usuario genera desde brand.json)
- `lib/push/{client,server}.ts` (VAPID setup)
- `app/api/push/subscribe/route.ts`
- `app/api/push/unsubscribe/route.ts`
- `app/api/push/send/route.ts`
- `app/(mobile)/install/page.tsx` (install prompt UI vía impeccable)
- `components/PWARegister.tsx`
- `components/PushPermissionPrompt.tsx`
- `components/InstallPromptUI.tsx`
- `hooks/usePushSubscription.ts`
- `actions/notifications.ts` (whitelist L-003 + R14 bulk gates)
- `migrations/0004_push_subscriptions.sql` (RLS L-001 + policies)

### MODE B — Capacitor (override por native shell, web-first stack)

Trigger:
- Tech Spec `mobile.mode = capacitor`, OR
- Decision tree señales: codebase web Next.js + camera/biometrics/deep-linking + App Store distribution + native push deseado + equipo no quiere learning curve React Native.

Detalle: `prompts/setup-capacitor.md`.

Output: 6 archivos config + integration con templates/pwa/* (Capacitor envuelve la PWA, los archivos PWA siguen siendo source of truth para web).

### MODE C — React Native + Expo (override por native shell, mobile-first stack)

Trigger:
- Tech Spec `mobile.mode = react-native-expo`, OR
- Decision tree señales: codebase ya es React Native + EAS deseado + expo-notifications integration + audience iOS-mayoritaria con push avanzado.

Detalle: `prompts/setup-react-native-expo.md`.

Output: 7 archivos config + integration patterns. NO incluye los archivos PWA (RN+Expo es codebase paralelo, no envoltorio web).

## Loop de ejecución

```
0. PREFLIGHT halt (8 gates) — ver arriba
1. Decision tree → mode A / B / C (NO PAUSE — D-012 binary boundary)
   ├─ Mode A (PWA)        → templates/pwa/**
   ├─ Mode B (Capacitor)  → templates/capacitor/** + reuse templates/pwa/** para web side
   └─ Mode C (RN+Expo)    → templates/react-native-expo/**

2. Pre-gen find-docs (R13):
   - PWA: resolve-library-id("web-push") + ("nextjs") "App Router 16 service worker push"
   - Capacitor: resolve-library-id("capacitor") + ("capacitor-push-notifications")
   - Expo: resolve-library-id("expo") + ("expo-notifications") + ("eas-cli")

3. Read brand.json + voice.json (R10):
   - tokens.colors.primary → manifest.theme_color + manifest.background_color (si no declara contrast manifest)
   - assets.icon_source → manifest.icons (placeholders si ausente)
   - voice.cta_examples → permission prompt CTAs ("Activar", "Ahora no", "Recordame")
   - voice.avoid_words → audit en push notification copy templates

4. Substituir templates → src/**
   · public/manifest.json (theme_color + icons del brand)
   · public/sw.js (NO fetch handler — iOS Safari)
   · lib/push/{client,server}.ts
   · 3 api routes + 1 actions
   · 3 components + 1 hook + 1 page
   · 0004_push_subscriptions.sql

5. Generar SQL migration:
   · 0004_push_subscriptions.sql con RLS L-001 + 3 policies (SELECT/INSERT/DELETE auth.uid()=user_id)
   · NO UPDATE direct (last_used_at via service_role en send route)
   · JSDoc cita [memory:lessons#L-001]

6. .env.local update:
   · VAPID_SUBJECT (mailto:noreply@example.com)
   · NEXT_PUBLIC_VAPID_PUBLIC_KEY (público — intencional, va al client SW)
   · VAPID_PRIVATE_KEY (server only)
   · Generación: `npx web-push generate-vapid-keys` (instrucciones en setup-pwa.md)

7. Security pre-handoff scan (10-check):
   · VAPID_PRIVATE_KEY NO en client / NO en SW
   · VAPID_PUBLIC_KEY puede ir a client (intencional, validar que NO se confunda con private)
   · push_subscriptions RLS habilitado + 3 policies
   · SW NO tiene fetch handler (iOS Safari quirk)
   · SW scope explícito (no '/' por default si subset is enough)
   · Permission flow respeta UX best practice (NO on page load — comprobado por dry-run)
   · iOS Safari quirks documented (PWA install + push 16.4+ limitations)
   · sendBroadcast / sendToTopic / revokeAllSubscriptions sin execute() automático
   · Rate limiting documented en /api/push/send (max 10/user/hour para individual; bulk via separate authenticated route)
   · Manifest icons match brand.json (no Lighthouse defaults)

8. Output handoff a el-guardian (pre-deploy):
   · Pasar checklist de prompts/handoff-el-guardian.md
   · Bloquear deploy hasta PASS
```

## Reglas operativas

1. **brand.json + voice.json son contrato no-negociable (R10).** Manifest theme_color + background_color desde `brand.json.tokens.colors.primary` + derivados. Icons desde brand.json.assets.icon_source (placeholders + warning si ausente). Permission prompt CTAs derivan de `voice.cta_examples` (con fallback conservador). avoid_words audit corre sobre push templates.
2. **Service Worker NUNCA tiene fetch handler.** iOS Safari rompe PWA install si el SW intercepta fetch. Solo install + activate + push + notificationclick + pushsubscriptionchange + message. Esta es la lección #1 del upstream saas-factory (14 commits de debug en producción) — preservada en setup-pwa.md.
3. **find-docs antes de cada generación (R13).** Web Push API tiene quirks por browser (iOS Safari 16.4+ cambió mucho). Capacitor 6 cambió plugin shape vs 5. Expo SDK 51+ deprecated push tokens legacy. Sin find-docs, runtime falla con cryptic errors o silent breakage.
4. **L-001 enforcement en push_subscriptions SQL.** Tabla con `enable row level security` + 3 policies:
   - SELECT: auth.uid() = user_id (user reads own subs)
   - INSERT: auth.uid() = user_id (user registers own device)
   - DELETE: auth.uid() = user_id (user unsubscribes own device)
   NO UPDATE direct (last_used_at via service_role en send route).
5. **L-002 en push payload handlers.** Push payload puede contener data desde external sources (server-generated notifications con LLM-derived content). El SW handler trata payload como **datos**, NO ejecuta acciones agentic basadas en él. NO `event.data.json().action === 'delete' && deleteUser()` — eso es prompt-injection-via-push.
6. **L-003 en validators.** `actions/notifications.ts` whitelist:
   - `title: z.string().min(1).max(50)`
   - `body: z.string().max(150)`
   - `topic: z.enum([...known topics])`
   - `icon_url: z.string().url().refine(isAllowedDomain)` (whitelist domains)
   - `data: z.object({ url: z.string().url().optional(), ... })` typed schema, NO `z.record(z.any())`
7. **R14 strict en bulk operations.** `sendBroadcast`, `sendToTopic`, `revokeAllSubscriptions` NO export `execute()` automático. Cada uno requiere typed-confirmation gate (input "BROADCAST" / "SEND_TO_TOPIC" / "REVOKE_ALL") + audit log en DB pre-execute. Cita `[memory:CONSTRAINTS.md#R14]`.
8. **VAPID isolation.** `VAPID_PRIVATE_KEY` solo en `lib/push/server.ts` y api routes server-only. `NEXT_PUBLIC_VAPID_PUBLIC_KEY` puede ir al client (intencional para `pushManager.subscribe`). NUNCA confundir.
9. **Permission flow UX best practice.** El permission prompt NO se muestra on page load. Se muestra **post-action** que justifica notifications (ej: después de "save for later" o "follow this thread" o explicit "enable notifications" CTA). PushPermissionPrompt incluye `autoShowDelay` configurable + localStorage dismissal tracking + comportamiento explícito documented.
10. **iOS Safari quirks documented.** PWA install requires user gesture + Safari ≥16.4 + manifest must validate + start_url must be cacheable. Push web en iOS requires PWA-installed-state (no funciona en Safari sin install). Documentado en `references/ios-safari-quirks.md`.
11. **Rate limiting en /api/push/send individual.** Max 10 notificaciones / user / hour para flows individuales. Bulk via separate authenticated admin route (R14 gates).
12. **NO third-party PWA libs.** NO instalar `next-pwa`, `Serwist`, `Workbox`. Hacerlo manual. Estas libs rompen iOS. Lección preservada del upstream saas-factory (14 commits debug).

## Refusals (lo que NUNCA hace)

- ❌ Generar service worker con fetch handler. Lección iOS Safari crítica — automatic reject.
- ❌ Hardcodear copy ignorando voice.json. Permission prompts siempre desde `voice.cta_examples` (con fallback conservador). NO "Allow notifications to never miss out!" (marketing slop).
- ❌ Skipear RLS en push_subscriptions SQL. L-001 no negociable.
- ❌ Exportar `sendBroadcast`, `sendToTopic`, `revokeAllSubscriptions` como `tool({ execute })`. R14 binario.
- ❌ Mostrar permission prompt on page load. UX best practice no negociable — siempre post-action.
- ❌ Importar `VAPID_PRIVATE_KEY` en archivos accesibles desde client (route handlers de api/ son OK; React components NO).
- ❌ Instalar `next-pwa` / `Serwist` / `Workbox`. Manual setup, lección upstream.
- ❌ Force-fit native shell cuando target no quiere developer accounts ni store distribution. PWA es la opción correcta entonces.
- ❌ Halt por "data sovereignty mandatory" — NO PAUSE en add-mobile. PWA-only es graceful fallback siempre. Ver D-012.
- ❌ Skipear handoff a el-guardian pre-deploy.
- ❌ Editar `brand/**`, `.claude/memory/**`, `src/lib/{supabase,insforge}/**` (otros skills' territory).

## Tool filter

Read · Grep · Glob · Bash (`npx tsc --noEmit` para L1, `supabase db lint` para SQL, `npx web-push generate-vapid-keys` para keys, manifest.json validate via `node -e "JSON.parse(require('fs').readFileSync('public/manifest.json'))"`) · Write/Edit en `src/app/api/push/**`, `src/app/(mobile)/**`, `src/lib/push/**`, `src/components/{PWARegister,PushPermissionPrompt,InstallPromptUI}.tsx`, `src/hooks/usePushSubscription.ts`, `src/actions/notifications.ts`, `public/{manifest.json,sw.js,icons/}`, `supabase/migrations/0004_push_subscriptions.sql`, `.env.local` (append-only).

NO Edit en `brand/**` (add-ui-kit). NO Edit en `.claude/memory/**` (el-evaluador). NO Edit en `src/lib/{supabase,insforge}/**` ni `src/app/(auth)/**` (add-login). NO Edit en `src/lib/{stripe,polar}/**` ni `src/lib/{resend,sendgrid}/**` (add-payments / add-emails).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | brand.json + manifest theme_color/icons |
| Constraint source | `[memory:CONSTRAINTS.md#R10]` | header de install-prompt UI + permission prompt |
| Constraint source | `[memory:CONSTRAINTS.md#R14]` | sendBroadcast / sendToTopic / revokeAllSubscriptions |
| Constraint source | `[memory:CONSTRAINTS.md#R13]` | header de prompts que generan código contra Web Push / Capacitor / Expo |
| Lessons | `[memory:lessons#L-001]` | push_subscriptions SQL preamble |
| Lessons | `[memory:lessons#L-002]` | SW push handler header (payload as data) |
| Lessons | `[memory:lessons#L-003]` | actions/notifications.ts validators header |
| Decisions | `[memory:decisions#D-010]` | pattern precedente (default + override) |
| Decisions | `[memory:decisions#D-011]` | pattern precedente trinario (compliance axis) |
| Decisions | `[memory:decisions#D-012]` | mobile binary boundary específico (NO PAUSE) |
| External docs | `[docs:web-push]` `[docs:web-push-libs]` `[docs:capacitor]` `[docs:capacitor-push-notifications]` `[docs:expo]` `[docs:expo-notifications]` `[docs:nextjs]` | Cualquier código que use API |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `find-docs` | dependency. Pre-gen R13 invoca en cada modo. |
| `baas` | upstream. baas decision determina dónde vive push_subscriptions table. |
| `add-login` | upstream **mandatory**. push_subscriptions.user_id depende de auth.users. |
| `add-ui-kit` | upstream. Sin brand.json + voice.json válidos, halt. |
| `impeccable` | upstream **mandatory**. PushPermissionPrompt + InstallPromptUI consumen Card + Button. |
| `add-payments` | sibling. Si add-payments corrió antes, add-mobile detecta `subscriptions` table y agrega push templates de "Pago exitoso / Pago fallido / Suscripción cancelada" como complemento a add-emails. |
| `add-emails` | sibling. Multi-channel: emails para flows formales (receipts, password reset), push para flows urgentes/efímeros. NO se reemplazan — se complementan. |
| `el-migrador` | downstream Supabase only. Aplica 0004_push_subscriptions.sql. |
| `el-guardian` | mandatory pre-deploy. Audita VAPID isolation, SW scope, permission UX, iOS quirks, R14 gates, RLS, rate limiting. |
| `el-evaluador` | post-gen valida L1+L2+L3 (Brand contract per surface, security pre-handoff). |

## Output handoff

Tras pasar L1+L2+L3 + security pre-handoff:

```markdown
## add-mobile handoff

**Mode:** PWA | CAPACITOR | RN_EXPO
**Files generated:** N
**Output paths (PWA mode):**
- public/{manifest.json,sw.js,icons/}
- src/lib/push/{client,server}.ts
- src/app/api/push/{subscribe,unsubscribe,send}/route.ts
- src/app/(mobile)/install/page.tsx
- src/components/{PWARegister,PushPermissionPrompt,InstallPromptUI}.tsx
- src/hooks/usePushSubscription.ts
- src/actions/notifications.ts
- supabase/migrations/0004_push_subscriptions.sql

**Brand contract per surface:**
| Surface | tokens(25) | layout(20) | a11y(30) | anti-slop(15) | voice(10) | TOTAL |
|---------|-----------|------------|----------|---------------|-----------|-------|
| Manifest (theme_color + icons)  | ... | ... | n/a | ... | n/a | ≥75 |
| InstallPromptUI page            | ... | ... | ... | ... | ... | ≥75 |
| PushPermissionPrompt component  | ... | ... | ... | ... | ... | ≥75 |
| Push notification copy template | ... | n/a | n/a | ... | ... | ≥75 |

**Security pre-handoff (10-check):**
- ✅ VAPID_PRIVATE_KEY NOT exposed in client / SW
- ✅ NEXT_PUBLIC_VAPID_PUBLIC_KEY only in client (intencional)
- ✅ push_subscriptions RLS enabled + 3 policies (SELECT/INSERT/DELETE auth.uid()=user_id)
- ✅ Service Worker has NO fetch handler (iOS Safari quirk)
- ✅ Permission flow NOT on page load (autoShowDelay + post-action)
- ✅ sendBroadcast / sendToTopic / revokeAllSubscriptions have NO automatic execute()
- ✅ Rate limiting documented on /api/push/send (10 req/user/hour)
- ✅ Manifest icons match brand.json (no Lighthouse defaults)
- ✅ iOS Safari quirks documented (PWA install + push 16.4+ requirements)
- ✅ SW updates idempotent (skipWaiting + clients.claim correctly used)

**Citations:**
- [memory:references#R-005] (Brand DNA + manifest theme_color)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:CONSTRAINTS.md#R13] (external docs)
- [memory:CONSTRAINTS.md#R14] (destructive — bulk push ops)
- [memory:lessons#L-001] (RLS push_subscriptions)
- [memory:lessons#L-002] (SW push payload as data)
- [memory:lessons#L-003] (whitelist validators in actions)
- [memory:decisions#D-010] (default + override pattern)
- [memory:decisions#D-011] (compliance/ecosystem axis precedent)
- [memory:decisions#D-012] (mobile binary boundary — NO PAUSE)
- [docs:web-push] · [docs:web-push-libs] · [docs:nextjs] (Mode A)
- [docs:capacitor] · [docs:capacitor-push-notifications] (Mode B)
- [docs:expo] · [docs:expo-notifications] · [docs:eas-cli] (Mode C)

**Mandatory next step:** invocar `el-guardian` con prompts/handoff-el-guardian.md.

**Frictions encountered (if any):**
- <ambigüedades en brand.json.assets.icon_source>
- <gaps en voice.cta_examples para mobile-specific CTAs>
- → Promote to errors.md as E-NNN if recurring
```

---

*"PWA es la app que no necesita app store. Native shell es la app que sí. La pregunta es qué necesita tu producto, no qué prefiere el equipo."*
