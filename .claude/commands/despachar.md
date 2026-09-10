---
description: "Ship workflow Forja: pre-flight (R1) → merge origin/main → Three-Layer Verification (R7) → review pre-landing → commits → push → PR. Non-interactive."
---

# /despachar — Ship Workflow

> *"La pieza terminada sale de la forja al mundo. Sin ceremonia de release, hasta el mejor código muere en una rama."*

Workflow automatizado de release: merge main, Three-Layer Verification (R7), review pre-landing con Brand DNA check, commits bisectables, push, crear PR. Para una rama lista, no para decidir qué construir.

## Instrucciones

### Protocolo: Non-Interactive por Defecto

`/despachar` es **automatizado**. No preguntar confirmación en cada paso. El usuario dijo `/despachar` — eso significa HAZLO.

**Solo detenerse por:**
- Estás en `main` (abortar)
- **R1 violation:** >1 feature en `active` en `feature_list.json`
- Merge conflicts que no se pueden auto-resolver (mostrar conflictos)
- Cualquier layer de R7 (typecheck, lint, build, tests) falla
- Review pre-landing encuentra issues CRITICAL (preguntar por cada uno)
- Cambios de seguridad detectados (auth, RLS, headers, payments) → invocar `el-guardian` antes de push

**Nunca detenerse por:**
- Cambios sin commitear (siempre incluirlos)
- Contenido del CHANGELOG (auto-generar)
- Aprobación del commit message (auto-commit)

---

### Paso 1: Pre-Flight

1. Verificar branch actual. Si es `main`, **abortar**: "Estás en main. Despacha desde una feature branch."

2. **R1 enforcement:** leer `feature_list.json` y contar features en `state: active`.
   - Si `>1` → **STOP** con mensaje: "R1 violation: {count} features en active. Resolvé (pasar las extras a `blocked` o `passing`) antes de despachar."
   - Si `=0` → warning informational: "Sin active feature. ¿Olvidaste marcar la feature como `active`?" (no bloquea, pero informa).
   - Si `=1` → continuar normal.

3. `git status` (nunca usar `-uall`). Cambios sin commitear se incluyen siempre.

4. `git diff main...HEAD --stat` y `git log main..HEAD --oneline` para entender qué se está despachando.

---

### Paso 2: Merge origin/main (ANTES de tests)

Traer los últimos cambios de main para testear contra el estado actual:

```bash
git fetch origin main && git merge origin/main --no-edit
```

**Si hay merge conflicts:** Intentar auto-resolver si son simples (CHANGELOG, package-lock, lock files). Si son complejos, **STOP** y mostrar.

**Si ya está al día:** Continuar silenciosamente.

---

### Paso 3: Three-Layer Verification (R7)

Ejecutar las 3 capas en orden. Si layer N falla, layer N+1 NO se intenta.

```bash
# Layer 1 — Syntax (typecheck + lint)
make typecheck 2>&1 | tee /tmp/despachar-typecheck.txt
make lint 2>&1 | tee /tmp/despachar-lint.txt

# Layer 2 — Runtime (tests)
make test 2>&1 | tee /tmp/despachar-test.txt

# Layer 3 — System (build + e2e si configurado)
make build 2>&1 | tee /tmp/despachar-build.txt
# Layer 3 e2e es opcional según el proyecto: make e2e si existe en Makefile.
```

**Si cualquier layer falla:** Mostrar errores y **STOP**. No proceder.

**Si el `Makefile` no expone uno de los targets** (ej: proyecto sin `make e2e`), caer al script equivalente: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`.

**Si todos pasan:** Continuar — solo notar los conteos brevemente.

---

### Paso 4: Review Pre-Landing

Revisión de diff para issues estructurales que los tests no capturan.

#### 4A. Obtener el diff

```bash
git diff origin/main
```

#### 4B. Checklist adaptado al Golden Path Forja

Revisar en dos pases:

**PASE 1 — CRITICAL (bloquea /despachar):**

| Categoría | Qué buscar |
|-----------|-----------|
| **TypeScript Safety** | `any` usado en lugar de `unknown`, `as` casts sin validación, `@ts-ignore` sin justificación |
| **Supabase Data Safety (L-001)** | RLS faltante en tablas nuevas, queries sin `.eq('user_id', userId)`, `service_role` key en cliente |
| **Auth Boundaries** | Routes sin middleware de auth, API routes sin verificar `session`, datos de usuario A accesibles por B |
| **Server/Client Boundary** | `"use client"` faltante en componentes con hooks, secrets importados en componentes client, `process.env` sin `NEXT_PUBLIC_` en client |
| **Injection Vectors (L-002, L-003)** | Input de usuario directo en queries SQL, `dangerouslySetInnerHTML` con datos de usuario, prompt injection en features de IA, falta de Zod whitelist en server actions |
| **R14 Destructive Tools** | Tools `delete*`/`send*`/`refund*`/`cancel*`/`deploy*` con `execute()` automático sin confirmación humana → reject automático |
| **Brand DNA Leak (R10)** | Tokens hardcoded fuera de `brand.css` (ej: `bg-purple-500`, `text-[#6366F1]`), Tailwind defaults en componentes nuevos sin reading `brand/brand.json` |

**PASE 2 — INFORMATIONAL (incluir en PR body):**

| Categoría | Qué buscar |
|-----------|-----------|
| **R10 Brand evidence** | Componentes UI nuevos sin evidencia explícita de leer `brand.json`/`voice.json` → flag informativo |
| **React Patterns** | useEffect sin cleanup, deps arrays incompletos, renders innecesarios, state que debería ser derived |
| **Zod Validation** | Inputs de API sin validación Zod, schemas incompletos, `.parse()` sin try/catch |
| **Performance** | Queries N+1, `use client` en páginas que podrían ser server components, imágenes sin `next/image` |
| **Dead Code** | Variables asignadas sin usar, imports no utilizados, componentes huérfanos |
| **Error Handling** | `catch(e) {}` vacíos, errores swallowed sin logging, estados de error UI faltantes |
| **Console Artifacts** | `console.log` olvidados en producción |
| **Citation grammar (R13)** | Imports/APIs de libs externas sin `[docs:libname]` en docstring/PR — flag informativo |

#### 4C. Output del review

```
Review Pre-Landing: N issues (X critical, Y informational)

**CRITICAL** (bloquea /despachar):
- [archivo:línea] Descripción del problema
  Fix: solución sugerida

**Issues** (no bloquean):
- [archivo:línea] Descripción del problema
  Fix: solución sugerida
```

Si no hay issues: `Review Pre-Landing: Sin issues encontrados.`

**Si hay issues CRITICAL:** Para CADA issue crítico, usar `AskUserQuestion` individual:
- Problema + fix recomendado
- Opciones: A) Arreglar ahora (recomendado), B) Reconocer y despachar igual, C) Falso positivo — saltar

Si el usuario elige A en alguno: aplicar fixes, commitear solo esos archivos, luego indicar "Ejecuta `/despachar` de nuevo para re-testear con los fixes."

#### 4D. Security trigger — el-guardian condicional

Si el diff incluye cambios en alguna de estas áreas → invocar `el-guardian` antes de seguir:
- `src/app/api/auth/**`, middleware de auth
- Migrations de Supabase (`supabase/migrations/*.sql`) con cambios en RLS o grants
- Webhooks (Stripe, Polar, Resend, SendGrid) — handler signature verification
- `src/app/api/payments/**`, `actions/payments.ts`
- Headers / CSP / CORS config

Audit corre vía `el-guardian` skill (Codex segundo cerebro). Si reporta Critical/High → **STOP** + mostrar `SECURITY-AUDIT-{feature}.md`. Override solo con `--skip-security` confirmado por el usuario.

---

### Paso 5: Commit (chunks bisectables)

**Objetivo:** Commits pequeños y lógicos que funcionen con `git bisect`. R2 enforced: conventional commits format `<type>(<scope>): <description>`.

1. Analizar el diff y agrupar cambios en commits lógicos. Cada commit = una unidad coherente.

2. **Orden de commits** (primero los más tempranos):
   - **Infraestructura:** migraciones SQL, config, rutas
   - **Services & Types:** services, tipos, hooks, server actions
   - **Components & Pages:** componentes UI (impeccable), páginas, layouts
   - **Tests:** si hay tests separados
   - **Final:** CHANGELOG / versión / docs (si aplica)

3. **Reglas:**
   - Un service y su hook van en el mismo commit
   - Un componente y su test van juntos
   - Si el diff total es pequeño (<50 líneas, <4 archivos): un solo commit está bien
   - Cada commit debe ser independientemente válido (typecheck + lint pasan en cada SHA)

4. **Formato de commit message (R2):**
   ```
   <type>(<scope>): <descripción imperativa, sin punto final, ≥10 chars>
   ```
   Types: `feat | fix | refactor | chore | docs | test | style | perf | ci | build | evaluator | memory`
   Scope: `F2-S7`, `auth`, `ui-kit`, etc. (alfanum + dashes)

   Memory writes (`.claude/memory/**`): scope `evaluator` o `memory` enforced por hook (R5).

---

### Paso 6: Push

```bash
git push -u origin <branch-name>
```

---

### Paso 7: Crear PR

Crear PR con resumen auto-generado del diff. El body se autogenera **desde `feature_list.json` + `plan.json`**
(S2 · `el-capataz` siembra `.github/pull_request_template.md` con estas mismas secciones, que aplica a los PRs
creados por UI; `/despachar` las rellena en CLI):

```bash
gh pr create --title "<type>(<scope>): <resumen>" --body "$(cat <<'EOF'
## Resumen
<bullet points de los cambios>

## Feature(s) / Story(ies)
<de feature_list.json: id + behavior del active feature; si hay .plan/, la story con featureRefs (as/want/soThat)>

## CI (AP8)
<ci_run.conclusion del active feature + `[ci:run#<id>]`, o "pendiente — correr /verificar-ci antes de mergear">

## Three-Layer Verification (R7)
- [x] Layer 1 — Syntax (typecheck + lint) ✅
- [x] Layer 2 — Runtime (tests) ✅
- [x] Layer 3 — System (build) ✅

## Review Pre-Landing
<hallazgos del Paso 4, o "Sin issues encontrados.">

## Brand DNA (R10)
<resultado del check de Brand DNA: tokens leyendo brand.json correctamente, o flags informativos>

## Security Audit (R14 + el-guardian)
<si aplicó Paso 4D — verdict del el-guardian; sino "No security-relevant changes detected.">

🔨 Despachado con [Forja](https://github.com/dodc1981/forja)
EOF
)"
```

**Output final:** La URL del PR — esto es lo último que el usuario debe ver.

---

### Paso 8 (Opcional): Si `gh` no está disponible

Si `gh` CLI no está instalado:

```bash
git push -u origin <branch-name>
```

Informar al usuario:

```
🔨 Branch despachada: <branch-name>

Para crear el PR manualmente:
→ https://github.com/<owner>/<repo>/compare/<branch-name>

💡 Tip: Instala GitHub CLI (gh) para crear PRs automáticamente:
   brew install gh && gh auth login
```

## Siguiente Paso Sugerido

```
🔨 Despachado.

Próximos pasos recomendados:

→ /web-quality       — Auditoría integral (Performance + A11y + SEO + Best Practices)
→ /el-guardian       — Security audit con Codex (si no se invocó en Paso 4D)
→ /avivar            — Cargar contexto de la próxima sesión con primer
→ /plan              — Planificar la siguiente feature con la-herreria
```

---

*"Forja despacha, pero no despacha sin verificar. Las 3 capas R7 + R1 + R10 + R14 son los gates no-negociables. /despachar es protocol; el humano confirma solo cuando el protocol detecta una excepción."*
