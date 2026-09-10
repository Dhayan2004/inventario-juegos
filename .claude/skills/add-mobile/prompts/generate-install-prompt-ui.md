# Generate Install Prompt UI (R10 — Brand DNA contract)

> Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005] · [memory:CONSTRAINTS.md#R13]

## Objetivo

Generar `app/(mobile)/install/page.tsx` + `components/InstallPromptUI.tsx` que consuman impeccable Card + Button, derivando copy desde voice.json y tokens desde brand.json.

## Antes de empezar (R13)

```
1. resolve-library-id("react") → query-docs
   query: "useEffect useState window.matchMedia BeforeInstallPromptEvent"
2. resolve-library-id("nextjs") → query-docs
   query: "App Router 16 client component metadata"
```

**Razón:** `BeforeInstallPromptEvent` es Chrome/Edge specific. iOS Safari NO dispatcha el evento — usuario debe usar "Add to Home Screen" manual. Detectar correctamente platform es crítico para UX.

## Inputs (R10 contract)

- `brand/brand.json.tokens.colors.primary` → CTA Button
- `brand/brand.json.tokens.colors.text` → headings + body
- `brand/brand.json.tokens.colors.surface` → Card background
- `brand/voice.json.cta_examples` → install CTA copy ("Instalar app", "Llevame al panel")
- `brand/voice.json.tone` → tono del body copy
- `brand/voice.json.avoid_words` → audit (no "miss out", "exclusive", "limited time" — marketing slop)

## Component shape

```tsx
'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/shared/components/ui/Card';
import { Button } from '@/shared/components/ui/Button';

/**
 * InstallPromptUI — Install PWA flow.
 *
 * Detection logic:
 * - Chrome/Edge desktop + Android → BeforeInstallPromptEvent
 * - iOS Safari → manual "Add to Home Screen" instructions
 * - Already installed → null (no prompt)
 *
 * R10 enforced: tokens via @/shared/components/ui/* (impeccable),
 * copy desde voice.json {{ COPY_INSTALL_* }}.
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
export function InstallPromptUI() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [platform, setPlatform] = useState<'chrome' | 'ios-safari' | 'installed' | 'unsupported'>('unsupported');

  useEffect(() => {
    // Already installed → matchMedia('(display-mode: standalone)')
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setPlatform('installed');
      return;
    }

    // iOS Safari detection
    const isIOSSafari = /iPad|iPhone|iPod/.test(navigator.userAgent) &&
      !(window as any).MSStream &&
      /Safari/.test(navigator.userAgent) &&
      !/CriOS/.test(navigator.userAgent);

    if (isIOSSafari) {
      setPlatform('ios-safari');
      return;
    }

    // Chrome/Edge: capture BeforeInstallPromptEvent
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
    if (deferredPrompt) {
      await deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      if (outcome === 'accepted') {
        setDeferredPrompt(null);
      }
    }
  };

  return (
    <Card className="max-w-md mx-auto">
      <CardHeader>
        <CardTitle>{'{{ COPY_INSTALL_HEADING }}'}</CardTitle>
        <CardDescription>{'{{ COPY_INSTALL_BODY }}'}</CardDescription>
      </CardHeader>
      <CardContent>
        {platform === 'chrome' && (
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
```

## Reglas

1. **Copy keys son substituidos al apply**: `{{ COPY_INSTALL_HEADING }}` viene de voice.json mapping. Sin el mapping al voice.cta_examples, fallback conservador ("Instalar como app", "Acceso rápido desde tu pantalla").
2. **NO Tailwind purple/indigo/violet/blue.** Tokens via `@/shared/components/ui/*` que ya consume brand.css vars.
3. **NO marketing slop** — palabras prohibidas en avoid_words: "miss out", "exclusive", "limited time", "amazing experience". Audit corre sobre el copy generado.
4. **Detection robusta de iOS Safari:** check userAgent + Safari + NO CriOS (Chrome iOS) + NO MSStream.
5. **`display-mode: standalone` check primero** — si ya está instalada, NO mostrar prompt.
6. **Accessibility:** Button con `size="lg"` cumple touch target ≥44×44px (iOS HIG / Material). Card heading con CardTitle (semantic h3 en impeccable).

## install/page.tsx

```tsx
import { InstallPromptUI } from '@/components/InstallPromptUI';

export const metadata = {
  title: 'Instalar app',
};

export default function InstallPage() {
  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <InstallPromptUI />
    </main>
  );
}
```

## Citations

- [memory:CONSTRAINTS.md#R10] (Brand DNA contract)
- [memory:references#R-005] (schema)
- [docs:react] · [docs:nextjs]
