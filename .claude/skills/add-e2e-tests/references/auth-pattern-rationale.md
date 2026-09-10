# auth-pattern-rationale — storageState + auth.setup.ts

> Reference. Por qué `tests/e2e/auth.setup.ts` + `storageState` es el
> patrón canónico para auth en Playwright, y cómo se integra con
> add-login Supabase.
>
> **Citas:** `[memory:decisions#D-026]`, `[docs:playwright]`.

---

## El problema

E2E specs que requieren un usuario logueado caen en una de tres trampas:

1. **Cada spec se loguea en `beforeEach`** → lentitud O(N specs × tiempo de login). 100 specs × 3s = 5min solo en login.
2. **Login en `beforeAll`** → estado compartido entre specs paralelos rompe `fullyParallel: true` y deadlocks en Playwright workers.
3. **Hardcodear cookies / tokens en specs** → credenciales en repo + tokens expiran + se rompe cuando refrescás auth provider.

Ninguna escala. Ninguna es robusta.

---

## El patrón canónico

Playwright resuelve esto con `storageState`. El flujo:

1. **`auth.setup.ts`** — un spec especial que corre UNA vez antes de
   todos los demás. Loguea con credenciales reales (de env vars),
   captura el estado de cookies + localStorage + sessionStorage, y lo
   guarda en `playwright/.auth/user.json`.

2. **`playwright.config.ts`** declara dos projects:
   - `setup` — corre `auth.setup.ts`.
   - `chromium` (y firefox, webkit en modo full) — declara `dependencies: ['setup']` + `use.storageState: 'playwright/.auth/user.json'`.

3. **Specs autenticados** simplemente `await page.goto('/dashboard')` y
   YA están logueados — Playwright inyecta el storageState al contexto
   antes de cada spec.

Resultado: 1 login total, no N. Specs paralelos sin shared mutable
state. Credenciales de env vars o GitHub Secrets, NUNCA en repo.

---

## Integración con add-login Supabase

`add-login` (Supabase mode) genera:

- `src/app/(auth)/sign-in/page.tsx` — form con `email` + `password` + submit button.
- Cookie de auth: `sb-<project-ref>-auth-token` (set por `createServerClient` en proxy/middleware).

El template `auth.setup.ts.template` matchea exactamente esa shape:

- `page.goto('/sign-in')`
- `page.getByLabel(/email/i).fill(...)` — funciona contra el `<label for="email">` del template add-login.
- `page.getByLabel(/password/i).fill(...)` — idem.
- `page.getByRole('button', { name: /sign in|iniciar sesión|entrar/i }).click()` — robusto a las 3 versiones de copy que voice.json puede producir.
- Espera redirect post-login (`waitForURL` con matcher).
- Asserts que la cookie `sb-*-auth-token` está presente antes de guardar storageState.

Si tu sign-in form difiere (otro provider, otra ruta, otras labels) →
editar `auth.setup.ts` post-install. El template está pensado para que
seas dueño del código post-scaffold, no para que lo regenere.

---

## Variables de entorno

| Var | Default si missing | Uso |
|-----|---------------------|-----|
| `TEST_USER_EMAIL` | **(halt — no default)** | login en auth.setup.ts |
| `TEST_USER_PASSWORD` | **(halt — no default)** | login en auth.setup.ts |
| `NEXT_PUBLIC_APP_URL` | `http://localhost:3000` | baseURL |
| `E2E_WEB_SERVER_COMMAND` | `npm run dev` | comando para `webServer` del config |

### Setup local

Crear `.env.test.local` (gitignored por defecto en Next.js):

```bash
TEST_USER_EMAIL=test+e2e@example.com
TEST_USER_PASSWORD=<password seguro>
```

Crear el usuario manualmente en Supabase Dashboard o vía script:

```sql
-- supabase/seed-test-user.sql (NO commitear)
SELECT auth.create_user('test+e2e@example.com', '<password>');
```

### Setup CI

GitHub Actions Secrets (modo full):

```
TEST_USER_EMAIL
TEST_USER_PASSWORD
NEXT_PUBLIC_APP_URL  (opcional)
```

El workflow ya los pasa como env vars al runner.

---

## Refresh de storageState

storageState **expira** cuando expira la sesión del provider. Supabase
default es 1 hora (configurable). Para CI esto no es problema (cada run
corre `auth.setup.ts` fresh). Local puede ser problema si el archivo
queda viejo.

Soluciones:
- Borrar `playwright/.auth/user.json` manual cuando arranca raro.
- Agregar a `npm run test:e2e` un pre-step que invalida el archivo
  si tiene >50min (post-install opcional, no incluido por default).

---

## Seguridad

- `playwright/.auth/*.json` está en `.gitignore` por defecto post-scaffold.
- NUNCA commitear el storageState file — contiene tokens activos.
- Credenciales del test user son production-grade — el user tiene los
  mismos permisos que cualquier usuario real. Si tu app permite acciones
  irreversibles, los tests deberían correr contra un environment de
  staging, no prod.

---

## Anti-patrones

- ❌ Hardcodear tokens / cookies en specs. Refresh imposible.
- ❌ Loguear en cada spec con `beforeEach`. Lento y frágil.
- ❌ Compartir storageState entre proyectos sin re-generarlo. Si auth
  changes, todos los specs fallan en cascada.
- ❌ Subir `playwright/.auth/*.json` al repo. Tokens en plain text.
- ❌ Usar el test user para tests destructivos en prod. Staging or bust.

---

*"Un login, un storageState, N specs paralelos. Credenciales en env vars o Secrets, nunca en repo."*
