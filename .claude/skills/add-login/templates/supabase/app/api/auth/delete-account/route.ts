// Delete account route. R14 enforced — typed confirmation required.
//
// Patrón:
// 1. UI presenta input "Para confirmar, escribí: DELETE my account".
// 2. Cliente POST con body { confirmation: "DELETE my account" }.
// 3. Server valida string match exacto antes de proceder.
// 4. NO se exporta como agentic tool con execute() automático — solo HTTP route
//    consumida explícitamente desde UI con confirmation gate.
//
// Cita:
// - [memory:CONSTRAINTS.md#R14]
// - [docs:supabase-js] (auth.admin.deleteUser requiere service_role)
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

const REQUIRED_CONFIRMATION = 'DELETE my account';

export async function POST(request: Request) {
  let body: { confirmation?: unknown } = {};
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: 'Invalid request body' },
      { status: 400 },
    );
  }

  if (typeof body.confirmation !== 'string' || body.confirmation !== REQUIRED_CONFIRMATION) {
    return NextResponse.json(
      { error: `Confirmation phrase mismatch. Type exactly: "${REQUIRED_CONFIRMATION}"` },
      { status: 400 },
    );
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: getUserError,
  } = await supabase.auth.getUser();

  if (getUserError || !user) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
  }

  // R14: la operación destructiva ocurre solo después del confirmation gate.
  // service_role aplicado en server-only admin client.
  const admin = createAdminClient();
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);

  if (deleteError) {
    return NextResponse.json({ error: deleteError.message }, { status: 500 });
  }

  await supabase.auth.signOut();

  return NextResponse.json({ ok: true }, { status: 200 });
}

// Explicit: NO exportar como agentic tool con execute() async automático.
// R14 requiere humano-in-the-loop para destructivas.
