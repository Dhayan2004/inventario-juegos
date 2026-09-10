-- 0004b_expo_push_tokens.sql (RN+Expo Mode C — codebase paralelo)
--
-- Paralela a push_subscriptions (Mode A) y native_push_tokens (Mode B).
-- Mode C usa Expo Push Service tokens (NO FCM/APNs direct ni Web Push
-- subscriptions). Backend send pipeline puede coexistir con las otras
-- tablas si proyecto soporta web + native simultáneamente.
--
-- Cita: [memory:lessons#L-001]

create table if not exists public.expo_push_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android')),
  device_name text,
  app_version text,
  created_at timestamptz default now(),
  last_used_at timestamptz default now(),
  unique (user_id, token)
);

create index if not exists idx_expo_push_tokens_user
  on public.expo_push_tokens(user_id);

alter table public.expo_push_tokens enable row level security;

-- L-001: 3 policies user-scoped
create policy "users read own expo tokens" on public.expo_push_tokens
  for select using (auth.uid() = user_id);

create policy "users insert own expo tokens" on public.expo_push_tokens
  for insert with check (auth.uid() = user_id);

create policy "users delete own expo tokens" on public.expo_push_tokens
  for delete using (auth.uid() = user_id);
