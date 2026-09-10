---
name: ai
description: >
  Catálogo de templates Vercel AI SDK v5 + OpenRouter (300+ modelos). Cubre 9
  capacidades: chat con streaming, web-search, historial persistido en BaaS,
  vision (image analysis), tools (function calling), RAG con pgvector,
  single-call (sin streaming), structured-outputs (Zod schemas), generative-ui
  (componentes generados por el modelo). Dos paths: chat (API route) y action
  (server actions). Cada template es copy-paste-ready en `references/`. NO
  hardcodea API keys; lee `.env`. Integra con `baas` (BaaS-aware), `el-guardian`
  (audita inputs LLM-bound), `el-evaluador` (verifica tras cada template).
tier: core
requires: OPENROUTER_API_KEY (o ANTHROPIC_API_KEY / OPENAI_API_KEY) en `.env`; baas configurado si template requiere persistencia
fallback: OpenAI API directa via SDK oficial si Vercel AI SDK no es opción (documentar el por qué en `TECH-SPEC` y abrir error E-NNN)
dependencies: [find-docs]
---

# ai

> *"Cada feature de IA en Forja es un template aplicado, no código artesanal."*

Skill catálogo. Materializa features de IA leyendo templates de `references/` y aplicándolos al proyecto activo. Stack: **Vercel AI SDK v5 + OpenRouter (default) + BaaS según `baas` decision**.

## PREFLIGHT halt

```
1. ¿Existe AGENTS.md? Si no → halt.
2. ¿OPENROUTER_API_KEY (o equivalente provider) en `.env`? Si no → ofrecer correr `setup-base` para configurarlo.
3. ¿Si el template requiere BaaS (historial, RAG)? → leer `TECH-SPEC-<nombre>.md` sección "BaaS Decision". Si no existe → halt + invocar `baas` primero.
4. ¿Si el template toca UI? → verificar `brand/brand.json` (R10) antes de generar componentes.
```

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Tras `la-herreria` con modo 🤖 (AI Feature) selected | la-herreria handoff |
| Carlos pide "agrega chat", "feature con AI", "RAG", "vision", "function calling" | Coordinator |
| Tras `baas` decide configuración de Model Gateway (InsForge) | baas handoff |
| Iterar/extender capability AI existente | Carlos |

## Catálogo de templates

### Chat path (secuencial, cada uno depende del anterior)

| # | Template | Capability | Asset |
|---|----------|------------|-------|
| 00 | `setup-base` | OpenRouter provider + .env + deps | `references/agents/00-setup-base.md` |
| 01 | `chat` | Chat con streaming completo (API route `/api/chat`) | `references/agents/01-chat-streaming.md` |
| 02 | `web-search` | Grounding con resultados de internet | `references/agents/02-web-search.md` |
| 03 | `historial` | Persistir conversaciones en BaaS (Supabase/InsForge) | `references/agents/03-historial-baas.md` |
| 04 | `vision` | Analisis de imagenes (upload + descripción) | `references/agents/04-vision-analysis.md` |
| 05 | `tools` | Function calling (modelo invoca funciones definidas) | `references/agents/05-tools-funciones.md` |
| 06 | `rag` | RAG con pgvector + embeddings + similarity search | `references/agents/06-rag-pgvector.md` |

### Action path (alternativa server actions)

| # | Template | Capability | Asset |
|---|----------|------------|-------|
| 00 | `setup-base` | mismo setup | `references/agents/00-setup-base.md` |
| 01-ALT | `action-stream` | Streaming via server actions (`useAction`), sin API route | `references/agents/01-alt-action-stream.md` |
| 02-06 | mismo que chat path | | |

### Standalone (independientes)

| Template | Capability | Asset |
|----------|------------|-------|
| `single-call` | una llamada sin streaming (clasificar, resumir, extraer) | `references/single-call.md` |
| `structured-outputs` | respuestas con schema Zod (JSON tipado garantizado) | `references/structured-outputs.md` |
| `generative-ui` | el modelo genera componentes React en tiempo real | `references/generative-ui.md` |

## Mapeo de descripción → template

Si el usuario describe lo que quiere sin nombrar el template:

| Frase del usuario | Template |
|-------------------|----------|
| "un chat", "chatbot", "asistente" | `chat` (o `action-stream` si prefiere actions) |
| "que busque en internet", "grounding" | `web-search` |
| "que recuerde", "historial de conversación" | `historial` |
| "que analice fotos / imágenes" | `vision` |
| "que ejecute funciones", "agente que hace cosas" | `tools` |
| "que busque en mis documentos", "RAG", "embeddings" | `rag` |
| "una respuesta sin chat", "clasificar / resumir / extraer" | `single-call` |
| "datos estructurados", "JSON tipado" | `structured-outputs` |
| "interfaz dinámica generada por el modelo" | `generative-ui` |

## Reglas operativas

1. **Siempre empezar con `setup-base`** si el proyecto no tiene OpenRouter (ni provider equivalente) configurado. Sin `setup-base`, los demás templates fallan al runtime.
2. **No saltar templates en una path.** Chat path = 00 → 01 → 02 → 03 → … Cada uno asume el anterior.
3. **Un template a la vez.** Si el usuario pide múltiples capabilities, aplicar en orden, verificar después de cada uno (`el-evaluador`), commitear, y avanzar.
4. **Templates son copy-paste-ready.** Pero adaptarlos al naming + estructura del proyecto. NO copiar nombres genéricos.
5. **Nunca hardcodear API keys.** Todas las keys vienen de `.env` via `process.env.<NAME>`.
6. **Provider default = OpenRouter.** Si el `baas` decidió InsForge con Model Gateway, usar el gateway endpoint. Si el usuario explícitamente pide Anthropic / OpenAI directo → documentar la decisión + flag `provider_override` en `TECH-SPEC`.

## BaaS-aware

| Template | Requiere BaaS | Razón |
|----------|---------------|-------|
| `setup-base` | ❌ | solo configura provider |
| `chat`, `web-search` | ❌ | sin persistencia |
| `historial` | ✅ Supabase o InsForge con tabla `messages` | persiste conversaciones |
| `vision` | depende | si guarda imágenes → necesita Storage |
| `tools` | depende del tool | algunos persisten resultados |
| `rag` | ✅ Supabase con `pgvector` extension | embeddings + similarity search |
| `single-call`, `structured-outputs`, `generative-ui` | ❌ | runtime puro |

Si el template requiere BaaS, verificar antes de aplicar:
1. `.env` tiene credenciales del BaaS.
2. Schema necesario existe (handoff a `el-migrador` si falta).
3. RLS policies relevantes están aplicadas.

## Brand DNA-aware

Templates que generan UI (`chat`, `action-stream`, `generative-ui`):
1. Leer `brand/brand.json` + `voice.json` antes de instanciar el componente.
2. Aplicar tokens (colores, radius, fonts).
3. Aplicar voice rules a placeholders, error messages, system prompts visibles al usuario.
4. Tras generar, invocar Anti-Slop Gate de `el-evaluador`.

Sin `brand.json` → halt automático por R10.

## Integración con `el-guardian`

Los siguientes templates tocan superficie sensible y requieren handoff a `el-guardian` antes de mergear:

| Template | Riesgo |
|----------|--------|
| `tools` | function calling con input usuario → prompt injection vía tool args |
| `rag` | inyección via documentos del usuario subidos al index |
| `web-search` | LLM consume contenido externo arbitrario → indirect prompt injection |
| `historial` | exposición de conversaciones de otros usuarios si RLS está mal |
| `vision` | uploads sin sanitizar, image-payload prompt injection |

Workflow: aplicar template → `el-evaluador` verifica → si template está en la lista de arriba → `el-guardian` audita → mergear.

## Cost & rate-limit awareness

Para cada template aplicado, anexar a `docs/ai/COST-LOG.md`:

```markdown
## <feature> — <template>

**Date applied:** YYYY-MM-DD
**Provider:** OpenRouter | InsForge Model Gateway | Anthropic | OpenAI
**Model:** <slug>
**Estimated cost per 1k requests:** $X.XX (input $A · output $B)
**Rate limit considered:** <yes/no, strategy>
**Token budget per request:** <num input + num output>
```

Si el cost estimate excede $10/1k requests, advertir al usuario antes de proceder y proponer modelo más barato.

## Output — sección "AI Capabilities" en TECH-SPEC

Tras aplicar un template, escribir/actualizar en `TECH-SPEC-<nombre>.md`:

```markdown
## AI Capabilities

| Capability | Template | Provider | Model | BaaS dependency |
|------------|----------|----------|-------|-----------------|
| Chat con streaming | chat | OpenRouter | anthropic/claude-opus-4-7 | — |
| Historial | historial | OpenRouter | (mismo) | Supabase tabla `messages` |
| RAG | rag | OpenRouter + Supabase | anthropic/claude-opus-4-7 + text-embedding-3-large | Supabase pgvector |

### Sources
- [memory:references#R-NNN] — OpenRouter provider config
- [web:sdk.vercel.ai/docs/v5](url) — Vercel AI SDK v5
```

## Refusals (lo que NUNCA hace)

- ❌ Hardcodear API keys.
- ❌ Saltar `setup-base` si no está aplicado.
- ❌ Aplicar template que requiere BaaS sin verificar configuración.
- ❌ Generar UI sin Brand DNA contract.
- ❌ Aplicar `tools` o `rag` o `vision` sin handoff a `el-guardian` (prompt injection surface).
- ❌ Combinar múltiples templates en un solo commit (atomicidad rota — R2).

## Tool filter

Read · Grep · Glob · Bash (npm install para deps, opcional supabase migration handoff) · Write (`.env.example`, archivos en `src/api/`, `src/app/`, `src/components/ai/`, `docs/ai/`) · Edit en mismos paths.

NO Edit en `.claude/memory/**` (eso lo hace `el-evaluador`). NO Edit en `supabase/migrations/**` (eso lo hace `el-migrador`).

## Loop de ejecución

```
0. PREFLIGHT halt
1. Si el usuario pide capability → mapear a template
2. Si setup-base no aplicado → aplicar primero
3. Por cada template:
   a. Read references/<file>.md
   b. Verificar dependencies (BaaS, Brand DNA, env vars)
   c. Si BaaS dep no satisfecha → halt + handoff a baas / el-migrador
   d. Aplicar template (Edit/Write con copy-paste-ready code adaptado al proyecto)
   e. Anexar a docs/ai/COST-LOG.md
   f. Anexar a TECH-SPEC sección "AI Capabilities"
   g. Devolver al orchestrator
4. el-evaluador → Three-Layer Verification del template aplicado
5. Si el template está en lista sensible → el-guardian audita
6. Si PASS → mergear
```

## Cuándo invocar find-docs

Antes de aplicar CUALQUIER template del catálogo. Vercel AI SDK rompió API entre v4 y v5 (entre otras: `tools` pasó de array a objeto con describe+execute; `streamText` cambió shape de output). Un agente con cutoff anterior va a generar v4 syntax si no consulta.

**Ejemplo:** antes de aplicar `tools` template, invocar `find-docs` con `libraryName: "vercel ai sdk"` y `query: "streamText tools v5 syntax function calling"`. Verificar que el snippet retornado muestra `tools: { weather: { describe: '...', execute: ... } }` (v5) y NO `tools: [{ name, description, parameters, execute }]` (v4). Citar `[docs:vercel-ai-sdk@v5]` en el commit que aplica el template. R13 enforced.

Trigger: el template depende de cualquier API del SDK (todos los templates excepto `setup-base` lo hacen).

## Catalog status (post-F2-port-ai)

13 templates portados desde `saas-factory/.claude/skills/ai/references/` con 5 adaptaciones Forja-específicas (citation grammar [docs:vercel-ai-sdk@v5], find-docs invocation, BaaS abstraction, el-guardian handoff donde aplica, Brand DNA reference donde genera UI):

| Template | LOC | Adaptación clave |
|----------|-----|------------------|
| `references/_index.md` | 153 | TOC con tabla de adaptaciones + handoff per template |
| `references/single-call.md` | 309 | brand tokens + voice |
| `references/structured-outputs.md` | 280 | brand tokens + voice |
| `references/generative-ui.md` | 311 | Brand DNA gate + tools v5 shape (object map) |
| `references/agents/00-setup-base.md` | 250 | BaaS env split (Supabase OR InsForge) |
| `references/agents/01-chat-streaming.md` | 277 | Brand DNA gate + v4→v5 migration table |
| `references/agents/01-alt-action-stream.md` | 625 | Brand DNA gate + semantic tokens (info/warning/success/accent) |
| `references/agents/02-web-search.md` | 250 | el-guardian handoff (indirect prompt injection) |
| `references/agents/03-historial-baas.md` | 831 | renombrado de 03-historial-supabase; Supabase + InsForge sub-secciones; el-guardian handoff |
| `references/agents/04-vision-analysis.md` | 520 | el-guardian handoff (uploads + image-payload prompt injection) |
| `references/agents/05-tools-funciones.md` | 506 | el-guardian handoff; v5 shape (`inputSchema`, `stopWhen`); whitelist enums; convención: destructivas SIN `execute` |
| `references/agents/06-rag-basico.md` | 461 | BaaS-aware (Supabase pgvector + InsForge); RLS por user_id agregado; `security invoker` en match function |
| **Total** | **4773 LOC** | port adaptado |

Catalog completo. Los templates son copy-paste-ready y se aplican uno por commit (R2 atomic commits).

Decisión registrada del rename `03-historial-supabase` → `03-historial-baas` en [memory:decisions#D-004](../../memory/decisions.md).

---

*"OpenRouter por default. Provider switch documentado. Cada template es un commit atómico."*
