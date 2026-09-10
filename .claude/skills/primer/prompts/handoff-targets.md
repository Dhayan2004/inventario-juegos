# Handoff Targets — qué skills invocar después de primer

## Objetivo

primer carga contexto pero NO ejecuta. Después del output, el agente (o usuario) elige el skill apropiado para la próxima acción. Este archivo documenta el routing.

## Mapping próxima acción → skill

| Estado detectado por primer | Próxima acción sugerida | Skill a invocar |
|------------------------------|--------------------------|-----------------|
| Brand DNA missing | "Inicializá Brand DNA" | `/add-ui-kit` (FRESH mode) |
| Brand DNA present, sin componentes UI | "Generá componentes UI base" | `/impeccable` (Mode C — BATCH) |
| Sin auth + necesita auth | "Setea auth" | `/add-login` |
| Auth presente + necesita pagos | "Setea pagos" | `/add-payments` |
| Auth presente + necesita emails transaccionales | "Setea emails" | `/add-emails` |
| Auth presente + necesita PWA/push | "Setea capabilities mobile" | `/add-mobile` |
| Active feature `passing` + queue tiene `pending` | "Próxima feature" | `/la-forja` (paralelización) o `/el-golpe` (one-shot) |
| Active feature `active` + working tree dirty | "Continuá active feature" | el agente continúa según estado de los archivos |
| Sin active feature + sin queue clara | "Planificá próxima feature" | `/la-herreria` (Blueprint generation) |
| Pre-deploy state | "Pre-deploy audit" | `/el-guardian` + `/web-quality` |
| Microtask atómica detectada | "<5min task" | `/el-tajo` |
| Mid-size feature | "<30min feature" | `/el-golpe` |
| Schema/migration cambio | "Apply migration" | `/el-migrador` |
| Tests/quality issues | "Test + audit" | `/calidad` o equivalente |
| User pidió "qué es esto" / "explicame" | (primer es la respuesta) | none — primer ya entrega |

## Cómo presentar handoffs

primer NO invoca skills automáticamente — solo SUGIERE. El usuario o el coordinator deciden qué skill correr.

### En output de primer

```markdown
## Próxima acción sugerida
- Corré `/add-ui-kit` Discovery FRESH para inicializar Brand DNA
  *(brand.json + voice.json missing detected en /brand/)*
```

Pattern: **acción específica + skill name + reason del gap detectado**.

### En output de error / gap

```markdown
## Próxima acción sugerida
- Resolver R1 violation antes de continuar — feature_list.json tiene 2 active features
  *(F3-S7 + promote-l-004 ambos active)*
- Tras resolver, invocá primer otra vez para refresh contexto
```

Pattern: **resolver el blocker primero + re-invocar primer si es ambiguo**.

## Casos donde primer NO sugiere skill

1. **Estado healthy + no obvious next step:** reportar "Sin pendiente claro — revisar feature_list backlog manualmente o invocar /la-herreria para planificar".
2. **Proyecto que es Forja factory mismo:** primer detecta esto via `.claude/memory/skills.md` presente + ARCHITECTURE.md presente (markers de Forja factory). Si lo detecta, sugerir `session_kickoff` en lugar de skills target-project.
3. **Proyecto sin Forja:** AGENTS.md missing → cold-start mode + sugerir `/forge-init` para inicializar.

## Cita L-004 (test diagnóstico)

primer NO usa el patrón default+override (no elige entre N providers). L-004 NO aplica directo. Pero si en el FUTURO emerge una sub-decisión (ej: "¿reportar 5 vs 10 vs 20 commits recientes?"), aplicar L-004:

> Test: ¿hay un degenerate case que requiera acción upstream del usuario? 
> - Para "5 vs 10 commits": NO. Es preference, ambos disponibles. → binary (default 5, override 10 via param)
> - Para "incluir branch lookup remoto": NO. Falla graceful si no hay network. → binary (default disabled, override enable via param)

Si emerge un caso con upstream user action mandatory → trinary con PAUSE. Por ahora no anticipo casos así para primer.

## Citations

- [memory:references#R-005] · [memory:lessons#L-004]
- [memory:CONSTRAINTS.md#R1] · [memory:CONSTRAINTS.md#R3]
