# Multi-Tenancy de Forge Enterprise (M6)

> **Qué es esto.** El contrato de diseño del **aislamiento por tenant** en las apps que genera Forge
> Enterprise. Es la generalización de la lección single-tenant `[memory:lessons#L-001]`
> (`auth.uid() = user_id`) al caso **multi-tenant** (`organization_id` + RLS por membresía). Define el
> modelo de tenancy canónico, el esquema base, los patrones de policy RLS, el modelo de amenazas
> cross-tenant y la disciplina de tests negativos que `el-migrador`, `el-guardian` y `la-herreria`
> consumen. Es a las apps multi-tenant lo que `ONTOLOGY_SCHEMA.md` es a la ontología: un **contrato
> de generación**, no un manual de plataforma.
>
> **Decisión de producto (B1, tomada por Carlos):** las **apps generadas** son multi-tenant; el
> **harness** sigue Claude-first/local (single-tenant por proyecto — un `ONTOLOGY.md` por empresa
> cliente). Una plataforma hospedada multi-cliente es dominio de Forge Cloud (W5), fuera de Enterprise.
> Fuente: `docs/06` §4 M6 + §9-B.

- **Versión:** v0.1.0 (2026-06-30, M6 · Multi-tenant)
- **Generaliza:** `[memory:lessons#L-001]` (RLS single-tenant) → `[memory:lessons#L-005]` (RLS por tenant).
- **Regla de enforcement:** `[memory:CONSTRAINTS.md#R16]` (contrato de aislamiento de tenant) + R7 Layer 4
  (test negativo cross-tenant). ADR: `[memory:decisions#D-028]`.

---

## 1. El modelo de tenancy canónico — shared-DB + RLS por membresía

De los tres modelos clásicos de aislamiento multi-tenant, Forge Enterprise adopta **uno** como Golden
Path y veta los otros dos (quedan como override documentado, nunca default):

| Modelo (`tenant_model.aislamiento`) | Aislamiento | Veredicto Forge |
|--------|-------------|-----------------|
| **A. Shared-DB + shared-schema + RLS por `organization_id`** (`rls`) | lógico, en Postgres RLS | ✅ **Golden Path** |
| B. Shared-DB + schema-por-tenant (`schema-per-tenant`) | fuerte, pero N schemas | ⚠️ override (migraciones × N, no escala a miles de tenants) |
| C. Database-por-tenant (`db-per-tenant`) | físico | ⚠️ override (sólo compliance extremo / residencia de datos por cliente) |

**Por qué A:** es el único modelo consistente con el Golden Path de Forge (Supabase + RLS de Postgres),
extiende `[memory:lessons#L-001]` en vez de reemplazarlo, mantiene **una** migración por cambio de
schema, y el aislamiento es **real** (lo enforce Postgres, no el código de la app). Es el patrón
multi-tenant documentado de Supabase [docs:supabase]. B y C sólo se eligen cuando un
`requisito_seguridad: critico` de `ONTOLOGY.md` (residencia de datos por cliente, air-gap por tenant)
lo obliga — y eso se decide en el Tech Spec (`la-herreria` asset 03), no por default.

> **Degradación segura.** Multi-tenancy es una propiedad de la app, no un default forzado. Si la app
> sirve a **individuos** (no a organizaciones), `[memory:lessons#L-001]` (`auth.uid() = user_id`) sigue
> siendo la regla — no se introduce tenant. El Tech Spec decide; el harness no lo impone.

---

## 2. El esquema base — `organizations` + `memberships`

Toda app multi-tenant arranca con una migración fundacional **`0000_tenancy.sql`** (corre ANTES de
`0001_profiles.sql`), que crea el tenant, la membresía usuario↔tenant, y el helper que las policies
consultan. El template canónico vive en
[`el-migrador/references/tenancy-pattern.sql`](../skills/el-migrador/references/tenancy-pattern.sql);
aquí está el contrato conceptual.

```
auth.users (Supabase)           profiles (1:1 con auth.users — NO lleva tenant; es identidad global)
     │                                │
     └──────────┐                     │  (un usuario tiene un perfil global y pertenece a N orgs)
                ▼                      ▼
        memberships (user_id, organization_id, role)  ──►  organizations (el TENANT)
                                                                  ▲
        <entidad de dominio> (organization_id, …)  ────────────────┘  (toda tabla tenant-scoped)
```

**Decisiones del esquema base:**

- **El tenant es `organizations`** (término por defecto). El **término del tenant es configurable** por
  app — `organization` | `workspace` | `account` | `team` (`docs/07` grupo M). El Tech Spec elige uno y
  lo usa **consistente** como nombre de tabla y de columna FK. La columna FK por defecto es
  `organization_id`; el resto de este doc usa ese nombre.
- **`profiles` NO lleva `organization_id`.** Un usuario es una identidad **global** (1:1 con
  `auth.users`); su pertenencia a tenants vive en `memberships` (N:M). Por eso `0001_profiles.sql` de
  `add-login` **no cambia** en multi-tenant — sigue siendo correcto. El tenant aplica a las **entidades
  de dominio**, no a la identidad.
- **`memberships` lleva `role`** (`owner` | `admin` | `member` por defecto) — la semilla del modelo de
  permisos. Las policies que mutan datos sensibles gatean por rol además de por pertenencia.
- **`unique (organization_id, user_id)`** en `memberships` — un usuario no se duplica dentro de un tenant.

---

## 3. El patrón de policy RLS (el corazón de M6)

El reemplazo de `using (auth.uid() = user_id)` por **pertenencia al tenant** se apoya en un helper
`security definer` que devuelve los `organization_id` del caller:

```sql
-- Helper: orgs a las que pertenece el caller. SECURITY DEFINER + STABLE + search_path fijo.
-- security definer es OBLIGATORIO: evita la recursión infinita de RLS (la policy de memberships
-- llamaría a un select sobre memberships que dispararía su propia policy → recursión). Al correr
-- como owner, el select interno NO re-aplica RLS. El filtro `where user_id = auth.uid()` garantiza
-- que sólo devuelve las orgs del PROPIO caller — no hay leak.
create or replace function public.auth_org_ids()
returns setof uuid
language sql stable security definer set search_path = public as $$
  select organization_id from public.memberships where user_id = auth.uid();
$$;
```

Y toda **tabla tenant-scoped** lleva `organization_id NOT NULL` + dos predicados:

```sql
alter table public.<entidad> enable row level security;

-- LECTURA: sólo filas de orgs a las que pertenezco.
create policy "<entidad> tenant isolation: select" on public.<entidad>
  for select using (organization_id in (select public.auth_org_ids()));

-- ESCRITURA: USING controla qué filas puedo tocar; WITH CHECK impide INSERTAR/mover una fila a una
-- org que NO es mía. Sin WITH CHECK, un member podría escribir en el tenant de otro (IDOR cross-tenant).
create policy "<entidad> tenant isolation: write" on public.<entidad>
  for all
  using      (organization_id in (select public.auth_org_ids()))
  with check (organization_id in (select public.auth_org_ids()));
```

**Los tres invariantes no-negociables (los enforce `el-guardian` y `el-migrador`):**

1. **Toda tabla tenant-scoped lleva `organization_id NOT NULL`** con FK a `organizations(id) on delete cascade`.
2. **Toda policy de escritura tiene `WITH CHECK`** con el predicado de tenant (no sólo `USING`).
3. **El `organization_id` que llega del cliente NUNCA se confía** — lo valida `WITH CHECK` contra la
   membresía real. El server jamás lee `organization_id` del body y lo inserta sin que RLS lo verifique.

### Escrituras gateadas por rol

Cuando sólo `owner`/`admin` pueden mutar (borrar miembros, cambiar settings del tenant), se agrega un
helper de rol y se gatea en la policy de escritura:

```sql
create or replace function public.auth_has_org_role(org uuid, roles text[])
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.memberships
    where user_id = auth.uid() and organization_id = org and role = any(roles)
  );
$$;

create policy "<entidad> admin write" on public.<entidad>
  for all
  using      (public.auth_has_org_role(organization_id, array['owner','admin']))
  with check (public.auth_has_org_role(organization_id, array['owner','admin']));
```

### Tenant activo para escrituras (cuando el usuario pertenece a varias orgs)

Si un usuario pertenece a N orgs, ¿a cuál pertenece una fila nueva? Dos caminos:

- **Explícito (canónico):** el cliente manda `organization_id` y `WITH CHECK` lo valida. Simple,
  RLS-enforced, sin estado de sesión. **Default.**
- **Claim de sesión (override):** un `org_id` activo en el JWT
  (`current_setting('request.jwt.claims', true)::json ->> 'org_id'`) para UX de "org activa única". Útil,
  pero NO reemplaza `WITH CHECK` — es una conveniencia encima, no el gate.

---

## 4. Modelo de amenazas cross-tenant (lo que ataca "El Infiltrado")

El persona adversarial **El Infiltrado** de `el-guardian` (Capa 3) caza estos vectores — un usuario
autenticado del tenant A intentando leer/escribir datos del tenant B:

| # | Vector | Cómo se filtra | Defensa |
|---|--------|----------------|---------|
| T1 | **Tabla sin `organization_id`** | la fila no tiene tenant → RLS no puede aislar | invariante 1 + `el-migrador` la rechaza |
| T2 | **Policy sólo con `USING`, sin `WITH CHECK`** | INSERT/UPDATE mueve filas a otra org | invariante 2 |
| T3 | **`organization_id` del body confiado** | IDOR: el caller declara la org de otro | invariante 3 (`WITH CHECK`) |
| T4 | **`SECURITY DEFINER` que bypassa tenant** | una función definer hace `select … from <entidad>` sin filtrar por org y la expone | toda función definer que toca datos de tenant filtra por `auth_org_ids()` o recibe `org` validado |
| T5 | **FK / join cross-tenant** | join a una tabla cuya RLS no aísla (o un FK a otra org) revela datos | toda tabla del join lleva su propia RLS de tenant; FKs no cruzan tenants |
| T6 | **Leak por agregado / count** | `count(*)`, `sum()` sin RLS de tenant cuenta filas ajenas | RLS aplica a agregados; funciones de reporte declaradas `security invoker` |
| T7 | **`service_role` en el cliente** | la service key bypassa toda RLS | `SUPABASE_SERVICE_ROLE_KEY` jamás en bundle cliente (cruza A02 / R15) |
| T8 | **`current_setting` spoofeado** | confiar un `org_id` de claim sin validar membresía | el claim es conveniencia, no gate (§3); `WITH CHECK` sigue mandando |
| T9 | **Realtime / Storage sin tenant** | canales realtime o buckets sin scope de org filtran | RLS de realtime por org; paths de Storage namespaced por `organization_id` |

`requisitos_seguridad` con `severidad: critico` del `ONTOLOGY.md` que hablen de aislamiento o
residencia por cliente son **Critical automáticos** en este modelo (Capa 0 de `el-guardian`), aunque
OWASP/threat-db no lo marquen.

---

## 5. Disciplina de tests negativos cross-tenant (R7 Layer 4)

El criterio de "listo para liberar" de una app multi-tenant gana una **4ª capa de verificación**
(`[memory:CONSTRAINTS.md#R7]` Layer 4): un **test negativo cross-tenant** sobre DB real (AP1 — nunca
mocks). El template vive en
[`el-migrador/references/tenancy-isolation.test.sql`](../skills/el-migrador/references/tenancy-isolation.test.sql).

**Fixtures mínimos (≥2 tenants):** org A y org B; `user_a ∈ A` (owner), `user_b ∈ B`, `user_m ∈ A`
(member, para el role-gate); ≥1 fila de cada entidad de dominio por org. **Cuatro aserciones (todas
deben pasar), cada negativa con su control positivo para no dar falso verde:**

1. **SELECT:** `user_a` ve **exactamente** sus filas de A — **0** de B.
2. **INSERT:** control positivo — `user_a` **sí** inserta en su propia org (si esto falla, el test rompe,
   no enmascara: descarta un grant/FK roto); negativa — `user_a` **no puede** insertar con
   `organization_id = B` (`WITH CHECK` lo aborta con `insufficient_privilege`/42501, el único error que el
   handler captura).
3. **UPDATE/DELETE ciegos** (sin `where org`, para ejercitar el `USING` de escritura y no la visibilidad
   del SELECT): tras un `update`/`delete` sin filtro de `user_a`, la fila de B sigue **intacta** (ni
   modificada ni borrada).
4. **Role-gate:** una operación de owner/admin (renombrar la org) **falla** para un `member` y **pasa**
   para el `owner` (control positivo).

Un test que pasa contra el patrón correcto **debe fallar** si se le quita `organization_id`, el
`WITH CHECK`, el `USING` de escritura, o el role-gate, o si se cambia un predicado por `true` — esa es su
prueba de que realmente aísla.

---

## 6. Quién consume esta doctrina (análogo a BRAND_DNA / ONTOLOGY)

| Consumidor | Qué hace con M6 |
|------------|-----------------|
| `la-herreria` asset 03 (Tech Spec) | decide el modelo de tenancy + término; sub-paso **3.5 Multi-Tenant Data Model** estampa `organizations`/`memberships` + `organization_id` en las entidades de dominio |
| `la-herreria` asset 09 (Security Audit) | cruza el modelo de amenazas cross-tenant (§4) + exige el test R7 Layer 4 |
| `el-migrador` | valida los 3 invariantes en su pre-validation pipeline; estampa `tenancy-pattern.sql`; gatea el `up` con el test negativo |
| `el-guardian` | persona **El Infiltrado** (Capa 3) + gate de aislamiento; cruza §4 con la threat-db |
| `baas` | el "RLS pattern" que genera tiene variante multi-tenant (este doc) además de la single-tenant L-001 |
| `el-ontologo` / `ONTOLOGY.md` | `tenant_model` (frontmatter) declara si la empresa genera apps multi-tenant, el término del tenant y el modelo de aislamiento |
| skills `add-*` (build, fasable) | sus migraciones de dominio heredan `organization_id` + RLS por membresía **cuando la app es multi-tenant** (ver §7) |

---

## 7. Alcance M6 — diseño (MUST) vs build per-app (fasable)

`docs/06` separa explícitamente **diseño** (MUST) de **build** (fasable): "el multi-tenant entra como
MUST en *diseño* pero su *construcción* es fasable" (`docs/06` §12). Lo que M6 construye AHORA:

- ✅ **La doctrina** (este doc) + el esquema/test canónicos + los 3 invariantes.
- ✅ **El enforcement en el harness:** `el-migrador` (valida + estampa), `el-guardian` (audita), R16,
  R7 Layer 4, el gate DevSecOps de tenant.
- ✅ **El diseño en el flujo:** Tech Spec 3.5, Security Audit cross-tenant, declaración en la ontología.

Lo que es **build per-app fasable** (se materializa cuando una app concreta lo pide, NO se reescribe
ahora en los skills `add-*`):

- La gestión de tenants (UI de orgs, invitaciones, roles) — territorio de **S2 (equipos)**.
- Las migraciones de dominio tenant-aware de `add-payments` (billing **por org** vs por user),
  `add-emails`, `add-mobile` — heredan este patrón cuando el Tech Spec marca la app multi-tenant; sus
  templates single-tenant actuales siguen siendo correctos para apps single-tenant (degradación segura).

> Por eso M6 **no** reescribe los 8 templates `.sql` de los skills `add-*`: serían build prematuro de un
> caso (billing por org) que aún no se especifica. La doctrina + `el-migrador` portan el patrón; cada
> app lo aplica a sus entidades cuando toca.

---

## 8. El contrato en una frase

Una app multi-tenant de Forge **aísla por Postgres, no por código**: toda tabla de dominio lleva
`organization_id NOT NULL`, toda policy de escritura tiene `WITH CHECK` por membresía, el
`organization_id` del cliente nunca se confía, y ningún diseño se marca "listo" sin un test negativo
cross-tenant verde sobre DB real. Es `[memory:lessons#L-001]` elevado de "un usuario" a "una
organización", con el mismo dogma: si otro tenant no debería verlo, RLS lo impide por default.

## Sources

- [docs:supabase] — Row Level Security multi-tenant pattern (security definer helper para evitar recursión de RLS). Validar con `find-docs` (`libraryName: "supabase"`, `query: "multi-tenant RLS organization membership security definer 2026"`) antes de estampar en un proyecto real (R13).
