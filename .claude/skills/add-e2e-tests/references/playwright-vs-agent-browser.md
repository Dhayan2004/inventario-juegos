# Playwright vs agent-browser — matriz de decisión

> Reference. Cuándo usar qué, y por qué `add-e2e-tests` NO contradice D4
> (agent-browser default).
>
> **Citas:** `[memory:decisions#D-004]` ↔ `[ARCHITECTURE.md#D4]`,
> `[memory:references#R-003]` (vercel-labs/agent-browser),
> `[memory:decisions#D-026]` (add-e2e-tests binary minimal/full).

---

## TL;DR

| Herramienta              | Caso de uso canónico                       | Status en Forja           |
|--------------------------|--------------------------------------------|---------------------------|
| `agent-browser` CLI      | QA agentic durante development             | **Default (D4)**          |
| Playwright **MCP**       | Cross-browser checks vía agente, exploración | Opcional (D4 fallback)    |
| `@playwright/test`       | Specs CI/CD que corren **sin agente**       | Opcional (`add-e2e-tests`)|

Los tres coexisten. No se reemplazan.

---

## Por qué tres herramientas, no una

Cada herramienta resuelve una pregunta operacional distinta:

1. **¿Cómo verifico que el cambio que acabo de hacer funciona, ahora, sin
   levantar test infra?** → `agent-browser` CLI. El agente abre Chromium
   (~4× menos tokens que Playwright MCP), navega, asserta visualmente,
   reporta. Iteración rápida durante development.

2. **¿Cómo exploro cross-browser issues que requieren juicio agentic
   (visual regression, layout flaky en webkit, accessibility ad-hoc)?**
   → Playwright **MCP**. El agente conduce la sesión, pero con la API
   completa de Playwright disponible. Caso menos frecuente, pero válido.

3. **¿Cómo bloqueo merges con un test gate que no requiere un agente
   activo en el loop, corriendo en GitHub Actions / Vercel / Coolify?**
   → `@playwright/test` (este skill). Specs declarativos, sin agente.
   CI gate, smoke pre-deploy, cross-browser matrix.

`add-e2e-tests` resuelve la **tercera** pregunta. No tiene sentido
forzarla a hacer las otras dos — agent-browser es ~4× más eficiente para
QA agentic, y Playwright MCP ya existe para cross-browser agentic.

---

## Matriz de decisión

| Pregunta | agent-browser CLI | Playwright MCP | @playwright/test |
|----------|:-----------------:|:--------------:|:----------------:|
| ¿Corre sin agente en el loop? | ❌ | ❌ | ✅ |
| ¿Optimizado para tokens (4× ratio)? | ✅ | ❌ | n/a (sin agente) |
| ¿Cross-browser nativo (chromium/firefox/webkit)? | parcial (chromium-first) | ✅ | ✅ |
| ¿Integrable a GitHub Actions / Vercel / Coolify? | parcial | ❌ | ✅ |
| ¿Trace viewer / HTML reports / video on failure? | ❌ | parcial | ✅ |
| ¿Storage state para auth reutilizable? | ad-hoc | ad-hoc | ✅ |
| ¿Smoke pre-deploy automatizable? | parcial | ❌ | ✅ |
| ¿Visual diff agentic vs `brand.json`? | ✅ (D4 use case) | ✅ | ❌ (requiere screenshot lib + agente) |
| ¿Setup time del primer test? | ~0min (instalado en Forja core) | ~5min (MCP config) | ~30-90s (npm install + browsers) |

**Conclusión:** las tres tienen "región dominante" — no hay overlap suficiente para reemplazo.

---

## Decisión recomendada por contexto

### Durante development (loop iterativo con un agente activo)
→ **agent-browser CLI**. Es el default Forja por D4. Tokens-efficient,
zero-setup, ya validado en el bloque D de ARCHITECTURE.md.

### Exploración cross-browser puntual (un agente revisa algo específico)
→ **Playwright MCP**. Configuración mediante `.mcp.json`. Útil cuando
agent-browser no cubre webkit/firefox o cuando hace falta la API
completa de Playwright dentro de la sesión del agente.

### CI/CD gate sin agente activo
→ **`@playwright/test` via add-e2e-tests**. Specs corren en GitHub
Actions, Vercel preview deployments, o pre-deploy local sin agente.
Mode `minimal` (chromium-only) es default conservador; mode `full`
agrega firefox + webkit + workflow.

### Combinaciones válidas

- agent-browser + @playwright/test: agentic durante dev, CI gate al
  push. **Combo canónico Forja.**
- agent-browser + Playwright MCP + @playwright/test: para apps con
  alto compromiso cross-browser (B2C, marketplace público).
- Solo @playwright/test: para proyectos con poco loop agentic (mucho
  CI/CD, poco dev iterativo). Raro pero válido.

---

## Anti-patrones

- ❌ **"Voy a reemplazar agent-browser con Playwright tests."** D4 sigue
  intacto. agent-browser optimiza un caso de uso que Playwright tests no
  cubre (QA agentic con tokens-efficient).
- ❌ **"Voy a correr @playwright/test desde un agente activo en lugar de
  agent-browser."** Funciona pero gasta ~4× más tokens. Solo si el caso
  requiere features que agent-browser no expone (trace viewer, video,
  storageState).
- ❌ **"Voy a meter `playwright.config.ts` específicos para agent-browser."**
  agent-browser tiene su propio runtime. No comparte config con
  @playwright/test.

---

## Citations

- `[memory:decisions#D-004]` ↔ `[ARCHITECTURE.md#D4]` — agent-browser default, Playwright MCP opcional.
- `[memory:references#R-003]` — vercel-labs/agent-browser repo.
- `[memory:decisions#D-026]` — add-e2e-tests binary minimal/full.
- `[memory:errors#E-009]` causa 3 — Gate 8 heredado (typecheck baseline pre-install).
- `[docs:playwright]`, `[docs:playwright-test]` — official docs vía find-docs.

---

*"Tres herramientas, tres preguntas operacionales distintas, cero canibalismo."*
