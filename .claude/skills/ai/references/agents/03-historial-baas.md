# Bloque 03 — Historial con BaaS (Action Stream Pattern)

> Persistencia de conversaciones (sessions + actions) sobre el BaaS decidido por el skill `baas`. Soporta Supabase y InsForge (D11).

**Tiempo:** 25 minutos
**Prerequisitos:** Bloque 01 o 01-ALT + decisión `baas` aplicada (`.env` con un solo bloque BaaS configurado)

---

## Antes de empezar (R13)

Antes de generar código, invocá [`find-docs`](../../find-docs/SKILL.md) con:

- `resolve-library-id('supabase') → query-docs('createBrowserClient RLS auth.uid 2026')` si la decisión fue Supabase.
- `resolve-library-id('insforge') → query-docs('client SDK insert select RLS')` si fue InsForge.

Citar `[docs:supabase]` o `[docs:insforge]` en el output. Confirmar shape de auth helpers + RLS expressions antes de aplicar SQL.

---

## Handoff a `el-guardian` (D3) — OBLIGATORIO

Este template **toca RLS + service role** + persiste mensajes de usuarios autenticados. Surface de seguridad alta:

| Riesgo | Qué chequea `el-guardian` |
|--------|---------------------------|
| RLS gap | toda tabla nueva tiene `ENABLE ROW LEVEL SECURITY` + ≥1 policy. Sin esto, leak entre usuarios. |
| `auth.uid()` mal usado | que las policies efectivamente comparen contra `auth.uid()`, no contra `user_id` que llegue del cliente |
| Service role en cliente | que `SUPABASE_SERVICE_ROLE_KEY` o `INSFORGE_SERVICE_KEY` NO aparezcan en código que se sirve al browser |
| PII en logs | que el contenido de `content` JSONB no se loggee con `console.log` ni se mande a Sentry sin redact |
| Cascade delete | que `ON DELETE CASCADE` esté presente para no dejar `agent_actions` huérfanas |

PASS criterio: 0 critical, 0 high. Sin signoff de `el-guardian` → no merge a main.

---

## Brand DNA gate (R10)

Este template **renderiza UI** (`<AgentSidebar>` + integración con `<AgentChat>`). Brand contract obligatorio. Tokens del brand reemplazan los `bg-blue-500`/`bg-gray-50`/`text-blue-700`/etc. del upstream.

---

## Qué obtenés

- Conversaciones persistentes con acciones tipadas (JSONB)
- Sidebar responsivo (sessions list + delete)
- Memoria efectiva: el LLM ve mensajes previos en su contexto
- Soporta múltiples action types (no solo texto)
- Batch save para performance
- Auto-generación de títulos
- Funciona indistintamente sobre Supabase o InsForge (un solo set de tipos + service abstracto)

---

## 1. Schema (Supabase) [docs:supabase]

```sql
-- Ejecutar vía supabase migration new (skill `el-migrador`)
-- NO copiar a la consola directamente; el-migrador genera .rollback.sql obligatorio

CREATE TABLE agent_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT DEFAULT 'Nueva sesión',
  model TEXT DEFAULT 'haiku-4.5',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE agent_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES agent_sessions(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (
    action_type IN ('user_message', 'think', 'message', 'analyze', 'calculate', 'recommend', 'alert')
  ),
  content JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_agent_sessions_user_id ON agent_sessions(user_id);
CREATE INDEX idx_agent_sessions_updated ON agent_sessions(updated_at DESC);
CREATE INDEX idx_agent_actions_session_id ON agent_actions(session_id);
CREATE INDEX idx_agent_actions_created ON agent_actions(created_at ASC);

-- RLS — OBLIGATORIO
ALTER TABLE agent_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own sessions"
  ON agent_sessions FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD actions in own sessions"
  ON agent_actions FOR ALL
  USING (
    session_id IN (
      SELECT id FROM agent_sessions WHERE user_id = auth.uid()
    )
  );
```

> Aplicar con `el-migrador`: `supabase migration new add_agent_history` + escribir el SQL arriba. el-migrador genera el `.rollback.sql` (DROP TABLE + DROP POLICY).

## 1-bis. Schema (InsForge) [docs:insforge]

InsForge usa Postgres con sintaxis equivalente. La diferencia está en cómo aplicar:

```sql
-- Mismo SQL que arriba; aplicarlo via InsForge dashboard o
-- vía SQL runner del `insforge` CLI según el flujo del skill `baas`.
```

Auth helper en InsForge: en lugar de `auth.uid()` puede ser `current_setting('jwt.claims.sub')::uuid` o `insforge_uid()` según versión. Validar con `find-docs(libraryName: 'insforge', query: 'RLS auth user id helper function 2026')` antes de aplicar.

---

## 2. Tipos TypeScript (compartidos)

```typescript
// features/agent/types/index.ts

export interface AgentSession {
  id: string
  user_id: string
  title: string
  model: string
  created_at: string
  updated_at: string
}

export type ActionType =
  | 'user_message'
  | 'think'
  | 'message'
  | 'analyze'
  | 'calculate'
  | 'recommend'
  | 'alert'

export interface AgentActionRecord {
  id: string
  session_id: string
  action_type: ActionType
  content: Record<string, unknown>
  created_at: string
}

// Acciones en memoria (UI)
export interface BaseAction {
  _type: ActionType
  complete: boolean
}

export interface UserMessageAction extends BaseAction { _type: 'user_message'; text: string }
export interface ThinkAction extends BaseAction { _type: 'think'; text: string }
export interface MessageAction extends BaseAction { _type: 'message'; text: string }
export interface AnalyzeAction extends BaseAction { _type: 'analyze'; title: string; points: string[] }
export interface CalculateAction extends BaseAction { _type: 'calculate'; label: string; value: string | number; trend?: 'up' | 'down' | 'neutral' }
export interface RecommendAction extends BaseAction { _type: 'recommend'; title: string; items: string[] }
export interface AlertAction extends BaseAction { _type: 'alert'; severity: 'info' | 'warning' | 'critical'; message: string }

export type AgentAction =
  | UserMessageAction
  | ThinkAction
  | MessageAction
  | AnalyzeAction
  | CalculateAction
  | RecommendAction
  | AlertAction
```

---

## 3. Servicio de historial — Supabase adapter [docs:supabase]

```typescript
// features/agent/services/historyService.supabase.ts

import { createClient } from '@/lib/supabase/client'
import type { AgentSession, AgentActionRecord, ActionType } from '../types'

export const supabaseHistoryService = {
  async listSessions(limit = 20): Promise<AgentSession[]> {
    const sb = createClient()
    const { data, error } = await sb
      .from('agent_sessions')
      .select('*')
      .order('updated_at', { ascending: false })
      .limit(limit)
    if (error) throw error
    return data || []
  },

  async createSession(title?: string, model?: string): Promise<AgentSession> {
    const sb = createClient()
    const { data: { user } } = await sb.auth.getUser()
    if (!user) throw new Error('No autenticado')

    const { data, error } = await sb
      .from('agent_sessions')
      .insert({
        user_id: user.id,
        title: title || 'Nueva sesión',
        model: model || 'haiku-4.5',
      })
      .select()
      .single()
    if (error) throw error
    return data
  },

  async loadActions(sessionId: string): Promise<AgentActionRecord[]> {
    const sb = createClient()
    const { data, error } = await sb
      .from('agent_actions')
      .select('*')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: true })
    if (error) throw error
    return data || []
  },

  async saveAction(sessionId: string, actionType: ActionType, content: Record<string, unknown>): Promise<AgentActionRecord> {
    const sb = createClient()
    const { data, error } = await sb
      .from('agent_actions')
      .insert({ session_id: sessionId, action_type: actionType, content })
      .select()
      .single()
    if (error) throw error

    await sb.from('agent_sessions').update({ updated_at: new Date().toISOString() }).eq('id', sessionId)
    return data
  },

  async saveActions(sessionId: string, actions: Array<{ actionType: ActionType; content: Record<string, unknown> }>): Promise<AgentActionRecord[]> {
    const sb = createClient()
    const records = actions.map((a) => ({
      session_id: sessionId,
      action_type: a.actionType,
      content: a.content,
    }))
    const { data, error } = await sb.from('agent_actions').insert(records).select()
    if (error) throw error

    await sb.from('agent_sessions').update({ updated_at: new Date().toISOString() }).eq('id', sessionId)
    return data || []
  },

  async updateSessionTitle(sessionId: string, title: string): Promise<void> {
    const sb = createClient()
    const { error } = await sb
      .from('agent_sessions')
      .update({ title: title.slice(0, 100) })
      .eq('id', sessionId)
    if (error) throw error
  },

  async deleteSession(sessionId: string): Promise<void> {
    const sb = createClient()
    const { error } = await sb.from('agent_sessions').delete().eq('id', sessionId)
    if (error) throw error
  },

  async getSession(sessionId: string): Promise<AgentSession | null> {
    const sb = createClient()
    const { data, error } = await sb
      .from('agent_sessions')
      .select('*')
      .eq('id', sessionId)
      .single()
    if (error) {
      if (error.code === 'PGRST116') return null
      throw error
    }
    return data
  },
}
```

## 3-bis. Servicio de historial — InsForge adapter [docs:insforge]

```typescript
// features/agent/services/historyService.insforge.ts

import { createClient } from '@/lib/insforge/client'
import type { AgentSession, AgentActionRecord, ActionType } from '../types'

// Misma interface que Supabase adapter — solo cambia el cliente.
// Validar shape de cada call con find-docs(libraryName: 'insforge') antes
// de aplicar; el SDK puede diferir en signatures.

export const insforgeHistoryService = {
  async listSessions(limit = 20): Promise<AgentSession[]> {
    const client = createClient()
    const { data, error } = await client
      .from('agent_sessions')
      .select('*')
      .order('updated_at', { ascending: false })
      .limit(limit)
    if (error) throw error
    return data || []
  },

  async createSession(title?: string, model?: string): Promise<AgentSession> {
    const client = createClient()
    // En InsForge, auth.getUser() puede no existir — usar helper del SDK.
    const user = await client.auth.user()
    if (!user) throw new Error('No autenticado')

    const { data, error } = await client
      .from('agent_sessions')
      .insert({
        user_id: user.id,
        title: title || 'Nueva sesión',
        model: model || 'haiku-4.5',
      })
      .select()
      .single()
    if (error) throw error
    return data
  },

  async loadActions(sessionId: string): Promise<AgentActionRecord[]> {
    const client = createClient()
    const { data, error } = await client
      .from('agent_actions')
      .select('*')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: true })
    if (error) throw error
    return data || []
  },

  // saveAction, saveActions, updateSessionTitle, deleteSession, getSession:
  // mismo shape que el Supabase adapter; solo cambia el cliente.
  // Para no duplicar 100 LOC, ver supabase adapter — los métodos son idénticos
  // a nivel de cuerpo, solo `createClient` difiere.
}
```

> Convención: ambos adapters exportan la MISMA interface. El componente `<AgentChat>` consume un single `historyService` que, en runtime, apunta al adapter correcto según `baas` decision. Centralizar el switch en un único `features/agent/services/historyService.ts` que re-exporta del adapter elegido.

---

## 4. Hook `useAgentHistory`

```typescript
// features/agent/hooks/useAgentHistory.ts

'use client'

import { useState, useEffect, useCallback } from 'react'
import { historyService } from '../services'
import type { AgentSession, AgentActionRecord, ActionType } from '../types'

interface UseAgentHistoryOptions {
  autoLoad?: boolean
}

export function useAgentHistory(options: UseAgentHistoryOptions = {}) {
  const { autoLoad = true } = options

  const [sessions, setSessions] = useState<AgentSession[]>([])
  const [currentSessionId, setCurrentSessionId] = useState<string | null>(null)
  const [currentActions, setCurrentActions] = useState<AgentActionRecord[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (autoLoad) loadSessions()
  }, [autoLoad])

  const loadSessions = useCallback(async () => {
    try {
      setIsLoading(true)
      setError(null)
      const data = await historyService.listSessions()
      setSessions(data)
    } catch (err) {
      console.error('Error loading sessions:', err)
      setError('Error al cargar sesiones')
    } finally {
      setIsLoading(false)
    }
  }, [])

  const createSession = useCallback(async (title?: string, model?: string) => {
    try {
      setIsSaving(true)
      setError(null)
      const session = await historyService.createSession(title, model)
      setSessions((prev) => [session, ...prev])
      setCurrentSessionId(session.id)
      setCurrentActions([])
      return session
    } catch (err) {
      setError('Error al crear sesión')
      throw err
    } finally {
      setIsSaving(false)
    }
  }, [])

  const selectSession = useCallback(async (sessionId: string) => {
    try {
      setIsLoading(true)
      setError(null)
      setCurrentSessionId(sessionId)
      const actions = await historyService.loadActions(sessionId)
      setCurrentActions(actions)
      return actions
    } catch (err) {
      setError('Error al cargar sesión')
      throw err
    } finally {
      setIsLoading(false)
    }
  }, [])

  const saveAction = useCallback(
    async (actionType: ActionType, content: Record<string, unknown>) => {
      const sid = currentSessionId ?? (await createSession()).id
      try {
        setIsSaving(true)
        const action = await historyService.saveAction(sid, actionType, content)
        setCurrentActions((prev) => [...prev, action])
        // Mover sesión al inicio (updated_at)
        setSessions((prev) => {
          const session = prev.find((s) => s.id === sid)
          if (!session) return prev
          const updated = { ...session, updated_at: new Date().toISOString() }
          return [updated, ...prev.filter((s) => s.id !== sid)]
        })
        return action
      } catch (err) {
        setError('Error al guardar acción')
        throw err
      } finally {
        setIsSaving(false)
      }
    },
    [currentSessionId, createSession]
  )

  const saveActions = useCallback(
    async (actions: Array<{ actionType: ActionType; content: Record<string, unknown> }>) => {
      const sid = currentSessionId ?? (await createSession()).id
      try {
        setIsSaving(true)
        const saved = await historyService.saveActions(sid, actions)
        setCurrentActions((prev) => [...prev, ...saved])
        setSessions((prev) => {
          const session = prev.find((s) => s.id === sid)
          if (!session) return prev
          const updated = { ...session, updated_at: new Date().toISOString() }
          return [updated, ...prev.filter((s) => s.id !== sid)]
        })
        return saved
      } catch (err) {
        setError('Error al guardar acciones')
        throw err
      } finally {
        setIsSaving(false)
      }
    },
    [currentSessionId, createSession]
  )

  const updateTitle = useCallback(async (title: string) => {
    if (!currentSessionId) return
    try {
      await historyService.updateSessionTitle(currentSessionId, title)
      setSessions((prev) =>
        prev.map((s) => (s.id === currentSessionId ? { ...s, title } : s))
      )
    } catch (err) {
      setError('Error al actualizar título')
    }
  }, [currentSessionId])

  const deleteSession = useCallback(
    async (sessionId: string) => {
      try {
        await historyService.deleteSession(sessionId)
        setSessions((prev) => prev.filter((s) => s.id !== sessionId))
        if (currentSessionId === sessionId) {
          setCurrentSessionId(null)
          setCurrentActions([])
        }
      } catch (err) {
        setError('Error al eliminar sesión')
        throw err
      }
    },
    [currentSessionId]
  )

  const startNewConversation = useCallback(() => {
    setCurrentSessionId(null)
    setCurrentActions([])
  }, [])

  const currentSession = sessions.find((s) => s.id === currentSessionId) || null

  return {
    sessions,
    currentSession,
    currentSessionId,
    currentActions,
    isLoading,
    isSaving,
    error,
    loadSessions,
    createSession,
    selectSession,
    saveAction,
    saveActions,
    updateTitle,
    deleteSession,
    startNewConversation,
  }
}
```

---

## 5. Componente `AgentSidebar` (con tokens del brand)

```typescript
// features/agent/components/AgentSidebar.tsx

'use client'

import { useState } from 'react'
import { Plus, MessageSquare, Trash2, X, Menu, Clock } from 'lucide-react'
import type { AgentSession } from '../types'

interface Props {
  sessions: AgentSession[]
  currentSessionId: string | null
  isLoading: boolean
  onSelectSession: (sessionId: string) => void
  onNewSession: () => void
  onDeleteSession: (sessionId: string) => void
}

export function AgentSidebar({
  sessions,
  currentSessionId,
  isLoading,
  onSelectSession,
  onNewSession,
  onDeleteSession,
}: Props) {
  const [isOpen, setIsOpen] = useState(false)
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null)

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)
    if (diffMins < 1) return 'Ahora'
    if (diffMins < 60) return `${diffMins}m`
    if (diffHours < 24) return `${diffHours}h`
    if (diffDays < 7) return `${diffDays}d`
    return date.toLocaleDateString('es-MX', { day: 'numeric', month: 'short' })
  }

  const handleDelete = (sessionId: string) => {
    if (deleteConfirm === sessionId) {
      onDeleteSession(sessionId)
      setDeleteConfirm(null)
    } else {
      setDeleteConfirm(sessionId)
      setTimeout(() => setDeleteConfirm(null), 3000)
    }
  }

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="lg:hidden fixed top-20 left-4 z-40 w-10 h-10 bg-card shadow-md rounded-xl flex items-center justify-center text-muted-foreground hover:text-primary transition-colors"
        aria-label="Abrir historial"
      >
        <Menu className="w-5 h-5" />
      </button>

      {isOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-foreground/30 z-40"
          onClick={() => setIsOpen(false)}
        />
      )}

      <aside
        className={`
          fixed lg:sticky top-0 left-0 h-screen z-50 lg:z-auto
          w-72 bg-muted border-r border-border
          flex flex-col
          transition-transform duration-300
          ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        <div className="p-4 border-b border-border">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-bold">Historial</h2>
            <button
              onClick={() => setIsOpen(false)}
              className="lg:hidden w-8 h-8 flex items-center justify-center text-muted-foreground hover:text-foreground"
              aria-label="Cerrar"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <button
            onClick={() => {
              onNewSession()
              setIsOpen(false)
            }}
            className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-primary text-primary-foreground rounded-xl font-medium text-sm hover:bg-primary/90 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Nueva conversación
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-3">
          {isLoading ? (
            <div className="flex items-center justify-center py-8">
              <div className="w-6 h-6 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
            </div>
          ) : sessions.length === 0 ? (
            <div className="text-center py-8">
              <MessageSquare className="w-10 h-10 text-muted-foreground/50 mx-auto mb-3" />
              <p className="text-sm text-muted-foreground">Sin conversaciones</p>
              <p className="text-xs text-muted-foreground mt-1">
                Iniciá una nueva para comenzar
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {sessions.map((session) => {
                const isSelected = currentSessionId === session.id
                const isDeleting = deleteConfirm === session.id

                return (
                  <div
                    key={session.id}
                    className={`
                      group relative rounded-xl transition-all cursor-pointer p-3
                      ${
                        isSelected
                          ? 'bg-primary/10 border border-primary/20'
                          : 'bg-card border border-border hover:border-primary/40'
                      }
                    `}
                    onClick={() => {
                      onSelectSession(session.id)
                      setIsOpen(false)
                    }}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <p
                          className={`text-sm font-medium truncate ${
                            isSelected ? 'text-primary' : 'text-foreground'
                          }`}
                        >
                          {session.title}
                        </p>
                        <div className="flex items-center gap-2 mt-1">
                          <Clock className="w-3 h-3 text-muted-foreground" />
                          <span className="text-xs text-muted-foreground">
                            {formatDate(session.updated_at)}
                          </span>
                          <span className="text-xs text-muted-foreground/60">|</span>
                          <span className="text-xs text-muted-foreground">{session.model}</span>
                        </div>
                      </div>

                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          handleDelete(session.id)
                        }}
                        className={`
                          flex-shrink-0 w-7 h-7 rounded-lg flex items-center justify-center
                          transition-all opacity-0 group-hover:opacity-100
                          ${
                            isDeleting
                              ? 'bg-destructive text-destructive-foreground'
                              : 'bg-muted text-muted-foreground hover:text-destructive'
                          }
                        `}
                        title={isDeleting ? 'Confirmar eliminar' : 'Eliminar'}
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        <div className="p-4 border-t border-border">
          <p className="text-xs text-muted-foreground text-center">
            {sessions.length} sesiones guardadas
          </p>
        </div>
      </aside>
    </>
  )
}
```

---

## 6. Memoria del agente (history → context del modelo)

> **Historial sin memoria es un log muerto.** Si guardás el historial, el modelo debe poder usarlo en futuros turnos.

```typescript
// features/agent/lib/actionsToHistory.ts

import type { AgentAction } from '../types'

export function actionsToHistory(
  actions: AgentAction[]
): Array<{ role: 'user' | 'assistant'; content: string }> {
  const history: Array<{ role: 'user' | 'assistant'; content: string }> = []
  for (const action of actions) {
    if (action._type === 'user_message' && action.text?.trim()) {
      history.push({ role: 'user', content: action.text })
    } else if (action._type === 'message' && action.text?.trim()) {
      history.push({ role: 'assistant', content: action.text })
    }
  }
  return history
}
```

API route consumiendo el historial:

```typescript
// app/api/agent/route.ts

import { streamText } from 'ai'
import { openrouter, MODELS } from '@/lib/ai/openrouter'

interface HistoryMessage { role: 'user' | 'assistant'; content: string }

export async function POST(req: Request) {
  const {
    prompt,
    history = [],
  }: { prompt: string; history?: HistoryMessage[] } = await req.json()

  // Limitar a últimos 10 para no explotar contexto
  const previousMessages = history.slice(-10)

  const result = streamText({
    model: openrouter(MODELS.balanced),
    system: SYSTEM_PROMPT,
    messages: [
      ...previousMessages,
      { role: 'user', content: prompt },
    ],
    temperature: 0,
  })

  return result.toUIMessageStreamResponse()
}
```

System prompt:
```typescript
const SYSTEM_PROMPT = `Sos un asistente con acceso a datos.

MEMORIA: tenés acceso al historial de la conversación.
Recordá nombres, preferencias y contexto previo del usuario.

(... resto del prompt ...)`
```

| Sin memoria | Con memoria |
|-------------|-------------|
| Usuario: "Me llamo Juan" | Usuario: "Me llamo Juan" |
| AI: "¡Hola Juan!" | AI: "¡Hola Juan!" |
| Usuario: "¿Cómo me llamo?" | Usuario: "¿Cómo me llamo?" |
| AI: "No lo sé" ❌ | AI: "Te llamás Juan" ✅ |

---

## Checklist

- [ ] `find-docs` invocado para Supabase O InsForge según `baas` decision
- [ ] Migration aplicada vía `el-migrador` (rollback existe)
- [ ] RLS habilitado en ambas tablas + policies presentes
- [ ] `historyService` adapter implementado para el BaaS elegido
- [ ] `useAgentHistory` hook funcionando
- [ ] `AgentSidebar` con tokens del brand (no colores hardcoded — AP6)
- [ ] `actionsToHistory` + memoria activa en API route
- [ ] **`el-guardian` audit ejecutado y PASS** — D3
- [ ] Anti-Slop Gate post-aplicación

---

## Siguiente bloque

- **Analizar imágenes**: `04-vision-analysis.md`
- **Agregar tools**: `05-tools-funciones.md`

## Sources
- [docs:supabase] — `createBrowserClient`, RLS, `auth.uid()`
- [docs:insforge] — SDK adapter equivalente
- [docs:vercel-ai-sdk@v5] — `streamText`, message shape
- [memory:references#R-007] — Context7 (find-docs)
- [memory:skills#el-guardian] — security audit handoff (D3)
- [memory:skills#el-migrador] — migration application (D10)
- [memory:decisions#D-011] — BaaS decision tree
- [memory:decisions#D-004] — historial-supabase → historial-baas rename rationale
