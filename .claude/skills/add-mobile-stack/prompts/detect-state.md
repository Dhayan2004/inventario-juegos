# detect-state

> Fase 0 de add-mobile-stack. Scan resume-aware de los 4 outputs canónicos (Brand DNA, core components, auth, mobile/PWA). Determina pipeline actual + presenta tabla + confirma modo de inicio. Aplica L-004 test → BINARY (D-021 — patrón heredado de D-019).

## Inputs

- Project root path.
- AGENTS.md (PREFLIGHT pasó — Forja installed).

## Output

```yaml
detection:
  project_root: <path>

  step_status:
    ui_kit:
      complete: bool
      paths_found: [<list>]    # brand.json, voice.json, brand.css
      paths_missing: [<list>]
    components:
      complete: bool
      paths_found: [<list>]    # component_rules.json + ≥7 de 11 .tsx files
      paths_missing: [<list>]
    auth:
      complete: bool
      paths_found: [<list>]    # src/features/auth/ + middleware
      paths_missing: [<list>]
    mobile:
      complete: bool
      paths_found: [<list>]    # public/manifest.json, public/sw.js, push migration
      paths_missing: [<list>]

  next_pending_step: 1 | 2 | 3 | 4 | none
  pending_count: 0 | 1 | 2 | 3 | 4
  estimated_time_min: <number>

  start_mode: go | desde-N | solo-step | abort
  resume_path: FRESH | EXISTING
```

## Step-by-step

### Paso 1 — Scan paths Brand DNA

```bash
test -f brand/brand.json
test -f brand/voice.json
test -f brand/brand.css
```

Si los 3 existen → `ui_kit.complete = true`. Validar `brand.json` parseable + tiene `tokens`, `posture`, `archetype`.

### Paso 2 — Scan paths impeccable BATCH

```bash
test -f brand/component_rules.json
ls src/shared/components/ui/{Button,Input,Card}/*.tsx
# Threshold: ≥7 de 11 components canónicos
```

### Paso 3 — Scan paths add-login

```bash
test -d src/features/auth/ || test -d src/app/\(auth\)/
test -f src/middleware.ts
ls src/app/\(auth\)/sign-in/page.tsx 2>/dev/null
```

### Paso 4 — Scan paths add-mobile (PWA)

```bash
test -f public/manifest.json
test -f public/sw.js
ls supabase/migrations/*push_subscriptions*.sql 2>/dev/null
test -f src/features/pwa/components/PushPermissionPrompt.tsx 2>/dev/null
```

Si manifest + sw + migration existen → `mobile.complete = true`.

**Edge case:** add-mobile en modo PWA-only (sin Native shell) es válido. NO contar Native shell como mandatory — D-012 binary, PWA es default y suficiente.

### Paso 5 — Determinar `next_pending_step`

```
Loop por step en orden 1→4:
  Si step.complete = false → next_pending_step = step
  Salir del loop.
Si todos completos → next_pending_step = none.
```

### Paso 6 — Estimar tiempo

```
estimated_time_min:
  ui_kit pendiente:    ~30min (Discovery FRESH)
  components pendiente: ~25min (impeccable BATCH)
  auth pendiente:       ~20min (add-login Mode A/B)
  mobile pendiente:     ~25min (add-mobile PWA + VAPID + push routes)
```

### Paso 7 — Presentar tabla de estado

```
━━━ add-mobile-stack — Setup SaaS + Mobile (D-021 BINARY) ━━━━━━━

  #   Paso        Skill        Output                     Estado    Tiempo
  ─────────────────────────────────────────────────────────────────────────
  1   ui-kit      add-ui-kit   brand.json + voice.json    ✅/⬜      ~30m
  2   components  impeccable   11 core components         ✅/⬜      ~25m
  3   auth        add-login    middleware + 4 pages       ✅/⬜      ~20m
  4   mobile      add-mobile   PWA + Push (VAPID)         ✅/⬜      ~25m

  Resume mode: {FRESH | EXISTING}
  Pending: {N}/4 pasos · estimado: {N}min restantes

  Opciones:
    `go`              — proceder desde paso pendiente
    `desde N`         — forzar arranque desde paso N (re-ejecuta lo completado)
    `solo paso-name`  — correr solo 1 paso aislado
    `abort`           — cancelar
```

### L-004 test diagnóstico (informativo — D-021 hereda de D-019)

| Caso | ¿Upstream user action requerida del selector? | Resultado |
|------|----------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí (correr forge-init / migrar a Next) | PREFLIGHT halt, NO PAUSE selector |
| FRESH path con sub-skill PAUSE interno | NO — D-020 doctrine: PAUSE-interno-delegado NO escala | NO PAUSE wizard |
| EXISTING parcial (1 de 4 pasos completados) | NO — resume-aware procede | NO PAUSE |
| add-mobile PWA-only fallback graceful | NO — add-mobile (D-012) decide internamente | NO PAUSE |

**Conclusión:** **BINARY** confirmed (D-021). Patrón heredado de D-019.

## Edge cases

### Edge 1 — brand.json existe pero parse falla
- `ui_kit.complete = false` + warning "brand.json corrupto, regenerar via add-ui-kit".

### Edge 2 — components < 7 (BATCH parcial)
- `components.complete = false` — re-ejecutar impeccable BATCH (re-genera componentes faltantes idempotentemente).

### Edge 3 — auth pages existen pero middleware falta
- `auth.complete = false` — add-login retomar paso de middleware setup.

### Edge 4 — manifest.json existe pero sin theme_color (no derivado de brand.json)
- `mobile.complete = false` — add-mobile re-ejecuta para sincronizar manifest.theme_color con brand.json.

### Edge 5 — Native shell (Capacitor) detectado en lugar de PWA
- `mobile.complete = true` — D-012 binary acepta ambos paths. Reportar como "EXISTING (Native shell)".

## Citation

[memory:decisions#D-021] (binary shape add-mobile-stack), [memory:decisions#D-019] (patrón heredado de init-saas), [memory:decisions#D-012] (add-mobile binary interno PWA/Native), [memory:lessons#L-004] (binary test informativo).
