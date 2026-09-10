// Browser Insforge client. Public key only (safe to expose).
// NEVER import INSFORGE_SECRET_KEY here.
//
// Cita: [docs:insforge] [memory:CONSTRAINTS.md#R10]
import { createBrowserClient } from '@insforge/sdk';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_INSFORGE_URL!,
    process.env.NEXT_PUBLIC_INSFORGE_PUBLIC_KEY!,
  );
}
