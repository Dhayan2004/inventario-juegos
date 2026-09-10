<!--
  Plantilla del ONTOLOGY.md final que emite `el-ontologo` (Fase −1).
  Contrato completo: ../../../references/ONTOLOGY_SCHEMA.md
  Frontmatter = machine-readable (enforce-able) · Cuerpo = narrativa (documentación, citable).
  Borra los comentarios <!-- ... --> al poblar.
-->
---
ontology_version: "0.1"
source_evidence: "ontology/evidence/"
discovery_completed: false        # → true solo al emitir (gate de consumo downstream)

empresa:
  nombre: ""
  sector: ""
  modelo_operativo: ""            # cómo gana y entrega valor, 1-2 oraciones

segmento_y_actores:
  - actor: ""
    rol: ""
    jtbd: "Cuando [contexto], quiero [trabajo], para [resultado]"

problema_priorizado:
  enunciado: ""
  evidencia:
    - "cita textual #fuente"      # Hecho = cita exacta. Sin evidencia → supuesto abierto, no aquí.
  customer_problem_fit: "pendiente"   # alcanzado | pendiente | no_alcanzado

propuesta_de_valor:
  headline: ""
  diferenciadores: []

entidades_dominio: []             # sustantivos canónicos del dominio (semilla del Data Model)

marca:
  arquetipo_primario: ""
  arquetipo_secundario: ""
  codigo_simbolico:
    metafora: ""
    arquetipo_cultural: ""
    estado: "no_levantado"        # levantado | no_levantado (opcional; no bloquea)
  brand_dna_ref: "brand/brand.json"

requisitos_seguridad:
  - requisito: ""
    origen: ""                    # "regulación X" | "dato sensible Y"
    severidad: ""                 # critico | alto | medio | bajo

restricciones: []                 # no-negociables legales/técnicas/de negocio

perfil_fundador:
  estado: "no_entregado"          # PUNTO DE EXTENSIÓN (W3) — no se levanta en M3
---

# Ontología: <Nombre de la empresa>

<1-2 párrafos: el "Norte" de la empresa — a qué se dedica y por qué existe (manifiesto).
 Producto de la ranura s1.>

## Cómo opera esta empresa

<Modelo operativo en prosa: cómo gana dinero, cómo entrega valor, su cadena de valor.
 Producto de la ranura s4. Es documentación citable, no enforce-able.>

## Glosario / lenguaje propio de la empresa

<!--
  El vocabulario del DOMINIO DE LA EMPRESA — su lenguaje propio. CAPA PADRE del CONTEXT.md
  funcional (modelo de dos capas). Formato PURO, un concepto = un término:
-->
**[Término]**: [Definición en 1-2 oraciones. Qué ES, no cómo se implementa.] · _Evitar_: [sinónimo 1], [sinónimo 2]

## Decisiones y supuestos abiertos

<!-- Decisiones irreversibles de EMPRESA (3 criterios) + supuestos no validados aún. -->
- **Decisión:** <qué se decidió> · **Trade-off:** <qué se ganó / qué se sacrificó> · **Evidencia:** [fuente#ancla]
- **Supuesto abierto:** <lo no validado aún> · **Cómo validarlo:** <siguiente paso>

---

<!--
Recordatorio de reglas (borrar al usar):
- Frontmatter = enforce-able. Solo va aquí lo respaldado por evidencia (Hecho). Inferencias
  débiles y sin-datos → "## Decisiones y supuestos abiertos", nunca al frontmatter.
- El código simbólico se DESCUBRE, no se proyecta. Si no se levantó, estado: "no_levantado".
- perfil_fundador SIEMPRE "no_entregado" en M3 (punto de extensión W3).
- discovery_completed: true solo cuando las claves obligatorias (ONTOLOGY_SCHEMA §2) están pobladas.
-->
