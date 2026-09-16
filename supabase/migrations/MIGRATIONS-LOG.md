# Migrations log — audit trail (append-only)

## 20260911061546 — add_game

**Date applied:** 2026-09-11 (local)
**Target:** local
**Feature:** F1-02 (branch `feat/f1-cimientos-datos`)
**Commit:** pending (not yet committed)
**Tables affected:** `public.game`
**RLS coverage:** ✅ enabled + 2 deny-all policies (`anon`, `authenticated`) — single-user app sin auth (L-001 degradado: acceso real solo server-side vía service role key)
**Security review:** N/A (no toca `auth.users`, no grants públicos, no `security definer` con lógica de negocio — solo un trigger `security invoker` para `updated_at`)
**Rollback file:** `supabase/rollbacks/20260911061546_add_game.rollback.sql`
**Verificado:** `supabase db reset` (up) + rollback aplicado a mano vía psql contra la DB local (down) + `supabase db reset` de nuevo para restaurar estado migrado. Both directions limpias, sin residuos (`\d public.game` confirma ausencia de la tabla tras el rollback).
