# Dynamic Workflows (Claude Code nativo) — alternativa a la-forja

> Referencia cargada bajo demanda desde `/build`. No es routing — vive acá para no inflar el budget del AGENTS.md.

## Qué es

Claude Code (host primario de Forja) trae orquestación multi-agente **nativa**: toma una tarea compleja, la divide, y coordina varios subagentes en paralelo (tests, bugs, arquitectura, migraciones), después junta resultados, valida e itera.

A diferencia de `la-forja` (que arma worktrees a mano y hace cherry-pick manual), Dynamic Workflows reparte el trabajo **automáticamente** sin setup de git worktrees.

## Cómo se activa

El humano opta-in desde el prompt — Forja NO lo dispara solo:

- Incluir la palabra **`workflow`** en el prompt del build, o
- Activar **`/effort ultracode`** antes de pedir el desarrollo.

Una vez activo, Claude Code decide el fan-out (cuántos subagentes, sobre qué) según la tarea y el repo.

## Cuándo usar cuál (decisión Forja)

| Situación | Camino recomendado |
|-----------|--------------------|
| Corrés en **Claude Code** y querés paralelismo sin fricción | **Dynamic Workflows** (nativo) — `workflow` / `/effort ultracode` |
| Corrés en **Codex / Hermes** (sin Dynamic Workflows) | `la-forja` — Fork/Coordinator/Swarm |
| Querés **control manual** del fork (N exacto, personalidades, cherry-pick selectivo) | `la-forja` Fork override |
| Build **secuencial con dependencias fuertes** entre fases | `la-forja` Coordinator, o Build Manual (`el-yunque`) |
| Feature **sensible**, fase por fase con tu "go" | Build Manual (`el-yunque`) |

**Default en Claude Code:** Dynamic Workflows es la alternativa nativa al "Modo Forja" del `/build`. `la-forja` queda como el camino host-agnostic (Codex/Hermes) y para cuando querés manejar el fork vos mismo.

## Lo que NO cambia

- **R10 Brand DNA, R7 Three-Layer, R2 atomic commits, R5 memory writer único** siguen aplicando: corras con Dynamic Workflows o con la-forja, el resultado pasa por `el-evaluador` antes de marcarse `passing`.
- El patrón **implementation-notes** (ver `.claude/references/implementation-notes.md`) se mantiene en CUALQUIER modo de build — es ortogonal a quién orquesta.
- Forja sigue siendo **Blueprint-First**: Dynamic Workflows ejecuta el Blueprint aprobado, no reemplaza `/plan`.

## Frase de hint (la que muestra `/build`)

> 💡 ¿En Claude Code? Hay una alternativa NATIVA al Modo Forja: **Dynamic Workflows** reparte subagentes en paralelo sin setup manual de worktrees. Activalo re-pidiendo el build con la palabra `workflow`, o corré `/effort ultracode`. `la-forja` queda para Codex/Hermes o control manual del fork.
