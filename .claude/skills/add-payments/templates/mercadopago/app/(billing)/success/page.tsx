/**
 * /success — client component (Mode C, Mercado Pago)
 *
 * Polling profile.has_access hasta que el webhook concede acceso.
 * Acceso = subscription_preapproval `authorized` webhook → has_access = true.
 * Si timeout (10 attempts × 2s = 20s), mostrar mensaje "procesando".
 *
 * OXXO/SPEI (?pending=1): el pago confirma vía webhook horas después (el
 * efectivo convierte lento) — mostrar "pendiente", NUNCA acceso anticipado.
 *
 * NUNCA grant acceso desde acá — el frontend NO es source of truth.
 *
 * R10 Brand DNA gate enforced.
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:lessons#L-002]
 */
'use client';
import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { Card, Button } from '@/shared/components/ui';

type Status = 'verifying' | 'success' | 'timeout' | 'pending_rail';

export default function SuccessPage() {
  const params = useSearchParams();
  const isPendingRail = params.get('pending') === '1';
  const [status, setStatus] = useState<Status>(isPendingRail ? 'pending_rail' : 'verifying');
  const router = useRouter();

  useEffect(() => {
    if (isPendingRail) return;
    let attempts = 0;
    const maxAttempts = 10;
    let cancelled = false;

    async function check() {
      if (cancelled) return;
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        router.push('/sign-in?next=/success');
        return;
      }

      const { data: profile } = await supabase
        .from('profiles')
        .select('has_access')
        .eq('id', user.id)
        .maybeSingle();

      if (profile?.has_access) {
        setStatus('success');
        setTimeout(() => router.push('/'), 1500);
        return;
      }

      attempts++;
      if (attempts >= maxAttempts) {
        setStatus('timeout');
        return;
      }
      setTimeout(check, 2000);
    }

    check();
    return () => { cancelled = true; };
  }, [router, isPendingRail]);

  return (
    <main aria-labelledby="success-title">
      <Card>
        <h1 id="success-title">{'{{ COPY_SUCCESS_TITLE }}'}</h1>

        {status === 'verifying' && (
          <p role="status" aria-live="polite">
            Verificando tu pago...
          </p>
        )}

        {status === 'success' && (
          <p role="status" aria-live="polite">
            Pago confirmado. Redirigiendo...
          </p>
        )}

        {status === 'pending_rail' && (
          <>
            <p role="status" aria-live="polite">
              Tu pago por OXXO/SPEI está pendiente. En cuanto se acredite (puede tardar hasta 48 h) te
              avisamos por email y se activa el acceso.
            </p>
            <Button as="a" href="/" variant="primary">
              {'{{ COPY_SUCCESS_CTA_BACK }}'}
            </Button>
          </>
        )}

        {status === 'timeout' && (
          <>
            <p role="alert">
              Tu pago se está procesando. El acceso se activará en pocos minutos.
              Te enviaremos un email de confirmación.
            </p>
            <Button as="a" href="/" variant="primary">
              {'{{ COPY_SUCCESS_CTA_BACK }}'}
            </Button>
          </>
        )}
      </Card>
    </main>
  );
}
