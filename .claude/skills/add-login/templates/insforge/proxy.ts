// Next.js 16 proxy.ts (Insforge variant).
//
// Cita: [docs:nextjs]
import { type NextRequest } from 'next/server';
import { updateSession } from '@/lib/insforge/proxy';

export async function proxy(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
