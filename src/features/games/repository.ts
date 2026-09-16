import { createServiceClient } from "@/shared/lib/supabase/service-client";
import {
  gameCreateSchema,
  gameDeleteSchema,
  gameIdSchema,
  gameUpdateSchema,
  type Game,
} from "./schema";

/**
 * Capa de acceso a datos de `game` (F1-03, BLUEPRINT §3).
 *
 * Server-only: usa el service role client (RLS deny-all para anon/authenticated,
 * ver migración 20260911061546_add_game.sql). Cada función parsea su input contra
 * el schema whitelist (L-003) antes de tocar la DB — un campo fuera de whitelist,
 * o un valor fuera de rango, nunca llega a Supabase.
 */

export async function createGame(input: unknown): Promise<Game> {
  const payload = gameCreateSchema.parse(input);
  const client = createServiceClient();

  const { data, error } = await client
    .from("game")
    .insert(payload)
    .select()
    .single();

  if (error) throw new Error(`createGame: ${error.message}`);
  return data as Game;
}

export async function listGames(): Promise<Game[]> {
  const client = createServiceClient();

  const { data, error } = await client
    .from("game")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) throw new Error(`listGames: ${error.message}`);
  return (data ?? []) as Game[];
}

export async function getGame(id: string): Promise<Game | null> {
  const validId = gameIdSchema.parse(id);
  const client = createServiceClient();

  const { data, error } = await client
    .from("game")
    .select("*")
    .eq("id", validId)
    .maybeSingle();

  if (error) throw new Error(`getGame: ${error.message}`);
  return (data as Game | null) ?? null;
}

export async function updateGame(id: string, input: unknown): Promise<Game> {
  const validId = gameIdSchema.parse(id);
  const payload = gameUpdateSchema.parse(input);
  const client = createServiceClient();

  const { data, error } = await client
    .from("game")
    .update(payload)
    .eq("id", validId)
    .select()
    .single();

  if (error) throw new Error(`updateGame: ${error.message}`);
  return data as Game;
}

/**
 * Borrado con confirmación tipada (R14): `gameDeleteSchema` exige
 * `confirmation === "ELIMINAR"`. Sin el token exacto, `.parse()` lanza antes de
 * ejecutar ningún DELETE — no hay `execute()` automático posible.
 */
export async function deleteGame(input: unknown): Promise<void> {
  const { id } = gameDeleteSchema.parse(input);
  const client = createServiceClient();

  const { error } = await client.from("game").delete().eq("id", id);

  if (error) throw new Error(`deleteGame: ${error.message}`);
}
