# Bootstrap Contract Checklist — Reference para migration-wizard

> Los 13 checks que migration-wizard analiza en Fase 1 (analyze-gaps.md) y reporta en el `MIGRATION-PLAN-{nombre}.md`. 5 son R11 mandatorios + 8 extras Forja Enterprise.

## R11 — Bootstrap Contract Gates (mandatorios para /build)

### R11-1 — make setup / package.json + deps

**Qué verifica:**
- `package.json` existe en root.
- `dependencies` y `devDependencies` declaradas.
- `npm install` (o `pnpm install`) puede ejecutar sin errores.

**Por qué importa:**
- Sin deps, el proyecto no compila ni corre.
- `/build` halts si `make setup` falla.

**Cómo arreglar:**
```bash
# Si package.json missing
npm init -y

# Si deps incompatibles
rm -rf node_modules package-lock.json
npm install
```

**Estimación:** ~5-15min según severidad.

---

### R11-2 — ≥1 test passing

**Qué verifica:**
- ≥1 archivo `*.test.ts` / `*.spec.ts` existe.
- Test runner configurado en `package.json` (Vitest, Jest, Mocha).
- `npm test` exit 0 con al menos 1 test passing.

**Por qué importa:**
- Sin tests, no hay Layer 2 verification (R7).
- `el-evaluador` no puede firmar features `passing` sin tests.

**Cómo arreglar:**
```bash
cd forja && npm i -D vitest
mkdir -p tests
cat > tests/sample.test.ts <<EOF
import { describe, it, expect } from "vitest";
describe("sample", () => {
  it("works", () => { expect(1).toBe(1); });
});
EOF
npm test
```

**Estimación:** ~20min para setup + sample test.

---

### R11-3 — feature_list.json con ≥3 features

**Qué verifica:**
- `feature_list.json` existe + valid JSON.
- ≥3 features declaradas con `verification` command.
- ≤1 feature en `state: active` (R1 WIP=1).

**Por qué importa:**
- `feature_list.json` es state machine de Forja (D2).
- `/build` necesita active feature definida.
- R3 active feature resolution depende de esto.

**Cómo arreglar:**
```bash
cp forja-template/forja/example.feature_list.json feature_list.json
# Editar manualmente con 3+ features iniciales
```

Template:
```json
{
  "schema_version": "1.0.0",
  "phase": "phase-name",
  "features": [
    {
      "id": "F1-T1",
      "behavior": "Login con Google OAuth funciona en /auth/sign-in",
      "verification": "npm run test:e2e -- google-oauth",
      "state": "active",
      "branch": "feature/google-oauth",
      "evidence": null,
      "commit": null
    },
    { ... más features ... }
  ]
}
```

**Estimación:** ~30min planificar features iniciales.

---

### R11-4 — .claude/memory/skills.md generado

**Qué verifica:**
- `.claude/memory/skills.md` existe.
- ≥10 skills declarados con `tier` / `requires` / `fallback` / `dependencies`.

**Por qué importa:**
- R6 dispatch validation requiere skills.md.
- Sin skills.md, los wizards (`init-saas`, `add-monetization`, `enterprise-stack`) PREFLIGHT halts.

**Cómo arreglar:**
```bash
cp -r forja-template/forja/.claude/memory/* .claude/memory/
# Editar skills.md si tenés skills custom
```

**Estimación:** ~15min.

---

### R11-5 — brand/brand.json + voice.json (R10 Brand DNA)

**Qué verifica:**
- `brand/brand.json` existe + valid JSON + tiene `tokens`, `posture`, `archetype`.
- `brand/voice.json` existe + tiene `tone`, `cta_examples`.
- `brand/brand.css` existe (CSS vars derivadas de tokens).

**Por qué importa:**
- R10 enforced en todo skill UI-generator.
- Sin Brand DNA, `impeccable` / `add-login` / `add-payments` / `add-emails` / `add-mobile` PREFLIGHT halts.
- Anti-Slop Gate post-generación requiere brand.json.

**Cómo arreglar:**
```bash
# Dentro de Claude Code:
/add-ui-kit
# Discovery FRESH ~30min con presets como starting points
```

ALTERNATIVA si ya tenés brand en otro formato:
- Migrar manualmente a R-005 schema (v1.1.0).
- Validar: `el-evaluador` firma R-005 compliance.

**Estimación:** ~30min.

---

## Forja Enterprise Extras (no mandatorios para /build pero recomendados)

### Extra 1 — AGENTS.md (routing host-agnostic)

**Qué verifica:** existe + tiene secciones "Identity", "PREFLIGHT", "Hard rules", "Routing por tarea".

**Por qué importa:** routing único cross-agent (Claude Code, Codex, Hermes). Sin AGENTS.md, cada agente improvisa.

**Cómo arreglar:** `cp forja-template/forja/AGENTS.md ./`. Estimación: ~5min.

---

### Extra 2 — CLAUDE.md (Factory OS)

**Qué verifica:** existe + tiene "Decision Router", "Golden Path", "Reglas de Código", "Bootstrap Contract".

**Por qué importa:** Claude Code-specific entry point. Adapta el routing host-agnostic de AGENTS.md.

**Cómo arreglar:** `cp forja-template/forja/CLAUDE.md ./`. Estimación: ~5min.

---

### Extra 3 — Hooks instalados (R1/R2/R5/R11)

**Qué verifica:**
- `.git/hooks/pre-commit` (R1 WIP=1).
- `.git/hooks/commit-msg` (R2 conventional + R5 memory writer scope).

**Por qué importa:** sin hooks, las reglas son aspiracionales. Cualquier commit puede violar R1/R2.

**Cómo arreglar:** `make install-hooks`. Estimación: ~5min.

---

### Extra 4 — Memory store (7 typed files)

**Qué verifica:** `.claude/memory/{lessons,errors,decisions,conventions,glossary,references,skills}.md`.

**Por qué importa:** Auto-Blindaje + R5 sole writer requieren los 7 files. Sin ellos, no hay memory store funcional.

**Cómo arreglar:** `cp -r forja-template/forja/.claude/memory/* .claude/memory/`. Estimación: ~5min.

---

### Extra 5 — Git conventional commits (R2)

**Qué verifica:** `git log --oneline -20` matchea regex `^(feat|fix|refactor|chore|docs|test|style|perf|ci|build|evaluator|memory)\(.+\): .{10,}$` en ≥80% de commits.

**Por qué importa:** R2 enforcement. Sin conventional, scope tracking falla.

**Cómo arreglar:**
- Forward: hook `commit-msg` enforcing → cualquier commit nuevo cumple.
- Backward: NO re-escribir history. Hook empieza a actuar desde la próxima commit.

**Estimación:** 0min (hook hace el trabajo a futuro).

---

### Extra 6 — RLS L-001 en tablas con user_id

**Qué verifica:** todas las tablas con columna `user_id` tienen `ENABLE ROW LEVEL SECURITY` + policy.

**Por qué importa:** L-001 es lección documentada. Sin RLS, datos expuestos a cualquier usuario autenticado.

**Cómo arreglar:**
```sql
ALTER TABLE [tabla] ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_[tabla]" ON [tabla]
  FOR ALL USING (auth.uid() = user_id);
```

Generar nuevas migrations para tablas existentes. Estimación: ~15-30min según cantidad.

---

### Extra 7 — R14 destructive tools

**Qué verifica:** `grep -rE "tool\(\{[^}]*execute:" src/ --include="*.ts" | grep -iE "delete|send|transfer|cancel|refund"` retorna 0 matches.

**Por qué importa:** R14 — destructive tools agentic con `execute()` automático violan typed confirmation requirement. L-002 prompt injection puede activarlas inadvertidamente.

**Cómo arreglar:**
```typescript
// ❌ Antes
export const deleteUser = tool({
  inputSchema: z.object({ userId: z.string() }),
  execute: async ({ userId }) => { /* destructive */ },
})

// ✅ Después
export const deleteUser = tool({
  description: 'Elimina un usuario — REQUIERE CONFIRMACIÓN MANUAL',
  inputSchema: z.object({ userId: z.string() }),
  // sin execute() — SDK pausa esperando confirmación humana
})
```

**Estimación:** ~20min por tool.

---

### Extra 8 — Brand DNA contract R-005 compatible

**Qué verifica:** `brand/brand.json` cumple schema R-005 v1.1.0 (secciones 1-9).

**Por qué importa:** R-005 es el contrato schema oficial de Brand DNA. Sin compliance, `impeccable` puede fallar.

**Cómo arreglar:** correr `el-evaluador` para auditar brand.json + sugerir fixes. Estimación: ~10-20min.

---

## Resumen — 13 checks total

| # | Check | Mandatory | Tiempo Fix Promedio |
|---|-------|-----------|---------------------|
| R11-1 | make setup / deps | Sí (R11) | ~10min |
| R11-2 | ≥1 test passing | Sí (R11) | ~20min |
| R11-3 | feature_list.json ≥3 features | Sí (R11) | ~30min |
| R11-4 | skills.md generado | Sí (R11) | ~15min |
| R11-5 | Brand DNA brand.json + voice.json | Sí (R11/R10) | ~30min |
| Extra 1 | AGENTS.md | No | ~5min |
| Extra 2 | CLAUDE.md Factory OS | No | ~5min |
| Extra 3 | Hooks instalados | Recomendado | ~5min |
| Extra 4 | Memory store 7 files | Recomendado | ~5min |
| Extra 5 | Git conventional commits | Recomendado | 0 (forward) |
| Extra 6 | RLS L-001 user_id tables | Crítico si BaaS | ~15-30min |
| Extra 7 | R14 destructive tools | Crítico si tools agentic | ~20min/tool |
| Extra 8 | Brand DNA R-005 compatible | Recomendado | ~10-20min |

**Total típico Bootstrap Contract mínimo (R11 only):** ~1h45min - 2h.
**Total típico Enterprise completo (R11 + Extras):** ~3-4h.

## Citation

[memory:CONSTRAINTS.md#R11] (Bootstrap Contract), [memory:CONSTRAINTS.md#R10] (Brand DNA gate), [memory:CONSTRAINTS.md#R6] (skills.md registry validation), [memory:CONSTRAINTS.md#R1] (WIP=1), [memory:CONSTRAINTS.md#R2] (Conventional Commits), [memory:CONSTRAINTS.md#R5] (memory writer scope), [memory:CONSTRAINTS.md#R7] (Three-Layer), [memory:CONSTRAINTS.md#R14] (destructive tools), [memory:lessons#L-001] (RLS user_id), [memory:lessons#L-002] (prompt injection awareness).
