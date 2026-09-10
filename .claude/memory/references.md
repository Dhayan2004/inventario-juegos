# References — Forja Memory

> Curated external URLs. Append-only.
> **Single writer:** `el-evaluador`. URLs are promoted here when cited in >2 sessions or marked as canonical reference.
>
> **Format per entry:**
> - ID `R-NNN` (zero-padded, monotonic)
> - Title
> - URL
> - One-line summary (why this reference matters for Forja)
> - Date promoted
> - Cite as `[memory:references#R-NNN]`

---

## R-001 — walkinglabs/learn-harness-engineering

**URL:** https://github.com/walkinglabs/learn-harness-engineering
**Promoted:** 2026-05-07
**Why:** Source canónico del modelo de 5 subsistemas, `feature_list.json` state machine, Independent Evaluator pattern, Bootstrap Contract, y Three-Layer Verification que adoptamos en Forja.

## R-002 — vincentconace/relay-kit

**URL:** https://github.com/vincentconace/relay-kit
**Promoted:** 2026-05-07
**Why:** Pattern catalog para Skills Registry validation, branch-as-active-feature, 7-typed-files append-only memory, y orchestrator-stays-thin. Reimplementado nativamente en Forja, NO instalado como dep.

## R-003 — vercel-labs/agent-browser

**URL:** https://github.com/vercel-labs/agent-browser
**Promoted:** 2026-05-07
**Why:** CLI Rust de browser automation. Default de Forja para QA + visual diff. ~4× ahorro de tokens vs Playwright MCP.

## R-004 — Anthropic Harness Design for Long-Running Apps

**URL:** https://www.anthropic.com/engineering/harness-design-long-running-apps
**Promoted:** 2026-05-07
**Why:** Engineering blog de Anthropic con principios oficiales de gestión de contexto, subagentes con contexto limpio, tareas en JSON externo. Referencia conceptual primaria.

## R-005 — Brand DNA Schema (input externo del especialista)

**URL (local):** `~/Documents/Codex/2026-05-07/files-mentioned-by-the-user-brand/brand-dna-schema-forja.md`
**Promoted:** 2026-05-07
**Why:** Schema completo de `brand.json` + `voice.json` con 6 ejes de posture, archetypes Mark+Pearson, 20 anti-slop patterns, color policy, motion philosophy, validación programática. Production-ready, usado en D9.

## R-006 — Hermes Technical Report

**URL (local):** `~/Developer/obsidian/wiki/tech/hermes-technical-report-2026-05-07.md`
**Promoted:** 2026-05-07
**Why:** Reporte detallado de capabilities de Hermes (NousResearch agent runtime con deepseek-v4-pro vía OpenCode Go). Base para D8.4 (integración opcional plug-and-play).

## R-007 — Context7 (Upstash)

**URL:** https://github.com/upstash/context7
**Promoted:** 2026-05-07
**Why:** MCP server para docs actualizadas de libs externas. Default tool del skill `find-docs` (F2-S7). Resuelve alucinación de sintaxis post-cutoff. Manual config: server URL `https://mcp.context7.com/mcp` + header `CONTEXT7_API_KEY`. Tools: `resolve-library-id` (libraryName → libraryId canónico) + `query-docs` (libraryId + query → docs). Citation grammar `[docs:libname]` o `[docs:libname@version]` enforced por R13.

## R-008 — Anshu Chimala, *How to turn your AI into a world-class designer* (Lenny's Newsletter)

**URL:** https://www.lennysnewsletter.com/p/how-to-turn-your-ai-into-a-world
**Promoted:** 2026-09-02
**Why:** fuente primaria de las 6 técnicas de diseño con agentes (semilla por shell, prompts ambiciosos + gusto humano, crítico en contexto fresco, imagen, video, cut). Forja las absorbe como guardrails + criterios de término (D-037), no como skills de pasos. Citar en `design-discover.md`, `DESIGN_ENRICH.md`, `QUALITY_GATES.md` §4.

## R-009 — Khullar, Hopkins, Wang, Roger — *Self-Attribution Bias: When AI Monitors Go Easy on Themselves*

**URL:** https://arxiv.org/abs/2603.04582
**Promoted:** 2026-09-02
**Why:** el sesgo del juez vive en el formato del turno (acción en turno assistant previo), no en el texto "lo hiciste tú". Fundamento empírico de AP3 estructural y del despacho fresco de `el-critico-de-diseno` (L-011). Citar cuando se diseñe cualquier rol de auditoría/juicio.

## R-010 — Misaki & Akiba (Sakana AI) — *String Seed of Thought* · Gu et al. (DeepMind) — *The Illusion of Stochasticity in LLMs*

**URL:** https://arxiv.org/abs/2510.21150 · https://arxiv.org/html/2604.06543
**Promoted:** 2026-09-02
**Why:** SSoT demuestra que el modelo puede mapear una string → decisión estocástica; Gu 2026 demuestra que NO puede generar el azar (el post-training amplifica el sesgo). Conclusión Forja: la semilla sale del PRNG del SO (`design-seed.sh`), el modelo solo mapea; diversidad se mide en pantallas (`design-diversity.mjs`, NoveltyBench arXiv 2504.05228).

## R-011 — Boris Cherny — *Building Claude Code* (Y Combinator) · Reporails, *Opus 5: Delete your CLAUDE.md?*

**URL:** https://podscripts.co/podcasts/y-combinator-startup-podcast/boris-cherny-building-claude-code · https://reporails.com/articles/opus-5-delete-your-claudemd
**Promoted:** 2026-09-02
**Why:** ablación (no opinión), hobbling (receta = quitarle la decisión al modelo) y el filtro 3R. Fundamento de D-036: el harness se pesa (`check-ceilings.mjs`) antes de crecer; guardrail + criterio de término sobreviven, la receta de pasos no. Rutina cada ~6 meses / salto de modelo (`docs/10-ablation-3r.md`).

## R-012 — PagoKit — Payment Integration Agent (Hainrixz / Enrique Rocha, MIT)

**URL:** https://github.com/Hainrixz/agente-pagokit
**Promoted:** 2026-09-02
**Why:** catálogo de 42 proveedores / 136 métodos / 106 monedas con exponente ISO 4217 + 14 familias de verificación de webhook, ranking determinista (`advise.js`), firmador de eventos (válido/forjado/replay) y 24 validadores fail-closed en hooks de turno. Veredicto Forja (`docs/11` §1): absorber datos + motores + validadores en `add-payments`/`threat-db`, Mercado Pago como Mode C; NO instalar el plugin (3R/L-007). Regla que vale copiar: sin esquema de firma verificado, no se emite verificador.

## R-013 — Anthropic — Previewing the Model Hardware Standard (MHS)

**URL:** https://www.anthropic.com/news/model-hardware-standard-research-preview
**Promoted:** 2026-09-02
**Why:** spec abierta (preview) para que agentes operen hardware: driver estándar read/write, capacidades + límites de seguridad en la spec, metadata en lenguaje natural, control vía MCP/CLI/código, humano confirma lo riesgoso. Evidencia externa de la doctrina Forja "el límite vive en el tool, no en el prompt" (AP3/AP9/R14). Backlog B11 gated (`docs/11` §2); fuera del dominio hasta open source + cliente con equipos.

---

<!-- additional URLs promoted by el-evaluador as they accumulate citations -->
