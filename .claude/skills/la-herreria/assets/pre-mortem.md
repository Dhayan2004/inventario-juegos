# Asset Especializado — Pre-Mortem (Análisis de Riesgos de Proyecto)

> *"No esperes a que el proyecto falle para preguntarte por qué falló."*

## Qué Hace

Ejecuta un **pre-mortem** antes de que el proyecto empiece la construcción. En vez de preguntar "¿qué podría salir mal?", asume que el proyecto YA FALLÓ y pregunta "¿por qué falló?". Desbloquea sesgos cognitivos que el optimismo natural oculta.

Clasifica riesgos usando el modelo **Tigers / Paper Tigers / Elephants**:

| Tipo | Qué es | Acción |
|------|--------|--------|
| **Tigers** | Riesgos reales y probables | Mitigar activamente |
| **Paper Tigers** | Riesgos percibidos pero manejables | Documentar plan, no obsesionarse |
| **Elephants** | Riesgos ignorados que nadie menciona | Forzar conversación |

**Cuándo usar:**
- Antes del Master Blueprint (asset 10) — complementa la Security Audit (asset 09B).
- En el route SaaS Completo, Step 9A (pre-Mortem antes de Security Audit).
- Antes de un sprint grande.
- Cuando el equipo tiene "demasiada confianza" en el plan.
- Como parte de `/brujula` o `/crisol` (`el-crisol` lo invoca opcionalmente como sub-análisis).

---

## Inputs

- `PDR-[nombre].md` — scope, features, timeline (asset 02).
- `TECH-SPEC-[nombre].md` — stack, integraciones, arquitectura (asset 03).
- `BMC-[nombre].md` o `LEAN-CANVAS-[nombre].md` — modelo de negocio, hipótesis (asset 01 / lean-canvas).
- `VIABILITY-[nombre].md` — riesgos ya identificados (asset 00).
- Contexto conversacional del usuario.

---

## Workflow

### Fase 1: El Escenario de Fracaso (~5 min)

Presentar al usuario:

```
Imaginá que estamos 6 meses en el futuro.
Tu proyecto [nombre] fracasó completamente.
Los usuarios no lo usan, el dinero se acabó, el equipo está frustrado.

Vamos a descubrir POR QUÉ fracasó — antes de que pase.
```

Preguntas provocadoras:
1. "Si tu proyecto fracasara, ¿cuál sería la razón #1?"
2. "¿Qué es lo que más te preocupa y no has dicho en voz alta?"
3. "¿Qué supuesto de tu plan es el más débil?"
4. "Si un competidor te copiara mañana, ¿qué te quitaría?"

### Fase 2: Identificación de Riesgos (~10 min)

Buscar riesgos en 6 categorías:

**1. Riesgos de Producto:**
- ¿El problema es real o asumido?
- ¿El MVP resuelve el problema o solo una parte?
- ¿Hay product-market fit o es un "nice to have"?

**2. Riesgos Técnicos:**
- ¿Hay integraciones con APIs inestables o nuevas?
- ¿El Forja Golden Path soporta lo que se quiere construir?
- ¿Hay dependencias de terceros críticas? (citation R13 si aplica)
- ¿La BaaS decision (D-009) es la correcta o se eligió por familiaridad?

**3. Riesgos de Mercado:**
- ¿El timing es correcto?
- ¿Hay competidores que no se consideraron?
- ¿El canal de adquisición está validado?

**4. Riesgos de Ejecución:**
- ¿El scope es realista para el timeline?
- ¿Hay conocimiento técnico faltante?
- ¿Quién mantiene el producto post-launch?

**5. Riesgos Financieros:**
- ¿Los costos están bien estimados? (incluir costos de IA si aplica — `.claude/skills/la-herreria/references/llm-cost-optimization.md` deferred F-tighten)
- ¿Hay runway suficiente para pivotar si falla?
- ¿El pricing es validado o asumido?

**6. Riesgos de Equipo/Humanos:**
- ¿Hay un solo punto de falla (una persona)?
- ¿El fundador tiene sesgo de confirmación sobre la idea?
- ¿Hay alignment entre stakeholders?

### Fase 3: Clasificar (Tigers / Paper Tigers / Elephants) (~5 min)

Para cada riesgo identificado:

```
| ID | Riesgo | Tipo | Probabilidad | Impacto | Score |
|----|--------|------|-------------|---------|-------|
| R-01 | [riesgo] | Tiger | Alta | Alto | 🔴 |
| R-02 | [riesgo] | Paper Tiger | Media | Bajo | 🟡 |
| R-03 | [riesgo] | Elephant | ? | Alto | 🔴 |
```

**Scoring:**
- **Probabilidad × Impacto** = Score del riesgo.
- 🔴 Alto × Alto = bloquear si no se mitiga.
- 🟡 Medio × Medio = plan de contingencia.
- 🟢 Bajo × Bajo = aceptar y monitorear.

### Fase 4: Plan de Mitigación (~5 min)

Para cada Tiger y Elephant:

```
R-01: [Título del riesgo]
├── Tipo: Tiger
├── Si ocurre: [impacto concreto]
├── Señales tempranas: [cómo detectar antes de que sea crítico]
├── Mitigación: [acción específica, no genérica]
├── Plan B: [qué hacer si la mitigación falla]
└── Responsable: [quién monitorea]
```

Para cada Paper Tiger:
```
R-02: [Título del riesgo]
├── Tipo: Paper Tiger
├── Por qué no es tan grave: [justificación]
└── Acción: [monitorear / aceptar / ninguna]
```

---

## Output Format

```markdown
# PRE-MORTEM-[nombre]

> Pre-mortem generado por Forja · [fecha]

## Escenario de Fracaso

> "Es [fecha + 6 meses]. [Nombre del proyecto] fracasó porque..."

[Narrativa breve del peor escenario realista — 3–5 oraciones]

---

## Inventario de Riesgos

### Tigers (Riesgos Reales — Mitigar Activamente)

| ID | Riesgo | Categoría | Probabilidad | Impacto |
|----|--------|-----------|-------------|---------|
| R-01 | [riesgo] | Producto | Alta | Alto |

**R-01: [Título]**
- **Si ocurre:** [impacto]
- **Señales tempranas:** [indicadores]
- **Mitigación:** [acción]
- **Plan B:** [contingencia]

### Paper Tigers (Riesgos Percibidos — No Obsesionarse)

| ID | Riesgo | Por Qué No Es Tan Grave |
|----|--------|------------------------|
| R-03 | [riesgo] | [justificación] |

### Elephants (Riesgos Ignorados — Forzar Conversación)

| ID | Riesgo | Por Qué Se Ignora | Impacto Real |
|----|--------|-------------------|-------------|
| R-05 | [riesgo] | [razón] | [impacto] |

---

## Resumen de Riesgos

| Categoría | Tigers | Paper Tigers | Elephants | Total |
|-----------|--------|-------------|-----------|-------|
| Producto | [N] | [N] | [N] | [N] |
| Técnico | [N] | [N] | [N] | [N] |
| Mercado | [N] | [N] | [N] | [N] |
| Ejecución | [N] | [N] | [N] | [N] |
| Financiero | [N] | [N] | [N] | [N] |
| Equipo | [N] | [N] | [N] | [N] |
| **Total** | **[N]** | **[N]** | **[N]** | **[N]** |

## Nivel de Riesgo Global

[🔴 Alto | 🟡 Medio | 🟢 Bajo]

[Justificación 1–2 oraciones]

---

## Plan de Acción

### Antes de Construir (Bloqueantes)
1. [Acción para Tiger más crítico]
2. [Acción para Elephant más grave]

### Durante la Construcción (Monitorear)
1. [Señal temprana a vigilar]
2. [Checkpoint de validación]

### Post-Launch (Contingencia)
1. [Plan B si [riesgo] se materializa]
```

---

## Naming Convention

| Documento | Archivo |
|-----------|---------|
| Pre-Mortem | `PRE-MORTEM-[nombre-kebab].md` |

---

## Integración con la-herreria

- **Complementa la Security Audit (asset 09B)** — Security Audit cubre riesgos técnicos/código; Pre-Mortem cubre riesgos de producto/mercado/equipo.
- **Step 9A en route SaaS Completo** — antes de Security Audit.
- Tigers identificados se incorporan al Master Blueprint (asset 10) como "riesgos a monitorear".
- Elephants generan conversaciones que pueden cambiar el scope del Blueprint.
- También disponible via `/crisol` (sub-análisis estratégico) y `/brujula`.

---

## Reglas

1. **Sé provocador, no complaciente.** El pre-mortem funciona porque fuerza honestidad brutal.
2. **Buscá los Elephants activamente.** Son los más peligrosos porque nadie los menciona.
3. **Mitigaciones específicas.** "Validar con usuarios" no es mitigación. "Entrevistar 5 early adopters esta semana y medir [métrica]" sí.
4. **No todo es un Tiger.** Sobre-clasificar genera parálisis. Distinguir Paper Tigers.
5. **El pre-mortem no es permiso para no actuar.** Es herramienta para actuar con los ojos abiertos.
