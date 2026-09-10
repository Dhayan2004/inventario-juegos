-- 0004_push_subscriptions.sql
--
-- Push subscription state + topic preferences + admin audit.
-- RLS L-001 enforced en push_subscriptions con 3 policies (SELECT/INSERT/DELETE
-- auth.uid()=user_id). NO UPDATE direct — last_used_at via service_role en
-- send route.
--
-- Cita: [memory:lessons#L-001] · [memory:CONSTRAINTS.md#R14]
-- @see prompts/setup-pwa.md · prompts/generate-push-subscription.md

-- ============================================================================
-- push_subscriptions (per-device subscription tracking)
-- ============================================================================
create table if not exists public.push_subscriptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  device_name text,
  browser text,
  user_agent text,
  created_at timestamptz default now(),
  last_used_at timestamptz default now(),
  unique (user_id, endpoint)
);

create index if not exists idx_push_subs_user
  on public.push_subscriptions(user_id);
create index if not exists idx_push_subs_endpoint
  on public.push_subscriptions(endpoint);

alter table public.push_subscriptions enable row level security;

-- L-001: 3 policies user-scoped
create policy "users read own subscriptions" on public.push_subscriptions
  for select using (auth.uid() = user_id);

create policy "users create own subscriptions" on public.push_subscriptions
  for insert with check (auth.uid() = user_id);

create policy "users delete own subscriptions" on public.push_subscriptions
  for delete using (auth.uid() = user_id);

-- NO UPDATE direct policy — last_used_at via service_role en send route.

-- ============================================================================
-- push_topic_preferences (per-user topic opt-in/opt-out)
-- ============================================================================
create table if not exists public.push_topic_preferences (
  user_id uuid not null references auth.users(id) on delete cascade,
  topic text not null check (topic in (
    'system', 'alerts', 'updates', 'social', 'marketing'
  )),
  enabled boolean default true,
  primary key (user_id, topic)
);

alter table public.push_topic_preferences enable row level security;

create policy "users read own preferences" on public.push_topic_preferences
  for select using (auth.uid() = user_id);

create policy "users insert own preferences" on public.push_topic_preferences
  for insert with check (auth.uid() = user_id);

create policy "users update own preferences" on public.push_topic_preferences
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users delete own preferences" on public.push_topic_preferences
  for delete using (auth.uid() = user_id);

-- ============================================================================
-- push_admin_actions (audit log para R14 destructive operations)
-- ============================================================================
create table if not exists public.push_admin_actions (
  id uuid default gen_random_uuid() primary key,
  admin_user_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (action in (
    'broadcast', 'send_to_topic', 'revoke_all'
  )),
  target_user_ids uuid[],
  payload jsonb default '{}'::jsonb,
  reason text not null,
  status text not null default 'pending' check (status in (
    'pending', 'completed', 'failed'
  )),
  error_message text,
  created_at timestamptz default now(),
  completed_at timestamptz
);

create index if not exists idx_push_admin_actions_admin_id
  on public.push_admin_actions(admin_user_id);
create index if not exists idx_push_admin_actions_created
  on public.push_admin_actions(created_at desc);

alter table public.push_admin_actions enable row level security;

create policy "admins read own actions" on public.push_admin_actions
  for select using (auth.uid() = admin_user_id);

-- ============================================================================
-- profiles.role (extension de add-login schema, idempotent — puede haber
-- corrido en 0003_email_subscriptions.sql también)
-- ============================================================================
alter table public.profiles
  add column if not exists role text default 'user' check (role in ('user', 'admin'));

create index if not exists idx_profiles_role
  on public.profiles(role) where role = 'admin';
