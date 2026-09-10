---
description: "Audita el acabado UI/UX read-only en 5 modos (critique con juez visual fresco / polish / normalize / redesign / cut antes del golden); produce reportes + handoff, NO genera (AP3) — el-pulidor."
---

# /pulidor

Lee y ejecuta `.claude/skills/el-pulidor/SKILL.md`.

`el-pulidor` es el **auditor de calidad de acabado UI/UX** de Forge Enterprise: **READ-ONLY ADVISORY**.
Consume el contrato Brand DNA (`brand/brand.json` + `voice.json`, R10) y reusa el Anti-Slop Gate de
`el-evaluador` (no lo reimplementa). **CRITICA/AUDITA y produce reportes + handoff; NUNCA genera ni
"arregla"** — esa frontera es AP3 (`impeccable` genera, `el-pulidor` critica, nunca la misma mano).

**Selector de modo** (pasalo explícito; sin modo, el skill pregunta UNA cosa):

| Modo | Invocación | Qué hace | Output |
|------|------------|----------|--------|
| **critique** | `/pulidor critique` | Rúbrica ~10 dims con código + **juez visual fresco** (`el-critico-de-diseno`, screenshot-only desktop+mobile, contexto vacío, cap 2, score = telemetría) → veredicto + issues + gaps + preguntas provocativas | `UI-CRITIQUE-<pantalla>.md` + `critiques/iter-k.md` |
| **polish** | `/pulidor polish` | Pasada pixel-perfect (spacing, typography, 8 estados, micro-interacciones, a11y fina) → checklist de fixes | `UI-POLISH-<pantalla>.md` |
| **normalize** | `/pulidor normalize` | Realinear con el design system (hardcoded→tokens, custom→componentes impeccable) → cambios propuestos | `UI-NORMALIZE-<area>.md` |
| **redesign** | `/pulidor redesign` | Auditoría full-project + plan ejecutable por fases (NO toca código hasta aprobación) | `REDESIGN-AUDIT.md` |
| **cut** | `/pulidor cut` | Pase de sustracción obligatorio antes de congelar un golden screen: candidatos a borrar (glows, contenedores, labels redundantes, custom peor que nativo) → el implementador aplica con OK humano | `UI-CUT-<pantalla>.md` + candidato golden |

**PREFLIGHT (R10):** sin `brand/brand.json` + `voice.json` válidos → halt + handoff a `/add-ui-kit` (sin
contrato no hay estándar contra el que auditar el acabado).

**Frontera (AP3, no cruzar):** `el-pulidor` NO edita `src/**`, NO escribe `brand/**` ni
`.claude/memory/**`. Produce el reporte y hace **handoff**: fixes de componente → `impeccable`; de
pantalla/flujo → `el-golpe`/`sprint`; si debe ser gate bloqueante → `el-evaluador` (único que firma).

**Anti-bloat:** `el-pulidor` NO duplica `web-quality` (performance/SEO/Lighthouse) ni `el-guardian`
(seguridad adversarial) ni `/despachar review` (correctness). Se queda en **acabado visual/UX**; deriva el
resto.

**Output esperado:** un reporte `.md` en la raíz del target (o `.claude/reports/`) + bloque de handoff con
el generador que aplica cada fix.
