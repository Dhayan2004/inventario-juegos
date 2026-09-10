# Generate Profiles Migration — Supabase SQL with RLS L-001 enforced

## Antes de empezar (R13)

Antes de generar el SQL, invocá `find-docs`:

```
1. resolve-library-id("supabase") → query-docs
   query: "row level security policies auth.uid trigger handle_new_user"
2. resolve-library-id("postgres") → query-docs
   query: "security definer vs invoker functions plpgsql trigger AFTER INSERT"
```

**Razón:** RLS policy syntax y `security definer`/`security invoker` semantics son críticos para L-001. Un trigger mal definido (sin `security definer`) puede impedir que la inserción del profile suceda al signup.

## L-001 — RLS por user_id es default

Cita `[memory:lessons#L-001]`:
> "Cualquier tabla que persiste datos derivados de input del usuario lleva `user_id uuid references auth.users(id) on delete cascade` + `enable row level security` + al menos una policy `using (auth.uid() = user_id)` o equivalente transitivo."

La tabla `profiles` cae directamente en este patrón. El SQL DEBE incluir:

1. `user_id` referenciando `auth.users(id)` con `on delete cascade` (en este caso es `id` que sirve dual: PK + foreign key).
2. `alter table public.profiles enable row level security`.
3. Policy `select using (auth.uid() = id)`.
4. Policy `update using (auth.uid() = id) with check (auth.uid() = id)` — **`WITH CHECK` es obligatorio**: `USING` filtra qué filas puede tocar el usuario, pero sin `WITH CHECK` no valida el estado *resultante* de la fila (U-01).
5. **Hardening por columna** — RLS filtra por FILA, no por columna. Sin esto, cuando la tabla gane una columna de privilegio (`rol`, `organization_id`, `es_admin`), el usuario se la auto-otorga en su propia fila sin violar ninguna policy: `revoke update on public.profiles from authenticated, anon;` + `grant update (full_name, avatar_url) on public.profiles to authenticated;`.
6. Trigger `handle_new_user` `after insert on auth.users` que crea el row de profile.
7. La función trigger `security definer` (necesaria para que el insert atraviese RLS al momento del signup donde no hay session aún).

## Anatomy del SQL

```sql
-- supabase/migrations/<TIMESTAMP>_profiles.sql
--
-- Profiles table — public.profiles 1:1 con auth.users.
--
-- L-001 enforcement: tabla persiste datos derivados de input del usuario
-- (signup metadata, profile edits). RLS habilitado + 2 policies + trigger.
-- Cita [memory:lessons#L-001].
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

-- Hardening por COLUMNA (U-01). RLS filtra por FILA, no por columna:
-- sin esto un usuario se auto-otorga columnas de privilegio en su propia fila.
revoke update on public.profiles from authenticated, anon;
grant update (full_name, avatar_url) on public.profiles to authenticated;

-- 4. Trigger handle_new_user — crea profile automaticamente al signup
-- security definer necesario porque el insert ocurre antes de que la session esté establecida
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

-- 5. updated_at touch trigger (no L-001 dependency, just hygiene)
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
```

## Verificación L-001

Post-generación, validar:

```bash
SQL_FILE=supabase/migrations/*_profiles.sql

# 1. RLS habilitado
grep -q "enable row level security" $SQL_FILE || echo "FAIL: RLS missing"

# 2. references auth.users(id) on delete cascade
grep -q "references auth.users(id) on delete cascade" $SQL_FILE || echo "FAIL: cascade missing"

# 3. 2 policies con auth.uid() (select USING + update USING + update WITH CHECK = 3 ocurrencias)
grep -c "auth.uid() = id" $SQL_FILE | grep -qE "^[3-9]" || echo "FAIL: falta policy o WITH CHECK"

# 3b. U-01: WITH CHECK en update + hardening por columna
grep -q "with check (auth.uid() = id)" $SQL_FILE || echo "FAIL: update sin WITH CHECK (U-01)"
grep -q "revoke update on public.profiles" $SQL_FILE || echo "FAIL: falta revoke update (U-01)"
grep -q "grant update (full_name, avatar_url)" $SQL_FILE || echo "FAIL: falta grant por columna (U-01)"

# 4. trigger handle_new_user
grep -q "handle_new_user" $SQL_FILE || echo "FAIL: trigger missing"
grep -q "after insert on auth.users" $SQL_FILE || echo "FAIL: trigger fires wrong event"

# 5. security definer en handle_new_user
grep -A 2 "function public.handle_new_user" $SQL_FILE | grep -q "security definer" || \
  echo "FAIL: handle_new_user not security definer (won't bypass RLS at signup)"

# 6. JSDoc cita L-001
head -10 $SQL_FILE | grep -q "L-001" || echo "FAIL: missing L-001 citation"
```

Todos los checks deben pasar antes de marcar el migration como ready.

## Cuándo NO regenerar

Si el target ya tiene `0001_*_profiles.sql` con RLS configurado correctamente, NO sobreescribir. Loggear y preguntar al usuario.

Si el target tiene una migration de profiles SIN RLS → halt + reportar como gap. NO mergear con add-login hasta que el evaluador valide.

## Insforge equivalent

Para Mode B (Insforge), el equivalente vive en `lib/insforge/schema.ts` declarativo. Ver `prompts/setup-insforge-auth.md` y `templates/insforge/lib/insforge/schema.ts`. Mismo principio L-001: el schema declara visibility/access policies por field.

## Citations

- [memory:lessons#L-001] (RLS por user_id, fuente del enforcement)
- [memory:CONSTRAINTS.md#R13]
- [docs:supabase] (RLS + policies syntax)
- [docs:postgres] (security definer semantics)
