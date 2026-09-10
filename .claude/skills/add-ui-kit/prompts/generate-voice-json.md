# generate-voice-json — Discovery output → brand/voice.json

> Operational prompt. Toma el `discovery_output.voice` y rellena `templates/voice.json.template` para producir `brand/voice.json`.
>
> **Source schema:** [memory:references#R-005] sección 9.2.
> **Template:** `templates/voice.json.template`.

---

## Input esperado

```yaml
discovery_output.voice:
  tone_axes: { directness, warmth, technicality, provocation, hype }
  principles: ["1-line statement", ...]
  vibe: "..."
  safe_words: ["..."]
  avoid_words: ["..."]            # adiciones project-specific (NO incluye baseline Forja)
  cta_style: "Directo, no pushy"
  hooks: ["..."]                   # opcional
  cta_examples: ["..."]            # opcional
  code_switching: { allowed, rule } # opcional
  sentence_rules: { prefer, avoid } # opcional
discovery_output.brand:
  name, product, audience            # para campos default-derivados
discovery_output.archetype:
  primary, secondary                 # para coherence-check
```

## Output esperado

`brand/voice.json` parseable.

---

## Procedimiento (5 pasos)

### Paso 1 — Cargar template

```
1. Read .claude/skills/add-ui-kit/templates/voice.json.template
2. Read .claude/skills/add-ui-kit/references/examples.md (shape reference; sección voice.json de Forge / Glow / Loop)
```

### Paso 2 — Resolver defaults derivados

| Campo | Default si Discovery no proveyó |
|-------|----------------------------------|
| `voice.name` | `discovery_output.brand.product` |
| `voice.language` | inferir del audience: si `LATAM` o `es-419` keyword → "es-419"; si `Spain` o `es-ES` → "es-ES"; default "en-US" |
| `voice.language_rules` | computar según `language`: si `"es-419"` → `["Español neutro de Latinoamérica con tú — NUNCA voseo argentino (vos/tenés/reservá/querés)", "Imperativos en tú: Reserva, Empieza, Aplica (no reservá, empezá, aplicá)", "Pronombres: tú, tu, te, ti (no vos, che)", "Anglicismos técnicos del sector OK: SaaS, deploy, repo, dashboard, MVP"]`. Si `"es-ES"` → `["Español de España con tú — tuteo estándar peninsular", "Imperativos en tú: Reserva, Empieza, Aplica", "Evitar vosotros en copy digital LATAM-facing"]`. Si `"en-US"` → omitir campo (emitir `[]`). |
| `voice.audience` | `discovery_output.brand.audience.join(' + ')` |
| `voice.code_switching` | si language="es-419" o "es-ES" → poblar default Forja con allowed=["Claude Code", "MCP", "ship", "deploy", "prompt"]. Si "en-US" → omitir. |
| `voice.hooks` | si Discovery no proveyó → emitir array vacío. NO inventar hooks. |
| `voice.cta_examples` | similar — si Discovery no proveyó → array vacío. NO inventar. |
| `voice.pacing` | defaults: 165 words_per_minute + 400 ms pause_after_hook. |

### Paso 3 — Mergear avoid_words

El template tiene 23 baseline avoid_words hardcoded (R-005 9.2 canon). El Discovery `voice.avoid_words` contiene **solo project-specific additions**:

```
final_avoid_words = baseline_23 ∪ discovery.avoid_words
```

Validar que no haya duplicados (case-insensitive). Si Discovery duplicó una palabra del baseline, omitir el duplicado y registrar warning.

#### Pronoun consistency check (solo si `language` = `"es-419"` o `"es-ES"`)

Revisar los campos de texto libre generados (`vibe`, `principles[*]`, `cta_style`, `sentence_rules.*`) por formas de **voseo argentino**:

```
hablás, tenés, querés, podés, hacés, empezás, reservás, aplicás,
estás, sos, vos, tené, empezá, reservá, aplicá, hacé
```

Por cada ocurrencia encontrada → corregir a forma **tú** antes de escribir:

| Voseo | Tú |
|-------|----|
| hablás | hablas |
| tenés | tienes |
| querés | quieres |
| podés | puedes |
| hacés | haces |
| empezás | empiezas |
| reservás | reservas |
| aplicás | aplicas |
| sos | eres |
| vos | tú |
| hablá | habla |
| empezá | empieza |
| reservá | reserva |
| aplicá | aplica |
| hacé | haz |

Si `voice.language = "es-419"`: imperativos siempre en tú (`Reserva`, `Empieza`, `Aplica` — **nunca** `Reservá`, `Empezá`, `Aplicá`). Registrar cuántas correcciones se aplicaron en `$generated_warnings`.

### Paso 4 — Coherence check vs archetype

Validar que voice.tone_axes sea coherente con archetype.primary (lookup en `references/archetypes-mark-pearson.md`):

| archetype.primary | Expected ranges | Si fuera → action |
|-------------------|-----------------|-------------------|
| Innocent | warmth ≥ 4, hype ≤ 2 | warn |
| Sage | technicality ≥ 3, hype ≤ 1 | warn |
| Explorer | warmth 3-4, provocation 2-3 | warn |
| Outlaw | provocation ≥ 4, directness ≥ 4 | halt + ask |
| Magician | hype ≥ 2 | warn |
| Hero | hype 2-4 | warn |
| Lover | warmth 4-5, provocation ≤ 2 | warn |
| Jester | warmth 4-5, hype 3-4 | warn |
| Everyman | warmth 3-4, technicality ≤ 2, hype ≤ 1 | warn |
| Caregiver | warmth ≥ 4, hype ≤ 1, provocation ≤ 2 | halt + ask |
| Ruler | warmth ≤ 2, technicality ≥ 3 | warn |
| Creator | technicality ≥ 3, hype ≤ 2 | warn |

Halt cases (Outlaw + low provocation; Caregiver + low warmth) reportan al usuario:

```
⚠️ Voice tone axes inconsistentes con archetype.primary = <X>:
   - <axis>: declarado <N>, esperado ≥ <M> (R-005 archetype <X>)

¿Reabrimos bloque (d) Voice axes o el bloque (b) Archetype?
```

Warn cases avanzan con un comentario en `$generated_warnings`.

### Paso 5 — Render template + write

1. Procesar template con todos los campos.
2. Validar JSON parseable.
3. Validar schema R-005 9.2:
   - `tone_axes.*` ∈ [1, 5]
   - `principles` length ≤ 5
   - `safe_words` length ≤ 20
   - `avoid_words` length ≤ 50
4. Write `brand/voice.json`.
5. Reportar al orchestrator: LOC + warnings + Coherence check result.

---

## Casos edge

### Discovery sin language declarado

Si la audiencia es ambigua (mix LATAM + España + US), preguntar UNA vez:
> "El voice.language define el spelling y vocabulario default. Tu audiencia es global — ¿prefiero `es-419` (LATAM neutral) o `es-ES` (España) o `en-US`?"

Sin respuesta → default `es-419`.

### Hooks vacíos en MVP

Es válido emitir `voice.hooks: []`. La marca puede no tener hooks definidos al inicio. Registrar warning sugiriendo iterar después de tener tagline + positioning estables.

### Tono que cruza contextos

Si Discovery declaró:
- `cta_style: "Imperativo confrontativo"` (Outlaw)
- pero `voice.tone_axes.warmth: 4` (Caregiver)

Esta es una contradicción potencial — cross-check con archetype:
- Si primary=Outlaw → warmth alto es shadow risk pero permitido
- Si primary=Caregiver → CTA imperativo confrontativo viola contrato

Tratar como halt + ask, no warn.

---

## Refusals

- ❌ Inventar `voice.hooks` o `voice.cta_examples` que el usuario no proveyó.
- ❌ Remover palabras del baseline avoid_words (los 23 son canon Forja, no opcionales).
- ❌ Escribir voice.json si la coherence check halt-level no se resuelve.
- ❌ Sobrescribir `brand/voice.json` existente sin que el orchestrator confirme.

---

## Citations en el output

```json
{
  "$schema_source": "[memory:references#R-005] sección 9.2",
  "$generated_by": "add-ui-kit (FRESH mode)",
  "$generated_at": "2026-05-07T22:30:00Z"
}
```

---

*"Voice tone debe ser coherente con archetype. Si no lo es, no avanza."*
