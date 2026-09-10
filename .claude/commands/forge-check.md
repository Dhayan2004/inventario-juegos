---
description: "Diagnóstico del entorno Forja — verifica que todo esté listo para /build."
---

# /forge-check — Diagnóstico de la Fragua

> *"Antes de encender el horno, el herrero verifica que todo esté en su lugar."*

Ejecuta diagnóstico completo del entorno Forja y ofrece arreglar lo que falte.

---

## Paso 1 — Archivos críticos

```bash
echo "=== FORJA CORE ==="
[ -f CLAUDE.md ]            && echo "OK:CLAUDE.md (Factory OS)"          || echo "FAIL:CLAUDE.md"
[ -f AGENTS.md ]            && echo "OK:AGENTS.md (routing)"             || echo "FAIL:AGENTS.md"
[ -f feature_list.json ]    && echo "OK:feature_list.json"               || echo "FAIL:feature_list.json"
[ -f brand/brand.json ]     && echo "OK:brand.json"                      || echo "FAIL:brand.json"
[ -f brand/voice.json ]     && echo "OK:voice.json"                      || echo "FAIL:voice.json"
[ -d .claude/skills ]       && echo "OK:skills/"                         || echo "FAIL:skills/"
[ -d .claude/commands ]     && echo "OK:commands/"                       || echo "FAIL:commands/"
[ -d .claude/memory ]       && echo "OK:memory/"                         || echo "FAIL:memory/"
[ -f .claude/memory/skills.md ] && echo "OK:skills.md (registry)"        || echo "FAIL:skills.md"
[ -f .claude/prompts/el-yunque.md ] && echo "OK:el-yunque (manual motor)" || echo "FAIL:el-yunque"
```

## Paso 2 — feature_list.json sano

```bash
echo "=== FEATURE LIST ==="
if [ -f feature_list.json ]; then
  ACTIVE=$(node -e "const f=require('./feature_list.json'); console.log(f.features.filter(x=>x.state==='active').length)" 2>/dev/null)
  TOTAL=$(node -e "const f=require('./feature_list.json'); console.log(f.features.length)" 2>/dev/null)
  [ "$ACTIVE" = "1" ] && echo "OK:WIP=1 ($ACTIVE active / $TOTAL total)" || echo "WARN:WIP=$ACTIVE (R1 violation if >1)"
fi
```

## Paso 3 — Dependencias Next.js

```bash
echo "=== DEPENDENCIAS NEXT.JS ==="
[ -d "node_modules" ] && echo "OK:node_modules" || echo "FAIL:node_modules (corré npm install)"
[ -f "package.json" ] && node -e "
  const p=require('./package.json');
  const d={...p.dependencies,...p.devDependencies};
  ['next','react','tailwindcss','zod','zustand','@supabase/supabase-js'].forEach(k => console.log(k+':'+(d[k]||'MISSING')));
" 2>/dev/null || echo "FAIL:package.json no encontrado"
```

## Paso 4 — Bootstrap Contract (R11)

```bash
echo "=== BOOTSTRAP CONTRACT ==="
make preflight && echo "OK:preflight" || echo "FAIL:preflight (ver mensaje arriba)"
```

## Paso 5 — Entorno

```bash
echo "=== ENTORNO ==="
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo "OK:git" || echo "FAIL:git"
[ -f .mcp.json ] && echo "OK:mcp" || ([ -f example.mcp.json ] && echo "WARN:mcp — copiá example.mcp.json a .mcp.json y agregá keys" || echo "FAIL:no mcp template")
```

## Paso 6 — Skills críticos presentes

```bash
echo "=== SKILLS ==="
for s in la-herreria la-forja el-evaluador el-guardian impeccable add-ui-kit; do
  [ -f ".claude/skills/$s/SKILL.md" ] && echo "OK:$s" || echo "WARN:$s (falta SKILL.md)"
done
```

---

## Paso 7 — Reporte unificado

Presentar tabla:

```
┌─────────────────────────────────────────────┐
│  DIAGNÓSTICO DE LA FRAGUA                   │
├─────────────────────────────────────────────┤
│  CORE                                       │
│  [✅/❌] Factory OS · routing · skills      │
│  [✅/❌] feature_list.json + WIP=1          │
│  [✅/❌] Brand DNA (brand.json + voice.json)│
│  [✅/❌] Memory store (7 archivos tipados)  │
│  [✅/❌] el-yunque (manual motor)           │
│                                             │
│  DEPENDENCIAS                               │
│  [✅/❌] node_modules instalados            │
│  [✅/❌] Next.js                            │
│  [✅/❌] zod                                │
│  [✅/❌] zustand                            │
│  [✅/❌] @supabase/supabase-js              │
│                                             │
│  BOOTSTRAP CONTRACT (R11)                   │
│  [✅/❌] make preflight exit 0              │
│                                             │
│  ENTORNO                                    │
│  [✅/⚠️] git · MCP                          │
│                                             │
│  SKILLS CORE                                │
│  [✅/⚠️] la-herreria · la-forja ·          │
│         el-evaluador · el-guardian ·        │
│         impeccable · add-ui-kit             │
├─────────────────────────────────────────────┤
│  RESULTADO: X ✅  Y ❌  Z ⚠️                │
│  VEREDICTO: [resumen 1 línea]               │
└─────────────────────────────────────────────┘
```

## Paso 8 — Ofrecer fixes

Para cada ❌, presentar la acción correctiva exacta:

| Issue | Fix |
|-------|-----|
| `node_modules` faltante | `npm install` |
| Next.js / zod / zustand / @supabase MISSING | revisar `package.json`, correr `npm install` |
| `.mcp.json` faltante | `cp example.mcp.json .mcp.json` + agregar keys |
| Brand DNA faltante | `/add-ui-kit` |
| feature_list vacío | `/plan` para generar Blueprint |
| `make preflight` falla | seguir mensaje del gate específico |

Preguntar: **"¿Quiero que arregle los issues marcados con ❌?"** — si sí, ejecutar uno por uno confirmando cada resultado. Si no, continuar — el usuario sabe lo que hace.

---

## Veredictos

- **Todo ✅:** *La fragua está encendida. Podés correr `/plan` o `/build`.*
- **Bootstrap falla:** *Falta cumplir R11 — `/build` bloqueado hasta resolver el gate.*
- **Brand DNA ausente:** *Sin `brand/*.json`, R10 falla — no se puede generar UI. Corré `/add-ui-kit`.*
- **Skills faltantes:** *Skills no instalados — el repo Forja está incompleto. Reinstalar template.*
