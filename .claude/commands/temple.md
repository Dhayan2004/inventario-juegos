---
description: "Auditoría full-project pre-release (4 dimensiones + Audit Score, bloquea deploy ante críticos) — project-auditor."
---

# /temple — Auditoría Full-Project (4 dimensiones, score compuesto)

> *"El acero se templa antes de soportar carga."*

Auditoría integral de **TODO el proyecto** (no solo el diff) en 4 dimensiones, con UN reporte
priorizado y un **Audit Score compuesto (0-100)**. Es el gate de seguridad **pre-release** de la
doctrina shift-left de Forge Enterprise (`CONSTRAINTS.md` § DevSecOps).

A diferencia de `el-guardian` (que audita la **feature activa / el diff** pre-deploy con Codex),
`/temple` barre `src/` completo con ripgrep, cruza la **threat-db** (77 amenazas) + los
**`requisitos_seguridad` de `ONTOLOGY.md`** + la **Sección 6 del SPEC**, consulta los advisors de
Supabase, y escribe un reporte versionable con score.

## Dimensiones

| Dimensión | Peso | Qué cubre |
|-----------|------|-----------|
| 🔒 Seguridad | 30% | threat-db + contrato (ONTOLOGY `requisitos_seguridad` + SPEC §6), secrets, injection, auth |
| 🗄️ Datos & Supabase/RLS | 25% | `get_advisors(security)`, RLS, filtros `user_id`, `service_role` |
| ⚡ Cache & Rendimiento | 25% | fetch sin cache, `revalidate`, N+1, índices, CDN, Web Vitals |
| 🌐 Calidad Web | 20% | A11y + SEO + Best Practices + `npm audit` (vía web-quality) |

## Modos de invocación

| Modo | Sintaxis | Qué hace |
|------|----------|----------|
| Full (default) | `/temple` | Las 4 dimensiones + reporte + score compuesto |
| Quick | `/temple quick` | Checklist rápido pre-deploy (solo críticos, sin score detallado) |
| Una dimensión | `/temple security` · `datos` · `cache` · `web` | Solo esa dimensión |
| Compare | `/temple compare` | Compara contra el último snapshot en `.forja/audits/` |
| Capa profunda | `/temple --deep` | Añade la capa adversarial de `el-guardian` (Codex, opt-in) |
| Harness | `/temple --harness` | Audita el harness mismo (hooks vivos, tool-filters, inyección, MCP/config, R15 sobre `.claude/`) — doctrina AgentShield, `QUALITY_GATES.md §3` |

## Ejecución

Lee y ejecuta `.claude/skills/project-auditor/SKILL.md`.

## Regla de bloqueo (fail-closed)

Cualquier hallazgo `critical`, o cualquier `requisito_seguridad: critico` del contrato de la empresa
no satisfecho, marca **⛔ BLOQUEA DEPLOY** — sin importar el score numérico.

## Ejemplo

```
/temple
/temple cache
/temple quick
/temple compare
/temple --deep
```

## Relacionado

- `el-guardian` — auditor adversarial de la **feature activa** pre-deploy (y la capa `--deep` de aquí).
- `la-herreria` asset #9 — el gate **pre-Blueprint** (misma threat-db + contrato).
