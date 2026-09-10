# Structured Outputs — Respuestas JSON Tipadas

> Genera JSON estructurado con schemas Zod. El LLM responde en formato definido por vos.

**Tiempo estimado:** 15 minutos
**Prerequisitos:** Bloque `agents/00-setup-base`

---

## Antes de empezar (R13)

Antes de generar código contra Vercel AI SDK v5, invocá [`find-docs`](../find-docs/SKILL.md) con `resolve-library-id('vercel-ai-sdk') → query-docs('generateObject schema mode v5')` para confirmar que `generateObject` y el shape de `schema` siguen vigentes. v5 usa Zod nativo; cambios entre minors han ocurrido. Citar `[docs:vercel-ai-sdk@v5]` en el output.

---

## Qué obtenés

- Respuestas del LLM en formato JSON
- Tipado fuerte con Zod schemas
- Validación automática de estructura
- Ideal para: formularios inteligentes, extracción de datos, clasificación

---

## Casos de uso

| Caso | Descripción |
|------|-------------|
| Extracción de entidades | Sacar nombres, fechas, montos de texto libre |
| Formularios inteligentes | El LLM completa campos faltantes |
| Clasificación multi-label | Categorizar contenido en múltiples dimensiones |
| Parseo de documentos | Convertir texto no estructurado a JSON |
| Validación semántica | Verificar si datos tienen sentido |

---

## 1. Concepto básico [docs:vercel-ai-sdk@v5]

```typescript
import { generateObject } from 'ai'
import { z } from 'zod'
import { openrouter, MODELS } from '@/lib/ai/openrouter'

// 1. Definir schema
const ContactSchema = z.object({
  name: z.string().describe('Nombre completo'),
  email: z.string().email().describe('Correo electrónico'),
  phone: z.string().optional().describe('Teléfono si se menciona'),
  company: z.string().optional().describe('Empresa si se menciona'),
})

// 2. Generar objeto tipado
const { object } = await generateObject({
  model: openrouter(MODELS.balanced),
  schema: ContactSchema,
  prompt: 'Extraé la info de contacto: "Hola, soy Juan Pérez de Acme Corp, mi correo es juan@acme.com"',
})

// 3. Resultado tipado
console.log(object.name)    // "Juan Pérez"
console.log(object.email)   // "juan@acme.com"
console.log(object.company) // "Acme Corp"
```

---

## 2. Patrón: extractor de entidades

```typescript
// lib/ai/extractors.ts

import { generateObject } from 'ai'
import { z } from 'zod'
import { openrouter, MODELS } from '@/lib/ai/openrouter'

const InvoiceDataSchema = z.object({
  vendor: z.string().describe('Nombre del proveedor'),
  invoiceNumber: z.string().describe('Número de factura'),
  date: z.string().describe('Fecha en formato YYYY-MM-DD'),
  total: z.number().describe('Monto total'),
  currency: z.enum(['USD', 'MXN', 'EUR']).describe('Moneda'),
  items: z.array(z.object({
    description: z.string(),
    quantity: z.number(),
    unitPrice: z.number(),
  })).describe('Lista de conceptos'),
})

type InvoiceData = z.infer<typeof InvoiceDataSchema>

export async function extractInvoiceData(text: string): Promise<InvoiceData> {
  const { object } = await generateObject({
    model: openrouter(MODELS.balanced),
    schema: InvoiceDataSchema,
    prompt: `Extraé los datos de esta factura:\n\n${text}`,
  })

  return object
}
```

---

## 3. Patrón: clasificador multi-dimensión

```typescript
// lib/ai/classifiers.ts

import { generateObject } from 'ai'
import { z } from 'zod'
import { openrouter, MODELS } from '@/lib/ai/openrouter'

const TicketClassificationSchema = z.object({
  category: z.enum([
    'billing',
    'technical',
    'sales',
    'general',
  ]).describe('Categoría principal'),

  priority: z.enum([
    'low',
    'medium',
    'high',
    'urgent',
  ]).describe('Nivel de urgencia'),

  sentiment: z.enum([
    'positive',
    'neutral',
    'negative',
    'angry',
  ]).describe('Tono del mensaje'),

  requiresHuman: z.boolean().describe('¿Necesita atención humana?'),

  suggestedTags: z.array(z.string()).describe('Tags relevantes'),
})

type TicketClassification = z.infer<typeof TicketClassificationSchema>

export async function classifyTicket(content: string): Promise<TicketClassification> {
  const { object } = await generateObject({
    model: openrouter(MODELS.fast),
    schema: TicketClassificationSchema,
    prompt: `Clasificá este ticket de soporte:\n\n${content}`,
  })

  return object
}
```

---

## 4. Patrón: formulario inteligente

```typescript
// features/forms/hooks/useSmartForm.ts

'use client'

import { useState } from 'react'
import { z } from 'zod'

interface UseSmartFormOptions<T> {
  schema: z.ZodSchema<T>
  extractEndpoint: string
}

export function useSmartForm<T>({ schema, extractEndpoint }: UseSmartFormOptions<T>) {
  const [data, setData] = useState<Partial<T>>({})
  const [loading, setLoading] = useState(false)

  // El usuario pega texto libre y el LLM lo parsea
  const extractFromText = async (text: string) => {
    setLoading(true)
    try {
      const res = await fetch(extractEndpoint, {
        method: 'POST',
        body: JSON.stringify({ text }),
      })
      const extracted = await res.json()
      setData((prev) => ({ ...prev, ...extracted }))
    } finally {
      setLoading(false)
    }
  }

  return {
    data,
    setData,
    loading,
    extractFromText,
  }
}
```

---

## 5. API route para structured output

```typescript
// app/api/extract/route.ts

import { NextRequest, NextResponse } from 'next/server'
import { generateObject } from 'ai'
import { z } from 'zod'
import { openrouter, MODELS } from '@/lib/ai/openrouter'

// Schema genérico (personalizá según caso)
const ExtractSchema = z.object({
  // MODIFICAR: definí tu schema aquí
  name: z.string().optional(),
  email: z.string().email().optional(),
  date: z.string().optional(),
  amount: z.number().optional(),
})

export async function POST(req: NextRequest) {
  const { text } = await req.json()

  if (!text) {
    return NextResponse.json({ error: 'Text required' }, { status: 400 })
  }

  try {
    const { object } = await generateObject({
      model: openrouter(MODELS.balanced),
      schema: ExtractSchema,
      prompt: `Extraé la información relevante de este texto:\n\n${text}`,
    })

    return NextResponse.json(object)
  } catch (error) {
    console.error('Extract error:', error)
    return NextResponse.json({ error: 'Extraction failed' }, { status: 500 })
  }
}
```

---

## Consideraciones

### Limitaciones conocidas

1. **Modelos soportados:** no todos los de OpenRouter soportan structured output [docs:vercel-ai-sdk@v5]. Verificar con `find-docs` el subset actual.
2. **Schemas complejos:** estructuras muy anidadas pueden fallar.
3. **Validación:** Zod valida estructura, NO semántica (el LLM puede inventar datos).

### Mejores prácticas

1. **Usar `.describe()`** en cada campo: ayuda al modelo a entender qué llenar.
2. **Schemas planos** sobre anidados.
3. **Enums sobre strings** para campos con opciones fijas (`z.enum()`).
4. **Campos opcionales** (`.optional()`) para lo que puede no existir.

---

## Checklist

- [ ] Schema Zod definido con `.describe()` en cada campo
- [ ] Función extractora con `generateObject()`
- [ ] API route o server action
- [ ] Manejo de errores de validación
- [ ] Testing con casos edge
- [ ] `find-docs` invocado pre-implementación si la sintaxis no fue revalidada en sesión reciente

---

## Relacionado

- **Llamada simple**: `single-call.md`
- **UI generativa**: `generative-ui.md`
- **Chat con tools**: `agents/05-tools-funciones.md`

## Sources
- [docs:vercel-ai-sdk@v5] — `generateObject`, schema mode
- [docs:zod] — schema definition + `.describe()` + `.enum()`
- [memory:references#R-007] — Context7 (find-docs)
