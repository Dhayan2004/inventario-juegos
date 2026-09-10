<!-- Adaptado de SpecFounder v2 (STATE-SCHEMA.md) — MIT © Ing. Oscar Lobo.
     Portado a Forge Enterprise como asset del skill `el-entrevistador` (Fase 0 de descubrimiento, previa a /plan). -->

# state-schema — Memoria persistente de `el-entrevistador`

> Este documento define **cómo la sesión de descubrimiento sobrevive a caídas**. Es el cimiento que aplican el orquestador `el-entrevistador` (SKILL.md) y los sombreros de cada fase. Léelo antes que cualquier otro asset del skill.

---

## Por qué existe

Si toda la entrevista vive solo en el contexto de la conversación, cualquier caída la borra: cerrar el aplicativo, perder la red o truncar el contexto significa **perder todo el progreso**. `el-entrevistador` persiste el estado en disco tras cada respuesta, de modo que cualquier sesión puede retomarse exactamente donde quedó, sin re-preguntar lo ya respondido.

---

## El directorio `.specfounder/`

Se crea en la **raíz del proyecto objetivo** (no en el repo de Forge). Es la única fuente de verdad del progreso de una sesión.

```
.specfounder/
├── session.md            # Ledger de estado (cursor + metadatos). EL archivo crítico.
├── SPEC.draft.md         # SPEC vivo (6 secciones del dominio software), se actualiza en tiempo real
├── CONTEXT.draft.md      # Glosario vivo, se actualiza en tiempo real
└── adr/
    ├── 0001-slug.md      # ADRs borrador (solo si aplican los 3 criterios)
    └── ...
```

**Separación de responsabilidades:** el **contenido** vive en los `*.draft.md` y en `adr/`. El **cursor** (en qué pregunta vamos, qué falta, qué sigue) vive en `session.md`. Así el ledger se mantiene pequeño y barato de reescribir tras cada turno.

> **Versionado:** durante la sesión, añade `.specfounder/` a `.gitignore` — los drafts cambian en cada turno y no deben ensuciar el historial. Cuando el adaptador **forge** emite los artefactos finales (`SPEC.md`, `CONTEXT.md`, `docs/adr/` — ver `references/emit-forge.md`), esos sí se versionan: son el handoff hacia `/plan` (skill `la-herreria`).

---

## Esquema de `session.md`

Markdown con **frontmatter YAML** (parte machine-readable) + **cuerpo estructurado** (parte human-readable). Se eligió markdown sobre JSON por portabilidad, fiabilidad de los LLM al leer/escribir, y porque un humano puede abrirlo y entender el progreso de un vistazo.

```markdown
---
version: "1.0.0"
session_id: "2026-06-30-mi-proyecto"
created_at: "2026-06-30T10:00:00Z"
updated_at: "2026-06-30T10:42:00Z"
domain: "software"             # software (único dominio por ahora; punto de extensión futuro)
methodology: "forge"           # siempre "forge" — el SPEC neutral se emite vía adaptador forge
project_mode: "nuevo"          # nuevo | existente | re-spec-parcial | glosario-urgente
project_name: "Mi Proyecto"
project_root: "/ruta/al/proyecto"
phase: "entrevista"            # exploracion | vision | entrevista | cierre | emitido
vision_mode: "generada"        # generada | aportada | "" (vacío si aún no se definió)
current_section: 2             # 1..6  (0 = aún sin empezar la entrevista)
current_question_id: "S2.Q3"   # id estable de la pregunta en curso
sections:                       # claves fijas s1..s6 (espina universal); etiqueta = perfil software
  s1_vision:        "completa"   # 1 · Visión del Producto · pendiente | en_curso | completa
  s2_actores:       "en_curso"   # 2 · Usuarios y Casos de Uso
  s3_elementos:     "pendiente"  # 3 · Funcionalidades por Módulo
  s4_estructura:    "pendiente"  # 4 · Flujos de Usuario
  s5_forma:         "pendiente"  # 5 · Arquitectura
  s6_restricciones: "pendiente"  # 6 · Requisitos No Funcionales
glossary_terms: 7              # nº de términos del glosario (detalle en CONTEXT.draft.md)
adr_count: 1
---

# Sesión: Mi Proyecto

## Siguiente acción (lo PRIMERO que se lee al retomar)
> Formular S2.Q3: "¿Existe un usuario anónimo no autenticado con acciones propias?
> Mi recomendación: sí, al menos lectura pública del catálogo."

## Ramas abiertas (deben cerrarse antes de avanzar de sección)
- [ ] S2: confirmar si "Operador" y "Supervisor" son roles distintos o el mismo con permisos.

## Log de decisiones (recomendaciones aceptadas / rechazadas)
- S1.Q1 ✅ Producto definido en una oración (ver SPEC.draft.md §1).
- S1.Q2 ✅ Usuario principal: empresa (B2B). Recomendación aceptada.
- S2.Q1 ✅ 3 tipos de usuario: Administrador, Operador, Cliente.
- S2.Q2 ⏳ En curso.

## Contradicciones resueltas
- "cuenta" se usó para Usuario y para Organización → canonizado como **Organización** (ver CONTEXT.draft.md).

## Notas de retomada
- (libre) cualquier contexto que el sombrero quiera dejarse a sí mismo para no perder hilo.
```

### Campos obligatorios del frontmatter
`domain`, `methodology`, `project_mode`, `phase`, `current_section`, `current_question_id`, `sections.*`, `updated_at`. Sin estos, el RESUME no es fiable.

### IDs de pregunta estables
Formato `S{sección}.Q{n}` (p. ej. `S4.Q2`). Cada sombrero usa estos IDs para que el cursor sea inequívoco. Las preguntas adaptativas (no del guion base) se numeran `S{sección}.Qa{n}` (`a` = ad-hoc).

---

## Protocolo de CHECKPOINT (regla inviolable del núcleo)

Tras **cada** respuesta del usuario, y **antes** de formular la siguiente pregunta, en este orden:

1. **Actualizar drafts** (incremental): editar la parte afectada de `SPEC.draft.md` y/o `CONTEXT.draft.md` y/o `adr/`.
2. **Actualizar `session.md`** (incremental — ver más abajo): `updated_at`, el estado de la sección, *append* de una línea al log de decisiones, las ramas abiertas y —lo más importante— el bloque **"Siguiente acción"** con la pregunta exacta que toca.
3. **Recién entonces** formular la siguiente pregunta al usuario.

> Si un sombrero formula una pregunta sin haber persistido el turno anterior, está violando el protocolo. El checkpoint es atómico respecto a la pregunta: **primero se persiste, luego se pregunta.**

### Escritura eficiente (rendimiento)
El checkpoint se ejecuta ~1 vez por turno durante decenas de turnos, así que es el mayor sumidero de tokens de salida del sistema. Reglas:
- **Edición incremental, no reescritura total.** Modifica solo los campos del frontmatter que cambiaron, *append* de **una línea** al log de decisiones, y reemplaza el bloque "Siguiente acción". No regeneres el archivo entero.
- **Ledger magro.** El log es un resumen (una línea por decisión), no una transcripción. Tope sugerido: **últimas ~12 entradas + todas las decisiones irreversibles (ADR)**; el detalle completo vive en los drafts.

---

## Protocolo de RESUME (al activarse `el-entrevistador`)

1. **Detectar**: ¿existe `.specfounder/session.md` en la raíz del proyecto?
   - **No existe** → sesión nueva. Empezar por la fase inicial del orquestador (`exploracion` si el proyecto es existente, `vision` si es nuevo).
   - **Sí existe** → continuar abajo.
2. **Cargar estado**: leer `session.md`, `SPEC.draft.md`, `CONTEXT.draft.md`, `adr/`.
3. **Mostrar resumen de retomada** al usuario (sin re-preguntar nada):
   - Modo de la sesión y fase actual.
   - Secciones completas vs pendientes.
   - Nº de términos del glosario y ADRs.
   - La última decisión registrada.
   - Las ramas abiertas que faltan cerrar.
4. **Confirmar y retomar**: "Retomo en **{Siguiente acción}**. ¿Continuamos?" — y al confirmar, formular esa pregunta exacta. No se repite ninguna pregunta ya marcada en el log de decisiones.

### Resumen de retomada — formato visible al usuario
```
🔄 Sesión recuperada — "Mi Proyecto" (Forge · proyecto nuevo)

Progreso:
  ✅ Sección 1 · Visión del Producto
  ⏳ Sección 2 · Usuarios y Casos de Uso (en curso)
  ⬜ Secciones 3–6 pendientes
Glosario: 7 términos · ADRs: 1

Última decisión: 3 tipos de usuario (Administrador, Operador, Cliente).
Rama abierta: confirmar si "Operador" y "Supervisor" son el mismo rol.

▶️ Retomo aquí: S2.Q3 — ¿Existe un usuario anónimo con acciones propias?
   ¿Continuamos?
```

---

## Estados de fase (`phase`)

| Fase | Significado |
|------|-------------|
| `exploracion` | (Solo proyecto existente) el sombrero Explorador está leyendo el código antes de la entrevista. |
| `vision` | (Solo proyecto nuevo, o re-spec con Visión rota) el sombrero de Visión construye o valida la Visión del Producto (Sección 1) antes de la entrevista. `vision_mode` registra si fue `generada` o `aportada`. |
| `entrevista` | Recorriendo las 6 secciones del SPEC software, una pregunta a la vez. |
| `cierre` | Todas las secciones completas; mostrando SPEC/CONTEXT/ADRs para revisión. |
| `emitido` | El adaptador **forge** (`references/emit-forge.md`) ya generó los artefactos finales y el handoff a `/plan` (`la-herreria`). |

---

## Punto de extensión — reusado por el dominio `ontologia` (M3)

`el-entrevistador` cubre el dominio `software` con sus 6 secciones fijas. El frontmatter incluye `domain` y mantiene las claves `s1..s6` precisamente para que otros perfiles reasignen la etiqueta de cada ranura sin romper el cursor. **El skill `el-ontologo` (M3) ya ejerce este punto de extensión:** reusa este protocolo de memoria **sin modificarlo**, con `domain: "ontologia"`, dir de trabajo `.ontologia/` (en vez de `.specfounder/`) y draft `ONTOLOGY.draft.md` (en vez de `SPEC.draft.md` + `CONTEXT.draft.md`). El CHECKPOINT, el RESUME, los IDs `S{n}.Q{m}` y la regla de oro son idénticos. **Este archivo sigue siendo el protocolo canónico de memoria para ambos perfiles** — no se duplica en `el-ontologo`.

---

## Regla de oro

> **El `session.md` siempre debe poder responder, por sí solo, la pregunta: "si todo se cae ahora mismo, ¿qué pregunta exacta toca hacer al volver?"** Si no puede, el checkpoint está incompleto.
