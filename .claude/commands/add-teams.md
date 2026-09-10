---
description: "Gestión de tenants drop-in (orgs/invitaciones/roles owner-admin-member) sobre la fundación M6 — migración 0005_teams + UI R10 + handoff a el-guardian (add-teams)."
---

# /add-teams

Lee y ejecuta `.claude/skills/add-teams/SKILL.md`.

`add-teams` pone la **cara de la gestión de equipo** sobre la fundación multi-tenant de M6
(`0000_tenancy.sql`): organizaciones, invitaciones por email con token, roles `owner`/`admin`/`member`,
transferencia de propiedad y zona peligrosa. Trae la migración `0005_teams.sql` (anti-escalación de
privilegios + `accept_invitation()` + `transfer_org_ownership()` definer owner-only + `guard_last_owner`),
server actions con R14 + L-003, y UI R10 vía `impeccable` (Button/Input/Select/Card/ConfirmModal + copy
de `voice.json`). NO reescribe la fundación — la **extiende**.

**Pre-requisitos (PREFLIGHT halt):**
- App **multi-tenant** (`tenant_model.multi_tenant: true`). Single-tenant → halt (gobierna L-001).
- Fundación `0000_tenancy.sql` aplicada — sin esto halt + handoff a `el-migrador`.
- `add-login` corrió (auth + `auth.users`) — sin esto halt + handoff a `add-login`.
- Brand DNA (`brand/brand.json` + `voice.json`) + componentes `impeccable` (Button/Input/Select/Card/ConfirmModal).

**Reglas duras:** R16 (aislamiento de tenant, enforce en Postgres) · R14 (destructivas con confirmación
tipada, sin `execute()` agentic) · L-003 (Zod por field) · R10 (UI vía impeccable) · R18 (GitHub es espejo
de una sola vía: nada marca `passing` desde un Issue).

**Mandatorio post-gen:** handoff a `el-guardian` (persona **El Infiltrado**) + R7 Layer 4 (test negativo
`0005_teams-isolation.test.sql`, los 5 T-TEAM-* verdes sobre Postgres real). Deploy bloqueado hasta PASS.
