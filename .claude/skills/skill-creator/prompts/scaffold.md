# scaffold

> Genera 4 artifacts del skill nuevo a partir de los inputs del entrevista (o YAML structured input en modo template-only). Output: skill folder listo para authoring real.

## Inputs

```yaml
# del prompts/interview.md (modo guided) o YAML structured input (modo template-only)
interview_result:
  name: <kebab-case>
  description: <texto>
  tier: core | optional | hidden
  shape: lightweight | orchestrator | pipeline | validator | meta
  has_selector: bool
  selector_dimensions: [...]              # si has_selector
  shape_rationale: <texto>                # si NOT has_selector
  reserved_adr_id: D-NNN
```

## Output

```
.claude/skills/<name>/
├── SKILL.md                              ← template completo, ~150-250 LOC
├── prompts/
│   └── README.md                         ← placeholder con instrucción
├── references/
│   └── README.md                         ← placeholder con instrucción
└── tests/
    └── dry-run.sh                        ← boilerplate L1+L2+L3 ejecutable
```

## Step 1 — Crear estructura de directorios

```bash
mkdir -p .claude/skills/<name>/prompts
mkdir -p .claude/skills/<name>/references
mkdir -p .claude/skills/<name>/tests
```

## Step 2 — Generar SKILL.md

Usar template canónico de [`references/skill-template.md`](../references/skill-template.md). Substituciones:

| Placeholder | Valor del interview |
|-------------|---------------------|
| `{{NAME}}` | name |
| `{{DESCRIPTION}}` | description |
| `{{TIER}}` | tier (formato según shape: "core", "core (lightweight)", "core (meta)", "optional", "hidden") |
| `{{SHAPE}}` | shape |
| `{{HAS_SELECTOR}}` | bool — afecta secciones del template |
| `{{ADR_ID}}` | reserved_adr_id (ej: D-019) |

Secciones del SKILL.md generado:

1. **Frontmatter YAML** completo (name, description, tier, requires, fallback, dependencies).
2. **Header H1 con epígrafe.**
3. **PREFLIGHT** placeholder (suave o duro según shape — lightweight=duro, orchestrator/pipeline=mix, validator=variable).
4. **Activación** tabla "cuándo se invoca + quién".
5. **Mode selector** (solo si has_selector=true) o **Shape rationale** (si has_selector=false).
6. **Loop o flujo principal** placeholder específico por shape.
7. **Output shape** con ejemplo.
8. **Reglas operativas** — mínimo 5 numeradas, con citation slots.
9. **Refusals** — mínimo 5.
10. **Tool filter** estimado por shape.
11. **Citation grammar** tabla (R/L/D apropiados).
12. **Integración con otros skills** tabla.
13. **Output handoff** template.
14. **Closing italic line** placeholder.

Comentario final del archivo:
```markdown
<!-- TODO post-authoring:
1. Llenar PREFLIGHT con gates específicos.
2. Authorizar prompts/ y references/.
3. Completar tests/dry-run.sh con checks reales.
4. Invocar el-evaluador para registrar entry en skills.md + ADR D-NNN
   (binary | trinary | boundary case según has_selector).
5. Cerrar feature en feature_list.json.
-->
```

## Step 3 — Generar prompts/README.md

```markdown
# {{NAME}} — prompts

Placeholder. Authorizar sub-prompts canónicos según shape:

- **lightweight**: 1-3 prompts (ej: triage-task.md, execute-iteration.md, close-or-escalate.md).
- **orchestrator**: prompts/select-pattern.md + prompts/orchestrate-*.md por pattern + prompts/handoff-*.md.
- **pipeline**: prompts/detect-state.md + prompts/run-step.md + prompts/build-output.md.
- **validator**: prompts/run-audit.md + prompts/build-report.md.
- **meta**: prompts/interview.md + prompts/scaffold.md (paralelo a skill-creator mismo).

Referencia: `.claude/skills/{{SHAPE_REFERENCE}}/prompts/` para pattern canónico.

Cuando termines de authorizar prompts/, eliminá este README.
```

## Step 4 — Generar references/README.md

```markdown
# {{NAME}} — references

Placeholder. Authorizar references según necesidad:

- **examples.md** (recomendado siempre): 3 escenarios canónicos del skill.
- **<topic>-rationale.md**: si shape requiere documentar L-004 application
  o boundary case (ver el-crisol/strategy-pipeline-rationale.md o
  web-quality/audit-mode-rationale.md como ejemplos).
- **<topic>-patterns.md**: si shape requiere guías técnicas extensas
  (ver web-quality/{performance,accessibility,seo,best-practices}.md).

Cuando termines de authorizar references/, eliminá este README.
```

## Step 5 — Generar tests/dry-run.sh boilerplate

Usar template canónico de [`references/dry-run-template.md`](../references/dry-run-template.md).

El boilerplate generado incluye:

- Header con E-008 awareness comment + F3-S10/S11 frictions absorbidas:
  ```bash
  #!/usr/bin/env bash
  # {{NAME}} dry-run test
  #
  # L1 (file presence) + L2 (frontmatter + contract) + L3 (escenarios).
  # E-008 awareness: usa `grep -E` con `|` plain (NUNCA `\|` ni `\\|`).
  # F3-S10/S11 frictions absorbidas:
  #   - Mode patterns: relax con ( N)? si pattern puede variar
  #   - Case-sensitivity: -i flag donde aplica
  #   - Patterns con --: usar `grep -qE -- "pattern"` para getopts
  #   - Ventanas -A flexibles (≥30 para secciones largas, ≥150 para bloques extendidos)
  ```

- Standard set/strict mode + helpers:
  ```bash
  set -euo pipefail
  
  SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  
  PASS=0
  FAIL=0
  ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
  fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
  ```

- L1 file presence (placeholder con archivos esperados según shape).
- L1 frontmatter checks (name, tier, requires, fallback, dependencies).
- L2 PREFLIGHT + reglas operativas placeholder.
- L3 escenarios canónicos placeholder con TODOs explícitos.
- D-NNN cita placeholder.
- Summary block estándar:
  ```bash
  echo ""
  echo "── Summary ────────────────────────────────────────────────────"
  echo "  PASS: $PASS"
  echo "  FAIL: $FAIL"
  if [ "$FAIL" -eq 0 ]; then
    echo "✅ {{NAME}} dry-run: ALL PASS ($PASS checks)"
    exit 0
  else
    echo "❌ {{NAME}} dry-run: $FAIL failures"
    exit 1
  fi
  ```

- `chmod +x` en el archivo (o instrucción al autor de ejecutarlo).

## Step 6 — Validación post-scaffold

```bash
# Verificar estructura
test -f .claude/skills/<name>/SKILL.md
test -d .claude/skills/<name>/prompts
test -d .claude/skills/<name>/references
test -f .claude/skills/<name>/tests/dry-run.sh

# Verificar dry-run.sh ejecutable y válido (parsing bash, no execution)
bash -n .claude/skills/<name>/tests/dry-run.sh
```

Si validación falla → reportar error específico al usuario + revertir scaffold (rm -rf .claude/skills/<name>).

## Step 7 — Mensaje final al usuario

```markdown
## ✅ Skill scaffolded

**Skill:** <name> ({{TIER}}, {{SHAPE}})
**Location:** .claude/skills/<name>/

**Files generados:**
- SKILL.md (template completo, ~150-250 LOC)
- prompts/README.md (placeholder)
- references/README.md (placeholder)
- tests/dry-run.sh (boilerplate L1+L2+L3, ejecutable)

**ADR reservado:** {{ADR_ID}} ({{SELECTOR_TYPE}}: binary | trinary | boundary case)

**Próximo paso:**
1. Abre `.claude/skills/<name>/SKILL.md` y completá:
   - PREFLIGHT con gates específicos del skill.
   - Reglas operativas (al menos 5).
   - Refusals (al menos 5).
   - Citation grammar tabla.
   - Integración con otros skills.
2. Authoriza `prompts/` (1-3 archivos según shape).
3. Authoriza `references/` (al menos examples.md).
4. Completá `tests/dry-run.sh` con checks reales (target: 60-150 según shape).
5. Run `bash .claude/skills/<name>/tests/dry-run.sh` hasta 100% PASS.
6. Invocá `el-evaluador` para registrar entry en skills.md + ADR {{ADR_ID}}.
7. Cerrá feature en feature_list.json + merge.
```

## Modo template-only (sin entrevista)

Si invoked con YAML structured input directo (CI/automation), saltar `prompts/interview.md` y ir directo a Step 1 con los inputs ya provistos.

Validación adicional para template-only:
- Todos los campos del `interview_result` deben estar presentes.
- Si falta cualquier campo → halt + reportar gap.
- Si campos válidos pero contradictorios (ej: tier=hidden + shape=lightweight) → reportar inconsistencia + esperar correction.

## Edge cases

### Edge: scaffold falla mid-step (ej: permisos en mkdir)

→ Revertir steps previos (rm -rf .claude/skills/<name>) + reportar al usuario. NO scaffold parcial.

### Edge: el SKILL.md template tiene placeholder sin valor del interview

→ Detectar pre-write + halt + reportar gap. Mejor crashear que generar SKILL.md con `{{NAME}}` literal.

### Edge: el archivo dry-run.sh boilerplate falla `bash -n` parsing

→ Bug en el template. Reportar + halt + revertir scaffold.

### Edge: tier=core con nombre NO metalúrgico

→ Warning suave (NO halt): "tier=core convención preferida es nombre metalúrgico (la-X, el-X). ¿Confirmás <nombre> tal cual?". El usuario decide.

### Edge: shape=lightweight pero el SKILL.md template incluye `templates/` folder placeholder

→ Bug en el template. Skills lightweight NO tienen templates folder por convención. Reportar + halt.

## Citation grammar

- [memory:CONSTRAINTS.md#R5] — skill-creator NO escribe a memory (solo el-evaluador post-authoring).
- [memory:errors#E-008] — boilerplate dry-run.sh con awareness from birth.
- [memory:decisions#D-018] — skill-creator binary mode.

## Refusals

- ❌ Generar SKILL.md sin frontmatter completo (frontmatter es contrato).
- ❌ Generar dry-run.sh sin E-008 awareness comment (lesson absorbida desde scaffold).
- ❌ Sobrescribir skill folder existente sin confirmation explícita.
- ❌ Scaffold parcial (si falla mid-step → revertir todo).
- ❌ Skip de validación post-scaffold (`bash -n` mandatorio).
- ❌ Generar templates/ folder en shape=lightweight.
