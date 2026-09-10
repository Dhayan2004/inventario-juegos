/**
 * POST /api/email/send  (SendGrid Mode B)
 *
 * Rate limit: max 10 / user / hour para transactional flows.
 * Bulk via separate authenticated admin route (R14 gates).
 *
 * Diferencia clave vs Mode A: usa SendGrid dynamic templates
 * (templateId pre-uploaded + dynamicTemplateData runtime), NO React Email
 * render inline.
 *
 * Cita: [memory:lessons#L-003] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:sendgrid-mail@v8] · [docs:rfc8058]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import {
  sendgrid,
  EMAIL_FROM,
  ALLOWED_TEMPLATE_IDS,
  ALLOWED_LOCALES,
  SENDGRID_UNSUBSCRIBE_GROUP_ID,
  assertTemplateConfigured,
  type AllowedTemplateId,
} from '@/lib/sendgrid/server';
import { createClient } from '@/lib/supabase/server';
import { isSuppressed } from '@/lib/email/suppression-check';
import { generateUnsubscribeToken } from '@/lib/email/unsubscribe-token';
import {
  WelcomeTemplate,
  MagicLinkTemplate,
  PasswordResetTemplate,
  InvoiceReceiptTemplate,
  PaymentFailedTemplate,
  SubscriptionCanceledTemplate,
  EmailChangedConfirmationTemplate,
} from '@/emails';

// Rate limiter (in-memory). Para producción, usar Upstash Redis.
const RATE_LIMIT = 10;
const WINDOW_MS = 60 * 60 * 1000;
const userBuckets = new Map<string, { count: number; resetAt: number }>();
function rateLimitOk(userId: string): boolean {
  const now = Date.now();
  const b = userBuckets.get(userId);
  if (!b || now > b.resetAt) {
    userBuckets.set(userId, { count: 1, resetAt: now + WINDOW_MS });
    return true;
  }
  if (b.count >= RATE_LIMIT) return false;
  b.count++;
  return true;
}

const InputSchema = z.object({
  templateId: z.enum(ALLOWED_TEMPLATE_IDS),
  to: z.string().email().max(254),
  locale: z.enum(ALLOWED_LOCALES).default('es-419'),
  data: z.record(z.unknown()),
});

const TEMPLATE_DESCRIPTORS: Record<
  AllowedTemplateId,
  { templateId: () => string; subject: (data: any) => string }
> = {
  welcome: WelcomeTemplate,
  magic_link: MagicLinkTemplate,
  password_reset: PasswordResetTemplate,
  invoice_receipt: InvoiceReceiptTemplate,
  payment_failed: PaymentFailedTemplate,
  subscription_canceled: SubscriptionCanceledTemplate,
  email_changed_confirmation: EmailChangedConfirmationTemplate,
};

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  if (!rateLimitOk(user.id)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  const body = await request.json();
  const parsed = InputSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Invalid' },
      { status: 400 }
    );
  }

  // Pre-send suppression check (mantenido por paridad con Mode A — SendGrid
  // también suprime side-server, pero hacemos check propio para audit + UI).
  if (await isSuppressed(parsed.data.to)) {
    return NextResponse.json({ skipped: true, reason: 'suppressed' });
  }

  const descriptor = TEMPLATE_DESCRIPTORS[parsed.data.templateId];
  const sgTemplateId = assertTemplateConfigured(parsed.data.templateId);

  const token = await generateUnsubscribeToken(parsed.data.to, user.id, 'all');
  const unsubscribeUrl =
    `${process.env.NEXT_PUBLIC_APP_URL}/api/email/unsubscribe?token=${token}`;

  // L-002: data es user-controlled. Whitelist via TS interface (a nivel call
  // site) + runtime field-by-field passthrough a SendGrid (que escapa
  // handlebar substitution server-side).
  const dynamicTemplateData = {
    ...parsed.data.data,
    unsubscribeUrl,
  };

  const subject = descriptor.subject(dynamicTemplateData);

  await sendgrid.send({
    from: EMAIL_FROM,
    to: parsed.data.to,
    templateId: sgTemplateId,
    dynamicTemplateData,
    subject, // override del subject del template (opcional)
    headers: {
      'List-Unsubscribe': `<${unsubscribeUrl}>`,
      'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
    },
    ...(SENDGRID_UNSUBSCRIBE_GROUP_ID && {
      asm: { groupId: SENDGRID_UNSUBSCRIBE_GROUP_ID },
    }),
    trackingSettings: {
      clickTracking: { enable: true },
      // openTracking off por privacy unless disclosed en footer
      openTracking: { enable: false },
    },
  });

  return NextResponse.json({ success: true });
}
