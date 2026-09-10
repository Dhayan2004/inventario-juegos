# Migraciones de esquema de `ONTOLOGY.md` (S3)

> Versionado de esquema del artefacto ontológico **sin pérdida de datos**. Cuando el esquema
> (`references/ONTOLOGY_SCHEMA.md`) evoluciona —una sección o campo nuevo— las ontologías que un
> cliente **ya llenó** necesitan actualizarse sin que nadie reescriba a mano ni pise sus datos.
> Este directorio es el equivalente de las migraciones de base de datos, pero sobre `ONTOLOGY.md`.
>
> Es el port a Forge del pipeline `apply-brand-migrations.py` de Estudio (`docs/04`), gobernado por
> `ontology_version`. El runner vive en [`scripts/apply-ontology-migrations.mjs`](../../scripts/apply-ontology-migrations.mjs)
> (Node zero-dep).

## Cómo se corre

Desde la **raíz de un proyecto** con `ONTOLOGY.md` emitido (`discovery_completed: true`):

```bash
node scripts/apply-ontology-migrations.mjs              # dry-run (default — NADA se escribe)
node scripts/apply-ontology-migrations.mjs --apply      # aplica las pendientes
make ontology-migrate                                   # atajo (= dry-run)
make ontology-migrate APPLY=1                            # atajo (= --apply)
```

`update-forja` lo invoca automáticamente tras sincronizar el template (FASE 5b), así que las
migraciones nuevas se propagan solas al actualizar un proyecto.

## Garantías

- **Dry-run por default.** Sin `--apply` no se escribe una sola línea; solo se reporta qué haría.
- **Idempotencia.** Cada migración declara un `check_line`: si esa cadena ya está en `ONTOLOGY.md`,
  se marca aplicada y se salta. Correr `--apply` dos veces no duplica nada.
- **Tracking (ledger).** Las migraciones aplicadas se registran en `.forja/ontology.migrations`
  (`migration_id TIMESTAMP`). Ese archivo **se versiona** (el equipo comparte el estado aplicado).
- **Backup.** Antes de la primera escritura de una corrida `--apply`, se copia `ONTOLOGY.md` a
  `.forja/ontology-backups/<timestamp>/` (efímero, gitignored). El rollback nunca depende solo de git.
- **Gobierno de versión.** Si la migración declara `ontology_version`, el runner sella ese valor en
  el frontmatter del `ONTOLOGY.md` al aplicarla (§9 de `ONTOLOGY_SCHEMA.md`).
- **Nunca toca datos.** Solo INYECTA estructura nueva (secciones/anclas). El contenido que el cliente
  ya escribió no se modifica ni se borra.

## Formato de una migración

Un archivo `NNNN_slug.md` con frontmatter YAML plano + cuerpo markdown. `NNNN` es un id ordenable
(`0001`, `0002`, …). Dos tipos:

### Tipo `ontology_md` — inyecta estructura en `ONTOLOGY.md`

| Campo | Obligatorio | Qué es |
|-------|:---:|--------|
| `migration_id` | sí | id ordenable, ej. `"0001"` |
| `title` | sí | descripción corta de una línea |
| `type` | sí | `"ontology_md"` |
| `anchor` | sí | línea EXACTA de `ONTOLOGY.md` donde anclar (ej. un heading `## ...`) |
| `position` | no | `"after"` (default) o `"before"` respecto del anchor |
| `check_line` | sí | cadena que, si ya existe, marca la migración como aplicada (idempotencia) |
| `ontology_version` | no | versión que esta migración deja sellada en el frontmatter |

El **cuerpo** del archivo (después del frontmatter) es el bloque markdown que se inyecta.

### Tipo `create_path` — crea estructura de directorios

| Campo | Obligatorio | Qué es |
|-------|:---:|--------|
| `migration_id`, `title`, `ontology_version` | como arriba | |
| `type` | sí | `"create_path"` |
| `paths` | sí | lista separada por comas de directorios a crear (relativos a la raíz) |

El **cuerpo** (opcional) se escribe como `README.md` en el directorio padre del primer path.

## Ejemplo (solo referencia — NO es una migración viva)

Este directorio ships **sin migraciones vivas**: el esquema está en `0.1` y todavía no ha evolucionado,
así que toda ontología `0.1` está al día (el runner reporta "al día"). La primera migración real se
escribe el día que `ONTOLOGY_SCHEMA.md` suba de versión. Así se vería:

```markdown
---
migration_id: "0001"
title: "Agrega '## Antipatrones' — lo que la empresa NO es (v0.1 → v0.2)"
type: "ontology_md"
anchor: "## Decisiones y supuestos abiertos"
position: "before"
check_line: "## Antipatrones"
ontology_version: "0.2"
---

## Antipatrones / lo que la empresa NO es

<!--
  El "espacio negativo" de la ontología: qué arquetipos, promesas o categorías la empresa
  RECHAZA. Disciplina anti-proyección (Klaric): definir lo que NO se es afila lo que sí se es.
-->
- **NO somos:** <categoría/arquetipo que se confunde con nosotros> · **Por qué:** <razón>
```

Migraciones vivas (si existieran) irían como `NNNN_slug.md` en este mismo directorio, junto a este
README. El runner las lee del top-level y salta este `README.md`.
