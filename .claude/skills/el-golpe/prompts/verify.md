# verify

> Protocolo de verificación post-execución. Typecheck → tests → sin console errors → commit. Si fail en cualquier step, revertir parcial y reportar al usuario antes de commit.

## Inputs

- Diff aplicado al codebase (Read + Edit + Write completados).
- Active feature actual.
- Brief plan ejecutado (`prompts/brief-plan.md` produjo el plan).

## Output

```yaml
verify_result:
  typecheck: pass | fail <details>
  tests: pass | fail <details>
  console_errors: clean | dirty <details>      # solo si UI
  ready_to_commit: bool
  
  # si ready_to_commit
  commits_planned:
    - type: feat | fix | refactor | chore | docs | test | style | perf | ci | build
      scope: <active-feature-id>
      message: <descripción <60 chars>
      files: [<paths>]
```

## Protocolo de verificación

### Step 1 — Typecheck (mandatory siempre)

```bash
tsc --noEmit
```

Pass criteria: exit 0.

Fail handling:
- Si error es del archivo que tocaste → fix the issue antes de proceder. NO commit con typecheck rojo.
- Si error es archivo que NO tocaste (bug pre-existente) → reportar al usuario. Decision: ¿fixar como parte del golpe (scope creep) o dejar y reportar?
- Si typecheck no aplica (proyecto JS sin TS) → skip + reportar.

### Step 2 — Tests relevantes (mandatory si tests existen)

```bash
# Solo tests relacionados a archivos modificados
npm test -- --findRelatedTests <files>

# o equivalente per framework:
# vitest --run --findRelatedTests <files>
# jest --findRelatedTests <files>
# pnpm test:related <files>
```

Pass criteria: exit 0, no skipped tests críticos.

Fail handling:
- Si test fail relevante a tu cambio → fixar antes de commit.
- Si test pre-existente flaky → reportar al usuario, NO disable test silenciosamente.
- Si NO hay tests para los archivos tocados → reportar como gap, sugerir agregar tests si feature es importante.

### Step 3 — Sin console errors (condicional, solo si UI)

Si feature toca UI, run el componente (dev server si está corriendo) y verificar:

- Sin React warnings en console (key prop missing, hydration mismatch, etc.)
- Sin runtime errors al renderear el componente nuevo o modificado
- Sin warnings de a11y obvios (axe-core opcional si configurado)

Pass criteria: console clean en happy path.

Fail handling:
- Console warning React → fixar. NO commit con warnings.
- Console error runtime → fixar. NO commit con render-broken UI.
- Si dev server no está corriendo → opcional skip + reportar al usuario que el visual check no se ejecutó.

### Step 4 — Build check opcional (si feature toca config crítico)

Si la feature modificó:
- `next.config.js` / `next.config.ts`
- `tsconfig.json`
- `package.json` (deps cambios)
- `.env.local.example` o `.env` defaults

Run `npm run build` o equivalente. Pass criteria: exit 0.

NO build check para features que solo tocan código de aplicación (componentes, routes) — typecheck + tests bastan.

### Step 5 — Commit atomic (R2)

Si los 4 steps pasan:

```bash
git add <files-modified-in-this-commit>
git commit -m "<type>(<active-feature-id>): <descripción>"
```

Conventional commits format (R2):
- type: `feat | fix | refactor | chore | docs | test | style | perf | ci | build`
- scope: ID del active feature (ej: `F3-S?`, `F2-S7`, etc.)
- description: ≥10 chars, imperativo, sin punto final, <60 chars total ideal

Si la feature requiere 2-3 commits naturales (ej: schema + UI + actions), separar:

```bash
# Commit 1: schema
git add .claude/migrations/0005_invitations.sql
git commit -m "feat(F3-S?): add invitations table with RLS L-001"

# Commit 2: lib + actions
git add lib/invite/ app/api/invite/route.ts
git commit -m "feat(F3-S?): add invite endpoint and email lib"

# Commit 3: UI
git add app/\(app\)/team/InviteForm.tsx
git commit -m "feat(F3-S?): add InviteForm UI consuming brand tokens"
```

Cada commit standalone — debe pasar typecheck + tests si se cherry-pickea solo.

## Retry/halt logic

Si Step 1, 2 o 3 fail:

1. Detener antes de commit.
2. Reportar al usuario:

```markdown
## Verify FAIL

**Step:** <typecheck | tests | console errors>
**Detalle:**
```
<output del fail>
```

**Opciones:**
- Fixar y re-verificar (recomendado)
- Halt y revertir cambios
- Forzar commit (NO recomendado, deja red en main del active branch)
```

3. NO loop automático — esperar decisión humana. el-golpe es one-shot, NO sprint.

Si Step 4 fail:

1. Si build fail por config issue del cambio → fixar config.
2. Si build fail por code issue que typecheck no detectó (raro) → revertir y reportar.

## R2 enforcement

> [memory:CONSTRAINTS.md#R2] — Atomic commits + Conventional Commits.

Hook commit-msg validará format. Si format wrong → hook rechaza, fixar mensaje y re-commit.

NO bypass con `--no-verify` (AP2). Si el hook tiene falso positivo, reportar para fixar el hook, NO bypass.

## Edge cases

### Edge: typecheck pasa pero tests fallan en archivo no-tocado

→ Bug pre-existente. Reportar al usuario. NO automatic fix (scope creep). Decision: el usuario decide si extiende el golpe o lo deja.

### Edge: tests no existen para los archivos tocados

→ Reportar como gap. Sugerir si feature es importante: "Considerá agregar 1-2 tests post-golpe (sprint o nuevo el-tajo)." NO bloquear el commit por falta de tests si la feature es benigna.

### Edge: console error solo en edge case que requiere setup específico

→ Reportar al usuario. Si edge case es excepcional (ej: solo en mobile Safari), documentar en commit message como follow-up.

### Edge: 2 commits planeados pero 1ro pasa, 2do falla en typecheck

→ Halt entre commits. NO revertir el 1ro (ya está hecho). Reportar al usuario el estado: "Commit 1 OK, commit 2 FAIL en step typecheck. Decision: fixar y continuar con commit 2 o halt en estado parcial."

### Edge: conventional commit hook rechaza el mensaje

→ Hook reporta el regex que no matchea. Ajustar mensaje para conformar (probable: scope con guión bajo en lugar de guión, o type fuera del set permitido).

### Edge: el cambio rompe linter rules nuevas (proyecto activó eslint plugin nuevo recientemente)

→ Si linter rules son legítimas → fixar. Si son demasiado strict para el scope del golpe → reportar al usuario, decision: relajar regla o fixar todo.

## Citation grammar

- [memory:CONSTRAINTS.md#R2] — atomic commits + conventional format.
- [memory:CONSTRAINTS.md#AP2] — no bypass de hooks con `--no-verify`.
- [memory:lessons#L-004] — el-golpe binary, verify NO introduce PAUSE.
- [memory:decisions#D-017] — escalation siempre disponible si verify fail repetidamente.

## Refusals

- ❌ Commit con typecheck rojo.
- ❌ Commit con tests fallando (a menos que sean pre-existentes y reportes el gap).
- ❌ Bypass de commit-msg hook con `--no-verify` (AP2).
- ❌ Multi-commit cuando 1 atomic basta (anti-pattern de pretender más output).
- ❌ Commit auto-firmado si user no confirmó el brief plan inicialmente.
- ❌ Loop "ciclo 1 → fix → ciclo 2 → fix" (eso es sprint, escalate).
- ❌ Disable test silenciosamente para que pase (anti-pattern crítico).
