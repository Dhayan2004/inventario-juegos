# Quality Gates anti-error — evidencia RED, review con contexto limpio, auditoría del harness

> **Qué es esto.** Tres doctrinas de calidad **absorbidas de ECC** (affaan-m/ECC, "Agent Harness OS",
> MIT) tras el feedback dogfooding 2026-08-18 (punto 1: "el agente sigue cometiendo muchos errores",
> punto 9: "a ver qué tomamos de ECC"). Igual que con Ponytail (C5) y las design-skills (lección
> Vercel): se absorbe la **metodología**, NO se instalan sus 285 skills / 68 agentes / plugin. El
> principio compartido: **los errores del modelo no se arreglan con más instrucciones — se arreglan
> con gates deterministas fuera de su razonamiento.**

- **Versión:** v0.1.0 (2026-08-18)
- **Complementa:** R7 (Three-Layer Verification) — estos gates endurecen las capas, no las reemplazan.
  `MINIMALISM.md` decide qué NO escribir; esto verifica lo que SÍ se escribió.
- **Consumidores:** `el-yunque`/`la-forja` (flujo de build), `el-evaluador` (checklist PASS),
  `project-auditor` (modo `--harness`).

---

## 1. Evidencia RED primero (TDD estructural, no aspiracional)

**Regla:** ningún fix de bug y ninguna feature con verificación automatizable se implementa sin haber
**capturado primero la evidencia del test en rojo**. "Escribe el test primero" como instrucción se
ignora bajo presión; como **gate de evidencia**, no se puede fingir.

- **Bugfix:** antes de tocar código, escribir el test que **reproduce el bug** y capturar su output
  FAIL (el RED). Después el fix. Después el mismo test en verde. Sin RED capturado, el test pudo haber
  nacido verde — y un test que nunca falló **no demuestra nada** (es el false-green que ya nos cazó
  una vez en S2: el test de teams que escribí mal y "pasaba").
- **Feature:** la `verification` de `feature_list.json` se corre ANTES de implementar (debe fallar =
  RED) y DESPUÉS (debe pasar = GREEN). El par RED→GREEN es la evidencia.
- **Dónde queda la evidencia:** evento `test_result` en `.plan/` con `result: "fail"` previo al
  commit del fix (sellado por `post-commit` → trazable por grep), o el output citado en la nota del
  feature. Formato citable: `[red:make test 2026-08-18]` → `[green:make test 2026-08-18]`.
- **Quién lo exige:** `el-evaluador` — al evaluar un bugfix, **pide el RED**. Sin evidencia RED, el
  veredicto es `NEEDS_FIX` con causa "test sin prueba de reproducción", no PASS.
- **Degradación segura:** cambios sin verificación automatizable (copy, docs, estilos) no gatillan el
  gate — pero un bugfix SIEMPRE la tiene (si "no se puede testear", eso es el primer bug a arreglar).

## 2. Review con contexto limpio (fresh-context review)

**Regla:** quien revisa **no comparte contexto** con quien generó. Un agente que pasó 2 horas
construyendo algo ya "sabe" que funciona — hereda todos los supuestos del código que revisa. El
contexto limpio es lo que convierte una revisión en una revisión.

- **Ya es estructural en Forja** para seguridad y evaluación: `el-guardian`, `el-migrador` y
  `el-evaluador` corren con `context: fork` + subagente custom con `tools:` whitelist (D-033) — no
  ven la conversación del generador. Y `el-guardian` usa **Codex como segundo cerebro** (modelo
  distinto, E-041/E-042: el mismo modelo firma sus propios bugs).
- **Lo que esta doctrina agrega:** el review de **corrección** (no solo seguridad) también merece
  contexto limpio cuando la feature es grande o crítica. Antes de marcar `passing` una feature
  `critical: true` (o >~300 líneas de diff), `el-evaluador` se invoca en sesión/fork limpio con SOLO:
  el diff, el SPEC de la feature, y la `verification` — sin el hilo de la conversación que la
  construyó. Lo que el generador "explica" no cuenta; cuenta lo que el diff demuestra.
- **Regla L-009 aplicada:** la independencia se valida por el harness (transcript/meta.json del
  fork), no por el self-report del agente.

## 3. Auditar el harness mismo (doctrina AgentShield)

**Regla:** el harness es superficie de ataque y de degradación — hooks que dejan de correr, filtros
de tools que se aflojan, skills que leen contenido remoto sin vetting, MCP servers nuevos sin
revisar. Nadie lo audita porque "es la herramienta". ECC lo llama AgentShield; aquí es un **modo de
`/temple`**: `/temple --harness`.

Checklist del modo (todo verificable por comando, doctrina AP5):

1. **Hooks vivos de verdad:** `make test-hooks` verde Y un commit de prueba en sandbox confirma que
   git los ejecuta (el incidente `core.hooksPath` global 2026-08-18 demostró que los hooks pueden
   estar perfectos en disco y NO correr — gate que grita y deja pasar es peor que no tenerlo).
2. **Tool-filters intactos:** `fork-agents.test.sh` verde (los forks siguen sin Edit donde no toca; el crítico visual sin Write/Edit/Grep/Glob).
3. **Superficie de inyección:** grep de skills/prompts que consuman contenido externo (WebFetch, URLs,
   transcripciones) sin pasar por `CYBERSEC_VETTING.md`; los inputs externos son datos, no instrucciones.
4. **Config y permisos:** diff de `.claude/settings.json` + MCP servers contra el último snapshot
   auditado — todo server/permiso nuevo se revisa (5 pasos de `CYBERSEC_VETTING.md`).
5. **Secrets del harness:** R15 sobre el propio `.claude/` (los skills también commitean).

Cadencia: pre-release (junto al `/temple` normal) y tras cambiar hooks, agents o MCP config.

## 4. Juez visual fresco + corte antes del golden (diseño sin slop de comité)

**Regla:** quien juzga la estética **no ve el código ni el hilo** que la produjo. Es §2 aplicado a
píxeles. Un agente que pide "mejora tu diseño" a su propio contexto no puede hacer zoom-out: ve su JSX,
sus decisiones, su racional — y Khullar et al. (2026) miden que el sesgo de autoatribución vive en el
**formato del turno** (la acción en un turno assistant anterior), no en el texto "sé objetivo".

- **Despacho:** `el-pulidor` modo `critique` (LIVE) → `Agent(el-critico-de-diseno)` con **solo**
  screenshots desktop + mobile (+ hasta 4 refs elegidas por el tenant en `brand/moodboard/`). Tools del
  crítico: `Read, Bash` — sin Write/Edit/Grep/Glob (AP3 estructural, `fork-agents.test.sh`). Mismo
  prompt cada vuelta (vive en `.claude/agents/el-critico-de-diseno.md`).
- **Stop conditions (viven AQUÍ, nunca en el prompt del crítico):**
  1. `MAX_CRITIC_ITERS=2` por defecto; el humano puede subir a 4. Nunca infinito (Anshu tuvo que cortar a
     mano su loop nocturno: el juez no tiene "good enough").
  2. Parada feliz = el producto **gana o empata** el ranking pairwise contra las refs (con position swap).
     Los scores absolutos driftean e inflan (Zheng 2023; WiserUI-Bench): `score` /10 es **telemetría**
     que se registra, no un gate. "9/10" no se escribe en ningún prompt.
  3. Parada por no-progreso: el ranking flippea (A>B>A) o los gaps se contradicen entre vueltas →
     archivar `iter-k.md` y devolver al humano.
  4. Parada R19: un gap que muta alcance/SPEC (qué existe, para quién) → parar y preguntar. El crítico
     no reescribe `SPEC.md`, `ONTOLOGY.md` ni `voice.json`.
  5. Si el crítico intenta editar, el harness lo bloquea por whitelist — no por promesa.
- **Cut obligatorio antes del golden:** `el-pulidor` modo `cut` (candidatos a borrar) → OK humano →
  el implementador resta → screenshot post-cut = **candidato golden** → el humano acepta →
  `brand/golden/<pantalla>@{desktop,mobile}.png` (F-P2.3). Goldens **nunca** se congelan en el Discover
  paralelo. Con motion real, el golden es el frame 0 + storyboard, no un mp4.
- **Comparación contra golden:** pairwise por el crítico fresco + checks deterministas
  (`anti-slop-gate.sh`, contraste, overflow, `prefers-reduced-motion`). **NO pixel-diff PNG** (falla con
  contenido dinámico; el snapshot de estructura ya lo cubre el gate AST). `el-evaluador` exige golden
  aceptado en features `critical` de UI.
- **Penalties → checks:** toda penalty del crítico mecanizable en JSX (glow-stack, hero-default,
  layout-prop animation, reduced-motion ausente) tiene su check en `anti-slop-gate.sh` (F-P2.1). Las no
  mecanizables (label redundante, custom-peor-que-nativo) son hallazgo del crítico, con skip justificado.
- **Fronteras (R7, tres capas + humano):** `el-critico-de-diseno` = gusto/estudio/píxeles ·
  `el-evaluador` = Anti-Slop AST + tokens + gates (firma) · `el-guardian` = seguridad/doctrina · humano =
  SPEC, taste notes, stop.
- **Costo:** crítico = tier *piensa* (target <10% de los tokens del loop — se mide, no se asume);
  implementador = *orquesta* (no *rellena*: debe ejecutar craft). `MODEL_PER_ROLE.md` §1.

## Qué NO se adoptó de ECC (y por qué)

| Pieza ECC | Veredicto | Razón |
|-----------|-----------|-------|
| 285 skills / 68 agentes / plugin | 🚫 NO instalar | lección Vercel (anti-bloat); el catálogo de Forja se pesa, no se cuenta (`check-ceilings.mjs`, D-036) |
| Memory Vault multi-harness | ⏳ diferido | R5 + memoria tipada cubren; re-evaluar si entra un 2º harness |
| Plan Canvas | 🚫 | `.plan/` + `plan.html` ya son el plano de control (A1) |
| Token budgeting/model routing | ⏳ | `MODEL_PER_ROLE.md` ya existe (opcional) |

## Sources
- ECC — github.com/affaan-m/ECC (MIT): TDD RED-evidence, fresh-context review, AgentShield (doctrina destilada, sin código importado).
- Feedback dogfooding 2026-08-18, puntos 1 y 9.
- E-041/E-042 (segundo cerebro) · L-009 (validar por harness, no self-report) · S2 (false-green).
- §4: Anshu Chimala, *How to turn your AI into a world-class designer* (Lenny's Newsletter, 2026-09-01) · Khullar, Hopkins, Wang, Roger, *Self-Attribution Bias* (arXiv 2603.04582, 2026) · Zheng et al., *Judging LLM-as-a-Judge* (NeurIPS 2023) · Jeon et al., WiserUI-Bench (arXiv 2505.05026) · D-037.
