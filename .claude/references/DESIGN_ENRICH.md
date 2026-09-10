# DESIGN_ENRICH — imagen, motion y video sin quemar dinero ni a11y (on-demand)

> Doctrina de enriquecimiento visual (Anshu Técnicas 4–5 · Nate Herk ScrollCraft · HIG/WCAG). **No es un
> skill ni un comando** — es la referencia que `la-herreria` (asset 07/08), `add-ui-kit` (motion) y
> `el-pulidor` (`cut`) consultan cuando el diseño pide "más personalidad". El guardrail duro vive en
> `CONSTRAINTS.md` **AP9** (gasto externo sin confirm). D-037.
> Cita: `[memory:CONSTRAINTS.md#AP9]` · `[memory:CONSTRAINTS.md#R15]` · `[memory:references#R-005]` §6.

## 0. El orden de la escalera (barato y accesible primero)

| Peldaño | Herramienta | Cuándo |
|---|---|---|
| 1 | **CSS / Motion / Lottie / Rive** (vector, scrubbable, pausable, respeta `prefers-reduced-motion`) | default de todo enriquecimiento. `motion.ts` (`brand/motion.ts`) es el runtime; se extiende, no se duplica |
| 2 | **Imagen generada** (mata el CSS-slop: gradientes, orbes, patrones = *AI tell*) | cuando el diseño está "plano" y el peldaño 1 no alcanza. Provider: nativo → Codex CLI (sub ChatGPT) → key en `.env.agents` → **dry-run** |
| 3 | **Video** (loop + matte · interpolación de keyframes · scrub-on-scroll) | solo si el efecto no es reproducible en vector **y** el humano autorizó gasto **y** pasa el gate a11y (§3). Agregador: fal.ai con `FAL_KEY` + spend cap |
| ⛔ | **Higgsfield / Forge Studio (Mac mini, Tailscale MCP) / Kie / cualquier estudio que cobra por escena** | nunca implícito. Frase de autorización explícita en el turno + UN job (AP9) |

Regla de Anshu que Forja convierte en doctrina: la Técnica 5 (video) **sin** la 6 (cut) produce motion
por motion. Se acoplan: enrich → `cut` → golden.

## 1. Keys — `.env.agents` (R15 fail-closed)

- Plantilla commiteable: `.env.agents.example` (placeholders `*_REPLACE_ME` + `*_SPEND_CAP_USD`). El
  archivo real `.env.agents` está gitignored; el agente lee el **path**, nunca imprime la key, nunca la
  escribe en código, producto, logs ni chat.
- Keys **dedicadas** por proveedor, con spend cap tenso y fáciles de revocar.
- Sin key ni Codex CLI ni tool nativo → **dry-run**: se escribe `design-lab/<run>/enrich-plan.md` (qué
  imagen, qué shader, qué slot) y se para. No se inventa una key ni se pide "pégamela para guardarla".

## 2. Recetas (fences ejecutables — se pegan tal cual)

**Enrich con imagen (Técnica 4):**

```text
The design is pretty plain. Add more personality using image generation. Consider shaders or 3D effects
in combination with images to create more interesting visuals.

Provider order: (1) built-in image tool if any; (2) Codex CLI billed to the ChatGPT subscription, not an
API key; (3) OPENAI_API_KEY or GEMINI_API_KEY from gitignored .env.agents.
Only use keys locally. Do not store a key in the code or product. Do not print it. If no provider, write
design-lab/<run>/enrich-plan.md and stop (R15 fail-closed).

Verify that your work looks right frame-by-frame in the browser.
```

**Motion dry-run (default):**

```text
DRY-RUN. No fal.ai, no Higgsfield, no MCP de Forge Studio.
Escribe design-lab/<run>/motion-storyboard.md: shots, loop vs keyframe interpolation, chroma/matte, dónde
se layera en la UI, fallback para prefers-reduced-motion (crossfade, no parallax, no spin 3D). Si el
efecto es glass: render over page background colors THEN matte.
Extiende stubs en brand/motion.ts (play-on-nav / scrub-on-scroll) sin red. Para cuando el storyboard esté.
```

**Video loop + matte (solo con "autorizo gasto fal.ai"):**

```text
Autorizo gasto fal.ai con FAL_KEY en .env.agents y el spend cap del archivo.
Replace the image with a looping video clip that does something more interesting. To get convincing
glass refraction, render the video over the page background colors first (bakes the refraction), then
remove the background with a video matting model. Find appropriate recent models for video generation
and background removal. Never print the key. Never commit it. Never call Higgsfield.
```

**Keyframe interpolation / scrub-on-scroll (fixture "maleta", Seedance-class):**

```text
Autorizo gasto fal.ai (FAL_KEY en .env.agents, spend cap del archivo). Never print the key. Never call
Higgsfield. Generate the initial frame with the image skill; generate a clip from that frame to the next
state; use the final frame to seed the next transition so it continues seamlessly; scrub through the
transitions as the user scrolls. Use a video model with strong physics and consistency.
```

**Higgsfield / Forge Studio (gated — sin esta frase, no hay llamada MCP):**

```text
Autorizo UN job Higgsfield / Forge Studio en el Mac mini (Tailscale MCP) para la escena de
motion-storyboard.md. Un job. Luego para y reporta costo. Si el MCP no responde, no reintentes en loop.
```

## 3. Gate a11y post-enrich (A11 — se corre SIEMPRE después de imagen/motion/video)

Si el enrich rompe cualquiera de estos, se revierte. Anshu verifica "frame a frame"; Forja verifica
*usuario con trastorno vestibular*.

| Check | Regla | Fuente |
|---|---|---|
| `prefers-reduced-motion` | toda animación de movimiento (transform/parallax/scroll-scrub/video) tiene fallback (crossfade o estático); `reduce_motion_default: true` en producto de trabajo | HIG Motion / `accessibilityReduceMotion` |
| pause on-page | movimiento que arranca solo, dura >5 s y va en paralelo a contenido → control on-page para pausar/parar/ocultar (`prefers-reduced-motion` **no** sustituye el control) | WCAG 2.2.2 |
| autoplay | video muted + `playsinline` + poster estático + botón unmute; con audio se bloquea (Chrome Autoplay Policy) | Chrome |
| peso | video ≤ presupuesto de la página (`web-quality` LCP/TBT); nunca un mp4 como golden — golden = frame 0 + storyboard | `QUALITY_GATES.md` §4 |
| capas | parallax = planos a distinta velocidad **como máximo**; no fly-through 3D en producto de trabajo (landing de campaña, con pausa) | Nate Herk / HIG |
| animables | solo `transform`/`opacity` (lista `SAFE` de `motion.ts`); `exit ≈ 75% enter`; nunca `width/height/top/left` | `anti-slop-gate.sh` check 11 |
| glass | `backdrop-blur` en navegación/chrome, no en cards de contenido (HIG Liquid Glass: materiales estándar en contenido) | HIG Materials |
| contraste | texto sobre imagen/video generado sigue ≥ 4.5:1 (overlay o placa) | WCAG AA |

## 4. Registro

`design-lab/<run>/COST.md`: modelo del crítico vs implementador, iteraciones, llamadas de imagen/video y
USD aproximados (`la-herreria/references/llm-cost-optimization.md`). Toda decisión de gasto real
(fal.ai / Higgsfield) va a `.plan/decisions[]` con la frase de autorización citada.

## Sources

- Anshu Chimala, *How to turn your AI into a world-class designer* (Lenny's Newsletter, 2026-09-01) — Técnicas 4–6.
- Nate Herk, *Fable 5.1 FINALLY Kills AI Website Slop* (X, 2026-09-02) — 7 entradas, ScrollCraft, layering.
- Apple HIG — Motion · Materials / Liquid Glass · `accessibilityReduceMotion`.
- W3C WCAG 2.2 — SC 2.2.2 Pause, Stop, Hide · SC 2.3.3 Animation from Interactions.
- Chrome Autoplay Policy (Beaufort) · fal.ai Seedance 2.5 / VEED background removal · Higgsfield credits.
