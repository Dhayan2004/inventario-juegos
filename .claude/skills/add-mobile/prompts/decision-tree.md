> Cita transversal: [memory:lessons#L-004] (test diagnóstico binario-vs-trinario para el patrón "default friction-reducer + override explícito"). add-mobile es **binario** (NO trinario): el test diagnóstico mostró que NO hay degenerate case que requiera acción upstream del usuario — PWA-only es siempre fallback graceful válido. D-012 es el primer caso del bloque D que prueba que la trinaridad no es universal.

# add-mobile — Decision Tree (PWA / Capacitor / RN+Expo)

> Cita: [memory:decisions#D-010] (pattern "default + override + PAUSE" precedente — payments)
> Cita: [memory:decisions#D-011] (extensión compliance/ecosystem axis — emails)
> Cita: [memory:decisions#D-012] (mobile binary boundary — D-010/D-011 NO universalmente trinario)
> Cita: [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra cualquier SDK)

## Cuándo correr este árbol

Antes de elegir Mode A (PWA), Mode B (Capacitor) o Mode C (React Native + Expo) en `add-mobile`. Si Tech Spec del proyecto declara `mobile.mode` explícito, este árbol es informativo. Si Tech Spec NO declara, este árbol decide y se loggea `assumed_default` flag.

## Pattern boundary — D-012 (importante)

**add-mobile NO tiene PAUSE option.** Las skills add-payments (D-010) y add-emails (D-011) tienen un PAUSE branch que halt el skill cuando el caso es degenerado y requiere acción upstream del usuario (constituir empresa MoR / constituir infra SMTP self-hosted). Estos PAUSE existen porque ambos dominios tienen casos genuinamente bloqueables.

Mobile NO tiene equivalente. PWA es siempre fallback graceful válido:

- ¿Sin developer accounts Apple/Google? → PWA sirve.
- ¿Sin App Store distribution? → PWA sirve.
- ¿Sin compliance enterprise para "real apps"? → PWA sirve (es web).
- ¿iOS Safari mayoritario con limitaciones de push? → PWA sirve, con caveats documentados.
- ¿Audiencia vintage browsers sin SW support? → PWA installable sin push (manifest only).

El único caso donde PWA NO sirve es proyectos que requieren features genuinamente nativas (camera con quality control, biometrics, in-app purchases, deep linking sistema, background sync robusto). Esos casos eligen Mode B o C — no necesitan PAUSE.

**Generalización D-012:** El patrón "default + override + PAUSE" NO es universalmente trinario. Es trinario cuando el dominio tiene un degenerate case que requiere acción upstream del usuario antes de re-invocar (D-010 entity-legal, D-011 infra). Es binario cuando el caso degenerado es siempre subset del default (mobile: PWA es subset funcional de native shell; siempre disponible aunque sub-óptimo). Cita [memory:decisions#D-012].

## Pregunta 1 — Distribución y compliance

```
¿El proyecto requiere distribución en App Store / Play Store con
listing oficial?

Casos típicos:
- Compliance enterprise que dice "must be in store"
- Branding que necesita el icono en home screen via store install
- Marketing que apunta a "descargá la app" desde stores
- Distribución corporativa via MDM (Mobile Device Management)

├─ SÍ → seguir a Pregunta 2 (probablemente native shell)
│
└─ NO → seguir a Pregunta 4 (probablemente PWA)
```

## Pregunta 2 — Native features mandatorias

```
¿Requiere ALGUNO de estos features genuinamente nativos
(no cubribles por Web APIs)?

- Camera con quality control fino (HDR, RAW, manual exposure)
- Biometrics (Face ID / Touch ID / Android equivalente)
- Geolocalización background continuous (no solo on-demand foreground)
- Deep linking sistema (Universal Links iOS / App Links Android)
- In-app purchases (Apple/Google 30% commission unavoidable)
- Background sync robusto (long-running tasks, no constraints PWA)
- File system access bidireccional sin user prompt cada vez
- Bluetooth Low Energy (BLE) hardware integration
- HealthKit / Google Fit data access
- Apple Pay / Google Pay nativo (no Web Payment Request API)

├─ SÍ → seguir a Pregunta 3 (Capacitor o Expo)
│
└─ NO → considerar PWA (Mode A) — la mayoría de "native features"
        que la gente pide tienen Web equivalents (camera = getUserMedia,
        geolocation = Geolocation API, push = Web Push, install = manifest).
        Solo cuando los Web equivalents NO sirven, ir a native shell.
```

## Pregunta 3 — Codebase actual del proyecto

```
¿Qué tecnología tiene el codebase actual?

- Next.js / Remix / web React → CAPACITOR (Mode B)
  Razón: Capacitor envuelve la build web existente. Reusa templates/pwa/
  como source of truth + Capacitor wraps en native shell para distribución
  store. Cero rewrite.

- React Native existente → EXPO (Mode C)
  Razón: Expo simplifica RN setup. Si ya hay codebase RN, no tiene sentido
  migrar a Capacitor. expo-notifications es la integración natural.

- Codebase mixto / desktop + mobile → considerar Tauri 2.x (mobile beta)
  Razón: si el target es desktop+mobile en una sola codebase, Tauri 2.x
  ofrece una opción. PERO: mobile beta status — no recomendable para
  producción aún. Default a Capacitor en este caso.

- Codebase nuevo greenfield + native UX prioritario → EXPO (Mode C)
  Razón: si vas a empezar de cero y querés native UX, RN+Expo es el
  stack más maduro. Capacitor es web-wrapper, no native UX nativo.
```

## Pregunta 4 — Setup speed + DX

```
¿El proyecto prioriza?

- Setup en <30 min (no >2-4h Capacitor / >4-8h Expo + EAS)
- Cero developer accounts ($99/año Apple + $25 one-time Google)
- Cero store review (rejection cycles, etc.)
- Iteración deploy <1 min (vercel push vs eas build + submit)
- Free tier amplio (Vercel deploy es gratis vs $99/año Apple)

├─ SÍ (todos o la mayoría) → PWA (Mode A) — default fuerte
│
└─ NO (algún hard constraint) → re-evaluar contra Pregunta 1+2
        Si la respuesta a P1 fue NO pero ahora hay constraint
        anti-PWA específico (ej: Apple Pay nativo unavoidable),
        considerar Capacitor o Expo. Sino, PWA gana.
```

## Pregunta 5 — Audience platform mix

```
¿Qué dispositivos usan los usuarios?

- Android-mayoritario (LATAM, India, Sudeste Asia) → PWA excelente
  Razón: Chrome PWA install + push web + offline shell + Android
  TWA option (Trusted Web Activities) para listing en Play Store si
  eventualmente se necesita.

- iOS-mayoritario con push crítico → PWA con caveats documentados
  Razón: iOS Safari PWA push requiere 16.4+ + PWA-installed-state.
  Si push es feature crítica para iOS (revenue depends on push), considerar
  Capacitor o Expo para garantizar push reliability. Sino, PWA con
  iOS-fallback (in-app banner si no installed) es suficiente.

- iOS-mayoritario sin push crítico → PWA OK
  Razón: install funciona post-16.4, push es nice-to-have no critical.

- Mixed con desktop primary → PWA gana (desktop install + mobile complement)

- Enterprise con MDM distribution → Capacitor o Expo (MDM no soporta PWA)
```

## Pregunta 6 — Equipo skills

```
¿Qué stack maneja el equipo cómodamente?

- Web React solamente → PWA o Capacitor
  PWA gana si setup speed importa. Capacitor si store distribution.

- React Native experiencia → Expo (Mode C)
  Razón: usar lo que ya saben. EAS workflow es mature.

- Equipo backend-mostly + mobile is side concern → PWA
  Razón: lowest learning curve. SW + manifest + Web Push API son
  plain web. RN + EAS + native modules son learning investment.

- Equipo native iOS/Android existing → considerar fuera-de-add-mobile-scope
  Razón: si el equipo es native first, ya tienen workflows. add-mobile
  asume web-first stack. Documentar como "consult specialist" en handoff.
```

## Tabla resumen

| Distribution store? | Native features? | Codebase | Decision |
|--------------------|-------------------|----------|----------|
| NO | ninguno crítico | Next.js / web | **PWA** |
| NO | ninguno | greenfield | **PWA** |
| SÍ | ninguno crítico | Next.js / web | **PWA + TWA** (Android) o Capacitor (iOS) |
| SÍ | camera quality / biometrics / IAP | Next.js / web | **CAPACITOR** |
| SÍ | mismos features | greenfield | **EXPO** (mobile-first) |
| SÍ | mismos features | React Native | **EXPO** |
| NO | ninguno | Android-mayoritario LATAM | **PWA** |
| iOS-mayoritario | push crítico | Next.js / web | **PWA** con caveats o **CAPACITOR** si push reliability is revenue |
| Enterprise MDM | distribution mandatory | cualquiera | **CAPACITOR** o **EXPO** |
| Sin developer accounts | quiere "app feel" | cualquiera | **PWA** (manifest install + Web Push) |

## Default cuando ambiguo o sin Tech Spec

**PWA (Mode A).** Loggear `assumed_default = true`. Rationale: cita [memory:decisions#D-010] (pattern friction reduction) + [memory:decisions#D-012] (mobile binary boundary — PWA es subset funcional siempre disponible).

PWA es default fuerte porque:
- Setup speed más rápido (10 min vs 2-8h)
- Cero dependencias developer accounts ($0 vs $99-$124/año)
- Cero store review cycles (días/semanas)
- Iteración deploy instant
- Cross-browser coverage moderna (Chrome/Firefox/Edge desde 2018, Safari 16.4+)
- Free tier infinito en Vercel/Netlify
- Si crece y eventualmente necesita native shell, Capacitor envuelve la PWA existente sin rewrite (Mode B reusa templates/pwa/)

## Outputs del árbol

```
1. PWA       → Mode A (templates/pwa/**)
2. CAPACITOR → Mode B (templates/capacitor/** + reuse templates/pwa/**)
3. RN+EXPO   → Mode C (templates/react-native-expo/**)

NO PAUSE — ver D-012 pattern boundary.
```

Resultado se documenta en TECH-SPEC-<nombre>.md sección "Mobile Decision":

```markdown
## Mobile Decision

**Mode:** pwa | capacitor | react-native-expo
**Rationale:**
- Distribution: <store-mandatory | web-only | TWA-Android-supplement>
- Native features critical: <none | camera-quality | biometrics | IAP | deep-linking | other>
- Codebase: <Next.js | React Native | greenfield | mixed>
- Setup speed: <prioritario | no>
- Audience: <Android-mayoritario | iOS-mayoritario | mixed | desktop-primary>
- Team skills: <web-react | react-native | backend-mostly | native-existing>

**Decision tree path:** P1 → P2 → ...
**Source:** add-mobile/prompts/decision-tree.md
**Cita:** [memory:decisions#D-010] · [memory:decisions#D-011] · [memory:decisions#D-012]
**Assumed default:** false | true
```

## Refusals del árbol

- ❌ Force-fit native shell cuando target NO necesita store distribution + NO necesita native features genuinos. PWA gana entonces.
- ❌ PAUSE option. NO existe en add-mobile. Si el caso parece "degenerado" (compliance que pide store + sin developer accounts), la respuesta es "PWA + advisory para constituir developer accounts si eventualmente necesitan store" — NO halt skill. Ver D-012.
- ❌ Default Capacitor o Expo cuando ambiguo. Default es PWA (D-012 + friction reduction).
- ❌ Skipear preguntas de codebase (P3) cuando native shell aplica. Capacitor vs Expo depende fuertemente del codebase actual.
- ❌ Asumir que "mobile-first" = "RN+Expo". Mobile-first se puede hacer perfectamente con PWA + responsive design + install prompt + push web.

## Cross-skill applicability — pattern evolution

Análisis del patrón add-* a través de las 4 skills del bloque D:

| Skill | Decision | Axis | Estructura | PAUSE? |
|-------|----------|------|------------|--------|
| add-login (D-009) | Supabase default + Insforge override | technical maturity | binary | NO |
| add-payments (D-010) | Stripe default + Polar override + PAUSE | entity legal vs MoR | trinary | YES (constituir empresa) |
| add-emails (D-011) | Resend default + SendGrid override + PAUSE | compliance vs ecosystem | trinary | YES (constituir SMTP) |
| add-mobile (D-012) | PWA default + native shell override | distribution + native features | binary | NO (PWA fallback siempre) |

**Conclusión D-012:** "default + override + PAUSE" NO es universalmente trinario. La presencia de PAUSE depende de si el dominio tiene un degenerate case que requiere acción upstream del usuario antes de re-invocar el skill. Cuando el degenerate case es siempre subset del default disponible (mobile: PWA es subset funcional de native shell, siempre disponible aunque sub-óptimo), el patrón es naturalmente binario.

**Generalización válida cross-domain:** "default friction-reducer + override explícito por decision tree" — esta es la parte universal del patrón D-009 → D-012. PAUSE es opcional, depende del dominio. Esta es la lección estructural más importante del bloque D.
