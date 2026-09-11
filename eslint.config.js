// Flat config (ESLint 9+). `next lint` fue removido en Next.js 16 —
// este proyecto corre eslint directo (ver "lint" en package.json).
const nextConfig = require("eslint-config-next");

module.exports = [
  ...nextConfig,
  {
    // .claude/** son assets del arnes Forja (templates, tests, fixtures de
    // skills, incluyendo fixtures deliberadamente "sucios" para probar el
    // Anti-Slop Gate) — no son codigo de aplicacion de este proyecto.
    ignores: [".next/**", "node_modules/**", "dist/**", "build/**", ".claude/**"],
  },
];
