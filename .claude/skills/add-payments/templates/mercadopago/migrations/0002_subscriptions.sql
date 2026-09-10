-- 0002_subscriptions.sql
--
-- Subscriptions + (opcional) refund_requests tables con RLS L-001 enforced.
-- Shape provider-agnostic — sirve para Stripe, Polar y Mercado Pago (Mode A, B y C
-- comparten esta migration; el ledger va en 0003_payments_ledger.sql).
--
-- Cita:
--   [memory:lessons#L-001] (RLS by user_id en cualquier tabla user-data)
--   [memory:CONSTRAINTS.md#R10] (Brand DNA contract — no aplica a SQL pero
--                                downstream pages consumen)
--   [memory:CONSTRAINTS.md#R14] (refund_requests existe para audit logs
--                                pre-execute en destructive flows)
--
-- @see prompts/setup-stripe.md · prompts/setup-polar.md · prompts/setup-mercadopago.md
-- @see references/refund-flow.md

-- ============================================================================
-- subscriptions
-- ============================================================================
create table if not exists public.subscriptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('stripe', 'polar', 'mercadopago')),
  external_subscription_id text not null,
  external_customer_id text,
  external_checkout_id text,
  status text not null default 'incomplete' check (status in (
    'incomplete', 'incomplete_expired', 'trialing', 'active',
    'past_due', 'canceled', 'unpaid', 'paused', 'revoked'
  )),
  current_period_end timestamptz,
  cancel_at_period_end boolean default false,
  amount_cents integer,
  currency text check (currency in ('usd', 'eur', 'mxn', 'ars', 'cop', 'brl', 'clp', 'pen', 'uyu')),
  interval text check (interval in ('month', 'year')),
  plan_id text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (provider, external_subscription_id)
);

create index if not exists idx_subscriptions_user_id
  on public.subscriptions(user_id);
create index if not exists idx_subscriptions_status
  on public.subscriptions(status);
create index if not exists idx_subscriptions_external
  on public.subscriptions(provider, external_subscription_id);

-- L-001: RLS habilitado, SELECT only para users (no INSERT/UPDATE direct —
-- solo via service_role en webhook handler).
alter table public.subscriptions enable row level security;

create policy "users read own subscriptions" on public.subscriptions
  for select using (auth.uid() = user_id);

-- NO policies INSERT/UPDATE/DELETE direct.
-- service_role bypasses RLS automáticamente para webhook ops.

-- ============================================================================
-- refund_requests (audit log para R14 destructive flows)
-- ============================================================================
create table if not exists public.refund_requests (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  charge_id text not null,
  refund_id text,
  reason text not null check (reason in (
    'requested_by_customer', 'duplicate', 'fraudulent', 'cancel_subscription'
  )),
  status text not null default 'pending' check (status in (
    'pending', 'completed', 'failed'
  )),
  error_message text,
  requested_at timestamptz default now(),
  completed_at timestamptz,
  unique (charge_id)
);

create index if not exists idx_refund_requests_user_id
  on public.refund_requests(user_id);

alter table public.refund_requests enable row level security;

create policy "users read own refund requests" on public.refund_requests
  for select using (auth.uid() = user_id);

-- NO INSERT/UPDATE direct policies — server actions usan auth context
-- + service_role para audit log integrity.

-- ============================================================================
-- profiles.has_access (extension de add-login schema)
-- ============================================================================
-- Si la columna ya existe (otra migration la agregó), esto es idempotente.
alter table public.profiles
  add column if not exists has_access boolean default false;

create index if not exists idx_profiles_has_access
  on public.profiles(has_access) where has_access = true;
