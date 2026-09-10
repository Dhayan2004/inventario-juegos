/**
 * POST /api/push/register-native (Mode B)
 *
 * Registra FCM/APNs token desde Capacitor (paralelo a /api/push/subscribe del Mode A).
 *
 * Cita: [memory:lessons#L-001] · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

const RegisterSchema = z.object({
  userId: z.string().uuid(),
  token: z.string().min(1).max(500),
  platform: z.enum(['ios', 'android', 'web']),
  app_version: z.string().max(32).optional(),
});

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();
  const parsed = RegisterSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid' },
      { status: 400 }
    );
  }

  // Verificar que userId del payload coincide con el authenticated user
  if (parsed.data.userId !== user.id) {
    return NextResponse.json({ error: 'User mismatch' }, { status: 403 });
  }

  const admin = createAdminClient();

  // UPSERT en native_push_tokens (paralela a push_subscriptions)
  const { data, error } = await admin
    .from('native_push_tokens')
    .upsert(
      {
        user_id: user.id,
        token: parsed.data.token,
        platform: parsed.data.platform,
        app_version: parsed.data.app_version ?? null,
        last_used_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,token' }
    )
    .select('id')
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true, token_id: data.id });
}
