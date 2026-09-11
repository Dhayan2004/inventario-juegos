import { createClient } from "@supabase/supabase-js";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { createServiceClient } from "@/shared/lib/supabase/service-client";

/**
 * F1-02 — verifica la migración 20260911061546_add_game.sql contra la DB local
 * real (Supabase CLI, Docker): la tabla existe con los campos de BLUEPRINT §3,
 * sus constraints rechazan datos inválidos a nivel DB, y RLS bloquea acceso
 * directo del cliente (anon/authenticated) dejando solo el service role.
 */
describe("game-migration", () => {
  const service = createServiceClient();
  const TEST_TITLE_PREFIX = "__test_migration__";

  beforeAll(() => {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!url || !anonKey) {
      throw new Error(
        "Faltan NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY — corre 'supabase start' primero."
      );
    }
  });

  afterEach(async () => {
    await service.from("game").delete().like("title", `${TEST_TITLE_PREFIX}%`);
  });

  it("crea la tabla game con los campos requeridos y sus defaults", async () => {
    const { data, error } = await service
      .from("game")
      .insert({ title: `${TEST_TITLE_PREFIX}minimal`, platform: "PC" })
      .select()
      .single();

    expect(error).toBeNull();
    expect(data).toMatchObject({
      title: `${TEST_TITLE_PREFIX}minimal`,
      platform: "PC",
      status: "owned",
      quantity: 1,
    });
    expect(data!.id).toBeTruthy();
    expect(data!.created_at).toBeTruthy();
    expect(data!.updated_at).toBeTruthy();
  });

  it("rechaza platform fuera del enum a nivel DB", async () => {
    const { error } = await service
      .from("game")
      .insert({ title: `${TEST_TITLE_PREFIX}bad-platform`, platform: "SegaSaturn" });

    expect(error).not.toBeNull();
    expect(error!.message).toMatch(/game_platform_check/);
  });

  it("rechaza quantity < 1 a nivel DB", async () => {
    const { error } = await service
      .from("game")
      .insert({ title: `${TEST_TITLE_PREFIX}bad-qty`, platform: "PC", quantity: 0 });

    expect(error).not.toBeNull();
    expect(error!.message).toMatch(/game_quantity_check/);
  });

  it("rechaza rating fuera de 1-10 a nivel DB", async () => {
    const { error } = await service
      .from("game")
      .insert({ title: `${TEST_TITLE_PREFIX}bad-rating`, platform: "PC", rating: 11 });

    expect(error).not.toBeNull();
    expect(error!.message).toMatch(/game_rating_check/);
  });

  it("actualiza updated_at automáticamente en cada edición", async () => {
    const { data: created } = await service
      .from("game")
      .insert({ title: `${TEST_TITLE_PREFIX}touch`, platform: "PC" })
      .select()
      .single();

    await new Promise((resolve) => setTimeout(resolve, 10));

    const { data: updated, error } = await service
      .from("game")
      .update({ notes: "actualizado" })
      .eq("id", created!.id)
      .select()
      .single();

    expect(error).toBeNull();
    expect(new Date(updated!.updated_at).getTime()).toBeGreaterThan(
      new Date(created!.updated_at).getTime()
    );
  });

  it("RLS bloquea lectura/escritura directa con la anon key", async () => {
    const anon = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      { auth: { persistSession: false } }
    );

    const { data: rows, error: selectError } = await anon.from("game").select("*");
    expect(selectError).toBeNull();
    expect(rows).toEqual([]);

    const { error: insertError } = await anon
      .from("game")
      .insert({ title: `${TEST_TITLE_PREFIX}anon-insert`, platform: "PC" });
    expect(insertError).not.toBeNull();
  });
});
