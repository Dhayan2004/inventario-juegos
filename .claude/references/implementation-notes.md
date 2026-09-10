# Implementation Notes — protocolo del running log de build

> **Estándar enforced del build (Forge Enterprise · M5).** Cargada bajo demanda desde `/build`, `el-yunque` y `la-forja`; aplica en CUALQUIER modo de build (manual, paralelo, o Dynamic Workflows nativo). Mantener este running log **deja de ser opcional**: `el-evaluador` NO marca una feature `passing` sin que sus *"Preguntas abiertas"* estén listadas y resueltas/confirmadas con el usuario (Clean-State Exit, R12). Endurecimiento pendiente (just-in-time): hook dedicado de verificación + citación ontológica `[ontology: Entidad]` cuando exista la capa de ontología (Fase −1).

## Qué es

Un archivo HTML vivo — `IMPLEMENTATION-NOTES-<feature>.html` — que se mantiene **mientras se construye**, no al final. Captura todo lo que el humano debería saber sobre cómo la implementación **interpreta o se desvía** del Blueprint/PIEZA.

No es PROGRESS.md (estado de sesión) ni la sección "Aprendizajes" de la PIEZA (errores+fixes técnicos). Es la **bitácora de criterio**: por qué se tomó cada decisión donde el spec no era explícito.

## Las 4 secciones obligatorias

Cada entrada se asocia a la fase/subtarea donde surgió.

1. **Decisiones de diseño** — elecciones hechas donde el Blueprint era ambiguo. (Qué se eligió + por qué.)
2. **Desviaciones** — lugares donde se departió intencionalmente del spec, y la razón. (Spec decía X, se hizo Y, porque Z.)
3. **Trade-offs** — alternativas consideradas y por qué se eligió lo que se eligió. (Opción A vs B → elegí A por C.)
4. **Preguntas abiertas** — cualquier cosa que el humano deba confirmar o revisar. (Marcadas como pendientes hasta que el usuario responda.)

## Cuándo se escribe

- **Se crea** al inicio del build (lo hace `/build`, junto con la PIEZA), con las 4 secciones vacías + metadata.
- **Se actualiza** al cerrar cada fase (en `el-yunque`, paso 6 "presentar diff"; en builds paralelos, cada sub-agente/worktree aporta su tramo y se consolida en el handoff).
- **Se cierra** en el Clean-State Exit (R12): las "Preguntas abiertas" sin resolver se listan explícitamente al usuario antes de marcar la feature `passing`.

## Reglas

- **No es memory (R5 no aplica).** Cualquier agente puede escribir el HTML — es artefacto de build, no `.claude/memory/`. `el-evaluador` NO es el writer exclusivo acá.
- **R4 (orchestrator thin):** `la-forja` MISMA no escribe el archivo (no tiene Write). Lo hace un sub-agente de consolidación al sintetizar, o cada worker en su worktree.
- **Honestidad sobre el spec:** si NO hubo desviaciones ni preguntas abiertas en una fase, escribir "Sin desviaciones en esta fase" — no inventar entradas para llenar.
- **Self-contained:** HTML standalone (CSS inline, sin build step), dark-mode, legible abriéndolo directo en el browser. Consistente con `tasks.html` / `PLAYBOOK.html` / `strategy-dashboard.html`.
- **Brand-aware (R10, opcional):** si `brand/brand.json` existe, usar sus tokens para el styling del HTML; si no, dark-mode neutro.

## Skeleton HTML

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Implementation Notes — <FEATURE></title>
<style>
  :root { color-scheme: dark; }
  body { font: 15px/1.6 ui-sans-serif, system-ui, sans-serif; max-width: 880px;
         margin: 0 auto; padding: 2rem 1.25rem; background: #0d0f14; color: #e6e8ee; }
  h1 { font-size: 1.5rem; margin: 0 0 .25rem; }
  .meta { color: #8b91a3; font-size: .85rem; margin-bottom: 2rem; }
  h2 { font-size: 1.1rem; margin: 2rem 0 .75rem; padding-bottom: .35rem;
       border-bottom: 1px solid #232733; }
  .entry { background: #151823; border: 1px solid #232733; border-radius: 10px;
           padding: .85rem 1rem; margin: .6rem 0; }
  .phase { font-size: .72rem; text-transform: uppercase; letter-spacing: .05em;
           color: #6ea8fe; margin-bottom: .3rem; }
  .open  { border-left: 3px solid #f5a623; }
  .resolved { opacity: .6; text-decoration: line-through; }
  code { background: #1c2030; padding: .1rem .35rem; border-radius: 4px; }
</style>
</head>
<body>
  <h1>Implementation Notes — <FEATURE></h1>
  <p class="meta">
    Blueprint: <code>.claude/PRPs/BLUEPRINT-&lt;nombre&gt;.md</code> ·
    Feature: <code>&lt;F?-T?&gt;</code> ·
    Build mode: &lt;Manual / Forja / Dynamic Workflows&gt; ·
    Actualizado: &lt;fase actual&gt;
  </p>

  <h2>🎯 Decisiones de diseño</h2>
  <div class="entry"><div class="phase">Fase N</div>
    <strong>&lt;decisión&gt;</strong> — &lt;por qué, dado que el spec era ambiguo en X&gt;.
  </div>

  <h2>↔️ Desviaciones del spec</h2>
  <div class="entry"><div class="phase">Fase N</div>
    El spec pedía <strong>&lt;X&gt;</strong>; se implementó <strong>&lt;Y&gt;</strong> porque &lt;Z&gt;.
  </div>

  <h2>⚖️ Trade-offs</h2>
  <div class="entry"><div class="phase">Fase N</div>
    Consideré <strong>&lt;A&gt;</strong> vs <strong>&lt;B&gt;</strong>. Elegí &lt;A&gt; por &lt;criterio&gt;.
  </div>

  <h2>❓ Preguntas abiertas</h2>
  <div class="entry open"><div class="phase">Fase N</div>
    &lt;qué necesito que confirmes o revises&gt;.
  </div>
</body>
</html>
```

Convención de cierre: cuando una pregunta abierta se resuelve, mover su `.entry` a clase `resolved` (no borrar — deja trazabilidad de qué se confirmó).
