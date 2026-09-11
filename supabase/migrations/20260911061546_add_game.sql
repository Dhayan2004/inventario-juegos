-- 20260911061546_add_game.sql
-- Entidad `game` — BLUEPRINT-inventario-juegos.md §3.
--
-- App de usuario único, sin auth (BLUEPRINT §0 "Usuarios"). L-001 exige RLS activo en
-- toda tabla de datos del usuario; sin `auth.users` no hay `user_id` que aislar, así que
-- la RLS aquí es deny-all para `anon`/`authenticated` — el único acceso es server-side vía
-- service role key (bypassa RLS por diseño de Supabase), nunca desde el cliente.

create table if not exists public.game (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) > 0),
  platform text not null check (platform in ('PC', 'PlayStation', 'Xbox', 'Nintendo Switch', 'Retro', 'Otro')),
  genre text,
  status text not null default 'owned' check (status in ('owned', 'wishlist', 'playing', 'completed', 'abandoned')),
  format text check (format in ('physical', 'digital')),
  quantity integer not null default 1 check (quantity >= 1),
  purchase_price numeric(12, 2) check (purchase_price >= 0),
  purchase_date date,
  rating integer check (rating between 1 and 10),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.game is 'Inventario de videojuegos — BLUEPRINT §3. App single-user, sin auth.';

create or replace function public.set_game_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger game_set_updated_at
  before update on public.game
  for each row
  execute function public.set_game_updated_at();

create index if not exists game_platform_idx on public.game (platform);
create index if not exists game_status_idx on public.game (status);
create index if not exists game_created_at_idx on public.game (created_at);

alter table public.game enable row level security;

-- Deny-all explícito: sin auth no hay predicado de propietario que declarar (L-001
-- degrada a "nadie entra por el cliente"). El acceso real ocurre server-side con la
-- service role key, que bypassa RLS por construcción — estas policies documentan y
-- refuerzan que ninguna key pública (anon/authenticated) puede tocar `game`.
create policy "game_deny_all_anon" on public.game
  for all
  to anon
  using (false)
  with check (false);

create policy "game_deny_all_authenticated" on public.game
  for all
  to authenticated
  using (false)
  with check (false);
