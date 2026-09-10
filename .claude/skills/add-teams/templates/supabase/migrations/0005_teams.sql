-- 0005_teams.sql — Gestión de equipos/tenants de Forge Enterprise (S2 · add-teams)
--
-- Capa de GESTIÓN sobre la fundación multi-tenant de M6 (0000_tenancy.sql). NO redefine
-- organizations/memberships/helpers — los EXTIENDE con invitaciones + las guardas de rol que la
-- gestión de equipo necesita (anti-escalación de privilegios, protección del último owner).
--
-- Requiere: 0000_tenancy.sql aplicado (organizations, memberships, auth_org_ids(),
--           auth_has_org_role(), trigger creator→owner). Corre DESPUÉS de él.
-- Doctrina: ../../../references/teams-model.md · ../../../../references/MULTI_TENANCY.md
-- Enforce:  [memory:CONSTRAINTS.md#R16] (3 invariantes) + [memory:lessons#L-005] (RLS por tenant).
-- Roles:    owner | admin | member (definidos en 0000_tenancy.sql).
-- Citation: [docs:supabase] [docs:postgres]
--
-- MODELO DE ROL (el contrato de autoridad — ver teams-model.md):
--   owner  → todo, incluyendo borrar la org y transferir la propiedad. Exactamente 1 por org (invariante).
--   admin  → invitar/expulsar/cambiar rol de members y admins; NUNCA crear/tocar un owner ni auto-promoverse.
--   member → solo lectura de su org y co-miembros.

-- ═════════════════════════════════════════════════════════════════════════════
-- 1. invitations — invitar usuarios a una org por email + token
-- ═════════════════════════════════════════════════════════════════════════════
create table if not exists public.invitations (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,  -- INVARIANTE 1 (R16)
  email            text not null,
  role             text not null default 'member' check (role in ('admin', 'member')),   -- NUNCA se invita como owner
  token            text not null unique default encode(gen_random_bytes(32), 'hex'),     -- secreto del link de aceptación
  status           text not null default 'pending' check (status in ('pending', 'accepted', 'revoked', 'expired')),
  invited_by       uuid not null default auth.uid() references auth.users(id),
  created_at       timestamptz not null default now(),
  expires_at       timestamptz not null default (now() + interval '7 days'),
  accepted_at      timestamptz,
  accepted_by      uuid references auth.users(id)
);
create index if not exists invitations_org_idx   on public.invitations(organization_id);
create index if not exists invitations_email_idx on public.invitations(lower(email));
-- una sola invitación PENDIENTE por (org, email) — no se spamea ni se duplica
create unique index if not exists invitations_unique_pending
  on public.invitations(organization_id, lower(email))
  where status = 'pending';

-- ═════════════════════════════════════════════════════════════════════════════
-- 2. Guardas de rol en memberships — endurecen la policy base de 0000_tenancy.sql
--    La policy "admins manage memberships" (for all) de la fundación es DELIBERADAMENTE amplia
--    (bootstrap). Para gestión de equipo la reemplazamos por policies por-operación que impiden
--    la ESCALACIÓN DE PRIVILEGIOS (un admin haciéndose owner / tocando al owner).
-- ═════════════════════════════════════════════════════════════════════════════
drop policy if exists "admins manage memberships" on public.memberships;

-- UPDATE de rol: owner/admin pueden, PERO un admin no puede tocar a un owner ni ascender a nadie a owner.
-- (el ascenso a owner sólo ocurre vía transfer_org_ownership(), abajo — atómico y owner-only.)
drop policy if exists "manage memberships update" on public.memberships;
create policy "manage memberships update" on public.memberships
  for update
  using (
    public.auth_has_org_role(organization_id, array['owner','admin'])
    and (role <> 'owner' or public.auth_has_org_role(organization_id, array['owner']))  -- tocar a un owner ⇒ ser owner
  )
  with check (
    public.auth_has_org_role(organization_id, array['owner','admin'])
    and (role <> 'owner' or public.auth_has_org_role(organization_id, array['owner']))  -- fijar role=owner ⇒ ser owner
  );

-- DELETE (expulsar): owner/admin; un admin no puede expulsar a un owner.
drop policy if exists "manage memberships delete" on public.memberships;
create policy "manage memberships delete" on public.memberships
  for delete
  using (
    public.auth_has_org_role(organization_id, array['owner','admin'])
    and (role <> 'owner' or public.auth_has_org_role(organization_id, array['owner']))
  );

-- INSERT directo a memberships: NADIE por RLS. Los miembros entran SOLO por el trigger creator→owner
-- (0000) o por accept_invitation() (definer, abajo). Sin policy de insert ⇒ insert directo del cliente
-- es rechazado por RLS (fail-closed). Esto cierra el vector "admin inserta una membership arbitraria".

-- Protección del ÚLTIMO OWNER: una org nunca puede quedarse sin owner (ni por delete ni por demote).
create or replace function public.guard_last_owner()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  org_id uuid := coalesce(old.organization_id, new.organization_id);
  owners_left int;
begin
  -- ¿se está quitando/degradando un owner?
  if old.role = 'owner' and (tg_op = 'DELETE' or new.role <> 'owner') then
    select count(*) into owners_left
    from public.memberships
    where organization_id = org_id and role = 'owner'
      and id <> old.id;
    if owners_left = 0 then
      raise exception 'cannot remove or demote the last owner of the organization (transfer ownership first)';
    end if;
  end if;
  return coalesce(new, old);
end;
$$;
drop trigger if exists memberships_guard_last_owner on public.memberships;
create trigger memberships_guard_last_owner
  before update or delete on public.memberships
  for each row execute procedure public.guard_last_owner();

-- ═════════════════════════════════════════════════════════════════════════════
-- 3. RLS de invitations
-- ═════════════════════════════════════════════════════════════════════════════
alter table public.invitations enable row level security;

-- LEER: owner/admin de la org ven sus invitaciones; ADEMÁS el invitado ve las suyas (por su email del JWT)
-- para poder aceptarlas aunque todavía no sea miembro.
drop policy if exists "invitations read" on public.invitations;
create policy "invitations read" on public.invitations
  for select using (
    public.auth_has_org_role(organization_id, array['owner','admin'])
    or lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

-- CREAR: sólo owner/admin de la org, y nunca con role='owner' (el check de la tabla ya lo impide).
-- INVARIANTE 3 (R16): el organization_id no se confía del cliente — WITH CHECK lo valida contra la membresía real.
drop policy if exists "invitations create" on public.invitations;
create policy "invitations create" on public.invitations
  for insert to authenticated
  with check (
    public.auth_has_org_role(organization_id, array['owner','admin'])
    and invited_by = auth.uid()
  );

-- ACTUALIZAR (revocar / reenviar): sólo owner/admin de la org. INVARIANTE 2 (R16): WITH CHECK además del USING.
drop policy if exists "invitations manage" on public.invitations;
create policy "invitations manage" on public.invitations
  for update
  using      (public.auth_has_org_role(organization_id, array['owner','admin']))
  with check (public.auth_has_org_role(organization_id, array['owner','admin']));

-- ═════════════════════════════════════════════════════════════════════════════
-- 4. accept_invitation() — el camino SEGURO para que un invitado se vuelva miembro
--    SECURITY DEFINER porque el invitado todavía NO es miembro (ninguna policy de insert lo dejaría).
--    El definer valida token + estado + expiración + que el email del JWT coincide con la invitación,
--    y SÓLO entonces inserta la membership con el rol invitado. El cliente nunca elige su rol.
-- ═════════════════════════════════════════════════════════════════════════════
create or replace function public.accept_invitation(invite_token text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  inv public.invitations%rowtype;
  caller_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
begin
  if auth.uid() is null then
    raise exception 'must be authenticated to accept an invitation';
  end if;

  select * into inv from public.invitations where token = invite_token for update;
  if not found then
    raise exception 'invitation not found';
  end if;
  if inv.status <> 'pending' then
    raise exception 'invitation is no longer pending (status: %)', inv.status;
  end if;
  if inv.expires_at < now() then
    update public.invitations set status = 'expired' where id = inv.id;
    raise exception 'invitation has expired';
  end if;
  -- el email del invitado DEBE coincidir con el de la cuenta que acepta (anti-robo de invitación)
  if caller_email = '' or lower(inv.email) <> caller_email then
    raise exception 'invitation email does not match the authenticated account';
  end if;
  -- ...y DEBE estar VERIFICADO. Que el email coincida no basta: si la instancia tiene desactivada la
  -- confirmación de email (default frecuente en self-hosted/dev), un atacante se registra con el email de
  -- la víctima sin probar posesión del buzón y su JWT lo lleva igual. Lo validamos contra el timestamp
  -- REAL de auth.users (el definer puede leerlo) — no contra un claim del JWT, que es spoofeable.
  if not exists (
    select 1 from auth.users where id = auth.uid() and email_confirmed_at is not null
  ) then
    raise exception 'email must be verified before accepting an invitation';
  end if;

  -- alta idempotente: si ya es miembro, no duplica (unique org_id,user_id de 0000)
  insert into public.memberships (organization_id, user_id, role)
  values (inv.organization_id, auth.uid(), inv.role)
  on conflict (organization_id, user_id) do nothing;

  update public.invitations
    set status = 'accepted', accepted_at = now(), accepted_by = auth.uid()
    where id = inv.id;

  return inv.organization_id;
end;
$$;

-- ═════════════════════════════════════════════════════════════════════════════
-- 5. transfer_org_ownership() — el ÚNICO camino para mover la propiedad (atómico, owner-only)
--    Resuelve el dilema "no puede haber 2 owners y no puede quedar 0": degrada al owner actual a
--    admin y promueve al nuevo, en una sola transacción. SECURITY DEFINER para saltar el guard del
--    último-owner durante el intercambio (la función garantiza el invariante por su cuenta).
-- ═════════════════════════════════════════════════════════════════════════════
create or replace function public.transfer_org_ownership(org uuid, new_owner uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.auth_has_org_role(org, array['owner']) then
    raise exception 'only the current owner can transfer ownership';
  end if;
  if not exists (select 1 from public.memberships where organization_id = org and user_id = new_owner) then
    raise exception 'the new owner must already be a member of the organization';
  end if;

  update public.memberships set role = 'admin'
    where organization_id = org and role = 'owner';
  update public.memberships set role = 'owner'
    where organization_id = org and user_id = new_owner;
end;
$$;

-- ═════════════════════════════════════════════════════════════════════════════
-- ROLLBACK — copiar a 0005_teams.rollback.sql (drop en orden inverso)
-- ═════════════════════════════════════════════════════════════════════════════
-- drop function if exists public.transfer_org_ownership(uuid, uuid);
-- drop function if exists public.accept_invitation(text);
-- drop trigger  if exists memberships_guard_last_owner on public.memberships;
-- drop function if exists public.guard_last_owner();
-- drop policy   if exists "invitations manage" on public.invitations;
-- drop policy   if exists "invitations create" on public.invitations;
-- drop policy   if exists "invitations read"   on public.invitations;
-- drop policy   if exists "manage memberships delete" on public.memberships;
-- drop policy   if exists "manage memberships update" on public.memberships;
-- drop table    if exists public.invitations;
-- -- restaurar la policy amplia de la fundación si se revierte add-teams:
-- create policy "admins manage memberships" on public.memberships
--   for all using      (public.auth_has_org_role(organization_id, array['owner','admin']))
--           with check (public.auth_has_org_role(organization_id, array['owner','admin']));
