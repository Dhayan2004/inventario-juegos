-- 0001_profiles.sql
--
-- Profiles table — public.profiles 1:1 con auth.users.
--
-- L-001 enforcement: tabla persiste datos derivados de input del usuario
-- (signup metadata, profile edits). RLS habilitado + 2 policies + trigger
-- handle_new_user con security definer (necesario para insert pre-session).
-- Cita: [memory:lessons#L-001]
--
-- Citation grammar: [docs:supabase] [docs:postgres]

-- 1. Tabla profiles
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  full_name text,
  avatar_url text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- 2. RLS habilitado (L-001 binary check)
alter table public.profiles enable row level security;

-- 3. Policies — auth.uid() = id (own profile only)
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Hardening por COLUMNA (U-01, patrón F-001 de forge-cloud). RLS filtra por
-- FILA, no por columna: sin esto, en cuanto la tabla gane una columna de
-- privilegio (rol, organization_id, es_admin) el usuario se la auto-otorga en
-- su propia fila sin violar ninguna policy. Columnas de negocio SOLO las
-- escribe el server (service_role); `authenticated` solo edita display.
revoke update on public.profiles from authenticated, anon;
grant update (full_name, avatar_url) on public.profiles to authenticated;

-- 4. Trigger handle_new_user — crea profile automaticamente al signup
-- security definer: necesario para que el insert atraviese RLS al momento
-- del signup donde no hay session aún.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name'
    ),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 5. updated_at touch trigger
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute procedure public.touch_updated_at();
