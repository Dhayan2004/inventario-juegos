# Bloque 00 — Setup Base

> Configuración inicial para todos los bloques de AI Templates.

**Tiempo:** 10 minutos
**Prerequisitos:** Proyecto Next.js existente + decisión `baas` aplicada (Supabase o InsForge) si vas a usar templates con persistencia.

---

## Antes de empezar (R13)

Antes de generar código, invocá [`find-docs`](../../find-docs/SKILL.md) con:

- `resolve-library-id('vercel-ai-sdk') → query-docs('install dependencies v5 setup')` para confirmar deps + minor version vigente.
- `resolve-library-id('@openrouter/ai-sdk-provider') → query-docs('createOpenRouter setup')` para confirmar provider.

Citar `[docs:vercel-ai-sdk@v5]` y `[docs:openrouter]` en el output.

---

## 1. Instalar dependencias [docs:vercel-ai-sdk@v5]

```bash
# Core AI SDK v5
npm install ai@^5 @ai-sdk/react@^2 @openrouter/ai-sdk-provider@^1

# Validación
npm install zod@^3

# Cliente BaaS — uno u otro según `baas` skill (D11):
# Supabase:
npm install @supabase/supabase-js @supabase/ssr
# o InsForge:
# npm install @insforge/sdk
```

> Si todavía no corriste el skill `baas`, hacelo primero — define cuál cliente instalar.

---

## 2. Variables de entorno

```env
# .env.local

# OpenRouter (REQUERIDO)
OPENROUTER_API_KEY=sk-or-v1-tu-api-key

# BaaS — completá el bloque que corresponda (NO ambos):
# Supabase:
NEXT_PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# InsForge:
# NEXT_PUBLIC_INSFORGE_URL=https://tu-proyecto.insforge.dev
# NEXT_PUBLIC_INSFORGE_ANON_KEY=...

# Metadata para OpenRouter (opcional pero recomendado)
NEXT_PUBLIC_SITE_URL=https://tu-app.com
NEXT_PUBLIC_SITE_NAME=Tu App
```

### Obtener API keys
1. **OpenRouter:** https://openrouter.ai/keys
2. **Supabase:** dashboard → Settings → API
3. **InsForge:** dashboard del proyecto → Settings → API

---

## 3. Configurar OpenRouter provider [docs:openrouter]

```typescript
// lib/ai/openrouter.ts

import { createOpenRouter } from '@openrouter/ai-sdk-provider'

export const openrouter = createOpenRouter({
  apiKey: process.env.OPENROUTER_API_KEY!,
})

// Modelos default — ajustá según necesidad
export const MODELS = {
  // Rápidos y económicos
  fast: 'google/gemini-2.0-flash-exp:free',

  // Balanceados
  balanced: 'anthropic/claude-3-5-sonnet',

  // Potentes
  powerful: 'anthropic/claude-3-5-sonnet',

  // Vision (análisis de imágenes)
  vision: 'google/gemini-2.0-flash-exp:free',
} as const

export type ModelKey = keyof typeof MODELS
```

> Modelos cambian rápido; `find-docs` con `query-docs('OpenRouter top models 2026')` antes de fijar la lista.

---

## 4. Configurar BaaS client (opcional)

Solo necesario si vas a usar templates con persistencia (`03-historial-baas`, `04-vision`, `05-tools` con resultados persistidos, `06-rag`).

### Supabase

```typescript
// lib/supabase/client.ts — cliente browser

import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

```typescript
// lib/supabase/server.ts — cliente server

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Server Component → ignorar
          }
        },
      },
    }
  )
}
```

### InsForge

```typescript
// lib/insforge/client.ts

import { createInsforgeClient } from '@insforge/sdk'

export function createClient() {
  return createInsforgeClient({
    url: process.env.NEXT_PUBLIC_INSFORGE_URL!,
    anonKey: process.env.NEXT_PUBLIC_INSFORGE_ANON_KEY!,
  })
}
```

> Validar shape del SDK con `find-docs` resolve-library-id('insforge') antes de aplicar.

---

## 5. Estructura de carpetas recomendada

```
src/
├── app/
│   └── api/
│       └── chat/           # API route para chat
│           └── route.ts
├── lib/
│   ├── ai/
│   │   └── openrouter.ts   # Provider configurado
│   └── <baas>/             # supabase/ o insforge/ según decisión
│       ├── client.ts       # Browser client
│       └── server.ts       # Server client (Supabase) o equivalente
└── features/
    └── chat/               # Feature de chat
        ├── components/
        ├── hooks/
        └── types/
```

---

## 6. Verificar setup

```typescript
// app/api/test/route.ts
// ELIMINAR después de verificar

import { openrouter, MODELS } from '@/lib/ai/openrouter'
import { generateText } from 'ai'

export async function GET() {
  try {
    const { text } = await generateText({
      model: openrouter(MODELS.fast),
      prompt: 'Decí "Setup OK" en una palabra.',
    })

    return Response.json({ status: 'ok', response: text })
  } catch (error) {
    return Response.json(
      { status: 'error', message: String(error) },
      { status: 500 }
    )
  }
}
```

Probar en `http://localhost:3000/api/test`.

---

## Checklist

- [ ] `find-docs` invocado para vercel-ai-sdk + openrouter (versión actual confirmada)
- [ ] `baas` skill aplicado (Supabase o InsForge decidido y `.env` con un solo bloque BaaS)
- [ ] Dependencies instaladas (incluyendo cliente BaaS correcto)
- [ ] `.env.local` con `OPENROUTER_API_KEY`
- [ ] `lib/ai/openrouter.ts` creado
- [ ] (Opcional) BaaS client creado en `lib/<baas>/`
- [ ] Endpoint `/api/test` devuelve `{ status: 'ok' }`

---

## Siguiente bloque

Elegí tu camino:
- **Chat tradicional** (API route): `01-chat-streaming.md`
- **Action stream** (server actions, sin endpoint): `01-alt-action-stream.md`

## Sources
- [docs:vercel-ai-sdk@v5] — `generateText`, install
- [docs:openrouter] — `createOpenRouter`, modelos disponibles
- [docs:supabase] — `createBrowserClient`, `createServerClient`
- [docs:insforge] — SDK setup
- [memory:references#R-007] — Context7 (find-docs)
- [memory:decisions#D-011] — BaaS decision tree
