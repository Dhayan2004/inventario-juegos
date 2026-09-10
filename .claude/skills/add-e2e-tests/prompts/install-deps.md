# install-deps — npm + playwright install

> Prompt operativo. Invocado por add-e2e-tests Fase 1.
> **Cita:** `[memory:CONSTRAINTS.md#R4]` (sub-agent invoca, no SKILL),
> `[memory:CONSTRAINTS.md#R13]` (find-docs antes de generar comandos contra Playwright),
> `[docs:playwright]`, `[docs:playwright-test]`.

---

## Precondiciones

- PREFLIGHT pasó los 3 gates (Next.js, npm, typecheck baseline).
- Mode seleccionado: `minimal` (chromium-only) o `full` (chromium + firefox + webkit).
- find-docs corrió contra `playwright` (versión actual + flags `install` actualizados).

---

## Protocolo

### Paso 1 — Instalar `@playwright/test`

```bash
npm install -D @playwright/test
```

- Sub-agent ejecuta el comando (R4 — la SKILL.md NO corre `npm install` directo).
- Verificar exit code: si ≠ 0 → halt + reportar stdout/stderr.
- Verificar que `package.json.devDependencies["@playwright/test"]` quedó escrito post-install.

### Paso 2 — Descargar browsers

Modo **minimal** (default):

```bash
npx playwright install chromium
```

Tamaño aprox: ~80 MB. Duración aprox: ~30s.

Modo **full**:

```bash
npx playwright install chromium firefox webkit
```

Tamaño aprox: ~280 MB. Duración aprox: ~90s.

- Sub-agent ejecuta el comando correspondiente.
- Verificar exit code: si ≠ 0 → halt + reportar.
- En CI sin permisos para descargar browsers → reportar al usuario que la descarga es necesaria localmente antes de correr los tests; el workflow GitHub Actions (Mode B) lo maneja con `cache` + `npx playwright install --with-deps`.

### Paso 3 — Verificación post-install

```bash
npx playwright --version
```

- Exit 0 esperado.
- Output: `Version <X.Y.Z>` — guardar para citation en handoff (`[docs:playwright@<X.Y.Z>]` si la versión es estable).

---

## Refusals

- ❌ Correr `npm install` directo desde la SKILL.md (R4 violation).
- ❌ Instalar browsers que el usuario no pidió (no instalar firefox+webkit en minimal sin override explícito).
- ❌ Instalar `playwright` legacy (sin `@playwright/test`) — el patrón canónico actual es `@playwright/test`. find-docs verifica esto antes de generar el comando.

---

*"Instalación es delegada a sub-agent, exit codes verificados, browsers descargados según mode."*
