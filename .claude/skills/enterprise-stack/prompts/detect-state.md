# detect-state

> Fase 0 de enterprise-stack. Scan resume-aware de los 3 wizards hijos (init-saas, add-monetization, add-mobile-stack). Determina pipeline actual + presenta tabla + confirma modo de inicio. Aplica L-004 test → BINARY (D-022).

## Inputs

- Project root path.
- AGENTS.md (PREFLIGHT pasó — Forja installed).
- skills.md validado (R6 — los 3 wizards existen).

## Output

```yaml
detection:
  project_root: <path>

  wizard_status:
    init_saas:
      complete: bool
      paths_found: [<list>]    # brand.json + voice.json + components + auth/
      paths_missing: [<list>]
    add_monetization:
      complete: bool
      paths_found: [<list>]    # payments/ + emails/ + (opcional) web-quality report
      paths_missing: [<list>]
    add_mobile_stack:
      complete: bool
      paths_found: [<list>]    # init-saas DONE + manifest.json + sw.js + push migration
      paths_missing: [<list>]

  next_pending_wizard: 1 | 2 | 3 | none
  pending_count: 0 | 1 | 2 | 3
  estimated_time_min: <number>

  start_mode: go | go-custom | solo-wizard | abort
  resume_path: FULL | CUSTOM
  custom_skip: [<list of wizards skipped si CUSTOM>]
```

## Step-by-step

### Paso 1 — Scan init-saas DONE

```bash
# init-saas outputs
test -f brand/brand.json
test -f brand/voice.json
test -f brand/brand.css
test -f brand/component_rules.json
ls src/shared/components/ui/Button/Button.tsx
ls src/shared/components/ui/Input/Input.tsx
ls src/shared/components/ui/Card/Card.tsx
test -d src/features/auth/ || test -d src/app/\(auth\)/
test -f src/middleware.ts
ls supabase/migrations/0001_profiles.sql 2>/dev/null
```

Si todos los paths críticos existen → `init_saas.complete = true`.

### Paso 2 — Scan add-monetization DONE

```bash
# add-monetization outputs
test -d src/features/payments/
test -d src/features/emails/
ls supabase/migrations/0002_subscriptions.sql 2>/dev/null
ls supabase/migrations/0003_email_subscriptions.sql 2>/dev/null
# web-quality report es opcional
ls .claude/reports/web-quality-*.md 2>/dev/null
```

Si payments/ + emails/ + las 2 migrations existen → `add_monetization.complete = true`. Web-quality report opcional (no bloquea).

### Paso 3 — Scan add-mobile-stack DONE

```bash
# add-mobile-stack es superconjunto de init-saas + mobile
# Primero verificar init-saas DONE (ya hecho en Paso 1)
test -f public/manifest.json
test -f public/sw.js
ls supabase/migrations/0004_push_subscriptions.sql 2>/dev/null
```

Si init-saas DONE + mobile paths existen → `add_mobile_stack.complete = true`.

**Edge case D-012:** Native shell (Capacitor / React Native) detectado en lugar de PWA → también válido. add-mobile internamente decide D-012 binary. Reportar como "EXISTING (Native shell)" pero `add_mobile_stack.complete = true`.

### Paso 4 — Determinar `next_pending_wizard`

```
Loop por wizard en orden 1→3:
  Si wizard.complete = false → next_pending_wizard = wizard
  Salir del loop.
Si todos completos → next_pending_wizard = none.
```

`pending_count` = cantidad de wizards con `complete = false`.

### Paso 5 — Estimar tiempo

```
estimated_time_min:
  init-saas pendiente:        ~75min (3 sub-pasos: ui-kit 30 + impeccable 25 + add-login 20)
  add-monetization pendiente: ~75min (3 sub-pasos: add-payments 30 + add-emails 25 + web-quality 20)
  add-mobile-stack pendiente: ~25min (solo el paso 4 mobile, asumiendo init-saas DONE)
                              ó ~100min si init-saas también pendiente (pero ese caso está cubierto en Wizard 1)
```

Estimación total FULL mode greenfield: ~3-4h primera vez.

### Paso 6 — Detectar override CUSTOM mode

Si el usuario invoca con override explícito:
- `enterprise-stack sin mobile` → `custom_skip = [add-mobile-stack]`.
- `enterprise-stack solo init-saas + add-monetization` → mismo.
- `enterprise-stack sin pagos` → `custom_skip = [add-monetization]`.
- `enterprise-stack full` (default) → no skip.

CUSTOM override es elección del usuario, NO degenerate case → NO PAUSE wizard.

### Paso 7 — Presentar tabla de estado

```
━━━ enterprise-stack — Setup Enterprise Completo (D-022 BINARY) ━━━━

  #   Wizard            Cubre                              Estado    Tiempo
  ──────────────────────────────────────────────────────────────────────────
  1   init-saas         Brand DNA + components + auth      ✅/⬜      ~75m
  2   add-monetization  Pagos + Emails + Audit web         ✅/⬜      ~75m
  3   add-mobile-stack  PWA + Push (superset de init-saas) ✅/⬜      ~25m*

  *: si init-saas DONE, add-mobile-stack solo ejecuta paso 4 mobile (~25min).
     Si init-saas pendiente, add-mobile-stack lo cubre completo (~100min).

  Resume mode: {FULL | CUSTOM}
  Pending: {N}/3 wizards · estimado: {N}min restantes

  Opciones:
    `go`              — proceder FULL desde wizard pendiente
    `go custom`       — preguntar al usuario qué wizards skipear
    `solo wizard-name` — correr solo 1 wizard aislado
    `abort`           — cancelar
```

### L-004 test diagnóstico (informativo — D-022)

| Caso | ¿Upstream user action requerida del selector? | Resultado |
|------|----------------------------------------------|-----------|
| Sin AGENTS.md / sin Next.js (PREFLIGHT) | Sí (correr forge-init) | PREFLIGHT halt, NO PAUSE selector |
| Sub-wizard PAUSE-interno (ej: add-monetization → add-payments → PAUSE-on-prem D-010) | NO — D-020 doctrine: PAUSE-interno-delegado NO escala | NO PAUSE wizard |
| EXISTING parcial (1 de 3 wizards completados) | NO — resume-aware procede | NO PAUSE |
| CUSTOM override (usuario excluye add-mobile-stack) | NO — override es elección del usuario | NO PAUSE |
| Wizards faltantes en skills.md (R6 fail) | Sí (re-instalar Forja) | PREFLIGHT halt R6, NO PAUSE selector |

**Conclusión:** **BINARY** confirmed (D-022 — wizard de wizards). FULL default + CUSTOM override + resume-aware, NO PAUSE genuino.

## Edge cases

### Edge 1 — add-mobile-stack DONE pero init-saas reporta paths incompletos
- Ambiguo: posible artifact de mover archivos manualmente.
- Reportar como "EXISTING parcial" + sugerir invocar `init-saas` directo para reconciliar.

### Edge 2 — Usuario eligió Insforge en init-saas → add-monetization debe consumirlo
- Detectar BaaS decision desde init-saas state (presencia de `lib/insforge/` vs `lib/supabase/`).
- Propagar a add-monetization (que invoca add-payments / add-emails con BaaS-aware paths).

### Edge 3 — CUSTOM mode skip add-monetization pero usuario quiere mobile
- Pipeline: init-saas → add-mobile-stack (skip 2).
- Válido. Resume-aware respeta.

### Edge 4 — Sub-wizard tiene PAUSE-interno (D-020 doctrine heredada)
- Sub-wizard reporta PAUSE-interno-delegado a enterprise-stack.
- enterprise-stack reporta al usuario: "Wizard {N} ({wizard_name}) PAUSE-interno: {razón del sub-wizard}".
- Halt graceful, NO escala como PAUSE-wizard.
- Usuario resuelve el sub-wizard manualmente. Re-invocar enterprise-stack.

### Edge 5 — R6 violation (wizard hijo no en skills.md)
- PREFLIGHT halt antes de Fase 1.
- NO ejecutar nada. Reportar wizard faltante + sugerir re-instalación.

## Citation

[memory:decisions#D-022] (binary shape wizard de wizards), [memory:decisions#D-019] (init-saas patrón heredado), [memory:decisions#D-020] (PAUSE-interno-delegado doctrine), [memory:decisions#D-021] (add-mobile-stack patrón heredado), [memory:decisions#D-012] (add-mobile binary interno), [memory:decisions#D-009] (init-saas → add-login Supabase default), [memory:CONSTRAINTS.md#R6] (skills.md registry validation), [memory:lessons#L-004] (binary test informativo).
