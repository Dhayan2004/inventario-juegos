-- 0000_tenancy.sql — Foundation multi-tenant de Forge Enterprise (M6)
--
-- Esquema base de aislamiento por tenant. Corre ANTES de 0001_profiles.sql.
-- Generaliza [memory:lessons#L-001] (auth.uid() = user_id) a [memory:lessons#L-005]
-- (organization_id + RLS por membresía). Doctrina: ../../../references/MULTI_TENANCY.md
-- Enforce: [memory:CONSTRAINTS.md#R16]. Citation: [docs:supabase] [docs:postgres]
--
-- TÉRMINO DEL TENANT configurable (organization | workspace | account | team). Este template usa
-- `organizations` / `organization_id`. Si el Tech Spec eligió otro término, renombrar de forma
-- CONSISTENTE en tabla, columna FK, helpers y policies (find/replace seguro, son nombres propios).
--
-- profiles (0001) NO lleva organization_id: la identidad del usuario es global (1:1 con auth.users);
-- la pertenencia a tenants vive en memberships (N:M). El tenant aplica a las ENTIDADES DE DOMINIO.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. organizations — el TENANT
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.organizations (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  created_by  uuid not null default auth.uid() references auth.users(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. memberships — usuario ↔ tenant (N:M), con rol
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.memberships (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  role             text not null default 'member' check (role in ('owner', 'admin', 'member')),
  created_at       timestamptz not null default now(),
  unique (organization_id, user_id)
);
create index if not exists memberships_user_idx on public.memberships(user_id);
create index if not exists memberships_org_idx  on public.memberships(organization_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Helpers SECURITY DEFINER — el corazón del aislamiento
--    security definer + search_path fijo: evitan la recursión de RLS (la policy de memberships
--    consultaría memberships → recursión). Al correr como owner, el select interno NO re-aplica RLS;
--    el filtro `user_id = auth.uid()` garantiza que sólo devuelven datos del PROPIO caller.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.auth_org_ids()
returns setof uuid
language sql stable security definer set search_path = public as $$
  select organization_id from public.memberships where user_id = auth.uid();
$$;

create or replace function public.auth_has_org_role(org uuid, roles text[])
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.memberships
    where user_id = auth.uid() and organization_id = org and role = any(roles)
  );
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Trigger: al crear una org, el creador se vuelve owner automáticamente.
--    security definer porque inserta la PRIMERA membership (antes no hay membresía que pase la policy).
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.handle_new_organization()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.memberships (organization_id, user_id, role)
  values (new.id, new.created_by, 'owner');
  return new;
end;
$$;

drop trigger if exists on_organization_created on public.organizations;
create trigger on_organization_created
  after insert on public.organizations
  for each row execute procedure public.handle_new_organization();

-- updated_at touch (reusa el patrón de 0001_profiles.sql si ya existe touch_updated_at)
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists organizations_touch_updated_at on public.organizations;
create trigger organizations_touch_updated_at
  before update on public.organizations
  for each row execute procedure public.touch_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. RLS de las tablas de tenancy
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.organizations enable row level security;
alter table public.memberships   enable row level security;

-- organizations: los miembros ven sus orgs; cualquier autenticado crea (y el trigger lo hace owner);
-- sólo owner/admin actualiza; sólo owner borra.
drop policy if exists "members read own orgs" on public.organizations;
create policy "members read own orgs" on public.organizations
  for select using (id in (select public.auth_org_ids()));

drop policy if exists "authenticated create org" on public.organizations;
create policy "authenticated create org" on public.organizations
  for insert to authenticated with check (created_by = auth.uid());

drop policy if exists "admins update org" on public.organizations;
create policy "admins update org" on public.organizations
  for update using      (public.auth_has_org_role(id, array['owner','admin']))
              with check (public.auth_has_org_role(id, array['owner','admin']));

drop policy if exists "owners delete org" on public.organizations;
create policy "owners delete org" on public.organizations
  for delete using (public.auth_has_org_role(id, array['owner']));

-- memberships: los miembros ven a sus co-miembros; sólo owner/admin invita/modifica/expulsa.
drop policy if exists "members read org memberships" on public.memberships;
create policy "members read org memberships" on public.memberships
  for select using (organization_id in (select public.auth_org_ids()));

drop policy if exists "admins manage memberships" on public.memberships;
create policy "admins manage memberships" on public.memberships
  for all using      (public.auth_has_org_role(organization_id, array['owner','admin']))
          with check (public.auth_has_org_role(organization_id, array['owner','admin']));

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. PLANTILLA por ENTIDAD DE DOMINIO (copiar por cada tabla tenant-scoped)
--    Los 3 invariantes no-negociables (R16): organization_id NOT NULL + WITH CHECK + cliente no confiado.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- create table if not exists public.<entidad> (
--   id               uuid primary key default gen_random_uuid(),
--   organization_id  uuid not null references public.organizations(id) on delete cascade,  -- INVARIANTE 1
--   -- ... columnas de dominio ...
--   created_at       timestamptz not null default now()
-- );
-- create index if not exists <entidad>_org_idx on public.<entidad>(organization_id);
-- alter table public.<entidad> enable row level security;
--
-- create policy "<entidad> tenant isolation: select" on public.<entidad>
--   for select using (organization_id in (select public.auth_org_ids()));
--
-- create policy "<entidad> tenant isolation: write" on public.<entidad>            -- INVARIANTE 2 (WITH CHECK)
--   for all using      (organization_id in (select public.auth_org_ids()))
--           with check (organization_id in (select public.auth_org_ids()));        -- INVARIANTE 3 (no IDOR)

-- ═════════════════════════════════════════════════════════════════════════════
-- ROLLBACK — copiar a 0000_tenancy.rollback.sql (drop en orden inverso)
-- ═════════════════════════════════════════════════════════════════════════════
-- drop trigger  if exists on_organization_created on public.organizations;
-- drop trigger  if exists organizations_touch_updated_at on public.organizations;
-- drop function if exists public.handle_new_organization();
-- drop function if exists public.auth_has_org_role(uuid, text[]);
-- drop function if exists public.auth_org_ids();
-- drop table    if exists public.memberships;
-- drop table    if exists public.organizations;
