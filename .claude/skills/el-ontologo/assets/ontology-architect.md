<!--
  el-ontologo · sombrero ARQUITECTO DE ONTOLOGÍA
  Destila entidades_dominio + requisitos_seguridad + decisiones irreversibles de EMPRESA.
  Reusa los 3 criterios de ADR del Arquitecto de el-entrevistador, reasignados al dominio ontologia.
-->

# Sombrero — Arquitecto de Ontología

> **Rol:** destilar de la entrevista las tres salidas estructuradas que más impactan downstream:
> (1) `entidades_dominio` (semilla del Data Model), (2) `requisitos_seguridad` (semilla DevSecOps/S1),
> y (3) las **decisiones irreversibles de empresa** (no ADRs técnicos — decisiones de negocio).
> **Cargado por:** `el-ontologo` (SKILL.md), en paralelo conceptual durante `negocio`, `marca` y el cierre de s6.
> **Escribe en:** frontmatter `entidades_dominio` / `requisitos_seguridad` / `restricciones` +
> narrativa `## Decisiones y supuestos abiertos` de `.ontologia/ONTOLOGY.draft.md`.

---

## 1. `entidades_dominio` (semilla del Data Model)

De los sustantivos centrales que el sombrero de negocio marca en s3.Q4 (y los que surjan en s2/s4),
destila la lista de **entidades canónicas del dominio** — los sustantivos que el futuro sistema
gestionará (p. ej. `Cliente`, `Póliza`, `Siniestro`), **no** conceptos del framework.

- Usa el **nombre canónico** que fijó el Glosarista (un concepto = un término).
- Verifica relaciones con **escenarios límite** antes de fijarlas: *"¿una Póliza puede existir sin
  Cliente? ¿un Cliente puede tener varias?"* — la cardinalidad y los huérfanos se descubren con
  escenarios. Anótalos como nota para el Data Model del Blueprint.
- Esta lista **alimenta `la-herreria`**: su modelo de datos parte de aquí, no de cero.

## 2. `requisitos_seguridad` (semilla DevSecOps → S1)

Cada vez que en la entrevista aparezca un **dato sensible** (financiero, médico, personal), una
**regulación** (GDPR, HIPAA, CFDI, PCI…) o una restricción de hosting/residencia de datos, destílalo:

```yaml
- requisito: "cifrado en reposo de datos médicos"
  origen: "regulación HIPAA / dato sensible: historia clínica"
  severidad: critico        # critico | alto | medio | bajo
```

> Este bloque es el **contrato** que consumirán `el-guardian` / `/temple` cuando se ate la seguridad
> shift-left (paso 4 del build, S1). Aquí solo se levanta — el cableado a los gates es de esa fase. No
> inventes requisitos: deben salir de algo que el cliente dijo o de una regulación que aplica de hecho.

## 3. Decisiones irreversibles de empresa (los 3 criterios, reasignados)

No son ADRs técnicos (esos son del Arquitecto de software, en Fase 0). Son **decisiones de negocio**
que cumplen los **3 criterios** (heredados del Arquitecto de `el-entrevistador`):

1. **Difícil de revertir** — cambiarla después cuesta caro o reposiciona la empresa.
2. **Sorprendente sin contexto** — alguien nuevo no la adivinaría.
3. **Trade-off real** — se ganó algo y se sacrificó algo.

Ejemplos: *"solo B2B enterprise (se renuncia al volumen B2C)"*, *"ingreso por suscripción anual
prepagada (se sacrifica conversión por previsibilidad)"*, *"el arquetipo es El Forajido (se renuncia a
la confianza institucional por diferenciación)"*.

Formato en `## Decisiones y supuestos abiertos`:
```
- **Decisión:** <qué se decidió> · **Trade-off:** <qué se ganó / qué se sacrificó> · **Evidencia:** [fuente#ancla]
- **Supuesto abierto:** <lo no validado aún> · **Cómo validarlo:** <siguiente paso>
```

> **Propuesta concreta, no menú.** Igual que el Arquitecto de software: cuando una decisión está "a
> decidir", propón UNA opción justificada a partir de lo levantado (s1–s4) y confírmala —no listes
> opciones sin recomendar.

## Protocolo

No entrevistas: recibes el balón de los entrevistadores vía el ledger y, en cada CHECKPOINT, actualizas
tus tres salidas en `ONTOLOGY.draft.md`. Lo no respaldado por evidencia va a **supuestos abiertos**,
nunca al frontmatter como hecho. Mantén el contrato de claves del [`ONTOLOGY_SCHEMA.md`](../../../references/ONTOLOGY_SCHEMA.md).
