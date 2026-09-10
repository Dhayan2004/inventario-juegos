# Examples — 3 tajos canónicos

> Cada ejemplo muestra input → scope check → execute → commit. Pattern reconocible para sub-agents y humanos.

## Escenario 1 — Extraer componente

**Input:** "Extraé el bloque de pricing del hero a su propio componente `PricingTeaser.tsx`."

**Scope check:**
```yaml
outcome: execute
scope_estimate:
  wallclock_min: 4
  loc_delta: 120     # 60 LOC al nuevo file + 60 movidos del hero
  files_modified: 2  # nuevo PricingTeaser.tsx + Hero.tsx editado
```

**Execute:**
1. Crear `src/shared/components/PricingTeaser.tsx` con el bloque extraído (props tipados).
2. Editar `src/app/(marketing)/landing/Hero.tsx` para importar y renderear `<PricingTeaser />`.
3. Run `tsc --noEmit` → exit 0.

**Commit:**
```
refactor(F3-S?): extract PricingTeaser from Hero

Pricing block (60 LOC) extracted to standalone component.
Hero composition unchanged from user perspective.
```

**Tajo material confirmed.** No discovery, no planning, no loop.

---

## Escenario 2 — Bumpear dependencia

**Input:** "Bumpeá `zod` de v3.22 a v3.23.8 (latest patch)."

**Scope check:**
```yaml
outcome: execute
scope_estimate:
  wallclock_min: 2
  loc_delta: 5       # package.json + package-lock.json
  files_modified: 2
```

**Execute:**
1. `npm install zod@3.23.8` → actualiza package.json + lock.
2. Run `tsc --noEmit` para detectar breaking changes en imports → exit 0 (patch bump, sin breaking).
3. Run `npm test -- --findRelatedTests <files using zod>` opcional si proyecto lo soporta.

**Commit:**
```
chore(F3-S?): bump zod from 3.22 to 3.23.8

Patch bump. Zero breaking changes detected via typecheck.
```

**Tajo material confirmed.** Si bump fuera major (zod 3 → 4), escalate — typecheck probable falla en >3 archivos consumiendo schemas.

---

## Escenario 3 — Agregar tracking event

**Input:** "Agregá `posthog.capture('cta_clicked', { source: 'pricing-page' })` al onClick del botón 'Subscribe' en `/pricing`."

**Scope check:**
```yaml
outcome: execute
scope_estimate:
  wallclock_min: 3
  loc_delta: 8       # import + onClick handler
  files_modified: 1  # pricing/page.tsx
```

**Execute:**
1. Read `src/app/(marketing)/pricing/page.tsx` — confirmar que `posthog` ya está inicializado en root layout (sí).
2. Edit pricing/page.tsx:
   ```tsx
   // ANTES
   <Button onClick={handleSubscribe}>Subscribe</Button>
   
   // DESPUÉS
   import posthog from 'posthog-js'
   
   function handleSubscribe() {
     posthog.capture('cta_clicked', { source: 'pricing-page' })
     // ...lógica existente
   }
   ```
3. Run `tsc --noEmit` → exit 0.

**Commit:**
```
feat(F3-S?): track pricing CTA clicks with posthog

Event 'cta_clicked' with source='pricing-page' for funnel analysis.
```

**Tajo material confirmed.** Si SDK posthog NO existiera (instalar + configurar + tracking) → escalate a el-golpe.

---

## Anti-pattern observable: tajo escalation NO ejecutado

**Input:** "Refactorizá toda la auth para usar el nuevo `useAuth()` hook en lugar de `useSession()`."

**Scope check:**
```yaml
outcome: escalate
escalation_reason: |
  Refactor cross-archivo (estimado >10 archivos consumiendo useSession).
  Wallclock estimado >15min. LOC delta >800 (cada consumer needs migration).
  NO califica como tajo (criterios: <5min, <500 LOC, ≤3 archivos).
next_skill: el-golpe
```

**Output al usuario:**

```markdown
## Tajo escalation → el-golpe

**Razón:**
- Scope estimado: ~15min wallclock, ~800 LOC delta, ~10 archivos.
- Excede criterios atómicos (<5min, <500 LOC, ≤3 archivos).
- Refactor cross-archivo requiere brief-plan visible.

**Próximo paso:**
→ Invocá `/el-golpe` con la misma tarea. el-golpe maneja scope mediano
  con brief-plan visible (3-5 líneas mostrando archivos afectados).

NO es escalación negativa — es match correcto del skill al scope.
```

NO se ejecuta el cambio. el-tajo solo escala. el-golpe ejecuta.

---

## Tabla resumen — los 3 escenarios + anti-pattern

| Escenario | Outcome | Wallclock | LOC | Archivos | Razón clave |
|-----------|---------|-----------|-----|----------|-------------|
| 1: Extract componente | execute | 4min | 120 | 2 | Cambio mínimo, atomic |
| 2: Bumpear dep patch | execute | 2min | 5 | 2 | Patch bump, sin breaking |
| 3: Agregar tracking | execute | 3min | 8 | 1 | SDK ya instalado |
| Anti: refactor auth | escalate | 15min | 800 | 10 | Cross-archivo, brief-plan needed |

## Citation grammar

- [memory:CONSTRAINTS.md#R2] — atomic commit en cierre (los 3 escenarios cierran con 1 commit).
- [memory:decisions#D-016] — binary shape (execute / escalate-graceful, NO PAUSE).
- [memory:lessons#L-004] — informativo (binary aplicado).
