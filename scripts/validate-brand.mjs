#!/usr/bin/env node
// brand:validate — Layer 2 (Runtime) gate for F2-01 (Brand DNA).
// Validates brand/brand.json + brand/voice.json against the checks the
// feature's acceptance criteria name explicitly: schema_version, keyed
// spacing, motion enums, plus checks 1-6 of the Anti-Slop Gate
// (.claude/skills/add-ui-kit/tests/anti-slop-gate.sh) run against THIS
// project's brand.json rather than the skill's own fixture.
//
// Node, no external deps — avoids the python3 dependency of the skill's
// own test script (Windows Store stub, non-functional on this machine).

import { readFileSync } from "node:fs";
import { existsSync } from "node:fs";

const ROOT = process.cwd();
const BRAND_PATH = `${ROOT}/brand/brand.json`;
const VOICE_PATH = `${ROOT}/brand/voice.json`;

let failures = 0;
let passes = 0;

function ok(label) {
  console.log(`  ✓ ${label}`);
  passes++;
}
function fail(label) {
  console.log(`  ✗ ${label}`);
  failures++;
}

function loadJson(path, label) {
  if (!existsSync(path)) {
    fail(`${label} existe (${path})`);
    return null;
  }
  try {
    const parsed = JSON.parse(readFileSync(path, "utf8"));
    ok(`${label} parsea como JSON valido`);
    return parsed;
  } catch (e) {
    fail(`${label} parsea como JSON valido — ${e.message}`);
    return null;
  }
}

console.log("── brand:validate ── F2-01 Runtime gate ──────────────");
console.log("");

const brand = loadJson(BRAND_PATH, "brand/brand.json");
const voice = loadJson(VOICE_PATH, "brand/voice.json");

if (!brand) {
  console.log("\nbrand/brand.json ausente o invalido — abortando resto de checks.");
  process.exit(1);
}

// ── schema_version ──────────────────────────────────────────────
if (typeof brand.schema_version === "string" && /^\d+\.\d+\.\d+$/.test(brand.schema_version)) {
  ok(`brand.json schema_version presente y valido (${brand.schema_version})`);
} else {
  fail("brand.json schema_version presente y con forma semver");
}
if (voice) {
  if (typeof voice.schema_version === "string" && /^\d+\.\d+\.\d+$/.test(voice.schema_version)) {
    ok(`voice.json schema_version presente y valido (${voice.schema_version})`);
  } else {
    fail("voice.json schema_version presente y con forma semver");
  }
}

// ── keyed spacing (E-002: arrays -> keyed objects) ──────────────
const spacing = brand.tokens?.spacing;
if (spacing && typeof spacing === "object" && !Array.isArray(spacing)) {
  const sectionY = spacing.section_y;
  const componentGap = spacing.component_gap;
  const isKeyedObject = (v) => v && typeof v === "object" && !Array.isArray(v);
  if (isKeyedObject(sectionY)) {
    ok("tokens.spacing.section_y es objeto keyed (no array)");
  } else {
    fail("tokens.spacing.section_y debe ser objeto keyed {sm,md,lg}, no array (E-002)");
  }
  if (isKeyedObject(componentGap)) {
    ok("tokens.spacing.component_gap es objeto keyed (no array)");
  } else {
    fail("tokens.spacing.component_gap debe ser objeto keyed {xs,sm,md,lg}, no array (E-002)");
  }
} else {
  fail("tokens.spacing presente");
}

// ── motion enums cerrados (R-005 v1.1.0 §6.1, E-003) ────────────
const MOTION_ENUMS = {
  energy: ["precise", "calm", "violent", "ceremonial", "mechanical"],
  elasticity: ["snap_not_bounce", "bounce", "glide", "rigid"],
  directionality: ["mechanical", "organic", "physical", "abstract"],
  sequencing: ["subtle_stagger", "uniform", "cascaded", "instant_all"],
  distance: ["short", "medium", "long"],
  restraint: ["high", "medium", "low"],
};
const personality = brand.motion?.personality;
if (personality && typeof personality === "object") {
  for (const [dim, allowed] of Object.entries(MOTION_ENUMS)) {
    const value = personality[dim];
    if (allowed.includes(value)) {
      ok(`motion.personality.${dim} = "${value}" (enum valido)`);
    } else {
      fail(`motion.personality.${dim} = "${value}" no esta en el enum cerrado [${allowed.join(" | ")}]`);
    }
  }
} else {
  fail("motion.personality presente");
}

// ── Anti-Slop Gate checks 1-6 (contra brand.json real, no fixture) ──
console.log("");
console.log("Anti-Slop Gate — checks 1-6 (contra brand/brand.json del proyecto)");

// Check 1: forbidden_colors
const FORBIDDEN_HEX = new Set(["#6366F1", "#8B5CF6", "#A855F7"].map((h) => h.toUpperCase()));
const colorValues = Object.values(brand.tokens?.colors ?? {}).filter((v) => typeof v === "string");
const usesForbiddenColor = colorValues.some((v) => FORBIDDEN_HEX.has(v.toUpperCase()));
if (!usesForbiddenColor) {
  ok("forbidden_colors — sin Tailwind purple/indigo default en tokens.colors");
} else {
  fail("forbidden_colors — se detecto un color prohibido en tokens.colors");
}

// Check 2: restricted_hues (primary fuera de hue [235,285] salvo Magician)
function hexToHue(hex) {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex);
  if (!m) return null;
  const r = parseInt(m[1].slice(0, 2), 16) / 255;
  const g = parseInt(m[1].slice(2, 4), 16) / 255;
  const b = parseInt(m[1].slice(4, 6), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const d = max - min;
  if (d === 0) return 0;
  let h;
  if (max === r) h = ((g - b) / d) % 6;
  else if (max === g) h = (b - r) / d + 2;
  else h = (r - g) / d + 4;
  h *= 60;
  if (h < 0) h += 360;
  return h;
}
const primaryHex = brand.tokens?.colors?.primary;
const primaryHue = primaryHex ? hexToHue(primaryHex) : null;
const archetypePrimary = brand.archetype?.primary;
const isMagician = archetypePrimary === "Magician";
if (primaryHue === null) {
  fail("restricted_hues — tokens.colors.primary no es hex valido");
} else if (primaryHue >= 235 && primaryHue <= 285 && !isMagician) {
  fail(`restricted_hues — primary hue ${primaryHue.toFixed(1)} cae en [235,285] sin archetype Magician`);
} else {
  ok(`restricted_hues — primary hue ${primaryHue.toFixed(1)} fuera del rango prohibido (o Magician declarado)`);
}

// Check 3: max_fonts
const maxFonts = brand.validation?.max_fonts;
const families = new Set(
  Object.values(brand.tokens?.typography ?? {})
    .map((t) => t?.family)
    .filter(Boolean)
);
if (typeof maxFonts === "number" && families.size <= maxFonts) {
  ok(`max_fonts — ${families.size} familia(s) unica(s) <= limite ${maxFonts}`);
} else {
  fail(`max_fonts — ${families.size} familia(s) unica(s) excede el limite ${maxFonts ?? "(no declarado)"}`);
}

// Check 4: max_radius_values
const maxRadius = brand.validation?.max_radius_values;
const radiusKeys = Object.keys(brand.tokens?.shape ?? {}).filter((k) => k.startsWith("radius_"));
const radiusValues = new Set(radiusKeys.map((k) => brand.tokens.shape[k]));
if (typeof maxRadius === "number" && radiusValues.size <= maxRadius) {
  ok(`max_radius_values — ${radiusValues.size} valor(es) unico(s) <= limite ${maxRadius}`);
} else {
  fail(`max_radius_values — ${radiusValues.size} valor(es) unico(s) excede el limite ${maxRadius ?? "(no declarado)"}`);
}

// Check 5: archetype_coherence (heuristico — Creator/Explorer vs tone_axes)
if (archetypePrimary && voice?.voice?.tone_axes) {
  ok(`archetype_coherence — archetype.primary "${archetypePrimary}" declarado, tone_axes presente en voice.json (revision semantica queda para el-evaluador)`);
} else {
  fail("archetype_coherence — falta archetype.primary o voice.tone_axes para cruzar");
}

// Check 6: anti_slop_patterns >= 7
const forbiddenPatterns = brand.anti_slop?.forbidden_patterns;
if (Array.isArray(forbiddenPatterns) && forbiddenPatterns.length >= 7) {
  ok(`anti_slop_patterns — ${forbiddenPatterns.length} patrones declarados (>= 7)`);
} else {
  fail(`anti_slop_patterns — ${forbiddenPatterns?.length ?? 0} patrones declarados, se requieren >= 7`);
}

console.log("");
console.log(`Resultado: ${passes} pass / ${failures} fail`);

if (failures > 0) {
  console.log("\n❌ brand:validate FAIL");
  process.exit(1);
} else {
  console.log("\n✅ brand:validate PASS");
  process.exit(0);
}
