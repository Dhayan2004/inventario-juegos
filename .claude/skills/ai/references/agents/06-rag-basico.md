# Bloque 06 — RAG Básico

> Retrieval Augmented Generation con BaaS + pgvector. Búsqueda semántica + tool `getInformation` para el agente.

**Tiempo:** 30 minutos
**Prerequisitos:** Bloque 00 (Setup) + Bloque 03 (BaaS configurado con `agent_sessions` y `agent_actions`)

---

## Antes de empezar (R13)

Antes de generar código, invocá [`find-docs`](../../find-docs/SKILL.md) con:
- `resolve-library-id('vercel-ai-sdk') → query-docs('embed embedMany v5')` para confirmar el shape de `embed` / `embedMany` en v5.
- `resolve-library-id('supabase') → query-docs('pgvector hnsw match function 2026')` para confirmar el patrón de `vector_cosine_ops` y `match_embeddings` function (cambió levemente entre Postgres 15 y 16).

Citar `[docs:vercel-ai-sdk@v5]` y `[docs:supabase]` en el output.

---

## Brand DNA gate (R10)

Si renderizás el chat consumidor del RAG, los componentes UI van con tokens del brand. El RAG core (rag.ts, embeddings.ts, chunking.ts) es backend puro y no tiene UI.

---

## Qué obtenés

- Base de conocimiento consultable por el agente
- Embeddings almacenados en BaaS (Supabase pgvector o equivalente InsForge)
- Búsqueda semántica (por significado, no keywords)
- Tool `getInformation` para el chat
- Hybrid search opcional (semántico + full-text)
- Cache de embeddings opcional

---

## Concepto RAG

```
Indexación (una vez):
  Documento → chunking → embeddings → BaaS

Consulta (cada pregunta):
  Pregunta → embedding → búsqueda similitud → context → LLM → respuesta
```

---

## 1. Setup BaaS — Supabase pgvector [docs:supabase]

```sql
-- Aplicar via `el-migrador` (no copiar a la consola)
-- supabase migration new add_rag_pgvector

-- Habilitar extensión
create extension if not exists vector;

-- Tabla de recursos (contenido original)
create table resources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  content text not null,
  metadata jsonb default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Tabla de embeddings (chunks vectorizados)
create table embeddings (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid references resources(id) on delete cascade,
  content text not null,
  embedding vector(1536), -- text-embedding-3-small dimension
  created_at timestamptz default now()
);

-- Índice HNSW para búsqueda rápida
create index on embeddings using hnsw (embedding vector_cosine_ops);

-- RLS — OBLIGATORIO
alter table resources enable row level security;
alter table embeddings enable row level security;

create policy "Users can CRUD own resources"
  on resources for all using (auth.uid() = user_id);

create policy "Users can CRUD embeddings of own resources"
  on embeddings for all using (
    resource_id in (select id from resources where user_id = auth.uid())
  );

-- Función de búsqueda por similitud (respeta RLS via auth.uid filter)
create or replace function match_embeddings(
  query_embedding vector(1536),
  match_threshold float default 0.5,
  match_count int default 5
)
returns table (
  id uuid,
  content text,
  similarity float
)
language sql stable
security invoker  -- usa permisos del caller, no del owner
as $$
  select
    embeddings.id,
    embeddings.content,
    1 - (embeddings.embedding <=> query_embedding) as similarity
  from embeddings
  where 1 - (embeddings.embedding <=> query_embedding) > match_threshold
  order by embeddings.embedding <=> query_embedding
  limit match_count;
$$;
```

> Aplicar via `el-migrador`. La migration genera `.rollback.sql` (drop policies, drop function, drop tables, drop extension si nadie más la usa).

## 1-bis. Setup BaaS — InsForge equivalente [docs:insforge]

InsForge soporta pgvector en su Postgres backend. Mismo SQL, distinto helper de auth (probablemente `current_setting('jwt.claims.sub')::uuid` o `insforge_uid()` — validar con `find-docs`). Aplicar via SQL runner del `insforge` CLI.

---

## 2. Configurar embeddings [docs:vercel-ai-sdk@v5]

```typescript
// lib/ai/embeddings.ts

import { embed, embedMany } from 'ai'
import { openrouter } from '@/lib/ai/openrouter'

const EMBEDDING_MODEL = 'openai/text-embedding-3-small'

export async function generateEmbedding(text: string): Promise<number[]> {
  const { embedding } = await embed({
    model: openrouter.textEmbeddingModel(EMBEDDING_MODEL),
    value: text,
  })
  return embedding
}

export async function generateEmbeddings(texts: string[]): Promise<number[][]> {
  const { embeddings } = await embedMany({
    model: openrouter.textEmbeddingModel(EMBEDDING_MODEL),
    values: texts,
  })
  return embeddings
}
```

---

## 3. Funciones de chunking

```typescript
// lib/ai/chunking.ts

interface Chunk {
  content: string
  index: number
}

// Divide texto en chunks por oraciones — heurística simple
// MODIFICAR: ajustá según tu caso (ej. token-aware, recursive split, etc.)
export function chunkText(text: string, maxChunkSize = 500): Chunk[] {
  const sentences = text
    .split(/(?<=[.!?])\s+/)
    .filter((s) => s.trim().length > 0)

  const chunks: Chunk[] = []
  let currentChunk = ''
  let chunkIndex = 0

  for (const sentence of sentences) {
    if ((currentChunk + sentence).length > maxChunkSize && currentChunk) {
      chunks.push({ content: currentChunk.trim(), index: chunkIndex++ })
      currentChunk = sentence
    } else {
      currentChunk += (currentChunk ? ' ' : '') + sentence
    }
  }

  if (currentChunk.trim()) {
    chunks.push({ content: currentChunk.trim(), index: chunkIndex })
  }

  return chunks
}
```

> Para chunking más sofisticado (token-aware, semántico), considerar `langchain/text_splitter` o equivalente. Validar con `find-docs` cuando incorpores.

---

## 4. Servicio RAG

```typescript
// lib/ai/rag.ts

import { createClient } from '@/lib/supabase/server'
import { generateEmbedding, generateEmbeddings } from './embeddings'
import { chunkText } from './chunking'

// Agregar documento a la base de conocimiento
export async function addDocument(content: string, metadata?: Record<string, unknown>) {
  const supabase = await createClient()

  // Capturamos user_id para RLS — server-side
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('No autenticado')

  // 1. Guardar recurso original
  const { data: resource, error: resourceError } = await supabase
    .from('resources')
    .insert({ content, metadata, user_id: user.id })
    .select('id')
    .single()
  if (resourceError) throw resourceError

  // 2. Chunks
  const chunks = chunkText(content)

  // 3. Embeddings
  const embeddings = await generateEmbeddings(chunks.map((c) => c.content))

  // 4. Guardar embeddings
  const embeddingRows = chunks.map((chunk, i) => ({
    resource_id: resource.id,
    content: chunk.content,
    embedding: embeddings[i],
  }))

  const { error: embeddingError } = await supabase
    .from('embeddings')
    .insert(embeddingRows)
  if (embeddingError) throw embeddingError

  return resource.id
}

// Buscar contenido relevante (respeta RLS via match_embeddings security invoker)
export async function findRelevantContent(
  query: string,
  threshold = 0.5,
  limit = 5
): Promise<{ content: string; similarity: number }[]> {
  const supabase = await createClient()

  const queryEmbedding = await generateEmbedding(query)

  const { data, error } = await supabase.rpc('match_embeddings', {
    query_embedding: queryEmbedding,
    match_threshold: threshold,
    match_count: limit,
  })
  if (error) throw error

  return data || []
}
```

> Para InsForge, el cliente cambia (`createClient` viene de `@insforge/sdk`) pero el shape de las llamadas (`.from(...).insert/.select`, `.rpc(...)`) es equivalente. Para el `auth.getUser()` puede haber un helper distinto del SDK — validar con `find-docs`.

---

## 5. Tool para el agente [docs:vercel-ai-sdk@v5]

```typescript
// lib/ai/tools/knowledge.ts

import { z } from 'zod'
import { tool } from 'ai'
import { findRelevantContent, addDocument } from '../rag'

export const knowledgeTools = {
  getInformation: tool({
    description: 'Busca información relevante en la base de conocimiento del usuario',
    inputSchema: z.object({
      query: z.string().describe('La pregunta o tema a buscar'),
    }),
    execute: async ({ query }) => {
      const results = await findRelevantContent(query)
      if (results.length === 0) {
        return 'No encontré información relevante sobre eso.'
      }
      return results.map((r) => r.content).join('\n\n---\n\n')
    },
  }),

  // Tool destructiva-ish — agrega contenido al index. SIN execute
  // → el-guardian recomienda confirmación manual antes de aplicar.
  addKnowledge: tool({
    description: 'Agrega información a la base de conocimiento — REQUIERE CONFIRMACIÓN',
    inputSchema: z.object({
      content: z.string().describe('El contenido a agregar'),
      source: z.string().optional().describe('Fuente de la información'),
    }),
    // Sin execute → confirmación humana antes de indexar
  }),
}
```

> Nota: usamos shape v5 (`tool({ inputSchema, execute })`), no v4 (`{ parameters, execute }`).

---

## 6. Integrar con chat [docs:vercel-ai-sdk@v5]

```typescript
// app/api/chat/route.ts

import { openrouter, MODELS } from '@/lib/ai/openrouter'
import { streamText, convertToModelMessages, stepCountIs, type UIMessage } from 'ai'
import { knowledgeTools } from '@/lib/ai/tools/knowledge'

const SYSTEM_PROMPT = `Sos un asistente con acceso a una base de conocimiento del usuario.

Cuando el usuario pregunte sobre algo, USÁ getInformation para buscar.
Basá tus respuestas en la información encontrada y citá la fuente.
Si no encontrás nada relevante, decilo honestamente — NO inventes datos.`

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json()

  const result = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages: await convertToModelMessages(messages),
    tools: knowledgeTools,
    stopWhen: stepCountIs(3), // máx 3 iteraciones (RAG suele resolver en 1-2)
  })

  return result.toUIMessageStreamResponse()
}
```

---

## 7. Script para indexar (CLI)

```typescript
// scripts/index-docs.ts
// Ejecutar: npx tsx scripts/index-docs.ts ./docs

import { addDocument } from '@/lib/ai/rag'
import fs from 'fs'
import path from 'path'

async function indexDocuments(docsDir: string) {
  const files = fs.readdirSync(docsDir)

  for (const file of files) {
    if (!file.endsWith('.md') && !file.endsWith('.txt')) continue

    const content = fs.readFileSync(path.join(docsDir, file), 'utf-8')
    console.log(`Indexando: ${file}`)
    await addDocument(content, { source: file })
    console.log(`  ✓ Indexado`)
  }

  console.log('Indexación completa.')
}

indexDocuments(process.argv[2] || './docs')
```

> Este script corre offline con un service-role-key (NO commitear). Para uso en runtime se recurre a `addDocument` con el cliente del usuario autenticado.

---

## Optimizaciones

### Hybrid search (semántico + keyword)

```sql
-- Aplicar via `el-migrador`
alter table embeddings
add column fts tsvector
generated always as (to_tsvector('spanish', content)) stored;

create index on embeddings using gin(fts);

create or replace function hybrid_search(
  query_text text,
  query_embedding vector(1536),
  match_count int default 5
)
returns table (id uuid, content text, score float)
language sql stable
security invoker
as $$
  select
    e.id,
    e.content,
    (
      0.6 * (1 - (e.embedding <=> query_embedding))
      + 0.4 * ts_rank(e.fts, websearch_to_tsquery('spanish', query_text))
    ) as score
  from embeddings e
  where e.fts @@ websearch_to_tsquery('spanish', query_text)
     or 1 - (e.embedding <=> query_embedding) > 0.3
  order by score desc
  limit match_count;
$$;
```

### Cache de embeddings

```typescript
// Embeddings del mismo texto son determinísticos → cachear vale la pena.

import { unstable_cache } from 'next/cache'

export const getCachedEmbedding = unstable_cache(
  async (text: string) => generateEmbedding(text),
  ['embedding'],
  { revalidate: 3600 * 24 } // 24 horas
)
```

> Si tu app maneja PII, considerá si el cache key (text input) puede leakear data sensible — el-guardian audita.

---

## Checklist

- [ ] `find-docs` invocado para `embed`/`embedMany` v5 + pgvector + auth helper del BaaS elegido
- [ ] Migration aplicada via `el-migrador` (rollback existe)
- [ ] Extensión pgvector habilitada
- [ ] Tablas `resources` y `embeddings` con RLS
- [ ] Función `match_embeddings` con `security invoker` (respeta RLS)
- [ ] Servicio RAG implementado (`addDocument`, `findRelevantContent`)
- [ ] Tool `getInformation` integrada al agente con `inputSchema` v5
- [ ] Tool `addKnowledge` SIN `execute` (requires confirmación)
- [ ] Script de indexación documentado
- [ ] (Opcional) Hybrid search aplicado
- [ ] (Opcional) Cache de embeddings configurado
- [ ] Anti-Slop Gate post-aplicación si modificaste UI

---

## Siguiente paso

Con RAG configurado, tu agente puede:
- Responder preguntas sobre documentos del usuario
- Citar fuentes
- Aprender nuevo conocimiento dinámicamente (con confirmación manual)

---

*"Un agente sin conocimiento solo puede adivinar. Con RAG, puede informar."*

## Sources
- [docs:vercel-ai-sdk@v5] — `embed`, `embedMany`, `tool`, `inputSchema`, `streamText`, `stopWhen`
- [docs:supabase] — pgvector, HNSW, `security invoker`, RLS policies
- [docs:insforge] — pgvector + auth helper equivalente
- [memory:references#R-007] — Context7 (find-docs)
- [memory:skills#el-migrador] — migration application (D10)
- [memory:skills#el-guardian] — review service-role-key handling (D3)
- [memory:decisions#D-011] — BaaS decision tree
- [memory:lessons#L-001] — RLS por user_id default (rationale del user_id + RLS policies + security invoker en este template)
