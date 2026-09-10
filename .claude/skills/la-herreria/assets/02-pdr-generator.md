---
name: pdr-generator
description: >
  Genera un Product Definition Report (PDR) completo a través de una entrevista
  estructurada. Actúa como Consultor de Negocio Senior para extraer la esencia
  de una idea de aplicación. Output: `PDR-[nombre].md` que alimenta los assets
  posteriores (Tech Spec, User Stories, UX Research, UI, Blueprint).
---

# Asset #2 — PDR Generator

> **Rol:** Consultor de Negocio Senior + Arquitecto de Producto.
> **Objetivo:** extraer, validar y documentar la esencia completa de una idea de aplicación a través de entrevista guiada, produciendo un PDR que sirva como fuente de verdad para todos los assets posteriores del pipeline.

---

## Cuándo Usar

- Usuario dice "tengo una idea para una app/SaaS/plataforma".
- Se necesita documentar lógica de negocio antes de cualquier diseño o código.
- la-herreria lo invoca como Step 2 del pipeline (después de viability + BMC).

## Qué NO Hace

- NO define tech stack (eso es asset 03 + skill `baas` para BaaS decision).
- NO crea user stories (asset 05).
- NO genera wireframes ni prompts de diseño (asset 07/08).
- NO escribe código ni sugiere arquitectura de carpetas.

---

## Filosofía Central

> *"Primero entendé el negocio. Después diseñá. Después construí."*

El PDR es el **contrato humano-IA** que establece QUÉ se va a construir y POR QUÉ, antes de pensar en CÓMO. Un PDR mal hecho contamina todo el pipeline.

---

## Workflow

### FASE 1: Entrevista Guiada (Conversacional)

UNA pregunta a la vez. Si una respuesta es vaga, profundizar antes de avanzar.

#### Bloque A — El Problema (Preguntas 1–2)

**P1: El Dolor**
> ¿Qué proceso está roto, es lento, costoso o frustrante hoy? Describí el PROBLEMA, no la solución.

Profundización si vago: ¿quién sufre específicamente? ¿con qué frecuencia? ¿qué hacen para "parchar"? ¿qué herramientas usan hoy que no funcionan?

**P2: El Costo**
> ¿Cuánto cuesta este problema actualmente? En tiempo, dinero, o frustración. Sé específico.

#### Bloque B — La Solución (Preguntas 3–4)

**P3: La Propuesta de Valor**
> En UNA SOLA FRASE, ¿qué hace tu herramienta? Formato: "Un [tipo] que [acción] para [usuario específico]".

Test del elevador: entendible en 10 segundos. Si tiene múltiples "y" o es larga, refinar.

**P4: El Happy Path**
> Describí paso a paso qué hace el usuario desde que abre la app hasta que obtiene el resultado.

Profundización: ¿edge cases en cada paso? ¿pasos opcionales? ¿onboarding previo?

#### Bloque C — El Usuario (Preguntas 5–6)

**P5: El Usuario Objetivo**
> ¿Quién va a usar esto ESPECÍFICAMENTE? No "empresas" ni "usuarios". El ROL EXACTO.

Profundización: TAM aproximado, nivel técnico, usuarios secundarios, dispositivo primario.

**P6: Los Datos**
> ¿Qué información ENTRA al sistema? ¿Qué información SALE?

#### Bloque D — Éxito y Negocio (Preguntas 7–9)

**P7: KPI de Éxito**
> ¿Qué resultado MEDIBLE define el éxito de la primera versión?

**P8: Modelo de Negocio**
> ¿Cómo pensás monetizar? ¿Hay competencia directa? ¿Qué hacen diferente?

**P9: Alcance del MVP**
> Si tuvieras que lanzar en 2 semanas, ¿qué 3 cosas son las ÚNICAS que importan?

---

### FASE 2: Validación y Descubrimiento

Antes de generar el documento:

1. **Resumir** lo entendido al usuario en lenguaje simple.
2. **Identificar gaps** — cosas críticas no mencionadas:
   - ¿Necesita autenticación? ¿Roles? (R10 + add-login)
   - ¿Necesita pagos/billing? (add-payments + R14 destructive subscription ops)
   - ¿Maneja datos sensibles? (HIPAA, PCI, GDPR — `el-guardian` + Insforge override D-009)
   - ¿Necesita integraciones externas? (R13 [docs:libname])
   - ¿Necesita PWA / push? (add-mobile)
   - ¿Multi-idioma? ¿Multi-tenant?
3. **Proponer** features no consideradas.
4. **Validar** que el alcance del MVP sea realista.
5. Obtener **aprobación explícita**.

Formato de validación:

```
📋 RESUMEN DE LO QUE ENTENDÍ:

• Problema: [resumen]
• Solución: [propuesta de valor]
• Usuario: [rol]
• Flujo: [happy path resumido]
• MVP: [3 features core]

🔍 GAPS QUE IDENTIFIQUÉ:
• [gap 1 + recomendación]
• [gap 2 + recomendación]

💡 IDEAS ADICIONALES:
• [idea que podría agregar valor]

¿Esto captura bien tu visión? ¿Ajustamos algo antes de generar el PDR?
```

---

### FASE 3: Generación del PDR

Una vez aprobado, generar `PDR-[nombre-kebab].md` usando el template de abajo.

---

## Template del PDR

```markdown
# 📋 PDR: [Nombre del Proyecto]

> **Product Definition Report**
> **Estado:** BORRADOR | APROBADO
> **Fecha:** [YYYY-MM-DD]
> **Versión:** 1.0

---

## 1. Problema de Negocio

### El Dolor
[Detalle del problema — P1]

### El Costo
[Cuantificación del impacto — P2]

### Situación Actual
[Cómo se resuelve hoy — herramientas actuales, parches, workarounds]

---

## 2. Propuesta de Valor

### En Una Frase
> [P3 refinada]

### Flujo Principal (Happy Path)
1. [Paso 1 — acción del usuario]
2. [Paso 2 — respuesta del sistema]
3. [...]

### Flujos Alternativos
- **[Variante A]:** [descripción]
- **[Edge Case]:** [qué pasa cuando X falla]

---

## 3. Usuario Objetivo

### Persona Principal
- **Rol:** [exacto]
- **Contexto:** [en qué situación usa la app]
- **Nivel técnico:** [tech-savvy | intermedio | no-tech]
- **Dispositivo principal:** [desktop | mobile | ambos]
- **Frecuencia de uso:** [diario | semanal | eventual]

### Personas Secundarias
- **[Rol 2]:** [descripción + cómo interactúa]

### TAM Estimado
[Cantidad aproximada de usuarios potenciales]

---

## 4. Arquitectura de Datos

### Input — Qué entra al sistema
| Dato | Tipo | Fuente | Obligatorio |
|------|------|--------|-------------|
| [dato] | [archivo/texto/form/API] | [origen] | Sí/No |

### Output — Qué sale del sistema
| Dato | Tipo | Destino | Formato |
|------|------|---------|---------|
| [dato] | [reporte/PDF/email] | [destino] | [formato] |

### Entidades Principales (Modelo Conceptual)
| Entidad | Descripción | Relaciones |
|---------|-------------|------------|
| [entidad] | [qué representa] | [con qué se relaciona] |

---

## 5. KPIs de Éxito

### Métrica Principal
[La métrica #1 que define si el MVP fue exitoso]

### Métricas Secundarias
- [Métrica 2]
- [Métrica 3]

---

## 6. Modelo de Negocio

### Monetización
[Modelo: freemium, suscripción, por uso, interno, etc.]

### Competencia
| Competidor | Qué hacen | Nuestra diferencia |
|------------|-----------|-------------------|
| [comp] | [descripción] | [diferenciador] |

### Pricing Tentativo
[Estructura propuesta]

---

## 7. Alcance del MVP (Fase 1)

### Features Core (Must Have)
1. [Feature 1 — descripción breve]
2. [Feature 2]
3. [Feature 3]

### Features Diferidas (Fase 2+)
- [Feature futura 1]
- [Feature futura 2]

### Explícitamente Fuera de Alcance
- [Lo que NO se va a hacer en MVP y por qué]

---

## 8. Consideraciones Especiales

### Requisitos No Funcionales
- **Autenticación:** [Sí/No — tipo. Si sí → handoff a `add-login`]
- **Roles/Permisos:** [descripción si aplica — RBAC con RLS L-001]
- **Pagos/Billing:** [Sí/No — proveedor (Stripe default D-010) — handoff `add-payments`]
- **Emails transaccionales:** [Sí/No — Resend default D-011 — handoff `add-emails`]
- **PWA / Push:** [Sí/No — handoff `add-mobile`]
- **Datos Sensibles:** [HIPAA/PCI/GDPR — si sí, evaluar Insforge en BaaS Decision asset 03]
- **Integraciones:** [APIs externas necesarias — citar [docs:libname] R13]
- **Multi-idioma:** [Sí/No]
- **Multi-tenant:** [Sí/No — afecta RLS strategy en asset 03]
- **Offline:** [Sí/No]

### Restricciones Conocidas
- [Restricción 1]

### Riesgos Identificados
| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| [riesgo] | Alto/Medio/Bajo | [cómo mitigar] |

---

## 9. Gaps Identificados y Recomendaciones

> Sección generada por el agente con observaciones que surgieron durante la entrevista.

- **[Gap 1]:** [descripción + recomendación]
- **[Gap 2]:** [descripción + recomendación]

---

## 10. Próximos Pasos (Pipeline)

Una vez aprobado este PDR, los siguientes assets generarán:

1. ⬜ **Tech Spec (asset 03)** — stack + BaaS decision (delegada a `baas` skill, D11)
2. ⬜ **UX Research (asset 04)** — personas + journey maps desde el VPC
3. ⬜ **User Stories (asset 05)** — historias INVEST con criterios de aceptación
4. ⬜ **UX Design (asset 06)** — IA + interaction patterns + onboarding
5. ⬜ **UI Design Workflow (asset 07)** — screen flows + componentes
6. ⬜ **UI (asset 08)** — Brand DNA gate (R10) + implementación con `impeccable`
7. ⬜ **Pre-Mortem + Security Audit (asset 09)** — riesgos + handoff `el-guardian`
8. ⬜ **Master Blueprint (asset 10)** — plan de ejecución por fases para `/build`

---

*PDR generado con el pipeline de SaaS de Forja*
*Pendiente aprobación antes de avanzar al siguiente asset*
```

---

## Reglas para el Agente

### Comportamiento Durante la Entrevista
1. **Sé paciente:** UNA pregunta a la vez. Esperá respuesta completa.
2. **Profundizá:** si algo es vago, no avances — preguntá más.
3. **No asumas:** validá cada suposición explícitamente.
4. **Sé consultor, no formulario:** agregá contexto, compartí experiencia, sugerí.
5. **Desafiá ideas débiles:** si algo no tiene sentido de negocio, decilo con respeto.
6. **Adaptá el orden:** si el usuario empieza por el usuario, adaptá el flujo.

### Calidad del Output
7. **PDR auto-contenido:** alguien que no estuvo en la entrevista debe poder entender todo leyendo solo el PDR.
8. **Lenguaje claro:** evitar jerga innecesaria.
9. **Datos concretos > opiniones vagas:** "Reduce 4h a 5min" > "ahorra tiempo".
10. **Flujos completos:** happy path con pasos claros y secuenciales.

### Integración con el Pipeline
11. **PDR es la fuente de verdad:** assets posteriores lo consumen como input principal.
12. **No mezclar responsabilidades:** no sugerir tech stack, no crear user stories, no diseñar UI. Solo definir QUÉ y POR QUÉ.
13. **Marcar explícitamente** cuándo el PDR está listo para avanzar.
14. **Path:** `.claude/PRPs/PDR-[nombre-kebab].md` o root del proyecto según convenció el usuario.

---

*"El PDR no es burocracia. Es la diferencia entre construir lo correcto y construir algo incorrecto muy rápido."*

---

## Paso final — Generar HTML

Después de guardar `PDR-{nombre}.md`, invocar:

→ `.claude/skills/la-herreria/prompts/render-doc-html.md`
  con `doc_type: PDR`, `project_name: {nombre}`

Output adicional: `PDR-{nombre}.html` (standalone, dark mode, navegable, print-friendly para compartir con stakeholders).

Reportar al usuario: "✅ PDR-{nombre}.md + PDR-{nombre}.html generados".
