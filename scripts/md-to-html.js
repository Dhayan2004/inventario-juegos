#!/usr/bin/env node
/**
 * md-to-html.js — Forja Markdown → HTML standalone
 *
 * Usage:
 *   node scripts/md-to-html.js INPUT.md OUTPUT.html [--title "Page Title"]
 *
 * No npm deps. Uses only Node built-in modules.
 * CSS/theme matches el-crisol/build-dashboard.md (Forja dark mode canónico).
 */

'use strict';

const fs   = require('fs');
const path = require('path');

const [,, inputArg, outputArg, ...rest] = process.argv;

if (!inputArg || !outputArg) {
  console.error('Usage: node scripts/md-to-html.js INPUT.md OUTPUT.html [--title "Title"]');
  process.exit(1);
}

const titleFlag = rest.indexOf('--title');
const overrideTitle = titleFlag !== -1 ? rest[titleFlag + 1] : null;

const mdText   = fs.readFileSync(inputArg, 'utf8');
const lines    = mdText.split('\n');

// ── helpers ───────────────────────────────────────────────────────────────────

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function inline(s) {
  // order matters: escape HTML first, then apply inline markup
  s = esc(s);
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  s = s.replace(/\*([^*]+)\*/g,     '<em>$1</em>');
  s = s.replace(/`([^`]+)`/g,       '<code>$1</code>');
  s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  return s;
}

function slugify(text) {
  return text.toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/[\s]+/g, '-')
    .replace(/-+/g, '-');
}

// ── first pass: extract h1 (title) + h2 (nav) ────────────────────────────────

let docTitle   = overrideTitle || path.basename(inputArg, '.md');
const navItems = [];

for (const line of lines) {
  if (/^# (?!#)/.test(line) && !overrideTitle) {
    docTitle = line.slice(2).trim();
  } else if (/^## (?!#)/.test(line)) {
    const text = line.slice(3).trim();
    navItems.push({ text, id: slugify(text) });
  }
}

// ── second pass: render body ──────────────────────────────────────────────────

let body      = '';
let inCode    = false;
let inTable   = false;
let inList    = false;
let inBlockq  = false;
let firstH1   = false;

function closeOpen() {
  if (inList)   { body += '</ul>\n';               inList   = false; }
  if (inTable)  { body += '</tbody></table>\n';    inTable  = false; }
  if (inBlockq) { body += '</blockquote>\n';       inBlockq = false; }
}

for (let i = 0; i < lines.length; i++) {
  const raw = lines[i];
  const trimmed = raw.trim();

  // ── code block fence ──────────────────────────────────────────────────────
  if (/^```/.test(raw)) {
    if (inCode) {
      body   += '</code></pre>\n';
      inCode  = false;
    } else {
      closeOpen();
      const lang = raw.slice(3).trim() || 'text';
      body   += `<pre><code class="lang-${esc(lang)}">`;
      inCode  = true;
    }
    continue;
  }

  if (inCode) {
    body += esc(raw) + '\n';
    continue;
  }

  // ── table row ─────────────────────────────────────────────────────────────
  if (/^\|/.test(trimmed)) {
    // skip separator rows like |---|---|
    if (/^\|[\s\-:|]+\|/.test(trimmed) && !/[a-zA-Z0-9{}]/.test(trimmed)) {
      continue;
    }
    const cells = trimmed
      .replace(/^\|/, '')
      .replace(/\|$/, '')
      .split('|')
      .map(c => c.trim());

    if (!inTable) {
      closeOpen();
      inTable = true;
      body += '<table>\n<thead><tr>';
      cells.forEach(c => { body += `<th>${inline(c)}</th>`; });
      body += '</tr></thead>\n<tbody>\n';
    } else {
      body += '<tr>';
      cells.forEach(c => { body += `<td>${inline(c)}</td>`; });
      body += '</tr>\n';
    }
    continue;
  } else if (inTable) {
    body   += '</tbody></table>\n';
    inTable = false;
  }

  // ── headings ──────────────────────────────────────────────────────────────
  if (/^#{1,6} /.test(raw)) {
    closeOpen();
    const level = raw.match(/^(#{1,6}) /)[1].length;
    const text  = raw.slice(level + 1).trim();
    if (level === 1) {
      if (!firstH1) {
        body  += `<h1>${inline(text)}</h1>\n`;
        firstH1 = true;
      }
      // don't repeat h1 if already emitted
    } else {
      const id = slugify(text);
      body += `<h${level} id="${id}">${inline(text)}</h${level}>\n`;
    }
    continue;
  }

  // ── horizontal rule ───────────────────────────────────────────────────────
  if (/^---+$/.test(trimmed) || /^═{3,}/.test(trimmed) || /^\*{3,}$/.test(trimmed)) {
    closeOpen();
    body += '<hr>\n';
    continue;
  }

  // ── blockquote ────────────────────────────────────────────────────────────
  if (/^> /.test(raw)) {
    if (inList) { body += '</ul>\n'; inList = false; }
    if (!inBlockq) {
      body   += '<blockquote>\n';
      inBlockq = true;
    }
    body += `<p>${inline(raw.slice(2))}</p>\n`;
    continue;
  } else if (inBlockq) {
    body   += '</blockquote>\n';
    inBlockq = false;
  }

  // ── list items ────────────────────────────────────────────────────────────
  if (/^(\s*)[-*] /.test(raw)) {
    if (!inList) {
      body  += '<ul>\n';
      inList = true;
    }
    const content = raw.replace(/^\s*[-*] /, '');
    // checkbox pattern: [ ] or [x]
    const withCheck = content
      .replace(/^\[x\] /, '<input type="checkbox" checked disabled> ')
      .replace(/^\[ \] /, '<input type="checkbox" disabled> ');
    body += `<li>${inline(withCheck)}</li>\n`;
    continue;
  } else if (inList && trimmed !== '') {
    body  += '</ul>\n';
    inList = false;
  }

  // ── empty line ────────────────────────────────────────────────────────────
  if (trimmed === '') {
    if (inList)   { body += '</ul>\n';            inList   = false; }
    if (inTable)  { body += '</tbody></table>\n'; inTable  = false; }
    if (inBlockq) { body += '</blockquote>\n';    inBlockq = false; }
    body += '\n';
    continue;
  }

  // ── paragraph ─────────────────────────────────────────────────────────────
  body += `<p>${inline(raw)}</p>\n`;
}

closeOpen();
if (inCode) body += '</code></pre>\n';

// ── build nav HTML ────────────────────────────────────────────────────────────

const navHtml = navItems.length
  ? `<ul>\n${navItems.map(n => `<li><a href="#${n.id}">${esc(n.text)}</a></li>`).join('\n')}\n</ul>`
  : '<p class="muted">—</p>';

// ── Forja canonical CSS (matches el-crisol/build-dashboard.md) ───────────────

const CSS = `
:root {
  --bg-primary:    #0a0a0f;
  --bg-card:       rgba(255,255,255,0.05);
  --bg-card-hover: rgba(255,255,255,0.08);
  --border-card:   rgba(255,255,255,0.1);
  --text-primary:  #f0f0f5;
  --text-secondary:rgba(240,240,245,0.6);
  --text-muted:    rgba(240,240,245,0.4);
  --accent-green:  #34d399;
  --accent-yellow: #fbbf24;
  --accent-red:    #f87171;
  --accent-blue:   #60a5fa;
  --accent-purple: #a78bfa;
  --radius:        16px;
  --blur:          20px;
}
*, *::before, *::after { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body {
  font-family: system-ui,-apple-system,sans-serif;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.75;
  font-size: 15px;
}
.layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  max-width: 1200px;
  margin: 0 auto;
  min-height: 100vh;
}
/* ── sidebar ── */
.sidebar {
  position: sticky;
  top: 0;
  align-self: start;
  height: 100vh;
  overflow-y: auto;
  padding: 2rem 1rem 2rem 1.25rem;
  border-right: 1px solid var(--border-card);
  scrollbar-width: thin;
  scrollbar-color: var(--border-card) transparent;
}
.sidebar-title {
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  margin-bottom: 0.75rem;
}
.sidebar ul { list-style: none; }
.sidebar a {
  display: block;
  padding: 0.35rem 0.6rem;
  color: var(--text-secondary);
  text-decoration: none;
  border-radius: 6px;
  font-size: 0.85rem;
  transition: background 0.15s, color 0.15s;
}
.sidebar a:hover,
.sidebar a.active { background: var(--bg-card); color: var(--text-primary); }
.sidebar .muted { color: var(--text-muted); font-size: 0.85rem; padding-left: 0.6rem; }
.sidebar-toggle {
  display: none;
  background: var(--bg-card);
  border: 1px solid var(--border-card);
  color: var(--text-primary);
  padding: 0.4rem 0.8rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  margin-bottom: 0.75rem;
}
/* ── main ── */
main {
  padding: 2.5rem 2.5rem 4rem;
  max-width: 860px;
  min-width: 0;
}
h1 { font-size: 2rem; line-height: 1.2; margin-bottom: 0.5rem; }
h2 {
  font-size: 1.35rem;
  margin: 2.5rem 0 0.9rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--border-card);
  scroll-margin-top: 1.5rem;
}
h3 { font-size: 1.1rem; margin: 1.75rem 0 0.6rem; color: var(--text-primary); }
h4 { font-size: 0.95rem; margin: 1.25rem 0 0.4rem; color: var(--text-secondary); }
p { margin-bottom: 0.85rem; }
ul { margin: 0.5rem 0 0.85rem 1.5rem; }
li { margin-bottom: 0.3rem; }
strong { color: var(--text-primary); }
em { color: var(--text-secondary); font-style: italic; }
a { color: var(--accent-blue); text-decoration: none; border-bottom: 1px dashed transparent; transition: border-color 0.15s; }
a:hover { border-bottom-color: var(--accent-blue); }
hr { border: none; border-top: 1px solid var(--border-card); margin: 2rem 0; }
code {
  font-family: ui-monospace,"SF Mono",Menlo,monospace;
  font-size: 0.85em;
  background: rgba(255,255,255,0.07);
  border: 1px solid var(--border-card);
  border-radius: 4px;
  padding: 0.1rem 0.35rem;
}
pre {
  background: rgba(255,255,255,0.04);
  backdrop-filter: blur(var(--blur));
  -webkit-backdrop-filter: blur(var(--blur));
  border: 1px solid var(--border-card);
  border-radius: var(--radius);
  padding: 1.1rem 1.25rem;
  overflow-x: auto;
  margin: 1rem 0 1.25rem;
  font-size: 0.83rem;
  line-height: 1.55;
}
pre code { background: transparent; border: none; padding: 0; font-size: inherit; }
blockquote {
  border-left: 3px solid var(--accent-blue);
  padding: 0.5rem 1.1rem;
  margin: 1rem 0;
  background: rgba(96,165,250,0.06);
  border-radius: 0 var(--radius) var(--radius) 0;
  color: var(--text-secondary);
}
blockquote p { margin-bottom: 0.4rem; }
blockquote p:last-child { margin-bottom: 0; }
table {
  width: 100%;
  border-collapse: collapse;
  margin: 1rem 0 1.25rem;
  font-size: 0.88rem;
}
th, td {
  padding: 0.55rem 0.85rem;
  text-align: left;
  border-bottom: 1px solid var(--border-card);
}
th {
  color: var(--text-secondary);
  font-weight: 600;
  background: rgba(255,255,255,0.04);
  white-space: nowrap;
}
tr:hover td { background: rgba(255,255,255,0.03); }
input[type="checkbox"] { margin-right: 0.4rem; accent-color: var(--accent-green); }
/* ── mobile ── */
@media (max-width: 1024px) {
  .layout { grid-template-columns: 1fr; }
  .sidebar {
    position: static;
    height: auto;
    border-right: none;
    border-bottom: 1px solid var(--border-card);
    padding: 1rem;
  }
  .sidebar-toggle { display: block; }
  .sidebar nav { display: none; }
  .sidebar.open nav { display: block; }
  main { padding: 1.5rem 1rem 3rem; }
  h1 { font-size: 1.6rem; }
}
/* ── print ── */
@media print {
  :root {
    --bg-primary: #fff;
    --bg-card: #f5f5f8;
    --border-card: #ddd;
    --text-primary: #111;
    --text-secondary: #555;
    --text-muted: #888;
  }
  .sidebar { display: none; }
  .layout { display: block; max-width: 100%; }
  main { padding: 0; max-width: 100%; }
  pre { backdrop-filter: none; break-inside: avoid; }
  a { color: inherit; border-bottom: none; }
  h2 { break-after: avoid; }
}
`.trim();

const JS = `
document.querySelector('.sidebar-toggle')?.addEventListener('click', () => {
  document.querySelector('.sidebar').classList.toggle('open');
});

// Highlight active nav item on scroll
const headings = document.querySelectorAll('main h2[id]');
const links    = document.querySelectorAll('.sidebar a');
const obs = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      links.forEach(l => l.classList.remove('active'));
      const a = document.querySelector('.sidebar a[href="#'+e.target.id+'"]');
      if (a) a.classList.add('active');
    }
  });
}, { rootMargin: '-20% 0px -70% 0px' });
headings.forEach(h => obs.observe(h));
`.trim();

const generatedAt = new Date().toISOString().slice(0, 10);
const srcFile     = path.basename(inputArg);

const fullHtml = `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${esc(docTitle)}</title>
<style>${CSS}</style>
</head>
<body>
<div class="layout">
  <aside class="sidebar">
    <button class="sidebar-toggle" aria-label="Menú">☰ Secciones</button>
    <p class="sidebar-title">Contenido</p>
    <nav>
${navHtml}
    </nav>
  </aside>
  <main>
${body.trim()}
    <hr>
    <p style="color:var(--text-muted);font-size:0.8rem;text-align:right">
      Generado ${generatedAt} · fuente <code>${esc(srcFile)}</code>
    </p>
  </main>
</div>
<script>${JS}</script>
</body>
</html>`;

fs.writeFileSync(outputArg, fullHtml, 'utf8');
console.log(`✅  ${outputArg}  (${(fullHtml.length / 1024).toFixed(1)} kB)`);
