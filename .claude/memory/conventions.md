# Conventions — Forja Memory

> Project-wide conventions. Append-only.
> **Single writer:** `el-evaluador`. Other agents READ ONLY.
>
> Cite as `[memory:conventions#section]`

---

## Naming

- **Skills core en español metalúrgico:** `la-herreria`, `el-crisol`, `la-forja`, `el-evaluador`, `el-guardian`, `el-migrador`, `el-tajo`, `el-golpe`, `el-supervisor` (opcional).
- **Skills funcionales en inglés cuando son universales:** `add-login`, `add-payments`, `add-emails`, `add-mobile`, `add-ui-kit`, `web-quality`, `ai`, `primer`, `sprint`, `baas`.
- **Comandos slash siguen el nombre del skill:** `/forge-init`, `/build`, `/plan`, `/crisol`, `/despachar`, `/inspeccionar`.

## Idioma

- **Docs internas + comentarios:** español
- **Código + identifiers:** inglés
- **Commits:** inglés con conventional format
- **UI generada por agentes:** según `voice.json` del proyecto target

## Commits

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

- **Types:** `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `style`, `perf`, `ci`, `build`
- **Scope:** ID de feature (`F1-T1`) o componente (`auth`, `ui-kit`)
- **Description:** imperativo, lowercase, ≥10 chars, sin punto final

## Branch naming

- `feature/<short-description>` — features nuevos
- `fix/<short-description>` — bug fixes
- `refactor/<short-description>` — refactors sin cambio de comportamiento
- `chore/<short-description>` — mantenimiento (deps, configs)
- `docs/<short-description>` — solo docs

## File organization

- **Feature-First:** código vive en `src/features/<feature-name>/` por feature.
- **Shared:** utilidades cross-feature en `src/shared/`.
- **Components UI:** en `src/features/<feature>/components/` o `src/shared/components/` si reusables.

## Citation grammar

- Memory interno: `[memory:lessons#L-001]`
- Web externo: `[web:dominio.com](url)`
- Docs externos vía Context7: `[docs:libname]` o `[docs:libname@version]` (ej. `[docs:vercel-ai-sdk@v5]`, `[docs:supabase]`). Producido por skill `find-docs`. Enforced por R13.
- Docs internos del repo: markdown links relativos `[CONSTRAINTS.md](../CONSTRAINTS.md)`

---

<!-- additional conventions populated as discovered -->
