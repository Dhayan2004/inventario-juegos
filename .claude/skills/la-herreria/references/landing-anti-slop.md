# Landing Anti-Slop — Patrones a evitar en landings AI-generadas

> Citable como `[memory:references#landing-anti-slop]`. Aplica en routes/landing-page.md y en el asset 08-ui.md cuando la página activa sea una landing.

Las 20 reglas anti-slop del Brand DNA Schema (R-005, sec 6) cubren UI en general. Esta guía aterriza el subset crítico para **landing pages** — la superficie donde más se nota el "AI-default look" y donde más impacta en conversión.

Brand DNA (`brand/brand.json` + `voice.json`) es contrato no negociable (R10). Si una decisión de copy o estilo entra en conflicto con esta guía, gana lo que diga el Brand DNA del proyecto target.

---

## Los 10 anti-patterns de landing AI-slop

### 1. Gradiente azul → morado en hero

El gradiente `from-indigo-500 via-purple-500 to-pink-500` (o variantes) es la firma visual de Tailwind defaults. Hue 235–285 sin justificación documentada → reject por Anti-Slop Gate.

**Alternativa:** color primario derivado de `tokens.color.primary` con un único acento. Si el hero necesita profundidad, usar opacidad sobre el primary o un noise/grain sutil. Gradiente solo si `voice.posture` lo justifica explícitamente (ej: BRUTALIST/EXPRESSIVE).

### 2. "Empower your business with AI" y derivados

Toda copy genérica con verbos vacíos (`empower`, `unlock`, `revolutionize`, `transform`) + objeto abstracto (`your business`, `your workflow`, `your potential`) + tecnología buzzword (`with AI`, `at scale`, `seamlessly`).

**Alternativa:** verbo concreto + sujeto específico + outcome medible. Tomar las 3 ventajas top del PDR/BMC del proyecto y traducir a copy con números o nombres de cosas reales del producto. Cita: `voice.json#cta_examples` y `voice.json#headlines`.

### 3. Tres cards idénticas con ícono + título + párrafo

El bloque "feature trio" con tres cards centradas, espaciado uniforme, ícono de Lucide arriba, título de 2 palabras, párrafo de 2 líneas. Lectura aburrida; el ojo no jerarquiza.

**Alternativa:** asimetría intencional — una card hero + dos secundarias, o un diff de tamaños 2:1:1. Cita el `component_rules.card` del brand. Si las 3 features tienen el mismo peso de negocio, replantear: probablemente una manda y las otras son consecuencia.

### 4. Inter 400 sobre fondo blanco puro

Fondo `#FFFFFF` + Inter Regular + texto `#0F172A`. Es el setup default de cualquier scaffolder, y se nota.

**Alternativa:** fondo desde `tokens.color.surface` (rara vez puro). Tipografía desde `tokens.typography` con jerarquía real (display vs body distintos pesos o familias). Si el proyecto exige Inter, al menos modular el peso (Display 700, Body 400) y dar contraste con un acento del brand.

### 5. Glassmorphism decorativo sin propósito

Cards con `backdrop-blur-md` + `bg-white/10` + `border-white/20` apiladas como decoración pura. El glass tiene sentido cuando hay capas reales de profundidad o cuando el `voice.posture` es ETHEREAL/SOFT — no como sticker visual.

**Alternativa:** elegir entre flat con sombra mínima, neumorphism del brand si está en `tokens.shadow`, o glass solo en superficies que estarían sobre contenido real (modales, popovers, cards con foto detrás).

### 6. Metric hero con emojis en lugar de números reales

`🚀 10x faster` / `⚡ Lightning fast` / `💎 Premium quality`. Emojis sustituyendo métricas de negocio reales. Es señal de que no se midió nada.

**Alternativa:** números concretos del producto o industria (`2.3s → 0.4s p95`, `400 invoices/h por usuario`, `87% retention a 30 días`). Si no hay datos reales todavía, decirlo (`beta — métricas iniciales en próximas 4 semanas`) en vez de fingir.

### 7. CTA genérico "Get Started" sin contexto

Botón huérfano `Get Started` o `Try Now` sin pista de qué pasa al click. Genera fricción cognitiva → caída en conversión.

**Alternativa:** CTA acción + objeto + outcome implícito. `voice.json#cta_examples` debe declarar 3+ variantes. Ej: `Crear mi primera factura`, `Probar sin tarjeta`, `Ver demo de 2 min`. Específico > genérico siempre, en el idioma del target.

### 8. Hero con imagen stock de persona sonriendo

Foto de Unsplash con personas en oficina con laptop sonriendo. Distrae del producto y se siente comprado.

**Alternativa:** screenshot real del producto, mockup del flujo principal, o ilustración custom alineada con `voice.archetype`. Si no hay producto todavía → diagrama del workflow esperado, no foto humana.

### 9. Sección "Features" con lista de 12 bullet points

Lista plana de 12 features en bullet points con check verde. Sin priorización, sin agrupación, sin valor diferenciado.

**Alternativa:** elegir las 3 ventajas top del PDR/BMC y ampliar cada una con un mini-bloque (título + 1 párrafo + screenshot/diagrama opcional). Las otras 9 features van a un `/features` separado o a un comparativo, no al hero scroll.

### 10. Footer con "Built with ❤️ by X"

Footer minimalista con corazón, año copyright y link a Twitter. No está mal per se — pero cuando aparece sin secciones legales (Privacy, Terms, contacto) en una landing que pide email/pago, es señal de "vibe coded sin pensar en compliance".

**Alternativa:** footer con Privacy, Terms, contacto (email real, no formulario), y opcionalmente "Built with [stack]" si el target audience valora transparencia técnica. Cita `legal-pages` del Tech Spec.

---

## Checklist pre-launch (10 binarios)

Marcar antes de invitar a mergear o deployar la landing:

- [ ] Hero **NO** usa gradiente hue 235–285 sin justificación en `brand.json#anti_slop.notes`
- [ ] Headline + sub-headline **derivan** de `voice.json#headlines` y `voice.json#tagline`, no son fillers
- [ ] CTAs visibles vienen de `voice.json#cta_examples` (no `Get Started` por default)
- [ ] Tipografía y colores del hero leen tokens de `brand.css` — `grep -n "indigo-\|purple-\|from-pink-" src/app/page.tsx` retorna 0 lines
- [ ] **No** hay imágenes stock de personas sonriendo (Unsplash, pexels, etc. fácilmente reverse-image-search-eable)
- [ ] Sección "features" tiene **3 features destacadas** (no 12 en bullets), cada una con copy de >1 línea
- [ ] Métricas usan **números reales** o están marcadas explícitamente como `beta`/`early access`
- [ ] Footer incluye Privacy, Terms y un email real de contacto (no solo Twitter)
- [ ] Glassmorphism / neumorphism solo aparece donde hay capas semánticas reales (modal, popover, card sobre imagen)
- [ ] `web-quality` (D-015) live audit pasa Performance ≥80 + A11y ≥95 + el-evaluador Anti-Slop Gate verde

Si **≥1 check falla**: NO mergear. Volver a `assets/08-ui.md` con findings, o pedir a `el-evaluador` el reporte completo del Anti-Slop Gate.

---

## Sources

- `.claude/references/BRAND_DNA_SCHEMA.md` (R-005, sec 6 anti-slop universal)
- `.claude/skills/la-herreria/assets/08-ui.md` (consume esta guía en el paso UI)
- `.claude/skills/la-herreria/routes/landing-page.md` (route que más cita esta guía)
- `.claude/skills/web-quality/SKILL.md` (Anti-Slop checks específicos en best-practices.md)
