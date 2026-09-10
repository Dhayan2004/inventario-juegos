# Asset #9 — Security & Scalability Audit

> *"El código que no revisás es código que el atacante ya revisó."*

## Qué Hace

Antes de que el Blueprint cristalice las decisiones de arquitectura en un plan de ejecución, este asset hace una parada obligatoria: auditoría integral del producto desde cinco ángulos.

**Por qué va antes del Blueprint:** auditar después significa refactorizar sobre código ya comprometido. Auditar antes significa que el Blueprint nace limpio.

**Cinco ángulos de auditoría:**
1. **Seguridad clásica** — OWASP Top 10 2025, autenticación, secretos, headers, CORS.
2. **Riesgos Vibe Coding / IA** — VCAL, trazabilidad, dependencias, prompt exposure, prompt injection (L-002).
3. **Escalabilidad** — bottlenecks, queries N+1, paginación, caching, bundle size.
4. **Observabilidad** — logging estructurado, métricas, circuit breakers, rate limiting, health checks.
5. **Web Quality** — Performance + Core Web Vitals + Accessibility + SEO + Best Practices (handoff a `web-quality` skill).

**Handoff opcional a `el-guardian`:** Codex como segundo cerebro para audit adversarial (D3). Recomendado para todos los proyectos pre-deploy.

---

## Inputs Requeridos

- `src/` — todo el código fuente.
- `ONTOLOGY.md` — **`requisitos_seguridad` de la empresa (Fase −1), si existe** — el contrato propio.
- `SPEC.md` — **Sección 6 (Requisitos No Funcionales), Fase 0, si existe** — datos sensibles/hosting/SLAs.
- `TECH-SPEC-[nombre].md` — del asset 03. Stack, BaaS decision, dependencias.
- `PDR-[nombre].md` — del asset 02. Datos sensibles que maneja el producto.
- `package.json` — dependencias actuales (npm audit).
- `next.config.ts` — security headers.

---

## El contrato de seguridad de la empresa (atado a la ontología — el gate shift-left)

Esta auditoría **pre-Blueprint** es el tercer gate de la doctrina DevSecOps shift-left
(`CONSTRAINTS.md` § DevSecOps). Cruza dos fuentes:

1. **Catálogo genérico** — `threat-db.yaml` (77 amenazas OWASP-2025 + vibe-coding + golden-path).
2. **Contrato específico de la empresa** (si existe; degradación segura si no):
   - **`ONTOLOGY.md › requisitos_seguridad`** (Fase −1) — regulaciones, datos sensibles propios.
   - **`SPEC.md` Sección 6 (Requisitos No Funcionales)** (Fase 0) — datos sensibles, hosting/región, SLAs.

   Cada `requisito_seguridad` con `severidad: critico` no satisfecho en el diseño/código → hallazgo
   **Critical** que **bloquea el Blueprint** (asset 10), aunque la threat-db genérica no lo marque.

## Referencias

- `.claude/skills/la-herreria/references/threat-db.yaml` — **base de amenazas estructurada (77 entradas, ✅ portada en S1)**.
- `.claude/skills/la-herreria/references/security-checklist.md` — OWASP Top 10 2025 (deferred F-tighten).
- `.claude/skills/la-herreria/references/vibe-coding-risks.md` — VCAL + prompt injection L-002 (deferred F-tighten).
- `.claude/skills/la-herreria/references/scalability-patterns.md` — bottlenecks + caching (deferred F-tighten).
- `.claude/skills/la-herreria/references/observability-guide.md` — logging + métricas (deferred F-tighten).
- `.claude/skills/web-quality/SKILL.md` — Web Quality canónico.
- `.claude/skills/el-guardian/SKILL.md` — handoff opcional Codex (capa adversarial, 4 modos de ataque).
- `.claude/skills/project-auditor/SKILL.md` — `/temple`, el gate gemelo **pre-release** (full-project + score).

---

## Workflow

### Paso 1: Compilar Contexto

```
CONTEXTO DE AUDITORÍA — [Nombre del Proyecto]

PRODUCTO:
¿Qué hace? ¿Quién lo usa? ¿Qué datos sensibles maneja?
(De PDR: modelo de negocio, usuarios objetivo, datos sensibles)

STACK:
Framework: Next.js [versión]
Auth: Supabase Auth / Insforge Auth (D-009)
DB: Supabase PostgreSQL / Insforge Postgres
AI features: [sí/no — cuáles, subtipo del asset 04 routes/ai-feature.md]
External APIs: [lista de integraciones con citation R13]
Pagos: Stripe / Polar / N/A
Emails: Resend / SendGrid / N/A
Mobile: PWA / Native / N/A
(De Tech Spec: stack completo)

VCAL ESTIMADO (Vibe Coding AI Level):
¿Qué porcentaje del código fue AI-generated vs. human-written?
→ VCAL-[1-5] — [justificación]
Referencia: vibe-coding-risks.md

SUPERFICIE DE ATAQUE:
→ Endpoints de autenticación: [/api/auth/...]
→ Endpoints con datos de usuario: [/api/...]
→ Features con IA: [si existen — auditar prompt injection]
→ Integraciones de pago: [si existen — webhook signature verification]
→ Datos PII manejados: [email, nombre, ...?]
→ Tablas con RLS L-001: [¿cuáles? ¿todas las necesarias?]
→ Tools agentic destructivas R14: [delete*, send*, transfer*, cancel* — ¿con typed confirmation?]
```

---

### Paso 2: Auditoría de Seguridad App (OWASP Top 10 2025)

**Proceso:**

1. **OWASP Top 10 2025** — revisar cada categoría (A01–A10) contra threat-db.yaml.
2. **Autenticación y Autorización:**
   ```bash
   find src/app/api -name "route.ts" | head -30
   grep -r "supabase.auth.getUser\|createServerClient" src/app/api/
   ```
   - ¿Cada API route verifica la sesión server-side?
   - ¿El user ID viene de la sesión, no del body?
   - ¿Tablas con datos de usuario tienen RLS L-001?
3. **Secretos:**
   ```bash
   grep -r "sk-\|api_key\|apiKey\|API_KEY" src/ --include="*.ts" --include="*.tsx" | grep -v "process.env\|env\."
   grep -r "localStorage" src/ | grep -i "token\|auth\|session"
   ```
4. **Headers de Seguridad:**
   - ¿`next.config.ts` tiene security headers (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)?
5. **npm audit:**
   ```bash
   cd forja && npm audit --audit-level=high
   ```
6. **Extended Vibe Coding Security Checks (14 vectores):** CORS, redirects, storage buckets, webhooks, session, GDPR, uploads, audit log, etc.
7. **R14 destructive tools verification:**
   ```bash
   grep -rE "tool\(\{[^}]*execute:" src/ --include="*.ts" | grep -iE "delete|send|transfer|cancel|refund"
   ```
   - Si encuentra match → escalate como CRITICAL (R14 violation).

**Formato de hallazgo:**
```
SEC-[N] — [Título]
OWASP: A0X / Severidad: [Critical/High/Medium/Low] / CVSS: X / Evidencia: [archivo:línea]
Descripción: [qué es el problema]
Impacto: [qué puede hacer un atacante]
Recomendación: [fix específico]
```

---

### Paso 3: Auditoría Vibe Coding / IA (L-002 + L-003)

**Proceso:**

1. **Confirmar VCAL** basado en exploración del código.
2. **Trazabilidad:**
   ```bash
   git log --oneline | head -30
   git log --stat | head -50
   ```
   - ¿Commits descriptivos o genéricos?
   - ¿Commits con +500 líneas sin contexto?
3. **Control de Dependencias:**
   ```bash
   cd forja && npm audit
   ```
   - ¿Todas las deps tienen >10K descargas semanales en npm?
   - ¿Hay deps redundantes con el stack ya provee?
4. **Exposición de Prompts:**
   ```bash
   grep -r "SYSTEM_PROMPT\|systemPrompt\|system_prompt" src/ --include="*.ts"
   grep -r "sk-ant\|sk-proj\|openai\|anthropic" src/ --include="*.ts" | grep -v "process.env"
   ```
5. **Prompt Injection (L-002 indirect)** — solo si el producto tiene features de IA:
   - ¿Hay endpoints donde input de usuario llega a un LLM?
   - ¿Ese input está separado del system prompt o concatenado?
   - ¿Hay límites de longitud de input?
   - ¿Tools agentic (R14) tienen `execute()` automático en destructivas? — REJECT.
6. **Whitelist L-003:** Zod en boundaries (forms, API, webhooks)?

---

### Paso 4: Auditoría Escalabilidad

- Queries N+1 (revisar selects con joins).
- Paginación en listados.
- Caching strategy (Upstash Redis para session/rate limit; SWR para client).
- Bundle size (`npm run build` + analyze).
- DB indexing en campos filtrados.

---

### Paso 5: Auditoría Observabilidad

- Logging estructurado (no PII en logs).
- Métricas: latency, error rate, throughput.
- Circuit breakers en integraciones externas.
- Rate limiting en endpoints sensibles (auth, AI, webhook).
- Health checks (`/api/health`).
- Sentry o equivalente configurado.

---

### Paso 6: Web Quality (handoff a web-quality skill)

Invocar `web-quality` skill ([memory:skills#web-quality]) para auditoría Lighthouse + Core Web Vitals + Accessibility WCAG 2.1 AA + SEO + Best Practices.

Modo D-015 binary:
- **live audit** (default) — agent-browser CLI o Lighthouse.
- **static analysis** (fallback) — sin URL/server.

---

### Paso 7: Handoff opcional a el-guardian (D3)

```
Auditoría adversarial con Codex como segundo cerebro recomendada.

→ Invocar el-guardian para audit pre-deploy
→ Cubre: OWASP 2025 + vibe-coding risks + R14 destructives + RLS validation
→ Output: SECURITY-AUDIT-CODEX-[nombre].md complementario
```

Si el usuario rechaza, ejecutar solo el asset estándar. Si acepta, sintetizar ambos audits en el reporte final.

---

## Output Format

```markdown
# SECURITY-AUDIT-[nombre]

> Auditoría integral generada por la-herreria asset 09 · [fecha]

## Resumen Ejecutivo

| Ángulo | Hallazgos Critical | High | Medium | Low |
|--------|-------------------|------|--------|-----|
| Seguridad clásica (OWASP) | [N] | [N] | [N] | [N] |
| Vibe Coding / IA | [N] | [N] | [N] | [N] |
| Escalabilidad | [N] | [N] | [N] | [N] |
| Observabilidad | [N] | [N] | [N] | [N] |
| Web Quality (web-quality skill) | [N] | [N] | [N] | [N] |

**Veredicto:** ✅ PASS / ⚠️ NEEDS-FIX / ❌ BLOCKED

**Bloqueo crítico:** si hay ANY hallazgo Critical o High → NO avanzar al asset 10.

---

## Hallazgos por Categoría

### Seguridad Clásica
[Lista de hallazgos formato SEC-N]

### Vibe Coding / IA
[Lista de hallazgos formato VCR-N]

### Escalabilidad
[Lista de hallazgos formato SCAL-N]

### Observabilidad
[Lista de hallazgos formato OBS-N]

### Web Quality (output de web-quality skill)
[Resumen + paths a reportes detallados]

---

## R14 Destructive Tools Verification

[Lista de tools auditadas + status (typed confirmation OK / VIOLATION)]

---

## RLS Coverage (L-001 / L-005)

| Tabla | RLS habilitado | Policy correcta | Tenant-scoped (M6) | Notas |
|-------|---------------|-----------------|--------------------|-------|
| [tabla] | ✅/❌ | ✅/❌ | `organization_id` + `WITH CHECK` ✅/❌ / N/A | [...] |

**Si la app es multi-tenant (M6):** cruzar el modelo de amenazas cross-tenant de
[`.claude/references/MULTI_TENANCY.md`](../../../references/MULTI_TENANCY.md) §4 (T1–T9) y exigir el
**test negativo cross-tenant** con ≥2 tenants (R7 Layer 4) como criterio de release. Los 3 invariantes de
`[memory:lessons#L-005]` (R16) — `organization_id NOT NULL`, `WITH CHECK` en escrituras, cliente no
confiado — son **Critical** si faltan. Handoff a `el-guardian` (El Infiltrado) para la capa adversarial.

---

## Plan de Remediación

[Lista priorizada de fixes — Critical primero. Cada fix con: archivo, línea, fix sugerido, esfuerzo estimado.]

---

## Sources

[Citations R8/R13 si se usaron fuentes externas]

---

## Próximos Pasos

- ⬜ Resolver TODOS los Critical y High antes del asset 10 (Master Blueprint).
- ⬜ Re-correr auditoría tras fixes.
- ⬜ (Opcional) handoff a el-guardian para audit adversarial pre-deploy.
- ⬜ Web-quality completa post-implementación (`/web-quality` antes de `make deploy`).

```

---

## Reglas Críticas

- **El contrato de la empresa manda.** Un `requisito_seguridad: critico` de `ONTOLOGY.md` (o de la Sección 6 del SPEC) no satisfecho es Critical y bloquea, aunque la threat-db genérica no lo marque.
- **Critical/High bloquean el pipeline.** Sin resolverlos, asset 10 (Blueprint) NO se ejecuta.
- **R14 violations son automáticamente Critical.** `execute()` en tools destructivas → reject.
- **L-001 RLS coverage no opcional** en tablas con user_id.
- **L-002 prompt injection awareness** mandatory en features de IA.
- **L-003 whitelist Zod** en boundaries — sin esto, downgrade a Medium pero documentar.
- **Citation grammar R13** en hallazgos que citen libs externas: [docs:libname] o [web:dominio.com](url) + Sources.

---

*"El Blueprint nace limpio o nace comprometido. La auditoría decide cuál."*

---

## Paso final — Generar HTML

Después de guardar `SECURITY-AUDIT-{nombre}.md`, invocar:

→ `.claude/skills/la-herreria/prompts/render-doc-html.md`
  con `doc_type: SECURITY-AUDIT`, `project_name: {nombre}`

El badge del header se colorea según hallazgos extraídos del doc:
- Critical/High > 0 → rojo (`--accent-red`)
- Solo Medium/Low → amarillo (`--accent-yellow`)
- Audit clean → verde (`--accent-green`)

Output adicional: `SECURITY-AUDIT-{nombre}.html` (standalone, dark mode, navegable). Print-friendly para incluir en deliverables a stakeholders.

Reportar al usuario: "✅ SECURITY-AUDIT-{nombre}.md + SECURITY-AUDIT-{nombre}.html generados".
