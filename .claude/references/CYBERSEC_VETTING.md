# Vetting de contenido de ciberseguridad defensivo (C3)

> **Qué es esto.** El **protocolo de vetting de 5 pasos** para incorporar contenido de seguridad
> **defensivo** a Forge Enterprise, y la política de qué se adopta y qué no. La cantera principal es
> `Anthropic-Cybersecurity-Skills` (`mukul975`) — una base de comunidad, licencia **Apache-2.0**, **NO
> un proyecto oficial de Anthropic** pese al nombre. Ese nombre engañoso crea un falso halo de autoridad,
> y es precisamente el primer motivo por el que **nada se adopta sin vetar**.
>
> **Decisión (`docs/05` §7.3.3/§7.5 · `docs/06` §C3/§9-G):** **NO importar el repo de ~817 skills.** Se
> incorpora un **subconjunto CURADO de 8–12 REFERENCIAS defensivas**, cada una vetada por los 5 pasos y
> **reescrita al estándar Forge** (no el `SKILL.md` crudo). El catálogo de 817 se trata como
> **inspiración y cantera**, nunca como dependencia importada en bloque (lección Vercel: −80% tools =
> +3× rendimiento). Cero contenido ofensivo.

- **Versión:** v0.1.0 (2026-06-30, C3 · Calidad — vetting de cybersec defensivo)
- **Alimenta:** el gate **CI/DevSecOps** por fase (`[memory:CONSTRAINTS.md]` § Seguridad shift-left, S1/A3) — le da **cantera de contenido vetado**, no un import masivo.
- **Regla de enforcement:** `[memory:CONSTRAINTS.md]` § DevSecOps (gates por fase) + R14 (tools destructivos → confirmación humana) + AP3 (el que vetea no es el que genera; `el-evaluador` firma).

---

## 1. Por qué vetting obligatorio (procedencia y dual-use)

`Anthropic-Cybersecurity-Skills` es **comunidad, no Anthropic**. Su propio `SECURITY.md` sólo cubre el
reporte de vulnerabilidades: **no gobierna el contenido ofensivo, no exige disclaimers de uso
autorizado, ni advierte sobre verificar las skills antes de usarlas** — la responsabilidad de vetting
recae **100% en quien adopta**. Además el contenido es **dual-use** (defensa y ataque comparten técnicas).
Por eso: **ninguna skill entra a Forge sin pasar los 5 pasos.** No se importa el repo; se **vetan e
incorporan referencias reescritas**.

---

## 2. El protocolo de vetting — 5 pasos (lo ejecutan `el-guardian` + `el-evaluador`)

Cada candidata pasa los 5 pasos **en orden**; si falla uno, se rechaza. AP3 aplica: quien vetea
(`el-guardian` adversarial + `el-evaluador` picky) **no** es quien genera el código que luego audita.

| # | Paso | Qué verifica | Falla si… |
|---|------|--------------|-----------|
| 1 | **Procedencia** | autor, historial de commits, skill no alterada; se registra el **commit hash exacto** adoptado (snapshot inmutable, **no `main` vivo**) | no se puede fijar un hash inmutable / origen dudoso |
| 2 | **Filtro defensivo (hard)** | rechazo automático si nombre/tags incluyen `attacking-`, exploitation, C2, phishing-offensive, red-team; **solo** pasa secure-development / defensivo / detección | cualquier señal ofensiva o dual-use peligrosa |
| 3 | **Precisión técnica** | `el-evaluador` revisa que los comandos del workflow sean correctos, **no destructivos**, y no introduzcan deps con CVE; cruce con **R14** (destructivos → confirmación humana) | comando incorrecto/destructivo, o dep con CVE |
| 4 | **Reescritura a estándar Forge** | no se adopta el `SKILL.md` crudo: se **re-deriva como referencia** (frontmatter + Brand/citation grammar de Forge: `[web:dominio](url)`, `[docs:libname]`), eliminando instrucciones ambiguas heredadas | no puede reescribirse sin conservar ambigüedad/ofensiva |
| 5 | **Gate adversarial** | `el-guardian` (Codex) corre la candidata como **quinto atacante** contra un proyecto de prueba antes de promoverla | introduce riesgo bajo ataque adversarial |

> **La regla maestra:** sólo tras los 5 pasos una referencia entra al subconjunto curado. Los pasos 1–2
> son **hard filters** automáticos (procedencia + defensivo); 3–5 exigen juicio (`el-evaluador` técnico,
> `el-guardian` adversarial). El resultado no es una skill importada: es una **referencia Forge reescrita**
> con su hash de origen citado.

---

## 3. El subconjunto defensivo candidato (8–12 referencias, **todas a vetar**)

Mapea a los pilares de seguridad enterprise y al stack que salga de la ontología. **Ninguna está
adoptada** — son candidatas que aún deben pasar el §2:

| # | Dominio | Referencia candidata (de la cantera) | Aporta al gate de… |
|---|---------|--------------------------------------|--------------------|
| 1 | **SAST / code scanning** | `implementing-github-advanced-security-for-code-scanning` (CodeQL/SAST) | **build** (núcleo — código recién generado) |
| 2 | **SBOM / SCA** | `analyzing-sbom-for-supply-chain-vulnerabilities` (deps + CVE) | **build** (refuerza el `npm audit` manual de `el-guardian`) |
| 3 | **IaC** | `auditing-terraform-infrastructure-for-security` | **build** (si Forge genera infra) |
| 4 | **IAM / cloud** | `auditing-aws-s3-bucket-permissions` / `auditing-gcp-iam-permissions` / `auditing-azure-active-directory-configuration` | **blueprint** (según el cloud de la ontología) |
| 5 | **K8s RBAC** | `auditing-kubernetes-cluster-rbac` / `benchmarking-kubernetes-with-kube-bench` | **blueprint/build** (solo si el stack incluye K8s) |
| 6 | **Compliance & Governance** | `achieving-cmmc-level-2-compliance` + set Compliance (9) | **spec** (sectores regulados) |
| 7 | **Zero Trust** | set Zero Trust Architecture (17) | **blueprint** (diseño IAM) |
| 8 | **API Security** | `analyzing-api-gateway-access-logs` + set API Security (28) | **blueprint/build** (productos con API expuesta) |

**EXCLUIDAS por política (ofensivas / dual-use peligrosas):** todo `attacking-*`, `performing-*` de
explotación, Red Teaming (33), Pentesting (21), C2, y simulación de phishing. Forge Enterprise **NO
adopta contenido ofensivo** — el objetivo es **defender el código generado**, no atacar (rechazo
automático en el paso 2).

---

## 4. Frontmatter de framework a AÑADIR a las skills de seguridad de Forge

Para trazabilidad hacia compliance/ontología, las skills/referencias de seguridad de Forge declaran a
qué control responden — copiando el patrón `nist_csf:`/`mitre_attack:` de la cantera. **Campos nuevos a
añadir** (además del frontmatter Forge canónico: `name` + `description` + `tier`):

```yaml
nist_csf: ["PROTECT.PS-6", "DETECT.CM-1"]   # función/categoría NIST CSF 2.0 que el control satisface
owasp: ["A03:2025", "A06:2025"]              # categoría(s) OWASP Top 10 2025 cubiertas
mitre_attack: ["T1195"]                       # técnica(s) MITRE ATT&CK mitigadas (ej. T1195 supply chain)
requisito_ontologico: "requisitos_seguridad[n]"  # ← el diferenciador: qué requisito de ONTOLOGY.md justifica este control
vetting:
  source_repo: "mukul975/Anthropic-Cybersecurity-Skills"
  source_commit: "<hash>"                     # snapshot inmutable adoptado (paso 1)
  vetted_by: "el-evaluador + el-guardian"     # paso 3 + paso 5
  vetted_at: "YYYY-MM-DD"
```

**La cadena de trazabilidad (el argumento de venta enterprise):** un hallazgo de seguridad se traza de
vuelta a *"este control existe porque la ontología de la empresa declaró X"*. El levantamiento
ontológico produce un **perfil de riesgo** (sector, datos, regulación) → ese perfil **selecciona qué
gates se activan y con qué severidad** (como un selector BINARY de Forja) → cada control cita su
`requisito_ontologico`. Convierte el DevSecOps de "checklist genérica" en **"seguridad a la medida de la
ontología de la empresa"**, con reporte **explicable y auditable** para el cliente.

> Cruza `ONTOLOGY.md › requisitos_seguridad` (`{ requisito, origen, severidad }` — ver
> `.claude/references/ONTOLOGY_SCHEMA.md`). Un `requisito_seguridad: critico` no satisfecho es Critical
> en **todos** los gates, aunque el catálogo genérico (threat-db) no lo marque.

---

## 5. Cómo se enchufa a los gates DevSecOps por fase (S1/A3, ya existentes)

Esto **NO** es un import masivo ni un gate nuevo: le da **cantera de contenido vetado** a los gates
shift-left que **ya existen** (`[memory:CONSTRAINTS.md]` § Seguridad shift-left). `el-guardian` ya es
per-phase; el vetting sólo lo abastece:

| Fase SDD | Gate existente (S1/A3) | Qué le aporta una referencia vetada |
|----------|------------------------|-------------------------------------|
| **−1** Ontología / **spec** | `el-ontologo` / `el-entrevistador` (levantan `requisitos_seguridad`) | Compliance & Governance + Zero Trust → threat modeling derivado del perfil de riesgo (NIST CSF **GOVERN/IDENTIFY**) |
| **blueprint** | `la-herreria` asset #9 (threat-db + contrato) | IAM/cloud + Zero Trust → diseño seguro (D3FEND, NIST CSF **PROTECT**) |
| **build** | `el-guardian` (Capas 0–3) + hooks | SAST/CodeQL + SBOM/SCA + IaC → escaneo del código recién generado (OWASP, ATT&CK T1195, NIST CSF **PROTECT/DETECT**) |
| **pre-deploy** | `el-guardian` (Codex, 4 modos + El Infiltrado) | Vuln/Cloud/Container Security según el stack ontológico (D3FEND, NIST CSF **DETECT**) |
| **CI** | `security.yml` + `/verificar-ci` (A2) + AP8 | el mismo escaneo en CI, certificado por runner remoto |

- **Principio:** el catálogo (threat-db) es **genérico**; el contrato (`requisitos_seguridad`) es **propio
  de la empresa**; las referencias vetadas son la **cantera de contenido** que nutre ambos. No reemplazan
  a `el-guardian` — lo evolucionan de gate monolítico a gates por fase con lenguaje de industria.
- **Degradación segura:** sin `ONTOLOGY.md`/`SPEC.md`, los gates operan sólo con el catálogo genérico; sin
  referencias vetadas, los gates siguen funcionando con lo que ya tienen (S1/A3). El vetting **suma**, no
  es precondición.

---

## 6. Refusals (lo que esta política prohíbe)

- ❌ Importar el repo de ~817 skills como dependencia en bloque (`npx skills add …` masivo).
- ❌ Adoptar cualquier skill sin fijar su **commit hash inmutable** (paso 1) — nada apunta a `main` vivo.
- ❌ Adoptar contenido **ofensivo / dual-use** (`attacking-*`, red-team, C2, phishing) — rechazo en paso 2.
- ❌ Adoptar el `SKILL.md` crudo sin reescribirlo al estándar Forge (paso 4).
- ❌ Promover una referencia sin el **gate adversarial** de `el-guardian` (paso 5).
- ❌ Que el mismo agente vetee y genere (AP3 — `el-guardian` + `el-evaluador` firman; no el generador).
- ❌ Confiar en el nombre "Anthropic-" como sello de calidad (es comunidad, no oficial).

---

## 7. El contrato en una frase

Forge **no importa** el repo de cybersec de comunidad: **vetea** un subconjunto de 8–12 referencias
**defensivas** por 5 pasos (procedencia con hash inmutable → filtro defensivo hard → precisión técnica →
reescritura a estándar Forge → gate adversarial de Codex), les añade frontmatter de framework
(`nist_csf`/`owasp`/`mitre_attack`) que las **traza de vuelta a un `requisito_seguridad` de la
ontología**, y las enchufa como **cantera de contenido** a los gates DevSecOps por fase que ya existen —
cero contenido ofensivo, cero import masivo.

## Sources
- `docs/05` §7 — arquitectura de skills + capa DevSecOps; §7.3.3 (subconjunto 8–12), §7.3.4 (cruce ontológico), §7.4 (los 5 pasos), §7.5 (veredicto). [web:github.com](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) (comunidad, Apache-2.0, NO oficial Anthropic).
- `docs/06` §C3 + §9-G (Q22/Q23 — vetting de 5 pasos como requisito antes de adoptar).
- [docs:mitre-attack] — MITRE ATT&CK v19.1 (mapeo de técnicas mitigadas). Validar con `find-docs` antes de estampar controles.
- [docs:nist-csf] — NIST CSF 2.0 (funciones GOVERN/IDENTIFY/PROTECT/DETECT). Validar con `find-docs`.
- `[memory:CONSTRAINTS.md]` § Seguridad shift-left (gates por fase S1/A3) · R14 (destructivos) · AP3 (vetting ≠ generación) · `.claude/references/ONTOLOGY_SCHEMA.md` (`requisitos_seguridad`).
