<!--
  PR template de Forge Enterprise (S2 · Equipos GitHub-native).

  Lo rellena `/despachar` desde feature_list.json + .plan/plan.json (body autogenerado), pero también
  sirve para PRs manuales. Las casillas marcan EVIDENCIA, no aspiraciones: no marques [x] sin el verde real.

  INVARIANTE R18 — GitHub es un ESPEJO de una sola vía. Mergear este PR NO marca ninguna feature `passing`
  ni muta feature_list.json: la transición active → passing la gobiernan los hooks (R1 + R7 + AP8), no el merge.
  Citation: [memory:CONSTRAINTS.md#R18].
-->

## Resumen

<!-- Qué cambia y por qué, en 1–3 frases. El "qué" técnico; el "por qué" del Blueprint/SPEC. -->



## Feature(s) / Story(ies)

<!--
  Feature(s) de feature_list.json que este PR construye (id + behavior). Story(ies) de .plan/plan.json
  que las agrupan (vía featureRefs[]). La VERDAD del estado vive en feature_list.json — esto sólo lo refleja (R18).
-->
- Feature(s): <!-- [F1-T2] el usuario puede … -->
- Story(ies): <!-- [S3] Como … quiero … para … -->

## Three-Layer Verification (R7)

<!-- No se marca `passing` sin las tres capas verdes. Cada casilla = un comando que corrió y dio verde. -->
- [ ] **Layer 1 — Syntax:** `make typecheck` + lint exit 0
- [ ] **Layer 2 — Runtime:** `make test` (unit + integration) exit 0
- [ ] **Layer 3 — System:** `make e2e` (headless + visual diff vs brand.json) exit 0
- [ ] `verification_command` de la(s) feature(s) exit 0

## Review Pre-Landing

- [ ] WIP=1 respetado (R1): una sola feature `active` al abrir este PR
- [ ] Commits atómicos + conventional (R2): `<type>(<scope>): <desc>`
- [ ] Sin `any` en TypeScript · archivos ≤500 líneas · funciones ≤50
- [ ] El plano (.plan/) quedó íntegro (R17): `make plan-validate` exit 0
- [ ] Reviewer de CODEOWNERS asignado para áreas sensibles (si aplica)

## Brand DNA (R10)

<!-- UI sólo desde componentes de impeccable + tokens del brand.json. Cero Tailwind defaults. -->
- [ ] Componentes desde `src/shared/components/ui/*` (impeccable); cero `bg-blue-500`/`purple` ni Tailwind defaults
- [ ] Copy/CTAs derivados de `voice.json` (`voice.cta_examples`), no hardcodeados
- [ ] Brand Score ≥ 75 por página tocada (validado por `el-evaluador`)
- [ ] N/A — este PR no toca UI

## Security (R14 + el-guardian)

<!-- Sin secrets literales (R15, el pre-commit lo bloquea). Destructivas tras confirmación tipada (R14). -->
- [ ] Sin secretos literales (R15): sólo `process.env.*` / placeholders `YOUR_*`/`CHANGE_ME`
- [ ] Server actions destructivas (revoke/remove/delete/transfer/leave/updateRole) NO exponen `execute()` agentic; corren tras confirmación tipada en UI (R14)
- [ ] `service_role` sólo en archivos server-only; RLS + `WITH CHECK` en tablas multi-tenant (R16)
- [ ] **el-guardian** corrió pre-deploy y devolvió PASS (sin critical/high)
- [ ] N/A — este PR no toca superficies de seguridad

## CI (AP8)

<!--
  AP8 — No `passing` sin CI verde. El árbitro es el runner remoto, no la máquina del agente.
  `/despachar` corre `verificar-ci` y pega aquí el objeto ci_run. La cita [ci:run#<id>] es la evidencia.
-->
- [ ] `ci_run.conclusion == "success"` para el SHA de HEAD (lo certifica GitHub, no el agente)
- Evidencia: `[ci:run#<run_id>]`
- Run URL: <!-- https://github.com/<owner>/<repo>/actions/runs/<run_id> -->

---
<sub>🔥 Forja — Factory OS · Blueprint-First · Brand DNA · Auto-Blindaje. El merge no marca `passing` (R18); lo gobiernan los hooks.</sub>
