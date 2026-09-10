# Chain rationale — init-saas

> Por qué este orden, qué produce cada step, qué dependencias tiene, y por qué la cadena resuelve E-006.

## Cadena canónica

```
add-ui-kit ──→ impeccable (Mode C BATCH) ──→ add-login
   (paso 1)         (paso 2)                  (paso 3)
```

## Qué produce cada paso

### Paso 1 — add-ui-kit (Discovery FRESH)

**Inputs:** AGENTS.md + Next.js + (opcionalmente) preset elegido por usuario.

**Outputs:**
- `brand/brand.json` — schema R-005 v1.1.0 (tokens + posture + archetype + anti_slop + component_rules + validation)
- `brand/voice.json` — schema R-005 v1.1.0 sección 9.2 (tone_axes + cta_examples + copy_voice + avoid_words)
- `brand/brand.css` — CSS vars derivadas 1:1 de tokens
- `src/app/(brand)/showcase/page.tsx` — visual showcase Next.js renderizando `component_rules`

**Tiempo típico:** ~30min (Discovery FRESH interview interactivo).

**Por qué primero:** Brand DNA es contrato no-negociable (D9 + R10). Sin él, impeccable no tiene tokens para consumir, add-login no tiene voice para copy de auth pages.

### Paso 2 — impeccable (Mode C BATCH)

**Inputs:** brand.json + voice.json + brand.css (de paso 1).

**Outputs:**
- `brand/component_rules.json` — declarative spec de los 11 components canónicos
- 11 `.tsx` files en `src/shared/components/ui/`:
  - **Form primitives:** Button (4 variants), Input (text+search), Textarea, Select
  - **Layout primitives:** Card (4 variants), Modal (3 variants)
  - **Navigation primitives:** Sidebar, Topbar, Tabs, Breadcrumb
- `src/shared/lib/cn.ts` — helper `cn()` para className merging (si shadcn-customizado mode)

**Brand Score:** ≥75 por componente (avg 87.5+ típico).

**Tiempo típico:** ~25min (BATCH genera 11 components con anti-slop gate post-gen).

**Por qué después de add-ui-kit:** impeccable consume brand.json tokens + voice.json copy + brand.css custom properties. Sin paso 1, no puede generar.

**Por qué antes de add-login:** add-login `auth pages` consumen los components Button + Input + Card + Form generados por impeccable. Sin paso 2, add-login templates no resuelven imports `@/shared/components/ui/Button`.

### Paso 3 — add-login (Mode A Supabase default o Mode B Insforge)

**Inputs:** brand.json + voice.json + components de impeccable + baas decision (o fallback Supabase).

**Outputs:**
- `lib/supabase/{client,server,proxy}.ts` (Mode A) o `lib/insforge/...` (Mode B)
- `src/middleware.ts` (Next.js 16 forward)
- 4 auth pages: `app/(auth)/{sign-in,sign-up,forgot-password,update-password}/page.tsx`
- Auth routes: `callback/route.ts` + `sign-out/route.ts` + `delete-account/route.ts`
- `actions/auth.ts` (server actions con Zod whitelist L-003)
- `hooks/useAuth.ts`
- `0001_profiles.sql` (RLS L-001 enforced)

**Tiempo típico:** ~20min.

**Por qué último:** depende de paso 1 (brand) + paso 2 (components) + baas decision. Sin esos inputs, los template substitutions fallan.

## Por qué este orden (no permutable)

| Permutación posible | Por qué falla |
|---------------------|---------------|
| add-login → impeccable → add-ui-kit | add-login template referencia `@/shared/components/ui/Button` (output de impeccable) y consume voice.json (output de add-ui-kit). Sin paso previo, halt. |
| impeccable → add-ui-kit → add-login | impeccable PREFLIGHT halt: "brand.json + voice.json missing". Sin Brand DNA, no genera. |
| add-ui-kit → add-login → impeccable | add-login PREFLIGHT halt: "components base missing". Sin impeccable, no resuelve imports. |
| add-ui-kit → impeccable → add-login | ✅ Único orden válido. |

El orden lo dicta el grafo de dependencias. init-saas codifica este grafo.

## Cómo resuelve E-006

Antes de init-saas (E-006 — UX gap conocido):

```
Usuario → /add-login
        ↓
        halt: "Falta src/shared/components/ui/Button"
        Sugerido: corré /impeccable Mode C primero
Usuario → /impeccable Mode C
        ↓
        halt: "Falta brand/brand.json"
        Sugerido: corré /add-ui-kit primero
Usuario → /add-ui-kit
        ↓
        Discovery FRESH interview, completa
Usuario → /impeccable Mode C
        ↓
        Genera 11 components
Usuario → /add-login
        ↓
        Finalmente arranca
```

3 invocaciones manuales, 2 halts intermedios, cognitive load alto.

Después de init-saas (post-F5-S1):

```
Usuario → /init-saas
        ↓
        Fase 0: detect-state → 0/3 pasos completados → mode FRESH
        Tabla mostrada al usuario, confirmación "go"
        ↓
        Paso 1: add-ui-kit Discovery FRESH (~30min)
        ↓
        Paso 2: impeccable Mode C BATCH (~25min)
        ↓
        Paso 3: add-login Mode A (~20min)
        ↓
        Handoff: ✅ Brand + components + auth listos
```

1 invocación, 0 halts intermedios (excepto bugs reales). UX cognitive load bajo.

**Resume-aware bonus:** si usuario interrumpe en paso 2 y vuelve después:

```
Usuario → /init-saas (segunda vez)
        ↓
        Fase 0: detect-state → paso 1 ✅ + paso 2 ⬜ + paso 3 ⬜ → mode EXISTING
        Reporta progreso parcial, ofrece continuar desde paso 2
        ↓
        Paso 2: impeccable (saltea Discovery del paso 1, ya resuelta)
        ↓
        Paso 3: add-login
        ↓
        Handoff: ✅ Pipeline completo
```

## Comparación con el-crisol (shape-par)

| Aspecto | el-crisol | init-saas |
|---------|-----------|-----------|
| Domain | strategy validation | build bootstrap |
| Pasos | 7 (brujula → ... → lanzamiento) | 3 (ui-kit → components → auth) |
| Dependencias | secuenciales fuertes | secuenciales fuertes |
| Resume-aware | Sí (Fase 0 detection) | Sí (Fase 0 detection, mismo shape) |
| Output | dashboard HTML + STRATEGY-REPORT.md | código generado en target project |
| Modos | go / saltar N / desde N / solo dashboard | go / desde N / solo [paso] |
| Veredicto | Go/Caution/No-Go (build confidence score) | N/A (wizard ejecuta, no evalúa) |
| ADR shape | D-014 boundary case (sin selector) | D-019 binary (FRESH / EXISTING) |
| L-004 aplica? | NO (sin selector) | SÍ (binary) |

**Distinción clave:** el-crisol NO tiene selector entre approaches → boundary case. init-saas SÍ tiene selector (FRESH vs EXISTING resume-aware) → binary aplica L-004.

D-019 documenta esta distinción explícitamente: aunque comparten shape estructural (sequential pipeline + resume-aware), el-crisol y init-saas tienen ADRs distintos (boundary vs binary) según presencia del selector.

## Cross-skill applicability — patrón wizard

init-saas establece el **patrón canónico para wizards de bootstrap**: cadena de 2-3 skills BUILD con resume-aware state detection. Aplicable a:

- **add-monetization** (paralelo): payments → emails → web-quality.
- **add-mobile-stack** (Phase 5+ futuro): add-mobile + push setup + manifest config.
- **add-admin-stack** (Phase 5+ futuro): admin layout + audit log + permissions matrix.

Cada wizard documenta su ADR D-NNN con shape (binary/trinary/boundary) según presencia de selector dentro del wizard.

## Citation grammar

- [memory:errors#E-006] — gap UX que init-saas resuelve.
- [memory:lessons#L-004] — binary test diagnóstico.
- [memory:decisions#D-009] — add-login Supabase default.
- [memory:decisions#D-014] — el-crisol boundary case (shape-par).
- [memory:decisions#D-015] — doctrine refinada (selector presence determina).
- [memory:decisions#D-019] — init-saas binary (FRESH / EXISTING).
- [memory:CONSTRAINTS.md#R4] — wizard MISMA NO invoca skills directo.
- [memory:CONSTRAINTS.md#R10] — Brand DNA contract via add-ui-kit (paso 1).

## Anti-patterns

- ❌ Permutar el orden ui-kit → components → auth (rompe dependencies).
- ❌ Ejecutar pasos en paralelo (cada paso depende del anterior).
- ❌ Saltar Fase 0 detección (waste si pasos ya completados).
- ❌ Re-ejecutar Discovery FRESH de add-ui-kit si brand.json válido existe.
- ❌ Force-fit init-saas a otros bootstraps (ej: marketing-site no tiene auth).
