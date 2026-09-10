---
description: "Revisión adversarial read-only del Blueprint/plan ANTES de /build — 5 fases (Scope · Arquitectura · Seguridad · Tests · Trayectoria) → veredicto EXPANSIÓN / MANTENER / REDUCCIÓN + FRAGUA-REVIEW.md (fragua-review, vive en el-crisol)."
---

# /fragua-review

Dispara una **revisión de arquitectura** read-only del Blueprint/plan de una feature o del proyecto,
**antes** de `/build`. La rúbrica canónica vive en
`.claude/skills/el-crisol/references/fragua-review.md` — el coordinador la recorre y sintetiza el veredicto.

`fragua-review` no toca código ni memory: **lee** el Blueprint (`.claude/PRPs/BLUEPRINT-<nombre>.md`),
el `SPEC.md`, la `ONTOLOGY.md` y `feature_list.json`, corre 5 fases de crítica adversarial y produce
`FRAGUA-REVIEW-<nombre>.md`. Es el complemento de arquitectura de `el-crisol`: donde `el-crisol` valida
si el **negocio** vale la pena (Go/Caution/No-Go), `fragua-review` valida si el **diseño** es correcto,
mínimo y construible.

## Cómo se ejecuta

Lee y aplica la rúbrica de [`.claude/skills/el-crisol/references/fragua-review.md`](../skills/el-crisol/references/fragua-review.md).
El coordinador de `el-crisol` (thin, read-only, R4) recorre las 5 fases **en orden** —cada fase produce
hallazgos citados a la línea del Blueprint— y al final sintetiza **un** veredicto:

```
/fragua-review                 # revisa el Blueprint del proyecto activo
/fragua-review <feature-id>    # acota la revisión a una feature de feature_list.json
/fragua-review --scope-only    # corre solo la Fase 1 (Nuclear Scope Challenge)
```

## Las 5 fases (resumen — detalle en la referencia)

| # | Fase | Pregunta central | Cruza con |
|---|------|------------------|-----------|
| 1 | **Nuclear Scope Challenge** | ¿Qué se puede **NO** construir? | minimalismo / YAGNI + Peldaño 0 ontológico (cada entidad/feature justifica su existencia contra el "ser" de la empresa en `ONTOLOGY.md`) |
| 2 | **Architecture** | ¿El diseño es correcto, acoplado lo justo, y feature-first? | Golden Path (`forge/CLAUDE.md`) + `ARCHITECTURE.md` |
| 3 | **Security / Edge Cases** | ¿Qué falla bajo entrada hostil o en el borde? | `threat-db.yaml` (la-herreria) + `ONTOLOGY.md › requisitos_seguridad` |
| 4 | **Tests** | ¿La estrategia de verificación prueba el comportamiento, no la implementación? | R7 Three-Layer Verification `[memory:CONSTRAINTS.md#R7]` (+ Layer 4 si multi-tenant) |
| 5 | **Trajectory** | ¿Este diseño nos deja mejor o peor para lo que viene? | roadmap del Blueprint + deuda declarada |

## Los 3 veredictos

| Veredicto | Significado | Handoff |
|-----------|-------------|---------|
| **EXPANSIÓN** | el diseño es demasiado angosto: falta cubrir un caso/edge/requisito que el negocio SÍ pide | volver a `/plan` (la-herreria) a ampliar el Blueprint |
| **MANTENER** | el diseño está bien calibrado — construir lo planeado, sin recortar ni ampliar | proceder a `/build` |
| **REDUCCIÓN** | el diseño construye de más (bloat / YAGNI): recortar antes de gastar sprints | volver a `/plan` a podar, o marcar el corte en `feature_list.json` |

## Output

`FRAGUA-REVIEW-<nombre>.md` (en `.claude/reports/`), con:

- **Registry de failure modes** — tabla `id · fase · severidad · síntoma · dónde en el Blueprint · fix propuesto`.
- **Diagramas ASCII** — el flujo/arquitectura propuestos, anotados con los puntos de riesgo.
- **Decisiones sin resolver** — preguntas de diseño abiertas que el humano debe cerrar antes de `/build`.
- **Veredicto** único + rationale citado por fase.

## Diferencia con sus parientes (no invadas su territorio)

| Skill / comando | Qué valida | Cuándo | Toca código |
|-----------------|-----------|--------|-------------|
| **`/crisol` (el-crisol)** | el **negocio / estrategia** — ¿vale la pena construir? (Go/Caution/No-Go) | post-Blueprint | no |
| **`/fragua-review`** (este) | el **diseño / arquitectura** del Blueprint — ¿es correcto, mínimo, construible? | post-Blueprint, **pre-`/build`** | **no (read-only)** |
| **`el-guardian`** | la **seguridad del CÓDIGO** ya escrito (auditoría adversarial con Codex) | pre-deploy, sobre `src/**` | no (audita código real) |

`fragua-review` critica **diseño en papel**, no código: no hay `src/**` que auditar todavía. Por eso es
`el-guardian` de diseño lo que `el-guardian` es de código — pero la seguridad que revisa aquí es la del
**plan** (¿el Blueprint contempla los requisitos de seguridad?), no la de la implementación.

## Refusals

- ❌ Escribir código o tocar `src/**` (es read-only sobre el plan).
- ❌ Escribir `feature_list.json` o `.claude/memory/**` (R5 — solo `el-evaluador`).
- ❌ Auto-evaluar un Blueprint que el mismo agente acaba de generar sin declararlo (AP3 — el que diseña no es el árbitro ideal).
- ❌ Emitir dos veredictos o ninguno — siempre **uno**: EXPANSIÓN / MANTENER / REDUCCIÓN.
- ❌ Correr sin Blueprint: si no hay `.claude/PRPs/BLUEPRINT-<nombre>.md`, halt + handoff a `/plan`.
