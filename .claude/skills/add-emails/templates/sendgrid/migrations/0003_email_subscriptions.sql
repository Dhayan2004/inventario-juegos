-- 0003_email_subscriptions.sql  (Mode B SendGrid — provider-agnostic)
--
-- Email subscription state + suppression list + event log + admin audit.
-- Idéntica a Mode A — schema es provider-agnostic. RLS L-001 enforced en
-- email_subscriptions (user-readable). suppression_list / email_events /
-- email_admin_actions: server-only (service_role bypass).
--
-- Cita: [memory:lessons#L-001] · [memory:CONSTRAINTS.md#R14]
-- @see prompts/setup-resend.md · prompts/setup-sendgrid.md

-- ============================================================================
-- email_subscriptions (per-user opt-out tracking)
-- ============================================================================
create table if not exists public.email_subscriptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  scope text not null check (scope in ('marketing', 'product_updates', 'all')),
  subscribed_at timestamptz default now(),
  unsubscribed_at timestamptz,
  unique (user_id, scope)
);

create index if not exists idx_email_subscriptions_user_id
  on public.email_subscriptions(user_id);

alter table public.email_subscriptions enable row level security;

-- Users can read their own opt-out state
create policy "users read own email subscriptions" on public.email_subscriptions
  for select using (auth.uid() = user_id);

-- NO INSERT/UPDATE direct policies — service_role bypass for webhook + actions

-- ============================================================================
-- suppression_list (hard bounces + spam complaints)
-- ============================================================================
create table if not exists public.suppression_list (
  email text primary key,
  reason text not null check (reason in (
    'hard_bounce', 'spam_complaint', 'admin_override', 'unsubscribe_global'
  )),
  suppressed_at timestamptz default now(),
  metadata jsonb default '{}'::jsonb
);

alter table public.suppression_list enable row level security;
-- NO policies — server-only via service_role. Users NO need access.

-- ============================================================================
-- email_events (audit log of all email events)
-- ============================================================================
create table if not exists public.email_events (
  id uuid default gen_random_uuid() primary key,
  external_event_id text unique not null,
  event_type text not null,
  recipient_email text not null,
  metadata jsonb default '{}'::jsonb,
  occurred_at timestamptz not null,
  created_at timestamptz default now()
);

create index if not exists idx_email_events_recipient
  on public.email_events(recipient_email);
create index if not exists idx_email_events_event_type
  on public.email_events(event_type);
create index if not exists idx_email_events_occurred_at
  on public.email_events(occurred_at desc);

alter table public.email_events enable row level security;
-- NO policies — server-only.

-- ============================================================================
-- email_admin_actions (audit log para R14 destructive operations)
-- ============================================================================
create table if not exists public.email_admin_actions (
  id uuid default gen_random_uuid() primary key,
  admin_user_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (action in (
    'bulk_unsubscribe', 'delete_suppression', 'resend_campaign'
  )),
  target_user_ids uuid[],
  target_email text,
  reason text not null,
  status text not null default 'pending' check (status in (
    'pending', 'completed', 'failed'
  )),
  error_message text,
  created_at timestamptz default now(),
  completed_at timestamptz
);

create index if not exists idx_email_admin_actions_admin_id
  on public.email_admin_actions(admin_user_id);
create index if not exists idx_email_admin_actions_created
  on public.email_admin_actions(created_at desc);

alter table public.email_admin_actions enable row level security;

-- Admins read their own actions (audit trail)
create policy "admins read own actions" on public.email_admin_actions
  for select using (auth.uid() = admin_user_id);

-- ============================================================================
-- profiles.role (extension de add-login schema)
-- ============================================================================
-- Si no existe ya, agregar role column para R14 admin role gating.
alter table public.profiles
  add column if not exists role text default 'user' check (role in ('user', 'admin'));

create index if not exists idx_profiles_role
  on public.profiles(role) where role = 'admin';
