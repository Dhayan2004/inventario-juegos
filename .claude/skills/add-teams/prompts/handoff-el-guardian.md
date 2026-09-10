# Handoff a el-guardian — Pre-deploy Security Checklist (add-teams)

> Este documento se invoca al cierre de add-teams. `el-guardian` usa Codex como "segundo cerebro"
> (modelo distinto al que generó el código) para auditar adversarialmente la gestión de tenants antes
> de `/despachar`. Persona de ataque dominante: **El Infiltrado** (Capa 3, cruza el modelo de amenazas
> T1–T9 de `MULTI_TENANCY.md`). **Sin PASS de el-guardian Y sin el test negativo verde (R7 Layer 4),
> deploy bloqueado.**

## Contexto

add-teams generó/enlazó:
- `supabase/migrations/0005_teams.sql` (invitations + guardas anti-escalación + `guard_last_owner` + `accept_invitation()` + `transfer_org_ownership()`) — **contrato, no reescrito**
- `supabase/migrations/0005_teams-isolation.test.sql` (los 5 T-TEAM-* + control positivo)
- `src/actions/teams.ts` (server actions R14 + L-003)
- `src/hooks/useOrganization.ts` + `src/lib/teams/queries.ts`
- 5 componentes + barrel en `src/features/teams/components/` + 2 pages (`(app)/settings/teams`, `invite/[token]`)

La autoridad real vive en Postgres (RLS + definer + triggers). La UI sólo refleja. El Infiltrado ataca
asumiendo que el cliente llama la API **directo, sin pasar por la UI**.

## Checklist obligatorio

### 1. Cross-tenant — aislamiento de org (R16 · T-TEAM-1)

```
✓ Toda lectura/escritura de invitations y memberships filtra por organization_id vía
  auth_has_org_role() (R16 invariante 1)
✓ El organization_id NUNCA se confía del body sin que RLS lo valide (R16 invariante 3)
✓ Las policies tienen USING **y** WITH CHECK (R16 invariante 2)
```

Comando audit:
```bash
SQL=supabase/migrations/0005_teams.sql
grep -q "auth_has_org_role" "$SQL"          # presente
grep -c "with check"        "$SQL"          # ≥3 (invitations create + manage, memberships update)
grep -rn "organization_id" src/actions/teams.ts   # revisar que viene de la sesión/RLS, no crudo del body
```
Negative test: **T-TEAM-1** debe estar verde (owner de B no ve ni invita en A).

### 2. Escalación admin → owner (anti-privilege-escalation · T-TEAM-2)

```
✓ Policy "manage memberships update" tiene WITH CHECK que prohíbe role='owner' salvo caller owner
✓ NINGÚN server action fija role='owner' por la vía ordinaria (updateMemberRole valida ∈ {admin,member})
✓ No existe policy de INSERT en memberships (alta = trigger creator→owner o accept_invitation())
```

Comando audit:
```bash
SQL=supabase/migrations/0005_teams.sql
grep -q "manage memberships update" "$SQL"
grep -q "role <> 'owner' or public.auth_has_org_role" "$SQL"   # la guarda anti-escalación
grep -E "role.*owner" src/actions/teams.ts                     # updateMemberRole NUNCA acepta owner
# Esperado: el enum de role en el schema Zod es {admin, member}, sin owner
```
Negative test: **T-TEAM-2** verde (un admin no se auto-asciende a owner).

### 3. Admin tocando al owner (expulsar/degradar · T-TEAM-3)

```
✓ Policies update/delete de memberships exigen ser owner para tocar una fila role='owner'
✓ removeMember rechaza expulsar a un owner si el caller no es owner (refleja la RLS)
```

Comando audit:
```bash
SQL=supabase/migrations/0005_teams.sql
grep -q "manage memberships delete" "$SQL"
grep -c "role <> 'owner' or public.auth_has_org_role" "$SQL"   # ≥3 (update using/check + delete using)
```
Negative test: **T-TEAM-3** verde (un admin no expulsa/degrada al owner).

### 4. Robo de invitación (anti-invitation-theft · T-TEAM-4)

```
✓ accept_invitation(token) valida: token existe · status='pending' · no expirada ·
  email del JWT == email invitado (lower-case match)
✓ El token es opaco (gen_random_bytes), no adivinable; con expires_at (7 días)
✓ La landing /invite/[token] trata el token como DATO (L-002), no lo parsea ni confía
✓ El cliente NUNCA elige su rol al aceptar (lo fija la invitación)
```

Comando audit:
```bash
SQL=supabase/migrations/0005_teams.sql
grep -q "does not match the authenticated account" "$SQL"   # el chequeo de email
grep -q "gen_random_bytes" "$SQL"                           # token secreto
grep -q "expires_at" "$SQL"
grep -q "L-002" src/app/invite/*/page.tsx
```
Negative test: **T-TEAM-4** verde (aceptar con email distinto al invitado falla y NO crea membership).

### 5. Último owner (org-never-ownerless · T-TEAM-5)

```
✓ Trigger guard_last_owner aborta el delete/demote que dejaría 0 owners
✓ transfer_org_ownership() es SECURITY DEFINER + owner-only + atómico (degrada owner→admin y
  promueve al nuevo en una transacción) — el único camino a owner
✓ leaveOrganization de un owner exige transferir primero (refleja el guard)
```

Comando audit:
```bash
SQL=supabase/migrations/0005_teams.sql
grep -q "guard_last_owner" "$SQL"
grep -q "cannot remove or demote the last owner" "$SQL"
grep -q "transfer_org_ownership" "$SQL"
grep -q "only the current owner can transfer ownership" "$SQL"
```
Negative test: **T-TEAM-5** verde (el último owner no puede auto-degradarse).

### 6. service_role / secret isolation

```
✓ NO `service_role` ni `SUPABASE_SERVICE_ROLE_KEY` en componentes/pages client
  (src/features/teams/**, src/app/(app)/settings/teams/**, src/app/invite/**)
✓ lib/teams/queries.ts usa el server client (anon key + sesión), NUNCA service_role
✓ accept_invitation / transfer_org_ownership son definer en la DB — NO requieren service_role en la app
✓ env vars privadas SIN prefix NEXT_PUBLIC_
```

Comando audit:
```bash
grep -rn "service_role\|SERVICE_ROLE" \
  src/features/teams/ src/app/ \
  2>/dev/null
# Esperado: 0 hits
```

### 7. R14 — destructivas sin execute() automático

```
✓ revokeInvitation / updateMemberRole / removeMember / leaveOrganization /
  transferOwnership / deleteOrganization NO se exportan como tools agentic con execute()
✓ transfer/delete corren tras confirmación TIPADA verificada SERVER-SIDE: la action lee
  organizations.name/.slug REAL por RLS y compara con confirm_name/confirm_slug antes de proceder
✓ removeMember/updateMemberRole/revokeInvitation usan ConfirmModal (gate humano) antes de disparar
```

Comando audit:
```bash
grep -E "execute:\s*async" src/actions/teams.ts
# Esperado: 0 matches

# La verificación de confirmación vive en la server action (no sólo en el cliente):
grep -E "confirm_name|confirm_slug" src/actions/teams.ts
grep -E "org\.name !== parsed\.confirm_name|org\.slug !== parsed\.confirm_slug" src/actions/teams.ts
# Esperado: ≥1 match cada uno (gate R14 server-side contra la fila real)

# Y el gate humano en la UI (ConfirmModal / form con confirm field):
grep -rE "ConfirmModal|confirm_name|confirm_slug" src/features/teams/ src/app/ | head
# Esperado: ≥1 gate por destructiva
```

### 8. L-003 — whitelist validation en server actions

```
✓ inviteMember valida email con whitelist (z.string().email().max(254))
✓ role validado contra enum {admin, member} (NUNCA owner)
✓ NO z.record(z.any()) en actions/teams.ts
✓ slug/name de org bounded (min/max)
```

Comando audit:
```bash
grep -E "z\.string\(\)\.email\(\)" src/actions/teams.ts
grep -E "z\.enum\(\['admin', ?'member'\]\)" src/actions/teams.ts
# z.record(z.any()) sólo como CÓDIGO (excluir comentarios que lo mencionan como prohibido):
grep -nE "z\.record\(z\.any\(\)\)" src/actions/teams.ts | grep -vE "^\s*[0-9]+:\s*//"
# Esperado: primeros 2 presentes; el tercero 0 hits de código (las menciones en comentarios no cuentan)
```

### 9. RLS WITH CHECK en invitations (R16 invariante 2)

```
✓ invitations tiene `enable row level security`
✓ Policy "invitations create" con WITH CHECK = auth_has_org_role(org, owner/admin) AND invited_by = auth.uid()
✓ Policy "invitations manage" con USING **y** WITH CHECK
✓ Índice unique parcial impide >1 invitación pendiente por (org, email)
```

Comando audit:
```bash
SQL=supabase/migrations/0005_teams.sql
grep -q "alter table public.invitations enable row level security" "$SQL"
grep -q "invited_by = auth.uid()" "$SQL"
grep -q "invitations_unique_pending" "$SQL"
```

### 10. R7 Layer 4 — test negativo verde sobre Postgres real

```
✓ el-migrador corrió 0005_teams-isolation.test.sql contra una DB con 0000_tenancy.sql + 0005_teams.sql
✓ Los 5 T-TEAM-* + el control positivo pasan (≥2 tenants sembrados)
✓ Kill-mutation validado: quitar una guarda DEBE poner en rojo algún T-TEAM-* (si todo sigue verde
  tras remover el WITH CHECK / el guard / el match de email, el test es inútil — arreglarlo primero)
```

Comando (referencial — lo corre el-migrador):
```bash
psql "$TEST_DB_URL" -v ON_ERROR_STOP=1 \
  -f supabase/migrations/0000_tenancy.sql \
  -f supabase/migrations/0005_teams.sql \
  -f supabase/migrations/0005_teams-isolation.test.sql
# Exit 0 + ninguna excepción "LEAK ..." = PASS
```

## Severidades

| Severity | Examples | Block deploy? |
|----------|----------|---------------|
| critical | admin puede ascenderse a owner; cross-tenant leak en invitations/memberships; service_role en client; org puede quedar sin owner | yes |
| high | accept_invitation sin match de email (robo de invitación); destructiva con execute() automático; INSERT policy directa en memberships; falta WITH CHECK en update | yes |
| medium | falta JSDoc citation; gating sólo en UI sin RLS detrás (si la RLS igual existe, baja a low); logs con email/PII | no, fix antes de prod |
| low | copy con avoid_words; falta `<th scope>` en la tabla de miembros | no, fix antes de prod |

PASS = 0 critical + 0 high **y** los 5 T-TEAM-* verdes.

## Output esperado

```markdown
# Security Audit — add-teams (El Infiltrado)

**Status:** PASS | NEEDS_FIX | FAIL

**Findings:**
- [critical] ... | none
- [high] ... | none
- [medium] ... | none
- [low] ... | none

**Negative test (R7 Layer 4) — Postgres real, ≥2 tenants:**
- [ ] T-TEAM-1 cross-tenant ......... PASS/FAIL
- [ ] T-TEAM-2 admin→owner .......... PASS/FAIL
- [ ] T-TEAM-3 admin toca owner ..... PASS/FAIL
- [ ] T-TEAM-4 robo de invitación ... PASS/FAIL
- [ ] T-TEAM-5 último owner ......... PASS/FAIL
- [ ] CONTROL+ flujo legítimo ....... PASS/FAIL

**Manual gates pending:**
- [ ] el-migrador aplicó 0005_teams.sql en la DB del entorno
- [ ] Política de expiración de invitaciones (7 días) confirmada con el usuario

**Deploy gate:** UNBLOCKED | BLOCKED

**Recommendations:**
- ...
```

Si BLOCKED → add-teams retorna NEEDS_FIX a `el-evaluador` con los gaps específicos. el-evaluador decide
regenerate (UI/actions) o handoff manual (si el gap está en la migración, que es contrato — escalá al
usuario antes de tocar `0005_teams.sql`).

## Citations

- [memory:lessons#L-005] (RLS por tenant) · [memory:lessons#L-003] (whitelist) · [memory:lessons#L-002] (payload externo)
- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R13] · [memory:CONSTRAINTS.md#R14] · [memory:CONSTRAINTS.md#R16] · [memory:CONSTRAINTS.md#R7]
- [memory:references#R-005]
- `references/teams-model.md` §3 (anti-escalación) · `MULTI_TENANCY.md` (T1–T9)
- [docs:supabase] · [docs:postgres]
