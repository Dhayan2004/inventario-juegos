# render-tasks-html

> Genera `tasks.html` standalone leyendo `feature_list.json`. Dashboard visual de todas las features: estado, branches, evidence, verification command. Sin Chart.js — solo CSS puro y badges. Útil al humano para ver el board de un vistazo sin parsear el JSON.

## Cuándo invocar

| Trigger | Quién lo invoca |
|---------|-----------------|
| Usuario pide "ver tareas", "dashboard", "qué falta", "estado de features" | Coordinator (manual) |
| `/build` ofrece al final: "¿Genero el dashboard actualizado?" | la-forja / el-yunque |
| **Clean-State Exit (R12)** — al cerrar sesión, regenerar automático | el-yunque (siempre) |
| Post-passing en `/despachar` step 1 (informativo) | /despachar (opcional) |

## Inputs

```yaml
feature_list_path: feature_list.json   # default
project_name: <opcional — extraer del repo si no provisto>
```

## Output

`tasks.html` — standalone (sin servidor, sin CDN). Sobreescribir si existe.

Reportar al final:
```
✅ tasks.html actualizado — {passing}/{total} features passing ({active} active · {pending} pending · {blocked} blocked)
```

## Especificaciones técnicas

| Spec | Valor |
|------|-------|
| Formato | HTML5 standalone (sin servidor, sin CDN, sin libs externas) |
| Theme | Dark mode default — paleta canónica Forja (idéntica a render-doc-html.md) |
| Layout | Header full-width · 4 KPI cards en row · barra de progreso global · kanban (4 columnas o lista agrupada por state) |
| Tipografía | `system-ui, -apple-system, sans-serif` · body 14px/1.6 |
| Charts | **NO** — solo barras CSS y badges. Texto > deps CDN para un dashboard de status. |
| Interacción | Click en card = toggle expand para ver evidence/verification completos (`<details>`) |
| Mobile | <768px columnas colapsan a 1 col vertical |
| Print | `@media print` fondo blanco, badges legibles, todas las cards expandidas |

## CSS canónico (heredar de render-doc-html.md, mismas variables)

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
  --accent-grey: #9ca3af;
  --radius: 16px;
  --blur: 20px;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: system-ui, -apple-system, sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
  font-size: 14px;
  padding: 1.5rem;
}

.container { max-width: 1200px; margin: 0 auto; }

/* Header */
.header { margin-bottom: 2rem; }
.header h1 { font-size: 1.75rem; margin-bottom: 0.25rem; }
.header .meta { color: var(--text-secondary); font-size: 0.85rem; }

/* KPI cards row */
.kpis {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
  margin-bottom: 1.5rem;
}
.kpi {
  background: var(--bg-card);
  backdrop-filter: blur(var(--blur));
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 1.25rem;
}
.kpi .label { color: var(--text-secondary); font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
.kpi .value { font-size: 2rem; font-weight: 700; line-height: 1; }
.kpi.passing .value { color: var(--accent-green); }
.kpi.active .value { color: var(--accent-blue); }
.kpi.pending .value { color: var(--accent-grey); }
.kpi.blocked .value { color: var(--accent-red); }

/* Global progress bar */
.progress {
  background: var(--bg-card);
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 1.25rem;
  margin-bottom: 2rem;
}
.progress .label { color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 0.5rem; }
.progress .bar { height: 12px; background: rgba(255,255,255,0.06); border-radius: 999px; overflow: hidden; }
.progress .fill { height: 100%; background: linear-gradient(90deg, var(--accent-green), var(--accent-blue)); border-radius: 999px; transition: width 0.5s; }

/* Kanban */
.kanban {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
}
.column h2 {
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text-secondary);
  margin-bottom: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.column h2 .count { background: var(--bg-card); padding: 0.1rem 0.5rem; border-radius: 999px; font-size: 0.75rem; }

/* Feature card */
.card {
  background: var(--bg-card);
  backdrop-filter: blur(var(--blur));
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 1rem;
  margin-bottom: 0.75rem;
  transition: background 0.15s;
}
.card:hover { background: var(--bg-card-hover); }

.card-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; gap: 0.5rem; }
.card-head .id { font-family: ui-monospace, SF Mono, monospace; font-size: 0.8rem; color: var(--text-secondary); }

.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.15rem 0.55rem;
  border-radius: 999px;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.badge-passing { background: rgba(52, 211, 153, 0.15); color: var(--accent-green); }
.badge-active { background: rgba(96, 165, 250, 0.15); color: var(--accent-blue); }
.badge-pending { background: rgba(156, 163, 175, 0.15); color: var(--accent-grey); }
.badge-blocked { background: rgba(248, 113, 113, 0.15); color: var(--accent-red); }

.card .behavior { font-size: 0.875rem; color: var(--text-primary); margin-bottom: 0.5rem; }
.card .meta-line { font-size: 0.75rem; color: var(--text-muted); display: flex; gap: 0.75rem; flex-wrap: wrap; }
.card .meta-line code { font-family: ui-monospace, monospace; background: rgba(255,255,255,0.05); padding: 0.05rem 0.3rem; border-radius: 3px; }

details.expand { margin-top: 0.5rem; font-size: 0.8rem; }
details.expand summary { cursor: pointer; color: var(--text-secondary); list-style: none; }
details.expand summary::-webkit-details-marker { display: none; }
details.expand summary::before { content: "▸ "; color: var(--text-muted); }
details.expand[open] summary::before { content: "▾ "; }
details.expand .body { margin-top: 0.5rem; padding-top: 0.5rem; border-top: 1px solid var(--border-card); color: var(--text-secondary); }
details.expand .body strong { color: var(--text-primary); }

footer { margin-top: 2rem; color: var(--text-muted); font-size: 0.8rem; text-align: center; }

@media (max-width: 1024px) {
  .kanban { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 768px) {
  body { padding: 1rem; font-size: 13px; }
  .kpis { grid-template-columns: repeat(2, 1fr); }
  .kanban { grid-template-columns: 1fr; }
}

@media print {
  :root {
    --bg-primary: #fff;
    --bg-card: #f7f7f9;
    --border-card: #ddd;
    --text-primary: #111;
    --text-secondary: #555;
    --text-muted: #888;
  }
  body { padding: 0; }
  .card, .kpi, .progress { backdrop-filter: none; break-inside: avoid; }
  details.expand .body { display: block !important; }
  details.expand[open] summary::before, details.expand summary::before { content: ""; }
}
```

## Estructura HTML (esqueleto)

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Forja Tasks — {project_name}</title>
<style>{CSS_CANONICO}</style>
</head>
<body>
<div class="container">
  <header class="header">
    <h1>Forja Tasks · {project_name}</h1>
    <div class="meta">Phase: {phase} · Generado {date_iso} · Source: <code>feature_list.json</code></div>
  </header>

  <section class="kpis">
    <div class="kpi"><div class="label">Total</div><div class="value">{total}</div></div>
    <div class="kpi passing"><div class="label">Passing</div><div class="value">{passing}</div></div>
    <div class="kpi active"><div class="label">Active</div><div class="value">{active}</div></div>
    <div class="kpi pending"><div class="label">Pending / Blocked</div><div class="value">{pending_blocked}</div></div>
  </section>

  <section class="progress">
    <div class="label">Progreso global · {passing}/{total} ({pct}%)</div>
    <div class="bar"><div class="fill" style="width: {pct}%"></div></div>
  </section>

  <section class="kanban">
    <div class="column">
      <h2>Active <span class="count">{count_active}</span></h2>
      {CARDS_ACTIVE}
    </div>
    <div class="column">
      <h2>Passing <span class="count">{count_passing}</span></h2>
      {CARDS_PASSING}
    </div>
    <div class="column">
      <h2>Blocked <span class="count">{count_blocked}</span></h2>
      {CARDS_BLOCKED}
    </div>
    <div class="column">
      <h2>Pending <span class="count">{count_pending}</span></h2>
      {CARDS_PENDING}
    </div>
  </section>

  <footer>
    Actualizado: {date_iso} — Forja v{version}<br>
    Corré <code>/build</code> para avanzar la siguiente feature pendiente.
  </footer>
</div>
</body>
</html>
```

## Template por feature card

```html
<article class="card">
  <div class="card-head">
    <span class="id">{id}</span>
    <span class="badge badge-{state}">{state}</span>
  </div>
  <div class="behavior">{behavior_truncado_120chars}</div>
  <div class="meta-line">
    <span>branch: <code>{branch}</code></span>
    {commit_si_existe}
  </div>
  <details class="expand">
    <summary>Detalles</summary>
    <div class="body">
      {evidence_si_existe}
      <strong>verification:</strong> <code>{verification_command}</code>
    </div>
  </details>
</article>
```

## Reglas de mapeo `feature_list.json` → cards

- **Estados conocidos:** `passing` (verde) · `active` (azul) · `pending` (gris) · `blocked` (rojo).
- **Estado desconocido:** caer al estado `pending` (gris) y log en consola del agente que generó.
- **Truncar `behavior`** a 120 chars en la vista compacta. La full description se ve al expandir.
- **Truncar `evidence`** a 80 chars en summary, full en `<details>`.
- **`commit`:** mostrar solo los 7 chars iniciales (short hash); link no — es texto.
- **`branch`:** mostrar tal cual.
- **`verification`:** mostrar siempre dentro de `<details>` (puede ser largo).
- **Orden dentro de cada columna:** por `id` ascendente (F1-T1 antes que F2-S7, F2-S1 antes que F2-S10).
- **Si una columna queda vacía:** mostrar `<p class="meta">Sin features en este estado.</p>` para no dejar columna huérfana.

## Cálculo de KPIs

```javascript
total = features.length
passing = features.filter(f => f.state === 'passing').length
active = features.filter(f => f.state === 'active').length
pending = features.filter(f => f.state === 'pending').length
blocked = features.filter(f => f.state === 'blocked').length
pending_blocked = pending + blocked
pct = total === 0 ? 0 : Math.round((passing / total) * 100)
```

R1 enforcement informativo: si `active > 1`, mostrar warning banner debajo del header:
```html
<div class="warning">⚠️ R1 violation — {active} features en active simultáneamente. Solo 1 permitida.</div>
```
(con `--accent-red` border-left).

## Algoritmo (lo que hace el agente al invocar este prompt)

1. **Leer** `feature_list.json` con `Read` tool.
2. **Parsear** JSON → extraer `phase`, `project_name` (si está; si no, derivar del repo path), `features[]`.
3. **Calcular KPIs** (total, passing, active, pending, blocked, pct).
4. **Agrupar features por state** en 4 columnas.
5. **Construir cards** con el template — escapar HTML entities en behavior/evidence/branch/verification.
6. **Validar R1**: si `active > 1`, agregar warning banner.
7. **Inyectar fecha** del momento (`new Date().toISOString().split('T')[0]`) y versión Forja (leer `package.json` si existe, fallback `0.1.x`).
8. **Escribir** HTML completo a `tasks.html` (sobreescribir).
9. **Reportar:** `✅ tasks.html actualizado — {passing}/{total} features passing ({active} active · {pending} pending · {blocked} blocked)`.

## Edge cases

### `feature_list.json` no existe
Halt: `"feature_list.json no encontrado en . Corré /forge-init para inicializar."` NO crear tasks.html vacío.

### `feature_list.json` con 0 features
Generar tasks.html igual con KPIs = 0 y un mensaje informativo: "Sin features en el backlog. Empezá con /plan o agregá features manualmente al feature_list.json."

### `feature_list.json` con campos faltantes (sin verification, sin evidence)
Renderizar igual; mostrar "—" en lugar de campos faltantes. NO halt — datos parciales son aceptables.

### `feature_list.json` con `active > 1` (R1 violation)
Renderizar todas las active en la columna pero agregar warning banner R1 al inicio. NO halt — el dashboard sirve para detectar el problema.

### Schema version desconocido
Renderizar best-effort. Si campos esenciales (id, behavior, state) faltan en una feature, omitir esa feature y log en el reporte final.

## R4/R5 enforcement

- **R4:** este prompt es invocado por sub-agents (desde el-yunque, /build, etc.). Los orchestrators NO escriben HTML directo.
- **R5:** sub-agent NO escribe a `.claude/memory/*.md`. `tasks.html` va a `` (state, no memory).
- **R10:** este HTML usa la paleta interna de Forja, NO consume `brand.json` del proyecto target. Igual que render-doc-html.md.

## Refusals

- ❌ Inventar features no presentes en el JSON.
- ❌ Reordenar la lista por algo distinto a `id` ascendente.
- ❌ Agregar libs externas (Chart.js, Tailwind CDN) — todo embebido.
- ❌ Modificar `feature_list.json` (read-only desde este prompt).
- ❌ Generar tasks.html sin haber leído el JSON first.
- ❌ Saltar el cálculo R1 violation (es información crítica para el humano).

---

*"El JSON es el source of truth. El HTML es el cristal por donde el humano lo mira."*
