# detect-state

> Fase 0 de init-saas. Scan resume-aware de los 3 outputs canónicos (Brand DNA, core components, auth). Determina pipeline actual + presenta tabla de estado + confirma modo de inicio. Aplica L-004 test → BINARY (D-019).

## Inputs

- Project root path (working directory).
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
      paths_found: [<list>]    # component_rules.json + 11 .tsx files
      paths_missing: [<list>]
    auth:
      complete: bool
      paths_found: [<list>]    # src/features/auth/ + middleware
      paths_missing: [<list>]
  
  next_pending_step: 1 | 2 | 3 | none
  pending_count: 0 | 1 | 2 | 3
  estimated_time_min: <number>
  
  start_mode: go | desde-N | solo-step | abort
  resume_path: FRESH | EXISTING
```

## Step-by-step

### Paso 1 — Scan paths Brand DNA (paso 1 = ui-kit)

```bash
# Glob targets canónicos
test -f brand/brand.json
test -f brand/voice.json
test -f brand/brand.css
```

Si los 3 existen → `ui_kit.complete = true`. Si falta cualquiera → `complete = false`.

Validar también que brand.json es válido JSON (parseable) y tiene `tokens`, `posture`, `archetype`. Si parse falla → `complete = false` + warning.

### Paso 2 — Scan paths impeccable BATCH (paso 2 = components)

```bash
# Marker file
test -f brand/component_rules.json

# 11 core components canónicos (mínimo Button + Input para que paso 3 funcione)
ls src/shared/components/ui/Button/Button.tsx
ls src/shared/components/ui/Input/Input.tsx
ls src/shared/components/ui/Card/Card.tsx
# ... (Modal, Form, Tabs, Sidebar, Topbar, Breadcrumb, Select, Textarea)
```

Si `component_rules.json` + ≥7 de 11 components existen → `components.complete = true`. Threshold relajado a 7 porque add-login solo consume Button + Input + Card mínimo.

### Paso 3 — Scan paths add-login (paso 3 = auth)

```bash
# Auth feature folder
test -d src/features/auth/ || test -d src/app/\(auth\)/

# Middleware
test -f src/middleware.ts || test -f middleware.ts || test -f pages/_middleware.ts

# 4 auth pages canónicas (sign-in, sign-up, forgot-password, update-password)
ls src/app/\(auth\)/sign-in/page.tsx 2>/dev/null
```

Si feature folder + middleware existen → `auth.complete = true`.

### Paso 4 — Determinar `next_pending_step`

```
Loop por step en orden 1→3:
  Si step.complete = false → next_pending_step = step
  Salir del loop.
Si todos completos → next_pending_step = none.
```

`pending_count` = cantidad de steps con `complete = false`.

### Paso 5 — Estimar tiempo

```
estimated_time_min:
  ui_kit pendiente:    ~30min (Discovery FRESH interview)
  components pendiente: ~25min (impeccable BATCH 11 components)
  auth pendiente:       ~20min (add-login Mode A)
  
Total = sumá los pendientes.
```

### Paso 6 — Presentar tabla de estado

```markdown
🔨 init-saas — Setup inicial SaaS

**Project:** {path}
**Mode:** {FRESH | EXISTING resume-aware}

  #   Skill         Produce                     Estado
  1   add-ui-kit    Brand DNA                   ✅ ya existe / ⬜ pendiente
                    (brand.json + voice.json
                     + brand.css)
  2   impeccable    Core components             ✅ / ⬜
                    (Button, Input, Card,
                     Form, Modal + 6 más)
  3   add-login     Auth completo               ✅ / ⬜
                    (middleware + 4 pages
                     + Supabase/Insforge)
  ──────────────────────────────────────────────────────
  Pendientes: {N} de 3  ·  Tiempo estimado: ~{T}min
  Existentes: {M} de 3  (se reutilizan)
```

### Paso 7 — Confirmar inicio

```markdown
**¿Arrancamos?**

- "go"           → ejecutar lo pendiente desde paso N
- "desde N"      → forzar arranque desde paso N (re-ejecuta aún si completo)
- "solo [paso]"  → correr 1 paso aislado (ej: "solo components")
- "abort"        → no ejecutar
```

### Paso 8 — L-004 test diagnóstico (informativo en cada invocación)

| Caso | ¿Upstream user action requerida del selector? | Resultado |
|------|----------------------------------------------|-----------|
| Sin AGENTS.md (PREFLIGHT) | Sí (correr forge-init) | **PREFLIGHT halt, NO PAUSE genuino** |
| Sin Next.js (PREFLIGHT) | Sí (migrar a Next o usar otro framework) | **PREFLIGHT halt, NO PAUSE genuino** |
| 0 de 3 pasos completados | NO — FRESH path procede | NO PAUSE |
| 1-2 de 3 pasos completados | NO — EXISTING path procede desde pendiente | NO PAUSE |
| 3 de 3 pasos completados | NO — wizard reporta "todo completo, nada que hacer" | NO PAUSE |
| Sub-skill tiene PAUSE interno (ej: add-login espera baas decision) | NO — PAUSE-interno-delegado, manejado en sub-skill | NO PAUSE wizard |

**Conclusión D-019:** **BINARY** confirmed. FRESH default + EXISTING resume-aware override. NO PAUSE.

## Edge cases

### Edge: brand.json existe pero es inválido (parse fail)

→ `ui_kit.complete = false` + warning explícito al usuario: "brand.json existe pero NO parsea como JSON válido. ¿Re-ejecutar add-ui-kit Discovery FRESH (sobrescribe) o pause para fix manual?". Default conservador: pause + reportar.

### Edge: 8 de 11 components existen pero faltan 3

→ Si los 3 faltantes son Modal/Tabs/Breadcrumb (no críticos para add-login) → `components.complete = true` con warning informativo.
→ Si los 3 faltantes incluyen Button/Input/Card → `components.complete = false` (críticos para auth pages).

### Edge: middleware existe pero feature/auth/ no

→ `auth.complete = false`. Middleware solo es 1 de 2 outputs de add-login. Probablemente add-login parcial o middleware preexistente unrelated.

### Edge: auth/ existe pero con shape distinto al canónico (ej: `pages/api/auth/[...nextauth].ts` de NextAuth)

→ `auth.complete = false` con warning: "detecté NextAuth integration distinto al patrón Forja Supabase/Insforge. ¿Re-ejecutar add-login (sobrescribe) o pause para reconciliación manual?".

### Edge: usuario corre init-saas en proyecto ya completado (3 ✅)

→ `next_pending_step = none`. Reportar: "init-saas: nada que hacer. Brand DNA + components + auth ya están todos. Próximos pasos sugeridos: /add-monetization, /add-mobile, /la-forja."

### Edge: usuario fuerza "desde 1" cuando paso 1 ya está completo

→ Confirmar destructive intent: "Forzar `desde 1` re-ejecuta add-ui-kit Discovery FRESH y SOBRESCRIBE brand.json existente. ¿Confirmás?". Default conservador: abort si usuario duda.

### Edge: usuario corre "solo [paso]" cuando precondiciones de ese paso no están

→ Halt con mensaje: "Paso 3 (add-login) requiere paso 2 (components) completo. Detecté components.complete = false. Corré 'go' para ejecutar 2+3 en orden."

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — init-saas thin (detect-state es lectura + análisis, no genera código).
- [memory:lessons#L-004] — test diagnóstico binario-vs-trinario.
- [memory:decisions#D-019] — init-saas binary (FRESH / EXISTING).
- [memory:errors#E-006] — context (resuelve gap UX cadena de skills).

## Refusals

- ❌ Saltar scan (sin detección no se sabe qué skipear).
- ❌ Re-ejecutar Discovery FRESH si brand.json válido existe (waste).
- ❌ Force-fit trinary inventando un PAUSE artificial.
- ❌ Confundir PREFLIGHT halt (sin AGENTS.md) con PAUSE del selector (no aplica).
- ❌ Marcar `auth.complete = true` sin middleware presente.
- ❌ Saltar confirmation antes de Fase 1.
