# Deliverability Best Practices

> Sin SPF/DKIM/DMARC + suppression handling, los emails van a spam aunque el código sea perfecto.

## DNS records (manual setup, no auto)

### SPF (Sender Policy Framework)

```
TXT @ "v=spf1 include:_spf.resend.com ~all"   # Resend
TXT @ "v=spf1 include:sendgrid.net ~all"      # SendGrid
```

`~all` (softfail) recomendado. `-all` (hardfail) solo si NO hay otro sender legítimo (newsletters, otros servicios).

### DKIM (DomainKeys Identified Mail)

Cada provider da los CNAMEs:

```
# Resend
CNAME resend._domainkey  resend._domainkey.<your-resend-region>.resend.com

# SendGrid
CNAME s1._domainkey  s1.domainkey.u<userId>.wl<num>.sendgrid.net
CNAME s2._domainkey  s2.domainkey.u<userId>.wl<num>.sendgrid.net
```

Verificar en provider dashboard tras propagación DNS (~24h max).

### DMARC

```
TXT _dmarc "v=DMARC1; p=quarantine; rua=mailto:dmarc@<domain>; ruf=mailto:dmarc@<domain>; fo=1"
```

Empezar con `p=quarantine` (suspicious mails to spam). Avanzar a `p=reject` después de 30d sin issues.

## Sender reputation

### Warming IP dedicada (SendGrid Pro+)

Si usás IP dedicada, SendGrid hace warmup automático las primeras 30d:
- Día 1: ~50 emails
- Día 7: ~5000
- Día 30: full capacity

Si tu volumen normal supera la curva → reducir manualmente.

### Resend (shared IPs por default)

Free tier shares IPs con otros senders. Si tu Domain Authentication está OK, Resend gestiona reputation. Para volumen >50K/mes, considerar dedicated IP add-on.

## Suppression list

**Hard bounces:** NO re-enviar nunca sin investigar manualmente. R14 gate en `deleteSuppressionEntry`.

**Spam complaints:** suppression permanente. Re-enabling es muy peligroso para reputation.

**Soft bounces:** retry 3x con backoff exponencial. Si falla 3x → mover a hard.

**Unsubscribes:** respetar inmediatamente. RFC 8058 mandate one-click.

## Engagement (open + click rates)

Los providers de inbox (Gmail, Outlook) penalizan senders cuyos emails NO se abren:
- Open rate <10% sustained → spam folder
- Click rate <2% sustained → degraded reputation

Mitigación:
- Confirma opt-in en signup (NO compras de listas)
- Re-engagement campaigns para users inactivos >90d
- Suppress automatically users con 0 opens en 6 emails

## Authentication beyond SPF/DKIM/DMARC

### BIMI (Brand Indicators for Message Identification)

Logo de tu brand en inbox. Requiere:
- DMARC `p=quarantine` o `p=reject` activo ≥30d
- VMC (Verified Mark Certificate) — paid (~$1500/year)
- SVG logo en formato BIMI-compliant

Opcional pero buen marketing signal.

### MTA-STS (Mail Transfer Agent Strict Transport Security)

Forces TLS para inbound mail. Setup via DNS + HTTPS endpoint con policy file. Aplica si recibís emails (no solo enviás).

## Privacy compliance

### GDPR (UE)

- Consent opt-in obligatorio para marketing
- Unsubscribe link en cada email (transactional + marketing)
- Data subject access request (DSAR): mostrar todos los emails enviados a un user (admin route)
- Right to be forgotten: delete email_events + suppression entries (R14 gate)

### CAN-SPAM (US)

- Physical address en footer obligatorio
- Unsubscribe en cada email + processed dentro de 10 días
- NO subject misleading

### LGPD (Brasil)

Similar a GDPR — consent + DPO contact + acknowledgment.

## Testing

| Tool | Uso |
|------|-----|
| mail-tester.com | Score 0-10 (target ≥9.0) — verifica SPF/DKIM/DMARC + spam triggers |
| MailGenius | Inbox placement por client (Gmail/Outlook/Yahoo) |
| Postmaster Tools (Google) | Reputation domain en Gmail (post-1000 emails) |
| MXToolbox | DNS records validation |
| Litmus / Email on Acid | Render preview por client (Outlook 2007-2019, Gmail dark mode, etc.) |

## Anti-patterns

- ❌ Comprar listas de emails. CAN-SPAM violation + reputation damage.
- ❌ Send a addresses sin opt-in.
- ❌ Subject lines con `RE:` o `FWD:` cuando NO es reply/forward (deceptive).
- ❌ Excessive use of `!`, ALL CAPS, `$$$` (spam triggers).
- ❌ Hide unsubscribe link.
- ❌ Tracking pixel oculto sin disclosure (privacy violation).
- ❌ Skip SPF/DKIM (delivery rate cae <60%).

## Citations

- [docs:rfc8058] (one-click unsubscribe)
- [docs:rfc7208] (SPF)
- [docs:rfc6376] (DKIM)
- [docs:rfc7489] (DMARC)
- [memory:CONSTRAINTS.md#R14] (R14 en deleteSuppressionEntry)
