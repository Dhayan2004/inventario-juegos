# Close or Escalate — condiciones de cierre o handoff explícito

## Objetivo

Decidir cómo termina el sprint según el outcome (`done` / `pause` / `escalate`), producir el output canónico de cierre, y hacer handoff explícito si corresponde. Cierre limpio es lo que hace que sprint sea reutilizable y rastreable.

## Los 3 outcomes posibles

| Outcome | Cuándo | Acción |
|---------|--------|--------|
| **`done`** | Usuario dice `done` (o equivalente: "me gusta", "suficiente", "listo"). | Atomic commit con scope del active feature (R2). |
| **`pause`** | Usuario dice `pause`, o checkpoint forzado decide pause, o timeout. | Diff queda staged en working tree, NO commit. Reportar estado para retake. |
| **`escalate`** | Sprint diverge / max iterations sin convergencia / scope reveal. | Handoff explícito a el-golpe / /build / la-herreria. NO commit (se pierde el loop al escalate). |

## Outcome 1 — DONE (atomic commit)

### Pre-commit checks

Antes de commit:

1. **Verificar criterio de éxito cumplido.** El usuario dijo `done` — implica criterio cumplido. Pero el agente verifica honestamente:
   - Si el criterio era "los 4 edge cases pasan" — correr los tests, confirmar PASS.
   - Si el criterio era "el usuario dice 'me gusta'" — el `done` es la confirmación.
   - Si hay typecheck/lint/test issues residuales, flagear ANTES de commit.

2. **Verificar scope alignment.** El cambio del sprint debe encajar en el active feature actual. Si el sprint cerró `done` pero el cambio es ortogonal al active feature → es scope creep, signal de error de triage. Reportar antes de commit y pedir confirmación.

3. **Verificar R10 si aplica.** Si el sprint tocó UI consuming brand tokens, validar contra `brand/brand.json` (no override de tokens).

4. **Verificar R14 si aplica.** Si el sprint generó / modificó tools agentic destructivas, validar que NO tienen `execute()` automático.

### Commit message

Formato R2:

```
<type>(<active-feature-scope>): <descripción imperativa>
```

Ejemplos:

```
feat(F3-S8): refine hero CTA copy con verb activo
fix(F4-S2): cubrí 4 edge cases del payment validator
refactor(F3-S5): ajusté spacing del hero según wireframe
docs(F2-S7): refiné voice del welcome email match voice.json
```

- `type` reflejado del cambio: `feat` si agrega feature, `fix` si corrige, `refactor` si reescribe, `docs` si toca docs/copy, `style` si solo formatting.
- `<active-feature-scope>` es el ID del active feature (NO inventar scope nuevo).
- Descripción imperativa, ≥10 chars, sin punto final.

### Output canónico DONE

```markdown
## Sprint cerrado — DONE

**Active feature:** <F?-S?>
**Cycles run:** N / 5
**Criterio cumplido:** <criterio>

**Cambios:**
- Archivos modificados: <files>
- LOC delta: +X / -Y

**Commit:**
```
<type>(<scope>): <descripción>
```

**Verificación post-commit:**
- typecheck: ✓
- lint: ✓
- tests: ✓ (si aplica)

**Próxima acción sugerida:**
- Continuá active feature `<F?-S?>` — próximo step en <ej: feature_list.json o PROGRESS.md>
- Si el sprint completó el criterio del active feature, considerá marcar `passing` (corré /el-evaluador para three-layer verification).
```

## Outcome 2 — PAUSE (diff staged, no commit)

### Estado preservado

Working tree queda con el diff del sprint. NO commit.

### Output canónico PAUSE

```markdown
## Sprint pausado — PAUSE

**Active feature:** <F?-S?>
**Cycles run:** N / 5 (parcial)
**Criterio:** <criterio>
**Convergencia:** <cerca / parcial / lejos>

**Estado del working tree:**
- Archivos modificados: <files>
- LOC delta: +X / -Y
- NO commit realizado

**Diff acumulado:**
```
<git diff --stat>
```

**Razón del pause:**
- <ej: usuario solicitó pause / max iter sin done / failure pendiente / etc>

**Para retake:**
1. `git diff` para ver el estado completo
2. Decidí: `continúa` (siguiente ciclo) / `revertí` (vuelvo a clean) / `done` (commit ahora) / `escalate` (a el-golpe / /build)
3. Si retake en sesión nueva, leé esta nota + corré /primer para context

**No el-evaluador handoff** (no hubo commit).
```

## Outcome 3 — ESCALATE (handoff explícito)

### Cuándo escalar

| Razón | Skill destino |
|-------|---------------|
| Max iterations (5) sin convergencia + el approach inicial parece incorrecto | `el-golpe` (one-shot rewrite del scope) |
| Sprint reveló que la tarea es un feature mediano <30min | `el-golpe` |
| Sprint reveló que la tarea es un feature completo con planning | `/build` (la-forja) |
| Sprint reveló que falta planning upstream (no había Blueprint, scope ambiguo) | `la-herreria` |
| Sprint tocó código que requiere security audit pre-deploy | `el-guardian` (después de cerrar el sprint con commit) |
| Sprint reveló que falta foundation (brand DNA, components base) | upstream skill (`add-ui-kit`, `impeccable`, etc.) |

### Pre-escalate

1. **NO commit** del estado intermedio del sprint. El sprint diverge → el commit final lo hace el skill destino con su propio scope.
2. **Stash o working tree dirty.** Default: dejar working tree dirty con el diff del loop, el skill destino decide si reusa o revierte.
3. **Documentar contexto del loop.** Lo que sigue importa al skill destino: criterio definido, ciclos corridos, qué falló.

### Output canónico ESCALATE

```markdown
## Sprint escalado — ESCALATE

**Active feature:** <F?-S?>
**Cycles run:** N / 5
**Criterio:** <criterio>
**Por qué escala:** <razón concreta>

**Estado del working tree:**
- Archivos modificados durante el sprint: <files>
- LOC delta: +X / -Y
- NO commit del sprint (el skill destino commitea con su scope)

**Handoff:**

→ Invocá `<skill destino>` con este contexto:

**Resumen del loop:**
- Ciclo 1: <descripción + outcome>
- Ciclo 2: <descripción + outcome>
- ...
- Ciclo N: <descripción + por qué reveló escalate>

**Lo que aprendimos:**
- <ej: el approach inicial X no es correcto porque Y>
- <ej: el scope real es Z, no W>

**Lo que el skill destino debería considerar:**
- <ej: revertir el working tree y empezar de cero con approach Y>
- <ej: reusar los cambios del ciclo N porque cubren caso edge>

**Working tree dirty preservado.** El skill destino decide reuse / revert.
```

## Pre-cierre: 4 checks rápidos

Antes de producir el output de cierre (cualquier outcome):

```
✓ ¿Active feature aún válido? (R1 — el active no cambió durante el sprint)
✓ ¿Working tree alineado con el outcome esperado? (DONE → about to commit; PAUSE → dirty; ESCALATE → dirty)
✓ ¿Citations correctas? (R10 si UI, R14 si tools destructivas, R2 en commit message)
✓ ¿Próxima acción específica? (NO genérica, NO "trabajá en lo que tengas")
```

Si algún check falla, NO cerrar todavía — reportar la falla y pedir corrección.

## Edge cases del cierre

### Edge 1 — Usuario dice `done` pero el cambio rompe typecheck

```markdown
## Sprint NO cerrado — typecheck failure

El cambio actual rompe typecheck:
```
<error>
```

NO commit posible. Opciones:
1. `continúa-fix` — ciclo extra para arreglar el typecheck antes de commit
2. `revertí-último` — vuelvo al ciclo anterior y commiteo ese
3. `pause` — paramos acá sin commit, fixeás manualmente
```

NO commitear con CI broken. R7 three-layer aplica al feature, sprint hereda el contract.

### Edge 2 — Usuario dice `done` pero el cambio no encaja en active feature

Ejemplo: active feature es F3-S8 (sprint), pero el sprint cerró cambiando archivos de un feature pasado (F3-S6 add-mobile).

```markdown
## Sprint cerrado — scope creep detectado

El sprint cerró `done` pero los cambios afectan archivos del feature F3-S6 (passing), no del active F3-S8.

Esto es signal de:
- Triage inicial incorrecto (era el-golpe en F3-S6 retoma, no sprint en F3-S8)
- O el active feature en feature_list.json está desincronizado del trabajo real

Opciones:
1. `commit-en-active` — commit con scope F3-S8 igual (registra como afín al sprint actual)
2. `commit-en-original` — commit con scope F3-S6 (más honesto, pero abre tema R1)
3. `pause` — paramos acá, revisamos R1 + active feature antes de commit
```

R1 (WIP=1) puede entrar en tensión. Reportar honesto, NO auto-fix.

### Edge 3 — DONE pero R10 violation (sprint tocó UI sin leer brand.json)

```markdown
## Sprint NO cerrado — R10 violation

El sprint modificó componente UI consuming brand tokens (`<Button>` en path/X.tsx) pero no leyó `brand/brand.json` durante los ciclos. R10 requiere validar tokens antes de override.

Opciones:
1. `valida-ahora` — leo brand.json + valido el cambio + commit si pass
2. `revertí` — vuelvo al estado clean, R10 violation evitada
3. `pause` — paramos acá, revisás manualmente
```

### Edge 4 — DONE pero R14 violation (tool destructiva con execute)

```markdown
## Sprint NO cerrado — R14 violation

El cambio incluye tool destructiva con `execute()` automático en `path/tool.ts`:
```typescript
export const deleteX = tool({ execute: async (...) => { ... } })
```

R14 requiere remover `execute()` para que SDK pause con typed confirmation.

Opciones:
1. `fix-r14` — ciclo extra, remuevo `execute()` y agrego confirmation gate
2. `revertí` — vuelvo al estado pre-tool
3. `pause` — paramos acá, fixeás manualmente
```

## Citations

- [memory:CONSTRAINTS.md#R1] (sprint commit usa scope del active feature, NO abre feature nueva)
- [memory:CONSTRAINTS.md#R2] (atomic commit en cierre DONE, conventional commits format)
- [memory:CONSTRAINTS.md#R10] (Brand DNA gate condicional si sprint toca UI)
- [memory:CONSTRAINTS.md#R14] (destructive tools sin execute condicional si sprint genera tools)
- [memory:CONSTRAINTS.md#R7] (three-layer verification — sprint hereda el contract del active feature)
