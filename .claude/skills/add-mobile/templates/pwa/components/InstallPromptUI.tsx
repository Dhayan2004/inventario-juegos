/**
 * InstallPromptUI — install PWA flow (Chrome auto-prompt + iOS Safari manual).
 *
 * R10 enforced: Card + Button via @/shared/components/ui/* (impeccable).
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005] · [docs:web-push]
 */
'use client';

import { useEffect, useState } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/shared/components/ui/Card';
import { Button } from '@/shared/components/ui/Button';

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

type Platform = 'chrome' | 'ios-safari' | 'installed' | 'unsupported';

export function InstallPromptUI() {
  const [deferredPrompt, setDeferredPrompt] =
    useState<BeforeInstallPromptEvent | null>(null);
  const [platform, setPlatform] = useState<Platform>('unsupported');

  useEffect(() => {
    if (typeof window === 'undefined') return;

    if (window.matchMedia('(display-mode: standalone)').matches) {
      setPlatform('installed');
      return;
    }

    const ua = navigator.userAgent;
    const isIOSSafari =
      /iPad|iPhone|iPod/.test(ua) &&
      !(window as any).MSStream &&
      /Safari/.test(ua) &&
      !/CriOS/.test(ua) &&
      !/FxiOS/.test(ua);

    if (isIOSSafari) {
      setPlatform('ios-safari');
      return;
    }

    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setPlatform('chrome');
    };
    window.addEventListener('beforeinstallprompt', handler);
    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  if (platform === 'installed' || platform === 'unsupported') return null;

  const handleInstall = async () => {
    if (!deferredPrompt) return;
    await deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      setDeferredPrompt(null);
    }
  };

  return (
    <Card className="max-w-md mx-auto">
      <CardHeader>
        <CardTitle>{'{{ COPY_INSTALL_HEADING }}'}</CardTitle>
        <CardDescription>{'{{ COPY_INSTALL_BODY }}'}</CardDescription>
      </CardHeader>
      <CardContent>
        {platform === 'chrome' && deferredPrompt && (
          <Button onClick={handleInstall} size="lg">
            {'{{ COPY_INSTALL_CTA }}'}
          </Button>
        )}
        {platform === 'ios-safari' && (
          <div className="space-y-2 text-sm text-muted-foreground">
            <p>{'{{ COPY_INSTALL_IOS_INSTRUCTIONS }}'}</p>
            <ol className="list-decimal list-inside space-y-1">
              <li>Toca el botón Compartir (cuadrado con flecha hacia arriba)</li>
              <li>Tocá "Agregar a pantalla de inicio"</li>
              <li>Confirmá tocando "Agregar"</li>
            </ol>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
