# Chain rationale — add-mobile-stack

> Por qué este orden, qué produce cada step, qué dependencias tiene, y por qué la cadena resuelve el chicken-egg de SaaS + Mobile bootstrap (extensión de E-006).

## Cadena canónica

```
add-ui-kit ──→ impeccable (Mode C BATCH) ──→ add-login ──→ add-mobile
   (paso 1)         (paso 2)                  (paso 3)       (paso 4)
```

## Por qué este orden (no permutable)

### Paso 1 — add-ui-kit (Discovery FRESH)

**Inputs:** AGENTS.md + Next.js + (opcionalmente) preset elegido.

**Outputs:**
- `brand/brand.json` — schema R-005 v1.1.0.
- `brand/voice.json` — sección 9.2 (tone + cta_examples).
- `brand/brand.css` — CSS vars derivadas 1:1 de tokens.
- `src/app/(brand)/showcase/page.tsx` — visual showcase.

**Tiempo típico:** ~30min.

**Por qué primero:** Brand DNA es contrato no-negociable (D9 + R10). Sin él, impeccable no tiene tokens para consumir, add-login no tiene voice para copy de auth pages, y **add-mobile no tiene `theme_color` ni icons para el manifest.json**.

### Paso 2 — impeccable (Mode C BATCH)

**Inputs:** brand.json + voice.json + brand.css (de paso 1).

**Outputs:**
- `brand/component_rules.json` — declarative spec de los 11 components canónicos.
- 11 `.tsx` files en `src/shared/components/ui/`.
- `src/shared/lib/cn.ts` — helper `cn()`.

**Brand Score:** ≥75 por componente.

**Tiempo típico:** ~25min.

**Por qué después de add-ui-kit:** impeccable consume brand.json tokens + voice.json copy + brand.css custom properties.

**Por qué antes de add-login:** add-login `auth pages` consumen Button + Input + Card + Form generados por impeccable. Sin paso 2, add-login no resuelve imports.

### Paso 3 — add-login (Mode A Supabase / B Insforge)

**Inputs:** brand.json + voice.json + components de impeccable + baas decision.

**Outputs:**
- `lib/supabase/{client,server,proxy}.ts` (Mode A) o `lib/insforge/...` (Mode B).
- `src/middleware.ts` (Next.js 16 forward).
- 4 auth pages: `app/(auth)/{sign-in,sign-up,forgot-password,update-password}/page.tsx`.
- Auth routes: `callback/route.ts` + `sign-out/route.ts` + `delete-account/route.ts` (R14 typed confirmation).
- `actions/auth.ts` (Zod whitelist L-003).
- `hooks/useAuth.ts`.
- `0001_profiles.sql` (RLS L-001).

**Tiempo típico:** ~20min.

**Por qué después de impeccable:** depende de paso 1 + paso 2.

**Por qué antes de add-mobile:** add-mobile produce `push_subscriptions` table tied to `user_id` (RLS L-001) — sin auth funcional, no hay user_id estable para asociar suscripciones de push.

### Paso 4 — add-mobile (D-012 binary PWA default / Native override)

**Inputs:** brand.json (theme_color + icons + splash) + add-login completado (push_subscriptions tied to user_id) + `.env.local` writable (VAPID keys público + privado).

**Outputs:**
- `public/manifest.json` — theme_color + icons + name desde brand.json.
- `public/sw.js` — service worker SIN fetch handler (iOS Safari quirk crítico).
- `lib/push/{client,server}.ts` con VAPID.
- `/api/push/{subscribe,unsubscribe,send}/route.ts` con whitelist L-003 + R14 strict en `sendBroadcast` y `revokeAllSubscriptions`.
- `src/features/pwa/components/PushPermissionPrompt.tsx` + `InstallPromptUI.tsx` (consumen impeccable Card + Button).
- `src/features/pwa/hooks/usePushSubscription.ts`.
- `src/features/pwa/actions/notifications.ts`.
- `0004_push_subscriptions.sql` (RLS L-001 enforced — tied to user_id).

**Tiempo típico:** ~25min.

**Por qué último:** depende de paso 1 (manifest.theme_color desde brand.json) + paso 2 (PushPermissionPrompt consume impeccable Card+Button) + paso 3 (push_subscriptions tied to user_id de add-login).

**Modo PWA-only fallback graceful (D-012 binary):** si el usuario decide NO incluir Native shell (Capacitor / React Native), PWA-only es output válido. add-mobile internamente decide. add-mobile-stack hereda — NO PAUSE wizard.

## Permutaciones que fallan

| Permutación posible | Por qué falla |
|---------------------|---------------|
| add-mobile → add-login → impeccable → add-ui-kit | add-mobile PREFLIGHT halt: "manifest.theme_color depende de brand.json"; "push_subscriptions tied to user_id depende de auth"; "PushPermissionPrompt depende de impeccable Card+Button". |
| impeccable → add-ui-kit → add-login → add-mobile | impeccable PREFLIGHT halt en paso 1. |
| add-ui-kit → add-mobile → impeccable → add-login | add-mobile PREFLIGHT halt: "auth missing — push_subscriptions sin user_id". |
| add-ui-kit → impeccable → add-mobile → add-login | add-mobile PREFLIGHT halt: "auth missing". |
| add-ui-kit → impeccable → add-login → add-mobile | ✅ Único orden válido. |

## Cómo resuelve el chicken-egg de SaaS + Mobile

Antes de add-mobile-stack:
- Usuario quiere PWA + push desde día 1 → corre `/add-mobile` → halt: "auth missing".
- Resuelve auth → corre `/add-mobile` de nuevo → halt: "Brand DNA missing (manifest.theme_color)".
- Resuelve Brand DNA → corre `/add-mobile` de nuevo → halt: "impeccable components missing (PushPermissionPrompt depende de Card+Button)".
- Resuelve impeccable → corre `/add-mobile` exitosamente.
- **4 invocaciones manuales con halt-handoff messages. Friction equivalente a E-006 pero un nivel arriba.**

Con add-mobile-stack:
- Usuario corre `/add-mobile-stack` → wizard detecta state → ejecuta los 4 pasos en orden → handoff final con stack completo.
- Una invocación. Resume-aware idempotente. Zero friction.

## Comparación con init-saas y add-monetization

| Wizard | Pasos | ADR | Resume-aware |
|--------|-------|-----|--------------|
| `init-saas` | 3 (ui-kit + components + auth) | D-019 binary | ✅ |
| `add-monetization` | 3 (payments + emails + audit) | D-020 binary + PAUSE-interno-delegado distinction | ✅ |
| `add-mobile-stack` | 4 (ui-kit + components + auth + mobile) | D-021 binary (hereda D-019) | ✅ |
| `enterprise-stack` (D-022) | 3 wizards (init-saas + add-monetization + add-mobile-stack) | D-022 binary (wizard de wizards) | ✅ |

**Patrón cross-wizards (post-D-021):**
1. Resume-aware state detection (D-014 boundary case shape).
2. Binary mode FRESH/EXISTING (L-004 binary, NO PAUSE genuino del selector).
3. PAUSE-interno-delegado de sub-skills NO escala (D-020 doctrine).
4. R4/R5/R10 enforcement con sub-agents.

## Cross-skill applicability

El patrón wizard que codifica add-mobile-stack es aplicable a cualquier cadena de skills donde:
- N skills tienen dependencias secuenciales rígidas (orden no permutable).
- Cada skill tiene PREFLIGHT halt si dependencia falta.
- Outputs de paso N son consumidos como inputs de paso N+1.
- El patrón se beneficia de resume-aware (idempotencia por re-invocación).

Wizards futuros que apliquen este patrón heredan D-021 + D-019 + D-020 doctrine.

## Citation

[memory:decisions#D-021] (binary shape add-mobile-stack), [memory:decisions#D-019] (init-saas patrón heredado), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine), [memory:decisions#D-012] (add-mobile binary interno PWA/Native), [memory:decisions#D-014] (boundary case shape — pipeline resume-aware), [memory:decisions#D-009] (add-login Supabase default), [memory:lessons#L-004] (binary test informativo), [memory:errors#E-006] (chicken-egg cadena de skills — extensión).
