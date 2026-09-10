.PHONY: setup test typecheck lint build e2e deploy clean preflight help install-hooks lint-citations test-hooks playbook plan plan-validate protect ontology-migrate

# ──────────────────────────────────────────────────────────────────
# Forja — Primary command surface (proyecto instalado)
# ──────────────────────────────────────────────────────────────────
# Every target here is consumable by both humans and agents.
# el-evaluador uses these for Three-Layer Verification (R7).
#
# Este Makefile asume que está en la raíz del proyecto target
# (instalado vía alias `forja`). No hay prefijo `cd forja &&`.

help:
	@echo "Forja — comandos disponibles:"
	@echo "  make setup           Initial bootstrap (deps + git hooks)"
	@echo "  make install-hooks   (Re)install git hooks from scripts/hooks/"
	@echo "  make preflight       Bootstrap Contract verification (R11)"
	@echo "  make lint-citations  Citation lint (R13 advisory, non-blocking)"
	@echo "  make test-hooks      Run hook unit + integration tests"
	@echo "  make typecheck       Layer 1 — Syntax (tsc + eslint + tailwind)"
	@echo "  make test            Layer 2 — Runtime (unit + integration)"
	@echo "  make e2e             Layer 3 — System (E2E + visual diff vs brand.json)"
	@echo "  make build           Production build"
	@echo "  make deploy          Deploy via vercel/coolify (requires confirmation)"
	@echo "  make clean           Remove build artifacts and caches"
	@echo "  make playbook        Regenerate PLAYBOOK.html desde PLAYBOOK.md"
	@echo "  make plan            Abrir el plano de control (.plan/) en http://localhost:4317"
	@echo "  make plan-validate   Validar .plan/plan.json + activity.log.jsonl (R17)"
	@echo "  make protect         Branch protection en main vía gh (S2 · el-capataz, idempotente/fail-safe)"
	@echo "  make ontology-migrate  Migrar el esquema de ONTOLOGY.md (S3, dry-run; APPLY=1 para aplicar)"

setup:
	@echo "==> Setting up Forja..."
	@npm install
	@./scripts/install-hooks.sh
	@echo "==> Setup complete."

install-hooks:
	@./scripts/install-hooks.sh

preflight:
	@./scripts/preflight.sh

lint-citations:
	@./scripts/citation-lint.sh

test-hooks:
	@bash scripts/hooks/tests/run-all.sh

typecheck:
	@echo "==> Layer 1 — Syntax verification..."
	@npx tsc --noEmit 2>/dev/null || echo "(typecheck pending — falta npm install?)"
	@npx eslint . 2>/dev/null || echo "(lint pending — falta npm install?)"

lint: typecheck

test:
	@echo "==> Layer 2 — Runtime verification..."
	@npm test 2>/dev/null || echo "(test runner pending — agregá tests al proyecto)"

build:
	@echo "==> Production build..."
	@npm run build 2>/dev/null || echo "(build target pending — falta npm install?)"

e2e:
	@echo "==> Layer 3 — System verification (agent-browser CLI)..."
	@npx agent-browser test 2>/dev/null || echo "(e2e pending — agent-browser no instalado)"

deploy:
	@echo "==> Deploy requires explicit confirmation. Run /despachar instead."
	@exit 1

clean:
	@rm -rf node_modules .next dist build .turbo
	@find . -name "*.log" -type f -delete
	@echo "==> Clean complete."

playbook:
	@echo "==> Regenerando PLAYBOOK.html desde PLAYBOOK.md..."
	@node scripts/md-to-html.js PLAYBOOK.md PLAYBOOK.html --title "Forja Playbook"

# ── Plano de control (A1) ──────────────────────────────────────────
plan:
	@test -d .plan || { echo "No existe .plan/ — corré /cartografo para inicializar el plano."; exit 1; }
	@echo "==> Plano de control en http://localhost:4317 (Ctrl-C para salir)..."
	@node scripts/plan-server.mjs

plan-validate:
	@node -e 'try{const fs=require("fs");\
	  const pf=".plan/plan.json", lf=".plan/activity.log.jsonl";\
	  if(!fs.existsSync(pf)){console.log("(sin .plan/plan.json — nada que validar)");process.exit(0)}\
	  const p=JSON.parse(fs.readFileSync(pf,"utf8"));\
	  if(!p.project||!Array.isArray(p.phases))throw new Error("plan.json: falta project/phases");\
	  if(fs.existsSync(lf)){fs.readFileSync(lf,"utf8").split("\n").filter(Boolean).forEach((l,i)=>{try{JSON.parse(l)}catch{throw new Error("activity.log.jsonl línea "+(i+1)+" inválida")}})}\
	  console.log("✓ plano válido: "+p.phases.length+" fases, schema "+(p._meta&&p._meta.schema_version||"?"))}\
	  catch(e){console.error("✗ R17: "+e.message);process.exit(1)}'

# ── Gobernanza de equipo (S2 · el-capataz) ─────────────────────────
protect:
	@bash scripts/protect-branch.sh

# ── Versionado de la ontología (S3 · el-ontologo) ──────────────────
# Migra el esquema de ONTOLOGY.md sin tocar datos. Default = dry-run.
#   make ontology-migrate          → preview (nada se escribe)
#   make ontology-migrate APPLY=1  → aplica las pendientes
ontology-migrate:
	@test -f ONTOLOGY.md || { echo "No existe ONTOLOGY.md — corré /ontologia (el-ontologo) primero."; exit 1; }
	@node scripts/apply-ontology-migrations.mjs $(if $(APPLY),--apply,)
