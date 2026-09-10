# Single Call — Llamada Simple a LLM

> Genera texto con una sola llamada. Sin chat, sin agente, sin streaming.

**Tiempo:** 5 minutos
**Prerequisitos:** Bloque `agents/00-setup-base`

---

## Antes de empezar (R13)

Antes de generar código contra Vercel AI SDK v5, invocá [`find-docs`](../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs('generateText v5 signature options')` para confirmar la sintaxis actual. La API v5 difiere de v4 en el shape de algunos campos. Citar `[docs:vercel-ai-sdk@v5]` en el output.

---

## Qué obtenés

- Llamada directa al LLM
- Respuesta completa (no streaming)
- Ideal para: botones, acciones puntuales, procesamiento batch

---

## Cuándo usar

| Usá Single Call | Usá Chat/Agent |
|-----------------|----------------|
| Botón "Resumir" | Conversación continua |
| Generar descripción | Preguntas de seguimiento |
| Traducir texto | Contexto acumulativo |
| Validar contenido | Streaming en tiempo real |
| Procesamiento batch | Interacción con usuario |

---

## 1. `generateText` (síncrono) [docs:vercel-ai-sdk@v5]

```typescript
// lib/ai/generate.ts
// MODIFICAR: ajustá el modelo según necesidad

import { generateText } from 'ai'
import { openrouter, MODELS } from '@/lib/ai/openrouter'

interface GenerateOptions {
  prompt: string
  system?: string
  maxTokens?: number
}

export async function generate({
  prompt,
  system,
  maxTokens = 1000,
}: GenerateOptions): Promise<string> {
  const { text } = await generateText({
    model: openrouter(MODELS.fast),
    system: system || 'Sos un asistente útil y conciso.',
    prompt,
    maxTokens,
  })

  return text
}
```

---

## 2. Uso en server action

```typescript
// app/actions/ai.ts
'use server'

import { generate } from '@/lib/ai/generate'

export async function summarizeText(text: string): Promise<string> {
  return generate({
    prompt: `Resumí el siguiente texto en 2-3 oraciones:\n\n${text}`,
    system: 'Sos experto en resumir textos. Sé conciso y claro.',
  })
}

export async function translateText(text: string, targetLang: string): Promise<string> {
  return generate({
    prompt: `Traducí al ${targetLang}:\n\n${text}`,
    system: 'Sos traductor profesional. Mantenés el tono original.',
  })
}

export async function generateDescription(product: string): Promise<string> {
  return generate({
    prompt: `Generá una descripción de producto para: ${product}`,
    system: 'Sos copywriter. Escribís descripciones atractivas y concisas.',
    maxTokens: 200,
  })
}
```

---

## 3. Uso en componente

```typescript
// features/content/components/SummarizeButton.tsx
'use client'

import { useState } from 'react'
import { summarizeText } from '@/app/actions/ai'

interface Props {
  text: string
  onSummary: (summary: string) => void
}

export function SummarizeButton({ text, onSummary }: Props) {
  const [loading, setLoading] = useState(false)

  const handleClick = async () => {
    setLoading(true)
    try {
      const summary = await summarizeText(text)
      onSummary(summary)
    } catch (error) {
      console.error('Error:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className="px-4 py-2 bg-primary text-primary-foreground rounded-lg disabled:opacity-50"
    >
      {loading ? 'Resumiendo…' : 'Resumir'}
    </button>
  )
}
```

> Estilos placeholder. Si el proyecto target tiene `brand/brand.json`, los tokens (`bg-primary`, `text-primary-foreground`, radius) los aplica `add-ui-kit`. Sin Brand DNA, halt automático por R10.

---

## 4. Uso en API Route

```typescript
// app/api/generate/route.ts

import { NextRequest, NextResponse } from 'next/server'
import { generate } from '@/lib/ai/generate'

export async function POST(req: NextRequest) {
  const { prompt, system } = await req.json()

  if (!prompt) {
    return NextResponse.json(
      { error: 'Prompt requerido' },
      { status: 400 }
    )
  }

  try {
    const text = await generate({ prompt, system })
    return NextResponse.json({ text })
  } catch (error) {
    console.error('Generate error:', error)
    return NextResponse.json(
      { error: 'Error generando texto' },
      { status: 500 }
    )
  }
}
```

---

## 5. Batch processing (múltiples llamadas)

```typescript
// lib/ai/batch.ts

import { generate } from './generate'

interface BatchItem {
  id: string
  prompt: string
}

interface BatchResult {
  id: string
  result: string
  error?: string
}

export async function generateBatch(
  items: BatchItem[],
  system?: string
): Promise<BatchResult[]> {
  const BATCH_SIZE = 5
  const results: BatchResult[] = []

  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const batch = items.slice(i, i + BATCH_SIZE)

    const batchResults = await Promise.all(
      batch.map(async (item) => {
        try {
          const result = await generate({ prompt: item.prompt, system })
          return { id: item.id, result }
        } catch (error) {
          return {
            id: item.id,
            result: '',
            error: error instanceof Error ? error.message : 'Unknown error',
          }
        }
      })
    )

    results.push(...batchResults)
  }

  return results
}
```

---

## Diferencia con `streamText` [docs:vercel-ai-sdk@v5]

| `generateText` | `streamText` |
|--------------|------------|
| Espera respuesta completa | Envía tokens progresivamente |
| Retorna `string` | Retorna `ReadableStream` |
| Ideal para acciones puntuales | Ideal para chat/UI interactiva |
| Menor complejidad | Requiere manejo de stream |

```typescript
// generateText — simple
const { text } = await generateText({ model, prompt })
console.log(text) // texto completo

// streamText — streaming
const result = streamText({ model, prompt })
for await (const chunk of result.textStream) {
  console.log(chunk) // token por token
}
```

---

## Casos de uso comunes

### Validar contenido
```typescript
export async function validateContent(content: string): Promise<boolean> {
  const result = await generate({
    prompt: `Analizá si este contenido es apropiado. Respondé solo "SI" o "NO":\n\n${content}`,
    maxTokens: 10,
  })
  return result.trim().toUpperCase() === 'SI'
}
```

### Extraer keywords
```typescript
export async function extractKeywords(text: string): Promise<string[]> {
  const result = await generate({
    prompt: `Extraé 5 keywords de este texto. Devolvé solo las palabras separadas por comas:\n\n${text}`,
    maxTokens: 50,
  })
  return result.split(',').map((k) => k.trim())
}
```

### Clasificar texto
```typescript
export async function classifyIntent(text: string): Promise<string> {
  const result = await generate({
    prompt: `Clasificá la intención del usuario. Opciones: PREGUNTA, QUEJA, SOLICITUD, OTRO.\n\nTexto: ${text}`,
    maxTokens: 20,
  })
  return result.trim().toUpperCase()
}
```

---

## Checklist

- [ ] Función `generate()` creada en `lib/ai/generate.ts`
- [ ] Server actions para casos de uso específicos
- [ ] Componente con botón y estado loading
- [ ] Manejo de errores implementado
- [ ] `find-docs` invocado pre-implementación si la sintaxis no fue revalidada en sesión reciente

---

## Relacionado

- **Chat interactivo**: `agents/01-chat-streaming.md`
- **Respuestas estructuradas**: `structured-outputs.md`

## Sources
- [docs:vercel-ai-sdk@v5] — `generateText`, `streamText` API
- [memory:references#R-007] — Context7 (find-docs)
