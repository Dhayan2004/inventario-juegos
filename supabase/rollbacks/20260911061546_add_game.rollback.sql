-- 20260911061546_add_game.rollback.sql
-- Revierte 20260911061546_add_game.sql en orden inverso.

drop policy if exists "game_deny_all_authenticated" on public.game;
drop policy if exists "game_deny_all_anon" on public.game;

drop trigger if exists game_set_updated_at on public.game;
drop function if exists public.set_game_updated_at();

drop index if exists public.game_created_at_idx;
drop index if exists public.game_status_idx;
drop index if exists public.game_platform_idx;

drop table if exists public.game;
