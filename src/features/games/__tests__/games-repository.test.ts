import { afterEach, describe, expect, it } from "vitest";
import { ZodError } from "zod";
import { createServiceClient } from "@/shared/lib/supabase/service-client";
import {
  createGame,
  deleteGame,
  getGame,
  listGames,
  updateGame,
} from "@/features/games/repository";
import { DELETE_CONFIRMATION_TOKEN } from "@/features/games/schema";

/**
 * F1-03 — capa de acceso a datos de `game` contra la DB local real: alta,
 * listado, obtención, edición y borrado, con whitelist (L-003) y confirmación
 * tipada de borrado (R14).
 */
describe("games-repository", () => {
  const service = createServiceClient();
  const TEST_TITLE_PREFIX = "__test_repo__";

  afterEach(async () => {
    await service.from("game").delete().like("title", `${TEST_TITLE_PREFIX}%`);
  });

  it("crea un juego con payload válido y lo persiste", async () => {
    const game = await createGame({
      title: `${TEST_TITLE_PREFIX}zelda`,
      platform: "Nintendo Switch",
      status: "playing",
      quantity: 1,
    });

    expect(game.id).toBeTruthy();
    expect(game.title).toBe(`${TEST_TITLE_PREFIX}zelda`);

    const fetched = await getGame(game.id);
    expect(fetched?.id).toBe(game.id);
  });

  it("rechaza un campo fuera de whitelist antes de tocar la DB", async () => {
    await expect(
      createGame({
        title: `${TEST_TITLE_PREFIX}mass-assignment`,
        platform: "PC",
        is_admin: true,
      })
    ).rejects.toThrow(ZodError);

    const games = await listGames();
    expect(games.find((g) => g.title === `${TEST_TITLE_PREFIX}mass-assignment`)).toBeUndefined();
  });

  it("rechaza quantity < 1 en el boundary de validación", async () => {
    await expect(
      createGame({ title: `${TEST_TITLE_PREFIX}qty`, platform: "PC", quantity: 0 })
    ).rejects.toThrow(ZodError);
  });

  it("rechaza rating fuera de 1-10 en el boundary de validación", async () => {
    await expect(
      createGame({ title: `${TEST_TITLE_PREFIX}rating`, platform: "PC", rating: 99 })
    ).rejects.toThrow(ZodError);
  });

  it("lista los juegos creados", async () => {
    await createGame({ title: `${TEST_TITLE_PREFIX}list-a`, platform: "PC" });
    await createGame({ title: `${TEST_TITLE_PREFIX}list-b`, platform: "Xbox" });

    const games = await listGames();
    const titles = games.map((g) => g.title);
    expect(titles).toContain(`${TEST_TITLE_PREFIX}list-a`);
    expect(titles).toContain(`${TEST_TITLE_PREFIX}list-b`);
  });

  it("actualiza un juego existente", async () => {
    const game = await createGame({ title: `${TEST_TITLE_PREFIX}edit`, platform: "PC" });
    const updated = await updateGame(game.id, { status: "completed", rating: 9 });

    expect(updated.status).toBe("completed");
    expect(updated.rating).toBe(9);
  });

  it("R14 — deleteGame sin el token de confirmación no ejecuta el borrado", async () => {
    const game = await createGame({ title: `${TEST_TITLE_PREFIX}guarded`, platform: "PC" });

    await expect(deleteGame({ id: game.id, confirmation: "borrar" })).rejects.toThrow(ZodError);
    await expect(deleteGame({ id: game.id })).rejects.toThrow(ZodError);

    const stillThere = await getGame(game.id);
    expect(stillThere).not.toBeNull();
  });

  it("R14 — deleteGame con el token correcto elimina el registro", async () => {
    const game = await createGame({ title: `${TEST_TITLE_PREFIX}delete-me`, platform: "PC" });

    await deleteGame({ id: game.id, confirmation: DELETE_CONFIRMATION_TOKEN });

    const gone = await getGame(game.id);
    expect(gone).toBeNull();
  });
});
