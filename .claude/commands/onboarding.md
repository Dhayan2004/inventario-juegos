---
description: "Punto de entrada para usuarios nuevos. Detecta si el proyecto está inicializado y guía al primer paso correcto: diagnóstico, planificación o retomar trabajo existente."
---

# /onboarding — Bienvenido a Forja

Detecta el estado del proyecto y guía al siguiente paso correcto.

## Detección de estado

Verificar en orden:

1. **¿Existe `AGENTS.md`?**
   - **NO** → proyecto Forja no inicializado.
     Preguntar: *"¿Copiaste la carpeta `` a tu proyecto? Si no, ejecuta el alias `forge` primero."*
     **Detener.**

2. **¿Existe `feature_list.json`?**
   - **NO** → proyecto fresh sin features definidas.
     Decir: *"Proyecto nuevo detectado. Corré `/forge-check` para validar el entorno, luego `/plan` para definir qué construir."*
     **Detener.**

3. **¿Hay features en `feature_list.json`?**
   - Si tiene features en `state: passing` o `active` → proyecto en curso.
     Decir: *"Proyecto en curso detectado. Corré `/avivar` para retomar el contexto de la última sesión."*
     **Detener.**
   - Si `feature_list.json` existe pero está vacío o solo tiene ejemplos →
     Decir: *"Entorno listo. Corré `/plan` para empezar a planificar."*
     **Detener.**

## Si llega hasta acá sin detenerse

Decir:

```
¡Bienvenido a Forja!

Detecté que el entorno está configurado pero no hay proyecto activo.

Opciones:
  /forge-check  → Diagnosticar el entorno antes de empezar
  /plan         → Planificar desde cero (La Herrería te guía)
  /avivar       → Retomar trabajo de una sesión anterior

¿Por dónde empezamos?
```
