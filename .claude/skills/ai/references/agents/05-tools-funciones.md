# Bloque 05 — Tools y funciones (AI SDK v5)

> Agregar herramientas que el modelo puede ejecutar.

**Tiempo:** 20 minutos
**Prerequisitos:** Bloque 01 (Chat Streaming)

---

## Antes de empezar (R13)

Antes de generar código, invocá [`find-docs`](../../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs('tool inputSchema execute stopWhen prepareStep v5')` para confirmar el shape v5 de tools (`inputSchema` reemplazó a `parameters`; `stopWhen` reemplazó a `maxSteps`). Citar `[docs:vercel-ai-sdk@v5]` en el output.

---

## Handoff a `el-guardian` (D3) — OBLIGATORIO

Este template **expone funciones que el LLM ejecuta con args controlados (parcialmente) por el usuario**. Surface alta:

| Riesgo | Qué chequea `el-guardian` |
|--------|---------------------------|
| Function abuse | tool args llegan vía LLM influenced por user input → indirect prompt injection puede llamar tools que no debería |
| SQL injection (si tool consulta DB) | que el cliente Supabase/InsForge se use con bind params, NO concatenar `query.from(filter)` |
| Mass assignment | tools que aceptan `data: z.record(z.any())` permiten setear campos arbitrarios; whitelist de campos editables |
| Tools destructivas sin confirmación | tools tipo `deleteItem`, `sendEmail` (no reversible) deben tener confirmación humana ("Sin execute = requiere confirmación manual") |
| Rate limit per tool | tool `sendEmail` puede ser usada para spam si no rate-limit por user |
| RLS bypass | tools que usan service role NO deben exponerse al LLM (solo helpers que respeten RLS) |
| Logging de tool args | args pueden contener PII; redact antes de loggear |

PASS criterio: 0 critical, 0 high. Sin signoff de `el-guardian` → no merge.

---

## Brand DNA gate (R10)

`<ChatWithTools>` renderiza UI. Brand contract obligatorio. Tokens del brand reemplazan colores hardcoded.

---

## Qué obtenés

- Tools definidas con Zod schemas (sintaxis v5)
- Ejecución automática o manual (confirmación)
- Resultados visibles en el chat
- Loop agéntico con `stopWhen`
- Control dinámico con `prepareStep`

---

## Cambios v4 → v5 (críticos) [docs:vercel-ai-sdk@v5]

| v4 (antes) | v5 (ahora) |
|------------|------------|
| `parameters: z.object({...})` | `inputSchema: z.object({...})` |
| `maxSteps: 5` | `stopWhen: stepCountIs(5)` |
| N/A | `outputSchema: z.object({...})` (opcional, type safety) |
| N/A | `prepareStep` (control dinámico por paso) |
| `tools: [{ name, ... }]` (array) | `tools: { name: tool({...}) }` (objeto) |

> Si `find-docs` devuelve shape distinto al de arriba, halt y revalidar antes de generar.

---

## 1. Definir tools con Zod (v5)

```typescript
// features/chat/tools/index.ts

import { z } from 'zod'
import { tool } from 'ai'

// Tool: clima
export const getWeather = tool({
  description: 'Obtiene el clima actual de una ciudad',
  inputSchema: z.object({
    city: z.string().describe('Nombre de la ciudad'),
  }),
  outputSchema: z.object({
    city: z.string(),
    temperature: z.number(),
    condition: z.enum(['soleado', 'nublado', 'lluvioso']),
  }),
  execute: async ({ city }) => {
    // En prod, llamar a una API de clima real
    return {
      city,
      temperature: Math.floor(Math.random() * 30) + 10,
      condition: ['soleado', 'nublado', 'lluvioso'][Math.floor(Math.random() * 3)] as 'soleado' | 'nublado' | 'lluvioso',
    }
  },
})

// Tool: calcular
export const calculate = tool({
  description: 'Realiza cálculos matemáticos',
  inputSchema: z.object({
    operation: z.enum(['sum', 'subtract', 'multiply', 'divide']),
    a: z.number(),
    b: z.number(),
  }),
  execute: async ({ operation, a, b }) => {
    const ops = {
      sum: a + b,
      subtract: a - b,
      multiply: a * b,
      divide: b !== 0 ? a / b : 'Error: división por cero',
    }
    return { operation, a, b, result: ops[operation] }
  },
})

// Tool: buscar productos (whitelist explícita de filtros)
export const searchProducts = tool({
  description: 'Busca productos en el catálogo',
  inputSchema: z.object({
    query: z.string().describe('Término de búsqueda'),
    category: z.enum(['shirts', 'pants', 'shoes']).optional().describe('Categoría'),
    maxPrice: z.number().min(0).max(100000).optional().describe('Precio máximo'),
  }),
  execute: async ({ query, category, maxPrice }) => {
    // Whitelist enforced por el schema; sin pass-through arbitrario
    return {
      query,
      results: [
        { id: 1, name: `Producto ${query} 1`, price: 100 },
        { id: 2, name: `Producto ${query} 2`, price: 200 },
      ],
      total: 2,
    }
  },
})

export const tools = {
  getWeather,
  calculate,
  searchProducts,
}
```

---

## 2. API route con tools (v5)

```typescript
// app/api/chat/route.ts

import { openrouter, MODELS } from '@/lib/ai/openrouter'
import { streamText, convertToModelMessages, stepCountIs, type UIMessage } from 'ai'
import { tools } from '@/features/chat/tools'

const SYSTEM_PROMPT = `Sos un asistente con acceso a herramientas.

Herramientas disponibles:
- getWeather: consultar el clima de una ciudad
- calculate: realizar cálculos matemáticos
- searchProducts: buscar productos en el catálogo

Usá las herramientas cuando sea apropiado. NO uses tools para responder
preguntas que podés contestar con conocimiento general.

IMPORTANTE: si el usuario pide una tool destructiva (eliminar, enviar
email, transferir dinero), pedí confirmación textual antes de ejecutar.`

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json()

  const modelMessages = await convertToModelMessages(messages)

  const result = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages: modelMessages,
    tools,
    stopWhen: stepCountIs(5), // máx. 5 iteraciones del loop
  })

  return result.toUIMessageStreamResponse()
}
```

---

## 3. Control avanzado con `prepareStep`

```typescript
// app/api/chat/route.ts

import { streamText, stepCountIs } from 'ai'

export async function POST(req: Request) {
  const { messages } = await req.json()

  const result = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages,
    tools,
    stopWhen: stepCountIs(5),

    prepareStep: async ({ stepNumber, previousSteps }) => {
      // Cambiar a modelo más potente después de step 2
      if (stepNumber > 2) {
        return { model: openrouter(MODELS.powerful) }
      }

      // Limitar tools después de step 3 (defensa: evitar loops abusivos)
      if (stepNumber > 3) {
        return { tools: { calculate } }
      }

      // Comprimir mensajes si hay muchos
      if (previousSteps.length > 10) {
        return { messages: compressMessages(previousSteps) }
      }

      return {}
    },
  })

  return result.toUIMessageStreamResponse()
}
```

---

## 4. Mostrar tool calls en UI (con tokens del brand)

```typescript
// features/chat/components/ChatWithTools.tsx

'use client'

import { useState, FormEvent } from 'react'
import { useChat } from '@ai-sdk/react'

export function ChatWithTools() {
  const { messages, status, sendMessage } = useChat()
  const [input, setInput] = useState('')

  const isLoading = status === 'submitted' || status === 'streaming'

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!input.trim() || isLoading) return
    const text = input.trim()
    setInput('')
    sendMessage({ text })
  }

  return (
    <div className="flex flex-col h-full bg-background text-foreground">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((m) => (
          <div key={m.id} className="space-y-2">
            <div className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div
                className={`max-w-[80%] p-3 rounded-lg ${
                  m.role === 'user'
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted text-foreground'
                }`}
              >
                {m.parts?.map((part, i) => {
                  if (part.type === 'text') return <p key={i}>{part.text}</p>

                  if (part.type === 'tool-invocation') {
                    return (
                      <div
                        key={i}
                        className="my-2 p-2 bg-accent/10 rounded border border-accent/20"
                      >
                        <div className="flex items-center gap-2 text-accent-foreground text-sm">
                          <span>🔧</span>
                          <span className="font-medium">{part.toolInvocation.toolName}</span>
                          {part.toolInvocation.state === 'calling' && (
                            <span className="animate-pulse text-muted-foreground">
                              ejecutando…
                            </span>
                          )}
                        </div>
                        <pre className="mt-1 text-xs text-muted-foreground overflow-x-auto">
                          {JSON.stringify(part.toolInvocation.args, null, 2)}
                        </pre>
                        {part.toolInvocation.state === 'result' && (
                          <div className="mt-2 p-2 bg-success/10 rounded">
                            <span className="text-success text-sm">Resultado:</span>
                            <pre className="mt-1 text-xs text-muted-foreground overflow-x-auto">
                              {JSON.stringify(part.toolInvocation.result, null, 2)}
                            </pre>
                          </div>
                        )}
                      </div>
                    )
                  }

                  return null
                })}
              </div>
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-muted p-3 rounded-lg animate-pulse text-muted-foreground">
              Pensando…
            </div>
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit} className="p-4 border-t border-border">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Probá: '¿Qué clima hace en Madrid?' o 'Calculá 25 × 4'"
            disabled={isLoading}
            className="flex-1 px-4 py-2 border border-input bg-background rounded-lg focus:outline-none focus:ring-2 focus:ring-ring"
          />
          <button
            type="submit"
            disabled={isLoading || !input.trim()}
            className="px-4 py-2 bg-primary text-primary-foreground rounded-lg disabled:opacity-50"
          >
            Enviar
          </button>
        </div>
      </form>
    </div>
  )
}
```

---

## 5. Tool con confirmación manual (DESTRUCTIVAS)

Para tools que NO son reversibles (delete, send email, transfer, etc.):

```typescript
// features/chat/tools/index.ts

export const deleteItem = tool({
  description: 'Elimina un item — REQUIERE CONFIRMACIÓN MANUAL',
  inputSchema: z.object({
    itemId: z.string(),
    itemName: z.string(),
  }),
  // SIN execute → el SDK pausa esperando confirmación humana
})
```

```typescript
// En el componente, manejar confirmación
const handleToolConfirm = async (toolCallId: string, result: any) => {
  sendMessage({
    text: '',
    toolResults: [{ toolCallId, result }],
  })
}
```

> Convención Forja: TODAS las tools tipo `delete*`, `send*`, `transfer*`, `pay*`, `cancel*` van SIN `execute`. La UI obliga al usuario a confirmar antes de continuar el loop.

---

## 6. Condiciones de parada combinadas

```typescript
import { streamText, stopWhen, hasToolCall, and, or, stepCountIs } from 'ai'

const result = streamText({
  model: openrouter(MODELS.balanced),
  messages,
  tools,

  // Parar cuando: 5 pasos O se llama a finalAnswer
  stopWhen: or(stepCountIs(5), hasToolCall('finalAnswer')),

  // O: 3 pasos Y se llamó a searchProducts
  // stopWhen: and(stepCountIs(3), hasToolCall('searchProducts')),
})
```

---

## 7. Ejemplos de tools útiles (con guardrails)

### Tool: consultar BaaS

```typescript
import { z } from 'zod'
import { tool } from 'ai'
import { createClient } from '@/lib/supabase/server'

export const queryDatabase = tool({
  description: 'Consulta datos del catálogo público',
  inputSchema: z.object({
    table: z.enum(['products', 'orders']), // whitelist; auth.users / private fuera
    filters: z.record(z.string()).optional(),
    limit: z.number().min(1).max(50).default(10),
  }),
  execute: async ({ table, filters, limit }) => {
    const supabase = await createClient()
    let query = supabase.from(table).select('*').limit(limit)

    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        // Bind param via .eq, no concat
        query = query.eq(key, value)
      })
    }

    const { data, error } = await query
    if (error) return { error: error.message }
    return { data, count: data?.length }
  },
})
```

### Tool: enviar email (con confirmación)

```typescript
export const sendEmail = tool({
  description: 'Envía un email — requiere confirmación manual',
  inputSchema: z.object({
    to: z.string().email(),
    subject: z.string().max(200),
    body: z.string().max(10000),
  }),
  // SIN execute — confirmación manual obligatoria
})
```

> Integración real con [`add-emails`](../../../add-emails/SKILL.md) (Resend + React Email) en Fase 3.

### Tool: crear registro (whitelist de campos)

```typescript
export const createProduct = tool({
  description: 'Crea un producto nuevo en el catálogo',
  inputSchema: z.object({
    name: z.string().max(120),
    description: z.string().max(1000),
    price: z.number().min(0).max(1000000),
    category: z.enum(['shirts', 'pants', 'shoes']),
    // Solo estos campos — NO admit `data: z.record(z.any())` (mass assignment)
  }),
  execute: async (input) => {
    const supabase = await createClient()
    const { data, error } = await supabase
      .from('products')
      .insert(input)
      .select()
      .single()
    if (error) return { error: error.message }
    return { created: data }
  },
})
```

---

## Checklist

- [ ] `find-docs` invocado para confirmar shape v5 (`inputSchema`, `stopWhen`, `tools` como objeto)
- [ ] Brand DNA contract presente — R10
- [ ] Tools definidas con `inputSchema` (no `parameters`)
- [ ] API route usa `stopWhen` (no `maxSteps`)
- [ ] Tools destructivas SIN `execute` (confirmación manual)
- [ ] Filtros de DB usan whitelist enums (no `z.record(z.any())`)
- [ ] System prompt instruye al LLM a pedir confirmación textual para destructivas
- [ ] UI muestra tool calls + args + resultados con tokens del brand
- [ ] (Opcional) `outputSchema` para type safety
- [ ] (Opcional) `prepareStep` para defensa por step
- [ ] **`el-guardian` audit ejecutado y PASS** — D3
- [ ] Anti-Slop Gate post-aplicación

---

## Cuándo usar tools vs regex detection

| Usá tools cuando | Usá regex detection cuando |
|------------------|----------------------------|
| El modelo debe DECIDIR qué acción tomar | La acción es predecible por keywords |
| Necesitás confirmación del usuario | Solo enriquecer contexto |
| La acción tiene side effects | Read-only (queries) |
| Múltiples opciones complejas | Patrón simple y conocido |

---

## Nota sobre Action Stream

Si preferís el patrón **Action Stream** (todas las acciones visibles), ver `01-alt-action-stream.md`. En ese patrón, las "tools" son acciones estructuradas que el usuario ve en tiempo real.

---

## Sources
- [docs:vercel-ai-sdk@v5] — `tool`, `inputSchema`, `outputSchema`, `stopWhen`, `prepareStep`, `hasToolCall`, `stepCountIs`, `tool-invocation` parts
- [docs:zod] — schema enums, max length constraints
- [docs:supabase] — `.from(...).select(...).eq(...)` bind params
- [memory:references#R-007] — Context7 (find-docs)
- [memory:skills#el-guardian] — security audit handoff (D3)
- [memory:skills#add-emails] — Resend integration (Fase 3)
- [memory:lessons#L-003] — whitelist validation, never `z.record(z.any())` (rationale para enums + bounded ranges en inputSchema)
- [memory:CONSTRAINTS.md#R14] — destructive tools require human confirmation (rationale para destructivas SIN `execute()`)
