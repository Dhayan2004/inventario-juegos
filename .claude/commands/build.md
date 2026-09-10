---
description: "Construye una feature aprobada — pregunta si ejecutar paralelo (la-forja) o manual (el-yunque)."
---

# /build

Toma el Blueprint aprobado y lo convierte en código production-ready.

## PREFLIGHT (R11 Bootstrap Contract)

Antes de cualquier acción, ejecuta `make preflight`. Si falla → halt con mensaje exacto del gate (no bypass).

## Qué hace

1. Lee `.claude/PRPs/BLUEPRINT-<nombre>.md` o `AI-FEATURE-BRIEF-<nombre>.md`.
2. Genera `.claude/PRPs/PIEZA-<nombre>.md` (spec ejecutable de la feature).
3. Crea `IMPLEMENTATION-NOTES-<nombre>.html` con las 4 secciones vacías (running log de criterio — ver `.claude/references/implementation-notes.md`).
4. Presenta plan de fases conciso (≤10 líneas).
5. **PREGUNTA modo:**

```
¿Cómo quieres ejecutar este build?

🔨 Modo Forja  — N agentes autónomos en sandboxes paralelos (la-forja, default)
🔧 Build Manual — Fase por fase, con tu aprobación (el-yunque)

💡 ¿En Claude Code? Hay una alternativa NATIVA al Modo Forja: Dynamic Workflows
   reparte subagentes en paralelo sin setup manual de worktrees. Activalo
   re-pidiendo el build con la palabra "workflow", o corré /effort ultracode.
   la-forja queda para Codex/Hermes o control manual del fork.
   → Detalle: .claude/references/dynamic-workflows.md
```

## Reglas críticas

- ❌ NO escribas ni una línea de código sin la elección del usuario.
- ✅ **Modo Forja** → leer y ejecutar `.claude/skills/la-forja/SKILL.md`.
- ✅ **Build Manual** → leer y ejecutar `.claude/prompts/el-yunque.md`.
- ✅ Validar nombre de skill contra `.claude/memory/skills.md` antes del dispatch (R6).
- ✅ **Implementation Notes en todos los modos:** mantené vivo `IMPLEMENTATION-NOTES-<nombre>.html` mientras construís (decisiones de diseño, desviaciones, trade-offs, preguntas abiertas). Protocolo en `.claude/references/implementation-notes.md`.

## Pre-requisitos

- Blueprint aprobado en `.claude/PRPs/`.
- Active feature en `feature_list.json` (R1: WIP=1).
- Brand DNA presente (`brand/brand.json` + `voice.json`) para fases con UI (R10).
