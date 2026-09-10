---
name: add-teams
description: >
  UI de gestión de tenants drop-in (orgs / invitaciones / roles
  owner-admin-member) sobre la fundación multi-tenant de M6
  (0000_tenancy.sql). Trae la migración 0005_teams.sql con anti-escalación
  de privilegios + accept_invitation() + transfer_org_ownership() (definer,
  owner-only), server actions R14 + L-003 (Zod por field), y UI R10 vía
  impeccable (Button/Input/Select/Card/ConfirmModal + voice.json). Las destructivas
  (revoke/remove/updateRole/leave/transfer/delete) corren tras confirmación
  tipada verificada server-side, NUNCA como tools agentic con execute().
  Handoff obligatorio a el-guardian (persona El Infiltrado) + R7 Layer 4 (test negativo
  0005_teams-isolation.test.sql, los 5 T-TEAM-*) pre-deploy.
tier: optional
requires: AGENTS.md exists, app declarada multi-tenant (tenant_model.multi_tenant: true), 0000_tenancy.sql aplicado (organizations + memberships + auth_org_ids() + auth_has_org_role() + trigger creator→owner), add-login corrió (auth + auth.users poblado), Brand DNA contract presente (brand/brand.json + voice.json), impeccable corrió (componentes UI base en src/shared/components/ui/).
fallback: App single-tenant (tenant_model.multi_tenant false o ausente) → halt (add-teams es exclusivo de multi-tenant; gobierna L-001, no hay tenants que gestionar). Sin fundación 0000_tenancy.sql → halt + handoff a el-migrador (aplicá la fundación M6 primero). Sin add-login → halt + handoff a add-login (no hay auth.users sin auth). Sin Brand DNA → halt + handoff a add-ui-kit. Sin impeccable components → halt + handoff a impeccable Mode C.
dependencies: [el-migrador, add-login, impeccable, add-ui-kit, el-guardian]
---

# add-teams

> *"Un equipo no es una lista de usuarios. Es una jerarquía de autoridad. Si esa autoridad la enforza el código y no la base, ya perdiste — un cliente con curl la rompe."*
> — Forja R16 / L-005

Skill drop-in. Setea la **gestión de tenants** completa (organizaciones, invitaciones por email, roles `owner`/`admin`/`member`, transferencia de propiedad, zona peligrosa) en una app target **multi-tenant**, **sobre** la fundación RLS de M6 (`0000_tenancy.sql`). Es a la gestión de equipo lo que `add-login` es a la auth: un drop-in que respeta R10 (Brand DNA), R14 (destructivas con confirmación tipada), L-003 (whitelist Zod), R16 (aislamiento de tenant), y hace handoff obligatorio a `el-guardian` pre-deploy.

NO reescribe la fundación: la **extiende** con `0005_teams.sql` (invitaciones + guardas anti-escalación + `accept_invitation` + `transfer_org_ownership`) y le pone cara. La doctrina completa vive en [`references/teams-model.md`](references/teams-model.md); la migración y su test negativo en `templates/supabase/migrations/0005_teams.sql` + `0005_teams-isolation.test.sql` — **son LEY; este skill los enlaza, no los redefine.**

> **Pattern boundary cross-skill:** add-teams **NO es binary/trinary de provider** (no hay "default friction-reducer + override"). Es un drop-in **condicional al shape del target**: existe sólo si la app es multi-tenant. Test diagnóstico [memory:lessons#L-004]: el degenerate case (single-tenant) NO requiere acción upstream del usuario sino que **niega la aplicabilidad del skill** → halt seco (no PAUSE, no fallback a otro provider). Mismo eje que la degradación de R16 (`[memory:CONSTRAINTS.md#R16]`).

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md? Si no → halt: "Forja no instalada."
2. ¿La app es multi-tenant (tenant_model.multi_tenant: true en SPEC/Tech Spec)? Si no
   → halt: "add-teams es exclusivo de multi-tenant. App single-tenant gobierna L-001
     (auth.uid() = user_id) — no hay tenants que gestionar."
3. ¿Existe la fundación 0000_tenancy.sql aplicada (tablas organizations + memberships +
   helpers auth_org_ids()/auth_has_org_role() + trigger creator→owner)? Si no
   → halt + handoff a el-migrador: "Aplicá la fundación M6 (0000_tenancy.sql) primero."
4. ¿Corrió add-login (auth + auth.users poblable)? Si no
   → halt + handoff a add-login: "Sin auth no hay auth.users a quién invitar."
5. ¿Existe brand/brand.json + voice.json? Si no
   → halt: "Falta Brand DNA. Corré /add-ui-kit primero. R10 no negociable."
6. ¿brand.json cumple R-005 v1.1.0 (schema_version + keyed spacing + motion enums)? Si no
   → halt: "brand.json malformado. Corré /add-ui-kit (regen)."
7. ¿Existen src/shared/components/ui/{Button,Input,Select,Card,ConfirmModal}/*.tsx (exportados por
   el barrel src/shared/components/ui/index.ts)? Si no
   → halt: "Faltan componentes base. Corré /impeccable Mode C primero." (la tabla de miembros usa
     <table role=table> semántica con tokens, no un componente Table dedicado.)
8. ¿Existe src/lib/cn.ts (helper)? Si no → halt mismo mensaje (impeccable lo provee).
```

Sin estos 8 gates, add-teams retorna error **sin generar código**.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide "agregame orgs / equipos / invitaciones / multi-tenant management" | Coordinator |
| `el-migrador` cerró la fundación M6 y el Tech Spec declara `tenant_model.multi_tenant: true` | el-migrador handoff |
| `la-herreria` detecta orgs/roles/invitaciones en las User Stories de una app multi-tenant | la-herreria handoff |
| Otro skill (add-payments per-seat, add-emails de invitación) requiere `organizations`/`memberships` de gestión y add-teams no corrió | skill handoff |

## Modo único — extensión de la fundación M6 (Supabase)

add-teams **no tiene selector de provider**: opera sobre la fundación que `el-migrador` ya dejó (`0000_tenancy.sql`, Supabase/Postgres). Si el target eligió InsForge por `baas`, la gestión de tenants se evalúa aparte (fuera del scope de este drop-in — halt con nota).

Flow:
```
a. find-docs (R13): resolve-library-id("supabase") + query-docs
   "RLS multi-tenant security definer policies WITH CHECK"
b. find-docs (R13): resolve-library-id("supabase-ssr") + query-docs
   "createServerClient cookies getAll setAll Next.js 16 server actions"
c. find-docs (R13): resolve-library-id("nextjs") + query-docs
   "App Router 16 Server Actions dynamic route [token]"
d. Read brand/brand.json + voice.json (R10 enforcement)
e. Substituir tokens en templates/supabase/** → src/**
   · placeholders {{ APP_NAME }}, {{ COPY_INVITE_CTA }}, etc.
   · imports apuntan a src/shared/components/ui/* (impeccable output)
f. Enlazar (NO reescribir) la migración 0005_teams.sql + su -isolation.test.sql
   en supabase/migrations/. La migración es LEY: nombres de tabla/columna/función/
   policy se respetan tal cual.
g. Generar server actions (src/actions/teams.ts) con R14 + L-003
h. Generar UI (src/features/teams/** + src/app/**) — ver prompts/generate-teams-ui.md
i. Security pre-handoff scan
j. Output handoff a el-guardian (prompts/handoff-el-guardian.md) + R7 Layer 4
```

Detalle de la UI: `prompts/generate-teams-ui.md`. Detalle del handoff: `prompts/handoff-el-guardian.md`.

## Loop de ejecución

```
0. PREFLIGHT halt (8 gates)

1. Pre-gen find-docs (R13):
   - resolve-library-id("supabase")     "RLS multi-tenant security definer WITH CHECK"
   - resolve-library-id("supabase-ssr") "createServerClient Next.js 16 server actions"
   - resolve-library-id("nextjs")       "App Router 16 dynamic route [token] Server Actions"

2. Read brand.json + voice.json (R10):
   - tokens.colors → CSS vars en componentes (vía impeccable)
   - voice.cta_examples → copy de "Invitar", "Crear organización", confirmaciones
   - voice.avoid_words → audit de strings hardcoded en pages/forms

3. Substituir templates → src/**
   · features/teams/components/* (OrgSwitcher, MembersList, InviteMemberForm,
     PendingInvitations, RoleSelect) + index.ts (barrel)
   · app/(app)/settings/teams/page.tsx  (gestión + ZONA PELIGROSA inline: rename/transfer/delete, R14)
   · app/invite/[token]/page.tsx        (landing de aceptación)
   · actions/teams.ts                   (las 9 server actions de teams-model §4 — R14 + L-003)
   · hooks/useOrganization.ts           (org activa client-side — cookie/localStorage, NO autoridad)
   · lib/teams/queries.ts               (reads server-side vía RLS — nunca service_role)

4. Enlazar migración (NO reescribir):
   · supabase/migrations/0005_teams.sql            ← templates/supabase/migrations/0005_teams.sql
   · supabase/migrations/0005_teams-isolation.test.sql
   · La migración define: invitations + guardas update/delete + guard_last_owner +
     accept_invitation() + transfer_org_ownership(). Nombres son contrato.

5. Security pre-handoff scan:
   · grep "service_role" en src/app|src/features → debe retornar vacío
   · server actions destructivas SIN execute() agentic (R14)
   · 0005_teams.sql contiene "enable row level security" en invitations
   · 0005_teams.sql contiene "with check" en "manage memberships update" (anti-escalación)
   · accept_invitation() contiene el match de email JWT↔invitación
   · guard_last_owner trigger presente
   · L-003: actions/teams.ts sin z.record(z.any()); role enum ∈ {admin,member}

6. Output handoff a el-guardian (pre-deploy) + R7 Layer 4:
   · Pasar el checklist de prompts/handoff-el-guardian.md (persona El Infiltrado)
   · el-migrador corre 0005_teams-isolation.test.sql sobre Postgres real (≥2 tenants):
     los 5 T-TEAM-* + control positivo DEBEN pasar (R7 Layer 4)
   · Bloquear deploy hasta que el-guardian retorne PASS y el test negativo esté verde
```

## Reglas operativas

1. **El modelo de rol de M6 es LEY (owner/admin/member) — no se inventan roles.** `owner` = todo (settings, borrar org, transferir propiedad), **exactamente 1 por org** (invariante). `admin` = invitar/expulsar/cambiar rol de members y admins, **NUNCA** tocar al owner ni auto-promoverse. `member` = lectura + aceptar invitaciones + salir. Ver `references/teams-model.md` §1.
2. **La autoridad se enforza en Postgres, no en el código (L-005).** RLS + funciones `security definer` + triggers son la frontera real. La UI sólo **refleja** (el consumidor oculta botones según el rol del caller); un cliente que llame la API directo igual rebota. Las lecturas de `lib/teams/queries.ts` pasan por el server client (anon key + sesión, RLS aplica) — **nunca service_role**.
3. **Invitaciones seguras (teams-model §2).** Sólo `owner`/`admin` crean invitaciones; `role` ∈ {admin, member}, **nunca owner**. El alta de membership ocurre SÓLO por el trigger creator→owner (0000) o por `accept_invitation()` (definer) — **no hay policy de INSERT en `memberships`**. El cliente nunca elige su rol ni inserta su membership.
4. **Anti-escalación de privilegios (teams-model §3).** La policy `manage memberships update` tiene `WITH CHECK` que prohíbe fijar `role='owner'` salvo que el caller sea owner (cierra admin→owner). Tocar/expulsar a un owner exige ser owner. El ascenso a owner ocurre SÓLO vía `transfer_org_ownership()` (atómico, definer, owner-only).
5. **Último owner protegido.** El trigger `guard_last_owner` aborta el delete/demote que dejaría 0 owners. Una org nunca queda huérfana; la propiedad se mueve con `transfer_org_ownership()`, jamás con un delete suelto.
6. **Robo de invitación cerrado.** `accept_invitation(token)` exige que el email del JWT del que acepta **coincida** con el email invitado. Token opaco (`gen_random_bytes`) + `expires_at` (7 días). El server llama la función definer; nunca inserta la membership a mano.
7. **R14 en destructivas.** `revokeInvitation`, `updateMemberRole`, `removeMember`, `leaveOrganization`, `transferOwnership`, `deleteOrganization` corren **tras confirmación tipada** (escribir el nombre de la org para transferir, el slug para borrar). La verificación del texto la hace la **server action** contra la fila REAL (lee `organizations.name`/`.slug` por RLS y compara), no el cliente — así la frontera de R14 vive server-side, igual que `api/auth/delete-account/route.ts` de add-login. **No** se exportan como tools agentic con `execute()` automático (R14 binario).
8. **L-003 en server actions.** Zod explícito por field; nada de `z.record(z.any())`. `role` validado contra enum `{admin, member}` (nunca owner por server action ordinaria). El `organization_id` jamás se confía del body sin que RLS lo valide (R16 invariante 3).
9. **R10 en toda la UI.** Componentes y pages importan `Button`/`Input`/`Select`/`Card`/`Table` desde el barrel `@/shared/components/ui` (output de `impeccable`). CERO Tailwind defaults (`bg-blue-500`, `text-gray-700`, `purple`, gradients sin justificar). CTAs derivan de `voice.cta_examples`. Brand Score ≥75 por página (lo valida `el-evaluador`).
10. **service_role isolation.** SÓLO en archivos server-only (`lib/supabase/server.ts` puede leerlo; `accept_invitation`/`transfer_org_ownership` son definer en la DB, no requieren service_role en la app). Las queries de `lib/teams/queries.ts` usan el server client con la sesión del caller, NUNCA service_role. Nada de service_role en componentes client ni en `src/app/**/page.tsx`. Audit en security pre-handoff.
11. **R18 — GitHub es espejo de una sola vía (S2).** Nada que genere add-teams escribe `feature_list.json` desde GitHub ni marca `passing` al cerrar un Issue. Las membresías de la app son datos de la app; la gobernanza del repo (CODEOWNERS/branch protection) la administra `el-capataz`, no este skill. No confundir el rol M6 de la app con el rol del roster de `.forja/team.json`.

## Refusals (lo que NUNCA hace)

- ❌ Reescribir o redefinir `0005_teams.sql` / `0005_teams-isolation.test.sql`. Son contrato: este skill los **enlaza**, no los muta.
- ❌ Inventar roles fuera de `owner`/`admin`/`member` (M6 es el vocabulario único).
- ❌ Crear una policy de INSERT en `memberships` (el alta es trigger creator→owner o `accept_invitation()`, nunca insert directo del cliente).
- ❌ Permitir que un server action o una policy fijen `role='owner'` por la vía ordinaria. El único camino a owner es `transfer_org_ownership()`.
- ❌ Quitar el `WITH CHECK` de `manage memberships update`, el `guard_last_owner`, o el match de email de `accept_invitation`. Cada uno es un kill-mutation del test negativo.
- ❌ Exportar `revokeInvitation`/`updateMemberRole`/`removeMember`/`leaveOrganization`/`transferOwnership`/`deleteOrganization` como tools agentic con `execute()`. R14 binario.
- ❌ Confiar el `organization_id` del body sin que RLS lo valide (R16 invariante 3).
- ❌ Generar UI con Tailwind hardcoded o copy que ignore `voice.json`. Siempre vía componentes impeccable + `voice.cta_examples`.
- ❌ Importar `service_role` en archivos accesibles desde client.
- ❌ Skipear el handoff a `el-guardian` ni el R7 Layer 4 (test negativo verde) pre-deploy.
- ❌ Editar `brand/**` (eso es add-ui-kit territory).
- ❌ Editar `.claude/memory/**` (R5 — sole writer es `el-evaluador`).
- ❌ Escribir `feature_list.json` desde GitHub ni marcar `passing` al cerrar un Issue (R18).

## Tool filter

Read · Grep · Glob · Bash (`npx tsc --noEmit` para L1; `psql --no-psqlrc -f` o `supabase migration check` para validar SQL syntax) · Write/Edit **solo** en:

- `src/features/teams/**`
- `src/app/**/teams/**` (page de gestión, ej. `src/app/(app)/settings/teams/page.tsx`)
- `src/app/invite/**` (landing de aceptación, `src/app/invite/[token]/page.tsx`)
- `src/actions/teams.ts`
- `src/hooks/useOrganization.ts`
- `src/lib/teams/**` (`queries.ts` y similares)
- `supabase/migrations/0005_*` (copiar/enlazar la migración + test; NO reescribir su cuerpo)

NO Edit en `brand/**` (add-ui-kit). NO Edit en `.claude/memory/**` (el-evaluador). NO Edit en `src/shared/components/ui/**` (impeccable).

**PROHIBIDO ABSOLUTO — alcance conceptual independiente de prefijo (E-009 causa 2):** los paths son patrones, NO literales. La restricción aplica con o sin prefijo.

- `**/proxy.ts` o `**/middleware.ts` ya escrito por add-login → APPEND quirúrgico (gating de org activa), NUNCA reescritura. Si ya define matcher/headers/lógica → halt + reportar.
- `**/app/(app)/layout.tsx` con providers ya escritos → APPEND (envolver con OrgProvider si aplica), NUNCA reescritura.
- Cualquier archivo bajo `**/src/features/teams/` ya existente → halt + confirmación humana antes de sobrescribir (el usuario puede tener gestión custom previa).
- `supabase/migrations/0005_teams.sql` ya presente con contenido distinto al template → halt + reportar (no pisar una migración del usuario).

Cita: [memory:errors#E-009].

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Schema canónico | `[memory:references#R-005]` | brand.json + voice.json reads |
| Constraint source | `[memory:CONSTRAINTS.md#R10]` | header de cada page/form de teams (R10 gate) |
| Constraint source | `[memory:CONSTRAINTS.md#R14]` | server actions destructivas + dialogs de confirmación |
| Constraint source | `[memory:CONSTRAINTS.md#R16]` | header de la migración + actions (aislamiento de tenant) |
| Constraint source | `[memory:CONSTRAINTS.md#R18]` | nota de no-escritura desde GitHub (S2) |
| Constraint source | `[memory:CONSTRAINTS.md#R13]` | header de prompts que generan código contra Supabase |
| Lessons | `[memory:lessons#L-005]` | migración + roles header (RLS por tenant) |
| Lessons | `[memory:lessons#L-003]` | actions/teams.ts validators header |
| Lessons | `[memory:lessons#L-004]` | rationale del pattern boundary (no provider selector) |
| External docs | `[docs:supabase]` `[docs:supabase-ssr]` `[docs:postgres]` `[docs:nextjs]` | cualquier código que use API |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `find-docs` | dependency. Pre-gen R13 invoca antes de generar (supabase + supabase-ssr + nextjs). |
| `el-migrador` | upstream **y** downstream. Upstream: aplicó `0000_tenancy.sql` (fundación M6). Downstream: aplica `0005_teams.sql` + corre `0005_teams-isolation.test.sql` (R7 Layer 4). |
| `add-login` | upstream. Sin auth no hay `auth.users` a quién invitar. Reusa `lib/supabase/{client,server}.ts`. |
| `add-ui-kit` | upstream. Sin brand.json + voice.json válidos, halt. |
| `impeccable` | upstream. La UI importa Button/Input/Select/Card/ConfirmModal del barrel de su output. Sin ellos, halt. |
| `el-guardian` | mandatory pre-deploy. Persona **El Infiltrado** audita cross-tenant + escalación de rol + robo de invitación + último owner + service_role isolation. |
| `el-evaluador` | post-gen valida L1 (tsc + sql syntax) + L2 (dry-run) + L3 (Brand Score per page + security pre-handoff). |
| `el-capataz` | sibling S2 (gobernanza GitHub-native). Consume el mismo vocabulario de roles M6 para CODEOWNERS/approvals, pero administra el repo, NO las orgs de la app. R18 los separa. |
| `add-payments` | downstream opcional. Billing per-seat / per-org consume `organizations`/`memberships` que este skill gestiona. |

## Output handoff

Tras pasar L1+L2+L3 + security pre-handoff + R7 Layer 4:

```markdown
## add-teams handoff

**Mode:** SUPABASE (extensión de fundación M6)
**Files generated:** N
**Output paths:**
- supabase/migrations/0005_teams.sql            (enlazada — contrato, no reescrita)
- supabase/migrations/0005_teams-isolation.test.sql
- src/actions/teams.ts                          (las 9 actions — R14 + L-003)
- src/hooks/useOrganization.ts
- src/lib/teams/queries.ts
- src/features/teams/components/{OrgSwitcher,MembersList,InviteMemberForm,PendingInvitations,RoleSelect}.tsx
- src/features/teams/components/index.ts
- src/app/(app)/settings/teams/page.tsx         (gestión + ZONA PELIGROSA inline OrgSettings, R14)
- src/app/invite/[token]/page.tsx

**Brand Score per page:**
| Page | tokens(25) | components(20) | accessibility(30) | anti-slop(15) | voice(10) | TOTAL |
|------|-----------|----------------|-------------------|---------------|-----------|-------|
| settings/teams (members + invite + danger zone) | ... | ... | ... | ... | ... | ≥75 |
| invite/[token] | ... | ... | ... | ... | ... | ≥75 |

**Security pre-handoff:**
- ✅ service_role NOT exposed in client (grep returned 0 hits in app/ y features/)
- ✅ RLS enabled on invitations + 3 policies (read/create/manage) con WITH CHECK
- ✅ manage memberships update tiene WITH CHECK anti-escalación (admin↛owner)
- ✅ guard_last_owner trigger presente (org nunca sin owner)
- ✅ accept_invitation() valida match de email JWT↔invitación
- ✅ transfer_org_ownership() es definer + owner-only + atómico
- ✅ NINGUNA server action destructiva exporta execute() automático (R14)
- ✅ L-003: actions/teams.ts sin z.record(z.any()); role ∈ {admin,member}

**R7 Layer 4 (test negativo cross-tenant — el-migrador sobre Postgres real):**
| Test | Amenaza | Estado |
|------|---------|--------|
| T-TEAM-1 | cross-tenant (leer/invitar en org ajena) | PASS |
| T-TEAM-2 | admin → owner (auto-ascenso) | PASS |
| T-TEAM-3 | admin expulsa/degrada al owner | PASS |
| T-TEAM-4 | robo de invitación (email distinto) | PASS |
| T-TEAM-5 | último owner (org sin owner) | PASS |
| CONTROL+ | owner invita y transfiere (flujo legítimo) | PASS |

**Citations:**
- [memory:references#R-005]
- [memory:CONSTRAINTS.md#R10] (Brand DNA) · [memory:CONSTRAINTS.md#R14] (destructivas)
- [memory:CONSTRAINTS.md#R16] (aislamiento de tenant) · [memory:CONSTRAINTS.md#R18] (espejo una vía)
- [memory:CONSTRAINTS.md#R13] (external docs)
- [memory:lessons#L-005] (RLS por tenant) · [memory:lessons#L-003] (whitelist validators)
- [docs:supabase] · [docs:supabase-ssr] · [docs:postgres] · [docs:nextjs]

**Mandatory next step:** invocar `el-guardian` con prompts/handoff-el-guardian.md como
checklist (persona El Infiltrado). Deploy BLOQUEADO hasta PASS y hasta que el test negativo
(0005_teams-isolation.test.sql) esté verde sobre Postgres real (R7 Layer 4).

**Frictions encountered (if any):**
- <listar campos del brand.json/voice.json ambiguos o faltantes>
- → Promote to errors.md as E-NNN if recurring
```

---

*"La frontera de la autoridad vive en Postgres. La UI sólo la dibuja. Si confundís las dos, El Infiltrado entra."*
