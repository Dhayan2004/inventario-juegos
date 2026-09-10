# Emisión — de `.ontologia/` borrador a `ONTOLOGY.md` versionado

> **Rol:** la fase final de `el-ontologo`. Compila el borrador vivo (`.ontologia/ONTOLOGY.draft.md`) en
> el artefacto **versionado** `ONTOLOGY.md` en la raíz del proyecto, valida el gate de completitud, y
> produce el handoff a las fases siguientes. Análogo a `emit-forge.md` de `el-entrevistador`.
> **Cargado por:** `el-ontologo` (SKILL.md) en la fase `emitido`.

---

## Precondición (gate de completitud — no narrativo)

Antes de emitir, verifica contra [`ONTOLOGY_SCHEMA.md`](../../../references/ONTOLOGY_SCHEMA.md) §2:

```
[ ] Las 6 ranuras en `completa` y sin ramas abiertas en session.md.
[ ] Claves obligatorias pobladas con contenido REAL (no placeholder):
    empresa.nombre · empresa.modelo_operativo · ≥1 segmento_y_actores con jtbd ·
    problema_priorizado.enunciado · propuesta_de_valor.headline · marca.arquetipo_primario
[ ] problema_priorizado tiene customer_problem_fit explícito (alcanzado|pendiente|no_alcanzado).
[ ] Toda afirmación de frontmatter sin evidencia está espejada en "## Decisiones y supuestos abiertos".
```

Si algo falta → **no emitas**: informa qué falta y vuelve a la ranura pendiente (no bloquees con
drama; el gate informa, no castiga — espíritu del gate de Founder OS). `marca.codigo_simbolico` puede
quedar `no_levantado` y `perfil_fundador` siempre `no_entregado` — ninguno bloquea.

## Pasos de emisión

1. **Escribir `ONTOLOGY.md`** en la raíz del proyecto (no en `.ontologia/`), desde el borrador:
   frontmatter machine-readable + cuerpo narrativo (3 secciones), siguiendo
   [`../templates/ontology.template.md`](../templates/ontology.template.md).
2. **Marcar `discovery_completed: true`** en el frontmatter — es el **gate de consumo** downstream
   (igual que `discovery_completed` en `BRAND.md`/Brand DNA): ningún consumidor trata la ontología como
   autoritativa hasta que esto sea `true`.
3. **Consolidar `ontology/evidence/`** en la raíz: mover/copiar el material citado y dejar las
   referencias `[fuente#ancla]` resolviendo. `source_evidence` apunta aquí.
4. **Versionar.** `ONTOLOGY.md` + `ontology/evidence/` se commitean (a diferencia de `.ontologia/`, que
   es working-state y va en `.gitignore`). Son el handoff hacia las fases siguientes.
5. **Marcar `phase: emitido`** en `session.md`.

> **`.gitignore`:** durante la sesión, `.ontologia/` no debe ensuciar el historial (cambia cada turno).
> Solo el artefacto final se versiona. Mismo patrón que `.specfounder/` en `el-entrevistador`.

## Handoff (R6: validar nombres contra skills.md antes)

```
✅ ONTOLOGY.md emitido (discovery_completed: true) · evidence/ versionado

La ontología ahora se inyecta en todo el flujo, igual que brand.json en cada UI:

→ /descubrir (el-entrevistador, Fase 0)
   El CONTEXT.md del producto DERIVA del "## Glosario / lenguaje propio" de ONTOLOGY.md
   (modelo de dos capas). el-entrevistador carga ONTOLOGY.md como upstream y mantiene
   consistencia: no redefine un término que la empresa ya canonizó.

→ /plan (la-herreria, Fase 1)
   Lee ONTOLOGY.md en PREFLIGHT. El Blueprint ORBITA la ontología: no rehace BMC/VPC
   desde cero (problema_priorizado + propuesta_de_valor ya están), y el Data Model parte
   de entidades_dominio.

→ /add-ui-kit
   Hereda marca.arquetipo_primario + el lenguaje propio como punto de partida del
   Brand DNA (brand.json/voice.json = sub-capa de implementación de marca.*).

→ Fase de Seguridad (S1, futuro)
   requisitos_seguridad es el contrato que consumirán el-guardian / /temple cuando se
   ate la seguridad shift-left (paso 4 del build). Hoy se levanta; el cableado es de S1.
```

## Re-levantamiento (modo `re-levantamiento`)

Cuando una empresa ya tiene `ONTOLOGY.md` y se quiere actualizar hay **dos caminos**, según qué cambia:

- **Cambia el CONTENIDO** (la empresa evolucionó — nuevo segmento, arquetipo revisado): re-levantás las
  ranuras que cambian, subís `ontology_version`, y conservás la trazabilidad anterior. Re-emitir reescribe
  el artefacto. Esto es dominio de `el-ontologo`.
- **Cambia el ESQUEMA** (el template agregó una sección/campo nuevo): NO re-preguntás nada — corrés el
  runner de migraciones, que inyecta la estructura nueva en el `ONTOLOGY.md` ya llenado sin tocar los
  datos: `make ontology-migrate` (dry-run) → `make ontology-migrate APPLY=1`. Es el patrón portado de
  `apply-brand-migrations.py` de Estudio, **construido en S3** (anchor + tracking + idempotencia +
  backup, gobernado por `ontology_version`). Runner: `scripts/apply-ontology-migrations.mjs`; formato en
  `.claude/ontology-migrations/README.md`; contrato en `ONTOLOGY_SCHEMA.md` §9. `update-forja` lo corre
  solo tras sincronizar el template.
