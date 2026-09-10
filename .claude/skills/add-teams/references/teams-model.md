# Teams / tenant management model — la doctrina de `add-teams` (S2)

> **Qué es esto.** El contrato del drop-in `add-teams`: la **UI de gestión de tenants** (organizaciones,
> invitaciones, roles) que se genera en una app target multi-tenant, **sobre** la fundación RLS de M6
> (`0000_tenancy.sql`). Cierra el ítem que M6 marcó "build per-app fasable" (`MULTI_TENANCY.md` §234:
> "La gestión de tenants — UI de orgs, invitaciones, roles — territorio de S2"). NO reescribe la
> fundación; la **extiende** (`0005_teams.sql`) y le pone cara.
>
> Es a la gestión de equipo lo que `add-login` es a la auth: un drop-in que respeta R10 (Brand DNA),
> R14 (destructivas con confirmación), L-003 (whitelist), y hace handoff obligatorio a `el-guardian`.

- **Versión:** v0.1.0 (2026-06-30, S2). **Tier:** optional (drop-in per-app).
- **Enforce:** `[memory:CONSTRAINTS.md#R16]` (3 invariantes de tenant) + `[memory:lessons#L-005]` (RLS por tenant).
- **Migración:** `templates/supabase/migrations/0005_teams.sql` (con el bloque ROLLBACK embebido al pie,
  patrón de `0000_tenancy.sql`) + `0005_teams-isolation.test.sql`.

---

## 1. El modelo de rol (la autoridad — debe respetarse en SQL, server actions y UI)

Reusa los roles de M6 (`owner`/`admin`/`member`), **no inventa otros**:

| Rol | Puede |
|-----|-------|
| `owner` | todo: settings de la org, **borrar la org**, **transferir la propiedad**, gestionar admins y members. **Exactamente 1 por org** (invariante, ver §3). |
| `admin` | invitar/expulsar/cambiar rol de **members y otros admins**. **NUNCA** crear o tocar a un owner, ni auto-promoverse a owner. |
| `member` | leer su org y co-miembros; aceptar invitaciones; salir de la org (`leaveOrg`). |

La autoridad **se enforce en Postgres (RLS + funciones definer + triggers)**, no en el código (L-005). La UI
sólo **refleja** lo que el rol permite (oculta botones), pero la frontera real es la DB — un cliente que
llame la API directo igual rebota.

---

## 2. Invitaciones — el flujo seguro

- Sólo `owner`/`admin` crean invitaciones (`role` ∈ {admin, member}; **nunca owner**).
- La invitación lleva un `token` secreto (`gen_random_bytes`) y `expires_at` (7 días por defecto).
- El invitado acepta con `accept_invitation(token)` — una función **SECURITY DEFINER** que valida:
  token existe · `status='pending'` · no expirada · **el email del invitado coincide con el del JWT del
  que acepta** (anti-robo de invitación). Sólo entonces inserta la membership con el rol invitado.
- El cliente **nunca** elige su propio rol ni inserta su membership directo (no hay policy de INSERT en
  `memberships`; el único alta es el trigger creator→owner o `accept_invitation`).

---

## 3. Anti-escalación de privilegios (lo que el-guardian "El Infiltrado" audita)

Las amenazas específicas de gestión de equipo y cómo las cierra `0005_teams.sql`:

1. **admin → owner (auto-ascenso):** la policy `manage memberships update` tiene `WITH CHECK` que prohíbe
   fijar `role='owner'` salvo que el caller sea owner. Test: `T-TEAM-2`.
2. **admin tocando al owner (expulsar/degradar):** las policies update/delete exigen ser owner para tocar
   una fila `role='owner'`. Test: `T-TEAM-3`.
3. **org sin owner (último owner):** el trigger `guard_last_owner` aborta el delete/demote que dejaría 0
   owners. La propiedad sólo se mueve con `transfer_org_ownership()` (atómico, owner-only). Test: `T-TEAM-5`.
4. **robo de invitación:** `accept_invitation` exige match de email JWT↔invitación. Test: `T-TEAM-4`.
5. **cross-tenant:** invitar/leer en una org ajena rebota por `auth_has_org_role` (R16). Test: `T-TEAM-1`.

> **R7 Layer 4 (M6):** la app multi-tenant no marca `passing` sin el test negativo verde. `add-teams`
> aporta `0005_teams-isolation.test.sql` (estos 5 + control positivo) que extiende el de M6. El
> kill-mutation está documentado en el propio test: quitar una guarda DEBE poner en rojo algún T-TEAM-*.

---

## 4. Server actions (R14 + L-003)

| Action | R14 (destructiva → confirmación tipada, sin `execute()` automático) | Validación |
|--------|--------------------------------------------------------------------|------------|
| `createOrganization` | no | L-003 (name/slug whitelist) |
| `inviteMember` | no (pero rate-limit + L-003 email) | email whitelist + role ∈ {admin,member} |
| `acceptInvitation` | no | token opaco; el server llama `accept_invitation()` |
| `revokeInvitation` | **sí** | id propio de la org |
| `updateMemberRole` | **sí** (cambia autoridad) | role ∈ {admin,member}; nunca owner por aquí |
| `removeMember` | **sí** | no a uno mismo si sos el último owner |
| `leaveOrganization` | **sí** | owner debe transferir antes |
| `transferOwnership` | **sí** (typed: escribir el nombre de la org) | llama `transfer_org_ownership()` |
| `deleteOrganization` | **sí** (typed: escribir el slug) | sólo owner; cascade |

- Las destructivas siguen el patrón de `add-login` `deleteAccount`: la server action corre **tras**
  confirmación tipada en UI; **no** se exponen como agentic tools con `execute()` (R14 binario).
- L-003: schemas Zod explícitos por field; nada de `z.record(z.any())`. El `organization_id` jamás se
  confía del body sin que RLS lo valide (R16 invariante 3).

---

## 5. UI (R10 — consume `impeccable` + `brand.json`/`voice.json`)

Superficie mínima (Feature-First, `src/features/teams/`):

- **OrgSwitcher** — selector de org activa (escribe el contexto de org en cookie/estado).
- **MembersList** — tabla de miembros con rol; acciones gated por el rol del caller.
- **InviteMemberForm** — email + rol; copy desde `voice.json`.
- **PendingInvitations** — invitaciones pendientes (revocar/reenviar).
- **RoleSelect** — cambiar rol (oculto para `member`; nunca ofrece `owner`).
- **AcceptInvite page** (`/invite/[token]`) — landing para aceptar (llama `acceptInvitation`).
- **OrgSettings** — renombrar, transferir propiedad, borrar org (zona peligrosa, R14).

Reglas R10 idénticas a `add-login`: cero Tailwind defaults; importar `Button`/`Input`/`Form`/`Card`/`Table`
de `impeccable`; CTAs desde `voice.cta_examples`; Brand Score ≥75 por página (lo valida `el-evaluador`).

---

## 6. PREFLIGHT + handoffs

- **PREFLIGHT halt:** AGENTS.md · app declarada multi-tenant (`tenant_model.multi_tenant`) · fundación
  `0000_tenancy.sql` aplicada (handoff de `el-migrador`/`baas`) · `add-login` corrió (auth + `auth.users`) ·
  Brand DNA + componentes `impeccable` presentes. Falta cualquiera → halt con el handoff exacto.
- **Upstream:** `baas` (decisión) → `el-migrador` (`0000_tenancy.sql`) → `add-login` (auth) → `add-teams`.
- **Downstream obligatorio:** `el-migrador` aplica `0005_teams.sql` + corre `0005_teams-isolation.test.sql`
  (R7 Layer 4); `el-guardian` audita pre-deploy (persona **El Infiltrado** + cross-tenant + escalación de
  rol); `el-evaluador` valida L1/L2/L3 + Brand Score.

## Sources
- `docs/06` §S2 · `MULTI_TENANCY.md` §234 (territorio S2) + modelo de amenazas T1–T9.
- `[docs:supabase]` RLS multi-tenant + security definer; `[docs:postgres]` triggers/policies. Validar con `find-docs` (R13).
