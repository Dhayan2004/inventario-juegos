-- tenancy-isolation.test.sql — Test NEGATIVO cross-tenant (R7 Layer 4 · M6)
--
-- El 4º check de la Three-Layer Verification para apps multi-tenant ([memory:CONSTRAINTS.md#R7]).
-- Corre sobre DB REAL (AP1 — nunca mocks): Supabase local (`supabase db reset`) o test branch,
-- como el rol que crea el schema (superuser/owner → bypassa RLS para el seed).
-- Doctrina: ../../../references/MULTI_TENANCY.md §5. Enforce: [memory:CONSTRAINTS.md#R16].
--
-- PLANTILLA: usa un sample entity `documents`. En un proyecto real, reemplazar `documents` por CADA
-- entidad de dominio tenant-scoped; las 4 ASERCIONES son el contrato invariable. Impersona vía el
-- claim JWT que Supabase Auth lee para auth.uid() (`request.jwt.claims -> sub`). Todo en una tx que
-- hace rollback → no deja residuo.
--
-- Disciplina anti-falso-verde (findings del workflow de verificación M6):
--   · Cada negativa tiene su CONTROL POSITIVO (una operación legítima que DEBE pasar) — así el verde
--     significa "RLS bloqueó el cross-tenant", no "todo está bloqueado por un grant/FK faltante".
--   · La escritura cross-tenant se prueba CIEGA (sin `where org`) para ejercitar el USING/WITH CHECK de
--     la policy de escritura, no la visibilidad del SELECT.
--   · El handler de excepción captura SÓLO el error de RLS (`insufficient_privilege` = SQLSTATE 42501,
--     "new row violates row-level security policy") — cualquier otro error propaga y rompe el test (no lo enmascara).
-- Un test que PASA contra el patrón correcto DEBE FALLAR si se le quita organization_id, el WITH CHECK,
-- el USING de escritura, o el role-gate. Esa es su prueba de que realmente aísla.

begin;

-- ── Sample entity (reemplazar por las entidades reales del proyecto) ──
create table if not exists public.documents (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title           text not null,
  created_at      timestamptz not null default now()
);
-- Grants explícitos al rol authenticated: RLS NO reemplaza los GRANTs de tabla. Sin esto, un INSERT
-- legítimo fallaría por permiso (no por RLS) y enmascararía el test. (Supabase los aplica por default
-- vía ALTER DEFAULT PRIVILEGES; se declaran acá para que la plantilla sea self-contained.)
grant select, insert, update, delete on public.documents to authenticated;
alter table public.documents enable row level security;
drop policy if exists "documents tenant isolation: select" on public.documents;
create policy "documents tenant isolation: select" on public.documents
  for select using (organization_id in (select public.auth_org_ids()));
drop policy if exists "documents tenant isolation: write" on public.documents;
create policy "documents tenant isolation: write" on public.documents
  for all using      (organization_id in (select public.auth_org_ids()))
          with check (organization_id in (select public.auth_org_ids()));

do $$
declare
  user_a   uuid := '11111111-1111-1111-1111-111111111111';  -- owner de org A
  user_b   uuid := '22222222-2222-2222-2222-222222222222';  -- owner de org B
  user_m   uuid := '33333333-3333-3333-3333-333333333333';  -- member de org A (para el role-gate)
  org_a    uuid;
  org_b    uuid;
  visible  int;
  inserted int;
begin
  -- ── Fixtures (≥2 tenants): seed como owner del schema (bypassa RLS). ──
  -- auth.users mínimo para satisfacer los FK. En Supabase hosted, sembrar vía Admin API.
  insert into auth.users (id, email) values
    (user_a, 'a@test.local'), (user_b, 'b@test.local'), (user_m, 'm@test.local')
  on conflict (id) do nothing;

  insert into public.organizations (name, slug, created_by)
    values ('Org A', 'org-a', user_a) returning id into org_a;
  insert into public.organizations (name, slug, created_by)
    values ('Org B', 'org-b', user_b) returning id into org_b;
  -- el trigger on_organization_created ya hizo owner a cada creador.
  insert into public.memberships (organization_id, user_id, role) values (org_a, user_m, 'member');

  insert into public.documents (organization_id, title) values (org_a, 'Doc de A');
  insert into public.documents (organization_id, title) values (org_b, 'Doc de B');

  -- ════════════════════════════════════════════════════════════════════════
  -- Impersonar a user_a (owner de tenant A)
  -- ════════════════════════════════════════════════════════════════════════
  perform set_config('request.jwt.claims',
                     json_build_object('sub', user_a, 'role', 'authenticated')::text, true);
  set local role authenticated;

  -- Aserción 1 — SELECT: user_a ve SÓLO sus filas de A, 0 de B.
  select count(*) into visible from public.documents;
  assert visible = 1, format('cross-tenant SELECT leak: user_a ve %s docs (esperado 1)', visible);
  assert (select count(*) from public.documents where organization_id = org_b) = 0,
    'cross-tenant SELECT leak: user_a ve filas de org B';

  -- Aserción 2 — INSERT: control positivo (own-org DEBE pasar) + negativa (cross-tenant DEBE fallar).
  --   Control positivo: si esto falla, propaga y rompe el test (grant/RLS roto para escritura legítima).
  insert into public.documents (organization_id, title) values (org_a, 'Doc propio de A');
  --   Negativa: INSERT en org B → RLS WITH CHECK lo aborta (SQLSTATE 42501). Sólo capturamos ESE error.
  inserted := 0;
  begin
    insert into public.documents (organization_id, title) values (org_b, 'Inyectado por A');
    inserted := 1;
  exception when insufficient_privilege or check_violation then
    inserted := 0;  -- esperado: RLS WITH CHECK rechaza la fila de otra org
  end;
  assert inserted = 0, 'cross-tenant INSERT permitido: user_a escribió en org B (falta WITH CHECK)';

  -- Aserción 3 — UPDATE/DELETE CIEGOS (sin `where org`): ejercitan el USING de la policy de escritura,
  --   no la visibilidad del SELECT. Bajo la policy `for all` correcta, sólo tocan filas de A.
  update public.documents set title = 'Hackeado';   -- sin WHERE: intenta tocar TODO lo escribible
  delete from public.documents;                       -- sin WHERE: intenta borrar TODO lo escribible
  reset role;
  --   Verificación privilegiada: la fila de org B sigue intacta (ni modificada ni borrada).
  assert (select count(*) from public.documents where organization_id = org_b) = 1,
    'cross-tenant write: UPDATE/DELETE ciego de user_a tocó filas de org B (USING de escritura débil)';
  assert (select title from public.documents where organization_id = org_b) = 'Doc de B',
    'cross-tenant write: UPDATE ciego de user_a modificó la fila de org B';

  -- ════════════════════════════════════════════════════════════════════════
  -- Aserción 4 — ROLE-GATE: un `member` no puede una operación de owner/admin; el owner sí (control +).
  -- ════════════════════════════════════════════════════════════════════════
  --   member de org A intenta renombrar la org (policy "admins update org") → 0 filas.
  perform set_config('request.jwt.claims',
                     json_build_object('sub', user_m, 'role', 'authenticated')::text, true);
  set local role authenticated;
  update public.organizations set name = 'Hijacked' where id = org_a;
  assert not found, 'role-gate bypass: un member modificó la organización (falta gate por rol)';
  reset role;
  assert (select name from public.organizations where id = org_a) = 'Org A',
    'role-gate bypass: el nombre de la org cambió por un member';

  --   Control positivo: el owner (user_a) SÍ puede renombrar la org.
  perform set_config('request.jwt.claims',
                     json_build_object('sub', user_a, 'role', 'authenticated')::text, true);
  set local role authenticated;
  update public.organizations set name = 'Org A (renamed)' where id = org_a;
  assert found, 'role-gate roto: el owner NO pudo actualizar su propia organización';
  reset role;

  raise notice 'PASS — aislamiento cross-tenant verificado: SELECT + INSERT + UPDATE/DELETE ciegos + role-gate (2 tenants)';
end;
$$;

rollback;
