<!-- Adaptado de SpecFounder (MIT, © Ing. Oscar Lobo) — persistence/templates/spec.template.md -->

# SPEC — <Nombre del Proyecto>

> Especificación neutral de descubrimiento (Fase 0, previa a `/plan`).
> El adaptador "forge" (`references/emit-forge.md`) lo entrega a `/plan` (la-herreria) como spec desambiguado.
> Sigue siendo la fuente de verdad compartida entre el equipo y los agentes.

---

## 1. Visión del Producto
*Qué es, para quién, y qué problema resuelve. En lenguaje no técnico.*

- **En una oración:**
- **Usuario principal:**
- **Problema que resuelve:**

---

## 2. Usuarios y Casos de Uso
*Roles concretos con acciones concretas. Sin perfiles de marketing.*

- **[Rol]:** [acción 1], [acción 2], [acción 3]
- **Acciones solo de admin:**
- **Usuario anónimo (no autenticado):**

---

## 3. Funcionalidades por Módulo
*Comportamiento observable. "El usuario puede…" / "El sistema hace/calcula/envía automáticamente…".*

### Módulo: [nombre]
- El usuario puede…
- El sistema automáticamente…

---

## 4. Flujos de Usuario
*Pasos exactos de cada acción crítica. Happy path + error path.*

### Flujo: [Nombre de la acción]
1. El usuario…
2. El sistema…
3. El usuario…
- **[Error en paso N]:** El sistema muestra…

---

## 5. Arquitectura
*Estructura técnica. Decisiones grandes → ADR.*

- **Plataforma:** (web / móvil / ambos)
- **Backend:** (propio / BaaS / serverless)
- **Stack y restricciones:**
- **Almacenamiento de datos:** (SQL / NoSQL / híbrido)
- **Autenticación:** (propia / OAuth / SAML)
- **Integraciones de terceros:**

---

## 6. Requisitos No Funcionales
*Las restricciones invisibles que destruyen proyectos en producción.*

- **Concurrencia (usuarios simultáneos v1):**
- **Datos sensibles y protección:**
- **Offline / conectividad limitada:**
- **Idiomas / i18n:**
- **SLAs / tiempos de respuesta:**
- **Restricciones de hosting / región:**
