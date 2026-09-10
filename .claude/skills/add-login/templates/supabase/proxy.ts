// Next.js 16 proxy.ts (Node.js runtime). En Next.js 14-15 este archivo se
// llama middleware.ts; el shape de la función + matcher es similar pero
// proxy.ts corre en Node runtime, no Edge. Por defecto Forja apunta a 16.
//
// Cita: [docs:nextjs]
import { type NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/proxy';

export async function proxy(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
