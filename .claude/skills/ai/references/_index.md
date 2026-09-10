# AI Templates — Catalog

> **"El 20% de componentes que produce el 80% de los resultados"**

Templates copy-paste para IA con **Vercel AI SDK v5 + OpenRouter**. Portado desde saas-factory upstream con 5 adaptaciones Forja-específicas (citation grammar, find-docs invocation, BaaS abstraction, el-guardian handoff donde aplica, Brand DNA reference donde genera UI).

## Antes de empezar (R13)

Antes de aplicar cualquier template, invocá [`find-docs`](../../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs(...)` para confirmar la sintaxis actual. La API v5 difiere de v4 en el shape de `tools` (objeto con `inputSchema + execute` vs array con `parameters + execute`) y en el output de `streamText`. Citar `[docs:vercel-ai-sdk@v5]` cuando incorpores info al código generado.

---

## Estructura

```
references/
├── _index.md              # Este archivo
│
├── agents/                # Flujo secuencial para agentes
│   ├── 00-setup-base.md
│   ├── 01-chat-streaming.md
│   ├── 01-alt-action-stream.md
│   ├── 02-web-search.md
│   ├── 03-historial-baas.md          ← BaaS-aware (Supabase + InsForge)
│   ├── 04-vision-analysis.md
│   ├── 05-tools-funciones.md
│   └── 06-rag-basico.md
│
└── [standalone]           # Capacidades independientes
    ├── single-call.md
    ├── structured-outputs.md
    └── generative-ui.md   ← Brand DNA-aware
```

---

## Dos tipos de templates

### 1. Agentes (secuenciales)

Bloques que se construyen progresivamente.

| # | Bloque | Prerequisitos | el-guardian handoff |
|---|--------|---------------|---------------------|
| 00 | **Setup Base** | Ninguno | — |
| 01 | **Chat Streaming** | 00 | — |
| 01-ALT | **Action Stream** | 00 (alternativa a 01, con UI components) | — |
| 02 | **Web Search** | 01 | ✅ (API keys de search providers) |
| 03 | **Historial** (BaaS) | 01 + decisión `baas` aplicada | ✅ (RLS, service role keys) |
| 04 | **Vision** | 01 | ✅ (file uploads + MIME validation) |
| 05 | **Tools** | 01 | ✅ (function execution boundary) |
| 06 | **RAG Básico** | 03 (BaaS con pgvector / vector store) | — |

**Dos caminos:**

```
Camino A (Chat):    00 → 01 → 02 → 03 → 04 → 05 → 06
Camino B (Action):  00 → 01-ALT → 02 → 03 → 04 → 06
```

### 2. Standalone (independientes)

| Template | Descripción | el-guardian handoff |
|----------|-------------|---------------------|
| **single-call.md** | Llamada simple a LLM | — |
| **structured-outputs.md** | JSON tipado con Zod | — |
| **generative-ui.md** | Componentes dinámicos generados por LLM | — |

---

## Cuándo usar cada uno

### Usa agentes cuando
- Necesitás conversación continua
- El usuario interactúa múltiples veces
- Requerís memoria/historial
- El LLM debe usar herramientas

### Usa standalone cuando
- Es una acción puntual (botón "Resumir")
- No hay interacción de chat
- Solo necesitás una respuesta
- Querés JSON estructurado

---

## Cómo referenciar

### Agentes
```
.claude/skills/ai/references/agents/00-setup-base.md
```

### Standalone
```
.claude/skills/ai/references/single-call.md
```

### Combinación
```
Necesito: Setup + Chat + RAG
```

---

## Stack compartido

Todos los templates usan:

```env
# .env.local
OPENROUTER_API_KEY=sk-or-v1-...

# BaaS (decidido por skill `baas`, no asumido aquí)
# Supabase:
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
# o InsForge:
# NEXT_PUBLIC_INSFORGE_URL=https://xxx.insforge.dev
# NEXT_PUBLIC_INSFORGE_ANON_KEY=...
```

```bash
# Dependencies (Vercel AI SDK v5) [docs:vercel-ai-sdk@v5]
npm install ai@^5 @ai-sdk/react@^2 @openrouter/ai-sdk-provider@^1 zod@^3

# BaaS client (uno u otro según `baas` decision):
npm install @supabase/supabase-js @supabase/ssr
# o:
# npm install @insforge/sdk
```

---

## Adaptaciones Forja-específicas (vs saas-factory upstream)

| # | Adaptación | Donde aplica |
|---|-----------|--------------|
| 1 | Citation grammar `[docs:vercel-ai-sdk@v5]` (R13) | Cualquier mención de API/sintaxis del SDK |
| 2 | Sección "Antes de empezar" con `find-docs` invocation | Header de cada template |
| 3 | BaaS abstraction (D11) | `03-historial-baas.md` con sub-secciones Supabase + InsForge |
| 4 | `el-guardian` handoff | Templates que tocan secrets/auth/RLS/uploads/function execution (02, 03, 04, 05) |
| 5 | Brand DNA reference (R10) | Templates que generan UI (`01-alt-action-stream.md`, `generative-ui.md`) |

---

## Combinaciones recomendadas

### Chatbot básico
```
agents/00 + agents/01 + agents/02
```

### Asistente con memoria
```
agents/00 + agents/01 + agents/02 + agents/03 (BaaS)
```

### Agente con conocimiento (RAG)
```
agents/00 + agents/01 + agents/03 + agents/06
```

### Botón de IA simple
```
single-call.md (sin agente)
```

### Extracción de datos
```
structured-outputs.md (sin agente)
```

---

## Principios

1. **Agentes = conversación**, standalone = acción puntual
2. **Copy-paste ready**: buscá `// MODIFICAR:` en cada template
3. **TypeScript + Zod**: tipos seguros siempre
4. **UI headless**: tu decidís el diseño (excepto cuando aplica Brand DNA — R10)
5. **find-docs antes de generar** (R13): cualquier sintaxis no estándar contra libs externas pasa por Context7

---

*"No todo necesita ser un agente. A veces un botón es suficiente."*

## Sources
- [docs:vercel-ai-sdk@v5] — API canónica para todos los templates
- [memory:references#R-007] — Context7 (find-docs source)
- [memory:decisions#D-009] — Brand DNA contract
- [memory:decisions#D-011] — BaaS decision tree
