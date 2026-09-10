---
name: add-e2e-tests
description: >
  Skill opt-in para configurar Playwright como framework de tests CI/CD
  automatizados. NO reemplaza agent-browser (default Forja para QA agentic,
  D4 en ARCHITECTURE.md) — coexisten porque sirven cosas distintas:
  agent-browser para QA agentic durante development, Playwright MCP para
  cross-browser checks vía agente, y @playwright/test (este skill) para
  specs CI/CD que corren sin agente. Instala `@playwright/test`, descarga
  browsers (chromium-only en minimal, +firefox+webkit en full), genera
  `playwright.config.ts`, estructura `tests/e2e/` con auth pattern
  (auth.setup.ts + helpers/) compatible con add-login Supabase, 1 spec de
  ejemplo, scripts `test:e2e` / `test:e2e:ui` / `test:e2e:debug` en
  package.json, y opcionalmente un workflow GitHub Actions. BINARY shape
  (D-026): minimal default / full override. Resume-aware — si `tests/e2e/`
  ya existe, scan + halt antes de overwrite. Hereda Gate 8 de E-009 causa
  3 (typecheck baseline sano pre-install — sin baseline limpio los specs
  heredan el roto).
tier: optional
requires: proyecto Next.js (`next` en package.json deps), package.json writable, `src/` o `pages/` accesible, `npm` disponible. Para modo full — `.github/workflows/` writable.
fallback: Si `tests/e2e/` ya existe con specs → halt + reporta inventario, sugiere modo APPEND (solo agregar config + helpers, no tocar specs). Si `playwright.config.ts` ya existe → halt + diff con propuesto, pedir confirmación humana antes de modificar. Si typecheck baseline roto (Gate 8) → halt + reportar errores antes de instalar nada (E-009 causa 3).
dependencies: [find-docs]
---

# add-e2e-tests

> *"Los tests agentic ocurren durante development. Los tests CI/CD ocurren sin agente. Ambos son válidos, ninguno reemplaza al otro."*
> — Forja D4 + D-026

Skill opt-in. Configura Playwright (`@playwright/test`) como framework de tests CI/CD automatizados, complementando — NO reemplazando — agent-browser, que sigue siendo el default Forja para QA agentic durante development.

## PREFLIGHT halt (3 gates)

```
1. ¿Existe package.json Y tiene `next` en deps (o devDeps)?
   Si no → halt: "add-e2e-tests requiere proyecto Next.js. Corré `forja`
   para inicializar el template, o ejecutá setup manual antes."

2. ¿npm está disponible? `command -v npm` exit 0.
   Si no → halt: "npm no disponible. Instalá Node.js + npm primero."

3. ¿typecheck baseline sano? `npm run typecheck` (o `npx tsc --noEmit`)
   exit 0.
   Si fail → halt: "Build pre-existente roto. Resolvelo antes de agregar
   tests — los specs de Playwright van a heredar los errores y no podés
   distinguir regresiones de baseline roto.
   Errores actuales (primeras 20 líneas): <stdout>.
   Cita: [memory:errors#E-009] causa 3 (lid-on-pot effect — heredado)."
```

Sin los 3 gates, add-e2e-tests retorna error sin instalar nada.

## Activación

| Cuándo se invoca | Quién |
|------------------|-------|
| Usuario pide "agregame Playwright / E2E tests / specs CI/CD / configurá tests automáticos" | Coordinator |
| Otro skill detecta specs `tests/e2e/**/*.spec.ts` sin `@playwright/test` instalado | skill handoff (caso E-009 dogfood Hirezia) |
| Pre-deploy pipeline necesita test gate automatizado sin agente en el loop | la-forja / el-yunque handoff |
| `el-guardian` pide cross-browser smoke como evidencia adicional pre-deploy | el-guardian handoff |

NO se invoca para QA agentic durante development — eso lo cubre `agent-browser` (D4). NO se invoca para cross-browser exploration agentic — eso lo cubre Playwright MCP. Ver `references/playwright-vs-agent-browser.md`.

## 2 modos (BINARY — D-026)

### MODE A — minimal (default)

Trigger:
- Usuario no especifica modo, OR
- "minimal", "quick setup", "solo chromium", "sin GitHub Actions".

Output:
- `@playwright/test` instalado como devDep.
- `npx playwright install chromium` (~80 MB de browsers, ~30s).
- `playwright.config.ts` con un solo project (Chromium).
- `tests/e2e/` con auth.setup.ts + example.spec.ts + helpers/auth.ts.
- Scripts `test:e2e`, `test:e2e:ui`, `test:e2e:debug` en package.json.
- `.gitignore` extendido con `playwright/.auth/*.json`, `test-results/`, `playwright-report/`.
- **NO** crea `.github/workflows/e2e.yml`.

Ideal para desarrollo local + smoke tests pre-deploy manual.

### MODE B — full (override)

Trigger:
- Usuario especifica "full", "cross-browser", "los 3 browsers", "con GitHub Actions".

Output:
- Todo lo de Mode A, más:
- `npx playwright install chromium firefox webkit` (~280 MB de browsers, ~90s).
- `playwright.config.ts` con 3 projects (Chromium, Firefox, WebKit).
- `.github/workflows/e2e.yml` con matrix por browser, cache de node_modules + browsers, upload de `playwright-report` como artifact.

Ideal para apps con compromiso cross-browser real (B2C público, marketplace, public-facing landing).

## Loop de ejecución

```
0. PREFLIGHT halt (3 gates: Next.js, npm, typecheck baseline)
   · Cita Gate 8 patrón heredado: [memory:errors#E-009] causa 3.

1. Detectar resume:
   ├─ ¿`tests/e2e/` existe con ≥1 `*.spec.ts`? → halt + reporta inventario,
   │   sugerir modo APPEND (solo agregar config + helpers).
   ├─ ¿`playwright.config.ts` existe? → halt + diff, esperar confirmación.
   └─ resto → continuar.

2. Preguntar modo al usuario (A minimal default / B full):
   Sin respuesta clara → A (minimal, conservador).

3. find-docs (R13) ANTES de generar:
   - resolve-library-id("playwright") + query-docs("playwright config v1.49 webServer storageState projects")
   - resolve-library-id("nextjs") + query-docs("App Router + e2e testing pattern")
   - Cita: [docs:playwright], [docs:nextjs].

4. Fase 1 — Instalación (R4: sub-agent invoca, no SKILL):
   - sub-agent ejecuta `npm install -D @playwright/test`
   - sub-agent ejecuta `npx playwright install [chromium | chromium firefox webkit]`
   - Verifica exit 0 en ambos comandos.

5. Fase 2 — Configuración:
   - Read templates/playwright.config.ts.template.
   - Substituir variables ({{ projects }}, {{ workers }}, {{ baseURL }}).
   - Write playwright.config.ts en raíz del proyecto target.

6. Fase 3 — Estructura tests/e2e/:
   - Write tests/e2e/auth.setup.ts (auth pattern Supabase-compatible).
   - Write tests/e2e/example.spec.ts (smoke test comentado).
   - Write tests/e2e/helpers/auth.ts (login/logout/assertAuthenticated).
   - Write playwright/.auth/.gitkeep (storageState directory).
   - Extend .gitignore: append `playwright/.auth/*.json`, `test-results/`,
     `playwright-report/` (solo si NO existen ya).

7. Fase 4 — package.json scripts:
   - Add `"test:e2e": "playwright test"`.
   - Add `"test:e2e:ui": "playwright test --ui"`.
   - Add `"test:e2e:debug": "playwright test --debug"`.
   - Si los scripts ya existen → skip (NO overwrite).

8. Fase 5 (solo modo full) — GitHub Actions:
   - Write .github/workflows/e2e.yml de template.
   - Si ya existe e2e.yml → halt + diff + confirmación.

9. Output handoff al usuario:
   "✅ Playwright configurado.
    → npm run test:e2e         (correr todos)
    → npm run test:e2e:ui      (UI mode interactivo)
    → npm run test:e2e:debug   (paso a paso)
    Spec de ejemplo en tests/e2e/example.spec.ts — bórralo cuando escribas
    los tuyos."
```

## Reglas operativas

1. **NO reemplaza agent-browser.** D4 (ARCHITECTURE.md) sigue intacto: agent-browser es default para QA agentic durante development. add-e2e-tests resuelve un problema ortogonal — specs CI/CD que corren **sin agente** en el loop. Documentado en `references/playwright-vs-agent-browser.md`.
2. **Gate 8 heredado de E-009.** typecheck baseline sano es PREFLIGHT mandatorio. Sin baseline limpio los specs heredan el roto y no se distinguen regresiones reales. Cita `[memory:errors#E-009]` causa 3.
3. **Resume-aware.** Si `tests/e2e/` ya tiene specs o `playwright.config.ts` existe → halt + reporte + confirmación. NUNCA overwrite silencioso (anti-patrón E-009 causa 2).
4. **find-docs antes de generar (R13).** Playwright API cambia entre versiones menores (`webServer`, `storageState`, `projects` evolucionan). Sin docs frescos, runtime falla con cryptic errors.
5. **Sub-agent invoca npm/npx, no el skill (R4).** El orchestrator-thin pattern aplica acá igual que en otros skills — la SKILL.md NO corre `npm install` directo, dispatcha a un sub-agente.
6. **package.json scripts append-only.** Si `test:e2e` ya existe, NO overwrite (el usuario puede tener customización). Reportar al usuario y dejar el script intacto.
7. **storageState pattern para auth.** Compatible con add-login Supabase — `auth.setup.ts` loguea con `TEST_USER_EMAIL` + `TEST_USER_PASSWORD` env vars y guarda en `playwright/.auth/user.json`. NUNCA hardcodear credenciales.
8. **`.gitignore` extends, no overwrite.** Append `playwright/.auth/*.json`, `test-results/`, `playwright-report/` solo si NO existen ya. Preservar entries previas.

## Refusals (lo que NUNCA hace)

- ❌ Sobrescribir `playwright.config.ts` existente sin confirmación humana.
- ❌ Modificar specs existentes en `tests/e2e/**/*.spec.ts`.
- ❌ Instalar paquetes sin que los 3 gates PREFLIGHT pasen.
- ❌ Ignorar Gate 8 — un baseline roto contamina todos los tests futuros (E-009 causa 3 heredado).
- ❌ Hardcodear credenciales de test en specs o config. Solo via `TEST_USER_EMAIL` / `TEST_USER_PASSWORD` env vars.
- ❌ Reemplazar agent-browser o desalentar su uso. Coexistencia es la decisión (D-026).
- ❌ Saltar `find-docs` antes de generar `playwright.config.ts` (R13 violation).
- ❌ Editar `brand/**` (add-ui-kit territory), `.claude/memory/**` (R5, sole writer el-evaluador), `src/lib/{supabase,insforge}/**` (add-login).
- ❌ Generar workflow GitHub Actions en modo minimal. Solo en modo full.

## Tool filter

Read · Grep · Glob · Bash (`command -v npm`, `npm run typecheck`, `npm install -D`, `npx playwright install`, `node -e` para sanity checks) · Write/Edit en `playwright.config.ts`, `tests/e2e/**`, `playwright/.auth/.gitkeep`, `package.json` (append-only en scripts), `.gitignore` (append-only), `.github/workflows/e2e.yml` (solo modo full).

**Alcance conceptual independiente de prefijo (E-009 causa 2):** los paths arriba son patrones, NO literales. La restricción aplica con o sin prefijo ``.

NO Edit en `brand/**` (add-ui-kit), `.claude/memory/**` (el-evaluador), `src/lib/{supabase,insforge}/**` ni `src/app/(auth)/**` (add-login), `supabase/migrations/**` (el-migrador).

## Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Decision | `[memory:decisions#D-026]` | SKILL.md + dry-run.sh + prompts (binary shape) |
| Decision | `[memory:decisions#D-004]` ↔ `[ARCHITECTURE.md#D4]` | references/playwright-vs-agent-browser.md (coexistencia con agent-browser default) |
| Reference | `[memory:references#R-003]` | references/playwright-vs-agent-browser.md (agent-browser tool source) |
| Error | `[memory:errors#E-009]` | SKILL.md PREFLIGHT (Gate 8 heredado, causa 3) |
| Constraint | `[memory:CONSTRAINTS.md#R4]` | SKILL.md loop (sub-agent invoca npm/npx) |
| Constraint | `[memory:CONSTRAINTS.md#R13]` | SKILL.md loop + prompts (find-docs antes de generar) |
| External docs | `[docs:playwright]`, `[docs:playwright-test]`, `[docs:nextjs]` | playwright.config.ts header + prompts |

## Integración con otros skills

| Skill | Relación |
|-------|----------|
| `find-docs` | dependency. R13 pre-gen para Playwright API freshness. |
| `add-login` | sibling. auth.setup.ts es compatible con Supabase clients que add-login instala (`createServerClient` / `createBrowserClient`). NO halt si add-login no corrió — los tests reciben TEST_USER_EMAIL/PASSWORD directos. |
| `web-quality` | sibling. web-quality default es agent-browser (live audit); add-e2e-tests es CI/CD specs. No se reemplazan. |
| `el-guardian` | sibling. el-guardian pide cross-browser smoke como evidencia adicional pre-deploy — add-e2e-tests Mode B lo provee. |
| `agent-browser` (D4 default, NO es skill) | **coexiste sin contradicción**. agent-browser para QA agentic en development; add-e2e-tests para CI/CD sin agente. |
| `el-evaluador` | post-gen valida L1 (typecheck post-instalación, playwright.config.ts parsea) y L3 (citations correctas). |

## Output handoff

```markdown
## add-e2e-tests handoff

**Mode:** MINIMAL | FULL
**Files generated:**
- playwright.config.ts
- tests/e2e/auth.setup.ts
- tests/e2e/example.spec.ts
- tests/e2e/helpers/auth.ts
- playwright/.auth/.gitkeep
- .gitignore (extended)
- package.json (scripts added)
- .github/workflows/e2e.yml (solo FULL)

**Browsers installed:** chromium [+ firefox + webkit en FULL]

**Scripts disponibles:**
- npm run test:e2e
- npm run test:e2e:ui
- npm run test:e2e:debug

**Env vars requeridas para auth.setup.ts:**
- TEST_USER_EMAIL
- TEST_USER_PASSWORD
- NEXT_PUBLIC_APP_URL (opcional, fallback http://localhost:3000)

**Citations:**
- [memory:decisions#D-026] (BINARY shape minimal/full)
- [memory:decisions#D-004] ↔ [ARCHITECTURE.md#D4] (coexistencia agent-browser default)
- [memory:references#R-003] (agent-browser tool)
- [memory:errors#E-009] (Gate 8 heredado, causa 3)
- [memory:CONSTRAINTS.md#R4] (sub-agent invoca npm/npx)
- [memory:CONSTRAINTS.md#R13] (find-docs antes de Playwright)
- [docs:playwright], [docs:playwright-test], [docs:nextjs]

**Próximo paso:** correr `npm run test:e2e` para verificar que el example.spec.ts pasa contra el dev server.
```

---

*"Tres herramientas, tres casos de uso, cero reemplazo. agent-browser durante development, Playwright MCP para exploración cross-browser agentic, @playwright/test para CI/CD sin agente."*
