<!-- Adaptador de emisión "forge". Concepto de emisión portado de SpecFounder v2
     (methodologies/, MIT © Ing. Oscar Lobo); el mapeo a la-herreria es propio de Forge Enterprise. -->

# Adaptador de emisión "forge" — SPEC → /plan (la-herreria)

> El cuarto "methodology" de SpecFounder, hecho a la medida de Forge. En vez de compilar a
> OpenSpec o Spec-Kit, **cierra el handoff dentro de la familia Forge**: entrega el SPEC neutral
> desambiguado a `la-herreria` (`/plan`), que ya sabe consumir "trabajo previo" (su Detección de
> estado **modo B**). Decisión de arranque de Forge Enterprise (06 §6.5 · §9-F #19/#20).

## Precondición

No emitir hasta que: las **6 secciones** estén `completa` en `session.md` **y** no queden
**ramas abiertas**. Si falta algo, volver a `entrevista`. (El usuario puede forzar una emisión
parcial explícitamente; en ese caso, marcar las secciones incompletas en el handoff como
`[pendiente — la-herreria debe levantarla]`.)

## Paso 1 — Emitir artefactos finales (versionados)

Copiar el contenido de los drafts de `.specfounder/` a la **raíz del proyecto**, como artefactos
versionados (los drafts y `session.md` quedan gitignored; estos NO):

| Draft (`.specfounder/`) | Artefacto final (raíz, versionado) |
|---|---|
| `SPEC.draft.md` | `SPEC.md` |
| `CONTEXT.draft.md` | `CONTEXT.md` |
| `adr/NNNN-*.md` | `docs/adr/NNNN-*.md` |

Marcar `phase: emitido` en `session.md`.

## Paso 2 — Mapeo SPEC → pipeline de la-herreria

`la-herreria` corre Mode Selector + 10 fases (Viability → BMC/VPC → PDR → Tech Spec → UX Research
→ User Stories → UX Design → UI Design Workflow → UI → Security Audit → Master Blueprint). El SPEC
**precarga** estas fases; la-herreria **profundiza donde el SPEC es delgado, no re-descubre lo que
el SPEC ya fijó**:

| Sección del SPEC | Precarga las fases de la-herreria | la-herreria aún profundiza |
|---|---|---|
| **§1 Visión** (oración · usuario · problema) | 0 Viability · 1 BMC/VPC · 2 PDR | modelo de negocio (BMC/VPC), monetización |
| **§2 Usuarios y Casos** | 2 PDR · 5 User Stories | personas (4 UX Research) a partir de los roles |
| **§3 Funcionalidades por Módulo** | 2 PDR (alcance) · 5 User Stories | criterios de aceptación por story |
| **§4 Flujos (happy/error)** | 5 User Stories · 6 UX Design · 7 Screen Flows | wireframes/IA detallada |
| **§5 Arquitectura** + **ADRs** | 3 Tech Spec (stack, backend, storage, auth, integraciones; BaaS decision) | detalle técnico; ADRs = **decisiones fijas, no re-decidir** |
| **§6 No-Funcionales** | 3 Tech Spec (NFR) · 9 Security Audit | ejecución de la auditoría (`el-guardian` opcional) |
| **`CONTEXT.md`** (glosario del cliente) | TODAS las fases | vocabulario canónico: **los únicos términos válidos** |

**NO viene del SPEC** (la-herreria lo genera igual): Brand DNA / UI visual (8, vía `add-ui-kit`,
R10) y el Master Blueprint (10, síntesis final). El SPEC es el "qué/quién/flujos/restricciones";
la capa visual y el blueprint ejecutable los produce la-herreria.

## Paso 3 — Bloque de handoff (lo que se le dice a la-herreria / al usuario)

Al cerrar, emitir este handoff y sugerir `/plan`:

```
✅ SPEC emitido → SPEC.md · CONTEXT.md · docs/adr/

→ /plan (la-herreria) consume este SPEC como TRABAJO PREVIO (Detección de estado, modo B):

  1. Trata SPEC.md como fuente de verdad del QUÉ/QUIÉN/FLUJOS/RESTRICCIONES.
     Mapea sus 6 secciones al pipeline (tabla arriba) y arranca desde la fase
     pendiente más temprana; NO re-preguntes lo que el SPEC ya fijó (Regla de
     contexto 1: "no repetir preguntas").
  2. CONTEXT.md es el glosario canónico: sus términos son los ÚNICOS válidos.
     Si una fase necesita un término nuevo, se añade al glosario, no se inventa
     un sinónimo (Regla 4: "nunca inventar"; Regla 2: "no contradecir").
  3. Los ADRs de docs/adr/ son decisiones FIJAS. Una fase no las re-decide; si
     necesita desviarse, lo marca como propuesta de `superseded by` para revisión.
  4. La §6 (No-Funcionales) alimenta Tech Spec (NFR) y Security Audit. Hallazgos
     críticos bloquean el Blueprint (Regla 5), igual que hoy.
  5. Profundiza donde el SPEC es delgado (BMC, personas, UI/Brand DNA); no donde
     ya es explícito.
```

## Reglas del adaptador

- **Determinista y casi sin juicio.** Este paso rellena artefactos y produce el handoff; no
  reabre decisiones de la entrevista (esas ya están en el SPEC/ADRs).
- **Un solo destino: `forge`.** Los otros emisores de SpecFounder (OpenSpec, Spec-Kit,
  creative-bible) NO se portan en este ciclo (M4). Si un cliente enterprise exige OpenSpec/Spec-Kit
  como entregable, es trabajo de la fase de Calidad (S5) — se puede portar el emisor correspondiente
  entonces, sin tocar este adaptador.
- **El SPEC sigue vivo.** Si tras /plan el usuario cambia el dominio/alcance, se vuelve a
  `el-entrevistador` (re-spec-parcial), se re-emite, y la-herreria propaga (Regla de contexto 3).
