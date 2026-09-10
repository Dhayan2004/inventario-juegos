# Checkpoint Progress — cuando pausar y mostrar estado al usuario

## Objetivo

Definir CUÁNDO el sprint debe pausar (forzado o por request del usuario) y CÓMO reportar el estado para que el sprint sea retakeable. Pausar bien es la diferencia entre "retomar en 30s" y "perder 10 minutos reconstruyendo contexto".

## Triggers de checkpoint

| Trigger | Comportamiento |
|---------|----------------|
| Usuario responde `pause` en ciclo N | Checkpoint inmediato, save state, reportar |
| Ciclo 5 alcanzado sin `done` | Checkpoint forzado, requiere decisión usuario (done/pause/escalate/+5-mas) |
| Cambio falla en typecheck/test/lint | Checkpoint con flag de falla, esperar `continúa-fix` o `revertí` |
| Desviación del criterio detectada | Checkpoint con flag de desviación, esperar `revertí-último` / `redefiní-criterio` / `continúa` / `escalate` |
| Time budget excedido (>20 min total) | Checkpoint forzado, recomendar escalate |
| Usuario silencioso post-ciclo (no responde) | Pause por timeout, diff staged, mensaje de retake |

## Estado a guardar

Cuando se hace checkpoint, el sprint guarda (NO commit, working tree):

1. **Diff acumulado** — `git diff` muestra todos los cambios desde inicio del sprint
2. **Lista de archivos modificados** — `git status --short`
3. **Criterio de éxito definido** — explicitar qué se buscaba
4. **Ciclos completados** — N de M esperados
5. **Razón del checkpoint** — pause-by-user / max-iterations / failure / divergence / timeout
6. **Próximo ciclo posible** — si hay dirección clara, describirla

NO commit. El diff queda en working tree para inspección.

## Output del checkpoint

### Caso 1 — Pause solicitado por usuario

```markdown
## Sprint pause — ciclo N de M esperados

**Razón:** pause solicitado por usuario.

**Estado actual:**
- Archivos modificados: `path/a.tsx`, `path/b.tsx`
- LOC delta: +12 / -8
- Ciclos completados: N
- Criterio: <criterio>
- Convergencia: <cerca / parcial / lejos>

**Diff acumulado:**
```
<git diff resumen — usar `git diff --stat` para resumen, full diff disponible bajo request>
```

**Para retake:**
- Mirá `git diff` para ver el estado completo
- Decidí: `continúa` (siguiente ciclo), `revertí` (vuelvo a clean), `done` (cierro con commit atómico)
- Si necesitás contexto del loop: `cat` esta nota o relé los ciclos previos

**Diff queda en working tree (no commit).**
```

### Caso 2 — Checkpoint forzado en ciclo 5

```markdown
## Sprint checkpoint forzado — ciclo 5 alcanzado

**Razón:** max iterations (5) sin `done` explícito. Sprint NO continúa silencioso.

**Estado actual:**
- Archivos modificados: <files>
- LOC delta: <delta>
- Criterio: <criterio>
- Convergencia: <reportar honestamente>

**Posibles acciones:**

1. **`done`** — cerrar con commit atómico aunque no sea perfecto.
   *Apropiado si:* el resultado actual cumple el criterio "suficientemente bien".

2. **`pause`** — diff queda staged, retake después.
   *Apropiado si:* querés volver con cabeza fresca, o consultar otra cosa primero.

3. **`escalate-golpe`** — handoff a /el-golpe (one-shot rewrite del scope completo).
   *Apropiado si:* el sprint diverge porque el approach inicial no era correcto, y querés un rewrite limpio.

4. **`escalate-build`** — handoff a /build (la-forja, planning formal).
   *Apropiado si:* la tarea reveló ser un feature mediano/grande, no un sprint.

5. **`+5-mas`** — extender a 10 ciclos máximo (escape hatch).
   *Apropiado si:* tenés razón específica para creer que 2-3 ciclos más cierran. NO usar como default.
   *Anti-pattern si:* es la segunda vez que se pide en el mismo sprint — eso es signal de divergence, escalate.

**Tu turno.** Sin elección, default es `pause`.
```

### Caso 3 — Checkpoint por failure (typecheck / test / lint)

```markdown
## Sprint checkpoint — falla detectada en ciclo N

**Razón:** el cambio del ciclo N introduce <typecheck error / test failure / lint warning>.

**Falla específica:**
```
<error output recortado a lo relevante>
```

**Estado actual:**
- Working tree: dirty con la falla
- Criterio: <criterio>

**Posibles acciones:**

1. **`continúa-fix`** — fixeo el error en el ciclo N+1 antes de seguir refinando.
2. **`revertí-último`** — vuelvo al estado pre-ciclo N (working tree sin el cambio fallido).
3. **`pause`** — paramos acá, fixeás vos manualmente.
4. **`escalate-golpe`** — la falla revela que el scope era más grande de lo que parecía.

**Tu turno.**
```

### Caso 4 — Checkpoint por desviación del criterio

```markdown
## Sprint checkpoint — desviación del criterio

**Razón:** los últimos 2 ciclos están alejándose del criterio en lugar de acercarse.

**Criterio original:** <criterio>
**Estado actual:** <descripción>

**Hipótesis de divergencia:**
- <ej: el criterio era ambiguo, el usuario y el agente lo interpretaron distinto>
- <ej: el approach inicial no es el correcto, hay que cambiar de táctica>
- <ej: scope creep — el sprint está intentando resolver más que lo pedido>

**Posibles acciones:**

1. **`redefiní-criterio`** — re-pensamos qué es "done" con info nueva del loop.
2. **`revertí-último`** — vuelvo al estado del último ciclo bueno y probamos otra dirección.
3. **`escalate-golpe`** — el sprint NO va a converger, mejor un rewrite one-shot del scope.
4. **`continúa`** — vos viste algo que yo no, sigo afinando con la dirección actual.

**Tu turno.**
```

### Caso 5 — Pause por timeout / silencio

```markdown
## Sprint pause — sin respuesta post-ciclo N

**Razón:** ejecuté ciclo N pero no recibí feedback en este turn.

**Estado actual:**
- Working tree: con el cambio del ciclo N
- Criterio: <criterio>

**Para retake:**
- `git diff` muestra el estado
- Cuando vuelvas: decidí `continúa` / `done` / `revertí` / `pause` (mantener)

**Diff queda en working tree.** No commit.
```

## Reglas operativas del checkpoint

1. **Checkpoint NO es commit.** Working tree queda dirty con los cambios. Sin commit hasta cierre `done` explícito.

2. **Checkpoint preserva contexto en el output del agente.** El user retoma leyendo el último checkpoint output — no debería tener que reconstruir el loop desde cero.

3. **NO inventar próxima dirección.** Si el sprint no tiene clara la próxima dirección post-checkpoint, reportar honestamente: "Sin dirección clara para ciclo siguiente. Pausa recomendada."

4. **Checkpoint forzado en ciclo 5 NO es opcional.** Si el usuario pide implícitamente seguir ("dale, otro ciclo"), aceptar SOLO si lo verbaliza como `+5-mas` con razón. NO continuar a ciclo 6 silencioso.

5. **Estado queda visible para retake.** El working tree dirty + el output del checkpoint son la fuente de retake. NO ocultar estado en lugares que el usuario no ve (no archivos `.sprint-state.json` raros — todo en git working tree + chat).

6. **Múltiples checkpoints en el mismo sprint son signal de fricción.** Si un sprint tiene 2+ checkpoints (failures, desviaciones, pause-resume), considerar escalate al final aunque cierre `done`. Reportar como E-NNN candidato si recurre cross-sprint.

## Citations

- [memory:CONSTRAINTS.md#R1] (sprint opera dentro de active feature, checkpoint NO toca feature_list)
- [memory:CONSTRAINTS.md#R2] (atomic commit solo en cierre done, NO en checkpoint)
