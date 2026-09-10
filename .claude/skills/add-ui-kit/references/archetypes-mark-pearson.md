# 12 Archetypes (Mark + Pearson) — UI & Copy Translation

> Lookup table consumida por `prompts/discovery-fresh.md` bloque (b) y `prompts/generate-brand-json.md`.
>
> **Source:** Mark & Pearson, *The Hero and the Outlaw* (2001) — adaptado para UI/copy generation.
> **Schema reference:** [memory:references#R-005] sección 2.
>
> Los 12 archetypes son vocabulario operativo: cada uno tiene una traducción concreta a UI rules + copy rules + allowed/forbidden behaviors. **NO se usan como etiqueta abstracta** — siempre con consecuencias.

---

## Cómo el agente usa esta tabla

1. Discovery captura `primary` + `secondary` + `shadow_to_avoid` por nombre.
2. `generate-brand-json.md` lookea cada uno acá y pega `ui_translation` + `copy_translation` + `allowed_behaviors` + `forbidden_behaviors` en el JSON output.
3. `el-evaluador` valida que component_rules + voice rules sean coherentes con el archetype declarado.

---

## Tabla maestra (12 archetypes)

### 1. Innocent

> *"Todo va a estar bien."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | felicidad, simplicidad, optimismo |
| Tagline mood | aspiracional, claro, sin pretensión |
| UI translation | colores claros, generosa whitespace, geometría suave, ilustraciones amistosas |
| Copy translation | frases cortas, tono cálido sin ser hype, beneficio directo |
| Posture defaults | density 1-2, expression 2-3, geometry 1-2, warmth 4-5, editoriality 1-2, materiality 1-2 |
| Voice defaults | directness 3, warmth 5, technicality 1-2, provocation 1, hype 1 |
| Allowed behaviors | usar metáforas de naturaleza/luz, color saturado pero claro, ilustración amable |
| Forbidden behaviors | sarcasmo, humor cínico, oscuridad, urgencia agresiva |
| Shadow risk | naive, infantil, irrelevante para audiencias técnicas |
| Brand examples | Coca-Cola, Dove, Method, Tyson Bedford |

### 2. Sage

> *"La verdad te hace libre."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | comprensión, conocimiento, sabiduría |
| Tagline mood | preciso, sereno, autoritativo sin condescender |
| UI translation | tipografía editorial cuidada, jerarquía clara, neutros sobrios, datos como protagonistas |
| Copy translation | claridad sobre persuasión, citas/referencias visibles, evitar superlativos vacíos |
| Posture defaults | density 3, expression 2, geometry 3, warmth 2-3, editoriality 4, materiality 1-2 |
| Voice defaults | directness 4, warmth 2-3, technicality 4, provocation 2, hype 1 |
| Allowed behaviors | citar fuentes, mostrar datos crudos, usar tipografía serif para autoridad |
| Forbidden behaviors | hype, urgencia falsa, "AI magic", testimoniales sin contexto |
| Shadow risk | académico, pedante, distante |
| Brand examples | The Economist, NYT, MIT, Bloomberg, Stripe (sage-tinted) |

### 3. Explorer

> *"No me pongas cajas."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | libertad, autenticidad, descubrimiento |
| Tagline mood | invitación al viaje, "ven a descubrir" |
| UI translation | layouts no-grid estrictos, fotografía outdoor / wide, paletas tierra + tonos cielo |
| Copy translation | imperativos suaves ("explorá", "salí"), descripciones de lugares/territorios |
| Posture defaults | density 2, expression 3, geometry 2-3, warmth 3-4, editoriality 3-4, materiality 2-3 |
| Voice defaults | directness 4, warmth 3, technicality 2, provocation 2, hype 2 |
| Allowed behaviors | imágenes de viaje/territorio, mapas, copy de "primera vez", fonts inspiradas en cartografía |
| Forbidden behaviors | corporate sterility, oficina-foto-stock, urgencia urbana |
| Shadow risk | irresponsable, sin foco, "wanderlust" superficial |
| Brand examples | Patagonia, Jeep, REI, AllTrails, Airbnb |

### 4. Outlaw

> *"Las reglas son para romper."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | revolución, liberación, ruptura |
| Tagline mood | confrontativo, manifiesto, anti-status-quo |
| UI translation | contraste alto, layouts asimétricos puntuales, color usado con violencia controlada, tipografía con peso |
| Copy translation | imperativos cortos, lenguaje directo, callouts vs status quo |
| Posture defaults | density 3, expression 4-5, geometry 4-5, warmth 1-2, editoriality 3-4, materiality 2-3 |
| Voice defaults | directness 5, warmth 2, technicality 3, provocation 5, hype 2 |
| Allowed behaviors | romper simetría, usar headlines confrontativos, color signature alto-contraste, manifiestos |
| Forbidden behaviors | caos visual gratuito, ironía adolescente, sacrificar accesibilidad por estética edgy |
| Shadow risk | nihilismo, edginess sin propósito, alienar a la audiencia |
| Brand examples | Harley-Davidson, MSCHF, Liquid Death, Cards Against Humanity |

### 5. Magician

> *"Hago que pase."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | transformación, visión, impacto |
| Tagline mood | "convertí X en Y", "transforma tu Z" |
| UI translation | gradientes cuidados (NO defaults), motion ceremonial, partículas/glow controlados, dark mode con accents brillantes |
| Copy translation | metáforas de transformación, "antes/después", énfasis en momento revelador |
| Posture defaults | density 2-3, expression 4, geometry 3, warmth 3, editoriality 3-4, materiality 3-4 |
| Voice defaults | directness 3, warmth 3, technicality 3, provocation 3, hype 3-4 |
| Allowed behaviors | usar gradiente como signature (con justificación), motion 320ms con easing dramático, glow puntual |
| Forbidden behaviors | "AI magic" como cualidad principal sin sustancia, blue/purple gradient default, abuso de glow |
| Shadow risk | promesa imposible, pretensión, hype vacío |
| Brand examples | Disney, Apple (touches mágicas), Tesla, MasterClass |
| Forja note | **el archetype Magician es el ÚNICO que justifica primary color en hue [235, 285].** Sin él, el Anti-Slop Gate bloquea purple/indigo. |

### 6. Hero

> *"Donde hay voluntad, hay camino."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | maestría, valor, prueba de competencia |
| Tagline mood | "construido para ganadores", "el campeón elige X" |
| UI translation | grids fuertes, contraste declarativo, fotografía de acción, motion direccional |
| Copy translation | métricas como prueba, comparativas vs competencia, "ranked #1", testimonios de líderes |
| Posture defaults | density 3, expression 3-4, geometry 3-4, warmth 2-3, editoriality 3, materiality 2-3 |
| Voice defaults | directness 4, warmth 2-3, technicality 3, provocation 2, hype 3 |
| Allowed behaviors | mostrar números/awards, comparison tables, copy de logro |
| Forbidden behaviors | grandilocuencia vacía, inflación de números, paternalismo |
| Shadow risk | arrogante, mansplaining, alienar a quien no se identifica con "ganador" |
| Brand examples | Nike, Salesforce ("Trailblazer"), Uber Pro, Toyota (Heroic-tinted) |

### 7. Lover

> *"Solo tenés ojos para mí."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | conexión, intimidad, placer |
| Tagline mood | seductor, sensorial, "vivilo" |
| UI translation | typography con tracking generoso, fotografía intimista, paletas cálidas + saturadas, motion suave |
| Copy translation | adjetivos sensoriales, segunda persona íntima, descripciones evocativas |
| Posture defaults | density 2, expression 3-4, geometry 2-3, warmth 4-5, editoriality 3-4, materiality 3 |
| Voice defaults | directness 2-3, warmth 5, technicality 1, provocation 2, hype 2 |
| Allowed behaviors | fotos lifestyle de cerca, copy sensorial, ilustración táctil |
| Forbidden behaviors | corporate-frío, datos como protagonistas, density alta |
| Shadow risk | superficial, manipulador, demasiado romántico para B2B |
| Brand examples | Chanel, Häagen-Dazs, Victoria's Secret, Nespresso |

### 8. Jester

> *"Si no te divierte, no vale la pena."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | diversión, espontaneidad, romper con seriedad |
| Tagline mood | irreverente, juguetón, autoconsciente |
| UI translation | color saturado, ilustración cartoon, microinteracciones festivas, motion bouncy controlado |
| Copy translation | humor verbal, references de cultura pop, autorreferencia |
| Posture defaults | density 2, expression 4-5, geometry 1-2, warmth 4-5, editoriality 2-3, materiality 3 |
| Voice defaults | directness 3, warmth 4-5, technicality 2, provocation 3, hype 3 |
| Allowed behaviors | jokes en empty states, gifs/animation playful, paletas saturadas |
| Forbidden behaviors | cinismo, humor que humilla al usuario, ironía constante (cansa) |
| Shadow risk | irresponsable, no-tomable-en-serio, alienar contextos formales |
| Brand examples | Old Spice, M&M's, Mailchimp (jester-tinted), Slack (touches), Duolingo |

### 9. Everyman

> *"Todos somos iguales."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | pertenencia, conexión cotidiana, equidad |
| Tagline mood | accesible, sin pretensión, "para vos y para mí" |
| UI translation | tipografía neutral/sans, paletas terrosas, fotografía documentary, layouts honestos |
| Copy translation | lenguaje de la calle, "nosotros" inclusivo, evitar tecnicismos |
| Posture defaults | density 3, expression 2, geometry 2-3, warmth 3-4, editoriality 2, materiality 2 |
| Voice defaults | directness 4, warmth 4, technicality 1-2, provocation 1, hype 1 |
| Allowed behaviors | testimonios de gente común, casos de uso cotidianos, precios transparentes |
| Forbidden behaviors | jerga, exclusividad, lujo |
| Shadow risk | aburrido, indiferenciado, "vainilla" |
| Brand examples | IKEA, Levi's, eBay, Target, Honda |

### 10. Caregiver

> *"Amás al prójimo como a ti mismo."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | servir, proteger, cuidar a otros |
| Tagline mood | cálido, protector, "estamos para vos" |
| UI translation | colores suaves cálidos, formularios bien guiados con ayuda contextual, errors empáticos, copy de soporte visible |
| Copy translation | segunda persona empática, instrucciones paso a paso, microcopy alentador |
| Posture defaults | density 2-3, expression 2-3, geometry 1-2, warmth 5, editoriality 2, materiality 2 |
| Voice defaults | directness 3, warmth 5, technicality 1-2, provocation 1, hype 1 |
| Allowed behaviors | help links visibles, error messages que ayudan no juzgan, modo asistido |
| Forbidden behaviors | tono frío, urgencia agresiva, paywalls que esconden ayuda básica |
| Shadow risk | paternalismo, infantilización del usuario, dependencia |
| Brand examples | Johnson & Johnson, Volvo, UNICEF, Mailchimp, Loom |

### 11. Ruler

> *"El poder es todo."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | control, prosperidad, jerarquía clara |
| Tagline mood | autoridad, herencia, premium |
| UI translation | tipografía serif autoritativa o sans muy cuidada, paletas oscuras + dorado/burgundy, simetría rigurosa |
| Copy translation | lenguaje formal, referencias institucionales, énfasis en duración / herencia |
| Posture defaults | density 3, expression 3-4, geometry 3-4, warmth 1-2, editoriality 4-5, materiality 3-4 |
| Voice defaults | directness 4, warmth 1-2, technicality 3-4, provocation 1, hype 1 |
| Allowed behaviors | metales (gold/silver/bronze) como accents, certifications/badges visibles, copy formal |
| Forbidden behaviors | informalidad, color saturado tipo juguetón, copy "casual" |
| Shadow risk | elitista, distante, fuera-de-tono |
| Brand examples | Rolex, American Express Platinum, BBC, Bank of America |

### 12. Creator

> *"Si lo podés imaginar, podés crearlo."*

| Aspecto | Valor |
|---------|-------|
| Core motivation | innovación, expresión, oficio visible |
| Tagline mood | celebrar el hacer, mostrar el proceso |
| UI translation | grids precisos, mono fonts en accents técnicos, tools visible, motion mecánico (no mágico), espacio para work-in-progress |
| Copy translation | énfasis en proceso/oficio, vocabulario técnico fluido, evitar buzzwords abstractos |
| Posture defaults | density 3-4, expression 3-4, geometry 4, warmth 2-3, editoriality 3-4, materiality 1-2 |
| Voice defaults | directness 4, warmth 3, technicality 4, provocation 2, hype 1 |
| Allowed behaviors | mostrar herramientas, blogs build-in-public, snippets de código en marketing, motion mecánico |
| Forbidden behaviors | "AI magic" sin sustancia, hype sin oficio, automation que oculta el proceso |
| Shadow risk | snob ("nosotros sabemos"), inaccesible para no-técnicos, perfeccionismo paralizante |
| Brand examples | Adobe, Figma, GitHub, Lego, Forge / Forja (default Forja-aligned) |

---

## Combinaciones más comunes (heurística para Discovery)

| Primary | Secondary frecuente | Producto típico |
|---------|---------------------|-----------------|
| Creator | Sage | Dev tools (Figma, GitHub, Vercel, Forge) |
| Sage | Creator | Analytics / data tools (Looker, Tableau) |
| Caregiver | Lover | Health / wellness / family SaaS |
| Outlaw | Creator | Counter-status quo SaaS (Linear vs Jira, Cash App vs banks) |
| Hero | Sage | B2B "ranked #1" tools (Salesforce-like) |
| Magician | Creator | Generative AI products (controlled use of magic) |
| Jester | Lover | B2C lifestyle apps (Duolingo, Headspace touches) |
| Everyman | Caregiver | Mass-market platforms (eBay, Target) |
| Explorer | Creator | Travel + outdoor SaaS (AllTrails, Strava) |
| Ruler | Sage | Premium B2B / fintech (Bloomberg, Amex Platinum) |

---

## Shadow archetypes — los más caros de evitar

Ranked por frecuencia de aparición tóxica en SaaS slop:

1. **Magician unjustified** — abuse de "AI magic" + blue-purple gradient default sin sustancia.
2. **Hero grandilocuente** — copy de "ranked #1" sin métricas reales.
3. **Lover-frío** — copy que pretende intimidad pero no la respalda con experience.
4. **Jester forzado** — humor que se siente Slack-bot-default, no auténtico de la marca.
5. **Caregiver paternalista** — error messages que dan lecciones en vez de ayudar.

`shadow_to_avoid` en R-005 sección 2.1 captura los 1-2 archetypes que el equipo decide cerrar la puerta.

---

## Cómo el `el-evaluador` valida coherencia archetype

Post-generación de brand.json:
1. Lee `archetype.primary` + `archetype.secondary`.
2. Cross-checa contra `visual_posture` y `voice.tone_axes`:
   - ¿Outlaw declarado pero `provocation: 1`? Inconsistencia.
   - ¿Creator declarado pero `editoriality: 1` y sin mono font? Inconsistencia.
   - ¿Caregiver declarado pero `warmth: 1`? Inconsistencia.
3. Cross-checa contra `tokens.colors`:
   - ¿Magician primary pero color primary fuera del hue range? OK.
   - ¿Cualquier otro archetype con color primary en hue [235, 285]? Reject.

Las inconsistencias generan `NEEDS_FIX` con root cause citando esta tabla.

---

*"Archetype no es etiqueta. Es contrato traducido a UI rules + copy rules."*
