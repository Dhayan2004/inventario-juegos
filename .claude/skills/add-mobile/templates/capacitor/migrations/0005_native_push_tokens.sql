-- 0005_native_push_tokens.sql (Capacitor Mode B)
--
-- Paralela a push_subscriptions (Mode A). Almacena FCM/APNs tokens desde
-- Capacitor app native. Backend send pipeline chequea ambas tablas según
-- runtime del cliente.
--
-- Cita: [memory:lessons#L-001] · [memory:CONSTRAINTS.md#R14]

create table if not exists public.native_push_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android', 'web')),
  app_version text,
  device_name text,
  created_at timestamptz default now(),
  last_used_at timestamptz default now(),
  unique (user_id, token)
);

create index if not exists idx_native_push_tokens_user
  on public.native_push_tokens(user_id);

alter table public.native_push_tokens enable row level security;

-- L-001: 3 policies user-scoped (mismo pattern que push_subscriptions)
create policy "users read own native tokens" on public.native_push_tokens
  for select using (auth.uid() = user_id);

create policy "users create own native tokens" on public.native_push_tokens
  for insert with check (auth.uid() = user_id);

create policy "users delete own native tokens" on public.native_push_tokens
  for delete using (auth.uid() = user_id);
