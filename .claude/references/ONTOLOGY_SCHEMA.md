# Ontology Schema de Forge Enterprise

> **Qué es esto.** El contrato del artefacto `ONTOLOGY.md` — el levantamiento del **"ser" de la
> empresa** (su identidad, propósito, problema, mercado, significado de marca y restricciones), que
> el harness inyecta en cada generación downstream **igual que hoy `brand.json`/`voice.json` se
> inyectan en cada UI**. Es la **Fase −1** del flujo Forge: precede al SPEC funcional (Fase 0,
> `el-entrevistador`) y al Blueprint (Fase 1+, `la-herreria`).
>
> Lo produce el skill **`el-ontologo`** (`/ontologia`). Es el mayor diferenciador de Forge
> Enterprise: lo que hace que el harness "gire alrededor de" la empresa, no de una idea cruda.
>
> **Fuentes de diseño:** `docs/06` §4 M3 · `docs/03` §5.2 (formato propuesto, Founder OS) ·
> `docs/04` (Estudio / código simbólico) · `docs/02` §6.2–6.3 (capa ontológica como Fase 0/−1).

- **Versión:** v0.1.0 (2026-06-30, M3 · Ontología)
- **Extiende:** [`BRAND_DNA_SCHEMA.md`](BRAND_DNA_SCHEMA.md) — el Brand DNA pasa a ser una **sub-capa**
  de la ontología (ver §4). El mecanismo (contrato de generación, no brand book) se hereda 1:1.

---

## 1. Principio de diseño (heredado del Brand DNA)

Tomado literal del `BRAND_DNA_SCHEMA` §10: *"no debe describir toda la empresa como un brand book;
debe actuar como un **contrato de generación**"* — suficientemente estricto para que
specs/blueprint/modelo-de-datos/UI/seguridad lo respeten, suficientemente flexible para empresas
distintas.

Igual que el Brand DNA separa **machine-readable (enforcement)** de **natural-language
(documentación)**, el `ONTOLOGY.md` separa:

| Capa | Qué contiene | Quién la consume |
|------|--------------|------------------|
| **Bloque machine-readable** (frontmatter YAML) | afirmaciones *enforce-ables*: empresa, segmento+JTBD, problema priorizado, propuesta de valor, entidades de dominio, requisitos de seguridad, restricciones | skills downstream (validación + derivación) |
| **Cuerpo narrativo** (markdown) | contexto: cómo opera la empresa, lenguaje propio, decisiones y supuestos abiertos | humanos + agentes (documentación citable) |

> **Distinción docs vs enforcement (igual que `archetype.allowed_behaviors` en Brand DNA,
> [memory:errors#E-004]):** el cuerpo narrativo es **documentación** — citable en specs, prompts y
> copy, pero NO enforce-able programáticamente. El enforcement vive en el frontmatter estructurado.

---

## 2. Bloque machine-readable (el contrato)

Estructura canónica del frontmatter de `ONTOLOGY.md`. **Las claves de primer nivel son el contrato
estable** — los consumidores downstream dependen de estos nombres exactos.

```yaml
---
ontology_version: "0.1"
source_evidence: "ontology/evidence/"      # carpeta de trazabilidad (entrevistas, docs del cliente)
discovery_completed: false                  # true solo cuando el-ontologo emite (gate de consumo)

# ── empresa ──────────────────────────────────────────────────────────────────
empresa:
  nombre: ""
  sector: ""                                # del onboarding empresarial (FOS)
  modelo_operativo: ""                      # cómo gana y entrega valor (1-2 oraciones)

# ── segmento_y_actores ≈ Lean Canvas Bloque 1 + CJM (FOS) + ICPs (Estudio §10) ─
segmento_y_actores:
  - actor: ""                               # nombre del segmento/stakeholder
    rol: ""                                 # qué hace frente a la empresa
    jtbd: "Cuando [contexto], quiero [trabajo], para [resultado]"

# ── problema_priorizado ≈ A08 consolidado / Customer-Problem Fit (FOS) ─────────
problema_priorizado:
  enunciado: ""
  evidencia:                                # jerarquía de evidencia (cita textual #fuente)
    - "cita textual #fuente"
  customer_problem_fit: "pendiente"         # alcanzado | pendiente | no_alcanzado

# ── propuesta_de_valor ≈ A11 (FOS) ────────────────────────────────────────────
propuesta_de_valor:
  headline: ""
  diferenciadores: []

# ── entidades_dominio → semilla del Data Model (A19) → alimenta el Blueprint ───
entidades_dominio: []                       # sustantivos canónicos del dominio (no del framework)

# ── marca → SUB-CAPA: contrato de identidad que brand.json/voice.json implementan (§4) ─
marca:
  arquetipo_primario: ""                    # 1 arquetipo Jung dominante (Estudio §2)
  arquetipo_secundario: ""
  codigo_simbolico:                         # Klaric/Rapaille (Estudio /klaric) — DESCUBIERTO, no proyectado
    metafora: ""                            # la metáfora destilada
    arquetipo_cultural: ""                  # rueda de 12, validado contra arquetipo_primario
    estado: "no_levantado"                  # levantado | no_levantado (opcional; no bloquea)
  brand_dna_ref: "brand/brand.json"         # dónde vive la implementación (add-ui-kit)

# ── requisitos_seguridad → DevSecOps atado a la ontología (norte §3.3) → S1 ────
requisitos_seguridad:
  - requisito: ""
    origen: ""                              # "regulación X" | "dato sensible Y"
    severidad: ""                           # critico | alto | medio | bajo

# ── restricciones → no-negociables legales/técnicas/de negocio ────────────────
restricciones: []

# ── tenant_model → arquitectura multi-tenant de las apps generadas (M6) ────────
tenant_model:
  multi_tenant: false                       # true si las apps de esta empresa sirven a organizaciones
  termino: "organization"                   # organization | workspace | account | team (cómo se llama el tenant)
  aislamiento: "rls"                         # rls (Golden Path) | schema-per-tenant | db-per-tenant (override)

# ── perfil_fundador → PUNTO DE EXTENSIÓN (W3, NO entregado) — ver §5 ───────────
perfil_fundador:
  estado: "no_entregado"                    # reservado para el perfilado de personalidad (Joaco)
---
```

### Claves obligatorias para `discovery_completed: true`
`empresa.nombre`, `empresa.modelo_operativo`, ≥1 `segmento_y_actores` con `jtbd`,
`problema_priorizado.enunciado`, `propuesta_de_valor.headline`, `marca.arquetipo_primario`.
El resto puede quedar parcial (con su rama abierta anotada). `el-ontologo` no emite con obligatorias
vacías (gate análogo al `discovery_completed` de `add-ui-kit`).

---

## 3. Cuerpo narrativo (documentación)

Después del frontmatter, tres secciones fijas en lenguaje natural — para humanos y para agentes que
citan contexto (no enforce-able):

```markdown
## Cómo opera esta empresa
<modelo operativo en prosa: cómo gana dinero, cómo entrega valor, cadena de valor.>

## Glosario / lenguaje propio de la empresa   ← alimenta el lenguaje de la UI y los specs
<el vocabulario del DOMINIO DE LA EMPRESA, formato PURO (un concepto = un término).
 Esta es la CAPA PADRE del CONTEXT.md funcional que emite el-entrevistador — ver §6.>

## Decisiones y supuestos abiertos
<decisiones irreversibles de empresa (con su trade-off) + supuestos no validados aún.>
```

> **`## Glosario / lenguaje propio de la empresa` es load-bearing.** Es el glosario del que **deriva**
> el `CONTEXT.md` funcional de la Fase 0 (modelo de **dos capas**, ver §6). Mismo dogma que el
> Glosarista de `el-entrevistador`: un concepto = un término, definición de **qué ES** (no cómo se
> implementa), sinónimos al banquillo.

---

## 4. El Brand DNA como sub-capa de la ontología

Antes de M3, `brand.json` + `voice.json` (de `add-ui-kit`) eran la raíz del contrato de marca. Con
la ontología, **el Brand DNA pasa a ser una sub-capa**: la ontología captura el **significado** de la
marca (arquetipo, código simbólico, lenguaje propio) y el `brand.json`/`voice.json` son su
**implementación operativa** (tokens, anti-slop, voice traits).

```
ONTOLOGY.md  (el "ser" — incluye marca.arquetipo + codigo_simbolico + glosario de empresa)
   └─► brand/brand.json + brand/voice.json  (la implementación — tokens/anti-slop/voice, add-ui-kit)
          └─► impeccable / add-* (componentes UI que respetan el contrato)
```

Regla de coherencia (futura, atada al Anti-Slop Gate de `el-evaluador`): `brand.json.archetype` debe
ser consistente con `ONTOLOGY.md › marca.arquetipo_primario`. Si `add-ui-kit` corre **después** de
`el-ontologo`, hereda `marca.*` como punto de partida en vez de preguntar desde cero. Si corre antes
(proyecto sin ontología), nada cambia — el Brand DNA sigue siendo válido autónomo (degradación segura).

---

## 5. Punto de extensión: perfil de personalidad del fundador (W3 — NO entregado)

El norte atribuye a Joaco un **perfilado ontológico de personalidad** (método de 12–14 años, "código
simbólico personal", OCP de Novo Labs) que **no está entregado** (W3 en el roadmap, `docs/02` §7 Q4,
`docs/04` §"preguntas abiertas" Q4). **Esta capa NO se construye en M3** — se diseña agnóstica para
integrarla después sin tocar el motor:

- El frontmatter reserva el bloque `perfil_fundador: { estado: "no_entregado" }`. Hoy no lo llena
  ningún sombrero; mañana, un sombrero `founder-profiler` (cuando Joaco entregue el método) lo puebla.
- `marca.codigo_simbolico` cubre el significado **cultural/de categoría** (Estudio `codigo-simbolico`,
  que SÍ está disponible conceptualmente) — NO el de **personalidad del fundador**. Son capas
  distintas; no las confundas.
- Ningún consumidor downstream debe **requerir** `perfil_fundador`. Su ausencia es el estado normal.

> Cuando llegue el método de Joaco: añade su guion como un sombrero más colgado de la ranura 5
> (significado), puebla `perfil_fundador`, y deja el resto del schema intacto.

---

## 6. Modelo de dos capas: ONTOLOGY.md → CONTEXT.md

**Decisión (resuelta JIT, `docs/02` §7 Q3):** ONTOLOGY.md y CONTEXT.md son **dos capas**, no un
artefacto fusionado.

| | `ONTOLOGY.md` (Fase −1, `el-ontologo`) | `CONTEXT.md` (Fase 0, `el-entrevistador`) |
|---|---|---|
| **Sujeto** | la **empresa** (su ser) | el **producto** (lo que se va a construir) |
| **Glosario** | lenguaje propio de la empresa (capa **padre**) | términos funcionales del producto (capa **derivada**) |
| **Alcance** | negocio + marca + seguridad + entidades | features, usuarios, módulos del producto |
| **Cuándo** | una vez por empresa/cliente | una vez por producto/proyecto |

Regla: el `CONTEXT.md` que emite `el-entrevistador` **deriva** del `## Glosario` de `ONTOLOGY.md` y
**debe ser consistente** con él (no redefine un término que la empresa ya canonizó). Si `ONTOLOGY.md`
existe, `el-entrevistador` lo carga como upstream; si no existe, opera autónomo (degradación segura —
el orden Fase −1 → Fase 0 es recomendado, no obligatorio).

---

## 7. Quién consume `ONTOLOGY.md` y cómo (análogo a BRAND_DNA)

| Consumidor | Qué lee | Efecto |
|------------|---------|--------|
| `la-herreria` (`/plan`) | todo, en PREFLIGHT | deja de hacer BMC/VPC desde cero → el Blueprint **orbita** la ontología |
| `el-entrevistador` (`/descubrir`) | `## Glosario` + `segmento_y_actores` | `CONTEXT.md` deriva del glosario de empresa (§6) |
| generador de specs / Blueprint | `problema_priorizado` + `propuesta_de_valor` | las features salen del problema real, no de la idea cruda del dev |
| modelo de datos / `el-migrador` | `entidades_dominio` | semilla del data model |
| `add-ui-kit` / `impeccable` | `marca.*` + `## Glosario` | el Brand DNA hereda arquetipo + lenguaje de empresa (§4) |
| `el-guardian` / `/temple` (S1) | `requisitos_seguridad` | gates de seguridad que salen del levantamiento real, no de un checklist genérico |
| `la-herreria` / `el-migrador` (M6) | `tenant_model` | si `multi_tenant: true`, el Data Model aplica RLS por tenant (organizations + membresía) en vez de single-tenant; término del tenant fijado por la empresa. Doctrina: [`MULTI_TENANCY.md`](MULTI_TENANCY.md) |

---

## 8. Trazabilidad (gramática de evidencia)

Toda afirmación enforce-able del frontmatter debe ser **auditable**. Patrón heredado de Founder OS
(`docs/03` §3.3) y de la memoria de Forja:

- Carpeta `ontology/evidence/` en la raíz del proyecto: transcripciones, `consolidado.md`, docs del
  cliente que respaldan las afirmaciones.
- Citación con la gramática `[fuente#ancla]` (la misma de la memoria de Forja).
- `problema_priorizado.evidencia` y `marca.codigo_simbolico` **deben** citar evidencia; lo no
  respaldado se marca como supuesto abierto en `## Decisiones y supuestos abiertos`, no como hecho.

> **El código simbólico se DESCUBRE, no se proyecta** (convicción no-negociable de Klaric, `docs/04`):
> `marca.codigo_simbolico` se levanta de lo que la cultura/cliente DICE y SIENTE, validado con el
> usuario antes de cargarse — nunca inventado por el agente.

---

## 9. Versionado y migraciones (S3 · CONSTRUIDO)

Como `brand.json`, el `ONTOLOGY.md` evolucionará su esquema después de que un cliente lo llene. El
patrón (portado de Estudio, `docs/04` `apply-brand-migrations.py`) ya existe en Forge: migraciones con
anchor + tracking + idempotencia + backup, gobernadas por `ontology_version`.

- **Runner:** [`scripts/apply-ontology-migrations.mjs`](../../scripts/apply-ontology-migrations.mjs) —
  Node zero-dep. Dry-run por default; `--apply` para escribir. Atajo `make ontology-migrate`.
- **Migraciones:** `.claude/ontology-migrations/NNNN_slug.md` (frontmatter + cuerpo). Dos tipos:
  `ontology_md` (inyecta estructura en un `anchor` exacto) y `create_path` (crea directorios).
  Formato y garantías en [`.claude/ontology-migrations/README.md`](../ontology-migrations/README.md).
- **Idempotencia** (`check_line`) + **ledger** versionado (`.forja/ontology.migrations`) + **backup**
  efímero (`.forja/ontology-backups/<ts>/`). Nunca toca los datos que el cliente ya escribió.
- **Gobierno de versión:** cada migración puede declarar `ontology_version`, que el runner sella en
  este frontmatter al aplicarla. Por eso `ontology_version` vive en el contrato: es el ancla del
  versionado. `update-forja` corre el runner tras sincronizar el template (propagación automática).

> El directorio ships **sin migraciones vivas**: el esquema está en `0.1` y no ha evolucionado, así
> que toda ontología `0.1` está al día. La primera migración real se escribe el día que este esquema
> suba de versión (ver el ejemplo trabajado en el README de `ontology-migrations/`).

> **Multi-tenant (M6, construido).** El campo `tenant_model` (frontmatter §2) declara si las apps de la
> empresa son multi-tenant, con qué término (`organization`/`workspace`/…) y qué modelo de aislamiento.
> Es una propiedad de la **empresa cliente** (single-tenant por proyecto en el harness — B1): el
> `ONTOLOGY.md` vive una vez por empresa, y `tenant_model` dice cómo se aíslan los **usuarios finales** de
> las apps que esa empresa genera. Lo consumen `la-herreria` (Data Model) y `el-migrador`. Doctrina:
> [`MULTI_TENANCY.md`](MULTI_TENANCY.md). `ontology_version` por cliente sigue permitiendo versionar la
> ontología por organización en el futuro.

---

## 10. Recomendación final (el contrato en una frase)

`ONTOLOGY.md` no intenta describir toda la empresa como un dossier corporativo. Es un **contrato de
generación del "ser" de la empresa**: un frontmatter enforce-able (qué validan y derivan las skills) +
un cuerpo narrativo citable, con el Brand DNA como sub-capa y la personalidad del fundador como punto
de extensión. La clave —igual que en el Brand DNA— no es solo declarar la empresa: es darle al harness
una **gramática del negocio** suficiente para tomar buenas decisiones en specs, datos, UI y seguridad
cuando el caso no estaba previsto.
