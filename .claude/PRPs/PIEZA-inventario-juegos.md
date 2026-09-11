# 🔩 PIEZA: F2-01 — Brand DNA (Inventario de Videojuegos)

> Spec ejecutable derivada de `.claude/PRPs/BLUEPRINT-inventario-juegos.md` §0 "Brand DNA (R10)" y Fase 2.
> Feature activa (R1): `F2-01`. Rama (R3): `chore/brand-dna`.

## Objetivo

Cerrar `F2-01`: el Brand DNA del proyecto existe, es válido contra el schema R-005, y queda commiteado
como base para toda UI subsiguiente (F2-02..F2-04, F3..F5).

## Verification command (de feature_list.json)

```
test -f brand/brand.json && test -f brand/voice.json && npm run brand:validate
```

## Estado de partida (detectado, no asumido)

- `brand/brand.json`, `brand/voice.json`, `brand/brand.css`, `brand/motion.ts` — generados hoy por
  `add-ui-kit` (modo FRESH, preset Tech Utility), **untracked**.
- `COMPONENT_RULES.md` y `src/app/(brand)/` (showcase) — untracked.
- `feature_list.json`, `package.json`, `package-lock.json` — modificados, sin commit.
- Ningún commit de este trabajo existe todavía (`git log` muestra solo el baseline `996b424`).

## Criterios de aceptación (de feature_list.json)

1. Los 3 archivos de brand existen (`brand.json`, `voice.json`, `brand.css`).
2. `npm run brand:validate` exit 0 (schema_version, keyed spacing, motion enums).
3. Preset Tech Utility: densidad alta, sin fuentes/gradientes/anti-slop prohibidos.

## Pasos

1. Layer 1 (Syntax): `make typecheck && make lint` sobre lo nuevo (brand/*, `src/app/(brand)/`).
2. Layer 2 (Runtime): `npm run brand:validate` — debe salir 0. Si falla, corregir `brand.json`/`voice.json`
   contra `.claude/references/BRAND_DNA_SCHEMA.md` (R-005), no relajar el validador.
3. Layer 3 (System): revisar el showcase en `src/app/(brand)/` contra `visual_posture` declarado
   (densidad 4, expresión 2, geometría 4, calidez 2) — confirmación visual de que el preset Tech Utility
   se ve como tal (sin Inter/Roboto/Arial de acento, sin gradiente decorativo).
4. `el-evaluador` firma Three-Layer Verification y marca `F2-01` → `passing` en `feature_list.json`.
5. Commit atómico (R2) con rutas explícitas (C2 de la casa — nunca `git add .`):
   `brand/brand.json brand/voice.json brand/brand.css brand/motion.ts COMPONENT_RULES.md "src/app/(brand)/" feature_list.json`.
   Mensaje: `feat(F2-01): brand dna tech utility preset`.
6. Handoff: siguiente feature activa es `F2-02` (Menú Principal, panel de control puro) — requiere que
   `F2-01` esté `passing` (consume `brand.css` para tokens).

## Fuera de alcance en esta pieza

- No se toca `package.json`/`package-lock.json` más allá de lo que `add-ui-kit` ya dejó (si el diff trae
  dependencias no relacionadas a brand, se separa en su propio commit — R2 atomic).
- No se generan componentes (`impeccable`) todavía — eso es F2-02/F2-04.

## Riesgo (pre-mortem del Blueprint, aplicable)

🐈 Paper tiger: si `brand:validate` no existe como script en `package.json`, es un blocker duro de F2-01 —
no hay fallback silencioso (R10 es contrato no-negociable).
