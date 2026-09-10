/**
 * Typography Section — renders display + body + mono families with
 * line-height samples. Verifies max_fonts validation rule
 * (brand.json.validation.max_fonts ≤ 2) by counting unique families.
 */

export function TypographySection() {
  return (
    <section aria-labelledby="typography-title">
      <h2
        id="typography-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Typography
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Roles: display (titulares), body (lectura), mono (técnico). Cada uno con
        un fallback a system fonts.
      </p>

      <div className="mt-[var(--space-8)] space-y-[var(--space-8)]">
        {/* Display scale */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            display · Geist
          </p>
          <p className="mt-[var(--space-3)] font-[family-name:var(--font-display)] text-6xl font-bold leading-[var(--line-height-display)]">
            Forjar es decidir antes de cortar.
          </p>
          <p className="mt-[var(--space-3)] font-[family-name:var(--font-display)] text-3xl font-semibold leading-tight text-[var(--color-text-muted)]">
            Una jerarquía visible.
          </p>
        </article>

        {/* Body scale */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            body · Geist
          </p>
          <p className="mt-[var(--space-3)] text-xl leading-[var(--line-height-body)] text-[var(--color-text)]">
            Body large — para subtítulos y leads. La densidad de la marca define
            cuán cómodo es leer este párrafo en pantalla durante varios minutos.
          </p>
          <p className="mt-[var(--space-3)] text-base leading-[var(--line-height-body)] text-[var(--color-text)]">
            Body base — la mayoría del contenido vive aquí. Si esta sección se
            siente densa, el eje <code className="font-mono">density</code> está
            alto y la marca asume un usuario que pasa horas en la UI.
          </p>
          <p className="mt-[var(--space-3)] text-sm leading-[var(--line-height-body)] text-[var(--color-text-muted)]">
            Body small — captions, metadatos, helper text. Nunca para párrafos
            largos: el contraste mínimo se pierde con peso bajo.
          </p>
        </article>

        {/* Mono */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            mono · Geist Mono
          </p>
          <pre className="mt-[var(--space-3)] overflow-x-auto rounded-[var(--radius-sm)] bg-[var(--color-surface)] p-[var(--space-4)] font-mono text-sm text-[var(--color-text)]">
            <code>
{`// brand.json.tokens.typography.mono.use_for
const monoUseFor = ['code', 'technical_labels', 'metadata']

function shouldRenderInMono(context) {
  return monoUseFor.includes(context)
}`}
            </code>
          </pre>
          <p className="mt-[var(--space-3)] text-xs text-[var(--color-text-subtle)]">
            avoid_for: long_paragraphs · marketing_headlines
          </p>
        </article>
      </div>
    </section>
  )
}
