---
name: add-marketing
description: >
  Capa de marketing CURADA para proyectos target — 11 métodos destilados de
  coreyhaines31/marketingskills (MIT, 44.8k★) tras vetting CYBERSEC de 5 pasos:
  product-marketing (fundación) · cro · copywriting · copy-editing · seo-audit ·
  programmatic-seo · site-architecture · schema · analytics · ab-testing ·
  onboarding. NO instala los 47 skills del repo (lección Vercel anti-bloat):
  cada método vive como reference destilada, con la fundación product-marketing
  DERIVADA de ONTOLOGY.md + SPEC.md cuando existen (no se re-entrevista lo que
  la Fase −1/0 ya levantó). Todo copy producido pasa por voice.json (R10) y el
  Anti-Slop Gate de el-evaluador. Read-mostly: produce análisis, copy y planes;
  los cambios de código van por el flujo normal (el-golpe / sprint / /build).
tier: optional
requires: nada duro. Mejora con ONTOLOGY.md (Fase −1), SPEC.md (Fase 0) y brand/voice.json (R10) presentes.
fallback: sin ontología/spec → levanta el contexto product-marketing preguntando (grill-me corto); sin voice.json → el copy queda en borrador marcado "sin voz de marca aplicada".
---

# add-marketing — capa de marketing curada (conversión · SEO · copy · analytics)

Marketing operativo para las apps generadas: optimizar conversión, auditar SEO,
escribir/editar copy, plan de analytics, experimentos A/B y onboarding.

## Cómo se usa

El usuario pide en lenguaje natural ("audita el SEO", "mejora el copy del hero",
"plan de analytics", "diseña el experimento A/B del pricing") o corre
`/add-marketing <área>`. El coordinador:

1. **Carga la fundación** — [`references/product-marketing.md`](references/product-marketing.md).
   Si el proyecto tiene `ONTOLOGY.md` (Fase −1) y/o `SPEC.md` (Fase 0), el posicionamiento,
   segmento, JTBD y lenguaje del cliente **se derivan de ahí** — no se re-preguntan (mismo
   principio que el CONTEXT.md de M4). Sin ellos: grill-me corto (≤5 preguntas, una por turno,
   recomendación obligatoria).
2. **Despacha al método** según el área pedida:

| Área | Reference | Produce |
|------|-----------|---------|
| Posicionamiento/mensaje | `product-marketing.md` | contexto fundacional que TODOS los demás leen primero |
| Conversión de páginas | `cro.md` | auditoría CRO priorizada (home/landing/pricing/forms) |
| Copy nuevo | `copywriting.md` | copy de página orientado a conversión |
| Editar copy existente | `copy-editing.md` | las 7 pasadas secuenciales, preservando la voz |
| Auditoría SEO | `seo-audit.md` | reporte técnico+contenido con plan priorizado |
| SEO programático | `programmatic-seo.md` | estrategia de páginas a escala (12 playbooks) |
| Arquitectura del sitio | `site-architecture.md` | estructura/clusters/internal linking |
| Datos estructurados | `schema.md` | JSON-LD por tipo de página |
| Medición | `analytics.md` | plan de eventos GA4/GTM orientado a decisiones |
| Experimentos | `ab-testing.md` | hipótesis + diseño estadístico + programa ICE |
| Activación | `onboarding.md` | flujo de onboarding orientado a "aha moment" |

3. **Aplica los contratos de Forja al output:**
   - **R10/voz:** todo copy final pasa por `brand/voice.json` — los references dictan el MÉTODO
     (estructura, jerarquía, especificidad); la VOZ la dicta el Brand DNA. Anti-slop aplica
     (nada de "streamline/optimize/unlock" — coincide con la regla de especificidad del propio método).
   - **R19:** si el trabajo revela que falta una promesa/página en el SPEC → surfacear, no editar el spec.
   - **Cambios de código** (meta tags, schema, eventos de analytics) → salen como handoff a
     `el-golpe`/`sprint`/`/build`, no los aplica este skill directamente.
   - **Cierre Ejecutivo** (`COMMUNICATION.md`): todo reporte termina en lenguaje de negocio + decisión guiada.

## Procedencia y vetting

- Destilado de [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)
  (MIT, © 2025 Corey Haines) el 2026-08-18 — 11 de 47 skills, elegidos por valor para apps
  SaaS/e-commerce generadas con Forja. Los frameworks conservan sus números exactos (7 sweeps,
  12 playbooks pSEO, CWV thresholds, ~7,000 usuarios/variante, ICE).
- Vetting `CYBERSEC_VETTING.md` aplicado en la destilación: sin instrucciones de fetch remoto en
  runtime, sin ejecución de shell, sin prompt injection. Referencias a skills NO curados eliminadas.
- Re-sync con upstream = re-correr la destilación (manual, no dependencia viva).

## Frontera (no cruzar)

- ❌ NO reemplaza a `el-crisol` (estrategia de negocio pre-build: precio, rivales, ROI) — esto es
  marketing OPERATIVO post-build sobre páginas/flujos que ya existen o se están construyendo.
- ❌ NO genera UI (eso es `impeccable` con R10) ni audita acabado visual (eso es `el-pulidor`).
- ❌ NO toca `feature_list.json`, memoria (R5) ni el spec (R19).
