import { z } from "zod";

/**
 * Whitelist de campos de `game` (lección L-003): cada boundary externo valida
 * contra un schema cerrado (`.strict()`), nunca `z.record(z.any())`. Los enums
 * espejan los `check` constraints de la migración 20260911061546_add_game.sql —
 * BLUEPRINT §3.
 */
export const GAME_PLATFORMS = [
  "PC",
  "PlayStation",
  "Xbox",
  "Nintendo Switch",
  "Retro",
  "Otro",
] as const;

export const GAME_STATUSES = [
  "owned",
  "wishlist",
  "playing",
  "completed",
  "abandoned",
] as const;

export const GAME_FORMATS = ["physical", "digital"] as const;

/** Token de confirmación tipada para el borrado (R14) — mismo texto que §4.3. */
export const DELETE_CONFIRMATION_TOKEN = "ELIMINAR";

const isoDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "purchase_date debe ser YYYY-MM-DD");

export const gameCreateSchema = z
  .object({
    title: z.string().trim().min(1, "title es requerido"),
    platform: z.enum(GAME_PLATFORMS),
    genre: z.string().trim().min(1).optional(),
    status: z.enum(GAME_STATUSES).default("owned"),
    format: z.enum(GAME_FORMATS).optional(),
    quantity: z.number().int().min(1).default(1),
    purchase_price: z.number().min(0).optional(),
    purchase_date: isoDate.optional(),
    rating: z.number().int().min(1).max(10).optional(),
    notes: z.string().trim().min(1).optional(),
  })
  .strict();

export const gameUpdateSchema = gameCreateSchema.partial().strict();

export const gameDeleteSchema = z
  .object({
    id: z.string().uuid(),
    confirmation: z.literal(DELETE_CONFIRMATION_TOKEN),
  })
  .strict();

export type GameCreateInput = z.infer<typeof gameCreateSchema>;
export type GameUpdateInput = z.infer<typeof gameUpdateSchema>;
export type GameDeleteInput = z.infer<typeof gameDeleteSchema>;

export interface Game {
  id: string;
  title: string;
  platform: (typeof GAME_PLATFORMS)[number];
  genre: string | null;
  status: (typeof GAME_STATUSES)[number];
  format: (typeof GAME_FORMATS)[number] | null;
  quantity: number;
  purchase_price: number | null;
  purchase_date: string | null;
  rating: number | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}
