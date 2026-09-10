/**
 * POST /api/email/send
 *
 * Rate limit: max 10 / user / hour para transactional flows.
 * Bulk via separate authenticated admin route (R14 gates).
 *
 * Cita: [memory:lessons#L-003] · [memory:CONSTRAINTS.md#R13]
 *       · [docs:resend@latest] · [docs:rfc8058]
 */
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { resend, EMAIL_FROM, ALLOWED_TEMPLATE_IDS, ALLOWED_LOCALES } from '@/lib/resend/server';
import { createClient } from '@/lib/supabase/server';
import { isSuppressed } from '@/lib/email/suppression-check';
import { generateUnsubscribeToken } from '@/lib/email/unsubscribe-token';
import {
  WelcomeEmail,
  MagicLinkEmail,
  PasswordResetEmail,
  InvoiceReceiptEmail,
  PaymentFailedEmail,
  SubscriptionCanceledEmail,
  EmailChangedConfirmationEmail,
} from '@/emails';

// Rate limiter
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

const TEMPLATE_MAP = {
  welcome: WelcomeEmail,
  magic_link: MagicLinkEmail,
  password_reset: PasswordResetEmail,
  invoice_receipt: InvoiceReceiptEmail,
  payment_failed: PaymentFailedEmail,
  subscription_canceled: SubscriptionCanceledEmail,
  email_changed_confirmation: EmailChangedConfirmationEmail,
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
    return NextResponse.json({ error: parsed.error.issues[0]?.message ?? 'Invalid' }, { status: 400 });
  }

  // Pre-send suppression check
  if (await isSuppressed(parsed.data.to)) {
    return NextResponse.json({ skipped: true, reason: 'suppressed' });
  }

  const Template = TEMPLATE_MAP[parsed.data.templateId];
  const token = await generateUnsubscribeToken(parsed.data.to, user.id, 'all');
  const unsubscribeUrl = `${process.env.NEXT_PUBLIC_APP_URL}/api/email/unsubscribe?token=${token}`;

  // L-002: data is user-controlled — Template props validates internally via TS,
  // pero campos desconocidos se pasan as-is al render (rendered to HTML — safe)
  const props = { ...parsed.data.data, unsubscribeUrl };

  await resend.emails.send({
    from: EMAIL_FROM,
    to: [parsed.data.to],
    subject: subjectForTemplate(parsed.data.templateId, props),
    react: Template(props as any),
    headers: {
      'List-Unsubscribe': `<${unsubscribeUrl}>`,
      'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
    },
  });

  return NextResponse.json({ success: true });
}

function subjectForTemplate(id: string, props: Record<string, unknown>): string {
  const productName = (props.productName as string) ?? 'App';
  const subjects: Record<string, string> = {
    welcome: `Bienvenido a ${productName}`,
    magic_link: `Tu enlace de acceso a ${productName}`,
    password_reset: `Restablecé tu contraseña — ${productName}`,
    invoice_receipt: `Recibo de ${productName}`,
    payment_failed: `Acción requerida — ${productName}`,
    subscription_canceled: `Tu suscripción a ${productName} fue cancelada`,
    email_changed_confirmation: `Confirmá tu nuevo email — ${productName}`,
  };
  return subjects[id] ?? productName;
}
