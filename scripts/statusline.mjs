#!/usr/bin/env node
// statusline.mjs — visibilidad de contexto en la statusline de Claude Code
// (F-P5.1 · docs/06 §12.2 · D-034). Zero-dep y rápido: lee archivos, no
// spawnea procesos. Configurado en .claude/settings.json → statusLine.
//
// Output (una línea): ⚒ <rama> · <active|sin-active> · <fase> · <plan>
// Degradación segura: cada segmento ausente se reporta como "—".

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();

function readJSON(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

// Input de Claude Code por stdin (JSON con model/workspace) — opcional.
let model = null;
try {
  const stdin = readFileSync(0, "utf8");
  model = JSON.parse(stdin)?.model?.display_name ?? null;
} catch {
  /* sin stdin: invocación directa */
}

// Rama: parsear .git/HEAD (sin spawn).
let branch = "—";
try {
  const head = readFileSync(join(ROOT, ".git", "HEAD"), "utf8").trim();
  branch = head.startsWith("ref: ") ? head.slice(5).replace("refs/heads/", "") : head.slice(0, 7);
} catch {
  /* sin git */
}

const fl = readJSON(join(ROOT, "feature_list.json"));
const active = fl?.features?.find((f) => f.state === "active")?.id ?? "sin-active";
const phase = fl?.phase ?? "—";

let plan = "";
if (existsSync(join(ROOT, ".plan", "plan.json"))) {
  plan = existsSync(join(ROOT, ".plan", ".inconsistent")) ? " · plan⚠" : " · plan✓";
}

const prefix = model ? `${model} · ` : "";
console.log(`⚒ ${prefix}${branch} · ${active} · fase ${phase}${plan}`);
