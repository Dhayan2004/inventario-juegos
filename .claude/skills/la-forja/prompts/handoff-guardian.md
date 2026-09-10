# handoff-guardian

> Handoff condicional pre-deploy a `el-guardian`. Aplica SOLO si la-forja orquestó full pipeline incluyendo deploy step. Si la-forja orquestó solo build → handoff queda al humano para invocar `/despachar` (que internamente llama el-guardian).

## Cuándo aplica

la-forja invoca handoff-guardian SOLO si:

- el orchestration_summary incluye una fase de deploy (Coordinator pattern con fase final deploy, Fork pattern con commits que incluyen deploy config, Swarm con sub-task de deploy).
- Y `el-evaluador` ya retornó PASS de R7 three-layer (sin PASS, no hay deploy).
- Y `el-guardian` está registrado en skills.md (R6 validation).

Si la-forja orquestó solo build (sin deploy step en el Blueprint) → NO handoff-guardian. La invocación de el-guardian queda al humano via `/despachar`.

## Pre-handoff state

la-forja debe tener:

```yaml
post_evaluador_state:
  evaluator_verdict: PASS
  active_feature: <F?-S?>
  commit: <sha confirmado>
  feature_state: passing
  
  pipeline_includes_deploy: true   # condición para invocar handoff-guardian
  deploy_target: vercel | coolify | (otro)
  
  security_scope:
    - new_endpoints_added: [paths]
    - new_secrets_referenced: [env vars]
    - rls_policies_modified: [tables]
    - destructive_tools_added: [tool names]  # R14 audit
    - external_apis_integrated: [list]
```

## Handoff invocation

la-forja NO invoca el-guardian directamente (R4). Dispatcha un sub-agent con tool filter Auditor:

```
[Sub-agent dispatched by la-forja]
  Role: Auditor (pre-deploy)
  Tool filter:
    - Read · Grep
    - Skill: el-guardian
  System prompt:
    "Sos el auditor pre-deploy. Recibís post_evaluador_state adjunto.
     Invocá el-guardian con el security_scope + cita la-forja handoff.
     el-guardian correrá audit OWASP Top 10 + vibe-coding-specific
     risks + RLS verification + R14 audit. Reportá output a la-forja."
```

## el-guardian audit scope

el-guardian (Codex como segundo cerebro) valida:

| Categoría | Checks |
|-----------|--------|
| OWASP Top 10 2025 | injection, broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, XSS, insecure deserialization, vulnerable components, insufficient logging |
| Vibe-coding risks | prompt injection en LLM-bound inputs, secrets en transcripts, dependencias AI-suggested no auditadas |
| RLS Supabase | tabla con datos de usuario tiene RLS enabled + policy correcta (cita L-001) |
| R14 destructivas | toda `delete*`, `send*`, `transfer*`, `cancel*`, `deploy*` con typed confirmation, NO `execute()` automático |
| Headers HTTP | CSP, HSTS, X-Frame-Options, X-Content-Type-Options |
| PII handling | datos sensibles cifrados at-rest, mask en logs, retention policy |
| Webhook signatures | toda incoming webhook valida signature ANTES de DB ops |
| Service role isolation | service_role keys solo en admin paths server-side, jamás en client-bundled code |

Output del el-guardian: `SECURITY-AUDIT-<feature>.md` en repo + verdict CRITICAL/HIGH/MEDIUM/LOW por finding.

## Pass criteria

el-guardian PASS solo si **CERO** findings de severidad `critical` o `high`.

- Findings `medium` o `low` → reportados pero no bloquean deploy. la-forja decide con humano si attendéeren ahora o post-deploy.
- Override solo con `--skip-security` confirmado explícitamente por humano. Sin override, deploy bloqueado.

## Output canónico del handoff

el-guardian devuelve a la-forja:

```yaml
guardian_verdict:
  status: PASS | BLOCKED | NEEDS_REMEDIATION
  audit_path: SECURITY-AUDIT-<feature>.md
  findings:
    critical: []
    high: []
    medium:
      - id: M-001
        category: <OWASP|RLS|R14|...>
        finding: <descripción>
        recommendation: <fix sugerido>
        blocks_deploy: false
    low: [...]
  
  override_required: false  # true si hay critical/high y user pidió skip-security
```

## Si BLOCKED

la-forja NO permite deploy. Opciones:

1. **Re-orchestrate con remediación:** la-forja lanza mini-Swarm para aplicar las recomendaciones de el-guardian, luego re-handoff a el-evaluador (validar fix) → re-handoff a el-guardian (re-audit).
2. **Halt + reportar al humano:** si findings son estructurales, opciones para humano son refactor del Blueprint o aceptar riesgo con `--skip-security` (último recurso, requiere confirmation explícita).

NUNCA: ignorar findings critical/high y deployar (vibe-coding violation).

## Si PASS

la-forja:

1. Recibe el-guardian PASS + audit_path.
2. Devuelve control al humano para que ejecute deploy:

```markdown
## la-forja → deploy ready

✅ el-evaluador R7 three-layer: PASS
✅ el-guardian audit: PASS (cero critical/high)
   - Audit report: SECURITY-AUDIT-<feature>.md
   - Medium findings: N (no bloquean, considerar attendéer post-deploy)
   - Low findings: M

Listos para deploy. Ejecutá:
  /despachar <target>     # o el comando de deploy del proyecto

la-forja NO ejecuta deploy automáticamente — el deploy es operación destructiva
(R14 cubre infra deploys también) que requiere confirmation humana explícita.
```

la-forja MISMA NO ejecuta deploy. R14 + R4 — deploy es ejecución destructiva con efecto en sistema externo.

## R4/R5/R6/R14 enforcement

- R4: la-forja dispatcha sub-agent Auditor; el sub-agent invoca el-guardian. la-forja NO invoca el-guardian directo.
- R5: el-guardian es read-only para audit; reporta findings, no escribe a memory directamente. Si el-guardian descubre patrón recurrente cross-skill, reporta a la-forja → handoff a el-evaluador para promoción a `.claude/memory/*`.
- R6: sub-agent Auditor valida el-guardian existe en skills.md (defensive double-check).
- R14: deploy NUNCA es automático. Confirmation humana mandatory post-PASS.

## Edge cases

### Edge: el-guardian PASS pero el-evaluador retornó NEEDS_FIX antes

→ Inconsistencia. el-guardian no debería ejecutar si el-evaluador no validó. la-forja halt + reportar al humano. Posible bug en orchestration flow — investigar.

### Edge: el-guardian BLOCKED por finding RLS missing en tabla nueva (L-001 violation)

→ Re-orchestrate: mini-Swarm para añadir RLS policy + handle_new_user trigger según L-001 patrón. Re-handoff a el-evaluador (R7) → re-handoff a el-guardian.

### Edge: la-forja orquestó solo build (no deploy step) — handoff-guardian se omite

→ Output canónico:

```markdown
## la-forja → build ready

✅ el-evaluador R7: PASS
ℹ️  el-guardian audit NO invocado (la-forja orquestó solo build, no deploy).

Para auditar pre-deploy, invocá:
  /despachar <target>

que internamente correrá el-guardian + deploy.
```

### Edge: el-guardian no responde / Codex CLI down

→ Fallback definido en skills.md de el-guardian: "advertir + permitir deploy con `--skip-security` solo si usuario lo confirma explícitamente". la-forja transmite el fallback al humano + pide confirmation explícita.

### Edge: Override con `--skip-security` aprobado por humano

→ la-forja documenta el override en feature evidence + audit_path apunta a "skipped". Recordar al humano que el security debt queda registrado y debe atendérse en próxima iteración. NO la-forja oculta el skip — visible en feature_list.json evidence.

## Citation grammar

- [memory:CONSTRAINTS.md#R4] — la-forja MISMA NO invoca el-guardian directo.
- [memory:CONSTRAINTS.md#R5] — el-guardian es read-only para audit; promotion via el-evaluador.
- [memory:CONSTRAINTS.md#R6] — sub-agent Auditor valida el-guardian en skills.md.
- [memory:CONSTRAINTS.md#R14] — deploy es operación destructiva, confirmation humana mandatory.
- [memory:lessons#L-001] — RLS audit por el-guardian.
- [memory:lessons#L-002] — vibe-coding-specific prompt injection audit.
- [memory:lessons#L-003] — whitelist validation audit.

## Refusals

- ❌ la-forja MISMA invoca el-guardian (R4).
- ❌ Deploy automático post-PASS (R14 — confirmation humana mandatory).
- ❌ Skip de el-guardian si la-forja orquestó deploy (no shortcuts pre-deploy).
- ❌ Marcar PASS si findings critical/high sin override explícito del humano.
- ❌ Override silencioso de findings — todo skip queda visible en feature evidence.
- ❌ el-guardian escribe a `.claude/memory/*` (R5 — promotion via el-evaluador).
