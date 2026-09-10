# Modelo por rol — tiering de LLM por sub-agente (C6, doctrina OPCIONAL)

> **Qué es esto.** La doctrina de **qué modelo usa cada rol/sub-agente** de Forja: *Opus piensa, Sonnet
> orquesta, Haiku rellena*. Es guía de **coste/rendimiento**, no una obligación cableada: el **default es
> heredar el modelo de la sesión** — nunca se fuerza. Se expresa opcionalmente con `model:` en el
> frontmatter de un skill/worker cuando la relación coste↔dificultad lo justifica. Es a la elección de
> modelo lo que `BRAND_DNA_SCHEMA.md` es a la UI: un contrato de referencia que el humano puede aplicar,
> no un gate automático.
>
> **Decisión de producto (Q28, de Carlos):** el tiering de modelo es una **decisión de negocio** (coste,
> licencia, plan disponible) — por eso se documenta como **opcional**, no se cablea a la fuerza en los
> skills. Forja funciona correctamente heredando un solo modelo; el tiering es una optimización que el
> humano habilita cuando le conviene. Fuente: `docs/06` §C6 + `docs/02` §3.10 (SpecFounder `RENDIMIENTO.md`).

- **Versión:** v0.1.0 (2026-06-30, C6 · autoresearch + modelo-por-rol)
- **Alinea con:** la consolidación de skills (D5) — menos skills, cada uno con un rol claro ⇒ el tiering de
  modelo se vuelve legible (un rol = un tier candidato).
- **Regla de enforcement:** ninguna dura. Es **guía opcional**. El único invariante es *default = heredar el
  modelo de sesión* (no forzar `model:` salvo justificación de coste/dificultad).

---

## 1. El principio — tres tiers, tres roles

De la lección de rendimiento de SpecFounder (`RENDIMIENTO.md`): el modelo más caro sólo se justifica donde
el **razonamiento** es el cuello de botella; donde el trabajo es mecánico, el modelo barato rinde igual a una
fracción del coste. Tres tiers, mapeados a los patrones de Forja (Coordinator/Fork/Swarm, D-013):

| Tier | Rol | Trabajo típico | Skills/roles candidatos de Forja |
|------|-----|----------------|----------------------------------|
| **Opus — piensa** | planificación, arquitectura, evaluación difícil | decisiones con muchas restricciones, trade-offs, juicio adversarial, **gusto** | `la-herreria` (Blueprint), `el-crisol` (veredicto), `el-guardian` (auditoría adversarial), `el-evaluador` (Anti-Slop + Three-Layer), el **juez** de `autoresearch`, **`el-critico-de-diseno`** (juez visual fresco — modelo más grande = distribución de gusto más ancha; en el run de Anshu fue <10% de los tokens del loop; que diseñe directo costó ~2×) |
| **Sonnet — orquesta** | coordinación, build, generación estándar | dispatch de sub-agentes, escribir código feature, generar UI contra un contrato claro | Coordinator / la-forja root, `impeccable`, los `add-*`, `el-tajo`, `el-golpe`, `sprint`, `el-pulidor` (orquesta el loop del crítico: screenshots, despacho fresco, cap), **el implementador de diseño** (no bajarlo a *rellena*: tiene que ejecutar craft, no parchear hex) |
| **Haiku — rellena** | tareas mecánicas, scaffolding | boilerplate, formateo, mover archivos, generar N variantes triviales | `skill-creator` (scaffold), generación de outputs mecánicos en el loop de `autoresearch`, tareas atómicas sin juicio |

**La regla de asignación:** subí de tier sólo cuando el rol **necesita más razonamiento**, no "por si acaso"
(análogo a AP4: nada "por las dudas"). Un rol que sólo rellena en Opus es coste tirado; un rol que decide
arquitectura en Haiku es calidad tirada.

### 1.1 El caso testigo — los sombreros de descubrimiento (cierra el *tiering* de S5)

El origen de esta doctrina es `RENDIMIENTO.md` de SpecFounder (`docs/02` §3.10), cuyo mapa de roles es
**directamente aplicable** a los sombreros de `el-entrevistador` (Fase 0) y `el-ontologo` (Fase −1), que
son un port de ese mismo motor. Ese mapa **es** el "tiering" que el roadmap listaba como residual de S5:
no era una pieza aparte por construir, sino esta doctrina (entregada en C6) aplicada a los sombreros.

| Tier | Sombreros de `el-entrevistador` / `el-ontologo` | Por qué |
|------|--------------------------------------------------|---------|
| **piensa** | `interviewer` (guion + recomendación por turno), `vision-generator`, `architect-adr`, `ontology-architect`, `business-interviewer` (FOS), `brand-interviewer` (Estudio) | el razonamiento (desambiguar, decidir un ADR, priorizar un problema) es el cuello de botella |
| **orquesta** | el coordinador inline, `explorer`/`source-reader`, `glossarist`/`ontology-glossarist` | leer/mapear/coordinar contra un guion claro; no deciden, precargan |
| **rellena** | el CHECKPOINT (persistir estado tras cada turno), `/ayuda` | mecánico, sin juicio |

**Igual que el resto de la doctrina, esto es opcional y default = heredar la sesión.** No se cablea
`model:` en los sombreros: el costo real de una entrevista (`RENDIMIENTO.md`: 1 pregunta × ~40 turnos)
lo domina el `interviewer`, y el tiering es la palanca *si* Carlos fija un techo de gasto para una Fase 0
larga (Q28). Sin ese requisito, la herencia de sesión rinde bien. El mapa vive acá como guía, no como gate.

## 2. El default no-negociable — heredar el modelo de sesión

**Si no declarás `model:`, el skill/worker hereda el modelo de la sesión.** Ese es el comportamiento por
defecto y el correcto para la mayoría de los casos:

- Forja **funciona completa** con un solo modelo (el de la sesión). El tiering es optimización, no requisito.
- Cablear `model:` en cada skill acopla el harness a una **matriz de disponibilidad** (planes, licencias,
  cuotas) que es decisión de negocio de Carlos, no del framework (Q28).
- Un `model:` hardcodeado que apunta a un modelo no disponible en el plan del usuario **rompe** el skill.
  Heredar la sesión nunca rompe: usa lo que el usuario ya tiene.

> **Degradación segura.** Igual que M6 no fuerza multi-tenancy y R17 se salta si no hay `.plan/`: el modelo
> por rol es una **propiedad opcional**. Ausencia de `model:` = herencia de sesión = correcto. Nunca es un halt.

## 3. Cuándo SÍ declarar `model:` (los casos que lo justifican)

Declarar `model:` en el frontmatter de un skill/worker es válido cuando el trade-off coste↔dificultad es
claro y estable:

- **Un rol de juicio caro en un pipeline barato:** el juez de `autoresearch`, `el-guardian` o
  `el-critico-de-diseno` (`model: opus` declarado en su agente) puede fijarse en el tier "piensa" aunque el
  resto del loop corra en un tier más barato — la calidad del veredicto domina el coste. Ojo NoveltyBench: el
  modelo más grande no es el más *diverso* — para divergir (Discover) no hace falta el tier caro; para juzgar, sí.
- **Un sub-agente Swarm mecánico masivo:** si un Swarm (D-013) lanza N workers que sólo rellenan boilerplate,
  fijarlos en "rellena" recorta coste sin tocar calidad.
- **Un requisito de coste explícito del negocio:** si Carlos fija un techo de gasto para una fase, el tiering
  se vuelve la palanca — pero es **su** decisión, documentada, no un default del framework.

Fuera de esos casos: **no declares `model:`**. La herencia de sesión es el default y evita el acoplamiento.

## 4. Cómo se expresa (frontmatter)

El campo es opcional y vive en el frontmatter del skill/worker, junto a `name`/`description`/`tier`:

```yaml
---
name: <skill>
description: >
  ...
tier: core
model: opus        # OPCIONAL. Omitir ⇒ hereda el modelo de sesión (default). Valores: opus | sonnet | haiku.
requires: ...
fallback: ...
dependencies: []
---
```

- **`inventory.js` no depende de `model:`** — es un campo extra que el parser ignora sin romperse (sólo lee
  `name`/`description`/`tier`/`context`). Agregarlo no desincroniza el inventario.
- **Un worker dentro de un Swarm** puede recibir el tier por su dispatch (el Coordinator elige el modelo del
  sub-agente), sin necesidad de un `model:` estático en un SKILL.md.
- **Nunca** un `model:` que apunte a un identificador de modelo específico y volátil (ej. un `-YYYYMMDD`): usá
  el alias de tier (`opus`/`sonnet`/`haiku`) para que el mapeo a la versión concreta sea del runtime, no del skill.

## 5. Fronteras y caveats

- **No es un gate.** Ningún hook ni `el-evaluador` rechaza un skill por su `model:` (o por su ausencia). Es
  guía; el enforcement lo pone el humano al decidir su presupuesto.
- **Caveat de coste/licencia (Q28):** el tier disponible depende del plan del usuario. Un skill que **exige**
  Opus excluye a usuarios sin ese acceso — por eso el default es herencia, y `model:` es una recomendación que
  el usuario puede sobreescribir con el modelo de su sesión.
- **Alinea con D5 (consolidación de skills):** cuando un skill tiene un rol único y claro, su tier candidato
  es obvio. Skills que hacen "de todo" no tienen un tier natural — otra razón para consolidar (menos skills,
  roles más nítidos, tiering más legible). Es la misma dirección anti-bloat de la lección Vercel.

## 6. El contrato en una frase

El modelo por rol es una **guía de coste opcional**: Opus donde se piensa, Sonnet donde se orquesta, Haiku
donde se rellena — pero el default siempre es **heredar el modelo de sesión**, y `model:` sólo se cablea
cuando la relación coste↔dificultad lo justifica y el negocio lo decide (Q28). Forja rinde bien sin tiering;
el tiering la hace más barata sin bajarle la calidad donde importa.

## Sources

- `docs/06` §C6 — modelo-por-rol como parte de Calidad, encuadrado opcional/anti-bloat.
- `docs/02` §3.10 — SpecFounder `RENDIMIENTO.md` (tiering Opus/Sonnet/Haiku por rol/sub-agente).
- Q28 (Carlos) — el tiering es decisión de negocio (coste/licencia); se documenta opcional, no se cablea.
- `[memory:decisions#D-013]` — patrones Coordinator/Fork/Swarm de Forja (el dispatch que elige el modelo del sub-agente).
