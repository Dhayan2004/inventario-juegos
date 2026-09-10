# Handoff a el-guardian — Pre-deploy Security Checklist

> Este documento se invoca al cierre de add-login. el-guardian usa Codex como
> "segundo cerebro" para auditar adversarialmente lo generado. Sin PASS de
> el-guardian, deploy bloqueado.

## Contexto

add-login generó:
- SDK clients (server + client) para Supabase o Insforge
- 4 auth pages + check-email + 6 components
- Server actions (login, signup, signout, resetPassword, updatePassword, deleteAccount)
- proxy.ts (Next.js 16) o middleware.ts
- callback OAuth + sign-out + delete-account routes
- 0001_profiles.sql con RLS L-001 (Supabase) o lib/insforge/schema.ts (Insforge)
- .env.local con placeholders

## Checklist obligatorio

### 1. service_role / private key isolation

```
✓ NO `service_role` ni `SUPABASE_SERVICE_ROLE_KEY` en archivos client
  (src/app/(auth)/**/*.tsx, src/features/auth/components/**)
✓ NO `INSFORGE_SECRET_KEY` en client/components
✓ service_role/secret_key SOLO en lib/<baas>/server.ts y server actions
✓ env vars privadas SIN prefix `NEXT_PUBLIC_`
```

Comando audit:
```bash
grep -rn "service_role\|SERVICE_ROLE\|INSFORGE_SECRET" \
  src/app/(auth)/ src/features/auth/ src/components/ \
  src/lib/supabase/client.ts src/lib/insforge/client.ts \
  2>/dev/null
# Esperado: 0 hits
```

### 2. RLS en profiles (L-001)

```
✓ profiles table tiene `enable row level security`
✓ ≥2 policies con `auth.uid() = id`
✓ trigger handle_new_user con `security definer`
✓ Foreign key con `on delete cascade`
```

Comando audit:
```bash
SQL=supabase/migrations/*_profiles.sql
grep -q "enable row level security" $SQL
grep -c "auth.uid() = id" $SQL
grep -q "security definer" $SQL
grep -q "on delete cascade" $SQL
```

### 3. OAuth redirect URIs whitelisted

```
✓ NEXT_PUBLIC_SITE_URL en .env.local
✓ callback route valida `next` contra ALLOWED_NEXT_PATHS (open-redirect guard)
✓ provider error parameter handled (no leak en logs)
✓ Manual: en Supabase Dashboard / Insforge UI, redirect URLs whitelisted
  con exactamente $NEXT_PUBLIC_SITE_URL + /**
```

Comando audit:
```bash
grep -q "ALLOWED_NEXT_PATHS" src/app/api/auth/callback/route.ts
grep -q "safeNext" src/app/api/auth/callback/route.ts
```

Manual gates documented in handoff: el-guardian pregunta al usuario si los settings de provider (Google Cloud Console + Supabase Dashboard) ya están aplicados. Si no → flag y bloquea deploy.

### 4. Email confirmation tokens single-use

```
✓ Supabase: nativamente single-use, documentar.
✓ Insforge: revisar config; si pluggable, exigir single-use.
✓ Reset password tokens: no log en server-side; nunca propagar como query string a otro origin.
```

Doc check: `references/oauth-providers.md` y `references/insforge-auth-patterns.md` declaran defaults.

### 5. R14 — destructive actions sin execute() automático

```
✓ deleteAccount route NO export tool con execute() async
✓ signOut all sessions sin execute()
✓ UI requiere typed confirmation antes de invocar (ej: usuario tipea "DELETE my account")
```

Comando audit:
```bash
# delete-account route es Server Action o POST handler con confirmation gate, NO tool agentic
grep -E "execute:\\s*async" src/app/api/auth/delete-account/route.ts
# Esperado: 0 matches

grep -q "DELETE my account\|confirmation\|confirmed" src/app/api/auth/delete-account/route.ts
# Esperado: ≥1 match (gate explícito)
```

### 6. L-002 — OAuth callback trata payload como dato

```
✓ Callback route NO ejecuta side-effects basados en provider response sin verificar
✓ `state` param verificado (Supabase lo hace nativamente vía cookies)
✓ Error param se traduce a redirect con flag, NO se loggea raw
```

Comando audit:
```bash
grep -q "L-002" src/app/api/auth/callback/route.ts
```

### 7. L-003 — Whitelist validation en form inputs

```
✓ actions/auth.ts valida email con regex whitelist (RFC-light)
✓ Password con minLength 8 + maxLength 128 (bounded)
✓ NO `z.record(z.any())` en server actions
```

Comando audit:
```bash
grep -E "z\\.string\\(\\)\\.email\\(\\)" src/actions/auth.ts
grep -E "z\\.string\\(\\)\\.min\\(8\\)\\.max\\(128\\)" src/actions/auth.ts
grep -E "z\\.record\\(z\\.any\\(\\)\\)" src/actions/auth.ts
# Esperado: primeros 2 presentes, último 0 hits
```

### 8. PII handling — emails y user_id

```
✓ NO logs con email completo en server-side errors (PII redaction)
✓ user_id en URLs solo en GET protected routes (no en query string público)
```

Manual review por el-guardian.

### 9. Headers HTTP (delegado a Next.js + Supabase defaults)

```
✓ HTTPS only en producción (NEXT_PUBLIC_SITE_URL https://)
✓ Cookies con `Secure` + `HttpOnly` + `SameSite=Lax` (Supabase defaults)
```

el-guardian valida en preview deploy si aplica.

### 10. Session expiry y refresh

```
✓ Refresh tokens habilitados (access_type: 'offline' en Google OAuth)
✓ Session cookie expiry razonable (Supabase default: 1 hora access + 1 semana refresh)
✓ proxy/middleware refresca session en cada request a rutas protegidas
```

Comando audit:
```bash
grep -q "supabase.auth.getUser" src/lib/supabase/proxy.ts
# proxy debe usar getUser (validates token), nunca getSession
```

## Severidades

el-guardian asigna severidad por gap:

| Severity | Examples | Block deploy? |
|----------|----------|---------------|
| critical | service_role en client; RLS missing en profiles | yes |
| high | open-redirect en callback; deleteAccount con execute(); password sin maxLength | yes |
| medium | falta JSDoc citation; logs PII en server | no, fix antes de prod |
| low | copy con avoid_words | no, fix antes de prod |

PASS = 0 critical + 0 high.

## Output esperado

el-guardian retorna:

```markdown
# Security Audit — add-login

**Status:** PASS | NEEDS_FIX | FAIL

**Findings:**
- [critical] ... | none
- [high] ... | none
- [medium] ... | none
- [low] ... | none

**Manual gates pending:**
- [ ] Google OAuth Client ID + Secret configurados en Supabase Dashboard
- [ ] Redirect URLs whitelisted con exactamente $NEXT_PUBLIC_SITE_URL/**
- [ ] Site URL configurado en Authentication > URL Configuration

**Deploy gate:** UNBLOCKED | BLOCKED

**Recommendations:**
- ...
```

Si BLOCKED → add-login retorna NEEDS_FIX al el-evaluador, gaps específicos. el-evaluador decide si regenerate o handoff manual al usuario.

## Citations

- [memory:lessons#L-001] · [memory:lessons#L-002] · [memory:lessons#L-003]
- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14]
- [memory:references#R-005]
- [docs:supabase] · [docs:supabase-ssr] · [docs:insforge]
