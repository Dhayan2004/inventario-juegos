---
description: "Pipeline DETECT → ANALYZE → PLAN para migrar proyectos existentes (Forge V2/V3 o Next.js custom) a Forja Enterprise."
---

# /migration-wizard

Lee y ejecuta `.claude/skills/migration-wizard/SKILL.md`.

Pipeline shape (D-023 — boundary case análogo a D-014 de el-crisol). Auto-detecta el tipo de origen del proyecto (5 tipos):

- **A.** Forge V3.x (`.claude/skills/la-herreria` existe + CLAUDE.md V3)
- **B.** Forge V2 (CLAUDE.md sin estructura `` + `.claude/skills` antiguo)
- **C.** Next.js custom (sin Forge/Forja previo)
- **D.** Otro framework (Remix, SvelteKit, Astro, etc.)
- **E.** Greenfield con código (sin `package.json` claro pero con archivos)

Analiza estado actual vs Bootstrap Contract de Forja (R11) + 8 extras Forja Enterprise. Identifica gaps críticos que bloquean `/build` y reusable existente.

**Output:** `MIGRATION-PLAN-{nombre}.md` con pasos priorizados, comandos Forja exactos, y estimación de tiempo.

**No ejecuta la migración — solo planifica.** La ejecución es responsabilidad del usuario (corre los comandos del plan en orden).

**Pre-requisito:** estar en el directorio del proyecto a migrar O proveer el path:

```
/migration-wizard /path/to/project
```

**Halt si proyecto ya está en Forja Enterprise** (AGENTS.md + feature_list.json + .claude/memory/skills.md existen) — usar `/forge-check` para diagnóstico en su lugar.
