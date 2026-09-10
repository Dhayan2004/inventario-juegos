<!--
  el-ontologo · sombrero SOURCE-READER (carga de métodos fuente, READ-ONLY)
  Lee el MÉTODO de Founder OS (negocio) y Estudio (marca) — nunca su código.
-->

# Sombrero — Source-Reader (carga de métodos fuente)

> **Rol:** preparar el levantamiento cargando (a) los **métodos** de negocio y marca que sirven de
> guion, y (b) —solo en modo `existente`— el material previo del cliente, ingiriéndolo a
> `ontology/evidence/` con marcas de confianza.
> **Cargado por:** `el-ontologo` (SKILL.md) en la fase `preparacion`.
> **Escribe en:** `ontology/evidence/` (material del cliente) y `session.md` (notas de retomada). NO
> escribe el draft de ontología (eso es de los sombreros entrevistadores).
> **Puede forkearse:** SÍ. En modo `existente` con mucho material, despáchalo a un sub-agente (este es
> el único trabajo aislable de `el-ontologo`; el resto es entrevista inline).

---

## Solo lectura sobre las fuentes (regla dura)

Founder OS y Estudio se leen como **metodología** — el guion de preguntas y la estructura del
artefacto. **Nunca** se modifican, se clonan ni se importa su código. Lo que viaja a Forge Enterprise
es el *método*, ya destilado en:

- **Negocio** → [`../references/fos-method.md`](../references/fos-method.md) (de Founder OS).
- **Marca** → [`../references/estudio-method.md`](../references/estudio-method.md) (de Estudio).

Estos dos archivos **ya contienen** el método destilado: en el flujo normal **no necesitas** ir a los
repos originales. Solo si el usuario pide profundizar más allá de lo destilado, los repos viven (SOLO
LECTURA) en `~/Developer/software/templates/founder-os` y `~/Developer/software/templates/estudio`.

## Trabajo en sesión nueva (modo `nuevo`)

1. Confirma que `fos-method.md` y `estudio-method.md` están disponibles (son parte del skill).
2. Deja en `session.md › ## Notas de retomada` una línea: "Métodos cargados: negocio (FOS) + marca (Estudio)."
3. Devuelve el control al coordinador para arrancar la fase `negocio`. No preguntes nada al usuario.

## Trabajo en modo `existente` (empresa con material previo)

Cuando el cliente ya tiene brief, deck, transcripciones, web, docs:

1. **Ingerir** el material a `ontology/evidence/` (copia o resumen citable, según tamaño).
2. **Pre-poblar** afirmaciones candidatas del frontmatter con **marcas de confianza** (disciplina
   anti-alucinación heredada del Explorador de `el-entrevistador`):
   - `[confirmado-por-fuente: archivo#ancla]` — el material lo dice explícitamente.
   - `[inferido]` — deducción razonable, **a confirmar** con el usuario en la entrevista.
   - `[ausente]` — no hay material; la entrevista debe levantarlo.
3. **No confirmes nada por tu cuenta.** Lo `[inferido]` queda como rama abierta para que el sombrero
   de negocio/marca lo valide. La entrevista posterior **salta** lo `[confirmado-por-fuente]` (lo da
   por confirmado salvo corrección) y se concentra en `[inferido]` / `[ausente]`.
4. Registra en `session.md` qué ranuras quedaron pre-pobladas y con qué nivel de confianza.

> Regla de oro del modo existente: el material **acelera** el levantamiento, no lo reemplaza. Toda
> afirmación enforce-able termina confirmada por el usuario o citada a evidencia — nunca asumida.
