# Bloque 01-ALT — Action Stream

> Patrón alternativo donde el usuario VE cada paso del agente. Reemplaza `01-chat-streaming.md` cuando la transparencia ES el producto.

**Tiempo:** 30 minutos
**Prerequisitos:** Bloque 00 (Setup Base)
**Reemplaza:** Bloque 01 (Chat Streaming)

---

## Antes de empezar (R13)

Antes de generar código, invocá [`find-docs`](../../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs('streamText textStream SSE response v5')` para confirmar el shape actual de `streamText` y `textStream` (la API se mantuvo estable v4→v5 pero verificar). Citar `[docs:vercel-ai-sdk@v5]` en el output.

---

## Brand DNA gate (R10)

Este template **genera UI** (`<AgentChat>`, `<ActionFeed>`, `<ActionItem>`). Pre-aplicación obligatorio:

1. `brand/brand.json` + `voice.json` deben existir, o correr `add-ui-kit` primero.
2. Los colores `bg-blue-50`, `bg-green-50`, `bg-yellow-50`, `bg-purple-50`, `bg-red-50` del upstream se reemplazan por tokens semánticos: `bg-info`, `bg-success`, `bg-warning`, `bg-accent`, `bg-destructive/10` (definidos en `brand.css` por `add-ui-kit`).
3. Anti-Slop Gate corre post-aplicación.

---

## El cambio de paradigma

### Chat tradicional (Bloque 01)
```
Usuario: "¿Cuánto me cuesta no automatizar?"
Bot:     "Estás perdiendo $4,500/mes"
Usuario: "¿De dónde sacaste ese número?"
```

### Action stream (este bloque)
```
Usuario: "¿Cuánto me cuesta no automatizar?"

💭 "Calculando tu situación actual…"
🔧 [calcularTiempo] 4 horas/día × $50/hora = $200/día
💬 "Perdés $200 diarios en tiempo"
🔧 [proyectarMes] 22 días laborales…
💬 "$4,400/mes en tiempo perdido"
🔧 [agregarErrores] +5% tasa de error…
💬 "Total: $4,500/mes"

Usuario: (no puede discutir, VIO el cálculo)
```

**La transparencia ES el producto.**

---

## Arquitectura

```
Usuario envía mensaje
    ↓
API Route recibe
    ↓
streamText() genera JSON estructurado
    ↓
closeAndParseJson() parsea mientras llega
    ↓
SSE envía acciones una por una
    ↓
useActionStream() recibe y renderiza
    ↓
Usuario VE cada paso en tiempo real
```

---

## 1. Parser de JSON parcial

```typescript
// lib/ai/closeAndParseJson.ts — NUNCA modificar (core del streaming)
//
// Parsea JSON incompleto cerrando brackets automáticamente.
// Permite procesar respuestas mientras llegan en streaming.

export function closeAndParseJson(str: string): any | null {
  const stack: string[] = []
  let i = 0

  while (i < str.length) {
    const char = str[i]
    const last = stack.at(-1)

    if (char === '"') {
      if (i > 0 && str[i - 1] === '\\') { i++; continue }
      if (last === '"') stack.pop()
      else stack.push('"')
    }

    if (last === '"') { i++; continue }

    if (char === '{' || char === '[') stack.push(char)
    if (char === '}' && last === '{') stack.pop()
    if (char === ']' && last === '[') stack.pop()

    i++
  }

  let closed = str
  for (let j = stack.length - 1; j >= 0; j--) {
    const opening = stack[j]
    if (opening === '{') closed += '}'
    if (opening === '[') closed += ']'
    if (opening === '"') closed += '"'
  }

  try { return JSON.parse(closed) } catch { return null }
}
```

---

## 2. Schemas de acciones

```typescript
// lib/ai/actionSchemas.ts — MODIFICAR: agregá tus acciones específicas

import { z } from 'zod'

// Acciones base (siempre incluir)
export const ThinkAction = z.object({
  _type: z.literal('think'),
  text: z.string(),
})

export const MessageAction = z.object({
  _type: z.literal('message'),
  text: z.string(),
})

// Acciones personalizadas
export const AskAction = z.object({
  _type: z.literal('ask'),
  question: z.string(),
  field: z.string(),
})

export const CalculateAction = z.object({
  _type: z.literal('calculate'),
  description: z.string(),
  formula: z.string(),
  result: z.number(),
  unit: z.string().optional(),
})

export const ToolAction = z.object({
  _type: z.literal('tool'),
  name: z.string(),
  args: z.record(z.any()),
  result: z.any().optional(),
})

// Union discriminada
export const ActionSchema = z.discriminatedUnion('_type', [
  ThinkAction,
  MessageAction,
  AskAction,
  CalculateAction,
  ToolAction,
])

export type Action = z.infer<typeof ActionSchema>

export const ResponseSchema = z.object({
  actions: z.array(ActionSchema),
})
```

---

## 3. API route con action stream [docs:vercel-ai-sdk@v5]

```typescript
// app/api/agent/route.ts — MODIFICAR: SYSTEM_PROMPT y acciones disponibles

import { openrouter, MODELS } from '@/lib/ai/openrouter'
import { streamText } from 'ai'
import { closeAndParseJson } from '@/lib/ai/closeAndParseJson'

const SYSTEM_PROMPT = `Sos un agente que responde con acciones estructuradas.

SIEMPRE respondé en este formato JSON:
{
  "actions": [
    { "_type": "think", "text": "tu razonamiento" },
    { "_type": "message", "text": "mensaje al usuario" },
    { "_type": "calculate", "description": "...", "formula": "...", "result": 123 }
  ]
}

Acciones disponibles:
- think: explicá tu razonamiento (el usuario lo ve)
- message: mensaje directo al usuario
- ask: pedir información al usuario
- calculate: mostrar un cálculo con fórmula visible
- tool: ejecutar una herramienta externa

REGLAS:
1. Usá múltiples acciones en secuencia
2. Siempre mostrá tu razonamiento con "think"
3. Cada cálculo debe mostrar fórmula y resultado
4. Sé transparente en cada paso`

export async function POST(req: Request) {
  const { prompt, context } = await req.json()

  const encoder = new TextEncoder()
  const stream = new TransformStream()
  const writer = stream.writable.getWriter()

  const forceStart = '{"actions": [{"_type":'

  const { textStream } = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages: [
      { role: 'assistant', content: forceStart },
      { role: 'user', content: prompt },
    ],
    temperature: 0,
  })

  ;(async () => {
    let buffer = forceStart
    let cursor = 0

    try {
      for await (const text of textStream) {
        buffer += text

        const parsed = closeAndParseJson(buffer)
        if (!parsed?.actions) continue

        const actions = parsed.actions

        while (cursor < actions.length) {
          const action = actions[cursor]
          const isComplete = cursor < actions.length - 1 || buffer.endsWith(']}')

          await writer.write(
            encoder.encode(`data: ${JSON.stringify({ ...action, complete: isComplete })}\n\n`)
          )

          if (isComplete) cursor++
          else break
        }
      }

      await writer.write(encoder.encode('data: [DONE]\n\n'))
    } catch (error) {
      await writer.write(
        encoder.encode(`data: ${JSON.stringify({ error: String(error) })}\n\n`)
      )
    } finally {
      await writer.close()
    }
  })()

  return new Response(stream.readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  })
}
```

---

## 4. Hook `useActionStream`

```typescript
// features/agent/hooks/useActionStream.ts — NUNCA modificar (core del cliente)

'use client'

import { useState, useCallback } from 'react'
import type { Action } from '@/lib/ai/actionSchemas'

export type StreamingAction = Action & { complete: boolean }

export function useActionStream(endpoint = '/api/agent') {
  const [actions, setActions] = useState<StreamingAction[]>([])
  const [isStreaming, setIsStreaming] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const sendPrompt = useCallback(async (prompt: string, context?: any) => {
    setIsStreaming(true)
    setError(null)
    setActions([])

    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, context }),
      })

      const reader = res.body?.getReader()
      const decoder = new TextDecoder()

      if (!reader) throw new Error('No reader')

      let buffer = ''

      while (true) {
        const { value, done } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n\n')
        buffer = lines.pop() || ''

        for (const line of lines) {
          const match = line.match(/^data: (.+)$/)
          if (!match) continue
          if (match[1] === '[DONE]') break

          try {
            const action: StreamingAction = JSON.parse(match[1])
            setActions((prev) => {
              if (prev.length > 0 && !prev[prev.length - 1].complete) {
                return [...prev.slice(0, -1), action]
              }
              return [...prev, action]
            })
          } catch (e) {
            console.error('Parse error:', e)
          }
        }
      }
    } catch (e) {
      setError(String(e))
    } finally {
      setIsStreaming(false)
    }
  }, [endpoint])

  const reset = useCallback(() => {
    setActions([])
    setError(null)
  }, [])

  return { actions, isStreaming, error, sendPrompt, reset }
}
```

---

## 5. Componente `ActionFeed` (con Brand DNA tokens)

```typescript
// features/agent/components/ActionFeed.tsx — MODIFICAR: rendering por tipo

'use client'

import { useState } from 'react'
import type { StreamingAction } from '../hooks/useActionStream'

const VALID_ACTION_TYPES = new Set(['think', 'message', 'ask', 'calculate', 'tool'])

function isValidAction(action: StreamingAction): boolean {
  if (!VALID_ACTION_TYPES.has(action._type)) return false
  switch (action._type) {
    case 'think':
    case 'message':
      return !!(action as { text?: string }).text?.trim()
    case 'ask':
      return !!(action as { question?: string }).question?.trim()
    case 'calculate':
      return !!(action as { description?: string }).description?.trim()
    case 'tool':
      return !!(action as { name?: string }).name?.trim()
    default:
      return false
  }
}

interface Props {
  actions: StreamingAction[]
}

export function ActionFeed({ actions }: Props) {
  return (
    <div className="space-y-3">
      {actions.filter(isValidAction).map((action, i) => (
        <ActionItem key={i} action={action} />
      ))}
    </div>
  )
}

function ActionItem({ action }: { action: StreamingAction }) {
  const baseClass = `flex items-start gap-3 p-3 rounded-lg transition-opacity ${
    !action.complete ? 'opacity-70' : ''
  }`

  switch (action._type) {
    case 'think':
      return <ThinkingToggle text={action.text} complete={action.complete} />

    case 'message':
      return (
        <div className={`${baseClass} bg-info/10 text-foreground`}>
          <span className="text-xl">💬</span>
          <p>{action.text}</p>
        </div>
      )

    case 'ask':
      return (
        <div className={`${baseClass} bg-warning/10 text-foreground`}>
          <span className="text-xl">❓</span>
          <p>{action.question}</p>
        </div>
      )

    case 'calculate':
      return (
        <div className={`${baseClass} bg-success/10 text-foreground`}>
          <span className="text-xl">🔢</span>
          <div>
            <p className="font-medium">{action.description}</p>
            <p className="text-sm text-muted-foreground font-mono">{action.formula}</p>
            <p className="text-lg font-bold text-success">
              = {action.result} {action.unit || ''}
            </p>
          </div>
        </div>
      )

    case 'tool':
      return (
        <div className={`${baseClass} bg-accent/10 text-foreground`}>
          <span className="text-xl">🔧</span>
          <div>
            <p className="font-medium text-accent-foreground">{action.name}</p>
            <pre className="text-xs text-muted-foreground mt-1">
              {JSON.stringify(action.args, null, 2)}
            </pre>
            {action.result && (
              <div className="mt-2 p-2 bg-card rounded">
                <pre className="text-xs">{JSON.stringify(action.result, null, 2)}</pre>
              </div>
            )}
          </div>
        </div>
      )

    default:
      console.warn('ActionItem: tipo no reconocido', action._type)
      return null
  }
}

function ThinkingToggle({ text, complete }: { text: string; complete: boolean }) {
  const [expanded, setExpanded] = useState(false)
  return (
    <button
      onClick={() => setExpanded(!expanded)}
      className={`w-full text-left transition-opacity ${!complete ? 'opacity-60' : ''}`}
    >
      {expanded ? (
        <div className="flex items-start gap-3 p-3 rounded-lg bg-muted">
          <span className="text-xl">💭</span>
          <p className="text-muted-foreground italic text-sm">{text}</p>
        </div>
      ) : (
        <p className="text-sm text-muted-foreground italic">thinking…</p>
      )}
    </button>
  )
}
```

> Tokens usados (`bg-info/10`, `bg-warning/10`, `bg-success/10`, `bg-accent/10`, `bg-destructive/10`, `text-success`, `text-accent-foreground`, etc.) provistos por `add-ui-kit` desde `brand.json`. Si tu `brand.json` no define estos semantic tokens, `add-ui-kit` los genera con fallback razonable + respeta blacklist de hue.

---

## 6. Componente principal

```typescript
// features/agent/components/AgentChat.tsx

'use client'

import { useState, FormEvent } from 'react'
import { useActionStream } from '../hooks/useActionStream'
import { ActionFeed } from './ActionFeed'

export function AgentChat() {
  const { actions, isStreaming, error, sendPrompt, reset } = useActionStream()
  const [input, setInput] = useState('')

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!input.trim() || isStreaming) return
    sendPrompt(input.trim())
    setInput('')
  }

  return (
    <div className="flex flex-col h-full max-w-2xl mx-auto bg-background text-foreground">
      <div className="p-4 border-b border-border flex justify-between items-center">
        <h1 className="font-bold text-lg">Agente transparente</h1>
        <button
          onClick={reset}
          className="text-sm text-muted-foreground hover:text-foreground"
        >
          Limpiar
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        {actions.length === 0 && !isStreaming && (
          <p className="text-center text-muted-foreground py-8">
            Escribí algo para comenzar…
          </p>
        )}

        <ActionFeed actions={actions} />

        {isStreaming && actions.length === 0 && (
          <p className="text-sm text-muted-foreground italic animate-pulse">thinking…</p>
        )}

        {error && (
          <div className="p-3 bg-destructive/10 text-destructive rounded-lg">
            Error: {error}
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit} className="p-4 border-t border-border">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Escribí tu solicitud…"
            disabled={isStreaming}
            className="flex-1 px-4 py-3 border border-input bg-background rounded-lg focus:outline-none focus:ring-2 focus:ring-ring"
          />
          <button
            type="submit"
            disabled={isStreaming || !input.trim()}
            className="px-6 py-3 bg-primary text-primary-foreground rounded-lg disabled:opacity-50 hover:bg-primary/90"
          >
            {isStreaming ? '…' : 'Enviar'}
          </button>
        </div>
      </form>
    </div>
  )
}
```

---

## Casos de uso ideales

| Caso | Por qué Action Stream |
|------|----------------------|
| Calculadoras ROI | usuario VE cada cálculo |
| Auditorías | cada verificación es trazable |
| Due diligence | cada fuente visible |
| Diagnósticos | "por qué llegué a esta conclusión" |
| Cotizadores | desglose transparente |
| Investigación | cada búsqueda mostrada |

---

## Complejidad

| Componente | Líneas | ¿Modificar? |
|------------|--------|-------------|
| `closeAndParseJson.ts` | ~50 | NUNCA |
| `useActionStream.ts` | ~70 | NUNCA |
| API route | ~60 | solo `SYSTEM_PROMPT` |
| `actionSchemas.ts` | ~15/acción | añadir acciones |
| `ActionFeed.tsx` | ~20/acción | personalizar UI con tokens del brand |

**Total core fijo:** ~180 líneas (copiar una vez)
**Por acción nueva:** ~35 líneas

---

## Checklist

- [ ] `find-docs` invocado para confirmar shape v5 de `streamText` + SSE pattern
- [ ] Brand DNA contract presente (`brand.json` + `voice.json`) — R10
- [ ] `closeAndParseJson.ts` copiado
- [ ] `actionSchemas.ts` con tus acciones
- [ ] API route `/api/agent` creada con SYSTEM_PROMPT adaptado al voice del brand
- [ ] `useActionStream` hook implementado
- [ ] `ActionFeed` renderiza cada tipo con tokens del brand (NO colores hardcoded — AP6)
- [ ] Probado que acciones aparecen en tiempo real
- [ ] Anti-Slop Gate post-aplicación

---

## Compatibilidad con otros bloques

- **02 web-search:** añadir `:online` al modelo (handoff a el-guardian si afecta inputs sensibles)
- **03 historial-baas:** guardar `actions[]` en lugar de `messages` (ver Phase 2 status del template)
- **04 vision:** añadir acción `analyze_image` (handoff a el-guardian)
- **05 tools:** las tools SON acciones (no necesitás bloque separado; handoff a el-guardian si hay user-controlled args)

---

*"No le digas el resultado. Mostrale cómo llegaste a él."*

## Sources
- [docs:vercel-ai-sdk@v5] — `streamText`, `textStream` async iteration, SSE pattern
- [docs:zod] — `discriminatedUnion`, action schemas
- [memory:references#R-007] — Context7 (find-docs)
- [memory:decisions#D-009] — Brand DNA contract (R10)
