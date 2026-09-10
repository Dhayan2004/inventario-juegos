# Accessibility — referencia (WCAG 2.1 AA)

> Guidelines accessibility basadas en WCAG 2.1 + Lighthouse accessibility audits. Goal: contenido usable por todos, incluidos usuarios con discapacidades. **WCAG 2.1 AA es mínimo no-negociable en Forja.**

## WCAG Principles: POUR

| Principle | Description |
|-----------|-------------|
| **P**erceivable | Contenido percibible por distintos sentidos |
| **O**perable | Interfaz operable por todos los usuarios |
| **U**nderstandable | Contenido + interfaz comprensibles |
| **R**obust | Funciona con assistive technologies |

## Conformance levels

| Level | Requirement | Target Forja |
|-------|-------------|--------------|
| **A** | Mínimo accesible | Mandatory |
| **AA** | Standard compliance | **Mandatory** (legal en muchas jurisdicciones) |
| **AAA** | Enhanced | Nice to have, no enforced |

WCAG 2.2 cuando find-docs confirme soporte upstream estable (`[docs:wcag]`).

---

## Perceivable

### Text alternatives (1.1)

**Imágenes informativas con alt descriptivo:**

```html
<!-- ❌ Missing alt → Lighthouse Critical -->
<img src="chart.png">

<!-- ✅ Descriptive alt -->
<img src="chart.png" alt="Bar chart showing 40% increase in Q3 sales">

<!-- ✅ Decorative image (empty alt + presentation role) -->
<img src="decorative-border.png" alt="" role="presentation">

<!-- ✅ Complex image con longer description -->
<figure>
  <img src="infographic.png" alt="2024 market trends infographic"
       aria-describedby="infographic-desc">
  <figcaption id="infographic-desc">
    Detailed description of trends...
  </figcaption>
</figure>
```

**Icon buttons necesitan accessible names:**

```html
<!-- ❌ No accessible name -->
<button><svg><!-- menu icon --></svg></button>

<!-- ✅ aria-label -->
<button aria-label="Open menu">
  <svg aria-hidden="true"><!-- menu icon --></svg>
</button>

<!-- ✅ Visually hidden text -->
<button>
  <svg aria-hidden="true"><!-- menu icon --></svg>
  <span class="visually-hidden">Open menu</span>
</button>
```

**Visually hidden class canónica:**

```css
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

### Time-based media (1.2)

- Video con captions (track kind="captions")
- Audio con transcripts
- Auto-play deshabilitado por default (prefers-reduced-motion)

### Adaptable (1.3)

**Heading hierarchy:**

```html
<!-- ✅ Estructura lógica -->
<h1>Page title (uno por página)</h1>
  <h2>Section</h2>
    <h3>Subsection</h3>
  <h2>Another section</h2>

<!-- ❌ Skip levels -->
<h1>Page title</h1>
  <h3>Subsection (skipped h2!)</h3>
```

**Forms con labels:**

```html
<!-- ✅ Label asociado -->
<label for="email">Email</label>
<input type="email" id="email" name="email" required>

<!-- ✅ Label envolvente -->
<label>
  Email
  <input type="email" name="email" required>
</label>

<!-- ✅ aria-label cuando label visual no es viable -->
<input type="search" aria-label="Search products" placeholder="Search...">
```

**Asociación de errores:**

```html
<label for="password">Password</label>
<input
  type="password"
  id="password"
  aria-invalid="true"
  aria-describedby="password-error">
<span id="password-error" role="alert">
  Password debe tener al menos 8 caracteres
</span>
```

### Distinguishable (1.4)

**Contraste mínimo:**

| Tamaño texto | Contraste mínimo |
|--------------|------------------|
| Normal text (< 18pt) | 4.5:1 |
| Large text (≥ 18pt o 14pt bold) | 3:1 |
| UI components & graphics | 3:1 |

```css
/* ✅ AA compliant */
color: #1a1a1a;          /* sobre #ffffff = 19.3:1 */
color: #595959;          /* sobre #ffffff = 7.0:1 */
color: #767676;          /* sobre #ffffff = 4.5:1 (límite) */

/* ❌ Falla AA */
color: #999999;          /* sobre #ffffff = 2.85:1 */
```

**No depender solo del color:**

```html
<!-- ❌ Solo color comunica error -->
<input class="border-red-500">

<!-- ✅ Color + icon + text -->
<div role="alert">
  <span aria-hidden="true">⚠️</span>
  <span class="text-red-700">Email es requerido</span>
</div>
<input
  class="border-red-500"
  aria-invalid="true"
  aria-describedby="email-error">
```

**Resize text 200% sin loss de funcionalidad.**

**Reflow:** texto reflows correctamente en viewports pequeños sin scroll horizontal.

---

## Operable

### Keyboard accessible (2.1)

**Todo accesible por keyboard:**

```html
<!-- ❌ Solo onClick — inaccesible por keyboard -->
<div onClick={handleClick}>Click me</div>

<!-- ✅ Botón nativo -->
<button onClick={handleClick}>Click me</button>

<!-- ✅ Si ABSOLUTAMENTE necesario div clickeable -->
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      handleClick()
    }
  }}>
  Click me
</div>
```

**Sin keyboard traps** — usuario puede navegar fuera del component con Tab/Shift+Tab.

**Focus management en modals:**

```tsx
'use client'
import { useEffect, useRef } from 'react'

function Modal({ isOpen, onClose, children }) {
  const dialogRef = useRef<HTMLDialogElement>(null)
  
  useEffect(() => {
    if (isOpen) {
      dialogRef.current?.showModal()
      // focus trap automático con <dialog> nativo
    } else {
      dialogRef.current?.close()
    }
  }, [isOpen])
  
  return (
    <dialog ref={dialogRef} onClose={onClose} aria-labelledby="modal-title">
      <h2 id="modal-title">Modal title</h2>
      {children}
      <button onClick={onClose} autoFocus>Cerrar</button>
    </dialog>
  )
}
```

### Enough time (2.2)

- Sin time limits arbitrarios; si los hay, dar opción de extender/desactivar
- Pause/stop/hide para contenido auto-actualizante (carousels, tickers)

### Seizures and physical reactions (2.3)

- Sin contenido que parpadee >3× por segundo
- Animaciones respetan `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Navigable (2.4)

**Skip links:**

```html
<a href="#main-content" class="skip-link visually-hidden focus:not-visually-hidden">
  Skip to main content
</a>

<header><nav>...</nav></header>

<main id="main-content">...</main>
```

**Page titles únicos y descriptivos:**

```tsx
// Next.js metadata API
export const metadata: Metadata = {
  title: 'Pricing — Forja',  // único por página
  description: '...',
}
```

**Focus visible siempre:**

```css
/* ❌ Remueve outline sin replacement → Lighthouse warning */
*:focus { outline: none; }

/* ✅ Replace con focus-visible */
*:focus-visible {
  outline: 2px solid var(--accent-primary);
  outline-offset: 2px;
}

/* ❌ Remover focus en keyboard users */
button:focus { outline: none; }

/* ✅ Solo en mouse users (focus-visible) */
button:focus-visible {
  outline: 2px solid var(--accent-primary);
}
```

**Heading hierarchy lógica.**

**Link purpose claro del texto del link:**

```html
<!-- ❌ "Click here" sin contexto -->
<a href="/pricing">Click here</a>

<!-- ✅ Link text descriptivo -->
<a href="/pricing">View pricing details</a>
```

### Input modalities (2.5)

**Tap targets ≥ 44×44px (touch):**

```css
button, a {
  min-height: 44px;
  min-width: 44px;
  /* o padding suficiente */
}
```

**No requerir gestos complejos** (multi-touch, pinch). Alternativa simple siempre disponible.

---

## Understandable

### Readable (3.1)

**`lang` en `<html>` (Critical en Lighthouse):**

```tsx
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html lang="es">  {/* o "en", según idioma principal */}
      <body>{children}</body>
    </html>
  )
}
```

**Idioma de partes específicas:**

```html
<p>El término <span lang="en">accessibility</span> se refiere a...</p>
```

### Predictable (3.2)

**Navegación consistente entre páginas.**

**No cambios de contexto inesperados** (no abrir nueva ventana sin warning, no auto-submit forms al cambiar input).

```html
<!-- Si link abre nueva pestaña, advertir -->
<a href="https://external.com" target="_blank" rel="noopener noreferrer">
  External link
  <span class="visually-hidden">(abre en nueva pestaña)</span>
</a>
```

### Input assistance (3.3)

**Errores claramente descritos y asociados al input** (ya cubierto en 1.3).

**Labels en TODOS los inputs.**

**Suggestions para corregir errores:**

```html
<label for="card-number">Número de tarjeta</label>
<input
  type="text"
  id="card-number"
  inputmode="numeric"
  autocomplete="cc-number"
  aria-describedby="card-error">
<span id="card-error" role="alert">
  Número inválido. Debe tener 16 dígitos.
</span>
```

**Confirmación antes de operaciones destructivas (R14 análogo a a11y):**

```tsx
// Confirmación typed para operaciones destructivas
<button
  onClick={() => {
    if (confirm('¿Estás seguro? Esta acción no se puede deshacer.')) {
      deleteAccount()
    }
  }}
  aria-describedby="delete-warning">
  Eliminar cuenta
</button>
<p id="delete-warning">Esta acción es permanente.</p>
```

---

## Robust

### Compatible (4.1)

**HTML válido:**

- Sin IDs duplicados (Lighthouse Critical si encuentra)
- Tags balanceados
- Attributes correctos

**ARIA usado correctamente:**

```html
<!-- ❌ ARIA ausente cuando elemento nativo basta -->
<div role="button" tabindex="0" onClick={...}>Submit</div>

<!-- ✅ Elemento nativo -->
<button onClick={...}>Submit</button>

<!-- ❌ ARIA roles redundantes -->
<button role="button">Submit</button>

<!-- ✅ Sin redundancia -->
<button>Submit</button>
```

**Status messages con role="status" o role="alert":**

```html
<!-- Alert: interrupción de usuario -->
<div role="alert">¡Error! Email inválido.</div>

<!-- Status: información no urgente -->
<div role="status" aria-live="polite">
  3 items added to cart.
</div>
```

---

## Lighthouse Accessibility audits — checklist

Lighthouse Accessibility 100 = sin issues automáticos. Audits críticos:

| Audit | Severity si fail |
|-------|------------------|
| `html-has-lang` | Critical |
| `html-lang-valid` | Critical |
| `image-alt` | High |
| `label` (inputs sin label) | High |
| `link-name` (links sin text) | High |
| `button-name` (buttons sin accessible name) | High |
| `color-contrast` | High |
| `meta-viewport` (sin viewport meta) | High |
| `heading-order` | Medium |
| `tap-targets` (< 48×48px en mobile) | Medium |
| `aria-valid-attr-value` | Medium |
| `duplicate-id-aria` | Medium |
| `bypass` (skip links) | Low |

## Manual checks (NO cubierto por Lighthouse automático)

Lighthouse cubre ~30% de WCAG. Manual mandatory:

- [ ] Keyboard navigation completa (sin trackpad/mouse)
- [ ] Screen reader testing (VoiceOver macOS / NVDA Windows / TalkBack Android)
- [ ] Focus order lógico (Tab a través de la página)
- [ ] Focus visible siempre
- [ ] Reflow correcto en zoom 400%
- [ ] Color contrast en estados (hover/focus/disabled)
- [ ] `prefers-reduced-motion` respetado
- [ ] Forms validation accesible (errors anunciados)

## Citation grammar

- [memory:CONSTRAINTS.md#R10] — Brand DNA contract incluye a11y rules en componentes generados.
- [memory:CONSTRAINTS.md#R13] — find-docs si chequeás WCAG 2.2 specifics.
- [docs:wcag] — guidelines canónicas si find-docs invocado.
- [docs:nextjs] — metadata API + layout.tsx lang.

## Anti-patterns

- ❌ `<html>` sin `lang` (Critical Lighthouse).
- ❌ `outline: none` sin replacement focus-visible.
- ❌ Solo color para error states.
- ❌ Tap targets < 44×44px en mobile.
- ❌ Auto-play media sin opt-out.
- ❌ Animaciones que ignoran `prefers-reduced-motion`.
- ❌ ARIA roles redundantes en elementos nativos.
- ❌ Modals sin focus trap o focus return.
- ❌ Forms sin labels asociados.
- ❌ Heading hierarchy con saltos (h1 → h3 sin h2).
