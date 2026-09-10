---
name: el-migrador
context: fork
agent: el-migrador
description: >
  Wrapper sobre Supabase CLI para gestión disciplinada de migrations. Crea
  (`migration new`), aplica (`db push`), revierte (`db reset` + replay), y
  diff'ea schema (`db diff`) con un protocolo que incluye pre-validation
  (rollback exists, idempotent, RLS coverage), naming convention `<timestamp>_<feature>_<verb>`,
  asociación al feature_list.json activo, y handoff a `el-guardian` para
  cambios sensibles (RLS, grants, public schema). NUNCA aplica migrations en
  prod sin gate explícito.
tier: core
requires: Supabase CLI instalado (`supabase --version` ≥ 1.190) + project linked (`supabase link --project-ref <ref>`)
fallback: generar SQL manual + instrucciones step-by-step para correr a mano (con CHECKSUMS)
dependencies: [find-docs]
---

# el-migrador

> *"La migration que no se puede revertir no se aplica."*
> — Forja D10

Skill operativo. Wraps Supabase CLI con un protocolo opinionated que evita los 3 modos clásicos de morir con DB en producción: aplicar sin rollback, romper RLS sin darse cuenta, y desincronizar local↔remoto.

## PREFLIGHT halt

```
1. ¿Supabase CLI instalado? `command -v supabase` exit 0. Si no → halt: "supabase CLI no instalado. brew install supabase/tap/supabase"
2. ¿Project linked? `supabase status` o `cat supabase/config.toml`. Si no → halt: "supabase link --project-ref <ref> primero"
3. ¿Variables .env presentes? SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY. Si falta → halt con lista de vars faltantes
4. ¿Hay feature activa con scope DB? Si la feature activa NO toca DB, este skill no aplica → halt + sugerir el-yunque/la-forja
5. ¿Branch local en un branch matching feature/* ? (R3) Si no → halt: "Crear branch feature/<name> antes de migrar"
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Feature activa requiere cambio de schema | la-forja / el-yunque / Coordinator |
| Carlos pide "crea migration", "aplica migration", "rollback de DB" | Coordinator |
| Tras Tech Spec (`la-herreria` Fase 3) que define DB schema | la-herreria |
| Pre-deploy: aplicar migrations pendientes a staging | Coordinator vía `/despachar` |

## Modos de operación

el-migrador opera en 5 modos. El usuario o el orchestrator elige uno:

### 1. `new` — crear migration nueva

```
supabase migration new <verb>_<feature>
```

`<verb>`: `add`, `alter`, `drop`, `rls`, `index`, `function`, `trigger`, `view`, `seed`.
`<feature>`: nombre de la feature activa en `feature_list.json` (kebab-case).

Ejemplo: `supabase migration new add_user_profiles`.

el-migrador genera 2 archivos en `supabase/migrations/`:
- `<timestamp>_<verb>_<feature>.sql` — la migration
- `<timestamp>_<verb>_<feature>.rollback.sql` — el rollback (obligatorio)

### 2. `up` — aplicar migrations pendientes

```
supabase db push --linked       # remoto
supabase db reset --local       # local + replay todas
```

Pre-checks antes de aplicar:
1. **Rollback existe.** Si `*.rollback.sql` no existe para alguna pending → halt.
2. **Idempotent.** SQL contiene `IF NOT EXISTS` / `CREATE OR REPLACE` donde aplique. Si no, advertir.
3. **RLS coverage.** Tablas nuevas tienen `ENABLE ROW LEVEL SECURITY` + al menos 1 policy. Si no → halt + handoff a `el-guardian`.
   - **Multi-tenant (M6):** si el proyecto es multi-tenant (ver "Multi-tenant" abajo), la cobertura RLS es más estricta — toda tabla **tenant-scoped** debe cumplir los 3 invariantes de `[memory:lessons#L-005]` ([memory:CONSTRAINTS.md#R16]): `organization_id NOT NULL` + predicado de tenant en `USING` **y** en `WITH CHECK`. Una tabla de dominio sin `organization_id`, o una policy de escritura sin `WITH CHECK`, es un blocker (cross-tenant leak T1/T2).
4. **No-downtime safety.** Detectar patrones peligrosos: `DROP COLUMN`, `ALTER COLUMN ... NOT NULL` sin default, `RENAME` (rompe clientes en flight). Si detecta → advertir + ofrecer split en 2 migrations.

### 3. `down` — revertir última migration

```
# Aplicar el .rollback.sql de la última migration aplicada
psql "<connection-string>" -f supabase/migrations/<timestamp>_*.rollback.sql
```

Solo en local o staging por default. Para prod: requiere `--force-prod` + confirmación explícita.

### 4. `diff` — generar migration desde cambios en local

```
supabase db diff --schema public --file <verb>_<feature>
```

Compara estado actual de DB local con remote/last migration y produce migration auto.

el-migrador post-procesa el diff:
1. Lee el diff generado.
2. Genera el `.rollback.sql` correspondiente (DROP de los CREATE, etc.).
3. Aplica naming convention.
4. Pide confirmación al usuario antes de mover de `<random_name>` al naming convention.

### 5. `status` — listar migrations + estado

```
supabase migration list
```

Output formateado:

```
APPLIED   TIMESTAMP        VERB    FEATURE              ROLLBACK
✅        20260507120000   add     user_profiles        ✅
✅        20260507130000   rls     user_profiles        ✅
⏳        20260507140000   alter   user_profiles_email  ✅
❌        20260508090000   drop    legacy_table         ❌ (FALTA)
```

Si una migration tiene `❌ (FALTA)` rollback → halt deploy hasta resolverla.

## Naming convention obligatoria

```
<timestamp>_<verb>_<feature_or_subject>.sql
<timestamp>_<verb>_<feature_or_subject>.rollback.sql
```

- `<timestamp>`: `YYYYMMDDHHMMSS` (lo que Supabase CLI genera).
- `<verb>`: uno de `add | alter | drop | rls | index | function | trigger | view | seed`.
- `<feature_or_subject>`: kebab-case, idealmente match con feature en feature_list.json.

Ejemplos válidos:
- `20260507120000_add_user_profiles.sql`
- `20260507130000_rls_user_profiles.sql`
- `20260508090000_alter_orders_add_status.sql`

Ejemplos inválidos (el-migrador rechaza y renombra):
- `20260507_some-random-thing.sql` (sin verbo)
- `migration_users.sql` (sin timestamp)

## Pre-validation pipeline

Antes de aplicar cualquier migration (modo `up`):

```
0. PREFLIGHT (sección PREFLIGHT)
1. Listar migrations pending: supabase migration list | filter "pending"
2. Para cada pending:
   a. Verificar que existe .rollback.sql con mismo timestamp
   b. Linter SQL: detectar patrones peligrosos
   c. Si toca tablas nuevas → verificar `ENABLE ROW LEVEL SECURITY`
   d. Si modifica RLS, GRANT/REVOKE, public schema → marcar para handoff a el-guardian
3. Si TODOS los pending pasan validación:
   a. Si target = local → supabase db reset
   b. Si target = staging → supabase db push --linked (project staging)
   c. Si target = prod → halt + requerir CONFIRMO_DEPLOY_PROD <reason>
4. Si alguna falla:
   a. Mostrar lista de blockers
   b. Halt — no aplicar nada (atomic: o todas o ninguna)
```

## Patrones SQL peligrosos (linter)

| Patrón | Por qué es peligroso | Sugerencia el-migrador |
|--------|----------------------|------------------------|
| `DROP COLUMN` directo | clientes en flight rompen | split: nullable col + deploy + drop |
| `ALTER COLUMN ... NOT NULL` sin default | rows existentes rompen | default + backfill + NOT NULL en migration separada |
| `RENAME COLUMN/TABLE` directo | breaking change instantáneo | crear nuevo + dual-write + drop viejo |
| `DELETE FROM ... WHERE ...` masivo | sin límite ni tx wrapper | wrap en tx + límite + chunks |
| `CREATE INDEX` sin `CONCURRENTLY` | locks tabla | `CREATE INDEX CONCURRENTLY` (requiere salir de tx) |
| `GRANT ... TO public` | leak de perms | usar role específico + RLS |
| `DROP POLICY` sin reemplazo | RLS gap | reemplazar primero, drop después |
| **Tabla tenant-scoped sin `organization_id`** (multi-tenant) | RLS no puede aislar → leak cross-tenant (T1) | agregar `organization_id NOT NULL` + RLS por membresía |
| **Policy de escritura sin `WITH CHECK`** (multi-tenant) | INSERT/UPDATE mueve filas a otra org (T2/T3 IDOR) | agregar `with check (organization_id in (select public.auth_org_ids()))` |

## Integración con el-guardian

Cualquier migration que toca:
- RLS policies (CREATE/ALTER/DROP POLICY)
- GRANT / REVOKE
- Schema `public` con tablas con PII
- Funciones SECURITY DEFINER

Requiere handoff a `el-guardian` ANTES de aplicar. Protocolo:

```
1. el-migrador detecta el patrón sensible
2. Marca la migration como "pending-security-review"
3. Invoca el-guardian con scope = "migration <file>"
4. el-guardian audita y produce verdict
5. Si PASS → el-migrador procede con db push
6. Si FAIL → halt + devolver al generador con findings
```

## Multi-tenant — RLS por tenant (M6)

> Doctrina completa: [`references/MULTI_TENANCY.md`](../../references/MULTI_TENANCY.md). Lección:
> `[memory:lessons#L-005]`. Regla: `[memory:CONSTRAINTS.md#R16]`. ADR: `[memory:decisions#D-028]`.

Cuando la app es **multi-tenant** (las apps de Forge Enterprise lo son por default — B1), el-migrador
generaliza la cobertura RLS de single-tenant (`auth.uid() = user_id`, `[memory:lessons#L-001]`) a
**aislamiento por tenant** (`organization_id` + RLS por membresía).

**Detección de multi-tenant** (en orden, degradación segura): `ONTOLOGY.md › tenant_model.multi_tenant:
true` · sección "Multi-Tenant Data Model" en `TECH-SPEC-<nombre>.md` (asset 03) · existencia de
`supabase/migrations/0000_tenancy.sql`. Si ninguna → single-tenant, aplica L-001 sin cambios.

### Estampar la foundation — `0000_tenancy.sql`

Para una app multi-tenant nueva, el-migrador estampa la migración fundacional **antes** de
`0001_profiles.sql`, copiando [`references/tenancy-pattern.sql`](references/tenancy-pattern.sql):
`organizations` + `memberships` (con `role`) + los helpers `auth_org_ids()` / `auth_has_org_role()`
(`security definer`, evitan recursión de RLS) + el trigger creator→owner + las policies. Genera también
su `.rollback.sql` (bloque al pie del template, drop en orden inverso). Si el Tech Spec eligió otro
**término de tenant** (`workspace`/`account`/`team`), renombrar de forma consistente tabla/columna/
helpers/policies.

> `profiles` (`0001`) **no** lleva `organization_id` — la identidad del usuario es global; la pertenencia
> vive en `memberships`. El tenant aplica a las **entidades de dominio**, no al perfil.

### Los 3 invariantes que el-migrador valida en cada `up` (R16)

1. Toda tabla **tenant-scoped** lleva `organization_id NOT NULL` con FK a `organizations(id) on delete cascade`.
2. Toda policy de **escritura** tiene `WITH CHECK` con el predicado de tenant (no sólo `USING`).
3. El `organization_id` del cliente nunca se confía — lo valida `WITH CHECK` contra la membresía real.

Falla cualquiera → halt + handoff a `el-guardian` (modo cross-tenant), igual que con RLS/grants.

### Gate del `up` — test negativo cross-tenant (R7 Layer 4)

Antes de aplicar migraciones que tocan tablas tenant-scoped, el-migrador exige que el **test negativo
cross-tenant** ([`references/tenancy-isolation.test.sql`](references/tenancy-isolation.test.sql), adaptado
a las entidades reales) **pase contra DB real** (AP1, ≥2 tenants). Es el 4º check de la Three-Layer
Verification para apps multi-tenant (`[memory:CONSTRAINTS.md#R7]` Layer 4). Sin test verde → halt; no se
aplica la migración a staging/prod.

## Output — migration log

Tras cada `up` exitoso, append a `supabase/migrations/MIGRATIONS-LOG.md`:

```markdown
## 20260507120000 — add_user_profiles

**Date applied:** 2026-05-07 12:00 UTC
**Target:** local | staging | prod
**Feature:** F2-S4 (feature/el-migrador)
**Commit:** <sha>
**Tables affected:** user_profiles
**RLS coverage:** ✅ 3 policies
**Security review:** N/A | el-guardian PASS (audit-doc-link)
**Rollback file:** 20260507120000_add_user_profiles.rollback.sql
```

Esto es el audit trail. NO se modifica entries pasadas (append-only).

## Refusals (lo que NUNCA hace)

- ❌ Aplicar migration sin `.rollback.sql` correspondiente.
- ❌ Aplicar a prod sin `CONFIRMO_DEPLOY_PROD <reason>` explícito.
- ❌ Crear tabla nueva sin RLS habilitado.
- ❌ Editar migrations ya aplicadas (append nueva migration superseding, nunca edit-in-place).
- ❌ Bypass del linter de patrones peligrosos sin justificación documentada.
- ❌ Aplicar migration cuya feature_list.json correspondiente está en estado distinto a `active` o `passing`.

## Tool filter

**Estructural (runtime-enforced) desde `[memory:decisions#D-033]`.** La ejecución forkeada corre con el
subagente [`agents/el-migrador.md`](../../agents/el-migrador.md) (frontmatter `agent: el-migrador`), cuyo
`tools:` es whitelist dura del runtime: Read · Grep · Glob · Bash (Supabase CLI + psql para rollback) ·
Write (solo `supabase/migrations/**`) · Skill (`find-docs` R13 + handoff a `el-guardian`).

**`Edit` no existe en este contexto** — las migraciones son append-only por construcción: una migración
aplicada nunca se edita, se supersede con una nueva (Write). El filtro es grueso (tool sí/no): el
path-scope del Write (solo migrations; NO `src/**`) sigue siendo regla de prompt. Doctrina:
[`references/SUBAGENT_TOOL_FILTERS.md`](../../references/SUBAGENT_TOOL_FILTERS.md).

## Loop de ejecución

```
0. PREFLIGHT halt
1. Determinar modo (new / up / down / diff / status)
2. Si modo=new:
   a. Pedir <verb> + nombre
   b. supabase migration new <timestamp>_<verb>_<feature>
   c. Generar también .rollback.sql plantilla
   d. Devolver al usuario para que escriba contenido
3. Si modo=diff:
   a. supabase db diff
   b. Post-process: generar rollback, renombrar, mover a directorio
4. Si modo=up:
   a. Pre-validation pipeline (todas las pending)
   b. Si target=prod → confirmación explícita
   c. Si toca RLS/grants → handoff a el-guardian
   d. Aplicar (atomic)
   e. Append a MIGRATIONS-LOG.md
5. Si modo=down:
   a. Identificar última migration aplicada
   b. Si target=prod → bloquear sin --force-prod
   c. Aplicar .rollback.sql via psql
   d. Append a MIGRATIONS-LOG.md (status: reverted)
6. Si modo=status:
   a. Listar migrations + estado + rollback availability
```

## Cuándo invocar find-docs

Antes de generar SQL contra sintaxis Supabase CLI o de aplicar comandos cuyo flag/output pudo cambiar post-cutoff.

**Ejemplo:** antes de correr `supabase migration new <name>` por primera vez, invocar `find-docs` con `libraryName: "supabase"` y `query: "migration new naming convention timestamp output 2026"` para confirmar que el formato del archivo generado sigue siendo `<timestamp>_<name>.sql` y no cambió. Citar `[docs:supabase]` en el output cuando se aplique el comando. R13 enforced por `el-evaluador`.

Trigger: cualquier comando del Supabase CLI que el skill no haya usado en sesiones recientes, o cualquier opción nueva (`--linked`, `--db-url`, `--schema`, etc.).

## Integraciones

- **`find-docs`:** consulta sintaxis CLI antes de generar SQL/comandos.
- **`la-herreria` Fase 3 (Tech Spec):** define schema → el-migrador lo materializa como migration.
- **`el-guardian`:** audita migrations sensibles antes de aplicar.
- **`el-evaluador`:** registra E-NNN si una migration falla en producción.
- **`/despachar`:** corre `el-migrador` modo `up` contra staging antes de prod.

---

*"Migrar es fácil. Revertir cuando todo falló a las 3 AM es lo que distingue a este skill."*
