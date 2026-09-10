> Cita transversal: [memory:lessons#L-004] (test diagnóstico binario-vs-trinario para el patrón "default friction-reducer + override explícito"). add-emails es **trinario** porque PAUSE = constituir SMTP self-hosted satisface el test: existe degenerate case que requiere acción upstream del usuario antes de re-invocar el skill productivamente.

# add-emails — Decision Tree (Resend / SendGrid / PAUSE)

> Cita: [memory:decisions#D-010] (pattern "default + override + PAUSE" precedente)
> Cita: [memory:decisions#D-011] (compliance vs ecosystem axis específico de add-emails)
> Cita: [memory:CONSTRAINTS.md#R13] (find-docs antes de generar contra cualquier SDK)

## Cuándo correr este árbol

Antes de elegir Mode A (Resend), Mode B (SendGrid) o Mode C (PAUSE) en `add-emails`. Si Tech Spec del proyecto declara `emails.provider` explícito, este árbol es informativo. Si Tech Spec NO declara, este árbol decide y se loggea `assumed_default` flag.

A diferencia de `add-payments` (donde el axis principal es legal entity + tax handling), acá el axis principal es **compliance vs ecosystem maturity vs data sovereignty**. La extensión D-011 captura ese cambio.

## Pregunta 1 — Compliance / regulatory requirements

```
¿El proyecto opera en jurisdicción o industria con requirements
de data sovereignty / on-prem mandatory?

Casos típicos:
- Banking en Argentina (BCRA Comunicación A 7724 — datos en territorio)
- Banking en México (CNBV/Banxico circular única)
- Healthcare con HIPAA + cliente exige BAA on-prem (no cloud)
- Government con air-gapped network o classified data
- UE strict GDPR + AEPD que rechaza processors fuera EEA

├─ SÍ → PAUSE (Mode C) — recomendar SMTP self-hosted
│        NO generar archivos. Recomendación stack:
│        · Postfix + Dovecot (SMTP server clásico)
│        · Mailcow (Postfix + Rspamd + SOGo, Docker)
│        · Listmonk (newsletters self-hosted)
│        · Haraka / Halon (SMTP enterprise performance)
│        Usuario evalúa setup + re-corre add-emails post-infra.
│
└─ NO → seguir a Pregunta 2
```

## Pregunta 2 — Compliance corporativo (no-sovereignty)

```
¿Empresa requiere compliance certificado pero CON cloud aceptable?

- SOC 2 Type II audited
- HIPAA con BAA (Business Associate Agreement) cloud-hosted
- GDPR estándar (no AEPD strict)
- ISO 27001 certified provider
- PCI-DSS cuando emails contienen receipts con últimos 4 dígitos

├─ SÍ → seguir a Pregunta 3 (probablemente SendGrid)
└─ NO → seguir a Pregunta 4 (probablemente Resend)
```

## Pregunta 3 — Volumen + features compliance

```
¿Necesita ALGUNO de estos?
- Volumen >100K emails/mes
- IPs dedicadas (warming + reputation gestionada)
- Multi-tenant emailing (varios clientes desde una infra)
- Suppression list robusta + dunning workflow
- Subuser API (delegate sub-accounts)
- Email validation API + advanced sender authentication
- Soporte enterprise + SLA 24/7

├─ SÍ → SENDGRID (override por compliance + scaling)
└─ NO ('compliance pero volumen bajo') → considerar Resend SOC 2
        (Resend obtuvo SOC 2 Type II en 2024). Si BAA HIPAA mandatory
        → SendGrid; si solo SOC 2 → Resend acceptable.
```

## Pregunta 4 — Setup speed + DX

```
¿El proyecto prioriza?
- Setup en <10 min (no >30 min de SendGrid config)
- React Email components (templates como JSX/TSX)
- Free tier amplio para validar (Resend: 3,000/mes vs
  SendGrid: 100/día primer 30 días, luego paid)
- Developer DX (logs en dashboard, replay events)

├─ SÍ → RESEND (default fuerte)
└─ NO → seguir a Pregunta 5
```

## Pregunta 5 — Volumen actual + crecimiento

```
¿Volumen esperado los próximos 6 meses?

- <10K/mes  → RESEND (free tier cubre, paid amplio hasta 50K)
- 10-50K/mes → RESEND (paid plan ergonómico)
- 50-100K/mes → RESEND si DX > scale, SendGrid si scale > DX
- >100K/mes → SENDGRID (IPs dedicadas + dunning robusto)
```

## Pregunta 6 — Ecosystem + audience

```
¿Audiencia / equipo prefiere?

- LATAM/global con docs en inglés y community Discord/forum
  → ambos OK
- Equipo Vercel-first stack (Next.js + Vercel + Supabase) que
  valora "fits like a glove"
  → RESEND (Vercel adquirió Resend en términos no oficiales pero
    integra naturalmente; React Email es proyecto Vercel-aligned)
- Equipo Java/.NET legacy migrating a SaaS
  → SENDGRID (más años en el mercado, Java/Python SDKs maduros)
- Standalone single SaaS sin multi-cliente
  → cualquiera; RESEND si no hay otro signal
```

## Tabla resumen

| Compliance | Volumen | Setup speed | DX | Decision |
|-----------|---------|-------------|----|----------|
| Data sovereignty mandatory | Cualquiera | N/A | N/A | **PAUSE** (Mode C) |
| HIPAA BAA on-prem mandatory | Cualquiera | N/A | N/A | **PAUSE** (Mode C) |
| SOC 2 + cloud OK | <50K/mes | Speed prioritario | React Email | RESEND |
| SOC 2 + cloud OK | <50K/mes | No prioritario | Java/.NET | SENDGRID |
| HIPAA con BAA cloud | Cualquiera | N/A | N/A | SENDGRID |
| GDPR estándar | Cualquiera | Speed prioritario | React Email | RESEND |
| Sin compliance estricto | <50K | Cualquiera | Cualquiera | RESEND (default) |
| Sin compliance estricto | 50-100K | Speed | DX | RESEND |
| Sin compliance estricto | 50-100K | Scale | Robust | SENDGRID |
| Sin compliance estricto | >100K | N/A | N/A | SENDGRID |
| Multi-tenant (varios clientes) | Cualquiera | N/A | N/A | SENDGRID |

## Default cuando ambiguo o sin Tech Spec

**RESEND.** Loggear `assumed_default = true`. Rationale: cita [memory:decisions#D-010] (pattern friction reduction) + [memory:decisions#D-011] (cuando no hay compliance/scaling signal explícito, ecosystem maturity gana via React Email DX). Si re-evaluación con Tech Spec actualizado señala SendGrid o PAUSE, add-emails re-corre.

## Outputs del árbol

El árbol produce uno de tres resultados:

```
1. RESEND   → Mode A (templates/resend/**)
2. SENDGRID → Mode B (templates/sendgrid/**)
3. PAUSE    → halt + recomendación stack on-prem
              (ver "Recomendación PAUSE" abajo)
```

Resultado se documenta en TECH-SPEC-<nombre>.md sección "Emails Decision":

```markdown
## Emails Decision

**Provider:** resend | sendgrid | none (PAUSE)
**Rationale:**
- Compliance: <data sovereignty | SOC 2 cloud | HIPAA BAA | none>
- Volumen esperado: <<10K | 10-50K | 50-100K | >100K> per month
- Setup speed: <prioritario | no>
- DX preference: <React Email | dynamic templates | otro>
- Ecosystem: <Vercel-first | Java/.NET | standalone>

**Decision tree path:** P1 → P2 → ...
**Source:** add-emails/prompts/decision-tree.md
**Cita:** [memory:decisions#D-010] · [memory:decisions#D-011]
**Assumed default:** false | true
```

## Recomendación PAUSE (Mode C output)

Cuando el árbol devuelve PAUSE, add-emails imprime:

```markdown
## add-emails PAUSE — Data Sovereignty

**Outcome:** add-emails NO genera archivos. Tu jurisdicción o
industria requiere SMTP self-hosted (no cloud SaaS).

**Reason:** <P1 trigger específico>

**Recomendación de stack:**

### Opción A — Postfix + Dovecot (clásico, control total)
- Postfix (SMTP) + Dovecot (IMAP) + OpenDKIM (DKIM signing)
- SPF/DKIM/DMARC vía DNS de tu dominio
- Setup: 4-8h primer-time. Mantenimiento: ongoing (security patches,
  DNS rotations, blacklist monitoring).
- Mejor para: equipos con SRE in-house.

### Opción B — Mailcow (Docker, all-in-one)
- Postfix + Dovecot + Rspamd + SOGo + nginx + Redis en Docker Compose
- UI de admin built-in (gestión de usuarios, dominios, aliases)
- Setup: 1-2h con Docker. Mantenimiento: tags de upgrade.
- Mejor para: orgs medianas con devops capacity.

### Opción C — Listmonk (solo newsletters)
- Self-hosted newsletter manager (Go single binary)
- NO SMTP server — necesita uno externo (puede ser Postfix on-prem)
- Mejor para: solo newsletters/marketing emails, no transaccionales.

### Opción D — Enterprise (Haraka / Halon)
- Haraka (Node.js SMTP server, plugin-based)
- Halon (commercial, performance enterprise tuning)
- Mejor para: orgs con throughput >1M/día.

**Después de constituir infra:** re-corré `/add-emails` con Tech
Spec actualizado declarando `emails.provider = self_hosted` para
que add-emails genere config files apuntando a tu SMTP local
(en lugar de Resend/SendGrid). NO se generan templates en Mode C
inicial — esos vienen post-infra.

**No procede add-emails Mode A/B** hasta resolver infra.
```

## Refusals del árbol

- ❌ Force-fit a Resend o SendGrid cuando data sovereignty PAUSE aplica. Recomendación PAUSE es output válido, no fallback degradado.
- ❌ Default SendGrid cuando ambiguo. Default es Resend (D-010 pattern).
- ❌ Skipear pregunta de compliance (P1+P2). Si HIPAA BAA mandatory y no se preguntó, decision tree es inválida — re-correr.
- ❌ Asumir que SOC 2 cloud-hosted satisface HIPAA BAA on-prem. Son requirements diferentes — gate explícito.

## Cross-skill applicability

D-011 evolution sobre D-010:
- D-009 (add-login): default + override binary (Supabase vs Insforge)
- D-010 (add-payments): default + override + PAUSE trinario (Stripe vs Polar vs constituir empresa)
- **D-011 (add-emails): default + override + PAUSE trinario con axis nuevo (compliance vs ecosystem vs sovereignty)**

El pattern PAUSE en D-010 era "actor needs to constitute legal entity". El pattern PAUSE en D-011 es "actor needs to constitute infrastructure (SMTP self-hosted)". Generalización: PAUSE es válido cuando el degenerate case requires *external action upstream* del usuario antes de re-invocar el skill.

F3-S6 (add-mobile) puede heredar D-011 con axis nuevo (push subscription requires user permission flow, NOT external infra). Probablemente NO PAUSE option — push notifications no tienen un equivalente de "data sovereignty mandatory" típicamente.
