#!/usr/bin/env bash
# design-seed.sh — entropía EXTERNA para Discover visual (D-037 · Anshu/Sakana SSoT con PRNG de shell)
#
# El modelo no puede ser aleatorio: pedirle "sé único" produce el token más probable de *sonar* aleatorio
# (púrpura, hero izq/der, cerámica). La semilla sale del PRNG del sistema operativo, nunca "de la cabeza"
# del agente (Gu et al. 2026, *The Illusion of Stochasticity*). El agente solo MAPEA semilla → dirección.
#
#   bash scripts/design-seed.sh <slug> <N>          # crea design-lab/<YYYY-MM-DD>-<slug>/v1..vN/SEED.md
#   bash scripts/design-seed.sh landing 5
#
# Reglas (la-herreria asset 07 · add-ui-kit discovery-fresh bloque (c) opción "semilla"):
#   - una semilla distinta por variante; prohibido reusar o copiar CSS entre vN
#   - el string NUNCA se revela en la UI (string_in_ui: false) — provenance solo en SEED.md
#   - SEED.md sí va a git; screenshots/mp4 no (.gitignore que este script siembra)
#   - el SPEC y .plan/decisions[] se LEEN, no se escriben, hasta CHOSEN.md (R1/R5/R19)
set -euo pipefail

slug="${1:-}"; n="${2:-5}"
if [[ -z "$slug" ]]; then echo "uso: design-seed.sh <slug> [N=5]" >&2; exit 2; fi
if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 || n > 12 )); then echo "N debe ser 1..12 (Anshu: 4–5; ≥4 para detectar colapso)" >&2; exit 2; fi

gen_seed() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import secrets,string; a=string.ascii_letters+string.digits; print(''.join(secrets.choice(a) for _ in range(128)))"
  elif command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 192 | tr -dc 'A-Za-z0-9' | head -c 128; echo
  else
    LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 128; echo
  fi
}

root="${DESIGN_LAB_ROOT:-design-lab}"
run="$root/$(date +%F)-$slug"
mkdir -p "$run"

# .gitignore del lab: provenance sí, pixeles/video no (política del repo puede subirlos a LFS)
if [[ ! -f "$root/.gitignore" ]]; then
  cat > "$root/.gitignore" <<'EOF'
# design-lab — provenance en git, pixeles fuera (o LFS según política del repo)
*.png
*.jpg
*.webp
*.mp4
*.mov
!**/SEED.md
!**/CHOSEN.md
!**/failed-prompts.md
!**/motion-storyboard.md
!**/enrich-plan.md
EOF
fi
# A5 — prompts que fallaron = eval fixtures del próximo modelo
if [[ ! -f "$root/failed-prompts.md" ]]; then
  cat > "$root/failed-prompts.md" <<'EOF'
# failed-prompts — ideas que sonaron terribles o que el modelo no pudo ejecutar (A5)

> Guardar el prompt, la fecha, el modelo y qué salió mal. Re-probar en cada salto de modelo: mide si
> estamos usando el techo del modelo nuevo. Dataset de regresiones, no de demos.

| Fecha | Modelo | Prompt (resumen) | Qué falló | Re-test |
|---|---|---|---|---|
EOF
fi

for ((i=1; i<=n; i++)); do
  dir="$run/v$i"
  if [[ -e "$dir/SEED.md" ]]; then echo "skip $dir (SEED.md ya existe — no se pisa una variante)"; continue; fi
  mkdir -p "$dir"
  seed="$(gen_seed)"
  cat > "$dir/SEED.md" <<EOF
# SEED — $run / v$i

seed: $seed
source: os_prng ($(command -v python3 >/dev/null 2>&1 && echo python3-secrets || echo openssl/urandom))
generated: $(date -u +%FT%TZ)
string_in_ui: false

## derived (lo llena el agente — mostrar la cuenta, no solo el resultado)
palette:
layout:
type:
motif:
arithmetic:   # substrings / char codes / mod — cómo se llegó de la semilla a la dirección

## posture (contrato R-005 §1.1 — obligatorio, como cualquier dirección custom)
density: · expression: · geometry: · warmth: · editoriality: · materiality:

## screenshot
desktop: v$i/screenshot@desktop.png
mobile:  v$i/screenshot@mobile.png
EOF
  echo "v$i  $dir/SEED.md  seed=${seed:0:12}…"
done

echo ""
echo "→ $n variante(s) en $run. Misma brief, distinta semilla, sin copiar CSS entre v*."
echo "→ Tras generar + screenshot: node scripts/design-diversity.mjs $run  (colapso = batch inválido)"
echo "→ El humano elige y escribe $run/CHOSEN.md (taste notes = SPEC, R19); una sola entrada en decisions[]."
