# shadcn-ui ↔ brand.json variants mapping

> Lookup table consumida por los 3 generate-* prompts. Define cómo cada `component_rules.<x>.variants` mappea a un componente shadcn-ui upstream (cuando está disponible) o a primitives Tailwind from-scratch (cuando no).
>
> **Decisión arquitectural:** ver [memory:decisions#D-007] (forward-ref a próximo commit en este branch) — *"shadcn-customizado por default cuando shadcn está instalado, from-scratch como fallback"*.
>
> **Citation:** [docs:shadcn-ui], [docs:tailwindcss].

---

## Detección de shadcn-ui en el target

```bash
# 1. Existe components.json?
test -f components.json && echo "shadcn-ui detected"

# 2. package.json incluye class-variance-authority + tailwind-merge?
grep -E '"class-variance-authority"|"tailwind-merge"' package.json

# 3. Existe src/lib/cn.ts (o equivalente)?
test -f src/lib/cn.ts || test -f src/lib/utils.ts

# 4. Alias path tsconfig: "@/components/ui" mapea a algún path?
```

Si las 4 son afirmativas → **MODO shadcn-customizado**.
Cualquier ausente → **MODO from-scratch** (Tailwind primitives directo).

---

## MODO shadcn-customizado — mapping table

### Button (component_rules.button)

| variant in brand.json | shadcn primitive | impeccable customization |
|------------------------|------------------|---------------------------|
| primary | `<Button>` (default) | override `default` variant en cva con `bg-[var(--color-primary)] text-white` |
| secondary | `<Button variant="outline">` | override outline con `border-[var(--color-border)] bg-[var(--color-surface)]` |
| ghost | `<Button variant="ghost">` | override con `text-[var(--color-text-muted)] hover:text-[var(--color-text)]` |
| danger | `<Button variant="destructive">` | rename "destructive" → "danger" en variants enum, mantener `bg-[var(--color-danger)]` |

**Source:** `npx shadcn@latest add button` instala `@/components/ui/button.tsx`. impeccable lo extiende vía override del cva.

### Card (component_rules.card)

| variant | shadcn | impeccable |
|---------|--------|-----------|
| default | `<Card>` (estándar) | override default con `bg-[var(--color-surface-elevated)] border-[var(--color-border)] rounded-[var(--radius-md)]` |
| interactive | `<Card>` + `hover:` clases | añadir `cursor-pointer hover:bg-[var(--color-surface-higher)] transition-colors` |
| metric | `<Card>` + composición CardContent + display font | `<Card>` con custom child layout — usa `--font-display` para number, `--font-mono` para label |
| empty | `<Card>` + `EmptyState` propio | composición — Card con texto centered en `--color-text-muted` |

### Form primitives (component_rules.form)

| variant | shadcn | impeccable |
|---------|--------|-----------|
| text (Input) | `<Input>` | override con tokens — `bg-[var(--color-surface)] border-[var(--color-border)] focus-visible:ring-[var(--color-primary)]` |
| search (Input) | `<Input>` + Lucide Search icon left | composición wrapper — Input con icon padding |
| textarea | `<Textarea>` | mismo patrón que Input |
| select | `<Select>` (Radix wrapped) | tokens override + select trigger styling |

### Modal (component_rules.modal)

| variant | shadcn | impeccable |
|---------|--------|-----------|
| confirm | `<AlertDialog>` (Radix) | tokens override en overlay (--color-surface/80) y content (--color-surface-elevated) |
| form | `<Dialog>` (Radix) | mismo + child <form> renderable |
| detail | `<Dialog>` (Radix), max-width: lg | mismo + size prop |

### Navigation (component_rules.navigation)

| variant | shadcn | impeccable |
|---------|--------|-----------|
| sidebar | shadcn no provee fully — usar primitives | `<aside role="navigation">` con tokens |
| topbar | shadcn no provee fully — primitives | `<header role="banner">` con tokens |
| tabs | `<Tabs>` (Radix) | override active state con `border-b-2 border-[var(--color-primary)]` |
| breadcrumb | shadcn provee `<Breadcrumb>` reciente | tokens override |

---

## MODO from-scratch — primitives Tailwind directo

Cuando shadcn NO está instalado, impeccable genera el componente from-scratch usando:

```typescript
import { cva, type VariantProps } from 'class-variance-authority'
// ↑ requiere que el target tenga cva instalado, o impeccable lo agrega como dep

import { cn } from '@/lib/cn'  // o '@/lib/utils' (clsx + tailwind-merge wrapper)
// ↑ si no existe, impeccable genera src/lib/cn.ts:
//   export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)) }
```

Las clases base son las mismas que shadcn — el tradeoff principal es:
- shadcn-customizado: menos código generado, deps Radix UI en algunos componentes (Dialog, Tabs)
- from-scratch: más control, sin deps Radix, pero impeccable maneja focus-trap + escape handling manualmente

---

## Tabla resumen — qué incluye cada componente

| Component | shadcn-customizado | from-scratch | Radix dep |
|-----------|---------------------|--------------|-----------|
| Button | ✅ via shadcn add | ✅ Tailwind cva | NO |
| Card | ✅ | ✅ | NO |
| Input | ✅ | ✅ | NO |
| Textarea | ✅ | ✅ | NO |
| Select | ✅ | ⚠️ requires manual a11y | YES (`@radix-ui/react-select` if shadcn) |
| Modal.confirm | ✅ via AlertDialog | ⚠️ requires focus-trap + escape | YES (if shadcn) |
| Modal.form | ✅ via Dialog | ⚠️ same | YES |
| Navigation.tabs | ✅ via Tabs | ⚠️ requires manual ARIA tablist | YES (if shadcn) |
| Navigation.sidebar | from-scratch always | from-scratch always | NO |
| Navigation.topbar | from-scratch always | from-scratch always | NO |
| Navigation.breadcrumb | ✅ if shadcn ≥ recent | ✅ from-scratch | NO |

---

## Cómo el agente decide

```python
def select_mode(target_dir):
    if shadcn_detected(target_dir):
        # default: customize shadcn
        if user_prefers_no_radix:
            return "from-scratch"
        return "shadcn-customizado"
    else:
        if user_wants_shadcn:
            offer_npx_shadcn_init()
        return "from-scratch"
```

Si el usuario explícitamente pide "no Radix" o "minimal deps", `from-scratch` aún cuando shadcn está disponible. Documentar elección en el commit message.

---

## class-variance-authority (cva) pattern

Ambos modos usan cva — es la forma canónica de variants en TypeScript con autocompletion:

```typescript
import { cva, type VariantProps } from 'class-variance-authority'

const buttonVariants = cva(
  // base classes
  'inline-flex items-center justify-center font-medium transition-colors',
  {
    variants: {
      variant: {
        primary: 'bg-[var(--color-primary)] text-white',
        secondary: '...',
      },
      size: {
        sm: 'h-9 px-3 text-sm',
        md: 'h-10 px-4',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  }
)

type ButtonProps = ComponentPropsWithoutRef<'button'> &
  VariantProps<typeof buttonVariants>
```

Source: [docs:shadcn-ui] — cva es el patrón oficial. impeccable lo aplica idéntico en ambos modos.

---

## tailwind-merge (cn helper)

`cn(...inputs)` resuelve conflictos cuando el caller pasa className override:

```typescript
<Button className="bg-red-500" />  // override por usuario
// cn(buttonVariants({ variant: 'primary' }), 'bg-red-500')
// → tailwind-merge resuelve: la última gana → bg-red-500 (no bg-primary)
```

Sin `cn`, el primary token siempre overridearía al user override (orden CSS depende de specificity, no de orden Tailwind classes).

---

## Citations

| Source | URL/path |
|--------|----------|
| shadcn-ui docs | [docs:shadcn-ui] (vía Context7 — query "button card variants cva pattern") |
| Tailwind v3 arbitrary values | [docs:tailwindcss] |
| Radix UI primitives | [docs:radix-ui] (referenciable cuando se justifica) |
| cva package | npm `class-variance-authority` |
| tailwind-merge | npm `tailwind-merge` |

---

*"shadcn cuando está disponible. from-scratch cuando no. cva siempre."*
