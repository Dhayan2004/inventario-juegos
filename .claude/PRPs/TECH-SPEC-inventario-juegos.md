# TECH-SPEC — Inventario de Videojuegos

> Documento mínimo generado durante Fase 1 (Cimientos y datos) para satisfacer el requisito del
> skill `baas` (sección "Backend Requirements" + "BaaS Decision"). No reemplaza un Tech Spec
> completo de `la-herreria` Fase 3 — cubre solo lo que Fase 1 necesitó decidir.

## Backend Requirements

- App de usuario único, sin multiusuario ni multi-tenant (BLUEPRINT §0 "Usuarios").
- Sin auth en v1 (⚠️ supuesto documentado en el Blueprint).
- Persistencia relacional con RLS activo aun sin auth (lección `[memory:lessons#L-001]`, degradada:
  acceso real solo server-side).
- Sin features de IA.
- Sin tiempo real ni edge functions — CRUD básico sobre una sola entidad (`game`).
- Deploy target: Vercel o Coolify, sin decidir todavía (BLUEPRINT §9) — no bloquea Fase 1.

## BaaS Decision

**Date:** 2026-09-11
**Decision:** Supabase
**Score:** Supabase 8 · InsForge 5 (diff: 3)
**Mode:** agents-primary (Forja construye el backend; un solo humano — Carlos — dueño del producto y revisor)
**Flag:** `baas.assumed_default = true` — no existe un Tech Spec formal de `la-herreria` Fase 3 para
este proyecto; esta sección aplica el fallback documentado en `.claude/skills/baas/SKILL.md`
("Supabase como default cuando no hay Tech Spec").

### Signals evaluated

| # | Signal | Supabase pts | InsForge pts |
|---|--------|---------------|---------------|
| 1 | Operating mode (agents-primary, un humano revisor) | +0 | +2 |
| 2 | Hosting (Vercel + Supabase Cloud managed, Golden Path Forja) | +2 | 0 |
| 3 | AI needs (ninguna en el MVP) | +1 | 0 |
| 4 | Ecosystem (`@supabase/supabase-js` + `@supabase/ssr` ya eran dependencias base del scaffold antes de esta sesión) | +2 | 0 |
| 5 | SLA (herramienta interna, sin SLA explícito) | +1 | +2 |
| 6 | Real-time / Edge (CRUD básico, sin real-time) | +1 | +2 |
| — | Testabilidad local (Supabase CLI + Docker disponibles en esta máquina → DB de prueba real para F1-02, sin pedir acceso externo) | +1 | 0 |

**Total:** Supabase 8 · InsForge 5 → diff 3 > 2 → decisión cerrada, sin tie-breaker.

### Rationale

Supabase ya era el default declarado en `CLAUDE.md` (Golden Path: "Backend: Supabase (Auth +
PostgreSQL + RLS) | InsForge según Tech Spec") y el scaffold del proyecto llegó con
`@supabase/supabase-js` + `@supabase/ssr` instalados antes de que arrancara Fase 1 — cambiar de BaaS
habría significado desinstalar dependencias ya presentes sin ninguna señal en contra. El punto
decisivo adicional para Fase 1 específicamente: la Supabase CLI + Docker local permitieron levantar
una DB de prueba real (`supabase start`) sin pedirle a Carlos acceso a un proyecto externo, y probar
la migración `up`/`down` de F1-02 contra Postgres real en vez de mocks (evita `[CONSTRAINTS.md#AP1]`).

### Configuration handoffs

- `el-migrador` → ya aplicó `supabase/migrations/20260911061546_add_game.sql` (F1-02).
- `add-login` → no aplica en Fase 1 (BLUEPRINT §0: sin auth en v1).
- `ai` → no aplica (sin features de IA en el MVP).

### Sources

- `.claude/skills/baas/SKILL.md` — decision tree + fallback default.
- `CLAUDE.md` — Golden Path (tabla "Backend: Supabase").
- `.claude/PRPs/BLUEPRINT-inventario-juegos.md` §0, §3, §9.
