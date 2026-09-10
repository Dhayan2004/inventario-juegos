# run-step

> Fase 1 de add-monetization. Protocolo genérico para ejecutar UN paso del pipeline (1 de 3). Sub-agents invocan add-payments/add-emails/web-quality. R4/R5 enforced. **Manejo crítico de PAUSE-interno-delegado (D-020)** documentado verbatim.

## Inputs

```yaml
step:
  number: 1 | 2 | 3
  name: payments | emails | audit
  skill_to_invoke: add-payments | add-emails | web-quality

context_acumulado:
  project_root: <path>
  brand_json_path: <path>            # validado en PREFLIGHT
  voice_json_path: <path>
  components_dir: <path>             # impeccable output, validado en PREFLIGHT
  
  # post-paso 1
  payments_provider: stripe | polar | null
  payments_pages: [<paths>]
  
  # post-paso 2
  emails_provider: resend | sendgrid | null
  emails_templates_dir: <path>
```

## Output

```yaml
step_result:
  step_name: payments | emails | audit
  outcome: success | failed | paused-internal

  # si success
  outputs_generated: [<paths>]
  output_summary:
    key_data: <ej: "Provider: Stripe, 12 archivos generados">
    rationale: <texto>
  next_step_context:
    propagate: [<vars>]

  # si failed
  fail_reason: <texto>
  fail_in_skill: <skill name>
  resume_instruction: <texto>

  # si paused-internal (CRÍTICO — D-020 distinction)
  pause_internal:
    sub_skill_with_pause: <add-payments | add-emails>
    pause_origin_adr: <D-010 | D-011>
    pause_reason: <texto del PAUSE genuino del sub-skill>
    pause_resolution: <texto>
    distinction_documented: true   # NO escala como PAUSE-wizard

  user_decision_post_step: continue | pause | abort
```

## Protocolo por paso

### Step 1 — Anunciar paso

```markdown
━━━ Paso {N}/3: {step_name} ━━━

**Skill a invocar:** {skill_to_invoke}
**Qué produce:** {output esperado}
**Dependencias del context:** {brand + components + auth via init-saas}
**Tiempo estimado:** ~{N}min
```

### Step 2 — Validar precondiciones

| Step | Precondiciones (heredadas de PREFLIGHT) |
|------|----------------------------------------|
| 1 (payments) | brand + components + add-login (validado en PREFLIGHT del wizard) |
| 2 (emails) | brand + components + add-login + (opcional pero útil) payments_provider del paso 1 |
| 3 (audit) | brand + components + add-login + (opcional) payments_pages + emails_templates_dir para audit focused |

### Step 3 — Dispatch sub-agent

```
[Sub-agent dispatched by add-monetization]
  Role: Pipeline executor (paso {N})
  Tool filter:
    - Read · Edit · Write · Grep · Glob (full-stack en project_root)
    - Bash: typecheck + tests + git
    - Skill: {skill_to_invoke}
  System prompt:
    "Sos pipeline executor para paso {N} (add-monetization wizard). Invocá
     {skill_to_invoke} con context: {context_acumulado_yaml}. NO escribas a
     .claude/memory/* (R5). Reportá step_result a add-monetization.
     
     **CRÍTICO si {skill_to_invoke} retorna PAUSE interno** (add-payments
     D-010 empresa MoR / add-emails D-011 on-prem SMTP):
     - Reportá outcome = paused-internal
     - NO escales el PAUSE como PAUSE-wizard
     - Provee pause_resolution detallado al wizard"
```

### Step 4 — Sub-agent ejecuta el skill

Sub-agent invoca `{skill_to_invoke}`. Skill ejecuta su flow normal:

- **add-payments:** Mode A (Stripe default) o Mode B (Polar override). Si baas decision dicta Polar y usuario indie sin empresa → PAUSE interno (D-010).
- **add-emails:** Mode A (Resend default), Mode B (SendGrid), Mode C (PAUSE on-prem SMTP — D-011). PAUSE genuino solo si compliance dicta on-prem.
- **web-quality:** binary live/static (D-015). Auto-degrada graceful sin halt.

Sub-agent reporta `step_result` al wizard.

### Step 5 — Wizard procesa step_result

**Si `outcome = success`:**

```markdown
✅ Paso {N}/3 completado → {output_summary.key_data}

**Outputs:**
{outputs_generated lista}

**Siguiente:** Paso {N+1} ({nombre}) — {qué hará}

¿Continuamos? (sí / pause / abort)
```

Procede a paso N+1 con context_acumulado actualizado (post user decision).

**Si `outcome = failed`:**

```markdown
❌ Paso {N} falló durante ejecución de {fail_in_skill}

**Razón:** {fail_reason}

**Próximo paso:** {resume_instruction}

**Cuando resuelvas:** re-invocá `/add-monetization` — resume-aware retoma
desde paso {N} o {N+1} según corresponda.
```

NO procede a paso N+1.

**Si `outcome = paused-internal` (CRÍTICO — D-020 distinction):**

```markdown
⏸️ Paso {N} PAUSED-internal — distinct from PAUSE-wizard

**Sub-skill con PAUSE:** {sub_skill_with_pause}
**ADR origen:** {pause_origin_adr} (PAUSE genuino del sub-skill, no del wizard)

**Razón:** {pause_reason}

**Resolución requerida (acción upstream del usuario):**
{pause_resolution}

**Distinción D-020:**
- Este es **PAUSE-interno-delegado** — el sub-skill ({sub_skill_with_pause})
  tiene PAUSE genuino documentado en {pause_origin_adr}.
- El wizard add-monetization **NO escala** este PAUSE al nivel wizard.
- add-monetization sigue siendo **BINARY** (full chain / partial) — no se
  trinariza por el PAUSE del sub-skill.

**Cuando resuelvas:**
Re-invocá `/add-monetization` → resume-aware detect-state Fase 0 verá:
- Paso {N}: progreso post-resolución (success → continúa) o aún en PAUSE
- Si success → wizard arranca desde paso {N+1}
- Si aún en PAUSE → wizard reporta el PAUSE de nuevo (idempotente)
```

NO procede a paso N+1. NO escala como PAUSE-wizard. Halt graceful.

### Step 6 — Transición según user_decision

| Decision | Acción |
|----------|--------|
| sí / continue | Procede a paso N+1 (solo si outcome = success) |
| pause | Halt graceful + reportar progreso |
| abort | Halt completo |
| (silencio) | Esperar — NO procede sin decisión explícita |

## CRÍTICO — D-020 distinction documentation

> [memory:decisions#D-020]: PAUSE-interno-delegado ≠ PAUSE-wizard.

Esta distinción es referenciable cross-wizards. Aplica a:

- **add-monetization** (este wizard): paso 1 add-payments puede tener PAUSE D-010 (empresa MoR Polar). Paso 2 add-emails puede tener PAUSE D-011 (on-prem SMTP). Wizard NO escala — propaga al usuario y resume-aware retoma.

- **Futuros wizards** (Phase 5+ o futuros add-* extensions): si componen sub-skills con PAUSE genuino interno, mismo manejo.

**¿Por qué esta distinción importa?**

Sin la distinción explícita, un agent podría razonar "add-payments es trinary (D-010), por lo tanto add-monetization es trinary (al wizard level)". Eso sería force-fit incorrecto:

- L-004 test al wizard level pregunta: "¿hay degenerate case que requiera upstream user action ESPECÍFICA DEL SELECTOR WIZARD (full chain vs partial)?". Respuesta: NO. El selector wizard es independiente del PAUSE de add-payments.
- El PAUSE de add-payments es interno al sub-skill — el usuario lo resuelve dentro del scope de add-payments (constituyendo empresa o cambiando provider). Cuando resuelve, add-monetization continúa normal.
- El selector wizard (full chain vs partial) NO requiere upstream user action. Ambos modos siempre disponibles.

D-020 codifica esta distinción para que cross-skill sea analítico, no force-fit.

## Reglas operativas (cross-pasos)

### 1. NO repetir setup decisions

Si add-payments definió `pricing_provider = stripe`, paso 2 (emails) hereda contexto pero NO re-decide payments. Cada sub-skill mantiene su scope.

### 2. Propagar contexto cuando aplica

```yaml
# Después de paso 1 (add-payments)
context_acumulado.payments_provider = "stripe"
context_acumulado.payments_pages = ["src/app/(marketing)/pricing/page.tsx", ...]

# Después de paso 2 (add-emails)
context_acumulado.emails_provider = "resend"
context_acumulado.emails_templates_dir = "emails/"

# Paso 3 (web-quality) puede usar payments_pages + emails_templates_dir
# como targets focused para audit
```

### 3. R4 strict

add-monetization MISMA NO invoca skills. Sub-agents son los que invocan add-payments/add-emails/web-quality.

### 4. R5 strict

Sub-agents NO escriben memory. Lessons/errors propagados a el-evaluador post-pipeline.

### 5. PAUSE-interno-delegado correctamente manejado

Documentado en step 5 + step 6 + D-020 distinction section. NO escalar como PAUSE-wizard.

### 6. web-quality graceful degradation

Si paso 3 web-quality no tiene URL/server → auto-degrada a static (D-015 binary). Wizard procede sin halt. Reporta al usuario que se usó modo static.

## Halt + handoff cuando paso falla

Si `step_result.outcome = failed`:

```markdown
❌ add-monetization — Paso {N} falló durante ejecución de {sub_skill}

**Context preservado:**
- Pasos completados: {1..N-1} ✅
- Paso {N} ❌
- Pasos pendientes: {N+1..3} ⬜

**Próximo paso (action requerida):**
{resume_instruction}

**Cuando termines:** re-invocá `/add-monetization` — resume-aware Fase 0
detectará progreso parcial y arrancará desde paso {N} o {N+1}.
```

## Edge cases

### Edge: paso 1 paused-internal (add-payments D-010)

→ Wizard reporta PAUSE-interno-delegado al usuario (formato del Step 5 paused-internal). Halt graceful. NO escala como PAUSE-wizard.

### Edge: paso 2 paused-internal (add-emails D-011 on-prem SMTP)

→ Mismo manejo. Reporta PAUSE-interno-delegado de add-emails. Halt graceful.

### Edge: paso 3 web-quality sin URL/server

→ web-quality auto-degrada a static. Reporta al usuario "usé modo static por falta de live target". Wizard procede sin halt.

### Edge: paso 1 success pero paso 2 add-emails reporta que no detecta payments_provider

→ Probablemente bug en propagación de context_acumulado. Halt + reportar al usuario para investigación. add-emails puede correr sin payments_provider (los templates de invoice/receipt son provider-agnostic en su core).

### Edge: usuario aborta mid-pipeline (paso 1 success, paso 2 sin arrancar)

→ Pipeline parcial guardado. Reportar: "1/3 completado. Re-invocá add-monetization para resumir."

### Edge: paso 1 success pero web-quality reporta NEEDS_FIX en audit final

→ web-quality reporta NEEDS_FIX como output. add-monetization handoff final reporta el gate como NEEDS_FIX. NO halt — el audit es informativo. Usuario decide si fixear ahora o post-deploy.

### Edge: usuario fuerza "solo payments" pero web-quality ya existe (audit.complete = true)

→ Modo partial respeta intención del usuario. Reporta: "Modo partial: solo paso 1. Audit existente preservado, NO se re-ejecuta."

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — wizard thin.
- [memory:CONSTRAINTS.md#R5] — sub-agents no memory.
- [memory:lessons#L-004] — binary D-020 informativo.
- [memory:decisions#D-020] — add-monetization binary + PAUSE-interno-delegado distinction.
- [memory:decisions#D-010] — add-payments PAUSE interno trinary (paso 1 puede emerger).
- [memory:decisions#D-011] — add-emails PAUSE interno trinary (paso 2 puede emerger).
- [memory:decisions#D-015] — web-quality binary live/static (paso 3 graceful degradation).

## Refusals

- ❌ Wizard MISMA invoca skills (R4 violation).
- ❌ Sub-agents escriben memory (R5).
- ❌ **Escalar PAUSE-interno-delegado al nivel wizard** (D-020 violation crítica).
- ❌ Force-fit trinary porque sub-skill es trinary (D-020 distinción).
- ❌ Continuar paso N+1 si paso N falló o paused-internal.
- ❌ Saltar confirmation entre pasos.
- ❌ Bypass de PREFLIGHT de sub-skills.
- ❌ Override decisiones cross-pasos.
