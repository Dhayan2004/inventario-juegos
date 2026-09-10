# REDESIGN MERGE — Integración no-destructiva de Brand DNA

> Prompt operativo. Invocado solo si Discovery REDESIGN sub-mode = MERGE.
>
> **Source schema:** [memory:references#R-005].
> **Precondición:** gates 5-7 del PREFLIGHT detectaron archivos con contenido propio
> (globals.css, tailwind.config.ts, layout.tsx). El usuario eligió MERGE explícitamente
> tras ver el reporte de Scan.
> **Cita:** [memory:errors#E-009] causa 2 (alcance conceptual de la restricción).

---

## Reglas del intérprete

1. **MERGE es quirúrgico, no destructivo.** Append/extend solamente. NUNCA reemplazar archivos.
2. **Conflictos requieren confirmación humana.** Si una var/key/import ya existe con valor distinto del Brand DNA → halt, reportar, esperar decisión.
3. **Verificación post-merge obligatoria.** Tras cada archivo modificado, correr `npm run typecheck` (o `npx tsc --noEmit`). Si falla → revertir ESE archivo (`git restore <path>`) y reportar al usuario qué falló.
4. **Alcance acotado.** Solo se tocan: `globals.css`, `tailwind.config.ts`, `layout.tsx` del proyecto + se generan `brand/brand.json`, `brand/voice.json`, `brand/brand.css` (nuevos, no merge).
5. **Showcase NO se genera por default en MERGE.** Solo si el usuario lo pide explícitamente Y `src/app/(brand)/showcase/` no existe.

---

## Protocolo de merge por archivo

### 1. globals.css

```
a. Read el archivo completo.
b. Identificar el bloque :root { ... } o equivalente (.dark, [data-theme], etc.).
c. Listar las CSS vars del Brand DNA nuevo (derivadas 1:1 de tokens de brand.json).
d. Para cada var nueva:
   · Si NO existe en el archivo → APPEND al final del :root { ... } correspondiente.
   · Si SÍ existe con MISMO valor → no-op (idempotente).
   · Si SÍ existe con VALOR DISTINTO → reportar conflicto al usuario:
     "Conflicto en --color-primary:
        actual:  #6366F1
        nuevo:   {{ brand.tokens.colors.primary }}
      ¿Sobrescribir, conservar actual, o cancelar MERGE?"
     NO sobrescribir sin confirmación.
e. Si el archivo NO tiene :root {}, NO inventar uno — reportar y pedir confirmación.
```

Resultado esperado: file size aumenta, contenido previo intacto, vars del Brand DNA disponibles.

### 2. tailwind.config.ts

```
a. Read el archivo completo.
b. Parsear (regex/AST-lite) sobre `theme.extend.colors`, `theme.extend.borderRadius`,
   `theme.extend.spacing` (o `theme.colors` si no hay extend).
c. Para cada token nuevo del Brand DNA:
   · Si la key NO existe → AGREGAR al objeto correspondiente.
   · Si SÍ existe con MISMO valor → no-op.
   · Si SÍ existe con VALOR DISTINTO → reportar conflicto, NO sobrescribir.
d. Preservar imports, plugins, content, presets, darkMode, y resto del config intactos.
e. Si el archivo usa un patrón no estándar (Tailwind v4 @theme, presets externos,
   tokens en archivo separado, etc.) → reportar al usuario y pedir guidance manual.
```

Resultado esperado: archivo TS válido (parsea), theme extended con keys nuevas, nada removido.

### 3. layout.tsx

```
a. Read los imports actuales.
b. Generar imports de fonts del Brand DNA via next/font/google (R10 + R13 find-docs).
c. APPEND imports nuevos al final del bloque de imports. NO remover imports existentes.
d. En el JSX:
   · Si <html> tiene className → APPEND className del/los font.variable
     (concatenar con cn() helper o template literal — preservar la className previa).
   · Si NO tiene className → AGREGAR className con los font.variable.
   · NUNCA remover className existente.
e. NO tocar children, providers, Toaster, ThemeProvider, ni cualquier wrapper del body.
f. Si el archivo importa fonts via otro mecanismo (CSS @font-face, link tags) →
   reportar y pedir guidance — NO duplicar.
```

Resultado esperado: layout funcional con fonts del Brand DNA + estado previo intacto.

---

## Refusals del modo MERGE

- ❌ **Reemplazar archivos.** Solo append/extend quirúrgico. Si el merge requiere reescritura → halt y reportar.
- ❌ **Resolver conflictos sin confirmación humana.** Si una var/key/import ya existe con valor distinto del Brand DNA → halt, reportar, esperar decisión explícita.
- ❌ **Tocar archivos fuera del set permitido.** Solo `globals.css`, `tailwind.config.ts`, `layout.tsx`, `brand/**`, y (opcional) `src/app/(brand)/showcase/**`. El alcance sigue siendo conceptual — aplica con o sin prefijo ``.
- ❌ **Continuar tras typecheck fail.** Si post-merge de un archivo el typecheck falla → revertir ESE archivo con `git restore` y reportar antes de seguir.
- ❌ **Generar showcase sobreescribiendo `src/app/(brand)/showcase/` existente.** Solo si la carpeta NO existe o el usuario lo pide explícito.

---

## Verificación post-merge

Después de cada archivo modificado:

```
1. npm run typecheck (o npx tsc --noEmit)
   · exit 0 → continuar al siguiente archivo.
   · fail   → git restore <path> + reportar al usuario qué falló (primeras 20 líneas
              del stdout) + halt. NO continuar al siguiente archivo.

2. Tras los 3 archivos:
   · npm run build (si está disponible y rápido — opcional pero recomendado).
   · Reporte final: qué cambió, qué vars nuevas hay disponibles, brand.json/voice.json/
     brand.css generados, y un diff resumido para que el usuario revise.
```

---

## Output del MERGE

Mismo contrato que FRESH, pero con scope explícito:

```yaml
mode: REDESIGN
sub_mode: MERGE
artifacts_generated:
  - brand/brand.json
  - brand/voice.json
  - brand/brand.css
artifacts_merged:
  - <project-root>/src/app/globals.css         # append vars
  - <project-root>/tailwind.config.ts           # extend theme
  - <project-root>/src/app/layout.tsx           # append font imports
showcase_generated: false   # default — true solo si el usuario lo pidió
typecheck_status: PASS      # cada archivo verificado
conflicts_reported: [<list>]
citations:
  - [memory:references#R-005]
  - [memory:errors#E-009]    # causa 2 (restricción conceptual)
  - [memory:CONSTRAINTS.md#R10]   # Brand DNA contract
```

---

*"MERGE no destruye. MERGE extiende. Si no se puede extender sin destruir, halt + reportar."*
