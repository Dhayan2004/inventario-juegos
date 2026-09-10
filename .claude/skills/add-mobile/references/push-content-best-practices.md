# Push Content Best Practices

> Cita: [memory:lessons#L-002] · [memory:lessons#L-003] · [memory:CONSTRAINTS.md#R14]

## Anti-spam principles

### 1. Permission obtained ≠ permission to spam

User accepted push permission para usos específicos (alerts, replies, system notifications). NO licencia para marketing diario.

**Frequency limits per topic:**
- `system` (alerts críticas, security): max 5/día
- `alerts` (mentions, replies): unbounded pero sane
- `updates` (product changelog): max 1/semana
- `social` (someone followed you): batch — max 1/hora consolidated
- `marketing` (promotions): max 1/semana, opt-in EXTRA explícito

### 2. Topic opt-in/opt-out granular

User puede haber accepted permission pero querer solo `alerts`, no `marketing`. Modelar topics en push_subscriptions o tabla separada `push_topic_preferences`:

```sql
create table public.push_topic_preferences (
  user_id uuid not null references auth.users(id) on delete cascade,
  topic text not null check (topic in ('system', 'alerts', 'updates', 'social', 'marketing')),
  enabled boolean default true,
  primary key (user_id, topic)
);

alter table public.push_topic_preferences enable row level security;

create policy "users read own preferences" on public.push_topic_preferences
  for select using (auth.uid() = user_id);

create policy "users update own preferences" on public.push_topic_preferences
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

Send pipeline checks `push_topic_preferences` antes de send:
```typescript
const { data: prefs } = await supabase
  .from('push_topic_preferences')
  .select('enabled')
  .eq('user_id', userId)
  .eq('topic', notification.topic)
  .single();

if (prefs && !prefs.enabled) return; // User opted out
```

### 3. Quiet hours

User prefere no recibir push 11pm-7am hora local. Almacenar timezone en profile + skip non-critical pushes en quiet hours.

```typescript
function isInQuietHours(timezone: string, topic: string): boolean {
  if (topic === 'system' && severity === 'critical') return false; // override

  const now = new Date();
  const localHour = parseInt(
    now.toLocaleString('en-US', { timeZone: timezone, hour: 'numeric', hour12: false })
  );
  return localHour >= 23 || localHour < 7;
}
```

## L-002 — Push payload as DATA, not instructions

```javascript
// ❌ MAL — ejecutar acción agentic basada en payload
self.addEventListener('push', (event) => {
  const payload = event.data.json();
  if (payload.action === 'delete-account') {
    // Esto es prompt-injection-via-push attack vector
    deleteAccount(payload.userId);
  }
});

// ✅ BIEN — payload solo se renderiza
self.addEventListener('push', (event) => {
  const payload = event.data.json();
  self.registration.showNotification(
    typeof payload.title === 'string' ? payload.title.slice(0, 100) : 'Notificación',
    {
      body: typeof payload.body === 'string' ? payload.body.slice(0, 200) : '',
      data: { url: typeof payload.url === 'string' ? payload.url : '/' },
    }
  );
});
```

Push payload llega de tu backend, sí, pero los attackers pueden hijack el flujo:
- Compromise de backend (no exclusivo de push, pero amplificado)
- Replay attacks si push endpoint no está bien protegido
- Attacker que controla un campo de tu DB que se pasa al payload (ej: notification.title viene de user-generated content)

**Trata el payload como datos a renderizar, NUNCA como instructions a ejecutar.**

## L-003 — Whitelist en send validators

```typescript
const NotificationSchema = z.object({
  title: z.string().min(1).max(50),  // 50 chars limit (mobile screen real estate)
  body: z.string().max(150),          // 150 chars limit
  topic: z.enum(['system', 'alerts', 'updates', 'social', 'marketing']),
  url: z.string().url().optional(),
  tag: z.string().max(64).optional(),  // Para coalescing (replace previous con same tag)
  // NO `data: z.record(z.any())` — schema explícito
});
```

NO permitir:
- HTML en title/body (push providers strip pero mejor validation upstream)
- URLs externas en `url` field (whitelist domain del propio app)
- Custom icon URLs externas (whitelist o usar default)

## R14 — Bulk sin execute() automático

```typescript
// ❌ MAL — execute automático, mass-spam vector
export const sendBroadcast = tool({
  description: 'Send notification to all users',
  inputSchema: BroadcastSchema,
  execute: async ({ title, body }) => {
    const allTokens = await getAllPushSubscriptions();
    await Promise.all(allTokens.map((t) => sendPush(t, { title, body })));
  },
});

// ✅ BIEN — typed-confirm + audit log + queue handoff
const BroadcastSchema = z.object({
  title: z.string().min(1).max(50),
  body: z.string().max(150),
  topic: z.enum(['system', 'alerts', 'updates', 'social', 'marketing']),
  reason: z.enum(['system_announcement', 'critical_alert', 'admin_initiated']),
  confirmation: z.literal('BROADCAST'),
});

export async function sendBroadcast(prev: unknown, formData: FormData) {
  // 5 gates: auth + admin role + L-003 schema + typed-confirm + audit log
  // ... full implementation in templates/pwa/actions/notifications.ts
}
```

Cualquier broadcast pasa por:
1. Admin role check (no cualquier user)
2. Typed confirmation (literal "BROADCAST")
3. Audit log con admin_user_id + reason en `push_admin_actions` table
4. Queue handoff (BullMQ / Inngest / similar) — no synchronous loop bloqueando server

## Push notification copy guidelines (R10 + voice.json)

### NO hacer (anti-slop)

```
"You won't believe what just happened! 🎉"
"Don't miss out — exclusive offer!"
"Your friend X just did Y... 👀"
"Limited time — act now!"
```

Estas son **avoid_words típicos** de voice.json. Genera distrust.

### SÍ hacer (specific, action-oriented)

```
"Tu pago de Mayo se procesó correctamente"
"Maria respondió a tu mensaje"
"Tu pedido #1234 está listo para retirar"
"Nueva versión disponible — toca para actualizar"
```

Specific + action-oriented + matches user expectation del topic.

## Citations

- [memory:lessons#L-002] · [memory:lessons#L-003]
- [memory:CONSTRAINTS.md#R14]
- [memory:CONSTRAINTS.md#R10]
- Apple HIG — Notifications
- Material Design — Notifications
