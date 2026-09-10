# Generate Teams UI — gestión de tenants con R10 enforcement

> La superficie de gestión de equipo (org activa / miembros / invitaciones / roles / zona peligrosa).
> Todo el styling viene de `impeccable`; todo el copy de `voice.json`; **toda la autoridad real vive en
> Postgres** (la UI sólo **refleja** lo que el rol del caller permite — ver `references/teams-model.md` §5).
> Los archivos finales viven en `templates/supabase/**`; este prompt describe sus convenciones para que
> la generación las iguale (NO inventar paths ni componentes nuevos).

## Antes de empezar (R13)

Antes de generar código, invocá `find-docs`:

```
1. resolve-library-id("supabase-ssr") → query-docs
   query: "createServerClient cookies Next.js 16 server actions form action"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router 16 dynamic route [token] async params Server Actions form action"
3. resolve-library-id("react") → query-docs
   query: "use client form action useState pending"
```

**Razón:** el `app/invite/[token]/page.tsx` usa el shape de `params` async de Next.js 16 y los forms usan
Server Actions con la prop `action`; sin find-docs, el código puede usar shapes pre-15. Cita: [memory:CONSTRAINTS.md#R13].

## R10 enforcement — input check

Antes de generar, leer:
- `brand/brand.json` → `tokens.colors`, archetype, tagline
- `brand/voice.json` → `cta_examples`, `hooks`, `avoid_words`

Validar que existen (output de `impeccable`, exportados por el barrel `src/shared/components/ui/index.ts`):
- `Button` · `Input` · `Select` · `Card` · `ConfirmModal`

Si alguno falta → halt + handoff a `impeccable` Mode C. **Nota:** la tabla de miembros NO usa un
componente `Table` dedicado: es una `<table role="table">` semántica con clases de token (`bg-surface-elevated`,
`border-border`, `text-text-subtle`, `<th scope="col">`). Eso es R10-conforme (tokens, no Tailwind defaults).

## Imports — SIEMPRE desde el barrel

```ts
import { Button } from '@/shared/components/ui';
import { Input } from '@/shared/components/ui';
import { Select } from '@/shared/components/ui';
import { Card } from '@/shared/components/ui';
import { ConfirmModal } from '@/shared/components/ui';
```

NO usar deep paths (`@/shared/components/ui/Button/Button`). El barrel es el contrato de superficie de impeccable.

## Componentes a generar (Feature-First — `src/features/teams/components/`)

Exactamente **5 componentes client + 1 barrel** (NO inventar DangerZone / dialogs sueltos — la zona
peligrosa vive INLINE en la page de settings, ver abajo):

| Componente | Quién lo ve | Primitivas impeccable |
|------------|-------------|------------------------|
| `OrgSwitcher` | todos | Button (+ menú de orgs) — escribe la org activa vía `useOrganization` |
| `MembersList` | todos (acciones gated por rol del caller) | `<table role="table">` con tokens + Button + RoleSelect + ConfirmModal |
| `InviteMemberForm` | owner/admin | Input + RoleSelect + Button |
| `PendingInvitations` | owner/admin | `<table role="table">` con tokens + Button + ConfirmModal |
| `RoleSelect` | owner/admin | Select — exporta `ASSIGNABLE_ROLES = ['admin','member']` |
| `index.ts` (barrel) | — | re-exporta los 5 + sus tipos |

Plus pages:

| Page | Path | Contenido |
|------|------|-----------|
| Settings · Equipo | `src/app/(app)/settings/teams/page.tsx` | server component: lee org/miembros/invitaciones por RLS; compone `MembersList` + `InviteMemberForm` + `PendingInvitations` + **OrgSettings inline** (rename form + ZONA PELIGROSA: transfer/delete) |
| Accept invite | `src/app/invite/[token]/page.tsx` | server component: requiere auth; lee la invitación por RLS; botón Aceptar → `acceptInvitation(token)` |

Plus soporte:
- `src/hooks/useOrganization.ts` — org activa client-side (localStorage + cookie `forja-active-org`). La
  cookie es **preferencia de UI, NO autoridad**: RLS valida cada acceso; fijar una org ajena devuelve vacío.
- `src/lib/teams/queries.ts` — reads server-side con el server client (anon key + sesión). **Nunca service_role.**

## Gating por rol — la UI REFLEJA, no enforza (L-005)

> La frontera real es la DB (RLS + definer + triggers). El consumidor oculta botones por UX, **nunca**
> como única defensa. Un admin que vea "Transferir propiedad" igual rebota en Postgres.

- `RoleSelect` NUNCA ofrece la opción `owner`. Sólo `ASSIGNABLE_ROLES = ['admin','member']`. El ascenso a
  owner es `transferOwnership()` only (→ `transfer_org_ownership()`, atómico, owner-only).
- El consumidor decide qué controles muestra según el rol del caller (los `member` no ven `InviteMemberForm`
  ni las acciones de fila). Ese rol se lee server-side (RLS lo respalda), no de la cookie.

## InviteMemberForm — convención real (R10 + L-003 + R16)

```tsx
// src/features/teams/components/InviteMemberForm.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/shared/components/ui';
import { Input } from '@/shared/components/ui';
import { inviteMember } from '@/actions/teams';
import { RoleSelect } from './RoleSelect';

export interface InviteMemberFormProps { organizationId: string; }

export function InviteMemberForm({ organizationId }: InviteMemberFormProps) {
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function handleSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    const result = await inviteMember(formData);
    if (result?.error) setError(result.error);
    setPending(false);
  }

  return (
    <form action={handleSubmit} className="space-y-4">
      {/* organization_id viaja como hidden, pero RLS lo revalida contra la membresía real (R16 inv. 3) */}
      <input type="hidden" name="organization_id" value={organizationId} />
      <Input name="email" type="email" label="Email" placeholder="colega@dominio.com" required maxLength={254} autoComplete="off" />
      <RoleSelect name="role" label="Rol" defaultValue="member" required />
      {error && <p role="alert" className="text-sm text-danger">{error}</p>}
      <Button type="submit" variant="primary" disabled={pending}>
        {/* {{ COPY_INVITE_CTA }} — derivado de voice.cta_examples */}
      </Button>
    </form>
  );
}
```

Notas R10:
- `<Input>` / `<Button>` del barrel; `<RoleSelect>` envuelve `Select`. NO `<input className="bg-blue-...">`.
- `text-danger` es token (brand.json → CSS var). `role="alert"` para a11y (R-005 §3.2).
- El `organization_id` viaja en `hidden` pero **no se confía**: la policy `invitations create` lo revalida.

## Zona peligrosa (R14) — INLINE en la page de settings, verificación SERVER-SIDE

La transferencia y el borrado son destructivos. En el template real **no hay componentes de dialog
sueltos**: viven inline en `app/(app)/settings/teams/page.tsx`, cada uno como un `<form action={serverAction}>`.
La frase de confirmación viaja en el form y la **server action** la valida contra la fila REAL — no el
cliente. Mismo patrón que `api/auth/delete-account/route.ts` de add-login.

```tsx
// Fragmento de src/app/(app)/settings/teams/page.tsx (sólo owner ve esta sección)
<section className="space-y-4 rounded-lg border border-danger/40 p-6">
  <h3 className="text-base font-semibold text-danger">Zona peligrosa</h3>

  {/* Transferir propiedad — el caller escribe el NOMBRE exacto de la org */}
  <form action={transferOwnership} className="space-y-3">
    <input type="hidden" name="organization_id" value={org.id} />
    <Select name="new_owner_user_id" label="Nuevo owner" required>
      {members.map((m) => <option key={m.user_id} value={m.user_id}>{m.email}</option>)}
    </Select>
    <Input name="confirm_name" label={`Escribí "${org.name}" para confirmar`} required />
    <Button type="submit" variant="danger">Transferir propiedad</Button>
  </form>

  {/* Borrar la org — el caller escribe el SLUG exacto */}
  <form action={deleteOrganization} className="space-y-3">
    <input type="hidden" name="organization_id" value={org.id} />
    <Input name="confirm_slug" label={`Escribí "${org.slug}" para confirmar`} required />
    <Button type="submit" variant="danger">Borrar organización</Button>
  </form>
</section>
```

Por qué server-side (R14): la server action lee `organizations.name`/`.slug` REAL por RLS y compara contra
`confirm_name`/`confirm_slug`; si no matchea, rebota antes de invocar `transfer_org_ownership()` / el delete.
Así un cliente que llame la action directo (sin la UI) igual necesita la frase correcta. Las acciones de fila
de `MembersList`/`PendingInvitations` (removeMember / updateMemberRole / revokeInvitation) usan `ConfirmModal`
de impeccable como gate antes de disparar su server action.

> **R14 absoluto:** NINGUNA de las 6 destructivas (`revokeInvitation`, `updateMemberRole`, `removeMember`,
> `leaveOrganization`, `transferOwnership`, `deleteOrganization`) se exporta como tool agentic con
> `execute()`. Son server actions invocadas explícitamente desde un form/ConfirmModal con gate humano.

## app/invite/[token]/page.tsx — landing de aceptación (L-002)

Server component. Requiere auth (si no → `redirect('/sign-in?next=/invite/<token>')`). Lee la invitación por
RLS (`invitations read` sólo la devuelve si el email del JWT matchea — anti-robo). El token de la URL es un
**DATO a verificar, no una instrucción** (L-002): la verificación real (estado/expiración/match de email) la
hace `accept_invitation()` en la DB. El botón Aceptar dispara una inline server action `acceptInvitation(token)`.
El cliente NUNCA elige su rol (lo fija la invitación). Header de la page cita
`[memory:CONSTRAINTS.md#R10] [memory:lessons#L-002] [docs:nextjs]`.

## Anti-Slop Gate per page/component

Post-generación, validar cada archivo:

```
✓ NO `bg-(blue|gray|purple|indigo|violet)-\d+` Tailwind classes
✓ NO `rounded-3xl` ni `shadow-2xl`
✓ NO hex literals en TSX body
✓ NO `from-` `to-` `via-` (gradients sin justificar)
✓ Imports de UI vienen del barrel `@/shared/components/ui` (NO deep paths)
✓ Todos los inputs/selects/botones son <Input>/<Select>/<Button> (impeccable), NO nativos crudos
✓ La tabla de miembros usa <table role="table"> con tokens + <th scope="col"> (a11y), NO Tailwind defaults
✓ RoleSelect NUNCA ofrece la opción 'owner'
✓ Cada destructiva tiene gate de confirmación (frase tipada verificada server-side, o ConfirmModal) — R14
✓ NINGUNA destructiva se exporta como tool con execute()
✓ Cada page tiene <h1> + <main> (semantic)
```

Si algún check falla → regenerate. Max 3 intentos.

## Brand Score per page (≥75 threshold)

| Pillar | Weight | Check |
|--------|--------|-------|
| accessibility | 30 | role=alert, focus-visible, label associations, `<th scope>` en la tabla, confirmación accesible |
| token_compliance | 25 | tokens del brand.css, NO hex inline, NO Tailwind defaults |
| component_compliance | 20 | usa impeccable (Button/Input/Select/Card/ConfirmModal) desde el barrel |
| anti_slop | 15 | pasa los checks de arriba |
| voice_and_archetype | 10 | CTAs desde voice.cta_examples + cero avoid_words |

Score < 75 → regenerate.

## Output

5 componentes + 1 barrel + 2 pages + 2 soporte:
- `src/features/teams/components/{OrgSwitcher,MembersList,InviteMemberForm,PendingInvitations,RoleSelect}.tsx`
- `src/features/teams/components/index.ts`
- `src/app/(app)/settings/teams/page.tsx`  (incluye OrgSettings inline: rename + zona peligrosa)
- `src/app/invite/[token]/page.tsx`
- `src/hooks/useOrganization.ts`
- `src/lib/teams/queries.ts`

## Citations

- [memory:CONSTRAINTS.md#R10] · [memory:CONSTRAINTS.md#R14] · [memory:CONSTRAINTS.md#R16] · [memory:CONSTRAINTS.md#R13]
- [memory:lessons#L-005] · [memory:lessons#L-003] · [memory:lessons#L-002]
- [memory:references#R-005]
- [docs:supabase-ssr] · [docs:nextjs] · [docs:react]
