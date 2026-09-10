#!/usr/bin/env node
// apply-ontology-migrations.mjs — S3 · versionado de esquema del ONTOLOGY.md
//
// Runner Node ZERO-DEP (stdlib only) que propaga cambios de ESTRUCTURA del esquema de
// `ONTOLOGY.md` (secciones/campos nuevos) a ontologías ya llenadas por un cliente, SIN
// tocar los datos. Mismo problema que resuelve `apply-brand-migrations.py` de Estudio sobre
// `BRAND.md` (docs/04) — este es su port a Forge Enterprise, gobernado por `ontology_version`.
//
// Mecánica: migraciones con anchor + tracking (ledger) + idempotencia (check_line) + backup,
// dry-run por default. Ver `.claude/ontology-migrations/README.md` para el formato.
//
// Uso (desde la raíz de un proyecto con ONTOLOGY.md):
//   node scripts/apply-ontology-migrations.mjs                 # dry-run (default, nada se escribe)
//   node scripts/apply-ontology-migrations.mjs --apply
//   node scripts/apply-ontology-migrations.mjs --apply --migration=0001
//   node scripts/apply-ontology-migrations.mjs --template-dir=/ruta/al/template
//
// Convención Forge: target = ONTOLOGY.md (raíz) · migraciones = <template>/.claude/ontology-migrations/
//   ledger = .forja/ontology.migrations (VERSIONADO — el equipo comparte el estado aplicado)
//   backup = .forja/ontology-backups/<timestamp>/ONTOLOGY.md (efímero, gitignored)
//
// Origen del patrón: estudio/apply-brand-migrations.py (MIT). Reimplementado en Node por
// consistencia con el tooling zero-dep del harness (inventory.js, plan-server.mjs, md-to-html.js).

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Frontmatter YAML manual (subset: `key: value` planos) ──────────────────────
function parseFrontmatter(text) {
  if (!text.startsWith('---')) return { meta: {}, body: text };
  const parts = text.split('---');
  // parts[0] === '' (antes del primer ---), parts[1] = frontmatter, resto = cuerpo
  if (parts.length < 3) return { meta: {}, body: text };
  const meta = {};
  for (let line of parts[1].split('\n')) {
    line = line.trim();
    if (!line || line.startsWith('#')) continue;
    const idx = line.indexOf(':');
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    let value = line.slice(idx + 1).trim();
    value = value.replace(/^["']|["']$/g, '');
    meta[key] = value;
  }
  const body = parts.slice(2).join('---').trim();
  return { meta, body };
}

function loadMigrations(migrationsDir) {
  if (!fs.existsSync(migrationsDir)) return [];
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.md') && f !== 'README.md')
    .sort();
  const result = [];
  for (const f of files) {
    const content = fs.readFileSync(path.join(migrationsDir, f), 'utf8');
    const { meta, body } = parseFrontmatter(content);
    if (meta.migration_id) {
      meta._body = body;
      result.push(meta);
    }
  }
  return result;
}

function loadApplied(ledgerFile) {
  const applied = new Set();
  if (fs.existsSync(ledgerFile)) {
    for (const line of fs.readFileSync(ledgerFile, 'utf8').split('\n')) {
      const id = line.trim().split(/\s+/)[0];
      if (id) applied.add(id);
    }
  }
  return applied;
}

function markApplied(ledgerFile, migrationId) {
  fs.mkdirSync(path.dirname(ledgerFile), { recursive: true });
  const ts = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
  fs.appendFileSync(ledgerFile, `${migrationId} ${ts}\n`);
}

function lineExistsInFile(filePath, checkLine) {
  if (!checkLine) return false;
  return fs.readFileSync(filePath, 'utf8').includes(checkLine);
}

// Backup one-shot por corrida --apply (antes de la primera escritura).
function backupOntology(ontologyPath, baseDir) {
  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const dir = path.join(baseDir, '.forja', 'ontology-backups', ts);
  fs.mkdirSync(dir, { recursive: true });
  fs.copyFileSync(ontologyPath, path.join(dir, 'ONTOLOGY.md'));
  return path.relative(baseDir, path.join(dir, 'ONTOLOGY.md'));
}

function injectIntoOntology(ontologyPath, anchor, position, content, dryRun) {
  const lines = fs.readFileSync(ontologyPath, 'utf8').split('\n');
  let anchorIdx = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trimEnd() === anchor.trimEnd()) {
      anchorIdx = i;
      break;
    }
  }
  if (anchorIdx === -1) return { ok: false, msg: `Anchor no encontrado: '${anchor}'` };

  const inject = ['', ...content.split('\n'), ''];
  let out;
  if (position === 'before') {
    out = [...lines.slice(0, anchorIdx), ...inject, ...lines.slice(anchorIdx)];
  } else {
    out = [...lines.slice(0, anchorIdx + 1), ...inject, ...lines.slice(anchorIdx + 1)];
  }
  if (!dryRun) fs.writeFileSync(ontologyPath, out.join('\n'));
  return { ok: true, msg: 'OK' };
}

function applyCreatePath(baseDir, pathsStr, readmeContent, dryRun) {
  const paths = (pathsStr || '').split(',').map((p) => p.trim()).filter(Boolean);
  const created = [];
  for (const p of paths) {
    const full = path.join(baseDir, p);
    if (!fs.existsSync(full)) {
      if (!dryRun) {
        fs.mkdirSync(full, { recursive: true });
        fs.writeFileSync(path.join(full, '.gitkeep'), '');
      }
      created.push(p);
    }
  }
  if (paths.length && readmeContent) {
    const readme = path.normalize(path.join(baseDir, paths[0], '..', 'README.md'));
    if (!fs.existsSync(readme)) {
      if (!dryRun) fs.writeFileSync(readme, readmeContent);
      created.push(path.relative(baseDir, readme));
    }
  }
  return created;
}

// Sella `ontology_version` en el frontmatter del ONTOLOGY.md (gobierno de versión, §9 del schema).
function stampVersion(ontologyPath, version, dryRun) {
  if (!version) return false;
  const text = fs.readFileSync(ontologyPath, 'utf8');
  const re = /^(ontology_version:\s*).*$/m;
  if (!re.test(text)) return false;
  const next = text.replace(re, `$1"${version}"`);
  if (next === text) return false;
  if (!dryRun) fs.writeFileSync(ontologyPath, next);
  return true;
}

function main() {
  const argv = process.argv.slice(2);
  const dryRun = !argv.includes('--apply');
  let onlyMigration = null;
  let templateDir = process.env.FORGE_TEMPLATE || path.join(__dirname, '..');
  for (const arg of argv) {
    if (arg.startsWith('--migration=')) onlyMigration = arg.split('=', 2)[1];
    else if (arg.startsWith('--template-dir=')) templateDir = arg.split('=', 2)[1];
  }

  const baseDir = process.cwd();
  const ontologyMd = path.join(baseDir, 'ONTOLOGY.md');
  const migrationsDir = path.join(templateDir, '.claude', 'ontology-migrations');
  const ledgerFile = path.join(baseDir, '.forja', 'ontology.migrations');

  // ── Safety ──────────────────────────────────────────────────────────────────
  if (!fs.existsSync(ontologyMd)) {
    console.error('❌ No hay ONTOLOGY.md en este directorio.');
    console.error('   Este runner solo corre desde la RAÍZ de un proyecto con ontología emitida');
    console.error('   (el-ontologo · discovery_completed: true). No corre desde el template.');
    process.exit(1);
  }
  if (path.resolve(migrationsDir).startsWith(path.resolve(baseDir) + path.sep) &&
      path.resolve(baseDir) === path.resolve(templateDir)) {
    console.error('❌ No corras el runner desde el propio template. Corré desde un proyecto objetivo.');
    process.exit(1);
  }

  const migrations = loadMigrations(migrationsDir);
  if (migrations.length === 0) {
    console.log(`ℹ️  No hay migraciones disponibles en: ${migrationsDir}`);
    process.exit(0);
  }

  const applied = loadApplied(ledgerFile);
  const modeLabel = dryRun ? 'DRY RUN — preview (nada se escribe)' : 'APPLY';

  console.log('═══════════════════════════════════════════════════════════════');
  console.log(`  Migraciones ONTOLOGY.md — ${modeLabel}`);
  console.log('═══════════════════════════════════════════════════════════════');
  console.log(`  Proyecto:            ${baseDir}`);
  console.log(`  Migraciones totales: ${migrations.length}`);
  console.log(`  Ya aplicadas:        ${applied.size}`);
  console.log('');

  const pending = [];
  for (const m of migrations) {
    const mid = m.migration_id || '';
    if (onlyMigration && mid !== onlyMigration) continue;
    if (applied.has(mid)) continue;
    if (m.check_line && lineExistsInFile(ontologyMd, m.check_line)) {
      console.log(`  ⏭️  ${mid} — ya presente en ONTOLOGY.md → marcando como aplicada`);
      if (!dryRun) markApplied(ledgerFile, mid);
      continue;
    }
    pending.push(m);
  }

  if (pending.length === 0) {
    console.log('  ✅ ONTOLOGY.md al día. No hay migraciones pendientes.');
    process.exit(0);
  }

  console.log(`  Pendientes: ${pending.length}`);
  console.log('');

  let backedUp = dryRun; // en dry-run no hay backup que hacer
  let appliedCount = 0;
  const errors = [];

  for (const m of pending) {
    const mid = m.migration_id || '';
    const title = m.title || '';
    const mtype = m.type || 'ontology_md';
    const body = m._body || '';
    const prefix = dryRun ? '[DRY RUN] ' : '';
    console.log(`  ${prefix}Migración ${mid}: ${title}`);

    // Backup one-shot antes de la primera escritura real.
    if (!backedUp) {
      const rel = backupOntology(ontologyMd, baseDir);
      console.log(`    💾 Backup: ${rel}`);
      backedUp = true;
    }

    if (mtype === 'ontology_md') {
      const anchor = m.anchor || '';
      const position = m.position || 'after';
      if (!anchor) {
        const msg = "falta campo 'anchor' en la migración";
        console.log(`    ❌ ${msg}`);
        errors.push(`${mid}: ${msg}`);
        continue;
      }
      const { ok, msg } = injectIntoOntology(ontologyMd, anchor, position, body, dryRun);
      if (ok) {
        console.log(`    ✅ Inyectado${dryRun ? ' (simulado)' : ''} — ${position} de '${anchor.slice(0, 50)}'`);
        if (stampVersion(ontologyMd, m.ontology_version, dryRun)) {
          console.log(`    🔖 ontology_version → "${m.ontology_version}"${dryRun ? ' (simulado)' : ''}`);
        }
        appliedCount++;
        if (!dryRun) markApplied(ledgerFile, mid);
      } else {
        console.log(`    ⚠️  ${msg}`);
        errors.push(`${mid}: ${msg}`);
      }
    } else if (mtype === 'create_path') {
      const created = applyCreatePath(baseDir, m.paths, body, dryRun);
      if (created.length) {
        for (const p of created) console.log(`    ✅ ${dryRun ? 'Crearía' : 'Creado'}: ${p}`);
      } else {
        console.log('    ⏭️  Paths ya existen, nada que crear');
      }
      if (stampVersion(ontologyMd, m.ontology_version, dryRun)) {
        console.log(`    🔖 ontology_version → "${m.ontology_version}"${dryRun ? ' (simulado)' : ''}`);
      }
      appliedCount++;
      if (!dryRun) markApplied(ledgerFile, mid);
    } else {
      console.log(`    ⚠️  Tipo desconocido: ${mtype}`);
      errors.push(`${mid}: tipo desconocido '${mtype}'`);
    }
    console.log('');
  }

  console.log('═══════════════════════════════════════════════════════════════');
  if (dryRun) {
    console.log(`  DRY RUN completo — ${appliedCount} migración(es) pendiente(s).`);
    console.log('');
    console.log('  Para aplicar:');
    console.log('    node scripts/apply-ontology-migrations.mjs --apply');
  } else {
    console.log(`  ✅ ${appliedCount} migración(es) aplicada(s).`);
    if (errors.length) {
      console.log(`  ⚠️  ${errors.length} error(es):`);
      for (const e of errors) console.log(`    - ${e}`);
    }
  }
  console.log('═══════════════════════════════════════════════════════════════');

  process.exit(errors.length ? 1 : 0);
}

main();
