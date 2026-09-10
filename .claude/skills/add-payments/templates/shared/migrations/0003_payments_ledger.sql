-- 0003_payments_ledger.sql
--
-- Ledger de pagos + dedup de eventos de webhook + llaves de idempotencia.
-- Shape provider-agnostic — Stripe, Polar y Mercado Pago (Mode A/B/C) comparten
-- esta migration. Se aplica DESPUÉS de 0002_subscriptions.sql.
--
-- Por qué existe (G2, docs/11):
--   · Sin `webhook_events_processed` el replay que la firma con ventana de tiempo
--     NO cubre (mismo evento reenviado dentro de la ventana) se procesa dos veces.
--     Dedup = unique (provider, event_id): el segundo INSERT falla → 200 sin reprocesar.
--   · Sin `payments` no hay ownership DB-backed para refunds (PAY-008/R14) ni
--     rastro del rail (OXXO/SPEI = irreversible, PAY-006).
--   · `idempotency_keys` registra las llaves emitidas (crypto UUID, PAY-003) para
--     auditoría y para no reintentar con la misma llave tras un fallo de red.
--
-- Multi-tenant (M6/R16, G1): `organization_id` es NULLABLE — apps single-tenant lo
-- dejan null. Si la app corrió add-teams (0000_tenancy.sql → public.auth_org_ids()),
-- la policy por membresía se crea automáticamente (bloque DO al final); si no,
-- solo aplica la policy por user_id. Degradación segura: nunca una policy que
-- referencie una función inexistente.
--
-- Cita:
--   [memory:lessons#L-001] (RLS by user_id en cualquier tabla user-data)
--   [memory:CONSTRAINTS.md#R16] (aislamiento de tenant: organization_id + WITH CHECK)
--   [memory:CONSTRAINTS.md#R14] (refund = destructivo; ownership DB-backed)
--   [memory:references#R-012] (PagoKit: dedup por event id + exponente ISO 4217)
--
-- @see prompts/setup-stripe.md · prompts/setup-polar.md · prompts/setup-mercadopago.md
-- @see references/currencies.md (amount_minor × 10^exponent)

-- ============================================================================
-- payments (ledger — un renglón por pago del proveedor)
-- ============================================================================
create table if not exists public.payments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  organization_id uuid,                      -- INVARIANTE 1 (R16) cuando la app es multi-tenant
  provider text not null check (provider in ('stripe', 'polar', 'mercadopago')),
  external_payment_id text not null,
  -- Unidades MENORES según exponente ISO 4217 (MXN 2 → centavos; CLP 0 → entero). PAY-004.
  amount_minor bigint not null check (amount_minor >= 0),
  currency text not null check (currency in ('usd', 'eur', 'mxn', 'ars', 'cop', 'brl', 'clp', 'pen', 'uyu')),
  status text not null default 'pending' check (status in (
    'pending', 'succeeded', 'failed', 'canceled', 'refunded', 'disputed'
  )),
  method text,                               -- visa · oxxo · spei · pix · …
  payment_type text,                         -- credit_card · ticket · bank_transfer · …
  refundable boolean not null default true,  -- false = rail irreversible → payout manual (PAY-006, R14)
  metadata jsonb default '{}'::jsonb,        -- Rule 11: mínimo PII (solo payer_email)
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (provider, external_payment_id)
);

create index if not exists idx_payments_user_id on public.payments(user_id);
create index if not exists idx_payments_org_id on public.payments(organization_id) where organization_id is not null;
create index if not exists idx_payments_status on public.payments(status);

-- L-001: RLS habilitado, SELECT only para el dueño (INSERT/UPDATE solo via service_role en webhooks).
alter table public.payments enable row level security;

create policy "users read own payments" on public.payments
  for select using (auth.uid() = user_id);

-- NO policies INSERT/UPDATE/DELETE direct.

-- ============================================================================
-- webhook_events_processed (dedup — replay dentro de la ventana de tiempo)
-- ============================================================================
create table if not exists public.webhook_events_processed (
  id uuid default gen_random_uuid() primary key,
  provider text not null check (provider in ('stripe', 'polar', 'mercadopago')),
  event_id text not null,
  event_type text,
  received_at timestamptz default now(),
  expires_at timestamptz not null,           -- purga periódica: delete where expires_at < now()
  unique (provider, event_id)
);

create index if not exists idx_webhook_events_expires on public.webhook_events_processed(expires_at);

-- Tabla interna: RLS habilitado SIN policies → solo service_role (webhooks) la toca.
alter table public.webhook_events_processed enable row level security;

-- ============================================================================
-- idempotency_keys (llaves emitidas a proveedores — PAY-003)
-- ============================================================================
create table if not exists public.idempotency_keys (
  key uuid primary key,                      -- crypto.randomUUID(); NUNCA Math.random()/Date.now()
  user_id uuid references auth.users(id) on delete set null,
  provider text not null check (provider in ('stripe', 'polar', 'mercadopago')),
  purpose text not null check (purpose in ('checkout', 'subscription', 'refund', 'portal')),
  created_at timestamptz default now()
);

alter table public.idempotency_keys enable row level security;
-- Sin policies: solo service_role.

-- ============================================================================
-- Multi-tenant (M6/R16) — solo si add-teams instaló public.auth_org_ids()
-- ============================================================================
do $$
begin
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
             where n.nspname = 'public' and p.proname = 'auth_org_ids') then
    -- Miembros de la org leen los pagos de su org (T1/T5: la tabla lleva su propio organization_id).
    execute $p$
      create policy "org members read org payments" on public.payments
        for select using (
          organization_id is not null
          and organization_id in (select public.auth_org_ids())
        )
    $p$;
    -- WITH CHECK (T2/T3): aunque hoy no hay INSERT por usuarios, si se agrega, el tenant se valida.
    execute $p$
      create policy "org members insert own org payments" on public.payments
        for insert with check (
          organization_id is null
          or organization_id in (select public.auth_org_ids())
        )
    $p$;
  end if;
end $$;
