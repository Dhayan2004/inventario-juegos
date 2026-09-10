---
name: add-monetization
description: >
  Wizard pipeline que compone la cadena de monetización: add-payments
  → add-emails → web-quality. Resume-aware (Fase 0 detección estado al
  estilo el-crisol/init-saas). Binary shape (D-020): full chain (default —
  los 3 pasos en orden) vs partial (override — payments-only para casos
  donde emails+audit son opcionales). Resuelve E-006 para cadena de
  monetización. Distinción CRÍTICA documentada en D-020: el PAUSE
  INTERNO de add-payments (D-010 trinary — Polar requiere empresa MoR)
  NO trinariza el wizard. add-monetization DELEGA a add-payments y este
  maneja su propio PAUSE internamente. Al wizard level, el selector es
  sobre la CADENA (full vs partial), NO sobre el provider de payments.
  PAUSE-interno-delegado ≠ PAUSE-wizard — primer ADR cross-skill que
  documenta esta distinción para futuros wizards. R4 enforced — wizard
  NO invoca skills directo, dispatch a sub-agents que invocan. Citas:
  [memory:errors#E-006] (resuelve), [memory:decisions#D-020] (binary
  + PAUSE-interno-delegado distinction), [memory:decisions#D-010]
  (add-payments PAUSE interno trinary), [memory:CONSTRAINTS.md#R4],
  [memory:CONSTRAINTS.md#R10] (Brand DNA via sub-skills).
tier: core
requires: add-login completado en proyecto target (add-payments lo requiere — PREFLIGHT halt si missing). Brand DNA presente: brand/brand.json + voice.json (PREFLIGHT halt si missing — handoff add-ui-kit). impeccable components base existen (Button + Input + Card mínimo — add-payments y add-emails los consumen). Active feature en feature_list.json (R1) recomendado.
fallback: Sin add-login → halt: "add-monetization requiere add-login completado. Corré /init-saas (compone add-ui-kit → impeccable → add-login) primero." Sin Brand DNA → halt + handoff add-ui-kit. Sin impeccable components → halt + handoff impeccable Mode C. Si add-payments retorna PAUSE interno (D-010 — empresa MoR para Polar) → wizard reporta el PAUSE-interno-delegado al usuario, espera resolución, y resume-aware retoma desde paso 2 cuando el usuario completa la decisión. Si web-quality (paso 3) no puede correr live (sin URL/server) → degrada a static analysis automático, NO halt.
dependencies: [find-docs, add-payments, add-emails, web-quality, add-login, impeccable]
---

# add-monetization

> *"Pagos. Emails. Audit. La cadena que monetiza sin sacrificar quality."*

Wizard pipeline. Compone la cadena de monetización Forja: **add-payments → add-emails → web-quality**. Mismo shape estructural que [`init-saas`](../init-saas/SKILL.md) y [`el-crisol`](../el-crisol/SKILL.md) — sequential pipeline + resume-aware state detection. Binary mode (D-020): full chain default + partial override sin PAUSE-wizard.

**Resuelve E-006** para cadena de monetización (paralelo a init-saas que resuelve la cadena auth/UI).

**No genera código.** No tiene `templates/` folder. R4 enforced — wizard MISMA NO invoca add-payments / add-emails / web-quality directamente. Solo dispatch a sub-agents que invocan.

## PREFLIGHT — halt-blocked en faltantes mandatorios

```
1. ¿add-login completado en proyecto target?
   - Detectar: src/features/auth/ o app/(auth)/ + middleware.ts
   - Sí → continuar
   - No → halt: "add-monetization requiere add-login. Corré /init-saas
            (compone add-ui-kit → impeccable → add-login) primero."

2. ¿Brand DNA presente (brand.json + voice.json)?
   - Sí → continuar (sub-skills consumen el contrato R10)
   - No → halt + handoff add-ui-kit: "Brand DNA missing. Corré /add-ui-kit
            o /init-saas para inicializar."

3. ¿impeccable components base existen?
   - Detectar: src/shared/components/ui/{Button,Input,Card} mínimo
   - Sí → continuar
   - No → halt + handoff impeccable Mode C BATCH

4. ¿feature_list.json con active feature (R1)?
   - Sí → asociar wizard al active feature
   - No → soft warning (no bloquea ejecución)
```

PREFLIGHT halt-blocked en gates 1+2+3 (precondiciones mandatorias). Gate 4 es soft warning.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario quiere integrar pagos en proyecto con auth ya listo | Coordinator |
| Usuario dice "monetización", "pagos + emails", "checkout completo + audit" | Coordinator |
| Triage de la-herreria post-Blueprint detecta SaaS con monetization → sugiere | la-herreria |
| Triage de la-forja Coordinator pattern compone init-saas + add-monetization secuencial | la-forja |

NO se invoca para: setup inicial SaaS sin auth (usá init-saas), feature pago individual sin emails (add-payments directo), audit web-quality sin pagos previos (web-quality directo).

## Mode selector (binary D-020)

| Modo | Trigger | Acción |
|------|---------|--------|
| **Full chain** (default) | Todos los pasos pendientes O usuario quiere stack completo | add-payments → add-emails → web-quality (3 pasos) |
| **Partial** (payments-only override) | Usuario dice "solo payments" / emails + audit out-of-scope | Solo paso 1 (add-payments). Skipea emails + audit. |

`prompts/detect-state.md` implementa la detección + ofrece modo según state.

### Resume-aware detection

```
¿src/features/payments/ existe + actions de checkout/portal?
├── Sí → skip add-payments (paso 1 ✅)
└── No → ejecutar (paso 1 ⬜)

¿lib/email.ts O React Email templates existen?
├── Sí → skip add-emails (paso 2 ✅)
└── No → ejecutar (paso 2 ⬜)

¿.claude/reports/web-audit-*.md existe + reciente (<7 días)?
├── Sí → skip web-quality (paso 3 ✅)
└── No → ejecutar (paso 3 ⬜)
```

### L-004 test aplicado a add-monetization

| Caso | ¿Upstream user action requerida del selector wizard? | Resultado |
|------|---------------------------------------------------|-----------|
| Sin add-login (PREFLIGHT) | Sí (correr init-saas) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Sin Brand DNA (PREFLIGHT) | Sí (add-ui-kit) | **PREFLIGHT halt, NO PAUSE genuino** |
| Sin impeccable components (PREFLIGHT) | Sí (impeccable Mode C) | **PREFLIGHT halt, NO PAUSE genuino** |
| Full chain con scope ambiguo | NO — partial mode siempre disponible | NO PAUSE |
| Partial mode pero usuario después quiere agregar emails | NO — re-invocar wizard, resume-aware detecta + ejecuta solo emails | NO PAUSE |
| **add-payments retorna PAUSE interno (D-010 — empresa MoR para Polar)** | **NO desde wizard** — PAUSE es **INTERNO al sub-skill add-payments**, NO del selector wizard. Wizard reporta PAUSE-delegado al usuario y resume-aware retoma cuando se resuelve. | **NO PAUSE wizard** (PAUSE-interno-delegado distinto) |

**Conclusión D-020:** **BINARY** confirmed. Full chain default + partial override. NO PAUSE-wizard genuino.

### CRÍTICO — Distinción PAUSE-interno-delegado ≠ PAUSE-wizard (D-020 documenta)

D-010 (add-payments) es **trinary** — tiene PAUSE genuino: si usuario indie sin empresa MoR registrada y baas decision tree dicta Polar, add-payments hace halt-blocked esperando que el usuario constituya empresa MoR.

D-020 (add-monetization) es **binary** — el wizard MISMO no tiene PAUSE genuino. ¿Por qué?

- El wizard **delega** a add-payments. Cuando add-payments encuentra su caso PAUSE interno, **reporta el PAUSE al wizard** como `step_result.outcome = paused` con `pause_resolution = "constituí empresa MoR para Polar O elegí Stripe (no requiere empresa)"`.
- El wizard **propaga** el PAUSE al usuario sin escalarlo al nivel selector wizard.
- El wizard sigue siendo BINARY (full vs partial) — el PAUSE de add-payments NO trinariza el wizard.
- Resume-aware: cuando usuario resuelve (constituye empresa O cambia decisión a Stripe), wizard re-invocado retoma desde donde quedó.

**Esta distinción es referenciable cross-wizards.** Futuros wizards que compongan skills con PAUSE interno (add-emails D-011 PAUSE on-prem SMTP, otros futuros) deben aplicar el mismo razonamiento: PAUSE-interno-delegado ≠ PAUSE-wizard.

D-020 es el primer ADR cross-skill que documenta este principio. Aplicable universalmente.

## Pipeline canónico (los 3 pasos)

```
add-payments ──→ add-emails ──→ web-quality
   (paso 1)       (paso 2)       (paso 3)
   │                │              │
   ▼                ▼              ▼
Stripe/Polar     Resend/        Lighthouse audit
checkout +       SendGrid       (live o static)
webhook +        + 7 React
subscriptions    Email templates
SQL              + suppression
```

| # | Sub-prompt | Skill invocado | Output | Necesita antes |
|---|------------|----------------|--------|----------------|
| 1 | `prompts/run-step.md` con `step=payments` | `add-payments` | lib/stripe + webhook + /pricing /checkout /success + 0002_subscriptions.sql | add-login + brand + components |
| 2 | `prompts/run-step.md` con `step=emails` | `add-emails` | lib/resend + 7 React Email templates + send route + 0003_email_subscriptions.sql | add-login + brand + components |
| 3 | `prompts/run-step.md` con `step=audit` | `web-quality` | .claude/reports/web-audit-*.md + Lighthouse scores | proyecto buildeado o src/ accesible |

## Fase 0 — Detección de estado

Detalle completo en [`prompts/detect-state.md`](prompts/detect-state.md). Resumen:

1. Scan paths canónicos:
   - `src/features/payments/` o `app/(app)/billing/` o equivalente
   - `lib/email.ts` o `lib/resend/` o `lib/sendgrid/` + `emails/` folder con React Email templates
   - `.claude/reports/web-audit-*.md` (recent: <7 días)
2. Determinar paso actual (primero pendiente).
3. Presentar tabla.
4. Confirmar inicio: `go` (full chain pendiente) / `solo payments` / `desde N` / `abort`.

## Fase 1 — Ejecución secuencial

Detalle en [`prompts/run-step.md`](prompts/run-step.md). Igual que init-saas — anunciar → dispatch → confirmar → transición. Diferencias específicas:

### Paso 1 (add-payments) — manejo de PAUSE-interno

```
[Sub-agent invoca add-payments]
   ↓
add-payments puede retornar 3 outcomes:
   - success → continuar paso 2
   - failed → halt + handoff add-payments
   - PAUSED-internal (PAUSE D-010, ej: empresa MoR requerida)
     → wizard NO escala como PAUSE-wizard
     → wizard reporta al usuario: "add-payments PAUSED — {pause_resolution}.
                                    Cuando resuelvas, re-invocá add-monetization."
     → halt graceful (resume-aware retomará desde paso 2 cuando usuario re-invoque)
```

### Paso 2 (add-emails)

```
add-emails también puede tener PAUSE interno (D-011 — on-prem SMTP).
Mismo manejo: PAUSE-interno-delegado, NO escala al wizard.
Reportar al usuario + halt graceful.
```

### Paso 3 (web-quality) — degradación graceful sin halt

```
web-quality binary (D-015): live audit (default si URL/server) vs static analysis (fallback).
Si no hay URL/server disponible al ejecutar paso 3 → web-quality auto-degrada a static.
NO halt — wizard procede con audit static + reporta al usuario.
```

## Reglas operativas (cross-pasos)

1. **NO repetir setup decisions.** Si add-payments definió `pricing_provider = stripe`, paso 2 (add-emails) hereda contexto pero NO consulta provider de payments — emails es independiente del provider de pagos.

2. **Propagar contexto cuando aplica.** Paso 3 (web-quality) puede recibir como input `payments_pages_paths` (de paso 1) y `email_templates_paths` (de paso 2) para audit focused en esas pages.

3. **R4 strict.** add-monetization MISMA NO invoca skills. Sub-agents son los que invocan add-payments/add-emails/web-quality.

4. **R5 strict.** Sub-agents NO escriben memory. Si emerge lesson/error → propagar a el-evaluador post-pipeline.

5. **PAUSE-interno-delegado correctamente manejado.** Documentado en regla operativa específica + run-step.md + D-020.

6. **Confirmation explícita entre pasos.** Igual que init-saas — usuario decide "continuar / pause / abort" después de cada paso.

7. **Halt + handoff explícito si paso falla.** Mensaje nombra el sub-skill + qué resolver. Resume-aware retoma post-fix.

8. **D-020 cita explícita.** detect-state.md + run-step.md citan D-020 + D-010 (PAUSE interno add-payments).

9. **Resuelve E-006 paralelo a init-saas.** SKILL.md cita E-006 explícitamente.

10. **NO templates folder.** Wizard shape thin.

## Output handoff (final)

```markdown
## ✅ add-monetization completado

**Pipeline ejecutado:** {N}/3 pasos
- ✅ Paso 1 (add-payments): {provider} — checkout + webhook + subscriptions
- ✅ Paso 2 (add-emails): {provider} — 7 React Email templates + suppression
- ✅ Paso 3 (web-quality): scores Performance/A11y/SEO/BP

**Tenés:** Pagos integrados + emails transaccionales + audit de calidad.

**Próximos pasos opcionales:**
- → `/add-mobile` para PWA + push notifications
- → `/la-forja` o `/build` para próxima feature de aplicación
- → `/el-guardian` audit pre-deploy serio (security audit complementario)

**Pre-deploy gate:** {PASS si web-quality sin Critical/High | NEEDS_FIX si gaps}

**Memory entries propuestas (para el-evaluador):**
- proposed_lesson: si emerge patrón cross-proyecto
```

Si pipeline parcial (paso falló o paused-internal):

```markdown
## add-monetization — Pipeline parcial

**Estado:** {N}/3 pasos
- ✅ Paso 1: completado
- ⏸️ Paso 2: PAUSED-internal (add-emails D-011 on-prem SMTP requerido)
- ⬜ Paso 3: pendiente

**Razón:** {pause_resolution}

**Próximo paso:** resolvé {sub-skill PAUSE}. Cuando termines, re-invocá
add-monetization → resume-aware retoma desde paso 2 (o 3 si 2 ya completo).

**NO PAUSE-wizard:** este es PAUSE-interno-delegado de {sub-skill} — el wizard
sigue siendo BINARY (D-020). Distinto a un PAUSE genuino del selector wizard
(que NO existe en add-monetization).
```

## Hard rules — R4/R5 enforcement

### R4 — Wizard MISMA NO invoca skills

> [memory:CONSTRAINTS.md#R4]: orchestrator NUNCA invoca skill directamente.

add-monetization MISMA:
- Lee state files
- Detecta state Fase 0 + presenta tabla
- Dispatch a sub-agents Fase 1
- Sintetiza outputs entre pasos
- NO Edit/Write a código de aplicación
- NO invoca add-payments/add-emails/web-quality directo

### R5 — Workers no escriben memory

Sub-agents NO tienen Write a `.claude/memory/*.md`. Outputs del wizard van a state (feature_list, .claude/reports/) y propagación de proposed_memory_entries al handoff de el-evaluador post-pipeline.

## Refusals

- ❌ Invocar add-payments/add-emails/web-quality directamente (R4 violation).
- ❌ Saltar Fase 0 detección (waste si pasos completos).
- ❌ Re-ejecutar add-payments si subscriptions ya existen (waste).
- ❌ Saltar confirmation entre pasos.
- ❌ Continuar paso N+1 si paso N falló.
- ❌ Bypass de PREFLIGHT de sub-skills.
- ❌ **Escalar PAUSE-interno-delegado al nivel wizard** (D-020 violation crítica).
- ❌ Force-fit trinary porque add-payments tiene PAUSE interno (D-020 distinción).
- ❌ Escribir código desde wizard (R4).
- ❌ Escribir a memory (R5).

## Tool filter — add-monetization MISMA

`Read · Grep · Glob · Bash (limited)`

NO Edit · NO Write directo · NO Skill (R4 — solo dispatch).

Bash limitado a:
- File globs (state detection)
- `git status` / `git log` (informativo)

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R4]` | en SKILL.md + run-step.md (orchestrator thin) |
| Constraint | `[memory:CONSTRAINTS.md#R5]` | en SKILL.md (workers no memory) |
| Constraint | `[memory:CONSTRAINTS.md#R10]` | en SKILL.md (Brand DNA via sub-skills) |
| Error | `[memory:errors#E-006]` | en SKILL.md + chain-rationale.md (resuelve gap) |
| Lesson | `[memory:lessons#L-004]` | en detect-state.md (binary D-020) |
| Decision | `[memory:decisions#D-020]` | en SKILL.md + detect-state.md + run-step.md (binary + PAUSE-interno-delegado distinction) |
| Decision | `[memory:decisions#D-010]` | en SKILL.md + run-step.md (add-payments PAUSE interno trinary) |
| Decision | `[memory:decisions#D-011]` | en run-step.md (add-emails PAUSE interno trinary) |
| Decision | `[memory:decisions#D-015]` | en run-step.md (web-quality binary modes para paso 3) |
| Decision | `[memory:decisions#D-019]` | informativo (init-saas paralelo) |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `add-payments` | downstream (paso 1). Sub-agent invoca con context (auth + brand + components). Maneja PAUSE-interno (D-010) sin escalarlo al wizard. |
| `add-emails` | downstream (paso 2). Sub-agent invoca. Maneja PAUSE-interno (D-011) sin escalarlo. |
| `web-quality` | downstream (paso 3). Sub-agent invoca con modo live (default) o static (fallback graceful). |
| `add-login` | upstream (PREFLIGHT). Sin add-login → halt + handoff init-saas. |
| `add-ui-kit` | upstream condicional (PREFLIGHT). Sin Brand DNA → halt + handoff. |
| `impeccable` | upstream condicional (PREFLIGHT). Sin core components → halt + handoff. |
| `init-saas` | wizard paralelo. init-saas resuelve auth/UI cadena, add-monetization resuelve monetización. Combinables: init-saas → add-monetization secuencial. |
| `add-mobile` | downstream sugerido. PWA + push después de monetización. |
| `el-guardian` | downstream condicional. Si proyecto va a deploy serio post-monetización, audit pre-deploy. |
| `el-evaluador` | post-pipeline. Recibe handoff con proposed_memory_entries. |
| `la-forja` | downstream sugerido para próxima feature. |

---

*"add-monetization compone la cadena de monetización con el mismo rigor R4 que init-saas. Y D-020 documenta el primer principio cross-wizard: PAUSE-interno-delegado ≠ PAUSE-wizard. Aplicable universalmente."*
