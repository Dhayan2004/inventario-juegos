---
description: "Gobernanza de equipo GitHub-native: CODEOWNERS + branch protection + sync feature_list/plan → Issues (espejo de UNA vía, R18) (el-capataz)."
---

# /capataz

Lee y ejecuta `.claude/skills/el-capataz/SKILL.md`.

`el-capataz` es la cara **GitHub-native** del pilar ② (equipos/gestión): proyecta el estado real del
build (`feature_list.json` + `plan.json` + el roster `.forja/team.json`) a la gobernanza del repo —
CODEOWNERS, branch protection sobre `main` (required checks = los jobs de A2), PR/Issue templates y
sync de Issues. Reusa los roles M6 (`owner`/`admin`/`member`) como vocabulario único, sin inventar un
segundo modelo de roles.

**Frontera R18 — GitHub es un ESPEJO de una sola vía:** `[memory:CONSTRAINTS.md#R18]`. La autoridad
sobre las transiciones de build sigue siendo `feature_list.json` + los hooks (R1 + AP8 + R7). GitHub es
proyección read-only: cerrar un Issue, mergear un PR o mover una card **NUNCA** marca una feature
`passing` ni muta `feature_list.json`. `el-capataz` **sólo lee y proyecta** — no escribe
`feature_list.json` ni `.claude/memory/**` (R5).

**Modos:**
- **INIT** — setea branch protection idempotente sobre `main` (`gh api`, leer estado → aplicar diff) y
  regenera `.github/CODEOWNERS` desde el roster + `modules[].area` del plano. Required checks = los `name:`
  de los workflows de A2; `require_code_owner_reviews` sólo con ≥2 colaboradores.
- **SYNC** — proyecta features (y opcionalmente stories) a Issues de una sola vía: un Issue por feature
  (`[<id>] <behavior>` + labels de estado), idempotente por la marca `<!-- forge:feature=<id> -->`
  (buscar→actualizar, no duplicar); cierra el Issue cuando la feature está `passing`.
- **STATUS** — reporta (read-only) el delta entre la verdad del JSON y el espejo en GitHub: protección
  vigente vs. requerida, CODEOWNERS desfasado, Issues huérfanos o sin sincronizar.

**PREFLIGHT (degradación segura, mismo patrón que `verificar-ci`):** sin `gh` / sin auth (`gh auth status`)
/ sin remote / sin `ci.yml` ⇒ `el-capataz` no puede tocar la gobernanza remota → **advierte** y documenta
los pasos manuales, **NO falla el harness**. El gobierno local (R1 / AP8 / hooks) sigue vigente.

**Output esperado:** `.github/CODEOWNERS` (regenerado) · branch protection aplicada sobre `main` ·
Issues sincronizados (una vía) · `.forja/team.json` (creado/leído como roster) · reporte de delta (STATUS).
