# add-teams Examples — invocación + mini-FAQ

> add-teams es un drop-in **condicional al shape del target**: existe sólo si la app es multi-tenant.
> No hay selector de provider (opera sobre la fundación M6 que `el-migrador` ya dejó). La doctrina
> completa: `references/teams-model.md`. La migración (contrato): `templates/supabase/migrations/0005_teams.sql`.

## Example 1 — happy path (app multi-tenant con fundación M6 lista)

### Input

- Tech Spec: `tenant_model.multi_tenant: true`.
- `el-migrador` ya aplicó `0000_tenancy.sql` (organizations + memberships + `auth_has_org_role()` + trigger creator→owner).
- `add-login` corrió → `auth.users` poblable, `lib/supabase/{client,server}.ts` presentes.
- Brand DNA: `brand/brand.json` con `brand.product = "Atlas"`, archetype Sage+Ruler.
- `voice.json` con `cta_examples: ["Sumá a tu equipo.", "Invitá a un colega.", "Crear organización."]`
- impeccable Mode C corrió → componentes en `src/shared/components/ui/` (Button/Input/Select/Card/ConfirmModal).

### Comando del usuario

> "Agregame gestión de equipo: que el dueño pueda crear su organización, invitar gente por email, y asignar roles."

### Flow

1. PREFLIGHT: 8 gates. Pasan todos.
2. find-docs (R13): `supabase` (RLS multi-tenant definer) + `supabase-ssr` (Next.js 16) + `nextjs` (dynamic route `[token]`).
3. R10 read brand.json + voice.json. Audit copy contra avoid_words.
4. Substitute templates → src/:
   - `actions/teams.ts` (las 9 actions — R14 + L-003), `hooks/useOrganization.ts`, `lib/teams/queries.ts`
   - 5 componentes + barrel en `features/teams/components/` (OrgSwitcher, MembersList, InviteMemberForm, PendingInvitations, RoleSelect)
   - pages: `app/(app)/settings/teams/page.tsx` (incl. zona peligrosa inline) + `app/invite/[token]/page.tsx`
5. Enlazar (NO reescribir) `0005_teams.sql` + `0005_teams-isolation.test.sql` en `supabase/migrations/`.
6. Security pre-handoff scan: 0 hits de service_role en client; WITH CHECK presente; guard_last_owner presente.
7. el-migrador aplica `0005_teams.sql` + corre el test negativo (5 T-TEAM-* + control → verde, R7 Layer 4).
8. Output handoff a `el-guardian` (El Infiltrado). Deploy bloqueado hasta PASS.

### Brand Score esperado

| Page | tokens | components | a11y | anti-slop | voice | TOTAL |
|------|--------|-----------|------|-----------|-------|-------|
| settings/teams (members + invite + danger zone) | 25 | 20 | 28 | 15 | 9 | 97 |
| invite/[token] | 25 | 20 | 28 | 15 | 9 | 97 |

Threshold 75 / actual 95+ → PASS holgado.

## Example 2 — halt seco (app single-tenant)

### Input

- Tech Spec: `tenant_model.multi_tenant: false` (o ausente).

### Comando del usuario

> "Quiero agregar equipos a mi app."

### Flow

1. PREFLIGHT gate 2 falla.
2. **Halt seco** (NO PAUSE, NO fallback a otro provider):

> "add-teams es exclusivo de apps multi-tenant. Tu app es single-tenant
> (`tenant_model.multi_tenant: false`), donde gobierna L-001 (`auth.uid() = user_id`) — no hay tenants
> que gestionar. Si querés convertir la app a multi-tenant, corré primero la fundación M6 con
> `el-migrador` (`0000_tenancy.sql`) y volvé."

Esto es el degenerate case del pattern boundary [memory:lessons#L-004]: niega la aplicabilidad del skill,
no propone un provider alternativo.

## Example 3 — halt + handoff (fundación M6 ausente)

### Input

- Tech Spec multi-tenant, pero `0000_tenancy.sql` nunca se aplicó (no existen `organizations`/`memberships`).

### Comando del usuario

> "Agregame orgs e invitaciones."

### Flow

1. PREFLIGHT gate 3 falla (no encuentra la fundación).
2. **Halt + handoff a `el-migrador`:**

> "add-teams extiende la fundación multi-tenant de M6, pero no la encuentro (`0000_tenancy.sql` no
> aplicada — faltan `organizations`/`memberships`/`auth_has_org_role()`). Corré primero `el-migrador`
> para aplicar la fundación M6, y después volvé a `/add-teams`."

## Mini-FAQ

**¿Y si mi app es single-tenant?**
add-teams no aplica (halt seco — ver Example 2). En single-tenant un usuario = un dueño de sus datos
(`auth.uid() = user_id`, L-001); no hay organizaciones ni roles entre miembros que gestionar. Convertí a
multi-tenant con la fundación M6 (`el-migrador`) si de verdad necesitás equipos.

**¿Puede una org tener un solo owner para siempre?**
Sí — el caso normal. El owner único funciona perfecto. La protección del **último owner**
(`guard_last_owner`) sólo impide que se quede en **cero** owners: un owner único no puede auto-degradarse
ni borrar su propia membership sin transferir primero. Para irse, transfiere la propiedad (a un miembro
existente) y entonces sí puede salir. Un owner único tampoco "necesita" un admin: es opcional.

**¿Cómo se transfiere la propiedad? ¿Puede haber 2 owners un instante?**
Con `transfer_org_ownership(org, new_owner)` — una función `SECURITY DEFINER`, owner-only, **atómica**:
en una sola transacción degrada al owner actual a `admin` y promueve al nuevo a `owner`. Nunca hay 2
owners ni 0; el invariante "exactamente 1 owner por org" se mantiene. El nuevo owner debe ya ser miembro.
Es el **único** camino a `owner`: ninguna policy ni server action ordinaria puede fijar `role='owner'`.

**¿Por qué un admin no puede invitar como owner?**
Porque el check de la tabla `invitations` limita `role` a `{admin, member}`, y la policy de UPDATE de
`memberships` tiene `WITH CHECK` que prohíbe fijar `role='owner'` salvo que el caller ya sea owner. La
escalación admin→owner es justo lo que audita El Infiltrado (T-TEAM-2). El ascenso a owner es transfer-only.

**¿Qué pasa si alguien reenvía el link de invitación a otra persona?**
`accept_invitation(token)` exige que el email del JWT del que acepta **coincida** con el email invitado.
Un tercero con el link rebota ("invitation email does not match") y NO queda como miembro (T-TEAM-4).

**¿La UI es la que decide quién puede qué?**
No. La UI sólo **oculta** botones por UX (gating cosmético: el consumidor decide según el rol del caller).
La frontera real es Postgres (RLS + funciones definer + triggers). Un cliente que llame la API directo,
saltándose la UI, igual rebota. Eso es L-005 y lo verifica el test negativo sobre Postgres real (R7 Layer 4).

## Citations

- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R14] · [memory:CONSTRAINTS.md#R16]
- [memory:lessons#L-005] · [memory:lessons#L-004] · [memory:lessons#L-003] · [memory:lessons#L-001]
- `references/teams-model.md` · `prompts/handoff-el-guardian.md`
- [docs:supabase] · [docs:postgres] · [docs:nextjs]
