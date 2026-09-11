import path from "node:path";
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    setupFiles: ["./vitest.setup.ts"],
    // Solo tests de la app — .claude/skills/** trae sus propios templates de
    // test (ej. add-payments) que no aplican a este proyecto y no deben correr aquí.
    include: ["src/**/*.test.ts"],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      // vitest corre en Node puro, sin la condición de resolución "react-server"
      // que usa el bundler de Next.js para vaciar este marker package en server
      // code. Sin este alias, `import "server-only"` tira en cualquier test.
      "server-only": path.resolve(__dirname, "node_modules/server-only/empty.js"),
    },
  },
});
