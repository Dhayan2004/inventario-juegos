# Execute Iteration — el ciclo per-cycle del loop

## Objetivo

Ejecutar UN ciclo del loop sprint: hacer un cambio pequeño, mostrar el diff, pedir feedback explícito al usuario, esperar respuesta. Cada ciclo es ~2-3 min. Max 5 ciclos por sprint.

## Estructura de un ciclo

```
1. EXECUTE (~30s-2min)
   - Hacer 1 cambio pequeño (Edit / Write / refactor chico)
   - Foco: el cambio mínimo que mueve hacia el criterio de éxito
   - NO acumular cambios — un ciclo, un cambio coherente

2. SHOW (~30s)
   - Diff del cambio (texto puro si es código/copy)
   - Output del cambio (si es validator: ejecutar tests; si es styling: descripción del visual delta)
   - Si es UI y hay screenshot disponible, referenciar

3. ASK (~10s)
   - Pedir feedback con 4 opciones explícitas:
     1. continúa — siguiente ciclo
     2. pause — checkpoint y reportar
     3. done — cerrar
     4. escalate — handoff a el-golpe / /build

4. WAIT (variable)
   - Esperar respuesta del usuario
   - NO ejecutar el siguiente ciclo silenciosamente
   - NO inventar respuesta
```

## Template de ciclo

```markdown
### Ciclo N (de M esperados)

**Cambio:** <descripción 1 línea de qué se modificó>

**Diff:**
```
<git diff o snippet del cambio>
```

**Resultado observable:** <qué se ve / qué pasa ahora>

**Tu turno:**
- `continúa` — voy al ciclo N+1
- `pause` — paramos acá, te reporto estado
- `done` — cerramos con commit atómico
- `escalate` — esto excede sprint, handoff a el-golpe / /build
```

## Reglas operativas del ciclo

1. **Un cambio coherente por ciclo.** NO mezclar "ajusté el copy + el spacing + agregué un validator" en un solo ciclo. Cada uno es su propio ciclo (o su propio sprint si es scope distinto).

2. **El diff es la unidad de feedback.** El usuario decide a partir del diff, no de la descripción narrativa. Mostrar el diff completo del cambio. Si es UI con screenshot disponible, agregar referencia.

3. **NO commits intermedios.** Cada ciclo modifica el working tree. Los commits van al CIERRE del sprint (un solo commit atómico, R2). Ciclos intermedios pueden:
   - Quedar en working tree (default)
   - Hacer `git stash` si el usuario quiere comparar contra clean state
   - NO `git commit` por ciclo

4. **Pedir feedback CON las 4 opciones explícitas.** No abrir el feedback ("¿qué te parece?") — listar `continúa / pause / done / escalate`. Reduce ambiguity. El usuario puede agregar matiz ("done pero achicá un poquito el padding"), pero las 4 opciones son el menú base.

5. **Si el usuario responde con un cambio nuevo en lugar de elegir opción.** Ejemplo: usuario dice "ahora hacelo más grande". Eso es implícitamente "continúa con un ajuste específico". Ejecutar el ajuste como ciclo N+1, NO preguntar de nuevo.

6. **Si el usuario responde con duda.** Ejemplo: usuario dice "no sé, qué pensás vos". Eso es signo de criterio borroso. Recordar el criterio definido en plan rápido. Si el criterio dice "el usuario decide", responder honestamente: "Está cumpliendo el criterio que definimos (X). Podés decir done si te alcanza, o continúa si querés afilar más."

7. **NO self-eval del cambio.** El sprint NO decide "esto ya está bien". Solo el usuario cierra el sprint con `done`. La excepción: si max iterations (5) sin convergencia, el sprint FUERZA un checkpoint, NO decide done unilateralmente.

8. **Cada ciclo nuevo construye sobre el anterior.** NO empezar de cero por ciclo. NO revertir el cambio anterior salvo que el usuario diga explícitamente "revertí el último".

## Ejemplo completo de ciclo (caso copy iteration)

```markdown
### Ciclo 1 (de 2-3 esperados)

**Cambio:** reemplacé el CTA "Empezar ahora" por "Probá Forja gratis 14 días" en `components/Hero.tsx`.

**Diff:**
```diff
- <Button>Empezar ahora</Button>
+ <Button>Probá Forja gratis 14 días</Button>
```

**Resultado observable:** CTA ahora es más específico, comunica trial duration + sin riesgo.

**Tu turno:**
- `continúa` — afino más (más urgencia, otro tono, etc)
- `pause` — paramos acá
- `done` — cierro con `feat(F3-S8): refine hero CTA copy`
- `escalate` — el problema es más grande (ej: rediseñar hero completo) → el-golpe
```

Usuario responde: "más urgencia, sin perder el trial mention".

```markdown
### Ciclo 2 (de 2-3 esperados)

**Cambio:** reescribí el CTA con verb fuerte + trial mention compactado.

**Diff:**
```diff
- <Button>Probá Forja gratis 14 días</Button>
+ <Button>Forjá tu primer proyecto — 14 días gratis</Button>
```

**Resultado observable:** verb activo "Forjá" (matchea el brand), trial mention preservado, mismo length.

**Tu turno:**
- `continúa` — sigo afinando
- `pause` — paramos acá
- `done` — cierro con `feat(F3-S8): refine hero CTA copy con verb activo`
- `escalate` — el-golpe / /build
```

Usuario: "done".

→ Procede a [`close-or-escalate.md`](close-or-escalate.md) con outcome `done`.

## Edge cases del ciclo

### Edge 1 — El cambio falla en runtime (typecheck / test)

Si el ciclo introduce error en typecheck/test/lint:

```markdown
### Ciclo N

**Cambio:** <descripción>
**Diff:** ...

**⚠ Falla detectada:** `tsc` reporta `Property 'foo' does not exist on type 'Bar'` en `path/file.tsx:23`.

**Tu turno:**
- `continúa-fix` — fixeo el error en el siguiente ciclo
- `pause` — paramos acá, fixeás vos
- `revertí` — vuelvo al estado pre-ciclo y replanteamos
```

NO mostrar diff con error sin flagearlo. NO continuar al siguiente ciclo silenciosamente con error en working tree.

### Edge 2 — Usuario no responde

Si no hay respuesta del usuario en el contexto de turn (caso async / batch), default a `pause`. NO continuar silencioso. Reportar:

```markdown
### Ciclo N — pause por timeout

Ejecuté ciclo N pero no recibí feedback. Pause con diff staged.
Para retake: `git diff` muestra el estado, decidí continúa/done/revertí.
```

### Edge 3 — El cambio diverge del criterio de éxito

Si el ciclo N+1 está alejándose del criterio en lugar de acercarse:

```markdown
### Ciclo N — desviación detectada

**Cambio:** <descripción>
**Diff:** ...

**⚠ Desviación:** el criterio era "<criterio>". Este ciclo se aleja porque <razón>.

**Tu turno:**
- `revertí-último` — vuelvo al estado de ciclo N-1 y probamos otra dirección
- `redefiní-criterio` — re-pensamos el criterio con info nueva
- `continúa` — vos viste algo que yo no, sigo
- `escalate` — esto excede sprint
```

### Edge 4 — Ciclo 5 (último permitido)

```markdown
### Ciclo 5 — checkpoint forzado

Llegamos a 5 ciclos sin done explícito. Sprint NO continúa a ciclo 6 silencioso.

**Estado actual:**
- Cambios acumulados: <files modified, LOC delta>
- Criterio definido: <criterio>
- Convergencia: <cerca / lejos / divergente>

**Tu turno:**
- `done` — cierro con commit atómico (aunque no sea perfecto)
- `pause` — diff staged, retake después con cabeza fresca
- `escalate-golpe` — handoff a /el-golpe (one-shot rewrite del scope)
- `escalate-build` — handoff a /build (planning formal)
- `+5-mas` — extender presupuesto a 10 ciclos máximo, EXPLÍCITAMENTE (anti-pattern, requiere razón)
```

`+5-mas` es escape hatch raro — requiere razón específica del usuario. Si el usuario lo pide reiteradamente, sprint lo registra como friction (E-NNN candidato).

## Citations

- [memory:CONSTRAINTS.md#R1] (sprint opera dentro de active feature)
- [memory:CONSTRAINTS.md#R2] (atomic commit en cierre, NO commits por ciclo)
