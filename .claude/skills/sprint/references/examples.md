# Examples — 3 escenarios reales de invocación sprint

## Escenario 1 — Copy iteration (CTA del hero)

### Context

- Proyecto: `customer-portal` (cliente B2B SaaS Forja-managed)
- Active feature: `F4-S2` (refinar landing post-launch)
- Brand archetype: Sage + Caregiver
- voice.json: tone professional + warm, evita marketing slop

### Invocación

```
Usuario: mejorá el copy del CTA del hero, ahora dice "Empezar ahora" y se siente genérico
```

### Triage (~30s)

```markdown
## Sprint: refinar CTA copy del hero

**Triage:**
- Atomicidad: NO (require iteración con feedback subjetivo del usuario)
- Iteración: SÍ (cada propuesta require feedback antes del siguiente)
- Scope: 5-10 min, 2-3 ciclos esperados

**Decisión:** sprint material (Pattern A — copy iteration).

**Plan rápido:**
- Ciclos esperados: 2-3
- Criterio: el usuario dice 'me gusta' Y matchea voice.json (professional + warm, no slop)
- Pre-pass: leer voice.json para anchor del tone
```

### Loop

#### Ciclo 1

**Cambio:** reemplacé `Empezar ahora` por `Probá Forja gratis 14 días` en `components/Hero.tsx:42`.

**Diff:**
```diff
- <Button>Empezar ahora</Button>
+ <Button>Probá Forja gratis 14 días</Button>
```

**Resultado observable:** CTA específico, comunica trial duration + sin riesgo. Tone neutral (no slop, no genérico).

**Tu turno:** `continúa` / `pause` / `done` / `escalate`.

#### Usuario: "más urgencia, sin perder el trial mention"

#### Ciclo 2

**Cambio:** reescribí con verb fuerte + trial compactado.

**Diff:**
```diff
- <Button>Probá Forja gratis 14 días</Button>
+ <Button>Forjá tu primer proyecto — 14 días gratis</Button>
```

**Resultado observable:** verb activo "Forjá" matchea brand product name. Trial preservado. Length similar (no overflow en mobile).

**Tu turno:** `continúa` / `pause` / `done` / `escalate`.

#### Usuario: "done"

### Cierre

```markdown
## Sprint cerrado — DONE

**Active feature:** F4-S2
**Cycles run:** 2 / 5
**Criterio cumplido:** voice match (verb activo + sin slop) + usuario aprobó

**Cambios:**
- Archivos modificados: `components/Hero.tsx`
- LOC delta: +1 / -1

**Commit:**
```
docs(F4-S2): refine hero CTA copy con verb activo
```

**Verificación post-commit:**
- typecheck: ✓
- lint: ✓

**Próxima acción sugerida:**
- Continuá F4-S2 — próximo step en feature_list.json (probable: refine secondary CTAs / hero subtitle / etc)
```

### Resultado

Sprint cerrado en ~6 minutos. 2 ciclos, 1 commit atómico, criterio cumplido.

---

## Escenario 2 — Styling iteration (spacing del hero)

### Context

- Proyecto: `internal-dashboard` (tooling B2B)
- Active feature: `F3-S2` (rediseño dashboard analytics)
- Brand archetype: Hero + Magician (Modern Minimal preset)
- brand.json: `tokens.spacing.section_y = {sm: 40, md: 64, lg: 96}`

### Invocación

```
Usuario: ajustá el spacing del hero hasta que se vea bien — ahora se siente apretado
```

### Triage (~30s)

```markdown
## Sprint: ajustar spacing del hero

**Triage:**
- Atomicidad: NO (require iteración visual con feedback)
- Iteración: SÍ (spacing depende del visual feel)
- Scope: 5-15 min, 2-3 ciclos esperados

**Decisión:** sprint material (Pattern B — styling iteration).

**⚠ Criterio borroso ("se vea bien"):** preguntar UNA pregunta antes de loopear.
```

#### Sprint pregunta:

> "¿Qué tendría que cumplir para que digas 'listo'? Comparado a un wireframe específico, o sensación visual ('más respirado', 'más denso')?"

#### Usuario: "más respirado, que el subtítulo no se pegue al headline"

```markdown
**Criterio actualizado:** spacing entre headline y subtítulo más amplio + sensación general de respiro vertical.

**Pre-pass R10:** leyendo brand.json → tokens.spacing.section_y = {sm: 40, md: 64, lg: 96}. Limitado a estos valores; NO override.
```

### Loop

#### Ciclo 1

**Cambio:** reemplacé `gap-2` (8px) por `gap-md` (que mapea a `--section-y-md` = 64px) entre headline y subtítulo en `components/Hero.tsx:23`.

**Diff:**
```diff
- <div className="flex flex-col gap-2">
+ <div className="flex flex-col gap-[var(--section-y-md)]">
   <h1>...</h1>
   <p>...</p>
 </div>
```

**Resultado observable:** spacing entre headline y subtítulo pasa de 8px a 64px. Hero se siente más "espacioso". Mobile: probablemente demasiado en sm breakpoint.

**Tu turno:** `continúa` / `pause` / `done` / `escalate`.

#### Usuario: "demasiado en mobile, ajustá responsive"

#### Ciclo 2

**Cambio:** mobile usa `--section-y-sm` (40px), desktop md+ usa `--section-y-md` (64px).

**Diff:**
```diff
- <div className="flex flex-col gap-[var(--section-y-md)]">
+ <div className="flex flex-col gap-[var(--section-y-sm)] md:gap-[var(--section-y-md)]">
   <h1>...</h1>
   <p>...</p>
 </div>
```

**Resultado observable:** spacing responsive — 40px en mobile, 64px en md+ desktop. Tokens de brand.json respetados (R10 OK).

**Tu turno:** `continúa` / `pause` / `done` / `escalate`.

#### Usuario: "done"

### Cierre

```markdown
## Sprint cerrado — DONE

**Active feature:** F3-S2
**Cycles run:** 2 / 5
**Criterio cumplido:** spacing más respirado + responsive + R10 (brand tokens, no override)

**Cambios:**
- Archivos modificados: `components/Hero.tsx`
- LOC delta: +1 / -1

**R10 check:** ✓ tokens consumidos via CSS vars derivadas de brand.json, sin override.

**Commit:**
```
style(F3-S2): adjust hero vertical spacing responsive con brand tokens
```

**Verificación post-commit:**
- typecheck: ✓
- lint: ✓
- visual diff (Lighthouse / manual): pending (no bloqueante)

**Próxima acción sugerida:**
- Continuá F3-S2 — próximo en feature_list.json (probable: ajustar otros componentes del dashboard)
- Considerá visual review en mobile + desktop antes de marcar passing
```

### Resultado

Sprint cerrado en ~8 minutos. 2 ciclos, criterio re-clarificado en triage (UNA pregunta), R10 enforced.

---

## Escenario 3 — Validator iteration (edge cases del payment form)

### Context

- Proyecto: `acme-billing`
- Active feature: `F4-S2` (Stripe webhooks + payment validators)
- L-003: whitelist explícita en validators

### Invocación

```
Usuario: iterá sobre el validator del payment amount hasta que cubra los edge cases — me reportaron 4 casos que pasan validation pero no deberían
```

### Triage (~30s)

```markdown
## Sprint: cubrir edge cases del payment amount validator

**Triage:**
- Atomicidad: NO (4 casos = 4 ciclos potenciales con verificación per-case)
- Iteración: SÍ (cada ciclo agrega cobertura de un caso, tests verifican)
- Scope: 5-15 min, 3-5 ciclos esperados

**Decisión:** sprint material (Pattern C — validator iteration).
```

#### Sprint pregunta:

> "¿Cuáles son los 4 edge cases? Necesito enumeración para criterio concreto."

#### Usuario: "negative amounts, NaN, extremely large numbers (>10^9), and floats con más de 2 decimales"

```markdown
**Criterio:** los 4 casos pasan tests:
1. `validate(-100)` → reject "negative not allowed"
2. `validate(NaN)` → reject "must be number"
3. `validate(1e10)` → reject "exceeds max"
4. `validate(99.999)` → reject "max 2 decimals"
```

### Loop

#### Ciclo 1

**Cambio:** agregué `negative` check + test.

**Diff:** (en `lib/validators/payment.ts` + `__tests__/payment.test.ts`)
```diff
+ if (amount < 0) return { ok: false, error: 'negative not allowed' }
+ // test: validate(-100) → { ok: false, error: 'negative not allowed' }
```

**Resultado:** test 1 PASS. Tests 2-4 todavía fallan (no cubiertos).

**Tu turno:** `continúa` / `pause` / `done` / `escalate`.

#### Usuario: "continúa"

#### Ciclo 2

**Cambio:** agregué `NaN` check.

**Diff:**
```diff
+ if (Number.isNaN(amount)) return { ok: false, error: 'must be number' }
```

**Resultado:** tests 1-2 PASS. Tests 3-4 fallan.

**Tu turno:** `continúa`.

#### Ciclo 3

**Cambio:** agregué `max amount` check (1e9 threshold).

**Diff:**
```diff
+ if (amount > 1_000_000_000) return { ok: false, error: 'exceeds max' }
```

**Tests 1-3 PASS.**

#### Ciclo 4

**Cambio:** agregué `decimal precision` check.

**Diff:**
```diff
+ const decimals = (amount.toString().split('.')[1] || '').length
+ if (decimals > 2) return { ok: false, error: 'max 2 decimals' }
```

**Resultado:** tests 1-4 PASS. Validator completo.

**Tu turno:** `continúa` / `pause` / `done` / `escalate`.

#### Usuario: "done"

### Cierre

```markdown
## Sprint cerrado — DONE

**Active feature:** F4-S2
**Cycles run:** 4 / 5
**Criterio cumplido:** los 4 edge cases cubiertos + tests PASS

**Cambios:**
- Archivos modificados: `lib/validators/payment.ts`, `lib/validators/__tests__/payment.test.ts`
- LOC delta: +12 / -0

**Verificación pre-commit:**
- typecheck: ✓
- lint: ✓
- tests: ✓ (4 nuevos PASS, regression suite OK)

**L-003 check:** ✓ whitelist + bounded ranges aplicados según [memory:lessons#L-003].

**Commit:**
```
fix(F4-S2): cubrí 4 edge cases en payment amount validator (negative/NaN/overflow/decimals)
```

**Próxima acción sugerida:**
- Continuá F4-S2 — próximo step en feature_list.json
- Considerá audit de otros validators del feature con mismo pattern (subscription amount, refund amount)
```

### Resultado

Sprint cerrado en ~12 minutos. 4 ciclos (uno por edge case), criterio enumerable cumplido, L-003 enforced.

---

## Anti-pattern observable: sprint que NO debería haber sido sprint

### Caso anti-pattern — "iterá hasta que pase CI"

```
Usuario: el typecheck está fallando, iterá hasta que pase
```

#### Triage

```markdown
## Sprint triage: HANDOFF

**Razón:** "pasar CI" no requiere user feedback subjetivo entre ciclos. El typecheck es deterministic — el agente lee el error, fixea, corre tsc, repite hasta exit 0. NO hay decisión que require feedback humano.

**Skill apropiado:** /el-tajo (atomic fix one-shot)

**Próxima acción:** corré `/el-tajo` con instrucción "fixeá los typecheck errors", el-tajo itera internamente sin user feedback per-iter.
```

NO sprint. el-tajo correcto.

---

## Citations

- [memory:lessons#L-003] (whitelist validators — Escenario 3)
- [memory:CONSTRAINTS.md#R10] (Brand DNA — Escenario 2)
- [memory:CONSTRAINTS.md#R2] (atomic commit format — todos los escenarios)
- [memory:CONSTRAINTS.md#R1] (active feature — todos los escenarios)
- [memory:lessons#L-004] (test diagnóstico — informativo, sprint no usa default+override pattern)
