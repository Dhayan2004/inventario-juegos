---
name: el-guardian
context: fork
agent: el-guardian
description: >
  Pre-deploy security auditor. Usa Codex como "segundo cerebro" (modelo
  distinto al que generó el código) para auditar adversarialmente la feature
  activa antes de `/despachar`, con 4 modos de ataque (El Intruso, El Caos, El
  Destructor, El Saboteador). Capa 0 = el contrato de seguridad de la empresa
  (ONTOLOGY.md requisitos_seguridad + SPEC Sección 6); Capa 1 = OWASP Top 10 2025
  cruzando threat-db.yaml (85 amenazas); Capa 2 = vibe-coding risks; Capa 3 =
  Forja gates. Produce SECURITY-AUDIT-<feature>.md con severidades. PASS solo si
  no hay critical/high. Es la capa adversarial `--deep` de /temple. Override solo
  con `--skip-security` confirmado explícitamente por el usuario.
tier: core
requires: Codex CLI instalado y configurado (codex-plugin-cc + codex-companion runtime)
fallback: advertir + permitir deploy con --skip-security solo si usuario lo confirma explícitamente
dependencies: []
---

# el-guardian

> *"El que generó el código no puede auditarlo. Trae otro cerebro."*
> — Forja D3 (Codex Security Auditor)

Skill de auditoría pre-deploy. Implementa el patrón "segundo cerebro" usando Codex (modelo OpenAI vía `codex-plugin-cc`) como reviewer independiente del código que Claude (Forja) generó. La diversidad de modelos es la defensa: lo que Claude no ve, Codex sí, y viceversa.

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿Codex CLI disponible? Probar `codex --version`. Si no → halt: "Codex CLI no disponible. Instalar codex-plugin-cc o usar fallback `el-evaluador` con --no-codex."
3. ¿Hay feature activa con código en src/**? Si no → halt: "el-guardian audita código. La feature activa no toca src/. Si querés audit de skill o config, usar `el-evaluador` con --security-only."
4. ¿Auditoría reciente válida (<48h, mismo commit)? Si sí → ofrecer reusar audit cache antes de re-correr.
```

## Activación

| Cuándo se invoca | Por quién |
|------------------|-----------|
| Antes de `/despachar` (deploy) | Coordinator / Carlos |
| Tras feature `passing` con cambios en `src/api/**` o `src/auth/**` | Coordinator |
| Antes de mergear a `main` features que tocan auth, payments, RLS, headers | Carlos |
| On-demand: "audita la feature actual" | Carlos |

NUNCA se invoca antes de que `el-evaluador` haya marcado `passing` (R7 — la verificación funcional precede la auditoría adversarial).

## Audit scope

### Capa 0 — Contrato de seguridad de la empresa (ontología/spec) — el gate shift-left

> **El diferenciador de Forge Enterprise.** Antes del catálogo genérico, el-guardian verifica el
> **contrato específico de esta empresa**, levantado en la Fase −1:

1. **`ONTOLOGY.md › requisitos_seguridad`** (si existe): por cada `requisito`, verificar que el código
   lo satisface. Un `requisito` con `severidad: critico` **no satisfecho** es un hallazgo `critical`
   automático — **aunque OWASP/threat-db no lo marquen** (es un requisito propio del negocio:
   regulación, dato sensible, residencia de datos).
2. **`SPEC.md` Sección 6 (Requisitos No Funcionales)** (si existe): datos sensibles, hosting/región,
   SLAs declarados → cada uno es un check.

Si no existe `ONTOLOGY.md`/`SPEC.md`, saltar esta capa (degradación segura) y anotar "sin contrato de
empresa — solo catálogo genérico (Capas 1-3)". Reportar cobertura: `requisitos_seguridad verificados: X/N`.
La threat-db (Capa 1) es el catálogo **genérico**; esta capa es lo **específico de la empresa**. Se cruzan.

### Capa 1 — OWASP Top 10 2025 (cruza `threat-db.yaml`)

> Fuente estructurada: [`la-herreria/references/threat-db.yaml`](../la-herreria/references/threat-db.yaml)
> (85 amenazas, 8 categorías: OWASP-2025 · vibe-coding · mcp-security · golden-path · infrastructure · blog-security-tips · data-privacy · **payments** PAY-001..008). Cruzar cada categoría; correr los
> `golden_path_check` con `automated: true` como grep sobre el target.

| # | Categoría | Qué chequea el-guardian |
|---|-----------|-------------------------|
| A01 | Broken Access Control | RLS policies de Supabase, route guards, role checks en server actions; **aislamiento cross-tenant si la app es multi-tenant (M6 — ver El Infiltrado)** |
| A02 | Cryptographic Failures | secrets hardcodeados, JWT mal firmado, HTTPS forzado, password hashing |
| A03 | Injection | SQL injection (uso de cliente Supabase), command injection (server actions con shell), prompt injection (LLM inputs) |
| A04 | Insecure Design | flujos con asunciones de trust no verificables, falta de rate limiting |
| A05 | Security Misconfig | headers (CSP, HSTS, X-Frame-Options), CORS abierto, debug en prod |
| A06 | Vulnerable Components | `npm audit` + comparar deps recientes vs CVE feed |
| A07 | Identity & Auth | session management, password reset flows, OAuth state, MFA hooks |
| A08 | Data Integrity | client-supplied IDs sin verificar ownership, integrity checks en uploads |
| A09 | Logging & Monitoring | logs con PII, falta de audit trail en operaciones críticas |
| A10 | SSRF | fetches con URL controlada por user, redirect open, webhooks sin allowlist |

### Capa 2 — Vibe-coding-specific risks

Estos no están en OWASP estándar pero son donde Forja se quema más:

| Riesgo | Qué chequea |
|--------|-------------|
| **Prompt injection** | inputs de usuario que llegan a `system` prompts, RAG sin sanitización |
| **Secrets en transcripts** | `console.log(env.SECRET_KEY)`, traces que persisten secretos, error messages que leak credentials |
| **Dependencias AI-suggested** | paquetes recientes con typosquatting, deps fantasma sugeridas por el LLM que no existen en npm registry |
| **Trazabilidad de cambios LLM-driven** | commits sin diff comprensible, archivos cambiados sin razón obvia |
| **Deuda AI** | TODO/FIXME generados que nunca se cierran, código duplicado entre features |
| **Supply chain in MCP** | servers MCP en `example.mcp.json` sin justificar, tool sprawl ([memory:errors#AP4]) |

### Capa 3 — Forja-specific gates

| Gate | Qué chequea |
|------|-------------|
| Brand DNA leak | tokens hardcoded fuera de `brand.css` (R10) |
| RLS coverage | toda tabla en Supabase con `enable_rls = true` (D10) |
| **Payments** (D-038) | si hay pagos: `payments-gate.sh` limpio (PAY-001..008) · ledger `0003_payments_ledger.sql` aplicado (dedup + idempotencia) · Layer 3 `tests/payments/webhook-*.test.mjs` verde (el handler RECHAZA forjado/replay/secret incorrecto) · sin llaves live en el repo (R15: `APP_USR-`, `sk_live_`, `lmnsq_live_`, `prv_prod_`) · rails irreversibles con `refundable = false`. Critical si falta firma/dedup o la firma usa la API key; High el resto. |
| **Tenant isolation** (M6) | si la app es multi-tenant: toda tabla tenant-scoped con `organization_id NOT NULL` + RLS por membresía + `WITH CHECK` en escrituras; `service_role` ausente del bundle cliente; `security definer` que toca datos de tenant filtra por `auth_org_ids()`. Los 3 invariantes de `[memory:CONSTRAINTS.md#R16]`. Un `requisito_seguridad: critico` de residencia/aislamiento por cliente no satisfecho = Critical (Capa 0). |
| Migration rollback | `el-migrador` produjo migration con `down` válido |
| Active feature WIP=1 | no hay >1 feature `active` en `feature_list.json` (R1) |
| Citation grammar | claims externos con `[web:...]` y `## Sources` (R8) |

## Adversarial review protocol — Codex como segundo cerebro

el-guardian invoca Codex con un prompt diseñado para encontrar lo que un Claude generador no vería.

### Los modos de ataque (personas adversariales)

El prompt al segundo cerebro adopta **4 lentes de ataque** portadas del `/adversarial-review` de
Forge Pro (los "4 agentes atacantes"), **más El Infiltrado** (5º lente, net-new de M6, sólo en apps
multi-tenant). Cada lente es un ángulo distinto; la diversidad de ángulos es la defensa. En `--quick`
corre solo El Intruso; en modo completo, los 4 (+ El Infiltrado si la app es multi-tenant, + El Cobrador si el proyecto tiene `subscriptions`/`payments` o `src/app/api/webhooks/**` — también en brownfield vía `migration-wizard`):

| Modo | Rol | Busca |
|------|-----|-------|
| **El Intruso** | Pentester senior | OWASP Top 10, injection, auth bypass, IDOR, secrets (cruza Capa 0 + threat-db) |
| **El Caos** | Chaos engineer | race conditions, cascadas, memory leaks, consistencia, fallos parciales |
| **El Destructor** | QA adversarial | boundary values, unicode, prototype pollution, fechas, overflow |
| **El Saboteador** | Usuario malicioso | doble-click, back button, sesiones expiradas, offline, replay |
| **El Infiltrado** (M6) | Usuario autenticado del tenant A | leak cross-tenant: tabla sin `organization_id`, policy sin `WITH CHECK`, `organization_id` del body confiado (IDOR), `security definer` que bypassa tenant, join/agregado cross-tenant, `service_role` en cliente |
| **El Cobrador** (D-038) | Usuario/atacante que quiere cobrar sin pagar o cobrar de más | webhook sin firma o firmado con la API key · body parseado antes de verificar · `===` en la firma · replay sin ventana ni dedup · idempotency con `Math.random()` · `amount * 100` en CLP/JPY · monto del cliente · refund por API en OXXO/SPEI/Pix. **Corre `bash .claude/skills/add-payments/tests/payments-gate.sh src/`** (= PAY-001..008 del threat-db, razón exacta por finding) + gates 0–10 de `add-payments/prompts/handoff-el-guardian.md` |

> Cada modo reporta sus hallazgos con la misma gramática (archivo:línea + categoría + severity). El
> Intruso es el único obligatorio (cubre el contrato + OWASP); El Caos/Destructor/Saboteador amplían la
> superficie. **El Infiltrado corre sólo si la app es multi-tenant** (degradación segura) y cruza el
> modelo de amenazas de [`references/MULTI_TENANCY.md`](../../references/MULTI_TENANCY.md) §4 (T1–T9).

### Llamada estándar

```bash
# Vía codex-plugin-cc slash command
/codex:adversarial-review <ruta-feature>
```

O via runtime directo:

```bash
codex review --mode adversarial \
  --target "src/<feature-path>/**" \
  --rubric "OWASP-2025 + Vibe-Coding + Forja-gates" \
  --output "SECURITY-AUDIT-<feature>.md"
```

### Adversarial prompt pattern

El prompt al second-cerebrum debe contener:

1. **Hipótesis de attacker:** "Asume que el atacante es un usuario autenticado que conoce internals de la app y quiere escalar privilegios / leak data / DOSear / inyectar."
2. **Contraste con el generador:** "Identifica suposiciones no verificadas que el agente que generó este código probablemente hizo (ej: 'asumió que `req.body.user_id` viene del session, pero llega del cliente')."
3. **Citaciones obligatorias:** cada finding cita archivo:línea + categoría OWASP/Vibe + severity.
4. **No fix patches:** Codex NO debe proponer el patch (queda para el-yunque o la-forja). Solo identifica.

## Severity classification

| Nivel | Definición | Bloquea deploy |
|-------|-----------|----------------|
| **critical** | exploit posible sin auth, sin user interaction, leak de PII a internet o RCE | ✅ siempre |
| **high** | exploit con auth o user interaction, leak interno, escalation | ✅ siempre |
| **medium** | misconfig que aumenta superficie pero no inmediatamente explotable | ❌ (warning) |
| **low** | hardening recomendado, defensa en profundidad | ❌ (info) |

PASS criteria: **0 critical AND 0 high**. Medium/low son warnings no bloqueantes pero deben registrarse en `SECURITY-AUDIT-<feature>.md`.

## Output format — `SECURITY-AUDIT-<feature>.md`

> Al entregar el reporte al humano, anteponer el **Cierre Ejecutivo**
> ([`COMMUNICATION.md`](../../references/COMMUNICATION.md)): qué significa el veredicto en lenguaje
> de negocio, qué bloquea el deploy y qué decisión toca — cada hallazgo técnico inevitable con su
> consecuencia en la misma frase ("falta WITH CHECK → un usuario podría darse permisos que no le tocan").

```markdown
# Security Audit — <feature-name>

**Date:** YYYY-MM-DD
**Auditor:** el-guardian (Forja) + Codex (codex-plugin-cc)
**Feature:** F2-SN
**Commit audited:** <sha>
**Verdict:** PASS | FAIL

## Summary

- Critical: N
- High: N
- Medium: N
- Low: N

## Findings

### F-001 — <title> · severity: <level>

**Category:** OWASP-A03 (Injection) | Vibe-Coding (Prompt Injection) | Forja-gate (RLS)
**Location:** `src/api/users/route.ts:42-58`
**Description:** <qué pasa, por qué es exploitable>
**Attack vector:** <secuencia para reproducir>
**Recommendation:** <a alto nivel — qué fix corresponde, NO el patch>
**References:** [web:owasp.org](url) · [memory:lessons#L-007]

---

### F-002 — …

## Mitigations not yet applied

(carry-over de auditorías previas que aún no se atendieron)

## Sources
- [web:owasp.org/Top10/2025](url)
- [web:supabase.com/docs/security](url)
- [memory:references#R-NNN]
```

Tras producir el archivo:

1. Escribir a `docs/security/SECURITY-AUDIT-<feature>.md`.
2. Pedir a `el-evaluador` que registre los findings nuevos en `errors.md` (E-NNN) con `Status: open`.
3. Devolver verdict al orchestrator.

## Override

Si el usuario solicita explícitamente `--skip-security` para un deploy:

```
⚠️  el-guardian: skip-security request

Findings actuales:
- critical: N
- high: N

Continuar SIN auditoría es responsabilidad tuya. Confirma escribiendo:

  CONFIRMO_SKIP_SECURITY <reason>

Esta confirmación se registra en `errors.md` (E-NNN) y queda asociada al
deploy. Si después hay incident, este registro es la trazabilidad.
```

Si el usuario no confirma con la frase exacta → halt. Si confirma → `el-evaluador` escribe E-NNN con la razón y el commit del deploy.

## Refusals (lo que NUNCA hace)

- ❌ Editar código de aplicación. Solo audita y produce el doc.
- ❌ Aplicar fixes — eso es tarea del skill `la-forja` (modo paralelo) o del prompt `.claude/prompts/el-yunque.md` (modo manual, NO skill registry) con el doc como input.
- ❌ Bypass del gate por presión de tiempo. El override existe pero requiere confirmación explícita y queda en log.
- ❌ Ejecutar Codex sin el target acotado a la feature activa (evitar audit completo del repo cada vez).
- ❌ Cachear findings stale: si el commit cambió, re-audita.

## Tool filter

**Estructural (runtime-enforced) desde `[memory:decisions#D-033]`.** La ejecución forkeada corre con el
subagente [`agents/el-guardian.md`](../../agents/el-guardian.md) (frontmatter `agent: el-guardian`), cuyo
`tools:` es whitelist dura del runtime: Read · Grep · Glob · Bash (Codex CLI, `npm audit`, supabase CLI
lectura) · Write (solo `docs/security/SECURITY-AUDIT-*.md`) · Skill (`/codex:adversarial-review` +
handoff a `el-evaluador`).

**`Edit` no existe en este contexto** — el auditor no puede editar lo que audita (AP3 por construcción:
el runtime rechaza la llamada con "No such tool available", no es promesa del prompt). El filtro es
grueso (tool sí/no): el path-scope del Write (solo el reporte; NO `src/**` ni `scripts/**`) sigue siendo
regla de prompt. Doctrina: [`references/SUBAGENT_TOOL_FILTERS.md`](../../references/SUBAGENT_TOOL_FILTERS.md).

## Loop de ejecución

```
0. PREFLIGHT halt (sección PREFLIGHT)
1. Read feature_list.json → identificar feature activa + commit hash
2. Construir target glob: src/<feature-paths>/**
3. Layer 0 — Contrato de empresa (ontología/spec)
   a. Si existe ONTOLOGY.md → por cada requisitos_seguridad[], verificar satisfacción en el target
   b. Si existe SPEC.md → cruzar Sección 6 (No Funcionales)
   c. requisito critico no satisfecho → finding critical automático
3.5. Layer 1 — OWASP scan (cruza threat-db.yaml)
   a. Run codex:adversarial-review --rubric "OWASP-2025 + threat-db" --target <glob> (4 modos de ataque)
   b. Parse output → findings array
4. Layer 2 — Vibe-coding scan
   a. Run codex:adversarial-review --rubric Vibe-Coding --target <glob>
   b. Parse output → findings array
5. Layer 3 — Forja gates
   a. Brand DNA leak grep
   b. RLS coverage check vía supabase CLI
   b'. Si multi-tenant (M6) → correr El Infiltrado: verificar los 3 invariantes de tenant (R16) en las migrations + que el test negativo cross-tenant (R7 Layer 4) exista y pase
   c. WIP=1 check en feature_list.json
   d. Citation grammar lint
6. Combinar findings + classify by severity
7. Write SECURITY-AUDIT-<feature>.md
8. Si critical>0 OR high>0:
   a. Verdict: FAIL
   b. Devolver al generador (skill `la-forja` o prompt `.claude/prompts/el-yunque.md`) con doc + lista priorizada
9. Si critical=0 AND high=0:
   a. Verdict: PASS (con warnings si medium/low > 0)
   b. Pedir a el-evaluador → marcar feature ready-to-deploy
   c. Liberar gate de /despachar
```

## Integraciones

- **`el-evaluador`** (R5): registra findings novel en `errors.md` y promueve patrones recurrentes.
- **`el-migrador`** (D10): comparte auditoría sobre RLS antes de aplicar migrations en producción. En apps multi-tenant (M6) cruzan los 3 invariantes de aislamiento (`[memory:lessons#L-005]` / R16) y el test negativo cross-tenant (R7 Layer 4). Doctrina: [`references/MULTI_TENANCY.md`](../../references/MULTI_TENANCY.md).
- **`la-herreria`** Fase 9: `el-guardian` puede invocarse como handoff opcional desde el security audit asset (que usa la misma `threat-db.yaml` + contrato de empresa).
- **`project-auditor` / `/temple`**: `el-guardian` ES la capa adversarial `--deep` del audit full-project (pre-release). Mientras `/temple` barre TODO `src/`, `el-guardian` profundiza adversarialmente con Codex.
- **`el-ontologo` / `el-entrevistador`**: producen el contrato (Capa 0) que `el-guardian` consume — `requisitos_seguridad` (ONTOLOGY.md) y Sección 6 (SPEC.md).
- **`/despachar`**: comando de deploy lee el verdict de `el-guardian` antes de proceder.

---

*"Diferentes modelos ven diferentes errores. La diversidad es la defensa."*
