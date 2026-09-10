# analyze-gaps

> Fase 1 de migration-wizard. Analiza el estado actual del proyecto vs Bootstrap Contract de Forja (R11) + extras Forja Enterprise. Identifica gaps críticos y reusable. Output alimenta Fase 2 (build-plan.md).

## Inputs

- Output de `detect-origin.md` (Tipo A/B/C/D/E + evidence).
- Project root path.

## Output

```yaml
analysis:
  bootstrap_contract:
    R11_1:  # make setup / package.json + deps
      status: pass | fail | warn
      evidence: <texto>
    R11_2:  # ≥1 test passing
      status: pass | fail | warn
      evidence: <texto>
    R11_3:  # feature_list.json
      status: pass | fail
    R11_4:  # .claude/memory/skills.md
      status: pass | fail
    R11_5:  # brand/brand.json + voice.json (R10)
      status: pass | fail

  forja_enterprise_extras:
    AGENTS_md:
      status: pass | fail
    CLAUDE_md_factory_os:
      status: pass | fail
    hooks_installed:
      status: pass | fail | warn
    memory_store_7_files:
      status: pass | fail | partial
    git_conventional_commits:
      status: pass | fail | warn
    rls_user_id_tables:
      status: pass | fail | n_a       # n_a si no hay BaaS
    r14_destructive_tools:
      status: pass | fail | warn

  reusable:
    skills_existentes:
      list: [<skill names>]
      mapped_to_forja: [<list>]
      to_archive: [<list>]
    blueprint_or_planning_docs:
      found: bool
      paths: [<list>]
    brand_or_design_system:
      found: bool
      compatible_r005: bool
    tests_existentes:
      found: bool
      framework: <vitest | jest | mocha | none>
      count: <number>
    db_migrations:
      found: bool
      paths: [<list>]
      rls_l001_present: bool
    api_routes:
      found: bool
      compatible_with_zod_l003: bool

  gaps_criticos:
    - id: gap-N
      description: <texto>
      blocks_build: bool
      forja_action: <texto>
      forja_command: <texto>
      estimacion_min: <number>

  total_gaps: <number>
  total_reusable: <number>
  estimacion_min_bootstrap: <number>
  estimacion_min_enterprise: <number>
```

## Step-by-step

### Paso 1 — Bootstrap Contract Gates (R11)

#### R11-1: make setup / package.json + deps

```bash
test -f package.json
[ -d node_modules ] || npm install --dry-run 2>/dev/null
```

- pass: package.json + deps instalables.
- fail: sin package.json o deps incompatibles.
- warn: package.json existe pero sin Next.js (Tipo D).

#### R11-2: ≥1 test passing

```bash
# Buscar tests
find . -path ./node_modules -prune -o \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -print | head -5
# Verificar test runner en package.json
grep -E "vitest|jest|mocha" package.json
```

- pass: ≥1 test file + test runner configurado.
- fail: no hay tests.
- warn: tests existen pero runner no está configurado.

#### R11-3: feature_list.json

```bash
test -f feature_list.json
```

- pass: existe + ≥3 features con verification command.
- fail: no existe.

#### R11-4: skills.md generado

```bash
test -f .claude/memory/skills.md && grep -c "^### " .claude/memory/skills.md
```

- pass: existe + skills declarados (≥10 entries esperado).
- fail: no existe o vacío.

#### R11-5: Brand DNA (R10)

```bash
test -f brand/brand.json
test -f brand/voice.json
test -f brand/brand.css
```

- pass: los 3 existen + brand.json parseable.
- fail: alguno falta.

### Paso 2 — Forja Enterprise Extras

#### AGENTS.md

```bash
test -f AGENTS.md
```

#### CLAUDE.md Factory OS

```bash
test -f CLAUDE.md && grep -E "Factory OS|Decision Router|Brand DNA" CLAUDE.md
```

#### Hooks instalados

```bash
test -f .git/hooks/pre-commit
test -f .git/hooks/commit-msg
ls .git/hooks/ | grep -E "pre-commit|commit-msg"
```

#### Memory store (7 typed files)

```bash
ls .claude/memory/{lessons,errors,decisions,conventions,glossary,references,skills}.md 2>/dev/null | wc -l
```

- pass: 7/7.
- partial: 1-6.
- fail: 0.

#### Git conventional commits

```bash
git log --oneline -20 | grep -cE "^[a-f0-9]+ (feat|fix|refactor|chore|docs|test|style|perf|ci|build|evaluator|memory)\("
```

- pass: ≥80% de los últimos 20 commits matchean conventional.
- warn: <80% pero ≥50%.
- fail: <50% (R2 enforcement requerirá hook).

#### RLS L-001 en tablas con user_id

```bash
# Si hay supabase/migrations/
find supabase/migrations -name "*.sql" 2>/dev/null | xargs grep -l "user_id" | xargs grep -L "ENABLE ROW LEVEL SECURITY"
```

- pass: todas las tablas con user_id tienen RLS enabled.
- fail: hay tablas con user_id sin RLS (gap CRÍTICO L-001).
- n_a: no hay BaaS / no hay migrations.

#### R14 destructive tools

```bash
grep -rE "tool\(\{[^}]*execute:" src/ --include="*.ts" 2>/dev/null | grep -iE "delete|send|transfer|cancel|refund" | head -5
```

- pass: 0 matches (no tools destructivas con execute() automático).
- fail: hay matches → R14 violation, mandatory fix.
- warn: no se puede determinar (no hay tools agentic en src/).

### Paso 3 — Reusable

#### Skills existentes

```bash
ls .claude/skills/ 2>/dev/null
```

Mapear cada skill encontrado contra Forja registry (skills.md). Por nombre exacto:
- ✅ Mapped to Forja: el skill puede ser portado o reusado.
- ⚠️ Diferent name pero misma función: candidato a port con rename.
- ❌ No mapping: archivar (no usar en Forja Enterprise).

#### Blueprint / planning docs

```bash
find . -maxdepth 3 -name "BLUEPRINT*.md" -o -name "PRD*.md" -o -name "PLAN*.md" 2>/dev/null
```

Si existen → reusar como input de la-herreria asset 10 (master-blueprint).

#### Brand / design system

```bash
test -f brand.json
test -f BRAND.md
ls .claude/design-systems/ 2>/dev/null
test -f tailwind.config.ts && grep -E "theme.extend.colors" tailwind.config.ts
```

Si existe en formato distinto a R-005 → migrar a brand.json + voice.json.

#### Tests existentes

```bash
find . -path ./node_modules -prune -o \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \) -print | wc -l
grep -E "vitest|jest|mocha" package.json
```

#### Pagos existentes (D-038 — brownfield con Stripe / Mercado Pago / Polar ya integrado)
- Glob `src/app/api/webhooks/**`, `**/stripe*`, `**/mercadopago*`, `**/polar*`, `lib/payments/**`.
- Si existe integración: correr `bash .claude/skills/add-payments/tests/payments-gate.sh <dir>` (PAY-001..008: webhook sin firma, body antes de verificar, idempotency débil, `* 100` sin exponente, `===` en firma, refund en rail irreversible, HMAC con API key, monto del cliente) + verificar dedup de eventos (`webhook_events_processed`) y llaves live en el repo (R15).
- Gap: `blocks_build: false`, **priority 1** (seguridad) si hay ≥1 finding critical (PAY-001/005/007); `forja_action: "lente El Cobrador de el-guardian + adoptar 0003_payments_ledger.sql"`; `forja_command: "/add-payments"` (reusa el proveedor existente — el ranking se corre solo como verificación, no para reemplazarlo).

#### DB migrations

```bash
ls supabase/migrations/*.sql 2>/dev/null
# Verificar RLS coverage
find supabase/migrations -name "*.sql" 2>/dev/null | xargs grep -l "user_id" | xargs grep -c "ENABLE ROW LEVEL SECURITY"
```

#### API routes existentes

```bash
ls src/app/api/*/route.ts 2>/dev/null | head -10
# Verificar Zod usage
grep -r "from 'zod'\|from \"zod\"" src/app/api/ 2>/dev/null | head -3
```

### Paso 4 — Generar gaps_criticos

Para cada gap detectado en Pasos 1-2:

```yaml
- id: gap-N
  description: <texto explícito>
  blocks_build: bool                    # true si gate de R11 falla
  forja_action: <acción Forja a tomar>
  forja_command: <comando exacto>
  estimacion_min: <number>
```

Priorización:
1. Gaps que bloquean `/build` (R11 fails) → priority 1.
2. Gaps de seguridad (RLS L-001 missing, R14 violations) → priority 1.
3. Gaps de Forja Enterprise extras (AGENTS.md, hooks) → priority 2.
4. Mejoras opcionales (memory store completo, voice.json refinement) → priority 3.

### Paso 5 — Estimación de tiempo total

```
estimacion_min_bootstrap = sum(gaps con priority 1).estimacion_min
estimacion_min_enterprise = bootstrap + sum(gaps con priority 2-3).estimacion_min
```

Típico:
- Tipo A (Forge V3.x): bootstrap ~3h / enterprise ~6h.
- Tipo B (Forge V2): bootstrap ~5h / enterprise ~9h (más re-estructuración).
- Tipo C (Next.js custom): bootstrap ~3h / enterprise ~6h.
- Tipo D (otro framework): bootstrap ~10h+ (incluye re-escritura a Next.js).
- Tipo E (greenfield): bootstrap ~2h / enterprise ~5h.

### Paso 6 — Presentar análisis al usuario

```
━━━ migration-wizard — Fase 1: ANALYZE ━━━

📊 Bootstrap Contract Gates (R11):
   R11-1 (setup/deps):       ✅/❌/⚠️
   R11-2 (≥1 test passing):  ✅/❌/⚠️
   R11-3 (feature_list):     ✅/❌
   R11-4 (skills.md):        ✅/❌
   R11-5 (Brand DNA / R10):  ✅/❌

📊 Forja Enterprise Extras:
   AGENTS.md:                ✅/❌
   CLAUDE.md Factory OS:     ✅/❌
   Hooks instalados:         ✅/❌/⚠️
   Memory store (7 files):   ✅/❌/parcial
   Conventional commits:     ✅/❌/⚠️
   RLS L-001 tables:         ✅/❌/n/a
   R14 destructive tools:    ✅/❌/⚠️

♻️ Reusable detectado:
   Skills mapeables:         {N} (de {M} totales)
   Blueprint/planning docs:  ✅/❌
   Brand/design system:      ✅/❌ (compatible R-005: ✅/❌)
   Tests existentes:         {N} en {framework}
   DB migrations:            {N} (RLS coverage: {N}/{M})
   API routes con Zod:       ✅/❌

❗ Gaps críticos (bloquean /build): {N}
🔧 Gaps importantes (Forja Enterprise extras): {N}
✨ Mejoras opcionales: {N}

⏱️ Estimación total:
   Bootstrap Contract mínimo: ~{X}h
   Enterprise completo:        ~{X}h

¿Proceder a Fase 2 (PLAN)? (sí / abort / ajustar)
```

## Edge cases

### Edge 1 — Tipo D (otro framework)
- Documentar incompatibilidad explícita.
- Ofrecer dos paths en analyze:
  - Path A: re-escribir a Next.js (incluye estimación de re-escritura).
  - Path B: NO migrar — usar Forja en proyecto separado.

### Edge 2 — Proyecto con secret en .env
- Detectar `.env` con valores reales (no `.env.example`).
- Warning: "secrets en .env detectados. Asegurate de que `.gitignore` los excluya."

### Edge 3 — Tests con coverage 0
- Tests existen pero todos failing.
- R11-2 fail. Documentar como gap crítico.

### Edge 4 — Multiple BaaS (Supabase + Insforge mezclados)
- Reportar inconsistencia. Forzar elección de UNO en el plan.

### Edge 5 — Skills existentes con conflicto de nombres
- ej: skill llamado "la-herreria" pero con SKILL.md distinto al de Forja.
- Reportar conflict + plan: archivar el existente + reemplazar con Forja's.

## Citation

[memory:decisions#D-023] (pipeline shape), [memory:CONSTRAINTS.md#R11] (Bootstrap Contract gates), [memory:CONSTRAINTS.md#R10] (Brand DNA R11-5), [memory:lessons#L-001] (RLS user_id), [memory:CONSTRAINTS.md#R14] (destructive tools).
