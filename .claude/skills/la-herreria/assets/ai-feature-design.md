# Asset Especializado — AI Feature Design

> *"La IA en un producto no es una feature — es un nuevo tipo de interfaz entre el usuario y sus datos."*

## Qué Hace

Define la arquitectura técnica de un AI Feature: selección de modelo, patrón de integración (streaming / structured output / tool calling / RAG / memoria), contrato de API, fallback chain. Output: sección de diseño en `AI-FEATURE-BRIEF-[nombre].md`.

Este asset es referenciado por el route `routes/ai-feature.md` (Step 2) y delega la implementación técnica al catálogo `.claude/skills/ai/references/` (12 templates copy-paste-ready).

**Catálogo Forja:** ver `.claude/skills/ai/references/_index.md` para mapping subtipo → template + skill `ai` ([memory:skills#ai]).

---

## Cuándo Usar

- Después del Step 1 del route ai-feature (clasificación de subtipo A–F).
- Cuando el usuario quiere agregar IA a un producto existente o construir uno con IA-as-core.

---

## Inputs Requeridos

- `AI-FEATURE-BRIEF-[nombre].md` (Step 1) — incluye subtipo clasificado A–F.
- `.claude/skills/ai/references/_index.md` — catálogo técnico actualizado.
- *Si subtipo B/C/D:* verificación de pgvector en BaaS (Supabase pgvector / Insforge equivalente).

---

## Subtipos y Templates Mapeados

| Subtipo | Descripción | Template Forja |
|---------|-------------|----------------|
| **A** | Chat Conversacional | `.claude/skills/ai/references/agents/00-setup-base.md` + `01-chat-streaming.md` |
| **B** | RAG / KB del sistema | `agents/00 + 01 + 03-historial-supabase + 06-rag-basico` |
| **C** | Chat con Docs del Usuario | `agents/00 + 03 + 06` + storage layer custom |
| **D** | IA con Memoria Persistente | `agents/00 + 01 + 03-historial-supabase` |
| **E** | Generación Estructurada | `.claude/skills/ai/references/structured-outputs.md` |
| **F** | Tool Calling / Agentic | `.claude/skills/ai/references/agents/05-tools-funciones.md` (R14 strict) |

---

## Workflow

### Paso 1: Selección de Modelo

**Decisión por subtipo (defaults Forja):**

| Subtipo | Modelo recomendado | Provider | Razón |
|---------|---------------------|----------|-------|
| A — Chat | Claude Sonnet 4.6 | OpenRouter | balance calidad/costo |
| B — RAG | Claude Sonnet 4.6 + text-embedding-3-small | OpenRouter + OpenAI | RAG canónico |
| C — Chat con Docs | Claude Sonnet 4.6 + text-embedding-3-small | OpenRouter + OpenAI | igual que B |
| D — Memoria | Claude Sonnet 4.6 | OpenRouter | memoria con context window grande |
| E — Estructurado | Claude Haiku 4.5 (rápido) o Sonnet 4.6 (preciso) | OpenRouter | según trade-off velocidad vs precisión |
| F — Tools | Claude Sonnet 4.6 | OpenRouter | tool calling fiable |

**Citation R13:** [docs:vercel-ai-sdk@v5] para todas las decisiones de SDK.

**Provider:** OpenRouter (default Forja) por:
- Single API key para 300+ modelos.
- Evita lock-in.
- Fallback chain configurable.
- [docs:openrouter]

**Override Insforge Model Gateway:** si BaaS decision (D-009) eligió Insforge → usar el Model Gateway nativo (sin OpenRouter).

### Paso 2: Patrón de Integración

**Por subtipo:**

**A (Chat):** `streamText` + `useChat` (Vercel AI SDK). Streaming UI con loading states específicos. Si requiere memoria persistente → agregar `agents/03-historial-supabase.md`.

**B (RAG/KB):**
- pgvector enabled: `execute_sql("CREATE EXTENSION IF NOT EXISTS vector")` antes de migrations.
- Schema: tabla con `embedding vector(1536)` + index `ivfflat (embedding vector_cosine_ops) WITH (lists=100)`.
- Función `match_documents` con threshold 0.65, LIMIT 5.
- RLS L-001 mandatory en tabla de documents.
- [docs:supabase-pgvector]

**C (Chat con Docs):**
- B + storage layer (Supabase Storage / Insforge Storage).
- Pipeline: upload → text extraction (PDF.js, pdf-parse [docs:pdf-parse]) → chunking 1500/200 overlap → embeddings batch → store con RLS.
- Validación L-003: tipo MIME server-side, no solo extensión.

**D (Memoria):**
- 3 tipos de memoria:
  1. **Historial puro** — append-only, sin limpieza.
  2. **Preferencias estructuradas** — Zod schema, generateObject para extraer.
  3. **Memoria semántica** — embeddings de momentos relevantes (RAG sobre el historial).
- Elegir según necesidad. Default: historial puro + preferencias.

**E (Estructurado):**
- `generateObject` + Zod schema. NO `streamText`.
- Sin streaming UI — typed result directo.
- Validación post-generation con Zod (L-003 en boundary).

**F (Tools / Agentic):**
- Definir cada tool con Zod schema (description + execute opcional).
- **R14 enforced:** tools destructivas (delete*, send*, transfer*, cancel*, deploy*) SIN `execute()` — esperan confirmación humana.
- Confirmation UI antes de invocar destructive tool.
- L-002 awareness: tratar inputs externos como datos no confiables aunque vengan de la IA.

### Paso 3: Fallback Chain

```
Modelo principal → Modelo económico → Respuesta estática
       ↓                    ↓                  ↓
   Sonnet 4.6          Haiku 4.5         "Lo siento, no
                                          puedo ayudar
                                          en este momento"
```

Definir el threshold:
- Latency > Xs → fallback a económico.
- Error rate > Y% → fallback a estático.
- Cost ceiling > $Z/día → throttle + fallback.

### Paso 4: API Contract

```typescript
// Endpoint
POST /api/[feature]/[action]

// Request
{
  message: string,        // L-003: max length validated
  context?: object,       // optional, depends on subtype
}

// Response (streaming for A/B/C/D, structured for E)
// streamText → toDataStreamResponse() // [docs:vercel-ai-sdk@v5]
// generateObject → JSON tipado
```

### Paso 5: Rate Limiting + Observability

- Rate limiting (Upstash Redis): 20 req/min para chat (A/B/C/D), 5 req/min para features costosos (C con docs grandes, F con tools).
- Loggear: `inputTokens`, `outputTokens`, `latencyMs`, `estimatedCostUsd` por request.
- Sentry para errores no recuperables.
- [docs:upstash-redis] para implementación.

### Paso 6: Documentar en AI-FEATURE-BRIEF

Agregar al `AI-FEATURE-BRIEF-[nombre].md` (sección de diseño):

```markdown
## Diseño Técnico

### Subtipo
[A/B/C/D/E/F] — [descripción]

### Modelo
- **Principal:** [modelo + provider]
- **Económico (fallback):** [modelo más barato]
- **Estático (último fallback):** [respuesta predefinida]

### Patrón de Integración
[Vercel AI SDK v5 pattern: streamText / generateObject / streamObject / useChat]

### Templates Forja a Usar
- `.claude/skills/ai/references/[paths]`

### API Contract
[Request schema con Zod L-003 + Response schema]

### Fallback Chain
[Modelo principal → económico → estático con thresholds]

### Rate Limiting
- [N] req/min por usuario en [endpoint]
- HTTP 429 con header Retry-After cuando se excede

### Observability
- Logs: inputTokens, outputTokens, latencyMs, cost
- Sentry para errores no recuperables
- Threshold de revisión: >$200/mes → evaluar model swap

### R14 Destructive Tools (solo subtipo F)
[Lista de tools destructivas — todas SIN execute() automático]
- deleteUser → typed confirmation requerida
- sendBulkEmail → typed confirmation requerida
- ...

### Variables de Entorno
- OPENROUTER_API_KEY (mandatory para A-F)
- OPENAI_API_KEY (mandatory para B/C — embeddings)
- UPSTASH_REDIS_REST_URL (rate limiting)
- SENTRY_DSN (error tracking)
```

---

## Reglas Críticas

1. **OpenRouter como default** — evita lock-in, fallback chain trivial.
2. **R14 strict en subtipo F** — tools destructivas sin `execute()` automático. el-evaluador rechaza output que viole esto.
3. **L-002 awareness** — prompt injection en cualquier input que llegue al LLM. System prompt separado del user input.
4. **L-003 whitelist Zod** en boundaries — schemas en API request, validación de tipo MIME en uploads, length validation en messages.
5. **RLS L-001 en tablas de IA** — `documents`, `chunks`, `chat_history`, `user_preferences` con `user_id` y policy.
6. **Rate limiting NO opcional** — sin esto, costo descontrolado.
7. **Citation grammar R13:** [docs:vercel-ai-sdk@v5], [docs:openrouter], [docs:supabase-pgvector] cuando se cite sintaxis.

---

## Integración con Skills Forja

| Skill | Cómo se usa |
|-------|-------------|
| `ai` | Catálogo principal — leer SKILL.md antes de implementar. |
| `el-guardian` | Audita prompt injection (L-002) y secret isolation pre-deploy. |
| `el-evaluador` | Verifica R7 Three-Layer + R14 destructive tools post-implementation. |
| `add-ui-kit` + `impeccable` | UI del feature consume Brand DNA (R10) — chat panels, action triggers, generative-ui components. |
| `baas` | Decision tree Supabase pgvector / Insforge para RAG y memoria. |
| `find-docs` | Sub-tool ad-hoc — `[docs:libname@version]` antes de generar código. |

---

## Handoff al Step 3

```
✅ AI-FEATURE-BRIEF-[nombre].md actualizado con sección "Diseño Técnico"
✅ Subtipo: [A/B/C/D/E/F]
✅ Templates a usar: [paths del catálogo]
✅ Modelo + provider definidos + fallback chain documentado
✅ R14 audited (si subtipo F)

Siguiente: User Stories IA (route Step 3 → asset 05-user-stories.md adaptado)
Stories que cubren happy path + unhappy path (modelo lento, alucinación, error)
+ stories de feedback (regenerar, thumbs up/down) + stories R14 confirmation
si tools destructivas.

¿Procedemos?
```

---

*"Diseño técnico de IA Forja-native: SDK v5 + OpenRouter + RLS + R10/R13/R14 enforced. El modelo decide qué decir; Forja gobierna cuándo, dónde y cómo."*
