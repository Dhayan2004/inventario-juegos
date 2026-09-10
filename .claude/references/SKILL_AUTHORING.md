# Skill Authoring Standard de Forge Enterprise (S4)

> **Qué es esto.** El **estándar canónico de autoría de skills** de Forge Enterprise: cómo se escribe,
> se poda y se registra un skill para que sea *predecible* (dispara cuando debe, ejecuta lo que dice,
> no infla el contexto). Sintetiza el meta-skill `writing-great-skills` de Matt Pocock
> [web:github.com](https://github.com/mattpocock/skills), la **plantilla de secciones fija** de las
> cybersec skills de comunidad ([`docs:mattpocock-skills`] + `docs/05` §7.2) y la disciplina de
> **progressive disclosure** que Forja ya practica de forma ejemplar. Es a los skills lo que
> `BRAND_DNA_SCHEMA.md` es a la UI y `ONTOLOGY_SCHEMA.md` es a la empresa: un **contrato de generación**,
> no un tutorial.
>
> **Doctrina rectora:** la lección Vercel — *"−80% tools = +3× rendimiento"* — a nivel de skill. Cada
> token de frontmatter se paga **en cada turno** como context load; cada línea del cuerpo se paga cuando
> la skill se activa. Autor de un skill = **presupuesto de tokens**, no descripción libre. Fuente de
> diseño: `docs/05` §1 (Matt Pocock) + §7 (cybersec skills, progressive disclosure de ~30 tokens).

- **Versión:** v0.1.0 (2026-06-30, S4 · Estándar de autoría de skills)
- **Lo enforza:** `skill-creator` (scaffolds contra este estándar) · `el-evaluador` (lo audita al firmar
  un skill, §6–§7) · el registro en `skills.md` (`[memory:CONSTRAINTS.md#R6]`, lo exige antes de dispatch).
- **Regla de enforcement:** `[memory:CONSTRAINTS.md#R6]` (registry/router) · AP3 (el que genera no se
  auto-evalúa) · AP7 (routing/knowledge fuera del archivo — mismo dogma aplicado al SKILL.md).

---

## 1. El eje de invocación — model-invoked vs user-invoked

Todo skill vive en **uno de dos ejes de invocación** (Matt Pocock). Elegir el eje mal es el primer
error de autoría: paga context load una skill que nadie dispara solo, o hace invisible una que el agente
necesitaba alcanzar.

| Eje | Mecánica (frontmatter) | Coste | Cuándo |
|-----|------------------------|-------|--------|
| **Model-invoked** | tiene `description` (el agente la lee cada turno) | **context load** permanente | el agente debe dispararlo solo, o **otro skill debe alcanzarlo** |
| **User-invoked** | `disable-model-invocation: true` (la `description` pasa a ser humana) | **cero context load**, pero **cognitive load** (el humano es el índice) | solo se dispara a mano (vía comando `/x`) |

**La regla dura (Matt, verbatim):** *"user-invoked skills may invoke model-invoked skills, but never
another user-invoked one"* [web:github.com](https://github.com/mattpocock/skills). Un user-invoked puede
delegar hacia abajo (a model-invoked), nunca lateral (a otro user-invoked) — si lo hace, el humano deja
de ser el índice y la cadena se vuelve inauditable.

**El router skill = el `skills.md` registry (R6).** Cuando los user-invoked se multiplican, Matt los cura
con un *router skill*: un user-invoked que nombra a los demás y cuándo usarlos. En Forge Enterprise ese
router **ya existe** y es `[memory:CONSTRAINTS.md#R6]`: el registry `.claude/memory/skills.md` que el
dispatcher valida antes de invocar cualquier skill (nombre → tier → usar-cuándo → requires → fallback).
No se inventa un router paralelo: `skills.md` **es** el router canónico. Registrar un skill nuevo ahí es
parte de darlo por terminado (§8).

---

## 2. La `description` — una rama-gatillo, no un tesauro

La `description` de un skill model-invoked hace **dos trabajos** (Matt): decir qué es el skill y **listar
las ramas que deben dispararlo**. Y se poda **más fuerte que el cuerpo**, porque se paga en cada turno.

**Las tres reglas de poda de la description:**

1. **Front-load el leading word** — la primera palabra es donde la description hace su trabajo de
   invocación (ver §5). No la desperdicies en relleno ("Este skill sirve para…").
2. **One trigger per branch** — un gatillo por rama *genuina*. Sinónimos que renombran la **misma** rama
   son duplicación que infla context load. *"optimiza este skill / mejora el skill / self-improve / pulí
   la skill"* son **una** rama escrita cuatro veces → colapsar a una. Es el error documentado de las
   descriptions de Forge Pro (`docs/05` §1.3.2): triggers-heavy con ~12 sinónimos de una sola rama.
3. **Cut identity that's already in the body** — la description son *triggers + una cláusula de reach*
   ("cuando otro skill necesita X"), nada más. La identidad del skill vive en el cuerpo, no repetida en
   el frontmatter.

**Techo del frontmatter (~30 tokens para escanear).** El agente decide cargar el cuerpo de una skill
leyendo **solo su frontmatter** — el mismo mecanismo por el que un catálogo grande sigue siendo barato
(`docs/05` §7.2.2: ~30 tokens/skill para escanear, ~500–2000 para cargar). Trata la `description` como
un **presupuesto de descubrimiento**: densa en keywords (para *recall* de invocación), cero relleno. En
Forge Enterprise mantenemos el español y el frontmatter rico de Forja (`name` · `description` plegada con
`>` · `tier` · `requires` · `fallback` · `dependencies`; `context: fork` opcional) — pero cada campo se
gana su lugar y **ningún campo es no-op** (§7). No copiamos el minimalismo de 3 campos de Matt: los
campos operativos de Forja codifican contratos reales; sí copiamos su disciplina de poda.

> **Densidad ≠ sinónimos.** "Denso en keywords" significa cubrir *ramas distintas* con las palabras que
> el humano/agente usaría para cada una, no repetir la misma rama con cuatro verbos. La densidad se mide
> en cobertura de ramas, no en cantidad de gatillos.

---

## 3. Jerarquía de información / progressive disclosure

Matt define una **escalera de 3 peldaños** por qué tan inmediato es el material para el agente:

1. **In-skill step** — acción ordenada en `SKILL.md` (tier primario). Cada step termina en un
   **completion criterion checkable** y, donde importa, *exhaustive* ("cada tabla modificada contabilizada",
   no "produce una lista de cambios") — un criterio vago invita a **premature completion** (§6).
2. **In-skill reference** — regla/hecho consultado on-demand dentro del `SKILL.md`. Puede ser plano.
3. **External reference** — material empujado fuera del `SKILL.md` a `references/`, `prompts/`,
   `templates/`, alcanzado por un **context pointer**. El *wording del pointer* (no su target) decide
   cuándo y cuán confiablemente el agente lo alcanza.

**Progressive disclosure** = mover material hacia abajo en la escalera para que el tope quede legible.
El test más limpio es por **branch**: *inline lo que TODA rama necesita; empuja detrás de un pointer lo
que solo ALGUNAS ramas alcanzan* (`docs/05` §1.3.4).

**Techo del `SKILL.md`: cuerpo de 500–2000 tokens** (`docs/05` §7.2.2). Un SKILL.md que crece más allá de
eso sin razón es **sprawl** (§6): el detalle debe estar disclosed. Forja **ya es ejemplar** aquí — sus
carpetas `prompts/ references/ routes/ templates/ tests/` *son* progressive disclosure implementada:
`add-payments/SKILL.md` enlaza `prompts/decision-tree.md` + `references/stripe-patterns.md` +
`templates/stripe/**`; `la-herreria` tiene 21 references + 5 routes detrás de un SKILL.md-índice. Este es
el modelo a calcar; el anti-modelo es Forge Pro (`add-ui-kit` = 1337 LOC = sprawl, `docs/05` §1.3.4).
Patrón de enlace canónico del repo: `` Detalle completo en [`prompts/x.md`](prompts/x.md). ``

`context: fork` (opcional, del Recurso 4) es la disclosure llevada al extremo: 0 tokens en el orquestador
hasta que el fork devuelve su resumen. Lo llevan los skills que corren aislados (`el-evaluador`,
`el-guardian`, `el-migrador`, `project-auditor`); los que grillan al humano (`el-entrevistador`,
`el-ontologo`) **NO** lo llevan a propósito (forkear rompe el grill-me — anti-bloat = memoria, no fork).

---

## 4. La plantilla de secciones fija (cybersec skills + Forja)

De la disciplina de secciones de las cybersec skills (`docs/05` §7.2.1) fusionada con las secciones
canónicas de Forja. **Orden fijo** — un lector (humano o `el-evaluador`) sabe dónde está cada cosa:

| # | Sección | Qué contiene | Peldaño |
|---|---------|--------------|---------|
| 1 | **When-to-Use / Activación** | tabla `Cuándo → Modo/Quién` — cuándo dispara y qué NO cubre | in-skill step |
| 2 | **Prerequisites / PREFLIGHT** | halt-lines: qué debe existir antes; sin ello, halt sin generar | in-skill step |
| 3 | **Workflow** | pasos numerados **con comandos reales** (no prosa vaga), cada uno con completion criterion | in-skill step |
| 4 | **Verification** | cómo se comprueba el output (R7 Three-Layer donde aplica; el gate del skill si no es código) | in-skill step |
| 5 | **Refusals** | lista `❌` de lo que el skill NUNCA hace (fronteras duras) | in-skill reference |
| 6 | **Tool filter** | tools permitidas + explícitamente denegadas (superficie mínima) | in-skill reference |
| 7 | **Citations** | qué se cita y con qué gramática (§5.3) | in-skill reference |
| 8 | **Integraciones** | upstream/downstream: qué skills lo invocan, a cuáles hace handoff | in-skill reference |

Regla de contribución heredada: `name` en **kebab-case (1–64 chars)**, metafórico si es core (§5);
instrucciones **accionables con comandos y nombres de herramientas reales**; `description` con keywords
para discovery. Los skills con MODOS/sub-análisis (patrón `el-crisol`, `el-cartografo`: GENERAR/MANTENER/
SERVIR) declaran los modos en una tabla de Activación y ramifican el Workflow por modo — cada modo es una
*branch* para el test de disclosure del §3.

---

## 5. Leading words — metáfora metalúrgica + ontología del cliente

Un **leading word** es un concepto compacto que ya vive en el pretraining del modelo y con el que el
agente *piensa mientras corre el skill* (Matt: *lesson*, *red*, *tight*, *tracer bullets*). Repetido,
acumula una definición distribuida y ancla toda una región de comportamiento en pocos tokens. Sirve dos
veces: en el **cuerpo** ancla *ejecución*; en la **description** ancla *invocación* (cuando la misma
palabra vive en tus prompts/docs/código, el agente liga ese lenguaje al skill y lo dispara más confiable).

**Dos fuentes de leading words en Forge Enterprise:**

1. **La metáfora metalúrgica (marca).** `la-forja`, `la-herreria`, `el-crisol`, `el-tajo`, `el-golpe`,
   `el-evaluador`, `el-guardian`, `el-migrador`, `el-cartografo` son leading words de marca que anclan
   comportamiento. Esto es exactamente lo que Matt prescribe y es un activo diferenciador: **doblarlo, no
   abandonarlo** (`docs/05` §1.3.5). Un skill core nuevo elige un nombre metafórico coherente.
2. **La ontología del cliente (vocabulario).** El `ONTOLOGY.md` levantado de cada empresa (Fase −1) es
   una mina de leading words *específicos del cliente*: los skills generados deben usar el vocabulario del
   `glosario`/`entidades_dominio` para anclar invocación y ejecución alrededor de cómo *esa* empresa
   entiende su mundo — análogo a cómo `brand.json` se inyecta en cada UI. Citación: `[ontology: Entidad]`.

Reemplazar un leading word débil por uno fuerte es una técnica de poda (§6, no-op hunt): *be thorough* →
*relentless*.

### 5.3 Citation grammar (la que un skill usa)

| Tipo | Forma | Fuente |
|------|-------|--------|
| Constraint | `[memory:CONSTRAINTS.md#Rxx]` | regla del harness |
| Lesson / Error / Decision | `[memory:lessons#L-00x]` · `[memory:errors#E-00x]` · `[memory:decisions#D-0xx]` | memory store |
| Docs externos | `[docs:lib]` o `[docs:lib@version]` | vía `find-docs` (R13) |
| Web | `[web:dominio.com](url)` + sección `## Sources` | claim externo (R8) |
| Ontología | `[ontology: Entidad]` | vocabulario del cliente |

Sin `## Sources` cuando hay claims externos → FAIL (lo captura `el-evaluador`, R8).

---

## 6. Pruning routine (de Matt) — la disciplina de mantenimiento

El pruning es minimalismo a nivel de *skill* (lo que Ponytail es a nivel de código). **Tres reglas**
(`docs/05` §1.3.7), aplicables como sub-rutina de refinamiento de un skill:

1. **Single source of truth** — cada significado en **un solo lugar** autoritativo. Si un hecho vive en
   `references/x.md`, el SKILL.md lo *apunta*, no lo *copia*. La citation grammar (`[memory:...]`) ya
   implementa esto: una regla se cita, no se re-explica.
2. **Relevance check** — línea por línea: ¿esta línea cambia lo que el agente hace? Si no, es candidata a
   borrar.
3. **No-op hunt** — frase por frase: una frase que el modelo **ya obedece por default** (ej. "sé claro",
   "escribe buen código") es no-op. La regla de Matt, verbatim: *"cuando una frase falla el test, borra la
   frase entera en vez de recortarle palabras. Sé agresivo."* No se recortan palabras: se borra la frase.

Los **failure modes nombrados** que el pruning combate (Matt), y que `el-evaluador` audita (§7):

| Modo de fallo | Definición | Defensa |
|---------------|------------|---------|
| **Premature completion** | terminar un step antes de estar genuinamente hecho | completion criterion checkable + exhaustive (§3) |
| **Duplication** | el mismo significado en más de un lugar | single source of truth · colapsar a un leading word |
| **Sediment** | capas viejas que se acumulan porque agregar se siente seguro y quitar arriesgado | disciplina de pruning |
| **Sprawl** | skill simplemente demasiado largo, aun si cada línea es viva | la escalera: disclose detrás de pointers; techo 500–2000 tokens |
| **No-op** | línea que el modelo ya obedece por default | test de comportamiento vs default; borrar o reemplazar leading word débil por fuerte |

---

## 7. Failure modes que `el-evaluador` audita al firmar/registrar un skill

Cuando `el-evaluador` firma "PASS" a un skill nuevo o lo registra en `skills.md`, corre esta **rúbrica**
(complementa el Anti-Slop Gate de UI; no lo duplica — aquel audita componentes, esta audita skills):

1. **Description ambigua** — no front-load leading word, o ninguna rama-gatillo clara → el agente no sabe
   cuándo dispararla. (§2)
2. **Frontmatter sprawl** — description con sinónimos de una misma rama, o campos no-op → context load
   inflado. Colapsar a one-trigger-per-branch. (§2, §6)
3. **Dup de single-source** — el SKILL.md re-explica una regla/hecho que ya vive en `references/` o en
   memory → citar, no copiar. (§6.1)
4. **No-op sentences** — frases que el modelo ya obedece por default → borrar (frase entera). (§6.3)
5. **Sprawl del cuerpo** — SKILL.md fuera del techo 500–2000 tokens sin disclosure → empujar detalle a
   `references/`/`prompts/`. (§3)
6. **Self-eval (AP3)** — el skill genera **y** se auto-valida, o su autor lo firma → violación de la
   frontera Implementer ≠ Reviewer. Un skill generador (ej. `impeccable`, que **genera** UI) nunca es su
   propio evaluador; `el-evaluador` (que **critica/audita**, no genera) es quien firma. AP3.
7. **Registro faltante (R6)** — el skill no está en `skills.md` con tier/usar-cuándo/requires/fallback →
   el dispatcher no lo puede validar antes de invocarlo. No existe hasta que está registrado.

Verdicto: ≥1 crítico (self-eval, registro faltante, description sin gatillo) → NEEDS_FIX; solo sprawl/
no-op menor → PASS con warnings de poda.

---

## 8. Cómo se enforza (el ciclo completo)

```
skill-creator  →  scaffolds un SKILL.md contra ESTE estándar
                  (secciones fijas §4 + frontmatter §2 + carpetas de disclosure §3)
       ↓
el-evaluador   →  audita la rúbrica de failure modes (§7) al firmar PASS   ← AP3: no lo firma su autor
       ↓
skills.md (R6) →  registro obligatorio (tier · usar-cuándo · requires · fallback)  ← el router canónico (§1)
       ↓
dispatcher     →  valida el nombre contra skills.md antes de invocar (R6); si no existe → fallback o halt
```

Esto cierra dos observaciones de `docs/05` §1:
- **Descriptions de Forge Pro triggers-heavy** (sinónimos de una rama) → §2 regla 2 (one-trigger-per-branch)
  enforzada por `el-evaluador` (§7.2).
- **`skill-creator` de Forja con frontmatter enorme** (~30 líneas = sprawl) → §2 techo de frontmatter +
  §7.2 auditado. `skill-creator` **scaffolds contra este estándar**, no contra su propio historial.

---

## 9. El contrato en una frase

Un skill de Forge se autoriza como se poda un tool set: **una rama-gatillo por description, un leading
word que ancle el comportamiento, el detalle disclosed detrás de pointers, cero no-ops, y el nombre en
`skills.md`** — porque cada token de frontmatter se paga en cada turno y cada línea del cuerpo cuando se
activa. Es la lección Vercel (*−80% = +3×*) aplicada a la unidad más pequeña del harness: el skill.

## Sources

- [web:github.com](https://github.com/mattpocock/skills) — `writing-great-skills` + `GLOSSARY.md`: eje
  model/user-invoked, router skill, description de 1 trigger/branch, jerarquía de información, leading
  words, failure modes, pruning. Licencia MIT. (`docs/05` §1)
- [web:raw.githubusercontent.com](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/writing-great-skills/SKILL.md)
  — meta-skill verbatim (reglas de poda de description, when-to-split, no-op hunt "delete the whole sentence").
- `docs/05` §7.2 — plantilla de secciones fija de las cybersec skills (`[docs:mattpocock-skills]`) +
  progressive disclosure de ~30 tokens (frontmatter) / 500–2000 (cuerpo). Vetting de comunidad: solo se
  copia el **patrón** de arquitectura, nunca el contenido (subconjunto curado, no mirror).
- Patrones internos calcados: `el-crisol` (MODOS) · `el-cartografo` + `verificar-ci` (skill core reciente:
  PREFLIGHT + modos + refusals + tool filter + integraciones) · `el-evaluador` (Anti-Slop Gate + AP3,
  este estándar lo complementa para skills) · `impeccable` (genera; frontera AP3 vs el-evaluador que audita).
- Cross-refs de doctrina: `docs/05` §2 (Ponytail — pruning es su análogo a nivel de skill) · §4
  (`context: fork` — disclosure al extremo).
