<!--
  el-entrevistador · ledger de sesión (.specfounder/session.md)
  Adaptado de SpecFounder v2 (MIT, © Ing. Oscar Lobo) — persistence/templates/session.template.md
  Perfil: software · emisión: adaptador "forge" (handoff a /plan vía references/emit-forge.md)
-->
---
source: "specfounder-v2 (MIT, Oscar Lobo)"
session_id: "AAAA-MM-DD-slug-proyecto"
created_at: "AAAA-MM-DDTHH:MM:SSZ"
updated_at: "AAAA-MM-DDTHH:MM:SSZ"
domain: "software"                 # FIJO por ahora (único perfil soportado)
methodology: "forge"               # FIJO — emisión vía adaptador forge (handoff a /plan)
project_mode: ""                   # nuevo | existente | re-spec-parcial | glosario-urgente
project_name: ""
project_root: ""                   # raíz del proyecto objetivo (donde vive .specfounder/)
phase: "seleccion"                 # seleccion | exploracion | vision | entrevista | cierre | emitido
vision_mode: ""                    # generada | aportada (vacío hasta definir la Visión; solo modo nuevo)
current_section: 0                 # 0 = en selección; luego 1..6
current_question_id: ""            # p.ej. S1.Q1 (o S1.Qa1 para preguntas ad-hoc)
sections:                          # claves fijas s1..s6 (espina universal); etiqueta = perfil software
  s1_vision:        "pendiente"    # 1 · Visión del Producto      | pendiente | en_curso | completa
  s2_actores:       "pendiente"    # 2 · Usuarios y Casos de Uso
  s3_elementos:     "pendiente"    # 3 · Funcionalidades por Módulo
  s4_estructura:    "pendiente"    # 4 · Flujos de Usuario
  s5_forma:         "pendiente"    # 5 · Arquitectura
  s6_restricciones: "pendiente"    # 6 · Requisitos No Funcionales
glossary_terms: 0                  # nº de términos del canon/glosario (detalle en CONTEXT.draft.md)
adr_count: 0
---

# Sesión: <nombre del proyecto>

## Siguiente acción
> (Lo PRIMERO que se lee al retomar. Pregunta exacta que toca formular —con su ID `S{n}.Q{m}`—
> al volver. SIEMPRE rellenar tras cada turno: si todo se cae ahora, esto debe bastar para
> continuar sin re-preguntar nada.)

## Ramas abiertas
> (Deben cerrarse antes de avanzar de sección.)
- [ ] (ninguna aún)

## Log de decisiones
> (Recomendaciones aceptadas / rechazadas. Una línea por decisión, no transcripción.
> Tope sugerido: últimas ~12 entradas + todas las irreversibles (ADR). El detalle vive en los drafts.)
- (vacío)

## Contradicciones resueltas
- (ninguna)

## Notas de retomada
- (libre — cualquier contexto que el agente quiera dejarse a sí mismo para no perder hilo.)
