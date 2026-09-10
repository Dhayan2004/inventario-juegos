# Examples — 3 golpes canónicos

> Cada ejemplo muestra input → brief plan visible → user confirms "go" → execute one-shot → verify → 1-3 atomic commits. Pattern reconocible para sub-agents y humanos.

## Escenario 1 — Implementar flujo invitar miembros

**Input:** "Agregá flujo de invitar miembros al team: form en `/team`, endpoint POST, email template, tabla invitations con RLS."

**PREFLIGHT:**
- ✅ Active feature: F3-S? (assume team-features)
- ✅ Feature toca UI → brand.json existe
- ✅ Tests + lint passing

**Brief plan emitido:**

```markdown
## Brief plan: invitar miembros al team

**Active feature:** F3-S?
**R10:** SÍ (form consume brand tokens)
**L-001:** SÍ (tabla invitations con user_id)
**L-003:** SÍ (validators en form + endpoint)

**Archivos afectados:**
- `.claude/migrations/0005_invitations.sql` — tabla + RLS L-001 + indexes
- `app/api/invite/route.ts` — POST endpoint con Zod whitelist
- `lib/invite/sendInviteEmail.ts` — Resend send con InviteEmail template
- `lib/invite/InviteEmail.tsx` — React Email template heredado de voice.json
- `app/(app)/team/InviteForm.tsx` — form con react-hook-form + Zod, consume brand

**Approach:**
- 5 archivos. Resend ya instalado por add-emails. RLS L-001 enforced en tabla.
- Form invoca impeccable Card + Input + Button (R10 enforcement vía sub-agent).
- Webhook delivery NO en este golpe (escalate si necesario).

**Sub-skills invocados:**
- el-migrador (para migration nueva)
- impeccable (para Card/Input/Button consuming brand)

**Verification:**
- typecheck: `tsc --noEmit`
- tests: `npm test -- --findRelatedTests app/api/invite app/(app)/team lib/invite`
- visual: `/team` → click "Invitar" → email recibido en bandeja test

**Estimación:**
- Wallclock: ~25min
- Commits: 3 (schema + lib/api + UI)

**Tu turno:** "go" / "ajustá X" / "escalá"
```

**Usuario:** "go"

**Execute one-shot:**

1. Sub-agent invoca el-migrador → migration `0005_invitations.sql` creada con RLS L-001.
2. Sub-agent crea `lib/invite/InviteEmail.tsx` + `lib/invite/sendInviteEmail.ts`.
3. Sub-agent crea `app/api/invite/route.ts` con Zod validators (L-003: `email().max(254)`, no `z.record`).
4. Sub-agent invoca impeccable → genera `InviteForm.tsx` consuming Card/Input/Button.

**Verify:**
- typecheck PASS
- tests relevantes PASS
- visual check `/team` → form renderea con brand colors, email enviado a bandeja test

**Commits:**

```
feat(F3-S?): add invitations table with RLS L-001

Migration 0005 creates invitations(id, email, inviter_id, accepted_at).
RLS policies: inviter sees own + invitee sees if invited.
Cite: [memory:lessons#L-001]
```

```
feat(F3-S?): add invite endpoint and email lib

- lib/invite/InviteEmail.tsx (React Email template, hereda voice.json)
- lib/invite/sendInviteEmail.ts (Resend wrapper)
- app/api/invite/route.ts (POST con Zod whitelist L-003)
```

```
feat(F3-S?): add InviteForm UI consuming brand tokens

InviteForm uses Card + Input + Button from impeccable.
Form validation with react-hook-form + Zod schema mirroring API.
```

**Golpe done.** 3 commits, ~22min wallclock real, 5 archivos, verification PASS.

---

## Escenario 2 — Dashboard 4 KPIs admin

**Input:** "Implementá dashboard admin con 4 cards: Total Users, MRR, Churn 30d, Signups This Week."

**PREFLIGHT:**
- ✅ Active feature: F3-S? (assume admin-features)
- ✅ Feature toca UI → brand.json existe (Card variant declarado)
- ✅ Tests + lint passing

**Brief plan emitido:**

```markdown
## Brief plan: admin dashboard 4 KPIs

**Active feature:** F3-S?
**R10:** SÍ (4 Cards consume brand)
**L-003:** SÍ (admin role check)

**Archivos afectados:**
- `app/(admin)/dashboard/page.tsx` — Server Component, 4 KPI cards
- `lib/queries/admin-stats.ts` — 4 funciones SQL via supabase admin client
- `app/(admin)/layout.tsx` — admin role guard (existing, solo verificar)

**Approach:**
- 2 archivos nuevos + 1 verificación. Sub-agent invoca impeccable Card BATCH.
- Queries usan service_role (admin.ts existing). Cada query memoizada con
  `revalidate: 300` (5min cache).
- NO real-time updates (escalate si necesario).

**Sub-skills invocados:**
- impeccable (Card variant existing)

**Verification:**
- typecheck: `tsc --noEmit`
- tests: `npm test -- --findRelatedTests app/(admin)/dashboard lib/queries`
- visual: `/admin/dashboard` → 4 cards renderean con datos reales

**Estimación:**
- Wallclock: ~18min
- Commits: 2 (queries + UI)

**Tu turno:** "go"
```

**Usuario:** "go"

**Execute:**

1. Crear `lib/queries/admin-stats.ts` con 4 funciones (queries SQL paramétricas).
2. Sub-agent invoca impeccable → confirma Card variant existing.
3. Crear `app/(admin)/dashboard/page.tsx` Server Component con 4 cards.
4. Verificar admin guard en `app/(admin)/layout.tsx` (no modificación).

**Verify:**
- typecheck PASS
- tests PASS
- visual `/admin/dashboard` → 4 cards con números reales, layout grid 2x2 responsive.

**Commits:**

```
feat(F3-S?): add admin stats queries

lib/queries/admin-stats.ts:
- getTotalUsers, getMRR, getChurn30d, getSignupsThisWeek
- All use service_role (admin.ts), revalidate: 300.
```

```
feat(F3-S?): add admin dashboard with 4 KPI cards

app/(admin)/dashboard/page.tsx Server Component.
4 Cards from impeccable consuming admin-stats queries.
Grid 2x2 desktop, 1col mobile.
```

**Golpe done.** 2 commits, ~16min wallclock, verification PASS.

---

## Escenario 3 — Auth flow simple (login con email + password)

**Input:** "Implementá login form simple con email + password en `/sign-in`. Supabase auth ya está configurado por add-login."

**PREFLIGHT:**
- ✅ Active feature: F3-S? (assume auth-tweak)
- ✅ Feature toca UI → brand.json existe
- ✅ Tests + lint passing
- ⚠️ add-login ya generó el form completo previamente. ¿Por qué un golpe?
  → Usuario quiere customizar el form (ej: agregar "Recordar email" checkbox o
    integrar con Magic Link toggle).

**Brief plan emitido (ajustado al scope real):**

```markdown
## Brief plan: customizar SignInForm con "Recordar email" checkbox

**Active feature:** F3-S?
**R10:** SÍ (form consume brand)
**L-003:** SÍ (email validator)

**Archivos afectados:**
- `app/(auth)/sign-in/SignInForm.tsx` — agregar checkbox + localStorage logic
- `lib/auth/rememberEmail.ts` — helper get/set localStorage (nuevo file)

**Approach:**
- 2 archivos. Form ya existe (generado por add-login).
- Checkbox usa Input variant existing. localStorage en client component
  con `'use client'`.
- localStorage NO contiene password (solo email para autocomplete).

**Verification:**
- typecheck: `tsc --noEmit`
- tests: `npm test -- --findRelatedTests app/(auth)/sign-in`
- visual: `/sign-in` → checkear checkbox → reload → email pre-filled.

**Estimación:**
- Wallclock: ~10min
- Commits: 1 (cambio compacto)

**Tu turno:** "go"
```

**Usuario:** "go"

**Execute:**

1. Crear `lib/auth/rememberEmail.ts` con `getRememberedEmail()` + `setRememberedEmail()`.
2. Editar `app/(auth)/sign-in/SignInForm.tsx`:
   - Importar helper.
   - Agregar `<Checkbox>` consuming brand variant.
   - useEffect: pre-fill email si exists.
   - onSubmit: si checked, persistir email.

**Verify:**
- typecheck PASS
- tests PASS
- visual `/sign-in` → flow PASS

**Commit:**

```
feat(F3-S?): add "Remember email" checkbox to SignInForm

SignInForm now persists email in localStorage when checkbox checked.
NO password persistence (security). Pre-fills email on next visit.
```

**Golpe done.** 1 commit, ~9min wallclock, 2 archivos, verification PASS.

---

## Anti-pattern observable: golpe escalado a /build

**Input:** "Implementá auth completo con email/password + Google OAuth + magic link + RBAC + audit log."

**Brief intentado:**

```markdown
## Brief plan: auth completo + RBAC + audit log

**Archivos afectados:**
- 9 archivos (lib/supabase + middleware + 4 pages + actions + RBAC + audit)
...
```

**Mientras escribía el brief detecté:**
- 9 archivos > límite 5 ideal de golpe.
- Wallclock realista: ~90min (auth + RBAC + audit).
- 4-5 commits naturales (lib + middleware + pages + RBAC + audit).
- Multi-domain: auth + access control + observability.

**Output al usuario:**

```markdown
## Golpe escalation → /build (la-forja)

**Razón:**
- Scope estimado: ~90min wallclock, 9 archivos, 4-5 commits.
- Excede criterios golpe (<30min, ≤5 archivos, ≤3 commits).
- Multi-domain: auth + RBAC + audit log requieren planning formal.

**Próximo paso:**
→ Invocá `/build` (la-forja). la-forja seleccionará pattern apropiado
  (probable Coordinator dado dependencias secuenciales: auth → RBAC → audit).

NO es escalación negativa — es match correcto del skill al scope.
```

NO se ejecuta el cambio. el-golpe solo escala. la-forja Coordinator/Fork/Swarm ejecuta.

---

## Tabla resumen — los 3 escenarios + anti-pattern

| Escenario | Outcome | Wallclock | Archivos | Commits | Sub-skills | R10 | L-001 | L-003 |
|-----------|---------|-----------|----------|---------|------------|-----|-------|-------|
| 1: Invitar miembros | done | 22min | 5 | 3 | el-migrador, impeccable | ✓ | ✓ | ✓ |
| 2: Admin dashboard 4 KPIs | done | 16min | 2 | 2 | impeccable | ✓ | — | ✓ (admin guard) |
| 3: Remember email checkbox | done | 9min | 2 | 1 | — | ✓ | — | ✓ |
| Anti: auth + RBAC + audit | escalated | 90min est | 9 | 4-5 | N/A | N/A | N/A | N/A |

## Citation grammar

- [memory:CONSTRAINTS.md#R2] — atomic commits cierre.
- [memory:CONSTRAINTS.md#R10] — brand contract en escenarios 1-3.
- [memory:lessons#L-001] — escenario 1 invitations table.
- [memory:lessons#L-003] — escenarios 1, 2, 3 todos validators.
- [memory:decisions#D-017] — binary shape (execute / escalate-graceful).
