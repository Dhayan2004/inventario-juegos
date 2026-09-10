# Glossary — Forja Memory

> Domain terms used in Forja. Append-only.
> **Single writer:** `el-evaluador`. Other agents READ ONLY.
>
> Cite as `[memory:glossary#term]`

---

## Forja-specific

| Término | Definición |
|---------|------------|
| **Forja** | Sistema agentic-first para construir SaaS production-ready con Claude Code. Repo `getforja/forja`. |
| **El Yunque** | Modo de ejecución secuencial de `/build` con humano aprobando cada fase. |
| **La Forja** (skill) | Modo de ejecución paralelo con N worktrees + cherry-pick. |
| **El Crisol** | Pipeline de validación estratégica post-Blueprint con dashboard ejecutivo. |
| **La Herrería** | Pipeline de planificación pre-build (BMC, PDR, Tech Spec, etc.). |
| **El Evaluador** | Independent Evaluator Agent. Único writer del memory store. |
| **El Guardian** | Codex Security Auditor. Pre-deploy gate. |
| **El Migrador** | Skill que automatiza Supabase migrations vía CLI. |
| **El Tajo** | One-shot atómico (microtarea <5min). |
| **El Golpe** | One-shot feature mediano (<30min). |
| **El Supervisor** | Hermes adapter opcional. NO core. |
| **Brand DNA** | Contrato no-negociable de identidad visual + voice por proyecto (`brand.json` + `voice.json` + `brand.css`). |
| **Anti-Slop Gate** | Validador automático que rechaza output con patrones AI-genérico (gradientes morado/azul, Inter+blanco, etc.). |
| **Bootstrap Contract** | Checklist de entrada que `/build` requiere antes de permitir construcción. |
| **Auto-Blindaje** | Filosofía: cada error → documentado → nunca repetido. |
| **Feature ID** | Formato `F<phase>-T<task>` ej. `F1-T3`. |
| **PIEZA** | Spec individual de feature en `.claude/PRPs/PIEZA-<name>.md`. |

## Agentic concepts

| Término | Definición |
|---------|------------|
| **Harness** | Todo lo que rodea al modelo: instructions, tools, environment, state, feedback. |
| **PREFLIGHT** | Halt-line que cada agente corre antes de cualquier tool call. |
| **WIP=1** | Work In Progress = 1: solo una feature `active` simultáneamente. |
| **VCR** | Verified Completion Rate (`verified / activated`). Si <1.0, no se permite activar más. |
| **Three-Layer Verification** | Syntax → Runtime → System. Sin skip. |
| **Independent Evaluator** | Agente estructuralmente separado del generador. Evita self-eval positive bias. |
| **Coordinator** | Multi-agent pattern: synthesis sequential entre fases. |
| **Fork** | Multi-agent pattern: paralelo con worktrees. |
| **Swarm** | Multi-agent pattern: workers tool-filtered para one-shot. |
| **Skills Registry** | `.claude/memory/skills.md` — validado pre-dispatch. |

## Stack

| Término | Definición |
|---------|------------|
| **Golden Path** | Stack default de Forja: Next.js 16 + Supabase + shadcn + Vercel AI SDK + agent-browser. |
| **BaaS** | Backend-as-a-Service. Forja decide entre Supabase y InsForge según `/plan` Tech Spec. |
| **InsForge** | BaaS agents-first con Model Gateway nativo. Alternativa a Supabase. |
| **agent-browser** | CLI Rust de Vercel Labs para browser automation. ~4× ahorro de tokens vs Playwright MCP. |
| **MCP** | Model Context Protocol. Servers que exponen tools al agente. |

---

<!-- additional terms populated as encountered -->
