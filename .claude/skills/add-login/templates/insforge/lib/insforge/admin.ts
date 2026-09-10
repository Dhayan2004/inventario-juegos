// Server-only Insforge admin client (uses INSFORGE_SECRET_KEY).
// NEVER import from client/components/app/(auth) pages.
// Solo accesible desde:
// - app/api/auth/delete-account/route.ts (con confirmation gate, R14)
//
// Cita: [memory:CONSTRAINTS.md#R14] [docs:insforge]
import { createAdminClient as createInsforgeAdmin } from '@insforge/sdk';

export function createAdminClient() {
  return createInsforgeAdmin(
    process.env.NEXT_PUBLIC_INSFORGE_URL!,
    process.env.INSFORGE_SECRET_KEY!,
  );
}
