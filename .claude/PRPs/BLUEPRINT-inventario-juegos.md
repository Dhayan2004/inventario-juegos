# 📋 BLUEPRINT: Inventario de Videojuegos

> **Master Blueprint · arné Forge · `la-herreria` · ruta 🔧 Herramienta Interna · 2026-09-09**
> **Build Mode:** 🔧 Herramienta Interna
> **Total Fases:** 7 · **Estimación total:** ~22–30 h de build
> **Destino en el repo de producto:** `.claude/PRPs/BLUEPRINT-inventario-juegos.md`
> **Listo para `/build`** (`el-yunque` manual recomendado; `la-forja` opcional) — *tras* resolver los ⚠️ y los gates R10/R11.
>
> **Este documento no contiene código de implementación.** Modelo de datos y flujos se expresan como
> especificación; el DDL, los componentes y los tests los produce el motor de build (`el-yunque` /
> `la-forja` / `el-migrador` / `impeccable`) dentro del repo de producto.

---

## 0. Contexto resumido (autocontenido)

### Producto

Aplicación web para llevar el **inventario de una colección de videojuegos**: dar de alta juegos,
editar/eliminar los que ya están cargados, y ver estadísticas agregadas de la colección.

La **arquitectura de navegación es el requisito duro** (pedido explícito del usuario, ✅):

- **Menú Principal = panel de control puro.** Solo título + controles de navegación (texto / botones).
  **No** muestra datos, **no** ejecuta acciones de negocio, **no** consulta la capa de datos.
- **Cada opción del menú abre una vista independiente y aislada:** ruta propia, sin estado compartido en
  memoria con las demás vistas, con retorno explícito al menú. Cada vista debe poder abrirse por deep-link
  directo y funcionar sola.
- **Tres vistas obligatorias:** Agregar juegos · Editar registros existentes · Estadísticas.

### Modo y encuadre

Herramienta interna / de uso personal. Sin modelo de negocio externo, sin landing, sin pagos. La
prioridad es **funcionalidad + claridad de navegación**; la estética es funcional/densa (preset
Brand DNA *Tech Utility*).

### Stack (⚠️ a fijar en Tech Spec, Fase 1)

| Capa | Elección propuesta (Golden Path Forge) | Nota |
|---|---|---|
| Framework | Next.js (App Router) | Una ruta por vista → aislamiento natural |
| Lenguaje | TypeScript | — |
| Persistencia | Postgres vía Supabase, con RLS (lección L-001) | ⚠️ Alternativa local-first (almacenamiento del navegador) si nunca se comparte entre dispositivos → decisión `baas` |
| Validación de entrada | Esquema con whitelist de campos (lección L-003) | Aplica en la capa de datos y en los formularios |
| UI | `add-ui-kit` (Brand DNA) + `impeccable` (componentes) | Preset *Tech Utility* |
| Auth | **Ninguna** (⚠️ supuesto: usuario único) | Si hay multiusuario → entra `/add-login` en Fase 1 y `game` gana `user_id` + RLS por usuario |
| Tests | Unit (capa de datos + agregaciones) + e2e (flujos de navegación y CRUD) | Comandos en cada feature de `feature_list.json` |
| Deploy | Vercel o Coolify | ⚠️ según Tech Spec |

### Brand DNA (R10)

- Preset: **Tech Utility** (densidad alta, postura funcional, sin decoración innecesaria).
- Se genera con `/add-ui-kit` en `F2-01` → `brand/brand.json` + `brand/voice.json` + `brand/brand.css`.
- Anti-slop: sin Inter/Roboto/Arial como fuente principal, sin gradientes violeta sobre blanco, sin
  defaults de Tailwind. Accesibilidad gana sobre estética.
- **Ninguna UI se genera sin leer `brand.json` + `voice.json` primero** (reject automático de `el-evaluador`).

### Usuarios

Un solo rol (⚠️): la persona dueña de la colección. Sin permisos, sin roles, sin auditoría de acciones
en v1.

### Fuera de alcance (v1) — ⚠️ confirmar

Importación masiva, exportación, imágenes/carátulas subidas, paginado avanzado, historial de cambios,
multiusuario, app móvil nativa, sincronización entre dispositivos más allá de la DB.

---

## 1. Resumen de historias de usuario

> Detalle completo diferido a `USER-STORIES-inventario-juegos.md` (a generar con el asset #05 dentro del
> repo de producto). Aquí, el resumen que el build necesita.

| Épica | Historias | Prioridad | Fase |
|---|---|---|---|
| **E1 · Navegación** | US-01 Ver el menú principal como panel de control · US-02 Entrar a una vista desde el menú · US-03 Volver al menú desde cualquier vista · US-04 Abrir una vista por URL directa | P0 | F2 |
| **E2 · Alta** | US-05 Cargar un juego nuevo con sus datos · US-06 Ver validación de campos obligatorios · US-07 Recibir confirmación de alta · US-08 Cargar varios seguidos | P0 | F3 |
| **E3 · Edición** | US-09 Ver la lista de juegos cargados · US-10 Buscar/filtrar en la lista · US-11 Editar los datos de un juego · US-12 Eliminar un juego con confirmación (⚠️) | P0 | F4 |
| **E4 · Estadísticas** | US-13 Ver el total de la colección · US-14 Ver desglose por plataforma / estado / formato · US-15 Ver valor total y promedios · US-16 Ver un estado vacío coherente sin datos | P0 | F5 |
| **E5 · Calidad** | US-17 Operar todo por teclado · US-18 La app cumple WCAG 2.1 AA en lo verificable | P1 | F6 |

Journey principal:

```
Menú Principal ──"Agregar juegos"──▶ Vista Agregar ──(guardar)──▶ confirmación ──▶ volver al Menú
      │
      ├──"Editar registros"──▶ Vista Editar ──(elegir)──▶ formulario ──(guardar/eliminar)──▶ volver
      │
      └──"Estadísticas"──▶ Vista Estadísticas ──(leer)──▶ volver al Menú
```

---

## 2. Bootstrap Contract (R11) — pre-flight

En el repo de producto, antes de `/build`:

```
[ ] make setup exit 0
[ ] ≥1 test passing
[ ] feature_list.json con ≥3 features y verification command  (este blueprint entrega 19)
[ ] .claude/memory/skills.md generado y validado
[ ] brand/brand.json + brand/voice.json existen  (correr /add-ui-kit, preset Tech Utility)
[ ] make preflight exit 0
```

`/build` no se permite hasta que `make preflight` dé exit 0.

---

## 3. Modelo de datos — entidad `game` (especificación, ⚠️ campos a confirmar)

> El DDL con RLS lo genera `el-migrador` en `F1-02` (lección L-001: toda tabla con datos del usuario
> con RLS activo). Aquí, la especificación de campos.

| Campo | Tipo | Requerido | Default | Nota |
|---|---|---|---|---|
| `id` | UUID | sí | generado | Clave primaria |
| `title` | texto | sí | — | Nombre del juego |
| `platform` | texto (enum) | sí | — | ⚠️ valores: PC · PlayStation · Xbox · Nintendo Switch · Retro · Otro |
| `genre` | texto | no | — | ⚠️ libre o catálogo |
| `status` | texto (enum) | sí | `owned` | ⚠️ owned · wishlist · playing · completed · abandoned |
| `format` | texto (enum) | no | — | ⚠️ physical · digital |
| `quantity` | entero | sí | 1 | ⚠️ ≥ 1; para copias duplicadas |
| `purchase_price` | decimal | no | — | ⚠️ moneda única a definir |
| `purchase_date` | fecha | no | — | — |
| `rating` | entero | no | — | ⚠️ escala 1–10 |
| `notes` | texto | no | — | Texto libre |
| `created_at` | timestamp | sí | ahora | Para "altas por mes" |
| `updated_at` | timestamp | sí | ahora | Se actualiza en cada edición |

Validación (lección L-003): whitelist explícita de campos aceptados en alta y edición; `quantity ≥ 1`;
`rating` dentro de rango si viene; `platform`/`status` dentro del enum.

---

## 4. Vistas y screen flows (ASCII inline)

> Wireframes de baja fidelidad — documentación, no diseño final. El diseño lo produce `impeccable`
> consumiendo `brand.json`.

### 4.1 Vista **Menú Principal** (`/`) — panel de control puro

```
┌─────────────────────────────────────────────┐
│                                             │
│        INVENTARIO DE VIDEOJUEGOS             │
│                                             │
│   ┌───────────────────────────────────┐     │
│   │        ▸  Agregar juegos          │     │   → navega a /agregar
│   └───────────────────────────────────┘     │
│   ┌───────────────────────────────────┐     │
│   │        ▸  Editar registros        │     │   → navega a /editar
│   └───────────────────────────────────┘     │
│   ┌───────────────────────────────────┐     │
│   │        ▸  Estadísticas            │     │   → navega a /estadisticas
│   └───────────────────────────────────┘     │
│                                             │
└─────────────────────────────────────────────┘

Regla dura: esta vista NO renderiza registros, NO muestra conteos,
NO importa la capa de datos. Solo navegación.
```

### 4.2 Vista **Agregar juegos** (`/agregar`) — aislada

```
┌─────────────────────────────────────────────┐
│  ‹ Volver al menú                            │
│                                             │
│  AGREGAR JUEGO                               │
│  ─────────────────────────────────────────  │
│  Título *        [_______________________]  │
│  Plataforma *    [ PC ▾ ]                    │
│  Estado *        [ owned ▾ ]                 │
│  Formato         [ físico ▾ ]               │
│  Cantidad *      [ 1 ]                       │
│  Género          [_______________________]  │
│  Precio          [________]  Fecha [______]  │
│  Calificación    [ – ▾ ]                     │
│  Notas           [_______________________]  │
│                                             │
│            [ Guardar juego ]                │
│                                             │
│  ✓ "God of War" agregado.  (feedback)       │
└─────────────────────────────────────────────┘

- Requeridos vacíos → error inline bajo el campo, no envía.
- Éxito → mensaje + formulario limpio para otra alta.
- Error de servidor → conserva lo tecleado.
```

### 4.3 Vista **Editar registros existentes** (`/editar`) — aislada

```
┌─────────────────────────────────────────────┐
│  ‹ Volver al menú                            │
│  EDITAR REGISTROS                            │
│  Buscar [ zelda________ ]  Plataforma [▾]    │
│  ─────────────────────────────────────────  │
│  │ Título              Plataforma  Estado │  │
│  │ ─────────────────────────────────────  │  │
│  │ Zelda: TotK         Switch      playing │ ▸│  → selecciona
│  │ Zelda: BotW         Switch      done    │ ▸│
│  ─────────────────────────────────────────  │
│                                             │
│  ── al seleccionar ──▼                       │
│  EDITAR · "Zelda: TotK"                      │
│  Título      [ Zelda: Tears of the Kingdom]  │
│  Plataforma  [ Switch ▾ ]   Estado [ done ▾]  │
│  ...                                         │
│     [ Guardar cambios ]   [ Eliminar ]       │
│                                             │
│  Eliminar → escribí "ELIMINAR" para confirmar│  (R14, sin ejecución automática)
└─────────────────────────────────────────────┘

- 0 registros → estado vacío con enlace a /agregar.
```

### 4.4 Vista **Estadísticas** (`/estadisticas`) — aislada, solo lectura

```
┌─────────────────────────────────────────────┐
│  ‹ Volver al menú                            │
│  ESTADÍSTICAS                                │
│  ─────────────────────────────────────────  │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐  │
│  │ Total     │ │ Valor     │ │ Rating    │  │
│  │   128     │ │ $ 4.210   │ │  7.8 prom │  │
│  └───────────┘ └───────────┘ └───────────┘  │
│                                             │
│  Por plataforma        Por estado           │
│  PC .............. 54   owned ......... 90   │
│  Switch .......... 41   playing ....... 6    │
│  PlayStation ..... 25   completed .... 28    │
│  Xbox ............ 8    wishlist ...... 4    │
│                                             │
│  Por formato:  físico 61  ·  digital 67      │
│                                             │
│  (sin datos → "Sin juegos cargados todavía")│
└─────────────────────────────────────────────┘

- Vista de solo lectura: no muta datos, no enlaza a otras vistas salvo "volver al menú".
```

---

## 5. Métricas de la vista Estadísticas (⚠️ set exacto a confirmar)

| Métrica | Cálculo | Estado vacío |
|---|---|---|
| Total de juegos | suma de `quantity` sobre todos los registros | 0 |
| Registros distintos | conteo de filas | 0 |
| Por plataforma | conteo agrupado por `platform` | lista vacía |
| Por estado | conteo agrupado por `status` | lista vacía |
| Por formato | conteo agrupado por `format` (físico / digital / sin dato) | lista vacía |
| Valor total | suma de `purchase_price * quantity` (ignora nulos) | $ 0 |
| Precio promedio | valor total / registros con precio | — |
| Calificación promedio | promedio de `rating` sobre registros con rating | — |
| Altas por mes | conteo agrupado por mes de `created_at` (⚠️ opcional v1) | — |

Las agregaciones se prueban con un dataset fijo en `stats-aggregations` (test unit): cada métrica tiene
un número esperado exacto.

---

## 6. Fases de desarrollo

> Detalle de subfases, tareas y gate R7 por fase en `PLAN-POR-FASES-inventario-juegos.md`. Resumen
> ejecutable acá; cada tarea mapea a una feature de `feature_list.json` §8.

### FASE 1 — Cimientos y datos
> **Entregable:** proyecto corriendo en local + entidad `game` con capa de acceso probada + `make preflight` exit 0. Sin UI.
> **Dependencias:** ninguna. **Features:** `F1-01`, `F1-02`, `F1-03`.
> **Skills:** `baas` (decisión de persistencia), `el-migrador` (migración + RLS).
> **Gate R7:** Layer 1 `make typecheck && make lint` · Layer 2 `make test` (datos) · Layer 3 n/a → migración aplica/revierte contra DB real. Firma `el-evaluador`.

### FASE 2 — Shell, panel de control y navegación aislada
> **Entregable:** Menú Principal (solo navegación) + 3 rutas aisladas vacías con retorno al menú + design system aplicado.
> **Dependencias:** F1. **Features:** `F2-01`, `F2-02`, `F2-03`, `F2-04`.
> **Skills:** `add-ui-kit` (preset Tech Utility, gate R10), `impeccable`.
> **Screen flows:** §4.1 (menú), placeholders de §4.2–4.4.
> **Gate R7:** Layer 1 · Layer 2 · Layer 3 `make e2e` (`main-menu`, `navigation-isolation`, `layout`) + visual diff vs `brand.json`. Firma `el-evaluador`.

### FASE 3 — Vista Agregar juegos
> **Entregable:** alta persistida desde la vista aislada, con validación, feedback y manejo de error.
> **Dependencias:** F1 (datos), F2 (shell + ruta). **Features:** `F3-01`, `F3-02`, `F3-03`.
> **Screen flow:** §4.2. **Skills:** `impeccable` (formulario).
> **Gate R7:** Layer 1 · Layer 2 · Layer 3 (`add-game-form`, `add-game-persist`). Firma `el-evaluador`.

### FASE 4 — Vista Editar registros existentes
> **Entregable:** listar → seleccionar → actualizar → eliminar (confirmación tipada, R14) un registro.
> **Dependencias:** F1, F2, F3. **Features:** `F4-01`, `F4-02`, `F4-03`.
> **Screen flow:** §4.3. **Skills:** `impeccable` (lista + formulario + modal de confirmación).
> **R14:** el borrado exige confirmación tipada, sin `execute()` automático.
> **Gate R7:** Layer 1 · Layer 2 · Layer 3 (`edit-list`, `edit-update`, `edit-delete`). Firma `el-evaluador`.

### FASE 5 — Vista Estadísticas
> **Entregable:** métricas agregadas (§5) renderizadas en la vista aislada de solo lectura; estado vacío.
> **Dependencias:** F1, F3 (necesita datos). **Features:** `F5-01`, `F5-02`, `F5-03`.
> **Screen flow:** §4.4.
> **Gate R7:** Layer 1 · Layer 2 (incl. `stats-aggregations`) · Layer 3 (`statistics-view`). Firma `el-evaluador`.

### FASE 6 — Calidad y pulido
> **Entregable:** las 3 capas de verificación del sistema en verde; menú y formularios operables por teclado; WCAG 2.1 AA en lo verificable; deep-link a cada ruta funciona.
> **Dependencias:** F2–F5. **Features:** `F6-01`, `F6-02`, `F6-03`.
> **Gate R7:** `make typecheck && make lint && make test && make e2e` exit 0; `a11y` sin violaciones críticas; cobertura ≥ target. Firma `el-evaluador`.

### FASE 7 — Auditoría y salida a producción
> **Entregable:** `web-quality` + `el-guardian` sin Critical/High; deploy con smoke test; cierre casa (definición de terminado 5/5).
> **Dependencias:** F6. **Features:** `F7-01`, `F7-02`, `F7-03`.
> **Skills:** `web-quality`, `el-guardian` (Codex).
> **Gate:** `SECURITY-AUDIT-inventario-juegos.md` con Critical = 0 y High = 0; smoke e2e verde contra la URL de producción. Firma `el-evaluador`.

---

## 7. Cronograma total

```
Fase 1: 4–6 h    Fase 2: 4–5 h    Fase 3: 3–4 h    Fase 4: 4–5 h
Fase 5: 3–4 h    Fase 6: 2–3 h    Fase 7: 2–3 h
──────────────────────────────────────────────────────────────
Total: ~22–30 h  (≈ 4–6 sesiones de build)
```

---

## 8. Pre-mortem (riesgos que afectan el plan de ejecución)

| Tipo | Riesgo | Mitigación en el plan |
|---|---|---|
| 🐘 Elefante | El brief está vacío: campos de `game` y métricas son hipótesis | `F1-02` bloquea hasta que Carlos/cliente confirmen §3 y §5; nada de `/build` antes |
| 🐯 Tigre | "Vista aislada" se implementa con un store global compartido → bugs de navegación | `F2-03` incluye e2e de aislamiento; F6 exige deep-link directo a cada ruta |
| 🐯 Tigre | El menú termina mostrando datos ("total de juegos" en un botón) → viola el requisito duro | `F2-02`: test de estructura que prohíbe importar la capa de datos desde la vista de menú |
| 🐈 Paper tiger | Elección DB vs local-first traba el arranque | Es la primera tarea (`F1-01`), gate de la fase |
| 🐯 Tigre | Borrado sin confirmación → pérdida de datos | `F4-03` con confirmación tipada (R14) como criterio de aceptación |

---

## 9. Plan de deploy (Fase 7)

- **Hosting:** Vercel (o Coolify self-hosted) — ⚠️ según Tech Spec.
- **Entornos:** producción; preview por PR si Vercel.
- **Gate pre-deploy:** `el-guardian` (RLS en `game`, validación de entrada, R14 en borrado, sin secretos en
  logs) + `web-quality`. Critical/High = 0.
- **DNS + SSL:** ⚠️ a definir con el cliente.
- **Monitoring:** Sentry (o equivalente) con DSN configurado — ⚠️ opcional v1.
- **Smoke post-deploy:** e2e del happy path (menú → agregar → editar → estadísticas) contra la URL real.
- **Cierre casa:** `estado.md` del cliente lo actualiza Carlos (dueño); mensaje al cliente; `/casa:promover`
  de lo reutilizable (o decisión explícita de que no).

---

## 10. Próximos pasos post-Blueprint

```
✅ BLUEPRINT-inventario-juegos.md generado.

Antes de construir:
  1. Carlos/cliente resuelven los ⚠️ (§0, §3, §5) → ✅.
  2. Crear repo de producto:
     bin/nuevo-cliente.sh inventario-juegos "Inventario de Videojuegos" --producto
  3. Copiar este Blueprint a .claude/PRPs/ y feature_list.json a la raíz del repo de producto.
  4. /add-ui-kit  (preset Tech Utility)  → brand.json + voice.json + brand.css   [R10]
  5. make preflight exit 0   [R11 Bootstrap Contract]

Para construir:
  → /build → elegir:
     🔧 Build Manual (el-yunque)  — recomendado: es un tool chico, secuencial, con tu aprobación por fase
     🔨 Modo Forja (la-forja)     — paralelo; útil si se corren F3/F4/F5 en worktrees separados

Pre-build checklist:
  [ ] make preflight exit 0
  [ ] Branch matchea ^(feature|fix|refactor|chore|docs)/.+$   (R3 · regla C7 de la casa)
  [ ] feature_list.json: F1-01 en "active", resto "pending"   (R1 WIP=1)
  [ ] brand/brand.json + voice.json presentes   (R10)
```

---

## Sources

- Arné Forge — `la-herreria` SKILL.md, `assets/10-master-blueprint.md`, `routes/internal-tool.md`
  (repo `Casa-Ajolote/inventario-juegos` template / copia en `clientes/lavifire/`).
- `CONSTRAINTS.md` R1, R2, R3, R7, R10, R14, AP8 (mismo template Forge).
- Casa Ajolote — `AGENTS.md` (C7, C8, C9), `operacion/reglas-de-la-casa.md`,
  `operacion/definicion-de-terminado.md`.
- Requisito de arquitectura de navegación: pedido explícito del usuario, 2026-09-09.

*Generado por el arné Forge · `la-herreria` · ruta Herramienta Interna. Sin código de implementación.*
