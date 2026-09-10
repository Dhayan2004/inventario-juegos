---
name: verificar-ci
description: >
  Valida una feature contra el resultado REAL de CI (no contra la narrativa del
  agente). Ejecuta `gh pr checks`/`gh run view`/`gh api check-runs` y devuelve un
  boolean verificable: una feature NO pasa a `passing` mientras el check-run del
  commit HEAD no sea `conclusion == success`. El `conclusion` lo emite GitHub —
  el agente no puede fabricarlo. Es la encarnación de AP5/AP8 en CI: el árbitro
  independiente que cierra el self-eval estructural. Produce el objeto `ci_run`
  ({run_id, sha, conclusion, url}) como evidencia citable `[ci:run#<id>]` para que
  `el-evaluador` lo registre en `feature_list.json` al marcar `passing`.
tier: core
requires: GitHub CLI (`gh`) instalado y autenticado (`gh auth status`) + repo con remote en GitHub + workflows ci.yml/security.yml presentes
fallback: si no hay `gh`/remote/CI configurado, degradar a verificación local (R7) y advertir que AP8 no puede enforzarse sin CI
dependencies: []
---

# verificar-ci

> *"El agente no marca `done` por su palabra: CI lo demuestra."*
> — A2 (entrega validada por CI)

Skill de verificación. Mueve el árbitro del `verification_command` de la máquina del agente (self-eval
estructural) a un **runner remoto independiente** cuyo veredicto el agente no puede falsificar. Es la
extensión de AP3 (el generador no valida) del agente al runner. Regla dura: `[memory:CONSTRAINTS.md#AP8]`.

## PREFLIGHT halt

```
1. ¿`gh` instalado? `command -v gh`. Si no → fallback: verificación local (R7) + advertir AP8 no enforzable.
2. ¿`gh auth status` OK? Si no → halt: "Autenticá gh (`gh auth login`) para leer check-runs."
3. ¿Repo con remote GitHub? `git remote get-url origin`. Si no → fallback local + advertir.
4. ¿Existe .github/workflows/ci.yml? Si no → fallback: sin CI, AP8 no aplica (degradación, comportamiento legacy).
```

## El flujo determinista (post push / PR)

```
1. DISPARAR Y ESPERAR (bloquea hasta que los required checks terminen):
     gh pr checks "$PR" --watch --fail-fast
   # alternativa de bajo nivel sin PR:
     RUN=$(gh run list --branch "$BRANCH" --json databaseId,headSha,status,conclusion -q '.[0]')

2. LEER EL VEREDICTO ESTRUCTURADO (no el texto):
     gh run view "$RUN_ID" --json conclusion,jobs
   # la verdad es conclusion == "success". Para un job rojo (ahorra contexto):
     gh run view "$RUN_ID" --log-failed

3. FUENTE DE VERDAD ÚLTIMA (API, anti-spoof — el conclusion lo emite GitHub):
     gh api repos/{owner}/{repo}/commits/"$SHA"/check-runs \
       --jq '.check_runs[] | {name, conclusion}'
   # TODOS los required deben ser conclusion=="success". Esto es lo que cierra AP5.
```

## Output — el objeto `ci_run` (evidencia citable)

verificar-ci NO escribe `feature_list.json` (eso lo hace `el-evaluador` con el commit
`chore(state): mark X passing`). Devuelve el veredicto + el objeto a registrar:

```jsonc
// para feature_list.json[X].ci_run:
{
  "run_id": 1234567890,
  "sha": "<commit HEAD auditado>",
  "conclusion": "success",            // success | failure | cancelled | timed_out
  "url": "https://github.com/<owner>/<repo>/actions/runs/1234567890"
}
```

- **Veredicto `true`** ⇔ `conclusion == "success"` para todos los required checks del SHA de HEAD.
  Sólo entonces el agente puede **proponer** la transición `active → passing` (la hace `el-evaluador`).
- **Veredicto `false`** (cualquier otro conclusion, o checks aún corriendo) → la feature **NO** pasa a
  `passing`. Devolver al generador con `gh run view --log-failed`.
- Citación: `[ci:run#<run_id>]` (gramática de Forja, análoga a `[memory:...]`).

## La regla que materializa (AP8)

> **AP8 — No `passing` sin CI verde.** Una feature NO pasa a `passing` mientras el check-run del commit
> HEAD no sea `conclusion == success`. El texto del agente ("CI debería pasar", "lo terminé") no cuenta.
> Doble condición para `active → passing`: (i) `verification_command` local exit 0 (R7, ya existe) **y**
> (ii) `ci_run.conclusion == "success"` (nuevo). Enforced fail-closed por el `pre-commit` (rechaza el
> commit `mark X passing` si `feature_list.json[X].ci_run.conclusion != "success"`).

## Refusals (lo que NUNCA hace)

- ❌ Declarar `passing` por narrativa o por el `verification_command` local solo (sin el check-run verde).
- ❌ Escribir `feature_list.json` (lo hace `el-evaluador`; verificar-ci solo verifica y entrega el `ci_run`).
- ❌ Rellenar `ci_run.conclusion` a mano — siempre del `gh api`/`gh run view` real (anti-spoof).
- ❌ Saltarse el gate con `--no-verify` (AP2).

## Tool filter

Read · Grep · Bash (`gh`, `git`) solamente. NO Edit ni Write.

## Integraciones

- **`el-evaluador`:** consume el veredicto + el `ci_run`; sólo marca `passing` si es `true` (R7 + AP8).
- **`feature_list.json`:** el objeto `ci_run` se registra ahí (por `el-evaluador`) como evidencia del run.
- **`ci.yml` / `security.yml`:** los workflows cuyo `conclusion` verificar-ci lee.
- **`/despachar`:** corre verificar-ci antes de permitir el deploy.

---

*"El exit 0 ya no lo declara el agente. Lo certifica un tercero. Eso es AP8."*
