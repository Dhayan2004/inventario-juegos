<!--
  Plantilla del ledger `.ontologia/session.md` de `el-ontologo`.
  Protocolo canónico (CHECKPOINT + RESUME + regla de oro):
  ../../el-entrevistador/references/state-schema.md  — se reusa SIN modificar, solo cambia dir y draft.
  Borra los comentarios al usar.
-->
---
version: "1.0.0"
session_id: "<fecha>-<empresa>"
created_at: "<ISO8601>"
updated_at: "<ISO8601>"
domain: "ontologia"            # perfil de dominio (reusa la espina universal)
methodology: "ontology"        # emisión vía emit-ontology.md (no adaptador forge)
project_mode: "nuevo"          # nuevo | existente | re-levantamiento
project_name: "<Empresa>"
project_root: "<ruta>"
phase: "negocio"               # preparacion | negocio | marca | cierre | emitido
current_section: 1             # 1..6 (0 = aún sin empezar)
current_question_id: "S1.Q1"   # id estable de la pregunta en curso
sections:                       # claves fijas s1..s6 (espina universal); etiqueta = perfil ontologia
  s1_proposito:     "en_curso"   # 1 · Propósito y Norte · pendiente | en_curso | completa
  s2_segmento:      "pendiente"  # 2 · Segmento y Actores
  s3_problema:      "pendiente"  # 3 · Problema y Propuesta de Valor
  s4_modelo:        "pendiente"  # 4 · Modelo Operativo
  s5_marca:         "pendiente"  # 5 · Identidad y Significado de Marca
  s6_restricciones: "pendiente"  # 6 · Restricciones y Requisitos de Seguridad
glossary_terms: 0              # nº de términos del glosario de empresa
evidence_items: 0             # nº de piezas en ontology/evidence/
---

# Sesión: <Empresa> (Ontología · Fase −1)

## Siguiente acción (lo PRIMERO que se lee al retomar)
> Formular S1.Q1: "¿A qué se dedica la empresa, en una sola oración?
> Mi recomendación: <default concreto si el usuario no decide>."

## Ramas abiertas (deben cerrarse antes de avanzar de ranura)
- [ ] <ej: S3 — falta evidencia de demanda; customer_problem_fit no puede marcarse alcanzado.>

## Log de decisiones (recomendaciones aceptadas / rechazadas)
- S1.Q1 ⏳ En curso.

## Contradicciones resueltas
- <ej: "cliente" se usó para el comprador y para el usuario final → canonizado como **Comprador** vs **Usuario** (ver glosario).>

## Notas de retomada
- <libre: qué quedó capturado por el lente negocio para que el de marca lo consuma sin re-preguntar; nivel de confianza del material en modo existente; etc.>
