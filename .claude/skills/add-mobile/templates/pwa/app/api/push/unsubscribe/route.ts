/**
 * DELETE /api/push/unsubscribe
 *
 * Auth required. RLS enforces ownership automatically.
 *
 * Cita: [memory:lessons#L-001] (RLS) · [memory:lessons#L-003]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';

const UnsubscribeSchema = z.object({
  endpoint: z.string().url().max(500),
});

export async function DELETE(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();
  const parsed = UnsubscribeSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid' },
      { status: 400 }
    );
  }

  // RLS ensures user can only delete own subs
  await supabase
    .from('push_subscriptions')
    .delete()
    .eq('endpoint', parsed.data.endpoint)
    .eq('user_id', user.id);

  return NextResponse.json({ success: true });
}
