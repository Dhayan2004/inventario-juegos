# Target Project Structure — qué archivos canónicos buscar

## Estructura canónica de un proyecto generado con Forja

```
<project-root>/
├── AGENTS.md                          # Routing del agente (entry point)
├── README.md                           # Info para humanos cold-arriving
├── CLAUDE.md                           # Compatibility shim → AGENTS.md
├── package.json                        # Stack dependencies
├── next.config.mjs                     # Next.js config (si aplica)
├── tsconfig.json                       # TS config
├── .env.local                          # Secrets (NO commiteado)
├── .env.example                        # Template para .env.local
├── .gitignore
│
├──                               # Forja-specific files
│   ├── feature_list.json               # State machine (R3 source of truth)
│   ├── PROGRESS.md                     # Narrative humana de sesiones previas
│   ├── HEAD                            # Fallback active feature (.forja/HEAD)
│   │
│   ├── .claude/
│   │   ├── memory/
│   │   │   ├── decisions.md            # ADRs (D-NNN)
│   │   │   ├── lessons.md              # Lessons (L-NNN)
│   │   │   ├── errors.md               # Errors (E-NNN)
│   │   │   ├── references.md           # External refs (R-NNN — diferente a R# constraint rules)
│   │   │   ├── skills.md               # Skill registry
│   │   │   └── conventions.md          # Citation grammar + naming
│   │   └── skills/                     # Skill folders (per-skill)
│   │       └── ...
│   │
│   ├── brand/
│   │   ├── brand.json                  # R-005 schema (tokens + posture + archetype)
│   │   ├── voice.json                  # Voice contract
│   │   └── brand.css                   # CSS vars derivadas
│   │
│   └── PRPs/                           # Blueprints de la-herreria
│       └── BLUEPRINT-*.md
│
├── src/                                # Application code
│   ├── app/                            # Next.js App Router
│   │   ├── (auth)/                     # Auth pages (add-login output)
│   │   ├── (mobile)/                   # PWA install (add-mobile output)
│   │   ├── (billing)/                  # Pricing + checkout (add-payments)
│   │   └── api/                        # API routes
│   ├── components/                     # Shared components
│   ├── shared/components/ui/           # impeccable output
│   ├── features/                       # Feature folders
│   ├── lib/                            # SDK clients (supabase/insforge/stripe/etc.)
│   ├── hooks/                          # React hooks
│   ├── actions/                        # Server actions
│   └── emails/                         # React Email components (add-emails)
│
├── public/                             # Static assets
│   ├── manifest.json                   # PWA manifest (add-mobile)
│   ├── sw.js                           # Service worker (add-mobile)
│   └── icons/                          # App icons
│
└── supabase/                           # If BaaS = Supabase
    └── migrations/                     # SQL migrations
        ├── 0001_profiles.sql           # add-login output
        ├── 0002_subscriptions.sql      # add-payments output
        ├── 0003_email_subscriptions.sql # add-emails output
        └── 0004_push_subscriptions.sql # add-mobile output
```

## Archivos críticos para primer

### Tier 1 — must read (siempre)
- `AGENTS.md` (routing)
- `feature_list.json` (state machine)
- git status + log (R3 fallback)

### Tier 2 — should read (si presente)
- `PROGRESS.md` (narrative humana)
- `brand/brand.json` (Brand DNA snapshot)
- `.claude/memory/decisions.md` (ADR count + último)

### Tier 3 — read solo si tier 1+2 no cubren
- `README.md` (humanos cold-arriving — info que NO debería duplicar AGENTS.md)
- `package.json` (stack confirm si AGENTS no declara explícito)

## Markers de detection

### "Es proyecto Forja"

```
✓ AGENTS.md existe
✓  directory existe
✓ feature_list.json existe
```

Si los 3 → proyecto Forja válido.
Si <3 → modo cold-start o "proyecto NO inicializado con Forja".

### "Es Forja factory mismo (NOT target project)"

```
✓ .claude/skills/skill-creator/ existe
✓ .claude/memory/skills.md tiene >10 entries
✓ ARCHITECTURE.md existe en root
✓ scripts/hooks/ existe (Phase 4 hooks instalados)
```

Si los 4 → es el repo Forja mismo. primer debería sugerir `session_kickoff` (que vive en `~/.claude/projects/-Users-...-forja/memory/`) en lugar de skills target-project.

### "Stack del proyecto"

Detection from `package.json`:
- `"@supabase/supabase-js"` o `"@supabase/ssr"` → BaaS = Supabase
- `"@insforge/sdk"` (hipotético) → BaaS = Insforge
- `"next"` → Next.js
- `"react"` solo (sin Next.js) → React standalone
- `"@capacitor/core"` → Mode B mobile
- `"expo"` → Mode C mobile

## Edge cases de structure

| Caso | Comportamiento primer |
|------|----------------------|
| `AGENTS.md` en lugar diferente (ej: `docs/AGENTS.md`) | Buscar con Glob `**/AGENTS.md` priorizando raíz |
| `` directory pero `feature_list.json` missing | Reportar gap + sugerir corregir |
| Múltiples `feature_list.json` (root + subdir) | Usar el de `` por convention |
| Brand DNA en lugar diferente (ej: `design/brand.json`) | Buscar con Glob `**/brand.json` priorizando `brand/` |
| Mobile codebase paralelo (`forja-mobile/`) | Detectar + reportar como sibling project (no leer su feature_list a menos que se pida explícito) |

## Citations

- [memory:CONSTRAINTS.md#R3] (active feature resolution)
- [memory:references#R-005] (Brand DNA schema)
- [memory:CONSTRAINTS.md#R5] (memory store ownership)
