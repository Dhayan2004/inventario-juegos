# find-docs — Cache de IDs canónicos Context7

> Mapping `<libraryName>` → `<libraryId>` para evitar `resolve-library-id` calls redundantes.
> **Single writer:** `el-evaluador`. Otros skills LEEN.
>
> Cada entry validado al menos una vez con Context7 (resolve-library-id + query-docs exitosos).

| libraryName | libraryId | Versión activa Forja default | One-line |
|-------------|-----------|------------------------------|----------|
| next.js | `/vercel/next.js` | 16 | App Router + Server Actions + RSC. Default framework Forja. |
| supabase | `/supabase/supabase` | latest | BaaS default. CLI + JS client + RLS + Storage + Realtime + Edge Functions. |
| insforge | `/insforge/insforge` | latest | BaaS alternativo agents-first. Postgres + MCP nativo + Model Gateway. |
| vercel-ai-sdk | `/vercel/ai` | v5 | streamText / generateText / generateObject. Tools como objeto (v5 syntax, NO v4 array). |
| stripe | `/stripe/stripe-node` | latest | Checkout sessions, subscriptions, billing portal, webhooks. |
| polar | `/polarsource/polar` | latest | Alternativa Stripe orientada a creators. Subscriptions + checkouts. |
| resend | `/resend/resend-node` | latest | Transactional email API. Pareado con react-email. |
| react-email | `/resend/react-email` | latest | Email components con React. |
| tailwindcss | `/tailwindlabs/tailwindcss` | 3 | CSS framework default. Forja override en brand.css. |
| shadcn-ui | `/shadcn/ui` | latest | Component library copy-paste. Default UI. |
| zod | `/colinhacks/zod` | latest | Schema validation. Default para structured-outputs en `ai`. |
| zustand | `/pmndrs/zustand` | latest | State management cliente. Default Forja. |
| playwright | `/microsoft/playwright` | latest | E2E browser automation. Alternativa a agent-browser. |
| agent-browser | `/vercel-labs/agent-browser` | latest | Default Forja para QA + visual diff (~4× ahorro tokens vs Playwright MCP). |

## Notas de versión

- **Vercel AI SDK:** Forja default = v5. La API cambió significativamente entre v4 y v5 — al consultar siempre incluir `@v5` en query si la versión importa (ej: `streamText tools v5`).
- **Next.js:** Forja default = 16. App Router exclusively (no Pages Router). RSC + Server Actions standard.
- **Tailwind:** Forja default = 3.x. Brand DNA tokens overrideen defaults.

## Misses registrados

(Append-only por `el-evaluador`. Cada miss = una librería que Context7 no encontró o devolvió ambiguo.)

| Date | libraryName | Query | Outcome | Fallback usado |
|------|-------------|-------|---------|----------------|
| (none) | | | | |

## Cómo se actualiza este cache

1. `find-docs` resuelve un `libraryId` nuevo (no estaba en este archivo).
2. Devuelve el resultado al caller + propone entry para cache.
3. `el-evaluador` (R5) verifica el ID + añade aquí en commit con scope `evaluator` o `memory`.
4. Próxima invocación de `find-docs` para ese lib → cache hit → skip resolve.
