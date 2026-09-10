# Comunicación con el humano — Cierre Ejecutivo y Decisión Guiada

> **Qué es esto.** La doctrina de **cómo el harness le habla al humano**. Recupera el registro
> Forge-Pro (resumen + guía de decisión) que se perdió al crecer la capa enterprise: el output se
> volvió técnico justo cuando entran **más colaboradores no técnicos** (feedback dogfooding
> 2026-08-18, punto 6). Regla de oro: **negocio primero, técnica bajo demanda** — el mismo principio
> de dos capas de la Guía del Socio (`tools/guia`).
>
> **Frontera:** esta doctrina gobierna la comunicación **harness → humano** (cierres de sesión,
> reportes, handoffs). NO gobierna el copy de las apps generadas — eso es territorio de `voice.json`
> (R10, Brand DNA) y no se toca.

- **Versión:** v0.1.0 (2026-08-18)
- **Consumidores:** todo skill coordinador que cierra una fase o produce un reporte — `la-herreria`,
  `el-crisol`, `el-guardian`, `project-auditor` (/temple), `el-capataz`, `el-cartografo`,
  `verificar-ci`, `el-pulidor`, `el-entrevistador`, `el-ontologo`.
- **No añade regla R-NNN:** es doctrina de output, enforced por rúbrica (`el-evaluador` § Ejes de
  Calidad) y por los templates de cierre de cada skill.

---

## 1. El Cierre Ejecutivo (obligatorio en toda salida mayor)

Toda salida mayor — cierre de fase, reporte de auditoría, fin de sesión de build, handoff — termina
con este bloque, **en este orden**:

```
─────────────────────────────────────
📋 EN CORTO
   2-4 frases en lenguaje de negocio. Qué pasó y qué significa para el
   proyecto. Cero jerga: nada de "RLS", "hook", "fork" sin traducir.

✅ QUEDÓ HECHO
   • lista corta, verificable, en términos de lo prometido al cliente

⚠️ OJO
   • riesgos, pendientes o supuestos que el humano debe conocer
   • si no hay: "Nada que te bloquee."

👉 TU DECISIÓN
   El siguiente paso como decisión guiada (ver §2), o "Nada que decidir —
   sigo con X" si no hay bifurcación.
─────────────────────────────────────
```

- **Longitud:** el bloque completo cabe en una pantalla. El detalle técnico va ANTES del cierre (el
  que quiere profundidad la tiene arriba), o disponible con "¿te muestro el detalle técnico?".
- **Traducción obligatoria:** cada término técnico inevitable lleva su consecuencia de negocio en la
  misma frase ("el CI está rojo → no se puede publicar todavía").
- **Los números citan su fuente** (score, tests, CI run) — la doctrina de `verificar-ci` aplica
  también a la prosa: no se afirma lo que no se puede citar.

## 2. Decisión Guiada (nunca pregunta abierta)

Cuando el humano tiene que decidir, **nunca** se le pregunta "¿qué quieres hacer?". Se presenta:

1. **2-3 opciones máximo**, cada una con su consecuencia en una línea.
2. **Una recomendación marcada** (⭐) con el porqué en una frase — el patrón grill-me de
   `el-entrevistador` (recomendación obligatoria), generalizado a todo el harness.
3. **El default si no contesta**: qué va a pasar (o qué queda detenido) si no decide ahora.

```
👉 TU DECISIÓN — ¿publicamos con el aviso legal pendiente?
   A) ⭐ Publicar ya y agregar el aviso esta semana — sales hoy; riesgo bajo y acotado.
   B) Esperar el aviso — sales en ~3 días, sin ningún riesgo.
   Si no decides: queda detenido en staging (no publica solo).
```

## 3. Dos capas, siempre en este orden

| Capa | Para quién | Dónde va |
|------|-----------|----------|
| **Negocio** (qué significa, qué sigue, qué decides) | Carlos + colaboradores + cliente | Primero — y SIEMPRE presente |
| **Técnica** (comandos, archivos, hallazgos crudos) | quien opera el harness | Antes del cierre, o bajo demanda |

Un reporte que solo tiene capa técnica está **incompleto** aunque sea correcto. El Audit Score, el
Build Confidence y los veredictos Go/Caution/No-Go ya siguen este patrón — esta doctrina lo vuelve
el estándar de TODA salida mayor, no solo de los dashboards.

## 4. Anti-patrones

- ❌ Cerrar una sesión con un dump de archivos tocados y ningún "qué significa".
- ❌ Pregunta abierta sin opciones ni recomendación.
- ❌ Jerga sin consecuencia ("falta el WITH CHECK" → ✅ "un usuario podría darse permisos que no le
  tocan; lo cierro antes de publicar").
- ❌ Enterrar la única decisión importante en el párrafo ocho.
- ❌ Prometer sin citar ("los tests pasan" sin el resultado real — AP5).

## Sources
- Feedback dogfooding 2026-08-18 (punto 6) — regresar al output nivel Forge-Pro.
- `tools/guia` (Guía del Socio) — el patrón de dos capas ya validado con no-técnicos.
- `el-entrevistador` grill-me — recomendación obligatoria por pregunta.
