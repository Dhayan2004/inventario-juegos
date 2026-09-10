# OAuth Providers — configs estándar

> Reference para Google / GitHub / Discord OAuth en Supabase + Insforge.
> Cita `[docs:supabase-js]` o `[docs:insforge]` cuando se use.

## Google (default recomendado)

### Supabase

Cliente:
```typescript
await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: `${origin}/api/auth/callback?next=${encodeURIComponent(next)}`,
    queryParams: {
      access_type: 'offline', // refresh tokens
      prompt: 'consent',       // siempre pide consent (para refresh tokens nuevos)
    },
    scopes: 'openid email profile', // default; agregar 'https://www.googleapis.com/auth/calendar.readonly' si necesitás Workspace APIs
  },
});
```

Provider config (manual, en Supabase Dashboard):
- Authentication > Providers > Google
- Enable
- Client ID + Client Secret (de Google Cloud Console)
- Authorized redirect URI: `https://<PROJECT_REF>.supabase.co/auth/v1/callback`

Google Cloud Console:
- APIs & Services > Credentials > Create Credentials > OAuth Client ID
- Application type: Web application
- Authorized redirect URIs: `https://<PROJECT_REF>.supabase.co/auth/v1/callback`

### Insforge

```typescript
await insforge.auth.oauth({
  provider: 'google',
  redirectTo: `${origin}/api/auth/callback?next=${encodeURIComponent(next)}`,
  queryParams: { access_type: 'offline', prompt: 'consent' },
  scopes: 'openid email profile',
});
```

Provider config (manual, en Insforge Admin UI):
- Settings > Auth > Providers > Google
- Enable + paste Client ID + Secret
- Redirect URI: `<INSFORGE_URL>/auth/v1/callback`

## GitHub

### Supabase
```typescript
await supabase.auth.signInWithOAuth({
  provider: 'github',
  options: {
    redirectTo: `${origin}/api/auth/callback?next=${encodeURIComponent(next)}`,
    scopes: 'read:user user:email',
  },
});
```

GitHub OAuth App: https://github.com/settings/developers > New OAuth App.
- Authorization callback URL: `https://<PROJECT_REF>.supabase.co/auth/v1/callback`

### Insforge
Misma forma, ajustando provider key. Provider config en Insforge UI.

## Discord

### Supabase
```typescript
await supabase.auth.signInWithOAuth({
  provider: 'discord',
  options: {
    redirectTo: `${origin}/api/auth/callback?next=${encodeURIComponent(next)}`,
    scopes: 'identify email',
  },
});
```

Discord Developer Portal > Application > OAuth2 > Redirects.

### Insforge
Mismo shape; provider key 'discord'.

## Common gotchas

1. **Site URL mismatch.** Si `NEXT_PUBLIC_SITE_URL` en .env.local no matchea el Site URL configurado en Supabase Dashboard / Insforge UI, OAuth callback redirige a sitio incorrecto post-auth. el-guardian audita.

2. **Refresh tokens missing.** Sin `access_type: 'offline'` + `prompt: 'consent'`, Google no devuelve refresh tokens. Usuario hace re-auth cada hora. Para Workspace integrations futuras (Gmail, Calendar, Sheets), refresh tokens son obligatorios.

3. **Scope creep.** Pedir solo scopes necesarios. `openid email profile` cubre 90% de casos de auth básico. Pedir `calendar`, `gmail.send`, etc., solo cuando hay use case explícito en Tech Spec.

4. **State param verification.** Supabase y Insforge ambos manejan `state` automáticamente vía cookies. NO override manualmente. Si falla, mirar settings de cookies (Secure, SameSite=Lax).

5. **Open-redirect vector.** Si el callback usa `next` query param sin whitelist, atacante puede mandar `next=//evil.com`. Mitigación: `safeNext` con `ALLOWED_NEXT_PATHS` (ver `prompts/generate-oauth-config.md`).

## Citations

- [docs:supabase-js] · [docs:insforge]
- [memory:lessons#L-002]
