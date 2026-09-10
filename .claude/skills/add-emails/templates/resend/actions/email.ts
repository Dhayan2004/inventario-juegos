/**
 * Email server actions.
 *
 * Non-destructive: sendTransactionalEmail (rate-limited, suppression-checked)
 *
 * DESTRUCTIVE (R14 strict, 5 gates each):
 *   - bulkUnsubscribe (admin role required, max 10000 user_ids)
 *   - deleteSuppressionEntry (re-enables sending — IP reputation risk)
 *   - resendCampaign (re-send to N users)
 *
 * Cita: [memory:CONSTRAINTS.md#R14] · [memory:lessons#L-001..3]
 *       · [docs:resend@latest]
 */
'use server';

import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

/* -----------------------------------------------------------------------------
 * bulkUnsubscribe — DESTRUCTIVE
 * -------------------------------------------------------------------------- */

const BulkUnsubscribeSchema = z.object({
  user_ids: z.array(z.string().uuid()).min(1).max(10000),
  scope: z.enum(['marketing', 'product_updates', 'all']),
  reason: z.enum(['admin_compliance', 'data_subject_request', 'spam_complaint_batch']),
  confirmation: z.literal('BULK_UNSUBSCRIBE', {
    errorMap: () => ({ message: 'Tipea exactamente BULK_UNSUBSCRIBE para confirmar.' }),
  }),
});

export async function bulkUnsubscribe(_prev: unknown, formData: FormData) {
  // 1. AUTH + role check
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  // 2. INPUT (L-003)
  const userIds = formData.getAll('user_ids') as string[];
  const parsed = BulkUnsubscribeSchema.safeParse({
    user_ids: userIds,
    scope: formData.get('scope'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  // 3. AUDIT log
  const { data: auditRow, error: logErr } = await supabase
    .from('email_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'bulk_unsubscribe',
      target_user_ids: parsed.data.user_ids,
      reason: parsed.data.reason,
      status: 'pending',
    })
    .select('id')
    .single();
  if (logErr) return { error: 'Error registrando.' };

  // 4. EXECUTE
  try {
    await createAdminClient()
      .from('email_subscriptions')
      .upsert(
        parsed.data.user_ids.map((uid) => ({
          user_id: uid,
          scope: parsed.data.scope,
          unsubscribed_at: new Date().toISOString(),
        })),
        { onConflict: 'user_id,scope' }
      );

    await supabase
      .from('email_admin_actions')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', auditRow.id);

    return { success: true, count: parsed.data.user_ids.length };
  } catch (err) {
    await supabase
      .from('email_admin_actions')
      .update({ status: 'failed', error_message: String(err) })
      .eq('id', auditRow.id);
    return { error: 'Error procesando.' };
  }
}

/* -----------------------------------------------------------------------------
 * deleteSuppressionEntry — DESTRUCTIVE (re-enables sending)
 * -------------------------------------------------------------------------- */

const DeleteSuppressionSchema = z.object({
  email: z.string().email().max(254),
  reason: z.enum(['user_complaint_resolved', 'address_corrected', 'admin_override']),
  confirmation: z.literal('DELETE_SUPPRESSION', {
    errorMap: () => ({ message: 'Tipea exactamente DELETE_SUPPRESSION para confirmar.' }),
  }),
});

export async function deleteSuppressionEntry(_prev: unknown, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  const parsed = DeleteSuppressionSchema.safeParse({
    email: formData.get('email'),
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  const { data: auditRow } = await supabase
    .from('email_admin_actions')
    .insert({
      admin_user_id: user.id,
      action: 'delete_suppression',
      target_email: parsed.data.email.toLowerCase(),
      reason: parsed.data.reason,
      status: 'pending',
    })
    .select('id')
    .single();

  try {
    await createAdminClient()
      .from('suppression_list')
      .delete()
      .eq('email', parsed.data.email.toLowerCase());

    await supabase
      .from('email_admin_actions')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', auditRow!.id);

    return { success: true };
  } catch (err) {
    await supabase
      .from('email_admin_actions')
      .update({ status: 'failed', error_message: String(err) })
      .eq('id', auditRow!.id);
    return { error: 'Error procesando.' };
  }
}

/* -----------------------------------------------------------------------------
 * resendCampaign — DESTRUCTIVE (re-send to N users)
 * -------------------------------------------------------------------------- */

const ResendCampaignSchema = z.object({
  template_id: z.enum(['welcome', 'magic_link', 'password_reset', 'invoice_receipt',
                       'payment_failed', 'subscription_canceled', 'email_changed_confirmation']),
  user_ids: z.array(z.string().uuid()).min(1).max(5000),
  reason: z.enum(['retry_after_outage', 'admin_initiated_announcement', 'support_request']),
  confirmation: z.literal('RESEND_CAMPAIGN', {
    errorMap: () => ({ message: 'Tipea exactamente RESEND_CAMPAIGN para confirmar.' }),
  }),
});

export async function resendCampaign(_prev: unknown, formData: FormData) {
  // Stub: same shape como bulkUnsubscribe, pero el execute invoca
  // /api/email/send para cada user_id en background queue.
  // Implementación completa requiere job queue (BullMQ, Inngest, etc.) —
  // fuera del scope de este template básico. Documentar handoff.

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'No autorizado.' };

  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (profile?.role !== 'admin') return { error: 'Requiere rol admin.' };

  const userIds = formData.getAll('user_ids') as string[];
  const parsed = ResendCampaignSchema.safeParse({
    template_id: formData.get('template_id'),
    user_ids: userIds,
    reason: formData.get('reason'),
    confirmation: formData.get('confirmation'),
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Input inválido.' };
  }

  return {
    error: 'resendCampaign requires job queue setup. ' +
           'Implementar BullMQ / Inngest / similar antes de habilitar.',
    documentation: '/docs/email/resend-campaign-setup',
  };
}
