---
name: baas
description: >
  Decision tree para elegir BaaS (Supabase vs InsForge) según Tech Spec del
  proyecto, y generador de configuración inicial (env vars, MCP config, schema
  starter, RLS pattern). Default cuando no hay Tech Spec = Supabase. Produce
  decisión documentada en `TECH-SPEC-<nombre>.md` sección "BaaS Decision" con
  rationale citable. Después de decidir, hace handoff a `el-migrador` para
  bootstrap del schema y a `add-login` (si aplica) para auth.
tier: core
requires: Tech Spec del proyecto generado por la-herreria (`TECH-SPEC-<nombre>.md` con sección "Backend Requirements")
fallback: Supabase como default cuando no hay Tech Spec; documentar la asunción en `TECH-SPEC-<nombre>.md` con flag `bass.assumed_default = true`
dependencies: [find-docs]
---

# baas

> *"La decisión de backend la toma la naturaleza del proyecto, no el agente."*
> — Forja D11

Skill consolidator. Reemplaza los antiguos skills separados `supabase` e `insforge` (Forge legacy) por un decision-tree que elige el BaaS apropiado y genera la configuración inicial. La consolidación 22 → 14 skills (D5) aplica acá: una entrada con decisión + dos paths.

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md? Si no → halt.
2. ¿Existe TECH-SPEC-<nombre>.md? Si no → fallback: usar Supabase con flag `assumed_default`. Loggear asunción.
3. ¿Tech Spec tiene sección "Backend Requirements"? Si no → pedir clarificación al usuario antes de decidir.
4. ¿BaaS ya está configurado en .env? Si sí → halt: "Ya hay BaaS configurado (NEXT_PUBLIC_<X>_URL detectado). Para cambiar, correr `baas migrate` (NO implementado en Phase 2)."
```

## Decision tree

el-baas extrae 6 señales del Tech Spec y produce un score:

### Señal 1 — Modo de operación primario

| Señal | Supabase | InsForge |
|-------|----------|----------|
| Equipo humano construye con DX intensiva | +2 | 0 |
| Agentes (Forja) construyen mayoría del backend | 0 | +2 |
| Equipo mixto (humanos + agentes) | +1 | +1 |

### Señal 2 — Hosting

| Señal | Supabase | InsForge |
|-------|----------|----------|
| Vercel + Supabase Cloud (managed) | +2 | 0 |
| Self-hosted Coolify / Docker Compose | +1 | +2 |
| Multi-cloud / on-prem enterprise | +2 | 0 |

### Señal 3 — Necesidad AI

| Señal | Supabase | InsForge |
|-------|----------|----------|
| Sin features AI por ahora | +1 | 0 |
| AI features con un solo provider | +1 | +1 |
| AI multi-provider con failover (OpenRouter, Anthropic, OpenAI, Gemini) | 0 | +2 |
| Model Gateway nativo deseado | 0 | +2 |

### Señal 4 — Ecosystem & comunidad

| Señal | Supabase | InsForge |
|-------|----------|----------|
| Necesita libs comunitarias maduras (auth helpers, react SDK) | +2 | 0 |
| OK con nuevo ecosystem | +1 | +1 |
| Vibe-coding-first, agents prefieren API simple | 0 | +2 |

### Señal 5 — SLAs y soporte enterprise

| Señal | Supabase | InsForge |
|-------|----------|----------|
| Cliente requiere SLA con soporte | +2 | 0 |
| Self-managed, downtime tolerado | +1 | +1 |
| Vibe-coding sin SLA explícito | +1 | +2 |

### Señal 6 — Real-time / Edge functions

| Señal | Supabase | InsForge |
|-------|----------|----------|
| Real-time crítico para UX | +2 | +1 |
| Edge functions necesarias | +2 | +1 |
| CRUD básico, sin real-time | +1 | +2 |

### Cálculo

```
supabase_score = sum(supabase points)
insforge_score = sum(insforge points)

if supabase_score > insforge_score + 2 → DECISION: Supabase
elif insforge_score > supabase_score + 2 → DECISION: InsForge
else → DECISION: presentar al usuario el tie-breaker
```

Diferencia ≤ 2 = decisión cerrada. el-baas presenta ambos scores + un tie-breaker basado en la señal con mayor diferencia.

## Path: Supabase

Si decisión = Supabase, generar:

### .env (template)

```bash
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>   # Solo server-side, NUNCA exponer al cliente
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

### `supabase/config.toml`

Generado por `supabase init`. el-baas no lo escribe a mano.

### MCP config (`example.mcp.json`)

```json
{
  "supabase": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres", "<connection-string>"],
    "env": {}
  }
}
```

### Schema starter

`supabase/migrations/<timestamp>_init_schema.sql` con:
- `auth.users` (gestionado por Supabase Auth, no se modifica)
- `public.profiles` (extiende auth.users, RLS habilitado)
- Política RLS base — **dos variantes según el tenancy model del Tech Spec (M6):**
  - **single-tenant** (default por usuario): `auth.uid() = id` / `auth.uid() = user_id` (`[memory:lessons#L-001]`).
  - **multi-tenant** (por organización): foundation `0000_tenancy.sql` + `organization_id` + RLS por
    membresía + `WITH CHECK` (`[memory:lessons#L-005]`, R16). Doctrina + template:
    [`.claude/references/MULTI_TENANCY.md`](../../references/MULTI_TENANCY.md).

Handoff a `el-migrador` para aplicar la migration inicial (y estampar `0000_tenancy.sql` si multi-tenant).

## Path: InsForge

Si decisión = InsForge, generar:

### .env (template)

```bash
NEXT_PUBLIC_INSFORGE_URL=https://<project>.insforge.dev
NEXT_PUBLIC_INSFORGE_ANON_KEY=<anon-key>
INSFORGE_SERVICE_KEY=<service-key>   # Solo server-side
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

### MCP config (`example.mcp.json`)

```json
{
  "insforge": {
    "url": "https://<project>.insforge.dev/mcp",
    "transport": "http",
    "auth": "oauth"
  }
}
```

InsForge usa OAuth para MCP — no requiere token local.

### Schema starter

InsForge usa Postgres también, así que migrations siguen mismo formato que Supabase. Handoff a `el-migrador`.

### Model Gateway setup

Si Tech Spec marcó "AI multi-provider" como señal:

```bash
# Configuración en InsForge dashboard:
# Settings → Model Gateway → Add Providers
# - OpenAI (key)
# - Anthropic (key)
# - OpenRouter (key)
# - Gemini (key)
#
# El gateway expone /api/ai/chat con failover automático
```

Handoff a `ai` skill para integración con Vercel AI SDK.

## Output — sección "BaaS Decision" en TECH-SPEC

el-baas escribe esta sección al archivo `TECH-SPEC-<nombre>.md`:

```markdown
## BaaS Decision

**Date:** YYYY-MM-DD
**Decision:** Supabase | InsForge
**Score:** Supabase N · InsForge M (diff: D)
**Mode:** humans-primary | agents-primary | mixed

### Signals evaluated

| # | Signal | Supabase pts | InsForge pts |
|---|--------|--------------|--------------|
| 1 | Operating mode | … | … |
| 2 | Hosting | … | … |
| 3 | AI needs | … | … |
| 4 | Ecosystem | … | … |
| 5 | SLA | … | … |
| 6 | Real-time / Edge | … | … |

### Rationale

<2-3 oraciones explicando la decisión basada en los puntos diferenciales más altos>

### Configuration handoffs
- el-migrador → bootstrap schema migration (`<timestamp>_init_schema.sql`)
- add-login (si auth en MVP) → setup auth flow
- ai (si AI en MVP) → setup AI integration con <provider/gateway>

### Sources
- [memory:decisions#D-011] — BaaS decision tree
- [web:supabase.com/docs](url) | [web:insforge.dev/docs](url)
```

## Migración entre BaaS (out of scope Phase 2)

Cambiar de Supabase a InsForge (o viceversa) post-decisión es un proceso documentado fuera de este skill. Para Phase 2: la decisión es por proyecto y se mantiene. Si Carlos pide migración:

```
baas migrate → halt: "Migración entre BaaS no implementada en Phase 2.
Documentar requerimiento + abrir feature en Phase 4 o 5."
```

## Refusals

- ❌ Decidir sin Tech Spec ni inputs explícitos → fallback a Supabase con flag.
- ❌ Setear ambas configuraciones simultáneamente (un proyecto, un BaaS).
- ❌ Sobrescribir `.env` existente sin backup.
- ❌ Generar service role key (eso lo hace el dashboard del proveedor; el-baas solo deja placeholder).
- ❌ Aplicar la migration inicial (eso lo hace `el-migrador`).

## Tool filter

Read · Grep · Glob · Bash (curl para verificar URLs de proveedor) · Write (`.env.example`, `supabase/config.toml`, `example.mcp.json`, sección de `TECH-SPEC-<nombre>.md`).

NO Edit en código de aplicación (`src/**`).

## Loop de ejecución

```
0. PREFLIGHT halt
1. Read TECH-SPEC-<nombre>.md → extraer "Backend Requirements"
2. Si falta sección o es vague:
   a. Pedir clarificación al usuario (3 preguntas máximo)
3. Calcular score por las 6 señales
4. Si diff > 2 → decisión clara
5. Si diff ≤ 2 → presentar tie-breaker al usuario, esperar respuesta
6. Generar archivos según path elegido (Supabase | InsForge)
7. Escribir sección "BaaS Decision" en TECH-SPEC-<nombre>.md
8. Handoff:
   a. el-migrador → bootstrap schema
   b. add-login (si auth en MVP)
   c. ai (si AI en MVP)
9. Devolver al orchestrator
```

## Cuándo invocar find-docs

Antes de generar el `.env`, MCP config, o instrucciones de cliente Supabase/InsForge cuyas keys, métodos o auth flow pudieron cambiar post-cutoff.

**Ejemplo:** antes de escribir el snippet de `createClient` (Supabase JS) en docs del proyecto target, invocar `find-docs` con `libraryName: "supabase"` y `query: "createClient signature 2026 server vs browser cookies"` para confirmar que la API actual sigue siendo `createServerClient` / `createBrowserClient` (split en v0.5+) y no la legacy `createClient` única. Citar `[docs:supabase]` en el output. Equivalente para InsForge: `libraryName: "insforge"`, `query: "Model Gateway endpoint auth header 2026"`.

Trigger: cualquier env var, header, signature de método, o flow de auth de Supabase / InsForge cuya forma actual no fue usada en sesión reciente.

## Integraciones

- **`find-docs`:** consulta APIs cliente y env-var schemas de Supabase / InsForge antes de generar.
- **`la-herreria` Fase 3 (Tech Spec):** input → produce sección "Backend Requirements" → input para `baas`.
- **`el-migrador`:** `baas` genera el migration starter; `el-migrador` lo aplica.
- **`add-login`:** si auth está en MVP, `baas` lo invoca después de configurar.
- **`ai`:** si Model Gateway elegido, `baas` documenta y handoff a `ai` skill.
- **`el-evaluador`:** registra la decisión como D-NNN en `decisions.md` si es novedosa para el proyecto.

---

*"Una decisión por proyecto. Documentada. No reabrible sin razón."*
