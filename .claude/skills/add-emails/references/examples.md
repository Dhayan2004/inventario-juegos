# Examples — Three Scenarios

## Example 1 — SaaS LATAM (RESEND)

### Operador
- Empresa: Forja MX SAS (mismo del add-payments Example 1)
- Producto: SaaS de automatización
- Audiencia: México/Colombia/Argentina (LATAM)
- Volumen esperado: ~5K emails/mes (welcome + reset + invoices de Stripe)
- Compliance: ninguno estricto

### Decision tree path

```
P1: Data sovereignty? NO → P2
P2: Compliance corporativo? NO → P4
P4: Setup speed + DX prioritario? SÍ → RESEND
```

**1 hop, no PAUSE.**

### Tech Spec

```markdown
## Emails Decision

**Provider:** resend
**Rationale:**
- Compliance: none strict
- Volumen esperado: ~5K/mes
- Setup speed: prioritario (lanzando en 2 semanas)
- DX: React Email integration (Vercel-first stack ya en uso)
- Ecosystem: Vercel + Next.js + Supabase

**Decision tree path:** P1 → P2 → P4
**Source:** add-emails/prompts/decision-tree.md
**Cita:** [memory:decisions#D-010] · [memory:decisions#D-011]
**Assumed default:** false (signal explícito de DX prioritario)
```

### Output

```bash
/add-emails
# Mode A — Resend
# 18 archivos generados
# 7 templates con voice.json CTAs LATAM-friendly:
#   "Empezá ahora", "Iniciar sesión", "Cambiar contraseña",
#   "Ver recibo", "Actualizar método de pago", "Compartir feedback",
#   "Confirmar email"
# avoid_words audit PASS
# Brand contract per template (R10): ≥75 los 7
# Security 8-check PASS
# Manual gates: SPF/DKIM/DMARC + Resend webhook URL
# el-guardian PASS (0 critical, 0 high)
```

## Example 2 — Healthcare Compliance (SENDGRID)

### Operador
- Empresa: HealthTech Inc (US, BAA con SendGrid required)
- Producto: telemedicina platform
- Audiencia: pacientes US + Canada
- Volumen: ~150K emails/mes (appointment reminders + lab results notifications)
- Compliance: HIPAA con BAA cloud-hosted aceptable, SOC 2 mandatorio

### Decision tree path

```
P1: Data sovereignty / on-prem mandatory? NO (HIPAA BAA cloud OK) → P2
P2: Compliance corporativo cloud-OK? SÍ (HIPAA + SOC 2) → P3
P3: Volumen + features compliance?
   - >100K/mes ✓
   - Multi-tenant (per-clinic subusers) ✓
   - Suppression list robusta ✓
   - HIPAA BAA mandatory ✓
   → SENDGRID
```

**3 hops, no PAUSE.**

### Output

```bash
/add-emails
# Mode B — SendGrid
# 18 archivos generados (mirror Mode A con shape SendGrid)
# 7 React Email templates exportados a HTML
# Pipeline: tsx → npx react-email export → upload SendGrid dashboard
# 7 SENDGRID_TEMPLATE_ID_* en .env.local
# ECDSA webhook signature
# Suppression groups configured
# asm.groupId = SENDGRID_UNSUBSCRIBE_GROUP_ID
# trackingSettings: openTracking disabled (HIPAA privacy)
# Manual gates: HIPAA BAA signed + SOC 2 audit refresh + SPF/DKIM/DMARC
# el-guardian PASS — pero con notas medium severity:
#   - openTracking disabled (correcto)
#   - clickTracking habilitado: verificar con compliance que está OK
#     bajo HIPAA (link tracking puede leak metadata)
```

## Example 3 — Banking Argentina (PAUSE)

### Operador
- Empresa: Banco Digital SA (Argentina)
- Producto: home banking app
- Audiencia: Argentina only
- Volumen: ~500K emails/mes (statements, alerts, OTPs)
- Compliance: BCRA Comunicación A 7724 — datos de clientes en territorio nacional argentino

### Decision tree path

```
P1: Data sovereignty mandatory?
    SÍ — BCRA exige que datos personales de clientes bancarios
    estén en infrastructure dentro de jurisdicción argentina.
    Resend (US-based) y SendGrid (US Twilio) NO cumplen.
    → PAUSE (Mode C)
```

**1 hop a PAUSE.**

### Output

```bash
/add-emails
# Mode C — PAUSE
# NO se generan archivos.
# Output recomendación:
```

```markdown
## add-emails PAUSE — Data Sovereignty (BCRA)

Tu jurisdicción (Argentina, BCRA Comunicación A 7724) requiere
SMTP self-hosted o provider con presencia en territorio nacional.
Resend (US) y SendGrid (Twilio US) NO cumplen.

**Recomendación de stack:**

### Opción primaria — Mailcow self-hosted en VPS argentino
- VPS en Cloudia / Donweb / hosting en Argentina
- Mailcow Docker stack
- DNS apuntando a tu IP argentino
- TLS/STARTTLS obligatorio (BCRA requirement implícito)

### Opción secundaria — Provider con BCRA registry
- Verificar listado actualizado de proveedores cloud autorizados
  por BCRA. (Algunos: BlueOcean Cloud Argentina, etc.)
- Si el provider tiene certificación BCRA, evaluá si soporta
  SMTP/transactional templates a la altura de Resend/SendGrid.

### NO recomendado
- Resend / SendGrid: NO cumplen sovereignty
- Mailgun: same
- AWS SES region us-east-1: NO cumple. Hay AWS region São Paulo
  pero sigue siendo cross-border desde perspectiva BCRA.

Después de resolver infra, re-corré /add-emails con
TECH-SPEC declarando `emails.provider = self_hosted` y
agregar config files para tu SMTP local.

**No procede add-emails Mode A/B** hasta resolver infra.
```

## Diferencias visibles

| Aspecto | Example 1 (Resend MX) | Example 2 (SendGrid HIPAA) | Example 3 (PAUSE BCRA) |
|---------|----------------------|----------------------------|------------------------|
| Decision tree path | P1→P2→P4 (1 hop happy) | P1→P2→P3 (3 hops) | P1 → PAUSE (1 hop bloqueado) |
| Tech Spec required? | recomendado | mandatory (HIPAA BAA + SOC 2) | mandatory (data sovereignty flag) |
| Files generados | 18 | 18 | 0 (recomendación only) |
| Compliance certs | n/a | HIPAA + SOC 2 + GDPR | BCRA self-hosted |
| Setup time típico | ~10 min + DNS propagation | ~1h + dashboard config + IP warmup | semanas (constituir infra) |
| Tracking enabled? | sí (default + disclosure) | clickTracking sí, openTracking no | n/a |
| Webhook signature | HMAC (Svix) | ECDSA | n/a |
| Brand Score promedio | 87 | 84 (más conservador con tracking) | n/a |

## Cross-skill applicability del PAUSE pattern

D-010 PAUSE: "constituir empresa antes de continuar" (legal entity).
D-011 PAUSE: "constituir infrastructure antes de continuar" (SMTP self-hosted).

Generalización: PAUSE is valid output cuando el degenerate case requiere **acción upstream del usuario** que el skill NO puede automatizar. El skill recomienda + bloquea, no fuerza un path no saludable.

F3-S6 (add-mobile) podría heredar este pattern si emerge un caso degenerate (ej: jurisdicción que prohibe push notifications a menores sin parental consent flow). Por ahora, presunción es que no hay PAUSE en mobile — se evaluará en F3-S6 build.

## Citations

- [memory:decisions#D-010] (PAUSE pattern precedente)
- [memory:decisions#D-011] (compliance/sovereignty axis)
- [memory:CONSTRAINTS.md#R10..14]
- [memory:lessons#L-001..3]
