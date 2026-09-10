// Delete account route (Insforge variant). R14 typed-confirmation gate.
//
// Cita: [memory:CONSTRAINTS.md#R14] [docs:insforge]
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/insforge/server';
import { createAdminClient } from '@/lib/insforge/admin';

const REQUIRED_CONFIRMATION = 'DELETE my account';

export async function POST(request: Request) {
  let body: { confirmation?: unknown } = {};
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
  }

  if (typeof body.confirmation !== 'string' || body.confirmation !== REQUIRED_CONFIRMATION) {
    return NextResponse.json(
      { error: `Confirmation phrase mismatch. Type exactly: "${REQUIRED_CONFIRMATION}"` },
      { status: 400 },
    );
  }

  const insforge = await createClient();
  const {
    data: { user },
    error: getUserError,
  } = await insforge.auth.getUser();

  if (getUserError || !user) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
  }

  const admin = createAdminClient();
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);

  if (deleteError) {
    return NextResponse.json({ error: deleteError.message }, { status: 500 });
  }

  await insforge.auth.signOut();

  return NextResponse.json({ ok: true }, { status: 200 });
}

// R14: NO exportar como agentic tool con execute() async.
