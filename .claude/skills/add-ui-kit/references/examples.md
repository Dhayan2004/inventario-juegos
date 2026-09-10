# 3 Brand DNA Examples — Well-formed brand.json + voice.json

> Reference de outputs canónicos. Consumida por `prompts/generate-brand-json.md` y `prompts/generate-voice-json.md` como model-de-llegada.
>
> **Source schema:** [memory:references#R-005].
> **Propósito:** mostrar 3 brand.json + voice.json completos, parseables, que pasan Anti-Slop Gate. El agente generador puede comparar contra estos ejemplos cuando dude del shape.

---

## Cómo usar este archivo

1. Cuando el Discovery termina, `generate-brand-json.md` rellena el template.
2. Si el agente duda de cómo expresar algo (ej: cómo declarar `restricted_hues`, cómo combinar `archetype.allowed_behaviors` con `voice.principles`), busca acá un ejemplo análogo.
3. **NO** copiar literal — usar como referencia de shape + completeness.

---

## Ejemplo 1 — Forge / Forja (Tech Utility + Outlaw tension)

> Sirve como caso canónico Forja: dark mode, Creator primary con Outlaw controlado, Geist + Geist Mono, primary orange #E85420.

### brand.json

```json
{
  "schema_version": "1.1.0",
  "brand": {
    "name": "Carlos Domínguez",
    "product": "Forge",
    "tagline": "El código mediocre se genera. El gran software se forja.",
    "positioning": "El puente entre el vibe coding caótico y el software bien construido.",
    "category": "AI-assisted software craft system",
    "audience": ["founders", "indie hackers", "dev leads", "B2B tech-ready LATAM"]
  },
  "archetype": {
    "primary": "Creator",
    "secondary": "Sage",
    "controlled_tension": "Outlaw",
    "shadow_to_avoid": ["Magician", "Hero"],
    "ui_translation": "craft, precision, visible structure, no spectacle",
    "copy_translation": "diagnosis, oficio, clarity, no hype",
    "allowed_behaviors": [
      "Mostrar herramientas y proceso, no solo resultados",
      "Confrontar el status quo de vibe coding cuando agrega valor (Outlaw controlado)",
      "Usar mono fonts para anclar autoridad técnica"
    ],
    "forbidden_behaviors": [
      "Vender 'AI magic' como cualidad principal",
      "Promesas de velocidad sin oficio",
      "Estética edgy sin propósito"
    ]
  },
  "visual_posture": {
    "density": 3,
    "expression": 4,
    "geometry": 4,
    "warmth": 3,
    "editoriality": 4,
    "materiality": 3
  },
  "tokens": {
    "colors": {
      "primary": "#E85420",
      "primary_deep": "#A02408",
      "primary_accessible_on_dark": "#FF8C5C",
      "accent": "#FFB627",
      "secondary": "#1A2238",
      "background": "#0A0A0A",
      "surface": "#161616",
      "surface_elevated": "#202020",
      "border": "#2A2A2A",
      "text": "#FFFFFF",
      "text_muted": "#A0A0A0",
      "text_subtle": "#888888",
      "success": "#00C896",
      "danger": "#FF3B5B",
      "warning": "#FFB020"
    },
    "typography": {
      "display": { "family": "Geist", "weights": [600, 700, 800], "use_for": ["page_titles", "section_headlines", "hero_statements"] },
      "body":    { "family": "Geist", "weights": [400, 500, 600], "line_height": 1.5 },
      "mono":    { "family": "Geist Mono", "use_for": ["code", "technical_labels", "metadata"], "avoid_for": ["long_paragraphs", "marketing_headlines"] }
    },
    "shape": { "radius_sm": 6, "radius_md": 12, "radius_lg": 16, "border_width": 1 },
    "spacing": {
      "unit": 8,
      "section_y":     { "sm": 48, "md": 72, "lg": 96 },
      "component_gap": { "xs": 8, "sm": 12, "md": 16, "lg": 24 }
    }
  },
  "component_rules": {
    "button": {
      "variants": ["primary", "secondary", "ghost", "danger"],
      "rules": [
        "Only one primary action per view section",
        "No diagonal gradients",
        "Focus, hover, active, disabled and loading states required",
        "Icon must clarify the action"
      ]
    },
    "card": {
      "variants": ["default", "interactive", "metric", "empty"],
      "rules": [
        "No nested cards",
        "Use border or surface before heavy shadow in dark UI",
        "Card must group, compare, execute or reveal"
      ]
    },
    "form": {
      "variants": ["text", "search", "textarea", "select"],
      "rules": [
        "Visible label by default",
        "Error message must be textual and near the field",
        "Focus state must be visible",
        "Mobile tap targets minimum 44px"
      ]
    },
    "navigation": {
      "variants": ["sidebar", "topbar", "tabs", "breadcrumb"],
      "rules": [
        "Active state must be unambiguous",
        "Do not hide critical navigation for aesthetics",
        "Mobile behavior must be defined"
      ]
    },
    "modal": {
      "variants": ["confirm", "form", "detail"],
      "rules": [
        "Contextual title required",
        "Escape/cancel behavior required",
        "Destructive actions require explicit confirmation",
        "Focus trap required"
      ]
    }
  },
  "motion": {
    "personality": {
      "energy": "precise",
      "elasticity": "snap_not_bounce",
      "directionality": "mechanical",
      "sequencing": "subtle_stagger",
      "distance": "short",
      "restraint": "high"
    },
    "durations_ms": { "instant": 80, "fast": 140, "base": 220, "slow": 320 },
    "rules": [
      "Respect prefers-reduced-motion",
      "No above-fold fade-in longer than 300ms",
      "No bounce unless explicitly declared",
      "Avoid layout-shifting animation"
    ]
  },
  "anti_slop": {
    "forbidden_colors": ["#6366F1", "#8B5CF6", "#A855F7"],
    "restricted_hues": [
      { "name": "default_ai_purple_blue", "hue_range": [235, 285], "allowed_only_if": ["brand_declares_purple_as_primary", "archetype_primary_is_magician"] }
    ],
    "forbidden_patterns": [
      "diagonal blue-purple gradient hero",
      "glassmorphism cards over blurred blobs",
      "three generic feature cards with icons",
      "Inter on white with purple CTA as default SaaS identity",
      "rounded-3xl everywhere",
      "shadow-2xl as default depth",
      "generic browser mockup with fake dashboard",
      "robot icon in circle gradient as hero visual"
    ]
  },
  "contexts": {
    "web_app": { "density": "balanced", "motion": "crisp", "navigation": "full" },
    "mobile_native": { "density": "slightly_spacious", "tap_target_min": 44, "navigation": "platform_native" },
    "vertical_video": { "contrast": "higher", "type_scale": "larger", "safe_area": true, "copy": "shorter" },
    "pitch_slides": { "editoriality": "higher", "density": "lower" },
    "transactional_email": { "motion": "none", "fallback_fonts": ["Arial", "Helvetica"], "layout": "single_column_first" }
  },
  "validation": {
    "min_contrast_body": 4.5,
    "min_contrast_large": 3,
    "max_fonts": 2,
    "max_radius_values": 3,
    "max_primary_color_usage_percent": 18,
    "brand_score_weights": {
      "accessibility": 30,
      "token_compliance": 25,
      "component_compliance": 20,
      "anti_slop": 15,
      "voice_and_archetype": 10
    }
  }
}
```

### voice.json

Ver R-005 sección 9.2 — el voice.json de Forge ya está poblado en el schema canónico y sirve 1:1 como ejemplo Forja-aligned.

---

## Ejemplo 2 — Glow (Warm & Soft + Caregiver)

> Sirve como caso human-first SaaS B2C. Imaginá un journaling app para wellness emocional. Audiencia: profesionales urbanos LATAM 25-40 que buscan soporte emocional sin terapeuta presencial.

### brand.json

```json
{
  "schema_version": "1.1.0",
  "brand": {
    "name": "Glow",
    "product": "Glow",
    "tagline": "Tu día, mejor entendido.",
    "positioning": "Glow es el journaling app que convierte tus pensamientos sueltos en pautas claras de bienestar.",
    "category": "wellness journaling SaaS",
    "audience": ["urban professionals 25-40 LATAM", "anyone who tried therapy and found it hard to access", "self-improvement readers"]
  },
  "archetype": {
    "primary": "Caregiver",
    "secondary": "Lover",
    "shadow_to_avoid": ["Ruler", "Outlaw"],
    "ui_translation": "calidez, espacio, formularios bien guiados, errores empáticos",
    "copy_translation": "segunda persona empática, instrucciones suaves, sin urgencia",
    "allowed_behaviors": [
      "Microcopy de aliento en empty states",
      "Help links siempre visibles",
      "Color saturado pero cálido (no clínico)"
    ],
    "forbidden_behaviors": [
      "Tono frío o clínico (rompe contrato Caregiver)",
      "Urgencia agresiva (ej: 'completá tu journaling AHORA')",
      "Paywalls que esconden ayuda básica"
    ]
  },
  "visual_posture": { "density": 2, "expression": 3, "geometry": 2, "warmth": 5, "editoriality": 2, "materiality": 2 },
  "tokens": {
    "colors": {
      "primary": "#FF6B6B",
      "primary_deep": "#C9433D",
      "primary_accessible_on_light": "#B8403B",
      "accent": "#FFD166",
      "surface": "#FFF8F1",
      "surface_elevated": "#FFFFFF",
      "border": "#F2E6D5",
      "text": "#2B2118",
      "text_muted": "#6B5D4F",
      "text_subtle": "#A39584",
      "success": "#06D6A0",
      "danger": "#E63946",
      "warning": "#F4A261"
    },
    "typography": {
      "display": { "family": "Outfit", "weights": [600, 700], "use_for": ["headlines", "section_titles"] },
      "body":    { "family": "Outfit", "weights": [400, 500], "line_height": 1.55 },
      "mono":    null
    },
    "shape": { "radius_sm": 8, "radius_md": 14, "radius_lg": 20, "border_width": 1 },
    "spacing": {
      "unit": 8,
      "section_y":     { "sm": 56, "md": 88, "lg": 120 },
      "component_gap": { "xs": 8, "sm": 16, "md": 20, "lg": 28 }
    }
  },
  "component_rules": {
    "button": {
      "variants": ["primary", "secondary", "ghost", "danger"],
      "rules": [
        "Primary CTA usa el coral #FF6B6B con texto blanco — contrast verified WCAG AA Large",
        "Hover state suaviza el color, no lo intensifica",
        "Loading state usa shimmer cálido, no spinner técnico"
      ]
    },
    "card": {
      "variants": ["default", "interactive", "empty"],
      "rules": [
        "Empty state cards llevan microcopy alentador, no instructivo",
        "Cards usan surface_elevated + border sutil, no shadow heavy"
      ]
    },
    "form": {
      "variants": ["text", "textarea", "select", "rating"],
      "rules": [
        "Labels visibles siempre",
        "Error messages empáticos: 'Necesitamos un email para enviarte el resumen' NO 'Invalid email'",
        "Required fields marcados con asterisco + tooltip descriptivo"
      ]
    },
    "navigation": {
      "variants": ["topbar", "tabs"],
      "rules": [
        "Help / Soporte siempre visible en topbar",
        "Active state usa primary color + leve glow"
      ]
    },
    "modal": {
      "variants": ["confirm", "form"],
      "rules": [
        "Confirm de delete usa copy empático: 'Esta entrada se va a borrar. ¿Querés guardarla antes?' NO 'Confirm delete'",
        "Cerrar con click outside permitido siempre"
      ]
    }
  },
  "motion": {
    "personality": {
      "energy": "calm",
      "elasticity": "soft_ease",
      "directionality": "ambient",
      "sequencing": "all_together",
      "distance": "short",
      "restraint": "medium"
    },
    "durations_ms": { "instant": 100, "fast": 180, "base": 280, "slow": 400 },
    "rules": [
      "Respect prefers-reduced-motion",
      "No bounce — el usuario está vulnerable, no queremos jugar",
      "Loading states acompañan, no entretienen"
    ]
  },
  "anti_slop": {
    "forbidden_colors": ["#6366F1", "#8B5CF6", "#A855F7"],
    "restricted_hues": [
      { "name": "default_ai_purple_blue", "hue_range": [235, 285], "allowed_only_if": ["brand_declares_purple_as_primary"] }
    ],
    "forbidden_patterns": [
      "lavado clínico con foto stock manos sosteniendo planta",
      "robot icon en círculo gradient como hero visual",
      "three feature cards genéricas",
      "rounded-3xl en todo (excepto avatares)",
      "shadow-2xl como default",
      "Inter on white con purple CTA",
      "AI-magic copy"
    ]
  },
  "contexts": {
    "web_app": { "density": "balanced", "motion": "calm", "navigation": "full" },
    "mobile_native": { "density": "spacious", "tap_target_min": 48, "navigation": "platform_native" },
    "transactional_email": { "motion": "none", "fallback_fonts": ["Helvetica", "Arial"], "layout": "single_column_first" }
  },
  "validation": {
    "min_contrast_body": 4.5,
    "min_contrast_large": 3,
    "max_fonts": 1,
    "max_radius_values": 3,
    "max_primary_color_usage_percent": 22,
    "brand_score_weights": {
      "accessibility": 35,
      "token_compliance": 20,
      "component_compliance": 20,
      "anti_slop": 15,
      "voice_and_archetype": 10
    }
  }
}
```

### voice.json (resumen — full structure igual a R-005 9.2)

```json
{
  "schema_version": "1.1.0",
  "voice": {
    "name": "Glow",
    "language": "es-419",
    "tone_axes": { "directness": 3, "warmth": 5, "technicality": 1, "provocation": 1, "hype": 1 },
    "principles": [
      "Acompañar, no diagnosticar",
      "Sin juicio",
      "Mostrar progreso, no urgencia",
      "Espacio para no saber qué decir"
    ],
    "vibe": "Una amiga que escucha sin opinión y solo sugiere cuando le pedís",
    "audience": "Profesionales urbanos LATAM 25-40 con vida emocional rica pero estresada",
    "code_switching": { "allowed": ["journaling", "mindfulness"], "rule": "Anglicismos solo cuando es vocabulario adoptado" },
    "safe_words": ["acompañar", "escuchar", "espacio", "ritmo", "pequeño paso"],
    "avoid_words": ["transform your life", "unlock", "supercharge", "AI-powered", "revolutionary", "best-in-class", "biohacking", "optimize yourself"],
    "sentence_rules": {
      "prefer": ["Frases que abren preguntas", "Verbos suaves", "Validación antes de sugerencia"],
      "avoid": ["Imperativos fuertes", "Comparaciones competitivas", "Hype emocional"]
    },
    "hooks": [
      "Tu día, mejor entendido.",
      "Lo que sentís hoy importa.",
      "No tenés que tener todo claro para empezar."
    ],
    "cta_style": "Suave, invita",
    "cta_examples": ["Empezá cuando estés listo.", "Probá un journal de 2 minutos.", "Mirá cómo funciona."]
  }
}
```

---

## Ejemplo 3 — Loop (Brutalist Experimental + Outlaw)

> Sirve como caso counter-status-quo. Imaginá una alt-finance app — neobanco para freelancers que rechaza la estética bank-tradicional y la fintech-friendly. Audiencia: creators 22-35 con desconfianza hacia bancos.

### brand.json

```json
{
  "schema_version": "1.1.0",
  "brand": {
    "name": "Loop",
    "product": "Loop",
    "tagline": "El banco que no te trata como cliente.",
    "positioning": "Loop es el neobanco diseñado por freelancers para freelancers — sin la estética conciliadora de los bancos digitales conformistas.",
    "category": "alt-fintech / neobank",
    "audience": ["freelance creators 22-35", "indie founders sin nómina fija", "people who closed their traditional bank account in disgust"]
  },
  "archetype": {
    "primary": "Outlaw",
    "secondary": "Creator",
    "shadow_to_avoid": ["Caregiver", "Innocent"],
    "ui_translation": "contraste violento controlado, layouts asimétricos puntuales, no decoraciones tranquilizadoras",
    "copy_translation": "manifiesto, imperativo, confrontativo vs banca tradicional, NUNCA vs el usuario",
    "allowed_behaviors": [
      "Headlines tipo manifesto",
      "Romper grid en hero sections cuando sirve al statement",
      "Uso intencional de rojo + amarillo brillante",
      "Copy directa que confronta status quo bancario"
    ],
    "forbidden_behaviors": [
      "Caos visual sin propósito",
      "Edginess adolescente (insultar al usuario, jokes que humillan)",
      "Sacrificar accesibilidad por estética",
      "Tono conciliador (rompe el contrato Outlaw)"
    ]
  },
  "visual_posture": { "density": 3, "expression": 5, "geometry": 5, "warmth": 1, "editoriality": 4, "materiality": 3 },
  "tokens": {
    "colors": {
      "primary": "#FF3B30",
      "primary_deep": "#B82018",
      "primary_accessible_on_dark": "#FF6B5C",
      "accent": "#FFFC00",
      "surface": "#000000",
      "surface_elevated": "#0A0A0A",
      "surface_higher": "#1A1A1A",
      "border": "#FF3B30",
      "text": "#FFFFFF",
      "text_muted": "#888888",
      "text_subtle": "#444444",
      "success": "#39FF14",
      "danger": "#FF3B30",
      "warning": "#FFFC00"
    },
    "typography": {
      "display": { "family": "Space Grotesk", "weights": [700, 800], "use_for": ["headlines", "manifestos"] },
      "body":    { "family": "Space Grotesk", "weights": [400, 600], "line_height": 1.4 },
      "mono":    { "family": "JetBrains Mono", "use_for": ["transaction_ids", "amounts", "system_messages"] }
    },
    "shape": { "radius_sm": 0, "radius_md": 0, "radius_lg": 2, "border_width": 2 },
    "spacing": {
      "unit": 8,
      "section_y":     { "sm": 48, "md": 96, "lg": 144 },
      "component_gap": { "xs": 8, "sm": 16, "md": 24, "lg": 32 }
    }
  },
  "component_rules": {
    "button": {
      "variants": ["primary", "secondary", "ghost", "danger"],
      "rules": [
        "Primary usa rojo #FF3B30 con texto blanco, border de 2px",
        "NO gradients — el primary es plano",
        "Hover invierte (background blanco, texto rojo)",
        "Disabled state mantiene contrast 3:1 mínimo (no fade-out cobarde)"
      ]
    },
    "card": {
      "variants": ["default", "metric", "transaction"],
      "rules": [
        "NO nested cards",
        "Cards de transacción usan mono font para amount",
        "Border de 2px reemplaza shadow"
      ]
    },
    "form": {
      "variants": ["text", "amount", "select"],
      "rules": [
        "Labels en uppercase con tracking",
        "Error message en rojo brillante con asterisco",
        "Focus state usa border de 2px blanco"
      ]
    },
    "navigation": {
      "variants": ["sidebar", "topbar"],
      "rules": [
        "Active state invierte completamente el item",
        "Sin transitions suaves — snap inmediato"
      ]
    },
    "modal": {
      "variants": ["confirm", "transaction", "manifesto"],
      "rules": [
        "Backdrop completamente negro, no blur",
        "Destructive actions con confirm de 2 pasos",
        "Modal de manifesto (welcome) ocupa fullscreen"
      ]
    }
  },
  "motion": {
    "personality": {
      "energy": "violent",
      "elasticity": "snap_only",
      "directionality": "abrupt",
      "sequencing": "instant_or_none",
      "distance": "minimal",
      "restraint": "low"
    },
    "durations_ms": { "instant": 60, "fast": 100, "base": 160, "slow": 240 },
    "rules": [
      "Respect prefers-reduced-motion",
      "NO bounce ever",
      "NO fade transitions — usar snap",
      "Motion como puntuación, no como decoración"
    ]
  },
  "anti_slop": {
    "forbidden_colors": ["#6366F1", "#8B5CF6", "#A855F7"],
    "restricted_hues": [
      { "name": "default_ai_purple_blue", "hue_range": [235, 285], "allowed_only_if": ["brand_declares_purple_as_primary"] }
    ],
    "forbidden_patterns": [
      "diagonal blue-purple gradient",
      "glassmorphism",
      "rounded-3xl",
      "shadow-2xl",
      "fintech-friendly blue with rounded buttons",
      "stock photo de gente sonriendo viendo el celular",
      "growth chart sin disclaimer",
      "testimonio sin nombre + cargo verificable"
    ]
  },
  "contexts": {
    "web_app": { "density": "balanced", "motion": "snap", "navigation": "full" },
    "mobile_native": { "density": "balanced", "tap_target_min": 44, "navigation": "platform_native" },
    "transactional_email": { "motion": "none", "fallback_fonts": ["Helvetica", "Arial"], "layout": "single_column_first" }
  },
  "validation": {
    "min_contrast_body": 4.5,
    "min_contrast_large": 3,
    "max_fonts": 2,
    "max_radius_values": 1,
    "max_primary_color_usage_percent": 25,
    "brand_score_weights": {
      "accessibility": 25,
      "token_compliance": 30,
      "component_compliance": 20,
      "anti_slop": 15,
      "voice_and_archetype": 10
    }
  }
}
```

### voice.json (resumen)

```json
{
  "schema_version": "1.1.0",
  "voice": {
    "name": "Loop",
    "language": "es-419",
    "tone_axes": { "directness": 5, "warmth": 1, "technicality": 3, "provocation": 5, "hype": 2 },
    "principles": [
      "Confrontá la banca tradicional, no al usuario",
      "Manifesto antes que feature list",
      "Frases cortas, declarativas",
      "Lenguaje del freelance, no del corporate"
    ],
    "vibe": "El amigo que ya no aguanta más al banco y decidió hacer algo",
    "audience": "Creators 22-35 con cuenta cerrada en banco tradicional",
    "code_switching": { "allowed": ["freelance", "side hustle", "neobank", "ACH", "wire"], "rule": "Vocabulario freelance adoptado sin traducir" },
    "safe_words": ["banco real", "tu plata", "sin pretender", "directo", "sin letras chicas"],
    "avoid_words": ["seamless", "premium", "world-class", "trusted partner", "fintech-friendly", "scale with confidence", "your financial wellness journey"],
    "sentence_rules": {
      "prefer": ["Imperativos cortos", "Manifesto headlines", "Comparativas vs banca tradicional"],
      "avoid": ["Lenguaje corporativo", "Conciliación", "Promesas absolutas"]
    },
    "hooks": [
      "El banco que no te trata como cliente.",
      "Tu plata no es 'producto financiero'. Es tu plata.",
      "Sin manager. Sin paciencia. Sin esperar."
    ],
    "cta_style": "Imperativo confrontativo",
    "cta_examples": ["Cerrá la cuenta vieja.", "Mové la plata.", "Probá un día."]
  }
}
```

---

## Anti-Slop Gate — verificación de los 3 ejemplos

| Ejemplo | hue range [235,285]? | max_fonts | max_radius_values | Justificación de overrides |
|---------|----------------------|-----------|-------------------|----------------------------|
| Forge | NO (primary #E85420 = orange, hue ~14) | 2 (Geist + Geist Mono) | 3 (6/12/16) | OK |
| Glow | NO (primary #FF6B6B = coral, hue ~0) | 1 (Outfit) | 3 (8/14/20) | OK |
| Loop | NO (primary #FF3B30 = red, hue ~3) | 2 (Space Grotesk + JetBrains Mono) | 1 (0/0/2 — es decir 0 y 2) | max_radius_values=1 documentado en validation; OK |

Los 3 pasan Anti-Slop Gate por construcción.

---

## Cómo el agente generador usa estos ejemplos

1. Leer Discovery output del usuario.
2. Identificar cuál de los 3 ejemplos es estructuralmente análogo.
3. Usar como **shape reference**, NO copiar literal.
4. Adaptar tokens / archetype / posture al input del usuario.
5. Aplicar Anti-Slop Gate al output.

Ejemplo: si Discovery dice `archetype.primary: Caregiver` + warmth alto → mirar ejemplo Glow para shape de `component_rules`, `motion.personality`, `validation`.

---

*"3 ejemplos completos. 3 archetypes muy distintos. 3 shapes de mismo schema."*
