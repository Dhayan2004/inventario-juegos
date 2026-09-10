-- 0005_teams-isolation.test.sql — Test negativo de gestión de equipos (S2 · add-teams)
--
-- Extiende tenancy-isolation.test.sql (M6, R7 Layer 4) con las amenazas propias de la GESTIÓN de
-- equipo: escalación de privilegios (admin→owner), robo/cross-tenant de invitaciones, email no
-- verificado, y protección del último owner. Corre sobre Postgres real con el shim de Supabase.
--
-- Enforce: [memory:CONSTRAINTS.md#R16] + [memory:CONSTRAINTS.md#R7] (Layer 4) + el-guardian "El Infiltrado".
-- Cómo correr: psql contra una DB de test con 0000_tenancy.sql + 0005_teams.sql aplicados.
--
-- DISCIPLINA DE ASERCIÓN (importante): la condición de fuga (LEAK) se afirma SIEMPRE *fuera* del bloque
-- begin/exception. Una policy que bloquea por la cláusula USING (fila no visible) en UPDATE/DELETE NO
-- lanza excepción — afecta 0 filas en silencio. Por eso NO confiamos en el `catch` como prueba: el catch
-- sólo absorbe el rechazo por WITH CHECK; la prueba real es leer el ESTADO final después. (Si pusieras el
-- `raise 'LEAK'` dentro del mismo begin/exception, el `when others` se lo tragaría → falso verde.)
--
-- Fixtures (≥2 tenants): org A (owner=user_a, admin=user_adm, member=user_m) y org B (owner=user_b).
-- El harness debe sembrar auth.users con estos ids/emails ANTES de este archivo, con email_confirmed_at
-- NO nulo para a/adm/m/b (cuentas legítimas) y una cuenta extra `user_unv` con email_confirmed_at NULL
-- (email = el de una invitación) para T-TEAM-6.

begin;

-- ── Shim de identidad: simula auth.uid() + auth.jwt() de Supabase ────────────────────────────────
create or replace function _claims(uid uuid, email text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'email', email)::text, true);
  perform set_config('role', 'authenticated', true);
end $$;

-- ids fijos (el harness siembra auth.users + las orgs/memberships con estos valores)
--   user_a   = ...a1 (owner A)   user_adm = ...a2 (admin A)   user_m = ...a3 (member A)
--   user_b   = ...b1 (owner B)   user_unv = ...c9 (email confirmado NULL, = invitación de A)

-- ════════════════════════════════════════════════════════════════════════════
-- T-TEAM-1 · CROSS-TENANT: el owner de B no ve ni invita en A
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; could_read boolean; could_invite boolean := false;
begin
  perform _claims('00000000-0000-0000-0000-0000000000b1', 'b@b.com');
  -- lectura cross-tenant (no debería ver la org A)
  select exists (select 1 from public.organizations where slug = 'org-a') into could_read;
  if could_read then
    raise exception 'LEAK T-TEAM-1a: user_b (org B) puede LEER la organización A';
  end if;
  -- invitar en A desde B: el insert debe rebotar por RLS (auth_has_org_role(A)=false)
  begin
    insert into public.invitations(organization_id, email, role)
    values ((select id from public.organizations where slug = 'org-a' limit 1), 'x@x.com', 'member');
    could_invite := true;  -- si llegamos aquí, el insert pasó (fuga)
  exception when others then could_invite := false;  -- rechazo = esperado
  end;
  if could_invite then
    raise exception 'LEAK T-TEAM-1b: user_b pudo CREAR invitación en org A';
  end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- T-TEAM-2 · ESCALACIÓN: un admin NO puede ascenderse a owner (WITH CHECK)
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; escalated boolean;
begin
  perform _claims('00000000-0000-0000-0000-0000000000a2', 'adm@a.com');  -- admin de A
  select id into org_a from public.organizations where slug = 'org-a';
  begin
    update public.memberships set role = 'owner'
      where organization_id = org_a and user_id = '00000000-0000-0000-0000-0000000000a2';
  exception when insufficient_privilege then null;  -- rechazo por WITH CHECK = esperado
           when others then null;                   -- cualquier otro rechazo también es aceptable aquí
  end;
  -- ASERCIÓN FUERA del catch: la fila NO quedó como owner
  select exists (
    select 1 from public.memberships
    where organization_id = org_a and user_id = '00000000-0000-0000-0000-0000000000a2' and role = 'owner'
  ) into escalated;
  if escalated then raise exception 'LEAK T-TEAM-2: un admin se auto-ascendió a OWNER'; end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- T-TEAM-3 · ESCALACIÓN: un admin NO puede expulsar al owner
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; owner_gone boolean;
begin
  perform _claims('00000000-0000-0000-0000-0000000000a2', 'adm@a.com');
  select id into org_a from public.organizations where slug = 'org-a';
  begin
    delete from public.memberships where organization_id = org_a and role = 'owner';
  exception when others then null;  -- rechazo (RLS USING o trigger) = esperado
  end;
  select not exists (select 1 from public.memberships where organization_id = org_a and role = 'owner')
    into owner_gone;
  if owner_gone then raise exception 'LEAK T-TEAM-3: un admin expulsó al OWNER (org sin owner)'; end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- T-TEAM-4 · ROBO DE INVITACIÓN: aceptar con un email distinto al invitado falla
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; tok text; stole boolean;
begin
  -- owner de A invita a alguien@a.com
  perform _claims('00000000-0000-0000-0000-0000000000a1', 'a@a.com');
  select id into org_a from public.organizations where slug = 'org-a';
  insert into public.invitations(organization_id, email, role)
    values (org_a, 'alguien@a.com', 'member') returning token into tok;

  -- user_b (otro email) intenta aceptar con el token robado
  perform _claims('00000000-0000-0000-0000-0000000000b1', 'b@b.com');
  begin
    perform public.accept_invitation(tok);
  exception when others then null;  -- "email does not match" = esperado
  end;
  -- ASERCIÓN FUERA del catch: user_b NO quedó como miembro de A
  select exists (
    select 1 from public.memberships
    where organization_id = org_a and user_id = '00000000-0000-0000-0000-0000000000b1'
  ) into stole;
  if stole then raise exception 'LEAK T-TEAM-4: user_b se metió a A con una invitación ajena'; end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- T-TEAM-5 · ÚLTIMO OWNER: el único owner no puede auto-degradarse (trigger guard_last_owner)
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; owner_gone boolean;
begin
  perform _claims('00000000-0000-0000-0000-0000000000a1', 'a@a.com');  -- owner de A (único)
  select id into org_a from public.organizations where slug = 'org-a';
  begin
    update public.memberships set role = 'admin'
      where organization_id = org_a and user_id = '00000000-0000-0000-0000-0000000000a1';
  exception when others then null;  -- rechazo por guard_last_owner = esperado
  end;
  select not exists (select 1 from public.memberships where organization_id = org_a and role = 'owner')
    into owner_gone;
  if owner_gone then raise exception 'LEAK T-TEAM-5: la org quedó SIN owner (último owner degradado)'; end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- T-TEAM-6 · EMAIL NO VERIFICADO: aceptar con email coincidente pero sin confirmar falla
--   (defensa contra instancias con "Confirm email" desactivado — ver accept_invitation)
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; tok text; got_in boolean;
begin
  -- owner de A invita a unverified@a.com (el email de user_unv, cuyo email_confirmed_at es NULL)
  perform _claims('00000000-0000-0000-0000-0000000000a1', 'a@a.com');
  select id into org_a from public.organizations where slug = 'org-a';
  insert into public.invitations(organization_id, email, role)
    values (org_a, 'unverified@a.com', 'member') returning token into tok;

  -- user_unv (email coincide, pero NO verificado) intenta aceptar
  perform _claims('00000000-0000-0000-0000-0000000000c9', 'unverified@a.com');
  begin
    perform public.accept_invitation(tok);
  exception when others then null;  -- "email must be verified" = esperado
  end;
  select exists (
    select 1 from public.memberships
    where organization_id = org_a and user_id = '00000000-0000-0000-0000-0000000000c9'
  ) into got_in;
  if got_in then raise exception 'LEAK T-TEAM-6: una cuenta con email NO verificado entró a la org'; end if;
end $$;

-- ════════════════════════════════════════════════════════════════════════════
-- CONTROL POSITIVO · el owner SÍ puede invitar y transferir (no romper el flujo legítimo)
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare org_a uuid; tok text;
begin
  perform _claims('00000000-0000-0000-0000-0000000000a1', 'a@a.com');  -- owner de A
  select id into org_a from public.organizations where slug = 'org-a';
  insert into public.invitations(organization_id, email, role)
    values (org_a, 'nuevo@a.com', 'member') returning token into tok;
  if tok is null then raise exception 'CONTROL FAIL: el owner no pudo invitar (flujo legítimo roto)'; end if;
  -- transferir a user_adm (ya es miembro) y verificar exactamente 1 owner
  perform public.transfer_org_ownership(org_a, '00000000-0000-0000-0000-0000000000a2');
  if (select count(*) from public.memberships where organization_id = org_a and role = 'owner') <> 1 then
    raise exception 'CONTROL FAIL: tras transferir, la org no tiene exactamente 1 owner';
  end if;
end $$;

rollback;  -- el test no deja estado

-- ─────────────────────────────────────────────────────────────────────────────
-- KILL-MUTATION (validación del propio test): si se quita el WITH CHECK de "manage memberships update",
-- el guard del último owner, el chequeo de email-match o el de email_confirmed_at en accept_invitation —
-- alguna de T-TEAM-2..6 DEBE empezar a fallar (=el test detecta la regresión). Si quitás una guarda y
-- todo sigue verde, el test es inútil: arreglalo antes de confiar en él. (Disciplina de M6.)
