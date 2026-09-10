# Generative UI — Componentes Dinámicos

> El LLM decide qué componente React renderizar según el contexto.

**Tiempo estimado:** 30 minutos
**Prerequisitos:** Bloques `agents/00-setup-base` + `agents/01-chat-streaming`

---

## Antes de empezar (R13)

Antes de generar código contra Vercel AI SDK v5, invocá [`find-docs`](../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs('streamText tools v5 UI message stream tool-invocation parts')` para confirmar el shape actual de tool calls en el stream y el patrón canónico para renderizar componentes a partir de ellos. v5 cambió el shape de `parts` (`tool-invocation` con `toolName + args` en lugar de v4). Citar `[docs:vercel-ai-sdk@v5]` en el output.

---

## Brand DNA gate (R10)

Este template **genera componentes UI**. Antes de aplicarlo:

1. Verificar que el proyecto target tenga `brand/brand.json` + `brand/voice.json`. Si no existen → halt automático por R10; correr `add-ui-kit` primero.
2. Los componentes generados a continuación usan tokens placeholder (`bg-card`, `border`, `text-foreground`). Cuando aplicás el template, `add-ui-kit` ya tradujo los tokens del brand contract al CSS efectivo. **No hardcodear** colores tipo `bg-blue-50`, `text-green-600`, `bg-gray-100` — esos son anti-slop (AP6) y los rechaza el-evaluador.
3. Anti-Slop Gate corre post-aplicación: visual diff vs `brand.json` + blacklist de hue (rangos 235-285 sin justificación documentada).

---

## Qué obtenés

- El LLM genera componentes React en tiempo real
- UI adaptativa según la conversación
- Ideal para: dashboards dinámicos, wizards inteligentes, interfaces contextuales

---

## Casos de uso

| Caso | Descripción |
|------|-------------|
| Dashboard adaptativo | Mostrar widgets según lo que pregunta el usuario |
| Wizard inteligente | Pasos dinámicos según respuestas anteriores |
| Visualización de datos | Gráficas generadas según el análisis |
| Formularios contextuales | Campos que aparecen según necesidad |
| Respuestas ricas | Tablas, cards, listas según el contenido |

---

## 1. Concepto básico

El LLM, en vez de solo responder texto, "llama" componentes React que vos definiste:

```
Usuario: "Mostrame las ventas de este mes"
LLM decide: "Voy a mostrar un SalesChart"
LLM llama tool: render_chart({ type: 'bar', data: [...] })
Tu app renderiza: <SalesChart data={...} />
```

---

## 2. Definir componentes renderizables

```typescript
// features/chat/components/generative/index.tsx

'use client'

// Componentes que el LLM puede invocar.
// Estilos vía tokens del brand contract (NO hardcoded colors).
export function WeatherCard({ city, temp, condition }: {
  city: string
  temp: number
  condition: string
}) {
  return (
    <div className="p-4 bg-card text-card-foreground rounded-lg border">
      <h3 className="font-bold">{city}</h3>
      <p className="text-2xl">{temp}°C</p>
      <p className="text-muted-foreground">{condition}</p>
    </div>
  )
}

export function StockPrice({ symbol, price, change }: {
  symbol: string
  price: number
  change: number
}) {
  const isPositive = change >= 0
  return (
    <div className="p-4 bg-card rounded-lg border">
      <h3 className="font-mono font-bold">{symbol}</h3>
      <p className="text-2xl">${price.toFixed(2)}</p>
      <p className={isPositive ? 'text-success' : 'text-destructive'}>
        {isPositive ? '+' : ''}{change.toFixed(2)}%
      </p>
    </div>
  )
}

export function DataTable({ headers, rows }: {
  headers: string[]
  rows: string[][]
}) {
  return (
    <table className="w-full border-collapse">
      <thead>
        <tr>
          {headers.map((h, i) => (
            <th key={i} className="border p-2 bg-muted">{h}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row, i) => (
          <tr key={i}>
            {row.map((cell, j) => (
              <td key={j} className="border p-2">{cell}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  )
}
```

> Tokens usados (`bg-card`, `bg-muted`, `text-success`, `text-destructive`, etc.) los provee `add-ui-kit` desde `brand.json`. Si tu proyecto target no los tiene, ese skill se ejecuta primero.

---

## 3. Definir tools de UI [docs:vercel-ai-sdk@v5]

```typescript
// lib/ai/ui-tools.ts

import { z } from 'zod'

// v5: tools como objeto con `description + inputSchema + execute` (NO v4 array shape).
// Para generative UI, execute puede devolver los args mismos (o enriquecidos)
// para que el frontend los renderice.
export const uiTools = {
  show_weather: {
    description: 'Muestra una tarjeta de clima',
    inputSchema: z.object({
      city: z.string().describe('Nombre de la ciudad'),
      temp: z.number().describe('Temperatura en Celsius'),
      condition: z.string().describe('Condición: sunny, cloudy, rainy, snowy, windy'),
    }),
  },

  show_stock: {
    description: 'Muestra precio de acción',
    inputSchema: z.object({
      symbol: z.string().describe('Símbolo de la acción'),
      price: z.number().describe('Precio actual'),
      change: z.number().describe('Cambio porcentual'),
    }),
  },

  show_table: {
    description: 'Muestra datos en tabla',
    inputSchema: z.object({
      headers: z.array(z.string()).describe('Encabezados de columnas'),
      rows: z.array(z.array(z.string())).describe('Filas de datos'),
    }),
  },
}
```

---

## 4. API route con tools de UI [docs:vercel-ai-sdk@v5]

```typescript
// app/api/chat-ui/route.ts

import { streamText, convertToModelMessages, type UIMessage } from 'ai'
import { openrouter, MODELS } from '@/lib/ai/openrouter'
import { uiTools } from '@/lib/ai/ui-tools'

const SYSTEM_PROMPT = `Sos un asistente que puede mostrar información visualmente.
Cuando el usuario pida datos, usá las tools disponibles para mostrar UI.
Siempre explicá brevemente qué estás mostrando.`

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json()

  const result = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages: await convertToModelMessages(messages),
    tools: uiTools,
  })

  return result.toUIMessageStreamResponse()
}
```

---

## 5. Renderizar componentes dinámicos

```typescript
// features/chat/components/GenerativeChat.tsx

'use client'

import { useChat } from '@ai-sdk/react'
import { WeatherCard, StockPrice, DataTable } from './generative'

export function GenerativeChat() {
  const { messages, sendMessage, status } = useChat({
    api: '/api/chat-ui',
  })

  // Mapear tool calls → componentes
  const renderToolResult = (toolName: string, args: Record<string, unknown>) => {
    switch (toolName) {
      case 'show_weather':
        return <WeatherCard {...args as Parameters<typeof WeatherCard>[0]} />
      case 'show_stock':
        return <StockPrice {...args as Parameters<typeof StockPrice>[0]} />
      case 'show_table':
        return <DataTable {...args as Parameters<typeof DataTable>[0]} />
      default:
        return null
    }
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((m) => (
          <div key={m.id}>
            {/* Texto normal */}
            {m.parts?.filter((p) => p.type === 'text').map((p, i) => (
              <p key={i}>{p.text}</p>
            ))}

            {/* Tool calls como componentes — v5 shape */}
            {m.parts?.filter((p) => p.type === 'tool-invocation').map((p, i) => (
              <div key={i} className="my-2">
                {renderToolResult(p.toolInvocation.toolName, p.toolInvocation.args)}
              </div>
            ))}
          </div>
        ))}
      </div>

      {/* Input... */}
    </div>
  )
}
```

---

## Consideraciones

### Limitaciones conocidas
1. **Complejidad:** requiere mapeo manual tool → componente.
2. **Hidratación:** cuidado con SSR y componentes dinámicos.
3. **Estado:** los componentes generados no persisten estado entre renders.
4. **Seguridad:** validar siempre los args antes de renderizar (si hay datos sensibles, considerá un handoff a `el-guardian`).

### Cuándo NO usar
- Si los componentes son predecibles (usá condicionales normales).
- Si la UI es estática (no necesitás LLM).
- Si el rendimiento es crítico (Generative UI tiene overhead).

### Alternativa simple
```typescript
// En vez de Generative UI...
if (response.includes('tabla')) {
  return <DataTable data={parseTable(response)} />
}

// ...usá clasificación + render condicional
const { type } = await classifyResponse(response)
switch (type) {
  case 'table': return <DataTable />
  case 'chart': return <Chart />
  default: return <Text />
}
```

---

## Checklist

- [ ] Brand DNA contract presente (`brand.json` + `voice.json`) — R10
- [ ] `find-docs` invocado para confirmar v5 shape de `tool-invocation` parts
- [ ] Componentes renderizables definidos usando tokens del brand (no colores hardcoded — AP6)
- [ ] Tools de UI con schemas Zod y `inputSchema` (v5 shape)
- [ ] API route con tools configuradas
- [ ] Lógica de renderizado dinámico
- [ ] Validación de argumentos antes de renderizar
- [ ] Testing de cada componente

---

## Relacionado

- **Chat básico**: `agents/01-chat-streaming.md`
- **Tools tradicionales**: `agents/05-tools-funciones.md`
- **Structured outputs**: `structured-outputs.md`

## Sources
- [docs:vercel-ai-sdk@v5] — `streamText`, `tools`, `tool-invocation` parts shape
- [docs:zod] — `inputSchema` definition
- [memory:references#R-007] — Context7 (find-docs)
- [memory:decisions#D-009] — Brand DNA contract (R10)
