# Asset #1 — Business Model Canvas

> *"Antes de diseñar pantallas o escribir código, hay que entender cómo el negocio
> crea, entrega y captura valor. Sin esto, todo lo demás es decoración."*

## Qué Hace

Genera dos documentos estratégicos fundamentales y valida que sean coherentes entre sí:

1. **Business Model Canvas (BMC)** — visión sistema completo del negocio en una página. 9 bloques: segmentos, propuesta de valor, canales, relaciones, ingresos, recursos, actividades, alianzas y costos.
2. **Value Proposition Canvas (VPC)** — zoom profundo en la relación entre lo que el cliente necesita y lo que el producto ofrece. Un VPC por cada segmento de cliente.
3. **Validación de Alineación** — 5 checks de consistencia entre BMC y VPC.

**Por qué va primero:** el BMC y el VPC informan todo lo que viene después. PDR, Tech Spec, User Stories, Wireframes y Blueprint son más precisos y coherentes cuando el modelo de negocio está claro desde el inicio.

---

## Referencias (deferred F-tighten)

- `.claude/skills/la-herreria/references/business-model-canvas.md` — bloques del BMC
- `.claude/skills/la-herreria/references/value-proposition-canvas.md` — VPC
- `.claude/skills/la-herreria/references/canvas-alignment.md` — alineación

---

## Workflow

### Fase 1: Entrevista Estratégica

Conversacional, no formulario. Máximo 3-4 preguntas por turno.

**Problema y cliente:**
1. ¿Qué problema específico resuelve tu producto? ¿Cómo lo resuelven hoy sin él?
2. ¿Quién tiene este problema? Describí a tu cliente ideal con contexto real.
3. ¿Hay diferentes tipos de clientes que lo necesitan por razones distintas?

**Solución y valor:**
4. ¿Qué hace tu producto concretamente? ¿Cuál es la acción principal?
5. ¿Por qué elegirían tu producto sobre las alternativas? ¿Qué lo diferencia?
6. ¿Qué frustraciones elimina? ¿Qué logros permite que antes no eran posibles?

**Modelo de negocio:**
7. ¿Cómo pensás cobrar? (suscripción, freemium, por uso, licencia, etc.)
8. ¿Cómo van a descubrir tu producto los clientes?
9. ¿Qué necesitás para operar? (equipo, tecnología, proveedores, capital.)

**Reglas:**
- Si las respuestas son vagas ("todo el mundo lo necesita"), profundizar.
- Si el usuario no sabe algo, documentarlo como **supuesto a validar**.
- No repetir lo que el usuario ya dijo.

### Fase 2: Generar el Business Model Canvas

**Orden de llenado:**
1. Customer Segments → 2. Value Propositions → 3. Channels → 4. Customer Relationships
→ 5. Revenue Streams → 6. Key Resources → 7. Key Activities → 8. Key Partnerships → 9. Cost Structure

**Output:** `BMC-[nombre-kebab].md` con los 9 bloques + Risk Points.

### Fase 3: Generar el Value Proposition Canvas

Para CADA segmento de cliente identificado, generar un VPC completo.

**Orden:**
1. Primero el **Customer Profile** (jobs → pains → gains).
2. Después el **Value Proposition** (pain relievers → gain creators).
3. Finalmente: **No Abordado** — cada dolor/ganancia sin cobertura con disposición explícita.

**Regla crítica:** NO poblar Value Proposition hasta que Customer Profile esté completo.

**Output:** `VPC-[nombre-kebab].md` con un VPC por segmento.

### Fase 4: Validar Alineación

Ejecutar 5 checks de consistencia:

| # | Check | Detecta |
|---|-------|---------|
| 1 | Cada Segmento del BMC tiene un VPC | Segmentos sin propuesta de valor definida |
| 2 | Cada Revenue Stream tiene un Value Proposition | Ingresos prometidos sin valor que los respalde |
| 3 | Cada Customer Job del VPC pertenece a un segmento del BMC | VPC apuntando a segmentos que el negocio no sirve |
| 4 | Pain Relievers y Gain Creators cubren la propuesta central | Promesas exageradas o subestimadas |
| 5 | Pains y Gains no abordados tienen disposición explícita | Problemas del cliente ignorados silenciosamente |

Si check falla → resolver conflicto antes de continuar.

### Fase 5: Presentar al Usuario

1. **BMC completo** — resumen de los 9 bloques.
2. **VPC por segmento** — Customer Profile + Value Proposition.
3. **Resultado de alineación** — los 5 checks (✅ o ❌).
4. **Risk Points** — riesgos identificados.
5. **Supuestos a validar** — lo que el usuario no supo responder.

Preguntar: "¿Esto refleja bien tu idea? ¿Hay algo que corregir o profundizar?"

---

## Output Contract

```
BMC:
  Customer Segments     → quién servimos (2-4 segmentos max)
  Value Propositions    → qué valor entregamos a cada segmento
  Revenue Streams       → cómo capturamos valor económico
  Channels              → cómo llegamos al cliente (adquisición + marketing)
  Cost Structure        → qué cuesta operar el modelo

VPC (por segmento):
  Customer Jobs         → qué intenta lograr el cliente
  Pains                 → qué le frustra del proceso actual (con magnitud)
  Gains                 → qué significa éxito
  Pain Relievers        → cómo el producto alivia cada dolor
  Gain Creators         → cómo el producto crea cada ganancia
  Unaddressed           → qué no se atiende y por qué
```

**Consumido por todos los assets downstream:**
- **PDR (#2):** segmentos y propuesta de valor como base.
- **Tech Spec (#3):** stack alineado con recursos clave del BMC.
- **User Stories (#5):** Customer Jobs → epics.
- **UX Research (#4):** personas derivadas de segmentos del VPC.
- **UI Design (#7-#8):** tono visual refleja propuesta de valor (R10 Brand DNA via voice.json).
- **Blueprint (#10):** fases respetan revenue streams y cost structure.

---

## Naming Convention

| Documento | Archivo |
|-----------|---------|
| Business Model Canvas | `BMC-[nombre-kebab].md` |
| Value Proposition Canvas | `VPC-[nombre-kebab].md` |
| Reporte de Alineación | Incluido al final de `BMC-[nombre-kebab].md` |

`[nombre-kebab]` se propaga a todos los documentos del pipeline + se usa como prefijo en `feature_list.json` features.

---

## Errores Comunes a Evitar

- **Segmentos demasiado amplios.** "Empresas" no es segmento. "Agencias de marketing de 5-20 personas que gastan >$10K/mes en herramientas" sí.
- **Value Propositions genéricas.** "Ahorra tiempo" no vale. "Elimina 30 minutos de entrada manual por factura cada semana" sí.
- **Customer Jobs como features.** "Usar el dashboard" es feature, no job. "Saber cuánto dinero me deben mis clientes" es job.
- **Pains sin magnitud.** "Es lento" no es medible. "Toma 45 minutos cada viernes" sí.
- **Llenar el Value Proposition antes del Customer Profile.** Siempre el cliente primero.

---

## Handoff al Asset #2

```
✅ BMC-[nombre].md generado
✅ VPC-[nombre].md generado
✅ Alineación validada (5/5 checks)

Siguiente: PDR Generator (asset 02-pdr-generator.md)
Con el modelo de negocio claro, la entrevista de producto será más
enfocada y el PDR más preciso.

¿Procedemos?
```

---

## Paso final — Generar HTML

Después de guardar `BMC-{nombre}.md` (y `VPC-{nombre}.md` si aplica), invocar para cada uno:

→ `.claude/skills/la-herreria/prompts/render-doc-html.md`
  con `doc_type: BMC` (o `VPC`), `project_name: {nombre}`

Output adicional: `BMC-{nombre}.html` y `VPC-{nombre}.html` (standalone, dark mode, navegable).

Reportar al usuario: "✅ BMC-{nombre}.md + BMC-{nombre}.html generados".
