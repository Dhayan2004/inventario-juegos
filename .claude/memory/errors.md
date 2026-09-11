# Errors — Forja Memory

> Append-only log of errors encountered during Forja work, with root cause analysis.
> **Single writer:** `el-evaluador`. Other agents READ ONLY.
>
> **Format per entry:**
> - ID `E-NNN` (zero-padded, monotonic)
> - Date in ISO format
> - Context (where it happened)
> - Symptom (what was observed)
> - Root cause (what actually caused it)
> - Fix (how it was resolved)
> - Promotion (`-` if isolated, `→ L-NNN` if recurrent and promoted to lesson, `→ R-NNN` if promoted to constraint rule)
> - Cite as `[memory:errors#E-NNN]`

---

## E-001 — Retroactive R5 violations during F2-S7 (find-docs)

**Date:** 2026-05-07
**Context:** Phase 2 reopen for F2-S7 (find-docs). 4 commits que tocaron `.claude/memory/**` (skills.md, references.md, conventions.md) y CONSTRAINTS.md.

**Symptom:** los commits usaron scope `feat(F2-S7)` por instrucción explícita del spec del usuario, en lugar de `evaluator|memory` que R5 requiere.

**Commits afectados (sin retro-fix — historia preservada):**
- `b422d35 feat(F2-S7): register find-docs in memory/skills.md`
- `aa71795 feat(F2-S7): add R-007 (Context7) to memory/references.md`
- `4e80685 feat(F2-S7): add [docs:libname] citation grammar to conventions.md`
- `d9ee950 feat(F2-S7): add R13 (external docs citation) to CONSTRAINTS.md` — toca CONSTRAINTS.md no memory/, técnicamente fuera de R5 strict scope, pero el patrón de "decisión sobre regla" canónicamente vendría de evaluator.

**Root cause:** sin hooks de enforcement instalados (R5 es aspiracional pre-Fase 4), no hay gate técnico que rechace el scope incorrecto. El spec del usuario tomó precedencia sobre la regla. Sequencing fue: skill primero, enforcement después.

**Fix:** documentado, NO retro-fix (rewriting commit history es destructivo y los commits ya están en main). Forward-fix: Fase 4 instala el commit-msg hook que rechaza esta clase de commit a partir de F4 merge. R5 deviation registered in D-003.

**Status:** open (single occurrence; no recurrent pattern yet).

**Promotion path:**
- Si recurre (≥2 violaciones más en sesiones nuevas, post-instalación de hooks) → promover a `L-NNN` con lección "commits a memory/** requieren scope evaluator|memory desde día 1, aunque hooks no estén instalados; resistir spec overrides en esta clase de regla."
- Si no recurre tras instalación de hooks → close en next el-evaluador audit.

**Cita:** `[memory:errors#E-001]`

---

## E-002 — `tokens.spacing.section_y` array shape (R-005 v1.0) impide mapping deterministico a CSS vars con nombres semánticos

**Date:** 2026-05-08
**Context:** detectado durante F3-S2 (autoría del skill `impeccable`) al consumir `brand/brand.json` producido por add-ui-kit con preset TECH UTILITY.

**Symptom:** `brand.json.tokens.spacing.section_y` es un array de 3 ints (`[40, 64, 96]`). Para mapear a CSS variables semánticas (`--section-y-sm/md/lg`), `add-ui-kit/templates/brand.css.template` y `impeccable/prompts/generate-component-known.md` tuvieron que **inventar nombres** (sm/md/lg) basados en orden de array, no en declaración del schema. Mismo problema con `component_gap` (4-elem array → xs/sm/md/lg).

Implicación: si add-ui-kit cambia la cardinalidad del array (ej: extiende section_y a 5 niveles para proyectos ultra-densos), impeccable rompe silenciosamente porque el mapping `array[0]→sm, [1]→md, [2]→lg` se vuelve incorrecto. No hay validación schema-level que prevenga drift.

**Root cause:** R-005 sección 9.1 v1.0 define `section_y` y `component_gap` como arrays de ints, dejando la asignación de **nombres semánticos** implícita por orden. Esto es un caso de schema débilmente tipado — el contrato no captura la intención del autor (qué nivel es cuál).

**Fix:** evolucionar R-005 a v1.1.0 con keyed objects:
```
ANTES: section_y: [40, 64, 96]
DESPUÉS: section_y: {sm: 40, md: 64, lg: 96}

ANTES: component_gap: [4, 8, 12, 16]
DESPUÉS: component_gap: {xs: 4, sm: 8, md: 12, lg: 16}
```

Aplicado en F3-tighten-brand-dna mini-fase. Documentado en [memory:decisions#D-008].

Downstream regen: brand.json.template + brand.css.template + dry-run expected (TECH UTILITY) + 11 component expected outputs de impeccable.

**Status:** closed in F3-tighten-brand-dna mini-phase.

**Promotion path:**
- Aplica un patrón general: schema fields que codifican una jerarquía semántica deben usar keyed objects, no arrays posicionales. Si recurre en otra parte del schema R-005 (o en otros skills generators), promover a `L-NNN` con la regla: "schema fields representando jerarquía semántica usan keyed objects, no arrays posicionales."

**Cita:** `[memory:errors#E-002]`

---

## E-003 — `motion.personality.*` free-string viola L-003 (whitelist explícita)

**Date:** 2026-05-08
**Context:** detectado durante F3-S2 (autoría del skill `impeccable`) al escribir `prompts/generate-brand-css.md` paso 4 (easing derivation lookup).

**Symptom:** R-005 sección 6.1 v1.0 define `motion.personality.energy`, `elasticity`, `directionality`, `sequencing`, `distance`, `restraint` como **strings libres**. El generador (impeccable + add-ui-kit) tuvo que mantener una lookup table interna de valores conocidos (5 para energy: precise/calm/violent/ceremonial/mechanical) y caer en default + warning si el usuario emite un valor fuera de la lista.

Esto significa que un brand.json con `motion.personality.energy: "snappy"` (typo o sinónimo no enumerado) genera silenciosamente un easing default sin alertar. La validación es ad-hoc por skill, no schema-level.

**Root cause:** **el schema mismo viola [memory:lessons#L-003]**: "Validación de inputs externos por whitelist explícita, nunca strings libres con lookup tabular". El meta-issue es que la lección se aplicó a inputs de runtime (form validators, MIME types, tool args en LLM) pero NO se aplicó al schema canónico de Forja. Cierre del loop falta.

**Fix:** aplicar L-003 al schema R-005 mismo. Cada dimensión de `motion.personality` se vuelve enum cerrado en v1.1.0:
- `energy`: precise · calm · violent · ceremonial · mechanical
- `elasticity`: snap_not_bounce · bounce · glide · rigid
- `directionality`: mechanical · organic · physical · abstract
- `sequencing`: subtle_stagger · uniform · cascaded · instant_all
- `distance`: short · medium · long
- `restraint`: high · medium · low

Validación schema-level rechaza valores fuera del enum. add-ui-kit Discovery FRESH bloque (motion config) ofrece dropdown en lugar de free-text. Aplicado en F3-tighten-brand-dna mini-fase.

**Status:** closed in F3-tighten-brand-dna mini-phase.

**Promotion path:**
- **Esta es la observación meta más valiosa del cierre F3-S2:** L-003 aplica al schema Forja mismo, no solo a inputs runtime. Candidata a strengthening de L-003 (ampliar el contexto) o a una nueva lesson `L-NNN` que generalice: "Whitelist validation aplica a schemas internos canónicos, no solo a runtime inputs externos." Decisión de promoción se evalúa post-F3-S6 cuando haya más data points.

**Cita:** `[memory:errors#E-003]` · cross-cite `[memory:lessons#L-003]`

---

## E-004 — `archetype.allowed_behaviors` / `forbidden_behaviors` ambiguity entre documentación y enforcement

**Date:** 2026-05-08
**Context:** detectado durante F3-S2 (autoría del skill `impeccable`) al escribir `prompts/validate-anti-slop.md` y `prompts/compute-brand-score.md`.

**Symptom:** R-005 sección 9.1 v1.0 declara `archetype.allowed_behaviors` y `archetype.forbidden_behaviors` como arrays de strings descriptivos en español natural ("Mostrar herramientas y proceso, no solo resultados"). impeccable no puede enforcear contra strings libres — solo cita el array en JSDoc del componente generado para que el revisor humano lo vea.

El value real para enforcement vive en `tokens` + `anti_slop` + `validation` + `component_rules` (campos estructurados). Pero los prompts y la documentación de R-005 no clarifican esa frontera, lo que llevó a varios momentos durante F3-S2 build de "intentar parsear los strings de allowed_behaviors para inferir clases CSS" — esfuerzo descartado por inviable.

**Root cause:** R-005 sección 9.1 mezcla campos enforcement (machine-readable: tokens, validation thresholds, anti_slop patterns) con campos documentación (human-readable: archetype.allowed_behaviors strings descriptivos) sin distinguirlos visualmente ni en la sección de validación. Resultado: el agente generador o el evaluador puede asumir incorrectamente que allowed_behaviors es contrato enforceable.

**Fix:** clarificación documental en R-005 v1.1.0 sección 9.1, agregando una nota explícita:

> "Estos campos (`allowed_behaviors`, `forbidden_behaviors`) son **DOCUMENTACIÓN** para humanos y agentes downstream — citables en JSDoc, prompts, copy guidelines, README — pero NO son enforcement-able programáticamente. El enforcement de marca vive en `tokens`, `anti_slop`, `validation` y `component_rules` — campos estructurados machine-readable."

`el-evaluador` adopta la regla: validación contra `tokens` + `anti_slop` + `validation` (binary checks); citación de `allowed_behaviors` en outputs (informativo).

Aplicado en F3-tighten-brand-dna mini-fase.

**Status:** closed in F3-tighten-brand-dna mini-phase.

**Promotion path:**
- Si otro skill downstream (ai/, add-* skills) confunde documentación vs enforcement en otro campo del schema, promover a `L-NNN` con regla generalizada: "Schema fields documentation-level vs enforcement-level deben distinguirse explícitamente — sin distinción, agentes los confunden."

**Cita:** `[memory:errors#E-004]`

---

## E-005 — skills.md add-* entries inconsistency (stub-sin-Cita)

**Date:** 2026-05-08
**Context:** detectado durante F3-S3 (autoría del skill `add-login`) cuando se completó el entry de add-login en skills.md con Cita section completa (R10/R13/R14 + L-001/L-002/L-003 + D-007/D-009 + [docs:*]). Auditoría retroactiva de los otros 3 add-* (add-payments, add-emails, add-mobile) reveló el mismo gap.

**Symptom:** los 4 add-* entries de skills.md (Phase 1 skeleton) se llenaron solo con triple `Tier/Usar cuando/Requiere/Fallback`, sin reservar slot para `Dependencies` ni `Cita`. Un agente downstream consumiendo skills.md (orchestrator, otro skill que necesita planificar handoffs) no tenía visibility de:
- skills upstream que el add-* depende de (add-login, impeccable, add-ui-kit, baas, find-docs)
- citations aplicables (R10 cuando genera UI, R13 para libs externas, R14 para destructive ops, lessons aplicables)
- patrones cross-skill (D-009 default-by-friction-reduction reusable en Stripe/Polar y Resend/SendGrid)

Hasta que el skill se construyera, esa info quedaba implícita.

**Root cause:** Phase 1 estableció un schema mínimo para entries (Tier/Usar/Requiere/Fallback, lo justo para R6 — skill registry validation). Cuando los skills se construyen (Fase 2-3), el entry se enriquece con Cita section. Pero el enriquecimiento no es atómico al build — la auditoría de F3-S3 reveló que add-login mismo tenía el problema antes de F3-S3 close. Sin un norm "skills nuevos llevan estructura completa desde scaffold con citations vacías si no aplican", el gap se acumula silenciosamente.

**Fix:** auditoría retroactiva en F3-S3 close. Los 3 entries restantes (add-payments, add-emails, add-mobile) se actualizaron a la estructura uniforme (Tier + Usar + Requiere + Fallback + Dependencies + Cita) con citations applicable según el shape esperado del skill futuro (ej: add-payments cita R14 porque refund/cancelSubscription son destructive; add-mobile cita L-001 porque push_subscriptions es tabla user-data).

Commit: `evaluator(skills): retroactive Cita audit on add-payments/add-emails/add-mobile`.

Forward fix: futuros entries de skills nuevos (Phase 5, optional new skills) llevan la estructura completa desde su scaffold inicial. Las citations pueden estar vacías si el skill no se construyó todavía, pero el slot existe.

**Status:** closed (auditoría completada en F3-S3 close).

**Promotion path:**
- Si recurre en F3-S4..S6 (add-payments, add-emails, add-mobile cuando se construyan, descubren Cita section que no anticipó alguna lesson nueva o regla nueva, y al actualizar revelan inconsistencia con otros entries) → promover a `L-004` con la regla: "skills.md entries siempre con estructura completa desde scaffold, no solo triple Usar/Requiere/Fallback. Slot Dependencies + Cita reservado aún si vacío."
- Si NO recurre tras F3-S6 → cerrar como observación válida one-off, fix en place suficiente.

**Cita:** `[memory:errors#E-005]`

---

## E-006 — add-login PREFLIGHT chain con dependency chicken-egg potencial

**Date:** 2026-05-08
**Context:** detectado durante F3-S3 (autoría del skill `add-login`). El PREFLIGHT 7-gate de add-login require que `src/shared/components/ui/{Button,Input,Form}/*.tsx` exista — output de impeccable Mode C. impeccable Mode C a su vez require `brand/brand.json + voice.json` — output de add-ui-kit FRESH.

**Symptom:** un usuario que invoca add-login directo (sin pasar por orchestrator que componga la cadena `add-ui-kit → impeccable Mode C → add-login`) puede sentir el gate de PREFLIGHT como circular o opaco. Los halt + handoff messages indican qué falta, pero requieren que el usuario pase manualmente por las 3 sub-skills en el orden correcto. UX cognitive load.

Concretamente:
- Usuario corre `/add-login` → halt: "Falta src/shared/components/ui/Button — corré /impeccable Mode C primero"
- Usuario corre `/impeccable Mode C` → halt: "Falta brand/brand.json — corré /add-ui-kit primero"
- Usuario corre `/add-ui-kit` → Discovery FRESH interactivo, completa
- Usuario re-corre `/impeccable Mode C` → genera 11 components
- Usuario re-corre `/add-login` → finalmente arranca

3 invocaciones manuales para un objetivo que conceptualmente es "dame auth completa".

**Root cause:** los skills downstream tienen dependencies implícitas (add-login → impeccable → add-ui-kit) declaradas en `dependencies: [...]` y en PREFLIGHT, pero NO hay un orchestrator-wizard skill que componga la cadena automáticamente. Cada skill halt-handoff manualmente porque skills no invocan otros skills directamente (R4 — orchestrator stays thin) y porque no hay orchestrator que coordine.

**Fix:** mitigado en F3-S3 con halt + handoff message explícito que indica el siguiente skill a correr y cuáles inputs faltan. NO solucionado a nivel de UX wizard. La solución arquitectural correcta sería un orchestrator skill (ej: `init-frontend` o `add-login-stack`) que componga `add-ui-kit Discovery FRESH → impeccable Mode C → add-login Mode A` con confirmación intermedia. Eso es Fase 5+ scope.

**Status:** closed in F5-S1 (2026-05-09) — wizards init-saas (D-019) + add-monetization (D-020) resuelven el gap.

**Resolución (F5-S1):** se autorizaron 2 wizard skills nuevos que componen las cadenas frecuentes con detección resume-aware:

- **init-saas (D-019):** compone add-ui-kit → impeccable → add-login. Detecta state Fase 0 al estilo el-crisol y skipea pasos completados. FRESH default (chain completa) / EXISTING resume-aware (skip automático). Resuelve el gap de auth/UI cadena.
- **add-monetization (D-020):** compone add-payments → add-emails → web-quality. Mismo patrón resume-aware. Full chain default / partial payments-only override. Codifica la distinción crítica PAUSE-interno-delegado ≠ PAUSE-wizard como principio cross-wizards aplicable universalmente.

Resultado UX: usuario greenfield Forja ya no descubre halt-handoff en cadena al invocar add-login. Una invocación de `/init-saas` compone el setup completo (Brand DNA + components + auth) con detección automática de progreso parcial.

**Patrón establecido:** wizards Forja siguen shape canónico heredado de el-crisol (sequential pipeline + resume-aware state detection) con dependencies = lista de skills compuestos. Phase 5+ wizards futuros (add-mobile-stack, enterprise-stack, migration-wizard) heredan este patrón.

**Cita:** `[memory:errors#E-006]`

---

## E-007 — add-login template Input/Form props binding no validable runtime

**Date:** 2026-05-08
**Context:** detectado durante F3-S3 build cuando se escribieron los form components (LoginForm, SignupForm, etc.). Los templates asumen el shape de props que `Input` (output de impeccable) expone — específicamente `label`, `hint`, `placeholder`, `autoComplete`, `minLength`, `maxLength`.

**Symptom:** los templates referencian:
```tsx
<Input
  name="password"
  type="password"
  label="Contraseña"     // assumes impeccable Input has `label` prop
  hint="Mínimo 8 caracteres"  // assumes `hint` prop
  required
  autoComplete="new-password"
  minLength={8}
  maxLength={128}
/>
```

Si el Input que impeccable genera NO expone alguna de esas props (ej: `hint` no está declarado en su variant), el TSX templates no falla en L1 (TypeScript no lo chequea sin el archivo real), pero falla en runtime cuando el target compila.

**Root cause:** validation runtime real requiere proyecto target con `brand/` poblado + impeccable Mode C ejecutado. El repo Forja MISMO es factory, no app target — no tiene brand.json ni component output. add-login tests/dry-run.sh valida la presencia de `@/shared/components/ui/Input` import (L1) pero no la signature de Input (eso es L2 runtime contra el output real). Gap entre contract assumption y validation.

**Fix:** documentado handoff a el-guardian audit en proyecto target. Si shape diverge en runtime (target compila → falla), el-guardian lo captura en pre-deploy + retorna NEEDS_FIX al add-login con el gap específico. Add-login regen los form components con el shape ajustado.

Mitigación intermedia: SKILL.md de add-login + handoff-el-guardian.md mencionan que props Input se asumen (label/hint/placeholder/autoComplete/minLength/maxLength) — si impeccable evolucione su Input shape, el handoff lo flagea.

**Status:** mitigated in F5-S1 (2026-05-09) — `.claude/skills/impeccable/tests/component-contract.sh` autorizado.

**Mitigación (F5-S1):** el contract test valida cross-skill (3 grupos):

- **Grupo A — add-login (D-009):** brand.json `component_rules` tiene Button con variant `primary`, Input con props canónicas (label, placeholder, type, autoComplete, minLength, required). Form/FormField structure soft warning si missing.
- **Grupo B — add-payments (D-010):** Button variant CTA-friendly (checkout/cta/upgrade/primary), estado loading, Card component declarado.
- **Grupo C — add-emails (D-011):** tokens.colors.primary, tokens.typography (warn), semantic colors (success/error warn), voice.json existence.

Comportamiento del test:
- Si `brand.json` NO existe → SKIPPED informativo (no fail). Recomienda correr add-ui-kit primero.
- Si `brand.json` existe → valida los 3 grupos. PASS si zero contracts críticos rotos. WARN soft documenta gaps no críticos. FAIL solo si gaps críticos (ej: Button primary missing, Card missing, voice.json missing).

E-008 awareness + F3-S10/S11/S12 frictions absorbidas en el header del test.

**Validation runtime real:** ejecutable en proyecto target post-add-ui-kit + impeccable. Si brand.json declara los contracts, los add-* skills NO fallarán en runtime por props/variants ausentes. NO 100% garantía (props pueden estar declaradas pero no implementadas en .tsx generado), pero cierra el gap más crítico documentado.

**Status open**: aún se mantiene status `open` para el caso runtime divergence (props declaradas en brand.json + implementadas en .tsx generado pero divergiendo del shape esperado por add-* templates). Mitigación intermedia: el-guardian audit pre-deploy lo captura y devuelve NEEDS_FIX. Si recurre cross-skill como pattern de divergencia template-vs-runtime, considerar promoción a constraint o lesson en F6+.

**Cita:** `[memory:errors#E-007]`
- NO promote a L-NNN todavía — un solo data point.

**Cita:** `[memory:errors#E-007]`

---

## E-008 — Test grep escape recurrence en dry-run.sh (lightweight skills)

**Date:** 2026-05-08
**Context:** detectado durante F3-S7 primer + F3-S8 sprint. Ambos skills lightweight tuvieron micro-frictions con `\|` BRE syntax dentro de `grep -E` patterns y con header inconsistencies en `examples.md` grep matching.

**Symptom:** tests fallaban en patterns extended donde el `\|` debe ser `|` plain con flag `-E`. State matching muy estricto en algunos cases (ej: el test esperaba "Plan" como header standalone en cada escenario, pero examples.md naturalmente lo escribe como parte de la sección Triage en algunos casos).

Casos concretos:
- F3-S7 primer (`tests/dry-run.sh`): pattern `"NO Edit, NO Write|read-only — primer"` requirió `grep -E` con `|` plain (no `\\|`); state-matching `"Proyecto $state|en $state|cerca de $state|recién $state|estado $state"` extendido para tolerar fraseo natural.
- F3-S8 sprint (`tests/dry-run.sh`): triggers `"max iter\\|Ciclo 5\\|max-iterations"`, `"failure\\|falla"`, `"[Dd]esviación\\|divergence"`, boundary `"/build\\|la-forja"` fallaron con `\\|` literal — fix: usar `|` plain con `-E`. Check de "Plan" como header en cada escenario falló porque solo aparece 1 vez (Plan rápido vive dentro del Triage en escenarios 2-3, no como header propio).

**Root cause:** bash grep BRE/ERE syntax mismatch — con `grep -E` el `|` es alternation, mientras que `\|` es literal pipe. La inercia de BRE syntax (sin `-E`, donde `\|` es alternation) lleva a escribirlo así por costumbre. Asumir header consistency cross-escenarios en examples.md también es asumir más estructura de la que naturalmente emerge cuando los ejemplos son concretos (cada escenario tiene su propio voice).

**Fix:** ambos casos resueltos en el test mismo, sin tocar prompts/refs (preserva documentación legible). Pattern extended con flexibilidad: `Proyecto $state|en $state|cerca de $state|recién $state|estado $state`. Patrón canónico para `grep -E` con alternation: usar `|` plain, NO `\|` ni `\\|`.

**Status:** closed — F3-S9 la-forja NO recurrió (specific-to-lightweight-skills confirmed).

**F3-S9 outcome (2026-05-08):** test `.claude/skills/la-forja/tests/dry-run.sh` se escribió aplicando E-008 lesson preventivamente: (a) `grep -E` con `|` plain en TODOS los patterns alternation (162 grep invocations); (b) ventanas `-A` flexibles (`-A150` para Escenario 2 Fork con cherry-pick recomendación + cleanup que extiende ~80 líneas); (c) header matching con prefix `## ` en lugar de assumir consistencia strict. Resultado: 162 PASS / 1 FAIL en primera iteración (1 fail por ventana `-A60` insuficiente para Fork escenario, no por escape syntax). Fix one-line: `-A60` → `-A150`. Re-run: 163/163 PASS. **Cero ocurrencias de `\|` o `\\|` escape syntax issues.**

**Diagnóstico de NO recurrencia:** la-forja shape estructural distinto a primer/sprint lightweight:
- **primer/sprint:** prompt-only, sin templates folder, tests grep-densos sobre prompts/refs con assumption de consistency strict (cada escenario tiene mismo header → grep `^### Header$` cross-escenarios). Variación natural de docs rompe pattern.
- **la-forja:** write-capable orchestrator multi-archivo (15 archivos: SKILL.md + 8 prompts + 6 references + tests). Tests grep-densos también, PERO patterns flexibles desde diseño (la lesson E-008 informó la escritura del test). Cada escenario en `references/examples.md` tiene su propio shape (Coordinator: synthesis tabular; Fork: cherry-pick recommendation + cleanup; Swarm: 3 roles flow). Tests no asumen consistency strict, usan `-A` con margen amplio + `## ` prefix.

**Conclusión empírica:** E-008 fue specific-to-lightweight-skills (primer + sprint son los únicos casos donde las assumptions de header/escape tightness eran tentadoras). la-forja, con shape distinto, demostró que conocer el patrón previamente (E-008 lesson absorbida) basta para evitar recurrencia. **NO hay regla cross-skill universal nueva** — la "regla" es leer E-008 antes de escribir tests/dry-run.sh y aplicar `grep -E` con `|` plain + ventanas flexibles.

**Promotion outcome:** **NO promovida a L-005**. La lesson queda como E-008 capture cross-skill (primer + sprint = 2 ocurrencias documentadas) con caveat aplicado preventivamente en F3-S9. Si emerge una 4ta ocurrencia en futuros tests con shape similar a primer/sprint → re-evaluar promoción a L-005.

**No refactor de `match_or()` helper:** ROI sigue bajo. F3-S9 la-forja no necesitó helper — conocer el pattern canónico bastó. Decisión confirmada: defer hasta >3 ocurrencias persistentes que requieran abstracción.

**Cita:** `[memory:errors#E-008]`

---

<!-- E-009 onwards -->

## E-009 — add-ui-kit sobreescribió globals.css / tailwind.config.ts / layout.tsx en proyecto con codebase activa

**Date:** 2026-05-12
**Status:** closed — SKILL.md parchado + PREFLIGHT + Refusals + Tool filter actualizados.

**Context:** Proyecto ATS (Hila) migrado de Forge-Pro vía forge-eject. La codebase tenía tokens propios en globals.css (94 líneas con CSS vars --color-surface, --background, --border, etc.), sistema de tokens en tailwind.config.ts (clases bg-surface, text-ink, text-graphite, bg-cream), y layout.tsx con Toaster, providers y font vars. Al correr add-ui-kit, el skill asumió proyecto greenfield y sobreescribió los 3 archivos de forma destructiva.

**Root cause exacto (3 fallas independientes):**
1. **FRESH vs REDESIGN mal detectado.** La regla de detección era `>5 archivos UI → REDESIGN`. El proyecto tenía codebase activa pero el agente interpretó el contexto y ejecutó FRESH (error de adaptación de paths, no de conteo).
2. **Regla 7 ignorada al adaptar rutas.** El skill dice "NO modificar archivos fuera de brand/ y src/app/(brand)/showcase/". Al adaptar esa regla al proyecto (que no tiene prefijo ), el agente perdió la restricción crítica — `globals.css`, `tailwind.config.ts`, y `layout.tsx` quedaron fuera del scope protegido de forma accidental.
3. **Efecto "tapa de olla"**: La reescritura de layout.tsx eliminó una importación de `agentation` que causaba fallo de compilación previo. Al desaparecer ese fallo, el build avanzó y expuso ~25 paquetes Radix/Lucide/DnD Kit no instalados — confundiendo al usuario que vio errores nuevos que eran pre-existentes tapados.

**Impacto:**
- globals.css: 94 líneas → 7 (todas las CSS vars del proyecto eliminadas)
- tailwind.config.ts: tokens existentes reemplazados por hz-* nuevos; todas las clases Tailwind del proyecto (bg-surface, text-ink, etc.) rotas
- layout.tsx: font vars, Toaster, providers, agentation eliminados
- Cascada de errores de módulos no instalados expuestos por la eliminación del import de agentation

**Remediation aplicada:**
- PREFLIGHT: 3 gates nuevos (5-7) verifican contenido de globals.css, tailwind.config.ts, layout.tsx antes de ejecutar nada. Si cualquiera tiene >10 líneas propias → REDESIGN FORZADO con mensaje claro.
- Loop de ejecución: detección de modo ahora es contenido-based primero, file-count-based después.
- Regla 7: explicitada con nombre de archivo específico + acción permitida (append quirúrgico, nunca reescritura).
- Refusals: 3 prohibiciones explícitas nuevas para los 3 archivos.
- Tool filter: bloque "PROHIBIDO ABSOLUTO" nombra los 3 archivos con criterio de contenido.

**Cita:** `[memory:errors#E-009]`

---

## E-010 — F2-01 build roto tras add-ui-kit: alias import, Tailwind 4 vs 3, y `$` literal en comentario que el JIT scanner intentó resolver

**Date:** 2026-09-11
**Status:** closed — verificado en verde (typecheck, lint, brand:validate, build) tras el fix, sin cambios a `brand.json`/`voice.json`/`brand.css` (tokens intactos).

**Context:** F2-01 (Brand DNA, `chore/brand-dna`) había quedado marcado `passing` en `feature_list.json`, pero el build de la app (`npm run build`) fallaba. Root cause: tres fallas independientes introducidas al generar el showcase de `add-ui-kit` sobre un `package.json` que ya fijaba `tailwindcss ^3.4.0`.

**Root cause exacto (3 fallas independientes):**
1. **Alias `@/` roto en import de CSS.** `src/app/(brand)/showcase/page.tsx` importaba `@/brand/brand.css`, pero el alias `@/*` del `tsconfig.json` mapea a `./src/*` — `brand/` vive fuera de `src/`, así que el alias nunca resolvía ahí. El bundler (Turbopack/Next 16) fallaba al no encontrar el módulo.
2. **`globals.css` en sintaxis Tailwind 4** (`@import 'tailwindcss'`) **contra `tailwindcss ^3.4.0` instalado.** La sintaxis de import single-line es Tailwind 4; v3 requiere las tres directivas `@tailwind base/components/utilities`. Mismatch de versión entre el snippet generado (asumió v4) y la dependencia real del proyecto.
3. **Comentario en `sections/toast.tsx` con patrón bracket-literal `${token}`** que el scanner JIT de Tailwind (Lightning CSS vía Turbopack) interpretó como clase arbitraria con `$` sin resolver, y crasheaba en vez de ignorarlo como prosa. El scanner de Tailwind no distingue comentario de código — cualquier string que *parezca* una className arbitraria (`[...]` o con `$`) dentro del archivo escaneado es candidata a intentar resolverse.

**Fix:**
1. Import corregido a ruta relativa `../../../../brand/brand.css` (alias `@/*` no cubre nada fuera de `src/`).
2. `globals.css` migrado a `@tailwind base; @tailwind components; @tailwind utilities;` (sintaxis v3, matchea `tailwindcss ^3.4.0` en `package.json`).
3. Comentario de `toast.tsx` reescrito sin el patrón bracket-literal (`${token}`) — mismo significado, sin token que el scanner JIT intente resolver.

**Prevención (para próximos proyectos con add-ui-kit):**
- El alias `@/*` de Next.js apunta a `src/`, NUNCA asumir que cubre `brand/` u otras carpetas top-level — imports hacia `brand/` desde dentro de `src/app/` van con ruta relativa o un alias nuevo explícito.
- Antes de generar cualquier snippet de import CSS de Tailwind, LEER la versión real en `package.json` (`tailwindcss` v3 vs v4 tienen sintaxis de entrada incompatible) — no asumir v4 por default solo porque es la más reciente en docs.
- En archivos que el scanner JIT de Tailwind escanea (cualquier `.tsx` bajo `src/`), evitar escribir en comentarios/prosa patrones que parezcan className arbitraria (`${...}`, `[...]`) aunque nunca se rendericen como clase — el scanner es léxico, no semántico.

**Cita:** `[memory:errors#E-010]`

---

