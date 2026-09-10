/**
 * PushPermissionPrompt — soft-ask before browser hard-ask.
 *
 * UX best practice: NO mostrar on page load. Mostrar post-action o
 * con autoShowDelay configurable. localStorage tracks dismissal.
 *
 * R10 enforced: Card + Button via @/shared/components/ui/* (impeccable).
 * Copy desde voice.json {{ COPY_PERMISSION_* }}.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
'use client';

import { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/shared/components/ui/Card';
import { Button } from '@/shared/components/ui/Button';
import { usePushSubscription } from '@/hooks/usePushSubscription';

const DISMISSED_KEY = 'forja:push-prompt-dismissed';

interface PushPermissionPromptProps {
  userId?: string;
  /** Default 0 — manual show via prop. NUNCA <5000 en autoshow without justification. */
  autoShowDelay?: number;
  show?: boolean;
  onDismiss?: () => void;
  onSubscribed?: () => void;
}

export function PushPermissionPrompt({
  userId,
  autoShowDelay = 0,
  show: externalShow,
  onDismiss,
  onSubscribed,
}: PushPermissionPromptProps) {
  const { isSupported, permission, isSubscribed, subscribe } =
    usePushSubscription(userId);
  const [internalShow, setInternalShow] = useState(false);

  const show = externalShow ?? internalShow;

  useEffect(() => {
    if (autoShowDelay <= 0) return;
    if (!isSupported || isSubscribed || permission === 'denied') return;

    const dismissed =
      typeof window !== 'undefined'
        ? window.localStorage.getItem(DISMISSED_KEY)
        : null;
    if (dismissed) return;

    const timer = setTimeout(() => setInternalShow(true), autoShowDelay);
    return () => clearTimeout(timer);
  }, [autoShowDelay, isSupported, isSubscribed, permission]);

  if (!show || !isSupported || isSubscribed || permission === 'denied') {
    return null;
  }

  const handleEnable = async () => {
    window.localStorage.setItem(DISMISSED_KEY, 'true');
    await subscribe();
    setInternalShow(false);
    onSubscribed?.();
  };

  const handleDismiss = () => {
    window.localStorage.setItem(DISMISSED_KEY, 'true');
    setInternalShow(false);
    onDismiss?.();
  };

  return (
    <Card className="fixed bottom-4 right-4 z-50 max-w-sm shadow-lg">
      <CardHeader>
        <CardTitle className="text-base">
          {'{{ COPY_PERMISSION_HEADING }}'}
        </CardTitle>
        <CardDescription className="text-xs">
          {'{{ COPY_PERMISSION_BODY }}'}
        </CardDescription>
      </CardHeader>
      <CardContent className="flex gap-2">
        <Button onClick={handleEnable} size="sm">
          {'{{ COPY_PERMISSION_CTA_ALLOW }}'}
        </Button>
        <Button onClick={handleDismiss} variant="ghost" size="sm">
          {'{{ COPY_PERMISSION_CTA_DISMISS }}'}
        </Button>
      </CardContent>
    </Card>
  );
}
