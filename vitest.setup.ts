import fs from "node:fs";
import path from "node:path";

// vitest no carga .env.local automáticamente (a diferencia de next dev/build);
// los tests de integración necesitan las credenciales de Supabase local.
const envPath = path.resolve(__dirname, ".env.local");

if (fs.existsSync(envPath)) {
  const content = fs.readFileSync(envPath, "utf8");
  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const separatorIndex = trimmed.indexOf("=");
    if (separatorIndex === -1) continue;
    const key = trimmed.slice(0, separatorIndex).trim();
    const value = trimmed.slice(separatorIndex + 1).trim();
    if (!(key in process.env)) process.env[key] = value;
  }
}
