# Bloque 01 — Chat Streaming

> Chat con streaming usando Vercel AI SDK v5 + `useChat` hook (camino A — API route).

**Tiempo:** 15 minutos
**Prerequisitos:** Bloque 00 (Setup Base)

---

## Antes de empezar (R13)

Antes de generar código, invocá [`find-docs`](../../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs('useChat v5 sendMessage status parts shape')` para confirmar el shape actual del hook (sendMessage, status enum, message.parts) — la API cambió entre v4 y v5. Citar `[docs:vercel-ai-sdk@v5]` en el output.

---

## Brand DNA gate (R10)

Este template **genera UI** (componente `<ChatWidget>`). Antes de aplicar:

1. `brand/brand.json` + `voice.json` deben existir, o correr `add-ui-kit` primero.
2. Los colores `bg-blue-500`, `text-gray-400`, `bg-red-50` del upstream se reemplazan por tokens (`bg-primary`, `text-muted-foreground`, `bg-destructive/10`). El Anti-Slop Gate corre post-aplicación.

---

## Qué obtenés

- Chat con respuestas en streaming
- Estado manejado automáticamente por `useChat`
- UI con tokens del Brand DNA
- Compatible con todos los bloques siguientes (web-search, historial, tools, RAG)

---

## 1. API route [docs:vercel-ai-sdk@v5]

```typescript
// app/api/chat/route.ts
// MODIFICAR: solo el system prompt

import { openrouter, MODELS } from '@/lib/ai/openrouter'
import { streamText, convertToModelMessages, type UIMessage } from 'ai'

// MODIFICAR: tu system prompt — leer voice.json para tono
const SYSTEM_PROMPT = `Sos un asistente útil y conciso.
Respondé en español.
Sé directo y práctico.`

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json()

  // v5: convertir UIMessage[] a formato del modelo
  const modelMessages = await convertToModelMessages(messages)

  const result = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages: modelMessages,
  })

  // v5: stream compatible con useChat
  return result.toUIMessageStreamResponse()
}
```

---

## 2. Hook `useChat`

```typescript
// features/chat/hooks/useChat.ts
// Re-exporta el hook v5 — no modificar.

'use client'

// v5: importar de @ai-sdk/react (NO de 'ai/react')
export { useChat } from '@ai-sdk/react'
export type { Message } from 'ai'
```

---

## 3. Componente de chat (con Brand DNA tokens)

```typescript
// features/chat/components/ChatWidget.tsx

'use client'

import { useState, FormEvent } from 'react'
import { useChat } from '@ai-sdk/react'

export function ChatWidget() {
  // v5: input se maneja externamente
  const { messages, status, error, sendMessage } = useChat()
  const [input, setInput] = useState('')

  const isLoading = status === 'submitted' || status === 'streaming'

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!input.trim() || isLoading) return

    const text = input.trim()
    setInput('')
    // v5: sendMessage espera { text: string }
    sendMessage({ text })
  }

  // Helper: extraer texto de message.parts
  const getMessageText = (message: typeof messages[0]): string => {
    if (!message.parts) return ''
    return message.parts
      .filter((part): part is { type: 'text'; text: string } => part.type === 'text')
      .map((part) => part.text)
      .join('')
  }

  return (
    <div className="flex flex-col h-full bg-background text-foreground">
      {/* Mensajes */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <p className="text-center text-muted-foreground">
            Escribí algo para comenzar…
          </p>
        )}

        {messages.map((m) => (
          <div
            key={m.id}
            className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[80%] p-3 rounded-lg ${
                m.role === 'user'
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-foreground'
              }`}
            >
              {getMessageText(m)}
            </div>
          </div>
        ))}

        {isLoading && messages[messages.length - 1]?.role === 'user' && (
          <ThinkingIndicator />
        )}

        {error && (
          <div className="p-3 bg-destructive/10 text-destructive rounded-lg">
            Error: {error.message}
          </div>
        )}
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="p-4 border-t border-border">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Escribí tu mensaje…"
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

function ThinkingIndicator() {
  return (
    <div className="flex justify-start">
      <p className="text-sm text-muted-foreground italic animate-pulse">
        thinking…
      </p>
    </div>
  )
}
```

---

## 4. Usar el componente

```typescript
// app/page.tsx

import { ChatWidget } from '@/features/chat/components/ChatWidget'

export default function Page() {
  return (
    <main className="h-screen">
      <ChatWidget />
    </main>
  )
}
```

---

## Cambios clave SDK v4 → v5 [docs:vercel-ai-sdk@v5]

| v4 (antiguo) | v5 (actual) |
|--------------|-------------|
| `import { useChat } from 'ai/react'` | `import { useChat } from '@ai-sdk/react'` |
| `input` del hook | `useState` externo |
| `handleInputChange` | `onChange` manual |
| `handleSubmit` | `sendMessage({ text })` |
| `isLoading` | `status === 'streaming'` |
| `message.content` | `message.parts.filter(p => p.type === 'text')` |
| `toDataStreamResponse()` | `toUIMessageStreamResponse()` |
| `convertToModelMessages` síncrono | `await convertToModelMessages(...)` (async) |

> Si el agente está generando con shape v4, halt y `find-docs` antes de seguir.

---

## Personalización

### Cambiar modelo
```typescript
// app/api/chat/route.ts
const result = streamText({
  model: openrouter(MODELS.powerful),
  // ...
})
```

### Agregar contexto del usuario
```typescript
const SYSTEM_PROMPT = `Sos un asistente para ${userName}.
Su empresa es ${companyName}.
Respondé de forma personalizada.`
```

### Endpoint personalizado
```typescript
const { messages, sendMessage } = useChat({
  api: '/api/mi-chat-custom',
})
```

---

## Checklist

- [ ] `find-docs` invocado para confirmar shape v5 de `useChat`
- [ ] `brand/brand.json` presente (o `add-ui-kit` corrido) — R10
- [ ] API route creada en `app/api/chat/route.ts`
- [ ] System prompt personalizado (lee `voice.json` para tono)
- [ ] `<ChatWidget>` implementado con tokens del Brand DNA
- [ ] Chat funciona con streaming local
- [ ] Anti-Slop Gate post-aplicación (visual diff vs `brand.json`)

---

## Siguiente bloque

- **Agregar búsqueda web**: `02-web-search.md`
- **Guardar conversaciones**: `03-historial-baas.md`
- **Analizar imágenes**: `04-vision-analysis.md`
- **Agregar tools**: `05-tools-funciones.md`

## Sources
- [docs:vercel-ai-sdk@v5] — `useChat`, `streamText`, `toUIMessageStreamResponse`, message parts
- [memory:references#R-007] — Context7 (find-docs)
- [memory:decisions#D-009] — Brand DNA contract (R10)
