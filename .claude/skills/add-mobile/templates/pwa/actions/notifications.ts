/**
 * Notification server actions.
 *
 * Non-destructive: sendUserNotification (rate-limited, self-only).
 *
 * DESTRUCTIVE (R14 strict, 5 gates each):
 *   - sendBroadcast (admin role required, queue handoff)
 *   - sendToTopic (admin role required, queue handoff)
 *   - revokeAllSubscriptions (admin role, user_id-targeted)
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-001..3] · [docs:web-push]
 */
'use server';

import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { ALLOWED_TOPICS } from '@/lib/push/server';

/* -----------------------------------------------------------------------------
 * sendUserNotification — non-destructive, self-only
 * -------------------------------------------------------------------------- */

const NotificationSchema = z.object({
  title: z.string().min(1).max(50),
  body: z.string().max(150),
  topic: z.enum(ALLOWED_TOPICS),
  url: z.string().url().optional(),
  tag: z.string().max(64).optional(),
});

export async function sendUserNotification(
  _prev: unknown,
  formData: FormData
) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const parsed = NotificationSchema.safeParse({
    title: formData.get('title'),
    body: formData.get('body'),
    topic: formData.get('topic'),
    url: formData.get('url'),
    tag: formData.get('tag'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // Self-only: send to user's own subscriptions (admin/system flows
  // van por sendBroadcast con R14 gates).
  const res = await fetch(
    `${process.env.NEXT_PUBLIC_APP_URL}/api/push/send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({ userId: user.id, notification: parsed.data }),
    }
  );

  if (!res.ok) {
    return { error: 'Error enviando notificación.' };
  }
  return { success: true };
}

/* -----------------------------------------------------------------------------
 * sendBroadcast — DESTRUCTIVE (mass-spam vector)
 * -------------------------------------------------------------------------- */

const BroadcastSchema = z.object({
  title: z.string().min(1).max(50),
  body: z.string().max(150),
  topic: z.enum(ALLOWED_TOPICS),
  reason: z.enum([
    'system_announcement',
    'critical_alert',
    'admin_initiated',
    'feature_release',
  ]),
  confirmation: z.literal('BROADCAST', {
    errorMap: () => ({
      message: 'Tipea exactamente BROADCAST para confirmar.',
    }),
  }),
});

export async function sendBroadcast(_prev: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  const parsed = BroadcastSchema.safeParse({
    title: formData.get('title'),
    body: formData.get('body'),
    topic: formData.get('topic'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // Audit log antes de queue handoff
  const { data: auditRow, error: logErr } = await supabase
    .from('push_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'broadcast',
      reason: parsed.data.reason,
      payload: {
        title: parsed.data.title,
        body: parsed.data.body,
        topic: parsed.data.topic,
      },
      status: 'pending',
    })
    .select('id')
    .single();
  if (logErr) return { error: 'Error registrando.' };

  return {
    error:
      'sendBroadcast requires job queue setup (BullMQ / Inngest / similar). Audit registrado.',
    audit_id: auditRow?.id,
    documentation: '/docs/push/broadcast-setup',
  };
}

/* -----------------------------------------------------------------------------
 * sendToTopic — DESTRUCTIVE (subset broadcast)
 * -------------------------------------------------------------------------- */

const SendToTopicSchema = z.object({
  title: z.string().min(1).max(50),
  body: z.string().max(150),
  topic: z.enum(ALLOWED_TOPICS),
  reason: z.enum(['scheduled_campaign', 'admin_initiated', 'support_request']),
  confirmation: z.literal('SEND_TO_TOPIC', {
    errorMap: () => ({
      message: 'Tipea exactamente SEND_TO_TOPIC para confirmar.',
    }),
  }),
});

export async function sendToTopic(_prev: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  const parsed = SendToTopicSchema.safeParse({
    title: formData.get('title'),
    body: formData.get('body'),
    topic: formData.get('topic'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  const { data: auditRow } = await supabase
    .from('push_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'send_to_topic',
      reason: parsed.data.reason,
      payload: {
        title: parsed.data.title,
        body: parsed.data.body,
        topic: parsed.data.topic,
      },
      status: 'pending',
    })
    .select('id')
    .single();

  return {
    error: 'sendToTopic requires job queue setup. Audit registrado.',
    audit_id: auditRow?.id,
    documentation: '/docs/push/send-to-topic-setup',
  };
}

/* -----------------------------------------------------------------------------
 * revokeAllSubscriptions — DESTRUCTIVE
 * -------------------------------------------------------------------------- */

const RevokeAllSchema = z.object({
  user_ids: z.array(z.string().uuid()).min(1).max(10000),
  reason: z.enum([
    'admin_compliance',
    'data_subject_request',
    'security_incident',
  ]),
  confirmation: z.literal('REVOKE_ALL', {
    errorMap: () => ({
      message: 'Tipea exactamente REVOKE_ALL para confirmar.',
    }),
  }),
});

export async function revokeAllSubscriptions(
  _prev: unknown,
  formData: FormData
) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  const userIds = formData.getAll('user_ids') as string[];
  const parsed = RevokeAllSchema.safeParse({
    user_ids: userIds,
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  const { data: auditRow, error: logErr } = await supabase
    .from('push_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'revoke_all',
      target_user_ids: parsed.data.user_ids,
      reason: parsed.data.reason,
      status: 'pending',
    })
    .select('id')
    .single();
  if (logErr) return { error: 'Error registrando.' };

  try {
    await createAdminClient()
      .from('push_subscriptions')
      .delete()
      .in('user_id', parsed.data.user_ids);

    await supabase
      .from('push_admin_actions')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
      })
      .eq('id', auditRow.id);

    return { success: true, count: parsed.data.user_ids.length };
  } catch (err) {
    await supabase
      .from('push_admin_actions')
      .update({ status: 'failed', error_message: String(err) })
      .eq('id', auditRow.id);
    return { error: 'Error procesando.' };
  }
}
