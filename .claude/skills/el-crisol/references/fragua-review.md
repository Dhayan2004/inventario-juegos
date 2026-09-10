# Fragua Review — rúbrica de revisión de arquitectura del Blueprint (C1)

> **Qué es esto.** La rúbrica detallada del comando `/fragua-review`: una revisión **adversarial y
> read-only** del Blueprint/plan de una feature (o del proyecto) que corre **antes** de `/build`.
> Complementa a `el-crisol`: `el-crisol` valida el **negocio** (¿vale la pena? → Go/Caution/No-Go);
> `fragua-review` valida el **diseño/arquitectura** (¿es correcto, mínimo, construible? → EXPANSIÓN /
> MANTENER / REDUCCIÓN). Vive aquí, como referencia de `el-crisol`, porque `el-crisol` es el skill de
> validación natural — así `fragua-review` habita junto a su pariente sin crear un skill nuevo (anti-bloat,
> lección Vercel "-80% tools = +3× rendimiento").
>
> **El coordinador que la recorre es thin (R4) y read-only:** lee el Blueprint + SPEC + ONTOLOGY +
> `feature_list.json`, corre las 5 fases en orden, y sintetiza **un** veredicto. NO escribe código, NO
> escribe `feature_list.json` ni `.claude/memory/**` (R5 — solo `el-evaluador`).

- **Versión:** v0.1.0 (2026-06-30, C1 · Calidad — fragua-review)
- **Lo dispara:** el comando [`/fragua-review`](../../../commands/fragua-review.md).
- **Lo produce:** `FRAGUA-REVIEW-<nombre>.md` en `.claude/reports/`.
- **Regla de enforcement citada:** `[memory:CONSTRAINTS.md#R7]` (Three-Layer Verification — la Fase 4
  la usa como contrato de "qué debe probar el plan"). `[memory:CONSTRAINTS.md#R4]` (el coordinador es
  thin, no invoca skills directo). AP3 (el que diseña no se auto-arbitra).

---

## 1. Cuándo se corre (y cuándo NO)

| Se corre | NO se corre |
|----------|-------------|
| Blueprint aprobado por `la-herreria`, **antes** de `/build` | Antes de tener Blueprint (halt → `/plan`) |
| Feature grande/riesgosa cuyo diseño conviene endurecer | Task atómico (`el-tajo`) o one-shot trivial (`el-golpe`) |
| Tras un cambio de alcance que reabre el diseño | Auditoría de código YA escrito (eso es `el-guardian`) |
| Cuando el humano pide "revisá el plan / la arquitectura / el blueprint" | Validación de negocio/estrategia (eso es `el-crisol`) |

Ubicación en el flujo Forja:

```
/plan (la-herreria) ──► BLUEPRINT ──► /crisol (negocio) ──► /fragua-review (arquitectura) ──► /build
        ▲                                   │                         │
        └──── EXPANSIÓN / REDUCCIÓN ◄────────┴─────────────────────────┘  (loop de vuelta a planear)
```

`el-crisol` y `fragua-review` son ortogonales: un Blueprint puede ser **Go** de negocio y a la vez
**REDUCCIÓN** de diseño (buen mercado, plan sobredimensionado). Se corren ambos; no se sustituyen.

---

## 2. Cómo el coordinador la recorre (protocolo, R4 + AP3)

El coordinador (`el-crisol` MISMA cuando se invoca `/fragua-review`, o un sub-agent Reviewer que despacha)
opera **read-only**:

1. **PREFLIGHT.** ¿Existe `.claude/PRPs/BLUEPRINT-<nombre>.md`? Si no → halt: "Sin Blueprint. Corré /plan
   primero. fragua-review revisa arquitectura de un plan existente, no la genera." Determinar `<nombre>`
   (del filename del Blueprint, o del `active` de `feature_list.json`, o preguntar UNA cosa).
2. **AP3 check.** Si el mismo agente que generó el Blueprint pide auto-revisarlo, declararlo en el reporte
   ("self-review — considerar árbitro independiente para el veredicto final"). El que diseña no es el
   árbitro ideal; la revisión es más fuerte con otro contexto/modelo.
3. **Cargar contexto** (degradación segura — usar lo que exista): Blueprint (fases, arquitectura, stories),
   `SPEC.md` (requisitos, Sección 6 NFR), `ONTOLOGY.md` (entidades de dominio, `requisitos_seguridad`,
   `tenant_model`), `feature_list.json` (features a construir), `ARCHITECTURE.md` + `forge/CLAUDE.md`
   (Golden Path), `la-herreria/references/threat-db.yaml` (catálogo de amenazas).
4. **Correr las 5 fases EN ORDEN** (§3–§7). Cada hallazgo se ancla a una línea/sección del Blueprint y se
   clasifica por severidad (`critical` / `high` / `medium` / `low`).
5. **Sintetizar UN veredicto** (§8) a partir de los hallazgos agregados.
6. **Emitir `FRAGUA-REVIEW-<nombre>.md`** (§9) — registry + diagramas ASCII + decisiones abiertas + veredicto.

**Reglas duras del coordinador:** thin (R4 — no invoca otros skills directo; si necesita docs frescas,
un sub-agent llama `find-docs` ad-hoc). Read-only (no Edit/Write a `src/**`, `feature_list.json`,
`.claude/memory/**`). No inventa hallazgos: cada uno cita la línea del Blueprint que lo motiva.

---

## 3. Fase 1 — Nuclear Scope Challenge (la más importante)

> **Doctrina central (lección Vercel).** La pregunta que abre la revisión NO es "¿está bien construido?"
> sino **"¿qué de esto se puede NO construir?"**. El default de un plan es tener de más. Cada entidad,
> cada endpoint, cada pantalla y cada dependencia debe **ganarse su lugar**.

Cruza dos anclas:

- **Minimalismo / YAGNI.** ¿Se está construyendo algo "por si acaso"? Toda feature especulativa (sin
  usuario/story que la pida HOY) es candidata a corte. Toda abstracción prematura (framework interno,
  capa genérica, config para un caso que aún no existe) es deuda, no valor.
- **Peldaño 0 ontológico.** Cada entidad de dominio y cada capability del Blueprint se cruza contra el
  "ser" de la empresa en `ONTOLOGY.md`: ¿esta entidad/feature existe en el glosario y las
  `entidades_dominio`, o es un invento del diseño que el negocio no pidió? Lo que no ancla en la ontología
  es scope inventado → candidato a corte (o a subir a la ontología si el negocio SÍ lo quiere).

**Checklist de corte:**

| Pregunta | Si "sí" → |
|----------|-----------|
| ¿Hay features sin story/usuario que las pida ahora? | candidato a REDUCCIÓN |
| ¿Hay abstracciones/genericidad para casos que no existen aún? | candidato a REDUCCIÓN (YAGNI) |
| ¿Hay entidades de dominio que NO están en `ONTOLOGY.md`? | corte, o subir a ontología (decisión del humano) |
| ¿Hay dependencias externas nuevas que un patrón existente ya cubre? | corte (anti-bloat; absorber, no importar) |
| ¿Falta un caso/requisito que la ontología/SPEC SÍ exige y el Blueprint ignora? | candidato a **EXPANSIÓN** |

La Fase 1 es la única que puede empujar a **ambos** extremos: recorta lo sobrante (REDUCCIÓN) y detecta
lo que falta cubrir del contrato (EXPANSIÓN).

---

## 4. Fase 2 — Architecture

¿El diseño es correcto, acoplado lo justo y consistente con el Golden Path?

| Check | Qué buscar | Fuente |
|-------|-----------|--------|
| **Feature-first** | ¿Todo lo de una feature vive junto (`src/features/<nombre>/`)? ¿Lo cross-feature está en `shared/`? | `forge/CLAUDE.md` Arquitectura Feature-First |
| **Golden Path** | ¿Usa el stack default (Next.js 16 / Supabase / Zod / AI SDK) o hay override sin justificar en el Tech Spec? | `forge/CLAUDE.md` Golden Path |
| **Boundaries** | ¿Los límites de datos (forms, API routes, webhooks) validan con Zod? ¿Hay `any`? ¿Secrets fuera de `.env`? | Reglas de Código |
| **Acoplamiento** | ¿Módulos con responsabilidad única? ¿Dependencias en una sola dirección? ¿Archivos <500 líneas, funciones <50 previstos? | `ARCHITECTURE.md` |
| **Data model** | ¿El modelo de datos deriva de `entidades_dominio`? Si multi-tenant, ¿toda tabla lleva `organization_id` + RLS por membresía (R16)? | `MULTI_TENANCY.md` |
| **Estados y errores** | ¿El diseño contempla loading/empty/error, no solo el happy path? | — |

Severidad: un override del Golden Path sin justificación en el Tech Spec es `high`; un modelo de datos que
no ancla en la ontología es `high`; acoplamiento circular es `critical`.

---

## 5. Fase 3 — Security / Edge Cases

Seguridad **del diseño**, no del código (ese es `el-guardian`, pre-deploy sobre `src/**`). Aquí la
pregunta es: *¿el Blueprint contempla los requisitos de seguridad y los bordes?*

- **Contrato de empresa (Capa 0).** Cruzar `ONTOLOGY.md › requisitos_seguridad`: por cada requisito, ¿el
  Blueprint lo cubre? Un `requisito` con `severidad: critico` **no contemplado en el diseño** es un
  hallazgo `critical` automático — aunque el catálogo genérico no lo marque (es propio del negocio:
  regulación, dato sensible, residencia de datos).
- **Catálogo genérico.** Cruzar `la-herreria/references/threat-db.yaml` (OWASP 2025 + vibe-coding): por
  cada categoría relevante al diseño, ¿hay una defensa planeada? (authz por objeto, rate limiting,
  validación de entrada, manejo de secretos, verificación de firma en webhooks).
- **Multi-tenant (si aplica).** Si `tenant_model.multi_tenant: true`: ¿el diseño estampa `organization_id`
  + RLS por membresía + `WITH CHECK`, y contempla el modelo de amenazas cross-tenant T1–T9 de
  `MULTI_TENANCY.md`? Un diseño multi-tenant sin `WITH CHECK` es `critical`.
- **Edge cases.** Entradas hostiles/vacías/enormes, concurrencia, fallos parciales (¿qué pasa si el pago
  cobra pero el webhook no llega?), límites (paginación, cuotas), estados imposibles.

Un requisito de seguridad crítico no contemplado, o un vector cross-tenant sin defensa en el diseño,
empuja el veredicto hacia **EXPANSIÓN** (falta cubrir).

---

## 6. Fase 4 — Tests

¿La estrategia de verificación del Blueprint prueba **comportamiento**, no implementación, y cubre las
capas que R7 exige?

> **Contrato R7 — Three-Layer Verification** `[memory:CONSTRAINTS.md#R7]`: para que una feature llegue a
> `passing` corren Syntax (typecheck+lint) → Runtime (tests) → System (e2e happy path + visual diff vs
> brand.json) → (Layer 4, solo multi-tenant) test negativo cross-tenant sobre DB real. La Fase 4 verifica
> que el **plan de tests** del Blueprint sea coherente con esas capas.

| Check | Qué buscar |
|-------|-----------|
| **Comportamiento, no implementación** | ¿Los tests planeados asertan resultados observables (lo que el usuario ve), o detalles internos que se rompen al refactor? |
| **Cobertura de las 3 capas** | ¿Hay `verification_command` claro por feature? ¿Se contempla e2e del happy path? ¿Visual diff vs `brand.json`? |
| **Layer 4 (multi-tenant)** | Si la app es multi-tenant, ¿el plan incluye el test negativo cross-tenant (≥2 tenants, DB real, AP1 — no mocks)? Su ausencia es `high`. |
| **Casos negativos** | ¿Se prueban los edge cases y fallos de la Fase 3, o solo el happy path? |
| **AP1 — sin mocks donde importa** | ¿Los tests de datos corren contra DB real, no mocks que dan falso verde? |

Un plan que solo prueba el happy path, o que no define `verification_command`, es un hallazgo `high` que
suele empujar a **EXPANSIÓN** (falta plan de verificación).

---

## 7. Fase 5 — Trajectory

¿Este diseño nos deja **mejor o peor** para lo que viene? Es la fase de segunda derivada: no "¿funciona?"
sino "¿en qué estado deja el sistema y al equipo?".

| Check | Qué buscar |
|-------|-----------|
| **Deuda declarada** | ¿El Blueprint nombra explícitamente lo que difiere (SHOULD/COULD/WON'T), o esconde deuda como si fuera completo? |
| **Extensibilidad honesta** | ¿El siguiente paso del roadmap es fácil sobre este diseño, o este diseño lo bloquea? (sin caer en over-engineering de la Fase 1) |
| **Reversibilidad** | ¿Las decisiones costosas de deshacer (esquema de DB, contrato de API público, dependencia core) están justificadas y son las correctas AHORA? |
| **Consistencia con el sistema** | ¿Este diseño sigue los patrones ya establecidos en el repo, o introduce un patrón nuevo que fragmenta? |
| **Coste de mantenimiento** | ¿Cuánta superficie nueva (endpoints, tablas, deps) hay que mantener vs. el valor que entrega? |

La Fase 5 rara vez cambia el veredicto sola, pero afina el rationale: un MANTENER con deuda no declarada
se documenta como "MANTENER — pero registrar la deuda X antes de `/build`".

---

## 8. Síntesis — el veredicto único (EXPANSIÓN / MANTENER / REDUCCIÓN)

El coordinador agrega los hallazgos de las 5 fases y emite **uno** solo:

| Veredicto | Se emite cuando | Handoff |
|-----------|-----------------|---------|
| **EXPANSIÓN** | Hay ≥1 hallazgo `critical`/`high` de **cobertura faltante** — el diseño ignora un requisito de seguridad, un edge case del contrato, o una capa de tests que el negocio/ontología SÍ exigen | volver a `/plan` (la-herreria) a **ampliar** el Blueprint en los puntos citados |
| **MANTENER** | Sin faltantes críticos ni bloat significativo — el diseño está calibrado | proceder a `/build` (con las notas `low`/`medium` como mejoras opcionales) |
| **REDUCCIÓN** | Hay scope sobrante dominante (Fase 1): features especulativas, abstracciones prematuras, entidades fuera de la ontología, deps evitables | volver a `/plan` a **podar**, o marcar los cortes en `feature_list.json` (lo hace el humano/`el-evaluador`, no fragua-review) |

**Regla de desempate:** si coexisten faltantes críticos (EXPANSIÓN) y bloat (REDUCCIÓN), **gana
EXPANSIÓN** — un hueco de seguridad/cobertura es más caro que construir de más. Se documentan ambos, pero
el veredicto es EXPANSIÓN y el rationale nombra también los cortes sugeridos.

**Nunca** dos veredictos ni ninguno. Nunca redondear hacia MANTENER para "no bloquear" — un `critical`
sin cubrir es EXPANSIÓN aunque sea incómodo.

---

## 9. Output — `FRAGUA-REVIEW-<nombre>.md`

Estructura canónica del reporte (en `.claude/reports/`):

```markdown
# Fragua Review — <nombre>

**Blueprint revisado:** .claude/PRPs/BLUEPRINT-<nombre>.md
**Fecha:** YYYY-MM-DD · **Feature/scope:** <feature-id | proyecto> · **Self-review:** sí/no (AP3)

## Veredicto: EXPANSIÓN | MANTENER | REDUCCIÓN
<rationale en 2-3 líneas, citando las fases que lo motivan>

## Registry de failure modes
| id | fase | severidad | síntoma | dónde en el Blueprint | fix propuesto |
|----|------|-----------|---------|-----------------------|---------------|
| FR-01 | 3 · Security | critical | requisito_seguridad "cifrado en reposo" no contemplado | § Arquitectura de datos | agregar columna cifrada + KMS al diseño |
| FR-02 | 1 · Scope | medium | feature "export a PDF" sin story que la pida | § Alcance F3 | cortar de v1 (YAGNI) |

## Diagramas (ASCII)
<flujo/arquitectura propuestos, anotados con ⚠ en los puntos de riesgo del registry>

    [Cliente] ──► [API route] ──► [Supabase RLS] ──► [DB]
                      │
                      └─⚠ FR-01: sin validación Zod del body (Fase 2)

## Decisiones sin resolver
- [ ] ¿El export a PDF entra en v1 o se difiere? (FR-02)
- [ ] ¿Multi-tenant desde el día 1 o single-tenant con migración futura? (Fase 2)

## Hallazgos por fase
### Fase 1 — Nuclear Scope Challenge
### Fase 2 — Architecture
### Fase 3 — Security / Edge Cases
### Fase 4 — Tests
### Fase 5 — Trajectory

## Handoff
- EXPANSIÓN → /plan (ampliar los puntos FR-xx marcados)
- MANTENER → /build
- REDUCCIÓN → /plan (podar) o marcar cortes en feature_list.json (humano/el-evaluador)
```

**Diagramas ASCII, no Mermaid:** el reporte es texto plano legible en cualquier diff de git; los puntos
de riesgo del registry se anclan con `⚠ FR-xx` sobre el diagrama.

---

## 10. Citation grammar

| Tipo | Forma | Cuándo |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#R7]` | Fase 4 (contrato de las capas de verificación) |
| Constraint | `[memory:CONSTRAINTS.md#R4]` | protocolo del coordinador (thin, no invoca skills) |
| Constraint | `[memory:CONSTRAINTS.md#R16]` | Fase 2/3 cuando el diseño es multi-tenant |
| Lesson/Decision | `[memory:lessons#L-xxx]` / `[memory:decisions#D-xxx]` | cuando un hallazgo se apoya en memoria del proyecto |
| Docs | `[docs:libname]` | si un sub-agent invoca `find-docs` para validar una lib del diseño |

Todo hallazgo cita la **línea/sección del Blueprint** que lo motiva (no claims vacíos — R8 análogo).

---

## 11. Frontera con los parientes (no la cruces)

| Skill / comando | Valida | Momento | Toca código |
|-----------------|--------|---------|-------------|
| `el-crisol` (`/crisol`) | negocio/estrategia (Go/Caution/No-Go) | post-Blueprint | no |
| **`/fragua-review`** (esta rúbrica) | **diseño/arquitectura** (EXPANSIÓN/MANTENER/REDUCCIÓN) | post-Blueprint, **pre-`/build`** | **no (read-only)** |
| `el-guardian` | seguridad del **código escrito** (Codex, 4 modos + El Infiltrado) | pre-deploy, sobre `src/**` | no (audita código real) |
| `el-evaluador` | verificación funcional (R7 Three-Layer) + firma `passing` | post-build | no (audita, único writer de memory) |
| `la-herreria` (`/plan`) | genera el Blueprint | pre-todo | no (produce docs) |

`fragua-review` es el **guardián del diseño**: revisa el plan antes de que exista código. `el-guardian`
audita el código cuando ya existe. Uno mira el mapa; el otro, el territorio construido. No se solapan.

---

## Sources

- Doctrina anti-bloat: lección Vercel "-80% tools = +3× rendimiento" (docs/05, docs/06 §C) — C1 vive como
  referencia de `el-crisol`, no como skill nuevo.
- R7 Three-Layer Verification: `forge/CONSTRAINTS.md` (+ Layer 4 multi-tenant, `docs/06` §12 / M6).
- Modelo de amenazas cross-tenant: `.claude/references/MULTI_TENANCY.md` §4 (T1–T9).
- Catálogo de amenazas: `.claude/skills/la-herreria/references/threat-db.yaml`.
