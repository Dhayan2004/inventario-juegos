# render-doc-html

> Convierte cualquier planning doc de la-herreria a HTML standalone legible. Se invoca al final de cada asset que produce un .md "humano-leíble". El agente sigue trabajando contra el .md; el humano navega el .html.

## Propósito

Generar `[nombre-doc].html` standalone a partir de `[nombre-doc].md` recién generado por un asset de la-herreria. El doc renderizado usa la paleta canónica de Forja (dark mode + Liquid Glass), tiene navegación lateral en desktop, secciones colapsibles, y `@media print` para PDF export. Standalone: abre en cualquier browser sin servidor.

Heredado de `.claude/skills/el-crisol/prompts/build-dashboard.md` (CSS vars, paleta, print mode). Diferencia clave: este prompt **NO** usa Chart.js — solo CSS puro + JS vanilla mínimo para colapsar secciones.

## Inputs

```yaml
doc_path: <path al .md recién generado>
doc_type: VIABILITY | BMC | VPC | PDR | TECH-SPEC | USER-STORIES | UX-RESEARCH | UX-DESIGN | UI-DESIGN | UI | SECURITY-AUDIT | BLUEPRINT | AI-FEATURE-BRIEF | LEAN-CANVAS | PRE-MORTEM
project_name: <{nombre-kebab}>
```

## Output

Mismo directorio que el `.md` → `[nombre-doc].html` (sobreescribir si existe).

Reportar al final:
```
✅ [nombre-doc].md + [nombre-doc].html generados (path/al/dir/)
```

## Especificaciones técnicas

| Spec | Valor |
|------|-------|
| Formato | HTML5 standalone (sin servidor, sin CDN, sin libs externas) |
| Theme | Dark mode default (paleta canónica Forja, idéntica a el-crisol/build-dashboard) |
| Layout | Sidebar fija desktop (≥1024px) · dropdown mobile (<1024px) · max-width 900px del contenido |
| Tipografía | `system-ui, -apple-system, sans-serif` · body 16px/1.7 |
| Colapsibles | `<details>` nativo HTML — sin JS para abrir/cerrar (mejor accesibilidad) |
| Smooth scroll | `html { scroll-behavior: smooth }` para nav anchors |
| Print | `@media print`: sidebar oculta, fondo blanco, todas las `<details>` expandidas (`details[open]` forzado vía CSS print) |
| Header badge color | depende de `doc_type` (ver tabla) |

### Header badge color por tipo

| `doc_type` | Color del badge | CSS variable |
|------------|----------------|--------------|
| VIABILITY (GO) | verde | `--accent-green` |
| VIABILITY (CAUTION) | amarillo | `--accent-yellow` |
| VIABILITY (NO-GO) | rojo | `--accent-red` |
| BLUEPRINT | azul (más prominente — el doc culmen) | `--accent-blue` |
| SECURITY-AUDIT (con Critical/High) | rojo | `--accent-red` |
| SECURITY-AUDIT (clean) | verde | `--accent-green` |
| PDR / TECH-SPEC / USER-STORIES / BMC / VPC / UX-* / UI-* / AI-FEATURE-BRIEF / LEAN-CANVAS / PRE-MORTEM | azul neutro | `--accent-blue` |

## CSS canónico

```css
:root {
  --bg-primary: #0a0a0f;
  --bg-card: rgba(255, 255, 255, 0.05);
  --bg-card-hover: rgba(255, 255, 255, 0.08);
  --border-card: rgba(255, 255, 255, 0.1);
  --text-primary: #f0f0f5;
  --text-secondary: rgba(240, 240, 245, 0.6);
  --text-muted: rgba(240, 240, 245, 0.4);
  --accent-green: #34d399;
  --accent-yellow: #fbbf24;
  --accent-red: #f87171;
  --accent-blue: #60a5fa;
  --accent-purple: #a78bfa;
  --radius: 16px;
  --blur: 20px;
}

* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }

body {
  font-family: system-ui, -apple-system, sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.7;
  font-size: 16px;
}

.layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  max-width: 1200px;
  margin: 0 auto;
  min-height: 100vh;
}

.sidebar {
  position: sticky;
  top: 0;
  align-self: start;
  height: 100vh;
  overflow-y: auto;
  padding: 2rem 1rem;
  border-right: 1px solid var(--border-card);
}

.sidebar h2 {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  margin-bottom: 0.75rem;
}

.sidebar ul { list-style: none; }
.sidebar a {
  display: block;
  padding: 0.4rem 0.75rem;
  color: var(--text-secondary);
  text-decoration: none;
  border-radius: 6px;
  font-size: 0.9rem;
  transition: background 0.15s, color 0.15s;
}
.sidebar a:hover { background: var(--bg-card); color: var(--text-primary); }

main { padding: 2rem 2.5rem; max-width: 900px; }

.header-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem 0.85rem;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  margin-bottom: 1rem;
}
.badge-blue { background: rgba(96, 165, 250, 0.15); color: var(--accent-blue); border: 1px solid rgba(96, 165, 250, 0.3); }
.badge-green { background: rgba(52, 211, 153, 0.15); color: var(--accent-green); border: 1px solid rgba(52, 211, 153, 0.3); }
.badge-yellow { background: rgba(251, 191, 36, 0.15); color: var(--accent-yellow); border: 1px solid rgba(251, 191, 36, 0.3); }
.badge-red { background: rgba(248, 113, 113, 0.15); color: var(--accent-red); border: 1px solid rgba(248, 113, 113, 0.3); }

h1 { font-size: 2.25rem; line-height: 1.2; margin-bottom: 0.75rem; }
h2 { font-size: 1.5rem; margin: 2.5rem 0 1rem; padding-bottom: 0.5rem; border-bottom: 1px solid var(--border-card); }
h3 { font-size: 1.15rem; margin: 1.75rem 0 0.75rem; color: var(--text-primary); }
h4 { font-size: 1rem; margin: 1.25rem 0 0.5rem; color: var(--text-secondary); }
p { margin-bottom: 1rem; color: var(--text-primary); }
ul, ol { margin: 0 0 1rem 1.5rem; }
li { margin-bottom: 0.4rem; }

a { color: var(--accent-blue); text-decoration: none; border-bottom: 1px dashed transparent; }
a:hover { border-bottom-color: var(--accent-blue); }

code {
  font-family: ui-monospace, SF Mono, Menlo, monospace;
  font-size: 0.875em;
  background: var(--bg-card);
  border: 1px solid var(--border-card);
  border-radius: 4px;
  padding: 0.1rem 0.35rem;
}
pre {
  background: var(--bg-card);
  backdrop-filter: blur(var(--blur));
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 1rem 1.25rem;
  overflow-x: auto;
  margin: 1rem 0;
  font-size: 0.875rem;
  line-height: 1.5;
}
pre code { background: transparent; border: 0; padding: 0; }

blockquote {
  border-left: 3px solid var(--accent-blue);
  padding: 0.5rem 1rem;
  margin: 1rem 0;
  color: var(--text-secondary);
  background: var(--bg-card);
  border-radius: 0 var(--radius) var(--radius) 0;
}

table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 0.9rem; }
th, td { padding: 0.6rem 0.85rem; text-align: left; border-bottom: 1px solid var(--border-card); }
th { color: var(--text-secondary); font-weight: 600; background: var(--bg-card); }
tr:hover td { background: var(--bg-card); }

details {
  background: var(--bg-card);
  backdrop-filter: blur(var(--blur));
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 0.5rem 1rem;
  margin: 1rem 0;
}
details summary {
  cursor: pointer;
  padding: 0.5rem 0;
  font-weight: 600;
  color: var(--text-primary);
  list-style: none;
}
details summary::-webkit-details-marker { display: none; }
details summary::before { content: "▸"; display: inline-block; margin-right: 0.5rem; transition: transform 0.15s; color: var(--text-muted); }
details[open] summary::before { transform: rotate(90deg); }

footer { margin-top: 3rem; padding-top: 1.5rem; border-top: 1px solid var(--border-card); color: var(--text-muted); font-size: 0.85rem; }

/* Mobile */
@media (max-width: 1024px) {
  .layout { grid-template-columns: 1fr; }
  .sidebar { position: static; height: auto; border-right: 0; border-bottom: 1px solid var(--border-card); padding: 1rem; }
  .sidebar-toggle { display: block; }
  .sidebar nav { display: none; }
  .sidebar.open nav { display: block; }
  main { padding: 1.5rem 1rem; }
  h1 { font-size: 1.75rem; }
}

/* Print */
@media print {
  :root {
    --bg-primary: #fff;
    --bg-card: #f7f7f9;
    --border-card: #ddd;
    --text-primary: #111;
    --text-secondary: #555;
    --text-muted: #888;
  }
  body { font-size: 11pt; }
  .sidebar { display: none; }
  .layout { grid-template-columns: 1fr; max-width: 100%; }
  main { padding: 0; max-width: 100%; }
  details { background: transparent; backdrop-filter: none; break-inside: avoid; }
  details > *:not(summary) { display: block !important; }   /* fuerza expandido en print */
  pre, blockquote { backdrop-filter: none; break-inside: avoid; }
  a { color: inherit; border-bottom: 0; }
  h1, h2 { break-after: avoid; }
}
```

## JS mínimo (sidebar toggle mobile)

```javascript
// Hamburger toggle solo en mobile (<1024px). Las secciones colapsibles usan <details> nativo.
document.querySelector('.sidebar-toggle')?.addEventListener('click', () => {
  document.querySelector('.sidebar').classList.toggle('open');
});
```

## Esqueleto canónico del HTML

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{TITLE} — Forja</title>
<style>{CSS_CANONICO}</style>
</head>
<body>
<div class="layout">
  <aside class="sidebar">
    <button class="sidebar-toggle" aria-label="Abrir navegación">☰</button>
    <nav>
      <h2>Secciones</h2>
      <ul>
        {NAV_ITEMS}  <!-- <li><a href="#section-id">Section title</a></li> por cada h2 -->
      </ul>
    </nav>
  </aside>
  <main>
    <span class="header-badge badge-{COLOR}">{DOC_TYPE_LABEL}</span>
    <h1>{H1_TITLE}</h1>
    <p class="subtitle">{SUBTITLE_DEL_DOC}</p>
    {CONTENIDO_RENDERIZADO}
    <footer>
      Generado por Forja v{VERSION} · {DATE_ISO}<br>
      Source: <code>{DOC_PATH}</code>
    </footer>
  </main>
</div>
<script>{JS_MINIMO}</script>
</body>
</html>
```

## Algoritmo de renderizado

El agente que invoca este prompt sigue estos pasos:

1. **Leer el `.md` completo** con el `Read` tool.
2. **Parsear secciones h2** (líneas que empiezan con `## `) → extraer títulos para la navegación lateral. Cada h2 obtiene un `id="section-N"` derivado del título en kebab-case.
3. **Convertir markdown a HTML** preservando TODO el contenido. Conversiones mínimas:
   - `# Título` → `<h1>Título</h1>` (la primera ocurrencia se usa como `H1_TITLE`).
   - `## Sección` → `<h2 id="section-id">Sección</h2>`.
   - `### / ####` → `<h3>` / `<h4>`.
   - `**bold**` → `<strong>`. `*italic*` → `<em>`. `` `code` `` → `<code>`.
   - Listas `- ` / `* ` / `1.` → `<ul><li>` / `<ol><li>`.
   - Tablas pipe `| col | col |` → `<table><tr><th>...</th></tr></table>`.
   - Bloques de código triple-backtick → `<pre><code>...</code></pre>` (escape HTML entities adentro).
   - Bloques `> ` → `<blockquote>`.
   - Links `[text](url)` → `<a href="url">text</a>`.
4. **Secciones h3 de bloques largos** (templates, checklists con >20 items) → wrap en `<details><summary>{título h3}</summary>...</details>` para colapsar.
5. **Determinar el color del badge** según `doc_type` y, si aplica, el veredicto extraído del `.md` (VIABILITY → buscar "GO" / "CAUTION" / "NO-GO" en h2 "Recomendación"; SECURITY-AUDIT → buscar "Critical: 0 · High: 0" → green, sino red).
6. **Escapar `</style>` y `</script>` en el contenido** del `.md` para no romper el HTML inline (si aparece en bloques de código markdown).
7. **Inyectar fecha** del momento (`new Date().toISOString().split('T')[0]`) y versión Forja (leer del `package.json` raíz si existe, fallback `0.1.x`).
8. **Escribir** el HTML al mismo directorio que el `.md`, con extensión `.html` (mismo basename).
9. **Reportar** en una línea: `✅ {basename}.md + {basename}.html generados ({dir})`.

## Reglas de fidelidad

- **NO** parafrasear el contenido del `.md`. La conversión es 1:1.
- **NO** agregar contenido no presente en el `.md`. Si el doc no tiene una sección, no inventarla.
- **NO** truncar contenido largo sin colapsar (usar `<details>` en lugar de cortar).
- **SÍ** preservar emojis, acentos, código.
- **SÍ** mantener el mismo orden de secciones del `.md`.
- **SÍ** linkear el `.md` source en el footer (`Source: .claude/PRPs/BLUEPRINT-{nombre}.md`).

## Edge cases

### `.md` vacío o sin h2
Renderizar igual con sidebar mostrando "Sin secciones — ver contenido completo abajo". El `<main>` muestra el contenido raw.

### `.md` con bloques de código que contienen `</style>` o `</script>`
Escapar como entidades HTML (`&lt;/style&gt;`) dentro del `<pre><code>`. NO romper el documento.

### `.md` extremadamente largo (>1000 líneas)
Renderizar todo igual — el `<details>` por h3 ya da progressive disclosure. No partir en múltiples archivos.

### `doc_type` desconocido
Fallback a badge azul neutro y label "DOCUMENTO".

### `.html` ya existe del run anterior
Sobreescribir sin warning. El `.md` es source of truth.

## R4/R5 enforcement

- **R4:** este prompt es invocado por sub-agents desde los assets de la-herreria. la-herreria MISMA NO genera HTML — sub-agent dispatched lo hace.
- **R5:** sub-agent NO escribe a `.claude/memory/*.md`. El HTML va al directorio del .md (state, no memory).
- **R10:** este HTML NO consume `brand.json` del proyecto target — usa la paleta interna de Forja (estos docs son de la-herreria, no UI generada para el proyecto). Por eso NO requiere PREFLIGHT R10.

## Refusals

- ❌ Generar HTML sin haber leído el `.md` first (riesgo de drift).
- ❌ Agregar libs externas (Chart.js, Tailwind CDN, fonts.googleapis) — todo embebido y standalone.
- ❌ Usar JS no-trivial — vanilla mínimo solo para sidebar toggle. Colapsibles con `<details>` nativo.
- ❌ Modificar el `.md` source (esto es solo lectura).
- ❌ Truncar contenido para "fit" en el HTML — `<details>` resuelve overflow visual sin perder info.

---

*"El agente lee `.md`. El humano lee `.html`. Ambos miran lo mismo."*
