# Generate Notification Permission Flow (UX best practice)

> Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
> Source: research-backed UX best practices for notification permission UX (Google, Apple HIG, Mozilla docs)

## Objetivo

Generar `components/PushPermissionPrompt.tsx` que respete UX best practice crítica: **el permission prompt NO se muestra on page load**. Se muestra **post-action** que justifica notifications.

## Por qué esto es regla de oro

Si el usuario rechaza notifications en el browser/OS prompt, la app pierde la capacidad de pedir permission de nuevo (al menos por ese tab/sesión, en algunos casos permanentemente). **Por eso pedir on page load es kamikaze:**

1. Usuario llega a la página por primera vez
2. App pregunta "¿Activar notificaciones?" sin contexto
3. Usuario default click "Bloquear"
4. App nunca más puede mostrar notifications a ese user

**Best practice:** mostrar el prompt cuando el usuario ya hizo una acción que **justifica** notifications. Ejemplos:
- Después de "Save for later" → "¿Querés que te avisemos cuando cambie el precio?"
- Después de "Follow this thread" → "¿Querés notificaciones cuando alguien responda?"
- Después de explicit "Enable notifications" CTA en settings page

Esto se llama **soft-ask in-app** antes del **hard-ask del browser**.

## Antes de empezar (R13)

```
1. resolve-library-id("react") → query-docs
   query: "useEffect useState useCallback Notification.permission
           navigator.serviceWorker.ready PushManager.getSubscription"
```

## Component shape

```tsx
'use client';

import { useState, useEffect, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/shared/components/ui/Card';
import { Button } from '@/shared/components/ui/Button';
import { usePushSubscription } from '@/hooks/usePushSubscription';

interface PushPermissionPromptProps {
  userId?: string;
  /**
   * Tiempo en ms antes de mostrar el prompt automáticamente.
   * Default: 0 (manual — solo se muestra cuando el caller llama setShow(true)).
   *
   * Si autoShowDelay > 0, el prompt se muestra después del delay
   * SIEMPRE QUE el usuario NO haya dismissed antes (localStorage check).
   *
   * IMPORTANTE: NO uses autoShowDelay = 0 con triggers automáticos
   * sin justificación. Mostrar post-action (ej: tras "save for later").
   */
  autoShowDelay?: number;
  /**
   * Trigger explícito desde fuera. Si el caller pasa `show={true}`,
   * el prompt se muestra inmediatamente. Use case: post-action UX.
   */
  show?: boolean;
  onDismiss?: () => void;
  onSubscribed?: () => void;
}

const DISMISSED_KEY = 'forja:push-prompt-dismissed';

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

  // Auto-show flow: respeta best practice — solo si autoShowDelay > 0 Y
  // el usuario aún no dismissed Y permission no está denied.
  useEffect(() => {
    if (autoShowDelay <= 0) return;
    if (!isSupported || isSubscribed || permission === 'denied') return;

    const dismissed = localStorage.getItem(DISMISSED_KEY);
    if (dismissed) return;

    const timer = setTimeout(() => setInternalShow(true), autoShowDelay);
    return () => clearTimeout(timer);
  }, [autoShowDelay, isSupported, isSubscribed, permission]);

  if (!show || !isSupported || isSubscribed || permission === 'denied') {
    return null;
  }

  const handleEnable = async () => {
    localStorage.setItem(DISMISSED_KEY, 'true');
    await subscribe();
    setInternalShow(false);
    onSubscribed?.();
  };

  const handleDismiss = () => {
    localStorage.setItem(DISMISSED_KEY, 'true');
    setInternalShow(false);
    onDismiss?.();
  };

  return (
    <Card className="fixed bottom-4 right-4 z-50 max-w-sm shadow-lg">
      <CardHeader>
        <CardTitle className="text-base">{'{{ COPY_PERMISSION_HEADING }}'}</CardTitle>
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
```

## Patterns de invocación

### Pattern 1 — Post-action explícito (recomendado)

```tsx
// En cualquier feature que justifique notifications
'use client';
import { useState } from 'react';
import { PushPermissionPrompt } from '@/components/PushPermissionPrompt';

function SaveForLaterButton({ itemId }: { itemId: string }) {
  const [showPushPrompt, setShowPushPrompt] = useState(false);

  const handleSave = async () => {
    await saveItemForLater(itemId);
    // Post-action: pedir permission AHORA que el user demostró interés
    setShowPushPrompt(true);
  };

  return (
    <>
      <Button onClick={handleSave}>Guardar para después</Button>
      <PushPermissionPrompt
        show={showPushPrompt}
        onDismiss={() => setShowPushPrompt(false)}
      />
    </>
  );
}
```

### Pattern 2 — Auto-show con delay (use con precaución)

```tsx
// Layout principal
<PushPermissionPrompt userId={user?.id} autoShowDelay={30000} />
```

`autoShowDelay = 30000` (30s) significa: si el user pasa 30s en la app sin dismissed, mostrar prompt. Esto **SOLO** es aceptable si:
- La app tiene context que justifica (ej: messaging app, alertas críticas)
- El delay >15s para que el user haya tenido tiempo de explorar
- localStorage dismissal tracking funcional (no spammear)

**NUNCA** `autoShowDelay = 0` o `autoShowDelay < 5000` sin trigger explícito post-action.

### Pattern 3 — Settings page CTA

```tsx
// Settings page — user explícitamente busca activar notifications
function SettingsNotifications() {
  const [showPrompt, setShowPrompt] = useState(false);
  return (
    <>
      <Button onClick={() => setShowPrompt(true)}>
        Activar notificaciones
      </Button>
      <PushPermissionPrompt show={showPrompt} onDismiss={() => setShowPrompt(false)} />
    </>
  );
}
```

## Reglas

1. **NEVER on page load.** `autoShowDelay = 0` está prohibido como default.
2. **localStorage dismissal tracking**: si user dismissed, NO mostrar de nuevo (al menos por 7 días — implementar TTL si querés re-prompt eventual).
3. **Permission denied → null.** Si `Notification.permission === 'denied'`, el prompt nunca se muestra. NO hay forma de forzar el prompt si user bloqueó.
4. **iOS Safari quirks**: en iOS Safari, push web requires PWA-installed-state. Si el user NO instaló PWA, el prompt explica el flow alternativo (instalar primero, después activar push). Documentado en `references/ios-safari-quirks.md`.
5. **R10 contract**: Card + Button desde `@/shared/components/ui/*` (impeccable). NO hardcoded styling.
6. **Copy desde voice.json**: 4 keys mínimo — heading + body + CTA allow + CTA dismiss. Fallback conservador si voice.cta_examples es genérico.
7. **Accessibility**: ESC key para dismiss + focus trap dentro del Card cuando visible (impeccable Card ya implementa esto si Mode KNOWN).

## Citations

- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:references#R-005] (schema)
- [docs:react] · [docs:nextjs]
