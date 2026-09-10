#!/usr/bin/env node
/*
 * design-diversity.mjs — ¿las N variantes de Discover son distintas de verdad, o "diversidad de teatro"?
 * (D-037 · A7: NoveltyBench / Gu 2026 — N strings distintas pueden mapear al MISMO layout púrpura)
 *
 * Mide diversidad a nivel de PANTALLA, no de semilla: aHash 8×8 (average hash) de cada screenshot y
 * distancia de Hamming entre pares. Si ≥ COLLAPSE_MIN variantes caen dentro de COLLAPSE_DIST bits de
 * otra, el batch colapsó al prior (SSoT ceremonial) → COLLAPSE, exit 1: se regenera con semillas nuevas,
 * no se "varía un poco".
 *
 *   node scripts/design-diversity.mjs design-lab/2026-09-02-landing            # busca vN/screenshot@desktop.png
 *   node scripts/design-diversity.mjs a.png b.png c.png d.png                   # archivos sueltos
 *   node scripts/design-diversity.mjs --selftest                                # fixtures sintéticos
 *
 * Zero-dep: decodifica PNG (8-bit, no entrelazado, color 0/2/4/6) con node:zlib. Un hash perceptual
 * simple basta para detectar "mismo layout, mismo hero, misma paleta"; no pretende ser CLIP.
 */
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import os from 'node:os';

const COLLAPSE_DIST = Number(process.env.COLLAPSE_DIST ?? 10); // bits de 64 (≤10 ≈ misma composición)
const COLLAPSE_MIN = Number(process.env.COLLAPSE_MIN ?? 3);    // ≥3 de 5 iguales = colapso (doc 01 §9)

// ── PNG decode (mínimo) ─────────────────────────────────────────────────────
function decodePNG(buf) {
  const SIG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (!buf.subarray(0, 8).equals(SIG)) throw new Error('no es PNG');
  let off = 8, w = 0, h = 0, depth = 0, ctype = 0, interlace = 0;
  const idat = [];
  while (off < buf.length) {
    const len = buf.readUInt32BE(off); const type = buf.toString('ascii', off + 4, off + 8);
    const data = buf.subarray(off + 8, off + 8 + len);
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); depth = data[8]; ctype = data[9]; interlace = data[12]; }
    else if (type === 'IDAT') idat.push(data);
    else if (type === 'IEND') break;
    off += 12 + len;
  }
  if (depth !== 8) throw new Error(`bit depth ${depth} no soportado (solo 8)`);
  if (interlace) throw new Error('PNG entrelazado no soportado');
  const ch = { 0: 1, 2: 3, 4: 2, 6: 4 }[ctype];
  if (!ch) throw new Error(`color type ${ctype} no soportado (0/2/4/6)`);
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * ch; const out = Buffer.alloc(h * stride);
  let p = 0;
  for (let y = 0; y < h; y++) {
    const f = raw[p++]; const row = out.subarray(y * stride, (y + 1) * stride);
    const prev = y ? out.subarray((y - 1) * stride, y * stride) : null;
    for (let x = 0; x < stride; x++) {
      const a = x >= ch ? row[x - ch] : 0, b = prev ? prev[x] : 0, c = (prev && x >= ch) ? prev[x - ch] : 0;
      const v = raw[p++];
      let r;
      switch (f) {
        case 0: r = v; break;
        case 1: r = v + a; break;
        case 2: r = v + b; break;
        case 3: r = v + ((a + b) >> 1); break;
        case 4: { const pa = Math.abs(b - c), pb = Math.abs(a - c), pc = Math.abs(a + b - 2 * c); r = v + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c); break; }
        default: throw new Error(`filtro PNG ${f} inválido`);
      }
      row[x] = r & 255;
    }
  }
  return { w, h, ch, data: out };
}

function gray(img, x, y) {
  const i = (y * img.w + x) * img.ch;
  if (img.ch <= 2) return img.data[i];
  return 0.299 * img.data[i] + 0.587 * img.data[i + 1] + 0.114 * img.data[i + 2];
}

/** aHash 8×8: promedio por celda, bit = celda > media global. 64 bits como string binaria. */
function ahash(img) {
  const cells = [];
  for (let cy = 0; cy < 8; cy++) for (let cx = 0; cx < 8; cx++) {
    const x0 = Math.floor(cx * img.w / 8), x1 = Math.max(x0 + 1, Math.floor((cx + 1) * img.w / 8));
    const y0 = Math.floor(cy * img.h / 8), y1 = Math.max(y0 + 1, Math.floor((cy + 1) * img.h / 8));
    let s = 0, n = 0;
    const sx = Math.max(1, Math.floor((x1 - x0) / 16)), sy = Math.max(1, Math.floor((y1 - y0) / 16));
    for (let y = y0; y < y1; y += sy) for (let x = x0; x < x1; x += sx) { s += gray(img, x, y); n++; }
    cells.push(s / n);
  }
  const mean = cells.reduce((a, b) => a + b, 0) / 64;
  return cells.map(c => (c > mean ? '1' : '0')).join('');
}
const hamming = (a, b) => { let d = 0; for (let i = 0; i < 64; i++) if (a[i] !== b[i]) d++; return d; };

// ── Inputs ──────────────────────────────────────────────────────────────────
function collect(args) {
  if (args.length === 1 && fs.existsSync(args[0]) && fs.statSync(args[0]).isDirectory()) {
    const run = args[0];
    return fs.readdirSync(run).filter(d => /^v\d+$/.test(d)).sort((a, b) => Number(a.slice(1)) - Number(b.slice(1)))
      .map(v => ['screenshot@desktop.png', 'screenshot.png'].map(f => path.join(run, v, f)).find(fs.existsSync))
      .filter(Boolean);
  }
  return args;
}

function analyze(files) {
  const hashes = files.map(f => ({ file: f, hash: ahash(decodePNG(fs.readFileSync(f))) }));
  const pairs = [];
  for (let i = 0; i < hashes.length; i++) for (let j = i + 1; j < hashes.length; j++) pairs.push({ a: i, b: j, d: hamming(hashes[i].hash, hashes[j].hash) });
  // colapso: tamaño del mayor "cluster" de variantes a ≤ COLLAPSE_DIST de una misma variante
  let worst = 0;
  for (let i = 0; i < hashes.length; i++) {
    const near = 1 + pairs.filter(p => (p.a === i || p.b === i) && p.d <= COLLAPSE_DIST).length;
    worst = Math.max(worst, near);
  }
  const min = pairs.length ? Math.min(...pairs.map(p => p.d)) : 64;
  const mean = pairs.length ? pairs.reduce((a, p) => a + p.d, 0) / pairs.length : 64;
  return { hashes, pairs, worst, min, mean, collapse: hashes.length >= 2 && worst >= Math.min(COLLAPSE_MIN, hashes.length) };
}

// ── Selftest (PNG sintéticos: 3 iguales + 2 distintos → COLLAPSE; 5 distintos → OK) ─────
function encodePNG(w, h, px) { // px(x,y) → [r,g,b]
  const crcTable = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
  const crc = b => { let c = 0xFFFFFFFF; for (const x of b) c = crcTable[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; };
  const chunk = (t, d) => { const len = Buffer.alloc(4); len.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([len, td, c]); };
  const raw = Buffer.alloc(h * (1 + w * 3));
  for (let y = 0; y < h; y++) { raw[y * (1 + w * 3)] = 0; for (let x = 0; x < w; x++) { const [r, g, b] = px(x, y); const i = y * (1 + w * 3) + 1 + x * 3; raw[i] = r; raw[i + 1] = g; raw[i + 2] = b; } }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
function selftest() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'design-diversity-'));
  const W = 160, H = 100;
  const leftHero = (x, y) => (x < W / 2 && y > 20 && y < 80 ? [40, 40, 200] : [250, 250, 250]);        // "hero izq / gráfico der"
  const variants = {
    a: leftHero, b: leftHero, c: (x, y) => leftHero(x, y).map(v => Math.min(255, v + 8)),          // 3 iguales (tinte distinto, misma composición)
    d: (x, y) => (y < H / 3 ? [20, 20, 20] : [240, 240, 240]),                                       // banda superior
    e: (x, y) => (((x >> 4) + (y >> 4)) % 2 ? [0, 0, 0] : [255, 255, 255]),                          // grid
    f: (x, y) => (x > W * 0.7 ? [200, 30, 30] : [255, 255, 255]),                                    // columna derecha
    g: (x, y) => ((x * 3 + y * 5) % 40 < 20 ? [30, 30, 30] : [220, 220, 220]),                       // diagonal
  };
  const f = k => { const p = path.join(dir, `${k}.png`); fs.writeFileSync(p, encodePNG(W, H, variants[k])); return p; };
  const r1 = analyze(['a', 'b', 'c', 'd', 'e'].map(f));
  const r2 = analyze(['d', 'e', 'f', 'g', 'a'].map(f));
  const ok1 = r1.collapse === true, ok2 = r2.collapse === false;
  console.log(`selftest 3-iguales+2 → collapse=${r1.collapse} (esperado true)  worst=${r1.worst} min=${r1.min}`);
  console.log(`selftest 5-distintos → collapse=${r2.collapse} (esperado false) worst=${r2.worst} min=${r2.min}`);
  fs.rmSync(dir, { recursive: true, force: true });
  console.log(ok1 && ok2 ? '✓ design-diversity selftest OK' : '✗ design-diversity selftest FAIL');
  process.exit(ok1 && ok2 ? 0 : 1);
}

// ── Main ────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
if (args.includes('--selftest')) selftest();
const files = collect(args.filter(a => !a.startsWith('--')));
if (files.length < 2) { console.error('uso: design-diversity.mjs <design-lab/run-dir | a.png b.png …>  (≥2 screenshots; --selftest)'); process.exit(2); }
const r = analyze(files);
console.log('==> design-diversity — aHash 8×8 · distancia de Hamming (0 = idéntico, 64 = opuesto)');
r.hashes.forEach((h, i) => console.log(`  [${i + 1}] ${path.relative(process.cwd(), h.file)}  ${h.hash.slice(0, 16)}…`));
for (const p of r.pairs) console.log(`  d(${p.a + 1},${p.b + 1}) = ${String(p.d).padStart(2)}${p.d <= COLLAPSE_DIST ? '  ← misma composición' : ''}`);
console.log(`  min=${r.min} mean=${r.mean.toFixed(1)} · cluster mayor=${r.worst} (umbral ${COLLAPSE_MIN} @ ≤${COLLAPSE_DIST} bits)`);
if (args.includes('--json')) console.log(JSON.stringify({ files, hashes: r.hashes.map(h => h.hash), pairs: r.pairs, min: r.min, mean: r.mean, worst: r.worst, collapse: r.collapse }));
if (r.collapse) { console.error(`✗ COLLAPSE — ${r.worst} de ${files.length} variantes comparten composición: el batch colapsó al prior (SSoT ceremonial). Regenerar con semillas nuevas (scripts/design-seed.sh), no "variar un poco".`); process.exit(1); }
console.log('✓ diversidad OK — las variantes difieren a nivel de pantalla, no solo de semilla');
