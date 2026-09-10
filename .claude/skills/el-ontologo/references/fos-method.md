# Método de negocio — destilado de Founder OS (lente NEGOCIO)

> El **guion de negocio** del perfil `ontologia` se deriva de **Founder OS** (el Sistema de Validación
> Paga™ de Novolabs, empaquetado como OS). Este archivo **destila el método** — las etapas, la
> jerarquía de evidencia y los gates — para que el sombrero `business-interviewer` lo aplique **sin
> leer el repo original**. Founder OS es solo-lectura (`~/Developer/software/templates/founder-os`);
> aquí viaja el *método*, no el código.
>
> **Fuente:** `docs/03` (investigación Founder OS).

---

## El momento ontológico (de dónde sale el guion)

El `/onboarding` de Founder OS es **la entrevista que destila el "ser" del negocio**: 11 preguntas en
5 bloques, conversacional (nunca formulario), que produce `startup-context.md` — el análogo funcional
exacto de `ONTOLOGY.md`. Las ranuras s1–s4 del perfil `ontologia` condensan esos 5 bloques:

| Bloque FOS | Ranura `ontologia` |
|------------|--------------------|
| A — Identidad (nombre, problema en 1 oración) | s1 Propósito |
| B — Mercado (quién sufre, por qué ese segmento) | s2 Segmento |
| C — Segmento específico (rúbrica de 5 criterios) | s2 Segmento |
| C bis — Dolor en palabras del cliente | s3 Problema |
| D — Solución (hipótesis + evidencia) | s3 Propuesta de valor |
| E — Estado (etapa honesta) | (contexto, no enforce-able) |

### Rúbrica de segmento específico (aplícala en S2.Q1)
El cliente debe precisarse por ≥3 de estos 5 criterios: **industria, rol, geografía, tamaño/etapa,
comportamiento específico**. Ejemplo del estándar FOS: no *"emprendedores"* sino *"fundadores de SaaS
B2B en Latam de 25–35 que buscan sus primeros 10 clientes"*. 0–2 criterios = vago → ayuda a precisar
antes de registrar.

### Dolor en palabras del cliente (aplícala en S3.Q1)
Exige el **lenguaje del cliente**, no del fundador. Detecta jerga (*"ineficiencias operativas"*) y
reformúlala a habla real (*"no sé cuánto voy a vender el mes que viene y eso me da ansiedad"*). La cita
textual ES la evidencia.

---

## Las 7 etapas (de dónde sale qué clave)

El levantamiento ontológico **no recorre las 7 etapas completas** (eso es validación de negocio a
fondo, dominio de Founder OS como herramienta aparte). Toma de cada etapa **la pregunta ontológica** y
el artefacto que alimenta una clave del schema:

| Etapa FOS | Pregunta ontológica | Alimenta |
|-----------|---------------------|----------|
| 2 · Modelo de Negocio (Lean Canvas + JTBD) | ¿esto tiene sentido como negocio? | `segmento_y_actores` (JTBD), `empresa.modelo_operativo` |
| 3 · Descubrimiento (Customer/Problem Fit) | ¿el problema es real, urgente, pagado? | `problema_priorizado` + `customer_problem_fit` |
| 4 · Solución (Propuesta de Valor, headline=JTBD) | ¿cuál es la solución mínima con sentido? | `propuesta_de_valor` |
| 7 · MVP (PRD + Data Model + Stack) | ¿qué versión mínima? | `entidades_dominio` (semilla; el resto es Fase 0/1) |

> El levantamiento ontológico se queda en el **"ser"** (etapas 2–4 + semilla de 7). El **"hacer"**
> (oferta, demanda, MVP completo) es trabajo de Fase 0 (`el-entrevistador`) y Fase 1 (`la-herreria`),
> que orbitarán esta ontología. No dupliques aquí lo que esas fases harán mejor.

---

## La gramática ontológica: trazabilidad de evidencia (lo más importante a portar)

El rasgo más valioso de Founder OS: **nada se inventa; cada afirmación se deriva con trazabilidad
explícita**. Aplícalo como disciplina del frontmatter:

### Jerarquía de evidencia (del `interview-analyzer` A07)
| Nivel | Qué es | Cómo se marca en `ONTOLOGY.md` |
|-------|--------|--------------------------------|
| **Hecho** | cita textual exacta de fuente | `evidencia: ["cita #fuente"]`, va al frontmatter |
| **Estimación** | número derivado con supuesto | frontmatter + nota del supuesto |
| **Inferencia débil** | deducción sin respaldo directo | `## Decisiones y supuestos abiertos`, NO frontmatter |
| **Sin datos** | no hay nada | rama abierta: "validar X" |

> **Regla absoluta (literal de FOS):** *"nunca inventar datos. Si algo no está en la transcripción, no
> está."* Para `el-ontologo`: si no está en lo que el cliente dijo o en `ontology/evidence/`, no es un
> hecho — es supuesto abierto.

### Fuerza de patrón (del `sop-consolidacion-entrevistas`)
Si la ontología se levanta de varias entrevistas a clientes: **patrón fuerte (5+ entrevistas) vs señal
moderada (3–4) vs aislada (1–2)**. Solo deja marcar `customer_problem_fit: alcanzado` con patrón fuerte
o evidencia equivalente. Una sola entrevista = señal, no fit.

---

## Gates de calidad (control estructural, no narrativo)

Heredado de `sop-gate-calidad` de FOS y alineado con el Independent Evaluator de Forja (R5/R7):
- El gate verifica el **output final, no el proceso**. Los **placeholders no cuentan**.
- Gate de emisión de `el-ontologo` (en [`emit-ontology.md`](emit-ontology.md)): las claves obligatorias
  del `ONTOLOGY_SCHEMA` §2 deben estar pobladas con contenido real (no placeholder), `problema_priorizado`
  debe tener veredicto CPF explícito, y toda afirmación de frontmatter sin evidencia debe estar
  espejada como supuesto abierto. **No bloquea al usuario — lo informa** (mismo espíritu que FOS).
