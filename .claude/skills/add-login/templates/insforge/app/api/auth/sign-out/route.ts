// Sign-out route (Insforge variant). POST-only. R14 reminder for global sign-out.
//
// Cita: [docs:insforge] [memory:CONSTRAINTS.md#R14]
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/insforge/server';

export async function POST(request: Request) {
  const insforge = await createClient();
  const { origin } = new URL(request.url);

  await insforge.auth.signOut();

  return NextResponse.redirect(`${origin}/sign-in`, { status: 303 });
}
