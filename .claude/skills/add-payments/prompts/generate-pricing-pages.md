# Generate Pricing Pages — R10 enforcement

## Antes de empezar (R13)

Antes de generar el código de las pages, invocá `find-docs` si no se invocó ya en setup-{stripe,polar}:

```
1. resolve-library-id("nextjs") → query-docs
   query: "App Router server components client components dynamic params
           Next.js 16 generateMetadata"
2. resolve-library-id("react") → query-docs
   query: "Suspense streaming server components React 19"
```

**Razón:** /pricing es server component que reads pricing tiers + brand. /checkout es client (interacción con Stripe.js / Polar SDK). Confundir client/server boundary rompe `STRIPE_SECRET_KEY` isolation. Citar `[docs:nextjs]`.

## Pages target (4 total)

| Page | Path | Tipo | Consume |
|------|------|------|---------|
| `/pricing` | `app/(billing)/pricing/page.tsx` | Server component | brand.json tokens, voice.json CTAs, tier definitions del Tech Spec |
| `/checkout` | `app/(billing)/checkout/page.tsx` | Client component | server action `createCheckoutSession()` |
| `/success` | `app/(billing)/success/page.tsx` | Client component | useEffect polling profile.has_access |
| `/billing` | `app/(billing)/billing/page.tsx` | Server component | active subscription + customer portal entry CTA |

## R10 contract per page

Cada page lleva en su preámbulo:

```tsx
/**
 * /pricing page
 *
 * R10 Brand DNA gate enforced.
 * - Tokens leídos de brand/brand.json (vía CSS vars en brand.css).
 * - CTAs derivan de brand/voice.json#cta_examples (gate 7 SKILL.md
 *   con fallback conservador si genéricos).
 * - Componentes importados de @/shared/components/ui (impeccable output).
 * - NO Tailwind hardcoded colors (bg-purple-500, text-gray-700, etc.).
 * - Avoid_words audit corre en build time (test/anti-slop.sh).
 *
 * Cita: [memory:CONSTRAINTS.md#R10] · [memory:references#R-005]
 */
```

## Tier rendering

`/pricing` renderiza N tiers (1-4 típicamente). Cada tier es un `<Card>` de impeccable con:

```tsx
<Card variant="elevated" data-tier={tier.id}>
  <CardHeader>
    <Badge variant={tier.featured ? 'primary' : 'subtle'}>{tier.label}</Badge>
    <h3>{tier.name}</h3>
    <p className="price">
      {formatPrice(tier.amount, tier.currency, tier.interval)}
    </p>
  </CardHeader>
  <CardBody>
    <ul>
      {tier.features.map((f, i) => <li key={i}>{f}</li>)}
    </ul>
  </CardBody>
  <CardFooter>
    <Button
      variant={tier.featured ? 'primary' : 'secondary'}
      formAction={() => createCheckoutSession({ priceId: tier.priceId })}
    >
      {COPY_PRICING_CTA}
    </Button>
  </CardFooter>
</Card>
```

Las props `variant`, `data-tier`, `formAction` son contrato impeccable + Next.js — verificar shape con find-docs si dudás (E-007 prevention: el shape de `Button` en impeccable se asume `variant`, `formAction`, `disabled`).

## Tier source

Tier definitions vienen de:

1. **Tech Spec** (`TECH-SPEC-<nombre>.md` sec "Pricing"):
   ```yaml
   pricing:
     - id: hobby
       name: Hobby
       amount: 0
       currency: usd
       interval: month
       features: ['Until 100 users', 'Email support']
       priceId: price_REPLACE_HOBBY  # llenar tras crear en Stripe/Polar
     - id: pro
       name: Pro
       amount: 2000  # cents
       currency: usd
       interval: month
       featured: true
       features: ['Unlimited users', 'Priority support']
       priceId: price_REPLACE_PRO
   ```

2. **Inline en el template** si no hay Tech Spec (ej: 2 tiers default Hobby+Pro con amounts placeholder).

3. **User input** en interactivo si Tech Spec ambigua.

## Fallback CTAs (gate 7 PREFLIGHT)

Si voice.json `cta_examples` ≥3 entries pero ninguna matchea `/(suscrib|comprar|continuar|empezar|confirmar|pagar|finaliz)/i`:

```javascript
const FALLBACK = {
  pricing:  'Continuar al pago',
  checkout: 'Confirmar suscripción',
  success:  'Ir al panel',
  billing:  'Gestionar facturación',
};
```

Logger de el-evaluador captura esto: `add-payments using conservative CTA fallbacks because voice.cta_examples lacks payment-oriented entries`.

## Avoid_words audit

Después de substituir, antes de commit:

```bash
node -e '
const v = JSON.parse(require("fs").readFileSync("brand/voice.json"));
const avoid = v.voice.avoid_words || [];
const files = require("glob").sync("src/app/(billing)/**/*.tsx");
let violations = 0;
for (const f of files) {
  const content = require("fs").readFileSync(f, "utf8");
  for (const word of avoid) {
    const re = new RegExp("\\b" + word + "\\b", "i");
    if (re.test(content)) {
      console.error(`Voice violation: "${word}" in ${f}`);
      violations++;
    }
  }
}
process.exit(violations > 0 ? 1 : 0);
'
```

Falla → halt con lista de violations. NO commit.

## Tokens consumidos

Las pages consumen estos tokens del brand.json (vía CSS vars):

| Token | CSS var | Uso |
|-------|---------|-----|
| `tokens.colors.surface` | `--surface` | Card background |
| `tokens.colors.surfaceElevated` | `--surface-elevated` | Card featured |
| `tokens.colors.textPrimary` | `--text-primary` | tier names |
| `tokens.colors.textMuted` | `--text-muted` | feature lists |
| `tokens.colors.accent` | `--accent` | featured tier badge |
| `tokens.spacing.section_y.lg` | `--section-y-lg` | page padding vertical |
| `tokens.spacing.component_gap.md` | `--gap-md` | tier cards gap |
| `tokens.typography.h2` | `--type-h2` | tier name |
| `tokens.typography.price` | `--type-price` | price display |

R-005 v1.1.0 (keyed spacing) — citá `[memory:references#R-005]`.

## Brand Score per page

el-evaluador valida cada page contra brand.json (mismo loop que impeccable):

| Eje | Peso | Pass |
|-----|------|------|
| tokens (CSS vars usados, no hardcoded) | 25 | usa ≥6 vars del brand |
| components (impeccable imports) | 20 | importa Card/Button/Badge de @/shared/components/ui |
| accessibility | 30 | role=region, aria-label en tiers, focus visible, keyboard nav |
| anti-slop | 15 | hue range, no purple-500/blue-500 hardcode, no "Modern Minimal" cliches |
| voice | 10 | CTAs de cta_examples (o fallback documented), avoid_words PASS |
| **TOTAL** | **100** | **≥75 (target ≥85)** |

Si <75 → regenerate hasta 3 attempts. Después de 3 fails → halt y reportar a el-evaluador como E-NNN.

## Citations

- [docs:nextjs] · [docs:react] (R13)
- [memory:references#R-005] (Brand DNA schema, sección 9.1 spacing keyed)
- [memory:CONSTRAINTS.md#R10] (Brand DNA contract — pages consumen brand.json)
- [memory:CONSTRAINTS.md#R13] (external docs)
- [memory:errors#E-007] (props binding assumption — verificar shape de Button/Card antes)
