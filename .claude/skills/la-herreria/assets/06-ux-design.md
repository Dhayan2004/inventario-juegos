# Asset #6 — UX Design

> *"La estructura invisible que hace que todo se sienta natural."*

## Qué Hace

Toma personas y modelos mentales (UX Research, asset 04) y User Stories (asset 05) para definir la arquitectura de la experiencia **antes de diseñar una sola pantalla**: cómo se organiza el producto, cómo se comportan los controles, si el flujo es usable, y cómo el primer usuario llega a su primer éxito.

---

## Inputs Requeridos

- `docs/ux-research/personas/` — del asset 04.
- `docs/ux-research/mental-models/` — del asset 04.
- `USER-STORIES-[nombre].md` — del asset 05.

---

## Referencias (deferred F-tighten)

- `.claude/skills/la-herreria/references/information-architecture.md`
- `.claude/skills/la-herreria/references/interaction-patterns.md`
- `.claude/skills/la-herreria/references/usability-evaluation.md`
- `.claude/skills/la-herreria/references/onboarding.md`

---

## Workflow

### Paso 1: Definir Information Architecture

La IA organiza el producto. Una IA incorrecta significa que los usuarios no pueden encontrar lo que necesitan. Una IA correcta se siente obvia.

**Fuentes para derivar la IA (no inventar):**

1. **Modelos mentales** (`docs/ux-research/mental-models/`) — términos y categorías que el usuario ya usa. Si piensa en "facturas", la nav dice "Facturas", no "Documentos" o "Transacciones".
2. **Epics de User Stories** — cada epic es un área principal del producto.

**Seleccionar UN patrón de navegación:**
- **Top Nav:** 3–6 secciones top-level, productos desktop-primary.
- **Sidebar:** 5+ secciones con subsecciones, apps de sesiones largas. En móvil: drawer tras hamburger.
- **Bottom Nav:** Mobile-first, 3–5 secciones primarias.

**Máxima profundidad: 3 niveles.** Si hay más, aplanar o dividir.

**Output:** `docs/ux-design/information-architecture.md`.

---

### Paso 2: Definir Interaction Patterns

Reglas que gobiernan cómo se comportan los controles en todo el producto. Consistencia significa que el usuario aprende una vez y aplica en todas las pantallas.

**5 patrones a definir:**

**1. Feedback Loops**
- Acción instantánea (click) → feedback < 200ms.
- Submit form → estado loading inmediato, luego success/error.
- Auto-save → indicador "Guardado" a los 2s, se desvanece.
- Proceso largo (>10s) → progress bar con tiempo estimado.

**2. Form Behavior**
- Validar on blur (al salir del campo), no on change.
- Errores inline debajo del campo, mensaje específico + corrección sugerida.
- Al submit: focus en primer campo con error.
- Success: form desaparece o transiciona a vista de detalle.
- **R14 strict:** acciones destructivas dentro de forms (delete account, cancel subscription) requieren typed confirmation, no botón directo.

**3. Progressive Disclosure**
- Vista default: solo controles para la acción más común.
- "Más opciones": campos adicionales expandibles inline.
- "Avanzado": configuración de power users detrás de toggle explícito.

**4. Error Recovery**
- Validación: inline, mantener datos, focus en primer error.
- Not found: mensaje claro + qué hacer a continuación.
- Permission denied: mensaje + qué permiso se necesita.
- Server error: mensaje legible + botón retry + preservar datos.
- Network error: indicador de conectividad + queue de acciones si es posible.
- **L-002 awareness:** si el error proviene de inputs externos (API, webhook), tratarlos como datos no confiables.

**5. State Transitions**
- Estado actual siempre visible como badge/indicador.
- Acciones disponibles etiquetadas con el estado resultante ("Enviar Factura", no solo "Siguiente").
- Transición: loading brief → badge actualizado → mensaje de confirmación.

**Output:** `docs/ux-design/interaction-patterns.md`.

---

### Paso 3: Evaluar Usabilidad

Antes de diseñar una sola pantalla, evaluar la experiencia planeada contra los 10 heurísticos de Nielsen.

**Los 10 Heurísticos:**
- H1: Visibilidad del estado del sistema
- H2: Match entre sistema y mundo real
- H3: Control y libertad del usuario
- H4: Consistencia y estándares
- H5: Prevención de errores
- H6: Reconocimiento sobre memoria
- H7: Flexibilidad y eficiencia de uso
- H8: Diseño estético y minimalista
- H9: Ayuda a reconocer, diagnosticar y recuperarse de errores
- H10: Ayuda y documentación

**Escala de severidad:**

| Score | Severidad | Acción requerida |
|-------|-----------|-----------------|
| 4 | Catastrófico | Bloquea el pipeline — rediseñar el flujo |
| 3 | Mayor | Resolver antes de implementar |
| 2 | Menor | Resolver antes de lanzar |
| 1 | Cosmético | Resolver si hay tiempo |

**Regla de bloqueo:** cualquier violación Severidad 4 debe resolverse ANTES de continuar al asset 07.

**Output:** `docs/ux-design/usability-evaluation/[feature-kebab].md` por feature principal.

---

### Paso 4: Diseñar Onboarding Strategy

Los primeros 60 segundos determinan si el usuario se queda o se va. El objetivo no es enseñar el producto completo — es llevar al usuario a su **PRIMER ÉXITO** lo más rápido posible.

**Pregunta central:**
> ¿Cuál es la cosa más valiosa que este usuario puede lograr en la primera sesión, y cómo llegamos ahí con cero fricción?

**Patterns a seleccionar (combinables):**

- **Empty State Design** — cada lista/tabla/dashboard vacío tiene empty state diseñado: ícono de dominio + headline + body (1 frase) + CTA primario que lleva al first success.
- **Guided First Action** — primer formulario tiene defaults sensibles, campos mínimos, helper text por campo, success state claro.
- **Contextual Tooltips** — capacidades nuevas se revelan en momento relevante. Un tooltip a la vez, siempre dismissible.
- **Progress Indication** — solo para productos con setup multi-paso (3+ pasos antes del first success).

**Definir empty states para TODAS las vistas de listado.**

**Output:** `docs/ux-design/onboarding.md`.

---

### Paso 5: Verificar Completitud

```
✅ Information Architecture documentada con patrón de navegación elegido
✅ Profundidad máxima 3 niveles respetada
✅ Labels de navegación en vocabulario de los modelos mentales
✅ Interaction patterns definidos para las 5 categorías
✅ Usabilidad evaluada → cero violaciones Severidad 4 sin resolver
✅ First success definido
✅ Empty states definidos para todas las vistas de listado
✅ Onboarding strategy documentada
✅ Todos los docs en docs/ux-design/
```

---

## Output

```
docs/ux-design/
├── information-architecture.md
├── interaction-patterns.md
├── onboarding.md
└── usability-evaluation/
    └── [feature-kebab].md
```

---

## Naming Convention

| Documento | Archivo |
|-----------|---------|
| Information Architecture | `docs/ux-design/information-architecture.md` |
| Interaction Patterns | `docs/ux-design/interaction-patterns.md` |
| Onboarding Strategy | `docs/ux-design/onboarding.md` |
| Usability Evaluation | `docs/ux-design/usability-evaluation/[feature-kebab].md` |

---

## Reglas Críticas

- **La IA se deriva de los modelos mentales — no se inventa.**
- **Un solo patrón de navegación, elegido una vez.** No mezclar top nav con sidebar.
- **Interaction patterns son producto-wide.** Mismo comportamiento en todos los formularios.
- **Severidad 4 bloquea el pipeline.**
- **First success se define ANTES de los empty states.**
- **R14 strict en interaction patterns destructivas** — typed confirmation, no `execute()` automático.
- **Documentar incluso si no se encuentran violaciones.**

---

## Handoff al Asset #7

```
✅ Information Architecture → docs/ux-design/information-architecture.md
✅ Interaction Patterns → docs/ux-design/interaction-patterns.md
✅ Usability Evaluation → docs/ux-design/usability-evaluation/ (sin Severidad 4)
✅ Onboarding Strategy → docs/ux-design/onboarding.md

Siguiente: UI Design Workflow (asset 07-ui-design-workflow.md)
Tomará IA y interaction patterns para diseñar screen flows respetando
la estructura ya definida.

¿Procedemos?
```
