# Route: 🤖 Feature con IA

> *"Integrá inteligencia real en tu producto. No decoración — valor medible."*

## Metadata

- **Modo:** 🤖 Feature con IA
- **Descripción:** diseña y construye un módulo AI dentro de una app existente o como núcleo de una nueva.
- **Tiempo estimado:** 2h 20m – 4h 20m
- **Steps activos:** 7 (incluye Viability Check)
- **Cuándo usar:** cuando el valor central del producto viene de un modelo de lenguaje/visión/audio, o cuando querés agregar una feature con IA a una app existente.

**Catálogo técnico:** este route delega a `.claude/skills/ai/references/` (12 templates copy-paste-ready) cuando llega Step 5/6. Ver `.claude/skills/ai/references/_index.md` y `.claude/skills/ai/SKILL.md`.

---

## Pipeline

```
VIABILITY → Definición → AI Design → User Stories IA → Prompt Engineering → UI del Feature → Cost & Ops
  Step 0      Step 1       Step 2         Step 3            Step 4             Step 5          Step 6
  20 min      15 min       25 min         20 min            20 min             30 min          15 min
```

**No usa:** BMC completo (#1), Tech Spec general (#3), UX Research (#4), UX Design completo (#6), UI Workflow (#7), Security Audit (#9), Blueprint (#10).

---

### Step 0 · Viability Check (Go/No-Go Gate)

- **Asset:** `assets/00-viability-check.md`
- **Output:** `VIABILITY-[nombre].md`
- **Tiempo:** ~20 min
- **Qué hace:** evalúa viabilidad técnica del feature IA (¿APIs disponibles? ¿Costo asumible? ¿El Forja Golden Path lo soporta?) y viabilidad de negocio (¿agrega valor real o es "IA decorativa"?).
- **Inputs requeridos:** solo la idea del usuario.
- **Gate:** si NO-GO → detener. Si GO → continuar.

---

### Step 1 · Definición del Feature IA

- **Asset:** ninguno — entrevista directa.
- **Output:** `.claude/PRPs/AI-FEATURE-BRIEF-[nombre].md`
- **Tiempo:** ~15 min
- **Qué hace:** define con precisión qué hace el feature de IA, qué inputs recibe, qué outputs produce y — **crítico** — qué subtipo de feature es para cargar el template correcto desde `.claude/skills/ai/references/`.

#### 1.1 Clasificar el Subtipo de Feature IA

```
¿Qué tipo de feature IA querés construir?

A. 💬 Chat Conversacional
   → El usuario escribe mensajes y el modelo responde en tiempo real
   → Ejemplos: asistente, chatbot, copilot de escritura
   → Template: agents/00-setup-base.md + agents/01-chat-streaming.md

B. 🔍 RAG / Búsqueda en Documentos Propios
   → El modelo responde basándose en documentos o KB del sistema
   → Ejemplos: FAQ de empresa, asistente sobre documentación técnica
   → Template: agents/00 + agents/01 + agents/03 (historial) + agents/06 (rag-basico)

C. 📄 Chat con Documentos del Usuario
   → El usuario SUBE sus propios archivos y conversa con ellos
   → Ejemplos: "Chat with PDF", análisis de contratos
   → Template: agents/00 + 03 + 06 + storage layer custom (chat-with-docs deferred F-tighten)

D. 🧠 IA con Memoria Persistente
   → El asistente recuerda al usuario entre sesiones
   → Ejemplos: coach personalizado, asistente que aprende preferencias
   → Template: agents/00 + 01 + 03-historial-supabase + memory layer (memory-pattern deferred F-tighten)

E. ⚙️ Generación Estructurada (sin chat)
   → El modelo produce datos estructurados a partir de un input
   → Ejemplos: extracción de datos, clasificación, generación de reportes
   → Template: structured-outputs.md (generateObject + Zod, sin streaming UI)

F. 🎛️ Tool Calling / Agentic
   → El modelo invoca tools/funciones para hacer cosas
   → Template: agents/05-tools-funciones.md (R14 strict — destructivas sin execute() automático)

Escribí la letra (A-F) o describí tu feature y lo clasifico.
```

**Según el subtipo elegido, el Step 2 cargará el template correcto:**

| Subtipo | Template a cargar en Step 2 |
|---------|----------------------------|
| A — Chat Conversacional | `.claude/skills/ai/references/agents/00-setup-base.md` + `01-chat-streaming.md` |
| B — RAG / KB del sistema | `agents/00 + 01 + 03 + 06-rag-basico.md` |
| C — Chat con Docs del Usuario | `agents/00 + 03 + 06` + storage layer (chat-with-docs deferred) |
| D — IA con Memoria | `agents/00 + 01 + 03-historial-supabase.md` (memory-pattern deferred) |
| E — Generación Estructurada | `structured-outputs.md` |
| F — Tool Calling / Agentic | `agents/05-tools-funciones.md` (R14 enforced) |

#### 1.2 Preguntas de Definición del Feature

- *"¿Qué tarea hace el usuario ahora manualmente que la IA va a hacer/acelerar?"*
- *"¿Qué INPUT recibe la IA? (texto libre, archivo subido, datos estructurados, imágenes)"*
- *"¿Qué OUTPUT espera el usuario? (texto generado, clasificación, análisis, recomendación, datos estructurados)"*
- *"¿Va dentro de una app existente o es el producto en sí?"*
- *"¿Hay latencia aceptable o necesita ser en tiempo real (streaming)?"*
- *"¿Cuántas llamadas al día estimás? ¿Tenés presupuesto de API en mente?"*
- *"¿Qué pasa si el modelo falla o alucina? ¿Hay un fallback?"*
- **R14:** *"¿La IA va a invocar tools que ejecuten acciones destructivas (delete, send, transfer, cancel)?"* — si sí, sin `execute()` automático, requiere typed confirmation humana.

---

### Step 2 · AI Feature Design

- **Asset:** `assets/ai-feature-design.md` (+ template específico de `.claude/skills/ai/references/` según subtipo).
- **Output:** sección de diseño en `AI-FEATURE-BRIEF-[nombre].md` (modelo, proveedor, patrón, API contract, fallbacks).
- **Tiempo:** ~25 min
- **Qué hace:** define la arquitectura del feature — selección de modelo, patrón de integración (streaming / structured output / tool calling / RAG), contrato de API y cadena de fallbacks.
- **Inputs requeridos:** `AI-FEATURE-BRIEF-[nombre].md` del Step 1 + subtipo clasificado.
- **Adaptación por subtipo:**
  - **A (Chat):** streamText + useChat; definir si incluirá memoria persistente.
  - **B (RAG/KB):** documentar estructura de knowledge base + pgvector schema [docs:supabase].
  - **C (Chat con Docs):** agregar storage layer + extracción de texto antes del RAG.
  - **D (Memoria):** elegir entre los 3 tipos de memoria (historial puro, preferencias estructuradas, memoria semántica).
  - **E (Estructurado):** `generateObject` + Zod; sin streaming.
  - **F (Tools):** definir cada tool con su Zod schema + R14 marcar destructivas.
- **Siempre:**
  - Usar OpenRouter como proveedor (evita lock-in, un solo API key) [docs:vercel-ai-sdk@v5].
  - Definir el fallback chain: modelo principal → modelo económico → respuesta estática.
  - Documentar el endpoint y el request/response schema antes de escribir código.

---

### Step 3 · User Stories IA

- **Asset:** `assets/05-user-stories.md`
- **Output:** `USER-STORIES-AI-[nombre].md`
- **Tiempo:** ~20 min
- **Qué hace:** stories específicas para el feature de IA.
- **Inputs requeridos:** `AI-FEATURE-BRIEF-[nombre].md`.
- **Adaptación para AI Feature:**
  - Incluir stories del happy path Y del unhappy path (modelo lento, respuesta vacía, error, alucinación).
  - Stories de feedback: *"Como usuario, sé si la IA está procesando mi request"*.
  - Stories de confianza: *"Como usuario, puedo ver la fuente de la recomendación"*.
  - Stories de control: *"Como usuario, puedo regenerar una respuesta que no me convenció"*.
  - Stories R14 si tools destructivas: *"Como usuario, confirmo explícitamente antes de que la IA borre/envíe/transfiera X"*.

---

### Step 4 · Prompt Engineering

- **Asset:** `assets/prompt-engineering.md` (deferred F-tighten — referenciar `.claude/skills/ai/references/agents/00-setup-base.md` como base).
- **Output:** `PROMPTS-[nombre].md` con system prompts versionados, few-shots y golden tests.
- **Tiempo:** ~20 min
- **Qué hace:** diseña los prompts de producción — anatomía del system prompt, patrones por tipo de feature, structured outputs con Zod, versionado semver y suite de golden tests pre-deploy.
- **Inputs requeridos:** `AI-FEATURE-BRIEF-[nombre].md` + decisiones del Step 2.
- **Adaptación para AI Feature:**
  - System prompt sigue 5 secciones: rol, tarea, reglas, formato, fallback.
  - Usar `generateObject` + Zod schema cuando el output es estructurado — nunca parsear JSON manualmente.
  - Prompts versionados en `src/features/[nombre]/prompts.ts` como constantes.
  - Correr los 5 golden tests antes de ir a producción: happy path, input vacío, ambiguo, **prompt injection** (L-002 indirect), otro idioma.

---

### Step 5 · UI del Feature IA (Brand DNA gate, R10)

- **Asset:** `assets/front-end-design.md` → luego `assets/08-ui.md`.
- **R10 gate:** `add-ui-kit` invocado si Brand DNA ausente. La UI del feature IA consume tokens + voice del proyecto target — no genérica.
- **Output:** componentes del feature en `src/features/[nombre-ai]/`.
- **Tiempo:** ~30 min
- **Qué hace:** UI para el feature de IA — patrones específicos de AI UX consumiendo Brand DNA.
- **Inputs requeridos:** `USER-STORIES-AI-[nombre].md` + `AI-FEATURE-BRIEF-[nombre].md`.
- **Adaptación para AI Feature:**
  - **Streaming UI:** usar `useChat` o `useCompletion` de Vercel AI SDK para mostrar texto en tiempo real.
  - **Loading states:** skeleton loaders mientras el modelo procesa — nunca spinner vacío.
  - **Error states:** mensajes claros cuando el modelo falla — con opción de reintentar.
  - **Confianza:** mostrar fuente de la respuesta si es RAG (citas inline `[doc:nombre]`).
  - **Control:** botones de regenerar, copiar, thumbs up/down para feedback.
  - **R14 confirmation UI:** si tools destructivas, modal de typed confirmation antes de ejecutar.

---

### Step 6 · Cost & Operations

- **Asset:** `assets/llm-cost-optimization.md` (deferred F-tighten).
- **Output:** sección de costos y ops en `AI-FEATURE-BRIEF-[nombre].md` + rate limiting implementado.
- **Tiempo:** ~15 min
- **Qué hace:** estima costo mensual, implementa rate limiting con Upstash Redis, configura observabilidad con Sentry, define estrategias de reducción (caching, model routing, batching).
- **Inputs requeridos:** modelo elegido (Step 2) + volumen estimado.
- **Adaptación para AI Feature:**
  - Calcular escenario conservador y crecimiento antes de ir a producción.
  - Rate limiting: 20 req/min para chat, 5 req/min para features costosos [docs:upstash-redis].
  - Loggear `inputTokens`, `outputTokens`, `latencyMs`, `estimatedCostUsd` por request.
  - Definir umbral de costo que dispara revisión arquitectural (ej: >$200/mes → evaluar model swap).

---

## Outputs Finales

| Entregable | Generado en |
|-----------|-------------|
| `AI-FEATURE-BRIEF-[nombre].md` | Steps 1–2 |
| `USER-STORIES-AI-[nombre].md` | Step 3 |
| `PROMPTS-[nombre].md` | Step 4 |
| `src/features/[nombre-ai]/` | Step 5 |
| Rate limiting + monitoring implementado | Step 6 |

---

## Arquitectura del Feature (Patrón Base)

```
src/
└── features/
    └── [nombre-ai]/
        ├── components/
        │   ├── AIInput.tsx        ← input del usuario
        │   ├── AIOutput.tsx       ← respuesta con streaming
        │   └── AIFeedback.tsx     ← thumbs up/down + regenerar
        ├── hooks/
        │   └── useAIFeature.ts    ← lógica con Vercel AI SDK
        └── api/
            └── route.ts           ← server-side: llama al modelo
```

**Integración con Vercel AI SDK v5** (template canónico desde `.claude/skills/ai/references/agents/00-setup-base.md`):

```typescript
// src/features/[nombre-ai]/api/route.ts
import { streamText } from 'ai'
import { createOpenRouter } from '@openrouter/ai-sdk-provider'

export async function POST(req: Request) {
  const { messages } = await req.json()
  const openrouter = createOpenRouter({ apiKey: process.env.OPENROUTER_API_KEY })

  const result = streamText({
    model: openrouter('anthropic/claude-3-5-sonnet'),
    system: SYSTEM_PROMPT, // desde PROMPTS-[nombre].md
    messages,
  })

  return result.toDataStreamResponse()
}
```

[docs:vercel-ai-sdk@v5] — `streamText` retorna `toDataStreamResponse()` (NO `toTextStreamResponse()`).

---

## Qué se Omite y Por Qué

| Elemento omitido | Razón |
|-----------------|-------|
| BMC completo (#1) | El feature IA va dentro de un product ya definido (o se define en el brief) |
| UX Research (#4) | Los usuarios del feature son los mismos de la app existente |
| UX Design completo (#6) | El feature tiene patrones de AI UX específicos — no IA general de la app |
| Security Audit (#9) | Se hace a nivel de app completa; AI-específicos (prompt injection L-002, R14 destructivas) están en el brief |
| Blueprint (#10) | El feature es scope acotado — el plan de construcción está en el brief |

Para auditoría adversarial específica de IA → handoff a `el-guardian` post-implementation (Codex audita prompt injection vectors).

---

*"La IA en un producto no es una feature — es un nuevo tipo de interfaz entre el usuario y sus datos."*
