# Método de marca — destilado de Estudio (lente MARCA)

> El **guion de marca** del perfil `ontologia` (ranura s5) se deriva de **Estudio** (el "cerebro de un
> departamento de marketing inteligente" de moscaOS / Joaco Moscardi). Este archivo **destila el
> método** — las 13 secciones de `BRAND.md` relevantes a la ontología + los 7 pasos del código
> simbólico de Klaric/Rapaille — para que el sombrero `brand-interviewer` lo aplique **sin leer el repo
> original**. Estudio es solo-lectura (`~/Developer/software/templates/estudio`); aquí viaja el
> *método*, no el código.
>
> **Fuente:** `docs/04` (investigación Estudio). **Origen:** MoscaOS / Klaric.

---

## Qué toma `el-ontologo` de Estudio (y qué NO)

Estudio tiene dos metodologías acopladas: (A) el **discovery de marca de 13 secciones** (`BRAND.md`) y
(B) el **ADN persuasivo Klaric/Rapaille** (código simbólico). La ranura s5 toma de ambas **solo la
capa ontológica** —el significado y la identidad—, no el arsenal de marketing.

| De Estudio | ¿A la ontología (s5)? |
|------------|------------------------|
| `BRAND.md` §1 Identidad (propósito/manifiesto, North Star) | ya cubierto por s1 (negocio) — no duplicar |
| `BRAND.md` §2 Arquetipos y personalidad | ✅ `marca.arquetipo_primario/secundario` |
| `BRAND.md` §9 Tono de voz · §10 ICPs (frases textuales) | ✅ lenguaje propio (glosario) + insumo para `voice.json` |
| `codigo-simbolico` (Klaric) | ✅ `marca.codigo_simbolico` (opcional, profundo) |
| §3–8, §11–13 (logo, paleta, tipografía, canales, anti-slop) | ❌ es **implementación** → `brand.json` (add-ui-kit), no ontología |
| Las 41 skills de marketing, 63 CLI tools, Nightly Creative Run | ❌ dominio marketing, fuera de la capa ontológica |

> La ontología captura **qué significa** la marca; `add-ui-kit`/`impeccable` capturan **cómo se ve y
> suena** (tokens, paleta, tipografía). El Brand DNA es la sub-capa de implementación (`ONTOLOGY_SCHEMA` §4).

---

## A. Arquetipo (S5.Q1)

1 arquetipo Jung **dominante** + 1 secundario (5 rasgos, "brand-as-person": cómo habla/viste/lee). La
recomendación se deriva del **propósito de s1** y se valida con el usuario.

> **Coherencia interna (gate de auto-auditoría, de `brand-guardian --self-check`):** el arquetipo debe
> ser consistente con el propósito y el tono. Arquetipo "El Forajido" + propósito "máxima confianza
> institucional" = contradicción → llámala antes de cargar. El sistema **audita su propia ontología**.

---

## B. Código simbólico — los 7 pasos (S5.Q2, opcional y profundo)

**Definición operativa (Klaric):** *"el significado subconsciente que creamos frente a una categoría o
concepto dentro de una cultura. No es lo que el producto ES; es lo que SIGNIFICA."* Es perfilado de
**significado cultural/de categoría**, NO de personalidad del fundador (eso es W3, no entregado —
`ONTOLOGY_SCHEMA` §5).

Los 7 pasos (de la skill `codigo-simbolico`):
1. **Encuadrar** categoría + cultura.
2. Recoger **lo que la gente DICE** (capa consciente).
3. Excavar **3 capas de beneficio**: funcional → emocional → instintivo.
4. Encontrar la **impronta** (el primer momento emocional, individual o colectivo, que fijó el significado).
5. Identificar el **arquetipo cultural** (rueda de 12), validado contra `marca.arquetipo_primario`.
6. Destilar la **metáfora**.
7. Componer el **código** → `marca.codigo_simbolico.{metafora, arquetipo_cultural}`.

### Tres convicciones no-negociables (de `klaric.md`)
1. **El código se DESCUBRE, no se proyecta** — sale de lo que la cultura/cliente dice y siente; el agente nunca lo inventa.
2. **El miedo se reduce, no se vende.**
3. **El reptil es metáfora, no biología.**

> **Validación humana obligatoria:** el código simbólico se valida con el usuario **antes** de cargarse
> al frontmatter — nunca automáticamente. Si el cliente no quiere ir a esta profundidad,
> `marca.codigo_simbolico.estado: "no_levantado"` es válido y **no bloquea** la emisión. Mejor un código
> vacío honesto que uno proyectado.

---

## C. Lenguaje propio (S5.Q3)

De `BRAND.md` §9 (vocabulario USAR/EVITAR) + §10 (frases textuales que dice el ICP). Es el **lenguaje
propio de la empresa** → narrativa `## Glosario / lenguaje propio de la empresa`, mantenido por el
Glosarista. Es la **capa padre** del `CONTEXT.md` funcional (`ONTOLOGY_SCHEMA` §6). Las "frases
textuales que dice el cliente" son críticas: alimentan el copy y el `voice.json` aguas abajo.

---

## Por qué este lente va DESPUÉS del de negocio

`novolabs-discovery` (la skill de Estudio que importa el método Novolabs) **duplica** la validación de
problema/ICP que Founder OS ya hace nativa. Resolución canónica de Forge Enterprise: Founder OS es la
**fuente** de esa validación; el lente de marca la **consume** (la cita del frontmatter), no la
re-levanta. Por eso s5 corre después de s1–s4 y empieza leyendo lo ya capturado. Ver
[`profile-ontologia.md`](profile-ontologia.md) §"Orden de lente".
