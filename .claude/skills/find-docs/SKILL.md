---
name: find-docs
description: >
  Wrapper sobre Context7 MCP (https://github.com/upstash/context7) para
  consultar docs actualizadas de libs externas antes de generar código. Resuelve
  alucinación de sintaxis post-cutoff. Dos llamadas: `resolve-library-id`
  (libraryName → libraryId canónico) y `query-docs` (libraryId + query → docs).
  Cache local de IDs comunes en `references.md` para evitar resolve calls
  redundantes. Output esperado: snippet de docs citado con `[docs:libname]` o
  `[docs:libname@version]` (grammar registrada en conventions.md, enforced por
  R13).
tier: core
requires: Context7 MCP configurado en `.mcp.json` (entry `context7`, ver `example.mcp.json`); `CONTEXT7_API_KEY` en env (opcional pero recomendado para rate limits)
fallback: WebFetch a docs oficiales del lib si Context7 no responde o no encuentra el lib; documentar el miss en `errors.md` (E-NNN) para que `el-evaluador` evalúe si añadir/promover el lib en `references.md`
---

# find-docs

> *"Antes de escribir código contra una lib externa, traé sus docs actuales."*
> — Forja R13

Skill catálogo. Wraps Context7 con un protocolo de 2 pasos (resolve → query) más una capa de cache local de IDs canónicos. Es la primera llamada que cualquier skill que escriba código contra una lib externa debe hacer.

## PREFLIGHT halt

```
1. ¿Context7 entry en .mcp.json? Si no → halt: "Context7 MCP no configurado. Copiá example.mcp.json a .mcp.json y completá CONTEXT7_API_KEY (opcional) en .env."
2. ¿Tools `resolve-library-id` y `query-docs` disponibles vía MCP? Si no → halt + sugerir reiniciar el cliente o re-config.
3. ¿La query del usuario es sobre un lib externo (import, API call, config, sintaxis NO-estándar de JS/TS)? Si es JS/TS estándar → no aplica este skill, devolver al caller.
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Tras `el-migrador` antes de generar SQL contra Supabase CLI sintaxis | el-migrador handoff |
| Tras `baas` antes de escribir cliente Supabase / InsForge | baas handoff |
| Tras `ai` antes de aplicar un template Vercel AI SDK v5 | ai handoff |
| Tras `add-login`, `add-payments`, `add-emails`, `add-mobile` (Fase 3) antes de generar código | skill handoff |
| Carlos pide "verifica la sintaxis de X", "está actualizado Y", "cómo se hace Z en versión N" | Coordinator |
| Cualquier skill que vaya a usar import/API/config de un lib externo | self-invocation antes de Edit/Write |

NUNCA se invoca para sintaxis JS/TS estándar (Array.map, Promise, async/await). El gate es: ¿el código depende de un package externo cuya API pudo cambiar post-cutoff?

## Protocolo de 2 pasos

### Paso 1 — `resolve-library-id`

Convierte un nombre humano a un Context7-compatible library ID.

```
MCP call: resolve-library-id
Params:
  query: "<la pregunta del usuario>"     // ej: "stream chat with tools"
  libraryName: "<nombre humano>"          // ej: "vercel ai sdk"
Output:
  libraryId: "/<canonical/path>"          // ej: "/vercel/ai"
```

**Cache local.** Antes del MCP call, lee `.claude/skills/find-docs/references.md` — si el libraryName está mapeado a un ID conocido, salta directamente al Paso 2.

### Paso 2 — `query-docs`

Trae el snippet relevante para la pregunta.

```
MCP call: query-docs
Params:
  libraryId: "/<canonical/path>"
  query: "<la pregunta del usuario>"
Output:
  docs: <markdown snippet con código + explicación>
```

**Si la respuesta es vacía o ambigua:** raise NEEDS_FIX al caller con el lib + query, sugerir reformular query o checar versión.

## Output format

Cuando find-docs devuelve docs al caller, debe envolver en este formato:

```markdown
### Docs — <libraryName>[@version]

**Source:** Context7 (`<libraryId>`)
**Query:** <la pregunta>

<snippet de docs>

[docs:<libname>] — citation grammar para reusar en el output del caller
```

El caller usa la cita `[docs:libname]` o `[docs:libname@version]` en su output cuando incorpora la info al código generado.

## Ejemplos concretos

### 1. Vercel AI SDK v5 — `streamText` con `tools`

```
Paso 1 (resolve):
  libraryName: "vercel ai sdk"
  query: "streamText with tools function calling v5"
  → libraryId: "/vercel/ai"

Paso 2 (query):
  libraryId: "/vercel/ai"
  query: "streamText tools parameter v5 syntax"
  → docs: snippet showing v5 streamText({ model, tools: { ... } })
          (tools as object with describe + execute, NOT v4's array shape)
```

Caller en `ai` skill cita: `[docs:vercel-ai-sdk@v5]` cuando aplica el template `tools`.

### 2. Supabase CLI — `migration new`

```
Paso 1:
  libraryName: "supabase"
  query: "migration new naming convention"
  → libraryId: "/supabase/supabase"

Paso 2:
  libraryId: "/supabase/supabase"
  query: "supabase migration new <name> file format"
  → docs: snippet of `supabase migration new <name>` generates
          `<timestamp>_<name>.sql` in supabase/migrations/
```

Caller en `el-migrador` cita: `[docs:supabase]`.

### 3. Stripe Checkout — Session API

```
Paso 1:
  libraryName: "stripe"
  query: "Checkout session create"
  → libraryId: "/stripe/stripe-node"

Paso 2:
  libraryId: "/stripe/stripe-node"
  query: "stripe.checkout.sessions.create payment_intent_data 2026 API"
  → docs: snippet of Session.create with line_items, mode, success_url
```

Caller en `add-payments` (Fase 3) cita: `[docs:stripe]`.

## Cache de IDs canónicos

Ver `.claude/skills/find-docs/references.md` — mapping `<libraryName>` → `<libraryId>` para los libs que ya se validaron al menos una vez. Evita `resolve-library-id` redundante.

Cuando un lib nuevo se resuelve, `el-evaluador` (sole writer) lo agrega al cache si la query fue exitosa.

## Refusals

- ❌ Generar código sin haber consultado docs cuando el lib no está en estándar JS/TS.
- ❌ Usar respuestas de Context7 sin la cita `[docs:libname]` en el output del caller.
- ❌ Omitir el version pin cuando aplica (ej. Vercel AI SDK v4 vs v5 tienen API diferente).
- ❌ Cachear IDs canónicos en `references.md` directamente (eso lo hace `el-evaluador`).
- ❌ Modificar `.claude/skills/find-docs/references.md` desde el propio skill (R5 — sole writer).

## Tool filter

MCP: `resolve-library-id`, `query-docs`. Read (cache + own SKILL.md). Bash (solo si fallback WebFetch necesario, raro).

NO Edit ni Write en código de aplicación. Es un skill de consulta, no de generación.

## Fallback — WebFetch

Si Context7 no responde o devuelve "library not found":

1. Identificar URL de docs oficiales del lib (ej. https://supabase.com/docs, https://sdk.vercel.ai/docs).
2. WebFetch con prompt específico de la pregunta del caller.
3. Citar como `[web:dominio.com](url)` en lugar de `[docs:libname]`.
4. Reportar el miss a `el-evaluador` para que decida:
   - Si el lib es valioso → escribir E-NNN + considerar añadirlo al cache de `references.md` cuando Context7 lo soporte.
   - Si es lib edge case → solo registrar el miss.

## Loop de ejecución

```
0. PREFLIGHT halt
1. Recibir <libraryName> + <query> del caller
2. Lookup en references.md cache:
   - Si hit → skip a paso 4 con cached libraryId
3. resolve-library-id(query, libraryName) → libraryId
4. query-docs(libraryId, query) → docs snippet
5. Wrap en output format con citation grammar
6. Devolver al caller
7. (background) Si libraryId era nuevo, propose entry para references.md → el-evaluador
```

## Integraciones (skills retrofitted)

| Skill | Cuándo invoca find-docs | Lib típico |
|-------|--------------------------|------------|
| `el-migrador` | antes de generar SQL contra sintaxis Supabase CLI | `supabase` |
| `baas` | antes de escribir cliente Supabase / InsForge | `supabase`, `insforge` |
| `ai` | antes de aplicar template Vercel AI SDK | `vercel-ai-sdk` |
| `add-login` (F3) | antes de Supabase Auth flow | `supabase`, `next-auth` |
| `add-payments` (F3) | antes de Stripe / Polar SDK | `stripe`, `polar` |
| `add-emails` (F3) | antes de Resend + React Email | `resend`, `react-email` |
| `add-mobile` (F3) | antes de PWA / VAPID push | `web-push`, `next-pwa` |

---

*"Cada import contra un lib externo paga el peaje de find-docs. Sin excepción."*
