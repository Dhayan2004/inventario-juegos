# Route: 🎯 Landing Page

> *"Primero pensá, después codificá. Copy aprobado antes del primer componente."*

## Metadata

- **Modo:** 🎯 Landing Page
- **Descripción:** página de alta conversión con pipeline copy-first y anti-AI-slop visual.
- **Tiempo estimado:** ~1 hora
- **Steps activos:** 4 + checkpoint de calidad
- **Cuándo usar:** cuando necesitás una página que convierte — no una app.

---

## Pipeline

```
Definición Rápida → Copywriting & Mensajería → Diseño Visual → [Review Anti-IA] → SEO & Deploy
      Step 1               Step 2                  Step 3          Checkpoint         Step 4
      10 min               20 min                  25 min           5 min             5 min
```

**No usa:** BMC completo, PDR, Tech Spec, UX Research, User Stories, UX Design, UI Workflow, Security Audit, Blueprint.

---

### Step 1 · Definición Rápida

- **Asset:** ninguno — entrevista directa.
- **Output:** `LANDING-BRIEF-[nombre].md` (inline, no archivo separado).
- **Tiempo:** ~10 min
- **Qué hace:** captura lo esencial para construir la landing.

#### Preguntas obligatorias

1. *"¿Qué es exactamente lo que ofrecés? Una frase."*
2. *"¿A quién va dirigido? Describí a esa persona."*
3. *"¿Cuál es el mayor dolor/problema que resolvés?"*
4. *"¿Cuál es el CTA principal? (registrarse, comprar, agendar llamada, unirse a waitlist)"*
5. *"¿Tenés prueba social? (testimonios, logos de clientes, métricas)"*
6. *"¿Hay urgencia o escasez? (early access, precio especial por tiempo limitado)"*
7. *"¿Tono? (profesional, casual, técnico, aspiracional, provocador, premium)"*

#### Preguntas de identidad visual

8. *"¿Hay alguna landing page que admires? Pasá la URL."*
9. *"¿Estilo visual?"* — opciones que conectan con presets de Brand DNA (R10):
   - **bento-grid** (default) → preset add-ui-kit *Modern Minimal*
   - **liquid-glass** → preset *Editorial Monocle*
   - **neobrutalism** → preset *Brutalist Experimental*
   - **warm-soft** → preset *Warm & Soft*
   - **tech-dense** → preset *Tech Utility*

#### Preguntas opcionales

10. ¿Tenés logo? (SVG preferido)
11. ¿Tenés testimonios escritos o screenshots de mensajes/reviews?
12. ¿Hay un deadline o urgencia real?
13. ¿Es standalone o parte de un funnel?
14. ¿Colores de marca? (si no tiene, proponer paleta vía preset elegido en pregunta 9)

**PUNTO DE CONTROL:** no avanzar a Step 2 sin respuestas a las preguntas 1–7.

---

### Step 2 · Copywriting & Mensajería

- **Asset:** `assets/copywriting-cro.md` (deferred F-tighten — incluye Reglas Anti-IA de Copy)
- **Referencia adicional:** `.claude/skills/impeccable/references/landing-anti-slop.md` → sección Checklist Copy
- **Output:** `COPY-[nombre].md` con toda la jerarquía de mensajería.
- **Tiempo:** ~20 min
- **Inputs requeridos:** `LANDING-BRIEF-[nombre].md` del Step 1.

#### Qué hace

Genera el copy completo ANTES de tocar código. Este es el paso más importante — copy mediocre con diseño premium sigue siendo mediocre.

#### Workflow de aprobación progresiva

1. **Primero:** definir jerarquía de mensajes (Pain / Gain / Differentiator / Proof / CTA).
2. **Después:** presentar 3 variaciones de headline (Outcome / Problem / Differentiation).
3. **Aprobar:** el usuario elige headline → generar subheadline y CTA button copy.
4. **Luego:** generar copy de todas las secciones restantes.
5. **Presentar resumen:** mostrar el copy completo por secciones para aprobación final.

#### Reglas activas

- Aplicar las **Reglas Anti-IA de Copy** del `copywriting-cro.md`:
  - Frases prohibidas: "Bienvenido a", "Solución integral", etc.
  - Tono café, no brochure.
  - Botones en primera persona.
  - Micro-copy de confianza.
- Psicología aplicada: Loss Aversion, Social Proof, Goal-Gradient, Hyperbolic Discounting.
- Form CRO: mínimo de campos según tipo de landing.
- **Voice contract (R10):** si existe `brand/voice.json`, los CTAs y micro-copy se derivan de `voice.cta_examples` — NO inventar slop genérico.

#### ⛔ PUNTO DE CONTROL CRÍTICO

> **Todo el copy debe estar aprobado por el usuario ANTES de empezar Step 3.**
> No se escribe ni una línea de código hasta que el `COPY-[nombre].md` esté aprobado.
> Esta es la regla #1 del pipeline. Copy primero, código después.

---

### Step 3 · Diseño Visual (R10 Brand DNA gate)

- **Asset:** `assets/front-end-design.md` → activa skill `impeccable` ([memory:skills#impeccable]).
- **R10 gate (mandatorio):** invocar `add-ui-kit` ([memory:skills#add-ui-kit]) si Brand DNA no existe — usar preset elegido en Step 1 pregunta 9 como starting point. Sin `brand/brand.json` + `voice.json`, halt.
- **Referencias adicionales:**
  - `.claude/skills/impeccable/references/landing-anti-slop.md` → anti-patrones visuales, tipografía, color, layout.
- **Output:** landing implementada en `src/features/landing/`.
- **Tiempo:** ~25 min
- **Inputs requeridos:** `COPY-[nombre].md` aprobado + Brand DNA presente.

#### Estructura de 10 secciones

```
1. Navbar      — Logo + máx 3 links + CTA button. Sticky con backdrop-blur.
2. Hero        — Headline resultado + subheadline + CTA + visual real + social proof badge
3. Problema    — 3 pain points en lenguaje del usuario. Storytelling, no bullets corporativos
4. Solución    — 3-4 pasos. Proceso, no features. Ícono/número + título + una línea
5. Features    — Bento grid o asimétrico. Resultado, no especificación técnica
6. Social Proof — Testimonios con nombre + foto + resultado. O screenshots de DMs/tweets
7. Pricing     — Anclaje de precio + máx 3 tiers + highlight recomendado + garantía
8. FAQ         — 4-5 objeciones REALES. Respuestas directas, no corporativas
9. CTA Final   — Repite headline del hero + CTA grande + micro-garantía
10. Footer     — Logo + links legales + contacto. Nada más
```

**Nota:** pricing y social proof son opcionales según el tipo de landing.

#### Reglas de código

1. **Fuentes:** Google Fonts premium via `next/font/google` [docs:nextjs] — pairings desde `brand.json typography.font_pairings`.
2. **Colores:** HSL/OKLch variables en `globals.css` — DERIVADOS DE `brand.json tokens.colors` (NO Tailwind defaults — R10).
3. **Layout:** bento grid para features, ritmo variable de spacing, asimetría.
4. **Imágenes:** `next/image` siempre. Reales > stock. Si no hay: tipografía + color.
5. **Responsive:** mobile-first. Hero en 375px. Touch targets 48px. Body 16px mín.
6. **Performance:** lazy load below the fold. Solo fonts que uses. LCP < 2.5s.
7. **Anti-Slop Gate:** post-generación, comparar contra `brand.json` reglas y hue range. Si falla → regenerate hasta 3 intentos.

#### Arquitectura de archivos (Feature-First)

```
src/features/landing/
├── components/
│   ├── navbar.tsx
│   ├── hero.tsx
│   ├── problem.tsx
│   ├── solution.tsx
│   ├── features.tsx
│   ├── testimonials.tsx
│   ├── pricing.tsx
│   ├── faq.tsx
│   ├── cta-final.tsx
│   └── footer.tsx
└── index.tsx            ← exporta el componente LandingPage completo

src/app/page.tsx   ← importa y renderiza <LandingPage />
```

#### No construir

- Auth, base de datos, backend — solo estático o Server Components.
- **Excepción:** si hay formulario de captación → API route mínima (`src/app/api/waitlist/route.ts`) con Zod validation L-003.

---

### Checkpoint · Review Anti-IA

- **Referencia:** `.claude/skills/impeccable/references/landing-anti-slop.md` → Checklist Review Anti-IA.
- **Tiempo:** ~5 min

#### Proceso

1. Pasar la **Checklist Review Anti-IA** (21 puntos: Visual + Copy + Técnico).
2. Si **3+ puntos fallan** → volver a Step 3 y corregir.
3. Si pasa → compartir screenshot/preview con el usuario.
4. Preguntar: *"¿Se siente diseñada por humano o por IA?"*
5. Si el usuario dice que se ve IA → usar las **soluciones de recuperación** de `landing-anti-slop.md`.

---

### Step 4 · SEO & Deploy

- **Asset:** `assets/seo-landing.md` (deferred F-tighten)
- **Output:** landing desplegada con URL pública + SEO implementado.
- **Tiempo:** ~5 min
- **Inputs requeridos:** `COPY-[nombre].md` + landing validada.

#### Qué hace

- `metadata` export en `layout.tsx`: title, description, og:image, twitter:card [docs:nextjs].
- JSON-LD: Organization + WebPage + FAQPage (si aplica).
- `public/robots.txt` con GPTBot, PerplexityBot, ClaudeBot, Google-Extended habilitados.
- Verificar LCP < 2.5s con `<Image priority>` en hero.
- Deploy: Vercel (`vercel --prod`) o Coolify según preferencia.

---

## Outputs Finales

| Entregable | Generado en |
|-----------|-------------|
| `COPY-[nombre].md` (mensajería completa y aprobada) | Step 2 |
| `src/features/landing/` (landing implementada) | Step 3 |
| Checklist Anti-IA passed | Checkpoint |
| URL pública en Vercel/Coolify | Step 4 |

---

## Qué se Omite y Por Qué

| Elemento omitido | Razón |
|-----------------|-------|
| BMC / PDR | La landing es el experimento — el business model se define si convierte |
| UX Research | Una landing tiene un usuario objetivo claro desde el brief |
| User Stories | No hay features — hay secciones y un CTA |
| UX Design | La landing tiene estructura probada + anti-slop guidelines |
| Security Audit | No hay datos sensibles ni backend complejo (excepto API route waitlist con Zod) |
| Blueprint | La landing se construye y se itera — no necesita plan de fases |

---

*"Copy aprobado antes del primer componente. Diseño con Brand DNA antes del deploy. Así se hace una landing que convierte."*
