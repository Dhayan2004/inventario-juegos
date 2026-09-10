# build-plan

> Fase 2 de migration-wizard. Toma el output de `analyze-gaps.md` y produce `MIGRATION-PLAN-{nombre}.md` — documento auto-contenido con pasos priorizados, comandos Forja exactos, y estimaciones. NO ejecuta. Solo planifica.

## Inputs

- Output de `detect-origin.md` (Tipo A/B/C/D/E).
- Output de `analyze-gaps.md` (gaps + reusable + estimaciones).

## Output

`MIGRATION-PLAN-{nombre}.md` en root del proyecto target o `.claude/PRPs/MIGRATION-PLAN-{nombre}.md`.

## Step-by-step

### Paso 1 — Determinar nombre y path del plan

- `{nombre}` = derivado de `package.json name` o cwd basename, kebab-case.
- Path por defecto: `MIGRATION-PLAN-{nombre}.md` en root del proyecto.
- Si el usuario prefiere otro path → confirmar antes de Write.

### Paso 2 — Generar secciones del plan

#### Sección 1: Header + Resumen Ejecutivo

```markdown
# MIGRATION-PLAN-{nombre}

> Plan generado por migration-wizard · [fecha]
> **Origen detectado:** Tipo {A/B/C/D/E} — {origin_description}
> **Estimación total:**
>   - Bootstrap Contract mínimo (gaps críticos): ~{X}h
>   - Enterprise completo (gaps + extras + opcional): ~{X}h
> **Status:** PLAN — pendiente ejecución por el usuario
```

#### Sección 2: Estado Actual vs Bootstrap Contract

```markdown
## Estado Actual vs Bootstrap Contract

### R11 Gates (mandatorios para /build)

| # | Gate | Status | Evidencia |
|---|------|--------|-----------|
| R11-1 | make setup / package.json + deps | ✅/❌/⚠️ | {evidence} |
| R11-2 | ≥1 test passing | ✅/❌/⚠️ | {evidence} |
| R11-3 | feature_list.json con ≥3 features | ✅/❌ | {evidence} |
| R11-4 | .claude/memory/skills.md generado | ✅/❌ | {evidence} |
| R11-5 | brand/brand.json + voice.json (R10) | ✅/❌ | {evidence} |

### Forja Enterprise Extras

| # | Check | Status |
|---|-------|--------|
| 1 | AGENTS.md (routing host-agnostic) | ✅/❌ |
| 2 | CLAUDE.md (Factory OS) | ✅/❌ |
| 3 | Hooks instalados (R1/R2/R5/R11) | ✅/❌/⚠️ |
| 4 | Memory store (7 typed files) | ✅/❌/parcial |
| 5 | Git conventional commits (R2) | ✅/❌/⚠️ |
| 6 | RLS L-001 en tablas con user_id | ✅/❌/n/a |
| 7 | R14 destructive tools sin execute() automático | ✅/❌/⚠️ |
| 8 | Brand DNA contract R-005 compatible | ✅/❌ |

**Resumen:** {N}/13 checks pasan. {N} gaps críticos detectados.
```

#### Sección 3: Gaps Críticos (bloquean /build)

```markdown
## Gaps Críticos (bloquean /build)

| # | Gap | Acción Forja | Comando | Estimación |
|---|-----|--------------|---------|------------|
| 1 | {gap-1.description} | {forja_action} | `{forja_command}` | ~{X}min |
| 2 | ... | ... | ... | ... |

**Total:** ~{X}min para resolver gaps críticos.
```

#### Sección 4: Reutilizable del Proyecto Actual

```markdown
## Reutilizable del Proyecto Actual

### ✅ Compatible — NO hay que rehcer
- {item 1}
- {item 2}

### ⚠️ Requiere ajustes menores
- {item — qué ajustar}

### ❌ Incompatible — archivar
- {item — por qué incompatible}
- {item — alternativa Forja}

**Ahorro estimado:** ~{X}h del trabajo total.
```

#### Sección 5: Pasos de Migración (ordenados por dependencia)

```markdown
## Pasos de Migración (orden dependencia)

### Paso 1 — Adoptar AGENTS.md + CLAUDE.md Forja (Factory OS)

**Por qué primero:** routing es la fundación. Sin AGENTS.md, ningún skill se invoca correctamente.

**Acción:** copiar `AGENTS.md` + `CLAUDE.md` (Factory OS) al proyecto.

**Comando:**
```bash
cp -r path/to/forja-template/forja/{AGENTS.md,CLAUDE.md} ./
```

**Tiempo:** ~10min.

**Verificación:** `cat AGENTS.md | head -5` debería mostrar el routing.

---

### Paso 2 — Crear feature_list.json

**Por qué:** R11-3 exige feature_list.json con ≥3 features y verification command.

**Acción:** generar feature_list.json inicial con backlog del PDR existente o features básicas.

**Comando:**
```bash
cp path/to/forja-template/forja/example.feature_list.json feature_list.json
# Editar feature_list.json con tus 3+ features inicial (con verification command)
```

**Tiempo:** ~30min (planificar features inicial).

**Verificación:** `make preflight` paso R11-3 → ✅.

---

### Paso 3 — Instalar hooks (R1/R2/R5/R11)

**Por qué:** sin hooks, las reglas duras quedan aspiracionales.

**Acción:** correr el script de install-hooks de Forja.

**Comando:**
```bash
make install-hooks
# o
bash scripts/install-hooks.sh
```

**Tiempo:** ~5min.

**Verificación:** `ls .git/hooks/ | grep -E "pre-commit|commit-msg"`.

---

### Paso 4 — Generar memory store (skills.md primero)

**Por qué:** R11-4 + R6 dispatch validation requieren skills.md.

**Acción:** copiar memory store template y poblar skills.md con los 23 skills disponibles + agregar custom si tu proyecto tiene skills propios mapeables.

**Comando:**
```bash
cp -r path/to/forja-template/forja/.claude/memory/* ./.claude/memory/
# Editar skills.md si tu proyecto tiene skills custom
```

**Tiempo:** ~15min.

---

### Paso 5 — Brand DNA (R10/R11-5 — bloqueante para UI)

**Por qué:** R10 enforced en todo skill UI-generator. Sin brand.json, impeccable / add-login / add-payments / etc. fallan.

**Acción:** correr `/add-ui-kit` Discovery FRESH para generar brand.json + voice.json + brand.css.

**Comando:**
```bash
# Dentro de Claude Code:
/add-ui-kit
```

**Tiempo:** ~30min (Discovery interactive).

**Verificación:** `test -f brand/brand.json && test -f brand/voice.json && test -f brand/brand.css`.

**ALTERNATIVA:** si ya tenés brand.json en otro formato, migrar a R-005 schema con `el-evaluador` o manualmente.

---

### Paso 6 — Stack base (init-saas o equivalente)

**Por qué:** init-saas resuelve la cadena Brand → components → auth en una invocación.

**Acción:** correr `/init-saas` (con resume-aware si Paso 5 ya cubrió Brand DNA, init-saas EXISTING resume desde paso 2 components).

**Comando:**
```bash
# Dentro de Claude Code:
/init-saas
```

**Tiempo:**
- Si Paso 5 ya hizo Brand DNA → init-saas resume desde paso 2 (components ~25min) + paso 3 (auth ~20min) = ~45min.
- Si Paso 5 lo skipeás → init-saas FRESH ~75min total.

**Verificación:** init-saas handoff reporta "Brand DNA + components + auth completed".

---

### Paso 7 — Tests (R11-2)

**Por qué:** sin ≥1 test passing, `/build` halt.

**Acción:** instalar Vitest si no existe + crear test sample.

**Comando:**
```bash
cd forja && npm i -D vitest
# Crear tests/sample.test.ts con un test passing trivial
echo 'import { describe, it, expect } from "vitest"; describe("sample", () => { it("works", () => { expect(1).toBe(1); }); });' > tests/sample.test.ts
npm test
```

**Tiempo:** ~20min.

**Verificación:** `npm test` exit 0.

---

### Paso 8 — Verificar Bootstrap Contract

**Por qué:** R11 enforcement. Sin esto, `/build` halts.

**Acción:** correr `make preflight`.

**Comando:**
```bash
make preflight
```

**Si exit 0:** Bootstrap Contract cumplido. Listo para `/build`.

**Si falla:** revisar mensaje exacto del gate específico y resolver. Re-correr.

---

### Paso 9 (OPCIONAL) — Setup enterprise completo

**Por qué:** si querés stack enterprise completo (pagos + emails + audit + PWA), `/enterprise-stack` lo cubre.

**Acción:** correr `/enterprise-stack` (resume-aware desde donde init-saas terminó).

**Comando:**
```bash
# Dentro de Claude Code:
/enterprise-stack
```

**Tiempo:**
- Resume-aware desde init-saas DONE → ejecuta solo add-monetization (~75min) + add-mobile-stack (~25min) = ~1h40min.
- Total enterprise: ~3-4h primera vez (incluyendo init-saas).

**Verificación:** enterprise-stack handoff reporta "Stack enterprise completo".

---

### Paso 10 (CRÍTICO si data sensitive) — RLS L-001 enforce

**Por qué:** L-001 — tablas con user_id deben tener RLS habilitado.

**Acción:** auditar todas las migrations existentes + agregar RLS donde falte.

**Comando:**
```bash
# Auditar
find supabase/migrations -name "*.sql" -exec grep -l "user_id" {} \; | xargs grep -L "ENABLE ROW LEVEL SECURITY"

# Agregar RLS donde falte (manualmente):
# ALTER TABLE [tabla] ENABLE ROW LEVEL SECURITY;
# CREATE POLICY "users_own_[tabla]" ON [tabla] FOR ALL USING (auth.uid() = user_id);
```

**Tiempo:** ~15-30min según cantidad de migrations.

**Verificación:** `el-guardian` audit reporta 0 RLS violations.

---

### Paso 11 (CRÍTICO si tools agentic) — R14 destructive tools

**Por qué:** R14 — tools destructivas (delete*, send*, transfer*, cancel*) sin `execute()` automático.

**Acción:** auditar tools existentes y removar `execute()` de las destructivas.

**Comando:**
```bash
# Auditar
grep -rE "tool\(\{[^}]*execute:" src/ --include="*.ts" | grep -iE "delete|send|transfer|cancel"

# Editar manualmente: removar execute() y agregar typed confirmation flow.
```

**Tiempo:** ~20min según cantidad de tools.

**Verificación:** `el-guardian` audit reporta 0 R14 violations.
```

#### Sección 6: Estimación Total

```markdown
## Estimación Total

| Path | Tiempo |
|------|--------|
| Bootstrap Contract mínimo (Pasos 1-8) | ~{X}h primera vez |
| Enterprise completo (Pasos 1-9) | ~{X}h primera vez |
| Con security audit completo (Pasos 1-11) | ~{X}h primera vez |

(Estimaciones basadas en proyecto Tipo {A/B/C/D/E} con {N} gaps detectados.)
```

#### Sección 7: Primer Comando a Correr

```markdown
## Primer Comando a Correr (HOY)

```bash
# Paso 1 — adoptar AGENTS.md + CLAUDE.md
cp -r path/to/forja-template/forja/{AGENTS.md,CLAUDE.md} ./
```

Después: seguir el plan paso por paso.
```

#### Sección 8: Próximos Pasos Después del Plan

```markdown
## Próximos Pasos

1. **Correr el primer comando indicado.**
2. **Avanzar paso por paso** siguiendo el plan.
3. **Cuando termines:** `make preflight` exit 0 → `/build` para tu primera feature.
4. **Si emerge un edge case:** documentar en `.claude/memory/errors.md` (vía `el-evaluador`) para futuros migration-wizards.
5. **Audit pre-deploy:** `/el-guardian` para Codex audit adversarial.

## Sources

[Citations [web:dominio.com](url) si se usaron fuentes externas durante el análisis. Section vacía si no aplica.]

---

*Plan generado por migration-wizard · Forja*
*NO ejecuta — el usuario corre los comandos en orden.*
```

### Paso 3 — Write el plan

Write file: `MIGRATION-PLAN-{nombre}.md` en path acordado.

### Paso 4 — Reportar handoff al usuario

```
✅ MIGRATION-PLAN generado: {path}

Resumen:
- Origen: Tipo {A/B/C/D/E}
- Bootstrap Contract gates passing: {N}/13
- Gaps críticos: {N}
- Reusable detectado: {N} items
- Estimación bootstrap: ~{X}h
- Estimación enterprise: ~{X}h

Primer comando a correr:
  {comando}

Para ejecutar el plan: seguilo paso por paso. Volvé acá si necesitás
ajustar algún paso o si emerge un edge case durante la migración.
```

## Edge cases

### Edge 1 — Plan generado pero el usuario rechaza
- migration-wizard NO ejecuta. Plan queda como referencia futura.

### Edge 2 — Tipo D (otro framework) con re-escritura inviable
- Plan documenta explícitamente el costo de re-escritura.
- Ofrecer alternativa: usar Forja en proyecto separado y migrar features gradualmente.

### Edge 3 — Plan parcial generado por interrupción
- Re-correr migration-wizard regenera el plan completo.

### Edge 4 — Cambios upstream en Forja-template entre invocaciones
- El plan referencia `forja-template` genéricamente. Usuario debe usar la versión actual de Forja al ejecutar.

## Citation

[memory:decisions#D-023] (pipeline shape DETECT → ANALYZE → PLAN), [memory:CONSTRAINTS.md#R11] (Bootstrap Contract gates), [memory:CONSTRAINTS.md#R10] (Brand DNA gate R11-5), [memory:CONSTRAINTS.md#R6] (skills.md registry), [memory:lessons#L-001] (RLS user_id), [memory:CONSTRAINTS.md#R14] (destructive tools), [memory:CONSTRAINTS.md#R8] (citation grammar Sources).
