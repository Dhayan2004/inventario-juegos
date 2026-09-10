# brief-plan

> Template del plan visible (3-5 líneas) que el-golpe muestra al usuario antes de ejecutar. NO Blueprint completo (eso es la-herreria), NO discovery extendida (>5min lectura → escalate). El brief existe para alinear scope con el usuario en <2min.

## Inputs

- Descripción de la feature (usuario o sub-agent dispatcher).
- Active feature actual del `feature_list.json`.
- Estado del repo (PREFLIGHT pasó: tests verdes + brand.json si UI).

## Output

Brief plan textual mostrado al usuario, formato canónico:

```markdown
## Brief plan: <descripción 1 línea>

**Archivos afectados:**
- `path/to/file1.tsx` — <qué cambia, una línea>
- `path/to/file2.ts` — <qué cambia>
- `path/to/file3.sql` — <qué cambia> *(si schema change → handoff a el-migrador)*

**Approach:**
<2-3 líneas explicando el approach. Mencionar libs externas si aplica
(ej: "uso react-hook-form con Zod, ya instalado").>

**Verification:**
- typecheck: `tsc --noEmit`
- tests: `npm test -- --findRelatedTests <files>`
- visual check (si UI): <opcional>

**Estimación:**
- Wallclock: ~<N>min
- Commits: <1-3>

**Tu turno:**
"go" → ejecuto · "ajustá X" → reescribo brief · "escalá a /build" → handoff
```

## Reglas del brief

### Concisión

3-5 líneas en sección "Archivos afectados". Si necesitás 6+ archivos, no es golpe — escalate a `/build`.

2-3 líneas en "Approach". Si necesitás párrafo, falta clarity en el scope o approach es complejo → considerá escalate.

### Concreción

NO "agregar feature de invitar miembros" (vago).
SÍ "agregar form de invitar email + endpoint POST /api/invite + email template + tabla invitations":

```markdown
**Archivos afectados:**
- `app/(app)/team/InviteForm.tsx` — nuevo form con react-hook-form + Zod
- `app/api/invite/route.ts` — POST endpoint con validación + send email
- `lib/email/InviteEmail.tsx` — React Email template
- `.claude/migrations/0005_invitations.sql` — tabla invitations + RLS L-001
```

4 archivos = límite. Si emerge un 5to, halt + escalate.

### Approach con dep awareness

Mencionar libs ya instaladas vs requeridas:

```markdown
**Approach:**
- Uso react-hook-form + Zod (ambos instalados, NO new dep).
- Email via Resend (instalado por add-emails). Template hereda voice.json.
- RLS L-001 enforced en invitations table (user_id FK to profiles).
```

Si requiere nueva dep → flag explícito al usuario:

```markdown
**Approach:**
- ⚠️ Requiere instalar `react-email` (~50KB).
- ¿Confirmás la dep nueva o preferís solución sin react-email?
```

NO instalar dep silenciosamente. Confirmation explícita.

### Verification concreta

NO "correr tests" (vago).
SÍ comandos exactos con paths:

```markdown
**Verification:**
- `tsc --noEmit`
- `npm test -- --findRelatedTests app/(app)/team/InviteForm.tsx app/api/invite/route.ts`
- Visual: ir a `/team`, click "Invite", confirmar email recibido en bandeja test.
```

### Estimación honesta

Wallclock realista. Si "feel" >25min → considerá si realmente es golpe o si hay que escalate.

Commits: 1 si cambio compacto, 2 si separación natural (schema + UI), 3 si feature involucra schema + lib + UI.

Si estimás 4+ commits → escalate.

## L-004 test aplicado

| Caso | ¿Upstream user action requerida? | Resultado |
|------|----------------------------------|-----------|
| Sin active feature (PREFLIGHT) | Sí (pickear backlog) | **PREFLIGHT halt, NO PAUSE genuino del selector** |
| Sin brand.json + UI requerida (PREFLIGHT) | Sí (corre /add-ui-kit) | **PREFLIGHT halt, NO PAUSE genuino** (gate de entrada) |
| Tests rojos pre-arranque (PREFLIGHT) | Sí (fixar tests) | **PREFLIGHT halt, NO PAUSE genuino** |
| Scope excede 30min | NO — escalate a /build SIEMPRE disponible | NO PAUSE |
| Scope excede mid-execution | NO — commit lo hecho + escalate | NO PAUSE |
| Iteración con feedback humano emerge | NO — escalate a sprint SIEMPRE disponible | NO PAUSE |
| Paralelización requerida | NO — escalate a la-forja Fork | NO PAUSE |

**Conclusión D-017:** **BINARY** confirmed. execute (default si scope califica) o escalate-graceful (a /build / sprint / la-forja según razón). NO PAUSE genuino — todas las escalaciones SIEMPRE disponibles, no requieren upstream user action específica del selector.

Razón heredada de D-016: paralelo conceptual a el-tajo (escalate a el-golpe SIEMPRE disponible). El patrón "escalate up the lightweight ladder" es BINARY by structure — D-017 lo confirma para el-golpe.

## Brief plan template canónico

```markdown
## Brief plan: <feature description in 1 line>

**Active feature:** <F?-S?>
**R10 enforcement:** <SÍ - feature toca UI, lee brand.json | NO - logic-only>
**R14 enforcement:** <SÍ - genera tool destructiva | NO - feature benigna>
**L-001 enforcement:** <SÍ - tabla user data | NO - sin DB user-tied>
**L-003 enforcement:** <SÍ - inputs externos | NO - sin validators public>

**Archivos afectados (1-3 ideal, max 5):**
- `<path>` — <cambio en 1 línea>
- `<path>` — <cambio>
- `<path>` — <cambio>

**Approach (2-3 líneas):**
<explanation con dep awareness>

**Sub-skills invocados (si aplica):**
- impeccable (si UI con tokens)
- el-migrador (si schema change)
- find-docs (si lib externa requiere docs frescas)

**Verification:**
- typecheck: `<command>`
- tests: `<command>`
- visual (si UI): `<paso>`

**Estimación:**
- Wallclock: ~<N>min
- Commits: <1-3>

**Tu turno:**
"go" / "ajustá <X>" / "escalá"
```

## Edge cases

### Edge: usuario dice "go" pero el brief omite un archivo crítico

→ Si durante ejecución detectás archivo crítico no listado en brief → halt + actualizar brief + esperar nueva confirmación. NO scope creep silencioso.

### Edge: usuario dice "ajustá X" → re-emitir brief

→ Aplicar el ajuste + re-emitir brief completo (no solo diff). Esperar nueva "go".

### Edge: usuario silencio post-brief (no responde)

→ Esperar. NO ejecutar default. el-golpe es one-shot CON confirmation explícita.

### Edge: scope excede mid-brief (al escribir el brief realizás que es más grande)

→ NO emitir el brief. Output directo: "Mientras escribía el brief detecté que el scope excede 30min. Escalate a /build con razón concreta: <texto>."

### Edge: feature mixta UI + schema + auth + payments (4 dominios)

→ Suele exceder. Brief tendrá 6+ archivos. Halt + escalate. la-forja Coordinator pattern es el path correcto para multi-domain.

### Edge: usuario insiste "es golpe, ejecutalo"

→ Si los criterios objetivos dicen no (LOC > 800, archivos > 5, wallclock > 35min) → respetar el límite. Reportar con datos: "Brief muestra 6 archivos + 900 LOC — excede criterios golpe. Si querés forzar, considera que el resultado puede no ser commit-clean."

## Citation grammar

- [memory:CONSTRAINTS.md#R1] — active feature requirement.
- [memory:CONSTRAINTS.md#R2] — atomic commits cierre.
- [memory:CONSTRAINTS.md#R10] — brand.json gate condicional.
- [memory:CONSTRAINTS.md#R14] — destructive tools confirmation.
- [memory:lessons#L-001] — RLS si tabla user data.
- [memory:lessons#L-003] — whitelist validators si inputs externos.
- [memory:lessons#L-004] — binary D-017 informativo.
- [memory:decisions#D-017] — el-golpe binary, NO PAUSE.

## Refusals

- ❌ Brief vago ("agregar feature X" sin paths).
- ❌ Skip de confirmation explícita del usuario antes de ejecutar.
- ❌ Brief con 6+ archivos (si excede, escalate antes de mostrar).
- ❌ Approach con párrafo largo (señal de scope mediano-mal-fitted).
- ❌ Verification con comandos vagos ("correr tests").
- ❌ Estimación inflada deliberadamente (honesty es contrato).
- ❌ Forzar golpe contra criterios objetivos por presión del usuario.
