# LLM Cost Optimization — Cost-Aware AI Dev en Forja

> Citable como `[memory:references#llm-cost-optimization]`. Aplica en assets de `routes/ai-feature.md` y en cualquier feature que invoque modelos via Vercel AI SDK + OpenRouter.

Forja's Golden Path para AI features es **Vercel AI SDK v5** + **OpenRouter** [docs:vercel-ai-sdk@v5]. Este doc cubre cómo no quemar la corrida de validación con un costo desproporcionado al valor entregado, y cómo pensar el TCO (total cost of ownership) por patrón AI antes de elegir.

---

## Principios de Cost-Aware AI Dev

### 1. Prompt caching primero, optimización del modelo después

Anthropic prompt caching (vía Claude Sonnet/Opus) reduce ~90% del costo de tokens en el system prompt y en bloques estáticos cuando se reusan en cadena. Vercel AI SDK v5 expone `cache_control` blocks en los messages [docs:vercel-ai-sdk@v5]. Antes de bajar de modelo, intentar cachear.

Regla práctica: cualquier endpoint que reciba >10 req/min con >2k tokens de contexto estático debe cachear ese prefijo.

### 2. Match modelo a tarea — no usar Opus por default

| Tarea | Modelo recomendado | Por qué |
|-------|-------------------|---------|
| Clasificación / extracción JSON / etiquetado | Haiku 4.5 | costo bajísimo, latencia baja, suficiente |
| Chat conversacional / RAG simple / summarization | Sonnet 4.6 / 4.7 | sweet spot calidad/costo |
| Razonamiento complejo / código difícil / agentes | Opus 4.7 | solo cuando el job lo justifica |

Default razonable en Forja: **Sonnet 4.6** para la primera versión, evaluar bajar a Haiku si el use case lo permite (test A/B con sample real).

### 3. Output length control — los tokens de salida cuestan 4-5× más que entrada

Un prompt de 2k tokens con respuesta de 800 tokens cuesta ~3× más en output que en input. Truncar respuestas con `max_tokens` realista al caso (no el default de 4096) y, en structured-output con Zod, definir schemas que no permitan listas infinitas.

Si stream `streamText`, ofrecer `experimental_stopOnToolCall` o stops semánticos (ej: cuando el JSON cierra) para no pagar tokens de respuesta de relleno.

### 4. Piensa en el unit-economics antes de codear

Antes de escribir el primer prompt, calcular: `costo por request × requests por usuario por mes × usuarios objetivo`. Si el resultado supera el ARPU/LTV razonable del producto → replantear arquitectura (cachear, reducir contexto, switchear modelo, batchear).

---

## Estimación de costos por patrón

Tabla aproximada con OpenRouter pricing 2026 ([docs:openrouter] para verificar). Asume Sonnet 4.6 si no se aclara modelo. Tokens incluye system + user + tools + outputs.

| Patrón AI | Tokens/request (estimado) | Costo/1000 reqs (Sonnet 4.6, sin cache) | Notas |
|-----------|---------------------------|------------------------------------------|-------|
| Chat simple (1 turn) | ~1.5k in + 0.5k out | ~$3 | Reduce a ~$0.50 con prompt caching del system. |
| Chat multi-turn (5 turns avg) | ~6k in + 2k out (acumulado) | ~$15 | Cache turns previos como bloque para bajar a ~$5. |
| RAG con pgvector top-3 | ~4k in (3 docs × 1k) + 1k out | ~$8 | Cache system + few-shot estático. Bajar a Haiku si la calidad alcanza. |
| Structured output (form parsing Zod) | ~1k in + 0.4k out | ~$2 | Haiku 4.5 lo hace bien y baja el costo a ~$0.20. |
| Generative UI (componentes generados) | ~3k in + 1.5k out | ~$10 | El output JSON pesa — limitar componentes posibles con union estricto. |
| Vision (image analysis 1024×1024) | ~2k tokens equivalentes + 0.6k out | ~$5 | Considerar bajar la resolución antes de mandarla. |

**Lectura:** un chat con 1k usuarios activos haciendo 5 req/día corre `1000 × 5 × 30 × $0.003 = $450/mes` sin caching. Con caching agresivo cae a ~$80. Esa diferencia decide si el feature sobrevive.

---

## Estrategias de reducción

### A. Prompt caching (Vercel AI SDK v5)

[docs:vercel-ai-sdk@v5] documenta `cache_control: { type: 'ephemeral' }` en los messages. Reglas para que el cache hit:

1. El bloque cacheado debe ser **prefix idéntico**: orden de messages estable, contenido idéntico carácter a carácter.
2. TTL del cache es 5 min — cargas con menos de 5 min entre requests pegan al cache.
3. Cachear lo que **no cambia por usuario**: system prompt, instrucciones de tools, few-shot examples. NO cachear bloques con datos de usuario que varían por sesión.

Patrón canónico en Forja: separar `system` (cacheable) + `developer` (cacheable, instructions específicas del feature) + `user` (no cacheable, varía).

### B. Selección de modelo por endpoint, no global

OpenRouter permite cambiar `model:` por route. Vercel AI SDK lo expone limpio:

```ts
const result = streamText({
  model: openrouter('anthropic/claude-haiku-4-5'),  // tarea simple
  messages: [...],
});
```

[docs:vercel-ai-sdk@v5] + [docs:openrouter]. Mantener un map en `lib/ai/models.ts` con: `classification → haiku`, `chat → sonnet`, `agent → opus`. Re-evaluar trimestralmente con sample real.

### C. Output control

- `maxOutputTokens` siempre definido y conservador (no el default).
- En structured outputs con Zod (`generateObject`/`streamObject`), definir schemas con `.max(N)` en arrays.
- Para chat largo, implementar **conversation summarization**: cuando el historial pasa N turns, comprimirlo con un Haiku call y reemplazar los turns viejos por el summary. Reduce input tokens significativamente.

### D. Batching cuando aplica

OpenRouter no tiene batch API equivalente al de Anthropic Messages Batches. Para casos de uso async (clasificar 10k entradas), considerar:

- Anthropic API directa con Batch API (~50% descuento, latencia 24h ok para offline).
- Cola interna (BullMQ + Redis o Supabase queues) para suavizar bursts y aprovechar caching consecutivo.

### E. Cache de embeddings + cosine threshold

Para RAG, embedding cost es bajo pero suma. Patrón:

1. Embedding de query con OpenAI `text-embedding-3-small` (más barato que ada-002). [docs:openai]
2. pgvector cosine similarity con threshold 0.78–0.85 según el dominio.
3. **Cachear embeddings** de queries frecuentes (Redis o pg table con TTL 24h). Las queries se repiten más de lo que parece.
4. Si la query cae bajo el threshold → no llamar al LLM, devolver fallback (`No tengo info sobre eso, pregunta soporte`).

---

## Red flags de over-spend

Si una feature AI tiene >1 de estos, está sobre-cocinada o mal medida:

1. **System prompt >5k tokens sin caching.** Probablemente repite info que podría ser tools documentation o RAG.
2. **`maxOutputTokens` no definido o >4096.** Pagás por tokens de relleno.
3. **Mismo modelo (Opus o Sonnet) para todo el producto.** Clasificación + chat + agente: tres tareas, tres modelos.
4. **Prompt caching no implementado pese a tener prefix estable.** Plata tirada — el setup es trivial en Vercel AI SDK [docs:vercel-ai-sdk@v5].
5. **Sin métrica de `tokens_in / tokens_out per request`.** Si no instrumentás esto en `observability-guide`, no podés optimizar; estás volando ciego.

---

## Sources

- [docs:vercel-ai-sdk@v5] — `cache_control`, `streamText`, `generateObject`, `maxOutputTokens`
- [docs:openrouter] — model catalog y pricing
- [docs:openai] — embeddings (`text-embedding-3-small`)
- `.claude/skills/ai/SKILL.md` — catálogo de templates con anotaciones de costo por patrón
- `.claude/skills/la-herreria/references/observability-guide.md` — instrumentación de métricas LLM
- [memory:CONSTRAINTS.md#R13] — citation grammar para libs externas
